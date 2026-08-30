-- SystemVerilog signal analysis: what writes it, what reads it.
--
-- Everything rests on a single observation about the verilog treesitter
-- grammar: the nature of an occurrence can be read from its ancestor chain. An
-- identifier is a driver when it sits under a `*_lvalue` without crossing a
-- `select` on the way -- which is what tells `q` from `idx` in `q[idx] <= sum`.

local M = {}

-- Ancestors that determine the nature of an occurrence.
local LVALUE = {
  net_lvalue = true,
  variable_lvalue = true,
  nonblocking_assignment_lvalue = true,
}
local SELECT = {
  select = true,
  bit_select = true,
  constant_bit_select = true,
  constant_range = true,
  constant_select = true,
  part_select_range = true,
  indexed_range = true,
}
local CONTROL = {
  cond_predicate = true,
  case_expression = true,
  case_item_expression = true,
}
local DECL = {
  variable_decl_assignment = true,
  net_decl_assignment = true,
  param_assignment = true,
  list_of_variable_decl_assignments = true,
  list_of_net_decl_assignments = true,
  list_of_port_identifiers = true,
  list_of_variable_identifiers = true,
}
local PORTDECL = {
  ansi_port_declaration = true,
  input_declaration = true,
  output_declaration = true,
  inout_declaration = true,
}
local PORTCONN = {
  named_port_connection = true,
  ordered_port_connection = true,
}
-- Nodes that open an expression: used to tell apart, in `.din(sig)`, the port
-- name (a direct child) from the connected signal (nested under an expression).
local EXPR = {
  expression = true,
  constant_expression = true,
  primary = true,
  constant_primary = true,
  mintypmax_expression = true,
}
local NOTSIGNAL = {
  name_of_instance = "instancename",
  module_instantiation = "moduletype",
  module_ansi_header = "modulename",
  module_nonansi_header = "modulename",
  module_header = "modulename",
}
local SCOPE = {
  module_declaration = true,
  interface_declaration = true,
  package_declaration = true,
  program_declaration = true,
  source_file = true,
}

--- Nature of an identifier occurrence, deduced from its ancestors.
--- @param node TSNode a `simple_identifier`
--- @return string kind driver|load|control|clock|decl|portdecl|port|portname
function M.classify(node)
  local parent = node:parent()
  if parent and parent:type() == "hierarchical_identifier" then
    local base = parent:named_child(0)
    if base and base:id() ~= node:id() then
      return "field"
    end
  end
  local n = parent
  local saw_select, saw_expr = false, false
  while n do
    local t = n:type()
    if SELECT[t] then
      saw_select = true
    elseif EXPR[t] then
      saw_expr = true
    elseif LVALUE[t] then
      -- Under a select we are indexing the target: that is a read.
      return saw_select and "load" or "driver"
    elseif NOTSIGNAL[t] then
      return NOTSIGNAL[t]
    elseif PORTDECL[t] then
      -- Under a select we are in a dimension: `[W-1:0]` reads W.
      return saw_select and "load" or "portdecl"
    elseif DECL[t] then
      return saw_select and "load" or "decl"
    elseif t == "event_control" then
      return "clock"
    elseif CONTROL[t] then
      return "control"
    elseif PORTCONN[t] then
      return saw_expr and "port" or "portname"
    elseif SCOPE[t] then
      return "load"
    end
    n = n:parent()
  end
  return "load"
end

--- Walks up to the first ancestor whose type appears in `set`.
local function ancestor(node, set)
  local n = node:parent()
  while n do
    if set[n:type()] then
      return n
    end
    if SCOPE[n:type()] then
      return nil
    end
    n = n:parent()
  end
end

local CONSTRUCT = {
  always_construct = true,
  continuous_assign = true,
  initial_construct = true,
  final_construct = true,
  module_instantiation = true,
  data_declaration = true,
  net_declaration = true,
  ansi_port_declaration = true,
}

--- Readable label for the enclosing construct: `always_ff`, `assign`, ...
function M.construct(node, src)
  local n = ancestor(node, CONSTRUCT)
  if not n then
    return "?"
  end
  local t = n:type()
  if t == "always_construct" then
    for c in n:iter_children() do
      if c:type() == "always_keyword" then
        return vim.treesitter.get_node_text(c, src)
      end
    end
    return "always"
  elseif t == "continuous_assign" then
    return "assign"
  elseif t == "initial_construct" then
    return "initial"
  elseif t == "final_construct" then
    return "final"
  elseif t == "module_instantiation" then
    return "instance"
  elseif t == "ansi_port_declaration" then
    return "port"
  end
  return "decl"
end

local ASSIGN = {
  operator_assignment = true,
  nonblocking_assignment = true,
  net_assignment = true,
}
local BRANCH = {
  conditional_statement = true,
  case_statement = true,
}

--- Names of the signals written in a subtree (handles concatenations and the
--- several branches of an `if` / `case`).
local function lvalue_names(node, src, acc, seen)
  acc, seen = acc or {}, seen or {}
  local t = node:type()
  -- A field access reads as one unit: `fcsr_d.fflags` is a single target.
  if t == "hierarchical_identifier" then
    local base = node:named_child(0)
    if base and M.classify(base) == "driver" then
      local name = vim.treesitter.get_node_text(node, src)
      if not seen[name] then
        seen[name] = true
        acc[#acc + 1] = name
      end
    end
    return acc
  end
  if t == "simple_identifier" and M.classify(node) == "driver" then
    local name = vim.treesitter.get_node_text(node, src)
    if not seen[name] then
      seen[name] = true
      acc[#acc + 1] = name
    end
  end
  for c in node:iter_children() do
    if c:named() then
      lvalue_names(c, src, acc, seen)
    end
  end
  return acc
end

--- What the occurrence feeds: the signal(s) written by the construct that
--- holds it. For a condition, that is everything the branch assigns.
function M.targets(node, src)
  local n = node:parent()
  while n do
    local t = n:type()
    if ASSIGN[t] or BRANCH[t] then
      return lvalue_names(n, src)
    elseif PORTCONN[t] then
      -- The first `simple_identifier` of a named connection is the port.
      for c in n:iter_children() do
        if c:type() == "simple_identifier" then
          return { vim.treesitter.get_node_text(c, src) }
        end
      end
      return {}
    elseif SCOPE[t] then
      return {}
    end
    n = n:parent()
  end
  return {}
end

--- Signals read by the assignment that writes `node`: the fan-in step.
function M.sources(node, src, self_name)
  local n, assign = node:parent(), nil
  while n do
    local t = n:type()
    if ASSIGN[t] or t == "continuous_assign" then
      assign = n
      break
    elseif SCOPE[t] then
      break
    end
    n = n:parent()
  end
  if not assign then
    return {}
  end
  local acc, seen = {}, {}
  local function dig(x)
    local t = x:type()
    if t == "hierarchical_identifier" then
      local base = x:named_child(0)
      if base then
        local kind = M.classify(base)
        if kind == "load" or kind == "control" then
          local name = vim.treesitter.get_node_text(x, src)
          local root_name = vim.treesitter.get_node_text(base, src)
          if not seen[name] and root_name ~= self_name then
            seen[name] = true
            acc[#acc + 1] = name
          end
        end
      end
      return
    end
    if t == "simple_identifier" then
      local kind = M.classify(x)
      if kind == "load" or kind == "control" then
        local name = vim.treesitter.get_node_text(x, src)
        if not seen[name] and name ~= self_name then
          seen[name] = true
          acc[#acc + 1] = name
        end
      end
      return
    end
    for c in x:iter_children() do
      if c:named() then
        dig(c)
      end
    end
  end
  dig(assign)
  return acc
end

--- Enclosing instance, for occurrences of kind `port`.
function M.instance(node, src)
  local n = ancestor(node, { module_instantiation = true })
  if not n then
    return nil
  end
  local mod, inst
  for c in n:iter_children() do
    if c:type() == "simple_identifier" then
      mod = vim.treesitter.get_node_text(c, src)
    elseif c:type() == "hierarchical_instance" then
      for d in c:iter_children() do
        if d:type() == "name_of_instance" then
          inst = vim.treesitter.get_node_text(d, src)
        end
      end
    end
  end
  return { module = mod, instance = inst }
end

--- Declared direction of a port of the current module (ANSI or not).
--- In ANSI style an omitted direction is inherited from the previous port.
function M.port_direction(node, src)
  local decl = ancestor(node, PORTDECL) or (PORTDECL[node:parent():type()] and node:parent())
  while decl do
    local found
    local function dig(n)
      for c in n:iter_children() do
        if c:type() == "port_direction" then
          found = vim.treesitter.get_node_text(c, src)
          return
        end
        if c:named() and not found then dig(c) end
      end
    end
    dig(decl)
    if found then
      return found
    end
    decl = decl:prev_named_sibling()
  end
end

--- Module enclosing a node, and its name.
function M.module_of(node, src)
  local n = node
  while n do
    if n:type() == "module_declaration" then
      local name
      for c in n:iter_children() do
        local t = c:type()
        if t == "module_ansi_header" or t == "module_nonansi_header" or t == "module_header" then
          for d in c:iter_children() do
            if d:type() == "simple_identifier" then
              name = vim.treesitter.get_node_text(d, src)
              break
            end
          end
        end
      end
      return n, name
    end
    n = n:parent()
  end
end

--- Regions treesitter failed to parse. Silence would be worse than an error,
--- so we count them in order to warn.
local function count_errors(node)
  if not node:has_error() then
    return 0
  end
  local n = 0
  if node:type() == "ERROR" then
    n = 1
  end
  for c in node:iter_children() do
    n = n + count_errors(c)
  end
  return n
end

--- Signal identifier under the cursor.
--- When the cursor sits on indentation or an operator, take the first
--- identifier to its right on the same line.
--- @return string|nil name, string|nil rejected_kind, TSNode|nil node
function M.signal_at_cursor(bufnr)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local node = vim.treesitter.get_node({ bufnr = bufnr })
  while node and node:type() ~= "simple_identifier" do
    node = node:parent()
  end

  if not node then
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "verilog")
    if ok and parser then
      local root = parser:parse()[1]:root()
      local query = vim.treesitter.query.parse("verilog", "((simple_identifier) @id)")
      local best, bestcol
      for _, n in query:iter_captures(root, bufnr, row, row + 1) do
        local r, c = n:range()
        if r == row and c >= col and (not bestcol or c < bestcol) then
          best, bestcol = n, c
        end
      end
      node = best
    end
  end

  if not node then
    return nil
  end
  local kind = M.classify(node)
  if kind == "modulename" or kind == "moduletype" or kind == "instancename" then
    return nil, kind
  end
  -- On a field (`pkt.hdr`), fall back to the base signal.
  if kind == "field" then
    node = node:parent():named_child(0)
  end
  return vim.treesitter.get_node_text(node, bufnr), nil, node
end

local IGNORE = {
  field = true,
  modulename = true,
  moduletype = true,
  instancename = true,
  portname = true,
}

--- Every occurrence of a signal inside the module that contains `from`.
--- @return table|nil result, string|nil error
function M.scan(src, from, name)
  local mod, modname = M.module_of(from, src)
  if not mod then
    return nil, "cursor is not inside a module"
  end
  local query = vim.treesitter.query.parse("verilog", "((simple_identifier) @id)")
  local out = {
    signal = name,
    module = modname,
    errors = count_errors(mod),
    drivers = {},
    loads = {},
    decls = {},
  }
  for _, node in query:iter_captures(mod, src) do
    if vim.treesitter.get_node_text(node, src) == name then
      local kind = M.classify(node)
      if not IGNORE[kind] then
        local lnum, col = node:range()
        local item = {
          lnum = lnum + 1,
          col = col,
          kind = kind,
          construct = M.construct(node, src),
        }
        if kind == "portdecl" then
          item.direction = M.port_direction(node, src)
        end
        if kind == "driver" then
          item.sources = M.sources(node, src, name)
          out.drivers[#out.drivers + 1] = item
        elseif kind == "decl" or kind == "portdecl" then
          out.decls[#out.decls + 1] = item
        elseif kind == "port" then
          item.instance = M.instance(node, src)
          item.targets = M.targets(node, src)
          out.loads[#out.loads + 1] = item
        else
          item.targets = M.targets(node, src)
          out.loads[#out.loads + 1] = item
        end
      end
    end
  end
  return out
end

return M

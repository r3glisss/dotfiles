-- Port directions of an instantiated module.
--
-- This is what tells whether `.dout(sig)` writes `sig` (the submodule drives
-- it) or reads it. Only the files actually encountered get parsed, and the
-- result is cached for as long as the file does not change.

local M = {}
local index = require("sigcone.index")

local cache = {}

--- Ports of a module: `name -> "input"|"output"|"inout"`, plus the ordering
--- needed for positional connections.
local function parse_ports(file)
  local stat = vim.uv.fs_stat(file)
  if not stat then
    return nil
  end
  local key = file .. ":" .. tostring(stat.mtime.sec)
  if cache[key] then
    return cache[key]
  end
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return nil
  end
  local src = table.concat(lines, "\n")
  local ok2, parser = pcall(vim.treesitter.get_string_parser, src, "verilog")
  if not ok2 then
    return nil
  end
  local root = parser:parse()[1]:root()
  local ports, order = {}, {}
  local last_dir
  local function visit(node)
    local t = node:type()
    if t == "ansi_port_declaration" then
      local dir, name
      local function dig(n)
        for c in n:iter_children() do
          local ct = c:type()
          if ct == "port_direction" then
            dir = vim.treesitter.get_node_text(c, src)
          elseif ct == "simple_identifier" and not name then
            name = vim.treesitter.get_node_text(c, src)
          elseif c:named() and ct ~= "data_type" and ct ~= "packed_dimension" then
            dig(c)
          end
        end
      end
      dig(node)
      -- In ANSI style a missing direction repeats the previous port's.
      dir = dir or last_dir or "input"
      last_dir = dir
      if name then
        ports[name] = dir
        order[#order + 1] = name
      end
      return
    elseif t == "input_declaration" or t == "output_declaration" or t == "inout_declaration" then
      local dir = t:match("^(%a+)_")
      local function dig(n)
        for c in n:iter_children() do
          if c:type() == "simple_identifier" then
            ports[vim.treesitter.get_node_text(c, src)] = dir
            order[#order + 1] = vim.treesitter.get_node_text(c, src)
          elseif c:named() then
            dig(c)
          end
        end
      end
      dig(node)
      return
    elseif t == "module_body" or t == "module_item" or t == "description" then
      -- continue
    end
    for c in node:iter_children() do
      if c:named() then
        visit(c)
      end
    end
  end
  visit(root)
  local res = { ports = ports, order = order }
  cache[key] = res
  return res
end

--- Direction of port `port` on module `modname`, as seen from `from_file`.
--- @return string|nil direction, string|nil module file
function M.direction(modname, port, from_file)
  if not modname or not port then
    return nil
  end
  local entry = index.modules(index.root(from_file))[modname]
  if not entry then
    return nil
  end
  local p = parse_ports(entry.file)
  if not p then
    return nil, entry.file
  end
  return p.ports[port], entry.file
end

--- Reclassifies the port connections of a scan result: an `output` port means
--- the submodule writes our signal, so it is a driver.
function M.apply(result, from_file)
  local keep = {}
  for _, item in ipairs(result.loads) do
    if item.kind == "port" and item.instance then
      local port = item.targets and item.targets[1]
      local dir, file = M.direction(item.instance.module, port, from_file)
      item.direction = dir
      item.modfile = file
      if dir == "output" or dir == "inout" then
        result.drivers[#result.drivers + 1] = item
      else
        keep[#keep + 1] = item
      end
    else
      keep[#keep + 1] = item
    end
  end
  result.loads = keep
  table.sort(result.drivers, function(a, b)
    return a.lnum < b.lnum
  end)
  return result
end

function M.invalidate()
  cache = {}
  index.invalidate()
end

return M

-- sigcone: where a signal comes from, where it goes.
--
-- Depth 1, deliberately. We show the direct writes and reads of the signal
-- under the cursor, and move one step at a time with <CR>. That manual walk
-- replaces a recursive tree: at every step you know whether you just crossed a
-- register, which a deep tree would hide.

local M = {}

local scan = require("sigcone.scan")
local resolve = require("sigcone.resolve")
local ui = require("sigcone.ui")

M.stack = {}
M.origin_win = nil
M.current = nil

local FT = { verilog = true, systemverilog = true }

--- Contents of a file, preferring a loaded buffer when one exists so unsaved
--- changes are taken into account.
local function get_lines(file)
  local bufnr = vim.fn.bufnr(file)
  if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end
  local ok, lines = pcall(vim.fn.readfile, file)
  return ok and lines or nil
end

--- Analyses `signal` in `file`, anchoring on `lnum` when possible.
local function analyze(file, signal, lnum)
  local lines = get_lines(file)
  if not lines then
    return nil, "cannot read file: " .. file
  end
  local src = table.concat(lines, "\n")
  local ok, parser = pcall(vim.treesitter.get_string_parser, src, "verilog")
  if not ok then
    return nil, "verilog parser unavailable"
  end
  local root = parser:parse()[1]:root()
  local query = vim.treesitter.query.parse("verilog", "((simple_identifier) @id)")

  local anchor, fallback
  for _, node in query:iter_captures(root, src) do
    if vim.treesitter.get_node_text(node, src) == signal then
      fallback = fallback or node
      if lnum and (node:range() + 1) == lnum then
        anchor = node
        break
      end
    end
  end
  anchor = anchor or fallback
  if not anchor then
    return nil, string.format("'%s' not found in %s", signal, vim.fs.basename(file))
  end

  local result, err = scan.scan(src, anchor, signal)
  if not result then
    return nil, err
  end
  pcall(resolve.apply, result, file)
  return result, nil, lines
end

local function setup_panel_keymaps()
  if not (ui.buf and vim.api.nvim_buf_is_valid(ui.buf)) then
    return
  end
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = ui.buf, silent = true, desc = desc })
  end
  map("<CR>", M.reroot, "Re-root on this signal")
  map("o", M.jump, "Jump to this line")
  map("<C-]>", M.jump, "Jump to this line")
  map("<BS>", M.back, "Back to the previous signal")
  map("R", M.refresh, "Refresh")
  map("q", M.close, "Close")
  map("<Esc>", M.close, "Close")
end

--- Roots the panel on a signal.
function M.root_at(file, signal, lnum)
  local result, err, lines = analyze(file, signal, lnum)
  if not result then
    vim.notify("sigcone: " .. err, vim.log.levels.WARN)
    return false
  end
  M.current = { file = file, signal = signal, lnum = lnum }
  ui.show(result, { file = file, lines = lines })
  setup_panel_keymaps()
  return true
end

--- Opens the panel on the signal under the cursor.
function M.open()
  if not FT[vim.bo.filetype] then
    vim.notify("sigcone: verilog / systemverilog only", vim.log.levels.WARN)
    return
  end
  local name, badkind = scan.signal_at_cursor(0)
  if not name then
    local why = badkind and ("that is a " .. badkind .. " name") or "no identifier under the cursor"
    vim.notify("sigcone : " .. why, vim.log.levels.WARN)
    return
  end
  M.origin_win = vim.api.nvim_get_current_win()
  M.stack = {}
  M.root_at(vim.api.nvim_buf_get_name(0), name, vim.api.nvim_win_get_cursor(0)[1])
end

--- Takes the panel's current line as the new root.
function M.reroot()
  local meta = ui.current()
  local root = meta and meta.root
  if not root then
    vim.notify("sigcone: nothing to follow on this line", vim.log.levels.INFO)
    return
  end
  local function go(signal)
    table.insert(M.stack, M.current)
    M.root_at(root.file, signal, nil)
  end
  if root.signal then
    go(root.signal)
  elseif root.candidates and #root.candidates == 1 then
    go(root.candidates[1])
  elseif root.candidates then
    -- Several sources in the assignment: let the user pick.
    vim.ui.select(root.candidates, { prompt = "Trace back to:" }, function(choice)
      if choice then
        go(choice)
      end
    end)
  end
end

--- Goes back to the previous signal.
function M.back()
  local prev = table.remove(M.stack)
  if not prev then
    vim.notify("sigcone: bottom of the stack", vim.log.levels.INFO)
    return
  end
  M.root_at(prev.file, prev.signal, prev.lnum)
end

--- Opens the pointed-at line in the originating window.
function M.jump()
  local meta = ui.current()
  if not (meta and meta.jump) then
    return
  end
  local win = M.origin_win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    win = vim.fn.win_getid(vim.fn.winnr("#"))
  end
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
  vim.cmd.edit(vim.fn.fnameescape(meta.jump.file))
  vim.api.nvim_win_set_cursor(0, { meta.jump.lnum, 0 })
  vim.cmd("normal! zz")
end

function M.refresh()
  resolve.invalidate()
  if M.current then
    M.root_at(M.current.file, M.current.signal, M.current.lnum)
  end
end

function M.close()
  ui.close()
end

function M.toggle()
  if ui.is_open() then
    M.close()
  else
    M.open()
  end
end

--- Sends the result to the quickfix list: handy when the fanout is huge.
function M.quickfix()
  if not FT[vim.bo.filetype] then
    return
  end
  local name = scan.signal_at_cursor(0)
  if not name then
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  local result, err, lines = analyze(file, name, vim.api.nvim_win_get_cursor(0)[1])
  if not result then
    vim.notify("sigcone: " .. err, vim.log.levels.WARN)
    return
  end
  local items = {}
  local function add(list, tag)
    for _, i in ipairs(list) do
      items[#items + 1] = {
        filename = file,
        lnum = i.lnum,
        col = i.col + 1,
        text = string.format("[%s/%s] %s", tag, i.kind, vim.trim(lines[i.lnum] or "")),
      }
    end
  end
  add(result.decls, "decl")
  add(result.drivers, "driver")
  add(result.loads, "fanout")
  vim.fn.setqflist({}, " ", { title = "sigcone : " .. name, items = items })
  vim.cmd("copen")
end

function M.setup()
  vim.api.nvim_create_user_command("SigCone", M.toggle, { desc = "Signal drivers / fanout" })
  vim.api.nvim_create_user_command("SigConeQf", M.quickfix, { desc = "Signal drivers / fanout in quickfix" })
  vim.api.nvim_create_user_command("SigConeRefresh", M.refresh, { desc = "Clear sigcone caches" })
end

return M

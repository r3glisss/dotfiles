-- Traversal: open, re-root (including across modules), go back.
local args = _G.arg or {}
vim.cmd.edit(vim.fn.fnameescape(args[1]))
vim.bo.filetype = "systemverilog"
vim.treesitter.start(0, "verilog")
vim.api.nvim_win_set_cursor(0, { tonumber(args[2]), tonumber(args[3]) })

local sc, ui = require("sigcone"), require("sigcone.ui")
sc.setup()
sc.open()

local function head()
  return (vim.api.nvim_buf_get_lines(ui.buf, 0, 1, false)[1] or ""):gsub("^%s+", "")
end

--- Moves the panel cursor to the first re-rootable line matching `pattern`.
local function seek(pattern)
  local lines = vim.api.nvim_buf_get_lines(ui.buf, 0, -1, false)
  for i, l in ipairs(lines) do
    if l:match(pattern) and type(ui.meta[i]) == "table" and ui.meta[i].root then
      vim.api.nvim_win_set_cursor(ui.win, { i, 0 })
      return true, l
    end
  end
  return false
end

print("1. root         : " .. head())
local ok, line = seek("⊙")
assert(ok, "no re-rootable port line")
print("   target line  : " .. vim.trim(line))
sc.reroot()
print("2. cross-module : " .. head())
assert(head():match("^data_i"), "cross-module re-rooting failed")

seek("←")
sc.reroot()
print("3. fan-in       : " .. head())

sc.back()
print("4. back         : " .. head())
sc.back()
print("5. back         : " .. head())
assert(head():match("^icache_data_q"), "going back did not restore the root")
print("\nfinal stack: " .. #sc.stack .. " entry/entries")

-- Whole chain: open a file, put the cursor on a signal, render the panel.
-- Usage: ... -l tests/sigcone_e2e.lua <file> <line> <column>
local args = _G.arg or {}
local file, lnum, col = args[1], tonumber(args[2]), tonumber(args[3])

vim.cmd.edit(vim.fn.fnameescape(file))
vim.bo.filetype = "systemverilog"
vim.treesitter.start(0, "verilog")
vim.api.nvim_win_set_cursor(0, { lnum, col })

local sc = require("sigcone")
sc.setup()

local t0 = vim.uv.hrtime()
sc.open()
local ms = (vim.uv.hrtime() - t0) / 1e6

local ui = require("sigcone.ui")
if not ui.is_open() then
  print("FAILED: panel did not open")
  os.exit(1)
end
local lines = vim.api.nvim_buf_get_lines(ui.buf, 0, -1, false)
local cfg = vim.api.nvim_win_get_config(ui.win)
print(string.format("opened in %.0f ms - window %dx%d anchor %s - %d lines",
  ms, cfg.width, cfg.height, cfg.anchor, #lines))
print(("-"):rep(cfg.width))
for i, l in ipairs(lines) do
  if i <= 24 then print(l) end
end
if #lines > 24 then print(("  ... %d more lines"):format(#lines - 24)) end
print(("-"):rep(cfg.width))

-- Interaction check: a fanout line must carry a re-rooting target.
local roots, jumps = 0, 0
for i = 1, #lines do
  local m = ui.meta[i]
  if type(m) == "table" then
    if m.root then roots = roots + 1 end
    if m.jump then jumps = jumps + 1 end
  end
end
print(string.format("interaction: %d re-rootable lines, %d navigable lines", roots, jumps))

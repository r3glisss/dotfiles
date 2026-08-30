-- The panel: a floating window anchored to the bottom right.
--
-- Every rendered line is backed by an entry in `meta`, carrying what is needed
-- to jump to the code (`jump`) and to re-root the panel (`root`). That table
-- is what drives the whole interaction.

local M = {}

M.win = nil
M.buf = nil
M.meta = {}

local SYM = {
  driver = "●",
  load = "·",
  control = "◆",
  clock = "○",
  port = "⊙",
  decl = "▸",
  portdecl = "▸",
}

local HL = {
  SigconeTitle = "Title",
  SigconeSection = "Statement",
  SigconeDriver = "DiagnosticOk",
  SigconeControl = "DiagnosticWarn",
  SigconePort = "Special",
  SigconeClock = "NonText",
  SigconeLnum = "LineNr",
  SigconeTarget = "Identifier",
  SigconeCode = "Comment",
  SigconeWarn = "WarningMsg",
  SigconeDim = "NonText",
}

local ns = vim.api.nvim_create_namespace("sigcone")

local function ensure_hl()
  for group, link in pairs(HL) do
    if vim.fn.hlexists(group) == 0 or true then
      vim.api.nvim_set_hl(0, group, { link = link, default = true })
    end
  end
end

--- One rendered line: symbol, source line, text, target.
local function render_item(item, lines, width)
  local sym = SYM[item.kind] or "·"
  local hl = "SigconeLoad"
  if item.kind == "driver" then
    hl = "SigconeDriver"
  elseif item.kind == "control" then
    hl = "SigconeControl"
  elseif item.kind == "port" then
    hl = "SigconePort"
  elseif item.kind == "clock" then
    hl = "SigconeClock"
  end

  local head = string.format("%s L%-5d ", sym, item.lnum)
  local tail = ""
  if item.direction == "output" then
    tail = tail .. " ← out"
  elseif item.direction == "input" then
    tail = tail .. " → in"
  elseif item.direction == "inout" then
    tail = tail .. " ↔ inout"
  end
  if item.sources and #item.sources > 0 then
    local t = table.concat(vim.list_slice(item.sources, 1, 2), ", ")
    if #item.sources > 2 then
      t = t .. " …+" .. (#item.sources - 2)
    end
    tail = " ← " .. t .. tail
  elseif item.targets and #item.targets > 0 and item.kind ~= "port" then
    local t = table.concat(vim.list_slice(item.targets, 1, 2), ", ")
    if #item.targets > 2 then
      t = t .. " …+" .. (#item.targets - 2)
    end
    tail = " → " .. t .. tail
  elseif item.kind == "port" and item.instance then
    tail = string.format(" ⊙ %s.%s%s", item.instance.instance or "?",
      item.targets and item.targets[1] or "?", tail)
  end

  local budget = width - #head - vim.fn.strdisplaywidth(tail) - 2
  local code = vim.trim((lines[item.lnum] or ""):gsub("%s+", " "))
  if budget > 8 and #code > budget then
    code = code:sub(1, budget - 1) .. "…"
  elseif budget <= 8 then
    code = ""
  end

  return head .. code .. tail, hl, #head
end

--- Renders a scan result. `ctx` carries the file and the lines to display.
function M.show(result, ctx)
  ensure_hl()
  local width = math.min(88, vim.o.columns - 6)
  local out, meta = {}, {}

  local function put(text, hl, meta_entry, hl_col)
    out[#out + 1] = text
    meta[#out] = meta_entry
    if hl then
      meta["hl" .. #out] = { hl, hl_col or 0 }
    end
  end

  put(string.format(" %s  ·  module %s", result.signal, result.module or "?"), "SigconeTitle")
  if result.errors and result.errors > 0 then
    put(string.format(" ⚠ %d region(s) treesitter could not parse", result.errors), "SigconeWarn")
  end

  for _, d in ipairs(result.decls) do
    local text, hl, col = render_item(d, ctx.lines, width)
    put(" " .. text, hl, {
      jump = { file = ctx.file, lnum = d.lnum },
    }, col)
  end

  put("", nil)
  put(string.format(" DRIVERS (%d)", #result.drivers), "SigconeSection")
  if #result.drivers == 0 then
    put("   none — signal is not driven in this module", "SigconeDim")
  end
  for _, d in ipairs(result.drivers) do
    local text, hl, col = render_item(d, ctx.lines, width)
    local root
    if d.modfile then
      root = { file = d.modfile, signal = d.targets and d.targets[1] }
    elseif d.sources and #d.sources > 0 then
      root = { file = ctx.file, candidates = d.sources }
    end
    put(" " .. text, hl, { jump = { file = ctx.file, lnum = d.lnum }, root = root }, col)
  end

  put("", nil)
  put(string.format(" FANOUT (%d)", #result.loads), "SigconeSection")
  if #result.loads == 0 then
    put("   none — signal is not read in this module", "SigconeDim")
  end
  for _, l in ipairs(result.loads) do
    local text, hl, col = render_item(l, ctx.lines, width)
    local root
    if l.kind == "port" and l.modfile then
      root = { file = l.modfile, signal = l.targets and l.targets[1] }
    elseif l.targets and l.targets[1] then
      root = { file = ctx.file, signal = l.targets[1] }
    end
    put(" " .. text, hl, { jump = { file = ctx.file, lnum = l.lnum }, root = root }, col)
  end

  -- Buffer
  if not (M.buf and vim.api.nvim_buf_is_valid(M.buf)) then
    M.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.buf].bufhidden = "hide"
    vim.bo[M.buf].filetype = "sigcone"
  end
  vim.bo[M.buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, out)
  vim.bo[M.buf].modifiable = false
  M.meta = meta

  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
  for i = 1, #out do
    local h = meta["hl" .. i]
    if h then
      vim.api.nvim_buf_set_extmark(M.buf, ns, i - 1, 0, {
        end_row = i - 1,
        end_col = math.min(#out[i], h[2] + 1),
        hl_group = h[1],
      })
      if h[2] > 0 then
        vim.api.nvim_buf_set_extmark(M.buf, ns, i - 1, math.min(#out[i], h[2] + 1), {
          end_row = i - 1,
          end_col = #out[i],
          hl_group = "SigconeCode",
        })
      end
    end
  end

  -- Floating window, anchored to the bottom right.
  local height = math.min(#out, math.max(10, math.floor(vim.o.lines * 0.45)))
  local cfg = {
    relative = "editor",
    anchor = "SE",
    row = vim.o.lines - 2,
    col = vim.o.columns - 2,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " ⟳ sigcone ",
    title_pos = "right",
  }
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_set_config(M.win, cfg)
  else
    M.win = vim.api.nvim_open_win(M.buf, false, cfg)
    vim.wo[M.win].wrap = false
    vim.wo[M.win].cursorline = true
  end
  return M.win
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win = nil
end

function M.is_open()
  return M.win and vim.api.nvim_win_is_valid(M.win)
end

function M.focus()
  if M.is_open() then
    vim.api.nvim_set_current_win(M.win)
  end
end

--- Metadata for the panel's current line.
function M.current()
  if not M.is_open() then
    return nil
  end
  local lnum = vim.api.nvim_win_get_cursor(M.win)[1]
  return M.meta[lnum]
end

return M

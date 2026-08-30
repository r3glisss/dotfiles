-- Sanity check against real RTL: scan a known signal and read the result by
-- eye. Usage: ... -l tests/sigcone_real.lua <file> <signal> [line]
local scan = require("sigcone.scan")
local args = _G.arg or {}
local file = args[1]
local signal = args[2]
local anchor = tonumber(args[3])

local lines = vim.fn.readfile(file)
local src = table.concat(lines, "\n")
local t0 = vim.uv.hrtime()
local root = vim.treesitter.get_string_parser(src, "verilog"):parse()[1]:root()
local t_parse = (vim.uv.hrtime() - t0) / 1e6

-- Anchor: the first occurrence of the signal, or the requested line.
local q = vim.treesitter.query.parse("verilog", "((simple_identifier) @id)")
local from
for _, node in q:iter_captures(root, src) do
  if vim.treesitter.get_node_text(node, src) == signal then
    local l = node:range() + 1
    if not anchor or l == anchor then
      from = node
      break
    end
  end
end
assert(from, "signal not found: " .. signal)

local t1 = vim.uv.hrtime()
local r, err = scan.scan(src, from, signal)
local t_scan = (vim.uv.hrtime() - t1) / 1e6
assert(r, err)

local function show(item)
  local txt = vim.trim(lines[item.lnum] or ""):sub(1, 62)
  local tgt = ""
  if item.targets and #item.targets > 0 then
    tgt = " -> " .. table.concat(vim.list_slice(item.targets, 1, 3), ", ")
    if #item.targets > 3 then tgt = tgt .. " +" .. (#item.targets - 3) end
  end
  if item.instance then
    tgt = string.format(" @ %s.%s", item.instance.instance or "?", tgt:gsub("^ %-> ", ""))
  end
  return string.format("  %-8s %-11s L%-5d %s%s", item.kind, item.construct, item.lnum, txt, tgt)
end

print(string.format("module %s   signal %s", r.module, r.signal))
print(string.format("parse %.0f ms - scan %.0f ms - %d ERROR regions in the module",
  t_parse, t_scan, r.errors))
print(string.format("\nDECLARATIONS (%d)", #r.decls))
for _, i in ipairs(r.decls) do print(show(i)) end
print(string.format("\nDRIVERS (%d)", #r.drivers))
for _, i in ipairs(r.drivers) do print(show(i)) end
print(string.format("\nFANOUT (%d)", #r.loads))
local by = {}
for _, i in ipairs(r.loads) do by[i.kind] = (by[i.kind] or 0) + 1 end
print("  " .. vim.inspect(by):gsub("%s+", " "))
for n, i in ipairs(r.loads) do
  if n <= 12 then print(show(i)) end
end

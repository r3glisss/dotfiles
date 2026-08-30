-- Broad sweep: many files, many signals, looking for crashes and for scans
-- that come back empty.
local scan = require("sigcone.scan")
local resolve = require("sigcone.resolve")
local root_dir = (_G.arg or {})[1]

local files = vim.fn.systemlist({ "find", root_dir, "-name", "*.sv" })
local nfile, nsig, nerr, nempty, nports = 0, 0, 0, 0, 0
local errors = {}
local t0 = vim.uv.hrtime()

for _, file in ipairs(files) do
  if nfile >= 150 then break end
  local ok, lines = pcall(vim.fn.readfile, file)
  if ok and #lines > 20 then
    nfile = nfile + 1
    local src = table.concat(lines, "\n")
    local pok, parser = pcall(vim.treesitter.get_string_parser, src, "verilog")
    if pok then
      local tree = parser:parse()[1]
      local query = vim.treesitter.query.parse("verilog", "((simple_identifier) @id)")
      -- A sample of distinct signals from the file.
      local seen, sample = {}, {}
      for _, node in query:iter_captures(tree:root(), src) do
        local nm = vim.treesitter.get_node_text(node, src)
        if not seen[nm] and scan.classify(node) == "driver" then
          seen[nm] = true
          sample[#sample + 1] = { nm, node }
          if #sample >= 8 then break end
        end
      end
      for _, pair in ipairs(sample) do
        nsig = nsig + 1
        local sok, res = pcall(scan.scan, src, pair[2], pair[1])
        if not sok then
          nerr = nerr + 1
          errors[#errors + 1] = string.format("%s / %s : %s", vim.fs.basename(file), pair[1], res)
        elseif res then
          local rok, rerr = pcall(resolve.apply, res, file)
          if not rok then
            nerr = nerr + 1
            errors[#errors + 1] = string.format("%s / %s (resolve) : %s",
              vim.fs.basename(file), pair[1], rerr)
          end
          if #res.drivers == 0 and #res.loads == 0 then
            nempty = nempty + 1
          end
          for _, d in ipairs(res.drivers) do
            if d.direction then nports = nports + 1 end
          end
        end
      end
    end
  end
end

print(string.format("%d files - %d signals - %.1f s", nfile, nsig, (vim.uv.hrtime() - t0) / 1e9))
print(string.format("crashes          : %d", nerr))
print(string.format("empty results    : %d", nempty))
print(string.format("ports resolved as drivers : %d", nports))
for i, e in ipairs(errors) do
  if i <= 8 then print("  " .. e) end
end
os.exit(nerr == 0 and 0 or 1)

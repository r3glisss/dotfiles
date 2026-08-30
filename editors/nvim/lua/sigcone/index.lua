-- Locating modules across the project.
--
-- No full index is built: a single ripgrep pass yields the `module -> file`
-- map, and only the files actually encountered are parsed afterwards. On CVA6
-- that pass costs about a hundred milliseconds.

local M = {}

local cache = {}

--- Root of the project containing `file`.
function M.root(file)
  local dir = vim.fs.dirname(vim.fn.fnamemodify(file, ":p"))
  local marker = vim.fs.find({ "verible.filelist", ".git" }, { path = dir, upward = true })[1]
  return marker and vim.fs.dirname(marker) or dir
end

--- Map `module name -> path`, built on demand and cached.
function M.modules(root)
  if cache[root] then
    return cache[root]
  end
  local out = vim.system({
    "rg", "--no-heading", "--with-filename", "--line-number", "--only-matching",
    "--replace", "$1", "--glob", "*.sv", "--glob", "*.svh", "--glob", "*.v", "--glob", "*.vh",
    [[^\s*(?:macro)?module\s+([A-Za-z_]\w*)]], ".",
  }, { cwd = root, text = true }):wait()
  local map = {}
  for _, line in ipairs(vim.split(out.stdout or "", "\n", { trimempty = true })) do
    local path, lnum, name = line:match("^(.-):(%d+):(.+)$")
    if name and not map[name] then
      map[name] = { file = root .. "/" .. path:gsub("^%./", ""), lnum = tonumber(lnum) }
    end
  end
  cache[root] = map
  return map
end

function M.invalidate()
  cache = {}
end

return M

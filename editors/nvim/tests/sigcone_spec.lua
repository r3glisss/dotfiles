-- Classification tests. Run with:
--   nvim --headless -u tests/minimal.lua -l tests/sigcone_spec.lua
local scan = require("sigcone.scan")

local SRC = [[
module m #(parameter W = 8) (
  input  logic         clk,
  input  logic [W-1:0] a,
  output logic [W-1:0] q
);
  logic [W-1:0] sum;
  logic         valid, stall;
  logic [3:0]   idx;

  assign sum = a + 1;

  always_ff @(posedge clk) begin
    if (valid && !stall) q[idx] <= sum;
    else                 q      <= '0;
  end

  always_comb begin
    valid = |a;
    case (sum)
      4'd0: valid = 1'b0;
    endcase
    stall = valid ? a[0] : 1'b1;
  end

  sub u_sub (.clk(clk), .din(sum), .valid(valid), .dout(idx));

  always_comb begin
    pkt.hdr.len = a;
  end
endmodule
]]

-- { line, name, expected kind, rationale }
local CASES = {
  { 2,  "clk",   "portdecl",     "module port declaration" },
  { 4,  "q",     "portdecl",     "module port declaration" },
  { 3,  "W",     "load",         "parameter read in a port dimension" },
  { 6,  "sum",   "decl",         "internal declaration" },
  { 6,  "W",     "load",         "parameter read in a dimension" },
  { 7,  "valid", "decl",         "declaration, multiple names" },
  { 10, "sum",   "driver",       "lvalue of a continuous assign" },
  { 10, "a",     "load",         "right-hand side of an assign" },
  { 12, "clk",   "clock",        "sensitivity list" },
  { 13, "valid", "control",      "if condition" },
  { 13, "stall", "control",      "if condition" },
  { 13, "q",     "driver",       "nonblocking lvalue, despite the index" },
  { 13, "idx",   "load",         "index under a select: a read" },
  { 13, "sum",   "load",         "right-hand side" },
  { 14, "q",     "driver",       "bare nonblocking lvalue" },
  { 18, "valid", "driver",       "blocking lvalue" },
  { 19, "sum",   "control",      "case expression" },
  { 20, "valid", "driver",       "lvalue inside a case item" },
  { 22, "stall", "driver",       "blocking lvalue" },
  { 22, "valid", "control",      "ternary condition" },
  { 22, "a",     "load",         "ternary branch" },
  { 25, "clk",   "portname",     "port name, not the signal" },
  { 25, "sum",   "port",         "signal wired to a port" },
  { 25, "idx",   "port",         "signal wired to a port" },
  { 1,  "m",     "modulename",   "module name, not a signal" },
  { 25, "sub",   "moduletype",   "instantiated type, not a signal" },
  { 25, "u_sub", "instancename", "instance name, not a signal" },
  { 28, "pkt",   "driver",       "base of a field access" },
  { 28, "hdr",   "field",        "struct field, not a signal" },
  { 28, "len",   "field",        "struct field, not a signal" },
}

local parser = vim.treesitter.get_string_parser(SRC, "verilog")
local root = parser:parse()[1]:root()
local query = vim.treesitter.query.parse("verilog", "((simple_identifier) @id)")

-- (line, name) -> list of kinds found
local found = {}
for _, node in query:iter_captures(root, SRC) do
  local lnum = node:range() + 1
  local name = vim.treesitter.get_node_text(node, SRC)
  local key = lnum .. ":" .. name
  found[key] = found[key] or {}
  table.insert(found[key], scan.classify(node))
end

local pass, fail = 0, 0
for _, c in ipairs(CASES) do
  local lnum, name, want, why = c[1], c[2], c[3], c[4]
  local got = found[lnum .. ":" .. name]
  if got and vim.list_contains(got, want) then
    pass = pass + 1
  else
    fail = fail + 1
    print(string.format("FAIL  L%-3d %-7s want %-9s got %-9s  (%s)",
      lnum, name, want, got and table.concat(got, ",") or "NOTHING", why))
  end
end

print(string.format("\n%d/%d", pass, pass + fail))
if fail > 0 then
  print("\n--- every occurrence ---")
  local keys = vim.tbl_keys(found)
  table.sort(keys, function(x, y)
    return tonumber(x:match("^%d+")) < tonumber(y:match("^%d+"))
  end)
  for _, k in ipairs(keys) do
    print(string.format("  L%-4s %-8s %s", k:match("^(%d+)"), k:match(":(.+)$"),
      table.concat(found[k], ",")))
  end
end
os.exit(fail == 0 and 0 or 1)

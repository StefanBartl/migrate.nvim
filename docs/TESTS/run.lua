-- docs/TESTS/run.lua — headless test runner for migrate.nvim.
--
-- Run from the repo root:
--   nvim --headless -u NONE -c "set rtp+=." -c "luafile docs/TESTS/run.lua" -c "qa!"
-- or:
--   nvim --headless -u NONE -c "set rtp+=." -l docs/TESTS/run.lua
--
-- Loads every *_spec.lua in this directory, runs it against the shared
-- harness, prints a per-spec result and exits non-zero on the first failing
-- spec (so it is CI-friendly).
--
-- Only covers the pure, dependency-free logic (opt.migrator, notify.parser.*):
-- migrate.opt/migrate.notify/migrate.common.* hard-require lib.nvim and
-- telescope.nvim and are out of scope for this headless suite.

local dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local H = dofile(dir .. "harness.lua")

local specs = {
  "opt_migrator_spec.lua",
  "notify_parser_spec.lua",
}

local failed = 0
for _, name in ipairs(specs) do
  local run = dofile(dir .. name)
  local ok, err = pcall(run, H)
  if ok then
    print(("ok    %s"):format(name))
  else
    failed = failed + 1
    print(("FAIL  %s\n      %s"):format(name, tostring(err)))
  end
end

if failed > 0 then
  print(("\n%d spec(s) failed"):format(failed))
  os.exit(1)
end

print("\nMIGRATE_TESTS_OK")

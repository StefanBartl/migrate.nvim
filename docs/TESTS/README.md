# Tests

Headless spec suite for migrate.nvim. Covers the pure, dependency-free logic:
the `opt` line-migration regex and the `notify` parser/migrator functions.
`migrate.opt`, `migrate.notify`, and `migrate.common.*` hard-require
`lib.nvim` and `telescope.nvim` and are therefore out of scope for this
headless suite (no picker/command/end-to-end coverage here).

## Run

From the repo root:

```sh
nvim --headless -u NONE -c "set rtp+=." -c "luafile docs/TESTS/run.lua" -c "qa!"
```

The runner prints one line per spec and exits non-zero on the first failure
(`MIGRATE_TESTS_OK` on success).

## Layout

| File | Covers |
| --- | --- |
| `harness.lua` | Shared assertions (`eq`, `ok`) and a `scratch(ft)` buffer helper. |
| `opt_migrator_spec.lua` | `migrate.opt.migrator.migrate_line` — buf/win, get/set, all prefix variants. |
| `notify_parser_spec.lua` | `migrate.notify.parser.{patterns,migrator}` + end-to-end `parser.scan_buffer`. |
| `run.lua` | Runner: loads every `*_spec.lua`, reports results, sets exit code. |

## Adding a spec

Create `<name>_spec.lua` returning `function(H) … end` (use `H.eq` / `H.ok` /
`H.scratch`) and add its filename to the `specs` list in `run.lua`. Keep
specs limited to modules that don't hard-require `lib.nvim`/`telescope.nvim`
— those need those plugins on the runtimepath to even `require()` without
erroring.

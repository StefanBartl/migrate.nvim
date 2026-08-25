# migrate.nvim - Usage Examples

Practical examples for every migration scenario.

## Table of content

- [migrate.nvim - Usage Examples](#migratenvim---usage-examples)
  - [Setup](#setup)
    - [Minimal Setup](#minimal-setup)
    - [Selective Setup](#selective-setup)
    - [Manual Setup](#manual-setup)
  - [notify Migration - Scenarios](#notify-migration-scenarios)
    - [Scenario 1: simple vim.notify calls](#scenario-1-simple-vimnotify-calls)
    - [Scenario 2: aliased calls](#scenario-2-aliased-calls)
    - [Scenario 3: mixed usage](#scenario-3-mixed-usage)
    - [Scenario 4: multiline calls](#scenario-4-multiline-calls)
    - [Scenario 5: the whole project (CWD)](#scenario-5-the-whole-project-cwd)
    - [Scenario 6: without a module name](#scenario-6-without-a-module-name)
  - [opt Migration - Scenarios](#opt-migration-scenarios)
    - [Scenario 1: Buffer Options](#scenario-1-buffer-options)
    - [Scenario 2: window options with an alias](#scenario-2-window-options-with-an-alias)
  - [Workflow examples](#workflow-examples)
    - [Workflow 1: Plugin-Migration](#workflow-1-plugin-migration)
- [1. Backup](#1-backup)
- [2. Test with one file](#2-test-with-one-file)
- [Check the result](#check-the-result)
- [3. The whole project](#3-the-whole-project)
- [<S-A> in Telescope for batch apply](#s-a-in-telescope-for-batch-apply)
- [4. Verification](#4-verification)
- [Should be empty](#should-be-empty)
- [5. Tests](#5-tests)
- [6. Commit](#6-commit)
    - [Workflow 2: step by step migration](#workflow-2-step-by-step-migration)
    - [Workflow 3: review before apply](#workflow-3-review-before-apply)
  - [Edge Cases](#edge-cases)
    - [Edge Case 1: already partly migrated](#edge-case-1-already-partly-migrated)
    - [Edge Case 2: Notify in Strings](#edge-case-2-notify-in-strings)
    - [Edge Case 3: Nested Modules](#edge-case-3-nested-modules)
  - [Performance Tips](#performance-tips)
    - [Tip 1: buffer mode for large projects](#tip-1-buffer-mode-for-large-projects)
    - [Tip 2: Batch-Processing Script](#tip-2-batch-processing-script)
  - [Troubleshooting Checklist](#troubleshooting-checklist)
  - [Further examples](#further-examples)

---

## Setup

### Minimal Setup

```lua
-- lua/config/migrate.lua
require("migrate").setup()

-- enables:
-- :MigrateOpt
-- :MigrateNotify
```

### Selective Setup

```lua
require("migrate").setup({
  opt = false,     -- disables :MigrateOpt
  notify = true,   -- enables only :MigrateNotify
})
```

### Manual Setup

```lua
-- Einzeln aktivieren
require("migrate.notify").enable()
require("migrate.opt").enable()
```

## notify Migration - Scenarios

### Scenario 1: simple vim.notify calls

**Vorher:**
```lua
-- lua/myplugin/commands.lua
local M = {}

function M.run()
  vim.notify("Command executed", vim.log.levels.INFO)

  if error_occurred then
    vim.notify("Error: " .. err, vim.log.levels.ERROR)
  end
end

return M
```

**Migration:**
```vim
:e lua/myplugin/commands.lua
:MigrateNotify % myplugin.commands
```

**Nachher:**
```lua
local notify = require("lib.nvim.notify").create("[myplugin.commands]")

local M = {}

function M.run()
  notify.info("Command executed")

  if error_occurred then
    notify.error("Error: " .. err)
  end
end

return M
```

### Scenario 2: aliased calls

**Vorher:**
```lua
-- lua/myplugin/ui.lua
local notify, levels = vim.notify, vim.log.levels

local M = {}

function M.show_message(msg, level)
  if level == "error" then
    notify(msg, levels.ERROR)
  else
    notify(msg, levels.INFO)
  end
end

function M.warn(msg)
  notify(msg, levels.WARN)
end

return M
```

**Migration:**
```vim
:e lua/myplugin/ui.lua
:MigrateNotify % myplugin.ui
```

**Nachher:**
```lua
local notify = require("lib.nvim.notify").create("[myplugin.ui]")

local M = {}

function M.show_message(msg, level)
  if level == "error" then
    notify.error(msg)
  else
    notify.info(msg)
  end
end

function M.warn(msg)
  notify.warn(msg)
end

return M
```

**Note:** the alias `local notify, levels = ...` was removed automatically!

### Scenario 3: mixed usage

**Vorher:**
```lua
-- lua/myplugin/core.lua
local n = vim.notify

local M = {}

function M.init()
  n("Initializing plugin...", vim.log.levels.INFO)

  -- direct calls later in the code as well
  vim.notify("Ready!", vim.log.levels.INFO)
end

return M
```

**Migration:**
```vim
:MigrateNotify % myplugin.core
```

**Nachher:**
```lua
local notify = require("lib.nvim.notify").create("[myplugin.core]")

local M = {}

function M.init()
  notify.info("Initializing plugin...")

  notify.info("Ready!")
end

return M
```

### Scenario 4: multiline calls

**Vorher:**
```lua
-- lua/myplugin/formatter.lua
local M = {}

function M.format_result(data)
  vim.notify(
    string.format(
      "Formatted %d items in %.2fs",
      data.count,
      data.elapsed
    ),
    vim.log.levels.INFO,
    { title = "Formatter" }
  )
end

return M
```

**Migration:**
```vim
:MigrateNotify % myplugin.formatter
```

**Nachher:**
```lua
local notify = require("lib.nvim.notify").create("[myplugin.formatter]")

local M = {}

function M.format_result(data)
  notify.info(string.format( "Formatted %d items in %.2fs", data.count, data.elapsed ), { title = "Formatter" })
end

return M
```

**Note:** multiline gets consolidated into a single line.

### Scenario 5: the whole project (CWD)

**Verzeichnis-Struktur:**
```
lua/myplugin/
├── init.lua
├── config.lua
├── commands.lua
└── ui/
    ├── window.lua
    └── statusline.lua
```

**Migration:**
```vim
:cd lua/myplugin
:MigrateNotify cwd myplugin

" opens the Telescope picker with every match
" <S-A> for batch apply
```

**Resultat:**
Alle Files bekommen:
```lua
local notify = require("lib.nvim.notify").create("[myplugin]")
```

**Alternative:** individual module names

```vim
" for each file individually:
:e lua/myplugin/ui/window.lua
:MigrateNotify % myplugin.ui.window

:e lua/myplugin/commands.lua
:MigrateNotify % myplugin.commands
```

Resultat:
```lua
-- ui/window.lua
local notify = require("lib.nvim.notify").create("[myplugin.ui.window]")

-- commands.lua
local notify = require("lib.nvim.notify").create("[myplugin.commands]")
```

### Scenario 6: without a module name

**Vorher:**
```lua
-- lua/utils/logger.lua
local M = {}

function M.log(msg, level)
  vim.notify(msg, vim.log.levels[level])
end

return M
```

**Migration:**
```vim
:MigrateNotify %
```

**Nachher:**
```lua
local notify = require("lib.nvim.notify").create("")

local M = {}

function M.log(msg, level)
  notify.info(msg)  -- the level was migrated into .info()
end

return M
```

**Follow-up:** change `""` to a sensible name by hand.

## opt Migration - Scenarios

### Scenario 1: Buffer Options

**Vorher:**
```lua
local M = {}

function M.setup_buffer(bufnr)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "myft")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return ft
end

return M
```

**Migration:**
```vim
:MigrateOpt %
```

**Nachher:**
```lua
local M = {}

function M.setup_buffer(bufnr)
  vim.api.nvim_set_option_value("filetype", "myft", { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  return ft
end

return M
```

### Scenario 2: window options with an alias

**Vorher:**
```lua
local api = vim.api

local M = {}

function M.configure_window(winid)
  api.nvim_win_set_option(winid, "number", true)
  api.nvim_win_set_option(winid, "relativenumber", true)
  api.nvim_win_set_option(winid, "wrap", false)
end

return M
```

**Migration:**
```vim
:MigrateOpt %
```

**Nachher:**
```lua
local api = vim.api

local M = {}

function M.configure_window(winid)
  api.nvim_set_option_value("number", true, { win = winid })
  api.nvim_set_option_value("relativenumber", true, { win = winid })
  api.nvim_set_option_value("wrap", false, { win = winid })
end

return M
```

## Workflow examples

### Workflow 1: Plugin-Migration

```bash
# 1. Backup
git commit -am "backup before migration"

# 2. Test with one file
nvim lua/myplugin/core.lua
:MigrateNotify % myplugin.core
# check the result

# 3. The whole project
:cd lua/myplugin
:MigrateNotify cwd myplugin
# <S-A> in Telescope for batch apply

# 4. Verification
:grep "vim\.notify\|vim\.log\.levels" lua/myplugin/**/*.lua
# should be empty

# 5. Tests
:! make test

# 6. Commit
git commit -am "chore: migrate to lib.nvim.notify"
```

### Workflow 2: step by step migration

```vim
" 1. Start with one module
:e lua/myplugin/ui.lua
:MigrateNotify % myplugin.ui

" 2. Test that module
:source %
:lua require("myplugin.ui").test()

" 3. The next module
:e lua/myplugin/commands.lua
:MigrateNotify % myplugin.commands

" etc...
```

### Workflow 3: review before apply

```vim
" 1. Scan without applying
:MigrateNotify %

" 2. In Telescope Picker:
"    - <Tab> for multi-select
"    - check the preview
"    - individually with <CR>, or all with <S-A>

" 3. After apply: undo if needed
u

" 4. Again, with adjustments
:MigrateNotify % corrected.module.name
```

## Edge Cases

### Edge Case 1: already partly migrated

**File:**
```lua
local notify = require("lib.nvim.notify").create("")

local M = {}

function M.old_code()
  vim.notify("Still old", vim.log.levels.WARN)
end

function M.new_code()
  notify.info("Already migrated")
end

return M
```

**Migration:**
```vim
:MigrateNotify % mymodule
```

**Resultat:**
- the import gets updated to `.create("[mymodule]")`
- only `vim.notify` gets migrated
- `notify.info` stays unchanged

### Edge Case 2: Notify in Strings

**Problem:**
```lua
local example = [[
  local test = function()
    vim.notify("test", vim.log.levels.INFO)
  end
]]
```

**Migration:** it gets detected wrongly!

**Solution:** undo it by hand after the migration.

### Edge Case 3: Nested Modules

**Struktur:**
```
lua/telescope/extensions/myext/
├── init.lua
├── picker.lua
└── actions.lua
```

**Migration with a namespace:**
```vim
:cd lua/telescope/extensions/myext
:e picker.lua
:MigrateNotify % telescope.extensions.myext.picker

:e actions.lua
:MigrateNotify % telescope.extensions.myext.actions
```

## Performance Tips

### Tip 1: buffer mode for large projects

Instead of `cwd` for huge projects:

```vim
" Erstelle File-Liste
:args lua/**/*.lua

" migrate each file individually with different names
:argdo MigrateNotify % | update
```

### Tip 2: Batch-Processing Script

```lua
-- migrate_all.lua
local files = vim.fn.globpath("lua/myplugin", "**/*.lua", false, true)

for _, file in ipairs(files) do
  vim.cmd("edit " .. file)

  -- Extract module name from path
  local module = file:match("lua/(.+)%.lua"):gsub("/", ".")

  vim.cmd("MigrateNotify % " .. module)
  vim.cmd("write")
end
```

## Troubleshooting Checklist

Check after the migration:

- [ ] all `vim.notify` migrated
- [ ] no `vim.log.levels` remnants
- [ ] the import is correct (with/without a module name)
- [ ] old aliases removed
- [ ] no duplicate imports
- [ ] the code runs without errors
- [ ] the tests pass
- [ ] `:checkhealth` ok

## Further examples

See also:
- `doc/migrate.txt` - the complete documentation (`:h migrate`)
- `docs/Technical-DeepDive.md` - implementation details
- `docs/PatternMatchingGuide.md` - Pattern-Matching Guide

---

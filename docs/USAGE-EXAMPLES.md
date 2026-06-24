# usrcmds.migrate - Usage Examples

Praktische Beispiele für alle Migrations-Szenarien.

## Table of content

- [usrcmds.migrate - Usage Examples](#usrcmdsmigrate-usage-examples)
  - [Setup](#setup)
    - [Minimal Setup](#minimal-setup)
    - [Selective Setup](#selective-setup)
    - [Manual Setup](#manual-setup)
  - [notify Migration - Scenarios](#notify-migration-scenarios)
    - [Scenario 1: Einfache vim.notify Aufrufe](#scenario-1-einfache-vimnotify-aufrufe)
    - [Scenario 2: Aliased Aufrufe](#scenario-2-aliased-aufrufe)
    - [Scenario 3: Gemischte Verwendung](#scenario-3-gemischte-verwendung)
    - [Scenario 4: Multiline Aufrufe](#scenario-4-multiline-aufrufe)
    - [Scenario 5: Gesamtes Projekt (CWD)](#scenario-5-gesamtes-projekt-cwd)
    - [Scenario 6: Ohne Modul-Namen](#scenario-6-ohne-modul-namen)
  - [opt Migration - Scenarios](#opt-migration-scenarios)
    - [Scenario 1: Buffer Options](#scenario-1-buffer-options)
    - [Scenario 2: Window Options mit Alias](#scenario-2-window-options-mit-alias)
  - [Workflow-Beispiele](#workflow-beispiele)
    - [Workflow 1: Plugin-Migration](#workflow-1-plugin-migration)
- [1. Backup](#1-backup)
- [2. Test mit einem File](#2-test-mit-einem-file)
- [Prüfe Resultat](#prfe-resultat)
- [3. Ganzes Projekt](#3-ganzes-projekt)
- [<S-A> in Telescope für Batch-Apply](#s-a-in-telescope-fr-batch-apply)
- [4. Verifizierung](#4-verifizierung)
- [Sollte leer sein](#sollte-leer-sein)
- [5. Tests](#5-tests)
- [6. Commit](#6-commit)
    - [Workflow 2: Schrittweise Migration](#workflow-2-schrittweise-migration)
    - [Workflow 3: Review vor Apply](#workflow-3-review-vor-apply)
  - [Edge Cases](#edge-cases)
    - [Edge Case 1: Bereits teilweise migriert](#edge-case-1-bereits-teilweise-migriert)
    - [Edge Case 2: Notify in Strings](#edge-case-2-notify-in-strings)
    - [Edge Case 3: Nested Modules](#edge-case-3-nested-modules)
  - [Performance Tips](#performance-tips)
    - [Tip 1: Buffer-Mode für große Projekte](#tip-1-buffer-mode-fr-groe-projekte)
    - [Tip 2: Batch-Processing Script](#tip-2-batch-processing-script)
  - [Troubleshooting Checklist](#troubleshooting-checklist)
  - [Weitere Beispiele](#weitere-beispiele)

---

## Setup

### Minimal Setup

```lua
-- lua/config/migrate.lua
require("usrcmds.migrate").setup()

-- Aktiviert:
-- :MigrateOpt
-- :MigrateNotify
```

### Selective Setup

```lua
require("usrcmds.migrate").setup({
  opt = false,     -- Deaktiviert :MigrateOpt
  notify = true,   -- Aktiviert nur :MigrateNotify
})
```

### Manual Setup

```lua
-- Einzeln aktivieren
require("usrcmds.migrate.notify").enable()
require("usrcmds.migrate.opt").enable()
```

## notify Migration - Scenarios

### Scenario 1: Einfache vim.notify Aufrufe

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
local notify = require("lib.notify").create("[myplugin.commands]")

local M = {}

function M.run()
  notify.info("Command executed")

  if error_occurred then
    notify.error("Error: " .. err)
  end
end

return M
```

### Scenario 2: Aliased Aufrufe

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
local notify = require("lib.notify").create("[myplugin.ui]")

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

**Beachte:** Alias `local notify, levels = ...` wurde automatisch entfernt!

### Scenario 3: Gemischte Verwendung

**Vorher:**
```lua
-- lua/myplugin/core.lua
local n = vim.notify

local M = {}

function M.init()
  n("Initializing plugin...", vim.log.levels.INFO)

  -- Später im Code auch direkte Aufrufe
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
local notify = require("lib.notify").create("[myplugin.core]")

local M = {}

function M.init()
  notify.info("Initializing plugin...")

  notify.info("Ready!")
end

return M
```

### Scenario 4: Multiline Aufrufe

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
local notify = require("lib.notify").create("[myplugin.formatter]")

local M = {}

function M.format_result(data)
  notify.info(string.format( "Formatted %d items in %.2fs", data.count, data.elapsed ), { title = "Formatter" })
end

return M
```

**Hinweis:** Multiline wird zu Single-Line konsolidiert.

### Scenario 5: Gesamtes Projekt (CWD)

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

" Öffnet Telescope Picker mit allen Matches
" <S-A> für Batch-Apply
```

**Resultat:**
Alle Files bekommen:
```lua
local notify = require("lib.notify").create("[myplugin]")
```

**Alternative:** Individuelle Modul-Namen

```vim
" Für jedes File einzeln:
:e lua/myplugin/ui/window.lua
:MigrateNotify % myplugin.ui.window

:e lua/myplugin/commands.lua
:MigrateNotify % myplugin.commands
```

Resultat:
```lua
-- ui/window.lua
local notify = require("lib.notify").create("[myplugin.ui.window]")

-- commands.lua
local notify = require("lib.notify").create("[myplugin.commands]")
```

### Scenario 6: Ohne Modul-Namen

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
local notify = require("lib.notify").create("")

local M = {}

function M.log(msg, level)
  notify.info(msg)  -- Level wurde zu .info() migriert
end

return M
```

**Nachbearbeitung:** Manuell `""` zu sinnvollem Namen ändern.

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

### Scenario 2: Window Options mit Alias

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

## Workflow-Beispiele

### Workflow 1: Plugin-Migration

```bash
# 1. Backup
git commit -am "backup before migration"

# 2. Test mit einem File
nvim lua/myplugin/core.lua
:MigrateNotify % myplugin.core
# Prüfe Resultat

# 3. Ganzes Projekt
:cd lua/myplugin
:MigrateNotify cwd myplugin
# <S-A> in Telescope für Batch-Apply

# 4. Verifizierung
:grep "vim\.notify\|vim\.log\.levels" lua/myplugin/**/*.lua
# Sollte leer sein

# 5. Tests
:! make test

# 6. Commit
git commit -am "chore: migrate to lib.notify"
```

### Workflow 2: Schrittweise Migration

```vim
" 1. Starte mit einem Modul
:e lua/myplugin/ui.lua
:MigrateNotify % myplugin.ui

" 2. Teste dieses Modul
:source %
:lua require("myplugin.ui").test()

" 3. Nächstes Modul
:e lua/myplugin/commands.lua
:MigrateNotify % myplugin.commands

" etc...
```

### Workflow 3: Review vor Apply

```vim
" 1. Scan ohne Apply
:MigrateNotify %

" 2. In Telescope Picker:
"    - <Tab> für Multi-Select
"    - Preview prüfen
"    - Einzeln mit <CR> oder alle mit <S-A>

" 3. Nach Apply: Undo wenn nötig
u

" 4. Erneut mit Anpassungen
:MigrateNotify % corrected.module.name
```

## Edge Cases

### Edge Case 1: Bereits teilweise migriert

**File:**
```lua
local notify = require("lib.notify").create("")

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
- Import wird aktualisiert zu `.create("[mymodule]")`
- Nur `vim.notify` wird migriert
- `notify.info` bleibt unverändert

### Edge Case 2: Notify in Strings

**Problem:**
```lua
local example = [[
  local test = function()
    vim.notify("test", vim.log.levels.INFO)
  end
]]
```

**Migration:** Wird fälschlicherweise erkannt!

**Lösung:** Manuell rückgängig machen nach Migration.

### Edge Case 3: Nested Modules

**Struktur:**
```
lua/telescope/extensions/myext/
├── init.lua
├── picker.lua
└── actions.lua
```

**Migration mit Namespace:**
```vim
:cd lua/telescope/extensions/myext
:e picker.lua
:MigrateNotify % telescope.extensions.myext.picker

:e actions.lua
:MigrateNotify % telescope.extensions.myext.actions
```

## Performance Tips

### Tip 1: Buffer-Mode für große Projekte

Statt `cwd` für riesige Projekte:

```vim
" Erstelle File-Liste
:args lua/**/*.lua

" Migriere jedes File einzeln mit unterschiedlichen Namen
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

Nach Migration prüfen:

- [ ] Alle `vim.notify` migriert
- [ ] Keine `vim.log.levels` Reste
- [ ] Import korrekt (mit/ohne Modul-Namen)
- [ ] Alte Aliases entfernt
- [ ] Keine doppelten Imports
- [ ] Code läuft ohne Fehler
- [ ] Tests bestehen
- [ ] `:checkhealth` ok

## Weitere Beispiele

Siehe auch:
- `notify/doc/migrate-notify.txt` - Vollständige Doku
- `docs/technical.md` - Implementierungs-Details
- `docs/patterns.md` - Pattern-Matching Guide

---

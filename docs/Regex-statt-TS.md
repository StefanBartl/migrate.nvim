# Migration Fix Dokumentation

## Table of content

  - [Das Problem](#das-problem)
  - [Die Lösung](#die-lsung)
    - [1. Regex statt Treesitter](#1-regex-statt-treesitter)
    - [2. Whole-Line Replacement](#2-whole-line-replacement)
    - [3. Descending Order Application](#3-descending-order-application)
    - [4. Import Offset Compensation](#4-import-offset-compensation)
    - [5. Exclusion Pattern](#5-exclusion-pattern)
  - [Kernprinzipien](#kernprinzipien)
  - [Ausschlaggebend bei der letzten Änderung](#ausschlaggebend-bei-der-letzten-nderung)
  - [Verwendung](#verwendung)
    - [Basis-Syntax](#basis-syntax)
    - [Mit .create() Import](#mit-create-import)

---

## Das Problem

Die ursprüngliche Treesitter-basierte Implementation hatte mehrere kritische Fehler:

1. **Self-Migration**: Das Modul hat sich selbst gescannt und dabei eigene `vim.notify` Aufrufe kaputt gemacht
2. **Offset-Korruption**: Bei mehrfachen Replacements wurden die Zeilen-Indizes inkorrekt berechnet
3. **Komplexe String-Offset-Berechnung**: Treesitter liefert byte-offsets, die mit Lua's 1-based String-Indexierung kollidierten

## Die Lösung

### 1. Regex statt Treesitter

**Warum**: Treesitter gibt exclusive `end_col` Werte zurück, die mit Lua's String-Slicing (1-based) schwer zu kombinieren sind.

**Wie**: Zurück zu einfachen Lua-Patterns wie in der working monofile:
- Pattern-Matching für `vim.notify(...)`
- Klammern-Zählung für multiline detection
- Komplette Zeilen-Ersetzung statt Teil-String-Manipulation

### 2. Whole-Line Replacement

**Warum**: Partial String-Replacements führten zu Offset-Fehlern bei mehrfachen Matches.

**Wie**:
```lua
-- Ersetze komplette Zeilen-Range auf einmal
api.nvim_buf_set_lines(bufnr, start_idx, end_idx, false, { replacement })
```

**Kritisch**: Die Index-Konvertierung:
- Parser liefert **1-based** line numbers (wie Vim)
- `nvim_buf_set_lines` erwartet **0-based** indices mit **exclusive end**

```lua
-- Beispiel: Ersetze Zeilen 5-7 (1-based, inclusive)
local start_idx = 5 - 1  -- = 4 (0-based start)
local end_idx = 7        -- = 7 (0-based exclusive end)
-- Ersetzt Buffer-Zeilen [4,5,6] = Vim-Zeilen [5,6,7]
```

### 3. Descending Order Application

**Warum**: Wenn man von oben nach unten ersetzt, verschieben sich alle folgenden Zeilen-Nummern.

**Wie**: Sortiere Matches absteigend nach `end_line`:
```lua
table.sort(matches, function(a, b)
  return a.extra.end_line > b.extra.end_line
end)
```

So bleiben alle noch nicht verarbeiteten Matches gültig.

### 4. Import Offset Compensation

**Warum**: Wenn `local notify = require("lib.notify")` an Zeile 1 eingefügt wird, verschieben sich alle Zeilen um +2.

**Wie**: Nach Import-Injection alle Match-Zeilen adjustieren:
```lua
if import_added then
  for _, match in ipairs(matches) do
    match.lnum = match.lnum + 2
    match.extra.end_line = match.extra.end_line + 2
  end
end
```

### 5. Exclusion Pattern

**Warum**: Das Modul hat sich selbst gescannt und dabei `vim.notify` Aufrufe in `init.lua` und `picker.lua` migriert.

**Wie**: Überspringe alle Files mit `/usrcmds/migrate/` im Pfad:
```lua
local function should_exclude(filepath)
  local normalized = filepath:gsub("\\", "/")
  return normalized:match("/usrcmds/migrate/") ~= nil
end
```

## Kernprinzipien

1. **Einfachheit über Cleverness**: Regex ist einfacher zu debuggen als Treesitter
2. **Komplette Units ersetzen**: Keine Teil-String-Operationen
3. **Descending Order**: Von unten nach oben arbeiten
4. **Offset-Awareness**: Import-Injection verschiebt Zeilen

## Ausschlaggebend bei der letzten Änderung

Der finale Fix war die **korrekte Index-Konvertierung** in `refactor.lua`:

```lua
-- VORHER (falsch):
local start_line = match.line - 1
local end_line = match.end_line  -- Unklar ob inclusive/exclusive

-- NACHHER (richtig):
local start_idx = match.line - 1     -- 1-based -> 0-based
local end_idx = match.end_line       -- 1-based inclusive -> 0-based exclusive
```

**Die Erkenntnis**:
* Parser gibt 1-based **inclusive** line numbers (wie Vim: Zeile 5 bis Zeile 7)
* API erwartet 0-based **exclusive** end (wie Arrays: indices [4, 7))
* Die Konvertierung ist: `start = line - 1`, `end = end_line` (OHNE -1!)

Dadurch werden endlich die richtigen Zeilen ersetzt statt vorher/nachher eingefügt.

## Verwendung

### Basis-Syntax

```vim
:MigrateNotify              " Aktuelle Zeile
:MigrateNotify %            " Ganzer Buffer (mit Picker)
:MigrateNotify cwd          " Alle Lua-Files im CWD (mit Picker)
:'<,'>MigrateNotify         " Visual selection / Range
```

### Mit .create() Import

Verwende `--create` um statt:
```lua
local notify = require("lib.notify")
```

Diese Import-Zeile zu generieren:
```lua
local notify = require("lib.notify").create("")
```

**Beispiele:**
```vim
:MigrateNotify % --create       " Buffer mit .create() import
:MigrateNotify cwd --create     " CWD mit .create() import
:MigrateNotify --create         " Aktuelle Zeile mit .create() import
```

**Verhalten:**
- Prüft ob bereits ein Import existiert (mit oder ohne `.create()`)
- Bei `--create`: Fügt `.create("")` Import ein an der ersten Nicht-Kommentar-Zeile
- Ohne `--create`: Fügt einfachen Import an Zeile 1 ein
- Bestehende `.create("module")` Imports werden erkannt und nicht dupliziert

---

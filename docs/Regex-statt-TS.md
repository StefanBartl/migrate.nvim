# Migration fix documentation

## Table of content

  - [The problem](#the-problem)
  - [The solution](#the-solution)
    - [1. Regex instead of treesitter](#1-regex-instead-of-treesitter)
    - [2. Whole-Line Replacement](#2-whole-line-replacement)
    - [3. Descending Order Application](#3-descending-order-application)
    - [4. Import Offset Compensation](#4-import-offset-compensation)
    - [5. Exclusion Pattern](#5-exclusion-pattern)
  - [Core principles](#core-principles)
  - [What decided the last change](#what-decided-the-last-change)
  - [Usage](#usage)
    - [Base syntax](#base-syntax)
    - [With a .create() import](#with-a-create-import)

---

## The problem

The original treesitter-based implementation had several critical faults:

1. **Self-migration**: the module scanned itself and broke its own `vim.notify` calls in the process
2. **Offset corruption**: with multiple replacements the line indices were computed incorrectly
3. **Complex string offset arithmetic**: treesitter delivers byte offsets, which collided with Lua's 1-based string indexing

## The solution

### 1. Regex instead of treesitter

**Why**: treesitter returns exclusive `end_col` values, which are hard to combine with Lua's (1-based) string slicing.

**How**: back to simple Lua patterns, as in the working monofile:
- pattern matching for `vim.notify(...)`
- bracket counting for multiline detection
- replacing complete lines instead of manipulating substrings

### 2. Whole-Line Replacement

**Why**: partial string replacements led to offset errors on multiple matches.

**How**:
```lua
-- replace the complete line range in one go
api.nvim_buf_set_lines(bufnr, start_idx, end_idx, false, { replacement })
```

**Critical**: the index conversion:
- the parser delivers **1-based** line numbers (like Vim)
- `nvim_buf_set_lines` expects **0-based** indices with an **exclusive end**

```lua
-- example: replace lines 5-7 (1-based, inclusive)
local start_idx = 5 - 1  -- = 4 (0-based start)
local end_idx = 7        -- = 7 (0-based exclusive end)
-- replaces buffer lines [4,5,6] = Vim lines [5,6,7]
```

### 3. Descending Order Application

**Why**: replacing from the top down shifts all the following line numbers.

**How**: sort the matches descending by `end_line`:
```lua
table.sort(matches, function(a, b)
  return a.extra.end_line > b.extra.end_line
end)
```

That way every match not yet processed stays valid.

### 4. Import Offset Compensation

**Why**: when `local notify = require("lib.notify")` is inserted at line 1, all lines shift by +2.

**How**: adjust every match line after the import injection:
```lua
if import_added then
  for _, match in ipairs(matches) do
    match.lnum = match.lnum + 2
    match.extra.end_line = match.extra.end_line + 2
  end
end
```

### 5. Exclusion Pattern

**Why**: the module scanned itself and migrated `vim.notify` calls in `init.lua` and `picker.lua` in the process.

**How**: skip every file with `/usrcmds/migrate/` in its path:
```lua
local function should_exclude(filepath)
  local normalized = filepath:gsub("\\", "/")
  return normalized:match("/usrcmds/migrate/") ~= nil
end
```

## Core principles

1. **Simplicity over cleverness**: regex is easier to debug than treesitter
2. **Replace complete units**: no substring operations
3. **Descending order**: work from the bottom up
4. **Offset awareness**: an import injection shifts lines

## What decided the last change

The final fix was the **correct index conversion** in `refactor.lua`:

```lua
-- BEFORE (wrong):
local start_line = match.line - 1
local end_line = match.end_line  -- unclear whether inclusive/exclusive

-- AFTER (right):
local start_idx = match.line - 1     -- 1-based -> 0-based
local end_idx = match.end_line       -- 1-based inclusive -> 0-based exclusive
```

**The insight**:
* the parser gives 1-based **inclusive** line numbers (like Vim: line 5 through line 7)
* the API expects a 0-based **exclusive** end (like arrays: indices [4, 7))
* the conversion is: `start = line - 1`, `end = end_line` (WITHOUT -1!)

With that, the right lines finally get replaced instead of being inserted before or after.

## Usage

### Base syntax

```vim
:MigrateNotify              " the current line
:MigrateNotify %            " the whole buffer (with a picker)
:MigrateNotify cwd          " all Lua files in the CWD (with a picker)
:'<,'>MigrateNotify         " visual selection / range
```

### With a .create() import

Use `--create` to generate, instead of this import line:
```lua
local notify = require("lib.notify")
```

this one:
```lua
local notify = require("lib.notify").create("")
```

**Examples:**
```vim
:MigrateNotify % --create       " the buffer with a .create() import
:MigrateNotify cwd --create     " the CWD with a .create() import
:MigrateNotify --create         " the current line with a .create() import
```

**Behaviour:**
- checks whether an import already exists (with or without `.create()`)
- with `--create`: inserts a `.create("")` import at the first non-comment line
- without `--create`: inserts a plain import at line 1
- existing `.create("module")` imports are recognized and not duplicated

---

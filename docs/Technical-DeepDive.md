# Technical Deep Dive

Technical documentation of the `usrcmds.migrate` infrastructure.

## Table of content

  - [Architecture overview](#architecture-overview)
  - [Core Components](#core-components)
    - [1. command.lua - Command Handler](#1-commandlua-command-handler)
    - [2. picker.lua - Telescope UI](#2-pickerlua-telescope-ui)
    - [3. buffer.lua - Buffer Operations](#3-bufferlua-buffer-operations)
  - [Module Implementation Pattern](#module-implementation-pattern)
    - [Required Interface](#required-interface)
    - [Match Format](#match-format)
  - [Critical Implementation Details](#critical-implementation-details)
    - [1. Index-Konvertierung](#1-index-konvertierung)
    - [2. Descending Order Application](#2-descending-order-application)
    - [3. Import Offset Compensation](#3-import-offset-compensation)
    - [4. Self-Migration Prevention](#4-self-migration-prevention)
  - [Performance Considerations](#performance-considerations)
    - [1. Lazy Buffer Loading](#1-lazy-buffer-loading)
    - [2. Ripgrep for the CWD scan (opt module)](#2-ripgrep-for-the-cwd-scan-opt-module)
  - [Error Handling](#error-handling)
    - [Graceful Degradation](#graceful-degradation)
    - [User Feedback](#user-feedback)
    - [Undo Safety](#undo-safety)
  - [Testing Strategy](#testing-strategy)
    - [Unit Tests (Empfohlen)](#unit-tests-empfohlen)
    - [Integration Tests](#integration-tests)
  - [Future Improvements](#future-improvements)
    - [1. AST-based Detection (with care!)](#1-ast-based-detection-with-care)
    - [2. Incremental Parsing](#2-incremental-parsing)
    - [3. Dry-Run Mode](#3-dry-run-mode)
    - [4. Undo-Stack Integration](#4-undo-stack-integration)
  - [Debugging Tips](#debugging-tips)
    - [Enable Verbose Logging](#enable-verbose-logging)
    - [Inspect Matches](#inspect-matches)
    - [Test Pattern in Isolation](#test-pattern-in-isolation)
    - [Check Buffer State](#check-buffer-state)

---

## Architecture overview

```
┌─────────────────────────────────────────────────────────┐
│                     User Interface                       │
│                   (Vim Commands)                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              common/command.lua                          │
│         (Command Handler & Router)                       │
└────────┬───────────────────────────────┬────────────────┘
         │                               │
         ▼                               ▼
┌─────────────────────┐        ┌──────────────────────────┐
│  Module-specific    │        │   common/picker.lua      │
│  Scanner            │───────▶│   (Telescope UI)         │
│  (parser.lua)       │        └──────────────────────────┘
└─────────┬───────────┘                 │
          │                             │
          ▼                             ▼
┌─────────────────────────────────────────────────────────┐
│              Module-specific Refactor                    │
│                 (refactor.lua)                           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              common/buffer.lua                           │
│         (Buffer I/O Operations)                          │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. command.lua - Command Handler

**Responsibility**: unified command registration and routing.

**Key Features**:
- a uniform syntax across every module
- Range/Mode Detection
- Argument Parsing
- Auto-completion

**Flow**:
```lua
User Input (e.g. :MigrateNotify %)
    ↓
Parse arguments (mode: %, cwd, etc.)
    ↓
Route to appropriate scanner
    ↓
Call show_picker or apply_matches
```

**Implementation Detail - Range Detection**:
```lua
if cmd_opts.range > 0 then
  -- Visual selection or explicit range (:1,5MigrateNotify)
  scan_range(bufnr, cmd_opts.line1, cmd_opts.line2)
else
  -- Check for argument
  if arg == "%" then
    scan_buffer(bufnr)
  elseif arg == "cwd" then
    scan_cwd()
  else
    -- Default: current line
    scan_range(bufnr, cursor[1], cursor[1])
  end
end
```

### 2. picker.lua - Telescope UI

**Responsibility**: a generic selection interface for every migration.

**Key Features**:
- Multi-select Support (`<Tab>`)
- preview with syntax highlighting
- Batch-Apply (`<S-A>`)
- Customizable Entry/Preview Formatters

**Entry Maker Pattern**:
```lua
entry_maker = function(match)
  return {
    value = match,              -- Original match data
    ordinal = display_text,     -- For fuzzy finding
    display = formatted_string, -- Display in picker
    filename = match.fname,     -- For telescope preview
    lnum = match.lnum,         -- For telescope preview
  }
end
```

**Preview Flattening**:
Problem: `format_preview` can return multiline strings (`"line1
line2"`).
Solution: flatten with a newline split:
```lua
local flattened = {}
for _, line in ipairs(lines) do
  for subline in line:gmatch("[^\r\n]+") do
    table.insert(flattened, subline)
  end
end
```

### 3. buffer.lua - Buffer Operations

**Responsibility**: safe buffer/file I/O operations.

**Key Operations**:

**Replace Line(s)**:
```lua
function M.replace_lines(bufnr, start_line, end_line, replacement)
  local start_idx = start_line - 1  -- 1-based → 0-based
  local end_idx = end_line          -- inclusive → exclusive

  return pcall(api.nvim_buf_set_lines,
    bufnr, start_idx, end_idx, false, replacement)
end
```

**File I/O**:
```lua
function M.replace_in_file(filepath, line_num, replacement)
  local lines = fn.readfile(filepath)
  lines[line_num] = replacement
  return fn.writefile(lines, filepath) == 0
end
```

**Undo Points**:
```lua
function M.create_undo_point(bufnr)
  api.nvim_buf_call(bufnr, function()
    pcall(vim.cmd, "undojoin")  -- Join with previous undo
  end)
end
```

**Recursive File Discovery**:
```lua
function M.find_lua_files(dir)
  return fn.globpath(dir, "**/*.lua", false, true)
end
```

## Module Implementation Pattern

### Required Interface

Every migration module has to implement these functions:

```lua
---@param bufnr integer
---@param line1 integer 1-based start
---@param line2 integer 1-based end (inclusive)
---@return MigrateCommon.Match[]
function scan_range(bufnr, line1, line2)
end

---@param bufnr integer
---@return MigrateCommon.Match[]
function scan_buffer(bufnr)
end

---@return MigrateCommon.Match[]
function scan_cwd()
end

---@param matches MigrateCommon.Match[]
function apply_matches(matches)
end

---@param matches MigrateCommon.Match[]
function show_picker_impl(matches)
end
```

### Match Format

```lua
---@class MigrateCommon.Match
{
  bufnr = integer,        -- Buffer number (required for apply)
  fname = string,         -- File path (optional, for display)
  lnum = integer,         -- 1-based line number
  text = string,          -- Original text (for display)
  migrated = string,      -- Replacement text
  source = "buf"|"file",  -- Source type
  extra = {               -- Module-specific data
    -- e.g. end_line, log_level, etc.
  }
}
```

## Critical Implementation Details

### 1. Index-Konvertierung

**Problem**: Vim uses 1-based line numbers, the Neovim API 0-based indices.

**Solution**:
```lua
-- the parser/scanner returns 1-based (like Vim)
local match = {
  line = 5,      -- line 5 (Vim style)
  end_line = 7,  -- through line 7 (inclusive)
}

-- convert for nvim_buf_set_lines
local start_idx = match.line - 1    -- 4 (0-based)
local end_idx = match.end_line      -- 7 (0-based exclusive!)

-- Wichtig: end_idx NICHT -1!
-- nvim_buf_set_lines(bufnr, 4, 7, false, ...)
-- replaces indices [4,5,6] = lines [5,6,7]
```

**Beweis**:
```lua
-- test in Neovim:
vim.api.nvim_buf_set_lines(0, 4, 7, false, {"NEW"})
-- replaces lines 5,6,7 with "NEW"
```

### 2. Descending Order Application

**Problem**: replacing from the top down shifts the lines.

**Example**:
```
line 5: match A
line 10: match B

1. Replace line 5 (multiline → single line)
   → every following line shifts by -2
   → match B is now at line 8 instead of 10!
```

**Solution**: descending order
```lua
table.sort(matches, function(a, b)
  if a.extra.end_line == b.extra.end_line then
    return a.extra.end_col > b.extra.end_col
  end
  return a.extra.end_line > b.extra.end_line
end)

-- apply: 10 → 5 (not 5 → 10)
```

### 3. Import Offset Compensation

**Problem**: the import injection inserts lines and shifts every match.

**Example**:
```lua
-- Vorher:
[Line 1] local M = {}
[Line 5] vim.notify(...)  ← Match

-- Nach Import-Injection:
[Line 1] local notify = require("lib.notify")
[Line 2]
[Line 3] local M = {}
[Line 7] vim.notify(...)  ← the match is here now!
```

**Solution**:
```lua
local import_added = refactor.inject_import(bufnr)

if import_added then
  local offset = 2  -- 2 lines (import + blank line)
  for _, match in ipairs(matches) do
    match.lnum = match.lnum + offset
    match.extra.end_line = match.extra.end_line + offset
  end
end
```

### 4. Self-Migration Prevention

**Problem**: the module scans itself and migrates its own code.

**Example**: `init.lua` has the line:
```lua
vim.notify("Applied migration", vim.log.levels.INFO)
```

With `:MigrateNotify cwd` that gets matched and broken too!

**Solution**: an exclusion pattern
```lua
local function should_exclude(filepath)
  local normalized = filepath:gsub("\\", "/")
  return normalized:match("/usrcmds/migrate/") ~= nil
end

-- In scan_cwd:
for _, file in ipairs(files) do
  if not should_exclude(file) then
    -- scan file
  end
end
```

## Performance Considerations

### 1. Lazy Buffer Loading

```lua
function M.ensure_buffer(filepath)
  local bufnr = fn.bufnr(filepath)

  if bufnr == -1 then
    bufnr = fn.bufadd(filepath)  -- Add without loading
  end

  if not api.nvim_buf_is_loaded(bufnr) then
    fn.bufload(bufnr)  -- Load only when needed
  end

  return bufnr
end
```

### 2. Ripgrep for the CWD scan (opt module)

Instead of loading and parsing every file:
```lua
local cmd = { "rg", "--vimgrep", pattern }
local result = fn.systemlist(cmd)

-- Parse ripgrep output
for _, line in ipairs(result) do
  local fname, lnum, text = line:match("^(.+):(%d+):%d+:(.*)$")
  -- Process only matched lines
end
```

**Trade-off**:
- ✅ faster for large projects
- ❌ needs an external dependency (ripgrep)
- ❌ less flexible (line-based only)

The notify module does not use ripgrep because:
- multiline detection is needed
- it has to load the buffer for the balanced-parentheses check

## Error Handling

### Graceful Degradation

```lua
local ok, err = pcall(api.nvim_buf_set_lines, ...)
if not ok then
  notify.error("Failed: " .. tostring(err))
  return false
end
return true
```

### User Feedback

```lua
-- Always inform user
notify.info(string.format("Applied %d/%d migrations",
  success_count, total_count))

-- Warn on issues
if excluded_count > 0 then
  notify.warn(string.format("Excluded %d files", excluded_count))
end
```

### Undo Safety

```lua
-- Create undo point BEFORE modifications
buffer_ops.create_undo_point(bufnr)

-- User can undo entire migration with single 'u'
```

## Testing Strategy

### Unit Tests (Empfohlen)

```lua
-- Test pattern matching
local function test_pattern()
  local input = 'vim.notify("test", vim.log.levels.INFO)'
  local output = migrate_line(input)
  assert(output == 'notify.info("test")')
end

-- Test index conversion
local function test_indices()
  local match = { line = 5, end_line = 7 }
  local start_idx = match.line - 1
  local end_idx = match.end_line
  assert(start_idx == 4)
  assert(end_idx == 7)
end
```

### Integration Tests

```lua
-- Create test buffer
local bufnr = api.nvim_create_buf(false, true)
api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'vim.notify("test", vim.log.levels.INFO)',
  'local x = 1',
})

-- Run migration
local matches = scan_buffer(bufnr)
apply_matches(matches)

-- Verify result
local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
assert(lines[1] == 'notify.info("test")')
```

## Future Improvements

### 1. AST-based Detection (with care!)

Treesitter could be used for:
- ✅ precise nested expression handling
- ✅ context awareness (string vs. code)

But: take care with the offset arithmetic!

### 2. Incremental Parsing

For large files:
```lua
-- Parse in chunks
for chunk_start = 1, line_count, 1000 do
  local chunk_end = math.min(chunk_start + 1000, line_count)
  local matches = scan_range(bufnr, chunk_start, chunk_end)
  -- Process chunk
end
```

### 3. Dry-Run Mode

```lua
:MigrateNotify % --dry-run
-- Shows what would be changed without applying
```

### 4. Undo-Stack Integration

```lua
-- Currently: Single undo point per buffer
-- Future: Undo each migration individually
for _, match in ipairs(matches) do
  buffer_ops.create_undo_point(bufnr)
  apply_match(match)
end
```

## Debugging Tips

### Enable Verbose Logging

```lua
local notify = require("lib.notify").create("[migrate.debug]")
notify.debug("Match at line " .. match.line)
notify.debug("Applying: " .. vim.inspect(match))
```

### Inspect Matches

```lua
-- Before applying, inspect what was found
:lua print(vim.inspect(require("usrcmds.migrate.notify").scan_buffer(0)))
```

### Test Pattern in Isolation

```lua
:lua local line = vim.fn.getline('.'); print(require("usrcmds.migrate.notify.parser").migrate_single_line(line))
```

### Check Buffer State

```lua
-- After migration
:lua print(vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false)))
```

---

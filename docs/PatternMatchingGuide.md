# Pattern Matching Guide

A practical guide to pattern detection in migration modules.

## Table of content

  - [Regex vs Treesitter](#regex-vs-treesitter)
    - [When to use regex?](#when-to-use-regex)
    - [When to use treesitter?](#when-to-use-treesitter)
  - [Lua Pattern Basics](#lua-pattern-basics)
    - [Grundlegende Metacharacters](#grundlegende-metacharacters)
    - [Wichtige Patterns](#wichtige-patterns)
  - [Pattern Examples](#pattern-examples)
    - [1. Simple Function Call](#1-simple-function-call)
    - [2. Function call with an argument](#2-function-call-with-an-argument)
    - [3. With different quotes](#3-with-different-quotes)
    - [4. Prefix variations](#4-prefix-variations)
    - [5. Multiline with a balance check](#5-multiline-with-a-balance-check)
  - [Common Pitfalls](#common-pitfalls)
    - [1. Forgotten escaping](#1-forgotten-escaping)
    - [2. Greedy Matching Problem](#2-greedy-matching-problem)
    - [3. Forgotten anchors](#3-forgotten-anchors)
    - [4. Quote-Handling](#4-quote-handling)
  - [Advanced Techniques](#advanced-techniques)
    - [1. Balanced Expression Capture](#1-balanced-expression-capture)
    - [2. Context-Aware Matching](#2-context-aware-matching)
    - [3. Expression Preservation](#3-expression-preservation)
    - [4. Capture Groups for Reconstruction](#4-capture-groups-for-reconstruction)
  - [Testing Patterns](#testing-patterns)
    - [Interactive REPL Testing](#interactive-repl-testing)
    - [Unit Test Pattern](#unit-test-pattern)
    - [Fuzzy Testing](#fuzzy-testing)
  - [Performance Optimization](#performance-optimization)
    - [1. Pre-compiled Patterns](#1-pre-compiled-patterns)
    - [2. Early Exit](#2-early-exit)
    - [3. Limit Backtracking](#3-limit-backtracking)
  - [Debugging Patterns](#debugging-patterns)
    - [Visualize Captures](#visualize-captures)
    - [Pattern Visualizer](#pattern-visualizer)

---

## Regex vs Treesitter

### When to use regex?

✅ **Use regex when**:
- the pattern is line-based
- single-line replacements
- the structure is simple (function calls, simple expressions)
- fast iteration matters

**Examples**:
- `vim.notify(...)` → `notify.level(...)`
- `nvim_buf_get_option(...)` → `nvim_get_option_value(...)`
- Import statements

### When to use treesitter?

✅ **Use treesitter when**:
- the AST structure matters
- nested expressions
- context awareness is needed (string vs. code)
- precise code manipulation

**Examples**:
- refactoring class structures
- Type-System Migrationen
- Complex Expression-Rewrites

⚠️ **Careful**: treesitter offset handling is complex! See the `notify` module's lessons learned.

## Lua Pattern Basics

### Grundlegende Metacharacters

```lua
.   -- Beliebiges Zeichen
%a  -- Letter
%d  -- Digit
%s  -- Whitespace
%w  -- Alphanumeric
%p  -- Punctuation

%A, %D, %S, %W, %P  -- Negierte Versionen

*   -- 0 or more (greedy)
+   -- 1 or more (greedy)
-   -- 0 or more (non-greedy)
?   -- 0 or 1
```

### Wichtige Patterns

**Dot Escaping**:
```lua
"vim.notify"     -- WRONG! also matches "vimXnotify"
"vim%.notify"    -- RICHTIG
```

**Greedy vs Non-Greedy**:
```lua
-- Input: "foo(bar, baz)"
"%((.*)%)"       -- Matched: "(bar, baz)" (greedy)
"%((.-)%)"       -- Matched: "(bar, baz)" (non-greedy, gleich hier)

-- Input: "foo(bar) and foo(baz)"
"%((.*)%)"       -- Matched: "(bar) and foo(baz)" (greedy!)
"%((.-)%)"       -- Matched: "(bar)" (non-greedy)
```

**Optional Whitespace**:
```lua
"notify%s*%("    -- 0 or more spaces
"notify%s+%("    -- 1 or more spaces
```

## Pattern Examples

### 1. Simple Function Call

```lua
-- Match: notify("message")
local pattern = 'notify%s*%(%s*"(.-)"%s*%)'

local msg = line:match(pattern)
if msg then
  return string.format('log("%s")', msg)
end
```

### 2. Function call with an argument

```lua
-- Match: vim.notify("msg", vim.log.levels.INFO)
local pattern = 'vim%.notify%s*%(%s*(.-)%s*,%s*vim%.log%.levels%.(%u+)%s*%)'

local msg, level = line:match(pattern)
if msg and level then
  return string.format('notify.%s(%s)', level:lower(), msg)
end
```

### 3. With different quotes

```lua
-- match: option("name") or option('name')
local function match_option(line)
  -- Capture quote type
  local quote, name = line:match('option%s*%(%s*(["\'])(.-)%1%s*%)')

  if name then
    return string.format('new_option(%s%s%s)', quote, name, quote)
  end
end
```

### 4. Prefix variations

```lua
-- Match: vim.api.func(), api.func(), func()
local prefix_map = {
  ["vim%.api%."] = "vim.api.",
  ["api%."] = "api.",
  [""] = "",
}

for pattern_prefix, replacement_prefix in pairs(prefix_map) do
  local new = line:gsub(
    pattern_prefix .. 'old_func%s*%((.-)%)',
    function(args)
      return replacement_prefix .. 'new_func(' .. args .. ')'
    end
  )

  if new ~= line then
    return new
  end
end
```

### 5. Multiline with a balance check

```lua
-- for patterns that span several lines
local function find_call_end(lines, start_idx)
  local paren_count = 0

  -- count the brackets
  for i = start_idx, #lines do
    local line = lines[i]

    for char in line:gmatch(".") do
      if char == "(" then
        paren_count = paren_count + 1
      elseif char == ")" then
        paren_count = paren_count - 1

        if paren_count == 0 then
          return i  -- Gefunden!
        end
      end
    end
  end

  return nil  -- Nicht geschlossen
end

-- Verwendung:
if line:match("vim%.notify%s*%(") then
  local end_idx = find_call_end(lines, i)

  if end_idx then
    local call_lines = {}
    for j = i, end_idx do
      table.insert(call_lines, lines[j])
    end

    -- Process multiline call
    local migrated = migrate_multiline(call_lines)
  end
end
```

## Common Pitfalls

### 1. Forgotten escaping

```lua
-- WRONG
"vim.api.nvim_buf_get_option"
-- also matches: "vimXapiXnvim_buf_get_option"

-- RICHTIG
"vim%.api%.nvim_buf_get_option"
```

### 2. Greedy Matching Problem

```lua
-- Input: 'notify("test", level), notify("test2", level)'
-- Pattern: 'notify%s*%((.*)%)'

-- WRONG: matches the WHOLE string up to the last )
-- Ergebnis: '"test", level), notify("test2", level'

-- RICHTIG: Non-greedy
-- Pattern: 'notify%s*%((.-)%)'
-- Ergebnis: '"test", level'
```

### 3. Forgotten anchors

```lua
-- a pattern without ^$ matches inside strings too!

-- WRONG:
local pattern = 'vim%.notify%s*%((.-)%)'

-- Code:
local example = 'vim.notify("in string", level)'  -- gets matched!

-- BETTER (for single-line):
local pattern = '^%s*vim%.notify%s*%((.-)%).*$'
-- ^%s* = start with optional whitespace
-- .*$ = the rest of the line
```

### 4. Quote-Handling

```lua
-- WRONG: hardcoded quote type
'option%s*%(%s*"(.-)"%s*%)'  -- only works for "

-- RICHTIG: Capture quote type
'option%s*%(%s*(["\'])(.-)%1%s*%)'
--                ^^^^        ^^ Backreference!
-- Matched: option("x") UND option('x')
```

## Advanced Techniques

### 1. Balanced Expression Capture

```lua
-- Match: func(arg1, func(nested), arg3)
-- Challenge: Nested parentheses!

local function extract_balanced(str, start_pos)
  local depth = 0
  local start = str:find("%(", start_pos)

  if not start then return nil end

  for i = start, #str do
    local char = str:sub(i, i)

    if char == "(" then
      depth = depth + 1
    elseif char == ")" then
      depth = depth - 1

      if depth == 0 then
        return str:sub(start + 1, i - 1)  -- Content without ()
      end
    end
  end

  return nil
end

-- Usage:
local content = extract_balanced('func(a, func(b, c), d)', 1)
-- Returns: "a, func(b, c), d"
```

### 2. Context-Aware Matching

```lua
-- Skip patterns inside strings/comments
local function is_in_string_or_comment(line, pos)
  -- Check if before pos we have unclosed string
  local before = line:sub(1, pos)

  -- Comment check
  if before:match("^%s*%-%-") then
    return true
  end

  -- String check (simplified)
  local quote_count = select(2, before:gsub('"', ''))
  if quote_count % 2 == 1 then
    return true  -- Inside string
  end

  return false
end

-- Usage:
local start = line:find("pattern")
if start and not is_in_string_or_comment(line, start) then
  -- Process pattern
end
```

### 3. Expression Preservation

```lua
-- Preserve complex expressions as-is
local pattern = 'func%s*%(%s*([%w_%.%:%(%%)%[%]%s%+%-%*/]-)%s*%)'
--                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--                              Allows: identifiers, dots, colons,
--                              parens, brackets, spaces, operators

-- Matches:
-- func(simple)
-- func(obj.method())
-- func(arr[idx])
-- func(a + b)
-- func(vim.fn.bufnr("%"))
```

### 4. Capture Groups for Reconstruction

```lua
-- Preserve indent and trailing content
local indent, content, rest = line:match(
  "^(%s*)old_pattern%s*%((.-)%)(.*)$"
)

if content then
  return string.format("%snew_pattern(%s)%s", indent, content, rest)
end

-- Example:
-- Input:  "    old_pattern(x) -- comment"
-- indent: "    "
-- content: "x"
-- rest:   " -- comment"
-- Output: "    new_pattern(x) -- comment"
```

## Testing Patterns

### Interactive REPL Testing

```lua
-- In Neovim command line
:lua local line = 'vim.notify("test", vim.log.levels.INFO)'
:lua print(line:match('vim%.notify%s*%((.-),%s*vim%.log%.levels%.(%u+)%)'))
-- Prints: test    INFO
```

### Unit Test Pattern

```lua
local function test_pattern()
  local cases = {
    {
      input = 'vim.notify("msg", vim.log.levels.INFO)',
      expected = 'notify.info("msg")',
    },
    {
      input = '  vim.notify("msg", vim.log.levels.WARN)  -- comment',
      expected = '  notify.warn("msg")  -- comment',
    },
  }

  for _, case in ipairs(cases) do
    local result = migrate_line(case.input)
    assert(result == case.expected,
      string.format("Failed: %s\nExpected: %s\nGot: %s",
        case.input, case.expected, result))
  end

  print("All tests passed!")
end

test_pattern()
```

### Fuzzy Testing

```lua
-- Generate random valid inputs
local function generate_test_case()
  local levels = {"INFO", "WARN", "ERROR", "DEBUG", "TRACE"}
  local level = levels[math.random(#levels)]

  local messages = {
    '"test message"',
    'string.format("count: %d", n)',
    '"multi\\nline"',
  }
  local msg = messages[math.random(#messages)]

  return string.format('vim.notify(%s, vim.log.levels.%s)', msg, level)
end

-- Test 100 random cases
for i = 1, 100 do
  local input = generate_test_case()
  local output = migrate_line(input)

  -- Verify output format
  assert(output:match("^notify%.%w+%("), "Invalid output: " .. output)
end
```

## Performance Optimization

### 1. Pre-compiled Patterns

```lua
-- SLOW (compiled on every call)
local function migrate(line)
  return line:gsub('vim%.notify%s*%((.-)%)', 'notify(%1)')
end

-- SCHNELL (compile once)
local pattern = 'vim%.notify%s*%((.-)%)'
local function migrate(line)
  return line:gsub(pattern, 'notify(%1)')
end
```

### 2. Early Exit

```lua
-- Check cheap condition first
if not line:match("notify") then
  return nil  -- Quick exit
end

-- Expensive pattern only if needed
local migrated = line:gsub(complex_pattern, replacement)
```

### 3. Limit Backtracking

```lua
-- LANGSAM (excessive backtracking)
'%s*(.*)%s*'

-- SCHNELL (possessive)
'%s*(.-)%s*'
```

## Debugging Patterns

### Visualize Captures

```lua
local function debug_pattern(line, pattern)
  local captures = {line:match(pattern)}

  print("Input: " .. line)
  print("Pattern: " .. pattern)
  print("Captures:")

  for i, capture in ipairs(captures) do
    print(string.format("  [%d] = %q", i, capture))
  end
end

-- Usage:
debug_pattern(
  'vim.notify("test", vim.log.levels.INFO)',
  'vim%.notify%s*%(%s*"(.-)"%s*,%s*vim%.log%.levels%.(%u+)%s*%)'
)
-- Output:
-- Input: vim.notify("test", vim.log.levels.INFO)
-- Pattern: vim%.notify%s*%(%s*"(.-)"%s*,%s*vim%.log%.levels%.(%u+)%s*%)
-- Captures:
--   [1] = "test"
--   [2] = "INFO"
```

### Pattern Visualizer

```lua
-- Show what pattern matches
local function visualize_match(line, pattern)
  local start_pos, end_pos = line:find(pattern)

  if start_pos then
    local before = line:sub(1, start_pos - 1)
    local match = line:sub(start_pos, end_pos)
    local after = line:sub(end_pos + 1)

    print(before .. ">>>" .. match .. "<<<" .. after)
  else
    print("No match")
  end
end

-- Usage:
visualize_match('vim.notify("test")', 'vim%.notify%s*%b()')
-- Output: >>>vim.notify("test")<<<
```

---

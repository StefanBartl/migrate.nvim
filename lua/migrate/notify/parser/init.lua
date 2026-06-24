---@module 'migrate.notify.parser'
---@brief Main parser orchestrator

local aliases = require("migrate.notify.parser.aliases")
local patterns = require("migrate.notify.parser.patterns")
local extractor = require("migrate.notify.parser.extractor")
local migrator = require("migrate.notify.parser.migrator")

local M = {}

local api = vim.api

---Scan buffer and return all matches
---@param bufnr integer
---@return UsrCmds.Migrate.Notify.Match[]
function M.scan_buffer(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  if vim.bo[bufnr].filetype ~= "lua" then
    return {}
  end

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local matches = {}
  local matched_lines = {}  -- Track which lines were already matched

  -- Detect aliases
  local notify_alias, levels_alias = aliases.detect(bufnr)

  local i = 1
  while i <= #lines do
    local line = lines[i]

    -- Skip non-processable lines (comments)
    if not patterns.is_processable(line) then
      i = i + 1
      goto continue
    end

    -- Skip if this line was already matched
    if matched_lines[i] then
      i = i + 1
      goto continue
    end

    -- Priority 1: vim.notify (direct calls)
    if patterns.is_vim_notify(line) then
      local end_idx = extractor.find_call_end(lines, i)

      if end_idx then
        if end_idx == i then
          -- Single line
          local migrated, level = migrator.migrate_vim_notify_line(line)
          if migrated then
            table.insert(matches, {
              line = i,
              end_line = i,
              col = 0,
              end_col = #line,
              original = line,
              replacement = migrated,
              log_level = level,
            })
            matched_lines[i] = true
          end
        else
          -- Multiline
          local call_lines = {}
          for j = i, end_idx do
            table.insert(call_lines, lines[j])
            matched_lines[j] = true  -- Mark all lines as matched
          end

          local migrated, level = migrator.migrate_multiline(call_lines)
          if migrated then
            table.insert(matches, {
              line = i,
              end_line = end_idx,
              col = 0,
              end_col = #lines[end_idx],
              original = table.concat(call_lines, "\n"),
              replacement = migrated,
              log_level = level,
            })
          end

          i = end_idx
        end
      end
    end

    -- Priority 2: Aliased notify (when aliases detected)
    -- SKIP if already matched
    if not matched_lines[i] and notify_alias and patterns.is_aliased_notify(line, notify_alias) then
      local end_idx = extractor.find_call_end(lines, i)

      if end_idx and end_idx == i then
        -- Only handle single-line aliased calls for now
        local migrated, level = migrator.migrate_aliased_line(
          line,
          notify_alias,
          levels_alias
        )
        if migrated then
          table.insert(matches, {
            line = i,
            end_line = i,
            col = 0,
            end_col = #line,
            original = line,
            replacement = migrated,
            log_level = level,
          })
          matched_lines[i] = true
        end
      end
    end

    -- Priority 3: Existing notify() calls (NEW)
    -- SKIP if already matched
    if not matched_lines[i] and patterns.is_existing_notify(line) then
      local migrated, level = migrator.migrate_existing_notify_line(line)
      if migrated then
        table.insert(matches, {
          line = i,
          end_line = i,
          col = 0,
          end_col = #line,
          original = line,
          replacement = migrated,
          log_level = level,
        })
        matched_lines[i] = true
      end
    end

    ::continue::
    i = i + 1
  end

  return matches
end

return M

---@module 'migrate.common.picker'
---@brief Generic Telescope picker for migration matches.
---@description
--- Provides a reusable picker implementation for all migration types.
--- Handles:
---   - Entry display with custom formatters
---   - Multi-select support (<Tab>)
---   - Preview with syntax highlighting
---   - Apply callback hooks
---   - Batch apply with <C-a>, <S-A>, or <M-a>

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local notify = require("lib.nvim.notify").create("[migrate.picker]")

local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("migrate.common.picker")

--- Show generic migration picker
---@param matches MigrateCommon.Match[]
---@param opts MigrateCommon.PickerOpts
function M.show(matches, opts)
  if not matches or #matches == 0 then
    notify.info("No matches found")
    return
  end

  if #matches == 1 and opts.single_apply then
    opts.on_apply({ matches[1] })
    return
  end

  pickers.new({}, {
    prompt_title = opts.title,

    finder = finders.new_table({
      results = matches,
      entry_maker = function(match)
        local display_text = opts.format_entry(match)

        -- Split into location and content
        local location = display_text:match("^(.-)  ") or display_text:sub(1, 35)
        local content = display_text:match("  (.+)$") or ""

        -- Format as simple string (no entry_display for now)
        local display_str = string.format("%-35s │ %s", location, content)

        return {
          value = match,
          ordinal = display_text,
          display = display_str,
          filename = match.fname,
          lnum = match.lnum,
        }
      end,
    }),

    previewer = previewers.new_buffer_previewer({
      title = "Migrated Preview",
      define_preview = function(self, entry)
        local lines = opts.format_preview(entry.value)

        -- Flatten: split any lines containing newlines
        local flattened = {}
        for _, line in ipairs(lines) do
          if type(line) == "string" then
            for subline in line:gmatch("[^\r\n]+") do
              table.insert(flattened, subline)
            end
            -- Handle empty lines (when line is just "\n")
            if line:match("^[\r\n]+$") then
              table.insert(flattened, "")
            end
          else
            table.insert(flattened, tostring(line))
          end
        end

        api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, flattened)
        api.nvim_set_option_value("filetype", "lua", { buf = self.state.bufnr })

        if #flattened > 0 then
          api.nvim_buf_set_extmark(self.state.bufnr, ns, 0, 0, { end_row = 1, hl_group = "DiffAdd" })
        end
      end,
    }),

    sorter = conf.generic_sorter({}),
    selection_caret = "▶ ",

    attach_mappings = function(prompt_bufnr, map)
      -- Helper function to apply migrations
      local function apply_migrations(selections)
        actions.close(prompt_bufnr)

        local ok, err = pcall(opts.on_apply, selections)
        if not ok then
          notify.error("Migration failed: " .. tostring(err))
        end
      end

      -- Replace default <CR> action (apply selected/multi-selected)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()

        if vim.tbl_isempty(selections) then
          local current = action_state.get_selected_entry()
          selections = { current }
        end

        local matches_to_apply = {}
        for _, entry in ipairs(selections) do
          if entry and entry.value then
            table.insert(matches_to_apply, entry.value)
          end
        end

        apply_migrations(matches_to_apply)
      end)

      -- Batch apply: Apply ALL matches (not just selected)
      -- Multiple keybindings for compatibility

      -- <C-a> (Ctrl-A) - Most reliable
      map({ "i", "n" }, "<C-a>", function()
        notify.info(string.format("Applying all %d matches...", #matches))
        apply_migrations(matches)
      end)

      -- <S-A> (Shift-A) - Alternative
      map({ "i", "n" }, "<S-A>", function()
        notify.info(string.format("Applying all %d matches...", #matches))
        apply_migrations(matches)
      end)

      -- <M-a> (Alt-A) - Another alternative
      map({ "i", "n" }, "<M-a>", function()
        notify.info(string.format("Applying all %d matches...", #matches))
        apply_migrations(matches)
      end)

      -- <C-y> (Ctrl-Y) - "Yes to all"
      map({ "i", "n" }, "<C-y>", function()
        notify.info(string.format("Applying all %d matches...", #matches))
        apply_migrations(matches)
      end)

      return true
    end,
  }):find()
end

return M

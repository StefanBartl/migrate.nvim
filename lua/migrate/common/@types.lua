---@meta
---@module 'migrate.common.@types'

---@class MigrateCommon.Match
---@field bufnr integer|nil        # Buffer number (if applicable)
---@field fname string|nil         # File path (if applicable)
---@field lnum integer             # 1-based line number
---@field text string              # Original text
---@field migrated string          # Replacement text
---@field source "buf"|"file"     # Source type
---@field extra table|nil          # Domain-specific metadata

---@class MigrateCommon.PickerOpts
---@field title string                             # Picker prompt title
---@field format_entry fun(match: MigrateCommon.Match): string # Format match for display
---@field format_preview fun(match: MigrateCommon.Match): string[] # Generate preview lines
---@field on_apply fun(selections: MigrateCommon.Match[]) # Callback for applying migrations
---@field single_apply boolean|nil                # Apply single match immediately without picker

---@class MigrateCommon.CommandOpts
---@field name string                                          # Command name (e.g. "MigrateNotify")
---@field scan_range fun(bufnr: integer, line1: integer, line2: integer): MigrateCommon.Match[] # Scan range
---@field scan_buffer fun(bufnr: integer): MigrateCommon.Match[]      # Scan buffer
---@field scan_cwd fun(): MigrateCommon.Match[]                       # Scan cwd
---@field apply_matches fun(matches: MigrateCommon.Match[])           # Apply migrations
---@field show_picker fun(matches: MigrateCommon.Match[])             # Show picker

---@class MigrateCommon.ApplyResult
---@field success boolean
---@field modified integer
---@field errors string[]

return {}

---@module 'migrate.opt.migrator'
---@brief Pure line-migration logic for the option API (no side effects).
---@description
--- Extracted from `migrate.opt` so it can be required (and tested) without
--- pulling in the command/picker/notify chain, which hard-depend on
--- lib.nvim/telescope.nvim.

local M = {}

local str_fmt = string.format

---Migrate a single line of text by replacing deprecated option API calls.
---@param line string The line to migrate
---@return string migrated The migrated line (unchanged if no match)
function M.migrate_line(line)
  local s = line

  -- Detect prefix used (vim.api., api., or nothing)
  local prefix_map = {
    ["vim%.api%."] = "vim.api.",
    ["api%."] = "api.",
    [""] = "",
  }

  -- nvim_buf_set_option(bufnr, "optname", value)
  -- → nvim_set_option_value("optname", value, { buf = bufnr })
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix
        .. "nvim_buf_set_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*'\"]-)%s*,%s*(['\"])(.-)%2%s*,%s*(.-)%s*%)",
      function(bufexpr, quote, optname, valueexpr)
        return str_fmt(
          "%snvim_set_option_value(%s%s%s, %s, { buf = %s })",
          replacement_prefix,
          quote,
          optname,
          quote,
          valueexpr,
          bufexpr
        )
      end
    )
  end

  -- nvim_win_set_option(winid, "optname", value)
  -- → nvim_set_option_value("optname", value, { win = winid })
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix
        .. "nvim_win_set_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*'\"]-)%s*,%s*(['\"])(.-)%2%s*,%s*(.-)%s*%)",
      function(winexpr, quote, optname, valueexpr)
        return str_fmt(
          "%snvim_set_option_value(%s%s%s, %s, { win = %s })",
          replacement_prefix,
          quote,
          optname,
          quote,
          valueexpr,
          winexpr
        )
      end
    )
  end

  -- nvim_buf_get_option(bufnr, "optname")
  -- → nvim_get_option_value("optname", { buf = bufnr })
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix
        .. "nvim_buf_get_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*'\"]-)%s*,%s*(['\"])(.-)%2%s*%)",
      function(bufexpr, quote, optname)
        return str_fmt(
          "%snvim_get_option_value(%s%s%s, { buf = %s })",
          replacement_prefix,
          quote,
          optname,
          quote,
          bufexpr
        )
      end
    )
  end

  -- nvim_win_get_option(winid, "optname")
  -- → nvim_get_option_value("optname", { win = winid })
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix
        .. "nvim_win_get_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*'\"]-)%s*,%s*(['\"])(.-)%2%s*%)",
      function(winexpr, quote, optname)
        return str_fmt(
          "%snvim_get_option_value(%s%s%s, { win = %s })",
          replacement_prefix,
          quote,
          optname,
          quote,
          winexpr
        )
      end
    )
  end

  return s
end

return M

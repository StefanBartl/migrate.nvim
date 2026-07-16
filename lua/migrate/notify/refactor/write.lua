---@module 'migrate.notify.refactor.write'
---@brief File write operations (sync/async) for migration results
---@description
--- Provides two strategies for writing migrated buffers to disk:
---   - write_sync: Blocking write using vim.fn.writefile
---   - write_async: Non-blocking write using vim.loop.fs_write
---
--- Both handle:
---   - Buffer validation
---   - Modified flag clearing
---   - Optional buffer unloading
---   - Error propagation via (ok, err) pattern

local M = {}

local api = vim.api

---Buffer lines joined for a plain-content write, matching vim.fn.writefile's
---own edge case: an empty buffer produces an empty (0-byte) file, not a file
---containing a single "\n".
---@param bufnr integer
---@return string
local function buffer_content(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return #lines > 0 and (table.concat(lines, "\n") .. "\n") or ""
end

---Synchronous file write. Delegates the actual write to
---lib.nvim.fs.write.to_file.
---@param bufnr integer Buffer to write
---@param filepath string Absolute path to write to
---@param unload_after boolean|nil Unload buffer after write if wasn't originally loaded
---@return boolean ok, string|nil err
function M.write_sync(bufnr, filepath, unload_after)
  if not api.nvim_buf_is_valid(bufnr) then
    return false, "Invalid buffer"
  end

  local ok, err = require("lib.nvim.fs.write.to_file")(filepath, buffer_content(bufnr))
  if not ok then
    return false, err
  end

  -- Clear modified flag (buffer now in sync with file)
  pcall(api.nvim_set_option_value, "modified", false, { buf = bufnr })

  -- Optional unload
  if unload_after then
    vim.schedule(function()
      if api.nvim_buf_is_valid(bufnr) then
        pcall(api.nvim_buf_delete, bufnr, { force = true, unload = true })
      end
    end)
  end

  return true, nil
end

---Asynchronous file write using vim.loop.fs_*
---@param bufnr integer Buffer to write
---@param filepath string Absolute path to write to
---@param unload_after boolean|nil Unload buffer after write if wasn't originally loaded
---@param callback fun(ok: boolean, err: string|nil)|nil Completion callback
---@return nil
function M.write_async(bufnr, filepath, unload_after, callback)
  callback = callback or function() end

  if not api.nvim_buf_is_valid(bufnr) then
    callback(false, "Invalid buffer")
    return
  end

  local content = buffer_content(bufnr)

  -- lib.nvim.fs.write.async already schedules its callback onto the main
  -- loop, so touching vim.api.* here (unlike the raw uv.fs_* calls this
  -- module used before) is safe without an extra vim.schedule wrapper.
  require("lib.nvim.fs.write.async")(filepath, content, function(ok, err)
    if not ok then
      callback(false, err)
      return
    end

    if api.nvim_buf_is_valid(bufnr) then
      pcall(api.nvim_set_option_value, "modified", false, { buf = bufnr })

      if unload_after then
        vim.schedule(function()
          if api.nvim_buf_is_valid(bufnr) then
            pcall(api.nvim_buf_delete, bufnr, { force = true, unload = true })
          end
        end)
      end
    end

    callback(true, nil)
  end)
end

---Batch write multiple buffers (sync or async based on strategy)
---@param write_jobs table[] Array of {bufnr, filepath, unload_after}
---@param strategy "sync"|"async" # Write strategy
---@param on_complete fun(written: string[], failed: table[])|nil Called when all writes done
---@return nil
function M.batch_write(write_jobs, strategy, on_complete)
  on_complete = on_complete or function() end

  local written = {}
  local failed = {}

  if strategy == "sync" then
    -- Synchronous: process sequentially
    for _, job in ipairs(write_jobs) do
      local ok, err = M.write_sync(job.bufnr, job.filepath, job.unload_after)

      if ok then
        table.insert(written, job.filepath)
      else
        table.insert(failed, { filepath = job.filepath, err = err })
      end
    end

    on_complete(written, failed)

  elseif strategy == "async" then
    -- Asynchronous: track completion with counter
    local total = #write_jobs
    local completed = 0

    if total == 0 then
      on_complete(written, failed)
      return
    end

    for _, job in ipairs(write_jobs) do
      M.write_async(job.bufnr, job.filepath, job.unload_after, function(ok, err)
        completed = completed + 1

        if ok then
          table.insert(written, job.filepath)
        else
          table.insert(failed, { filepath = job.filepath, err = err })
        end

        -- All done? Callback
        if completed == total then
          vim.schedule(function()
            on_complete(written, failed)
          end)
        end
      end)
    end

  else
    error(string.format("Invalid write strategy: %s (must be 'sync' or 'async')", strategy))
  end
end

return M

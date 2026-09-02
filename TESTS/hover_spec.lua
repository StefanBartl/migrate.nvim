-- TESTS/hover_spec.lua — the hover.nvim contribution.
--
-- Two things are worth pinning, and neither is "does it produce output":
--
--   1. **It answers only where there is something to say.** That is the whole
--      argument for this integration being on by default rather than opt-in:
--      `migrate_line` returns the line unchanged unless it genuinely migrates,
--      so a line with nothing deprecated in it must produce nil. If that ever
--      stops holding, the pairing becomes exactly the unasked-float noise
--      hover.nvim is otherwise built to avoid.
--   2. **It degrades to nothing without hover.nvim**, and without erroring.
--      This plugin does not depend on it; the contribution is a bonus for
--      people who have both.
--
-- hover.nvim is stubbed through `package.loaded` rather than required: this
-- suite runs with `-u NONE` and only the repo itself on the runtimepath, so a
-- real hover.nvim is not there — and pinning the *shape of the contribution*
-- is the point anyway.

---@param H table harness
return function(H)
  local hover = require("migrate.hover")

  --- Run `fn` with a fake `hover.registry`, and hand back what was registered.
  ---@param opts { positions_supported?: boolean }
  ---@param fn fun(captured: table)
  local function with_stub(opts, fn)
    local real = package.loaded["hover.registry"]
    local captured = {}
    package.loaded["hover.registry"] = {
      register = function(name, contribution)
        captured.name = name
        captured.contribution = contribution
      end,
      -- Presence of this function is how the integration tells a hover.nvim
      -- that knows `positions` from an older one that would ignore it.
      position_at = opts.positions_supported ~= false and function() end or nil,
    }
    hover._reset()
    local ok, err = pcall(fn, captured)
    package.loaded["hover.registry"] = real
    hover._reset()
    if not ok then
      error(err, 0)
    end
  end

  -- ---------------------------------------------------------------- shape --
  with_stub({}, function(captured)
    H.ok(hover.setup(), "setup reports it registered")
    H.eq(captured.name, "migrate.nvim", "registers under this plugin's name")
    H.ok(type(captured.contribution) == "table", "hands over a contribution")
    H.ok(type(captured.contribution.positions) == "table", "as positions")
    H.eq(#captured.contribution.positions, 1, "exactly one position function")
  end)

  -- --------------------------------------------------------------- answers --
  with_stub({}, function(captured)
    hover.setup()
    local answer = captured.contribution.positions[1]

    local buf = H.scratch("lua")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "local c = vim.lsp.buf_get_clients(0)",
      "local x = 1 + 1",
      "",
    })

    local deprecated = answer(buf, 1)
    H.ok(type(deprecated) == "table", "a deprecated line produces content")
    H.eq(deprecated.title, "migrate.nvim", "and says who is speaking")
    local body = table.concat(deprecated.lines, "\n")
    H.ok(body:find("get_clients({ bufnr = 0 })", 1, true) ~= nil, "naming the replacement")

    H.eq(answer(buf, 2), nil, "an ordinary line says nothing")
    H.eq(answer(buf, 3), nil, "an empty line says nothing")
    H.eq(answer(buf, 99), nil, "a row past the end says nothing")
    H.eq(answer(-1, 1), nil, "an invalid buffer says nothing")
  end)

  -- ------------------------------------------------------------ degradation --
  do
    local real = package.loaded["hover.registry"]
    package.loaded["hover.registry"] = nil
    -- Make `require` fail the way a missing plugin does.
    local real_loaders = package.preload["hover.registry"]
    package.preload["hover.registry"] = function()
      error("module 'hover.registry' not found")
    end
    hover._reset()
    H.eq(hover.setup(), false, "without hover.nvim, setup declines quietly")
    package.preload["hover.registry"] = real_loaders
    package.loaded["hover.registry"] = real
    hover._reset()
  end

  with_stub({ positions_supported = false }, function(captured)
    H.eq(hover.setup(), false, "an older hover.nvim without positions is declined")
    H.eq(captured.name, nil, "and nothing is registered into it")
  end)

  -- ------------------------------------------------------------- idempotence --
  with_stub({}, function(captured)
    H.ok(hover.setup(), "first setup registers")
    captured.name = nil
    H.ok(hover.setup(), "second setup still reports success")
    H.eq(captured.name, nil, "but does not register again")
  end)
end

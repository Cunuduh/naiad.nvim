local config = require('naiad.config')
local core = require('naiad.core')

local M = {}

---@brief Sets up the naiad plugin.
---@param user_config table? User configuration overrides.
function M.setup(user_config)
  config.options = vim.tbl_deep_extend('force', {}, config.options, user_config or {})
end

---@brief Triggers the ai prompt based on cursor position or visual selection.
---@param start_line integer? The starting line number of a visual selection (1-based).
---@param end_line integer? The ending line number of a visual selection (1-based).
function M.trigger(start_line, end_line)
  core.handle_trigger(start_line, end_line)
end

return M

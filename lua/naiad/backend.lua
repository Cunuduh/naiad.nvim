local config = require('naiad.config')
local providers = require('naiad.providers')

local M = {}

---@brief Sends a request to the configured AI provider backend.
---@param prompt string The full prompt string.
---@param callback fun(result: string?): nil Callback function with the AI response.
function M.request(prompt, callback)
  local provider_name = config.options.provider
  local provider_func = providers.providers[provider_name]

  if not provider_func then
    vim.notify('naiad: unknown provider configured: ' .. provider_name, vim.log.levels.ERROR)
    callback(nil)
    return
  end

  vim.notify('naiad: sending request via ' .. provider_name .. ' provider', vim.log.levels.INFO)

  ---@type naiad.ProviderRequestOpts
  local opts = {
    prompt = prompt,
    callback = callback,
    provider_config = config.options,
  }

  provider_func(opts)

end

return M

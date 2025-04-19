---@class naiad.Config
---@field provider string The AI provider to use ('ollama', 'openai', 'anthropic', 'gemini'). Use 'openai' for OpenAI-compatible providers (including OpenRouter).
---@field model string The model name specific to the chosen provider.
---@field api_key string? API key for the chosen provider (if required).
---@field base_url string? Custom base URL for the provider APIs (if required).
---@field context_lines_before integer Number of lines before the trigger to include as context.
---@field context_lines_after integer Number of lines after the trigger to include as context.
---@field request_timeout integer Timeout for API requests in milliseconds.
---@field max_tokens integer? Maximum tokens (or output tokens) for providers.

local M = {}

---@type naiad.Config
M.options = {
  provider = 'ollama',
  model = 'gemma3:12b',
  api_key = nil,
  base_url = nil,
  context_lines_before = 10,
  context_lines_after = 5,
  request_timeout = 30000,
  max_tokens = 1024,
}

return M

local curl = require('plenary.curl')

local M = {}

---@class naiad.ProviderRequestOpts
---@field prompt string
---@field callback fun(result: string?): nil
---@field provider_config naiad.Config

---@alias naiad.Provider fun(opts: naiad.ProviderRequestOpts): nil

---@param opts naiad.ProviderRequestOpts
local function handle_curl_response(opts, res, provider_name, response_parser)
  if not res or res.status ~= 200 then
    local err_msg = string.format('naiad: %s api request failed. status: %s', provider_name, res and res.status or 'unknown')
    vim.notify(err_msg, vim.log.levels.ERROR)
    if res and res.body then
      vim.notify('response body: ' .. res.body, vim.log.levels.ERROR)
    end
    opts.callback(nil)
    return
  end

  local ok, decoded = pcall(vim.fn.json_decode, res.body)
  if not ok or not decoded then
    vim.notify('naiad: failed to decode ' .. provider_name .. ' json response.', vim.log.levels.ERROR)
    vim.notify('response body: ' .. res.body, vim.log.levels.ERROR)
    opts.callback(nil)
    return
  end

  local result_text, err = response_parser(decoded)
  if err then
    vim.notify('naiad: error parsing ' .. provider_name .. ' response: ' .. err, vim.log.levels.ERROR)
    vim.notify('decoded response: ' .. vim.inspect(decoded), vim.log.levels.ERROR)
    opts.callback(nil)
  elseif result_text then
    opts.callback(result_text)
  else
    vim.notify('naiad: unexpected response structure from ' .. provider_name .. '.', vim.log.levels.ERROR)
    vim.notify('decoded response: ' .. vim.inspect(decoded), vim.log.levels.ERROR)
    opts.callback(nil)
  end
end

---@type naiad.Provider
local function request_ollama(opts)
  local base_url = opts.provider_config.base_url or 'http://localhost:11434'
  local url = base_url .. '/api/generate'
  local payload = {
    model = opts.provider_config.model,
    prompt = opts.prompt,
    stream = false,
  }
  curl.post(url, {
    body = vim.fn.json_encode(payload),
    headers = { ['Content-Type'] = 'application/json' },
    timeout = opts.provider_config.request_timeout,
    callback = vim.schedule_wrap(function(res)
      handle_curl_response(opts, res, 'ollama', function(decoded)
        if decoded.response and type(decoded.response) == 'string' then
          return decoded.response, nil
        elseif decoded.error then
          return nil, 'ollama api returned an error: ' .. decoded.error
        else
          return nil, 'unexpected json response structure'
        end
      end)
    end),
  })
end

---@type naiad.Provider
local function request_openai_compatible(opts)
  local api_key = opts.provider_config.api_key
  if not api_key then
    vim.notify('naiad: ' .. opts.provider_config.provider .. ' provider requires an api_key in config.', vim.log.levels.ERROR)
    opts.callback(nil)
    return
  end

  local base_url = opts.provider_config.base_url or 'https://api.openai.com/v1'
  local url = base_url .. '/chat/completions'

  local payload = {
    model = opts.provider_config.model,
    messages = { { role = 'user', content = opts.prompt } },
    stream = false,
    max_completion_tokens = opts.provider_config.max_tokens or 1024,
    max_tokens = opts.provider_config.max_tokens or 1024,
  }

  local headers = {
    ['Content-Type'] = 'application/json',
    ['Authorization'] = 'Bearer ' .. api_key,
  }

  curl.post(url, {
    body = vim.fn.json_encode(payload),
    headers = headers,
    timeout = opts.provider_config.request_timeout,
    callback = vim.schedule_wrap(function(res)
      handle_curl_response(opts, res, opts.provider_config.provider, function(decoded)
        if decoded.choices and decoded.choices[1] and decoded.choices[1].message and decoded.choices[1].message.content then
          return decoded.choices[1].message.content, nil
        elseif decoded.error then
          return nil, opts.provider_config.provider .. ' api returned an error: ' .. vim.inspect(decoded.error)
        else
          return nil, 'unexpected json response structure'
        end
      end)
    end),
  })
end

---@type naiad.Provider
local function request_anthropic(opts)
  local api_key = opts.provider_config.api_key
  if not api_key then
    vim.notify('naiad: anthropic provider requires an api_key in config.', vim.log.levels.ERROR)
    opts.callback(nil)
    return
  end

  local base_url = opts.provider_config.base_url or 'https://api.anthropic.com/v1'
  local url = base_url .. '/messages'

  local payload = {
    model = opts.provider_config.model,
    messages = { { role = 'user', content = opts.prompt } },
    max_tokens = opts.provider_config.max_tokens or 1024,
    stream = false,
  }

  curl.post(url, {
    body = vim.fn.json_encode(payload),
    headers = {
      ['Content-Type'] = 'application/json',
      ['x-api-key'] = api_key,
      ['anthropic-version'] = '2023-06-01',
    },
    timeout = opts.provider_config.request_timeout,
    callback = vim.schedule_wrap(function(res)
      handle_curl_response(opts, res, 'anthropic', function(decoded)
        if decoded.content and decoded.content[1] and decoded.content[1].text then
          return decoded.content[1].text, nil
        elseif decoded.error then
           return nil, 'anthropic api returned an error: ' .. vim.inspect(decoded.error)
        else
          return nil, 'unexpected json response structure'
        end
      end)
    end),
  })
end

---@type naiad.Provider
local function request_gemini(opts)
   local api_key = opts.provider_config.api_key
  if not api_key then
    vim.notify('naiad: gemini provider requires an api_key in config.', vim.log.levels.ERROR)
    opts.callback(nil)
    return
  end

  local base_url = opts.provider_config.base_url or 'https://generativelanguage.googleapis.com/v1beta'
  local url = string.format('%s/models/%s:generateContent?key=%s', base_url, opts.provider_config.model, api_key)

  local payload = {
    contents = {
      { parts = { { text = opts.prompt } } },
    },
    generationConfig = {
      maxOutputTokens = opts.provider_config.max_tokens or 1024,
    }
  }

  curl.post(url, {
    body = vim.fn.json_encode(payload),
    headers = {
      ['Content-Type'] = 'application/json',
    },
    timeout = opts.provider_config.request_timeout,
    callback = vim.schedule_wrap(function(res)
       handle_curl_response(opts, res, 'gemini', function(decoded)
         if decoded.candidates and decoded.candidates[1] and decoded.candidates[1].content and decoded.candidates[1].content.parts and decoded.candidates[1].content.parts[1] and decoded.candidates[1].content.parts[1].text then
           return decoded.candidates[1].content.parts[1].text, nil
         elseif decoded.error then
            return nil, 'gemini api returned an error: ' .. vim.inspect(decoded.error)
         else
           if decoded.promptFeedback and decoded.promptFeedback.blockReason then
              return nil, 'gemini request blocked: ' .. decoded.promptFeedback.blockReason
           end
           return nil, 'unexpected json response structure or empty response'
         end
       end)
    end),
  })
end


---@type table<string, naiad.Provider>
M.providers = {
  ollama = request_ollama,
  openai = request_openai_compatible, -- Handles OpenAI and compatible APIs (like OpenRouter)
  anthropic = request_anthropic,
  gemini = request_gemini,
}

return M

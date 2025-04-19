local backend = require('naiad.backend')

local M = {}

local inference_prompt_template = [[You are a writing assistant that determines the best response type for a user's command.

command: %s
context: "%s"

Based on this command and its context, determine the single best response type from the following options:
1. "socratic" - ask questions to help the writer explore their ideas
2. "contrarian" - provide a counterpoint or alternative perspective
3. "associate" - generate related/symbolic connections to the ideas
4. "style" - suggest tone shifts or stylistic improvements
5. "interpret" - offer literary interpretation of symbols or meaning
6. "emotion" - explore emotional depth or motivations

Respond with ONLY the type name in lowercase. NO explanation or other text. NO punctuation, no quotes, no extra spaces.]]

---@brief Determines the response type using the backend.
---@param command string The user's command from [!...].
---@param context string The surrounding text context.
---@param callback fun(response_type: naiad.ResponseType?): nil The callback function.
function M.get_response_type(command, context, callback)
  local prompt = string.format(inference_prompt_template, command, context:gsub('"', '\"'))

  backend.request(prompt, function(result)
    if result then
      local valid_types = {
        socratic = true, contrarian = true, associate = true,
        style = true, interpret = true, emotion = true,
      }
      local clean_result = result:match('^%s*"?([%w_]+)"?%s*%.?$')
      if clean_result then
        clean_result = clean_result:lower()
        if valid_types[clean_result] then
          callback(clean_result)
        else
          vim.notify('naiad: router received invalid type: ' .. result, vim.log.levels.WARN)
          callback(nil)
        end
      else
        vim.notify('naiad: router could not parse type from: ' .. result, vim.log.levels.WARN)
        callback(nil)
      end
    else
      callback(nil)
    end
  end)
end

return M

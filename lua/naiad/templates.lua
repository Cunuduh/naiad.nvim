local M = {}

---@alias naiad.TemplateFn fun(command: string, context: string): string

local newline_instruction = '\n\nimportant: use newlines to break up long sentences or ideas to ensure the response fits comfortably on screen without horizontal scrolling, but use them sparingly. finally, remember that the command in [!...] is the user request and not part of the actual text.'

---@type table<naiad.ResponseType, naiad.TemplateFn>
M.templates = {
  socratic = function(command, context)
    local prompt_text = command .. '\n\n' .. context
    return [[you're a thoughtful writing assistant.
given this text and request: "]] .. prompt_text:gsub('"', '\"') .. [["
respond with thought-provoking questions that help the writer explore their ideas more deeply based on the request "]] .. command .. [[".
be concise (under 50 words). follow the style of the text, including capitalization and punctuation (or lack thereof). don't introduce yourself.]] .. newline_instruction
  end,

  contrarian = function(command, context)
    local prompt_text = command .. '\n\n' .. context
    return [[you're a thoughtful contrarian writing assistant.
given this text and request: "]] .. prompt_text:gsub('"', '\"') .. [["
provide a strong, thoughtful counterpoint or alternative perspective to challenge the writer's thinking, focusing on the request "]] .. command .. [[".
be concise (under 50 words). follow the style of the text, including capitalization and punctuation (or lack thereof). don't introduce yourself.]] .. newline_instruction
  end,

  associate = function(command, context)
    local prompt_text = command .. '\n\n' .. context
    return [[you're a creative writing assistant.
given this text and request for associations/symbols: "]] .. prompt_text:gsub('"', '\"') .. [["
generate three symbolic interpretations or associations as requested by "]] .. command .. [[", encouraging the writer to make their own connections.
format as a simple dash list. be concise. follow the style of the text, including capitalization and punctuation (or lack thereof). don't introduce yourself.]] .. newline_instruction
  end,

  style = function(command, context)
    local prompt_text = command .. '\n\n' .. context
    return [[you're a writing style consultant.
given this text and request: "]] .. prompt_text:gsub('"', '\"') .. [["
suggest a specific tone shift or style change based on the request "]] .. command .. [[" that would heighten tension or improve the writing, but let the writer implement it themselves.
be concise (under 50 words). follow the style of the text, including capitalization and punctuation (or lack thereof). don't introduce yourself.]] .. newline_instruction
  end,

  interpret = function(command, context)
    local prompt_text = command .. '\n\n' .. context
    return [[you're a literary interpretation assistant.
given this text and request: "]] .. prompt_text:gsub('"', '\"') .. [["
offer a brief literary interpretation of the symbols or meaning based on the request "]] .. command .. [[" to inspire the writer's own deeper analysis.
be concise (under 50 words). follow the style of the text, including capitalization and punctuation (or lack thereof). don't introduce yourself.]] .. newline_instruction
  end,

  emotion = function(command, context)
    local prompt_text = command .. '\n\n' .. context
    return [[you're an emotional writing assistant.
given this text and request: "]] .. prompt_text:gsub('"', '\"') .. [["
explore possible emotional depths or motivations behind what's described, guided by the request "]] .. command .. [[", to help the writer develop stronger characterization.
be concise (under 50 words). follow the style of the text, including capitalization and punctuation (or lack thereof). don't introduce yourself.]] .. newline_instruction
  end,
}

setmetatable(M, { __index = M.templates })

return M

local config = require('naiad.config')
local router = require('naiad.router')
local templates = require('naiad.templates')
local backend = require('naiad.backend')
local ui = require('naiad.ui')

local M = {}

---@alias naiad.ResponseType
---| '"socratic"'
---| '"contrarian"'
---| '"associate"'
---| '"style"'
---| '"interpret"'
---| '"emotion"'

---@brief Extracts commands and context, prioritizing visual selection range if provided.
---@param start_line integer? The starting line number of a visual selection (1-based).
---@param end_line integer? The ending line number of a visual selection (1-based).
---@return table[]? triggers A list of { command: string, line_nr: integer } sorted bottom-up.
---@return string[]? context_lines Raw lines of the context block.
---@return integer? context_start_line 1-based line number of the first line in context_lines.
local function find_triggers_and_context(start_line, end_line)
  local buf_nr = vim.api.nvim_get_current_buf()
  ---@type table[]
  local triggers = {}
  ---@type string[]
  local context_lines
  ---@type integer
  local context_start_line

  if start_line and end_line and start_line ~= end_line then
    local sel_start_line = math.min(start_line, end_line)
    local sel_end_line = math.max(start_line, end_line)

    context_start_line = sel_start_line
    context_lines = vim.api.nvim_buf_get_lines(buf_nr, sel_start_line - 1, sel_end_line, false)

    for i, line_text in ipairs(context_lines) do
      local trigger_start, _, found_command = line_text:find('%[%!(.-)%]')
      if trigger_start then
        table.insert(triggers, { command = found_command, line_nr = context_start_line + i - 1 })
      end
    end

    if #triggers == 0 then
      vim.notify('naiad: no [!...] trigger found in visual selection.', vim.log.levels.WARN)
      return nil, nil, nil
    end

    table.sort(triggers, function(a, b)
      return a.line_nr > b.line_nr
    end)

  else
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_line_nr = cursor_pos[1]
    local current_line_text = vim.api.nvim_buf_get_lines(buf_nr, current_line_nr - 1, current_line_nr, false)[1]

    local trigger_start, _, found_command = current_line_text:find('%[%!(.-)%]')
    if not trigger_start then
      vim.notify('naiad: no [!...] trigger found on current line.', vim.log.levels.WARN)
      return nil, nil, nil
    end

    local ctx_start = math.max(0, current_line_nr - 1 - config.options.context_lines_before)
    local ctx_end = math.min(vim.api.nvim_buf_line_count(buf_nr), current_line_nr + config.options.context_lines_after)
    context_start_line = ctx_start + 1
    context_lines = vim.api.nvim_buf_get_lines(buf_nr, ctx_start, ctx_end, false)
    table.insert(triggers, { command = found_command, line_nr = current_line_nr })
  end

  return triggers, context_lines, context_start_line
end

---@brief Creates a context string, masking triggers other than the current one.
---@param context_lines string[] The raw context lines.
---@param context_start_line integer The 1-based line number of the first context line.
---@param current_trigger_line_nr integer The 1-based line number of the trigger to keep unmasked.
---@return string masked_context_string
local function create_masked_context(context_lines, context_start_line, current_trigger_line_nr)
  local masked_lines = {}
  for i, line in ipairs(context_lines) do
    local actual_line_nr = context_start_line + i - 1
    if actual_line_nr == current_trigger_line_nr then
      table.insert(masked_lines, line)
    else
      local masked_line = string.gsub(line, '%[%!(.-)%]', '[!...hidden...]')
      table.insert(masked_lines, masked_line)
    end
  end
  return table.concat(masked_lines, '\\n')
end

---@brief Main function to handle the trigger action(s).
---@param start_line integer? The starting line number of a visual selection (1-based).
---@param end_line integer? The ending line number of a visual selection (1-based).
function M.handle_trigger(start_line, end_line)
  local triggers, context_lines, context_start_line = find_triggers_and_context(start_line, end_line)
  if not triggers or not context_lines or not context_start_line or #triggers == 0 then
    return
  end

  local buf_nr = vim.api.nvim_get_current_buf()

  local function process_trigger(index)
    if index > #triggers then
      return
    end

    local current_trigger = triggers[index]
    local command = current_trigger.command
    local line_nr = current_trigger.line_nr
    local display_line_nr = line_nr - 1

    ui.show_loading_indicator(display_line_nr, 'identifying response type...')

    local masked_context = create_masked_context(context_lines, context_start_line, line_nr)

    router.get_response_type(command, masked_context, function(response_type)
      if not response_type then
        vim.notify('naiad: could not determine response type for trigger on line ' .. line_nr, vim.log.levels.ERROR)
        ui.hide_loading_indicator(buf_nr, display_line_nr)
        process_trigger(index + 1)
        return
      end

      vim.notify('naiad: inferred type: ' .. response_type .. ' for line ' .. line_nr, vim.log.levels.INFO)

      ui.show_loading_indicator(display_line_nr, 'loading response...')

      local template_fn = templates[response_type]
      if not template_fn then
        vim.notify('naiad: no template found for type: ' .. response_type, vim.log.levels.ERROR)
        ui.hide_loading_indicator(buf_nr, display_line_nr)
        process_trigger(index + 1)
        return
      end

      local full_prompt = template_fn(command, masked_context)

      backend.request(full_prompt, function(result)
        ui.hide_loading_indicator(buf_nr, display_line_nr)

        if not result then
          vim.notify('naiad: backend request failed for trigger on line ' .. line_nr, vim.log.levels.ERROR)
        else
          vim.notify('naiad: received response for line ' .. line_nr, vim.log.levels.INFO)
          ui.show_virtual_text(display_line_nr, result)
        end
        process_trigger(index + 1)
      end)
    end)
  end

  process_trigger(1)
end

return M

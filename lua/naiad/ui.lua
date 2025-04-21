local M = {}

local namespace_id = vim.api.nvim_create_namespace('naiad_virtual_text')
local current_virtual_texts = {} -- { buf_nr = { line_nr = extmark_id } }
local active_loading_indicators = {} -- { buf_nr = { line_nr = extmark_id } }

---@brief Hides the virtual text for a specific line.
---@param buf_nr integer
---@param line_nr integer The line number (0-based).
function M.hide_virtual_text(buf_nr, line_nr)
  if current_virtual_texts[buf_nr] and current_virtual_texts[buf_nr][line_nr] then
    local extmark_id = current_virtual_texts[buf_nr][line_nr]
    pcall(vim.api.nvim_buf_del_extmark, buf_nr, namespace_id, extmark_id)
    current_virtual_texts[buf_nr][line_nr] = nil
  end
end

---@brief Hides the loading indicator for a specific line.
---@param buf_nr integer
---@param line_nr integer The line number (0-based).
function M.hide_loading_indicator(buf_nr, line_nr)
  if active_loading_indicators[buf_nr] and active_loading_indicators[buf_nr][line_nr] then
    local extmark_id = active_loading_indicators[buf_nr][line_nr]
    pcall(vim.api.nvim_buf_del_extmark, buf_nr, namespace_id, extmark_id)
    active_loading_indicators[buf_nr][line_nr] = nil
  end
end

---@brief Shows a static loading indicator below a specific line.
---@param line_nr integer The line number (0-based) to attach the indicator below.
---@param text string The text to display in the loading indicator.
function M.show_loading_indicator(line_nr, text)
  local buf_nr = vim.api.nvim_get_current_buf()

  M.hide_virtual_text(buf_nr, line_nr)
  M.hide_loading_indicator(buf_nr, line_nr)

  local loading_text = text or 'loading...'
  local extmark_id = vim.api.nvim_buf_set_extmark(buf_nr, namespace_id, line_nr, 0, {
    virt_lines = { { { loading_text, 'Comment' } } },
    hl_mode = 'combine',
    virt_lines_above = false,
  })

  if not active_loading_indicators[buf_nr] then
    active_loading_indicators[buf_nr] = {}
  end
  active_loading_indicators[buf_nr][line_nr] = extmark_id
end


---@brief Displays virtual text below a specific line.
---@param line_nr integer The line number (0-based) to attach the text below.
---@param text string The text content to display.
function M.show_virtual_text(line_nr, text)
  local buf_nr = vim.api.nvim_get_current_buf()
  M.hide_virtual_text(buf_nr, line_nr)
  M.hide_loading_indicator(buf_nr, line_nr)

  local lines = vim.split(text, '\n', { trimempty = true })
  local virt_lines_data = {}
  for _, line in ipairs(lines) do
    table.insert(virt_lines_data, { { line, 'Comment' } })
  end

  if #virt_lines_data > 0 then
    local extmark_id = vim.api.nvim_buf_set_extmark(buf_nr, namespace_id, line_nr, 0, {
      virt_lines = virt_lines_data,
      hl_mode = 'combine',
    })

    if not current_virtual_texts[buf_nr] then
      current_virtual_texts[buf_nr] = {}
    end
    current_virtual_texts[buf_nr][line_nr] = extmark_id
  end
end

---@brief Clears virtual texts and loading indicators created by this plugin.
---@param start_line? integer The starting line number (1-based) of the range.
---@param end_line? integer The ending line number (1-based) of the range.
function M.clear_virtuals(start_line, end_line)
  local buf_nr = vim.api.nvim_get_current_buf()

  if start_line and end_line then
    local start_line_0 = start_line - 1
    local end_line_0 = end_line - 1
    vim.api.nvim_buf_clear_namespace(buf_nr, namespace_id, start_line_0, end_line_0 + 1)

    if current_virtual_texts[buf_nr] then
      for line = start_line_0, end_line_0 do
        current_virtual_texts[buf_nr][line] = nil
      end
    end
    if active_loading_indicators[buf_nr] then
      for line = start_line_0, end_line_0 do
        active_loading_indicators[buf_nr][line] = nil
      end
    end
    vim.notify('naiad: cleared virtual text in range ' .. start_line .. '-' .. end_line .. '.', vim.log.levels.INFO)
  end
end

---@brief Checks if virtual text managed by naiad exists for a specific line.
---@param buf_nr integer The buffer number.
---@param line_nr integer The line number (0-based).
---@return boolean True if virtual text exists, false otherwise.
function M.does_virtual_text_exist(buf_nr, line_nr)
  if current_virtual_texts[buf_nr] and current_virtual_texts[buf_nr][line_nr] then
    local extmark_id = current_virtual_texts[buf_nr][line_nr]
    local extmark_info = vim.api.nvim_buf_get_extmark_by_id(buf_nr, namespace_id, extmark_id, {})
    return extmark_info ~= nil and type(extmark_info) == 'table' and #extmark_info > 0
  end
  return false
end

vim.api.nvim_create_autocmd({'BufHidden', 'BufDelete'}, {
  pattern = '*',
  callback = function(args)
    local buf_nr = args.buf
    if current_virtual_texts[buf_nr] then
      pcall(vim.api.nvim_buf_clear_namespace, buf_nr, namespace_id, 0, -1)
      current_virtual_texts[buf_nr] = nil
    end
    if active_loading_indicators[buf_nr] then
      active_loading_indicators[buf_nr] = nil
    end
  end,
})


return M

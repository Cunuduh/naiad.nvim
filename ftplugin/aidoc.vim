" Vim filetype plugin file
" Language: aidoc

" Set filetype-specific options if needed
" For example:
" setlocal spell spelllang=en_us
" setlocal wrap

" You might want to map the trigger command locally
nnoremap <buffer> <silent> <leader>ai :AIPromptTrigger<CR>
vnoremap <buffer> <silent> <leader>ai :AIPromptTrigger<CR> " Add visual mode mapping if supported later

" Map clear command
nnoremap <buffer> <silent> <leader>ac :AIClearVirtuals<CR>


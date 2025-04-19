" naiad.nvim plugin loader

if exists('g:loaded_naiad')
  finish
endif
let g:loaded_naiad = 1

command! -nargs=0 -range AIPromptTrigger lua require('naiad').trigger(<line1>, <line2>)
command! -nargs=0 -range AIClearVirtuals lua require('naiad.ui').clear_virtuals(<line1>, <line2>)

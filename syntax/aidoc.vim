" Vim syntax file
" Language: aidoc (AI Writer Document)
" Maintainer: Glae Alejo
" Latest Revision: 2025-04-17

if exists("b:current_syntax")
  finish
endif

" Inherit from markdown syntax if available
runtime! syntax/markdown.vim
unlet b:current_syntax

" Highlight AI Writer triggers [!...]
syn region naiadTrigger start="\[!" end="\]" contains=naiadCommand containedin=markdownCode,markdownCodeBlock,@NoSpell
syn match naiadCommand "[^]]*" contained containedin=naiadTrigger

" Define highlight links
hi def link naiadTrigger SpecialComment
hi def link naiadCommand Function

let b:current_syntax = "aidoc"

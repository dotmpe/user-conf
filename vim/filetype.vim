
if exists("did_load_filetypes")
  finish
endif

" set filetype based on name, overrides $VIMRUNTIME/filetype.vim
"
augroup filetypedetect
  au! BufRead,BufNewFile *.u-c      setfiletype user-config
  au! BufRead,BufNewFile *.bats     setfiletype bats
augroup END


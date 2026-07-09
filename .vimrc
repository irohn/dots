" Globals
let mapleader = " "
let maplocalleader = " "

" Options
set cursorline
set clipboard=unnamedplus
set hlsearch
set ignorecase
set mouse=a
set number
set smartcase
set undofile
set splitbelow
set splitright
set termguicolors
set timeoutlen=300
set ttimeout
set ttimeoutlen=10
set virtualedit=block
set wildmenu
set wildmode=longest:full,full

set wildignore+=./,../
set path+=**

syntax on
filetype plugin indent on

" Keymaps
vnoremap > >gv
vnoremap < <gv

tnoremap <Esc><Esc> :nohlsearch<CR> <C-\><C-n>
tnoremap <C-w> <C-\><C-n><C-w>

nnoremap - :Explore<CR>

" Yank Highlight
augroup irohn_highlight_on_yank
  autocmd!
  autocmd TextYankPost * call s:highlight_yank()
augroup END

function! s:highlight_yank() abort
  if v:event.operator !=# 'y'
    return
  endif

  let l:start = getpos("'[")
  let l:end = getpos("']")
  let l:pos = []

  for lnum in range(l:start[1], l:end[1])
    let l:col = lnum == l:start[1] ? l:start[2] : 1
    let l:last = lnum == l:end[1] ? l:end[2] : col([lnum, '$'])
    call add(l:pos, [lnum, l:col, max([1, l:last - l:col + 1])])
  endfor

  silent! let l:id = matchaddpos('IncSearch', l:pos[:200], 10)
  call timer_start(150, {-> execute('silent! call matchdelete(' . l:id . ')')})
endfunction

" persistent colorscheme
let s:state_dir = expand('~/.vim/state')
let s:saved_colorscheme_file = s:state_dir . '/last_colorscheme'

if !isdirectory(s:state_dir)
  call mkdir(s:state_dir, 'p')
endif

if !filereadable(s:saved_colorscheme_file)
  call writefile(['default'], s:saved_colorscheme_file)
endif

augroup PersistentColorscheme
  autocmd!

  autocmd VimEnter * call s:load_colorscheme()
  autocmd ColorScheme * call s:save_colorscheme()
augroup END

function! s:load_colorscheme() abort
  let l:saved_colorscheme = get(readfile(s:saved_colorscheme_file), 0, 'default')
  let g:saved_colorscheme = l:saved_colorscheme

  try
    execute 'colorscheme ' . l:saved_colorscheme
  catch
  endtry
endfunction

function! s:save_colorscheme() abort
  call writefile([get(g:, 'colors_name', 'default')], s:saved_colorscheme_file)
endfunction

" Force block cursor in all modes
let &t_SI = "\e[1 q"
let &t_SR = "\e[1 q"
let &t_EI = "\e[1 q"

augroup force_block_cursor
  autocmd!
  autocmd VimEnter,VimLeave * silent! let &t_EI = "\e[2 q"
augroup END

" netrw
let g:netrw_banner = 0
let g:netrw_browse_split = 0
let g:netrw_winsize = 25

nnoremap <silent> - :Explore %:p:h<CR>

augroup netrw_settings
  autocmd!
  autocmd FileType netrw nnoremap <silent><buffer> - :Explore ..<CR>
augroup END

" Terminal
augroup terminal_settings
  autocmd!
  autocmd TerminalOpen * call s:terminal_settings()
augroup END

function! s:terminal_settings() abort
  setlocal nonumber
  setlocal norelativenumber
  setlocal signcolumn=no
  setlocal nocursorline
  setlocal bufhidden=hide
  startinsert
endfunction

" vim: ts=2 sts=2 sw=2 et

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Copyright 2012 Mike Dreves
"
" All rights reserved. This program and the accompanying materials
" are made available under the terms of the Eclipse Public License v1.0
" which accompanies this distribution, and is available at:
"
"     http://opensource.org/licenses/eclipse-1.0.php
"
" By using this software in any fashion, you are agreeing to be bound
" by the terms of this license. You must not remove this notice, or any
" other, from this software. Unless required by applicable law or agreed
" to in writing, software distributed under the License is distributed
" on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
" either express or implied.
"
" @author Mike Dreves
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:results_window_height = 6


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Vim wrapper around scaladoc.Search
"
" Args:
"   keywords: Keywords to search for.
"   a:1: Name of function to call to open URL (default: 'scaladoc#OpenUrl')
"   a:2: Name of temporary buffer (default: 'scaladoc_matches')
"   a:3: Temp win pos 'left', 'right', 'top', 'bottom' (default: 'bottom')
"   a:4: Temp win width (left/right) or height (top/bottom) (default: 6)
function! scaladoc#Search(keywords, ...) abort " {{{
  if a:keywords == ''
    return scaladoc#util#EchoError('Missing keywords')
  endif

  let cur_file = expand('%:p')
  let matches = []

python << PYTHON_CODE
import vim
import scaladoc

cur_file = vim.eval('cur_file')
keywords = vim.eval('a:keywords').split(',')
scaladoc_paths = vim.eval('g:scaladoc_paths').split(',')
cache_dir = vim.eval('g:scaladoc_cache_dir')
cache_ttl = int(vim.eval('g:scaladoc_cache_ttl'))

matches = scaladoc.Search(
    cur_file, keywords, scaladoc_paths, cache_dir, cache_ttl)

for match in matches:
  vim.command('call add(matches, "%s")' % match.strip())
PYTHON_CODE

  let opener = a:0 > 0 ? a:1 : "scaladoc#OpenUrl"

  if len(matches) == 0
    return scaladoc#util#EchoError('No matches found')
  elseif len(matches) == 1
    call call(opener, [matches[0]])
  else
    let buf_name = a:0 > 1 ? a:2 : "scaladoc_matches"
    let win_pos = a:0 > 2 ? a:3 : "bottom"
    let win_size = a:0 > 3 ? a:4 : s:results_window_height

    call scaladoc#util#OpenReadonlyWindow(
        \ buf_name, matches, win_pos, win_size)

    let w:opener = opener

    " map q to close window
    nnoremap <silent> <buffer> q
      \ :call ide#util#CloseWindow(bufname(''))<CR>

    " map enter to open URL under cursor
    nnoremap <silent> <buffer> <cr>
      \ :call <SID>SelectUrlAndCloseWindow(
      \     getline('.'), bufname(''), w:opener)<CR>

    augroup scaladoc_search_augroup
      autocmd! BufWinLeave <buffer>
      call scaladoc#util#SelectWindow(cur_file)
    augroup END

    call scaladoc#util#SelectWindow(buf_name)
  endif
endfunction " }}}


" Vim wrapper around scaladoc.OpenUrl
function! scaladoc#OpenUrl(url) abort " {{{
  if a:url == ''
    return scaladoc#util#EchoError('Missing URL')
  endif

python << PYTHON_CODE
import vim
import scaladoc

url = vim.eval('a:url')
scaladoc.OpenUrl(url)
PYTHON_CODE
endfunction " }}}


" Helper function to select URL and close the current window
"
" Args:
"   url: Url to open.
"   buf_name: Name of buffer holding match results.
"   opener: Name of function to call to open URL.
function! s:SelectUrlAndCloseWindow(url, buf_name, opener) abort " {{{
  call call(a:opener, [a:url])
  call scaladoc#util#CloseWindow(a:buf_name)
endfunction " }}}

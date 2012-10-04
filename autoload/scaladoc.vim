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

let s:results_window_height = 6

" Vim wrapper around scaladoc.Search
function! scaladoc#Search(keywords) "{{{
  if a:keywords == ''
    echoerr 'Missing keywords'
    return
  endif

  let l:cur_file = expand('%:p')
  let l:matches = []

python << PYTHON_CODE
import vim
import scaladoc

cur_file = vim.eval('l:cur_file')
keywords = vim.eval('a:keywords').split(',')
scaladoc_paths = vim.eval('g:scaladoc_paths').split(',')
cache_dir = vim.eval('g:scaladoc_cache_dir')
cache_ttl = int(vim.eval('g:scaladoc_cache_ttl'))

matches = scaladoc.Search(
    cur_file, keywords, scaladoc_paths, cache_dir, cache_ttl)

for match in matches:
  vim.command('call add(l:matches, "%s")' % match.strip())
PYTHON_CODE

  if len(l:matches) == 0
    echoerr 'No matches found'
  elseif len(l:matches) == 1
    call scaladoc#OpenUrl(l:matches[0])
  else
    call scaladoc#util#OpenReadonlyWindow(
        \ 'scaladoc_matches', l:matches, s:results_window_height)
    " if enter hit in new window open URL under cursor
    nnoremap <silent> <buffer> <cr>
      \ :call <SID>SelectUrlAndCloseWindow(getline('.'), 'scaladoc_matches')<CR>
    augroup readonly_window
      autocmd! BufWinLeave <buffer>
      call scaladoc#util#SelectWindow(l:cur_file)
    augroup END
    call scaladoc#util#SelectWindow('scaladoc_matches')
  endif
endfunction "}}}

" Vim wrapper around scaladoc.OpenUrl
function! scaladoc#OpenUrl(url) "{{{
  if a:url == ''
    echoerr 'Missing URL'
  endif

python << PYTHON_CODE
import vim
import scaladoc

url = vim.eval('a:url')
scaladoc.OpenUrl(url)
PYTHON_CODE
endfunction "}}}

" Helper function to select URL and close the current window
function! s:SelectUrlAndCloseWindow(url, window_name)
  call scaladoc#OpenUrl(a:url)
  call scaladoc#util#CloseWindow(a:window_name)
endfunction

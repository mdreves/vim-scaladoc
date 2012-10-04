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


" Opens named readonly window for displaying data in.
"
" Args:
"   name: Window name
"   data: Data to display into window
"   height: Height of window
function! scaladoc#util#OpenReadonlyWindow(name, data, height) " {{{
  let prev_winnr = winnr()
  let prev_file = expand('%:p')

  if bufwinnr(a:name) == -1
    silent! noautocmd exec 'botright ' . a:height . ' sview ' .
        \ escape(a:name, ' []')
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal winfixheight
    setlocal nobuflisted
    setlocal noswapfile
    silent doautocmd WinEnter
  else
    let bufwinnr = bufwinnr(a:name)
    if bufwinnr != winnr()
      exec bufwinnr . 'winc w'
      silent doautocmd WinEnter
    endif
  endif

  call scaladoc#util#ClearWindow(a:name)

  setlocal noreadonly
  setlocal modifiable
  call append(1, a:data)
  silent 1,1delete _
  retab
  call cursor(1, 1)
  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified

  silent doautocmd BufEnter

  if prev_file != expand('%:p')
    let b:prev_winnr = prev_winnr
    let b:prev_file = prev_file

    augroup readonly_window
      autocmd! BufWinLeave <buffer>
      exec 'autocmd BufWinLeave <buffer> ' .
        \ 'call scaladoc#util#SelectWindow("' . escape(b:prev_file, '\') . '")'
        \ ' | doautocmd BufEnter'
    augroup END
  endif
endfunction " }}}

" Selects named window
"
" Args:
"   name: Window name
function! scaladoc#util#SelectWindow(name) "{{{
  let bufwinnr = bufwinnr(bufnr('^' . a:name . '$'))
  if bufwinnr != -1
    exec bufwinnr . "winc w"
    return 1
  endif
  return 0
endfunction " }}}

" Closes named window
"
" Args:
"   name: Window name
function! scaladoc#util#CloseWindow(name) "{{{
  let bufwinnr = bufwinnr(bufnr('^' . a:name . '$'))
  if bufwinnr != -1
    exec 'bd ' . bufwinnr
    return 1
  endif
  return 0
endfunction " }}}


" Clears named window
"
" Args:
"   name: Window name
function! scaladoc#util#ClearWindow(name) "{{{
  if bufwinnr(a:name) != -1
    let winnr = winnr()
    exec bufwinnr(a:name) . 'winc w'
    setlocal noreadonly
    setlocal modifiable
    silent 1,$delete _
    exec winnr . 'winc w'
  endif
endfunction " }}}

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
" Window/Buffer Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Opens named readonly window for displaying data in.
"
" Args:
"   buf_name: Buffer name.
"   data: Data to display into window.
"   pos : 'left, 'right', 'top', 'bottom'
"   size: width (left/right) or height (top/bottom)
function! scaladoc#util#OpenReadonlyWindow(
    \ buf_name, data, pos, size) abort " {{{
  let prev_win_num = winnr()
  let prev_file = expand("%:p")

  if bufwinnr(a:buf_name) == -1
    let modifier = scaladoc#util#GetVimOpenModifiers(a:pos)
    exec modifier . " " . a:size . " sview " . escape(a:buf_name, " []")

    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal winfixheight
    setlocal nobuflisted
    setlocal noswapfile
    silent doautocmd WinEnter
  else
    let buf_win_num = bufwinnr(a:buf_name)
    if buf_win_num != winnr()
      exec buf_win_num . " wincmd w"
      silent doautocmd WinEnter
    endif
  endif

  call scaladoc#util#ClearWindow(a:buf_name)

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

  if prev_file != expand("%:p")
    let b:prev_win_num = prev_win_num
    let b:prev_file = prev_file

    augroup scaladoc_readonly_window_augroup
      autocmd! BufWinLeave <buffer>
      exec "autocmd BufWinLeave <buffer> " .
        \ 'call scaladoc#util#SelectWindow(
        \      "' . escape(b:prev_file, '\') . '")' .
        \ " | doautocmd BufEnter"
    augroup END
  endif
endfunction " }}}


" Closes first window associated with named buffer.
"
" Args:
"   buf_name: Buffer name.
"
" Returns:
"   1 if selected, 0 if not found.
function! scaladoc#util#CloseWindow(buf_name) "{{{
  let buf_win_num = bufwinnr(bufnr("^" . a:buf_name . "$"))
  if buf_win_num != -1
    exec buf_win_num . " wincmd w"
    exec "q"
    return 1
  endif
  return 0
endfunction " }}}


" Selects first window associated with named buffer.
"
" Args:
"   buf_name: Buffer name.
"
" Returns:
"   1 if selected, 0 if not found.
function! scaladoc#util#SelectWindow(buf_name) "{{{
  let buf_win_num = bufwinnr(bufnr("^" . a:buf_name . "$"))
  if buf_win_num != -1
    exec buf_win_num . " wincmd w"
    return 1
  endif
  return 0
endfunction " }}}


" Clears first window associated with named buffer.
"
" Args:
"   buf_name: Buffer name.
"
" Returns:
"   1 if selected, 0 if not found.
function! scaladoc#util#ClearWindow(buf_name) "{{{
  if bufwinnr(a:buf_name) != -1
    let win_num = winnr()
    exec bufwinnr(a:buf_name) . " wincmd w"
    setlocal noreadonly
    setlocal modifiable
    silent 1,$delete _
    exec win_num . " wincmd w"
  endif
endfunction " }}}


" Gets VIM open modifier given a view position.
"
" These modifiers not only determine horizontal vs vertical layout, but ensure
" that the opening takes into account the entire visual space and not just
" the current VIM window (e.g. 'botright' will " open a view at the bottom
" that uses the full width of the main view).
"
" Args:
"   pos: View position ('top', 'left', 'right', 'bottom')
"
" Returns:
"   'botright', 'topleft', 'leftabove', or 'rightbelow'
function! scaladoc#util#GetVimOpenModifiers(pos) abort " {{{
  if a:pos ==# "left"
    return "vertical topleft"
  elseif a:pos ==# "right"
    return "vertical botright"
  elseif a:pos ==# "bottom"
    return "botright"
  elseif a:pos ==# "top"
    return "topleft"
  else
    return ""
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Error Utils
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Displays error message.
"
" Args:
"   msg: Warning messaage
function! scaladoc#util#EchoError(msg) abort " {{{
  echohl ErrorMsg
  echomsg a:msg
  echohl None
  let v:warningmsg = a:msg
endfunction " }}}



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

let s:scaladoc_version = "0.1"

" Check if loaded
if exists("g:loaded_scaladoc") || &cp
  finish
endif

" User disabled
if exists("g:scaladoc") && g:scaladoc == 0
 finish
endif

let g:loaded_scaladoc = s:scaladoc_version

" Check python support
if !has('python')
  echoerr expand("<sfile>:t") . " Vim must be compiled with +python."
  finish
endif

let s:keepcpo = &cpo
set cpo&vim

" Update python path
python << PYTHON_CODE
import os
import sys
import vim

cwd = vim.eval('getcwd()')
pylibs_path = os.path.join(os.path.dirname(os.path.dirname(
    vim.eval("expand('<sfile>:p')"))), 'pylibs')

sys.path = [pylibs_path, cwd] + sys.path
PYTHON_CODE

" Default variables
if !exists("g:scaladoc_cache_dir")
  let g:scaladoc_cache_dir = ''  " Use python default
endif
if !exists("g:scaladoc_cache_ttl")
  let g:scaladoc_cache_ttl = 15
endif
if !exists("g:scaladoc_paths")
  let g:scaladoc_paths = ''
endif

if !exists(":ScalaDoc")
  command -buffer -nargs=+ ScalaDoc :call scaladoc#Search('<f-args>')
endif

let &cpo = s:keepcpo
unlet s:keepcpo

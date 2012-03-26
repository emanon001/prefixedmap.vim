" Vim additional indent settings: vim/prefixmap - indent prefixmap commands
" Version: 0.0.1
" Author:  emanon001 <emanon001@gmail.com>
" License: DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2 {{{
"     This program is free software. It comes without any warranty, to
"     the extent permitted by applicable law. You can redistribute it
"     and/or modify it under the terms of the Do What The Fuck You Want
"     To Public License, Version 2, as published by Sam Hocevar. See
"     http://sam.zoy.org/wtfpl/COPYING for more details.
" }}}

let &l:indentexpr = 'GetVimPrefixMapIndent(' . &l:indentexpr . ')'
setlocal indentkeys+==PrefixMapEnd

if exists('*GetVimPrefixMapIndent')
  finish
endif

function GetVimPrefixMapIndent(base_indent)
  let indent = a:base_indent

  let base_lnum = prevnonblank(v:lnum - 1)
  let line = getline(base_lnum)
  if 0 <= match(line, '\(^\||\)\s*\(PrefixMapStart\)\>')
    let indent += &l:shiftwidth
  endif

  if 0 <= match(getline(v:lnum), '\(^\||\)\s*\(PrefixMapEnd\)\>')
    let indent -= &l:shiftwidth
  endif

  return indent
endfunction

" __END__
" vim: foldmethod=marker

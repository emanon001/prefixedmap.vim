" The definition of key mapping using a prefix key is supported.
" Version: 0.0.1
" Author:  emanon001 <emanon001@gmail.com>
" License: DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2 {{{
"     This program is free software. It comes without any warranty, to
"     the extent permitted by applicable law. You can redistribute it
"     and/or modify it under the terms of the Do What The Fuck You Want
"     To Public License, Version 2, as published by Sam Hocevar. See
"     http://sam.zoy.org/wtfpl/COPYING for more details.
" }}}

" Prologue {{{1

scriptencoding utf-8

let s:save_cpoptions = &cpoptions
set cpoptions&vim




" Constants {{{1

let s:TRUE = 1
let s:FALSE = !s:TRUE
let s:PLUGIN_NAME = expand('<sfile>:t:r')

lockvar! s:TRUE s:FALSE s:PLUGIN_NAME




" Variables {{{1

let s:prefixedmap = {}


" Preparation of initialization. {{{2

function! s:prefixedmap.__init__() " {{{3
  call self.__init_variables__()
endfunction

function! s:prefixedmap.__init_variables__() " {{{3
  call extend(self, {
        \  'is_loaded': s:FALSE,
        \  'prefix_key': ''
        \ })
endfunction




" Interface {{{1

function! prefixedmap#load() " {{{2
  if !s:prefixedmap.is_loaded
    call s:prefixedmap.create_commands()
    let s:prefixedmap.is_loaded = s:TRUE
  endif
endfunction




" Core {{{1


function! s:prefixedmap.create_commands() " {{{2
  call self.create_block_commands()
  call self.create_map_commands()
endfunction


function! s:prefixedmap.create_block_commands() " {{{2
  command! -nargs=1 PrefixedMapStart
        \ call s:prefixedmap.set_prefix_key(<q-args>, expand('<sfile>'))
  command! -nargs=0 PrefixedMapEnd
        \ call s:prefixedmap.reset_prefix_key()
endfunction

function! s:prefixedmap.set_prefix_key(prefix_key, sfile) " {{{3
  let actual_prefix_key = a:prefix_key
  if a:prefix_key =~# '^<SID>'
    let actual_prefix_key = s:path_to_sid(a:sfile) . matchstr(a:prefix_key, '<SID>\zs.*$')
  endif
  let self.prefix_key = actual_prefix_key
endfunction

function! s:prefixedmap.reset_prefix_key() " {{{3
  let self.prefix_key = ''
endfunction


function! s:prefixedmap.create_map_commands() " {{{2
  let base_commands = ['map', 'nmap', 'vmap', 'xmap', 'smap', 'omap',
        \              'imap', 'lmap', 'cmap']
  let command_prefix = 'P'
  for command in base_commands
    let bang = command ==# 'map' ? '-bang' : ''
    " Map command.
    execute printf('command! -nargs=+ %s %s%s
          \         call s:prefixedmap.create_key_mapping(''%s'',''<bang>'', <q-args>)',
          \         bang, command_prefix, command, command)
    " Nore-map command.
    let nore_command = matchstr(command, '^\zs.*\zemap!\=') . 'noremap'
    execute printf('command! -nargs=+ %s %s%s
          \         call s:prefixedmap.create_key_mapping(''%s'',''<bang>'', <q-args>)',
          \         bang, command_prefix, nore_command, nore_command)
  endfor
endfunction


function! s:prefixedmap.create_key_mapping(command_name, bang, command_arg) " {{{2
  if self.prefix_key == ''
    echohl WarningMsg | echomsg s:create_error_message(':PrefixedMapStart {prefix-key} is not executed.') | echohl None
    return
  endif

  let map_arguments_pattern = '\%(' .
        \ join(['<buffer>', '<silent>', '<special>', '<script>', '<expr>', '<unique>'], '\|') .
        \ '\)'
  let _ = matchlist(a:command_arg, '^\(\%('. map_arguments_pattern . '\s*\)*\)\(.*\)$')
  execute a:command_name . a:bang _[1]
        \ self.prefix_key . _[2]
endfunction




" Misc {{{1

function! s:create_error_message(message) " {{{2
  return printf('%s: %s', s:PLUGIN_NAME, a:message)
endfunction


function! s:path_to_sid(path) "{{2
  let snr_infos = s:parse_script_names()
  call filter(snr_infos, 'expand(v:val.path) ==# expand(a:path)')

  if empty(snr_infos) "{{2
    throw s:create_error_message('Could not convert the <SID>.')
  endif
  return printf('<SNR>%d_', snr_infos[0].snr)
endfunction


function! s:parse_script_names() "{{2
  redir => _
  silent! scriptnames
  redir END

  let infos = split(_, '\n')
  let infos = map(infos, 'matchlist(v:val, ''^\s*\(\d*\):\s*\(.*\)$'')[1:2]')
  return map(infos, '{"snr": v:val[0], "path": v:val[1]}')
endfunction


" Init {{{1

call s:prefixedmap.__init__()




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker

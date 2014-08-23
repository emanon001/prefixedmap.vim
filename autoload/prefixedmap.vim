" The definition of key mapping using a prefix key is supported.
" Version: 0.1.0
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
        \  'prefix_key': '',
        \  'sid': ''
        \ })
endfunction




" Interface {{{1

function! prefixedmap#load() " {{{2
  if !s:prefixedmap.loaded_p()
    call s:prefixedmap.load()
  endif
endfunction




" Core {{{1

function! s:prefixedmap.load() " {{{2
  call self.create_commands()
  let self.is_loaded = s:TRUE
endfunction


function! s:prefixedmap.create_commands() " {{{2
  call self.create_block_commands()
  call self.create_map_commands()
endfunction


function! s:prefixedmap.create_block_commands() " {{{2
  command! -nargs=1 PrefixedMapBegin
        \ call s:prefixedmap.begin(<q-args>, expand('<sfile>'))
  command! -nargs=0 PrefixedMapEnd
        \ call s:prefixedmap.end()
endfunction

function! s:prefixedmap.begin(prefix_key, sfile) " {{{3
  try
    let self.sid = s:path_to_sid(a:sfile)
  catch /^prefixedmap: Convert/
    call s:print_error(v:exception)
    return
  catch /^prefixedmap: Argument/
    " TODO: Run on the command line.
    call s:print_error('Can not be used from the command line.')
    return
  endtry
  let self.prefix_key = s:expand_sid(a:prefix_key, self.sid)
endfunction

function! s:prefixedmap.end() " {{{3
  let self.prefix_key = ''
  let self.sid = ''
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
    call s:print_error(':PrefixedMapBegin {prefix-key} is not executed.')
    return
  endif

  try
    let [map_arguments, lhs, rhs] = self.parse_command_arg(a:command_arg)
  catch /^prefixedmap: Parse/
    call s:print_error([v:exception, 'command is "' . a:command_name . a:bang . ' ' . a:command_arg . '"'])
    return
  endtry
  execute a:command_name . a:bang map_arguments lhs rhs
endfunction


function! s:prefixedmap.parse_command_arg(command_arg) " {{{2
  let map_arguments_pattern = '\%(' .
        \ join(['<buffer>', '<silent>', '<special>', '<script>', '<expr>', '<unique>'], '\|') .
        \ '\)'
  let [map_arguments, _lhs, _rhs] = matchlist(a:command_arg,
        \ '^\(\%('. map_arguments_pattern . '\s*\)*\)\(\%(\%(\%x16 \)\|\S\)*\)\s*\(.*\)$')[1:3]

  if _lhs == '' || (_lhs !=# '<Nop>' && _rhs == '')
    " Invalid command arg.
    throw s:create_exception('Parse', 'Invalid command arg.')
  elseif _lhs ==# '<Nop>' && _rhs == ''
    " {map-arguments} <Nop>
    " -> {map-arguments} {prefix-key} <Nop>
    let lhs = self.prefix_key
    let rhs = '<Nop>'
  else
    " {map-arguments} {lhs} {rhs}
    " -> {map-arguments} {prefix-key}{lhs} {rhs}
    let lhs = self.prefix_key . _lhs
    let rhs = s:expand_sid(_rhs, self.sid)
  endif
  return [map_arguments, lhs, rhs]
endfunction


function! s:prefixedmap.loaded_p() " {{{2
  return self.is_loaded
endfunction




" Misc {{{1

function! s:create_exception(type, message) " {{{2
  return printf('%s: %s: %s', s:PLUGIN_NAME, a:type, a:message)
endfunction


function! s:print_error(message) " {{{2
  let head_messages = [printf('%s: %s', s:PLUGIN_NAME, 'The error occurred.')]
  let main_messages = type(a:message) == type([]) ? copy(a:message) : [a:message]
  " Remove prefix string of exception.
  call map(main_messages,
        \  'matchstr(v:val, ''^\%('' . s:PLUGIN_NAME . '': [^:]*:\)\=\s*\zs.*'')')

  for _ in head_messages + main_messages
    echohl WarningMsg | echomsg _ | echohl None
  endfor
endfunction


function! s:path_to_sid(path) "{{{2
  if a:path =~ '^\s*$'
    throw s:create_exception('Argument', 'File path is empty.')
  endif

  let snr_infos = s:parse_script_names()
  call filter(snr_infos, 'expand(v:val.path) ==# expand(a:path)')
  if empty(snr_infos)
    throw s:create_exception('Convert', 'Could not convert from file path "' . a:path . '" to SID.')
  endif
  return printf('<SNR>%d_', snr_infos[0].snr)
endfunction


function! s:parse_script_names() "{{{2
  redir => _
  silent! scriptnames
  redir END

  let infos = split(_, '\n')
  let infos = map(infos, 'matchlist(v:val, ''^\s*\(\d*\):\s*\(.*\)$'')[1:2]')
  return map(infos, '{"snr": v:val[0], "path": v:val[1]}')
endfunction


function! s:expand_sid(val, sid) " {{{2
  " XXX:
  return substitute(a:val, '<SID>', a:sid, 'g')
endfunction




" Init {{{1

call s:prefixedmap.__init__()




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker

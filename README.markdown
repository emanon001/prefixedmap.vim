# prefixedmap.vim
Vim plugin: The definition of key mapping using a prefix key is supported.

## Usage

```vim
call prefixedmap#load()
 
" PrefixedMapBegin {prefix-key}
PrefixedMapBegin <SID>[Tag]
  " P{map-command} {map-arguments} <Nop>
  " -> {map-command} {map-arguments} {prefix-key} <Nop>

  Pnnoremap <Nop>
  " -> nnoremap <SID>[Tag] <Nop>


  " P{map-command} {map-arguments} {lhs} {rhs}
  " -> {map-command} {map-arguments} {prefix-key}{lhs} {rhs}

  Pnnoremap <silent> <Space> <C-]>
  " -> nnoremap <silent> <SID>[Tag]<Space> <C-]>
  Pnnoremap <silent> j :<C-u>tag<CR>
  Pnnoremap <silent> k :<C-u>pop<CR>
  Pnnoremap <silent> s :<C-u>tags<CR>
  Pnnoremap <silent> n :tnext<CR>
  Pnnoremap <silent> p :tprevious<CR>
  Pnnoremap <silent> f :tfirst<CR>
  Pnnoremap <silent> l :tlast<CR>
PrefixedMapEnd

nnoremap <script> t <SID>[Tag]
```

## LICENSE

[WTFPL](http://sam.zoy.org/wtfpl/COPYING)

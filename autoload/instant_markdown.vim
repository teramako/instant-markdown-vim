" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! instant_markdown#load()
    " dummy function to load this script.
endfunction


let s:host = get(g:, 'instant_markdown_host', 'localhost')
let s:port = get(g:, 'instant_markdown_port', 8090)
let s:BASE_URL = 'http://'.s:host.':'.s:port

function! s:update_markdown()
  let saved_changedtick = s:getbufvar('changedtick', '')
  if (saved_changedtick == "" || saved_changedtick != b:changedtick)
    call s:setbufvar('changedtick', b:changedtick)
    let current_buffer = join(getbufline("%", 1, "$"), "\n")
    " Empty {input} string for system() causes E677.
    let current_buffer = current_buffer == '' ? ' ' : current_buffer
    let url = s:BASE_URL . s:find_var('instant_markdown_path', '/markdown')
    call s:setbufvar('posted_url', url)
    call system("curl -X POST --data-urlencode 'file@-' ".shellescape(url)." &>/dev/null &", current_buffer)
  endif
endfunction
function! s:getbufvar(name, else)
  if !exists('b:instant_markdown')
    let b:instant_markdown = {}
  endif
  return get(b:instant_markdown, a:name, a:else)
endfunction
function! s:setbufvar(name, value)
  if !exists('b:instant_markdown')
    let b:instant_markdown = {}
  endif
  let b:instant_markdown[a:name] = a:value
endfunction
function! s:find_var(varname, else)
    for ns in [b:, w:, t:, g:]
        if has_key(ns, a:varname)
            return ns[a:varname]
        endif
    endfor
    return a:else
endfunction
function! instant_markdown#open()
  augroup instant-markdown
    autocmd!
    autocmd CursorMoved,CursorMovedI,CursorHold,CursorHoldI <buffer> silent call s:update_markdown()
    autocmd BufWinLeave <buffer> silent call instant_markdown#close()
    autocmd BufWinEnter <buffer> silent call instant_markdown#open()
  augroup END

  call s:setbufvar('changedtick', '')
  call s:update_markdown()
endfunction
function! instant_markdown#close()
  augroup instant-markdown
    autocmd!
  augroup END

  let url = s:getbufvar('posted_url', '')
  if url ==# ''
    echohl ErrorMsg
    echomsg 'instant-markdown: call :InstantMarkdownStart at first.'
    echohl None
    return
  endif
  silent! exec "silent! !curl -s -X DELETE " . shellescape(url) . " &>/dev/null &"
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

func! dressing#prompt_confirm(text) abort
  call luaeval("require('dressing.input').confirm(_A)", a:text)
endfunc

func! dressing#prompt_cancel() abort
  lua require('dressing.input').confirm()
endfunc

function! dressing#fzf_run(labels, options, window) abort
	call fzf#run({
        \ 'source': a:labels,
        \ 'sink': funcref('dressing#fzf_choice'),
        \ 'options': a:options,
        \ 'window': a:window,
        \ })
endfunction

function! dressing#fzf_choice(label) abort
	call v:lua.dressing_fzf_choice(a:label)
endfunction

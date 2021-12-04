func! dressing#prompt_confirm(text) abort
  call v:lua.dressing_prompt_confirm(a:text)
endfunc

func! dressing#prompt_cancel() abort
  lua dressing_prompt_confirm()
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

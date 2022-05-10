function! dressing#fzf_run(labels, options, window) abort
	call fzf#run(fzf#wrap({
        \ 'source': a:labels,
        \ 'sink': funcref('dressing#fzf_choice'),
        \ 'options': a:options,
        \ 'window': a:window,
        \}))
endfunction

function! dressing#fzf_choice(label) abort
	call v:lua.dressing_fzf_choice(a:label)
endfunction

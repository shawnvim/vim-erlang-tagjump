
if !exists('g:vimErlangTagJump_sortTag')
	let g:vimErlangTagJump_sortTag = ""
endif


if !exists('g:vimErlangTagJump_sortLengthMax')
	let g:vimErlangTagJump_sortLengthMax = 10
endif


function vimErlangTagJump#TagFunc(pattern, flags, info)
    if (a:pattern =~# 'MODULE')
        let keyword = expand('%:t:r')
    else
        let keyword = a:pattern
    endif

    let [l:tagname, l:filter] = s:getFilter(keyword)

    return s:sortTag(l:tagname, a:flags, a:info, l:filter)

endfunc


func! s:getFilter(pattern)
    let isk_origin = &isk

    setlocal isk+=:
    let keyword1 = expand('<cword>')
    setlocal isk+=?
    setlocal isk+=#
    setlocal isk+='
    let keyword2 = expand('<cword>')
    setlocal isk+=(
    setlocal isk+=/
    let keyword3 = expand('<cword>')
    let &isk = isk_origin

    if (keyword1[1:] =~ ':')
        let [l:mod, l:fun] = split(keyword1, ':')
        let funfilter = 'v:val.kind =~# "^f"'
        let modpattern = '"' . l:mod . '"'
        if l:fun =~# a:pattern
            let funname = a:pattern
        else
            let funname = l:fun
        endif
        return [funname, 'get(v:val, "module", "") ==# ' . '"' . l:mod . '"' . ' && ' . 'v:val.kind =~# "^f"']
    elseif (keyword2 =~ '#')
        return [a:pattern, 'v:val.kind =~# "^[r|a]"']
    elseif (keyword2 =~ '?')
        return [a:pattern, 'v:val.kind =~# "^[d|m|a]"']
    elseif (keyword3 =~ '[(|/]')
        return [a:pattern, 'v:val.kind =~# "^[f|t]"']
    else
        return [a:pattern, 'v:val.filename =~# ".[e|h]rl$"']
    endif
endfunc


function! s:sortTag(tagname, flags, info, filter)
    let pattern = '^' . a:tagname . '$'
    let fullpath = a:info.buf_ffname
    let tagList = taglist(pattern, fullpath)
    if tagList == []
        call s:printWarning()
        return v:null
    endif
    let result = filter(tagList, a:filter)
    if (result != [] && fullpath !~# result[0].filename && g:vimErlangTagJump_sortTag != "" && len(result) < g:vimErlangTagJump_sortLengthMax)
        for item in result
            let item['index'] = str2nr(system(g:vimErlangTagJump_sortTag . ' ' . item['filename'] . ' ' . fullpath . get(item, "module", "") . a:tagname))
        endfor
        " echom result
        call sort(result, function("CompareFilenames", [fullpath]))
    endif
    if result == []
        call s:printWarning()
        return v:null
    endif
    return result
endfunction


function! s:printWarning()
    echom 'No tag found, fallback using standard tag lookup'
endfunction


function CompareFilenames(arg, item1, item2)
    let f1 = a:item1['index']
    let f2 = a:item2['index']
    return f1 <=# f2 ? -1 : f1 >=# f2 ? 1 : 0
endfunction


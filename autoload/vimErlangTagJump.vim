
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


    if l:filter == ''
        return vimErlangTagJump#FbTagFunc(a:pattern, a:flags, a:info)
    else
        return s:sortTag(l:tagname, a:flags, a:info, l:filter)
    endif
endfunc

function vimErlangTagJump#FbTagFunc(pattern, flags, info)
    let pattern = '^' . a:pattern . '$'
    let fullpath = a:info.buf_ffname
    let tagList = taglist(pattern, fullpath)
    if tagList == []
        call s:printWarning()
        return v:null
    endif
    let extended_name_set = get(b:, 'extended_name_set', [])
    if extended_name_set == [] || a:info.buf_ffname == tagList[0].filename
        return tagList
    endif
    let result = filter(tagList, 'index(extended_name_set, fnamemodify(v:val.filename, ":e:r")) >= 0')
    if result == []
        call s:printWarning()
        return v:null
    endif
    return result
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
        if l:fun =~# a:pattern
            let funname = a:pattern
        else
            let funname = l:fun
        endif
        let funfilter1 = '(v:val.kind =~# "^f"' . ' && ' . 'get(v:val, "module", "") ==# ' . '"' . l:mod . '")'
        let funfilter2 = '(v:val.kind =~# "^t"' . ' && ' . 'fnamemodify(v:val.filename, ":t:r") ==# ' . '"' . l:mod . '")'
        return [funname, funfilter1 . ' || ' . funfilter2]
    elseif (keyword2 =~ '#')
        return [a:pattern, 'v:val.kind =~# "^[r|a]"']
    elseif (keyword2 =~ '?')
        return [a:pattern, 'v:val.kind =~# "^[d|m|a]"']
    elseif (keyword3 =~ '[(|/]')
        return [a:pattern, 'v:val.kind =~# "^[f|t|a]"']
    else
        return [a:pattern, '']
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
            if g:vimErlangTagJump_sortTag == 'default'
                let item['index'] = DefaultStringDifferencial(item['filename'], fullpath)
            else
                let item['index'] = str2nr(system(g:vimErlangTagJump_sortTag . ' ' . item['filename'] . ' ' . fullpath . get(item, "module", "") . a:tagname))
            endif
        endfor
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


function DefaultStringDifferencial(str1, str2)
    let whole = split(a:str1, '/') + split(a:str2, '/')
    return len(uniq(whole))
endfunction


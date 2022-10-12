if exists("g:erlang_minlines")
  exec "syn sync minlines=" . g:erlang_minlines
endif

if exists("g:erlang_maxlines")
  exec "syn sync maxlines=" . g:erlang_maxlines
endif

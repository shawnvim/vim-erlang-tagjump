vim-erlang-tagjump
=======

Tag jump by using universal-ctags in VIM

Setup
------------
 - Set tagfunc in your vimrc as
    ```vim
    autocmd BufNewFile,BufRead *.erl,*.hrl setlocal tagfunc=vimErlangTagJump#TagFunc
    ```

Custom
------------
If you want to use some specific sort algorithm, please set a max length to avoid stack due to long tag list
- Set algorithm and length
    ```vim
    let g:vimErlangTagJump_sortTag = PathToYourAlgorithmFile
    let g:vimErlangTagJump_sortLengthMax = 15
    ```



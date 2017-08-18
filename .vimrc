"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General configuration

" Use Pathogen
execute pathogen#infect()

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Make the font smaller
" set guifont=Luxi\ Mono\ 9

command! Homefont :set guifont=Monaco:h9
command! Bigfont :set guifont=Menlo:h11

" Make backspace back up a tabstop. Especailly handy for editing Python
set smarttab

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" don't show warning messages if a .swp file already exists
set shortmess+=A

set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set noshowcmd		" display incomplete commands
set incsearch		" do incremental searching
set ignorecase          " case insensitive searching
set hidden		" allow hidden buffers
"in normal mode wrap lines and break at work boundries
set wrap
set linebreak

" Sets tab stops and indenting. Note that in some cases this is done in
" ~/.vim/indent files and some is overridden below in the language specific
" sections.
set ts=3 sw=3 et        "tab stops and shift width == 3 and expand tabs to spaces

set showmatch           "show matching brackets
"
"Make <Tab> complete work like bash command line completion
set wildmode=longest,list

" Don't have the scratch buffer show up when there are multiple matches.
set completeopt=

" Turn on a fancy status line
set statusline=%m\ [File:\ %f]\ [Type:\ %Y]\ [ASCII:\ %03.3b]\ [Col:\ %03v]\ [Line:\ %04l\ of\ %L]
set laststatus=2 " always show the status line

" Turn off swap files. Gets rid of annoying warnings that the file is open in
" two windows and keeps dirs from getting cluttered with .swp files but at the
" cost of greater risk of losing work.
set updatecount=0

" this combination of options causes a backup file to be written before a write
" begins but that file is deleted as soon as the write succeeds so we don't get
" a bunch of files ending with "~" cluttering things up.
set writebackup
set nobackup

" Enable file type detection.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on
filetype plugin on

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
autocmd BufReadPost *
 \ if line("'\"") > 0 && line("'\"") <= line("$") |
 \   exe "normal g`\"" |
 \ endif

" If we're in an xterm tell vim that we have a dark background so it picks good
" syntax highlighting colors
if ! has("gui_running")
  " turns out I use a light term more often that a dark one.
  " set background=dark
  " This is experimental, but it seems like it fixes the problems with using vim
  " via ssh from my Mac. I don't think it causes problems when I'm not ssh'd
  " in, but I'm not sure yet...
  " set term=linux

  " Make vimdiff colors not suck
  highlight DiffAdd cterm=none ctermfg=Black ctermbg=Green
  highlight DiffDelete cterm=none ctermfg=Black ctermbg=Red
  highlight DiffChange cterm=none ctermfg=Black ctermbg=Yellow
  highlight DiffText cterm=none ctermfg=Black ctermbg=Magenta
endif

if has("gui_running")
   set background=light
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General commands/keyboard shortcuts for all files

"commands for easily adding a blank line above or below the current line
map <leader>o o<esc>
map <leader>O O<esc>
"
" emacs like key bindings in insert mode
imap <C-e> <esc>$a
imap <C-a> <esc>0i
imap <C-u> <esc>ld0i
imap <C-k> <esc>ld$a

" C-s to save in insert and normal mode
imap <C-s> <esc>:w<cr>a
nmap <C-s> :w<cr>

"map killws to a command to remove trailing whitespace
command! Killws :% s/\s\+$//g

" Don't use Ex mode, use Q for formatting
map Q gq

" Close the current buffer but leave the window open
" on the previous buffer (if you just close the current buffer it also
" closes the window. b# goes to previous buffer, and then bd# deletes the
" one you were just on)
command! Bc :b#|:bd#

" This command causes text to not be automatically cut at 80 characters - lines
" have abritrary length. However, lines are wrapped on the screen at a
" reasonable place.
command! Flow :setlocal textwidth=0 wrap lbr nolist

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

""""""""""""""""""""""""""""""""""
" Build commands

" <F4> goes to the next error when compiling
" Also map C-n and C-p in regular. These are particularly handy in screen
" sessions 'cause screen seems to grab F4
map <F4> :cn<CR>
nmap <C-n> :cn<CR>
nmap <C-p> :cp<CR>

" A command to call :make and then open the error window at the bottom of the
" screen.
command! Mk :make|:copen|:winc J

""""
" Scons

" Set up a :Scons command to build via scons. Arguments are just passed
" through to scons.
function! BuildWithScons(...)
 " a:0 == # of args to the command
 if a:0 == 0
    let &makeprg="scons -u"
 else
    let &makeprg = "scons -u " . join(a:000)
 endif
 :make!
endfunction

command! -narg=* -complete=file Scons :call BuildWithScons(<f-args>)|:copen|:winc J
" Run checkstyle, cleanup the error format, set the error format, etc.
function! RunSconsCheckstyle()
   let &l:efm = '%f %l %c %m'
   let &makeprg = 'scons -u checkstyle \|& python ~/.vim/util_scripts/cleanup_checkstyle_quickfix.py'
   :make!
   :copen
   :winc J
endfunction
command! Sc :call RunSconsCheckstyle()

function! SbtCompile(...)
   set errorformat=%E\ %#[error]\ %#%f:%l:\ %m,%-Z\ %#[error]\ %p^,%-C\ %#[error]\ %m
   set errorformat+=,%W\ %#[warn]\ %#%f:%l:\ %m,%-Z\ %#[warn]\ %p^,%-C\ %#[warn]\ %m
   set errorformat+=,%-G%.%#
    " a:0 == # of args to the command
    if a:0 == 0
       let &makeprg="play compile"
    else
       let &makeprg = "play " . join(a:000)
    endif
   :make!
   :copen
   :winc J
endfunction
command! -narg=* -complete=file S :call SbtCompile(<f-args>)

function! MvnCompile(...)
    set errorformat=[ERROR]\ %f:%l:\ %m
    " a:0 == # of args to the command
    if a:0 == 0
       let &makeprg="mvn compile"
    else
       let &makeprg = "mvn " . join(a:000)
    endif
   :make!
   :copen
   :winc J
endfunction
command! -narg=* -complete=file M :call MvnCompile(<f-args>)


" Scons config files (SConstruct and SConscript) are really python files.
au BufNewFile,BufRead SConstruct setlocal filetype=python
au BufNewFile,BufRead SConscript setlocal filetype=python

" On some OS's (Ubuntu, I'm looking at you) the default collation order is
" wrong so you can't use !sort to sort file names that have '.' characters in
" them. This fixes that ugliness.
command! -range=% Sort :<line1>,<line2>!LC_COLLATE=C sort

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Templates: My personal templating system
"
" It works like this:
"
" Given a new file like /p1/p2/p3/p4/file.h we look in ~/.vim/templates for
" matching templates. We 1st start by walking backward up the list of dirs so
" we look for a ~/.vim/templates/p4 directory. If there is one and it contains
" a template.h file that is used. If not (either not such dir or there is a
" dir but it doesn't contain a .h template) we go up and look for p3, then p2,
" etc. Suppose we find a ~/.vim/templates/p2. We then go forwards again
" looking for a ~/.vim/templates/p2/p3/template.h, then a
" ~/.vim/templates/p2/p3/p4/template.h, etc. The longest matching path is
" used. If we can't find any matching subdirs we just look for a template.h
" file in ~/.vim/templates and use that.
"
" Template matching rules: template files are of the form template_<suffix> so
" template_.h matches files that end in '.h' while template_SConstruct matches
" files that end with 'SConstruct'.
"
" Once a template is found it is loaded and all the <+KEYWORD+> items are
" replaced as per ExpandPlaceholders() below. This is a very flexible
" mechanism that allows you to easily add new keywords and functions for
" their replacement. Keywords also can accept arguments.
"
" Finally, if the string ~~CURSOR~~ is found the cursor is moved to that
" position and the user is left in insert mode.

" Given directory dir returns the name of a template that matches fname or the
" empty string if not such template could be found.
function! FindTemplateMatch(dir, fname)
   let l:dir = a:dir
   if match(a:dir, '.*/$') == -1
      let l:dir = a:dir . '/'
   endif
   let l:templates = split(glob(l:dir . 'template_*'))
   for l:template_fname in l:templates
      let l:suf_idx = strridx(l:template_fname, 'template_')
      let l:suffix = strpart(l:template_fname, l:suf_idx + 9)
      let l:suf_idx = strridx(a:fname, l:suffix)
      if l:suf_idx >= 0
         if strpart(a:fname, l:suf_idx) == l:suffix
            return l:template_fname
         endif
      endif
   endfor
   return ''
endfunction

" Given a file whose full path is fname see if there is an appropriate
" template for it. If so return the name of that template.
function! FindTemplate(fname)
   let l:templates_dir = fnamemodify('~/.vim/templates', ':p')
   " First see if there's a template that matches any of the directories in
   " the path. If so we use this. If not we just check file extension.

   " Expand to a full path and strip off the file name so we have just the
   " directory name
   let l:fname_abs_dir = fnamemodify(a:fname, ':p:h')
   " Cur path starts out as the full path. Then we remove the ending dir one
   " dir at a time to see if we can find a matching template. For example, if
   " it starts with '/home/odain/this/long/path' we first look for a directory
   " named 'path' in the templates directory. If there isn't one we then
   " update l:cur_path to be '/home/odain/this/long' and look for a dir named
   " 'long', etc.
   let l:cur_path = l:fname_abs_dir
   let l:cur_match_template = ''
   while strlen(l:cur_path) > 1
      let l:cdir = fnamemodify(l:cur_path, ':t')
      let l:match_dir = finddir(l:cdir, l:templates_dir)
      " We found a matching dir but we're not done. We also need to see if
      " there's a matching template. There also might be a more specific
      " matching template (e.g. in a subdirectory) that we should use instead.
      if !empty(l:match_dir)
         let l:cur_match_dir = l:templates_dir . l:cdir
         let l:potential_template = FindTemplateMatch(l:cur_match_dir, a:fname)
         if !empty(l:potential_template) && filereadable(l:potential_template)
            let l:cur_match_template = l:potential_template
         endif
         " Now see if there's a more specific match. To do that we go through
         " the path from the matching dir forward looking for subdirs that
         " also match.
         let l:dir_suffix = strpart(l:fname_abs_dir, strlen(l:cur_path))
         let l:subdirs = split(l:dir_suffix, '/')
         let l:cur_subdir = l:cur_match_dir
         for l:subdir in l:subdirs
            if !empty(finddir(l:subdir, l:cur_subdir))
               let l:cur_subdir = l:cur_subdir . '/' . l:subdir
               let l:potential_template = FindTemplateMatch(l:cur_subdir, a:fname)
               if !empty(l:potential_template) && filereadable(l:potential_template)
                  let l:cur_match_template = l:potential_template
               endif
            else
               break
            endif
         endfor
         " If we've got a template now we're done
         if !empty(l:cur_match_template)
            return l:cur_match_template
         endif
      endif  
      let l:cur_path = fnamemodify(l:cur_path, ':h')
   endwhile
 
   " If we got here we didn't find a template in any of the subdirs so we just
   " look by file extension for a match.
   let l:cur_match_template = FindTemplateMatch(l:templates_dir, a:fname)
   if !empty(l:cur_match_template) && filereadable(l:cur_match_template)
      return l:cur_match_template
   else
      return ''
   endif
endfunction

" Function used to expand <+FOO+> place holders in the current buffer. Some
" place holders have a ,ARG suffix like <+FOO,ARG+> in which case ARG is used
" to help us expand FOO. Generally this is called after a macro file is read
" in.
function! ExpandPlaceholders()
   " Map from placeholders to functions that expand them
   let l:placeholders = {'VIM_FILE': function('ExpandVimFile'),
            \            'INCLUDE_GUARD': function('ExpandIncludeGuard'),
            \            'DATE': function('ExpandDate'),
            \            'PATH_TO_PACKAGE': function('PathToPackage')}
   let l:place_pattern = '<+\([^+,]\+\),\?\([^+]*\)+>'
   let l:line = search(l:place_pattern)
   while l:line > 0
      let l:line_text = getline(l:line)
      let l:place_holder = matchlist(l:line_text, l:place_pattern)
      if !has_key(l:placeholders, l:place_holder[1])
         echoerr "Unknown placeholder '" l:place_holder[1] "'"
         return
      endif
      " Find the replacement function in the dictionary
      let l:Fun = l:placeholders[l:place_holder[1]]
      " Call the function passing anyting after the "," as additional
      " arguments
      if (len(l:place_holder) > 2 && !empty(l:place_holder[2])) 
         let l:replacement = l:Fun(l:place_holder[2])
      else
         let l:replacement = l:Fun()
      endif
      " Unset l:Fun or we get errors when we call :let again. Not sure why as
      " you can usually overwrite a variable but function pointers seem to be
      " special.
      unlet l:Fun
      let l:m_start = match(l:line_text, l:place_holder[0])
      let l:m_end = matchend(l:line_text, l:place_holder[0])
      let l:line_text = strpart(l:line_text, 0, l:m_start) . l:replacement .  strpart(l:line_text, l:m_end)
      :call setline(l:line, l:line_text) 
      let l:line = search(l:place_pattern)
   endwhile
endfunction

" Given the current file path, convert this to a java package. The argument is
" the 'beginning of the package'. For example, if this is called with
" 'com.threeci' from a file at
" /home/oliver/code/com/threeci/commons/logger/file.java, this will walk up
" the path until it find conecutive directories com/threeci. It would then
" construct the package name from all the directories; in this example it
" would be com.threeci.commons.logger.
function! PathToPackage(fargs)
   let l:fname = expand('%:p:h')
   let l:dotted = substitute(l:fname, '/', '.', 'g')
   let l:package_start = match(l:dotted, a:fargs)
   return strpart(l:dotted, l:package_start)
endfunction

" Do fnamemodify on the current file name with the supplied arguments. For
" example, passing ':p' results in the full path, etc.
function! ExpandVimFile(fargs)
   return fnamemodify(expand('%'), a:fargs)
endfunction

" To be used like #ifndef <+INCLUDE_GUARD,spar+> via ExpandPlaceholders. This
" expands the INCLUDE_GUARD to be PATH_TO_FILE_H_ where the path is relative
" to the argument (in the example above it's relative to the directory spar).
function! ExpandIncludeGuard(eargs)
   let l:fname = fnamemodify(expand('%'), ':p')
   let l:end_path_pos = matchend(l:fname, '/' . a:eargs . '/')
   let l:end_path = strpart(l:fname, l:end_path_pos)
   let l:end_path = substitute(l:end_path, '/', '_', 'g')
   let l:end_path = substitute(l:end_path, '-', '_', 'g')
   let l:end_path = substitute(l:end_path, ' ', '_', 'g')
   let l:end_path = substitute(l:end_path, '\.', '_', 'g')
   return toupper(l:end_path) . '_'
endfunction

" Returns a string representing today's date. The argument is a string
" specifying how the date should be formatted in standard strftime notation.
function! ExpandDate(dargs)
  return strftime(a:dargs, localtime()) 
endfunction

function! MoveToCursor()
   " The \V makes the pattern "very non-magic" so its pretty much a literal
   " string match.
   let l:line = search('\V~~CURSOR~~')
   if l:line != 0
      " The string '~~CURSOR~~' is 10 characters long and search leaves us at the
      " beginning of the match so delete the next 10 characters and put us in
      " insert mode.
      normal 10dl
      startinsert
   endif
endfunction

function! OnNewFile()
   let l:template = FindTemplate(expand('%'))
   if !empty(l:template)
      " move the cursor to be beginning of the file
      normal gg
      " Read in the template
      execute ':r ' . l:template
      " The read command puts the file contents on the line *after*
      " the cursor position so we have a blank line at the top of the
      " file. Delete that.
      normal ggdd
      :call ExpandPlaceholders()
      " If there's a ~~CURSOR~~ marker in the file move to it and start insert
      " mode
      :call MoveToCursor()
   endif
endfunction

au! BufNewFile * :call OnNewFile()

"""""""""""""""""""""""""""" end templates



""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Language specific configs
" Note some of this is also done via ~/.vim/indent, ~/.vim/ftplugin, etc.


""""
" Configs for multiple languages
" highlight characters after column 80
hi TooManyChars guifg=White guibg=Red ctermfg=White ctermbg=Red
autocmd FileType python,javascript match TooManyChars /\%>80v.\+/
autocmd FileType cpp,c,python,javascript match TooManyChars /\%>120v.\+/
autocmd FileType java match TooManyChars /\%>120v.\+/
" Quick command to turn off this highlighting. Handy when editing files that
" don't conform to the 80 char limit.
" TODO: This turns off highlighting globally. Should figure out how to do it
" for just the current buffer.
command! No80 :hi TooManyChars NONE

""""
" Java
autocmd FileType java setlocal et ts=4 sw=4 tw=120 
" spell check is smart enough to only check spelling in comments and strings,
" so turn that on for Java code.
autocmd FileType java setlocal spell
" Assumes the jar is in ~/bin/checkstyle-all.jar and we're using the
" sun_checks.xml file in that dir.
function! RunJavaCheckstyle(lintArgs)
    let old_errorformat = &errorformat
    set errorformat=%f:%l:%m

    let checkstyle_cmd = 'arc lint --output=compiler ' . a:lintArgs
    let old_makeprg = &makeprg
    let &makeprg = checkstyle_cmd
    echo "will run: " . checkstyle_cmd

    :make!
    :copen
    :winc J

    " restore the previously existing error format and makeprg
    let &errorformat = old_errorformat
    let &makeprg = old_makeprg
endfunction
autocmd FileType java map <leader>l :call RunJavaCheckstyle("%:p")<CR>
command! -narg=1 LintAll :call RunJavaCheckstyle('--rev=' . <f-args>)<CR>

""""
" Python
autocmd FileType python setlocal foldmethod=indent
" set foldlevel really high so that, initially, all folds are open
autocmd FileType python setlocal foldlevel=1000
autocmd FileType python setlocal et ts=4 sw=4 tw=79
autocmd FileType python map <leader>l :call Flake8()<CR>
autocmd FileType python setlocal completeopt=menu,longest,preview
autocmd FileType python nmap <buffer> <C-]> :call g:jedi#goto()<CR>
let g:jedi#popup_on_dot = 0


""""
" TypeScript
autocmd FileType typescript setlocal completeopt+=menu
autocmd FileType typescript setlocal completeopt+=menu,preview

""""
" HTML Tempaltes

" .gen files are Genshi templates so highlight as HTML
au BufNewFile,BufRead *.gen setlocal filetype=html
au BufNewFile,BufRead *.swig setlocal filetype=html

"""
" HTML, CSS, JS

autocmd FileType javascript setlocal ts=2 sw=2 et tw=80
autocmd Filetype html,xml source ~/.vim/scripts/closetag.vim 
let g:user_emmet_expandabbr_key = '<leader>e'

""""
" C++
" Add ability to switch from .h to .cc quickly
command! Toh :e %:r.h
command! Toc :e %:r.cc
autocmd FileType c,cpp setlocal et ts=2 sw=2 tw=120 
" spell check is smart enough to only check spelling in comments and strings,
" so turn that on for C++ code.
autocmd FileType c,cpp setlocal spell

""""
" clang_complete - auto complete stuff for C++

let g:clang_auto_select=1
" Automatically try to complete if if I don't hit C-X C-U
let g:clang_complete_auto=1
let g:clang_complete_copen=0
" Use the clang *library* instead of the executable. Much faster.
let g:clang_use_library = 1
let g:clang_library_path = '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib'
" Use C++11 with clang_complete
let g:clang_user_options='-std=c++0x -x c++' 
" Hitting F2 will show clang_complete errors for debugging purposes
map <F2>  :call g:ClangUpdateQuickFix()<CR>

""""
" supertab
"
" use supertab with clang_complete. Not sure if I'm going to end up wanting
" file type detection with this so we use something else for non-C++ code.
" autocmd FileType cpp,c call SuperTabSetDefaultCompletionType("<c-x><c-u>")
let g:SuperTabDefaultCompletionType = "context"
"let g:SuperTabContextDefaultCompletionType = s:ContextText
"let g:SuperTabCompletionContexts = ['s:ContextText', 's:ContextDiscover']


""""
" R
" handle R files correctly
au BufNewFile,BufRead *.R     setf r
au BufNewFile,BufRead *.R     set syntax=r


""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Fileype specific configs for non-programming languages.

" If editing a subversion commmit file automatically go to the top of the file
" and enter insert mode
au BufNewFile,BufRead *svn-commit*tmp  :1
" Same for git commits
au BufNewFile,BufRead *.git/COMMIT_EDITMSG :1
" text files are limited to 80 character lines
autocmd FileType text setlocal textwidth=80

""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin configuration


""""
" Taglist
map <leader>tl :TagbarToggle<cr>

""""
" LustyExplorer
" Don't print annoying warning if machine doesn't have Ruby support
let g:LustyExplorerSuppressRubyWarning = 1
if has('ruby')
   nmap ,e :LustyFilesystemExplorerFromHere<CR>
   " ,p opens a filesystem explorer from the current working director (p is short
   " for pwd)
   nmap ,p :LustyFilesystemExplorer<CR>
   nmap ,b :LustyBufferExplorer<CR>
endif

""""
" Eclim stuff
" Is eclim running?
function! EclimRunning()
  let l:res = 0
  try
     let l:res = eclim#EclimAvailable()
  catch /E117/
     let l:res = 0
  endtry
  return l:res
endfunction

" I'm not really sure why, but when I use vim on the command line and do
" NON-eclim stuff I get a warning unless I have this set.
let g:EclimMakeLCDWarning = 0

" Setup eclim key mappings
function! SetupEclimKeys()
 if EclimRunning()
   " \i adds the required import for the class under the cursor
   autocmd FileType java nnoremap <silent> <buffer> <leader>i :JavaImport<cr>
   " Search for the javadocs of the element under the cursor
   autocmd FileType java nnoremap <silent> <buffer> <leader>d :JavaDocSearch -x declarations<cr>
   " Perform a context sensitive search of the element under the cursor
   autocmd FileType java nnoremap <silent> <buffer> <C-]> :JavaSearchContext<cr>
   " Suggest corrections for errors on this line
   autocmd FileType java nnoremap <silent> <buffer> <leader>c :JavaCorrect<cr>
   " Fix up imports, adding any that are missing and removing any that are no
   " longer needed.
   autocmd FileType java nnoremap <silent> <buffer> <leader>fi :JavaImportOrganize<cr>

   " let g:SuperTabDefaultCompletionType = "<c-x><c-u>"
   autocmd FileType java call SuperTabSetDefaultCompletionType("<c-x><c-u>")
   " I don't know why this is needed. For some reason eclim seems to reset the
   " TooManyChars highlight group so I call this a 2nd time.
   hi TooManyChars guifg=White guibg=Red ctermfg=White ctermbg=Red

   command! Pr :execute '!play "eclipse skip-parents=false"' | :ProjectRefreshAll
   nmap ,pt :ProjectsTree<CR>

   command! -narg=* Jr JavaRename <f-args>
   command! -narg=* Jf JavaSearch <f-args>
   command! Jg JavaGet
   command! Js JavaSet
   command! Jgs JavaGetSet
 else
   echo "Eclim not running"
 endif
endfunction
command! SetupEclimKeys :call SetupEclimKeys()

" There is apparently a bug in some versions of gvim that cause the cursor to
" be invisible. This strange hack fixes it!
let &guifont=&guifont

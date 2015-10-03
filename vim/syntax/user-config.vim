" Vim syntax file

syntax clear

syn case ignore
com! -nargs=+ HiLink hi def link <args>

syn match ucVar "\$[A-Za-z_]\+"
syn match ucInstallDirective "^INSTALL\ "
syn match ucBaseDirective "^BASE\ "
syn match ucDirective "^\(COPY\|SYMLINK\)\ "
syn case match

syn keyword etTodo TODO FIXME XXX NOTE
syn match unixComment  "#.\{-}$" contains=etTodo,@Spell

HiLink ucIdentifier Identifier
HiLink ucVar ucIdentifier

HiLink ucInstallDirective ucDirective
HiLink ucDirective Statement
HiLink ucBaseDirective Constant

HiLink unixComment Comment

delcommand HiLink


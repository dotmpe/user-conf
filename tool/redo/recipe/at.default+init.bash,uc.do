: "${1#@}"
: "${_#+init.do.do}"
part=${_}
redo-ifchange ${env_init[@]} &&
. "${env_init_sh}" &&
uc-env -r uc &&
uc-part $part &&
uc-apply $part &&
>$3 echo "
redo-ifchange ${env_init[*]} &&
. ${env_init_sh} &&
uc-env -r uc &&
uc-update $part
" &&
< $3 redo-stamp

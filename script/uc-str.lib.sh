uc_str_lib__load()
{
  lib_require envd
}

uc_str_lib__init ()
{
  envd_dtype uc/str.lib lib &&
  envd_dfun str_word &&
  true || return
  ! { "${DEBUG:-false}" || "${DEV:-false}" || "${INIT:-false}"; } ||
  ${LOG:?} notice ":uc-str:lib-init" "Initialized uc-str.lib"
}

str_word () # ~ <Str>
{
  echo "${1//[^A-Za-z0-9_]/_}"
}

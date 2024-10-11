#!/usr/bin/env bash

## OS: files, paths

os_uc_lib__load()
{
  : "${OS_HOST:="$(hostname -f)"}"
  : "${OS_HOSTNAME:="$(hostname -s)"}"
  : "${OS_NAME:="$(uname -o)"}"
  : "${OS_UNAME:="$(uname -s)"}"
}


read_nix_style_file () # [cat_f=] ~ File [Grep-Filter]
{
  test $# -eq 1 -a -e "${1-}" || return 64
  cat $1 | grep -Ev '^\s*(#.*|\s*)$'
}

read_nix_style_files()
{
  test $# -gt 0 || return 64
  while test $# -gt 0
  do
    read_nix_style_file $1
    shift
  done
}

filesize() # File
{
  while test $# -gt 0
  do
    case "${OS_UNAME:?}" in
      Darwin )
          stat -L -f '%z' "$1" || return 1
        ;;
      Linux | CYGWIN_NT-6.1 )
          stat -L -c '%s' "$1" || return 1
        ;;
      * ) $LOG error ":os-uc.lib" "filesize: $OS_UNAME?" "" 1 ;;
    esac; shift
  done
}

# Use `stat` to get modification time (in epoch seconds)
filemtime() # File
{
  local flags=- ; file_stat_flags
  while test $# -gt 0
  do
    case "${OS_UNAME:?}" in
      Darwin )
          trueish "${file_names-}" && pat='%N %m' || pat='%m'
          stat -f "$pat" $flags "$1" || return 1
        ;;
      Linux | CYGWIN_NT-6.1 )
          trueish "${file_names-}" && pat='%N %Y' || pat='%Y'
          stat -c "$pat" $flags "$1" || return 1
        ;;
      * ) $LOG error ":os-uc.lib" "filemtime: $OS_UNAME?" "" 1 ;;
    esac; shift
  done
}

file_stat_flags()
{
  test -n "$flags" || flags=-
  test ${file_deref:-0} -eq 0 || flags=${flags}L
  test "$flags" != "-" || flags=
}

filter_dir_paths ()
{
  local path len; while read -r path
  do
    len="$(( ${#path} - 1 ))"
    stderr echo "${path:$len}" = /
    test "${path:$len}" = / || continue
    echo "${path:1:$len}"
  done
}

# Go over arguments and echo. If no arguments given, or on argument '-' the
# standard input is cat instead or in-place respectively. Strips empty lines.
# (Does not open filenames and read from files). Multiple '-' arguments are
# an error, as the input is not buffered and rewounded. This simple setup
# allows to use arguments as stdin, insert arguments-as-lines before or after
# stdin, and the pipeline consumer is free to proceed.
#
# If this routine is given no data is hangs indefinitely. It does not have
# indicators for data availble at stdin.
foreach_item ()
{
  {
    test -n "$*" && {
      while test $# -gt 0
      do
        test "$1" = "-" && {
          # XXX: echo foreach_stdin=1
          cat -
          # XXX: echo foreach_stdin=0
        } || {
          printf -- '%s\n' "$1"
        }
        shift
      done
    } || cat -
  } | grep -v '^$'
}


# Read `foreach-item` lines and act, default is echo ie. same result as
# `foreach-item`
# but with p(refix) and s(uffix) wrapped around each item produced. The
# unwrapped loop-var is _S.
foreach_do ()
{
  test -n "${p-}" || local p= # Prefix string
  test -n "${s-}" || local s= # Suffix string
  test -n "${act-}" || local act="echo"
  foreach_item "$@" | while read -r _S ; do S="$p$_S$s" && $act "$S" ; done
}


ignore_sigpipe()
{
  local r=$?
  test $r -eq 141 || return $r # For bash: 128+signal where signal=SIGPIPE=13
}

read_nix_style_file ()
{
  test -n "${1-}" || return 1
  test -z "${2-}" || error "read-nix-style-file: surplus arguments '$2'" 1
  cat ${cat_f-} "$1" | grep -Ev '^\s*(#.*|\s*)$' || return 1
}

normalize_relative()
{
  OIFS=$IFS
  IFS='/'
  local NORMALIZED=

  for I in $1
  do
    # Resolve relative path punctuation.
    if [ "$I" = "." ] || [ -z "$I" ]
      then continue

    elif [ "$I" = ".." ]
      then
        NORMALIZED=$(echo "$NORMALIZED"|sed 's/\/[^/]*$//g')
        continue
      else
        NORMALIZED="${NORMALIZED}/${I}"
        #test -n "$NORMALIZED" \
        #  && NORMALIZED="${NORMALIZED}/${I}" \
        #  || NORMALIZED="${I}"
    fi
  done
  IFS=$OIFS
  test -n "$NORMALIZED" \
    && {
      case "$1" in
        /* ) ;;
        * )
            NORMALIZED="$(expr_substr "$NORMALIZED" 2 ${#NORMALIZED} )"
          ;;
      esac
    } || NORMALIZED=.
  trueish "${strip_trail-}" && echo "$NORMALIZED" || case "$1" in
    */ ) echo "$NORMALIZED/"
      ;;
    * ) echo "$NORMALIZED"
      ;;
  esac
}

# Change cwd to parent dir with existing local path element (dir/file/..) $1, leave go_to_before var in env.
go_to_dir_with () # ~ Local-Name
{
  test -n "$1" || error "go-to-dir: Missing filename arg" 1

  # Find dir with metafile
  go_to_before=.
  while true
  do
    test -e "$1" && break
    go_to_before=$(basename -- "$(pwd)")/$go_to_before
    test "$(pwd)" = "/" && break
    cd ..
  done

  test -e "$1" || return 1
}

# Count lines with wc (no EOF termination correction)
count_lines () # ~ Source
{
  test "${1-"-"}" = "-" && {
    wc -l | awk '{print $1}'
    return
  } || {
    while test $# -gt 0
    do
      wc -l $1 | awk '{print $1}'
      shift
    done
  }
}

#!/bin/sh

## OS: files, paths

os_uc_lib_load()
{
  true "${uname:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"
  true "${hostname:="$(hostname -s | tr 'A-Z' 'a-z')"}"
  true "${os:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"

  test -n "${gsed-}" || case "$uname" in
      linux ) gsed=sed ;; * ) gsed=gsed ;;
  esac
  test -n "${ggrep-}" || case "$uname" in
      linux ) ggrep=grep ;; * ) ggrep=ggrep ;;
  esac
  test -n "${gdate-}" || case "$uname" in
      linux ) gdate=date ;; * ) gdate=gdate ;;
  esac
  test -n "${gstat-}" || case "$uname" in
      linux ) gstat=stat ;; * ) gstat=gstat ;;
  esac
}

read_nix_style_file()
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
    case "$uname" in
      darwin )
          stat -L -f '%z' "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          stat -L -c '%s' "$1" || return 1
        ;;
      * ) $LOG error "os" "filesize: $1?" "" 1 ;;
    esac; shift
  done
}

# Use `stat` to get modification time (in epoch seconds)
filemtime() # File
{
  while test $# -gt 0
  do
    case "$uname" in
      darwin )
          stat -L -f '%m' "$1" || return 1
        ;;
      linux | cygwin_nt-6.1 )
          stat -L -c '%Y' "$1" || return 1
        ;;
      * ) $LOG error "os" "filemtime: $1?" "" 1 ;;
    esac; shift
  done
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

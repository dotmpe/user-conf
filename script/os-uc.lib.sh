#!/bin/sh


# OS: files, paths

os_uc_lib_load()
{
  test -n "$uname" || uname="$(uname -s)"
  test -n "$os" || os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  export name os

  # Set vars for GNU variants
  test -n "$gsed" || case "$uname" in
      linux ) gsed=sed ;; * ) gsed=gsed ;;
  esac
  test -n "$ggrep" || case "$uname" in
      linux ) ggrep=grep ;; * ) ggrep=ggrep ;;
  esac
  test -n "$gstat" || case "$uname" in
      linux ) gstat=stat ;; * ) gstat=gstat ;;
  esac
  test -n "$gtr" || case "$uname" in
      linux ) gtr=tr ;; * ) gtr=gtr ;;
  esac
}



short()
{
  test -n "$1" || set -- "$(pwd)"
  # XXX maybe replace python script. Only replaces home
  $scriptpath/short-pwd.py -1 "$1"
}


filesize() # File
{
  local flags=- ; file_stat_flags
  case "$uname" in
    darwin )
        stat -f '%z' $flags "$1" || return 1
      ;;
    linux )
        stat -c '%s' $flags "$1" || return 1
      ;;
    * ) error "filesize: $1?" 1 ;;
  esac
}

filemtime() # File
{
  local flags=- ; file_stat_flags
  case "$uname" in
    darwin )
        trueish "$file_names" && pat='%N %m' || pat='%m'
        stat -f "$pat" $flags "$1" || return 1
      ;;
    linux )
        trueish "$file_names" && pat='%N %Y' || pat='%Y'
        stat -c "$pat" $flags "$1" || return 1
      ;;
    * ) error "filemtime: $1?" 1 ;;
  esac
}

read_nix_style_file()
{
  test -n "$1" || return 1
  test -z "$2" || error "read-nix-style-file: surplus arguments '$2'" 1
  cat $cat_f "$1" | grep -Ev '^\s*(#.*|\s*)$' || return 1
}

read_nix_style_files()
{
  while test -n "$1"
  do
    read_nix_style_file $1
    shift
  done
}

normalize_relative()
{
  OIFS=$IFS
  IFS='/'
  local NORMALIZED

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
            NORMALIZED=$(expr_substr $NORMALIZED 2 ${#NORMALIZED} )
          ;;
      esac
    } || NORMALIZED=.
  case "$1" in
    */ ) echo $NORMALIZED/
      ;;
    * ) echo $NORMALIZED
      ;;
  esac
}

# Change cwd to parent dir with existing local path element (dir/file/..) $1, leave go_to_before var in env.
go_to_dir_with()
{
  test -n "$1" || error "go-to-dir: Missing filename arg" 1

  # Find dir with metafile
  go_to_before=.
  while true
  do
    test -e "$1" && break
    go_to_before=$(basename "$(pwd)")/$go_to_before
    test "$(pwd)" = "/" && break
    cd ..
  done

  test -e "$1" || return 1
}

# Sync: CONF:

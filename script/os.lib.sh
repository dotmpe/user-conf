#!/bin/sh

# OS: files, paths




filesize()
{
  case "$uname" in
    Darwin )
      stat -L -f '%z' "$1" || return 1
      ;;
    Linux )
      stat -L -c '%s' "$1" || return 1
      ;;
  esac
}

filemtime()
{
  case "$uname" in
    Darwin )
      stat -L -f '%m' "$1" || return 1
      ;;
    Linux )
      stat -L -c '%Y' "$1" || return 1
      ;;
  esac
}

read_nix_style_file()
{
  cat $1 | grep -Ev '^\s*(#.*|\s*)$'
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


#!/usr/bin/env bash


# Insert into file using `ed`. Accepts literal content as argument.
# file-insert-at 1:file-name[:line-number] 2:content
# file-insert-at 1:file-name 2:line-number 3:content
file_insert_at_spc=" ( FILE:LINE | ( FILE LINE ) ) INSERT "
file_insert_at()
{
  test -x "$(command -v ed)" || error "'ed' required" 1

  test -n "$*" || error "arguments required" 1

  local file_name= line_number=
  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -e "$file_name" || error "no file $file_name" 1
  test -n "$1" || error "content expected" 1
  echo "$1" | grep -q '^\.$' && {
    error "Illegal ed-command in input stream"
    return 1
  }

  # use ed-script to insert second file into first at line
  # Note: this loses trailing blank lines
  # XXX: should not have ed period command. Cannot sync this function, file-insert-at
  stderr info "Inserting at $file_name:$line_number"
  echo "${line_number}a
$1
.
w" | ed -s $file_name
}


# Replace one entire line
file_replace_at() # ( FILE:LINE | ( FILE LINE ) ) INSERT
{
  file_replace_at_sed "$@"
}


# Replace one entire line using Sed.
file_replace_at_ed() # ( FILE:LINE | ( FILE LINE ) ) INSERT
{
  test -n "$*" || error "arguments required" 1
  test -z "$4" || error "too many arguments" 1

  local file_name= line_number=

  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -e "$file_name" || error "no file: $file_name" 1
  test -n "$line_number" || error "no line_number: $file_name: '$1'" 1
  test -n "$1" || error "nothing to insert" 1

  note "Removing line $file_name:$line_number"
  echo "${line_number}d
.
w" | ed $file_name >/dev/null

  file_insert_at $file_name:$(( $line_number - 1 )) "$1"
}

# XXX: no escape for insert string
file_replace_at_sed()
{
  test -n "$*" || error "arguments required" 1

  local file_name= line_number=

  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -e "$file_name" || error "no file $file_name" 1
  test -n "$line_number" || error "no line_number" 1
  test -n "$1" || error "nothing to insert" 1

  set -- "$( echo "$1" | sed 's/[\#&\$]/\\&/g' )"
  $gsed -i $line_number's#.*#'"$1"'#' "$file_name"
}

get_lines()
{
  test -n "$*" || error "arguments required" 1

  local file_name= line_number=

  fnmatch *:[0-9]* "$1" && {
    file_name=$(echo $1 | cut -f 1 -d :)
    line_number=$(echo $1 | cut -f 2 -d :)
    shift 1
  } || {
    file_name=$1; shift 1
    line_number=$1; shift 1
  }

  test -n "$1" || set -- 1

  tail -n +$line_number $file_name | head -n $1
}

# Sync: U-S:src/sh/lib/str.lib.sh

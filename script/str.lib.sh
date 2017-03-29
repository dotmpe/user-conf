#!/bin/sh


# ID for simple strings without special characters
mkid()
{
  id=$(printf -- "$1" | tr -sc 'A-Za-z0-9\/:_-' '-' )
}

# to filter strings to variable id name
mkvid()
{
  vid=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g')
  # Linux sed 's/\([^a-z0-9_]\|\_\)/_/g'
}
mkcid()
{
  cid=$(echo "$1" | sed 's/\([^a-z0-9-]\|\-\)/-/g')
}


# x-platform regex match since Bash/BSD test wont chooche on older osx
x_re()
{
  echo $1 | grep -E "^$2$" > /dev/null && return 0 || return 1
}

# Use this to easily matching strings based on glob pettern, without
# adding a Bash dependency (keep it vanilla Bourne-style shell).
fnmatch()
{
  case "$2" in $1 ) return 0 ;; *) return 1 ;; esac
}


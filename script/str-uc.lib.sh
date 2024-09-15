#!/usr/bin/env bash

str_uc_lib__load ()
{
  : "${str_uc_fun:=str_indent str_globmatch str_suffix}"
  : "${str_htd_fun:=}"
}

str_uc_lib__init ()
{
  test -z "${str_uc_lib_init-}" || return $_
  ! { "${DEBUG:-false}" || "${DEV:-false}" || "${INIT:-false}"; } ||
  ${LOG:?} notice ":str-uc:lib-init" "Initialized str-uc.lib"
}


# see also fnmatch and wordmatch
str_globmatch () # ~ <String> <Glob-patterns...>
{
  [[ 2 -le $# ]] || return ${_E_GAE:-193}
  declare str=${1:?"$(sys_exc str-globmatch:str@_1 "String expected")"}
  shift
  while [[ $# -gt 0 ]]
  do
    case "$str" in ( ${1:?} ) return ;; * ) ${any:-true} || return 1 ;; esac
    shift
  done
  return 1
}

str_suffix () # (s) ~ <Suffix-str>
{
  local str prefix=${1:?"$(sys_exc str-suffix:str@_1 "Suffix string expected")"}
  while read -r str
  do echo "${str}${suffix}"
  done
}


# Remove ANSI as best as possible in a single sed-regex
ansi_clean ()
{
  echo "$1" | perl -e '
while (<>) {
  s/ \e[ #%()*+\-.\/]. |
    \r | # Remove extra carriage returns also
    (?:\e\[|\x9b) [ -?]* [@-~] | # CSI ... Cmd
    (?:\e\]|\x9d) .*? (?:\e\\|[\a\x9c]) | # OSC ... (ST|BEL)
    (?:\e[P^_]|[\x90\x9e\x9f]) .*? (?:\e\\|\x9c) | # (DCS|PM|APC) ... ST
    \e.|[\x80-\x9f] //xg;
    1 while s/[^\b][\b]//g;  # remove all non-backspace followed by backspace
  print;
}'
  return

  #XXX: I'm not sure what the differences are, or how to change the script even @Regex @Perl
  echo "$1" | perl -e '
#!/usr/bin/env perl
## uncolor — remove terminal escape sequences such as color changes
while (<>) {
    s/ \e[ #%()*+\-.\/]. |
       \e\[ [ -?]* [@-~] | # CSI ... Cmd
       \e\] .*? (?:\e\\|[\a\x9c]) | # OSC ... (ST|BEL)
       \e[P^_] .*? (?:\e\\|\x9c) | # (DCS|PM|APC) ... ST
       \e. //xg;
    print;
}'
}

# Use this to easily matching strings based on glob pettern, without
# adding a Bash dependency
fnmatch () # ~ PATTERN STRING
{
  case "$2" in ( $1 ) return 0 ;; ( * ) return 1 ;; esac
}
# Derive: str_globmatch

# mkid STR '-' '\.\\\/:_'

str_uc_id () # ~
{
  : "${1:?}"
  #: "${_//[^A-Za-z0-9\/:_,.-]/-}"
  # XXX: this doesnt collapse
  : "${_//[^A-Za-z0-9:_,.%+-]/-}"
  "${upper:-false}" "$_" &&
  echo -n "${_^^}" || {
    "${lower:-false}" "$_" &&
    echo -n "${_,,}" || echo -n "$_"
  }
}

str_uc_mkid () # ~ <Var> [<Input>]
{
  local -n __str_uc_mkid_1=${1:?} &&
  __str_uc_mkid_1=$(str_uc_id "${__str_uc_mkid_1:-${2-}}")
}

# Sync-Sh: BIN:str-htd.lib.sh

# Normalize whitespace (replace newlines, tabs, subseq. spaces)
normalize_ws()
{
  [[ "${1-}" ]] || set -- '\n\t '
  tr -s "$1" ' ' # | sed 's/\ *$//'
}

## Put each word into lookup table (with Awk), print on first occurence only (1)
#
# Like remove-dupes but act on words from each line, printing every word not
# yet encountered on a line to stdout.
# The input can contain newlines however these are seen as belonging to the last
# word of that line. Adding a space before the newline introduces blank lines in
# the output that separate the word lists into groups of output per line of input.
#
# This remembers each word of every line read.
# Alternatively use unique-words to de-dupe words only per line.
# To *print* one line of output but still remove all dupe words from a stream
# use the remove-dupe-words-lines variant.
remove_dupe_words () # <words> ... ~
{
  awk 'BEGIN { RS = " " } !a[$0]++'
}

## Put each line into lookup table (with Awk), print on first occurence only
#
# To remove duplicate lines in input, without sorting (unlike uniq -u).
remove_dupes () # <line> ... ~
{
  awk '!a[$0]++'
}

# Output INPUT, concatenated as many times as needed with two the PADding
# strings to reach LENgth.
str_padd () # ~ LEN [PAD [INPUT [PAD]]]
{
  local padding="${3-}" p1="${2-" "}" p2="${4-""}"
  while [ ${#padding} -lt $1 ]; do padding="${p1}$padding${p2}"; done
  printf '%s' "$padding"
}

str_padd_left () # ~ LEN [PAD [INPUT]]
{
  str_padd "$1" "$2" "$3"
}

str_padd_right () # ~ LEN [PAD [INPUT]]
{
  str_padd "$1" "" "$3" "$2"
}

# Treat text as ASCII with other codes, only count ASCII codes.
# Note this may still contain (parts of?) ANSI escaped codes.
str_ascii_len ()
{
  local str
  str="$(echo "$1" | tr -cd "[:print:]")"
  printf '%i' ${#str}
}

# XXX: try to count characters as would be displayed by PS1
str_sh_clean ()
{
  ansi_clean "$1" | sed -e 's/\(\\\(\[\|\]\)\)//g' | tr -d '[:cntrl:]'
}

str_sh_expand_braces ()
{
  eval "echo $*"
}

# Get the length of the string counting the number of visible characters
# Strips ANSI codes and delimiter escapes (for Bash PS1) before count
str_sh_len ()
{
  local str
  str="$(str_sh_clean "$1")"
  printf '%i' ${#str}
}

str_sh_lpadd ()
{
  local raw="${2-}" invis newpadd
  invis=$(( ${#raw} - $(str_sh_len "$raw") ))
  newpadd=$(( $1 + $invis ))
  printf '%'$newpadd's' "$raw"
}

# Treat text as ASCII with Bash-escaped ANSI codes.
# Does not correct for double-byte chars ie. unicode, NERD/Powerline font symbols etc.
str_sh_padd () # ~ LEN [INPUT]
{
  str_sh_lpadd "$@"
}

# XXX: printf cannot this this, could do a substitute on space. Maybe two to
# allow spaces in INPUT.
str_sh_padd_ch () # ~ LEN [PAD [INPUT [PAD]]]
{
  local raw="${3-}" p1="${2-" "}" p2="${4-""}" invis
  invis=$(( ${#raw} - $(str_sh_len "$raw") ))
  while [ $(( ${#raw} - $invis )) -lt $1 ]; do raw="${p1}$raw${p2}"; done
  printf '%s' "$raw"
}

str_sh_rpadd ()
{
  local raw="${2-}" invis newpadd
  invis=$(( ${#raw} - $(str_sh_len "$raw") ))
  newpadd=$(( $1 + $invis ))
  printf '%-'$newpadd's' "$raw"
}

# Remove last n chars from stream at stdin
strip_last_nchars() # Num
{
  rev | cut -c $(( 1 + $1 ))- | rev
}

## Put each word into lookup table per line, print each first occurence only on that line
#
# A loop calling remove-dupe-words on each line of input.
# The last line must be followed by newline or it is ignored.
unique_line_words ()
{
  while IFS= read -r line
  do printf '%s' "$line" | unique_words; echo
  done
}

## Put each word into lookup table (with Awk), print on first occurence only (2)
#
# Unlike remove-dupe-words this prints one line of output per line of input.
# To remove newlines completely, these need to be removed from input
# as wel or just filtered on output with lines-to-words.
# See remove-dupes and remove-dupe-words for variants.
#
# To only remove words per-line, call for every line.
# See unique-line-words.
unique_words () # <words> ... ~
{
  awk 'BEGIN { RS = " "; ORS = " " } !a[$0]++'
}

# [2024-07-05] new style str id funs for uc use

uc_id () # ~ <Value> <Extra> <Subst>
{
  <<< "${1:?}" uc_sid "${2-}" "${3-}"
}

uc_sid () # (s) ~ [<Extra>] [<Subst>]
{
  if_ok "$(</dev/stdin tr -sc 'A-Za-z0-9'"${1:-"\/:_,.-"}" "${2:-"-"}")" &&
  "${upper:-false}" "$_" &&
  echo "${_^^}" || {
    "${lower:-false}" "$_" && echo "${_,,}" || echo "$_"
  }
}

uc_mkid () # ~ <Value> <Extra> <Subst>
{
  id=$(uc_id "$@")
}

# mkvid: see str-vword vid <string>

uc_wordid ()
{
  uc_id "$1" "${2-}" "_"
}

# Derive: U-S:src/sh/lib/str.lib.sh

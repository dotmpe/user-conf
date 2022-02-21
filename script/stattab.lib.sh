#!/usr/bin/env bash

stattab_lib_load ()
{
  test -n "${HOME-}" || HOME=/srv/home-local
  test -n "${STTTAB-}" || STTTAB=$HOME/.local/var/stttab.list
}

stattab_lib_init ()
{
  test -n "${STTTAB-}" || {
    $LOG error ":stattab.lib:init" "Expected STTTAB" "$STTTAB"
    return 1
  }
  test -e "$STTTAB" || {
    test ${init:-0} -eq 0 && {
        $LOG error ":stattab.lib:init" "Expected existing STTTAB" "$STTTAB"
        return 1
      }
    mkdir -p "$(dirname "$STTTAB")" && touch "$STTTAB" || return
  }
}

# Assuming entry is updated replace or add to Stat-Tab
stattab_commit () # ~
{
  stattab_exists && {

# XXX: observe different Id types in replace as well like in grep, probably..
    local p_=$stttab_id
    #$(match_grep "$stttab_id")
    $gsed -i 's/^[0-9 +-]* '$p_':.*$/'"$(stattab_entry)"'/' "$STTTAB"
    return
  } || {
    stattab_entry >>"$STTTAB"
  }
}

# Parse date-id
stattab_date ()
{
  fnmatch "@*" "$1" && echo "${1:2}" || date_pstat "$1"
}

# Prepare env for Stat-Id
stattab_env_init () # [stattab] ~ [St]
{
  stattab_entry_env_reset && {
    test -z "$1" || {
      stattab_entry_init "$1" && shift
  } } && stattab_entry_defaults "$@"
}

stattab_entry () #
{
  echo "${stttab_status:--}"\
" $(date_id "@$stttab_btime")"\
" $(date_id "@$stttab_ctime")"\
" $(test -n "$stttab_utime" && date_id "@$stttab_utime" || echo "-")"\
" ${stttab_directives:--} ${stttab_passed:--} ${stttab_skipped:--}"\
" ${stttab_errors:--} ${stttab_failed:--} $stttab_vid: $stttab_short"\
" $stttab_tags" | normalize_ws
}

stattab_entry_id () # STVID [STID]
{
  test $# -gt 1 || set -- "$1" "$(mkid "$1" && printf "$id")"
  stttab_vid="$1"
  stttab_id="$2"
}

stattab_entry_init () # STVID [STID]
{
  stattab_entry_id "$@" &&
  echo "$stttab_id" | grep -q '^[A-Za-z_][A-Za-z0-9_-]*$' ||
      error "Illegal ST name '$stttab_id'" 1
}

stattab_entry_env_reset ()
{
  stttab_status=
  stttab_btime=
  stttab_ctime=
  stttab_utime=
  stttab_directives=
  stttab_passed=
  stttab_skipped=
  stttab_erred=
  stttab_failed=
  stttab_vid=
  stttab_short=
  stttab_tags=

  stttab_entry=
  stttab_stat=
  stttab_record=
  stttab_id=
  stttab_primctx=
  stttab_primctx_id=
  stttab_tags_raw=
}

stattab_entry_defaults () # Tags
{
  local now="$(date +'%s')"
  stattab_value "${stttab_btime:-}" || stttab_btime=$now
  stattab_value "${stttab_ctime:-}" || stttab_ctime=$now
}

# Parse statusdir index file line
stattab_entry_parse () # [entry] ~
{
  test $# -eq 0 || return 64
  # Split rest into three parts (see stattab format), first stat descriptor part
  stttab_stat="$(echo "$stttab_entry" | grep -o '^[^_A-Za-z]*' )"
  stttab_record="$(echo "$stttab_entry" | sed 's/^[^_A-Za-z]*//' )"
  debug "Parsing descriptor '$stttab_stat' and record '$stttab_record'"
  stattab_parse_STD_stat $stttab_stat
  stattab_record_parse
  stattab_entry_defaults
}

stattab_exists () # [<Stat-Id>] [<Stat-Tab>] [<Entry-Type>]
{
  grep_f=${grep_f:-"-q"} \
    stattab_grep "${1:-$stttab_id}" "${3:-"id"}" "${2:-$STTTAB}"
}

# Retrieve and parse entry from table
stattab_fetch () # ~ [<Sttab-Id>] [<Search-Type>] [<Stat-Tab>]
{
  local fetch_id=${1:-"${stttab_id:-}"}
  test -n "${fetch_id:-}" || return 64
  stattab_parse "$(grep_f="-m1 -n" stattab_grep "$fetch_id" "${2:-"id"}" "${3:-"$STTTAB"}")"
}

# Take tab output and perform some sort of grep
stattab_grep () # ~ <Sttab-Id> [<Search-Type>] [<Stat-Tab>]
{
  { true "${generator:=stattab_tab}"
    $generator "" "${3-}" || ignore_sigpipe
    return $?
  } | {
    test "unset" != "${grep_f-"unset"}" || local grep_f=-m1
    local p_=$(match_grep "$1")
    case "${2:-"local"}" in
      ( id )
          $ggrep $grep_f "^[0-9 +-]* $p_:\\?\\(\\ \\|\$\\)" ;;

      ( * ) false ;;
    esac
  }
}

stattab_ids ()
{
  $gsed -E 's/^[0-9 T+-]+ ([A-Za-z0-9:$%&@_\.+-]+):.*$/\1/'
}

stattab_init ()
{
  test -s "$STTTAB" && return
  mkdir -vp "$(dirname "$STTTAB")" &&
  { cat <<EOM
# [Status] [BTime] CTime UTime [Dirs Pass Skip Err Fail Tot] Name-Id: Short @Ctx +Proj
# Id: _CONF                                                        ex:ft=todo:
EOM
} >"$STTTAB"
}

# List ST-Id's only from tab output
stattab_list () # ? LIST
{
  test -n "${2-}" || set -- "${1-}" "$STTTAB"
  stattab_tab "$@" | stattab_ids
}

# Parse entry from Grep-line
stattab_parse () # ~ <Grep-Line>
{
  test $# -gt 0 || return 64
  test -n "$*" || return 60
  stattab_entry_env_reset
  # Remove grep-line filename/linenumber from entry and parse
  stttab_entry="$*"
  stttab_lineno="$(echo "$stttab_entry" | cut -d : -f 1)"
  debug "Parsing Grep-Line found at '$stttab_lineno'"
  stttab_entry="$(echo "$stttab_entry" | cut -d : --output-delimiter : -f 2-)"
  stattab_entry_parse
}

stattab_parse_STD_ids ()
{
  test -z "${1-}" || stattab_entry_id "$1"
}

stattab_parse_STD_stat () # ~ [Status] [BTime] [CTime] [UTime] [Dirs] [Passed] [Skipped] [Error] [Failed]
{
  ! stattab_value "${1-}" || stttab_status=$1
  ! stattab_value "${2-}" || stttab_btime="$(stattab_date "$2")"
  ! stattab_value "${3-}" || stttab_ctime="$(stattab_date "$3")"
  ! stattab_value "${4-}" || stttab_utime="$(stattab_date "$4")"
  ! stattab_value "${5-}" || stttab_directives=$5
  ! stattab_value "${6-}" || stttab_passed=$6
  ! stattab_value "${7-}" || stttab_skipped=$7
  ! stattab_value "${8-}" || stttab_erred=$8
  ! stattab_value "${9-}" || stttab_failed=$9
}

# Set to new given entry and add it to table directly
stattab_record () # ~ <Entry>
{
  test $# -gt 0 || return 64
  test -n "$*" || return 60
  stattab_entry_env_reset
  stttab_entry="$*"
  stattab_entry_parse &&
  stattab_entry >>"$STTTAB"
}

stattab_record_parse ()
{
  # stattab_parse ID_SPEC TAGS META SHORT

  stttab_idspec="$(echo "$stttab_record"|cut -d':' -f1)"
  stattab_parse_STD_ids $stttab_idspec

  stttab_rest="$(echo "$stttab_record"|cut -d : --output-delimiter : -f2-)"
  # XXX: Stop short description at first tag?
  stttab_short="$(echo "$stttab_rest"|$gsed 's/^\([^[+@<]*\).*$/\1/'|normalize_ws)"

  stttab_refs="$(echo "$stttab_rest"|$ggrep -Po '(?<=<)[^ ]+(?=>)'|normalize_ws)"

  stttab_ids="$(echo "$stttab_rest"|$ggrep -Po '(?<=#)[^ ]+(?= |$)'|normalize_ws)"

  stttab_meta="$(echo "$stttab_rest"|$ggrep -Po '[^ ]+:[^ ]+'|normalize_ws)"

  # FIXME: seems like an old regex
  stttab_tags_raw="$(echo "$stttab_rest"|$gsed 's/^[^\[+@<]*//'|normalize_ws)"
  stttab_tags="$(echo "$stttab_tags_raw"|$ggrep -o '[+@][^ ]*'|normalize_ws)"
}

# List entries; first argument is glob, converted to (grep) line-regex
stattab_tab () # <Match-Line> [<Stat-Tab>]
{
  test -n "$2" || set -- "$1" "$STTTAB"
  test "$1" != "*" || set -- "" "$2"
  test -n "$1" && {
    test -n "${grep_f-}" || local grep_f=-P
    $ggrep $grep_f "$(compile_glob "$1")" "$2" || return
  } || {
    read_nix_style_file "$2" || return
  }
}

stattab_update () # ~ <Entry>
{
      stttab_status="${1:-"${new_tab_status:-"$stttab_status"}"}"
       stttab_btime="${2:-"${new_tab_btime:-"$stttab_btime"}"}"
       stttab_ctime="${3:-"${new_tab_ctime:-"$stttab_ctime"}"}"
       stttab_utime="${4:-"${new_tab_utime:-"$stttab_utime"}"}"
  stttab_directives="${5:-"${new_tab_directives:-"$stttab_directives"}"}"
      stttab_passed="${6:-"${new_tab_passed:-"$stttab_passed"}"}"
     stttab_skipped="${7:-"${new_tab_skipped:-"$stttab_skipped"}"}"
       stttab_erred="${8:-"${new_tab_erred:-"$stttab_erred"}"}"
      stttab_failed="${9:-"${new_tab_failed:-"$stttab_failed"}"}"

  # XXX: the vid can be updated as well, may want to check wether new VId==Id
        stttab_vid="${10:-"${new_tab_vid:-"$stttab_vid"}"}"
  # XXX: these may have whitespace and need to be quoted, or change this to wark
  # like parser.
      stttab_short="${11:-"${new_tab_short:-"$stttab_short"}"}"
       stttab_tags="${12:-"${new_tab_tags:-"$stttab_tags"}"}"
}

stattab_value () # ~ <Value>
{
  test -n "${1-}" -a "${1-}" != "-"
}

#

#!/usr/bin/env bash

### StatTab-UC

# Functions to tetrieves record using fetch/grep and parse them.

# Started adding psuedo-class to deal with simultaneous instances.


stattab_uc_lib__load ()
{
  lib_require str-uc todotxt || return
  # XXX: lib_require_alt str-htd str-uc || return
  #lib_require str-uc || return
  test -n "${HOME-}" || HOME=/srv/home-local
  test -n "${STTTAB-}" || STTTAB=$HOME/.local/var/stttab.list
  : "${ctx_class_types:="${ctx_class_types-}${ctx_class_types+" "}StatTabEntry StatTab"}"
  : "${stattab_var_keys:=status btime ctime utime short refs idrefs meta}"
}


# Assuming entry is updated replace or add to Stat-Tab
stattab_commit () # ~ [<Stat-Tab>]
{
  test -n "${1-}" || set -- $STTTAB
  stattab_exists "" "" "$1" && {

# XXX: observe different Id types in replace as well like in grep, probably..
    local p_=$stttab_id
    #$(match_grep "$stttab_id")
    $gsed -i 's/^[0-9 +-]* '$p_':.*$/'"$(stattab_entry)"'/' "$1"
    return
  } || {
    stattab_entry >>"$1"
  }
}

# Parse date-id
stattab_date ()
{
  fnmatch "@*" "$1" && echo "${1:2}" || date_pstat "$1"
}

# Parse Entry or set all defaults
stattab_init () # ~ [<Entry>]
{
  stattab_entry_env_reset && {
    test $# -eq 0 || {
      stattab_entry_init "$@" && shift
  } } && stattab_entry_defaults
}

stattab_entry () #
{
  echo "${stttab_status:--}"\
" $(date_id "@$stttab_btime")"\
" $(date_id "@$stttab_ctime")"\
" $(test -n "$stttab_utime" && date_id "@$stttab_utime" || echo "-")"\
" ${stttab_directives:--} ${stttab_passed:--} ${stttab_skipped:--}"\
" ${stttab_errors:--} ${stttab_failed:--} $stttab_id: $stttab_short"\
" $stttab_tags" | normalize_ws
}

stattab_entry_id () # ~ <StatTab-SId> [<StatTab-Id>]
{
  test $# -gt 1 || set -- "$1" "$(mkid "$1" && printf "$id")"
  stttab_sid="$1"
  stttab_id="$2"
}

stattab_entry_init () # ~ [<Entry>]
{
  stattab_entry_env_reset
  stttab_entry="$*"
  stattab_entry_parse &&

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
  stttab_sid=
  stttab_short=
  stttab_refs=
  stttab_idrefs=
  stttab_meta=
  stttab_tags_raw=
  stttab_tags=

  stttab_lineno=
  stttab_entry=
  stttab_stat=
  stttab_record=
  stttab_id=
  stttab_primctx=
  stttab_primctx_id=
}

stattab_entry_defaults () # ~
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
  $LOG debug : "Parsing descriptor and record" "'$stttab_stat':'$stttab_record'"
  stattab_parse_STD_stat $stttab_stat &&
  stattab_record_parse
}

stattab_exists () # [<Stat-Id>] [<Entry-Type>] [<Stat-Tab>]
{
  grep_f=${grep_f:-"-q"} \
    stattab_grep "${1:-$stttab_id}" "${2:-"id"}" "${3:-$STTTAB}"
}

# Retrieve and parse entry from table
stattab_fetch () # ~ [<Stat-Id>] [<Search-Type>] [<Stat-Tab>]
{
  local fetch_id=${1:-"${stttab_id:-}"}
  test -n "${fetch_id:-}" || return 64
  stttab_src=${3:-}
  stattab_parse "$(grep_f="-m1 -n" stattab_grep "$fetch_id" "${2:-"id"}" "${3:-"$STTTAB"}")"
}

# Take tab output and perform some sort of grep
stattab_grep () # ~ <Stat-Id> [<Search-Type>] [<Stat-Tab>]
{
  { true "${generator:=stattab_tab}"
    $generator "" "${3-}" || ignore_sigpipe
    return $?
  } | {
    test "unset" != "${grep_f-"unset"}" || local grep_f=-m1
    local p_=$(match_grep "$1")
    case "${2:-"id"}" in
      ( id )
          $ggrep $grep_f "^[0-9 +-]* $p_:\\?\\(\\ \\|\$\\)" ;;

      ( * ) $LOG error : "No such search-type" "$2" 1 ;;
    esac
  }
}

stattab_ids ()
{
  $gsed -E 's/^[0-9 T+-]+ ([A-Za-z0-9:$%&@_\.+-]+):.*$/\1/'
}

stattab_tab_init () # ~ [<Stat-Tab>]
{
  test $# -le 1 || return 177
  test -n "${1-}" || set -- "$STTTAB"
  test -s "$1" && return
  mkdir -vp "$(dirname "$1")" &&
  { cat <<EOM
# [Status] [BTime] CTime UTime [Dirs Pass Skip Err Fail Tot] Name-Id: Short @Ctx +Proj
# Id: _CONF                                                        ex:ft=todo:
EOM
} >"$1"
}

# List ST-Id's only from tab output
stattab_list () # ~ [<Match-Line>] [<Stat-Tab>]
{
  stattab_tab "$@" | stattab_ids
}

stattab_list_field_ () # ~
{
  local field=${1:?}; shift;
  read_nix_style_file "$@" | todotxt_field_${field//-/_}
}

stattab_list_ () # ~ ( context-tags | chevron-refs | meta-tags | hash-tags | project-tags )
{
  local field=${1:?}; shift;
  stattab_tab "$@" | todotxt_field_${field//-/_}
}

# Parse entry from Grep-line
stattab_parse () # ~ <Grep-Line>
{
  test $# -gt 0 || return 64
  test -n "$*" || return 60
  stattab_entry_env_reset
  # Remove grep-line filename/linenumber from entry and parse
  stttab_lineno="$(echo "$*" | cut -d : -f 1)"
  #debug "Parsing Grep-Line found at '$stttab_lineno'"
  stttab_entry="$(echo "$*" | cut -d : --output-delimiter : -f 2-)"
  stattab_entry_parse ||
    $LOG error :stattab-parse "Parsing entry" E$?:L$stttab_lineno:$stttab_src $?
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
  stattab_entry_init "$@" &&
  stattab_entry_defaults &&
  stattab_entry >>"$1"

  stattab_commit >>"$1"
}

stattab_record_parse ()
{
  # stattab_parse ID_SPEC TAGS META SHORT

  stttab_idspec="$(echo "$stttab_record"|cut -d':' -f1)"
  stattab_parse_STD_ids $stttab_idspec

  stttab_rest="$(echo "$stttab_record"|cut -d : --output-delimiter : -f2-)"
  # XXX: Stop short description at first tag?
  stttab_short="$(echo "$stttab_rest"|$gsed 's/^\([^[+@<]*\).*$/\1/'|normalize_ws)"

  stttab_refs="$(todotxt_field_chevron_refs <<< "$stttab_rest")"
  stttab_idrefs="$(todotxt_field_hash_tags <<< "$stttab_rest")"
  stttab_meta="$(todotxt_field_meta_tags <<< "$stttab_rest")"

  # FIXME: seems like an old regex
  stttab_tags_raw="$(echo "$stttab_rest"|$gsed 's/^[^\[+@<]*//'|normalize_ws)"
  stttab_tags="$(todotxt_field_context_tags <<< "$stttab_tags_raw")"

  true
}

# List entries; first argument is glob, converted to (grep) line-regex.
# FIXME: combine read-nix regex with match-glob
stattab_tab () # ~ [<Match-Line>] [<Stat-Tab>]
{
  test -n "${2-}" || set -- "${1-}" "$STTTAB"
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

  # XXX: the id can be updated as well, may want to check wether new VId==Id
         stttab_id="${10:-"${new_tab_id:-"$stttab_id"}"}"
  # XXX: these may have whitespace and need to be quoted, or change this to wark
  # like parser.
      stttab_short="${11:-"${new_tab_short:-"$stttab_short"}"}"
       stttab_tags="${12:-"${new_tab_tags:-"$stttab_tags"}"}"
}

stattab_value () # ~ <Value>
{
  test -n "${1-}" -a "${1-}" != "-"
}


class.StatTabEntry.load () # ~
{
  declare -g -A StatTabEntry__btime=()
  declare -g -A StatTabEntry__ctime=()
  declare -g -A StatTabEntry__utime=()
  declare -g -A StatTabEntry__id=()
  declare -g -A StatTabEntry__short=()
  declare -g -A StatTabEntry__tags=()
}

class.StatTabEntry () # ~ <ID> .<METHOD> <ARGS...>
#   .StatTabEntry <Entry...>
#   XXX: .StatTabEntry <Type> [<Src:Line>] - constructor
#   .tab-ref
#   .tab
#   .get
#   .set
#   .update
#   .commit
{
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- $1 .toString
  local name=StatTabEntry super_type=Class self super id=$1 m=$2
  shift 2
  self="class.$name $id "
  super="class.$super_type $id "

  case "$m" in
    ".$name" ) $super.$super_type "$@"
      ;;
    ".__$name" ) $super.__$super_type
        unset StatTabEntry__status[$id]
        unset StatTabEntry__btime[$id]
        unset StatTabEntry__ctime[$id]
        unset StatTabEntry__utime[$id]
        unset StatTabEntry__id[$id]
        unset StatTabEntry__short[$id]
        unset StatTabEntry__tags[$id]
        unset StatTabEntry__refs[$id]
      ;;

    .tab-ref ) echo "class.StatTab ${Class__instances[$id]} " ;;
    .tab ) $($self.tab-ref).tab ;;

    .get )
        StatTabEntry__status[$id]=$stttab_status
        StatTabEntry__btime[$id]=$stttab_btime
        StatTabEntry__ctime[$id]=$stttab_ctime
        StatTabEntry__utime[$id]=$stttab_utime
        StatTabEntry__id[$id]=$stttab_id
        StatTabEntry__short[$id]=$stttab_short
        StatTabEntry__tags[$id]=$stttab_tags
        StatTabEntry__refs[$id]=$stttab_refs
      ;;
    .set )
        stttab_status=${StatTabEntry__status[$id]}
        stttab_btime=${StatTabEntry__btime[$id]}
        stttab_ctime=${StatTabEntry__ctime[$id]}
        stttab_utime=${StatTabEntry__utime[$id]}
        stttab_id=${StatTabEntry__id[$id]}
        stttab_short=${StatTabEntry__short[$id]}
        stttab_tags=${StatTabEntry__tags[$id]}
        stttab_refs=${StatTabEntry__refs[$id]}
      ;;

    .update )
        $self.set &&
        stattab_update "$@" &&
        $self.get
      ;;
    .commit )
        $self.set &&
        stattab_commit $($($self.tab-ref).tab-ref)
      ;;

    .attr ) # ~ <Name-key>
        : "StatTabEntry__${1//-/_}"
        echo "${!_[$id]}"
      ;;
    .var ) # ~ <Var-key>
        : "stttab_${1//-/_}"
        echo "${!_}"
      ;;

    .todotxt-field ) # ~ <Field-key>
        #local field=${1:?}
        #shift
        #todotxt_field_${field//-/_} <<< "$"
      ;;

    .class-context ) class.tree .tree ;;
    .info | .toString ) class.info ;;

    * ) $super$m "$@" ;;
  esac
}

class.StatTab () # ~ <ID> .<METHOD> <ARGS...>
#   .StatTab <Tab> [<EntryType>]         - constructor
#   .tab
#   .tab-exists
#   .tab-init
#   .exists <Entry-Id> <Type>
#   .init
#   .fetch <Var-Name> <Entry-Id>
#   .update
#   .commit
{
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- $1 .toString
  local name=StatTab super_type=Class self super id=$1 m=$2
  shift 2
  self="class.$name $id "
  super="class.$super_type $id "

  case "$m" in
    ".$name" )
        test -e "${2:-}" ||
            $LOG error : "Tab file expected" "$2" 1 || return
        $super.$super_type "$1" "$2" "${3:-StatTabEntry}"
      ;;
    ".__$name" ) $super.__$super_type ;;

    .tab ) stattab_tab "${1:-}" "$($self.tab-ref)" ;;
    .tab-ref )
        : "$($self.params)" && : "${_/ *}" && echo "$_"
      ;;
    .tab-entry-class )
        : "$($self.params)" && : "${_/* }" && echo "$_"
      ;;
    .tab-exists ) test -s "$($self.tab-ref)" ;;
    .tab-init ) stattab_tab_init "$($self.tab-ref)" ;;
    .list|.ids|.keys ) # ~ [<Key-match>]
        stattab_list "${1:-}" "$($self.tab-ref)"
      ;;

    .exists ) stattab_exists "$1" "" "$($self.tab-ref)" ;;
    .init ) local var=$1; shift
        stattab_init "$@" &&
        create "$var" StatTabEntry "$id"
      ;;
    .fetch ) # ~ <Var-name> <Stat-id>
        stattab_fetch "$2" "" "$($self.tab-ref)" &&
        $LOG info : "Retrieved $($self.class) entry" "$1=$_:E$?" $? &&
        create "$1" $($self.tab-entry-class) "$id" "$stttab_src:$stttab_lineno" &&
        ${!1}.get
      ;;

    .class-context ) class.tree .tree ;;
    .info | .toString ) class.info ;;

    * ) $super$m "$@" ;;
  esac
}

# Derive: BIN:

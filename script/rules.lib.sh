#!/usr/bin/env bash

### Track sets of commands


#shellcheck disable=2015,2086,2162


rules_lib__load ()
{
  true "${RULE_EXT:=.list}"
  true "${RULE_NS:=user/rules}"
  true "${RULE_DIRS:=$UCONF $U_C $U_S}"
  true "${LCACHE_DIR:=.meta/cache}"

  true "${_E_next:=196}" # std:states
  true "${_E_stop:=197}" # std:states
}

rules_lib__init()
{
  lib_require env-main
}


rule_run () # (s) ~ <Ns>
{
  case "${1:-$RULE_NS}" in
    ( user/diag ) rule_run__diag ;;
    # TODO other rule sets maybe with other automatic contexts
    ( user/rules ) rule_run__xxx ;;
    ( user/tasks ) rule_run__xxx ;;
    ( * ) $LOG error "" "Unknown rule set" "${1:-}"; return 1;;
  esac
}

rule_run__diag () # (:rr)
{
  local atime utime ltime lvl rstat stdl errl cwd sh cmdline
  ${read:-read -r} atime utime ltime lvl rstat stdl errl sh cwd cmdline ||
    return $_E_stop

  # Process shell spec as part EC id, part shell session type spec
  env_box_spec=${sh//[^@a-z0-9-]}
  sh_spec=${sh//[@a-z0-9-]}
  test "$env_box_spec" != "-" || env_box_spec=$hostname

  # Resolve groups or named EC
  local env_box_ls env_box_l env_box_n
  env_box_get "$env_box_spec" || {
    $LOG error "" "EC not found" "$sh"
    return $_E_next
  }

  # Parse rest as session-type spec
  shell=$(rule_sh_spec "$sh_spec") || return

  # Now we have the EC instance(s),
  rule_stat "$cmdline" "$cwd" $env_box_spec
  return

  test $env_box_n -gt 1 && {
    echo "$env_box_ls" |
        while read -r env_box_uuid env_box_nameid env_box_type env_box_specs
        do
          rule_run__diag__item
        done ||
            return $_E_next
  } || {
    read -r env_box_uuid env_box_nameid env_box_type env_box_specs <<< "$env_box_l"
    rule_run__diag__item ||
        return $_E_next
  }
}

rule_run__diag__item ()
{
  # env_box_stat "$env_box_uuid:$rule_cmdid"


  # Assemble command script
  cmd="$cmdline"

  test - = "$cwd" && cwd=/ || {
    # XXX: we can run pre-run check for local command working directory
    test -d "$cwd" || {
      $LOG warn "" "No such local directory" "$cwd"
      return $_E_next
    }
  }
  cmd="cd $cwd && $cmd"

  test - = "$rstat" ||
    cmd="{ $cmd; } || { r=\$?; test \$r -eq $rstat || exit \$r; }"

  $LOG note "" "Executing $lvl" "$sh $cwd $cmdline"
  $shell "$cmd" || echo E$?
}

rule_sh_spec () # ~ <Spec-> # Resolve shell specifiers
{
  local sh_spec="${1:-}"
  set -- ${SHELL_NAME:?} -
  while test -n "$sh_spec"
  do
    case "$sh_spec" in
        ( *"%"* ) set -- "$*l" ; sh_spec=${sh_spec//%} ;;
        ( *":"* ) set -- "$*i" ; sh_spec=${sh_spec//:} ;;
        ( *"#"* ) set -- sudo "$*" ; sh_spec=${sh_spec//#} ;;

        ( * ) $LOG error "" "Unkown shell spec" "$sh_spec"; return 1 ;;
    esac
  done
  echo "$*c"
}

rule_stat ()
{
  false
}


rules_clear_cache ()
{
  dir_act=rules_dir_clean_cache rules_dirs_do "$@"
}

rules_dir_clean_cache () # ~ <Path> <Ns>
{
  test -d "${1:?}/$LCACHE_DIR/${2:?}" || return 0
  rules_dir_files "$1" "$2" |
      sed 's#'"$1/$2/"'##' | while ${read:-read -r} t
        do
          #shellcheck disable=2154
          test ! -e "$1/$LCACHE_DIR/$2/$t" || rm -v "$1/$LCACHE_DIR/$2/$t"
        done
}

rules_dir_files () # ~ <Path> <Ns> [<Exclude-Name-Glob>]
{
  find "${1:?}/${2:?}" -type f -iname "*${RULE_EXT:?}" -not -iname "${3:-.*}"
}

rules_dir_user_files () # ~ <Path> <Ns>
{
  rules_dir_files "${1:?}" "${2:?}" '[_.]*' |
      sed -e 's#'"$1/$2/"'#'"$1"' '"$2"' #' -e 's#'"${RULE_EXT:?}"'$##'
}

rules_dirs_do () # ~ [<Ns...>]
{
  test $# -gt 0 || set -- $RULE_NS
  local d b
  for d in ${RULE_DIRS:?}
  do
    for b in "${@:?}"
    do
      test "$b" = "--" && break
      test -d "$d/$b" || continue
      ${dir_act:-rules_dir_files} "$d" "$b"
    done
  done
}

rules_file_build ()
{
  local lk=${lk:-:rules}:build first=${first:-true} first_only=
  "${top:-false}" && first_only=true || first_only=false

  grep -q '^ *#include ' "${1:?}/${2:?}/${3:?}${RULE_EXT:?}" && {
    rules_file_preproc "$1" "$2" "$3" || return
    $LOG info "$lk" "Found cached rule file" "$1 $2 $3"
  } || {
    $first_only && ! $first || echo "$1 $2 $3"
  }
}

rules_file_preproc ()
{
  true "${ext:=${RULE_EXT:?}}"

  set -- "${1:?}" "${2:?}" "${3:?}" "$1/$LCACHE_DIR/$2/$3$ext"

  # Skip fresh files
  test "$1/$2/$3$ext" -ot "$4" && {
    $first_only && ! $first || echo "$1 $LCACHE_DIR/$2 $3"
    return
  }

  # Recurse to pre-proc referenced files, then process current one and
  # finally report d/b/t on stdout if options ask for it.

  local lk=${lk:-:rules}:preproc
  $LOG debug "$lk" "Updating cache" "${1:?} ${2:?} ${3:?}"
  mkdir -p "$(dirname "$4")" && {

    list_include_refs include "$1/$2/$3$ext" rules_resolve_ref |
        while ${read:-read -r} ref file
        do
          local ns_vid lname fname
          #shellcheck disable=2154
          rules_ref "$ref"
          first=false rules_file_build "${!ns_vid:?}" "$2" "${lname:?}"
        done
  } && {

    {
      echo "# Build <$1::$3> at $(date --iso=sec)"
      expand_preproc include "$1/$2/$3$ext" rules_resolve_ref |
          sed 's/^ *#include /\n# Source: /g' |

          # Strip empty comments, preproc, and metadata
          grep -v '^ *#\([^ ].*\| *\| @.*\)$'

          # TODO: should want to collapse multiple blank lines into one, not strip them

          # Strip empty comments, preproc and empty lines
          #grep -v '^ *\(#\([^ ].*\| *\)\|\)$'

    } > "${4:?}"
  } && {

    $first_only && ! $first || echo "$1 $LCACHE_DIR/$2 $3"
  }
}

rules_files () # ~ [<Bases...>]
{
  dir_act=rules_dir_user_files rules_dirs_do "$@"
}

rules_files_cached () # ~ [<Rules-Files-argv...>]
{
  local first
  rules_files "$@" | while ${read:-read -r} d b t
      do
        rules_file_build "$d" "$b" "$t" | sponge
      done
}

rules_reader () # ~ [<Rules-Files-Cached-argv...>] -- <Selector>
{
  local more_args='' more_argc lk=${lk:-:rules}:reader
  args_has_seq "$@" && {
      args_q=0 args_more "$@" && shift ${more_argc:?}
    }
  args_is_seq "$@" && shift

  top=true rules_files_cached $more_args | {
    act="${1:-lines}"
    test $# -eq 0 || shift
    while ${read:-read -r} d b t
    do
      case "$act" in

        ( raw )
            cat "$d/$b/$t$RULE_EXT"
          ;;

        ( raw-code )
            $LOG info "$lk:$act" "Reading formatted data and comment lines" "$d::$t"
            # NOTE: if we start removing empty lines, line comments turn into
            # one block (and we need more regex info to correct with collapse).
            # Instead, just let user group comment blocks. Works fine that way.
            line_comments_collapse < "$d/$b/$t$RULE_EXT" |
                line_comment_conts_collapse | filter_empty_lines
          ;;

        ( raw-lines )
            $LOG info "$lk:$act" "Reading collapsed data and comments" "$d::$t"
            filter_empty_lines < "$d/$b/$t$RULE_EXT" |
                line_conts_collapse | line_comments_collapse | tr -s ' '
          ;;

        ( lines )
            $LOG info "$lk:$act" "Reading compiled table" "$d::$t"
            line_conts_collapse < "$d/$b/$t$RULE_EXT" |
                filter_content_lines | tr -s ' '
          ;;

        ( blocks )
            $LOG info "$lk:$act" "Reading blocks from compiled table" "$d::$t"
            read=read_literal read_blocks "${@:?}" < "$d/$b/$t$RULE_EXT"
          ;;

        ( * ) $LOG error "$lk" "No such action" "$act"; return 1;;
      esac
    done
  }
}

rules_ref () # (v) ~ <Ref> # Parse <Ref> into <ns_vid,{l,f}name>
{
  ns_vid=${1//:*}
  lname="${1//*:}"
  fname="$lname${RULE_EXT:?}"
}

rules_resolve_ref () # ~ <Ref> [<From>] # XXX: parses only VAR:name refs \
# No other name or ID lookups.
{
  local ns_vid lname fname file
  rules_ref "${1:?}"
  file="${!ns_vid:?}/${RULE_NS:?}/${fname:?}"
  test -e "$file" || {
    $LOG warn "${lk:-:rules}:resolve-ref" \
        "Cannot resolve reference" "ref:$1${2:+ file:}${2:-}"
    return 9
  }
  { test ${cache:-0} -eq 1 && grep -q '^ *#include ' "$file"
  } \
    && echo "${!ns_vid}/$LCACHE_DIR/$RULE_NS/$fname" \
    || echo "$file"
}

rules_list () # (:u) ~ [<Ns>] [<:Rules-select...>] # Simple wrapper to run rules-select
{
  local ns=${1:-$RULE_NS} ql=${2:-1} lk=${lk:-:rules}:list; shift 2
  RULE_NS=$ns rules_select "$ql" "$@"
}

rules_run () # (:u) ~ [<Ns>] [<Ql>] [<:Rs-select...>] # Pipe rule-select to rule-run handler \
# Builds on the rules-select's 'lines' formatted output, but the actual reading
# is up to the handler. See rule-run.
{
  local ns=${1:-$RULE_NS} ql=${2:-1} lk=${lk:-:rules}:run; shift 2
  RULE_NS=$ns rules_select "$ql" "$@" | while true
      do
        rule_run $ns || {
          ignore_stat eq $_E_next && continue || {
            ignore_stat eq $_E_stop && break || return
          }
        }
      done
}

# This complex function serves to a) select the proper reader, b) the proper
# format or translator and c) an optional output filter, all based on the given
# list of arguments.
#
# XXX: There are a few use-cases here, and not all are implemented
rules_select () # ~ [<Level>] [<Header> <Glob>] [<Cmd-Regex>] [<Format>]
{
  local qs ns=${ns:-$RULE_NS}
  #shellcheck disable=2016 # using single quotes on AWK expression
  #test "${1:-1}" = "-"
  test "${1:-1}" = "*" && {
    qs='1' # Disable AWK filter
  } || {
    test "${1:-1}" -gt 0 && {
      qs='$4 == "'"${1:-1}"'!" || $4 !~ /!/ && 0 < $4 && $4 <= '"${1:-1}"
      $LOG debug "$lk" "Query level ${1:-1}" "$qs"
    } || {
      qs='$4 == 0'
      $LOG debug "$lk" "Query for all baselines" "$qs"
    }
  }
  { test -z "${3:-}" && {
      rules_reader $ns -- lines || return
    } || {
      rules_reader $ns -- blocks "# ${2:-Source}:" "$3" || return
    }
  } | {
    case "${5:-lines}" in
      ( lines ) line_conts_collapse | awk_line_select "$qs" ;;
      ( * ) cat ;;
    esac
  } | {
    test -z "${4:-}" && cat - || grep "$4" -
  }
}

#

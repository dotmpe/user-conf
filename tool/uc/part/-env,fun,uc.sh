# Group function holding all user-conf env tools.
# TODO: check with uc_env options
# Prefixes:
# - hide/exclude from argument values: use for flags and non-mutating commands
# + change env state
# @ include in global set
# % change env
# : other special or internal/private/local call
#shellcheck disable=2128 # FUNCNAME is array, but just want first value anyway
uc_env ()
{
  local ENV_CTX=${ENV_CTX:-$0[$$]}
  local lk="${lk-}:$ENV_CTX:$FUNCNAME:$1"
  case "${1}" in
  ( "" ) uc_env :help-summary && false ;;
  ( -d- ) # ~~ [<Type-src>] # Generate definition statement(s)
    local -n _dmin_dt=${2:-uc_env_types}
    local _dmin_{key,type,stmt}
    for _dmin_key in "${!_dmin_dt[@]}"
    do
      uc_env :type $_dmin_key _dmin_type &&
      uc_env :dtype $_dmin_key _dmin_stmt "${_dmin_type}" ||
        continue
      echo "$_dmin_stmt"
    done
  ;;
  ( -d% ) # ~~ [<Type-array>] # Generate all definition statement(s)
    local -n _dpct_dt=${2:-uc_env_types}
    local _dpct_{key,type,stmt}
    for _dpct_key in "${!_dpct_dt[@]}"
    do
      uc_env :dtype "${_dpct_key:?}" _dpct_stmt &&
      echo "${_dpct_stmt:?}"
    done
  ;;
  ( -d%* ) # ~ ~%[<Type>] <Id> ... # Generate definition statement
    : input "${2:?Part name expected: $*, $ENV_CTX:$FUNCNAME${1}}"
    local _dtype_stmt
    uc_env :dtype "${2}" _dtype_stmt ${1#+d%} &&
    echo "${_dtype_stmt:?}"
  ;;
  ( -dif% ) # ~~ [<Type-src>] # Generate statements when undefined or changed
    local -n _dif_dt=${3:-uc_env_types}
    local _dif_{key,type,stmt}
    for _dif_key in "${!_dif_dt[@]}"
    do
      uc_env :type $_dif_key _dif_type &&
      uc_env :dtype $_dif_key _dif_stmt "${_dif_type}" ||
        continue
      # FIXME: I think 'g' flag may be missing in between reported by
      # declaration vs. provided for by :dtype...
      case "${_dif_type}" in
      ( *f* | *d* )
        :pass "$(typeset -f $_dif_key)" &&
        [[ $_ = "$_dif_stmt" ]] ||
        echo "  $_dif_stmt"
      ;;
      ( * )
        :pass "$(typeset -p $_dif_key)" &&
        [[ $_ = "$_dif_stmt" ]] ||
        echo "  $_dif_stmt"
      ;;
      esac
    done
  ;;
  ( -dump ) # ~~ <Ids...>
    : input "${2?:Part names expected: $*, $ENV_CTX:$FUNCNAME}"
    local _env_{key,type}
    # Use -dump.<dtype> directly for better performance than <type>
    for _env_key in "${@:2}"
    do
      uc_env :type "${_env_key}" _env_type &&
      uc_env -dump.$_env_type "${_env_key}" || return
    done
  ;;
  ( -dump.a ) # ~~ <Ids...>
    : input "${2?:Part names expected: $*, $ENV_CTX:$FUNCNAME}"
    local _env_id
    for _env_id in "${@:2}"
    do
      local -n _env_dr=${_env_id:?}
      cat <<EOM
      declare -ga ${_env_id:?}
      ${_env_id}=( ${_env_dr[@]@Q} )
EOM
    done
  ;;
  ( -dump.A ) # ~~ <Ids...>
    : input "${2?:Part name(s) expected: $*, $ENV_CTX:$FUNCNAME}"
    local _env_{d{,r},{,d}id}
    for _env_id in "${@:2}"
    do
      echo "declare -gA ${_env_id:?}"
      local -n _env_dr=${_env_id:?}
      for _env_did in "${!_env_dr[@]}"
      do
        _env_d=${_env_dr["$_env_did"]?Data expected at $_env_id:$_env_did}
        echo "  ${_env_id}[\"$_env_did\"]=${_env_d@Q}"
      done
    done
  ;;
  ( -dump.* ) # ~~ <Ids...>
    : input "${2?:Part name(s) expected: $*, $ENV_CTX:$FUNCNAME}"
    local _dump_type=${1#-dump.}
    [[ $_dump_type = n ]] && >&2 echo dump n $*
    uc_env -d%${_dump_type} "${@}"
  ;;
  ( -gi | :group-info )
    : param '~~ <Group-name> ...'
    : input "${2:?Group name expected: $*, $ENV_CTX:$FUNCNAME${1}}"
    local -n _type="uc_env_types[\"${2}\"]"
    uc_env :assert-type G "${!_type}" || return
    local _spec _{b,t,e}i
    _spec=${_type#G}
    test -z "$_spec" && \
      echo -n "Regular group ${2}" ||
      echo -n "Group ${2} -$_spec"
    read -r _bi _ti _ei <<< "${uc_env_parts["$2.G"]}"
    echo -n " Base: ${ENV_BASE:0:$_bi}"
    #local prev_grp
    #: "${ENV_BASE:0:$_bi}"
    #: "${_% *}"
    #: "${#_}"
    #echo -n " Base: ${ENV_BASE:${_}:$(( _bi - _ ))}"
    test -z "${uc_env_parts["${2}.src"]-}" || echo -n " <$_>"
    test -z "${uc_env_parts["${2}.ctx"]-}" || echo -n " Context: $_"
    echo
  ;;
  ( :info )
    : param '~~ <Part-name> ...'
    : input "${2:?Part name expected: $*, $ENV_CTX:$FUNCNAME${1}}"
    local -n _type="uc_env_types[\"${2}\"]"
    uc_env :assert-exists "${!_type}" || return
    echo part ${2} type=$_type
    local -n _part="uc_env_parts[\"${2}.${_type:1:1}\"]"
    ! [[ ${part:+set} ]] || echo part=$_part
  ;;
  ( -h | -\? | --help | :help-summary )
    cat <<EOM
Usage:
  ${FUNCNAME} <Key ...>
                      ~ -h | -? | --help | :help-summary ...
                      ~ -gi | :group-info ...
                      ~ -pr | :pretty ...
                      ~ -su | :summary ...
EOM
  ;;
  ( -l | :list )
    : param '...'
    local _k
    for _k in "${!uc_env_parts[@]}"
    do
      uc_env -pi "${_k%.*}"
    done
  ;;
  ( -lc | :list-components )
    : about "List all components"
    : param '...'
    local _k
    for _k in "${!uc_env_parts[@]}"
    do
      _Str_Glob_Match "*.c*" "$_k" || continue
      uc_env -pi "${_k%.c*}"
    done
  ;;
  ( -lg | :list-groups )
    : about "List all groups"
    local _k
    for _k in "${!uc_env_parts[@]}"
    do
      _Str_Glob_Match "*.G*" "$_k" || continue
      uc_env -gi "${_k%.G*}"
    done
    # TODO: print sorted by base, and propagate group end-index, ie. at
    # .end attribute
  ;;
  ( -i | --include | \
    -l | --load )
    : param '~~ <Name ...>'
    : input ${2:?Expected part name(s), $ENV_CTX:$FUNCNAME:$1}
    local _pn
    for _pn in "${@:2}"
    do
      [[ ${uc_env_types["$_pn"]+set} ]] ||
          uc_env :load-part "$_pn" || return
    done
  ;;
  ( -pi | :part-info )
    : param '~~ <Name> [<Type-spec>]'
    local _ts
    [[ ${3-} ]] && _ts=${3} || uc_env :type "${2}" _ts
    local _type=${_ts:0:1} _spec=${_ts:1} label=part
    ! [[ $_spec ]] &&
    echo "Regular $_type $label ${2}" ||
      {
        echo "${_type} ${2} -$_spec"
        for _atr in ${2} ${_spec}
        do
          : "${uc_env_parts["${2}.${_atr}"]-}"
          test -z "$_" ||
            echo " $_atr: $_"
        done
      }
  ;;
  ( -pr | :pretty )
    : param '~ ~ ...'
    : param '~ :pretty.<Type> <Array-name> ...'
    uc_env :pretty.a uc_env_exports
    local -a _arrs=( uc_env_{types,parts,hooks} )
    _Sys_Exec_Apply uc_env :pretty.A _arrs
  ;;
  ( :pretty.a )
    : param '~ ~ <Array-name> ...'
    local -n _arr=${2}
    echo "declare -a ${2}=("
    for k in "${!_arr[@]}"
    do
      echo "  [$k]=${_arr[k]@Q}"
    done
    echo ")"
  ;;
  ( :pretty.A )
    : param '~ ~ <Array-name> ...'
    local -n _arr=${2}
    echo "declare -A ${2}=("
    for k in "${!_arr[@]}"
    do
      echo "  [\"$k\"]=${_arr["$k"]@Q}"
    done
    echo ")"
  ;;
  ( -Q )
    : param '~~ <Type> <Name> ...'
    ! _OS_Fun_Exists uc-env::${3} ||
        [[ ${uc_env_parts["${3}.${2}"]:+set} ]] ||
            uc_env @d:${2} ${3} "$(declare -f uc-env::${3})"
  ;;
  ( -q | :query )
    : param '~~ <Names...>'
    local _pn
    for _pn in "${@:2}"
    do [[ ${uc_env_parts[${_pn:?}]+set} ]] || return
    done
    #local -n "uc_env_parts[\"\${_pn:?}\"]"
  ;;
  ( -r | --require | :require-parts )
    : about 'Require env parts'
    : param '~~ <Name ...>'
    : input ${2:?Expected part name(s), $ENV_CTX:$FUNCNAME:$1}
    local -a _parts=( "${@:2}" )
    _Sys_Exec_Apply --all uc_env :require-part _parts
  ;;
  ( -rld | :reload )
    : param '...'
    . "${U_C:?}/tool/uc/part/-env,fun,uc.sh"
  ;;
  ( -summary )
    >&2 echo "Env-ctx: ${ENV_CTX-(unset)}"
    local -a _env_{base,ctx,lib,src}
    _Sys_Read_Exec _env_base printf -- '%s\n' ${ENV_BASE-}
    _Sys_Read_Exec _env_ctx printf -- '%s\n' ${ENV_CTX-}
    _Sys_Read_Exec _env_lib printf -- '%s\n' ${ENV_LIB-}
    _Sys_Read_Exec _env_src printf -- '%s\n' ${ENV_SRC-}
    >&2 echo "Env-base-current: ${ENV_BASE//* }"
    >&2 echo "Env-base-len: ${#_env_base[*]}"
    >&2 echo "Env-ctx-len: ${#_env_ctx[*]}"
    >&2 echo "Env-src-len: ${#_env_src[*]}"
    >&2 echo "Env-lib-len: ${#_env_lib[*]}"
    >&2 echo --
    >&2 echo "Type-len: ${#uc_env_types[*]}"
    >&2 echo "Part-len: ${#uc_env_parts[*]}"
    >&2 echo Printing uc env Hooks...
    #>&2 echo "Export-len: ${#uc_env_exports[*]}"
    #>&2 echo "Hook-seqs: ${!uc_env_hooks[*]}"
    {
      uc_env -typeset.hooks
    } | IF_LANG=bash ${PAGER:?}
  ;;
  ( -typeset )
    set -- ENV_{BASE,CTX,LIB,SRC} uc_env_{exports,hooks,parts,types}
    declare -p  "$@"
  ;;
  ( -typeset.hooks )
    local _env_hook
    local -a _env_hooks
    uc_env :pretty.A uc_env_hooks
    for _env_hook in ${!uc_env_hooks[*]}
    do
      read -a _env_hooks <<< "${uc_env_hooks["$_env_hook"]}"
      #>&2 echo "Hooks-$_env_hook-len: ${#_env_hooks[*]}"
      set -- "$@" "${_env_hooks[@]}"
    done
    declare -f "${@:2}"
  ;;
  ( @by-name ) # ~~ <Name> <To-name> [<Part-spec-reset...>]
    : about "Declare & define by-name variable"
    uc_env +d n "${@:2}"
  ;;
  ( @contexts )
    : param '~~ <Name ...>'
    : about 'Record given names as us env context'
    : extended 'Helper to register uc env component parts'
    shift
    local ctx
    for ctx
    do
      #uc_cmp :define-context "${ctx}"

      # Store like dynfun, but lazy-eval hook only upon -r
      :pass "$(_Sh_Fun_Body "uc-env::${ctx}")" &&
      #uc_env +d dx "uc-env::${ctx}" "${_}" &&
      #super=$(metafor super <<< "$ctx")
      # Register as component type of part
      uc_env @d:c "${ctx}" "${_}" ||
      #uc_env +d c "${ctx}" "uc-env::" ||
        _WARN "Failed adding context ${ctx}: E$?, $ENV_CTX:$FUNCNAME@contexts"

      uc_env -gi "${ctx}"
    done
  ;;
  ( +continue )
    : param '...'
    : about "Reload uc env from export, and redeclare dynamic parts"
    >&2 echo Continue $$...
    uc:env:${SHELL_NAME:-bash} &&
    _INFO "Loaded compiled env" ||
      _WARN "Failed loading compiled env: E$?" || return
    # run-defs without exports, just special attributes and other dyn. types
    local env_defs
    env_defs="$(uc_env -dif%)" &&
    [[ -n "$env_defs" ]] && {
      _uconf_info_ "Evaluating uc-env..."
      eval "$env_defs" || {
        _uconf_err_ "Failed to continue from env export: E$?" ||
          "${uc_stat:-exit}" $?
      }
      _uconf_info_ "Done evaluating uc-env"
    } ||
      _uconf_warn_ "uc_env +continue: Nothing to continue from"
  ;;
  ( +d )
    : param '~~ <Type> <Id> [<Spec...>]'
    : about 'Declare & define'
    : extended 'See @d:* for registration, and +d.* for definition'
    : extended 'Some types currently use custom spec'
    uc_env @d:${2} "${@:3}" &&
    uc_env +d.${2} "${3}"
  ;;
  ( @d:d* )
    : input "${2?:Symbol name expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env :register-part "${2}" "${1#@d\:}" "${@:4}"
    [[ $# -eq 2 ]] && return
    : input "${3?:Script string expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env_parts["$2.d"]=${3}
  ;;
  ( @d:G* )
    : input "${2?:Group name expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env :register-part "${2}" "${1#@d\:}" "${3}"
    [[ $# -eq 3 ]] && return
    : input "${4?:Source name expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env_parts["$2.src"]=${4}
    _Sh_ByName_Add ENV_SRC ' ' "$4"
    [[ $# -eq 4 ]] && return
    : input "${5?:Context tag expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env_parts["$2.ctx"]=${5}
    _Sh_ByName_Add ENV_CTX ' ' "$5"
  ;;
  ( @d:n* )
    # XXX: should need this for n
    : input "${2?:Variable name expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env :register-part "${2}" "${1#@d\:}" "${@:4}"
    [[ $# -eq 2 ]] && return
    : input "${3?:Reference name expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env_parts["$2.n"]=${3}
  ;;
  ( @d:* )
    : param '~ ~:[<Type>] <Id> [<Spec...>]'
    : about 'Generic declare'
    uc_env :register-part "${2}" "${1#@d\:}" "${@:3}"
  ;;
  #( +d.n* )
  #  declare -gn "${2}"="${3% *}"
  #;;
  ( +d.* )
    : param '~ ~.[<Type>] <Id> ...'
    : about 'Evalute definition (ie. re-apply from uc_env meta)'
    : input "${2?:Part name expected: $*, $ENV_CTX:$FUNCNAME}"
    # TODO: reval only when dirty
    uc_env :reval "${1#+d.}" "${2}"
  ;;
  ( +eval | :reval )
    : param '<Type> <Name> [<Pref] [<Suf>]'
    local _dtype_stmt
    uc_env :dtype "${3}" _dtype_stmt ${2} &&
    eval "${4-}${_dtype_stmt:?}${5-}"
  ;;
  ( @exports )
    : param '...'
    : input "${2?:Part name(s) expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env_exports+=( "${@:2}" )
  ;;
  ( @functions )
    : param '...'
    : input "${2?:Function name(s) expected: $*, $ENV_CTX:$FUNCNAME}"
    shift
    local fun
    for fun
    do
      uc_env_types[${fun}]=${uc_env_types[${fun}]:-f}
    done
  ;;
  ( @hooks:* )
    : param '~ ~<Set> <Handlers...>'
    : about 'Declare additional hooks'
    local hookset=${1#@hooks:} hook
    local -n hooks="uc_env_hooks[\"${hookset}\"]"
    for hook in "${@:2}"
    do _Str_Glob_Match "*,${hook},*" ",${hooks}," && continue
      _Sh_ByName_Add "${!hooks}" ',' "${hook}"
    done
  ;;
  ( +if-init )
    : param '...'
    uc_env +try-init || [[ ${uc_env_parts[*]+set} ]] || uc_env +init
  ;;
  ( +init )
    : param '...'
    : "${ENV_BASE:=}"
    declare -gA uc_env_{hooks,parts,types}
    declare -ga uc_env_exports
  ;;
  ( +load )
    : param '...'
    local _env_{key,type}
    for _env_key in "${uc_env_types[@]}"
    do
      _env_type="${uc_env_types["$_env_key"]-}"
      case "${_env_type}" in
      ( n )
          [[ ${uc_env_parts["$_env_key.n"]:+set} ]] || {
            :pass "$(_Sh_Fun_Body "$_env_key")" &&
            uc_env_parts["$_env_key.n"]=${_} ||
              _uconf_alert_ "Failed to retrieve dynamic function body: E$?:$_env_key" $? || return
          }
        ;;
      esac
    done
  ;;
  ( +start ) # ~~ ... [ -- <ctx...> ] #
    : about "Finalize current env, and export for subprocess"
    : extended "After normal export (vars, functions), run 'start' hook,"
    : extended "followed by dump, and export for current uc_env state."
    local _sh=${SHELL_NAME:-$0}
    if [[ ${*:2:2} == "profile --" ]]
    then
      uc_env :export
    elif [[ ${*:2:2} == "rc --" ]]
    then
      _uconf_debug_ "Running uc env 'start' hooks"
      uc_env :hooks:start
    fi
    # run-defs
    #:pass "$(uc_env -dif%)" &&
    local __uc_env_start
    __uc_env_start="$(uc_env :dump+${SHELL_NAME:-bash} -- "$@" )" &&
    eval "$__uc_env_start" || {
      local __uc_env_dump __stat=$?
      __uc_env_dump=/tmp/uc-env.err.$$
      echo "$__uc_env_start" > $__uc_env_dump
      _uconf_err_ "uc:env start failure E$__stat <$__uc_env_dump>"
      return ${__stat}
    }
  ;;
  ( +try-init )
    #: input "${2?:Tag expected: $*, $ENV_CTX:$FUNCNAME}"
    _Sh_Fun_Exists uc:env:${SHELL_NAME:-bash} && {
      uc_env +init &&
      uc_env +continue
    }
    #[[ ${uc_env_types["${2}"]-} = G ]] ||
    #  _uconf_alert_ "Group expected $2:${uc_env_types["${2}"]} (ignored)"
  ;;
  ( :export )
    : about "Declare all exported variables and functions"
    : param "~~ ..."
    local _env_{key,type}
    [[ $# -gt 1 ]] || set -- "$1" "${uc_env_exports[@]}"
    for _env_key in "${@:2}"
    do
      : "${_env_key:?$0[$$]:$FUNCNAME$1: Empty env key in uc_env_exports}"
      uc_env :type "${_env_key}" _env_type || continue
      case "${_env_type/x}" in
      ( v* )
          declare -gx $_env_key
        ;;
      ( [df]* )
          declare -gfx $_env_key
        ;;
      ( [ns]* )
        ;;
      ( * )
          >&2 echo unhandled env export ${_env_key}: ${_env_type/x}
      esac
    done
  ;;
  ( :inline-part | @part )
    : about "Register for new inline base"
    : param "~ <Type> <Id> ..."
    : input "${2?$ENV_CTX:$FUNCNAME${1}: Type expected: $*}"
    : input "${3?:Id expected: $*, $ENV_CTX:$FUNCNAME}"
    ! [[ ${prev_group+set} ]] ||
      uc_env_parts["${prev_group}.end"]=${#ENV_BASE}\ ${#uc_env_types[*]}\ ${#uc_env_exports[*]}
    uc_env +d "${2}" "${3}" \
      ${#ENV_BASE}\ ${#uc_env_types[*]}\ ${#uc_env_exports[*]} \
      "${@:4}"
    _Sh_ByName_Add ENV_BASE ' ' "${3}"
    declare -g _prev_group=${3}
  ;;
  ( :load-part )
    : extended 'See :require-part for post-load init'
    : input ${2:?Expected part name, $ENV_CTX:$FUNCNAME:$1}
    [[ ${uc_env_types["${2}"]+set} ]] || {
      . "${2}.inc.sh" || _ERR "uc env '${2}' not found"
    }
  ;;
  ( :redefine-export | +increment )
    :pass "$(declare -f uc:env:${SHELL_NAME:-bash})" && {
      : "${_#uc:env:${SHELL_NAME:-bash} ()$'*\n\{*\n'}" &&
      : "${_%\}}  : :#: Local-env append: "
    } || {
      : "  : :#: Local-env root: "
    }
  ;;
  ( :hooks:* ) # ~~ ... [ -- <ctx...> ] # Run callbacks group
    local _ucenv_hook{,seq}
    _ucenv_hookseq=${1#:hooks:}
    local -n _ucenv_hooks="uc_env_hooks[\"${_ucenv_hookseq}\"]"
    [[ ${_ucenv_hooks:+set} ]] &&
    for _ucenv_hook in ${_ucenv_hooks//,/ }
    do
      : "${_ucenv_hook:?Empty env key in hook sequence $_ucenv_hookseq, $ENV_CTX:$FUNCNAME$1}"
      "${_ucenv_hook}" -- ${FUNCNAME}${1} "${@:2}" &&
      _uconf_info_ "Hook $_ucenv_hook OK" ||
        _ _uconf_warn_ "Hook $_ucenv_hook E$?"
    done ||
      _ _uconf_warn_ "No uc env ${_ucenv_hookseq@Q} hooks"
  ;;
  ( :unexport-parts | @locals )
    : "${2?:Keys expected: $*, $ENV_CTX:$FUNCNAME}"
    local _env_key
    for _env_key in "${@:2}"
    do
      uc_env :delattr X $_env_key
    done
  ;;
  ( :delattr ) # ~~ <Spec> <Key>
    : "${3?:Key expected: $*, $ENV_CTX:$FUNCNAME}"
    local _def
    local -n _del_ref=${3}
  ;;
  ( :attr ) # ~~ <Spec> <Key>
    : about "Toggle attribute <Spec> for part <Key>"
    : "${2?:Spec expected: $*, $ENV_CTX:$FUNCNAME}"
    : "${3?:Key expected: $*, $ENV_CTX:$FUNCNAME}"
    case "${2}" in
    ( -* )
      local _define
      uc_env :type "${3}" _def &&
      uc_env :vfl-default "${2:2}" _def &&
      uc_env_types["${3}"]=${_def}
      return
    ( +* )
      local _def
      uc_env :type "${3}" _def &&
      uc_env :vfl-strip "${2:2}" _def &&
      uc_env_types["${3}"]=${_def}
      return
    ( * )
      _uconf_alert_ "${1}? Unsupported, $ENV_CTX:${FUNCNAME[0]}"
      #_ERR "$FUNCNAME:$1?"
    esac
  ;;
  ( :dtype )
    : param '~~ <Name> <Dest-ref> [<Type-spec>] ...'
    : about 'Build declaration statement for dynamic symbol'
    : extended 'All simple Bash variables and functions can be exported, but'
    : extended ' without attributes. No arrays. And limited special function names. '
    : input "${2?:Part name expected: $*, $ENV_CTX:$FUNCNAME}"
    : input "${3?:Dest var expected: $*, $ENV_CTX:$FUNCNAME}"
    local -n _dtype_sref=${3}
    local _dtype_tp
    [[ ${4:-} ]] && _dtype_tp=${4} || uc_env :type "${2}" _dtype_tp
    : "${_dtype_tp:?$0[$$] uc-env$1: Require type for ${2:?}${4:+: ${4}}}"
    _dtype_sref=${_dtype_tp%% *}
    case "${_dtype_sref}" in
    ( *G* ) false ;; # no export for groups here
    #( *f* ) [[ ${_dtype_sref/f} != x ]] ;; # special case: xf we can just skip
    esac &&
    case "${_dtype_sref}" in
    ( *s* ) # static script symbol
      local -n _dtype_target="uc_env_parts[\"${2}.s\"]"
      : "${_dtype_target:?Expected script part for ${2} ($_dtype_sref)}"
      _dtype_sref="alias ${2}=${_dtype_target}"
      return ;;
    ( *d* ) # dynamic symbol
      # name could be alias, function maybe even temp/trans cmd?
      local _dtype_body=${uc_env_parts["${2}.d"]}
      _dtype_sref="${2} () {
  ${_dtype_body:?}
}"
      return ;;
    ( *n* ) # by-name variable
      local _dtype_spec=${uc_env_parts["${2}.n"]}
      _dtype_sref="${_dtype_sref} ${2}=${_dtype_spec% *}" ;;
      # all other func (incl readonly) and var (int/lower/ro/trace/upper)
    ( *f* | *i* | *l* | *r* | *t* | *u* )
      _dtype_sref="${_dtype_sref} ${2}" ;;
    ( * ) false ;;
    esac &&
    _dtype_sref="declare -g${_dtype_sref:?}"
  ;;
  ( :dump+bash )
    echo $'uc:env:bash ()\n{'
    :pass "$(declare -f uc:env:bash)" && {
      : "${_#uc:env:bash ()*$'\n'\{*$'\n'}"
      : "${_%\}}  : :#: Local-env append: "
      echo  "$_"

      : "${*:2}"
      _uconf_warn_ "TODO: incremental dump ${_@Q},base:${ENV_BASE-(unset)}"

    } || {
      echo "  : :#: Local-env root: "
      uc_env -dump.a uc_env_exports
      uc_env -dump.A uc_env_{hooks,parts,types}
      uc_env -d%
    }
    echo $'}\ndeclare -xf uc:env:bash'
  ;;
  ( :part-attr )
    : param '<Part> <Array> <Fields...>'
    : input ${2:?Expected part name, $ENV_CTX:$FUNCNAME:$1}
    : input ${3:?Expected array name, $ENV_CTX:$FUNCNAME:$1}
    : input ${4:?Expected attribute name(s), $ENV_CTX:$FUNCNAME:$1}

    local -n __uc_env_pa_out=${3}
    local _an _fundecl
    _fundecl="$(declare -f uc-env::${2})" &&
    for _an in "${@:4}"
    do
      :pass "$(<<< "${_fundecl}" uc_cmp :metafor ${_an})" || return
      __uc_env_pa_out[${_an}]=${_}
    done
  ;;
  ( :part-names )
    : param '~ ~ <Dest> ...'
    : about 'Get actual list of all part names'
    : extended 'Tracked parts must be either registered with type or as export'
    : extended 'ie. in uc-env-types or uc-env-exports'
    # uc env registration can be incomplete: 1, the default type is v for
    # variable and those can exist in the env and as export only (so no type or
    # parts), and 2, normal external functions similary exists. And neither
    # is necessarily exported.
    local -n _dest_arr=${2}
    local -a _parts=( "${!uc_env_types[@]}" )
    _Sys_Arr_Union _parts uc_env_exports _dest_arr
  ;;
  ( :require-part )
    : input ${2:?Expected part name, $ENV_CTX:$FUNCNAME:$1}
    #_Str_Glob_Match " $ENV_BASE " "* ${2} *" && return
    _Sh_Fun_Exists uc-env::${2} ||
      [[ ${uc_env_parts["${2}.c"]+set} ]] ||
        uc_env :load-part "${2}" ||
          _WARN "Unrecognized part ${2@Q}" ||
            return
    uc_cmp :define-context "${2}" &&
    uc_cmp :resolve-context "${2}" && {
      _Sh_ByName_Add ENV_BASE " " "${2}" || return 0
      uc-env::${2}
    } ||
      _ERR "Require part ${2@Q} failed, E$?"
  ;;
  ( :register-part )
    : param '~~ <Id> <Spec> ...'
    : extended 'Set type to full type-flag, and part to given spec'
    : input "${2?:Part name expected: $*, $ENV_CTX:$FUNCNAME}"
    : input "${3?:Spec/primary type expected: $*, $ENV_CTX:$FUNCNAME}"
    uc_env_types["${2}"]=${3}
    uc_env_parts["${2}.${3:0:1}"]="${*:4}"
  ;;
  ( +reset )
    : param '...'
    : extended 'This is just for testing purposes'
    local _parts
    uc_env :part-names _parts &&
    _Sys_Exec_Apply --all uc_env +remove _parts
    unset \
      ENV_BASE \
      uc_env_{hooks,parts,types} \
      uc_env_exports
  ;;
  ( :assert-exists ) # ~~ <Type-ref>
    local -n __type_ref=${2}
    [[ ${__type_ref:+set} ]] || _WARN "No such uc env entity for ${2}"
  ;;
  ( :assert-type ) # ~~ <Flag> <Type-ref>
    local -n __type_ref=${3}
    uc_env :assert-exists "${3}" || return
    [[ ${__type_ref:1:1} = ${2} ]]  ||
      _WARN "No such ${2} entity (${3}='${__type_ref}')" || return
  ;;
  ( :type )
    : about 'Retrieve full uc env type for name'
    : param '~ ~ <Name> <Dest> ...'
    : input "${2?:Part name expected: $*, $ENV_CTX:$FUNCNAME}"
    : input "${3?:Dest var expected: $*, $ENV_CTX:$FUNCNAME}"
    local -n _uc_etp_dest=${3}
    _uc_etp_dest=${uc_env_types["${2}"]:-v}
    if _Sys_Arr_Find uc_env_exports "${2}"
    then uc_env :vfl-defstrip x X _uc_etp_dest
    else _uc_etp_dest=${_uc_etp_dest/x}
    fi
  ;;
  ( :vfl-default )
    : about 'Add default flag unless complement flag is set'
    : param '~ ~ <Default-flag> <Complement-flag> <Var-ref> ...'
    local -n _vfl_ref=${4}
    case "${_vfl_ref}" in
    ( *"${2}"* | *"${3}"* ) ;;
    ( * ) _vfl_ref=${_vfl_ref}${2} ;;
    esac
  ;;
  ( :vfl-defstrip )
    : about 'Strip default flag unless complement flag is set'
    : param '~ ~ <Default-flag> <Complement-flag> <Var-ref> ...'
    local -n _vfl_ref=${4}
    case "${_vfl_ref}" in
    ( *"${3}"* ) _vfl_ref=${_vfl_ref/${3}} ;;
    ( * ) _vfl_ref=${_vfl_ref/${2}}${2} ;;
    esac
  ;;
  ( +remove )
    : param '~ ~ <Name> ...'
    : input "${2?:Part name expected: $*, $ENV_CTX:$FUNCNAME}"
    local __type
    local -n __part
    uc_env :type "${2}" __type &&
    #__part="uc_env_parts[\"${1}.${__type:1:1}\"]" &&
    case "${__type:-v}" in
    ( *c* )
      case "${__type}" in
      ( *x* ) declare -f +x uc-env::${2} ;;
      esac
      unset -f uc-env::${2} ;;
    ( *f* | *d* )
      case "${__type}" in
      ( *x* ) declare -f +x ${2} ;;
      esac
      unset -f ${2} ;;
    ( *v* )
      case "${__type}" in
      ( *x* ) declare -f +x ${2} ;;
      esac
      unset ${2} ;;
    ( * ) false ;;
    esac &&
    true
  ;;

  ( @uc/env )
    #:ignore () { "$@" || uc_stats+=( "$?" ); }
    :ignore () { "$@" || true; }
    :pass () { return; }
    :stat () { return ${1:?}; }

    uc_env +if-init &&

    uc_env +d dx :ignore '"${@}" || true' &&
    uc_env +d dx :pass 'return' &&
    uc_env +d dx :stat 'return ${1:?}' &&

    #uc_cmp :init-includes uc-{afs,cmp,env}
    uc-env::uconf-profile-dsl &&
    uc-env::uconf-shell-log &&
    uc_env -r uconf-shell{,-core-dsl} uconf-profile-dsl &&
    #declare -gfx :ignore :pass :stat &&
    # FIXME: scripts loaded *and* run during profile need to use us_env
    # instead, but until support is rolled out simply export everything loaded
    # until now from uconf-shell includes.
    uc_env @functions \
      uc_env &&
    uc_env @exports \
      uc_env \
      _ _IF{_,DBG,VBS} _uconf_shell_is{debug,verbose} append_path \
      :ignore :pass :stat &&
    uc_env :export &&
    true
  ;;

  ( @uc ) #XXX: registration
    : param '...'
  ;;

  ( * )
    _uconf_alert_ "${1}? Unsupported, $ENV_CTX:${FUNCNAME[0]}"
    :stat ${_E_next:-196}
  ;;
  esac || return

  : id uc-env-base
  : typ us-line-seq
  : ctx user-conf::
  : req user-script::{uc-profile,sh-{funbody,mapfile}}
  : src tool/uc/part/-env,fun,uc.sh
  : pak user-conf,env,fun,uc,sh
  : su user-conf::uc
  : sub %uc.sh,core
  : sub %uc.sh,base
}
# ex:ft=bash:

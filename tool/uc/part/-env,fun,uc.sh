# Group function holding all user-conf env tools.
# TODO: check with uc-env options
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
  : "${1:?$ENV_CTX:$FUNCNAME: Switch expected}"
  local lk="${lk-}:$ENV_CTX:$FUNCNAME:$1"
  case "${1}" in
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
  ( -gi ) # ~~  <group>
    # XXX: temporary routine for inspect
    echo group: $2
    echo type spec: ${uc_env_types["$2"]}
    echo part spec: ${uc_env_parts["$2.G"]}
    read -r _bi _ti _ei <<< "${uc_env_parts["$2.G"]}"
    echo Base: ${ENV_BASE:$_bi}
  ;;
  ( -d-* ) # ~~ [<Type-src>] # Generate definition statement(s)
    false
  ;;
  ( -d% ) # ~~ [<Type-src>] # Generate definition statement(s)
    local -n _dpct_dt=${2:-uc_env_types}
    local _dpct_{key,type,stmt}
    for _dpct_key in "${!_dpct_dt[@]}"
    do
      uc_env :dtype "${_dpct_key:?}" _dpct_stmt &&
      echo "${_dpct_stmt:?}"
    done
  ;;
  ( -d%* ) # ~ ~%[<Type>] <Id> ... # Generate definition statement
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part name expected}"
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
        if_ok "$(typeset -f $_dif_key)" &&
        [[ $_ = "$_dif_stmt" ]] ||
        echo "  $_dif_stmt"
      ;;
      ( * )
        if_ok "$(typeset -p $_dif_key)" &&
        [[ $_ = "$_dif_stmt" ]] ||
        echo "  $_dif_stmt"
      ;;
      esac
    done
  ;;
  ( -dump ) # ~~ <Ids...>
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part names expected}"
    local _env_{key,type}
    # Use -dump.<dtype> directly for better performance than <type>
    for _env_key in "${@:2}"
    do
      uc_env :type "${_env_key}" _env_type &&
      uc_env -dump.$_env_type "${_env_key}" || return
    done
  ;;
  ( -dump.a ) # ~~ <Ids...>
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part names expected}"
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
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part names expected}"
    local _env_{d{,r},{,d}id}
    for _env_id in "${@:2}"
    do
      echo "declare -gA ${_env_id:?}"
      local -n _env_dr=${_env_id:?}
      for _env_did in "${!_env_dr[@]}"
      do
        _env_d=${_env_dr["$_env_did"]:?Data expected at $_env_id:$_env_did}
        echo "  ${_env_id}[\"$_env_did\"]=${_env_d@Q}"
      done
    done
  ;;
  ( -dump.* ) # ~~ <Ids...>
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part name(s) expected}"
    local _dump_type=${1#-dump.}
    uc_env -d%${_dump_type} "${@}"
  ;;
  ( -print )
    declare -p ENV_{BASE,CTX,LIB,SRC}
  ;;
  ( -summary )
    stderr echo "Env-ctx: ${ENV_CTX-(unset)}"
    local -a _env_{base,ctx,lib,src}
    sh_mapfile _env_base printf -- '%s\n' ${ENV_BASE-}
    sh_mapfile _env_ctx printf -- '%s\n' ${ENV_CTX-}
    sh_mapfile _env_lib printf -- '%s\n' ${ENV_LIB-}
    sh_mapfile _env_src printf -- '%s\n' ${ENV_SRC-}
    stderr echo "Env-base-len: ${#_env_base[*]}"
    stderr echo "Env-ctx-len: ${#_env_ctx[*]}"
    stderr echo "Env-src-len: ${#_env_src[*]}"
    stderr echo "Env-lib-len: ${#_env_lib[*]}"
    stderr echo --
    stderr echo "Type-len: ${#uc_env_types[*]}"
    stderr echo "Part-len: ${#uc_env_parts[*]}"
    stderr echo --
    stderr echo "Export-len: ${#uc_env_exports[*]}"
    stderr echo "Hook-seqs: ${!uc_env_hooks[*]}"
    local _env_hook
    local -a _env_hooks
    for _env_hook in ${!uc_env_hooks[*]}
    do
      read -a _env_hooks <<< "${uc_env_hooks["$_env_hook"]}"
      stderr echo "Hooks-$_env_hook-len: ${#_env_hooks[*]}"
    done
  ;;

  ( @by-name ) # ~~ <Name> <To-name> [<Part-spec-reset...>]
    #uc_env +d n "$@"
    uc_env_types["${2}"]='n'
    uc_env_parts["${2}.n"]="${3}"
    declare -gn "${2}"="${3% *}"
  ;;
  ( +continue ) # ~ .... #

    uc:env:bash &&
      _uconf_debug_ "Loaded uc-env export" ||
      _uconf_notice_ "Continue existing uc-env"

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
      _uconf_warn_ "uc-env +continue: Nothing to continue from"
  ;;
  ( +d ) # ~~ <Type> <Id> [<Spec...>] # Declare & define
    uc_env @d:${1} "${@:2}" &&
    uc_env +d.${1} "${2}"
  ;;
  ( @d:* ) # ~ ~:[<Type>] <Id> [<Spec...>] # Generic declare
    set -- @d: "${1#@d\:}" "${@:2}"
    uc_env_types["${3}"]=${2}
    uc_env_parts["${3}.${2}"]="${4}"
  ;;
  ( +d.* ) # ~ ~.[<Type>] <Id> # Evalute definition (ie. re-apply from uc-env meta)
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part name expected}"
    local _dtype_stmt
    uc_env :dtype "${2}" _dtype_stmt ${1#+d.} &&
    eval "${_dtype_stmt:?}"
  ;;
  ( @exports )
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part name(s) expected}"
    uc_env_exports+=( "${@:2}" )
  ;;
  ( +load ) # ~ ... #
    local _env_{key,type}
    for _env_key in "${uc_env_types[@]}"
    do
      _env_type="${uc_env_types["$_env_key"]-}"
      case "${_env_type}" in
      ( n )
          [[ ${uc_env_parts["$_env_key.n"]:+set} ]] || {
            if_ok "$(sh_funbody "$_env_key")" &&
            uc_env_parts["$_env_key.n"]=${_} ||
              _uconf_alert_ "Failed to retrieve dynamic function body: E$?:$_env_key" $? || return
          }
        ;;
      esac
    done
  ;;
  ( +start ) # ~~ ... [ -- <ctx...> ] #
    local _sh=${SHELL_NAME:-$0}
    [[ ${*:2:2} == "profile --" ]] && {
      uc_env :export
    }
    [[ ${*:2:2} == "rc --" ]] && {
      _uconf_debug_ "Running uc-env rc init hooks"
      #stderr echo "$0[$$]:$FUNCNAME$1: Interactive auto-start of $_sh env"
      uc_env :hooks:start
    } ||
      _uconf_info_ "No uc-env init hooks"
    # run-defs
    #if_ok "$(uc_env -dif%)" &&
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
  ( :export ) # ~ ... # Mark all variables and functions as exported
    local _env_{key,type}
    for _env_key in "${uc_env_exports[@]}"
    do
      : "${_env_key:?$0[$$]:$FUNCNAME$1: Empty env key in uc_env_exports}"
      uc_env :xtype "${_env_key}" _env_type || continue
      _env_type=${_env_type/v}
      declare -g${_env_type} $_env_key
    done
  ;;
  ( :init ) # ~ <key>
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Tag expected}"
    if_ok "$(declare -F uc:env:bash)" && {
      uc:env:bash || {
        _uconf_warn_ "Failed loading compiled env meta: E$?" ||
          "${uc_stat:-exit}" $?
      }
    }
    [[ ${uc_env_types["${2}"]-} = G ]] ||
      _uconf_alert_ "Group expected $2:${uc_env_types["${2}"]} (ignored)"
    TODO "uc-env:env-init, see +continue"
  ;;
  ( :inline-part | @part ) # ~ <Type> <Id> ...
    : "${2?$ENV_CTX:$FUNCNAME${1}: Type expected}"
    : "${3:?$ENV_CTX:$FUNCNAME${1}: Id expected}"
    uc_env_types["${3}"]=${2}
    uc_env_parts["${3}.${2}"]=${#ENV_BASE}\ ${#uc_env_types[*]}\ ${#uc_env_exports[*]}
    sh_vadd ENV_BASE ' ' "${3}"
  ;;
  ( :redefine-export | +increment )
    if_ok "$(declare -f uc:env:bash)" && {
      : "${_#uc:env:bash ()$'*\n\{*\n'}" &&
      : "${_%\}}  : :#: Local-env append: "
    } || {
      : "  : :#: Local-env root: "
    }
  ;;
  ( :hooks:* ) # ~~ ... [ -- <ctx...> ] # Run callbacks group
    local _ucenv_hook{,seq}
    _ucenv_hookseq=${1#:hooks:}
    for _ucenv_hook in ${uc_env_hooks["${_ucenv_hookseq}"]}
    do
      : "${_ucenv_hook:?$ENV_CTX:$FUNCNAME$1: Empty env key in hook sequence $_ucenv_hookseq}"
      "${_ucenv_hook}" -- ${FUNCNAME}${1} "${@:2}" &&
      _uconf_info_ "Hook $_ucenv_hook OK" || {
        _uconf_warn_ "Hook $_ucenv_hook E$?" || true
      }
    done
  ;;
  ( :unexport-parts | @locals )
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Keys expected}"
    local _env_key
    for _env_key in "${@:2}"
    do
      uc_env :delattr X $_env_key
    done
  ;;
  ( :delattr ) # ~~ <Spec> <Key>
    : "${3:?$ENV_CTX:$FUNCNAME${1}: Key expected}"
    local _def
    local -n _del_ref=${3}
  ;;
  ( :attr ) # ~~ <Spec> <Key>
    : about "Toggle attribute <Spec> for part <Key>"
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Spec expected}"
    : "${3:?$ENV_CTX:$FUNCNAME${1}: Key expected}"
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
      sh_abort "$FUNCNAME:$1?"
    esac
  ;;
  ( :dump+bash )
    echo $'uc:env:bash ()\n{'
    if_ok "$(declare -f uc:env:bash)" && {

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
  ( :dtype ) # ~~ <Name> <Dest-ref> [<Type-spec>] ...
    : about 'Build declaration statement for dynamic symbol'
    : extended 'All simple Bash variables and functions can be exported, but'
    : extended ' without attributes. No arrays. And no special function names. '
    : param "${2:?$ENV_CTX:$FUNCNAME${1}: Part name expected}"
    : param "${3:?$ENV_CTX:$FUNCNAME${1}: Dest var expected}"
    local -n _dtype_sref=${3}
    local _dtype_tp
    [[ ${4:-} ]] && _dtype_tp=${4} || uc_env :type "${2}" _dtype_tp
    _dtype_sref=${_dtype_tp?$0[$$] uc-env$1: Require type for ${2:?}${4:+: ${4}}}
    case "${_dtype_sref}" in
    ( *G* ) false ;; # no export for groups here
    #( *f* ) [[ ${_dtype_sref/f} != x ]] ;; # special case: xf we can just skip
    esac &&
    case "${_dtype_sref}" in
    ( *s* ) # static script symbol
      local _dtype_target=${uc_env_parts["${2}.s"]}
      _dtype_sref="alias ${2}=${_dtype_target}"
      return ;;
    ( *d* ) # dynamic symbol
      # name could be alias, function maybe even temp/trans cmd?
      local _dtype_body=${uc_env_parts["${2}.d"]}
      _dtype_sref="${2} () {
  ${_dtype_body}
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
    _dtype_sref="declare -g${_dtype_sref}"
  ;;
  ( :query | -q ) # ~~ <Names...>
    for name
    do [[ ${uc_env_parts[${name:?}]+set} ]] || return
    done
  ;;
  ( :type ) # ~~ <Name> <Dest> ...
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part name expected}"
    : "${3:?$ENV_CTX:$FUNCNAME${1}: Dest var expected}"
    local -n _uc_etp_dest=${3}
    _uc_etp_dest=${uc_env_types["${2}"]:-v}
    uc_env :vfl-defstrip x X _uc_etp_dest
  ;;
  ( :vfl-defstrip ) # ~~ <Default-flag> <Complement-flag> <Var-ref> ...
    local -n _vfl_ref=${4}
    case "${_vfl_ref}" in
    ( *"${3}"* ) _vfl_ref=${_vfl_ref/${3}} ;;
    ( * ) _vfl_ref=${2}${_vfl_ref/${2}} ;;
    esac
  ;;
  ( :vfl-default ) # ~~ <Default-flag> <Complement-flag> <Var-ref> ...
    local -n _vfl_ref=${4}
    case "${_vfl_ref}" in
    ( *"${2}"* | *"${3}"* ) ;;
    ( * ) _vfl_ref=${2}${_vfl_ref} ;;
    esac
  ;;
  ( :xtype ) # ~~ <Name> <Dest> ....
    : "${2:?$ENV_CTX:$FUNCNAME${1}: Part name expected}"
    : "${3:?$ENV_CTX:$FUNCNAME${1}: Dest var expected}"
    local -n _xtype_ref=${3}
    uc_env :type "${@:2}" &&
    case "${_xtype_ref}" in
    ( *x* ) _ref=${_xtype_ref/x} ;;
    ( * ) false ;;
    esac &&
    case "${_xtype_ref}" in
    ( *f* ) ;;
    ( *i* ) _ref=${_xtype_ref/i} ;;
    ( *l* ) _ref=${_xtype_ref/l} ;;
    ( *r* ) _ref=${_xtype_ref/r} ;;
    ( *t* ) _ref=${_xtype_ref/t} ;;
    ( *u* ) _ref=${_xtype_ref/u} ;;
    ( *v* ) _ref=${_xtype_ref/v} ;;
    ( * ) false ;;
    esac
  ;;
  ( * )
    sh_abort "$ENV_CTX:${FUNCNAME[0]}:${1}?" "Unsupported"
  ;;
  esac
}
# ex:ft=bash:

: "${compo_inc_sh:=${C:?}/includes,composure.bash}"

# Handle composure-select target set
case "${xredo_target:?}" in

( "$A"/*.inc )
    _inc="${1:${#A}+1}"
    redo-stamp <"${C_INC:?}/$_inc" &&
    redo-ifchange "${C_INC:?}/$_inc"
  ;;

# Fields are extracted in groups or sets bc it seems like a waste to restart
# (reload) entire cached env for each individual fields.

( "$A"/include,composure/*.about )
    : "${1:${#A}+19}"
    _inc=${_%about}inc
    redo-ifchange "$A"/include,composure/${_inc%.inc}.typeset &&
    # XXX: also need to consider see-also, notes, and dep-type field and
    # whatever else is in actual source
    cache_loadmaps "${compo_inc_sh}" compo_inc_{name,typeset,param,about,extended} &&
    _fun=${compo_inc_name["$_inc"]:?} &&
    _typeset="${compo_inc_typeset["$_fun"]:?Typeset expected for $_fun}" &&
    TODO "Get About, Extended and Param fields from typeset"
  ;;

( "$A"/include,composure/*.id )
    : "${1:${#A}+19}"
    _inc=${_%id}inc
    redo-ifchange "$A"/include,composure/${_inc%.id}.typeset &&
    cache_loadmaps "${compo_inc_sh}" compo_inc_{name,typeset,id,type,group,alias} &&
    _fun=${compo_inc_name["$_inc"]:?} &&
    _typeset="${compo_inc_typeset["$_fun"]:?Typeset expected for $_fun}" &&
    TODO "Get Id, Type, Group and Alias fields from typeset"
  ;;

( "$A"/include,composure/*.typeset )
    : about "Track single actual function name and typeset of include"
    : extended "Further processing requires the id-fieldset"
    : "${1:${#A}+19}"
    _inc=${_%typeset}inc
    #>&2 echo "Updating for $_inc"
    cache_loadmaps "${compo_inc_sh}" compo_inc_{name,typeset}

    : "$(<"${C_INC:?}/$_inc" grep -m 1 -P '^[^ #\(]+ *\(\) *({)? *(#.*)?$')"
    : "${_%% *}"
    : "${_%()}"
    test -n "$_" ||
      :failp "Error getting function name from ${_inc@Q}" || exit
    _fun=${_}

    mkdir -p "${compo_inc_sh%/*}"

    [[ ${compo_inc_name["$_inc"]:+set} ]] &&
    [[ ${compo_inc_name["$_inc"]} = "$_fun" ]] || {
      compo_inc_name["$_inc"]=$_fun &&
      >>"$compo_inc_sh" echo "compo_inc_name[\"$_inc\"]=${_fun@Q}"
    }

    [[ ${compo_inc_typeset["$_fun"]:+set} ]] || {
      _typeset=$(. "${C_INC:?}/$_inc" && declare -f "${fun}") &&
      compo_inc_typeset["$_fun"]=${_typeset} &&
      >>"$compo_inc_sh" echo "compo_inc_typeset[\"$_fun\"]=${_typeset@Q}"
    }

    redo-stamp <<<"${compo_inc_typeset["$_fun"]:?Typeset expected for $_fun}" &&
    redo-ifchange "$A/$_inc" "${BASH_SOURCE[0]}"
  ;;


( @compo )
    declare -a inc dep

    >/dev/null pushd "${C_INC:?}" &&
    _Sys_Read_Exec inc find . \
      -newer "${compo_inc_sh:?}" \
      -iname '*.inc' -type f \
      -not -ipath '*/[Tt]ool/*' \
      -not -ipath '*/.*' &&
    >/dev/null popd &&
    ((${#inc[@]})) || exit 0

    >&2 echo "Updating $1 for ${#inc[@]} files"
    for _inc in "${inc[@]}"
    do
      dep+=(
        "$A/include,composure/${_inc%.inc}.id"
        "$A/include,composure/${_inc%.inc}.about"
      )
    done &&
    redo-ifchange "${dep[@]}" &&
    touch "$compo_inc_sh" &&
    redo @compo:groups &&
    redo-stamp < "$compo_inc_sh" &&
    redo-always
  ;;

( @compo:groups )
    redo-ifchange @compo
    >/dev/null pushd "${C_INC:?}" &&
    cache_loadmaps "${compo_inc_sh}" compo_inc_{name,group}
    declare -a groups
    _Sys_Arr_Adduniq groups "${compo_inc_group[@]}" &&
    for _group in "${groups[@]}"
    do
      >&2 declare -p _group
      #deps+=( "${_group}" )
    done &&
    >/dev/null popd &&
    redo-stamp <<< "$(declare -p groups)" &&
    redo-ifchange "${deps[@]}" "${BASH_SOURCE[@]}"
  ;;

( @compo:touch )
    _Sys_Read_Exec inc find "${C_INC:?}" \
      -iname '*.inc' -type f \
      -not -ipath '*/[Tt]ool/*' \
      -not -ipath '*/.*' &&
    ((${#inc[@]})) || exit 0

    touch "${inc[@]}"
  ;;


( "$B"/tool/*/part/*.inc )
    ENV_CTX=$$/$0:B:tool/*/part/*.inc
    _uc_build__tool_name "${B?}" '.inc'
    mkdir -p "${B?}/tool/${tool:?}/part"
    curpath=$PATH
    append_path "${UCONF?}/script/composure"
    . "common,local.sh"
    append_path "${UCONF?}/script/composure/Tool/sh/part"
    append_path "${UCONF?}/script/composure/Tool/uc/part"
    append_path "${UCONF?}/script/composure/Tool/us/part"
    # Find and extract typeset meta
    us_env_nametoid name{,id}
    # FIXME: should use one specific extension for this later
    scr_find namescr "$nameid" .inc .bash .sh ||
      :failp "E$? finding ${nameid@Q} part" || return
    . "${namescr}"  &&
    qname=${name//-/:} &&
    _nametypeset=$(declare -f ${qname}) &&
    us_env_inc_key_all_values _nametypeset '' from &&
    for path in "${from[@]}"
    do
      append_path "${UCONF?}/script/composure/${path}"
    done &&
    echo "PATH=\$PATH:${PATH:${#curpath}+1}" &&
    # Generate pre-requisite list
    us_env_inc_key_all_values _nametypeset '' parts &&
    namens=${qname%:*} &&
    declare -a parts{cname,scr} &&
    for part in "${parts[@]}"
    do
      us_env_cname "$part" "$qname" partcname
      partscname+=( "$partcname" )
      : "${_//:/-}"
      : "${partcname:${#namens}+1}"
      partsscr+=( "$(command -v "${_//:/-}.inc")" )
    done &&
    declare -p name{,id,scr,ns} parts{cname,scr}
    # Done
    echo "# Generated with redo ${1@Q}"
    :pass "$(date --iso=sec)" &&
    echo "# Time ${_}"
  ;;

( tool/*/part/*.sh )
    append_path "${UCONF?}/script/composure"
    _uc_build__tool_name '' '.sh'
    redo-ifchange "$B/tool/$tool/part/$name.inc" &&
    . "$_" &&
    . "common,local.sh" &&
    mkdir -p "tool/$tool/part" &&
    declare -a _deps &&
    >>"$3" us_env_typeset_sh "$name" _deps &&
    >&2 declare -p _deps &&
    for partscr in "${partsscr[@]}"
    do
      : "${partscr##*/}"
      bn="${_%.inc}"
      grep -v '^ *: \(id\|group\)' "$partscr" |
        sed 's/\<'"$bn"'\>/'"${bn//-/_}"'/'
      echo
    done >>"$3" &&
    : "$(date --iso=sec)" &&
    >>"$3" echo "# Generated with redo ${1@Q}, on ${_}" &&
    <"$3" redo-stamp &&
    redo-ifchange "${_deps[@]}"
  ;;

( "tool/*/part" )
    . "common,local.sh" &&
    us_env_node_init &&
    >&2 us_env_node_list &&
    TODO "build $1"
  ;;

( tool/*/part/* )
    . "common,local.sh" &&
    TODO "build $1"
  ;;

( tool/*/part/*.sh )
    : "${ENV_CTX:=$$/$0:tool/*/part/*.sh}"
    shopt -s nullglob
    . "common,local.sh" &&
    us_env_node_init &&
    >&2 us_env_node_list &&
    TODO "build $1" ||
    :failp "E$? during load"
  ;;

 * ) return ${_E_next:-196}

esac

# Id: uc-build.composure-select.bash.do                            ex:ft=bash:

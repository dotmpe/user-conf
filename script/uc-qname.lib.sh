uc_qname () # ~ <URI>
{
  false
}

uc_qname_import () # ~ <Name> [<From>] [<As>]
{
  # user_ns_group_rdf
  # user_ns_group_xml
  declare name=${1:?} from=${2:-} to=${3:-$1} \
    nsdefs=${USER_NS_:?}group_${from}[$name]
  declare -n nslookup=${UC_NS_:?}[$to]
  declare -g "$nsdefs=$nslookup"
}


# Make name-reference variables by zipping Names with From values,
# including the optional Prefix with the new variables.
sys_gref () # ~ <Prefix-> <Names> <From...>
{
  local to=${1:-} names=${2:?} name
  shift 2 &&
  for name in $names
  do
    declare -gn ${to}${name}=${1:?} &&
    shift || return
  done
}

sys_arefmap () # ~ <Refs-arr> <Vars-arr>
{
  declare -n refvars=${1:?} varnames=${2:?}
  local i
  for i in "${!refvars[@]}"
  do
    declare -gn "${varnames[$i]}=${refvars[$i]}" || return
  done
}

sys_refmap () #
{
  local prefix=${1:-} suffix=${2:?} names=${3:?} name
  shift 3 &&
  for name in $names
  do
    declare -gn $prefix$name$suffix=${1:?} &&
    shift || return
  done
}

#

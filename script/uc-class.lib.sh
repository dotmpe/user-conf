uc_class_lib__load ()
{
  : about "Some stuff to help with declaration, to move into class.lib later"
  lib_require str sys argv class-uc
}

uc_class_lib__init ()
{
  # TODO: see ns/package management
  declare -gA uc_ns_{alias,exec,group,ref,path,urn,usr}
  declare -ga uc_path
}

# Wrapper for direct static call invocations during type load/declaration,
# see uc-class-declare.

uc_class_d () # ~
{
  declare class_cur
  class_cur=${Class__hook[${1:2}]:?"$(sys_exc uc:class:d "Hook declaration for '$1' expected")"} &&
  call=${1:?} class_${class_cur}_ "${@:2}" || class_loop_done
}

# Helper for class load phase to declare all aspects for type; as these can
# be inherited calling us-class-declare makes all basetypes fully load and
# declare first in a recursive way.

# The latter is also why this routine is kept in uc-class.lib for now: for a
# more proper non-recursive implementation the declaration line should be
# recorded and handled after load is completed during class-init.

uc_class_declare () # ~ <Class> <Types...> [ -- <declare-hooks..> ]
{
  declare baserefs=() bases=() &&
  argv_hseq baserefs "${@:2}" &&
  test 0 -eq "${#baserefs[@]}" || {
    sys_arr bases str_words "${baserefs[@]}" &&
    class_load "${bases[@]}" || return
  }
  declare class_static=$1 &&
  str_vword class_static &&
  argv_seq=args_hseq_arrv sys_csp=uc_class_d sys_csa="args_oseq_arrv 1" \
  sys_cmd_seq --type "$@"
}

uc_import () # ~ [<module>.]<type> | <type> <module>
{
  false
}

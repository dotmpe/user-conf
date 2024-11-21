ucbuild.hostvar:define ()
{
  uc.build.declare-target hostvar.PATH macro &&
  uc.build.declare-target hostvar.PPATH macro &&
  true || return

  # PPATH combine userdirs and result of /src/local/*+current{,+working}
  local key=ucbuild:hostvar.PPATH
  uc_node[${key}]="ucbuild:target &PPATH.lookup.var"

  ucbuild_declarevar \
    ucbuild:hostvar.PPATH \

  #uc_node[$PACK_NS:\&PATH.lookup${key}]="ucbuild:handler &PPATH.lookup.var"

  uc_node_deps[${key}]=ucbuild:hostvar.USERDIRS

  uc_node_handler[${key}]="ucbuild:target &PPATH.lookup.var"
}

ucbuild.path:define ()
{
  false
}
ucbuild.ppath:define ()
{
  false
}
ucbuild.src-local:define ()
{
  false
}
ucbuild.userdirs:define ()
{
  false
}

#

uc_type[PATH]=var
#uc_node[-uc-build.host.vars]=vars
# XXX: from uc-build.host-vars.type.bash
: "${PACK_SEED_VARS=us-bin,u-s,u-c,uconf,c-inc}"
: "${HOST_VARS:-ppath,path,scriptpath${PACK_SEED_VARS:+,}${PACK_SEED_VARS-}}"
uc_node[hostvar]=$_
uc_node_base[hostvar]=ucbuild
uc_node_dep[hostvar]=hostpack
# ..

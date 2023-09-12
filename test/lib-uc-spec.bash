. script/lib-uc.lib.sh
lib_uc_lib__load &&
lib_uc_lib__init || return

export PATH=$PATH:test/var/lib/sh

lib_load argv-uc
test "$lib_loaded" = "argv-uc"
test "$argv_uc_lib_loaded" = "0"
# FIXME: why does above work but below not. Var name doesnt seem to matter
# values seem to get set, but after lib-load suddenly its empty
stderr declare -p ENV_LIB
#test -n "$ENV_LIB"

lib_load example-empty
test "$lib_loaded" = "argv-uc example-empty"

lib_load example-load-hook

sh_mode dev

stderr echo "lib-load is a function"
. script/lib-uc.lib.sh
sh_fun lib_load
lib_uc_lib__load
lib_uc_lib__init


stderr echo "~ that sources .lib.sh files"

test_libs=test/var/lib/sh
#export SCRIPTPATH=$SCRIPTPATH:$test_libs
export PATH=$PATH:$test_libs
lib_load example-empty


stderr echo "~ and tracks lib names, sources and status"

test -n "$lib_loaded"
test "$lib_loaded" = "example-empty"
test "$example_empty_lib_loaded" = "0"
test "$ENV_LIB" = "$test_libs/example-empty.lib.sh"

lib_load example-load-hook
test "$example_load_hook_lib_loaded" = "0"
test "$lib_loaded" = "example-empty example-load-hook"


stderr echo "All libs load correctly"

libs=$(for scr in script/*.lib.sh; do basename "$scr" .lib.sh; done)
#libs="date date-htd stdlog-uc str script-mpe us-build log"
stderr echo "* lib-require ${libs//$'\n'/ }"
lib_require $libs

#

load helper
init
uc_lib=${lib}/user-conf
scriptname=us-resolve.bats
lib_require ctx-class 

test_funs_exists ()
{
  for sym in "$@"
  do
    run sh_fun $sym
    test_ok_empty || stdfail "$sym"
  done
}

@test "Class and helpers exists" {

  test_funs_exists class.Class class.Class.load
  test_funs_exists class.deinit class.info class.info-tree class.init class.load
}

@test "Class instance helpers initialize" {

  diag "ctx_class_types: $ctx_class_types"

  run lib_init ctx-class
  test_ok_empty || stdfail 1

  lib_init ctx-class
  test_funs_exists create destroy
}

#

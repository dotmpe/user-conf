#setup ()
#{
base=uc-fields-lib-spec
load helper
init
lib_require std-uc uc-fields
#}

@test "Can define from simple braces spec-sets" {

  run uc_fields_define foo {bar,baz-{a,b}}
  test_ok_empty || stdfail 1

  # Now do again, but check for variables
  uc_fields_define foo {bar,baz-{a,b}}
  for suf in bar baz-{a,b} 
  do
    std_silent declare -p foo_fields_${suf//-/_}
  done
}

@test "Can update a field value" {

  base=base
  uc_fields_define $base foo

  run uc_field foo my-data my-value
  test_ok_empty || stdfail 1

  uc_field foo my-data my-value

  run uc_field foo my-data
  test_ok_nonempty || stdfail 2
}

@test "Can run hooks (optional or required functions) per field" {
  TODO
}

@test "Does run validators before setting value (test 'change' validator hook)" {

  base=base
  uc_fields_define $base foo
  uc_field foo my-data my-value

  run uc_vfield foo my-data my-value
  test_ok_empty || stdfail 1
}

#

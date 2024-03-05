uc_os_lib__load()
{
  lib_require envd
}

uc_os_lib__init ()
{
  envd_dtype uc/os.lib lib &&
  envd_dfun filter_args
}

filter_args () # ~ <Test-cmd> <Args...> # Print args for which test pass
{
  local value test=${1:?}
  for value in "${@:2}"
  do
    $test "$value" || {
      continue
      # TODO: make test functions discern between error and test failure/pass
      #test ${_E_next:?} -eq $? && continue
      #return $_
    }
    echo "$value"
  done
}

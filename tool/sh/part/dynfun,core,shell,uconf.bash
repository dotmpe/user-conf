UConf-Shell-Core:dynfun ()
{
  : "${1:?Function name expected}"
  : "${2:?Function body expected}"
: param "<Function-name> <Function-body...>"
  : "${1} () { ${*:2}; }"
  eval "$_"
}

Sh-Fun-Eval ()
{
  : about "Define function from script-string"
  : param "<Function-name> <Function-body> ..."
  : input "${1:?Function name expected, $ENV_CTX:$FUNCNAME}"
  : input "${2:?$1: Function body expected, $ENV_CTX:$FUNCNAME}"
  : :# Format function and evaluate
  : "${1} () { ${*:2}; }"
  eval "$_"
}

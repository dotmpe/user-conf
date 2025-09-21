:pass () { return; }
:stat () { return ${1:?}; }
:ignore () { "$@" || true; }
:fun ()
{
  : param '<Function-name> <Function-body>'
  : "${1:?Function name expected}"
  : "${2:?Function body expected}"
  : "${1} () { ${*:2}; }"
  eval "$_"
}
:fun ':%' ':fun "$@"'
:fail ()
{
  : param '<Message> <Status>'
	: "${1:?Failure message expected}"
	: "${2:?Failure status expected}"
	>&2 echo "${1}"
	return ${2}
}
:failp ()
{
	local stat=$?
  : param '<Message>'
	: "${*:?Failure message expected}"
	>&2 echo "$*"
	return ${stat}
}

declare -xf :pass :stat :ignore :fail{,p} :fun :%

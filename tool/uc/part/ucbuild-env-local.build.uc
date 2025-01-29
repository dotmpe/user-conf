%{@,env,build,uc}

%{announce-start:local@env,build,uc}

ucbuild-env-next || %{vfail-next:local@env,build,uc}

%{vchk-incomplete:local@env,build,uc}

%{announce-complete:local}

ENV_NID=${ENV_ID:+${ENV_ID}:}local

: "${ENV_BASE//[-]}"
: "${_// /-}"
: "${ENV_NAME:=${PACK_NAME:-${APP:?env-local: No env-name (dir: $EWD, bases: $_, pending: ${ENV_PEND-unset})}}.${_}}"

: "${ENV_TRIGGERS:=local build bash}"
: "${ENV_NAMES:=local pack static boot}"

%{announce-finish:local}

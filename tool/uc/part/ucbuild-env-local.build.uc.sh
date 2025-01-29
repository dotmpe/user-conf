ucbuild_tpl_env_local_v ()
{
  cat <<EOM

$(ucbuild_env_announce_start local)

ucbuild-env-next || $(ucbuild_env_vfail_next local)

$(ucbuild_env_vfail_incomplete local)

$(ucbuild_env_announce_complete local)

ENV_NID=\${ENV_ID:+\${ENV_ID}:}local

: "\${ENV_BASE//[-]}"
: "\${_// /-}"
: "\${ENV_NAME:=\${PACK_NAME:-\${APP:?env-local: No env-name (dir: \$EWD, bases: \$_, pending: \${ENV_PEND-unset})}}.\${_}}"

: "\${ENV_TRIGGERS:=local build bash}"
: "\${ENV_NAMES:=local pack static boot}"

$(ucbuild_env_announce_finish local)

EOM
}


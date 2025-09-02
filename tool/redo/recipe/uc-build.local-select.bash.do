#( :all-projects )
#    shopt -s nullglob expand_aliases &&
#    . "${UCONF:?}/tool/sh/part/ucbuild-als.sh"
#  ;;

case "${xredo_target}" in

# Default build target
( all|[@:.]all )
      redo-ifchange @env:a:local_all_target "${local_all_target[@]}"
    ;;

( @env:a:* )
			: "${1#@env:a:}"
			if_ok "$(declare -p "${_:?Array variable name expected}")" &&
			<<< "${_}" redo-stamp &&
			redo-ifchange ".env.sh"
    ;;

( @env:fun:* )
      local fun src
      : "${1#@env:fun:}"
      src=${_%:*} fun="${1##*:}"
      redo-ifchange "${src:?Expected source file path}" &&
      . "$src" &&
      if_ok "$(declare -f "${fun:?Expected function name}")" &&
      <<< "${_}" redo-stamp
    ;;


( +*:* )
    ;;


( +* )
    #V=7 VERBOSE=true DEV=true \
    env -i \
      HOME=$HOME \
      bash -lic '
        set -euETo pipefail
        shopt -s nullglob expand_aliases
        . "${UCONF:?}/tool/sh/part/ucbuild-als.sh"

        cwd "'"${REDO_TARGET#\+}"'" build &&
        stderr pwd &&
        redo -k
      '
  ;;

( :all-projects )
    # Alias: redo-all (see ucbuild-als)
    for redo_base in uconf htdocs annex-p
    do ( ENV_DIR="$redo_base" && cwd && stderr pwd && redo -k )
    done
  ;;

( :user/config )
    ( cd ~/.conf && redo -k )
  ;;


  * )
      >&2 echo "! do,local: Unknown target: ${1@Q}"
      exit "${_E_nsa:-68}"
    ;;


esac

# ex:ft=bash:

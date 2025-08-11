#!/usr/bin/env bash

# See @build+init: initial helper to init/update hosts' shell dev environment
# For effective user/host/project setup we need a layered approach, with ad hoc
# customizable parts. By creating a ~/local (or ~/.local) project, and possibly
# others, this can be done in a host-centric way, using Bash, Git and Redo as
# basic prerequisite tools.

set -eETuo pipefail

[[ ${REDO_RUNID-} && ${REDO_TARGET} = @shdev+init ]] || {
#[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = @shdev+init+local.do ]] || {
  echo  "Illegal env" && exit 124
}

# Keep this recipe UTD automatically
[[ -h @shdev+init.do ]] || {
  ! "${DEV:-false}" && {
    ! "${DEBUG:-false}" || {
      >&2 diff -bqr @shdev+init.do \
      "${U_C:?}"/tool/redo/recipe/at.shdev+init.bash,uc.do ||
        $LOG alert : "Local recipe is OOD" "E122:doenv/req" 122 || exit $?
    }

  } || {

    >&2 diff -bqr @shdev+init.do \
      "${U_C:?}"/tool/redo/recipe/at.shdev+init.bash,uc.do || {

      >&2 cp -v "${U_C:?}"/tool/redo/recipe/at.shdev+init.bash,uc.do @shdev+init.do && {
        $LOG warn : "Local recipe was OOD" "E123:noenv/pend" 123 || exit $?
      } ||
        $LOG alert : "Local recipe update failed" "E121:ifenv/bug" 121 || exit $?
    }
  }
}

: "${EWD:=${REDO_BASE:?}}"

uc_shdev_sldef=(
  "${HOME:?}/.l" ".local"
  "${HOME:?}/.l/c" "share/composure"
)

for ((i=0; i<${#uc_shdev_sldef[*]}; i+=2))
do
  [[ -e "${uc_shdev_sldef[i]}" ]] || {
    # Remove if broken symlink
    [[ ! -h "${uc_shdev_sldef[i]}" ]] || {
      >&2 rm -v "${uc_shdev_sldef[i]}" || {
        _ALERT "Failed removing symlink" "${uc_shdev_sldef[i]}"
        exit 3
      }
    }
  }
  [[ -d "$(dirname "${uc_shdev_sldef[i]}")" ]] ||
    >&2 mkdir -vp "$(dirname "${uc_shdev_sldef[i]}")"
  [[ -h "${uc_shdev_sldef[i]}" ]] ||
    >&2 ln -vs "${uc_shdev_sldef[i+1]}" "${uc_shdev_sldef[i]}"
done

uc_shdev_reporefs_1=( "dotmpe/composure" "test" "" 
  "/src/local/composure+dev" "~/.local/share/composure" "~/.local/c" )
uc_shdev_reporefs_2=( "dotmpe/user-conf" "r0.2" "" 
  "/src/local/user-conf+dev" )
uc_shdev_reporefs_3=( "dotmpe/user-scripts" "r0.0" "" 
  "/src/local/user-scripts+dev" )
uc_shdev_reporefs_4=( "dotmpe/conf-mpe" "master" "" 
  "/src/local/conf-mpe+dev" "~/.local/share/dotfiles" "~/.conf" )

# XXX: assume first scm-git instance has branch/tag; convenient when all repos are 
# mirrors however that may not apply

for ((i=1; i<5; i+=1))
do
  declare -n repo_data="uc_shdev_reporefs_${i}"
  repo_ref="${repo_data[0]:?}"
  for repo in /srv/scm-git*/${repo_ref}.git
  do
    [[ -d "$repo" ]] && break || continue
  done
  [[ -d "$repo" ]] || exit
  : "${repo#\/srv\/scm-git-}"
  : "${_%%/*}"
  srv_tag=${_:?}
  # XXX: adapt to checkout either fresh? tag, or UTD branch
  branch="${repo_data[1]:-}"
  tag="${repo_data[2]:-}"
  [[ -d "${repo_data[3]}/" ]] && repo_fresh=0 || {
    >&2 git clone -q --origin "${srv_tag}-bare" --branch "${branch}" \
        "$repo" "${repo_data[3]}/" || exit
    repo_fresh=1
  }
  >&2 pushd "${repo_data[3]}/" || exit
  repo_up=1
  for repo in /srv/scm-git*/${repo_ref}.git
  do
    [[ -d "$repo" ]] || exit
    : "${repo#\/srv\/scm-git-}"
    : "${_%%/*}"
    srv_tag=${_:?}
    repo_url=$(git config remote.$srv_tag-bare.url) && {
    [[ $repo_url = $repo ]] && continue ||
      repo_up=0
      [[ ${repo+set} ]] && {
        git remote set-url $srv_tag-bare "$repo" || exit
      } ||
        git remote add $srv_tag-bare "$repo"
    }
  done
  ((repo_up)) ||
    >&2 git fetch -q --all
  ((repo_fresh)) || {
    >&2 git checkout -q "${branch}" -- &&
    >&2 echo git pull -q "${srv_tag}-bare" "${branch}" &&
    >&2 git pull -q "${srv_tag}-bare" "${branch}" || exit
  }
  >&2 popd
done
. ./.env-init.sh || exit

>&2 mkdir -vp "${METADIR?}"/build/data

# ex:ft=bash:

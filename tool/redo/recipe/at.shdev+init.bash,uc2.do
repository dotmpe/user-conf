#!/usr/bin/env bash

# See @build+init: initial helper to init/update hosts' shell dev environment
# For effective user/host/project setup we need a layered approach, with ad hoc
# customizable parts. By creating a ~/local (or ~/.local) project, and possibly
# others, this can be done in a host-centric way, using Bash, Git and Redo as
# basic prerequisite tools.

# TODO: split this up into host config and project config parts, review env-local base setup

set -eETuo pipefail

[[ ${REDO_RUNID-} && ${REDO_TARGET} = @shdev+init ]] || {
#[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = @shdev+init+local.do ]] || {
  >&2 echo "$0: Illegal env"
  exit 124
}

. "${U_C:?}"/tool/uc/part/ucassert.bash

# Keep this recipe UTD automatically
uc-assert symlink-or-copy @shdev+init.do \
  "${U_C:?}"/tool/redo/recipe/at.shdev+init.bash,uc.do

: "${EWD:=${REDO_BASE:?}}"

uc_shdev_sldef=(
  "${HOME:?}/.l" ".local"
  "${HOME:?}/.l/s" "share"
  "${HOME:?}/.l/s/c" "composure"
  "${HOME:?}/.l/c" "s/c"
  "${HOME:?}/.l/s/composure" "${HOME}/.conf/script/composure"
)

uc-assert symlink-all uc_shdev_sldef

# XXX: the real user composure include dir is submod of conf-mpe
uc_shdev_reporefs_1=( "dotmpe/composure" "master" ""
  "/src/local/composure-mpe+dev" "~/project/composure-mpe" )
uc_shdev_reporefs_2=( "dotmpe/user-conf" "r0.2" ""
  "/src/local/user-conf+dev" "~/project/user-conf" )
uc_shdev_reporefs_3=( "dotmpe/user-scripts" "r0.0" ""
  "/src/local/user-scripts+dev" "~/project/user-scripts" )
uc_shdev_reporefs_4=( "dotmpe/conf-mpe" "master" ""
  "/src/local/conf-mpe+dev" "~/.local/share/dotfiles" "~/.conf" "~/project/conf-mpe" )

# XXX: assume first scm-git instance has branch/tag; convenient when all repos are
# mirrors however that may not apply

for ((i=1; i<5; i+=1))
do
  # see note on redo-stamp at bottom
  declare -p "uc_shdev_reporefs_${i}" | redo-stamp
  declare -n repo_data="uc_shdev_reporefs_${i}"
  repo_ref="${repo_data[0]:?}"
  for repo in /srv/scm-git-[0-9]*/${repo_ref}.git
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
  >/dev/null 2>&1 pushd "${repo_data[3]}/" || exit
  repo_up=1
  for repo in /srv/scm-git-[0-9]*/${repo_ref}.git
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
    >&2 git pull -q "${srv_tag}-bare" "${branch}" || {
      >&2 echo ALERT: "Cannot update $PWD from" "remotes/$srv_tag-bare/$branch"
      exit
    }
  }
  >/dev/null 2>&1 popd

  for sl in "${repo_data[@]:4}"
  do
    sl=${sl/#~/$HOME}
    [[ -e "${sl}" ]] && {
      [[ -h "${sl}" ]] || continue
      target=$(readlink "${sl}") &&
      [[ $target = "${repo_data[3]}" ]] && continue
    } || {
      [[ ! -h "${sl}" ]] ||
      [[ -e "${sl}" ]] ||
      >&2 rm -v "${sl}" || {
        >&2 echo ALERT: "Failed removing path or symlink" "${sl}"
        #_ALERT "Failed removing path or symlink" "${sl}"
        exit 3
      }
    }

    [[ -d "$(dirname "${sl}")" ]] ||
      >&2 mkdir -vp "$(dirname "${sl}")"
    [[ -h "${sl}" ]] ||
      >&2 ln -vs "${repo_data[3]}" "${sl}"
  done
done

. ${EWD:?}/.env-init.sh || exit

: "${METADIR:=.${PACK_ID:?}}"

: "${B:=${METADIR:?}/build}"
: "${C:=${METADIR:?}/cache}"
: "${D:=${METADIR:?}/dist}"

>&2 mkdir -vp "${B}" "${C}" "${D}"

# XXX: track metadata names+values only, or consider script modifications as
# well?  for production or dist mode none are expected or no functional changes
# are expected regardless of modifications; for dev would want to track
# modifications to entire script as updates.
declare -p uc_shdev_sldef METADIR B C D | redo-stamp

# ex:ft=bash:

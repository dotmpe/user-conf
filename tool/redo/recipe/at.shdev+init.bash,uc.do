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
  >&2 echo "$$/$0: Illegal env ${1@Q}"
  exit 124
}

: "${UC_SRC_ENV:=dev}"
: "${UC_DIR_ENV:=local}"

#: "${METADIR:=.${PACK_ID:?}}"
#
#: "${B:=${METADIR:?}/build}"
#: "${C:=${METADIR:?}/cache}"
#: "${D:=${METADIR:?}/dist}"
#
#>&2 mkdir -vp "${B}" "${C}" "${D}"

# basic install profiles. remote setup is so that SSH user auth/config is used
# for all provisioning
shdev_prereq=( sshuser+init gituser+init )
case "${UC_DIR_ENV:-local}" in
( local ) # sources are all at prefixes
    # including configs. scripts are copies during setup, until all checkouts
    # at prefixes are completed. initial phase seeds config copies, but helps
    # creating new instances. basedir becomes new redo project holding local
    # config files and linking to recipe scripts at dev checkouts directly.
    # This is the bleeding edge setup, and all env (including profile and rc)
    # scripts depend on the DSL for C-INC. And all user projects can be source
    # or even annex prerequisites, the goal being to build virtual local
    # projects (like ~/Documents and other user dirs) as part of an integrated,
    # full host build.
    #
    # But when starting from blank slate there is a bit if of a chicken and the
    # egg problem. Mostly this has to do with the choice of configuration to
    # use. One solution is to start packaging and distributing, using some sort
    # of toolkit however that is not the intent of the local profile. Instead,
    # the initial pre-checkout fileset is required to be provided, e.g. by
    # remote mount or local copy of the working trees.
    #
    # env-local parts are all found and properly symlinked and init-env is used
    # as trigger to provide env to use for @shdev+init (ie. with ENV_PEND="init
    # local").

    env_init=( @local{env,uc} )
    new=0
    for init in "${env_init[@]}"
    do
      [[ -e "${init:?}" ]] && continue
      new=1 && break
    done
    >&2 declare -p new
    ((new)) && {
      # Need to apply this ucinit group, but working from scratch.
      : "${UC_INIT:=/srv/src-local/local/user-conf+${UC_SRC_ENV:?}}"
      . "${_:?}/tool/sh/part/init,uc.bash" &&

      # XXX: This will get easier with some prepared groups, but need to
      # sync/build those. May later detect or configure to
      # init for bourne shell or bash, and re-use from profile cq. env or
      # otherwise.

      # Start loading parts simply using path-add, UCONF should be optional but the UC_INIT must have all parts needed to apply ucinit
      . "${UC_INIT:?}/tool/sh/part/add,path,os.bash" &&
      . "${UC_INIT:?}/tool/sh/part/assert,path,os.bash" &&
      OS-Path-Assert "${UC_INIT:?}/tool/sh/part" &&
      [[ ! "${UCONF:+set}" || ! -d "${UCONF-}" ]] || {
        OS-Path-Assert "${UCONF:-${HOME:?}/.conf}/tool/sh/part"
      } &&
      . "common,uc.bash" &&
      . "common,uconf.bash" &&
      . "common,c-inc.bash" &&  # During dev working also from C_INC
      . "part,uc.bash" &&
      . "runner,uc.bash" &&
      . "copy,directive,uc.bash" &&

      uc-runner apply ucinit ||
        :failp "Failed to apply ucinit profile" || exit
    }
    env_init_sh=".init-env.sh"
    redo-ifchange "${env_init[@]}" &&
    . "$env_init_sh"
    shdev_parts=( user{inc,conf,dirs,docs,bup,scripts,bin}+init )
    #tool/redo/recipe
    #tool/uc/part/ for env parts
    #tool/shdev/part
  ;;

( basedir ) # sources and config are prepared at basedir.
    # intention is to work with installed scripts and specific versions only.
    # so that for CI we can build exact map of the context, and also to use
    # a more bourne-shell compatible but secondary format for all env scripts
    # for non-dev hosts. Only one package is needed (assuming all prerequisites
    # are fully packaged and versioned projects and come preinstalled). (Although
    # its unlikely I will ever use ie. USBIN or HTDOCS as such.)
    # FIXME: current scripts are for composure setup, see local dir-env
    fail
  ;;
  * )
esac

exit 123

for target in "${shdev_prereq[@]}"
do
  shdev_targets+=( "@$target" )
  shdev_prereq_targets+=( "@$target" )
done
exec 4>@shdev.do.do
echo -n "redo-ifchange" >&4
for target in "${shdev_parts[@]}"
do
  echo -n " ${target%+init}"
  shdev_targets+=( "@$target" )
done >&4
echo " @local{env,uc} && . \"${env_init_sh:?}\" && uc-env -r uc && uc-stat shdev" >&4

redo-ifchange "${shdev_prereq_targets[@]}" &&

uc-env -r uc &&
uc-part shdev &&
uc-apply shdev &&

redo-ifchange "${shdev_targets[@]}"

exit

for dir in \
  "${HOME:=/home/${USER:-$(whoami)}}" \
  "${SRC_LOCAL:=$(realpath /src/local)}" \
  "${SCM_GIT_LOCAL:=$(realpath ${scm_git_pref}local)}" \
  "${ANNEX_LOCAL:=$(realpath /srv/annex-local)}"
do
  [[ -d "${dir:-}" ]] || {
    >&2 echo "$$/$0: Missing prefix ${dir@Q}"
    exit 120
  }
done

# Tags for env vars to the repository checkouts
uc_shdev_reporefs_env=(
  C_INC
  U_C
  U_S
  UCONF
  US_BIN
  HTDOC
)

# Perequisite repos for dev setup
# XXX: the real user composure include dir is submod of conf-mpe
uc_shdev_reporefs_1=( "dotmpe/composure" "test" ""
  "${SRC_LOCAL}/composure-mpe+dev" "~/project/composure-mpe" )
uc_shdev_reporefs_2=( "dotmpe/user-conf" "r0.2" ""
  "${SRC_LOCAL}/user-conf+dev" "~/project/user-conf" )
uc_shdev_reporefs_3=( "dotmpe/user-scripts" "r0.0" ""
  "${SRC_LOCAL}/user-scripts+dev" "~/project/user-scripts" )
uc_shdev_reporefs_4=( "dotmpe/conf-mpe" "master" ""
  "${SRC_LOCAL}/conf-mpe+dev" "~/.local/share/dotfiles" "~/.conf" "~/project/conf-mpe" )
uc_shdev_reporefs_5=( "dotmpe/script-mpe" "features/docker-ci" ""
  "${SRC_LOCAL}/script-mpe+dev" "~/bin" "~/project/script-mpe" )
uc_shdev_reporefs_6=( "dotmpe/htdocs-mpe" "master" ""
  "${ANNEX_LOCAL}/htdocs-mpe" "~/htdocs" )

# Additional symlink definitions
uc_shdev_sldef=(
  "${HOME:?}/.l" ".local"
  "${HOME:?}/.l/s" "share"
  "${HOME:?}/.l/s/c" "composure"
  "${HOME:?}/.l/c" "s/c"
  "${HOME:?}/.l/s/composure" "${HOME}/.conf/script/composure"
)

: "${U_C:-${uc_shdev_reporefs_2[3]}}"
. "${_:?}"/tool/uc/part/uc-assert.directive-handlers.bash

uc-assert repo-dir-env uc_shdev_reporefs_{env,}

uc_shdev_path=(
  "$C_INC/tool/bash/exec"
  "$U_C/bin"
  #"$U_C/tool/sh/exec"
  "$U_S/bin"
  #"$U_S/tool/sh/exec"
  "$UCONF/path/Generic"
  "$UCONF/path/Linux"
  "$UCONF/script/Generic"
  "$UCONF/script/Linux"
  "$UCONF/tool/sh/exec"
  "$UCONF/tool/py/exec"
)

# Keep this recipe UTD automatically
uc-assert symlink-or-copy @shdev+init.do \
  "${U_C:?}"/tool/redo/recipe/at.shdev+init.bash,uc.do

: "${EWD:=${REDO_BASE:?}}"

uc-assert symlink-all uc_shdev_sldef

# XXX: assume first scm-git instance has branch/tag; convenient when all repos are
# mirrors however that may not apply
# FIXME: not using SCM_GIT_LOCAL env here. It would make more sense to have a
# VENDOR path for looking up packages, ie. <project>/<repo>.git in this case.

for ((i=1; i<5; i+=1))
do
  # see note on redo-stamp at bottom
  declare -p "uc_shdev_reporefs_${i}" | redo-stamp
  declare -n repo_data="uc_shdev_reporefs_${i}"
  repo_ref="${repo_data[0]:?}"
  for repo in ${scm_git_pref}[0-9]*/${repo_ref}.git
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
  for repo in ${scm_git_pref}[0-9]*/${repo_ref}.git
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

. "${C_INC:?}/uconf-shell-core.inc.sh"

uc-assert path-env uc_shdev_path

. ${EWD:?}/.env-init.sh || exit

# XXX: track metadata names+values only, or consider script modifications as
# well?  for production or dist mode none are expected or no functional changes
# are expected regardless of modifications; for dev would want to track
# modifications to entire script as updates.
declare -p uc_shdev_sldef METADIR B C D | redo-stamp

# ex:ft=bash:

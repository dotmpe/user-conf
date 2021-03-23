#!/bin/sh

set -e

stderr_()
{
  echo "$log_pref$1" >&2
  test -z "$2" || exit $2
}

test -z "$Build_Deps_Default_Paths" || {

  test -n "$SRC_PREFIX" || {
    test -w /src/ \
      && SRC_PREFIX=/src/local \
      || SRC_PREFIX=$HOME/build
  }

  test -n "$PREFIX" || {
    test -w /usr/local/ \
      && PREFIX=/usr/local/ \
      || PREFIX=$HOME/.local
  }

  stderr_ "Setting default paths: SRC_PREFIX=$SRC_PREFIX PREFIX=$PREFIX"
}

test -n "$SRC_PREFIX" ||
  stderr_ "Not sure where to checkout (SRC_PREFIX missing)" 1

test -n "$PREFIX" ||
  stderr_ "Not sure where to install (PREFIX missing)" 1


test -d $SRC_PREFIX || mkdir -vp $SRC_PREFIX
test -d $PREFIX || mkdir -vp $PREFIX

install_Basher ()
{
  test -n "${BASHER_REPO-}" || BASHER_REPO=https://github.com/dotmpe/basher.git
  test -n "${BASHER_BRANCH-}" || BASHER_BRANCH=feature/better-package-env
  test -n "${BASHER_BASE-}" || BASHER_BASE=$HOME/.basher

  test -d "$BASHER_BASE" || {
    git clone "$BASHER_REPO" "$BASHER_BASE" || return
  }
  (
    cd "$BASHER_BASE" &&
    git checkout "$BASHER_BRANCH"
  ) || return
  export PATH=$BASHER_BASE/bin:$BASHER_BASE/cellar/bin:$PATH
}


uninstall_Basher ()
{
  test -n "${BASHER_BASE-}" || BASHER_BASE=$HOME/.basher
  rm -rf "$BASHER_BASE"
}


install_Bats ()
{
  test -n "${BATS_REPO-}" || BATS_REPO=https://github.com/dotmpe/bats-core.git
  test -n "${BATS_BRANCH-}" || BATS_BRANCH=master
  test -n "${BATS_BASE-}" || BATS_BASE=$SRC_PREFIX/dotmpe/bats-core

  test -d "$BATS_BASE" || {
    git clone "$BATS_REPO" "$BATS_BASE" || return
  }
  (
    cd "$BATS_BASE" &&
    git checkout "$BATS_BRANCH"
  ) || return
  ( cd $BATS_BASE && ${pref} ./install.sh $PREFIX && git clean -dfx )

}


uninstall_Bats ()
{
  test -n "${BATS_BASE-}" || BATS_BASE=$SRC_PREFIX/dotmpe/bats-core
  rm -rf "$BATS_BASE"
}


install_User_Conf ()
{
  basher install dotmpe/user-conf
}


uninstall_User_Conf ()
{
  basher uninstall dotmpe/user-conf
}


install_User_Conf_dev ()
{
  test -n "${USER_CONF_DEV_REPO-}" || USER_CONF_DEV_REPO=https://github.com/dotmpe/user-conf.git
  test -n "${USER_CONF_DEV_BRANCH-}" || USER_CONF_DEV_BRANCH=r0.2
  test -n "${USER_CONF_DEV_BASE-}" || USER_CONF_DEV_BASE=$SRC_PREFIX/User-Conf-dev

  test -d "$USER_CONF_DEV_BASE" || {
    git clone "$USER_CONF_DEV_REPO" "$USER_CONF_DEV_BASE" || return
  }
  (
    cd "$USER_CONF_DEV_BASE" &&
    git checkout "$USER_CONF_DEV_BRANCH"
  ) || return
  basher link $USER_CONF_DEV_BASE dotmpe/user-conf
}


uninstall_User_Conf_dev ()
{
  test -n "${USER_CONF_DEV_BASE-}" || USER_CONF_DEV_BASE=$SRC_PREFIX/User-Conf-dev
  rm -rf "$USER_CONF_DEV_BASE"
}


install_User_Conf_repo ()
{
  test -n "${USER_CONF_REPO_REPO-}" || USER_CONF_REPO_REPO=dotmpe:git-repos/conf-mpe.git
  test -n "${USER_CONF_REPO_BRANCH-}" || USER_CONF_REPO_BRANCH=master
  test -n "${USER_CONF_REPO_BASE-}" || USER_CONF_REPO_BASE=$HOME/.conf

  test -d "$USER_CONF_REPO_BASE" || {
    git clone "$USER_CONF_REPO_REPO" "$USER_CONF_REPO_BASE" || return
  }
  (
    cd "$USER_CONF_REPO_BASE" &&
    git checkout "$USER_CONF_REPO_BRANCH"
  ) || return
  export PATH=$USER_CONF_REPO_BASE/path/Generic:$USER_CONF_REPO_BASE/path/Linux:$PATH
  uc init ${uc_profile-} || return
  uc install
}


uninstall_User_Conf_repo ()
{
  test -n "${USER_CONF_REPO_BASE-}" || USER_CONF_REPO_BASE=$HOME/.conf
  rm -rf "$USER_CONF_REPO_BASE"
}


install_git_versioning ()
{
  test -n "${GIT_VERSIONING_REPO-}" || GIT_VERSIONING_REPO=https://github.com/dotmpe/git-versioning.git
  test -n "${GIT_VERSIONING_BRANCH-}" || GIT_VERSIONING_BRANCH=master
  test -n "${GIT_VERSIONING_BASE-}" || GIT_VERSIONING_BASE=$SRC_PREFIX/git-versioning

  test -d "$GIT_VERSIONING_BASE" || {
    git clone "$GIT_VERSIONING_REPO" "$GIT_VERSIONING_BASE" || return
  }
  (
    cd "$GIT_VERSIONING_BASE" &&
    git checkout "$GIT_VERSIONING_BRANCH"
  ) || return
  ( cd $GIT_VERSIONING_BASE &&
     ./configure.sh $PREFIX &&
    ENV_NAME=production ./install.sh &&
    git checkout . && git clean -dfx )

}


uninstall_git_versioning ()
{
  test -n "${GIT_VERSIONING_BASE-}" || GIT_VERSIONING_BASE=$SRC_PREFIX/git-versioning
  rm -rf "$GIT_VERSIONING_BASE"
}



tool_bin_install ()
{
  test -x "$(which $3)" && {
    type update_${2} >/dev/null 2>&1 || return 0
    update_${2} || return
  } || {
    install_${2} || return
  }
}

tool_bin_require ()
{
  test -x "$(which $1)" || stderr_ "Prerequisite command '$1' not found" 3
}

prepend_dependencies ()
{
  local depends=
  while test "$1" != "--"
    do depends="${depends-}${depends+" "}$1"; shift; done; shift

  for dep in $depends
  do case " $dep " in " $* " )
    set -- $(echo $@ | sed 's/ \?'"$dep"' \?/ /') ;; esac
    set -- $dep "$@"
  done

  echo "$@"
}

main_install_dependencies () # Tags...
{
  test $# -gt 0 || set -- User-Conf-dev
  stderr_ "Running 'install-dependencies $*'"

  for a in $@
  do case "$a" in
    Basher ) set -- $(prepend_dependencies Git -- $@) ;;
    Bats ) set -- $(prepend_dependencies Git -- $@) ;;
    User-Conf ) set -- $(prepend_dependencies Basher Git -- $@) ;;
    User-Conf-dev ) set -- $(prepend_dependencies Basher Git -- $@) ;;
    User-Conf-repo ) set -- $(prepend_dependencies Git -- $@) ;;
    git-versioning ) set -- $(prepend_dependencies Git -- $@) ;;
  esac; done
  stderr_ "Resolved prerequisites '$*', running install..."

  while test $# -gt 0
  do case "$1" in
    Bash ) tool_bin_require bash ;;
    Basher ) tool_bin_install $1 Basher basher ;;
    Bats ) tool_bin_install $1 Bats bats ;;
    Git ) tool_bin_require git ;;
    User-Conf ) tool_bin_install $1 User_Conf uc ;;
    User-Conf-dev ) tool_bin_install $1 User_Conf_dev uc ;;
    User-Conf-repo ) tool_bin_install $1 User_Conf_repo user-conf-repo ;;
    git-versioning ) tool_bin_install $1 git_versioning git-versioning ;;

    * ) stderr_ "Unknown tool '$1'" 1 ;;
    esac
    stderr_ "OK. Pre-requisites for '$1' checked"
    shift
  done
}


main_load ()
{
  #test -x "$(which tput)" && ... TODO: colorize install-dependencies
  log_pref="[install-dependencies] "
  #stderr_ "Loaded (pwd:$PWD)"
}


main_load && main_install_dependencies "$@"
# Generated at 2021-02-23T03:17+01:00 using /home/hari/.local/composure/Tools/install-dependencies.scr

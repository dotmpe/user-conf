#!/usr/bin/env bash


vc_uc_lib__init()
{
  test "${vc_uc_lib_init-}" = "0" && return
  #lib_groups \
  #  git: \
  #  hg: \
  #  bzr: \
  #  svn: \
  #  fields:vc-fields-{}
}


vc_bzrdir()
{
  test -d "${1-}" || error "vc-bzrdir expected dir argument: '$1'" 1
  (
    cd "$1"
    root=$(bzr info 2> /dev/null | grep 'branch root')
    if [ -n "$root" ]; then
      echo "$root"/.bzr | sed 's/^\ *branch\ root:\ //'
    fi
  )
  return 1
}

# vc_git_initialized
vc_check_git()
{
  test $# -eq 1 -a -n "${1-}" || return

  # There should be a head
  # other checks on .git/refs seem to fail after garbage collect
  git rev-parse HEAD >/dev/null ||
  test "$(echo $1/refs/heads/*)" != "$1/refs/heads/*" ||
  test "$(echo $1/refs/remotes/*/HEAD)" != "$1/refs/remotes/*/HEAD"
}

# NOTE: scanning like this does not allow to nest in different repositories
# except but one in order.
vc_dir()
{
  test $# -le 1 || err "vc-dir surplus arguments" 1
  test -n "${1-}" || set -- "."
  test -d "$1" || error "vc-dir expected dir argument: '$1'" 1
  vc_gitdir "$1" && return
  vc_bzrdir "$1" && return
  vc_svndir "$1" && return
  vc_hgdir "$1" && return
  return 1
}

vc_flags_git()
# Flags:
#   b:branch
#   c:repotype - BARE: if no working tree is checked out
#   g:gitdir - the gitdir for the given or current basedir
#   i:staged
#   r:state
#   s:stashed
#   u:untracked
#   w:modified
{
  test $# -le 2 || return
  test $# -eq 1 || set -- "$PWD"
  test -n "$1" -a -d "$1" || err "No such directory '$1'" 3
  local b r= g fmt
  fmt=${2:-(%s%s%s%s%s%s%s%s)}

  g="$(vc_gitdir "$1")"
  test -e "$g" || return

  vc_check_git "$g" || {
    echo "(!git:unborn)"
    return
  }

  cd "$1"
  std_quiet git status -s || {
    echo "(!git:E$?)"
    return
  }

  if [ -f "$g/rebase-merge/interactive" ]; then
    r="|REBASE-i"
    b="$(cat "$g/rebase-merge/head-name")"
  elif [ -d "$g/rebase-merge" ]; then
    r="|REBASE-m"
    b="$(cat "$g/rebase-merge/head-name")"
  else
    if [ -d "$g/rebase-apply" ]; then
      if [ -f "$g/rebase-apply/rebasing" ]; then
        r="|REBASE"
      elif [ -f "$g/rebase-apply/applying" ]; then
        r="|AM"
      else
        r="|AM/REBASE"
      fi
    elif [ -f "$g/MERGE_HEAD" ]; then
      r="|MERGING"
    elif [ -f "$g/BISECT_LOG" ]; then
      r="|BISECTING"
    fi

    b="$(git symbolic-ref HEAD 2>/dev/null)" || {

      b="$(
      case "${GIT_PS1_DESCRIBE_STYLE-}" in
      (contains)
        git describe --contains HEAD ;;
      (branch)
        git describe --contains --all HEAD ;;
      (describe)
        git describe HEAD ;;
      (* | default)
        git describe --exact-match HEAD ;;
      esac 2>/dev/null)" ||

      b="$(cut -c1-11 "$g/HEAD" 2>/dev/null)" || b="unknown"
      # XXX b="($b)"
    }
  fi

  local w= i= s= u= c=

  if [ "true" = "$(git rev-parse --is-inside-git-dir 2>/dev/null)" ]; then
    if [ "true" = "$(git rev-parse --is-bare-repository 2>/dev/null)" ]; then
      c="BARE:"
    else
      b="DIR!"
    fi
  elif [ "true" = "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then
    if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ]; then

      if [ "$(git config --bool bash.showDirtyState)" != "false" ]; then

        git diff --no-ext-diff --ignore-submodules \
          --quiet --exit-code || w='*'

        if git rev-parse --quiet --verify HEAD >/dev/null; then

          git diff-index --cached --quiet \
            --ignore-submodules HEAD -- || i="+"
        else
          i="#"
        fi
      fi
    fi
    if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ]; then
      git rev-parse --verify refs/stash >/dev/null 2>&1 && s="$"
    fi

    if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ]; then
      if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        u="~"
      fi
    fi
  fi

  repotype="$c"
  branch="${b##refs/heads/}"
  modified="$w"
  staged="$i"
  stashed="$s"
  untracked="$u"
  state="$r"

  x=
  rg=$g
  test -f "$g" && {
    g=$(dirname $g)/$(cat .git | cut -d ' ' -f 2)
  }

  # TODO: move to extended escription cmd
  #x="; $(git count-objects -H | sed 's/objects/obj/' )"

  if [ -d $g/annex ]; then
    #x="$x; annex: $(echo $(du -hs $g/annex/objects|cut -f1)))"
    x="$x annex"
  fi

  #shellcheck disable=SC2059 # Variable is set to pattern
  printf "$fmt" "$c" "${b##refs/heads/}" "$w" "$i" "$s" "$u" "$r" "$x"

  #shellcheck disable=2164 # XXX: cd is at end of execution block (typ)
  cd "$1"
}

vc_getscm()
{
  scmdir="$(vc_dir "$@")"
  test -n "$scmdir" || return 1
  scm="$(basename "$scmdir" | cut -c2-)"
}

# Given COPY src and trgt file from user-conf repo,
# see if target path is of a known version for src-path in repo,
# and that its the currently checked out version.
vc_gitdiff ()
{
  test -n "${1-}" || err "vc-gitdiff expected src" 1
  test -n "${2-}" || err "vc-gitdiff expected trgt" 1
  test -z "${3-}" || err "vc-gitdiff surplus arguments" 1
  test -n "${GITDIR-}" || err "vc-gitdiff expected GITDIR env" 1
  test -d "$GITDIR" || err "vc-gitdiff GITDIR env is not a dir" 1

  target_sha1="$(${sudor:-} git hash-object "$2")"
  co_path="$(cd $GITDIR;git rev-list --objects --all | grep "^$target_sha1" | cut -d ' ' -f 2)"
  test -n "$co_path" -a "$1" = "$GITDIR/$co_path" && {
    # known state, file can be safely replaced
    test "$target_sha1" = "$(git hash-object "$1")" \
      && return 0 \
      || {
        return 1
      }
  } || {
    return 2
  }
}

vc_gitdir()
{
  test $# -le 1 || err "vc-gitdir surplus arguments" 1
  test -n "${1-}" || set -- "."
  test -d "$1" || err "vc-gitdir expected dir argument" 1

  test -d "$1/.git" && {
    echo "$1/.git"
  } || {
    test "$1" = "." || cd $1 || return
    git rev-parse --git-dir 2>/dev/null
  }
# XXX: cleanup
  #local pwd="$(pwd)"
  #cd "$1"
  #repo=$(git rev-parse --git-dir 2>/dev/null)
  #while fnmatch "*/.git/modules*" "$repo"
  #do repo="$(dirname "$repo")" ; done
  #test -n "$repo" || return 1
  #echo "$repo"
  ##repo="$(git rev-parse --show-toplevel)"
  ##echo $repo/.git
  #cd "$pwd"
}

vc_hgdir()
{
  test -d "${1-}" || error "vc-hgdir expected dir argument: '$1'" 1
  ( cd "$1" && go_to_dir_with .hg && echo "$(pwd)"/.hg || return 1 )
}

# See if path is in GIT checkout
vc_isgit()
{
  test -e "${1-}" || err "vc-isgit expected path argument" 1
  test -d "$1" || {
    set -- "$(dirname "$1")"
  }
  ( cd "$1" && go_to_dir_with .git || return 1 )
}

vc_isscmdir()
{
  test -n "${1-}" || set -- "."
  test -d "$1" || error "vc-isscmdir expected dir argument: '$1'" 1
  vc_isgit "$1" && return
  vc_isbzr "$1" && return
  vc_issvn "$1" && return
  vc_ishg "$1" && return
  return 1
}

vc_issvn()
{
  test -d "${1-}" || error "vc-issvn expected dir argument: '$1'" 1
  test -e "$1"/.svn
}

# special updater (for Bash PROMPT_COMMAND)
vc_prompt_command()
{
  test $# -le 1 || return
  test $# -eq 1 || set -- "$PWD"
  test -n "$1" -a -d "$1" || err "No such directory '$1'" 3

  local pwdref cache

  # cache response in file
  pwdref="$(echo "$1" | tr '/' '-' )"
  cache="$(statusdir.sh assert-dir vc prompt-command "$pwdref")" || return

  test ! -e "$cache" -o "$1"/.git -nt "$cache" && {
    __vc_status "$1" > "$cache"
  }

  cat "$cache"
}

vc_ps1()
{
  local s
  s="$(vc_status "$PWD")" || return $?
  echo "$s"
}

vc_remote()
{
  test -n "$1" || set -- "." "origin"
  test -d "$1" || error "vc-remote expected dir argument" 1
  test -n "$2" || error "vc-remote expected remote name" 1
  test -z "$3" || error "vc-remote surplus arguments" 1

  local pwd=$PWD
  cd "$1"
  vc_remote_$scm "$2"
  cd "$pwd"
}

vc_remote_git()
{
  git config --get remote.$1.url
}

# XXX: unused
vc_remote_hg()
{
  hg paths "$1"
}

vc_status ()
{
  test $# -le 1 || return
  test $# -eq 1 || set -- "$PWD"
  test -n "$1" -a -d "$1" || err "No such directory '$1'" 3

  local w short realcwd sub git bzr

  realcwd="$(cd "$1" && pwd -P)"
  #short="$(realpath "$1")"
  short="${1/#$HOME/\~}"
  test -n "$short" || err "homepath" 1

  git="$(vc_gitdir "$realcwd")"
  bzr="$(vc_bzrdir "$realcwd")"

  if [ -n "$git" ]; then

    vc_check_git "$git" || {
      echo "$realcwd (git:unborn)"
      return
    }

    checkoutdir="$(cd "$realcwd" && git rev-parse --show-toplevel)"

    [ -n "$checkoutdir" ] && {

      rev="$(cd "$realcwd" && git show "$checkoutdir" | grep '^commit' \
        | sed 's/^commit //' | sed 's/^\([a-f0-9]\{9\}\).*$/\1.../')"
      sub="${realcwd##$checkoutdir}"
    } || {

      realgitdir="$(cd "$git"&& pwd -P)"
      rev="$(vc_revision_git)"
      #rev="$(cd $realcwd; git show . | grep '^commit'|sed 's/^commit //' | sed 's/^\([a-f0-9]\{9\}\).*$/\1.../')"
      realgit="$(basename "$realgitdir")"
      sub="${realcwd##$realgit}"
    }

    short="${short%$sub}"
    echo "$short\[$GREEN\] $(vc_flags_git "$realcwd" "[git:%s%s%s%s%s%s%s%s $rev]")\[$NORMAL\]$sub"

  elif [ -n "$bzr" ]; then
    #if [ "$bzr" = "." ];then bzr="./"; fi
    realbzr="$(cd "$bzr" && pwd -P)"
    realbzr="${realbzr%/.bzr}"
    sub="${realcwd##$realbzr}"
    short="${short%$sub/}"
    local revno=$(bzr revno)
    local s=''
    if [ "$(bzr status|grep added)" ]; then s="${s}+"; fi
    if [ "$(bzr status|grep modified)" ]; then s="${s}*"; fi
    if [ "$(bzr status|grep removed)" ]; then s="${s}-"; fi
    if [ "$(bzr status|grep unknown)" ]; then s="${s}~"; fi
    [ -n "$s" ] && s="$s "
    echo "$short$CSEP [bzr:$s$revno]$sub"

  #else if [ -d ".svn" ]; then
  #  local r=$(svn info | sed -n -e '/^Revision: \([0-9]*\).*$/s//\1/p' )
  #  local s=""
  #  local sub=
  #  if [ "$(svn status | grep -q -v '^?')" ]; then s="${s}*"; fi
  #  if [ -n "$s" ]; then s=" ${s}"; fi;
  #  echo "$short$PSEP [svn:r$r$s]$sub"
  else
    echo "$short"
  fi

  #shellcheck disable=2164 # XXX: cd is at end of execution block (typ)
  cd "$1"
}

vc_revision_git()
{
  git show-ref --head HEAD -s
}

vc_scmdir()
{
  vc_dir "$@" || error "can't find SCM-dir" 1
}

vc_svndir()
{
  test -d "${1-}" || error "vc-svndir expected dir argument: '$1'" 1
  ( test -e "$1/.svn" && echo $(pwd)/.svn || return 1 )
}



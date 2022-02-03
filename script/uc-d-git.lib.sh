#!/usr/bin/env bash

## GIT directive

d_GIT()
{
  test -n "$1" || error "expected url for $diridx:GIT" 1
  test -n "$2" || error "expected target path for $diridx:GIT <$1>" 1
  test -n "${3-}" || set -- "$1" "$2" "origin" "${4-}" "${5-}"
  test -n "${4-}" || set -- "$1" "$2" "$3" "master" "${5-}"
  test -n "${5-}" || set -- "$1" "$2" "$3" "$4" "clone"
  test $# -lt 6 || error "surplus params: '$6'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) \
    || error "target must be existing directory or a new name in one: $2" 1

  test ! -e "$2/.git" || {
    req_git_remote "$1" "$2" "$3" || return $?
  }

  test ! -e "$2" -a -d "$(dirname "$2")" || {
    test -e "$2/.git" && req_git_remote "$1" "$2" "$3" || {
      test "$(basename "$1" .git)" != "$1" \
        || error "cannot get target basename from GIT <$1>, please provide "\
"full check path (for $diridx:GIT)" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3" "$4" "$5"
    }
  }

  req_git_age

  case "$RUN" in update ) PREF= ;; stat ) PREF="echo '** DRY-RUN **: '" ;; esac

  case "$5" in

    clone )
      test -e "$2/.git" && { ( cd $2

        git diff --quiet && {
          GITDIR="$(vc_gitdir)"
          test -d "$GITDIR" || error "cannot determine gitdir at <$2>" 1
          { { test -e $GITDIR/FETCH_HEAD || {
              std_info "No FETCH_HEAD in <$2>" ; false; }
            } && {
              newer_than $GITDIR/FETCH_HEAD $GIT_AGE
            }
          } || {
            std_info "Fetching <$2> branch '$4' from remote '$3'"
            test "$RUN" = stat && {
              git fetch --dry-run -q $3 $4 || true
            } || {
              git fetch -q $3 $4 2>/dev/null || {
                error "Error fetching remote $3 for $2"; return 1; }
            }
          }
          debug "Comparing <$2> branch '$4' with remote '$3' ref"
          git diff --quiet && {
            git show-ref --quiet $3/$4 || git fetch $3
            git show-ref --quiet $3/$4 || {
              warn "No ref '$3/$4'"
              return 1
            }
            git diff --quiet $3/$4..HEAD && {
              test "$4" = "master" \
                && std_info "Checkout $2 clean and up-to-date" \
                || std_info "Checkout $2 clean and up-to-date at branch $4"
            } || {

              # Try to merge remote, but only not if bare. NOTE: need to keep .git
              # at remote URLs for to denote bare, strip .../.git from checkout.
              fnmatch "*/.git " "$1" && return

              note "Checkout <$2> clean but not in sync with '$3' at branch '$4'"
              false # break to co/pull
            }
          } || {
            test -e ".git/refs/heads/$4" || {
              ${PREF}git checkout -b $4 -t $3/$4 || return
            }
            ${PREF}git checkout $4 -- || return
            ${PREF}git pull $3 $4 || return
            test ! -e .gitmodules || { # XXX: assumes always need modules
              git submodule update --init
            }
            test "$4" = "master" \
              && note "Updated <$2> from remote '$3'" \
              || note "Updated <$2> from remote '$3' (at branch $4)"
            case "$RUN" in update ) ;; * ) return 1 ;; esac
          }
        } || {
          test "$4" = "master" \
            && warn "Checkout at <$2> looks dirty" \
            || warn "Checkout of '$4' at <$2> looks dirty"
          return 1
        }
        ) || return

      } || {
        test "$4" = "master" \
          && note "Checkout missing at <$2>" \
          || note "Checkout of '$4' missing at <$2>"
        ${PREF}git $5 "$1" "$2" --origin $3 --branch $4
        case "$RUN" in update ) return $? ;; * ) return 1 ;; esac
      } ;;

    * ) error "Invalid GIT mode $5"; return 1 ;;

  esac
}

d_GIT_stat ()
{
  RUN=stat d_GIT "$@" || return $?
}

d_GIT_update ()
{
  RUN=update d_GIT "$@" || return $?
}

# Id: US:

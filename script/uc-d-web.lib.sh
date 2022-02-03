#!/usr/bin/env bash

## Web directive (cURL)

d_WEB () # URL TARGET-PATH
{
  test -n "$1" || error "expected url for $diridx:WEB" 1
  test -n "$2" || error "expected target path for $dirix:WEB <$1>" 1
  test $# -lt 4 || error "surplus params: '$4'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) -o -f "$2" \
    || error "target must be existing directory or a (new) file in one: $2 "\
"(for $diridx:WEB)" 1

  test -d "$2" && {
      test "$(basename "$1")" != "$1" \
        || error "cannot get target basename from URL '$1', please provide "\
"full path (for $diridx:WEB)" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3"
  }

  case "$RUN" in update ) PREF= ;; stat ) PREF="echo '** DRY-RUN **: '" ;; esac

  tmpf=$TMP/$(uuidgen)
  curl -LsS "$1" -o $tmpf || {
    error "Unable to fetch '$1' to $tmpf"
    return 1
  }
  test -e "$tmpf" || {
    error "Failed to fetch '$1' to $tmpf"
    return 1
  }

  test -e "$2" && {
    diff -bq $2 $tmpf && {
      std_info "Up to date with web at $2"
    } || {
      ${PREF}cp $tmpf $2 || {
        error "Failed to copy $tmpf to '$1'"
        return 1
      }
      note "Updated $2 from $1"
      case "$RUN" in update ) ;; * ) return 1 ;; esac
    }
  } || {
    ${PREF}cp $tmpf $2 || {
       error "Failed to copy $tmpf to '$1'"
      return 1
    }
    note "New path $2 from $1"
    case "$RUN" in update ) ;; * ) return 1 ;; esac
  }
}

d_WEB_update () # URL TARGET-PATH
{
  RUN=update d_WEB "$@" || return $?
}

d_WEB_stat () # URL TARGET-PATH
{
  RUN=stat d_WEB "$@" || return $?
}

# Id: U-C:

#!/usr/bin/env bash

## Copy directive

# TODO: make copy update permission bits
d_COPY() # SCM-Src-File Host-Target-File
{
  local sudor= sudow= sudod=
  test -e "$1" && set -- "$(realpath "$1")" "$2" "$1"
  test -f "$1" || {
    error "not a file: $1 ($(pwd))"
    return 1
  }
  uc_sudo_path_target "$@"

  ${sudor}test -e "$2" -a -d "$2" && {
      copy_target="$(normalize_relative "$2/$(basename "$1")")"
      debug "Expanding '$2' to '$copy_target'"
      set -- "$1" "$copy_target"
  } || true

  ${sudor}test -e "$2" && {
    # Existing copy

    stat=0
    ${sudor}test -f "$2" && {
      diff_copy "$1" "$2" || { stat=2
        ${sudor}diff -q "$1" "$2" && {
           note "Changes resolved but uncommitted for 'COPY \"$1\" \"$2\"'"
           return
        }
        # Check existing COPY version
        test $STD_INTERACTIVE -eq 1 && {
          # XXX: lmfao. shut up
          #${sudow}test -w /dev/tty || {
            sudo chmod go+rw /dev/tty || return; # }
          # XXX: FIXME without TTY vimdiff won't work here
          ${sudow}vimdiff "$1" "$2" </dev/tty >/dev/tty && {
            ${sudor}diff -q "$1" "$2" && stat=0 || return 1
          } ||
            warn "Interactive Diff still non-zero ($?)"
        } || return 1
      }
    } || {
      ${sudor}test ! -f "$2" && {
        error "Copy target path already exists and not a file '$2'"
        return 2
      }
    }

    case "$stat" in
      0 )
          std_info "Up to date with '$1' at '$2'"
          return
        ;;
      2 )
          warn "Unknown state of '$1' for path '$2'"
          return 2
        ;;
    esac

    case "$RUN" in
      stat )
          note "Out of date with '$1' at '$2'"
          return 1
        ;;
      update )
          ${sudow}cp "$1" "$2" || {
            log "Copy to $2 failed"
            return 1
          }
        ;;
    esac

  } || {

    # New copy
    test -w "$(dirname "$2")" || {
      test ${warn_on_sudo:-1} -eq 0 || {
        warn "Setting sudo to access '$(dirname $2)' (for '$1')"
      }
      sudod="sudo "
    }
    case "$RUN" in
      stat )
        log "Missing copy of '$1' at '$2'"
        return 1
        ;;
      update )
        ${sudod}cp "$1" "$2" &&
        log "New copy of '$1' at '$2'" || {
          warn "Unable to copy '$1' at '$2'"
          return 1
        }
        ;;
    esac
  }
}

d_COPY_update ()
{
  RUN=update d_COPY "$@" || return $?
}

d_COPY_stat ()
{
  RUN=stat d_COPY "$@" || return $?
}

# Id: U-C:

#!/usr/bin/env bash


ansi_uc_lib_load ()
{
  : ${ncolors:=$(tput colors)}

  # Load term-part to set this to more sensible default
  #: ${COLORIZE:=0}
}

ansi_uc_env_def ()
{
  declare -g \
    _f0= BLACK=   _b0= BG_BLACK= \
    _f1= RED=     _b1= BG_RED= \
    _f2= GREEN=   _b2= BG_GREEN= \
    _f3= YELLOW=  _b3= BG_YELLOW= \
    _f4= BLUE=    _b4= BG_BLUE= \
    _f5= CYAN=    _b5= BG_CYAN= \
    _f6= MAGENTA= _b6= BG_MAGENTA= \
    _f7= WHITE=   _b7= BG_WHITE= \
    BOLD= REVERSE= NORMAL=
}

ansi_uc_lib_init ()
{
  test ${COLORIZE:-1} -eq 1 || {
    ansi_uc_env_def
    return 0
  }

  local tset
  case "$TERM" in xterm | screen ) ;; ( * ) false ;; esac && tset=set ||
  case "$TERM" in xterm-256color | screen-256color ) ;; ( * ) false ;; esac &&
  case ${ncolors:-0} in
    ( 8 ) tset=set ;;
    ( 256 ) tset=seta ;;
    ( * ) false ;;
  esac || {
    # If no color support found, simply set vars and return zero-status.
    # Maybe want to fail trying to init ANSI.lib later...
    bash_env_exists _f0 || ansi_uc_env_def; return;
  }

  : ${REVERSE:=$(tput rev)}
  : ${BOLD:=$(tput bold)}
  : ${NORMAL:=$(tput sgr0)}

  # XXX: might as well rewrite to raw codes and do away with xterm case
  #local esc=$(ansi_uc_esc)

  case "$TERM" in
  ( screen-256color | \
    xterm-256color | \
    xterm )

      : ${_f0:=${BLACK:=$(tput ${tset}f 0)}}
      : ${_f2:=${GREEN:=$(tput ${tset}f 2)}}
      : ${_f5:=${CYAN:=$(tput ${tset}f 5)}}
      : ${_f7:=${WHITE:=$(tput ${tset}f 7)}}

      test ${ncolors:-0} -eq 8 || {
        : ${_b0:=${BG_BLACK:=$(tput ${tset}b 0)}}
        : ${_b2:=${BG_GREEN:=$(tput ${tset}b 2)}}
        : ${_b5:=${BG_CYAN:=$(tput ${tset}b 5)}}
        : ${_b7:=${BG_WHITE:=$(tput ${tset}b 7)}}
      }
    ;;

  ( * )
      ansi_uc_env_def
      return;
    ;;
  esac

  case "$TERM" in

  ( xterm-256color | \
    screen-* )
        : ${_f1:=${RED:=$(tput ${tset}f 1)}}
        : ${_f3:=${YELLOW:=$(tput ${tset}f 3)}}
        : ${_f4:=${BLUE:=$(tput ${tset}f 4)}}
        : ${_f6:=${MAGENTA:=$(tput ${tset}f 6)}}

        test ${ncolors:-0} -eq 8 || {
          : ${_b1:=${BG_RED:=$(tput ${tset}b 1)}}
          : ${_b3:=${BG_YELLOW:=$(tput ${tset}b 3)}}
          : ${_b4:=${BG_BLUE:=$(tput ${tset}b 4)}}
          : ${_b6:=${BG_MAGENTA:=$(tput ${tset}b 6)}}
        }
      ;;

  ( xterm )
        : ${_f1:=${BLUE:=$(tput ${tset}f 1)}}
        : ${_f3:=${MAGENTA:=$(tput ${tset}f 3)}}
        : ${_f4:=${RED:=$(tput ${tset}f 4)}}
        : ${_f6:=${YELLOW:=$(tput ${tset}f 6)}}

        test ${ncolors:-0} -eq 8 || {
          : ${_b1:=${BG_BLUE:=$(tput ${tset}b 1)}}
          : ${_b3:=${BG_MAGENTA:=$(tput ${tset}b 3)}}
          : ${_b4:=${BG_RED:=$(tput ${tset}b 4)}}
          : ${_b6:=${BG_YELLOW:=$(tput ${tset}b 6)}}
        }
      ;;
  esac
}

ansi_uc_esc ()
{
  case "$uname" in

    Darwin ) # BSD echo
        esc=`echo -e '\033'`
      ;;

    Linux | CYGWIN_NT-* )

        case "$(sed --version)" in *"This is not GNU sed"* )
              # For matchbox sed
              esc=`echo -e '\033'`
            ;;
          ( * )
              # For GNU echo/sed: \o033
              esc=`echo '\o33'`
            ;;
        esac
      ;;

    * ) $LOG error "" "No ansi-escape -type for $uname" ; return 1 ;;
  esac
}

#

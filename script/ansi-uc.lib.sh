#!/usr/bin/env bash


ansi_uc_lib_load ()
{
  : ${ncolors:=$(tput colors)}

  # Load term-part to set this to more sensible default
  : ${COLORIZE:=0}

  test $COLORIZE -eq 1 || ansi_uc_env_def
}

ansi_uc_env_def ()
{
  declare \
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
  local tset
  # XXX: used urxvt for ref
  case ${ncolors:-0} in

    (   8 ) tset=set ;;
    ( 256 ) tset=seta ;;

    # If no color support found, simply set vars and return zero-status.
    # Maybe want to fail trying to init ANSI.lib later...
    (   * ) bash_env_exists _f0 || ansi_uc_env_def; return ;;
  esac

  : ${_f0:=${BLACK:=$(tput ${tset}f 0)}}
  : ${_f1:=${RED:=$(tput ${tset}f 1)}}
  : ${_f2:=${GREEN:=$(tput ${tset}f 2)}}
  : ${_f3:=${YELLOW:=$(tput ${tset}f 3)}}
  : ${_f4:=${BLUE:=$(tput ${tset}f 4)}}
  : ${_f5:=${CYAN:=$(tput ${tset}f 5)}}
  : ${_f6:=${MAGENTA:=$(tput ${tset}f 6)}}
  : ${_f7:=${WHITE:=$(tput ${tset}f 7)}}

  : ${_b0:=${BG_BLACK:=$(tput ${tset}b 0)}}
  : ${_b1:=${BG_RED:=$(tput ${tset}b 1)}}
  : ${_b2:=${BG_GREEN:=$(tput ${tset}b 2)}}
  : ${_b3:=${BG_YELLOW:=$(tput ${tset}b 3)}}
  : ${_b4:=${BG_BLUE:=$(tput ${tset}b 4)}}
  : ${_b5:=${BG_CYAN:=$(tput ${tset}b 5)}}
  : ${_b6:=${BG_MAGENTA:=$(tput ${tset}b 6)}}
  : ${_b7:=${BG_WHITE:=$(tput ${tset}b 7)}}

  : ${REVERSE:=$(tput rev)}
  : ${BOLD:=$(tput bold)}
  : ${NORMAL:=$(tput sgr0)}
}

#

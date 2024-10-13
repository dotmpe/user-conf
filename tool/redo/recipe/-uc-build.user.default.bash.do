#!/usr/bin/env bash

set -euo pipefail

# XXX: symlinked to ~/default.do

[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = default.do ]] ||
  $LOG alert "" "Illegal env" "" 124

# To bootstrap the build system for a project, it should aggregate and then
# select from prewritten available recipes (or parts of) and then expand on
# those.

# Before that some definitions need to be established that are in part already
# defined by the host OS. The most basic parameter here is PATH, and to the
# (Linux) kernel the default for that is (at least) ``/bin:/usr/bin:$PWD``

# PATH affects all exec (and shell source) statements, and so it makes sense
# to have full control of what is in it based on context. PPATH is used as a
# 'proto-path' or 'project-path' where every package that has build parts is
# listed (or all those that make up a particular context).

# SCRIPTPATH is where user-scripts looks for *.lib.sh files
# BUILDPATH is where user-config looks for recipe/* or part/* files
# XXX: make C_INC a lookup path as well?
# USERDIRS is a standard set like PPATH but with all predefined purposes (see
# XDG user dirs, e.g. xdg-user-dir DESKTOP)
#
# xdg-user-dirs := desktop,documents,downloads,music,pictures,publicshare,templates,videos

# There are different strategies of generating values for these parameters,
# as well as injecting user-config and seed values. See individual recipes.

# All lookup recipes build an array as that seems to give the most clean
# syntax, and allows for spaces in the paths (see os-path) and without using
# a subshell plus while-read loop reading fields to do that. Otherwise if
# spaces do not occur in lookup paths (which is also very sensible approach)
# this wouldnt really be needed. Both .var.sh and .lookup.sh targets are
# available depending on this choice for a certain context.

# XXX: some os-* functionality is used now that checks if var-ref is already an
# array; a more direct approach here is preferable (and I really dont want
# to suggest mixing such usage, but thats really more of a naming issue to me).

# XXX: it is possibly to outfactor more of these scripts, ie. by using
# os-lookuppaths. However that reduces readability further, and inverts the
# .var->lookup dependency. I think for these recipes the most simple approach
# while allowing for different usage options is the right one here.

# XXX actually XDG requires a lot more work to figure out and setup the
# proper desktop files and templates. But paths are all configured using
# ~/.config/user-dirs.dirs, and a key 'dotfiles' is added to include a
# user-conf style config and seed repository

# TOTEST: with and without proper env this command (or function) would either
# extend the current shell session (if defined as function) to load that env;
# or prepare that env and restart the script (fork to a new instance) to
# properly load it and run the entire script to complete the current given
# command.
us-env -r user-script &&
# XXX: for all those use cases to work, need to change boilerplate to
#us-env -r user-script -- "$@" &&

# XXX: rewrite to us-env -r uc-build &&
lib_require sys os build-uc &&

ucbuild_do4124 uc-build.user.default.bash.do "$@"

exit $?

case "${2:?}" in
( all )
    redo-ifchange \
      @hostpaths+dev \
      @recipes+dev
  ;;


( ".local/cache/PATH.env.sh" )
    # Store current value of PATH
    echo "$PATH" > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;


( ".local/cache/ANNEXDIRS.lookup.sh" )
    redo-ifchange ".local/cache/ANNEXDIRS.var.sh" &&
    . ".local/cache/ANNEXDIRS.var.sh" &&
    os_path ANNEXDIRS &&
    declare -p ANNEXDIRS{,_arr} > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/ANNEXDIRS.var.sh" )
    ANNEXDIRS=
    redo-ifchange ".local/cache/VOLUMEDIRS.lookup.sh" &&
    . ".local/cache/VOLUMEDIRS.lookup.sh" &&
    for voldir in "${VOLUMEDIRS_arr[@]}"
    do
      for annexbase in $voldir/{Annex,annex}
      do
        [[ -d "$annexbase" ]] || continue
        ANNEXDIRS=${ANNEXDIRS:-}${ANNEXDIRS:+:}$annexbase
      done
    done &&
    declare -x ANNEXDIRS=$ANNEXDIRS &&
    declare -p ANNEXDIRS > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/BUILDPATH.lookup.sh" )
    redo-ifchange ".local/cache/BUILDPATH.var.sh" &&
    . ".local/cache/BUILDPATH.var.sh" &&
    os_path BUILDPATH &&
    declare -p BUILDPATH{,_arr} > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/BUILDPATH.var.sh" )
    BUILDPATH=
    # Generate BUILDPATH by looking up 'tool/{build,redo}' dirs (on PPATH)
    redo-ifchange ".local/cache/PPATH.lookup.sh" &&
    . ".local/cache/PPATH.lookup.sh" &&
    for path in "${PPATH_arr[@]}"
    do
      for pathbase in $path/tool/{build,redo}
      do
        [[ -d "$pathbase" ]] || continue
        BUILDPATH=${BUILDPATH:-}${BUILDPATH:+:}$pathbase
      done
    done &&
    declare -x BUILDPATH=$BUILDPATH &&
    declare -p BUILDPATH > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/PATH.lookup.sh" )
    redo-ifchange ".local/cache/PATH.var.sh" &&
    (
      . ".local/cache/PATH.var.sh" &&
      os_path PATH &&
      declare -p PATH{,_arr} > "${3:?}"
    ) &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/PATH.var.sh" )
    # Generate PATH by looking up 'bin' and 'tool/bin' dirs (on PPATH)
    # This is slighty more involved as other recipes, to avoid interfering with
    # command lookup during recipe run.
    redo-ifchange ".local/cache/PPATH.lookup.sh" &&
    . ".local/cache/PPATH.lookup.sh" &&
    _PATH=/bin:/usr/bin &&
    PATH_cnt=2 &&
    for path in "${PPATH_arr[@]}"
    do
      for pathbase in $path/{,tool/}bin
      do
        [[ -d "$pathbase" ]] || continue
        _PATH=${_PATH:-}${_PATH:+:}$pathbase
        incr PATH_cnt
      done
    done &&
    stderr echo "Found ${PATH_cnt} dirs for 'PATH'" &&
    ( declare -x PATH=$_PATH &&
      declare -p PATH > "${3:?}"
    ) &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/PATH-ucbuild-type-parts.sh" )
    redo-ifchange ".local/cache/BUILDPATH.lookup.sh" &&
    . ".local/cache/BUILDPATH.lookup.sh" &&
    rcnt=0 &&
    for buildpath in "${BUILDPATH_arr[@]}"
    do
      for part in ${buildpath:?}/part/*.type.{,ba}sh
      do
        [[ -s "$part" ]] || continue
        incr rcnt &&
        echo "ucbuild_type_parts+=( \"$part\" )"
      done
    done > "${3:?}" &&
    stderr echo "Found ${rcnt} parts for 'type'" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/PPATH.lookup.sh" )
    redo-ifchange ".local/cache/PPATH.var.sh" &&
    . ".local/cache/PPATH.var.sh" &&
    os_path PPATH &&
    declare -p PPATH{,_arr} > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/PPATH.var.sh" )
    # Generate PPATH by adding existing user-dirs and looking for
    # /src/local/*+${tags} dirs. Alternative and earlier version of this
    # heuristic used ~/project/*/ and have looked for packagage.y*ml files,
    # even using the locate database for a complete, system-wide list of
    # project source package dirs.
    redo-ifchange ".local/cache/USERDIRS.var.sh" &&
    . ".local/cache/USERDIRS.var.sh" &&
    os_path USERDIRS &&
    PPATH=$USERDIRS &&
    : "${PPATH//[^:]}" &&
    PPATH_cnt=$(( 1 + ${#_} )) &&
    for srcdir in /src/local/*+current{,+working}
    do
      PPATH=${PPATH:-}${PPATH:+:}$srcdir
      incr PPATH_cnt
    done &&
    stderr echo "Found ${PPATH_cnt} dirs for 'PPATH'" &&
    declare -x PPATH=$PPATH &&
    declare -p PPATH > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/SCRIPTPATH.lookup.sh" )
    redo-ifchange ".local/cache/SCRIPTPATH.var.sh" &&
    . ".local/cache/SCRIPTPATH.var.sh" &&
    os_path SCRIPTPATH &&
    declare -p SCRIPTPATH{,_arr} > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/SCRIPTPATH.var.sh" )
    SCRIPTPATH=
    SCRIPTPATH_cnt=0
    # Generate SCRIPTPATH by looking up 'tool/{build,redo}' dirs (on PPATH)
    redo-ifchange ".local/cache/PPATH.lookup.sh" &&
    . ".local/cache/PPATH.lookup.sh" &&
    for path in "${PPATH_arr[@]}"
    do
      # XXX: command should be deprecated, others would depend on context as
      # well. Ie. user may need access to more classes or personal types, etc.
      for pathbase in $path/{command{,s},script{,/{class,context{,s}}},src/{,ba}sh/lib,tool/{,ba}sh/{class,lib}}
      do
        [[ -d "$pathbase" ]] || continue
        SCRIPTPATH=${SCRIPTPATH:-}${SCRIPTPATH:+:}$pathbase
        incr SCRIPTPATH_cnt
      done
    done &&
    stderr echo "Found ${SCRIPTPATH_cnt} dirs for 'SCRIPTPATH'" &&
    declare -x SCRIPTPATH=$SCRIPTPATH &&
    declare -p SCRIPTPATH > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/USERDIRS.lookup.sh" )
    redo-ifchange ".local/cache/USERDIRS.var.sh" &&
    . ".local/cache/USERDIRS.var.sh" &&
    os_path USERDIRS &&
    stderr echo "Found ${#USERDIRS_arr[@]} dirs for USERDIRS" &&
    declare -p USERDIRS{,_arr} > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/USERDIRS.var.sh" )
    USERDIRS=
    : "${XDG_USER_DIRS-desktop,documents,dotfiles,download,music,pictures,publicshare,templates,videos}"
    for userdir in ${_//[,]/ }
    do
      dirpath=$(xdg-user-dir ${userdir^^})
      [[ -d "$dirpath" &&
        "$dirpath" != "${HOME:?}" &&
        "$dirpath" != "${HOME:?}/" ]] || continue
      USERDIRS=${USERDIRS:-}${USERDIRS:+:}$dirpath
    done &&
    declare -x USERDIRS=$USERDIRS &&
    declare -p USERDIRS > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/VOLUMEDIRS.lookup.sh" )
    redo-ifchange ".local/cache/VOLUMEDIRS.var.sh" &&
    . ".local/cache/VOLUMEDIRS.var.sh" &&
    os_path VOLUMEDIRS &&
    stderr echo "Found ${#VOLUMEDIRS_arr[@]} dirs for VOLUMEDIRS" &&
    declare -p VOLUMEDIRS{,_arr} > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( ".local/cache/VOLUMEDIRS.var.sh" )
    VOLUMEDIRS=
    shopt -s nullglob &&
    for voldir in /srv/volume-[0-9]*-[0-9]*
    do
      VOLUMEDIRS=${VOLUMEDIRS:-}${VOLUMEDIRS:+:}$voldir
    done &&
    declare -x VOLUMEDIRS=$VOLUMEDIRS &&
    declare -p VOLUMEDIRS > "${3:?}" &&
    < "${3:?}" redo-stamp
  ;;

( @hostpaths+dev )
    redo-ifchange @hostpaths+conf+dev
    # TODO: diagnose/check some user-conf is applied and still proper
    #redo-ifchange src/local srv @hostpaths+conf+dev
  ;;
( @hostpaths+conf+dev )
    redo-ifchange \
      "&"{{ANNEX,USER,VOLUME}DIRS,{,BUILD,P,SCRIPT}PATH}.lookup.sh
  ;;

( @recipes+dev )
    redo-ifchange @config:types
  ;;
( @config:types )
    redo-ifchange "&PATH-ucbuild-type-parts.sh"
    declare -gA ucbuild_types
  ;;

( "&ANNEXDIRS.lookup.sh" )
    redo-ifchange ".local/cache/ANNEXDIRS.lookup.sh"
  ;;
( "&BUILDPATH.lookup.sh" )
    redo-ifchange ".local/cache/BUILDPATH.lookup.sh"
  ;;
( "&PATH.lookup.sh" )
    redo-ifchange ".local/cache/PATH.lookup.sh"
  ;;
( "&PATH-ucbuild-type-parts.sh" )
    redo-ifchange ".local/cache/PATH-ucbuild-type-parts.sh"
  ;;
( "&PPATH.lookup.sh" )
    redo-ifchange ".local/cache/PPATH.lookup.sh"
  ;;
( "&SCRIPTPATH.lookup.sh" )
    redo-ifchange ".local/cache/SCRIPTPATH.lookup.sh"
  ;;
( "&USERDIRS.lookup.sh" )
    redo-ifchange ".local/cache/USERDIRS.lookup.sh"
  ;;
( "&VOLUMEDIRS.lookup.sh" )
    redo-ifchange ".local/cache/VOLUMEDIRS.lookup.sh"
  ;;

( src/local )
    ok=true
    for name in /src/local/*/
    do
      case "$name" in
        ( *"+"* ) continue ;;
        ( * ) stderr echo "$name"
            ok=false
          ;;
      esac
    done
    "${ok:?}"
  ;;

( srv )
  ;;

( * )
stderr echo ? $2
stderr echo do file $xredo_name
stderr echo 1=$1
stderr echo 2=$2
stderr echo 3=$3
stderr declare -p REDO_{BASE,PWD,STARTDIR}
false
  ;;
esac
#

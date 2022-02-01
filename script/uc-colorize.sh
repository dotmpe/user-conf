#!/bin/sh
uname=$(uname | tr 'A-Z' 'a-z')

case "$uname" in

  darwin ) # BSD echo
      esc=`echo -e '\033'`
    ;;

  linux | cygwin_nt-* )
      # For GNU echo/sed: \o033
      esc=`echo '\o33'`

      case "$(sed --version)" in *"This is not GNU sed"* )
              # For matchbox sed
              esc=`echo -e '\033'`
          ;;
      esac
    ;;

  * ) $LOG error "" "No ansi-escape -type for $uname" ; return 1 ;;
esac

normal=$esc'[0m'
boldblack=$esc'[1;30m'
green=$esc'[0;32m'
red=$esc'[0;31m'
yellow=$esc'[0;33m'
blue=$esc'[0;34m'

sed -E '
    s/^ok /'$green'OK: '$esc'[0m/g
    s/^fail:([0-9]+) /'$red'Failure(\1): '$esc'[0m/g

    s/Error:/'$red'Error:'$esc'[0m/g
    s/(Warning|Failed.*):/'$yellow'Warning:'$esc'[0m/g
    s/Notice:/'$blue'Notice:'$esc'[0m/g
    s/^\[(.*)\]/'$boldblack'\[\1\]'"$esc"'[0m/g

    s/^(.*)$/\1'$esc'[0;37m/g
  '

#    s/^\[(.*)\]\ Error:/\\033[1;30m\[\1\]\\033[0;31m\ Error:\\033[0m/g
#    s/^\[(.*)\]\ Warning:/\\033[1;30m\[\1\]\\033[0;33m\ Warning:\\033[0m/g
#    s/^\[(.*)\]\ Notice:/\\033[1;30m\[\1\]\\033[0;34m\ Notice:\\033[0m/g
#    s/\*/\\&/g

# Id: user-conf/0.2.0 script/uc-colorize.sh

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

  * ) echo "No stdio-type for $uname" 1>&2 ; exit 1 ;;
esac


sed -E '
    s/^ok /'"$esc"'[0;32mOK: '"$esc"'[0m/g
    s/^fail:([0-9]+) /'$esc'[0;31mFailure(\1): '$esc'[0m/g

    s/Error:/'$esc'[0;31mError:'$esc'[0m/g
    s/(Warning|Failed.*):/'$esc'[0;33mWarning:'$esc'[0m/g
    s/Notice:/'$esc'[0;34mNotice:'$esc'[0m/g
    s/^\[(.*)\]/'"$esc"'[1;30m\[\1\]'"$esc"'[0m/g

    s/^(.*)$/\1'"$esc"'[0;37m/g
  '

#    s/^\[(.*)\]\ Error:/\\033[1;30m\[\1\]\\033[0;31m\ Error:\\033[0m/g
#    s/^\[(.*)\]\ Warning:/\\033[1;30m\[\1\]\\033[0;33m\ Warning:\\033[0m/g
#    s/^\[(.*)\]\ Notice:/\\033[1;30m\[\1\]\\033[0;34m\ Notice:\\033[0m/g
#    s/\*/\\&/g
# Id: user-conf/0.2.0-dev script/uc-colorize.sh

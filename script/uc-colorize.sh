#!/bin/bash


uname=$(uname)

case "$uname" in
  Darwin )
      esc=`echo -e '\033'`
    ;;
  Linux )
      # For GNU sed: \o033
      esc=`echo -e '\o33'`

      case "$(sed --version)" in *"This is not GNU sed"* )
              # For matchbox sed
              esc=`echo -e '\033'`
          ;;
      esac
    ;;
esac


sed -E '
    s/Error:/'$esc'[0;31mError:'$esc'[0m/g

    s/Warning:/'$esc'[0;33mWarning:'$esc'[0m/g
    s/Notice:/'$esc'[0;34mNotice:'$esc'[0m/g
    s/^\[(.*)\]/'$esc'[1;30m\[\1\]'$esc'[0m/g
  '

#    s/^\[(.*)\]\ Error:/\\033[1;30m\[\1\]\\033[0;31m\ Error:\\033[0m/g
#    s/^\[(.*)\]\ Warning:/\\033[1;30m\[\1\]\\033[0;33m\ Warning:\\033[0m/g
#    s/^\[(.*)\]\ Notice:/\\033[1;30m\[\1\]\\033[0;34m\ Notice:\\033[0m/g
#    s/\*/\\&/g


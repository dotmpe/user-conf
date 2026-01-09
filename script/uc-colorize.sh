#!/bin/sh
: "${ansi_esc:?uc-colorize expects ANSI escape}"

#: "${TERM:=dumb}"
#[ -n "${esc-}" ] ||
#case "${OS_UNAME,,}" in
#
#  darwin ) # BSD echo
#      esc=$(echo -e '\033')
#    ;;
#
#  linux | cygwin_nt-* )
#      # For GNU echo/sed: \o033
#      esc=$(echo '\o33')
#
#      #case "$(sed --version)" in *"This is not GNU sed"* )
#      #        # For matchbox sed
#      #        esc=$(echo -e '\033')
#      #    ;;
#      #esac
#    ;;
#
#  * ) >&2 echo "Error: No ansi-escape for ${TERM@Q} at $OS_UNAME" ; return 1 ;;
#esac

# restore normal terminal style
#: "${ansi_normal:=$(tput sgr0)}"
: "${ansi_normal:="${ansi_esc}[0m"}"

#  TODO: switch based on CS to black or white
#  insert if colorscheme requires, however not all urxvt builds seem to support it
: "${ansi_bg:="${ansi_esc}[48;2;0;0;0m"}"
# inactive
: "${ansi_boldblack:="${ansi_esc}[1;30m"}"
# ok
: "${ansi_green:="${ansi_esc}[0;32m"}"
: "${ansi_red:="${ansi_esc}[0;31m"}"
: "${ansi_yellow:="${ansi_esc}[0;33m"}"
: "${ansi_blue:="${ansi_esc}[0;34m"}"

sed -E '
    s/^ok /'"${ansi_bg}${ansi_green}"'OK: '"${ansi_normal}"'/g
    s/^fail:([0-9]+) /'"${ansi_bg}${ansi_red}"'Failure(\1): '"${ansi_normal}"'/g
    s/Error:/'"${ansi_bg}${ansi_red}"'Error:'"${ansi_normal}"'/g
    s/(Warning:|Failed[^ :]*:)/'"${ansi_bg}${ansi_yellow}"'Warning:'"${ansi_normal}"'/g
    s/Notice:/'"${ansi_bg}${ansi_blue}"'Notice:'"${ansi_normal}"'/g
    s/^\[(.*)\]/'"${ansi_bg}${ansi_boldblack}"'\[\1\]'"${ansi_normal}"'/g
    s/^(.*)$/'"${ansi_bg}"'\1'"${ansi_normal}"'/g
  '

#    s/^\[(.*)\]\ Error:/\\033[1;30m\[\1\]\\033[0;31m\ Error:\\033[0m/g
#    s/^\[(.*)\]\ Warning:/\\033[1;30m\[\1\]\\033[0;33m\ Warning:\\033[0m/g
#    s/^\[(.*)\]\ Notice:/\\033[1;30m\[\1\]\\033[0;34m\ Notice:\\033[0m/g
#    s/\*/\\&/g

# Id: user-conf/0.2.0 script/uc-colorize.sh

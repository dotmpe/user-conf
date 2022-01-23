#!/bin/bash


getVersion_local()
{
  case "$1" in

    *.gitconfig )
        get_unix_comment_id "$1"
      ;;

    * )
        return 1
      ;;

  esac
}

applyVersion_local()
{
  case "$1" in

    *.gitconfig )
        apply_commonUnixComment "$1"
      ;;

    * )
        return 1
      ;;

  esac
}

# Id: user-conf/0.2.0 .versioning-local-formats.sh

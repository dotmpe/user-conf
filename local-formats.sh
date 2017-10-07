#!/bin/bash


getVersion_local()
{
  case "$1" in

    * )
        get_unix_comment_id $1
      ;;
  esac
}

applyVersion_local()
{
  case "$1" in

    * )
        apply_commonUnixComment $1
      ;;
  esac
}

# Id: user-conf/0.1.0 local-formats.sh

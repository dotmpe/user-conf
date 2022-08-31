#!/usr/bin/env bash

## Main lib for u-c CLI ('uc')


uc_lib_load ()
{
  true
}

uc_lib_init ()
{
  # Some more things hardcoded, ripe for clean-up
  uc_main_init || return

  # Prepare access to our specific UC configs table file
  uc_prefix_var_tag_ stattab_ STTTAB &&

  # Default still empty env
  uc_env_defaults &&

  # Get stattab instance
  create uctab StatTab $STTTAB_UC || return

  # Create table if not exists
  $uctab.tab-exists || $uctab.tab-init
}

uc_env_defaults ()
{
  test -n "${human_out:-}" || {
    # Output must be on terminal
    std_term 1 && human_out=1 || human_out=0
  }

  true "${uc_cache_ttl:="3600"}"

  true "${UC_NAMES_TPL:="\$username@\$hostname\\n\$username\\n\$hostname\\n\$domainname\\n\$hostname.\$domain\\n\$domain\\n\$hardware_name-\$hardware_processor\\n\$hardware_processor\\n\
  \$hardware_name\\n\$OS_KERNEL-\$os_release\\n\$os_release\\n\$OS_KERNEL\\n"}"

  true "${UC_LOCAL_TPL:="\$hostname.\$domainname"}"

  # FIXME:
  true "${UC_STAT_TPL:="\$(git_ref)"}"

  true "${UC_PATHS_TPL:="\$PWD\\n\${CONFDIR:-\$UCONF}\\n\${CONFDIR:-\$UCONF}/etc/profile.d\\n"}"

  true "${STTTAB_UC:="$HOME/.local/var/user-conf/configs.tab"}"
}

uc_main_init ()
{
  # XXX: force Git color output
  #git -c color.status=always status

  RT_HOME=${XDG_RUNTIME_HOME:=/run/user/$(id -u)}
  CACHE_HOME=${XDG_CACHE_HOME:=$HOME/.cache}
  #STATE_HOME=${XDG_STATE_HOME:=$HOME/.local/state}

  {
    mkdir -vp $RT_HOME/user-conf &&
    mkdir -vp $CACHE_HOME/user-conf
    #mkdir -vp $STATE_HOME/user-conf
  } || {
    $LOG crit "" "Unable to get required directories, check XDG_{RUNTIME,CACHE}_HOME settings"
    return 1
  }

  # FIXME: better tmp setup, see ram-tmpdir
  test -n "${TMP-}" -a -w "${TMP-}" || {
    test -w /tmp && TMP=/tmp || {
      TMP=$HOME/.local/tmp
      mkdir -p $TMP
    }
  }
}

# Use vc-gitdiff to check the file's checkout path and SHA1 object.
# Here, also allow file to exist in different repository.
diff_copy () # ~ SCM-File Other-File
{
  GITDIR="$UCONF" vc_gitdiff "$1" "$2"
}

uc_check_facts ()
{
  false # TODO: gather/verify-facts?
  #   What if static record has changed from previously build.
}

# get conf env: set matching u-c file for this host
# XXX: and all its includes...
uc_conf_get () # ~
{
  test -n "${conf-}" || {

    test -e Ucfile && conf=$PWD/Ucfile
    test -e "${conf-}" ||

      for UCONF in `uc___paths`
      do
        for tag in `uc___names`
        do
          conf=$UCONF/install/${tag}.u-c
          test -e $conf && break 2
          unset conf
        done
      done
  }

  test -e "${conf-}" && tag=$(basename "$conf" .u-c)
}

#
uc_conf_load () # ~ <Subcmd-Name>
{
  # Find table record using tags list. Abort if none found...
  for tag in `uc___names`
  do
    $uctab.exists $tag && break
  done
  $uctab.exists $tag || {
    case $1 in
      ( init ) return ;;
      ( help | list | names | -names | -path | -paths | list-records )
            error "No static config found. Did you run init?"
            return ;;
      ( * ) error "No static config found. Did you run init?" 1 ;;
    esac
  }

  std_info "Loading config for '$tag'..."
  $uctab.fetch ucstat $tag || {
    error "No entry" 1
  }

# FIXME: want to eval/source in sequence as defined in record

  test -z "$stttab_meta" || {
    eval "$(echo "$stttab_meta" | tr ':' '=')" || {
      error "Error getting uctab meta for record '$stttab_entry'" 1
    }
  }

  local ref ref_path
  for ref in $stttab_refs
  do
    ref_path=$(uc__path "$ref") || {
      error "Cannot find source file for '$ref'"
      continue
    }

    . $ref_path && std_info "Sourced <$ref_path>"
  done

  note "Loaded config $tag: '$stttab_short'"
}

uc_conf_req ()
{
  uc_conf_get
  test -e "${conf:-}" || error "no user-config ${conf-}" 1
  conf="$(echo $conf $(verbose=false uc_exec_dirs include $conf))"
  test -n "$conf" && note "Using U-c '$conf'" || {
      warn "No U-c found"
      return 1
    }
}

# Private helper for uc_exec_dirs
_prep_dir_func () # Action
{
  test -n "$directive" || error "empty directive" 1
  directive="$(echo "$directive"|tr '-' '_'|tr 'a-z' 'A-Z')"
  arguments="$arguments_raw"
  func_name=
  gen_eval=

  case $directive in

    # base and bin are global settings, not processed in sequence
    BIN | BASE )
      return 1
      ;;

    INSTALL )
      case $1 in stat|update) return 1 ;; esac
      packager=$(echo $arguments_raw | awk '{print $1}')
      arguments="$(eval echo "$arguments_raw")"
      arguments="$(echo "$arguments" | cut -c$(( 2 + ${#packager} ))-${#arguments} )"

      test "$packager" = "*" && {
        for packager in APT BREW PIP OPKG
        do
          func_name="d_INSTALL_$packager"
          d_INSTALL_list_$packager "$arguments"
        done
      } || {
        packager="$(echo $packager | tr 'a-z' 'A-Z')"
        func_name="d_INSTALL_$packager"
        arguments="$(d_INSTALL_list_$packager "$arguments")"
      }
      test -n "$arguments" && {
        note "#$diridx $packager missing packages: $arguments"
      } || {
        std_info "Nothing to install for #$diridx $packager"
        return 1
      }
      ;;

    # provision/config directives support stat or update
    COPY | SYMLINK | GIT | WEB | LINE | DIR | SH_UPDATE )
      case $1 in install) return 1 ;; esac
      func_name="d_${directive}_$1"
      arguments="$(eval echo "$arguments_raw")"
      ;;

    ENV | AGE | SH | BASH ) # Update env; always updates
      gen_eval="d_${directive}_exec"
      ;;

    INCLUDE )
      case $1 in include) ;; * ) return ;; esac
      arguments="$(eval echo "$arguments_raw")"
      echo "$arguments"
      ;;

    * ) error "Unknown directive $directive" 1 ;;

  esac
}

# Move last result to cache location and update table values
uc_commit_report ()
{
  test -n "${uc_cache-}" || uc_reset_report
  test -e "$uc_results" && {
    cat "$uc_results" >"$uc_cache"
    rm "$uc_results"
  }
  $uctab.fetch ucstat "$tag" || return

  uc_report || return
  local ctime utime
  utime="$(filemtime "$uc_cache")" || return

  $ucstat.update $status "" "" "$utime" "$directives" "$passed" "" "" "$failed" || return

  # Don't change file if entry is the same as fetched
  test "$(stattab_ UC entry)" = "$stttab_entry" && return

  ctime="$(date +'%s')" &&
  stattab_ UC update "" "" "$ctime" &&
  stattab_ UC commit
}

# Dynamic Eval of directives from u-c file, pref-dir-func maps each directive
# to a function with name ``d_<DIRECTIVE>_<function>()``.
# Use index argument to select single line to execute
uc_exec_dirs () # Action Directive-Index read-args..
{
  test $# -ge 3 || return 98
  local action=$1 func_name= arguments= diridx=0 idx=${2-} idxs
  test -z "$idx" || {
    note "Requested selective execution of directives '$idx'"
    idxs="$(uc_idx_spec "$idx")"
    debug "Resolved index-spec to '$idxs'"
  }

  uc_reset_report $2
  shift 2
  read_nix_style_files "$@" | while read directive arguments_raw
  #OLDIFS="$IFS"
  #IFS=$'\n'; for directive_line in $( read_nix_style_files $@ | lines )
  do
    #IFS="$OLDIFS"
    #directive="${directive_line/ *}"
    #arguments_raw="${directive_line:$(( ${#directive} + 1 ))}"
    diridx=$(( $diridx + 1 ))

    #printf -- "'$directive' '$arguments_raw'\n"
    # look for function or skip
    _prep_dir_func $action || {
      r=$?; test $r -gt 1 || continue
      echo "err:$r prepare:$diridx $directive $arguments_raw" >>"$uc_results"
      error "Error preparing directive $directive $arguments_raw" $r
    }

    test -z "$idx" || {
      # Skip if diridx requested does not match
      fnmatch "* $diridx *" " $idxs " || continue
      # XXX: cleanup
      #test $diridx -lt $idx \
      #  && continue || test $idx -eq $diridx || return
    }

    # Evaluate before function
    test -n "$gen_eval" && {
      gen=$($gen_eval "$arguments")
      echo "$gen" >&2
      local r
      eval $gen && {
        debug "evaluated $directive $arguments_raw"
        echo "ok eval:$diridx $directive $arguments_raw" >>"$uc_results"
        continue
      } || { r=$?
        error "Evaluation failure ($r): in $directive with '$arguments'"
        echo "fail:$r eval:$diridx $directive $arguments_raw" >>"$uc_results"
        continue
      }
    } || true

    # Execute directive
    local r
    $func_name $arguments && {
      debug "executed $directive $arguments_raw"
      echo "ok exec:$diridx $directive $arguments_raw" >>"$uc_results"
      continue
    } || { r=$?
      test "${RUN:-}" = "stat" &&
        std_info "Status warning ($r): $directive '$arguments'" ||
        debug "Failed ($r): $directive '$arguments'"
      echo "fail:$r exec:$diridx $directive $arguments_raw" >>"$uc_results"
    }

  done

  local ret=0

  uc_commit_report
}

# Get or set default GIT age
req_git_age ()
{
  # XXX AGE is eval'd in sequence, seems convenient for some meta dirs
  #grep -qi '^AGE\ GIT\ ' && {
  #  age_expr=$(echo $(grep -i '^AGE\ GIT\ ') | cut -d ' ' -f 3)
  #  # TODO: parse some expression for age: 1h 5min 5m etc.
  #  GIT_AGE="$age_expr"
  #} || true

  test -n "$GIT_AGE" || {
    GIT_AGE=$_5MIN
    debug "Max. GIT remote ref age set to $GIT_AGE seconds"
  }
}

req_git_remote ()
{
  test -n "$1" || error "expected url" 1
  test -d "$2" || error "expected checkout dir '$2'" 1
  test -n "$3" || set -- "$1" "$2" "origin"
  test $# -lt 4 || error "req-git-remote surplus arguments" 1

  GITDIR="$(vc_gitdir "$2")"
  url="$(cd "$2"; git config remote.${3}.url)"
  test -n "$url" && {
    test "$url" = "$1" -o "$url" = "$1/.git" || {
      error "Checkout exists at path $2 for $3 <$url> not <$1>"
      return 1
    }
  } || {
    case "$RUN" in
      update )
        ( cd $2; git remote add $3 $1 ; git fetch --all )
        note "New remote $3 for $2";;
      stat ) error "No remote $3 at $2"; return 1;;
    esac
  }
}

uc_idx_spec ()
{
  local start len
  set -- $(echo "$*" | tr ',' ' ')
  while test $# -gt 0
  do
    debug "spec '$1'"
    case "$1" in
      *"-"* ) seq ${1//-/ } ;;
      *"+"* ) start=${1//+*/}; len=${1//*+/};
        seq $start $(( $start + $len )) ;;
      * ) echo "$1" ;;
    esac
    shift
  done | tr '\n' ' '
}

# Generate new function to call function with local-env set based on 'tag'.
# Given env <Generic-Var>_<Tag>=<Global-Val> and function
# <Func-Prefix>_<Func-Suffix> that takes <Generic-Var>=<Val> env.
uc_prefix_func_lvar_tag_ () # ~ <Func-Prefix> <Generic-Var>
{
  eval "
$1 () # ~ <Tag> <Func-Suffix> <Args...>
{
  local fun=\"\$2\" lval gkey=${2}_\$1
  shift 2
  lval=\"\${!gkey}\" || return
  $2=\$lval $1\$fun \"\$@\"
}
"
}

# XXX: cleanup
#uc_prefix_gvar_tag_ ()
#{
#  eval "
#${1}_var_ () # ~ <Tag> <Var-Suffix> [<New-Value>]
#{
#  local var=\"\$2\" lval gkey=${2}_\$1
#  shift 2
#  test \$# -le 1 || return 177
#  test \$# -eq 1 && {
#    eval $gkey=\"\$1\"
#  } || {
#    lval=\"\${!gkey}\" || return
#    echo \"\$lval\"
#  }
#}
#"
#}

uc_prefix_var_tag_ ()
{
  uc_prefix_func_lvar_tag_ "$@"
  #uc_prefix_gvar_tag_ "$@" &&
}

# Load last results
uc_report ()
{
  test -n "${uc_cache-}" || uc_reset_report
  test -e "$uc_cache" || {
    error "No results"
    passed= failed= directives=
    return 1
  }

  passed="$(grep '^ok ' "$uc_cache" | count_lines )"
  failed="$(grep -v '^ok ' "$uc_cache" | count_lines )"
  directives="$(count_lines "$uc_cache")"

  # XXX: pass real status from scripts?
  test $passed -gt 0 -a $failed -eq 0 && {
    status=0
  }

  test $passed -gt 0 || {
    status=1
  }
# TODO: more complex report parsing, notice missing/errors as well...
#  test $erred -eq 0 || {
#    status=2
#  }
  test $failed -eq 0 || {
    status=3
  }

  return
# XXX: change status if results turn stale?
  { test -e "$uc_cache" && newer_than "$uc_cache" $uc_cache_ttl
  } || {
    status=4
  }
}

# Set cache and result files
uc_reset_report () # Index
{
  set -- $tag${1:+-}${1:-}.list
  uc_results=$RT_HOME/user-conf/uc:$$:$1
  uc_cache=$CACHE_HOME/user-conf/uc:$1
}

uc_sudo_path_target ()
{
  { test ! -r "$2" -o ! -r "$(dirname "$2")";} && {
    test ${warn_on_sudo:-1} -eq 0 || {
      warn "Setting sudo to read '$2' (for '$1')"
    }
    sudor="sudo -i "
  }

  test "$RUN" = "update" || return 0

  { test ! -w "$2" -o ! -w "$(dirname "$2")";} && {
    test ${warn_on_sudo:-1} -eq 0 || {
      warn "Setting sudo to write '$2' (for '$1')"
    }
    sudow="sudo -i "
  }
}

reverse ()
{
  for (( i=$#;i>0;i-- ))
  do echo "${!i}"
  done
}

uc_req_network_facts ()
{
  uc_req_domain "${host_fqdn:=$(hostname -f)}"
}

uc_req_uname_facts ()
{
  #true "${os_name:="$(uname -o)"}"            # Eg. 'GNU/Linux'
  true "${OS_KERNEL:="$(uname -s)"}"           # Eg. 'Linux', also 'OS name'
  true "${os_release:="$(uname -r)"}"          # Version nr
  true "${hardware_name:="$(uname -m)"}"       # Eg. x86_64
  #true "${hardware_platform:="$(uname -i)"}"  # Eg. x86_64
  true "${hardware_processor:="$(uname -p)"}"  # Idem. to machine-type on x86

  if test -e /etc/os-release
  then
    _os_dist () { sed 's/^/DIST_/g' /etc/os-release | tr 'A-Z' 'a-z'; }
    eval $(_os_dist)                           # Eg. DIST_ID=debian or ubuntu
                                               # And DIST_NAME='Debian GNU/Linux'
                                               #  or DIST_NAME=Ubuntu
  else
    dist_id=
    dist_name=
    dist_version=
    dist_version_id=
  fi

  if test "$OS_KERNEL" = "Darwin" # BSD/Darwin
  then
    os_name=
    hardware_platform=
  else
    true "${os_name:="$(uname -o)"}"
    true "${hardware_platform:="$(uname -i)"}"
  fi
}

# Parse FQDN and compare with hostname. Set other vars based on that.
uc_req_domain () # ~ [FQDN]
{
  local nameraw=${1:-$host_fqdn}

  # Auto extract domain if attached to 'fqdn'
  # If TLD has periods set Uc-Domain-Tld-D >1

  domainname=
  domain_tld=
  domain=

  # TOTEST: Set = 0 to force empty and no match on domain
  test ${UC_DOMAIN_TLD_D:-1} -eq 0 && {
    host_domain=$nameraw
  } || {
    lvls=$(echo $nameraw | tr -dc .)

    test ${#lvls} -eq 0 && {
      # No domain info in host fqdn whatsoever...
      host_domain=$nameraw
    } || {
      test ${#lvls} -eq 1 && {
        # Only one '.': a TLD, or local lan name perhaps or a bare domain?
        # Use last '.' delimited part as domain, but no name, TLr
        host_domain=$nameraw
        # XXX: accept hostname -s or cut from FQDN.
        #hostname=$(echo $nameraw | cut -d. --output-delimiter . -f1)
        domain=$(echo $nameraw | cut -d. --output-delimiter . -f2)
      } || {
        # Remove last or UC_DOMAIN_TLD_D '.' delimited part and use as TLD
        dlvls=$(( 1 + ${#lvls} - ${UC_DOMAIN_TLD_D:-1} ))
        host_domain=$(echo $nameraw | cut -d. --output-delimiter . -f-$dlvls)
        # XXX: accept hostname -s or cut from FQDN.
        #hostname=$(echo $nameraw | cut -d. --output-delimiter . -f1)
        domainname=${host_domain:$(( 1 + ${#hostname} ))}
        domain_tld=${nameraw:$(( 1 + ${#host_domain} ))}
        domain=$domainname.$domain_tld
        unset dlvls
      }
    }
    unset lvls
  }
}

os_readable ()
{
  local stat
  stat=$(stat -c '%a' "$2")
  stat=$( case "$1" in
      u ) echo "${stat:0:1}" ;;
      g ) echo "${stat:1:2}" ;;
      o ) echo "${stat:2}" ;;
    esac )
  test $stat -ge 4
}

#

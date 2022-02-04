#!/usr/bin/env bash
# Created: 2015-09-21

test -n "${sh_lib:-}" || sh_lib="$(dirname $uc_lib)"

true "${LOG:?Require log handler}"

. ${sh_lib}/../tools/u-c/env.sh
INIT_LOG=$LOG

. "$sh_lib"/shell-uc.lib.sh
shell_uc_lib_load

test $IS_BASH_SH -eq 1 && {
  # This triggers
  #/etc/profile.d/uc-profile.sh: /usr/share/bashdb/bashdb-main.inc: No such file or directory
  #/etc/profile.d/uc-profile.sh: warning: cannot start debugger; debugging mode disabled
  # at t460s but only sometimes.
  set -o errexit  # set -e
  set -o nounset  # set -u
  set -o pipefail #

  shopt -q extdebug || shopt -s extdebug >&2

  # setting errtrace allows our ERR trap handler to be propagated to functions,
  #  expansions and subshells
  set -o errtrace # same as -E

  # Leave a path of line-numbers in array BASH_LINENO
  # thate tells where functions where called
  set -o functrace # same as -T

  # trap ERR to provide an error handler whenever a command exits nonzero
  #  this is a more verbose version of set -o errexit
  . "$sh_lib"/bash-uc.lib.sh
  trap 'bash_uc_errexit' ERR

} || {

  $LOG warn "" "Non-Bash TO-TEST"
}

test $IS_DASH_SH -eq 1 && {
  set -o nounset
}

true "${USER:=$(whoami)}"
true "${username:=$USER}"
true "${hostname:=$(hostname -s)}"

log_key=$username@$hostname:$scriptname[$$]:${1-}
UC_LOG_LEVEL=${verbosity:=${v:-4}}
export log_key UC_LOG_LEVEL

# load and init lib parts
. "$sh_lib"/argv-uc.lib.sh
. "$sh_lib"/std-uc.lib.sh
. "$sh_lib"/str-uc.lib.sh
. "$sh_lib"/src-uc.lib.sh
. "$sh_lib"/ansi-uc.lib.sh
. "$sh_lib"/match-uc.lib.sh
. "$sh_lib"/os-uc.lib.sh
. "$sh_lib"/date-uc.lib.sh
. "$sh_lib"/vc-uc.lib.sh
. "$sh_lib"/sys-uc.lib.sh
. "$sh_lib"/stdlog-uc.lib.sh
#. "$sh_lib"/syslog-uc.lib.sh
. "$sh_lib"/conf-uc.lib.sh
. "$sh_lib"/uc.lib.sh
for d in copy symlink web line git
do
  . "$sh_lib"/uc-d-$d.lib.sh
done
. "$sh_lib"/stattab.lib.sh

sys_uc_lib_load
std_uc_lib_load
os_uc_lib_load
ansi_uc_lib_load
stdlog_uc_lib_load
#syslog_uc_lib_load
stattab_lib_load

case "${TERM-}" in
  "" ) ;;
  dumb ) ;;
  * ) true "${COLORIZE:=1}" ;;
esac

std_uc_lib_init
ansi_uc_lib_init

test -s "$STTTAB" || stattab_init
stattab_lib_init


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


# Gather some facts to use in the installation profile
test -n "${HOME-}" || {
  test -n "${username:-}" && HOME=/home/$username || error "no user dir set" 100
}
test -e "$HOME" || error "no user dir" 100

true "${UC_NAMES_TPL:="\$hostname\\n\$domainname\\n\$hostname.\$domain\\n\$hardware_name-\$hardware_processor\\n\$hardware_processor\\n\
\$hardware_name\\n\$OS_KERNEL-\$os_release\\n\$OS_KERNEL\\n\$os_release\\n"}"

true "${UC_LOCAL_TPL:="\$hostname.\$domainname"}"

true "${UC_STAT_TPL:="\$(git_ref)"}"

# All boxes
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

true "${host_fqdn:=$(hostname -f)}"

req_domain

test -n "${human_out:-}" || { test -t 1 && human_out=1 || human_out=0; }

test -n "${TMP-}" -a -w "${TMP-}" || {
	test -w /tmp && TMP=/tmp || {
		TMP=$HOME/.local/tmp
		mkdir -p $TMP
	}
}

true "${uc_cache_ttl:="3600"}"

# XXX:
#git -c color.status=always status


## Command handler functions

# Add a new path to config (COPY directive only)
uc__add () # ~ <Directive> <Args...>
{
  case "$1" in
    SYMLINK|COPY ) ;;
    * ) echo "? expected valid directive, not '$1'"; exit 1 ;; esac
  test -f "$2" || error "? expected file argument '$2'" 1

  # Best effort to get canonical path
  local basename="$(basename "$2")" \
    basedir="$(cd $(dirname "$2"); pwd -P)"
  # Start off u-c env
  local pwd=$(pwd) conf=
  uc_conf_req || return

  local toadd=$basedir/$basename

  # Look if any BASE direct matches source path, use that
  # mapping for the target path inside the repository
  #exec_dirs base
  match_grep_pattern_test "$basedir"
  grep -iq "^BASE\ $p_\ " "$conf" && {
    ucbasedir_raw="$(grep "^\s*BASE\ $p_\ " "$conf" | cut -d ' ' -f 3 )"
    test -n "$ucbasedir_raw" || error "error parsing BASE directive for $basedir" 1
    note "Found customized rcbase $ucbasedir_raw"
    ucbasedir=$(eval echo "$ucbasedir_raw")
  } || {
    ucbasedir="$UCONF/$(basename "$basedir")"
    ucbasedir_raw="\$UCONF/$(basename "$basedir")"
  }

  log "Adding $toadd to $ucbasedir_raw"
  test -d "$ucbasedir" || mkdir -vp "$ucbasedir"
  cp "$toadd" "$ucbasedir"
  git add "$ucbasedir/$basename"

  test "${2:0:${#HOME}}" = "$HOME" && {
    echo "$1 $ucbasedir_raw/$basename \$HOME/${2:$(( ${#HOME} + 1))}" >> "$conf"
  } || {
    echo "$1 $ucbasedir_raw/$basename $toadd" >> "$conf"
  }
  # Add file to index and show state
  git add "$conf"
}

uc__commit ()
{
  local conf
  uc_conf_req || return
  # re-commit report values to Stat-Tab XXX: should o this once after exec-dirs?
  uc_commit_report

  return
# XXX:
  test "$(pwd)" = "$UCONF" || cd $UCONF
  git diff --quiet && {
    git commit -m "At $hostname" || return
    git pull || return
    git push || return
  } || {
    error "dir looks dirty"
  }
}

# Report on config and location
uc__env ()
{
  local conf=
  test $human_out -eq 1 && {
    local verbosity=6
      std_info "U-c scripts: $uc_lib"
      std_info "Sh script libs: $sh_lib"
  } || {
      echo "uc_lib=$uc_lib"
      echo "sh_lib=$sh_lib"
  }

  uc_conf_get || return 0

  config_name="$(test "$( basename $conf .u-c )" = "local" &&
                    basename $conf .u-c || basename $(realpath $conf) .u-c )"

  test $human_out -eq 1 && {
    local verbosity=6
    std_info "UConf: $UCONF"
    std_info "Config: $conf"
    std_info "Config-Name: $config_name"
  } || {
    echo "UCONF=$UCONF"
    echo "conf=$conf"
    echo "config_name=$config_name"
  }
}

uc__copy ()
{
  uc__add COPY "$1"
}

# Report on config and state
uc__info ()
{
  uc__env &&
  uc__report
}

uc__init ()
{
  uc__initialize "$@"
}

# Look for config, add
uc__initialize ()
{
  uc_conf_get || true
  test -d "${UCONF-}" || error "No UCONF found" 1

  test -e "${conf-}" && {

    stattab_exists $tag && {
      note "Already initialized: $tag"
      return
    }
  }

  # Create local link for ease of access
  local local_conf=local.u-c
  test -e "${conf-}" || {

    # Default name for new config file
    tag=$(eval echo \"$UC_LOCAL_TPL\")
    conf=$UCONF/install/$tag.u-c
    note "Set new configuration $tag"
  }
  test -e "$UCONF/install/$local_conf" ||
    ln -vs $(basename $conf) $UCONF/install/$local_conf

  test -e "${conf-}" && {
    note "Using existing $tag configuration"

    stattab_record $tag: $UC_STAT_TPL @Local
    return
  } ||
    local UCONF_
    for UCONF_ in $PWD ${UCONFDIR:-$HOME/.conf}
    do
      local tpl= bp_tag
      for bp_tag in `uc___names`
      do
        tpl=$UCONF_/install/boilerplate${bp_tag:+-}${bp_tag}.u-c
        test -e "$tpl" || continue

        cp -v $tpl $conf
        stattab_record $tag: $UC_STAT_TPL @$bp_tag

        note "Initialized config $tag from $bp_tag boilerplate"
        break 2
      done
    done
}

uc__install ()
{
  local conf=
  uc_conf_req || return
  exec_dirs install "$1" $conf || return $?
}

# XXX: just copied from of uc_conf_get, want to write loop over row-cols w/o subshell
# and then introduce some more list functions at conf_list*
# But why. Still need/have remove_dupes on output for convenience?
# Ie. all, config, user, local, repo, boilerplate
uc__list ()
{
  echo "# Listing config paths. First would be selected as config." >&2
  test -e Ucfile && echo $PWD/Ucfile

  local conf UCONF_
  for UCONF_ in $PWD ${UCONFDIR:-$HOME/.conf}
  do
    for tag in `uc___names`
    do
      conf=$UCONF_/install/boilerplate-${tag}.u-c
      test -e $conf && echo $conf
      conf=$UCONF_/install/${tag}.u-c
      test -e $conf && echo $conf
    done
  done | remove_dupes
}

uc__list_records ()
{
  test -n "${2-}" || set -- "${1-}" "$STTTAB"
  stattab_tab "$@"
}

uc__names ()
{
  stattab_list
}

uc___names ()
{
  eval "echo -e \"$UC_NAMES_TPL\""
}

# Report on last result
uc__report ()
{
  uc_conf_req && uc_report || return

  test $human_out -eq 1 && {
    local verbosity=6
    note "Results are $(fmtdate_relative "$(filemtime $uc_cache)" "" " old")"
    std_info "Conf: $conf"
    std_info "Tag: $tag"
    std_info "Passed: $passed"
    std_info "Failed: $failed"
    std_info "Total: $directives"
  } || {
    echo "Conf=$conf"
    echo "Tag=$tag"
    echo "passed=$passed"
    echo "failed=$failed"
    echo "total=$directives"
  }
}

# Compare host with provision and config directives
# 1:diridx
uc__stat ()
{
  local conf=
  uc_conf_req || return
  exec_dirs stat "${1-}" $conf || return $?
}

uc__status ()
{
  local conf ret=0
  uc_conf_req && uc_report || return

  test $verbosity -ge 5 && {
    cat "$uc_cache"
  } || {
    test $verbosity -ge 4 && {
      grep -v '^ok ' "$uc_cache"
    }
  }

  std_info "Passed: $passed, Failed: $failed"
  test $passed -gt 0 -a $failed -eq 0 && {
    note "All $passed directives passed"
  }

  test $passed -gt 0 || {
    error "No directive ran successfully"
    ret=1
  }
  test $failed -eq 0 || {
    warn "Failed $failed directives"
    ret=3
  }

  { test -e "$uc_cache" && newer_than "$uc_cache" $uc_cache_ttl
  } || {
    warn "Results are stale (>${uc_cache_ttl}s)"
    ret=4
  }

  return $ret
}

uc__symlink ()
{
  uc__add SYMLINK "$1"
}

# Quietly test for valid result
uc__test ()
{
  test -n "${uc_cache-}" || uc_reset_report
  test -e "$uc_cache" && newer_than "$uc_cache" $uc_cache_ttl || return
  uc_report
  test $failed -eq 0 -a $passed -gt 0
}

# Update host from provision- and config-directives
uc__update ()
{
  local conf=
  uc_conf_req || return
  exec_dirs update "${1-}" $conf || return $?
}


### XXX: organize directives elsewhere

# TODO: add sudo for both FILE and DIR directives
d_DIR_stat ()
{
  local dir
  for dir in $@
  do test -d "$dir" || return
  done
}

d_DIR_update ()
{
  local dir
  for dir in $@
  do test -d "$dir" || mkdir -p "$dir"
  done
}

d_FILE_stat ()
{
  local file
  for file in $@
  do test -f "$file" || return
  done
}

d_FILE_update ()
{
  local file
  for file in $@
  do test -f "$file" || touch "$file"
  done
}


## Meta

d_ENV_exec ()
{
  set -- $@
  printf -- "export $@\n"
}

d_SH_exec ()
{
  printf -- "$@\n"
}

d_BASH_exec ()
{
  echo bash -c "'$@'"
}

d_AGE_exec ()
{
  set -- $@
  test $# -lt 3 || error "AGE surplus params: '$3'" 1
  test $# -eq 1 && set -- "CACHE" "$1"
  set -- "$(echo $1 | tr 'a-z' 'A-Z')" "$2"
  case "$1" in
    GIT )
      printf "export GIT_AGE=$2"
      std_info "Max. GIT remote ref age to $2 seconds"
    ;;
    * )
      printf "export %s_AGE=%s" "$@"
    ;;
  esac
}


## Installers

# print missing/mismatching packages
d_INSTALL_list_APT()
{
  out=$TMP/bin-apt-installed.list
  dpkg-query -l >$out
  for pack in $@
  do
    grep -q '^ii\s*'$pack'\>' $out || echo $pack
  done
}

d_INSTALL_list_BREW()
{
  echo $@
}

d_INSTALL_list_PIP()
{
  out=$TMP/bin-pip-installed.list
  pip list >$out
  for pack in $@
  do
    grep -qi '^'$pack'\>\ ' $out || echo $pack
  done
}

d_INSTALL_list_OPKG()
{
  echo $@
}

d_INSTALL_list_BIN()
{
  echo $@
}

# install using package manager
d_INSTALL_APT()
{
  sudo apt-get install -qq -y "$@"
}

d_INSTALL_BREW()
{
  brew install "$@"
}

d_INSTALL_PIP()
{
  pip install $@
}

d_INSTALL_OPKG()
{
  opkg update >/dev/null
  opkg install "$@"
}

d_INSTALL_BIN()
{
  echo $@
}



# XXX: consolidate, integrate

: "${DOMAIN:=}"
: "${HOST:="$(hostname --long)"}"

: "${UC_CONFIG_NAME:="local $DOMAIN $HOST-$USER $hostname-$USER host $HOST $hostname user $USER generic default"}"

: "${UC_CONFIG_INSTALL_EXT:="u-c"}"
: "${UC_DEFAULT_GROUPS:="etc"}"

# Lookup file anywhere in UCONF repo, based on its filename and location.
uc__config () # ~ [NAME][.EXT] [--] [GROUP [GROUP...]]
{
  argv_uc__argc :uc:config $# ge 1 || return
  local name ext groups
  fnmatch "*.*" "$1" && {
    # EXT is the last '.'-separated part of the name
    ext="${1##*.}"
    # NAME is minus last EXT
    name="${1%.*}"
  } || name="$1"
  shift

  test "${1-}" = '--' || set -- "$@" ${UC_DEFAULT_GROUPS}
  test "${1-}" = "--" && shift
  set -- $name "$@"
  $LOG debug :uc:config "Looking for config at" "$*"

  test -n "${ext-}" || {

    # Look-up exts for most specific NAME with exts
    ext=`uc__resolve_env EXT $(reverse "$@")` || {
      $LOG error :uc:config "Cannot find EXT" "" 1
    }
  }

  $LOG note :uc:config "Looking for config file" "$name.$ext"

  while test $# -gt 0
  do
    local path lname

    for path in `uc__resolve_path $(reverse "$@") | while IFS= read -r path; \
      do \
        first=true; \
        while $first || test "$path" != "./" -a "$path" != "//"; \
        do \
          first=false; \
          echo "$path"; \
          path=$(dirname "$path")/; \
        done; \
      done || true`
    do
      for lname in `uc__resolve_env "$@" || echo "$1"`
      do
        test -e "$UCONF/$path/$lname.$ext" || continue
        break 2
      done
    done
    shift

    test -n "${lname-}" -a -n "${path-}" -a -e "$UCONF/${path-}/${lname-}.$ext" && {
      echo "$UCONF/$path$lname.$ext"
      break
    } || {
      test $# -gt 0 || return
    }
  done
}

## Lookup actual file(s) named 'FILE' in a location specified by GROUP's.
uc__resolve () # ~ [[...GROUP] GROUP] FILE[.EXT]
{
  true
}

## Lookup actual directory named by GROUP's.
uc__resolve_path () # ~ GROUP [GROUP...]
{
  test $# -gt 0 || return 64

  $LOG note :resolve-path "Lookup existing path for groups" "$*"
  {
    local last=false
    while test $# -gt 0
    do
      local name=
      for name in $(uc__resolve_env $(reverse "$@") || true)
      do
        test -d "$name" || continue
        break
      done
      test -n "$name" || name="$1"
      shift
      test -d "$name" || return
      cd "$name"
      echo "$name"
    done
  } | {
    tr -s "$IFS" '/'; echo;
  }
}

## Lookup ``UC_{<GROUP>_,}<VAR>``-keyed value in shell env.
uc__resolve_env () # ~ VAR [GROUP [GROUP...]]
{
  test $# -gt 0 || return 64

  local v var="$1" uc_resolve_prefix
  uc_resolve_prefix="${UC_RESOLVE_PREFIX:-"Uc Config "}"
  shift
  # Reverse arguments Bash-style
  set -- $(for (( i=$#;i>0;i-- ));do echo "${!i}"; done)
  $LOG note :resolve-env "Lookup env var" "NAME=$var GROUPS=$*"

  # Loop until either varref exists or no args left
  while true
  do
    varref="$uc_resolve_prefix$(test $# -eq 0 || printf '%s ' "$@")$var"
    v="$(printf '%s' "$varref" | tr -c 'A-Za-z0-9_' '_')"
    v="${v^^}"
    #echo varref=$varref varname=$v >&2
    v="${!v-}"
    test -n "$v" -o $# -eq 0 && break
    shift
  done
  # Abort or print
  test -n "${v-}" || return
  printf -- '%s' "$v"
}

uc__has_config ()
{
  uc__config >&2
}

uc__user_has_config ()
{
  true
}

#

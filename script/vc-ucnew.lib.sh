#!/usr/bin/env bash

# Fields
#   b:branch - set to name if checkout corresponds to tip of revision history
#   :revision - set to unique Id for current revision
#   r:state
#   s:stash

vc_ucnew_lib__load ()
{
  lib_require uc-cmdcache || return
}

vc_ucnew_lib__init ()
{
  test "${vc_ucnew_lib_init-}" = "0" && return
  : "${vc_fields:=branch revision type status index stash branches remotes}"
  : "${vc_keys:=scmsys dir}"
  test -n "${vc_ucnew_lib_init-}" || {
    vc_fields_define || return
    vc_commands_declare || return
  }
  #lib_groups \
  #  git: \
  #  hg: \
  #  bzr: \
  #  svn: \
  #  fields:vc-fields-{}
  #! sys_debug -debug -dev -init ||
  ! { "${DEBUG:-false}" || "${DEV:-false}" || "${INIT:-false}"; } ||
  ${LOG:?} notice ":vc-ucnew:lib-init" "Initialized vc-ucnew.lib"
}


vc__gitdir ()
{
  false
}

vc_commands_declare ()
{
  uc_command git-untracked git ls-files --others --exclude-standard
  uc_command git-stashed   git rev-parse --verify refs/stash

  uc_command git-modified \
      git diff --no-ext-diff --ignore-submodules --name-only
  uc_command git-modified-q \
      git diff --no-ext-diff --ignore-submodules --quiet --exit-code

  uc_command git-added \
      git diff-index --cached --ignore-submodules HEAD --name-only --
  uc_command git-added-q \
      git diff-index --cached --ignore-submodules HEAD --quiet --
}

vc_field ()
{
  false
}

vc_fields_key ()
{
  vc__${vc_scmsys}dir
}

vc_field_branch ()
{
  vc_fields_branches[$id]=
}

vc_fields_define ()
{
  uc_fields_define vc {type,ctime,mtime} \
    gitdir,
    git-{branch,remote,index,stash,status,revision,branches,remotes}
}

# Update all fields for SCM system
vc_status () # ~ [<Dir>]
{
  local scmsys varn

  varn=${scmsys}dir
  vc_$varn || return
}

vc_status_format () # ~ [<Dir>] [<Fmt>]
{
  vc_status
}

#

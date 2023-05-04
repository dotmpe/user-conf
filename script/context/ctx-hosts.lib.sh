#!/usr/bin/env bash

ctx_hosts_lib__load () { :;}
ctx_hosts_lib__init () { :;}

@Hosts.init ()
{
  echo @Hosts.init $*
}

@Hosts.exist ()
{
  false
}

@Hosts.load ()
{
  false
}

#

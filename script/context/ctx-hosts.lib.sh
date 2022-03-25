#!/bin/sh

ctx_hosts_lib_load () { :;}
ctx_hosts_lib_init () { :;}

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

User-Config
===========
:Created: 2015-10-03
:Version: 0.1.1-dev
:Project:

  .. image:: https://secure.travis-ci.org/bvberkum/user-conf.png
    :target: https://travis-ci.org/bvberkum/user-conf
    :alt: Build

  .. image:: https://badge.fury.io/gh/bvberkum%2Fuser-conf.png
    :target: http://badge.fury.io/gh/bvberkum%2Fuser-conf
    :alt: GIT

A dotfile repository, with shell scripts for misc. provisioning and
configuration tasks.


.. figure:: doc/screen-shot.png


Intro
-----
It was time to expand a little on my existing dotfile repo setup.
There's probably many out there. But this was not about example dotfiles,
but a way to deal with copies and checkouts spread over different hosts.

Simplicity meant using GIT, and a Bourne shell as the only requirements.
BATS is optional for testing the core libraries.

To provision or configure a host there is one config file per host.
There is no real frontend (yet), but the commands are in scripts/user-conf/<cmd>.sh
and there is a little guide and some other docs.


Install
-------
::

  # something to put in your shell profile script
  export UCONF=$HOME/.conf

  git clone --origin tpl git@github.com:bvberkum/user-conf.git $UCONF


Guide
------
Each host::

  cd $UCONF; ./script/user-conf/init.sh

Add file copies using script::

  cd /etc/acme
  $UCONF/script/user-conf/add.sh gizmo.conf

Or edit ``$UCONF/install/$hostname.conf`` by hand to create symlinks,
and to supply other directives.

To run the directives::

  $UCONF/script/user-conf/update.sh

Or to dry-run::

  $UCONF/script/user-conf/stat.sh

See Manual_ and Specification_ for user documentation.


Dev
----
- Think about domain and some kind of preferential wildcard
  matching based on that.

  Still using one file per host.
  But want a bit more flexible variable expansion to improve reuse.

  replace $domain in COPY/SYMLINK src argument with first match
  starting with full hostname.

  E.g. with box.example.net, vim/rc.$domain expands to first existing path from::

   rc.box.example.net
   rc.example.net
   rc.net
   rc(.default)


- TODO: git directive submodule mode

- XXX: maybe new type of directives for configuration: cron, munin-node,
  hostname, hosts and fstab maybe. XXX: first try to use LINE for this?

- TODO: config may need interactive init. But can be avoided for now.

- TODO: add a simple frontend script to put in $PATH.

- TODO: handling of sudo. Can determine wether paths are writable, and do auto
  root. Maybe stick a decorator to directive to always run with sudo.

- TODO: a source directive. As new directives are added it should be useful
  create generic bits of ufile with var. directives and distribute ucfiles in bits.

- XXX: maybe use installer glob for INSTALL. But would need to map package names
  then too.

- XXX: make directives optional. Maybe stick an asterix or q-mark to the keyword. Then
  expand init to initialize paths, and let stat and update only deal with
  existing paths and leave new-paths if the directive is optional?

- XXX: at some point, replace cat $conf with something that handles SOURCE
  directives. Current set up does seem to handle multilines using '\' trailer.

- XXX: DIR directive, and consolidation asks for kind of interaction
  that makes scripts complex. Not sure wether to include that here.

  Also GIT does not take note of cruft (yet). If that is made an option,
  then maybe other tooling would be obsolete. Until then, ~/bin is to support.


.. _Specification: Specification.rst
.. _Manual: Manual.rst

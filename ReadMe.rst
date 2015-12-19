User-Config
===========
:Created: 2015-10-03
:Project:

  .. image:: https://secure.travis-ci.org/dotmpe/user-config.png
    :target: https://travis-ci.org/dotmpe/user-config
    :alt: Build

  .. image:: https://badge.fury.io/gh/dotmpe%2Fuser-config.png
    :target: http://badge.fury.io/gh/dotmpe%2Fuser-config
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
There is no real frontend (yet), but the commands are in scripts/<cmd>.sh


Install
-------
::

  # something to put in your shell profile script
  export UCONF=$HOME/.conf

  git clone --origin tpl git@github.com:dotmpe/user-config.git $UCONF


Guide
------
Each host::

  cd $UCONF; ./script/init.sh

Add file copies using script::

  cd /etc/acme
  $UCONF/script/add.sh gizmo.conf

Or edit ``$UCONF/install/$hostname.conf`` by hand to create symlinks,
and to supply other directives.

To run the directives::

  $UCONF/script/update.sh

Or to dry-run::

  $UCONF/script/stat.sh

See Manual_ and Specification_ for user documentation.


Dev
----
- One file per host seems OK. Keeps args/variables in ucfile down.

  My initial dotfile repo symlinks.tab used hostnames as tags, to filter out
  rules per host. Still an interesting concept. Compare with optional directives.

- Want a directive to specify which command to use to test for installed
  programs, so that INSTALL can be a regular stat/update directive. \
  XXX: BIN directive.

- TODO: more provision directives: web (curl).

- TODO: git directive submodule mode

- TODO: new type of directives for configuration: cron, munin-node,
  hostname, hosts and fstab maybe. XXX: first try to use LINE for this.

- TODO: add some interactive resolving off differences.
- TODO: add a simple frontend script to put in $PATH

- TODO: handling of sudo. Can determine wether paths are writable, and do auto
  root. Maybe stick a decorator to directive to always run with sudo.

- TODO: a source directive. As new directives are added it should be useful
  create generic bits of ufile with var. directives and distribute ucfiles in bits.

- XXX: an INIT directive, create customized per-host file from boilerplate
- XXX: maybe use installer glob for INSTALL. But would need to map package names
  then too. Should also be useful with SOURCE directive iot generalize.
- XXX: make directives optional. Maybe stick an asterix or q-mark to the keyword. Then
  expand init to initialize paths, and let stat and update only deal with
  existing paths and leave new-paths if the directive is optional?

- XXX: at some point, replace cat $conf with something that handles SOURCE
  directives. Current set up does seem to handle multilines using '\' trailer.


.. _Specification: Specification.rst
.. _Manual: Manual.rst


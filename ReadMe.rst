.. include:: .default.rst

User-Config
===========
:Created: 2015-10-03
:Updated: 2021-01-23
:Version: 0.2.0
:Project:

  .. image:: https://secure.travis-ci.org/dotmpe/user-conf.png
    :target: https://travis-ci.org/dotmpe/user-conf
    :alt: Build

  .. image:: https://badge.fury.io/gh/dotmpe%2Fuser-conf.png
    :target: http://badge.fury.io/gh/dotmpe%2Fuser-conf
    :alt: GIT

Scripts and config directives for a dotfile repository.

.. figure:: doc/screen-shot.png


Intro
-----
It was time to expand a little on my existing dotfile repo setup.
There's probably many out there. But this was not about example dotfiles,
but a way to deal with copies and checkouts spread over different hosts.

Simplicity meant using GIT, and a Bourne shell as the only requirements.
BATS is optional for testing the core libraries.

To provision or configure a host the script takes one config file as input.


Install
-------
::

  # something to put in your shell profile script
  export UCONF=$HOME/.conf
  git clone --origin tpl git@github.com:dotmpe/user-conf.git $UCONF


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


- 2015-12-19 TODO: git directive submodule mode

- 2015-12-20 XXX: maybe new type of directives for configuration: cron, munin-node,
  hostname, hosts and fstab maybe. XXX: first try to use LINE for this?

- 2016-06-13 TODO: config may need interactive init. But can be avoided for now.

- 2015-12-20 TODO: add a simple frontend script to put in $PATH.

- 2015-10-03 TODO: handling of sudo. Can determine wether paths are writable, and do auto
  root. Maybe stick a decorator to directive to always run with sudo.

- 2015-10-03 TODO: a source directive. As new directives are added it should be useful
  create generic bits of ufile with var. directives and distribute ucfiles in bits.

- 2015-10-03 XXX: maybe use installer glob for INSTALL. But would need to map package names
  then too.

- 2015-10-03 XXX: make directives optional. Maybe stick an asterix or q-mark to the keyword. Then
  expand init to initialize paths, and let stat and update only deal with
  existing paths and leave new-paths if the directive is optional?

- 2015-10-04 XXX: at some point, replace cat $conf with something that handles SOURCE
  directives. Current set up does seem to handle multilines using '\' trailer.

- 2015-12-20 XXX: DIR directive, and consolidation asks for kind of interaction
  that makes scripts complex. Not sure wether to include that here.

  Also GIT does not take note of cruft (yet). If that is made an option,
  then maybe other tooling would be obsolete. Until then, ~/bin is to support.


.. _Specification: doc/Specification.rst
.. _Manual: doc/Manual.rst

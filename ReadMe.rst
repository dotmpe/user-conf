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
-----
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


Bugs
----
While not experimental code, this a heavy work-in-progress at the moment.

This document should be updated to reflect the current version but will be lagging a bit until I catch up.


Versions
--------
Expect a long way to go to any definite 1.0 version, if any.

Development release listing in ``ChangeLog.rst``.


.. _Specification: doc/Specification.rst
.. _Manual: doc/Manual.rst

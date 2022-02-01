U-c dev docs
============
:Created: 2022-01-28


Intro
-----


Design specs
------------

uc-init [NAMES...]
  Setup to read user configuration
  to the file found with ``uc-config [NAMES...] install``
  Usually ``UCONF:install/<NAME>.u-c``.

uc-init-copy [NAMES...]
  Alias for ``UC_INIT_COPY=1 uc-init [NAMES...]``.

uc-init-symlink [NAMES...]
  Alias for ``UC_INIT_COPY=0 uc-init [NAMES...]``.

uc-conf
  Set/show config root path

uc-config [NAME][.EXT] [GROUP [GROUP...]]
  Lookup file anywhere in UCONF repo, based on its filename and location.

  Each NAME or GROUP may be a specific value, but settings taken from the shell environment take precedence over existing files.
  This should allow some specific configurations.

  (These arguments go from specific to generic, unlike the other GROUP-argv sequences in this lib that always go from generic to specific.)

  Starts with the given set of groups, or if none given with NAME as group.

  With groups, each argument is used to lookup directories. Starting with the right-most argument it checks if that exists (or rather its ``uc-resolve``  values) and continues to build a path for NAME.

  If at any time a part does not exists ``uc-config`` aborts, unless the argument was '!' prefixed then it drops the group and continues.

  When finally the NAME only argument is left, its `uc-resolve`` result is then added to the path to use as filename and that is echo'd.

uc-resolve [[...GROUP] GROUP] FILE[.EXT]
  Lookup actual file(s) named 'FILE' in a directory specified by GROUP's.

  This uses ``uc-resolve-path`` to find the directory,
  and then tests each ``uc-resolve-env`` to find the final filename.

uc-resolve-path GROUP [GROUP...]
  Lookup actual directory named by GROUP's.

  For each group argument, test whether any of its ``uc-resolve-env`` values or its given literal value exists as directory on the current path.
  If so change to that path, and continue until all arguments are consumed and then echo new current path.
  An argument prefixed with '!' is skipped if it does not yield an directory path.
  At each invocation this first changes the current directory to ``UCONF``.

uc-resolve-env VAR [GROUP [GROUP...]]
  Lookup ``UC_{<GROUP>_,}<VAR>``-keyed value in shell env.

  Starts with the given set of groups, removes last argument until var exists.
  Echoes value on first existing variable and returns success.

uc-groups
  Render a GROUP or GROUP-NAME tree from current settings and files.
  .. for current repository and/or environment.

uc-default
  Set/show special var. In the shell env. these are all 'UC_DEFAULT_` prefixed?
  NAME{,S}

uc-defaults
  Alias for ``uc-default all?``

uc-add [DEST [SOURCE]]
  Mark file to manage.

uc-copy
  ..

uc-symlink
  ..

uc-diff
  ..

Wf is uc-resolve

There are plenty of names for configuration parts.
The profile.d folder will be the litmus test

public
local
static
main
user
system
default

they reflect the context in which they are to be loaded, but also the context which they seek to establish or assert


uc-default
  _NAMES="local user $USER-$HOST $USER-$hostname $USER $HOST $hostname generic default"
  _SH_EXTS=.sh
  _INSTALL_NAMES="Ucfile"
  _INSTALL_EXTS=".u-c .uc"

uc-file
  ..

uc-user-has-config [NAME][.EXT] [GROUP] [GROUP2...]
  Look for a user configuration file under name,

  ``UCONF:etc/<NAME>/<NAME><.EXT>``
  ``UCONF:etc/<NAME><.EXT>``

  ``UCONF:etc/<NAME>/<GROUP><.EXT>``

  ``UCONF:etc/<NAME>/<GROUP><.GROUP2><.EXT>``

  NAMES applies to the NAME argument if left empty or a literal 'NAME' is given.
  It causes to look in sequence for NAMES to find a filename with that ``.EXT``-suffix


Dev
---
- Looking at 'standard' shell idiom in +U-s

- Need uc-resolve or something to find configs

- One file per host seems OK. Keeps args/variables in ucfile down.

- My initial dotfile repo symlinks.tab used hostnames as tags, to filter out
  rules per host. Still an interesting concept. Compare with optional directives.

- TODO: consolidate ~/.local/share and etc and others maybe. Some monitoring.

  Ub/Deb setup shoves some installed apps as '\*.desktop' into
``~/.local/share/applications/defaults.list``

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

..

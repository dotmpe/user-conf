User-Config Specification
=========================
Each line in the user-config should define a rule.
It starts with a directive keyword, followed by one or more
parameters for that directive.

A user-config file can further have unix-style comments ('#'-leader),
empty lines, and line continuations (using '\'-trailer on the line before).

The main directives are the config rules to be applied in sequence,
and described in section Rules_.
Each rule deals with one or more configuration paths, of files or other sorts somewhere on the local host.
There are further secondary directives for metadata and scripting,
some which work in sequence and some are treated globally.

The general rule syntax is::

  [<decorator>]<DIRECTIVE> <param>.. \
    <param>..

The directives and other keywords are case insentive, and the given
case is by convetion but not enforced through code.


Rules
-----

SYMLINK
  Symlink path exists and destination matches::

    SYMLINK <ucfile> <destpath>

  - Requires two arguments: a source and target path (or destination and source resp. [!] in link parlance).

    - First argument should be an existing file or directory path,
      not necessarily in $UCONF.

    - Second argument should be a path to an existing symlink,
      a non-existant file-path, or an existing directory.

      - If the second argument is a directory, the basename of the first argument is
        appended. If the basename cannot be retrieved, an error is given.
      - Otherwise the argument specifies the path to a symlink.

  - Upon update, only symlinks paths are replaced. Existing paths of other types
    result in an error. Paths are only updated as their target is different.


COPY
  File path exists and matches currently checked out UCDIR file::

    COPY <ucfile> <destpath>

  - Requires two arguments: a source and target path.

    - First argument should be an existing file, not necessarily in $UCONF.

    - Second argument should be a path to an existing file,
      a non-existant file-path, or an existing directory.

      - If the second argument is a directory, the basename of the first argument is
        appended. If the basename cannot be retrieved, an error is given.

  - Upon update, an existing target file is only updated if its GIT hash matches a known version of the source file.
    This should prevent overwriting locally modified files.

  TODO: added +/- attriibutes. Iow. delete, but only known files.
  Same for SYMLINK perhaps.


GIT
  GIT checkout exists and has named remote with matching url::

    GIT <giturl> <destpath> [<remote> [<branch> [clone|submodule]]]

  - Requires two arguments, takes at most five arguments.

    - First argument is a GIT url.
    - Second argument should be a target path.

    The use of the second argument, and the function of the directive depends
    on the following optional arguments.

    - Third argument is the name for the remote, defaults to origin.
    - Fourth argument is the branch to checkout and for remote tracking.
      Defaults to master.
    - Fourth is the mode of the target. This defaults to 'clone',
      and can also be 'submodule' or kkk

  - Only the target basepath needs to be provided if `basename <url> .git`
    provides the correct checkout directory name.

    In that case the target path is an existing directory, and not
    a GIT checkout, and it is used as basedir for a new clone.

    A custom path can also be given.

  - A checkout is created if it does not exist. If the path does exist
    is should be a checkout with matching URL and remote name.

  - An existing checkout should be clean. On stat or update each is checked
    for modifications, cruft, or local commits.

  - XXX: for consolidation git can be used, no need to improve there?

  - If mode is submodule instead of clone, then the second argument
    should be an existing GIT checkout of which this directive specifies
    a submodule. The same update rules are applied.

  Notes
    - If multiple remotes are desired, it is best to put the origin first.
      This way if it not exists, this remote is cloned from.
    - The remote ref is compared with HEAD, to note local commits that
      need to be pushed. XXX: To keep no-push remotes some other function is
      needed.


INSTALL::

    INSTALL [apt|pip|brew|...|*] <packages>

  TODO: Install user-commands using given package manager.
  The commands requested are listed as parameters. If a command does not exit normally when used without arguments or options, an entry with BIN should be made.


WEB::

    WEB <url> <destpath>

  Fetch, update file from URL.


DIR::

    DIR <destpath> [copy|symlink] [nouc]


  TODO: each path below dir is treated as a copy, symlink or git repo.
  Wich ever is appropiate. Plain directories and other types of paths are
  ignored. Other non-GIT SCM checkouts same, until supported.

  All files are hashed and checked wether present in UCONF repo,
  of a currently checked out file, and wether that file is listed in the Ucfile.


LINE::

    LINE <filepath> <lines>..

  TODO: check or update certain plain-text file lines.

  - Takes two or more arguments: a path to a plain-text config file, and a set of strings each representing a line that should be found in the file.
  - If the line is not present, it is appended to the file.
  - If the line starts with a word of at least three characters, the file is searched for any commented line starting with that word (and followed by whitespace). If found, the last occurence is used as an insert point instead: the new line is inserted after that line.


Decorators
----------
TODO: Expand on notation for rule directives to allow instance parametrization.
For common attributes use single-character decorators, prefixing the directive.
Decorators may be combined by concatenation.

Directive decorators:
   +DIRECTIVE
        Default. Apply the given rule.

   -DIRECTIVE
        Reverse apply the rule: undo changes or remove paths.

   ?DIRECTIVE .. <destpath> ..
        The rule is applied if destpath does not exist yet.
        Existing paths are ignored if properties don't match directive.

   !DIRECTIVE
        The rule is applied normally, but the result is ignored and does not
        influence the stat or update exit-code.

   %DIRECTIVE
        Prefix operations with sudo.

   \*DIRECTIVE var=foo,override=bar,sudo=1
        Parametrize rule: include shell vars with custom default settings before rule parameters.

        The preceeding decorators respectively equal::

          *DIRECTIVE apply=[normal|reverse]
          *DIRECTIVE ignore=true
          *DIRECTIVE silent=true
          *DIRECTIVE sudo=true

        And the following two lines are identical::

          +?!%DIRECTIVE <param>..
          *DIRECTIVE apply=1,ignore=1,silent=1,sudo=1 <param>..

        However silent makes ignore unnecessary.


Meta directives
---------------

SH <sh-cmdline>
  Shell command, evaluated in-sequence.

ENV <sh-var-decl>
  Shell variables, evaluated in-sequence.

AGE [git|url] <age>
  Set the maximum GIT head reference age, before it is refetched to check for updates.

BASE <host-path> <repo-path>
  Map local-host paths to user-config repository paths.
  This is a global setting, used by the 'script/add' user command.
  It takes two arguments: host path, and repository path.

BIN
  TODO: provide test commands for INSTALL to use to check wether a user-command is installed. This is for commands that don't exit normally when executed without arguments.

  To use, for example::

    BIN "sed --version" "rsync -h"

..

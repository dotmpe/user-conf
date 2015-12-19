User-Config Specification
=========================
Each line in the user-config should start with a directive,
followed by one or more parameters for that directive.

The main directives are the config rules to be applied in sequence.
Each rule deals with one or more configuration paths, of files or other sorts somewhere on the local host.
There are further secondary directives for metadata and scripting.

A user-config file can have unix-style comments ('#'-leader),
empty lines, and line continuations using '\'-trailer.

TODO: Expand on notation for rule directives:

   +DIRECTIVE
        Default. Apply the given rule.

   -DIRECTIVE
        Reverse apply the rule: undo changes or remove paths.

   DIRECTIVE var=foo override=1
        Specify rule behaviour: include shell vars with custom default settings before rule parameters.


Rules
-----

INSTALL [apt|pip|brew|...|*]
  TODO: Install user-commands using given package manager.
  The commands requested are listed as parameters. If a command does not exit normally when used without arguments or options, an entry with BIN should be made.


SYMLINK
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
  - Requires two arguments: a source and target path.

    - First argument should be an existing file, not necessarily in $UCONF.

    - Second argument should be a path to an existing file,
      a non-existant file-path, or an existing directory.

      - If the second argument is a directory, the basename of the first argument is
        appended. If the basename cannot be retrieved, an error is given.

  - Upon update, an existing target file is only updated if its GIT hash matches a known version of the source file.
    This should prevent overwriting locally modified files.


GIT
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
    for modifications or cruft.

  - XXX: for consolidation git can be used, no need to improve there?

  - If mode is submodule instead of clone, then the second argument
    should be an existing GIT checkout of which this directive specifies
    a submodule. The same update rules are applied.


ANNEX
  TODO: exactly like git.


LINE
  TODO:

  - Takes two or more arguments: a path to a plain-text config file, and a set of strings each representing a line that should be found in the file.
  - If the line is not present, it is appended to the file.
  - If the line starts with a word of at least three characters, the file is searched for any commented line starting with that word (and followed by whitespace). If found, the last occurence is used as an insert point instead: the new line is inserted after that line.



Meta directives
---------------
SH
  Shell command, evaluated in-sequence.

ENV
  Shell variables, evaluated in-sequence.

AGE git
  Set the maximum GIT head reference age, before it is refetched to check for updates.

BASE
  Map local-host paths to user-config repository paths.
  This is a global setting, used by the 'script/add' user command.
  It takes two arguments: host path, and repository path.

BIN
  TODO: provide test commands for INSTALL to use to check wether a user-command is installed. This is for commands that don't exit normally when executed without arguments.

  To use, for example::

    BIN "sed --version" "rsync -h"



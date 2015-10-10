
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
  ..


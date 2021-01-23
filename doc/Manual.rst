User-Config Manual
==================
See the Specification for details regarding the syntax and available directives.


User-Conf is the beach-head for user-libs

  uc init [domain [hostname]]   # Run to configure installation profile
  uc install                    # Install every dependency
  uc update                     # Run and report on every directive
  uc stat                       # Only update report for every directive

  uc info                       # Default: show config and (last) status
  uc status                     # Return cached report and status
  uc test                       # Return cached status
  uc report                     # Show current stat numbers
  uc help

TODO: make stat into quick, cache or no-cache response
and turn status into caching for itself and stat

Frontends
  - ``path/Generic/uc`` is working, but
  - ``script/user-conf/*.sh`` also still in use

TODO: install-dependencies.sh should be able to consolidate into INSTALL directives, and user-lib(s).

TODO: should merge install action into update/stat cycle


UCONF is used as the target to move/copy user config files to and from.

TODO: set UCONFDIR from sh_lib while none given

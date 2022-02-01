#
# In practive these idoms emerged during almost 15 years of scripting, website
# building and devops. First:
#
#    $LOG <Header> <Message description> <Context info> <Exit-Status>
#
# That quickly turned into
#
#    $LOG <Level-Name> <Event-Tag> <Message description> <Context info> <Exit-Status>
#    <Level-Name> <Message description> <Exit-Status>
#
# While related however their meanings diverged, respectively:
#
#    1. Inform user or system of some (exceptional) change in program flow,
#       stop maybe sometimes.
#    2. Stop program flow now, informing user
#
# Obvious from the name maybe the first was never implemented thoughtfully.
#
# With the {emerg,alert,crit,err,warn,note,info,debug}
# stdlog interface an immediate exit can be requested.
# This is an obvious action in user-command scripts,
# but robs the program from the opportunity to handle the result status.
#
# Switching this behaviour based on Batch-Mode setting allows to
# script long running, complex batch sessions based on a simple fact established
# during their start-up: is there interaction (at input, output, or any stdio
# stream, stderr, etc.).
#
# Still an exit or return state may be set, using std-error.
#
# Sadly only 255 values are possible, but depending on context might some useful
# work can be made of them?
#
# std:term [0] [1] [2] [...]
# std:fail <Status-Code> <>
# std:error <Status-Code>
# std:err <Header> <Message> <Exit-if-...?>
# std:v -> std:verbose <Numeric-Verbosity-Level>
#
# Currently Exit-if-...? is ill-defined, it should ofcourse not compare with the
# severity-level and log-/verbosity-level if header is already compared with
# that. And while header might have evolved into tags, it didn't but was used
# for severity tag.
#
# Could mask 'exit requested' Status-Code, but currently setting all 'true'...?!
#
# More sane argv idiom.
#

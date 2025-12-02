uc_dsl_userconf_pre=User-Conf.Config-DSL

declare -gA \
uc_dsl_userconf=(
  [age]=param
  [apply]=flow
  [assert-dir]=directive
  [assert-file]=directive
  [copy-or-symlink]=directive
  [clean]=directive
  [cook]=alias:apply
  [copy]=directive
  [env]=directive
  [git]=directive
  [git-age]=param
  [install]=directive
  [os-age]=param
  [line]=directive
  [line-word]=directive
  [path]=directive
  [symlink]=directive
)

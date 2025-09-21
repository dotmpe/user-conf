uconf-shell-core ()
{
  : about "Core routines for uc-env"
  #: super uc-env
  : part \
      {add,assert},path,os.bash \
      {body,eval,exists},fun,sh.bash \
      match,glob,str.bash \
      firstseq,argv,sys.bash \
      {find,union},arr,sys.bash \
      {apply,narr},exec,sys.bash \
      {names,narr},try,sys.bash \
      add,narr,sys.bash \
      {exec,items},read,sys.bash \
      {dynfun,failerr{,-pass},include,reloadfun,reference},core,shell,uconf.bash
}

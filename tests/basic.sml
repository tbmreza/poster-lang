use "compiler/cps.sml";
open Interpreter;
open Types;

script(apply (LPrim OpOutput, LVar "version"));
script(apply (LFn (CLO ("x", LApp (LPrim OpOutput, LVar "x"), Env [])), LStr "yippi"));

script(apply (LVar "#output", LStr "\tplease"));

script(LProg (apply (LVar "#output", LStr "\tfst"), apply (LVar "#output", LStr "\tsnd")));

script(
  LLet (
    ("uprint", LDef ("x", LApp (LPrim OpOutput, LVar "x"))),
    apply (LVar "uprint", LStr "\tyattayooo"))
);

script(
  LLet (
    ("outer", LDef ("x", LVar "x")),
    LLet (
      ("uprint", LDef ("x", LApp (LPrim OpOutput, LVar "x"))),
      apply (LVar "uprint", apply (LVar "outer", LStr "\tkeren juga"))))
);


script(
LProg (
apply (LVar "#output", LStr "\tfst"), LProg (
apply (LVar "#output", LStr "\tsnd"),
apply (LVar "#output", LStr "\tthd")))
);


script(
  LFor ("i", LInt 0, LInt 3, apply (LVar "#output", LStr "0\n"))

  (* print "0\n1\n2\n" *)
)

(* ??

a := 11
a := 22
a := 33
#output a

*)

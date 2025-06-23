use "compiler/types.sml";

signature INTERPRETER = sig
  type expr

  val instanceInfo : string
  val apply : (expr * expr) -> expr
  val script : expr -> unit
end

structure Interpreter : INTERPRETER = struct
val instanceInfo = "poster 0.1"

open Types
fun toString(STRING s) = s
  | toString(INT v) = Int.toString v
  | toString(BOOL v) = Bool.toString v
  | toString _ = raise unimplemented

fun doOutput(arg: value) = let
  val _ = print((toString arg) ^ "\n")
in
  UNIT
end

fun doReadFile(arg: value) = let
  val _ = print("unimplemented reading from " ^ (toString arg) ^ "\n")
in
  UNIT
end

(* It matters that env is an ordered list (of history of values)
   that `lookup` returns early on the closest/most local value
   of bound variable.

   Looking up in doesn't pass time in our history. The fact that
   the operation is non-constant time (worst O(n)) is out of our
   granularity.  *)
(* fun lookup x (Env []) = raise Fail ("Unbound variable: " ^ x) *)
(*   | lookup x (Env ((y, v)::env)) = if x = y then v else lookup x (Env env) *)
fun lookup x (Env []) = 
    (print ("DEBUG: Looking up '" ^ x ^ "' in empty environment\n");
     raise Fail ("Unbound variable: " ^ x))
  | lookup x (Env ((y, v)::env)) = 
    (print ("DEBUG: Looking up '" ^ x ^ "', checking against '" ^ y ^ "'\n");
     if x = y then 
       (print ("DEBUG: Found match! Returning value\n"); v)
     else 
       (print ("DEBUG: No match, continuing search...\n");
        lookup x (Env env)))

fun extend x v (Env env) = Env ((x, v)::env)

(* Presumably with `ioInterp : value -> (computation(); UNIT)`,
   halt/non-halting k differentiation is rendered unnecessary. *)
fun ioInterp (INT v) =    (v; UNIT)
  | ioInterp (STRING v) = (v; UNIT)
  | ioInterp (BOOL v) =   (v; UNIT)
  | ioInterp  UNIT =     ((); UNIT)

  | ioInterp (CLO _) =
    (print("<closure>\n");
     UNIT)

fun node (BOOL b) = LBool b
  | node (CLO (farg, exp, _)) = LDef (farg, exp)
  | node (INT n) = LInt n
  | node UNIT = LUnit
  | node (STRING s) = LStr s


(* ??: visualize to web *)
val mutHistory : (snapshot list) ref
               = ref []

fun snap! ssExpr ssEnv ssCont = let
  val ss = Snapshot
    { ssExpr = ssExpr
    , ssEnv = ssEnv
    , ssCont = ssCont
    }
  val _ = mutHistory := ss :: !mutHistory
in
  ssCont
end

(* Evaluate AST to a value via CPS rules. Save env on every interesting
   reductions (i.e. cps invocations in rhs' that extends env, branches that we take, ).

    cps :     expr    -> value  *)
fun cps (LInt v, _, k) = k (INT v)
  | cps (LStr v, _, k) = k (STRING v)
  | cps (LBool v, _, k) = k (BOOL v)

  | cps (LDef (farg, body), env, k) =
    k (CLO (farg, body, env))

  | cps (LVar var, env, k) = let val var' = lookup var env in
    k var' end


  | cps (LAdd (LInt m, LInt n), env, k) =
    k (INT (m + n))

  | cps (LAdd (la, lb), env, k) =
    cps (la, env, fn la' =>
      cps (lb, env, fn lb' =>
        cps (LAdd (node la', node lb'), env, k)))


  | cps (LMul [LInt m, LInt n], env, k) =
    k (INT (m * n))

  | cps (LMul [la, lb], env, k) =
    cps (la, env, fn la' =>
      cps (lb, env, fn lb' =>
        cps (LMul [(node la'), (node lb')], env, k)))


  | cps (LApp (LDef (farg, exp), arg), env, k) =
    (* Closure's env is extended with (farg, arg'). *)
    cps (arg, env, fn arg' => let val env' = (extend farg arg' env) in
      cps (exp, env', k) end)

  | cps (LApp (LPrim prim, exp), env, k) =
    cps (exp, env, fn exp' => k (case prim of
      OpOutput => doOutput exp'
    | OpReadFile => doReadFile exp'))

  | cps (LApp (f, arg), env, k) =
    cps (f, env, fn f' =>
      cps (arg, env, fn arg' =>
        cps (LApp (node f', node arg'), env, k)))


  | cps (LIf (LBool true, exp, _), env, k) =
    (* cps (exp, env,             fn exp' => k exp') *)
    cps (exp, env, snap! exp env (fn exp' => k exp'))

  | cps (LIf (LBool false, _, exp), env, k) =
    (* cps (exp, env, fn exp' => k exp') *)
    cps (exp, env, snap! exp env (fn exp' => k exp'))

  | cps (LIf (b, thn, els), env, k) =
    cps (b, env, fn b' =>
      cps (LIf (node b', thn, els), env, k))


  | cps (LProg (s, t), env, k) =
    cps (s, env, fn _ => cps (t, env, k))

(* desugaring
  for i = lo to hi do
    body(i)



  let
    fun loop i =
      if i > hi then ()
      else (
        body(i);
        loop (i + 1)
      )
  in
    loop lo
  end
*)
  
  (*
  a := 11         -- env { a: 11 }
  b := a + 100    -- env { a: 11, b: 111 }
  pi := 300 + 14  -- env { pi: 314 }
  ()  -- unit body
  *)

  | cps (LLet ((name, exp), body), env, k) =
    cps (exp, env, fn exp' => let val env' = (extend name exp' env) in
      cps (body, env', snap! body env' k) end)


  | cps (LGt (LInt m, LInt n), env, k) =
    k (BOOL (m > n))

  | cps (LGt (a, b), env, k) =
    cps (a, env, fn a' =>
      cps (b, env, fn b' => cps (LGt (node a', node b'), env, k)))

  (* ??: read up on parallel cps data/control flow. *)

  (* First extend env with (loopVar, lo). *)
  (* Contextualize body with new env. *)
  | cps (LFor (loopVar, LInt lo, LInt hi, LDef ("_", payload)), env, k) =
    let
      val env' = extend loopVar (INT lo) env
    in
      case lo = hi of
        true => k UNIT
      | _ =>
        cps (payload, env', fn _ =>
          cps (LFor (loopVar, LInt (lo + 1), LInt hi, LDef ("_", payload)), env', k))
    end

  | cps (LFor (loopVar, LInt lo, LInt hi, body), env, k) =
    cps (LFor (loopVar, LInt lo, LInt hi, LDef ("_", body)), env, k)

  | cps (LFor (loopVar, lo, hi, body), env, k) =
    cps (lo, env, fn lo' => k (case OpOutput of
      OpOutput => doOutput (STRING "yea dis")
    | OpReadFile => doOutput (STRING "yea")))


  (* | cps (todo, _, _) = (print("todo"); raise unimplemented) *)

fun script(ast) = let
  val builtins = Env
    [ ("ident",   CLO ("x", LVar "x", Env []))
    , ("#output", CLO ("x", LApp (LPrim OpOutput, LVar "x"), Env []))
    , ("version", STRING "v1.0")
    ]

  val _ = ioInterp
    (cps (ast, builtins, snap! ast builtins (fn v => v)))

in () end;

end

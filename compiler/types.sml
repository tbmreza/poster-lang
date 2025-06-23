structure Types = struct

exception unreachable
exception unimplemented

(* Operations we'd rather not encode from pure lambda calculus. *)
datatype primitive =
  OpOutput
| OpReadFile

datatype expr =
  LUnit
| LProg of expr * expr  (* a cons-list of statements makes a program *)
| LLet of  (string * expr) * expr
| LInt of  int
| LAdd of  expr * expr
| LMul of  expr list
| LStr of  string
| LVar of  string
| LBool of bool
| LGt of   expr * expr
| LIf of   expr * expr * expr

| LApp of  expr * expr    (* first component reducible to LDef | LPrim *)
| LPrim of primitive      (* LApp (LPrim OpOutput, LVar "x") *)
| LDef of  string * expr  (* fn (string) => expr *)
| LFn of   value          (* an adapter(!) for when the interpreter expects
                             closures in expr form. *)

| LFor of string * expr * expr * expr  (* for (string := LInt; string <= LInt) { body } *)

(* ??: currying list of formal params *)

and value =
  UNIT
| INT of    int
| STRING of string
| BOOL of   bool
(* Closure is a contextualized function definition form.
   env ⊢ fn string => expr  *)
| CLO of string * expr * env

(* type alias wouldn't suffice here in ML; env needs to be a datatype
   with constructor.  *)
and env = Env of ((string * value) list);

fun apply (LFn (CLO (farg, body, _)), arg) = LApp (LDef (farg, body), arg)
  | apply (f, arg) = LApp (f, arg)

(* ??: fun thunk payload = LDef ("_", payload) *)

datatype snapshot =
  Snapshot of { ssExpr: expr
              , ssEnv: env
              , ssCont: value -> value
              }

end

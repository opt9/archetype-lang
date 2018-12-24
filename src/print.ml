(* -------------------------------------------------------------------- *)
open Core
open Location
open Ast

(* -------------------------------------------------------------------- *)
let pp_list sep pp =
  Format.pp_print_list
    ~pp_sep:(fun fmt () -> Format.fprintf fmt "%(%)" sep)
    pp

(* -------------------------------------------------------------------- *)
let pp_id fmt (id : lident) =
  Format.fprintf fmt "%s" (unloc id)

(* -------------------------------------------------------------------- *)
let pp_ident fmt { pldesc = e } =
  match e with
  | Isimple id -> Format.fprintf fmt "%a" pp_id id
  | Idouble (id, _) -> Format.fprintf fmt "%a" pp_id id


(* -------------------------------------------------------------------- *)
let logical_operator_to_str op =
match op with
  | And   -> "and"
  | Or    -> "or"
  | Imply -> "->"
  | Equiv -> "<->"

let pp_logical_operator fmt op =
 Format.fprintf fmt "%s" (logical_operator_to_str op)

let comparison_operator_to_str op =
match op with
  | Equal  -> "="
  | Nequal -> "<>"
  | Gt     -> ">"
  | Ge     -> ">="
  | Lt     -> "<"
  | Le     -> "<="

let pp_comparison_operator fmt op =
 Format.fprintf fmt "%s" (comparison_operator_to_str op)

let arithmetic_operator_to_str op =
match op with
  | Plus   -> "+"
  | Minus  -> "-"
  | Mult   -> "*"
  | Div    -> "/"

let pp_arithmetic_operator fmt op =
 Format.fprintf fmt "%s" (arithmetic_operator_to_str op)

let assignment_operator_to_str op =
match op with
  | Assign      -> ":="
  | PlusAssign  -> "+="
  | MinusAssign -> "-="
  | MultAssign  -> "*="
  | DivAssign   -> "/="
  | AndAssign   -> "&="
  | OrAssign    -> "|="

let pp_assignment_operator fmt op =
 Format.fprintf fmt "%s" (assignment_operator_to_str op)

let quantifier_to_str op =
match op with
  | Forall -> "forall"
  | Exists -> "exists"

let pp_quantifier fmt op =
 Format.fprintf fmt "%s" (quantifier_to_str op)

let rec pp_expr fmt { pldesc = e } =
  match e with
  | Eterm (id, _args) ->
      Format.fprintf fmt "%a"
        pp_ident id (*pp_list "@," pp_expr) args*)

  | Eliteral x ->
      Format.fprintf fmt "%a"
        pp_literal x

  | Edot (lhs, rhs) ->
      Format.fprintf fmt "%a.%a"
        pp_expr lhs pp_expr rhs

  | Elogical (op, lhs, rhs) ->
      Format.fprintf fmt "%a %a %a"
        pp_expr lhs pp_logical_operator op pp_expr rhs

  | Enot e ->
      Format.fprintf fmt "not %a"
        pp_expr e

  | Ecomparison (op, lhs, rhs) ->
      Format.fprintf fmt "%a %a %a"
        pp_expr lhs pp_comparison_operator op pp_expr rhs

  | Earithmetic (op, lhs, rhs) ->
      Format.fprintf fmt "%a %a %a"
        pp_expr lhs pp_arithmetic_operator op pp_expr rhs

  | Earray values ->
      Format.fprintf fmt "[%a]"
        (pp_list "@," pp_expr) values

  | EassignFields l ->
      Format.fprintf fmt "{%a}"
        (pp_list " " pp_assignment_field) l

  | Equantifier (q, id, t, body) ->
      Format.fprintf fmt "%a %a : %a, %a"
        pp_quantifier q
        pp_id id
        pp_expr t
        pp_expr body

and pp_literal fmt lit =
  match lit with
  | Lnumber n -> Format.fprintf fmt "%d" n
  | Lstring s -> Format.fprintf fmt "%s" s

and pp_assignment_field fmt f =
  match f with
  | AassignField (op, id, e) ->
      Format.fprintf fmt "%a %a %a;"
        pp_ident id pp_assignment_operator op pp_expr e

(* -------------------------------------------------------------------- *)
let pp_extension fmt { pldesc = e } =
  match e with
  | Eextension (id, Some args) -> Format.fprintf fmt "[%%%a %a]" pp_id id (pp_list "@," pp_expr) args
  | Eextension (id, _) -> Format.fprintf fmt "[%%%a]" pp_id id


(* -------------------------------------------------------------------- *)
let pp_field fmt { pldesc = f } =
  match f with
  | Ffield (id, typ) -> Format.fprintf fmt "%a : %a;" pp_id id pp_id typ


(* -------------------------------------------------------------------- *)
let rec pp_instr fmt { pldesc = s } =
  match s with
  | Iassign (op, lhs, rhs) ->
      Format.fprintf fmt "%a %a %a"
        pp_expr lhs pp_assignment_operator op pp_expr rhs

  | Iletin (id, e, body) ->
      Format.fprintf fmt "let %a = %a in %a"
        pp_id id pp_expr e (pp_list "@," pp_instr) body

  | Iif (cond, _then, _else) ->
      Format.fprintf fmt "if (%a) {%a}"
        pp_expr cond
        (pp_list "@," pp_instr) _then
       (*match _else with | _ -> Format.fprintf fmt ""*)

  | Ifor (id, expr, body) ->
      Format.fprintf fmt "for (%a in %a) {%a}"
        pp_id id pp_expr expr (pp_list "@," pp_instr) body

  | Icall e ->
      Format.fprintf fmt "%a"
        pp_expr e

  | Iassert e ->
      Format.fprintf fmt "assert (%a);"
        pp_expr e


(* -------------------------------------------------------------------- *)
let pp_transitem fmt { pldesc = t } =
  match t with
  | Targs fields ->
      Format.fprintf fmt "args = {@[<v 2>]@,%a@]}\n"
        (pp_list "@," pp_field) fields

  | Tcalledby (e, _exts) ->
      Format.fprintf fmt "called by %a;\n"
        pp_expr e

  | Tensure e ->
      Format.fprintf fmt "ensure: %a;\n"
        pp_expr e

  | Tcondition e ->
      Format.fprintf fmt "condition: %a;\n"
        pp_expr e

  | Ttransition (from, _to) ->
      Format.fprintf fmt "transition from %a to %a;"
        pp_id from pp_id _to

  | Taction instrs ->
      Format.fprintf fmt "action:\n %a" (pp_list "@," pp_instr) instrs


(* -------------------------------------------------------------------- *)
let pp_declaration fmt { pldesc = e } =
  match e with
  | Duse id ->
      Format.fprintf fmt "use %a\n" pp_id id

  | Dmodel id ->
      Format.fprintf fmt "model %a\n" pp_id id

  | Dconstant (id, typ, _) ->
      Format.fprintf fmt "constant %a %a\n" pp_id id pp_id typ

  | Dvalue (id, typ, _) ->
      Format.fprintf fmt "value %a %a\n" pp_id id pp_id typ

  | Drole (id, _val, _exts) ->
      Format.fprintf fmt "role %a\n" pp_id id

  | Denum (id, ids) ->
      Format.fprintf fmt "enum %a =\n  | %a"
        pp_id id (pp_list "\n  | " pp_id) ids

  | Dstates (None, _ids) ->
      Format.fprintf fmt ""
(*      Format.fprintf fmt "states\n  | %a" (pp_list "\n  | " pp_id) ids*)

  | Dstates (Some _id, _ids) ->
      Format.fprintf fmt ""
(*      Format.fprintf fmt "states %a =\n  | %a"
        pp_id id (pp_list "\n  | " pp_id) ids*)

  | Dasset (id, fields, _op) ->
      Format.fprintf fmt "asset %a = {@[<v 2>]@,%a@]}\n"
        pp_id id (pp_list "@," pp_field) fields

  | Dassert e ->
      Format.fprintf fmt "assert (%a)\n"
        pp_expr e

  | Dtransition (id, from, _to, _) ->
      Format.fprintf fmt "transition %a from %a to %a\n"
        pp_id id pp_id from pp_id _to

  | Dtransaction (id, items) ->
      Format.fprintf fmt "transaction %a = {@[<v 2>]@,%a@}\n"
        pp_id id (pp_list "@," pp_transitem) items


(* -------------------------------------------------------------------- *)
let pp_model fmt (Mmodel es) =
  Format.fprintf fmt "%a" (pp_list "@,\n" pp_declaration) es

(* -------------------------------------------------------------------- *)
let string_of__of_pp pp x =
  Format.asprintf "%a" pp x

(* -------------------------------------------------------------------- *)
let ident_to_str  = string_of__of_pp pp_ident
let expr_to_str  = string_of__of_pp pp_expr
let extension_to_str = string_of__of_pp pp_extension
let field_to_str  = string_of__of_pp pp_field
let instr_to_str = string_of__of_pp pp_instr
let transitem_to_str = string_of__of_pp pp_transitem
let declaration_to_str = string_of__of_pp pp_declaration
let model_to_str  = string_of__of_pp pp_model

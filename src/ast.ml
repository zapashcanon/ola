(* Abstract Syntax Tree *)

type location = Lexing.position * Lexing.position

type number_type =
  | Tinteger
  | Tfloat

type typ =
  | Tnil
  | Tboolean
  | Tnumber of number_type
  | Tstring
  | Tfunction
  | Tuserdata
  | Tthread
  | Ttable

type number =
  | Ninteger of int
  | Nfloat of float

type value =
  | Vnil of unit
  | Vboolean of bool
  | Vnumber of number
  | Vstring of string

type name = string

type var = Name of name

type unop =
  | Unot
  | Uminus
  | Usharp

type binop =
  | Band
  | Bor
  | Badd
  | Bsub
  | Bmul
  | Bdiv
  | Bfldiv
  | Bmod
  | Bexp
  | Beq
  | Bneq
  | Blt
  | Ble
  | Bgt
  | Bge
  | Bddot

type expr = location * expr'

and expr' =
  (* type expr = *)
  | Evalue of value
  | Evar of var
  | Eunop of unop * expr
  | Ebinop of binop * expr * expr

type stmt =
  | Sempty
  | Sassign of var list * expr list
  | Sbreak
  | Slabel of name
  | Sgoto of name
  | Sblock of block
  | Swhile of expr * block
  | Srepeat of block * expr
  | Sif of expr * block * (expr * block) list * block option
  | Sfor of name * expr * expr * expr option * block
  | Siterator of name list * expr list * block
  | Sprint of expr

and block = stmt list

type chunk = block

(* pretty printer *)

let print_var fmt var = match var with Name n -> Format.pp_print_string fmt n

let print_unop fmt unop =
  match unop with
  | Unot -> Format.pp_print_string fmt "not "
  | Uminus -> Format.pp_print_string fmt "-"
  | Usharp -> Format.pp_print_string fmt "#"

let print_binop fmt binop =
  match binop with
  | Band -> Format.pp_print_string fmt " and "
  | Bor -> Format.pp_print_string fmt " or "
  | Badd -> Format.pp_print_string fmt "+"
  | Bsub -> Format.pp_print_string fmt "-"
  | Bmul -> Format.pp_print_string fmt "*"
  | Bdiv -> Format.pp_print_string fmt "/"
  | Bfldiv -> Format.pp_print_string fmt "//"
  | Bmod -> Format.pp_print_string fmt "%"
  | Bexp -> Format.pp_print_string fmt "^"
  | Blt -> Format.pp_print_string fmt "<"
  | Ble -> Format.pp_print_string fmt "<="
  | Bgt -> Format.pp_print_string fmt ">"
  | Bge -> Format.pp_print_string fmt ">="
  | Beq -> Format.pp_print_string fmt "=="
  | Bneq -> Format.pp_print_string fmt "~="
  | Bddot -> Format.pp_print_string fmt ".."

let print_number fmt number =
  match number with
  | Ninteger i -> Format.pp_print_int fmt i
  | Nfloat f -> Format.pp_print_float fmt f

let print_value fmt value =
  match value with
  | Vnil _ -> Format.pp_print_string fmt "nil"
  | Vboolean b -> Format.pp_print_bool fmt b
  | Vnumber num -> print_number fmt num
  | Vstring s -> Format.pp_print_string fmt s

let rec print_expr fmt expr =
  match expr with
  | Evalue v -> print_value fmt v
  | Evar i -> print_var fmt i
  | Eunop (uop, (_, e)) ->
    print_unop fmt uop;
    print_expr fmt e
  | Ebinop (bop, (_, e1), (_, e2)) ->
    print_expr fmt e1;
    print_binop fmt bop;
    print_expr fmt e2

let rec print_stmt fmt stmt =
  let pp_sep fmt () = Format.fprintf fmt ", " in
  let to_el = List.map (fun (_, e) -> e) in
  match stmt with
  | Sempty -> Format.fprintf fmt ""
  | Sassign (il, lel) ->
    Format.pp_print_list ~pp_sep print_var fmt il;
    Format.fprintf fmt " = ";
    Format.pp_print_list ~pp_sep print_expr fmt (to_el lel);
    Format.fprintf fmt "@."
  | Sbreak -> Format.fprintf fmt "break@."
  | Slabel n ->
    Format.fprintf fmt "::";
    Format.pp_print_string fmt n;
    Format.fprintf fmt "::@."
  | Sgoto n ->
    Format.fprintf fmt "goto ";
    Format.pp_print_string fmt n;
    Format.fprintf fmt "@."
  | Sblock b -> print_block fmt b
  | Swhile ((_, e), b) ->
    Format.fprintf fmt "while ";
    print_expr fmt e;
    Format.fprintf fmt "@.do ";
    print_block fmt b;
    Format.fprintf fmt "end@."
  | Srepeat (b, (_, e)) ->
    Format.fprintf fmt "repeat ";
    print_block fmt b;
    Format.fprintf fmt "@.until ";
    print_expr fmt e;
    Format.fprintf fmt "@."
  | Sif ((_, e), b, lebl, ob) ->
    let to_ebl = List.map (fun ((_, e), b) -> (e, b)) in
    let print_elseif fmt (e, b) =
      Format.fprintf fmt "elseif ";
      print_expr fmt e;
      Format.fprintf fmt " then ";
      print_block fmt b
    in
    Format.fprintf fmt "if ";
    print_expr fmt e;
    Format.fprintf fmt " then ";
    print_block fmt b;
    Format.pp_print_list print_elseif fmt (to_ebl lebl);
    begin
      match ob with
      | Some b ->
        Format.fprintf fmt "else ";
        print_block fmt b
      | None -> ()
    end
  | Sfor (n, (_, e1), (_, e2), oe, b) ->
    Format.fprintf fmt "for ";
    Format.pp_print_string fmt n;
    Format.fprintf fmt " = ";
    print_expr fmt e1;
    Format.fprintf fmt ", ";
    print_expr fmt e2;
    begin
      match oe with
      | Some (_, e3) ->
        Format.fprintf fmt ", ";
        print_expr fmt e3
      | None -> ()
    end;
    Format.fprintf fmt "@.do ";
    print_block fmt b;
    Format.fprintf fmt "end@."
  | Siterator (nl, lel, b) ->
    Format.fprintf fmt "for ";
    Format.pp_print_list ~pp_sep Format.pp_print_string fmt nl;
    Format.fprintf fmt " = ";
    Format.pp_print_list ~pp_sep print_expr fmt (to_el lel);
    Format.fprintf fmt "@.do ";
    print_block fmt b;
    Format.fprintf fmt "end@."
  | Sprint (_, e) ->
    Format.fprintf fmt "print(";
    print_expr fmt e;
    Format.fprintf fmt ")@."

and print_block fmt block =
  let pp_sep _fmt () = () in
  Format.pp_print_list ~pp_sep print_stmt fmt block

let print_chunk fmt chunk = print_block fmt chunk

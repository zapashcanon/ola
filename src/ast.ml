(* Abstract Syntax Tree *)

type typ =
  | Tnil
  | Tnumber
  | Tboolean
  | Tstring
  | Tfunction
  | Tuserdata
  | Tthread
  | Ttable

type ident = string

(* type unop =
  | Unot not e *)

type binop =
  | Badd | Bsub | Bmul
(*  | Bdiv           (* + - * / *)
  | Beq | Bneq | Blt | Ble | Bgt | Bge  (* == != < <= > >= *)
  | Band | Bor                          && || *)

type number =
  | Ninteger of int
  | Nfloat of float

type value =
  | Vnil
  | Vfalse
  | Vtrue
  | Vnumber of number
  | Vstring of string

type expr =
  | Evalue of value
  | Eident of ident
  (* | Eunop of unop * expr *)
  | Ebinop of binop * expr * expr

type stmt =
  | Sblock of block
  (* | Sassign of var list * expr list *)
  | Sprint of expr

and block =
  | Bstmt of stmt list

type script = stmt list

(* pretty printer *)

let print_ident fmt ident =
  match ident with
  | ident -> Format.pp_print_string fmt ident 

let print_binop fmt binop =
  match binop with
  | Badd -> Format.pp_print_string fmt "+"
  | Bsub -> Format.pp_print_string fmt "-"
  | Bmul -> Format.pp_print_string fmt "*"

let print_number fmt number =
  match number with
  | Ninteger i -> Format.pp_print_int fmt i
  | Nfloat f -> Format.pp_print_float fmt f

let print_value fmt value =
  match value with
  | Vnil -> Format.pp_print_string fmt "nil"
  | Vfalse -> Format.pp_print_string fmt "false"
  | Vtrue -> Format.pp_print_string fmt "true"
  | Vnumber num -> print_number fmt num
  | Vstring s -> Format.pp_print_string fmt s

let rec print_expr fmt expr =
  match expr with
  | Evalue v -> print_value fmt v
  | Eident i -> print_ident fmt i
  | Ebinop (bop, e1, e2) ->
    print_expr fmt e1;
    print_binop fmt bop;
    print_expr fmt e2

let print_stmt fmt stmt =
  match stmt with
  | Sblock _b -> print_endline "not implemented"
  | Sprint e ->
    Format.fprintf fmt "print(";
    print_expr fmt e;
    Format.fprintf fmt ")@."

let print_script fmt script =
  List.iter (print_stmt fmt) script

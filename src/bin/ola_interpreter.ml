open Format
open Ola

let debug = ref false

let no_typing = ref false

let in_file_name = ref ""

let set_file s = in_file_name := s

let options =
  [ ("--no-typing", Arg.Set no_typing, " Interprete without typing checks")
  ; ("--debug", Arg.Set debug, " Debug mode")
  ]

let usage =
  "usage: dune exec ./src/bin/ola_interpreter.exe ./test/file_name.lua \
   [options]"

let process source_code_file no_typing debug =
  try
    let ic = open_in source_code_file in
    let lexbuf = Sedlexing.Utf8.from_channel ic in
    Sedlexing.set_filename lexbuf source_code_file;
    let lexer = Sedlexing.with_tokenizer Lexer.token lexbuf in
    let parser =
      MenhirLib.Convert.Simplified.traditional2revised Parser.chunk
    in
    let chunk = parser lexer in
    if debug then begin
      print_endline "debug mode";
      Ast.print_chunk Format.std_formatter chunk
    end;
    if not no_typing then begin
      print_endline "typing checks ...";
      Typer.typecheck chunk
    end;
    print_endline "interprete ...";
    Interpret.run chunk;
    close_in ic
  with
  | Lexer.Lexing_error message ->
    eprintf "Lexical error: %s@." message;
    exit 1
  | Parser.Error ->
    eprintf "Syntax error@.";
    exit 1
  | Typer.Typing_error message ->
    eprintf "Typing error: %s@." message;
    exit 1

(* OLA entry point : Lua language interpreter *)
let _ =
  Arg.parse options set_file usage;
  if !in_file_name = "" then begin
    eprintf "init error: missing test file name to interpret!@.";
    Arg.usage options usage;
    exit 1
  end;
  process !in_file_name !no_typing !debug

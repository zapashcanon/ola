/* Syntactic analyzer */

%{ %}

%token PLUS MINUS MUL LPAREN RPAREN SEMICOLON     // DIV COMMA
%token LT LE GT GE EQ NEQ
%token NOT AND OR
%token DO END WHILE
%token PRINT
%token EOF

%token <Ast.value> VALUE
%token <Ast.ident> IDENT

%left PLUS MINUS
%left MUL      // DIV

// %nonassoc UMINUS

%start chunk

%type <Ast.chunk> chunk
%type <Ast.unop> unop
%type <Ast.binop> binop
%type <Ast.stmt> stmt
%type <Ast.expr> expr
// %type <Ast.stmt list> stmt_list
// %type <Ast.expr list> expr_list

%%

chunk : l=block EOF { l };

block :
     | l=list(stmt) { l }
     ;

stmt :
     | SEMICOLON { Ast.Sempty }
     | DO b=block END { Ast.Sblock b }
     | WHILE e=expr DO b=block END { Ast.Swhile (e, b) }
     | PRINT LPAREN e=expr RPAREN { Ast.Sprint e }          // tmp
     ;

unop :
     | NOT { Ast.Unot }
     | MINUS { Ast.Uminus }
     ;

binop :
     | AND { Ast.Band }
     | OR { Ast.Bor }
     | PLUS { Ast.Badd }
     | MINUS { Ast.Bsub }
     | MUL { Ast.Bmul }
     | LT { Ast.Blt }
     | LE { Ast.Ble }
     | GT { Ast.Bgt }
     | GE { Ast.Bge }
     | EQ { Ast.Beq }
     | NEQ { Ast.Bneq }
     ;

expr :
     | v=VALUE { Ast.Evalue v }
     | i=IDENT { Ast.Eident i }
     | op=unop e=expr { Ast.Eunop (op, e) }
     | e1=expr op=binop e2=expr { Ast.Ebinop (op, e1, e2) }
     ;

// expr_list :
//      | { [] }
//      | e=expr { [e] }
//      | e=expr COMMA l=expr_list { e :: l }
//      | l=separated_list(COMA, expr) { l }
//      | l=list(expr) { l }
//      ;

%%

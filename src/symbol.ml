open Parser
open Parser.MenhirInterpreter

let string_of_token = function
  | WITH            -> "WITH"
  | WHEN            -> "WHEN"
  | VARIABLE        -> "VARIABLE"
  | VAR             -> "VAR"
  | USE             -> "USE"
  | UNDERSCORE      -> "UNDERSCORE"
  | TZ n            -> Printf.sprintf "TZ(%s)" (Big_int.string_of_big_int n)
  | TRUE            -> "TRUE"
  | TRANSITION      -> "TRANSITION"
  | TRANSFER        -> "TRANSFER"
  | TO              -> "TO"
  | THEOREM         -> "THEOREM"
  | THEN            -> "THEN"
  | STRING s        -> Printf.sprintf "STRING(%s)" s
  | STATES          -> "STATES"
  | SPECIFICATION   -> "SPECIFICATION"
  | SORTED          -> "SORTED"
  | SOME            -> "SOME"
  | SHADOW          -> "SHADOW"
  | SEMI_COLON      -> "SEMI_COLON"
  | SECURITY        -> "SECURITY"
  | RPAREN          -> "RPAREN"
  | RETURN          -> "RETURN"
  | REQUIRE         -> "REQUIRE"
  | REFUSE_TRANSFER -> "REFUSE_TRANSFER"
  | REF             -> "REF"
  | RECORD          -> "RECORD"
  | RBRACKET        -> "RBRACKET"
  | RBRACE          -> "RBRACE"
  | RATIONAL (d, n) -> Printf.sprintf "RATIONAL(%s, %s)" (Big_int.string_of_big_int d) (Big_int.string_of_big_int n)
  | POSTCONDITION   -> "POSTCONDITION"
  | PREDICATE       -> "PREDICATE"
  | PLUSEQUAL       -> "PLUSEQUAL"
  | PLUS            -> "PLUS"
  | PIPE            -> "PIPE"
  | PKEY            -> "PKEY"
  | PERCENTRBRACKET -> "PERCENTRBRACKET"
  | PERCENT         -> "PERCENT"
  | PARTITION       -> "PARTITION"
  | OTHERWISE       -> "OTHERWISE"
  | OREQUAL         -> "OREQUAL"
  | OR              -> "OR"
  | OPTION          -> "OPTION"
  | ON              -> "ON"
  | OF              -> "OF"
  | NUMBER n        -> Printf.sprintf "NUMBER(%s)" (Big_int.string_of_big_int n)
  | NOT             -> "NOT"
  | NONE            -> "NONE"
  | NEQUAL          -> "NEQUAL"
  | NAMESPACE       -> "NAMESPACE"
  | MULTEQUAL       -> "MULTEQUAL"
  | MULT            -> "MULT"
  | UTZ n           -> Printf.sprintf "UTZ(%s)" (Big_int.string_of_big_int n)
  | MTZ n           -> Printf.sprintf "MTZ(%s)" (Big_int.string_of_big_int n)
  | MINUSEQUAL      -> "MINUSEQUAL"
  | MINUS           -> "MINUS"
  | MATCH           -> "MATCH"
  | LPAREN          -> "LPAREN"
  | LET             -> "LET"
  | LESSEQUAL       -> "LESSEQUAL"
  | LESS            -> "LESS"
  | LEMMA           -> "LEMMA"
  | LBRACKETPERCENT -> "LBRACKETPERCENT"
  | LBRACKET        -> "LBRACKET"
  | LBRACE          -> "LBRACE"
  | LABEL           -> "LABEL"
  | ITER            -> "ITER"
  | INVARIANT       -> "INVARIANT"
  | INVALID_EXPR    -> "INVALID_EXPR"
  | INVALID_EFFECT  -> "INVALID_EFFECT"
  | INVALID_DECL    -> "INVALID_DECL"
  | INITIALIZED     -> "INITIALIZED"
  | INITIAL         -> "INITIAL"
  | IN              -> "IN"
  | IMPLY           -> "IMPLY"
  | IF              -> "IF"
  | IDENTIFIED      -> "IDENTIFIED"
  | IDENT s         -> Printf.sprintf "IDENT(%s)" s
  | GREATEREQUAL    -> "GREATEREQUAL"
  | GREATER         -> "GREATER"
  | FUNCTION        -> "FUNCTION"
  | FROM            -> "FROM"
  | FORALL          -> "FORALL"
  | FOR             -> "FOR"
  | FALSE           -> "FALSE"
  | FAILIF          -> "FAILIF"
  | EXTENSION       -> "EXTENSION"
  | EXISTS          -> "EXISTS"
  | EQUIV           -> "EQUIV"
  | EQUAL           -> "EQUAL"
  | EOF             -> "EOF"
  | ENUM            -> "ENUM"
  | END             -> "END"
  | ELSE            -> "ELSE"
  | EFFECT          -> "EFFECT"
  | DURATION s      -> Printf.sprintf "DURATION(%s)" s
  | DO              -> "DO"
  | DONE            -> "DONE"
  | DOT             -> "DOT"
  | DIVEQUAL        -> "DIVEQUAL"
  | DIV             -> "DIV"
  | DEFINITION      -> "DEFINITION"
  | DATE s          -> Printf.sprintf "DATE(%s)" s
  | CONTRACT        -> "CONTRACT"
  | CONSTANT        -> "CONSTANT"
  | COMMA           -> "COMMA"
  | COLONEQUAL      -> "COLONEQUAL"
  | COLON           -> "COLON"
  | COLLECTION      -> "COLLECTION"
  | CALLED          -> "CALLED"
  | BY              -> "BY"
  | BUT             -> "BUT"
  | BREAK           -> "BREAK"
  | BEFORE          -> "BEFORE"
  | AT_UPDATE       -> "AT_UPDATE"
  | AT_REMOVE       -> "AT_REMOVE"
  | AT_ADD          -> "AT_ADD"
  | AT              -> "AT"
  | ASSET           -> "ASSET"
  | ASSERT          -> "ASSERT"
  | ARCHETYPE       -> "ARCHETYPE"
  | ANDEQUAL        -> "ANDEQUAL"
  | AND             -> "AND"
  | ADDRESS s       -> Printf.sprintf "DURATION(%s)" s
  | ACTION          -> "ACTION"
  | ACCEPT_TRANSFER -> "ACCEPT_TRANSFER"

let string_of_symbol = function
  | X (T T_error) -> "error"
  | X (T T_WITH) -> "with"
  | X (T T_WHEN) -> "when"
  | X (T T_VAR) -> "var"
  | X (T T_VARIABLE) -> "variable"
  | X (T T_USE) -> "use"
  | X (T T_UNDERSCORE) -> "_"
  | X (T T_TZ) -> "a tz"
  | X (T T_TRUE) -> "true"
  | X (T T_TRANSITION) -> "transition"
  | X (T T_TRANSFER) -> "transfer"
  | X (T T_TO) -> "to"
  | X (T T_THEOREM) -> "theorem"
  | X (T T_THEN) -> "then"
  | X (T T_STRING) -> "a string"
  | X (T T_STATES) -> "states"
  | X (T T_SPECIFICATION) -> "postcondition"
  | X (T T_SORTED) -> "sorted"
  | X (T T_SOME) -> "some"
  | X (T T_SHADOW) -> "shadow"
  | X (T T_SEMI_COLON) -> ";"
  | X (T T_SECURITY) -> "security"
  | X (T T_RPAREN) -> ")"
  | X (T T_RETURN) -> "return"
  | X (T T_REQUIRE) -> "require"
  | X (T T_REFUSE_TRANSFER) -> "refuse transfer"
  | X (T T_REF) -> "ref"
  | X (T T_RECORD) -> "record"
  | X (T T_RBRACKET) -> "]"
  | X (T T_RBRACE) -> "}"
  | X (T T_RATIONAL) -> "rational"
  | X (T T_PREDICATE) -> "predicate"
  | X (T T_POSTCONDITION) -> "postcondition"
  | X (T T_PLUSEQUAL) -> "+="
  | X (T T_PLUS) -> "+"
  | X (T T_PIPE) -> "|"
  | X (T T_PKEY) -> "pkey"
  | X (T T_PERCENTRBRACKET) -> "%]"
  | X (T T_PERCENT) -> "%"
  | X (T T_PARTITION) -> "partition"
  | X (T T_OTHERWISE) -> "otherwise"
  | X (T T_OREQUAL) -> "|="
  | X (T T_OR) -> "or"
  | X (T T_OPTION) -> "option"
  | X (T T_ON) -> "on"
  | X (T T_OF) -> "of"
  | X (T T_NUMBER) -> "a number"
  | X (T T_NOT) -> "not"
  | X (T T_NONE) -> "none"
  | X (T T_NEQUAL) -> "<>"
  | X (T T_NAMESPACE) -> "namespace"
  | X (T T_MULTEQUAL) -> "*="
  | X (T T_MULT) -> "*"
  | X (T T_MTZ) -> "a mtz"
  | X (T T_UTZ) -> "a utz"
  | X (T T_MINUSEQUAL) -> "-="
  | X (T T_MINUS) -> "-"
  | X (T T_MATCH) -> "match"
  | X (T T_LPAREN) -> "("
  | X (T T_LET) -> "let"
  | X (T T_LESSEQUAL) -> "<="
  | X (T T_LESS) -> "<"
  | X (T T_LEMMA) -> "lemma"
  | X (T T_LBRACKETPERCENT) -> "[%"
  | X (T T_LBRACKET) -> "["
  | X (T T_LBRACE) -> "{"
  | X (T T_LABEL) -> "label"
  | X (T T_ITER) -> "iter"
  | X (T T_INVARIANT) -> "invariant"
  | X (T T_INVALID_EXPR) -> "invalid-expression"
  | X (T T_INVALID_EFFECT) -> "invalid-effect"
  | X (T T_INVALID_DECL) -> "invalid-declaration"
  | X (T T_INITIALIZED) -> "initialized"
  | X (T T_INITIAL) -> "initial"
  | X (T T_IN) -> "in"
  | X (T T_IMPLY) -> "->"
  | X (T T_IF) -> "if"
  | X (T T_IDENTIFIED) -> "identified"
  | X (T T_IDENT) -> "an ident"
  | X (T T_GREATEREQUAL) -> ">="
  | X (T T_GREATER) -> ">"
  | X (T T_FUNCTION) -> "function"
  | X (T T_FROM) -> "from"
  | X (T T_FORALL) -> "forall"
  | X (T T_FOR) -> "for"
  | X (T T_FALSE) -> "false"
  | X (T T_FAILIF) -> "failif"
  | X (T T_EXTENSION) -> "extension"
  | X (T T_EXISTS) -> "exists"
  | X (T T_EQUIV) -> "<->"
  | X (T T_EQUAL) -> "="
  | X (T T_EOF) -> "end-of-file"
  | X (T T_ENUM) -> "enum"
  | X (T T_END) -> "end"
  | X (T T_ELSE) -> "else"
  | X (T T_EFFECT) -> "effect"
  | X (T T_DURATION) -> "duration"
  | X (T T_DO) -> "do"
  | X (T T_DONE) -> "done"
  | X (T T_DOT) -> "."
  | X (T T_DIVEQUAL) -> "/="
  | X (T T_DIV) -> "/"
  | X (T T_DEFINITION) -> "definition"
  | X (T T_DATE) -> "a date"
  | X (T T_CONTRACT) -> "contract"
  | X (T T_CONSTANT) -> "constant"
  | X (T T_COMMA) -> ","
  | X (T T_COLONEQUAL) -> ":="
  | X (T T_COLON) -> ":"
  | X (T T_COLLECTION) -> "collection"
  | X (T T_CALLED) -> "called"
  | X (T T_BY) -> "by"
  | X (T T_BUT) -> "but"
  | X (T T_BREAK) -> "break"
  | X (T T_BEFORE) -> "before"
  | X (T T_AT_UPDATE) -> "@update"
  | X (T T_AT_REMOVE) -> "@remove"
  | X (T T_AT_ADD) -> "@add"
  | X (T T_AT) -> "at"
  | X (T T_ASSET) -> "asset"
  | X (T T_ASSERT) -> "assert"
  | X (T T_ARCHETYPE) -> "archetype"
  | X (T T_ANDEQUAL) -> "&="
  | X (T T_AND) -> "and"
  | X (T T_ADDRESS) -> "an address"
  | X (T T_ACTION) -> "action"
  | X (T T_ACCEPT_TRANSFER) -> "accept address"
  | X (N N_specification_fun) -> "a specification function"
  | X (N N_specification_decl) -> "a specification declaration"
  | X (N N_spec_items) -> "a list of specification item"
  | X (N N_vc_decl_VARIABLE_) -> "a variable declaration"
  | X (N N_vc_decl_CONSTANT_) -> "a constant declaration"
  | X (N N_variable) -> "a variable"
  | X (N N_types) -> "types"
  | X (N N_type_s_unloc) -> "types"
  | X (N N_type_r) -> "a type"
  | X (N N_list_loc_spec_variable__) -> "a list of specification variable item"
  | X (N N_list_loc_spec_theorem__) -> "a list of specification theorem item"
  | X (N N_list_loc_spec_postcondition__) -> "a list of specification postcondition item"
  | X (N N_list_loc_spec_predicate__ ) -> "a list of specification predicate item"
  | X (N N_list_loc_spec_lemma__) -> "a list of specification lemma item"
  | X (N N_list_loc_spec_effect__) -> "a list of specification effect item"
  | X (N N_list_loc_spec_definition__) -> "a list of specification definition item"
  | X (N N_list_loc_spec_assert__) -> "a list of specification assert item"
  | X (N N_transition_to_item) -> "a transition to item"
  | X (N N_transition) -> "a transition"
  | X (N N_start_expr) -> "a start expression"
  | X (N N_snl2_COMMA_simple_expr_) -> "a non empty list of simple expression separated by  ,"
  | X (N N_snl2_OR_security_arg_) -> "a non empty list of security argument separated by  OR"
  | X (N N_security_arg_unloc) -> "a security argument"
  | X (N N_security_decl_unloc) -> "a security declaration"
  | X (N N_security_decl) -> "a security declaration"
  | X (N N_simple_expr_r) -> "a simple expression"
  | X (N N_signature) -> "a signature"
  | X (N N_separated_nonempty_list_SEMI_COLON_record_item_) -> "a non empty list of record item by ;"
  | X (N N_separated_nonempty_list_COMMA_type_t_) -> "a non empty list of type separated by ,"
  | X (N N_separated_nonempty_list_COMMA_security_arg_) -> "a non empty list of security arg"
  | X (N N_require) -> "a require"
  | X (N N_record_item) -> "a record item"
  | X (N N_pattern) -> "a pattern"
  | X (N N_order_operations) -> "order operations"
  | X (N N_order_operation) -> "an order operation"
  | X (N N_option_with_effect_) -> "a with effect option"
  | X (N N_option_specification_fun_) -> "a specification function option"
  | X (N N_option_simple_expr_) -> "a simple expression option"
  | X (N N_option_require_value_) -> "a require option"
  | X (N N_option_require_) -> "a require option"
  | X (N N_option_on_value_) -> "a on value option"
  | X (N N_option_function_return_) -> "a function return option"
  | X (N N_option_failif_) -> "a failif option"
  | X (N N_option_extensions_) -> "extensions option"
  | X (N N_option_effect_) -> "an effect option"
  | X (N N_option_default_value_) -> "a default value option"
  | X (N N_option_calledby_) -> "a call by option"
  | X (N N_option_bracket_asset_operation__) -> "a list of asset operation"
  | X (N N_option_asset_options_) -> "assets option"
  | X (N N_option_asset_fields_) -> "asset fields option"
  | X (N N_on_value) -> "on value"
  | X (N N_nonempty_list_type_tuple_) -> "a non empty list of type tuple"
  | X (N N_nonempty_list_transition_to_item_) -> "a non empty list of transition to item"
  | X (N N_nonempty_list_signature_) -> "a non empty list of signature"
  | X (N N_nonempty_list_pipe_ident_) -> "a non empty list of pipe identifier"
  | X (N N_nonempty_list_loc_pattern__) -> "a non empty list of pattern"
  | X (N N_nonempty_list_ident_typ_q_item_) -> "a non empty list of typed identifier"
  | X (N N_nonempty_list_ident_) -> "a non empty list of identifier"
  | X (N N_nonempty_list_function_arg_) -> "a non empty list of function argument"
  | X (N N_nonempty_list_extension_) -> "a non empty list of extension"
  | X (N N_nonempty_list_enum_option_) -> "a non empty list of enum"
  | X (N N_nonempty_list_declaration_) -> "a non empty list of declaration"
  | X (N N_nonempty_list_branch_) -> "a non empty list of branch"
  | X (N N_nonempty_list_asset_option_) -> "a non empty list of asset option"
  | X (N N_nonempty_list_asset_operation_enum_) -> "a non empty list of asset operation enum"
  | X (N N_namespace) -> "a namespace"
  | X (N N_main) -> "archetype"
  | X (N N_loption_separated_nonempty_list_COMMA_security_arg__) -> "a non empty list of security arg"
  | X (N N_literal) -> "a literal"
  | X (N N_list_function_item_) -> "a list of item function"
  | X (N N_list_invars_) -> "a list of invariants"
  | X (N N_list_asset_post_option_) -> "a list of asset post option"
  | X (N N_implementation_archetype) -> "an archetype implementation"
  | X (N N_ident_typ_q) -> "an item of type"
  | X (N N_function_item) -> "an item function"
  | X (N N_function_decl) -> "a function declaration"
  | X (N N_field_r) -> "a field"
  | X (N N_failif) -> "a failif"
  | X (N N_extension_r) -> "an extension"
  | X (N N_expr_r) -> "an expression"
  | X (N N_equal_enum_values) -> "enum values with equal operator"
  | X (N N_enum_values) -> "enum values"
  | X (N N_enum_option) -> "an enum option"
  | X (N N_enum) -> "an enum"
  | X (N N_effect) -> "an effect"
  | X (N N_dextension) -> "a extension declaration"
  | X (N N_declaration_r) -> "a declaration"
  | X (N N_contract) -> "a contract"
  | X (N N_constant) -> "a constant"
  | X (N N_calledby) -> "called by"
  | X (N N_branch) -> "branch"
  | X (N N_boption_REF_) -> "ref option"
  | X (N N_asset_post_option) -> "asset post option"
  | X (N N_asset_option) -> "an asset option"
  | X (N N_asset) -> "an asset"
  | X (N N_archetype_r) -> "archetype"
  | X (N N_archetype_extension) -> "an extension"
  | X (N N_archetype) -> "archetype"
  | X (N N_action_properties) -> "action properties"
  | X (N N_action) -> "an action"
  | X (N N_snl_SEMI_COLON_security_item_) -> "a non empty list of security item"
  | X (N N_sl_SEMI_COLON_security_item_) -> "a list of security item"
  | X (N N_snl_SEMI_COLON_field_) -> "a non empty list of field"
  | X (N N_sl_SEMI_COLON_field_) -> "a list of field"
  | X (N N_snl_SEMI_COLON_label_expr_) -> "a non empty list of label expr"
  | X (N N_label_expr_unloc) -> "a label expr"
  | X (N N_snl_COMMA_security_arg_) -> "a non empty list of security argument"
  | X (N N_sl_COMMA_security_arg_) -> "a list of security argument"

let string_of_item (p, i) =
  string_of_symbol (lhs p) ^ " -> "
  ^ String.concat " " (
    List.mapi (fun j s ->
        (if j = i then "." else "") ^ string_of_symbol s)
      (rhs p))
  ^ (if i = List.length (rhs p) then "." else "")

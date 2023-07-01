%{
	#include "lslmini.hh"
	#include "logger.hh"
	#include <stdio.h>
	#include <string.h>
	//int yylex(YYSTYPE *yylval_param, YYLTYPE *yylloc_param);
	extern int yylex (YYSTYPE * yylval_param,YYLTYPE * yylloc_param , void *yyscanner);

	LLScriptScript *script;
	int yyerror( YYLTYPE*, void *, const char * );
	#define MAKEID(type,id,pos) new LLScriptIdentifier(TYPE(type), (id), &(pos))

	#define LSLINT_STACK_OVERFLOW_AT 150
	inline int _yylex( YYSTYPE * yylval, YYLTYPE *yylloc, void *yyscanner, int stack ) {
		return yylex( yylval, yylloc, yyscanner );
	}
	#define yylex(a,b,c) _yylex(a, b, c,  (int)(yyssp - yyss))


	// Same as bison's default, but update global position so we don't have
	// to pass it in every time we make a branch
	# define YYLLOC_DEFAULT(Current, Rhs, N)				\
		((Current).first_line   = (Rhs)[1].first_line,		\
		 (Current).first_column = (Rhs)[1].first_column,	\
		 (Current).last_line    = (Rhs)[N].last_line,		\
		 (Current).last_column  = (Rhs)[N].last_column,		\
		 LLASTNode::set_glloc(&(Current)))

	enum simple_recurse_mode { SIMPLE_ANY, SIMPLE_LIST };
	static LLScriptSimpleAssignable *getSimpleAssignable(LLScriptExpression *expression, simple_recurse_mode mode = SIMPLE_ANY);

%}

%define parse.error verbose
%locations
%define api.pure
%parse-param { void *scanner }
%lex-param { void *scanner }

%union
{
	S32								ival;
	F32								fval;
	char							*sval;
	class LLScriptType				*type;
	class LLScriptConstant			*constant;
	class LLScriptIdentifier		*identifier;
	class LLScriptSimpleAssignable	*assignable;
	class LLScriptGlobalVariable	*global;
	class LLScriptEventHandler		*handler;
	class LLScriptExpression		*expression;
	class LLScriptStatement			*statement;
	class LLScriptGlobalFunction	*global_funcs;
	class LLScriptFunctionDec		*global_decl;
	class LLScriptEventDec			*global_event_decl;
	class LLScriptState				*state;
	class LLScriptGlobalStorage		*global_store;
	class LLScriptScript			*script;
};

%initial-action
{
	script = new LLScriptScript();
	script->define_builtins();
};


%token					INTEGER
%token					FLOAT_TYPE
%token					STRING
%token					LLKEY
%token					VECTOR
%token					QUATERNION
%token					LIST

%token					STATE
%token					EVENT
%token					JUMP
%token					RETURN

%token					SWITCH
%token					CASE
%token					BREAK

%token <sval>			IDENTIFIER
%token <sval>			STATE_DEFAULT

%token <ival>			INTEGER_CONSTANT
%token <ival>			INTEGER_TRUE
%token <ival>			INTEGER_FALSE

%token <fval>			FP_CONSTANT

%token <sval>			STRING_CONSTANT

%token					INC_OP
%token					DEC_OP
%token					POSTINC_OP
%token					POSTDEC_OP
%token					ADD_ASSIGN
%token					SUB_ASSIGN
%token					MUL_ASSIGN
%token					DIV_ASSIGN
%token					MOD_ASSIGN

%token					EQ
%token					NEQ
%token					GEQ
%token					LEQ

%token					BOOLEAN_AND
%token					BOOLEAN_OR

%token					SHIFT_LEFT
%token					SHIFT_RIGHT

%token					IF
%token					ELSE
%token					FOR
%token					DO
%token					WHILE

%token					PRINT

%token					PERIOD

%token					ZERO_VECTOR
%token					ZERO_ROTATION

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%type <script>			lscript_program
%type <global_store>	globals
%type <global_store>	global
%type <global>			global_variable
%type <constant>		constant
%type <type>			typename
%type <global_funcs>	global_function
%type <global_decl>		function_parameters
%type <global_decl>		function_parameter
%type <global_event_decl>		event_parameters
%type <global_event_decl>		event_parameter
%type <state>			states
%type <state>			other_states
%type <state>			default
%type <state>			state
%type <handler>			state_body
%type <handler>			event
%type <statement>		compound_statement
%type <statement>		statement
%type <statement>		statements
%type <statement>		declaration
%type <statement>		';'
%type <statement>		'@'
%type <expression>		nextforexpressionlist
%type <expression>		forexpressionlist
%type <expression>		nextfuncexpressionlist
%type <expression>		funcexpressionlist
%type <expression>		nextlistexpressionlist
%type <expression>		listexpressionlist
%type <expression>		unarypostfixexpression
%type <expression>		vector_initializer
%type <expression>		quaternion_initializer
%type <expression>		list_initializer
%type <expression>		lvalue
%type <expression>		'-'
%type <expression>		'!'
%type <expression>		'~'
%type <expression>		'='
%type <expression>		'<'
%type <expression>		'>'
%type <expression>		'+'
%type <expression>		'*'
%type <expression>		'/'
%type <expression>		'%'
%type <expression>		'&'
%type <expression>		'|'
%type <expression>		'^'
%type <expression>		ADD_ASSIGN
%type <expression>		SUB_ASSIGN
%type <expression>		MUL_ASSIGN
%type <expression>		DIV_ASSIGN
%type <expression>		MOD_ASSIGN
%type <expression>		EQ
%type <expression>		NEQ
%type <expression>		LEQ
%type <expression>		GEQ
%type <expression>		BOOLEAN_AND
%type <expression>		BOOLEAN_OR
%type <expression>		SHIFT_LEFT
%type <expression>		SHIFT_RIGHT
%type <expression>		INC_OP
%type <expression>		DEC_OP
%type <expression>		'('
%type <expression>		')'
%type <expression>		PRINT
%type <identifier>		name_type
%type <expression>		expression
%type <expression>		unaryexpression
%type <expression>		typecast
// TODO
%type <statement>		switch_body
%type <statement>		case_block

%nonassoc INTEGER_CONSTANT FP_CONSTANT // solves 'expression FP_CONSTANT' conflicts
%right '=' MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN
%left 	BOOLEAN_AND BOOLEAN_OR
%left	'|'
%left	'^'
%left	'&'
%left	EQ NEQ
%left	'<' LEQ '>' GEQ
%left	SHIFT_LEFT SHIFT_RIGHT
%left 	'+' '-'
%left	'*' '/' '%'
%right	'!' '~' INC_OP DEC_OP
%nonassoc INITIALIZER

%%

lscript_program
	: globals states
	{
		script->push_child($1);
		script->push_child($2);
	}
	| states
	{
		script->push_child(new LLASTNullNode());
		script->push_child($1);
	}
	;

globals
	: global
	{
		DEBUG( LOG_DEBUG_SPAM, NULL, "** global\n");
		$$ = $1;
	}
	| global globals
	{
		if ( $1 && $2 ) {
			DEBUG( LOG_DEBUG_SPAM, NULL, "** global [%p,%p] globals [%p,%p]\n", $1->get_prev(), $1->get_next(), $2->get_prev(), $2->get_next());
			$1->add_next_sibling($2);
			$$ = $1;
		} else {
			$$ = $2 ? $2 : $1;
		}
	}
	;

global
	: global_variable
	{
		$$ = new LLScriptGlobalStorage($1, NULL);
	}
	| global_function
	{
		$$ = new LLScriptGlobalStorage(NULL, $1);
	}
	| error ';'
	{
		$$ = NULL;
	}
	;

name_type
	: typename IDENTIFIER
	{
		$$ = new LLScriptIdentifier($1, $2, &@2);
	}
	;

global_variable
	: name_type ';'
	{
		$$ = new LLScriptGlobalVariable($1, NULL);
	}
	| name_type '=' expression ';'
	{
		LLScriptSimpleAssignable *sa = getSimpleAssignable($3);
		if (sa) {
			$$ = new LLScriptGlobalVariable($1, sa);
		} else {
			ERROR(&@3, E_GLOBAL_INITIALIZER_NOT_CONSTANT);
			$$ = NULL;
		}
	}
	| name_type error ';'
	{
		$$ = new LLScriptGlobalVariable($1, NULL);
	}
	;

constant
	: INTEGER_CONSTANT
	{
		$$ = new LLScriptIntegerConstant($1);
	}
	| INTEGER_TRUE
	{
		$$ = new LLScriptIntegerConstant($1, true);
	}
	| INTEGER_FALSE
	{
		$$ = new LLScriptIntegerConstant($1, true);
	}
	| FP_CONSTANT
	{
		$$ = new LLScriptFloatConstant($1);
	}
	| STRING_CONSTANT
	{
		$$ = new LLScriptStringConstant($1);
	}
	;

typename
	: INTEGER
	{
		$$ = TYPE(LST_INTEGER);
	}
	| FLOAT_TYPE
	{
		$$ = TYPE(LST_FLOATINGPOINT);
	}
	| STRING
	{
		$$ = TYPE(LST_STRING);
	}
	| LLKEY
	{
		$$ = TYPE(LST_KEY);
	}
	| VECTOR
	{
		$$ = TYPE(LST_VECTOR);
	}
	| QUATERNION
	{
		$$ = TYPE(LST_QUATERNION);
	}
	| LIST
	{
		$$ = TYPE(LST_LIST);
	}
	;

global_function
	: IDENTIFIER '(' ')' compound_statement
	{
		$$ = new LLScriptGlobalFunction( MAKEID(LST_NULL, $1, @1), NULL, $4 );
	}
	| name_type '(' ')' compound_statement
	{
		$$ = new LLScriptGlobalFunction( $1, NULL, $4 );
	}
	| IDENTIFIER '(' function_parameters ')' compound_statement
	{
		$$ = new LLScriptGlobalFunction( MAKEID(LST_NULL, $1, @1), $3, $5 );
	}
	| name_type '(' function_parameters ')' compound_statement
	{
		$$ = new LLScriptGlobalFunction( $1, $3, $5 );
	}
	;

function_parameters
	: function_parameter
	{
		$$ = $1;
	}
	| function_parameter ',' function_parameters
	{
		if ( $1 ) {
			$1->push_child($3->get_children());
			delete $3;
			$$ = $1;
		} else {
			$$ = $3;
		}
	}
	;

function_parameter
	: typename IDENTIFIER
	{
		$$ = new LLScriptFunctionDec( new LLScriptIdentifier($1, $2, &@2) );
	}
	;

event_parameters
	: event_parameter
	{
		$$ = $1;
	}
	| event_parameter ',' event_parameters
	{
		if ( $1 ) {
			$1->push_child($3->get_children());
			delete $3;
			$$ = $1;
		} else {
			$$ = $3;
		}
	}
	;

event_parameter
	: typename IDENTIFIER
	{
		$$ = new LLScriptEventDec( new LLScriptIdentifier($1, $2, &@2) );
	}
	;

states
	: default
	{
		$$ = $1;
	}
	| default other_states
	{
		if ( $1 ) {
			DEBUG( LOG_DEBUG_SPAM, NULL, "---- default [%p,%p] other_states [%p,%p]\n", $1->get_prev(), $1->get_next(), $2->get_prev(), $2->get_next());
			$1->add_next_sibling($2);
			$$ = $1;
		} else {
			$$ = $2;
		}
	}
	;

other_states
	: state
	{
		//DEBUG(200,"--(%d)-- state\n", yylloc.first_line);
		$$ = $1;
	}
	| state other_states
	{
		//DEBUG(200,"--(%d)-- state other_states\n", yylloc.first_line);
		if ( $1 ) {
			$1->add_next_sibling($2);
			$$ = $1;
		} else {
			$$ = $2;
		}
	}
	;

default
	: STATE_DEFAULT '{' state_body '}'
	{
		$$ = new LLScriptState( NULL, $3 );
	}
	| STATE_DEFAULT '{' '}'
	{
		ERROR( &@1, E_NO_EVENT_HANDLERS );
		$$ = new LLScriptState( NULL, NULL );
	}
	;

state
	: STATE IDENTIFIER '{' state_body '}'
	{
		$$ = new LLScriptState( MAKEID(LST_NULL, $2, @2), $4 );
	}
	| STATE IDENTIFIER '{' '}'
	{
		ERROR( &@1, E_NO_EVENT_HANDLERS );
		$$ = new LLScriptState( NULL, NULL );
	}
	;

state_body
	: event
	{
		$$ = $1;
	}
	| event state_body
	{
		if ( $1 ) {
			$1->add_next_sibling($2);
			$$ = $1;
		} else {
			$$ = $2;
		}
	}
	;

event
	: IDENTIFIER '(' ')' compound_statement
	{
		$$ = new LLScriptEventHandler(MAKEID(LST_NULL, $1, @1), NULL, $4);
	}
	| IDENTIFIER '(' event_parameters ')' compound_statement
	{
		$$ = new LLScriptEventHandler(MAKEID(LST_NULL, $1, @1), $3, $5);
	}
	;

compound_statement
	: '{' '}'
	{
		$$ = new LLScriptStatement(0);
	}
	| '{' statements '}'
	{
		$$ = new LLScriptCompoundStatement($2);
	}
	| '{' error '}'
	{
		$$ = new LLScriptStatement(0);
	}
	| '{' statements error '}'
	{
		$$ = new LLScriptCompoundStatement($2);
	}
	;

statements
	: statement
	{
		//DEBUG( LOG_DEBUG_SPAM, NULL, "statement %d\n", yylloc.first_line );
		$$ = $1;
	}
	| statements statement
	{
		if ( $1 ) {
			$1->add_next_sibling($2);
			$$ = $1;
		} else {
			$$ = $2;
		}
	}
	;

statement
	: ';'
	{
		$$ = new LLScriptStatement(0);
	}
	| STATE IDENTIFIER ';'
	{
		$$ = new LLScriptStateStatement(MAKEID(LST_NULL, $2, @2));
	}
	| STATE STATE_DEFAULT ';'
	{
		$$ = new LLScriptStateStatement();
	}
	| JUMP IDENTIFIER ';'
	{
		$$ = new LLScriptJumpStatement(MAKEID(LST_NULL, $2, @2));
	}
	| '@' IDENTIFIER ';'
	{
		$$ = new LLScriptLabel(MAKEID(LST_NULL, $2, @2));
	}
	| RETURN expression ';'
	{
		$$ = new LLScriptReturnStatement($2);
	}
	| RETURN ';'
	{
		$$ = new LLScriptReturnStatement(NULL);
	}
	| expression ';'
	{
		$$ = new LLScriptStatement($1);
	}
	| declaration ';'
	{
		$$ = $1;
	}
	| compound_statement
	{
		$$ = $1;
	}
	| IF '(' expression ')' statement	%prec LOWER_THAN_ELSE
	{
		$$ = new LLScriptIfStatement($3, $5, NULL);
	}
	| IF '(' expression ')' statement ELSE statement
	{
		$$ = new LLScriptIfStatement($3, $5, $7);
	}
	| FOR '(' forexpressionlist ';' expression ';' forexpressionlist ')' statement
	{
		$$ = new LLScriptForStatement($3, $5, $7, $9);
	}
	| DO statement WHILE '(' expression ')' ';'
	{
		$$ = new LLScriptDoStatement($2, $5);
	}
	| WHILE '(' expression ')' statement
	{
		$$ = new LLScriptWhileStatement($3, $5);
	}
	| SWITCH '(' expression ')' '{' switch_body '}'
	{
		$$ = new LLScriptSwitchStatement($3, $6);
	}
	| SWITCH '(' expression ')' '{' statements switch_body '}'
	{
		ERROR(&@6, W_STATEMENTS_BEFORE_CASE);
		$$ = new LLScriptSwitchStatement($3, $7);
	}
	| BREAK ';'
	{
		$$ = new LLScriptBreakStatement();
	}
	| declaration error ';'
	{
		$$ = $1;
	}
	| error ';'
	{
		$$ = new LLScriptStatement(0);
	}
	;

switch_body
	: case_block
	{
		$$ = $1;
	}
	| switch_body case_block
	{
		$1->add_next_sibling($2);
		$$ = $1;
	}
	;

case_block
	: STATE_DEFAULT ':'
	{
		$$ = new LLScriptCaseBlock(NULL, NULL);
	}
	| STATE_DEFAULT ':' statements
	{
		$$ = new LLScriptCaseBlock(NULL, $3);
	}
	| STATE_DEFAULT compound_statement // FS syntax extension
	{
		$$ = new LLScriptCaseBlock(NULL, $2);
	}
	| CASE expression ':'
	{
		$$ = new LLScriptCaseBlock($2, NULL);
	}
	| CASE expression ':' statements
	{
		$$ = new LLScriptCaseBlock($2, $4);
	}
	| CASE expression compound_statement // FS syntax extension
	{
		$$ = new LLScriptCaseBlock($2, $3);
	}
	;

declaration
	: typename IDENTIFIER
	{
		$$ = new LLScriptDeclaration(new LLScriptIdentifier($1, $2, &@2), NULL);
	}
	| typename IDENTIFIER '=' expression
	{
		DEBUG( LOG_DEBUG_SPAM, NULL, "= %s\n", $4->get_node_name());
		$$ = new LLScriptDeclaration(new LLScriptIdentifier($1, $2, &@2), $4);
	}
	| typename IDENTIFIER '=' error
	{
		$$ = new LLScriptDeclaration(new LLScriptIdentifier($1, $2, &@2), NULL);
	}
	;

forexpressionlist
	: /* empty */
	{
		//$$ = new LLScriptExpression(0, NULL, NULL);
		$$ = NULL;
	}
	| nextforexpressionlist
	{
		$$ = new LLScriptExpression(1, $1);
	}
	;

nextforexpressionlist
	: expression
	{
		$$ = $1;
	}
	| expression ',' nextforexpressionlist
	{
		if ( $1 ) {
			$1->add_next_sibling($3);
			$$ = $1;
		} else {
			$$ = $3;
		}
	}
	;

funcexpressionlist
	: /* empty */
	{
		//$$ = new LLScriptExpression(0);
		$$ = NULL;
	}
	| nextfuncexpressionlist
	{
		$$ = $1;
	}
	;

nextfuncexpressionlist
	: expression
	{
		$$ = $1;
	}
	| expression ',' nextfuncexpressionlist
	{
		if ( $1 ) {
			$1->add_next_sibling($3);
			$$ = $1;
		} else {
			$$ = $3;
		}
	}
	;

listexpressionlist
	: /* empty */
	{
		//$$ = new LLScriptExpression(0);
		//$$ = NULL;
		$$ = NULL;
	}
	| nextlistexpressionlist
	{
		$$ = $1;
	}
	;

nextlistexpressionlist
	: expression
	{
		$$ = $1;
	}
	| expression ',' nextlistexpressionlist
	{
		if ($1) {
			$1->add_next_sibling($3);
			$$ = $1;
		} else {
			$$ = $3;
		}
	}
	;

expression
	: unaryexpression
	{
		$$ = $1;
	}
	| lvalue '=' expression
	{
		$$ = new LLScriptExpression( $1, '=', $3 );
	}
	| IDENTIFIER '[' expression ']' '=' expression
	{
		if (! lazy_lists) {
			ERROR( &@2, E_SYNTAX_ERROR, "Unexpected '[' - did you forget to activate lazy lists?" );
			// Ignore the [expression] part and treat it as IDENTIFIER = $6 - that will cause further errors
			$$ = new LLScriptExpression( new LLScriptLValueExpression(new LLScriptIdentifier($1)), '=', $6 );
		} else {
			// Convert the assignment into a function call to lazy_list_set
			char *lazy_list_set = new char[14];
			strcpy(lazy_list_set, "lazy_list_set");
			LLScriptExpression *params = new LLScriptLValueExpression(new LLScriptIdentifier($1));
			params->add_next_sibling($3);
			params->add_next_sibling(new LLScriptListExpression($6));
			$$ = new LLScriptExpression( new LLScriptLValueExpression(new LLScriptIdentifier($1)), '=',
				new LLScriptFunctionExpression(new LLScriptIdentifier(lazy_list_set), params)
			);
		}
	}
	| lvalue ADD_ASSIGN expression
	{
		// TODO: clean these up
		$$ = new LLScriptExpression( $1,'=', new LLScriptExpression(new LLScriptLValueExpression(new LLScriptIdentifier((LLScriptIdentifier*)$1->get_child(0))), '+', $3) );
	}
	| lvalue SUB_ASSIGN expression
	{
		$$ = new LLScriptExpression( $1, '=', new LLScriptExpression(new LLScriptLValueExpression(new LLScriptIdentifier((LLScriptIdentifier*)$1->get_child(0))), '-', $3) );
	}
	| lvalue MUL_ASSIGN expression
	{
		$$ = new LLScriptExpression( $1, '=', new LLScriptExpression(new LLScriptLValueExpression(new LLScriptIdentifier((LLScriptIdentifier*)$1->get_child(0))), '*', $3) );
	}
	| lvalue DIV_ASSIGN expression
	{
		$$ = new LLScriptExpression( $1, '=', new LLScriptExpression(new LLScriptLValueExpression(new LLScriptIdentifier((LLScriptIdentifier*)$1->get_child(0))), '/', $3) );
	}
	| lvalue MOD_ASSIGN expression
	{
		$$ = new LLScriptExpression( $1, '=', new LLScriptExpression(new LLScriptLValueExpression(new LLScriptIdentifier((LLScriptIdentifier*)$1->get_child(0))), '%', $3) );
	}
	| expression EQ expression
	{
		$$ = new LLScriptExpression( $1, EQ, $3 );
	}
	| expression NEQ expression
	{
		$$ = new LLScriptExpression( $1, NEQ, $3 );
	}
	| expression LEQ expression
	{
		// (A <= B) is equivalent to !(A > B)
		$$ = new LLScriptExpression(new LLScriptExpression( $1, '>', $3 ), '!');
	}
	| expression GEQ expression
	{
		// (A >= B) is equivalent to !(A < B)
		$$ = new LLScriptExpression(new LLScriptExpression( $1, '<', $3 ), '!');
	}
	| expression '<' expression
	{
		$$ = new LLScriptExpression( $1, '<', $3 );
	}
	| expression '>' expression
	{
		$$ = new LLScriptExpression( $1, '>', $3 );
	}
	| expression '+' expression
	{
		$$ = new LLScriptExpression( $1, '+', $3 );
	}
	| expression '-' expression
	{
		$$ = new LLScriptExpression( $1, '-', $3 );
	}
	| expression '*' expression
	{
		$$ = new LLScriptExpression( $1, '*', $3 );
	}
	| expression '/' expression
	{
		$$ = new LLScriptExpression(  $1, '/',  $3  );
	}
	| expression '%' expression
	{
		$$ = new LLScriptExpression(  $1, '%',  $3  );
	}
	| expression '&' expression
	{
		$$ = new LLScriptExpression(  $1, '&',  $3  );
	}
	| expression '|' expression
	{
		$$ = new LLScriptExpression(  $1, '|',  $3  );
	}
	| expression '^' expression
	{
		$$ = new LLScriptExpression(  $1, '^',  $3  );
	}
	| expression BOOLEAN_AND expression
	{
		$$ = new LLScriptExpression(  $1, BOOLEAN_AND,  $3  );
	}
	| expression BOOLEAN_OR expression
	{
		$$ = new LLScriptExpression(  $1, BOOLEAN_OR,  $3  );
	}
	| expression SHIFT_LEFT expression
	{
		$$ = new LLScriptExpression(  $1, SHIFT_LEFT,  $3  );
	}
	| expression SHIFT_RIGHT expression
	{
		$$ = new LLScriptExpression(  $1, SHIFT_RIGHT,  $3  );
	}
	| expression INTEGER_CONSTANT
	{
		ERROR( &@2, E_NO_OPERATOR );
		$$ = NULL;
	}
	| expression FP_CONSTANT
	{
		ERROR( &@2, E_NO_OPERATOR );
		$$ = NULL;
	}
	;

unaryexpression
	: '-' expression
	{
		$$ = new LLScriptExpression( $2, '-' );
	}
	| '!' expression
	{
		$$ = new LLScriptExpression(  $2 , '!' );
	}
	| '~' expression
	{
		$$ = new LLScriptExpression(  $2 , '~' );
	}
	| INC_OP lvalue
	{
		$$ = new LLScriptExpression(  $2 , INC_OP );
	}
	| DEC_OP lvalue
	{
		$$ = new LLScriptExpression(  $2 , DEC_OP );
	}
	| typecast
	{
		$$ = $1;
	}
	| unarypostfixexpression
	{
		$$ = $1;
	}
	| '(' expression ')'
	{
		$$ = new LLScriptExpression($2, 0);
	}
	;

typecast
	: '(' typename ')' '-' INTEGER_CONSTANT
	{
		$$ = new LLScriptTypecastExpression($2, new LLScriptIntegerConstant(-$5));
	}
	| '(' typename ')' '-' FP_CONSTANT
	{
		$$ = new LLScriptTypecastExpression($2, new LLScriptFloatConstant(-$5));
	}
	| '(' typename ')' '-' IDENTIFIER
	{
		LLScriptSymbol *symbol = script->get_symbol_table()->lookup($5);
		if (!symbol || symbol->get_symbol_type() != SYM_VARIABLE || symbol->get_sub_type() != SYM_BUILTIN || symbol->get_type()->get_itype() == LST_VECTOR || symbol->get_type()->get_itype() == LST_QUATERNION)
			ERROR(&@4, E_SYNTAX_ERROR, "Need parentheses around expression.");
		$$ = new LLScriptTypecastExpression($2, new LLScriptExpression( new LLScriptLValueExpression( new LLScriptIdentifier($5) ), '-') );
	}
	| '(' typename ')' unarypostfixexpression
	{
		$$ = new LLScriptTypecastExpression($2, $4);
	}
	| '(' typename ')' IDENTIFIER '[' funcexpressionlist ']'
	{
		if (! lazy_lists) {
			ERROR( &@5, E_SYNTAX_ERROR, "Unexpected '[' - did you forget to activate lazy lists?" );
			$$ = new LLScriptTypecastExpression($2, new LLScriptExpression( new LLScriptLValueExpression( new LLScriptIdentifier($4) ), '-') );
		} else {
			char *fnname = new char[20]; // fits the longest string used here ("llList2quaternion")
			strcpy(fnname, "llList2");
			if ($2->get_itype() == LST_QUATERNION)
				strcpy(fnname + 7, "Rot");
			else {
				strcpy(fnname + 7, $2->get_node_name());
				fnname[7] &= ~0x20; // uppercase the first letter of the type
			}
			LLScriptLValueExpression *firstparam = new LLScriptLValueExpression(new LLScriptIdentifier($4));
			firstparam->add_next_sibling($6);
			$$ = new LLScriptFunctionExpression(new LLScriptIdentifier(fnname), firstparam);
		}
	}
	| '(' typename ')' '(' expression ')'
	{
		$$ = new LLScriptTypecastExpression($2, $5);
	}
	;

unarypostfixexpression
	: vector_initializer
	{
		DEBUG( LOG_DEBUG_SPAM, NULL, "vector intializer..");
		$$ = $1;
	}
	| quaternion_initializer
	{
		$$ = $1;
	}
	| list_initializer
	{
		$$ = $1;
	}
	| lvalue
	{
		$$ = $1;
	}
	| lvalue INC_OP
	{
		$$ = new LLScriptExpression(  $1 , POSTINC_OP );
	}
	| lvalue DEC_OP
	{
		$$ = new LLScriptExpression(  $1 , POSTDEC_OP );
	}
	| IDENTIFIER '(' funcexpressionlist ')'
	{
		if ( $3 != NULL ) {
			$$ = new LLScriptFunctionExpression( new LLScriptIdentifier($1), $3 );
		} else {
			$$ = new LLScriptFunctionExpression( new LLScriptIdentifier($1) );
		}
	}
	| PRINT '(' expression ')'
	{
		if (mono_mode)
			ERROR( &@1, W_PRINT, "will cause the compilation to fail");
		else
			ERROR( &@1, W_PRINT, "may cause a runtime error");
		// Result is the same type as the expression, but without a
		// value. As a compromise, we return the expression because
		// we can't fetch the type at this point.
		$$ = $3;
	}
	| constant
	{
		$$ = new LLScriptExpression($1);
	}
	;

vector_initializer
	: '<' expression ',' expression ',' expression '>'	%prec INITIALIZER
	{
		$$ = new LLScriptVectorExpression($2, $4, $6);
	}
	| ZERO_VECTOR
	{
		$$ = new LLScriptVectorExpression();
	}
	;

quaternion_initializer
	: '<' expression ',' expression ',' expression ',' expression '>' %prec INITIALIZER
	{
		$$ = new LLScriptQuaternionExpression($2, $4, $6, $8);
	}
	| ZERO_ROTATION
	{
		$$ = new LLScriptQuaternionExpression();
	}
	;

list_initializer
	: '[' listexpressionlist ']' %prec INITIALIZER
	{
		$$ = new LLScriptListExpression($2);
	}
	;

lvalue
	: IDENTIFIER
	{
		$$ = new LLScriptLValueExpression(new LLScriptIdentifier($1));
	}
	| IDENTIFIER PERIOD IDENTIFIER
	{
		$$ = new LLScriptLValueExpression(new LLScriptIdentifier($1, $3));
	}
	;

%%

int yyerror( YYLTYPE *lloc, void *scanner, const char *message ) {
	ERROR( lloc, E_SYNTAX_ERROR, message );
	return 0;
}

static LLScriptSimpleAssignable *getSimpleAssignable(LLScriptExpression *expression, simple_recurse_mode mode)
{
  // Check if the expression is simple and construct a LLSimpleAssignable node
  // from it if so. Recurse to handle list and vector elements; the mode
  // parameter tells us what to accept.

  LLScriptConstant *constant = NULL;
  LLScriptIdentifier *identifier = NULL;

  LLASTNode *node = expression;

  int sign = 1;
  if (expression->get_operation() == '-' && node->get_child(1) == NULL) {
    // Enter the expression after the sign
    sign = -1;
    node = node->get_child(0);
  }

  if (node->get_node_type() == NODE_EXPRESSION) { // this should always be true

    LLNodeSubType subtype = node->get_node_sub_type();
    if ((subtype == NODE_NO_SUB_TYPE || subtype == NODE_LVALUE_EXPRESSION)
        && !((LLScriptExpression *)node)->get_operation()
        && node->get_child(1) == NULL) {

      // Handle integer, float, string, variable, constant

      node = node->get_child(0);

      if (node->get_node_type() == NODE_IDENTIFIER) {

        LLScriptSymbol *symbol;
        if (((LLScriptIdentifier*)node)->get_member() == NULL) { // vector or rotation components not accepted
          // Accept negative only if it's a builtins.txt integer or float constant
          if (sign == 1
              || ((symbol = script->get_symbol_table()->lookup(((LLScriptIdentifier *)node)->get_name()))
                  && symbol->get_symbol_type() == SYM_VARIABLE
                  && symbol->get_sub_type() == SYM_BUILTIN
                  && (symbol->get_type()->get_itype() == LST_INTEGER
                      || symbol->get_type()->get_itype() == LST_FLOATINGPOINT)
                 )) {
            identifier = (LLScriptIdentifier *)node;
          }
        }

      } else if (node->get_node_type() == NODE_CONSTANT) {
        subtype = node->get_node_sub_type();

        // Integer, float, string, but not -TRUE/-FALSE
        if ((subtype == NODE_INTEGER_CONSTANT && (sign != -1 || !((LLScriptIntegerConstant *)node)->get_is_bool()))
            || subtype == NODE_FLOAT_CONSTANT
            || (subtype == NODE_STRING_CONSTANT && sign != -1)) {
          constant = (LLScriptConstant *)node;
        }
      }
    } else if (sign != -1 && (mode == SIMPLE_ANY || mode == SIMPLE_LIST)
               && (subtype == NODE_VECTOR_EXPRESSION
                   || subtype == NODE_QUATERNION_EXPRESSION)) {

      // Handle vector/quaternion

      LLScriptSimpleAssignable *x = getSimpleAssignable((LLScriptExpression *)node->get_child(0), SIMPLE_ANY);
      LLScriptSimpleAssignable *y = getSimpleAssignable((LLScriptExpression *)node->get_child(1), SIMPLE_ANY);
      LLScriptSimpleAssignable *z = getSimpleAssignable((LLScriptExpression *)node->get_child(2), SIMPLE_ANY);
      if (subtype == NODE_QUATERNION_EXPRESSION) {
         LLScriptSimpleAssignable *s = getSimpleAssignable((LLScriptExpression *)node->get_child(3), SIMPLE_ANY);
         if (x && y && z && s)
           constant = new LLScriptQuaternionConstant(x, y, z, s);
      } else {
         if (x && y && z)
           constant = new LLScriptVectorConstant(x, y, z);
      }
    } else if (sign != -1 && subtype == NODE_LIST_EXPRESSION && mode == SIMPLE_ANY) {

      // Handle list

      int i = 0;
      LLScriptExpression *list_entry;
      LLScriptSimpleAssignable *converted;
      LLScriptSimpleAssignable *new_list = NULL;
      do {
        list_entry = (LLScriptExpression *)node->get_child(i++);
        if (!list_entry || list_entry->get_node_type() != NODE_EXPRESSION) {
          constant = new LLScriptListConstant(new_list);
          break;
        }
        converted = getSimpleAssignable(list_entry, SIMPLE_LIST);
        if (!converted)
          break;
        if (new_list)
          new_list->add_next_sibling(converted);
        else
          new_list = converted;
      } while (true);
    }
  }

  if (constant)
    return new LLScriptSimpleAssignable(constant);
  else if (identifier)
    return new LLScriptSimpleAssignable(identifier);
  else
    return NULL;
}

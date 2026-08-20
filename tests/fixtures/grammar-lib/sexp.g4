/* All of this heavily borrowed from the ANTLR ST/STG grammars */
lexer grammar sexp;

import LexBasic ;

channels {
    OFF_CHANNEL // non-default channel for whitespace and comments
}

// ------------------------------------------------------------------------------
// mode default


COMMENT   : Comment   -> channel(OFF_CHANNEL);
WS : Ws+ -> channel(OFF_CHANNEL);

ATOM : NameChar+ ;
DQSTRING : DQuoteLiteral ;
// RAWSTRING : '{' NameChar IdentChar?

LPAREN : '(' ;
RPAREN : ')' ;

fragment Comment   : ';' .*? ('\n' | EOF) ;

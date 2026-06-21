lexer grammar L;
I : '0'..'9'+ {print("I", file=self._output)} ;
WS : [ \n\u000D] -> skip ;

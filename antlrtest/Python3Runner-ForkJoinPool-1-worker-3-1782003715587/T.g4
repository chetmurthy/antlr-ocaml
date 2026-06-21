grammar T;
a : ID INT {
print($text, file=self._output)
};
ID : 'a'..'z'+ ;
INT : '0'..'9'+;
WS : (' '|'\n') -> skip;

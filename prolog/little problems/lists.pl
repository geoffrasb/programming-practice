rev([],[]).
rev([H|T],R):-
    rev(T,RT),
    add_back(RT,H,R).
add_back([],X,[X]).
add_back([H|T],X,[H|NT]):-
    add_back(T,X,NT).

palindrome(L):-
    palindrome_aux([],L).

palindrome_aux([],[]).
palindrome_aux([_],[]):-!.
palindrome_aux([AH|AT], [H|T]):-
    (AH =\= H ->
        [AH|AT] = T,!;
        AT = T,!).
palindrome_aux(Accum,[H|T]):-
    palindrome_aux([H|Accum],T).


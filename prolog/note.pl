/* repeating a generator

?- flag(count,_,5).
gen(A):-
    repeat,
    flag(count,A,A-1).

run:-
    gen(A),
    (A >= 0 ->
        write(A),fail;
        true,!).
*/

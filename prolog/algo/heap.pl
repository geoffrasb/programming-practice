use_module(library(gensym)).


unitRecord(Key,Old,New):-
    (\+recorded(Key,Old,Ref)->
        recordz(Key,New);
        erase(Ref), recordz(Key,New)).
genNsym(Key,[]).
genNsym(Key,[H|T]):-
    gensym(Key,H),
    genNsym(Key,T).


% -------------------

makeHeap(Key,CompareClause):-  %CompareClause/2 true for bigger in max-heap
    \+recorded(Key,_),
    genNsym(Key,[L,V,R]),
    recordz(Key,node(L,V,R),NodeRef),
    recordz(Key,compareClause(CompareClause)),
    recordz(Key,lastNode(NodeRef)).

deleteHeap(Key):-
    recorded(Key,_,Ref),
    erase(Ref),fail.
deleteHeap(_).

heapInsert(Key,Value):-
    recorded(Key, heapRoot(Compare,RootValKey), Ref),
    recorded(RootValKey,RootVal,RR),
    (RootVal = nil-> 
        replaceUnitRecord(RootValKey,_,Value);
        recorded(Key, lastNode(NR)),


heapExtract


/* 
proc( id,
      startTime,
      burstTime,
      waitTime ,
      readyTimes)
*/

makeScheduler(ProcList):-
nextToRun(A):-



runOnce(PID,Rest):-
    runningproc(PID,Burst),
    retract(runningproc(PID,Burst)),
    Rest is Burst - 1,
    assertz(runningproc(PID,Rest)).
increaseWaitTime(PID):-
    proc(PID,A,B,Wait,C),
    retract(proc(PID,_,_,_,_)),
    NWait is Wait+1,
    assertz(PID,A,B,NWait,C).
increaseReadyTimes(PID):-
    proc(PID,A,B,C,Ready),
    retract(proc(PID,_,_,_,_)),
    NR is Ready+1,
    assertz(PID,A,B,C,NR).


execute(ProcSeq,ProcDone):-
    nextToRun(P,ProcDone),
    (P == 0 ->
        ProcSeq = [];
        runOnce(P,Rest),
        forall(proc(WP,_,_,_,_),WP /= P,increaseWaitTime(WP)),
        (ProcSeq = [Last|_] ->
            increaseReadyTimes(Last);true),
        (Rest>0 ->
            execute([P|ProcSeq],fail);
            execute([P|ProcSeq],true)))

initialProcs([]).
initialProcs([proc(ID,_,Burst,_,_)|Ps]):-
    assertz(runningproc(ID,Burst)),
    initialProcs(Ps).

runMachine(ProcList,ProcSeq):-
    makeScheduler(ProcList),
    initialProcs(ProcList),!,
    execute(Result),
    reverse(Result,ProcSeq).

sumWaitTime([],0).
sumWaitTime([P|Ps],R):-
    proc(P,_,_,Wait,Ready),
    sumWaitTime(Ps,NR),
    R is Wait/Ready + NR.

evalAWT(ProcList,Result):-
    sumWaitTime(ProcList,TotalWaitTime),
    length(ProcList,Len),
    Result is TotalWaitTime/Len.

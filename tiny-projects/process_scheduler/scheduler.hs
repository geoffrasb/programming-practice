import Data.Set
import Utils

data Proc = Proc { procId :: Int
                 , startTime :: Int
                 , procLen :: Int
                 , waitTime :: Int
                 , readyTimes :: Int
                 , restWorks :: Int
                 } deriving (Show)
type PID = Int

seq2proc::(PID,Int,Int) -> Proc
seq2proc (pid,len,start) = Proc {procId=pid, startTime=start, procLen=len, waitTime=0, readyTimes=1, restWorks=len}

-- scheduler implimentation
data AbsProc = SingleProc Proc | CombinedProc [(Proc, Int)] deriving (Show)
data SchedulerState = 



type PIDState = (PID, Int) -- Int be the rest works
type NextSignal = Bool --True for notify that the process has done
type Scheduler = (SchedulerState -> NextSignal -> (SchedulerState,PID))
type MetaScheduler = [Proc] -> (Scheduler,SchedulerState)
type ExeSeq = [PID]

execute :: (Set PIDState) -> (Scheduler, SchedulerState, Bool) -> ExeSeq
execute pstateSet (scheduler, schedulerState, procFinish) procExeSeq = 
    if null $ filter (\(_,restworks) -> restworks > 0) pstateSet then
        reverse procExeSeq
    else
        let (nextState,nextProc) = (scheduler schedulerState procFinish) 
            p                    = (head $ filter (\(nextproc,_)->True) pstateSet)
            newSet = Set.insert (fst p, (snd p) -1) (Set.delete p pstateSet)
        in
            execute newSet (scheduler,nextState,(snd p==0)) (nextProc : ProcExeSeq)
        
        
runmachine:: [Proc] -> MetaScheduler -> ExeSeq
runmachine procs metaScheduler =
    let getPidState = map (\Proc {procId=pid, procLen=len} -> (pid,len)) procs
        (scheduler,schedulerState) = (metaScheduler procs) 
    in
        execute (Set.fromList $ map getPidState procs) (scheduler,schedulerState,False) []

---------------
evalAWT :: [Proc] -> ExeSeq -> Double
evalAWT procs exeseq =
    let ps =
            map (\Proc {procId=pid, startTime=st, procLen=len} -> (pid,st,len)) procs
        pid_rdy_waits = 
            map (\ (pid,st,len) ->
                 let f pid lst last rdytms dotms fintm = 
                        case lst of
                            []   -> error "this should not happen"
                            x:xs -> 
                                if dotms==len then
                                    (pid,rdytms,fintm-st-len)
                                else
                                    if x==pid then
                                        f pid xs pid rdytms (dotms+1) (fintm+1)
                                    else
                                        if last==pid then
                                            f pid xs x (rdytms+1) dotms (fintm+1)
                                        else
                                            f pid xs x rdytms dotms (fintm+1))
                ps
                                                                    
    in
        --(lrec (\(_,rdy,wait) b-> (wait/rdy)+b) 0.0 pid_rdy_waits)/(length pid_rdy_waits)
        (foldr (\(_,rdy,wait) b-> (wait/rdy)+b) 0.0 pid_rdy_waits)/(length pid_rdy_waits)



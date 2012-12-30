import Data.Set

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




type PIDState = (PID, Int) -- Int be the rest works
type PeriodSignal = ()
type Scheduler = (PeriodSignal -> PID)
type MetaScheduler = [Proc] -> Scheduler
type ExeSeq = [PID]

execute :: (Set PIDState) -> Scheduler -> ExeSeq
execute pstateSet scheduler procExeSeq = 
    if null $ filter (\(_,restworks) -> restworks > 0) pstateSet then
        reverse procExeSeq
    else
        let nextProc = (scheduler ()) 
            p = (head $ filter (\(nextproc,_)->True) pstateSet)
            newSet = Set.insert (fst p, (snd p) -1) (Set.delete p pstateSet)
        in
            execute newSet scheduler (nextProc : ProcExeSeq)
        
        
runmachine:: [Proc] -> MetaScheduler -> ExeSeq
runmachine procs metaScheduler =
    let getPidState = (\Proc {procId=pid, procLen=len} -> (pid,len))
    in
        execute (Set.fromList $ map getPidState procs) (metaScheduler procs) []

---------------
evalAWT :: [Proc] -> ExeSeq -> Double



data Proc = Proc { p_id :: Int
                 , p_startTime :: Int
                 , p_length :: Int
                 , p_waitTime :: Int
                 , p_readyTimes :: Int
                 } deriving (Show)

data AbsProc = SingleProc Proc | CombinedProc [(Proc, Int)]

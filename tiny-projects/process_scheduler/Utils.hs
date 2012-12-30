module Utils
( lrec

) where


lrec :: (a -> c -> c) -> c -> ([a] -> c)
lrec f base =
    let g lst = 
            case lst of
                []   -> base
                x:xs -> f x (g xs)
    in 
        g

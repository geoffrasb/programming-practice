import Data.Char

{-
compilation:
$ ghc --make file

-}

-- let binding in 'do' do not have 'in' keyword
prog1 = do 
    putStrLn "What's your first name?"
    firstName <- getLine
    putStrLn "What's your last name?"
    lastName <- getLine
    let bigFirstName = map toUpper firstName
        bigLastName = map toUpper lastName
    putStrLn $ "hey " ++ bigFirstName ++ " " ++ bigLastName ++ ", how are you?"

-- example of reversing the words
prog2 = do
    line <- getLine
    if null line
        then return ()
        else putStrLn $ reverseWords line

reverseWords :: [Char] -> [Char]
reverseWords = unwords . map reverse . words


prog3 = do
    a <- return "hell"
    b <- return "yeah!"
    putStrLn $ a ++ " " ++ b

import Control.Monad --for 'when' function
main = do 
    putChar 'g'
    putStr "ood"
    print [1,2,3]
    c <- getChar
    when (c /= ' ') $ do
        putChar c
    rs <- sequence [getLine,getLine,getLine]
    print rs
    
sequence (map print [1,2,3])
--equals to
mapM print [1,2,3]
mapM_ print [1,2,3] --see :t mapM_

prog4 = do
    corlors <- forM [1,2,3,4] (\a -> do
        putStrLn $ "Which color do you associate with the number " ++ show a ++ "?"
        color <- getLine
        return color)
    putStrLn "The colors that you associate with 1, 2, 3, and 4 are: "
    mapM_ putStrLn colors

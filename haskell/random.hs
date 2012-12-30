import System.Random
{-

random :: (RandomGen g, Random a) => g -> (a,g)
Take an random generator and returning a new one.

StdGen is an instance of the RandomGen typeclass


-}

random (mkStdGen 1) :: (Int, StdGen) -- we can get random an integer

threeCoins :: StdGen -> (Bool, Bool, Bool)
threeCoins gen =
    let (firstCoin, newGen) = random gen
        (secondCoin, newGen') = random newGen
        (thirdCoin, newGen'') = random newGen'
    in  (firstCoin, secondCoin, thirdCoin)

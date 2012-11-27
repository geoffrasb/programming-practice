import Types1
{-
class Eq a where
    (==) :: a->a->Bool
    (/=) :: a->a->Bool
    x == y = not (x /= y)
    x /= y = not (x == y)
-}

data TrafficLight = Red | Yellow | Green

instance Eq TrafficLight where
    Red == Red = True
    Green == Green = True
    Yellow == Yellow = True
    _ == _ = False

-- "class" is fro defining new typeclasses and
-- "instance" is for making our types instances of typeclasses.

instance Show TrafficLight where
    show Red = "Red light"
    show Yellow = "Yellow light"
    show Green = "Green light"

-- case of "Maybe"
{-
instance (Eq m) => Eq (Maybe m) where
    Just x == Just y = x == y
    Nothing == Nothing = True
    _ == _ = False
-}
--
-- use ":info" in ghci to see a typeclass's instances



------------- A yes/no typeclass

class YesNo a where
    yesno :: a -> Bool
instance YesNo Int where
    yesno 0 = False 
    yesno _ = True
instance YesNo [a] where
    yesno [] = False
    yesno _ = True
instance YesNo Bool where
    yesno = id
instance YesNo (Maybe a) where
    yesno Nothing = False
    yesno _ = True
instance YesNo Tree a where
    yesno EmptyTree = False
    yesno _ = True
instance YesNo TrafficLight where
    yesno Red = False 
    yesno _ = True



---------------- The Functor typeclass

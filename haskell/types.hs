import qualified Data.Map as Map

-- declare Shape TYPE
-- with VALUE CONSTRUCTORs Circle and Rectangle. 
-- VALUE CONSTRUCTORs are functions returning values of certain data types.


data Point = Point Float Float deriving (Show)
data Shape = Circle Point Float | Rectangle Point Point deriving (Show)

surface :: Shape -> Float
surface (Circle _ r) = pi*r^2
surface (Rectangle (Point x1 y1) (Point x2 y2)) = (abs $ x2 - x1)*(abs $ y2 - y1)

nudge :: Shape -> Float -> Float -> Shape  
nudge (Circle (Point x y) r) a b = Circle (Point (x+a) (y+b)) r  
nudge (Rectangle (Point x1 y1) (Point x2 y2)) a b = Rectangle (Point (x1+a) (y1+b)) (Point (x2+a) (y2+b))

baseCircle :: Float -> Shape  
baseCircle r = Circle (Point 0 0) r  
  
baseRect :: Float -> Float -> Shape  
baseRect width height = Rectangle (Point 0 0) (Point width height) 



data Person = Person { firstName :: String
                     , lastName :: String
                     , age :: Int
                     } deriving (Show)
-- then we obtain functions like age :: Person->Int
-- construct a data like:
{-
 - Person {firstName="xxx" , lastName="yyy" ...}
 -
 -}


------------ type param

data Vector a = Vector a a a deriving (Show)

vplus :: (Num t) => Vector t->Vector t->Vector t
(Vector i j k) `vplus` (Vector l m n) = Vector (i+l) (j+m) (k+n)

vectMult :: (Num t) => Vector t -> t -> Vector t
(Vector i j k) `vectMult` m = Vector (i*m) (j*m) (k*m)

scalarMult :: (Num t) => Vector t -> Vector t -> t
(Vector i j k) `scalarMult` (Vector l m n) = i*l + j*m + k*n



-------------- deriving types


mikeD = Person {firstName = "Michael", lastName = "Diamond", age = 43}  
adRock = Person {firstName = "Adam", lastName = "Horovitz", age = 41}  
mca = Person {firstName = "Adam", lastName = "Yauch", age = 44}  


------------  type synonyms

-- type String = [Char]

-- ---------  some examples

data LockerState = Taken | Free deriving (Show, Eq)
type Code = String
type LockerMap = Map.Map Int (LockerState, Code)

lockerLookup :: Int -> LockerMap -> Either String Code
lockerLookup k m = case Map.lookup k m of
                    Nothing -> Left $ "locker number " ++ show k ++ " doesn't exist."
                    Just (state,code) -> if state == Free
                                            then Right code
                                            else Left $ " taken"


----------- Recursive data structures
data List a = Empty | a :-: (List a) deriving (Show, Read, Eq, Ord)

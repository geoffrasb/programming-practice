data Tree a = EmptyTree | Node a (Tree a) (Tree a) deriving (Show,Read,Eq)

treeSingleton :: a -> Tree a
treeSingleton x = Node x EmptyTree EmptyTree

treeInsert :: (Ord a) => a -> Tree a -> Tree a
treeInsert x EmptyTree = treeSingleton x
treeInsert x (Node a left right)
    | x == a = Node a left right
    | x < a = Node a (treeInsert x left) right
    | x > a = Node a left (treeInsert x right)

treeElem :: (Ord a) => a -> Tree a -> Bool
treeElem x EmptyTree = False
treeElem x (Node a left right)
    | x == a = True
    | x < a  = treeElem x left
    | x > a  = treeElem x right
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
instance YesNo (Tree a) where
    yesno EmptyTree = False
    yesno _ = True
instance YesNo TrafficLight where
    yesno Red = False 
    yesno _ = True



---------------- The Functor typeclass
{-
class Functor f where
    fmap :: (a -> b) -> f a -> f b

instance Functor [] where
    fmap = map

instance Functor Maybe where
    fmap f (Just x) = Just (f x)
    fmap f Nothing = Nothing

instance Functor Either a where
    fmap f (Left x) = Left x       -- 
    fmap f (Right x) = Right (f x) -- the unbounded type belongs to Right

-}

instance Functor Tree where
    fmap f EmptyTree = EmptyTree
    fmap f (Node a left right) = Node (f a) (fmap f left) (fmap f right)

----------------- Kind
-- normal types like Int, Char, are the kind "*"
-- type constructor Maybe is the kind "*->*"
-- we can do some simple type inference here

class Tofu t where
    tofu :: j a -> t a j
-- t the type-constructor is the kind *->(*->*)->*

data Frank a b = Frank' {frankField :: b a} deriving (Show)
-- Frank the type-constructor is the kind *->(*->*)->*
--  due to Frank' the data-constructor's construction (definition)

instance Tofu Frank where
    tofu  = Frank' 

data Barry t k p = Barry' {yabba:: p, dabba:: t k}
-- We can infer that Barry is the kind of (*->*)->*->*->*
--  due to Barry' the data-constructor

instance Functor (Barry a b) where
    fmap f (Barry' {yabba=x, dabba= y}) = Barry' {yabba=(f x), dabba=y}



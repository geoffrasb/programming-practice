import qualified Data.Map as Map


findKey' :: (Eq k) => k -> [(k,v)] -> v
findKey' key xs = snd . head . filter (\(k,v)-> key==k) $ xs

findKey'' :: (Eq k) => k -> [(k,v)] -> Maybe v
findKey'' key [] = Nothing
findKey'' key ((k,v):xs) = if key == k
                            then Just v
                            else findKey key xs

findKey :: (Eq k) => k -> [(k,v)] -> Maybe v
findKey key = foldr (\(k,v) acc -> if key==k then Just v else acc) Nothing


-- fromList is a data constructor
-- fromList :: Ord k => [(k,a)] -> Map k a
-- empty :: Map k a
-- insert :: (Ord k) => k -> a -> (Map k a) -> (Map k a)
Map.insert 97 'a' Map.empty

-- null :: Map k a -> Bool
-- size :: Map k a -> Int
-- singleton :: k -> a -> Map k a
-- member :: (Ord k) => k -> Map k a -> Bool
-- map :: (a -> b) -> Map k a -> Map k b
-- filter :: (Ord k) => (a -> Bool) -> Map k a -> Map k a
-- toList :: Map k a -> [(k,a)]
-- keys = map fst . toList
-- elems = map snd . toList
-- fromListWith -- this function will not discards the duplicated key
-- insertWith

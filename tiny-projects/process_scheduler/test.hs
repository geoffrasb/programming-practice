data TS = TS { a::Int
             , b::Int} deriving (Show)

f all@TS{ a=y } x = all

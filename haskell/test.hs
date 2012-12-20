
a = (do j <- [1..]
        return
        (do i <- [1,2]
            return (i,j)))

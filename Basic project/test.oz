declare

   /** IsIsland
        X, Y = position on the map
        if the point(X,Y) is an island then true    
        else false
    */
    fun{IsIsland X Y Map}
        case Map
        of H1|T1 then 
            if(X ==1) then
                case H1 
                of H2|T2 then 
                    if(Y==1) then
                        if(H2 == 1) then %Sur une ile
                            true
                        else
                            false
                        end
                    else
                        {IsIsland X Y-1 T2|T1}
                    end
                else
                    false
                end
            else
                {IsIsland X-1 Y T1}
            end
        else
            false
        end
    end

    /** IsOnMap
    @pre
        (X, Y) coordonnates
    @post
        true if the Coordonates are on the map
        false otherwise    
    */
    fun{IsOnMap X Y}
        if(X=<NRow andthen X>0) then
            if(Y=<NColumn andthen Y>0) then
                true
            else
                false
            end
        else
            false
        end
    end

    /** IsPositionOnMap
    @pre
        Position
    @post
        true if the Position is on the map
        false otherwise    
    */
    fun{IsPositionOnMap Position}
        {IsOnMap Position.x Position.y}
    end

fun{PositionMine Position}
    Pos XMine YMine DeltaX DeltaY CondX CondY in 
    %Delta 
    DeltaX = {OS.rand} mod (MaxDistanceMine + 1)
    if DeltaX < MinDistanceMine then
        DeltaY = MinDistanceMine + {OS.rand} mod (MaxDistanceMine-DeltaX)
    else
        DeltaY = {OS.rand} mod (MaxDistanceMine-DeltaX)
    end
    %Cond to know position or negative
    if ({OS.rand} mod 2) == 1 then CondX = ~1
    else
        CondX=1
    end
    if ({OS.rand} mod 2) == 1 then CondY = ~1
    else
        CondY=1
    end

    XMine = Position.x + CondX * DeltaX
    YMine = Position.y + CondY * DeltaY
    Pos = pt(x:XMine y:YMine)
    if {IsOnMap Pos.x Pos.y} andthen {Not {IsIsland Pos.x Pos.y Map} } then 
        Pos
    else 
        {PositionMine Position}
    end

end

/**PositionMissile
    give a random position that is bounded by minDistanceMissile and maxDistanceMissile around Position*/
fun{PositionMissile Position}
    Pos XMissile YMissile DeltaX DeltaY CondX CondY in 
    %Delta        
    DeltaX = {OS.rand} mod (MaxDistanceMissile + 1)
    if DeltaX < MinDistanceMissile then
        DeltaY = MinDistanceMissile + {OS.rand} mod (MaxDistanceMissile-DeltaX +1)
    elseif DeltaX == MaxDistanceMissile then
        DeltaY=0
    else
        DeltaY = {OS.rand} mod (MaxDistanceMissile-DeltaX)
    end

    %Cond to know position or negative
    if ({OS.rand} mod 2) == 1 then CondX = ~1
    else
        CondX=1
    end
    if ({OS.rand} mod 2) == 1 then CondY = ~1
    else
        CondY=1
    end

    XMissile = Position.x + CondX * DeltaX
    YMissile = Position.y + CondY * DeltaY
    Pos = pt(x:XMissile y:YMissile)
    if {IsOnMap Pos.x Pos.y} then Pos
    else 
        {PositionMissile Position}
    end

end
MinDistanceMine = 1
MaxDistanceMine = 2
MinDistanceMissile = 1
MaxDistanceMissile = 6
      NRow = 10
      NColumn = 10


Map = [[0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 1 1 0 0 0 0 0]
      [0 0 1 1 0 0 1 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 1 0 0 1 1 0 0]
      [0 0 1 1 0 0 1 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]]

{Browse {PositionMissile pt(x:5 y:5)} }
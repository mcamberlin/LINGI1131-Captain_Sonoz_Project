declare

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

fun{PositionMissile State ?Enemy}

    %1. retourner une liste de position ou peut se trouver l'ennemi
    /** Increment
    @pre 
        Position = position présumée de l'ennemi
        Min = borne min missile
        Max = borne max missile
    @post
        retourne une liste de position atteignable par le missile
        */
    fun{Increment Position Min Max} 
        case Position
        of pt(x:0 y:Y) then
            if(Min =< Max) then
                pt(x:Min y:Y) | {Increment Position Min+1 Max}
            else
                nil
            end
        [] pt(x:X y:0) then
            if(Min =<Max) then
                pt(x:X y:Min) |{Increment Position Min+1 Max}
            else
                nil
            end
        else
            nil
        end
    end  


    %2. Parmi cette liste, retirer les positions trop proche de nous
    /** TooClose
    @pre 
        L = list of positions where we can fire a missile
    @post
        L = list of positions where positions are not too close  */
    fun{TooClose L State} 
        case L
        of H|T then
            if( {ManhattanDistance H State.position} > Input.minDistanceMissile andthen {ManhattanDistance H State.position} >1  andthen {IsPositionOnMap H} andthen {Not {IsIsland H.x H.y Input.map}} ) then
                H|{TooClose T State}
            else
                {TooClose T State}
            end
        else
            nil
        end
    end 

    %3. Choisir aléatoirement une position parmi la liste restante 
    fun{GetRandomPosition L}
        fun{Length L Acc}
            case L 
            of H|T then {Length T Acc+1}
            else
                Acc
            end
        end
        Longueur
    in  
        Longueur = {Length L 0}
        if(Longueur == 0) then 
            null
        else
        
            {Get L (1+{OS.rand} mod (Longueur) ) }
        end 

    end
    /** RecursivePositionMissile
    @pre
        List = list of enemies
        State = state of the current player
        Enemy = unbound
    @post
        bound Enemy to the enemy supposed to be fired
        return a reachable position where fired a missile without damaging ourself 
    */
    fun{RecursivePositionMissile List State ?Enemy }
        case List              
        of enemy(id:I position: P)|T then
            case P 
            of pt(x:0 y:0) then
                {RecursivePositionMissile T State ?Enemy }
            [] pt(x:0 y:Y) then
                local L1 L2 DeltaX DeltaY MinX MaxX in
                    DeltaY = {Abs State.position.y - Y} 
                    DeltaX = Input.maxDistanceMissile - DeltaY 

                    if(DeltaX<0) then 
                    {RecursivePositionMissile T State ?Enemy }
                    else
                        
                        MinX = State.position.x - DeltaX
                        MaxX = State.position.x + DeltaX

                        L1 = {Increment pt(x:0 y:Y) MinX MaxX }
                        L2 = {TooClose L1 State}

                        Enemy = enemy(id:I position: P)

                        {GetRandomPosition L2}
                    end
                end

            []pt(x:X y:0) then
                local L1 L2 DeltaX DeltaY MinY MaxY in
                    DeltaX = {Abs State.position.x - X} 
                    DeltaY = 4 - DeltaX 
                    if(DeltaY <0) then
                        {RecursivePositionMissile T State ?Enemy }
                    else
                        
                        MinY = State.position.y - DeltaY
                        MaxY = State.position.y + DeltaY

                        L1 = {Increment pt(x:X y:0) MinY MaxY }
                        L2 = {TooClose L1 State}
                        Enemy = enemy(id:I position: P)

                        {GetRandomPosition L2}
                    end
                end
            else /* Les Deux sont connues */
                if( {ManhattanDistance P State.position} < Input.maxDistanceMissile andthen {ManhattanDistance P State.position} > Input.minDistanceMissile andthen {ManhattanDistance P State.position} >1  andthen {IsPositionOnMap P} andthen {Not {IsIsland P.x P.y Map}} ) then
                    Enemy = enemy(id:I position: P)
                    P  
                else
                    {RecursivePositionMissile T State ?Enemy }
                end
            end
        else
            Enemy = null
            null
        end
    end
    
in
    {RecursivePositionMissile State.enemies State ?Enemy}
end


fun{Increment Position Min Max} 
    case Position
    of pt(x:0 y:Y) then
        if(Min =< Max) then
            pt(x:Min y:Y) | {Increment Position Min+1 Max}
        else
            nil
        end
    [] pt(x:X y:0) then
        if(Min =<Max) then
            pt(x:X y:Min) |{Increment Position Min+1 Max}
        else
            nil
        end
    else
        nil
    end
end

Position = pt(x:0 y:7)


MinDistanceMine = 1
MaxDistanceMine = 2
MinDistanceMissile = 1
MaxDistanceMissile = 6
      NRow = 10
      NColumn = 10


Map = [[0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]]

{Browse {IsIsland 1 1 Map} }
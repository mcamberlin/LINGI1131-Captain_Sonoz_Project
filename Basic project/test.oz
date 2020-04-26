declare
fun{ManhattanDistance Position1 Position2}
    if(Position1 == nil orelse Position2 == nil) then nil
    else
        {Abs Position1.x-Position2.x} + {Abs Position1.y-Position2.y}
    end
end

fun{Get L I}
    case L
    of nil then nil
    [] H|T then 
            if(I ==1) then H 
            else
                {Get T I-1}
            end
    else
        nil
    end
end
    
fun{PositionMissile State}

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

    fun{TooClose L State} 
        case L
        of H|T then
            if( {ManhattanDistance H State.position} > 1 andthen {ManhattanDistance H State.position} >1 )then %andthen {IsPositionOnMap H} ) then
                H|{TooClose T State}
            else
                {TooClose T State}
            end
        else
            nil
        end
    end 

    fun{GetRandomPosition L}
        fun{Length L Acc}
            case L 
            of H|T then {Length T Acc+1}
            else
                Acc
            end
        end
    in  
        {Get L (1+{OS.rand} mod ({Length L 0}) ) }
    end

    fun{RecursivePositionMissile List State}
        case List              
        of enemy(id:I position: P)|T then
            case P 
            of pt(x:0 y:0) then
                {RecursivePositionMissile T State}

            [] pt(x:0 y:Y) then
                local L1 L2 DeltaX DeltaY MinX MaxX in
                    DeltaY = {Abs State.position.y - Y} 
                    DeltaX = 4 - DeltaY 

                    if(DeltaX<0) then 
                        {RecursivePositionMissile T State}
                    else
                        
                        MinX = State.position.x - DeltaX
                        MaxX = State.position.x + DeltaX

                        L1 = {Increment pt(x:0 y:Y) MinX MaxX }
                        L2 = {TooClose L1 State}
                        {GetRandomPosition L2}
                    end
                end

            []pt(x:X y:0) then
                local L1 L2 DeltaX DeltaY MinY MaxY in
                    DeltaX = {Abs State.position.x - X} 
                    DeltaY = 4 - DeltaX 
                    if(DeltaY <0) then
                        {RecursivePositionMissile T State}
                    else
                        
                        MinY = State.position.y - DeltaY
                        MaxY = State.position.y + DeltaY

                        L1 = {Increment pt(x:X y:0) MinY MaxY }
                        L2 = {TooClose L1 State}
                        {GetRandomPosition L2}
                    end
                end
            else /* Les Deux sont connues */
                P
            end
        else
            null
        end
    end
    
in
    {RecursivePositionMissile State.enemies State}
end

declare
L = enemy(id:1 position:pt(x:0 y:0)) | enemy(id:2 position:pt(x:0 y:0)) | enemy(id:1 position:pt(x:3 y:0)) | nil
State = state(position:pt(x:8 y:4) enemies: L)

{Browse {PositionMissile State}}
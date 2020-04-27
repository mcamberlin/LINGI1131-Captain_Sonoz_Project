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
    true if the coordinate are on the map
    false otherwise    
*/
fun{IsOnMap X Y}
    if(X=<Input.nRow andthen X>0) then
        if(Y=<Input.nColumn andthen Y>0) then
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

/** Get
@pre
    L = list of elements
    I = index of the element considering in the list
@post
    return the Index th element in the list
    */
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

fun{Length L Acc}
    case L 
    of H|T then {Length T Acc+1}
    else
        Acc
    end
end

/** IsAlreadyVisited
@pre
    Position
    State
@post
    true if the Position has already been visited
    false otherwise
*/
fun{IsAlreadyVisited Position State}
    fun{Contains ListPositions Position}
        case ListPositions
        of nil then false
        [] H|T then
            if(H == Position) then true
            else
                {Contains T Position}
            end
        else
            false
        end
    end
in
    if State.lastPositions == nil then false 
    else
        {Contains State.lastPositions Position}
    end
end

/** RandomDirection
@pre
@post 
    return a random direction (east, west, north, south, surface)
*/
fun{RandomDirection}
    NewDirection = {OS.rand} mod 5
in
    if(NewDirection == 0) then surface
    elseif(NewDirection == 1) then east
    elseif(NewDirection == 2) then north
    elseif(NewDirection == 3) then west
    else 
        south
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



/** Move
@pre
    ID = unbound; Position = unbound; Direction = unbound
    State = current state of the submarine
@post

*/ 
fun{Move ID Position Direction State}

    /** GetPositionFromDirection
    @pre 
        Direction = the new direction selected for the submarine
    @post
        return the new Position according to the direction selected 
    */
    fun{GetPositionFromDirection Direction State}
        NewPosition in
        case Direction 
        of surface then 
            NewPosition = State.position
        [] north then 
            NewPosition = pt(x:(State.position.x-1) y:State.position.y)
        [] south then 
            NewPosition = pt(x:(State.position.x+1) y:State.position.y)
        [] east then 
            NewPosition = pt(x:State.position.x y:(State.position.y+1))
        else /* west*/
            NewPosition = pt(x:State.position.x y:(State.position.y-1))
        end
        NewPosition
    end

    /** DirectionAvailable
    @post
        return a list of Directions available to move there
    */
    fun{DirectionAvailable Directions State}
        case Directions
        of H|T then
            Position in 
            Position = {GetPositionFromDirection H State}
            if( {Not {IsAlreadyVisited Position State}} andthen {IsOnMap Position} andthen {Not {IsIsland Position.x Position.y Input.map}} ) then
                H | {DirectionAvailable T State}
            else
                {DirectionAvailable T State}
            end
        else
            nil
        end
    end

    /**GenerateEnemiesPosition
    @pre
    @post
        return a list of known position of enemies
    */
    fun{GenerateEnemiesPosition Enemies}
        case Enemies
        of enemy(id: I position:P)|T then
            case P
            of pt(x:0 y:0) then
                {GenerateEnemiesPosition T}
            []pt(x:X y:Y) then
                P|{GenerateEnemiesPosition T}
            else
                nil
            end  
        else
            nil
        end
    end

    /** SelectDirection
    @pre
    @post
        return one direction to an enemy
    */
    fun{SelectDirection EnemiesPosition DirectionsAvailable State}
        
        fun{RecursiveSelectDirection EnemiesPosition DAvailable State}
            case EnemiesPosition
            of E|T2 then
                if( DAvailable == east andthen E.y \= 0 andthen E.y > State.position.y) then east
                   
                elseif(DAvailable == west andthen E.y \= 0 andthen E.y < State.position.y) then west
                
                elseif(DAvailable == north andthen E.x \= 0 andthen E.x < State.position.x) then north

                elseif(DAvailable == south andthen E.x \= 0 andthen E.x > State.position.x) then south

                else
                    {RecursiveSelectDirection T2 DAvailable State}
                end
            else
                nil
            end

        end
    in
        case DirectionsAvailable
        of H|T then
            local R in
                R = {RecursiveSelectDirection EnemiesPosition H State}
                if(R == nil) then
                    {SelectDirection EnemiesPosition T State}
                else
                    R
                end
            end
        else 
            nil
        end 

    end
 
    DirectionsAvailable
    EnemiesPosition
    NewState
in

    DirectionsAvailable = {DirectionAvailable [north south east west] State}
    
    /* Aucune direction n'est possible => va a la surface */
    if(DirectionsAvailable == nil) then 
        % reset the last positions visited since last surface phase
        Position = State.position
        NewState = {AdjoinList State [lastPositions#[Position] ]}
        ID = State.id
        Direction = surface
        NewState

    else
        EnemiesPosition = {GenerateEnemiesPosition State.enemies}
        if(EnemiesPosition == nil) then
            local Index in
                Index = {OS.rand} mod {Length DirectionsAvailable 0}
                Direction = {Get DirectionsAvailable Index+1}
                Position = {GetPositionFromDirection Direction}
                ID = State.id
                NewState = {AdjoinList State [position#Position lastPositions#(Position|State.lastPositions) ]}
                NewState
            end

        else
            local NewDirection in
                NewDirection = {SelectDirection EnemiesPosition DirectionsAvailable State}
                if(NewDirection == nil) then
                    local Index in
                        Index = {OS.rand} mod {Length DirectionsAvailable 0}
                        Direction = {Get DirectionsAvailable Index+1}
                        Position = {GetPositionFromDirection Direction}
                        ID = State.id
                        NewState = {AdjoinList State [position#Position lastPositions#(Position|State.lastPositions) ]}
                        NewState
                    end
                else
                    Direction = NewDirection
                    Position = {GetPositionFromDirection Direction}
                    ID = State.id
                    NewState = {AdjoinList State [position#Position lastPositions#(Position|State.lastPositions) ]}
                    NewState
                end
            end
        end
           
    end
end
declare

NRow = 5 %10
NColumn = 10

Map = [[0 0 0 0 0 0 0 0 0 0]
[0 0 0 0 0 0 0 0 0 0]
[0 0 0 1 1 0 0 0 0 0]
[0 0 1 1 0 0 1 0 0 0]
[0 0 0 0 0 0 0 0 0 0]]

/** Move
    ID = unbound; Position = unbound; Direction = unbound
    State = current state of the submarine
    Select a random position and bind ID, Position to new Position and Direction to new Direction
*/ 
fun{Move ID Position Direction State}
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

    /** NotAlreadyVisited
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

    /** Last
    @pre 
        L = list
    @post
        return the last element of the list L
    */
    fun{Last L}
        fun{RLast L Acc}
            case L 
            of nil then Acc
            []H|T then {RLast T H}
            end
        end
    in
        {RLast L nil}
    end

    NewDirection
    NewPosition
    NewState
in
    NewDirection = {RandomDirection}
    {System.show 'la direction choisie pour Move est : ' #NewDirection}
    
    case NewDirection 
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

    {System.show 'la nouvelle position est : '#NewPosition}

    if(NewDirection == surface) then
        NewState = {AdjoinList State [surface#true lastPositions#nil ]} % reset the last positions visited since last surface phase
        ID = State.id
        Position = NewPosition
        Direction = NewDirection
        NewState %return

    elseif( {Not {IsPositionOnMap NewPosition} } ) then 
        {System.show 'The direction selected is outside the map'}
        {Move ID Position Direction State}
    
    elseif {IsIsland NewPosition.x NewPosition.y Map} then
        {System.show 'The direction selected correspond to an island'}
        {Move ID Position Direction State}

    elseif{IsAlreadyVisited NewPosition State} then
        {System.show 'The direction selected correspond to a spot already visited'}
        {Move ID Position Direction State}

    else

        NewState = {AdjoinList State [position#NewPosition lastPositions#(NewPosition|State.lastPositions)]}  /*Add the NewPosition To The position visited*/
        ID = State.id
        Position = NewPosition
        Direction = NewDirection
        NewState %return
    end
    
end 
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

ID Position Direction in

{Browse {Move ID Position Direction state(id: id(id:1 color:null name:null) 
                            position: pt(x:1 y:1) 
                            lastPositions: pt(x:2 y:1)|pt(x:2 y:2)|pt(x:3 y:2)|pt(x:4 y:2)|nil 
                            direction: east
                            surface: false
                            dive: false 
                            damage:0
                            loads: loads(mine:0 missile:0 drone:0 sonar:0)
                            weapons: weapons(mine:0 missile:0 drone:0 sonar:0)
                            mines: nil
                            )}}
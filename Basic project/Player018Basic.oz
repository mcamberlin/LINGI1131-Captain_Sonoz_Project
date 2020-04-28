functor
import
    Input
    System
    OS 
export
    portPlayer:StartPlayer
define

    InitPosition
    Move
    Dive
    ChargeItem 
    FireItem
    FireMine
    IsDead
    SayMove
    SaySurface
    SayCharge
    SayMinePlaced
    SayMissileExplode
    SayMineExplode
    SayPassingDrone
    SayAnswerDrone
    SayPassingSonar
    SayAnswerSonar 
    SayDeath
    SayDamageTaken

    ManhattanDistance
    PositionMine 
    PositionMissile
    RandomPosition
    IsIsland
    IsOnMap
    IsPositionOnMap

    StartPlayer
    TreatStream
in
    /** InitPosition
        ID = unbound; Position= unbound
        State = current state of the submarine
        bind ID and position to a random position on the map
    */
    fun{InitPosition ID Position State} 
        ID = State.id
        Position = {RandomPosition} 
        {AdjoinList State [position#Position lastPositions#[Position]]}
    end

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

        NewDirection
        NewPosition
        NewState
    in
        NewDirection = {RandomDirection}
        {System.show 'la direction choisie pour Move est : ' #NewDirection}
        {System.show 'son etat est : '#State}
        
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
            % reset the last positions visited since last surface phase
            NewState = {AdjoinList State [surface#true lastPositions#[NewPosition] ]}
            ID = State.id
            Position = NewPosition
            Direction = NewDirection
            NewState

        elseif( {Not {IsPositionOnMap NewPosition} } ) then 
            {System.show 'The direction selected is outside the map'}
            {Move ID Position Direction State}
        
        elseif {IsIsland NewPosition.x NewPosition.y Input.map} then
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
            NewState 
        end
        
    end 

    
    /** Dive 
        State = current state of the submarine
    */
    fun{Dive State}
        {System.show 'The player ' #State.id.id# 'dives'}
        State
    end

    /** ChargeItem
        ID = unbound ; KindItem = unbound
        State = current state of the submarine
        if(the loader reaches te right number of loads given in the Input file) then
            the id is bound
            a new item is created by binding it with the arg
            the player announce it 
        else
            the id is bound
            the item has nil value
            increase the load by one one the item selected (mine, missile, drone or sonar)
        return the new state of the submarine
    */
    fun{ChargeItem ID KindItem State}
        /** RandomItem
        @pre
        @post 
            return a random item (mine,missile, sonar, drone)
        */
        fun{RandomItem}
            NewItem = {OS.rand} mod 4
        in
            if(NewItem == 0) then mine
            elseif(NewItem == 1) then missile
            elseif(NewItem == 2) then sonar
            else 
                drone
            end
        end
        NewState NewLoad NewWeapons NewLoads NewItem
    in
        {System.show 'l etat du joueur est : ' #State}
        NewItem = {RandomItem}
        {System.show 'L item choisi dans chargeItem est : '#NewItem}

        case NewItem
        of missile then
            %Increase the loads of missile
            NewLoad = {AdjoinList State.loads [missile#(State.loads.missile+1)]}

            if(NewLoad.missile >= Input.missile) then 
                % new missile created: number of loading charges required to create a missile reached
                NewLoads = {AdjoinList NewLoad [missile#(NewLoad.missile - Input.missile)]}
                NewWeapons = {AdjoinList State.weapons [missile#(State.weapons.missile +1)]}
                
                NewState = {AdjoinList State [weapons#NewWeapons loads#NewLoads]}
                
                % the player should say that a new missile has been created by binding the given item
                KindItem = missile
                {System.show 'The number of missile has increased'}
            else
                KindItem = null
                NewState = {AdjoinList State [loads#NewLoad]}
            end  

        [] mine then
            %Increase the loads of mine
            NewLoad = {AdjoinList State.loads [mine#(State.loads.mine+1)]}

            if(NewLoad.mine >= Input.mine) then
                % new mine created: number of loading charges required to create a mine reached
                NewLoads = {AdjoinList NewLoad [mine#(State.loads.mine - Input.mine)]}
                NewWeapons = {AdjoinList State.weapons [mine#(State.weapons.mine+1)]}
                
                NewState = {AdjoinList State [weapons#NewWeapons loads#NewLoads]}

                % the player should say that a new item has been created by binding the given item
                KindItem = mine
                {System.show 'The number of mine has increased'}
            else
                KindItem = null
                NewState = {AdjoinList State [loads#NewLoad]} 
            end       
        [] sonar then 
            %Increase the loads of sonar
            NewLoad = {AdjoinList State.loads [sonar#(State.loads.sonar+1)]}

            if(NewLoad.sonar >= Input.sonar) then 
                % new sonar created: number of loading charges required to create a sonar reached
                NewLoads = {AdjoinList NewLoad [sonar#(State.loads.sonar - Input.sonar)]}
                NewWeapons = {AdjoinList State.weapons [sonar#(State.weapons.sonar+1)]}

                NewState = {AdjoinList State [weapons#NewWeapons loads#NewLoads]}

                % the player should say that a new sonar has been created by binding the given item
                KindItem = sonar
                {System.show 'The number of sonar has increased for player'}
            else
                KindItem = null
                NewState = {AdjoinList State [loads#NewLoad]} 
            end       
        [] drone then
            %Increase the loads of drone
            NewLoad = {AdjoinList State.loads [drone#(State.loads.drone+1)]}

            if(NewLoad.drone >= Input.drone) then 
                % new drone created: number of loading charges required to create a drone reached    
                NewLoads = {AdjoinList NewLoad [drone#(State.loads.drone - Input.drone)]}
                NewWeapons = {AdjoinList State.weapons [drone#(State.loads.drone+1)]}
            
                NewState = {AdjoinList State [weapons#NewWeapons loads#NewLoads]}
        
                % the player should say that a new drone has been created by binding the given item
                KindItem = drone
                {System.show 'The number of drone has increased for player'}
            else
                KindItem = null
                NewState = {AdjoinList State [loads#NewLoad]} 
            end   
        else
            skip
        end 
        ID = State.id
        NewState
    end


    /** FireItem
        ID = unbound; KindFire = unbound
        State = current state of the submarine
        permet d'utiliser un item disponible. Lie ID et l'item utilsé à Kindfire        
    */
    fun{FireItem ID KindFire State}
        /* 
        1. check wich item is available
        2. fire the item by decreasing the specific weapon 
        3. Bind ID and KindFire to the weapon   Comment demander position????
        */
        NewState NewWeapon in
        if State.weapons.missile > 0 then
            NewWeapon = {AdjoinList State.weapons [missile#State.weapons.missile-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            KindFire = missile({PositionMissile NewState.position})

        elseif State.weapons.mine > 0 then
            NewMines Position in
            Position = {PositionMine State.position}
            NewMines = Position|State.mines
            NewWeapon = {AdjoinList State.weapons [mine#State.weapons.mine-1]}
            NewState = {AdjoinList State [weapons#NewWeapon mines#NewMines]}
            ID = State.id
            KindFire = mine(Position) 
        
        elseif State.weapons.drone > 0 then
            NewWeapon = {AdjoinList State.weapons [drone#State.weapons.drone-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            local Random PositionSelected in
                PositionSelected = {RandomPosition}
                Random = {OS.rand} mod 2
                if(Random == 0) then 
                    KindFire = drone(row :PositionSelected.x)
                else
                    KindFire = drone(column :PositionSelected.y)
                end
            end

        elseif State.weapons.sonar > 0 then
            NewWeapon = {AdjoinList State.weapons [sonar#State.weapons.sonar-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            KindFire = sonar

        else 
            ID = State.id
            KindFire = null
            NewState = State
        end

        
        {System.show 'the weapon fired is '#KindFire}
        NewState
        
    end

    
    

    /** FireMine(ID Mine) 
    @pre
        ID = unbound
        Mine = unbound
    @post
        if a mine is ready to be fired, we randomly decided to explode it or not.
    */
    fun{FireMine ID Mine State}
        Fire NewState in
        case State.mines 
        of M|T then
            Fire = {OS.rand} mod 2
            if Fire == 0 then %The first mine of the list explodes
                Mine = M
                ID = State.id
                NewState = {AdjoinList State [mines#T]}
                NewState
            else %Do not want to explode a mine
                Mine = null
                ID = State.id
                State
            end
        else % None mine to place
            Mine = null
            ID = State.id
            State
        end
    end

    /** IsDead
    the player is dead if his damage is greater than Input.maxDamage
    */
    fun{IsDead Answer State}
        Answer = State.damage >= Input.maxDamage
        State
    end 

    /** SayMove 
    @pre
        ID = ID of the submarine
        Direction = NewDirection of the submarine
    @post
        Announce to the others that the player with id ID has changed direction to Direction
    */
    fun{SayMove ID Direction State}
        {System.show 'Le joueur a changé de direction vers'#Direction}
        State
    end


    /** SaySurface 
    @pre 
        ID = Bound
        State
    @post
    */
    fun{SaySurface ID State}
        {System.show 'the player has made surface'}
        State
    end


    /** SayCharge 
    @pre
        ID = ID of the submarine
        Direction = NewDirection of the submarine
    @post
        Announce to the others that the player with id ID has charged the item KindItem
    */
    fun{SayCharge ID KindItem State}
        if KindItem == null then {System.show 'the player cannot charge an item'}
        else
            {System.show 'The player charged a'}
            {System.show KindItem}
        end
        State
    end

    /** SayMinePlaced 
    */
    fun{SayMinePlaced ID State}
        {System.show 'A mine has been placed by the player : '#ID.id}
        
        State
    end


    /** SayMissileExplode 
    @pre 
        ID = the id of the player that made a missile explode 
        Position = the position of the explosion
        Message (unbound)
    @post 
        Bind message to informations about the damages of the player indentified by State :
            if Manhattan distance >= 2 : no damage -> Message = nil
            elseif                    == 1 : 1 damage
            else                    == 0 : 2 damages

            if death : Message = sayDeath(ID) and <surface> = true (on a choisi de faire monter en surface une fois que le submarine est mort)
            else : Message = sayDamageTaken(ID Damage LifeLeft)
    */
    fun{SayMissileExplode ID Position Message State}
        Distance NewState NewDamage
    in
        
        Distance = {ManhattanDistance Position State.position}
        case Distance 
        of 0 then 
            NewDamage = State.damage +2 
            if NewDamage >= Input.maxDamage then /*Dead */
                Message = sayDeath(State.id)
                NewState = {AdjoinList State [damage#NewDamage surface#true]}
                NewState
            else
                NewState = {AdjoinList State [damage#NewDamage]}
                Message = sayDamageTaken(NewState.id 2 Input.maxDamage-NewState.damage)
                NewState
            end
        [] 1 then 
            NewDamage = State.damage +1 
            if NewDamage >= Input.maxDamage then  /*Dead */
                Message = sayDeath(State.id)
                NewState = {AdjoinList State [damage#NewDamage surface#true]}
                NewState
            else
                NewState = {AdjoinList State [damage#NewDamage]}
                Message = sayDamageTaken(NewState.id 1 Input.maxDamage-NewState.damage)
                NewState
            end
        else %Distance >= 2
            Message = null
            State
        end
    end
    

    /** SayMineExplode 
        ID indicates the id of the player that made a mine explode 
        Position is the position of the explosion
        Message (unbound) contains the informations about the damages of the player indentified by State :
            - Manhattan distance >= 2 : no damage -> Message = null
            -                    == 1 : 1 damage
            -                    == 0 : 2 damages
            If death : Message = sayDeath(ID)
            If no death : Message = sayDamageTaken(ID Damage LifeLeft)
    */
    fun{SayMineExplode ID Position Message State}
        Distance NewState NewDamage
    in
        Distance = {ManhattanDistance Position State.position}
        case Distance 
        of 0 then 
            NewDamage = State.damage +2 
            if NewDamage >= Input.maxDamage then /*Dead */
                Message = sayDeath(State.id)
                NewState = {AdjoinList State [damage#NewDamage surface#true]}
                NewState
            else
                NewState = {AdjoinList State [damage#NewDamage]}
                Message = sayDamageTaken(NewState.id 2 Input.maxDamage-NewState.damage)
                NewState
            end
        [] 1 then 
            NewDamage = State.damage +1 
            if NewDamage >= Input.maxDamage then  /*Dead */
                Message = sayDeath(State.id)
                NewState = {AdjoinList State [damage#NewDamage surface#true]}
                NewState
            else
                NewState = {AdjoinList State [damage#NewDamage]}
                Message = sayDamageTaken(NewState.id 1 Input.maxDamage-NewState.damage)
                NewState
            end
        else
            Message = null
            State
        end
    end


    /** SayPassingDrone 
    @pre
        Drone 
        ID
        Answer
        State
    @post
        Answer the question contained in the drone in arg
        ID is bound 
        Answer is bound to true if the drone is on the row/column given in the drone
        false otherwise
    */
    fun{SayPassingDrone Drone ID Answer State}
        if(State.damage >= Input.maxDamage) then %the submarine is already dead
            ID = nil
            Answer = nil
            State
        else
            case Drone
            of drone(row X) then
                if(State.position.x == X) then
                    Answer = true
                    ID = State.id
                    State
                else
                    Answer = false
                    ID = State.id
                    State
                end
            [] drone(column Y) then
                if(State.position.y == Y) then
                    Answer = true
                    ID = State.id
                    State
                else
                    Answer = false
                    ID = State.id
                    State
                end
            else
                State
            end
        end
    end
    

    /** SayAnswerDrone 
    */
    fun{SayAnswerDrone Drone ID Answer State}
        case Drone
        of drone(row X) then
            if Answer then 
                {System.show 'The player ' #State.id.id# ' detected an ennemy in row '#X}
            else
                {System.show 'The player' # State.id.id# ' did not detect an ennemy in row '# X}
            end
        [] drone(column Y) then 
            if Answer then 
                {System.show 'The player ' # State.id.id # 'detected an ennemy in column '# Y}
            else
                {System.show 'The player ' # State.id.id # ' did not detect an ennemy in column '# Y}
            end
        else
            {System.show 'Bad initialisation of Drone.'}
        end
        State
    end


    /** SayPassingSonar 
    @pre 
        ID
        Answer
        State
    @post
        Answer a position with one coordinate right and the other wrong
        ID is bound 
        Answer is bound to true if the drone is on the row/column given in the drone
        false otherwise
    */
    fun{SayPassingSonar ID Answer State}
        Rand RandomPos
    in
        if(State.damage >= Input.maxDamage) then %the submarine is already dead
            ID = nil
            Answer = nil
            State
        else
            RandomPos = {RandomPosition}
            Rand = {OS.rand} mod 2
            if(Rand == 0) then
                Answer = pt(x:RandomPos.x y:State.position.y)
                ID = State.id
                State
            else
                Answer = pt(x:State.position.x y:RandomPos.y)
                ID = State.id
                State
            end
        end
    end
    

    /** SayAnswerSonar 
    */
    fun{SayAnswerSonar ID Answer State}
        {System.show 'The player s sonar detect an ennemy around the position ' #Answer}
        State
    end

    /** SayDeath 
    @pre
        ID = ID of the new dead submarine
        State
    @post
        Display an informative message of the death of the player id
    */
    fun{SayDeath ID State}
        {System.show 'This player is dead :'#ID.id}
        State
    end

    /** SayDamageTaken 
    */
    fun {SayDamageTaken ID Damage LifeLeft State}
        {System.show 'The player take a total damage of '#Damage}
        {System.show 'His health point is '#LifeLeft}
        State        
    end


    /**PositionMine 
    @pre 
        Position
    @post
        return a random position that is bounded by minDistanceMine and maxDistanceMine around Position*/
    fun{PositionMine Position}
        Pos XMine YMine DeltaX DeltaY CondX CondY in 
        %Delta 
        DeltaX = {OS.rand} mod (Input.maxDistanceMine + 1)
        if DeltaX < Input.minDistanceMine then
            DeltaY = Input.minDistanceMine + {OS.rand} mod (Input.maxDistanceMine-DeltaX)
        else
            DeltaY = {OS.rand} mod (Input.maxDistanceMine-DeltaX)
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
        if {IsOnMap Pos.x Pos.y} andthen {Not {IsIsland Pos.x Pos.y Input.map} } then 
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
        DeltaX = {OS.rand} mod (Input.maxDistanceMissile + 1)
        if DeltaX < Input.minDistanceMissile then
            DeltaY = Input.minDistanceMissile + {OS.rand} mod (Input.maxDistanceMissile-DeltaX)
        else
            DeltaY = {OS.rand} mod (Input.maxDistanceMissile-DeltaX)
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

    /**ManhattanDistance
     */
    fun{ManhattanDistance Position1 Position2}
        {Abs Position1.x-Position2.x} + {Abs Position1.y-Position2.y}
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


    /** RandomPosition
    @pre
    @post
        return a random position in water in the map
    */
    fun{RandomPosition}
        X Y  in
        X = {OS.rand} mod Input.nRow+1
        Y = {OS.rand} mod Input.nColumn+1
        %Check if on water
        if {IsIsland X Y Input.map} then {RandomPosition}
        else
            pt(x:X y:Y)
        end
    end

    /** StartPlayer
        @pre
            Color
            ID
        @post 
            Create a port representing the player
    */
    fun{StartPlayer Color ID}
        Stream
        Port
        InitialState
    in
        {NewPort Stream Port}
        InitialState = state(id: id(id:ID color:Color name:'JoueurBasic') 
                            position: pt(x:1 y:1) 
                            lastPositions: nil 
                            damage:0
                            loads: loads(mine:0 missile:0 drone:0 sonar:0)
                            weapons: weapons(mine:0 missile:0 drone:0 sonar:0)
                            mines: nil
                            )
        thread
            {TreatStream Stream InitialState}
        end
        Port
    end

    /** TreatStream
        Stream = a stream of input data for the player
        State = a record 
    */
    proc{TreatStream Stream State} 
        case Stream 
        of nil then skip
        [] initPosition(ID Position)|T then 
            {TreatStream T {InitPosition ID Position State}}
        [] move(ID Position Direction)|T then 
            {TreatStream T {Move ID Position Direction State}}
        [] dive|T then
            {TreatStream T {Dive State}}
        [] chargeItem(ID KindItem)|T then
            {TreatStream T {ChargeItem ID KindItem State}}
        [] fireItem(ID KindFire)|T then 
            {TreatStream T {FireItem ID KindFire State}}
        [] fireMine(ID Mine)|T then
            {TreatStream T {FireMine ID Mine State}}
        [] isDead(Answer)|T then 
            {TreatStream T {IsDead Answer State}}
        [] sayMove(ID Direction)|T then
            {TreatStream T {SayMove ID Direction State}}
        [] saySurface(ID)|T then
            {TreatStream T {SaySurface ID State}}
        [] sayCharge(ID KindItem)|T then
            {TreatStream T {SayCharge ID KindItem State}}
        [] sayMinePlaced(ID)|T then
            {TreatStream T {SayMinePlaced ID State}}
        [] sayMissileExplode(ID Position Message)|T then
            {TreatStream T {SayMissileExplode ID Position Message State}}
        [] sayMineExplode(ID Position Message)|T then 
            {TreatStream T {SayMineExplode ID Position Message State}}
        [] sayPassingDrone(Drone ID Answer)|T then
            {TreatStream T {SayPassingDrone Drone ID Answer State}}
        [] sayAnswerDrone(Drone ID Answer)|T then 
            {TreatStream T {SayAnswerDrone Drone ID Answer State}}
        [] sayPassingSonar(ID Answer)|T then
            {TreatStream T {SayPassingSonar ID Answer State}} 
        [] sayAnswerSonar(ID Answer)|T then 
            {TreatStream T {SayAnswerSonar ID Answer State}}
        [] sayDeath(ID)|T then
            {TreatStream T {SayDeath ID State}}
        [] sayDamageTaken(ID Damage LifeLeft)|T then
            {TreatStream T {SayDamageTaken ID Damage LifeLeft State}}
        else
            {System.show 'MESSAGE NOT UNDERSTOOD IN TREATSTREAM IN PLAYER'}
        end
    end
end
/** State
state( id(id<idNum> color:<color> name:Name) 
                position:<position> 
                lastPositions:nil | <position>
                direction:<direction> 
                surface: <true>|<false>
                dive: <true>|<false>
                loads: loads(mine:x missile:y drone:z sonar: u) 
                weapons: weapons(mine:x missile:y drone:z sonar:u))
*/
%http://mozart2.org/mozart-v1/doc-1.4.0/tutorial/node3.html
functor
import
    Input
    QTk at 'x-oz://system/wp/QTk.ozf'
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

    Item
    KindItem

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
        local
            /*Ouvre une fenetre pour demander la position initiale */
            fun{AskPosition}
                Position X Y in
                Position = {QTk.dialogbox load(defaultextension:"qdw" 
                                    initialdir:"." 
                                title:"Choose a initiale position : " 
                                initialfile:"" 
                                filetypes:q("Position" q("X" X) q("Y" Y) ) ) }  %normalement ouvre une fenetre mais pas sur
                if Position.X > Input.nRow then skip end 
                if Position.Y > Input.nColumn then skip end 
                Position
            end
        in
            ID = State.id
            Position = {RandomPosition} %{AskPosition}
            {AdjoinList State [position#Position]} %return le nouvel etat
        end
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
            {Contains State.lastPositions Position}
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
        case NewDirection 
        of surface then 
            NewPosition = {Last State.lastPositions}
        [] north then 
            NewPosition = pt(x:(Position.x-1) y:Position.y)
        [] south then 
            NewPosition = pt(x:(Position.x+1) y:Position.y)
        [] east then 
            NewPosition = pt(x:Position.x y:(Position.y+1))
        else /* west*/
            NewPosition = pt(x:Position.x y:(Position.y-1))
        end 

        if( {Not {IsPositionOnMap NewPosition} } ) then 
            {System.show 'The direction selected is outside the map'}
            {Move ID Position Direction State}
        
        elseif {IsIsland NewPosition.x NewPosition.y Input.map} then
            {System.show 'The direction selected correspond to an island'}
            {Move ID Position Direction State}

        elseif {IsAlreadyVisited NewPosition State} then
            {System.show 'The direction selected correspond to a spot already visited'}
            {Move ID Position Direction State}

        else
            ID = State.id
            Position = NewPosition
            Direction = NewDirection
            if(NewDirection == surface) then
                NewState = {AdjoinList State [surface#true lastPositions# [nil] ]} % reset the last positions visited since last surface phase
            else
                NewState = {AdjoinList State [position#NewPosition lastPositions#({OS.Append lastPositions NewPosition})]}  /*Add the NewPosition To The position visited*/
            end
            
            NewState %return
        end
    end 

    
    /** Dive 
        State = current state of the submarine
    */
    fun{Dive State}
        {AdjoinList State [dive#true]}
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
            the item has null value
            increase the load by one one the item selected (mine, missile, drone or sonar)
        return the new state of the submarine
    */
    fun{ChargeItem ID KindItem State}
        NewState NewLoad NewWeapons NewLoads in
        case KindItem
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
                {System.show {OS.Append 'The number of missile has increased for player ' NewState.id.id}}
            else
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
                {System.show {OS.Append 'The number of mine has increased for player ' State.id.id}}
            else
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
                {System.show {OS.Append 'The number of sonar has increased for player ' State.id.id}}
            else
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
                {System.show {OS.Append 'The number of drone has increased for player ' State.id.id}}
            else
                NewState = {AdjoinList State [loads#NewLoad]} 
            end   
        else
            skip
        end 
        ID = State.id
        NewState
    end


    /** FireItem
        ID = unbound; KindItem = unbound
        State = current state of the submarine
        permet d'utiliser un item disponible. Lie ID et l'item utilsé à Kindfire
        state(id:id(id:ID color:Color name:'name') position:pt(x:1 y:1) dive:false mine:0 missile:0 drone:0 sonar:0)
        Comprend pas comment envoyer un item....
    */
    fun{FireItem ID KindFire State}
        /* 
        1. check wich item is available
        2. fire the item by decreasing the specific weapon 
        3. Bind ID and KindFire to the weapon   Comment demander position????
        */
        NewState NewWeapon TargetPosition in
        if State.weapons.mine > 0 then
            NewWeapon = {AdjoinList State.weapons [mine#State.weapons.mine-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            FireItem = mine({PositionMine NewState.position})        %Demander position ???????????????
            NewState
        elseif State.weapons.missile > 0 then
            NewWeapon = {AdjoinList State.weapons [missile#State.weapons.missile-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            FireItem = missile({PositionMissile NewState.position})        %Demander position ???????????????
            NewState

        elseif State.weapons.drone > 0 then
            NewWeapon = {AdjoinList State.weapons [drone#State.weapons.drone-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            FireItem = drone(row 1)       %Demander position ???????????????
            NewState

        elseif State.weapons.sonar > 0 then
            NewWeapon = {AdjoinList State.weapons [sonar#State.weapons.sonar-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            FireItem = sonar
            NewState

        else 
            KindFire = null
            State
        end
        
    end

    
    

    /** FireMine(ID Mine) 
    */

    /** IsDead
    the player is dead if his damage is greater than Input.maxDamage
    */
    fun{IsDead Answer State}
        Answer = State.damage >= Input.maxDamage
        State
    end 

    /** SayMove 
    */
    fun{SayMove ID Direction State}
        {System.show {OS.Append {OS.Append {OS.Append 'The player ' ID} 'moved to the '} Direction}}
        State
    end


    /** SaySurface 
    */
    fun{SaySurface ID State}
        if(State.surface) then 
            {System.show {OS.Append {OS.Append 'The player ' State.id.id} ' has made surface.'}}
            ID = nil
        else 
            {System.show {OS.Append {OS.Append 'The player ' State.id.id} ' is underwater.'}}
            ID = State.id
        end

        
        State
    end


    /** SayCharge 
    */

    /** SayMinedPlaced 
    */
    fun{SayMinePlaced ID State}
        {System.show {OS.Append {OS.Append 'The player ' State.id.id} ' placed a mine.'}}
        ID = State.id
        State
    end


    /** SayMissileExplode 
        ID indicates the id of the player that made a missile explode 
        Position is the position of the explosion
        Message (unbound) contains the informations about the damages of the player indentified by State :
            - Manhattan distance >= 2 : no damage -> Message = null
            -                    == 1 : 1 damage
            -                    == 0 : 2 damages
            If death : Messge = sayDeath(ID)
            If no death : Message = sayDamageTaken(ID Damage LifeLeft)

        Note : c'est idem que sayMineExplode mais verifie quand meme ce que j'ai fait ;)
    */


    /** SayMineExplode 
        ID indicates the id of the player that made a mine explode 
        Position is the position of the explosion
        Message (unbound) contains the informations about the damages of the player indentified by State :
            - Manhattan distance >= 2 : no damage -> Message = null
            -                    == 1 : 1 damage
            -                    == 0 : 2 damages
            If death : Messge = sayDeath(ID)
            If no death : Message = sayDamageTaken(ID Damage LifeLeft)
    */
    fun{SayMineExplode ID Position Message State}
        Distance NewState in
        Distance = {ManhattanDistance Position State.position}
        case Distance 
        of 0 then 
            NewState = {AdjoinList State [damage#State.damage+2]}
            if NewState.damage >= Input.maxDamage then
            %if death
                Message = sayDeath(NewState.id)
                NewState
            else
                Message = sayDamageTaken(NewState.id 2 Input.maxDamage-NewState.damage)
            end
        [] 1 then 
            NewState = {AdjoinList State [damage#State.damage+1]}
            if NewState.damage >= Input.maxDamage then
            %if death
                Message = sayDeath(NewState.id)
                NewState
            else
                Message = sayDamageTaken(NewState.id 1 Input.maxDamage-NewState.damage)
            end
        else
            Message = null
            State
        end
    end


    /** SayPassingDrone 
    */
    

    /** SayAnswerDrone 
    */
    fun{SayAnswerDrone Drone ID Answer State}
        case Drone
        of drone(row X) then
            if Answer then {System.show {OS.Append {OS.Append {OS.Append 'The player ' State.id.id} ' detected an ennemy in row '} X}}
            else
                {System.show {OS.Append {OS.Append {OS.Append 'The player ' State.id.id} ' did not detect an ennemy in row '} X}}
            end
        [] drone(column Y) then 
            if Answer then {System.show {OS.Append {OS.Append {OS.Append 'The player ' State.id.id} ' detected an ennemy in column '} Y}}
            else
                {System.show {OS.Append {OS.Append {OS.Append 'The player ' State.id.id} ' did not detect an ennemy in column '} Y}}
            end
        else
            {System.show 'Bad initialisation of Drone.'}
        end
        State
    end


    /** SayPassingSonar 
    */
    

    /** SayAnswerSonar 
    */
    fun{SayAnswerSonar ID Answer State}
        {System.show {OS.Append {OS.Append {OS.Append 'The player ' State.id.id} ' detect an ennemy around the position '} Answer}}
        State
    end

    /** SayDeath 
    */

    /** SayDamageTaken 
    */
    fun {SayDamageTaken ID Damage LifeLeft State}
        {System.show {OS.Append {OS.Append 
                            {OS.Append 
                                    {OS.Append 'The player ' State.id.id} 
                                    ' received '} 
                            Damage}}}
        {System.show {OS.Append {OS.Append 
                            {OS.Append 
                                    {OS.Append 'The player ' State.id.id} 
                                    ' has a total health point of '} 
                            LifeLeft}}}
        State        
    end


    /**PositionMine 
        give a random position that is bounded by minDistanceMine and maxDistanceMine around Position*/
    fun{PositionMine Position}
        Pos XMine YMine in 
        XMine = Position.x + Input.minDistanceMine + {OS.rand} mod (Input.maxDistanceMine-Input.minDistanceMine)
        YMine = Position.y + Input.minDistanceMine + {OS.rand} mod (Input.maxDistanceMine-Input.minDistanceMine)
        Pos = pt(x:XMine y:YMine)
        if {IsOnMap Pos.x Pos.y} then {PositionMine Position}
        else 
            Position 
        end

    end

    /**PositionMissile
        give a random position that is bounded by minDistanceMissile and maxDistanceMissile around Position*/
    fun{PositionMissile Position}
        Pos XMissile YMissile in 
        XMissile = Position.x + Input.minDistanceMissile + {OS.rand} mod (Input.maxDistanceMissile-Input.minDistanceMissile)
        YMissile = Position.y + Input.minDistanceMissile + {OS.rand} mod (Input.maxDistanceMissile-Input.minDistanceMissile)
        Pos = pt(x:XMissile y:YMissile)
        if {IsOnMap Pos.x Pos.y} then {PositionMissile Position}
        else 
            Position 
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
                        {IsIsland X Y-1 T2}
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
        if(X<Input.nRow andthen X>0) then
            if(Y<Input.nColumn andthen Y>0) then
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
        select a random position in water in the map
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
        InitialState = state(id: id(id:ID color:Color name:Name) 
                            position: pt(x:1 y:1) 
                            lastPosition: nil 
                            direction: east
                            surface: true
                            dive: false 
                            damage:0
                            loads: loads(mine:0 missile:0 drone:0 sonar:0)
                            weapons: weapons(mine:0 missile:0 drone:0 sonar:0)
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
        [] fireItem(ID FireItem)|T then 
            {TreatStream T {FireItem Item KindItem State}}
        [] firemine(ID Mine)|T then
            {TreatStream T {FireMine ID Mine State}}
        [] isDead(Answer)|T then 
            {TreatStream T {IsDead Answer State}}
        [] sayMove(ID Direction)|T then
            {TreatStream T {SayMove ID Direction State}}
        [] saySurface(ID)|T then
            {TreatStream T {SaySurface ID State}}
        %[] sayCharge(ID KindItem)|T then
        [] sayMinePlaced(ID)|T then
            {TreatStream T {SayMinePlaced ID State}}
        %[] sayMissileExplode(ID Position Message)|T then
        [] sayMineExplode(ID Position Message)|T then 
            {TreatStream T {SayMineExplode ID Position Message State}}
        %[] sayPassingDrone(Drone ID Answer)|T then
        [] sayAnswerDrone(Drone ID Answer)|T then 
            {TreatStream T {SayAnswerDrone Drone ID Answer State}}
        %[] sayPassingSonar(ID Sonar)|T then
        [] sayAnswerSonar(ID Answer)|T then 
            {TreatStream T {SayAnswerSonar ID Answer State}}
        %[] sayDeath(ID)|T then
        [] sayDamagetaken(ID Damage Lifeleft)|T then
            {TreatStream T {SayDamageTaken ID Damage Lifeleft State}}
        else
            skip
        end
    end
end
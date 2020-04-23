/** State
state( id(id<idNum> color:<color> name:Name) 
                position:<position> 
                lastPositions:nil | <position>
                direction:<direction> 
                surface: <true>|<false>
                dive: <true>|<false>
                loads: loads(mine:x missile:y drone:z sonar: u) 
                weapons: weapons(mine:x missile:y drone:z sonar:u))
                enemy: enemy(id:i position:P)
                enemies: enemies(id:i lastKnownPosition:P)  | nil


Second level of player
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

    ManhattanDistance
    PositionMine 
    PositionMissile
    RandomPosition
    IsIsland
    IsOnMap
    IsPositionOnMap

    StartPlayer
    TreatStream
    Get
    Change
in

    /** Useful functions ----------------------------------------------------------------------*/

    /**
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

    /**
    @pre 
        L = list
        I = index
        Item = what to change
    @post
        return a list where the I th element has been replaced by the element Item
    */
    fun{Change L I Item}
        case L
        of H|T then
            if(I == 1) then 
                Item|T
            else
                H|{Change T I-1 Item}
            end
        else 
            nil
        end
    end
    /** End useful functions ----------------------------------------------------------------------*/


    /** InitPosition
        ID = unbound; Position= unbound
        State = current state of the submarine
        bind ID and position to a random position on the map

        Arthur : Rien a changer 
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
            {AdjoinList State [position#Position lastPositions#[Position]]} %return le nouvel etat
        end
    end

    /** Move
        ID = unbound; Position = unbound; Direction = unbound
        State = current state of the submarine
        Select a random position and bind ID, Position to new Position and Direction to new Direction

        Arthur : garder en mémoire la derniere position de chaque joueur et se deplacer vers le plus proche 
    */ 
    fun{Move ID Position Direction State}


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

        /**
        @pre  
            L = liste of ennemies
        @post
            return the direction to of the nearest enemy
        */
        fun{SelectDirection State} 
            /**
            @pre  
                L = liste of ennemies
            @post
                return the ID to of the nearest enemy
            */
            fun{NearestEnemy L ID MinDist State}
                case L
                of H|T then 
                    case H 
                    of enemy(id:I position:P) then
                        %One of the two position is knwon
                        if ( (P.x == nil andthen P.y \= nil) orelse (P.x \= nil andthen P.y == nil) ) then
                            DistX DistY in 
                            if(P.x \= nil) then
                                {Browse 'DistX' #DistX}
                                DistX = {Abs P.x - State.position.x}
                                if(MinDist > DistX) then
                                    {NearestEnemy T I DistX State}
                                else
                                    {NearestEnemy T ID MinDist State}
                                end
                            else
                                DistY = {Abs P.y - State.position.y}
                                {Browse 'DistY' #DistY}
                                if(MinDist > DistY) then
                                    {Browse 'ici'}
                                    {NearestEnemy T I DistY State}
                                else
                                    {NearestEnemy T ID MinDist State}
                                end
                            end
                        else
                            {SelectDirection T ID MinDist State}
                        end
                    else
                        ~1
                        {System.show 'Problem... This case should never occur'}
                    end
                else
                    ID
                end
            end
            I %ID of the nearest ennemy
            Enemy
        in
            I = {NearestEnemy State.ennemies 1 {Max Input.nRow Input.nColumn} State}
            Enemy = {Get State.ennemies I}
            
            if(EnemyPosition.x \= nil) then
                if(EnemyPosition.x > State.position.x) then south
                elseif(EnemyPosition.x < State.position.x) then north
                else
                    if(EnemyPosition.y > State.position.y) then east
                    else west
                    end
                end
            elseif(EnemyPosition.y \= nil) then
                if(EnemyPosition.y > State.position.y) then east
                elseif(EnemyPosition.y < State.position.y) then west
                else
                    south
                end
            else
                surface
            end

        end

        NewDirection
        NewPosition
        NewState
    in


        NewDirection = {SelectDirection State}
        {System.show 'la direction choisie pour Move est : ' #NewDirection}
        
        case NewDirection 
        of surface then 
            NewPosition = {Last State.lastPositions}
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
            NewState %return
        end
        
    end 

    
    /** Dive 
        State = current state of the submarine

        Arthur : rien a changer 
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
            the item has nil value
            increase the load by one one the item selected (mine, missile, drone or sonar)
        return the new state of the submarine

        Arthur : rien a changer 
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
        state(id:id(id:ID color:Color name:'name') position:pt(x:1 y:1) dive:false mine:0 missile:0 drone:0 sonar:0)
        
        
        Arthur : verifier si un ennemi est assez proche que pour le toucher en plus de regarder si on a des munitions 
    */
    fun{FireItem ID KindFire State}
        /* 
        1. check wich item is available
        2. fire the item by decreasing the specific weapon 
        3. Bind ID and KindFire to the weapon   Comment demander position????
        */
        NewState NewWeapon in
        if State.weapons.mine > 0 then
            NewMines Position in
            Position = {PositionMine State.position}
            NewMines = Position|State.mines
            NewWeapon = {AdjoinList State.weapons [mine#State.weapons.mine-1]}
            NewState = {AdjoinList State [weapons#NewWeapon mines#NewMines]}
            ID = State.id
            KindFire = mine(Position) 

        elseif State.weapons.missile > 0 then
            NewWeapon = {AdjoinList State.weapons [missile#State.weapons.missile-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            KindFire = missile({PositionMissile NewState.position})   

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


        Arthur : exploser une mine si elle fait du degat a un ennemi
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

    Arthur : rien a chnager 
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

        Arthur : Il faut interpreter les msg pour tous les say
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
        if(State.surface) then 
            {System.show 'the player has made surface'}
        else 
            {System.show 'The player is underwater'}
        end
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
            Message = nil
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
            Message = nil
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
        if(State.damage == Input.maxDamage) then %the submarine is already dead
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
        @pre
            Drone = drone previously
            ID = id of the submarine that send the response
            Anwser = reponse of the question in the drone
        @post
            update the estimate position of the submarine ID 
    */
    fun{SayAnswerDrone Drone ID Answer State}
        case Drone
        of drone(row X) then
            if Answer then 
                % The submarine ID is located in row X
                % => Update lastPositionKnown
                NewPosition NewEnemy NewEnemies NewState in
                NewPosition = position(x:X y:nil)
                NewEnemy = enemy(id:ID position:NewPosition)
                NewEnemies = {Change State.enemies ID NewEnemy}
                NewState = {AdjoinList State [enemies#NewEnemies]}
                {System.show 'The player ' #State.id.id# ' detected the submarine ' #ID# ' in row '#X}
                NewState
            else
                {System.show 'The player' # State.id.id# ' do not detect an enemy in row '# X}
                State
            end

        [] drone(column Y) then 
            if Answer then 
                % The submarine ID is located in column Y
                % => Update lastPositionKnown
                NewPosition NewEnemy NewEnemies NewState in
                NewPosition = position(x:nil y:Y)
                NewEnemy = enemy(id:ID position:NewPosition)
                NewEnemies = {Change State.enemies ID NewEnemy}
                NewState = {AdjoinList State [enemies#NewEnemies]}
                {System.show 'The player ' #State.id.id# ' detected the submarine ' #ID# ' in column '#Y}
                NewState
            else
                {System.show 'The player ' # State.id.id # ' did not detect an enemy in column '# Y}
                State
            end
        else
            {System.show 'Bad initialisation of Drone.'}
            State
        end
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
        if(State.damage == Input.maxDamage) then %the submarine is already dead
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
         {System.show 'The player s sonar detect an enemy around the position ' #Answer}
        case Answer
        of pt(x:X y:Y) then
            CurrentEnemy CurrentPosition in 
            CurrentEnemy = {Get State.enemies ID}
            CurrentPosition = CurrentEnemy.position
            % First sonarAnwser
            if(CurrentPosition.x == nil andthen CurrentPosition.y == nil) then
                NewPosition NewEnemy NewEnemies NewState in
                NewPosition = position(x:X y:Y)
                NewEnemy = enemy(id:ID position:NewPosition)
                NewEnemies = {Change State.enemies ID NewEnemy}
                NewState = {AdjoinList State [enemies#NewEnemies]}






            % A position was already known for this submarine
            if(CurrentPosition.x \= nil andthen CurrentPosition.y \= nil) then
                if(CurrentPosition.x == X andthen CurrentPosition.y == Y) then  %the submarine didn't move
                    State
                else
                    %Check which coordonate anwsered is correct
                    if(CurrentPosition.x == X ) then
                        %The x coordonate is the same as the previous known, therefore the correct coordonate answered is the y one.
                        %Update the y coordonate for this submarine
                        NewPosition NewEnemy NewEnemies NewState in
                        NewPosition = position(x:X y:Y)
                        NewEnemy = enemy(id:ID position:NewPosition)
                        NewEnemies = {Change State.enemies ID NewEnemy}
                        NewState = {AdjoinList State [enemies#NewEnemies]}
                        {System.show 'The player ' #State.id.id# ' think that the submarine ' #ID# ' is located at position '#NewPosition}
                        NewState
                    elseif(CurrentPosition.y == Y) then
                        %The x coordonate is the same as the previous known, therefore the correct coordonate answered is the y one.
                        %Update the y coordonate for this submarine
                        % The submarine ID is located in row X
                        % => Update lastPositionKnown
                        NewPosition NewEnemy NewEnemies NewState in
                        NewPosition = position(x:X y:Y)
                        NewEnemy = enemy(id:ID position:NewPosition)
                        NewEnemies = {Change State.enemies ID NewEnemy}
                        NewState = {AdjoinList State [enemies#NewEnemies]}
                        {System.show 'The player ' #State.id.id# ' think that the submarine ' #ID# ' is located at position '#NewPosition}
                        NewState

                end   
                
 


            else

            end

        else

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
        return a random position that is bounded by minDistanceMine and maxDistanceMine around Position

        Arthur : poser la mine pres d'un enemi ou au le plus proche possible de lui
    */
    fun{PositionMine Position}
        Pos XMine YMine DeltaX DeltaY CondX CondY in 
        %Delta 
        DeltaX = Input.minDistanceMine + {OS.rand} mod (Input.maxDistanceMine-Input.minDistanceMine)
        DeltaY = Input.minDistanceMine + {OS.rand} mod (Input.maxDistanceMine-Input.minDistanceMine)
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
        give a random position that is bounded by minDistanceMissile and maxDistanceMissile around Position

        Arthur : idem que pour positionMine essayer de toucher l'ennemi le plus proche     
    */
    fun{PositionMissile Position}
        Pos XMissile YMissile DeltaX DeltaY CondX CondY in 
        %Delta 
        DeltaX = Input.minDistanceMissile + {OS.rand} mod (Input.maxDistanceMissile-Input.minDistanceMissile)
        DeltaY = Input.minDistanceMissile + {OS.rand} mod (Input.maxDistanceMissile-Input.minDistanceMissile)
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
        if(Position1 == nil) then nil
        elseif(Position2 == nil) then nil
        else
            {Abs Position1.x-Position2.x} + {Abs Position1.y-Position2.y}
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
        /** CreateEnemies
        @pre
            Nb = number of enemies to create
        @post
            return a list of enemies with position pt(x:nil y:nil)
         */
        fun{CreateEnemies Nb}
            if(Nb==0) then
                nil
            else
                enemy(id: (Input.nbPlayer - Nb +1) x:nil y:nil)| {CreateEnemies Nb-1}
            end
        end
    in
        {NewPort Stream Port}
        InitialState = state(id: id(id:ID color:Color name:Name) 
                            position: pt(x:1 y:1) 
                            lastPositions: nil 
                            direction: east
                            surface: true
                            dive: false 
                            damage:0
                            loads: loads(mine:0 missile:0 drone:0 sonar:0)
                            weapons: weapons(mine:0 missile:0 drone:0 sonar:0)
                            mines: nil
                            enemies: {CreateEnemies Input.nbPlayer}
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
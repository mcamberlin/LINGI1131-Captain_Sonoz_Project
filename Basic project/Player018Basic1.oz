/** State
state( id(id<idNum> color:<color> name:Name) 
                position:<position> 
                lastPosition:<position>
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
    SayAnwserDrone
    SayPassingSonar
    SayAnswerSonar 
    SayDeath
    SayDamageTaken

    Item
    KindItem

    RandomPosition
    IsIsland
    StartPlayer
    TreatStream
in
    /** InitPosition
        ID = unbound; Position= unbound
        State = current state of the submarine
        bind ID and position by the current position selected
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
        bind ID, Position and Direction by the new position and direction selected
    */ 
    fun{Move ID Position Direction State}
        NewState NewPosition in
        case Direction 
        of surface then 
            NewState = {AdjoinList State [surface#true]}  %What the fuck is surface ???
        [] north then 
            NewPosition = pt(x:(Position.x)-1 y:Position.y)
            if {IsIsland NewPosition.x NewPosition.y Input.map} then
                {System.show 'The direction selected correspond to an island'}
            else
                Position = pt(x:(Position.x)-1 y:Position.y) 
                NewState = {AdjoinList State [position#NewPosition]}
            end
        [] east then 
            NewPosition = pt(x:Position.x y:(Position.y+1))
            {System.show 'The New Position is :'}
            {System.show NewPosition}
            if {IsIsland NewPosition.x NewPosition.y Input.map} then
                {System.show 'The direction selected correspond to an island'}
            else
                NewPosition = pt(x:Position.x y:(Position.y)+1) 
                {System.show 'Binding Position'}
                Position = NewPosition
                NewState = {AdjoinList State [position#NewPosition]}
            end
        [] south then 
            NewPosition = pt(x:(Position.x)-1 y:Position.y)
            if {IsIsland NewPosition.x NewPosition.y Input.map} then
                {System.show 'The direction selected correspond to an island'}
            else
                Position = pt(x:(Position.x)+1 y:Position.y) 
                NewState = {AdjoinList State [position#NewPosition]}
            end
        [] west then 
            NewPosition = pt(x:(Position.x)-1 y:Position.y)
            if {IsIsland NewPosition.x NewPosition.y Input.map} then
                {System.show 'The direction selected correspond to an island'}
            else
                Position = pt(x:Position.x y:(Position.y)-1) 
                NewState = {AdjoinList State [position#NewPosition]}
            end
        else
            {System.show 'Direction unknown'}
            NewState = State
            Direction = nil
        end 
        %Binding variables
        ID = NewState.id
        Direction = NewState.direction
        %returning current state
        NewState
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
        NewState NewWeapon in
        if State.weapons.mine > 0 then
            NewWeapon = {AdjoinList State.weapons [mine#State.weapons.mine-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            FireItem = mine({RandomPosition})        %Demander position ???????????????
            NewState
        elseif State.weapons.missile > 0 then
            NewWeapon = {AdjoinList State.weapons [missile#State.weapons.missile-1]}
            NewState = {AdjoinList State [weapons#NewWeapon]}
            ID = State.id
            FireItem = missile({RandomPosition})        %Demander position ???????????????
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
        Answer = State.damage >= maxDamage
        State
    end 

    /** SayMove 
    */


    /** SaySurface 
    */


    /** SayCharge 
    */

    /** SayMinedPlaced 
    */

    /** SayMissileExplode 
    */


    /** SayMineExplode 
    */

    /** SayPassingDrone 
    */

    /** SayAnswerDrone 
    */

    /** SayPassingDrone 
    */

    /** SayPassingSonar 
    */

    /** SayAnswerSonar 
    */

    /** SayDeath 
    */

    /** SayDamageTaken 
    */


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
        [] isDead(Answer)|T then 
            {TreatStream T {IsDead Answer State}}
        else
            skip
        end
    end
end
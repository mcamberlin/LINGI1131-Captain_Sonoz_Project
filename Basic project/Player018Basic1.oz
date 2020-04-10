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
                Position in
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
                if(isIsland(NewPosition.x NewPosition.y)) then
                    System.show('The direction selected correspond to an island')
                else
                    Position = pt(x:(Position.x)-1 y:Position.y) 
                    NewState = {AdjoinList State [position#NewPosition]}
                end
            [] east then 
                NewPosition = pt(x:(Position.x)-1 y:Position.y)
                if(isIsland(NewPosition.x NewPosition.y)) then
                    System.show('The direction selected correspond to an island')
                else
                    Position = pt(x:Position.x y:(Position.y)+1) 
                    NewState = {AdjoinList State [position#NewPosition]}
                end
            [] south then 
                NewPosition = pt(x:(Position.x)-1 y:Position.y)
                if(isIsland(NewPosition.x NewPosition.y)) then
                    System.show('The direction selected correspond to an island')
                else
                    Position = pt(x:(Position.x)+1 y:Position.y) 
                    NewState = {AdjoinList State [position#NewPosition]}
                end
            [] west then 
                NewPosition = pt(x:(Position.x)-1 y:Position.y)
                if(isIsland(NewPosition.x NewPosition.y)) then
                    System.show('The direction selected correspond to an island')
                else
                    Position = pt(x:Position.x y:(Position.y)-1) 
                    NewState = {AdjoinList State [position#NewPosition]}
                end
            else
                System.show('Direction unknown')
                skip
            end
        end 
        %Binding variables
        ID = State.id
        Direction = State.direction
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
        NewState NewLoad in
        case KindItem
        of missile then
            %Increase the loads of missile
             {AdjoinList State.loads [missile#(State.loads.missile+1)] NewLoad}

            if(NewLoad.missile >= Input.missile) then 
                local NewWeapons NewLoads in
                    % new missile created: number of loading charges required to create a missile reached
                    {AdjoinList State.loads [missile# (State.loads.missile - Input.missile)] NewLoads}
                    {AdjoinList State.weapons [missile#(State.weapons.missile +1)] NewWeapons}
                    
                    {AdjoinList State [weapons#NewWeapons loads#Newloads] NewState}
                end
                
                % the player should say that a new missile has been created by binding the given item
                KindItem = missile
                {System.show {Os.Append 'The number of missile has increased for player ' NewState.id.id}}
            else
                {AdjoinList State [loads#NewLoad] NewState}
            end  

        [] mine then
            %Increase the loads of mine
            {AdjoinList State.loads [mine# (State.loads.mine+1)] NewLoad}

            if(NewLoad.mine >= Input.mine) then
                local NewWeapons NewLoads in
                    % new mine created: number of loading charges required to create a mine reached
                    {AdjointList State.loads [mine# (State.loads.mine - Input.mine)] NewLoads}
                    {AdjoinList State.weapons [mine# (State.weapons.mine+1)] NewWeapons}
                   
                    {AdjoinList State [weapons#NewWeapons loads#NewLoads] NewState}
                end

                % the player should say that a new item has been created by binding the given item
                KindItem = mine
                {System.show {Os.Append 'The number of mine has increased for player ' State.id.id}}
            else
                {AdjoinList State [loads#NewLoad] NewState} 
            end       
        [] sonar then 
            %Increase the loads of sonar
            {AdjoinList State.loads [sonar# (State.loads.sonar+1)] NewLoad}

            if(NewLoad.sonar >= Input.sonar) then 
                local NewWeapons NewLoads in
                    % new sonar created: number of loading charges required to create a sonar reached
                    {AdjoinList State.loads [sonar#(State.loads.sonar - Input.sonar)] NewLoads}
                    {AdjoinList State.weapons [sonar#(State.weapons.sonar+1)] NewWeapons}

                    {AdjoinList State [weapons#NewWeapons loads#NewLoads] NewState}
                end

                % the player should say that a new sonar has been created by binding the given item
                KindItem = sonar
                {System.show {Os.Append 'The number of sonar has increased for player ' State.id.id}}
            else
                {AdjoinList State [loads#NewLoad] NewState} 
            end       
        [] drone then
            %Increase the loads of drone
            {AdjoinList State.loads [drone# (State.loads.drone+1)] NewLoad}

            if(NewLoad.drone >= Input.drone) then 
                local NewWeapons NewLoads in
                    % new drone created: number of loading charges required to create a drone reached    
                    {AdjoinList State.loads [drone#(State.loads.drone - Input.drone)] NewLoads}
                    {AdjoinList State.weapons [drone#(State.loads.drone+1)] NewWeapons}
               
                    {AdjoinList State [weapons#NewWeapons loads#NewLoads] NewState}
                end
                % the player should say that a new drone has been created by binding the given item
                KindItem = drone
                {System.show {Os.Append 'The number of drone has increased for player ' State.id.id}}
            else
                {AdjoinList State [loads#NewLoad] NewState} 
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
    /* fun{FireItem ID KindFire State}
        if State.mine >= Input.mine then 

        else if State.missile >= Input.missile then ...

        else if State.drone >= Input.drone then ...

        else if State.sonar >= Input.sonar then ...

        else ID=State.id KindFire=null State
        end
    end
    */

    /** FireMine(ID Mine) 
    */

    /** IsDead
    
    */

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
                            loads: loads(mine:0 missile:0 drone:0 sonar:0)
                            weapons: weapons(mine:0 missile:0 drone:0 sonar:0)
                            )
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
        thread
            {TreatStream Stream InitialState}
        end
        Port
    end

    /** TreatStream
        Stream = a stream of input data for the player
        State = a record including (id score submarine mines path lastPos)
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
        else
            skip
        end
    end
end
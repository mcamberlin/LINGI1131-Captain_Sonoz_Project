functor
import
    GUI
    Input
    PlayerManager
    System
    Time
    OS
define
    GUIPORT
    PLAYER_PORTS

    /* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% USEFUL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

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

    /** Change
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

    /** Broadcast
    @pre
        PLAYER_PORTS = list of each port representing a player
        M = message to broacast
    @post
        Send the message M on every port of PLAYER_PORTS
    */
    proc{Broadcast PLAYER_PORTS M}
        case PLAYER_PORTS
        of H|T then
            {Send H M}
            {Broadcast T M}
        else
            skip
        end
    end

    /** GameState
    @pre 
        Gamestate = current state of the game
    @post
        Show details about GameState
    */
    proc{Print GameState}
        proc{PrintPlayer PlayersState}
            case PlayersState 
            of H|T then 
                {System.show 'Port = ' #H.port}
                {System.show 'Alive = ' #H.alive}
                {System.show 'TurnAtSurface = ' #H.turnAtSurface}
                {PrintPlayer T}
            else 
                {System.show ' ---------- '}
                skip
            end
        end
    in
        {System.show ' ---------- '}
        {System.show 'GameState : '}
        {System.show 'nbPlayersAlive =  '#GameState.nbPlayersAlive}
        {PrintPlayer GameState.playersState} 
    end
    
    /** DisplayWinner
            @pre 
                PlayersState = liste de playerState
            @post
                Affiche un message pour indiquer le gagnant de la partie
    */
    proc{DisplayWinner PlayersState}
        case PlayersState
        of H|T then 
            if H.alive then
                ID Position Direction in 
                {Send H.port move(ID Position Direction)}
                {Wait ID}{Wait Position}{Wait Direction}
                {System.show 'The winner is the player number : ' #ID }
            else
                {DisplayWinner T}
            end
        else
            {System.show 'There is no winner. Several submarines sinks at the same time'}
        end
    end

    /* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END useful functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */
   

    /** CreateEachPlayer
    @pre 
        NbPlayer = number of players during the game
        Kinds = list types of users (AI or Human)
        Colors = list of colors for each player
        ID = unique ID assigned to a specific player
    @post
        create a port for each player
        assign a unique ID, a color
        initialise players on the map
        return a list of port representing the players just created
    */
    fun{CreateEachPlayer NbPlayer Kinds Colors ID}
        case Kinds
        of K1|KT then
            case Colors
            of C1|CT then
                P Id Position in
                    P = {PlayerManager.playerGenerator K1 C1 ID} 
                    {Send P initPosition(Id Position)}
                    {Wait Id} {Wait Position}
                    {Send GUIPORT initPlayer(Id Position)}

                    P | {CreateEachPlayer NbPlayer-1 KT CT ID+1}
            else
                nil
            end
        else
            nil
        end
    end


    /** StartGame
        @pre
        @post 
            Create a gameState representing the current state of the Game
    */
    fun{StartGameSimultaneous}
        
        /** StartPlayers
        @pre
        @post
            Create a list of PlayerState representing the state of each player.
            Their place in the list correspond to their ID
        */
        fun{StartPlayers NbPlayer Acc}
            if(NbPlayer ==0) then
                nil
            else
                NewPlayerState 
                in
                    NewPlayerState = playerState(
                                                port: {Get PLAYER_PORTS Acc} 
                                                )
                    NewPlayerState | {StartPlayers NbPlayer-1 Acc+1}
            end
        end

    in
        gameState(
                    nbPlayersAlive: Input.nbPlayer
                    playersState: {StartPlayers Input.nbPlayer 1}
                    )
    end


    /** StartGame
        @pre
        @post 
            Create a gameState representing the current state of the Game
    */
    fun{StartGameTurnByTurn}
        
        /** StartPlayers
        @pre
        @post
            Create a list of PlayerState representing the state of each player.
            Their place in the list correspond to their ID
        */
        fun{StartPlayers NbPlayer Acc}
            if(NbPlayer ==0) then
                nil
            else
                NewPlayerState 
                in
                    NewPlayerState = playerState(
                                                port: {Get PLAYER_PORTS Acc}
                                                alive:true 
                                                turnAtSurface:Input.turnSurface
                                                )
                    NewPlayerState | {StartPlayers NbPlayer-1 Acc+1}
            end
        end

    in
        gameState(
                    nbPlayersAlive: Input.nbPlayer
                    playersState: {StartPlayers Input.nbPlayer 1}
                    )
    end

    /** WhichFireItem
    @pre
        KindFire 
        ID = id of the 
        PlayerState = playerState() of the player that decided to fire an item
        GameState = current gameState()
    @post
        return the newState of the Game
    */
    fun{WhichFireItem KindFire ID PlayerState GameState}
        {System.show 'Debut WhichFireItem avec un ' #KindFire}
        case KindFire
        of nil then GameState
        [] missile(Position) then {Missile Position ID GameState}
        [] mine(Position) then {Mine Position ID GameState}
        [] sonar then {Sonar PlayerState GameState}
        [] drone(RowOrColumn Index) then {Drone KindFire PlayerState GameState}
        else
            GameState
        end
    end
    
    /** Missile
    @pre 
        Position = position of where the missile lands
        ID = id of the of the player who decides to fire a missile
        PlayerState = playerState() of the player who decides to fire a missile
        GameState = current game state
    @post
        return the new current gameState()
    */
    fun{Missile Position ID GameState}
        fun{RecursiveMissile ID PlayersState GameState Position}
            case PlayersState 
            of H|T then
                Answer in
                {Send H.port isDead(Answer)}
                {Wait Answer}
                if(Answer == true) then
                    /** The player is already dead */
                    {RecursiveMissile ID T GameState Position}
                else
                    Message 
                    in
                    {Send H.port sayMissileExplode(ID Position Message)}
                    {Wait Message}
                    {System.show 'A missile has been launched and the message is '#Message}

                    case Message
                    of sayDeath(ID_Dead_Submarine) then 
                        NewGameState NewPlayersState NewPlayerState
                        in
                        {Broadcast PLAYER_PORTS sayDeath(ID_Dead_Submarine)}
                        
                        NewPlayerState = {AdjoinList {Get GameState.playersState ID_Dead_Submarine.id} [alive#false]} %set to false the "alive" of the player dead
                        NewPlayersState = {Change GameState.playersState ID_Dead_Submarine.id NewPlayerState} 
                        NewGameState = {AdjoinList GameState [playersState#NewPlayersState nbPlayersAlive#(GameState.nbPlayersAlive -1)]} %update the number of players alive 

                        {Send GUIPORT removePlayer(ID_Dead_Submarine)}
                        {System.show 'this player is removed of the party :'#ID.id}
                        
                        {RecursiveMissile ID T NewGameState Position}
                        
                    [] sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft) then
                        {Broadcast PLAYER_PORTS sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft)}
                        {Send GUIPORT lifeUpdate(ID_Damaged_Submarine LifeLeft)}

                        {RecursiveMissile ID T GameState Position}
                    else
                        {System.show 'Format of Message in Missile is not death or damage. The player is not touched'}
                        {RecursiveMissile ID T GameState Position}
                    end
                end
            else
                GameState
            end
        end
    in
        {RecursiveMissile ID GameState.playersState GameState Position}
    end

    
    /** Mine
    @pre
        Position = position of the mine
        ID = ID of the placer of mines
    @post
        send the message sayMinePlaced() to everyone alive and the message putMine() to the GUI
        return GameState
    */
    fun{Mine Position ID GameState}
        fun{RecursiveMine Position ID PlayersState GameState}
            case PlayersState
            of H|T then 
                if(H.alive == false) then
                    /** The player is already dead */
                    {RecursiveMine Position ID T GameState}
                else
                    {Send H.port sayMinePlaced(ID)}
                    {RecursiveMine Position ID T GameState}
                end
            else
                GameState
            end
        end
    in
        {Send GUIPORT putMine(ID Position)}
        {System.show 'A mine has been place in the position' #Position}
        {RecursiveMine Position ID GameState.playersState GameState}
    end


    /** Sonar
    @pre 
        PlayerState = playerState() of the player to decided to fire an item
        GameState = current gameState()
    @post 
        send a sayPassingSonar message to all players alive
        send the response to the player that send a sonar request
        return the new state of the game
    */
    fun{Sonar PlayerState GameState}
        /** 
        @pre 
            PlayersState = liste de playerState
        */
        fun{RecursiveSonar PlayersState PlayerState GameState}
            case PlayersState 
            of H|T then
                if(H.alive == false) then 
                    /** The player is already dead */
                    {RecursiveSonar T PlayerState GameState}
                else
                    %A Sonar detection is occuring   
                    ID Answer 
                    in
                    {Send H.port sayPassingSonar(ID Answer)}
                    {Wait ID} {Wait Answer}

                    case Answer
                    of pt(x:X y:Y) then
                            %Send a message to the emitter of the sonar the position returned by the other players
                            {Send PlayerState.port sayAnswerSonar(ID Answer)}      
                            {RecursiveSonar T PlayerState GameState}                  
                    else
                        {System.show 'Format of Message in Sonar not understood (not a sonar)'}
                        {RecursiveSonar T PlayerState GameState}
                    end
                end
            else
                GameState
            end
        end
    in
        {RecursiveSonar GameState.playersState PlayerState GameState}
    end

    /** Drone
    @pre
        KindFire = <Drone>
        PlayerState = playerState() of the player to decided to fire an item
        GameState = current gameState()
    */
    fun{Drone KindFire PlayerState GameState}
        /**
        @pre
            PlayersState = liste de playerState()
        */
        fun{RecursiveDrone KindFire PlayersState PlayerState GameState}
            case PlayersState
            of H| T  then
                if(H.alive == false) then
                    /** The player is already dead */
                    {RecursiveDrone KindFire T PlayerState GameState}
                else
                    %A Drone detection is occuring   
                    ID Answer 
                    in
                    {Send H.port sayPassingDrone(KindFire ID Answer)}
                    {Wait ID} {Wait Answer}
                    {Send PlayerState.port sayAnswerDrone(ID Answer)}      
                    {RecursiveDrone KindFire T PlayerState GameState}  
                end
            else
                GameState
            end
        end
    in
        {RecursiveDrone KindFire GameState.playersState PlayerState GameState}
    end


    /** ExplodeMine
        @pre:
        
        @post: return a new GameState

     */
    fun{ExplodeMine Mine ID NewPlayerState GameState}
        fun{RecursiveExplodeMine PlayersState GameState}
            case PlayersState
            of H | T then 
                if(H.alive == false) then
                    /** The player is already dead */
                    {RecursiveExplodeMine T GameState}
                else
                    Message in 
                    {Send H.port sayMineExplode(ID Mine Message)}
                    
                    {Wait Message}
                    
                    {System.show 'The Message in ExplodeMine is :'#Message}

                    case Message 
                    of sayDeath(ID_Dead_Submarine) then 
                        NewGameState NewPlayersState NewPlayerState
                        in
                        {Broadcast PLAYER_PORTS sayDeath(ID_Dead_Submarine)}
                        {Send GUIPORT removePlayer(ID_Dead_Submarine)}
                        
                        NewPlayerState = {AdjoinList {Get GameState.playersState ID_Dead_Submarine.id} [alive#false]} %set to false the "alive" of the player dead
                        NewPlayersState = {Change GameState.playersState ID_Dead_Submarine.id NewPlayerState} 
                        NewGameState = {AdjoinList GameState [playersState#NewPlayersState nbPlayersAlive#(GameState.nbPlayersAlive -1)]} %update the number of players alive   

                        {RecursiveExplodeMine T NewGameState}

                    [] sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft) then
                        {Broadcast PLAYER_PORTS sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft)}
                        {Send GUIPORT lifeUpdate(ID_Damaged_Submarine LifeLeft)}

                        {RecursiveExplodeMine T GameState}
                    else
                        {System.show 'Format of Message not sayDamage or sayDeath in ExplodeMine. The player '#ID.id#' is not touched'}
                        {RecursiveExplodeMine T GameState}
                    end
                end
            else
                GameState
            end
        end
        GameStateMine
    in
        if Mine == null then GameState
        else
            GameStateMine = {RecursiveExplodeMine GameState.playersState GameState}
            {Send GUIPORT removeMine(ID Mine)}
            GameStateMine
        end
    end



    proc{TurnByTurn}
        InitialState in
        InitialState = {StartGameTurnByTurn}
        {InLoopTurnByTurn InitialState 1}
    end

    /** InLoopTurnByTurn
    @pre
        GameState = current game state
        I = I in the playersState of the player that will play
    @post
    */
    proc{InLoopTurnByTurn GameState I}
        
        {Print GameState}
        
        if(GameState.nbPlayersAlive >1) then

            Index TestIndex CurrentPlayer in 
            TestIndex = I mod (Input.nbPlayer)
            if TestIndex == 0 then Index = Input.nbPlayer
            else
                Index = TestIndex
            end
            
            {System.show 'Au tour' #I# 'pour le joueur : '#Index}

            CurrentPlayer = {Get GameState.playersState Index}
            {System.show '     Etat du joueur actuel : ' #CurrentPlayer}

            %0. Si le joueur est deja mort
            if(CurrentPlayer.alive == false) then
                {System.show 'Le joueur : '#Index# ' est deja mort.'}
                {System.show '-------------------Fin du tour pour le joueur '#Index}
                {InLoopTurnByTurn GameState I+1}          
            
            %1                   
            elseif (CurrentPlayer.turnAtSurface < Input.turnSurface) then %the player can't play
            
                NewPlayerState NewPlayersState NewGameState in
                NewPlayerState = {AdjoinList CurrentPlayer [turnAtSurface#(CurrentPlayer.turnAtSurface +1)]}
                NewPlayersState = {Change GameState.playersState Index NewPlayerState }
                NewGameState = {AdjoinList GameState [playersState#NewPlayersState]}
                {System.show '-------------------Fin du tour pour le joueur '#Index}
                {InLoopTurnByTurn NewGameState I+1}

            %2
            %if it's the first round or the submarine is just going to dive on the previous round
            elseif(I=<Input.nbPlayer orelse CurrentPlayer.turnAtSurface == Input.turnSurface) then 
                local
                    ID Position Direction NewPlayersState NewGameState  GameStateFire GameStateMine NewPlayerStateSurface
                in
                    {System.show '%2.'}
                    {Send CurrentPlayer.port dive}


                    %3. Ask the direction 
                    {System.show '%3.'}
                    {Send CurrentPlayer.port move(ID Position Direction)}
                    {Wait ID}{Wait Position} {Wait Direction}

                    {System.show 'The State of the player is '#CurrentPlayer}
                    if(Direction == surface) then
                        %4. the player want to go at surface 
                        {System.show '%4.'}
                        NewPlayerStateSurface = {AdjoinList CurrentPlayer [turnAtSurface#1]}
                        NewPlayersState = {Change GameState.playersState Index NewPlayerStateSurface }
                        NewGameState = {AdjoinList GameState [playersState#NewPlayersState]}
                        {Broadcast PLAYER_PORTS saySurface(ID)}
                        {Send GUIPORT surface(ID)}
                        {System.show '-------------------Fin du tour pour le joueur '#Index}
                        {InLoopTurnByTurn NewGameState I+1}
                    else
                        %5. the player want to move to a direction
                        {System.show '%5.'}
                        {Broadcast PLAYER_PORTS sayMove(ID Direction)}
                        {Send GUIPORT movePlayer(ID Position)}

                        %6. the player charge an item
                        {System.show '%6.'}
                        local 
                            ID_Charge KindItem
                        in
                            {Send CurrentPlayer.port chargeItem(ID_Charge KindItem)}
                            {Wait ID_Charge} {Wait KindItem}
                            if KindItem \= null then
                                {Broadcast PLAYER_PORTS sayCharge(ID_Charge KindItem)}
                            end
                        end

                        %7. the player fire the item
                        {System.show '%7.'}
                        local ID_Fire KindFire
                        in
                            {Send CurrentPlayer.port fireItem(ID_Fire KindFire)}
                            {Wait ID_Fire} {Wait KindFire}
                            {System.show 'KindFire is '#KindFire}

                            GameStateFire = {WhichFireItem KindFire ID_Fire CurrentPlayer GameState}
                        end

                        %8. the player can explode a mine after fire a item (GameStateFire)
                        {System.show '%8.'}
                        local ID Mine
                        in
                            {Send CurrentPlayer.port fireMine(ID Mine)} %Mine = position of the mine NOT mine(Position)
                            {Wait ID} {Wait Mine}
                            GameStateMine = {ExplodeMine Mine ID CurrentPlayer GameStateFire}
                        end

                        NewGameState = GameStateMine

                        {System.show 'Fin du tour pour le joueur' #Index}
                        {InLoopTurnByTurn NewGameState I+1}

                    end           
                end                        
            else
                {System.show 'probleme dans les conditions turnbyturn'}
                skip
            end
        else            
            {DisplayWinner GameState.playersState}
            {System.show 'EndGame'} 
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULTANEOUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun{IsSomebodyThere ListPort}

        fun{IsSomebody ListPort Acc}
            case ListPort
            of H|T then 
                Answer in 
                {Send H isDead(Answer)}
                {Wait Answer}
                if(Answer==true) then
                    {IsSomebody T Acc}
                else
                    {IsSomebody T Acc+1}
                end
            else
                Acc
            end
        end
    in
        if( {IsSomebody ListPort 0} >1 ) then
            true
        else
            false
        end
    end

    proc{WhichFireItemSimu KindFire ID  PortPlayer} 
        {System.show 'Debut WhichFireItem avec un ' #KindFire}
        case KindFire
        of missile(Position) then {MissileSimu Position ID}
        [] mine(Position) then {MineSimu Position ID}
        [] sonar then {SonarSimu PortPlayer}
        [] drone(RowOrColumn Index) then {DroneSimu KindFire PortPlayer}
        else
            skip
        end
    end
    
    /** Missile
    @pre 
        Position = position of where the missile lands
        ID = id of the of the player who decides to fire a missile
        PlayerState = playerState() of the player who decides to fire a missile
        GameState = current game state
    @post
        return the new current gameState()
    */
    proc{MissileSimu Position ID}
        proc{RecursiveMissile ID Position ListPort}
            case ListPort 
            of H|T then
                Answer Message  in
                {Send H isDead(Answer)}
                {Wait Answer}
                if(Answer == true) then
                    /** The player is already dead */
                    {RecursiveMissile ID Position T}
                else
                    {Send H sayMissileExplode(ID Position Message)}
                    {Wait Message}
                    {System.show 'A missile has been launched and the message is '#Message}

                    case Message
                    of sayDeath(ID_Dead_Submarine) then 
                        NewGameState NewPlayersState NewPlayerState
                        in
                        {Broadcast PLAYER_PORTS sayDeath(ID_Dead_Submarine)}
                        {Send GUIPORT removePlayer(ID_Dead_Submarine)}
                        {System.show 'this player is removed of the party :'#ID.id}
                        
                        {RecursiveMissile ID Position T}
                        
                    [] sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft) then
                        {Broadcast PLAYER_PORTS sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft)}
                        {Send GUIPORT lifeUpdate(ID_Damaged_Submarine LifeLeft)}

                        {RecursiveMissile ID Position T}
                    else
                        {System.show 'Format of Message in Missile is not death or damage. The player is not touched'}
                        {RecursiveMissile ID Position T}
                    end
                end
            else
                skip
            end
        end
    in
        {RecursiveMissile ID Position PLAYER_PORTS}
    end

    
    /** Mine
    @pre
        Position = position of the mine
        ID = ID of the placer of mines
    @post
        send the message sayMinePlaced() to everyone alive and the message putMine() to the GUI
        return GameState
    */
    proc{MineSimu Position ID}
        proc{RecursiveMine ID ListPort}
            case ListPort
            of H|T then 
                Answer in
                {Send H isDead(Answer)}
                {Wait Answer}
                if Answer==true then
                    /** The player is already dead */
                    {RecursiveMine ID T}
                else
                    {Send H sayMinePlaced(ID)}
                    {RecursiveMine ID T}
                end
            else
                skip
            end
        end
    in
        {Send GUIPORT putMine(ID Position)}
        {System.show 'A mine has been place in the position' #Position}
        {RecursiveMine ID PLAYER_PORTS}
    end


    /** Sonar
    @pre 
        PlayerState = playerState() of the player to decided to fire an item
        GameState = current gameState()
    @post 
        send a sayPassingSonar message to all players alive
        send the response to the player that send a sonar request
        return the new state of the game
    */
    proc{SonarSimu PortPlayer}
        /** 
        @pre 
            PlayersState = liste de playerState
        */
        proc{RecursiveSonar ListPort PortPlayer}
            case ListPort 
            of H|T then
                Answer in
                {Send H isDead(Answer)}
                {Wait Answer}

                if(Answer==true) then 
                    /** The player is already dead */
                    {RecursiveSonar T PortPlayer}
                else
                    %A Sonar detection is occuring   
                    local ID Answer 
                    in
                        {Send H sayPassingSonar(ID Answer)}
                        {Wait ID} {Wait Answer}

                        case Answer
                        of pt(x:X y:Y) then
                                %Send a message to the emitter of the sonar the position returned by the other players
                                {Send PortPlayer sayAnswerSonar(ID Answer)}      
                                {RecursiveSonar T PortPlayer}                  
                        else
                            {System.show 'Format of Message in Sonar not understood (not a sonar)'}
                            {RecursiveSonar T PortPlayer}
                        end
                    end
                end
            else
                skip
            end
        end
    in
        {RecursiveSonar PLAYER_PORTS PortPlayer}
    end

    /** Drone
    @pre
        KindFire = <Drone>
        PlayerState = playerState() of the player to decided to fire an item
        GameState = current gameState()
    */
    proc{DroneSimu KindFire PortPlayer}
        proc{RecursiveDrone KindFire ListPort PortPlayer}
            case ListPort
            of H|T  then
                Answer in
                {Send H isDead(Answer)}
                {Wait Answer}

                if(Answer==true) then 
                    /** The player is already dead */
                    {RecursiveDrone KindFire T PortPlayer}
                else
                    %A Drone detection is occuring  
                    local ID Answer 
                    in
                        {Send H sayPassingDrone(KindFire ID Answer)}
                        {Wait ID} {Wait Answer}
                        {Send PortPlayer sayAnswerDrone(ID Answer)}      
                        {RecursiveDrone KindFire T PortPlayer}  
                    end
                end
            else
                skip
            end
        end
    in
        {RecursiveDrone KindFire PLAYER_PORTS PortPlayer}
    end


    /** ExplodeMine
        @pre:
        
        @post: return a new GameState

     */
    proc{ExplodeMineSimu Mine ID PortPlayer}
        proc{RecursiveExplodeMine Mine ID ListPort PortPlayer}
            case ListPort
            of H|T  then
                Answer Message in
                {Send H isDead(Answer)}
                {Wait Answer}

                if(Answer==true) then 
                    /** The player is already dead */
                    {RecursiveExplodeMine Mine ID T PortPlayer}
                else 
                    {Send H sayMineExplode(ID Mine Message)}
                    
                    {Wait Message}
                    
                    {System.show 'The Message in ExplodeMine is :'#Message}

                    case Message 
                    of sayDeath(ID_Dead_Submarine) then 

                        {Broadcast PLAYER_PORTS sayDeath(ID_Dead_Submarine)}
                        {Send GUIPORT removePlayer(ID_Dead_Submarine)}
                        {RecursiveExplodeMine Mine ID T PortPlayer}

                    [] sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft) then
                        {Broadcast PLAYER_PORTS sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft)}
                        {Send GUIPORT lifeUpdate(ID_Damaged_Submarine LifeLeft)}

                        {RecursiveExplodeMine Mine ID T PortPlayer}
                    else
                        {System.show 'Format of Message not sayDamage or sayDeath in ExplodeMine. The player '#ID.id#' is not touched'}
                        {RecursiveExplodeMine Mine ID T PortPlayer}
                    end
                end
            else
                skip
            end
        end
    in
        if Mine == null then skip
        else
            {RecursiveExplodeMine Mine ID PLAYER_PORTS PortPlayer}
            {Send GUIPORT removeMine(ID Mine)}
            skip
        end
    end
    

    proc{Simultaneous}
        proc{LaunchThread ListPort}
            case ListPort
            of Port|T then 
                thread {InLoopSimultaneous Port} end
                {LaunchThread T}
            else
                skip
            end
        end
        in
        %We have to launch a thread for each player. And they have to play independently. 
        {LaunchThread PLAYER_PORTS} %List of each Port
        
    end



    proc{InLoopSimultaneous PortPlayer}

        Answer EndOfGame in 

        EndOfGame = {IsSomebodyThere PLAYER_PORTS}
        {Send PortPlayer isDead(Answer)}
        {Wait Answer}
        
        if(Answer==true orelse EndOfGame == false) then 
            if(EndOfGame == false) then
                {System.show '----------------------------------------------------- ENDGAME ------------------------------------------------'}
            end
            skip %this is the end for this player ... :(
        else

            %1. if first turn or surface ended -> send dive 
            {Send PortPlayer dive}

            %2. Simulate thinking 
            {Delay Input.thinkMin + {OS.rand} mod (Input.thinkMax-Input.thinkMin)}
            

            %3. Choose direction. 
            ID Position Direction in
            {Send PortPlayer move(ID Position Direction)}
            {Wait ID} {Wait Position} {Wait Direction}

            %4. If surface -> end turn, wait Input.turnSurface seconds and Gui is notified 
            if Direction==surface then 
                {Send GUIPORT surface(ID)}
                {Broadcast PLAYER_PORTS saySurface(ID)}
                {Delay Input.turnSurface*1000}
                {InLoopSimultaneous PortPlayer}
            else

                %5. Broadcast the direction and also say too Gui
                {Send GUIPORT movePlayer(ID Position)}
                {Broadcast PLAYER_PORTS sayMove(ID Direction)}

                %6. Simulate thinking 
                {Delay Input.thinkMin + {OS.rand} mod (Input.thinkMax-Input.thinkMin)}


                %7. Charge an item. Braodcast information if a weapon is ready 
                local ID KindItem %GameStateFire GameStateMine 
                in
                    {Send PortPlayer chargeItem(ID KindItem)}
                    {Wait ID} {Wait KindItem}
                    if KindItem \= null then
                        {Broadcast PLAYER_PORTS sayCharge(ID KindItem)}
                    end
                end

                %8. Simulate thinking 
                {Delay Input.thinkMin + {OS.rand} mod (Input.thinkMax-Input.thinkMin)}

                %9. Fire an item. Broadcast information if touched an ennemy
                local ID KindFire
                in
                    {Send PortPlayer fireItem(ID KindFire)}
                    {Wait ID} {Wait KindFire}
                    {System.show 'KindFire is '#KindFire} 
                    {WhichFireItemSimu KindFire ID PortPlayer}
                end

                %10. Simulate thinking 
                {Delay Input.thinkMin + {OS.rand} mod (Input.thinkMax-Input.thinkMin)}

                %11. Explode a mine. Broadcast information if touched an ennemy
                local ID Mine
                in 
                    {Send PortPlayer fireMine(ID Mine)}
                    {Wait ID} {Wait Mine}
                    {ExplodeMineSimu Mine ID PortPlayer}

                end
                %12. End of turn -> repeat
                {InLoopSimultaneous PortPlayer}

            end
        end

    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END SIMULTANEOUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



in
    {System.show '----------------------------------------------------- GAME LAUNCHED ------------------------------------------------'}

    GUIPORT = {GUI.portWindow} %Create the port for the GUI
    {Send GUIPORT buildWindow} %Launch its interface

    PLAYER_PORTS = {CreateEachPlayer Input.nbPlayer Input.players Input.colors 1} %Initialize players (assign id, color, initial position) 

    %Launch the game in the correct mode
    if(Input.isTurnByTurn) then
        {TurnByTurn}
        {System.show '----------------------------------------------------- ENDGAME ------------------------------------------------'}
    else
        {Simultaneous}
    end    
end
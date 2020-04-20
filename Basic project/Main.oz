/* 
Command in the terminal
    Compiling
        ozc -c Input.oz GUI.oz Main.oz Player018Basic1.oz PlayerManager.oz
    Executing
        ozengine Main.ozf 
*/
functor
import
    GUI
    Input
    PlayerManager
    System
    OS
define
    GUIPORT
    PLAYER_PORTS

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

    proc{Broadcast PLAYER_PORTS M}
        case PLAYER_PORTS
        of H|T then
            {Send H M}
            {Broadcast T M}
        else
            skip
        end
    end

    
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

    proc{Simultaneous}
        skip
    end



    /** StartGame
        @pre
        @post 
            Create a gameState representing the current state of the Game
    */
    fun{StartGame}
        
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
                                                isAtSurface:true 
                                                turnAtSurface:Input.turnSurface
                                                )
                    NewPlayerState | {StartPlayers NbPlayer-1 Acc+1}
            end
        end

        InitialState
    in
        InitialState = gameState(
                                nbPlayersAlive: Input.nbPlayer
                                playersState: {StartPlayers Input.nbPlayer 1}
                                )
        InitialState
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
        {System.show 'Debut WhichFireItem avec un '}
        {System.show KindFire}
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
            of playerState(port:P alive:A isAtSurface:IAS turnAtSurface:TAS) | T then
                {System.show 'inside case Missile'}
                if(A == false) then
                    /** The player is already dead */
                    {RecursiveMissile ID T GameState Position}
                else
                    Message 
                    in
                    {System.show 'inside sayMissileExplode'}
                    {System.show ID}
                    {System.show Position}
                    {Send P sayMissileExplode(ID Position Message)}
                    {Wait Message}
                    {System.show 'A missile has been launched and the message is '}
                    {System.show Message}

                    case Message
                    of sayDeath(ID_Dead_Submarine) then 
                        NewGameState NewPlayersState NewPlayerState
                        in
                        {Broadcast PLAYER_PORTS sayDeath(ID_Dead_Submarine)}
                        
                        NewPlayerState = {AdjoinList {Get GameState.playersState ID_Dead_Submarine.id} [alive#false]} %set to false the "alive" of the player dead
                        NewPlayersState = {Change PlayersState ID_Dead_Submarine.id NewPlayerState}  
                        NewGameState = {AdjoinList GameState [playersState#NewPlayersState nbPlayersAlive#(GameState.nbPlayersAlive -1)]} %update the number of players alive 

                        {Send GUIPORT removePlayer(ID_Dead_Submarine)}
                        {System.show 'this player is removed of the party :'}
                        {System.show ID.id}  
                        
                        {RecursiveMissile ID T NewGameState Position}
                        
                    [] sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft) then
                        {Broadcast PLAYER_PORTS sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft)}
                        {Send GUIPORT lifeUpdate(ID_Damaged_Submarine LifeLeft)}

                        {RecursiveMissile ID T GameState Position}
                    else
                        {System.show 'Format of Message is not death or damage'}
                        {RecursiveMissile ID T GameState Position}
                    end
                end
            else
                GameState
            end
        end
    in
        {System.show 'Début Missile'}
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
            of playerState(port:P alive:A isAtSurface:IAS turnAtSurface:TAS) | T then 
                if(A == false) then
                    /** The player is already dead */
                    {RecursiveMine Position ID T GameState}
                else
                    {Send P sayMinePlaced(ID)}
                    {RecursiveMine Position ID T GameState}
                end
            else
                GameState
            end
        end
    in
        {Send GUIPORT putMine(ID Position)}
        {System.show 'A mine has been place in the position'}
        {System.show Position}
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
            of playerState(port:P alive:A isAtSurface:IAS turnAtSurface:TAS) | T then
                if(A == false) then 
                    /** The player is already dead */
                    {RecursiveSonar T PlayerState GameState}
                else
                    %A Sonar detection is occuring   
                    ID Answer 
                    in
                    {Send P sayPassingSonar(ID Answer)}
                    {Wait ID} {Wait Answer}

                    case Answer
                    of pt(x:X y:Y) then
                            %Send a message to the emitter of the sonar the position returned by the other players
                            {Send PlayerState.port sayAnswerSonar(ID Answer)}      
                            {RecursiveSonar T PlayerState GameState}                  
                    else
                        {System.show 'Message not understood (not a sonar)'}
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
            of playerState(port:P alive:A isAtSurface:IAS turnAtSurface:TAS) | T  then
                if(A == false) then
                    /** The player is already dead */
                    {RecursiveDrone KindFire T PlayerState GameState}
                else
                    %A Drone detection is occuring   
                    ID Answer 
                    in
                    {Send P sayPassingDrone(KindFire ID Answer)}
                    {Wait ID} {Wait Answer}
                    {Send PlayerState.port sayAnswerDrone(ID Answer)}      
                    {RecursiveDrone KindFire T PlayerState GameState}  
                    /* 
                    Pas nécessaire car sayAnswerDrone dit deja si touché ou pas 
                    case Answer 
                    of true then
                        %Send a message to the emitter of the drone the position returned by the other players
                        {Send PlayerState.port sayAnswerDrone(ID Answer)}      
                        {RecursiveDrone KindFire T PlayerState GameState}   

                    [] false then
                        %Send a message to the emitter of the drone the position returned by the other players
                        {Send PlayerState.port sayAnswerDrone(ID Answer)}      
                        {RecursiveDrone KindFire T PlayerState GameState}   
                    else
                        {RecursiveDrone KindFire T PlayerState GameState}
                    end
                    */
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
            of playerState(port:P alive:A isAtSurface:IAS turnAtSurface:TAS) | T then 
                if(A == false) then
                    /** The player is already dead */
                    {RecursiveExplodeMine T GameState}
                else
                    Message in 
                    {Send P sayMineExplode(ID Mine Message)}
                    {System.show 'The Message in ExplodeMine is :'}
                    
                    {Wait Message}
                    
                    {System.show Message}

                    case Message 
                    of sayDeath(ID_Dead_Submarine) then 
                        NewGameState NewPlayersState NewPlayerState
                        in
                        {Broadcast PLAYER_PORTS sayDeath(ID_Dead_Submarine)}
                        {Send GUIPORT removePlayer(ID_Dead_Submarine)}
                        
                        NewPlayerState = {AdjoinList {Get GameState.playersState ID_Dead_Submarine.id} [alive#false]} %set to false the "alive" of the player dead
                        NewPlayersState = {Change PlayersState ID_Dead_Submarine.id NewPlayerState}  
                        NewGameState = {AdjoinList GameState [playersState#NewPlayersState nbPlayersAlive#(GameState.nbPlayersAlive -1)]} %update the number of players alive   
                        
                        {RecursiveExplodeMine T NewGameState}

                    [] sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft) then
                        {Broadcast PLAYER_PORTS sayDamageTaken(ID_Damaged_Submarine Damage LifeLeft)}
                        {Send GUIPORT lifeUpdate(ID_Damaged_Submarine LifeLeft)}

                        {RecursiveExplodeMine T GameState}
                    else
                        {System.show 'Format of Message not sayDamage or sayDeath in ExplodeMine'}
                        {RecursiveExplodeMine T GameState}
                    end
                end
            else
                GameState
            end
        end
    in
        if Mine == null then GameState
        else
            {RecursiveExplodeMine GameState.playersState GameState}
        end
    end


    /** InLoopTurnByTurn
    @pre
        GameState = current game state
        I = I in the playersState of the player that will play
    @post
    */
    proc{InLoopTurnByTurn GameState I}
        
        {System.show 'Le nombre de joueurs en vie est de : ' #GameState.nbPlayersAlive# ' '}
        
        if(GameState.nbPlayersAlive >1) then

            Index TestIndex CurrentPlayer in 
            TestIndex = I mod (Input.nbPlayer)
            if TestIndex == 0 then Index = 3
            else
                Index = TestIndex
            end
            CurrentPlayer = {Get GameState.playersState Index}


            {System.show 'Au tour' #I# 'pour le joueur : '#Index# ' '}
            {System.show 'Etat du jeu : ' #GameState}
            {System.show '     Etat du joueur actuel : ' #CurrentPlayer# ' '}

            %0. Si le joueur est deja mort
            if(CurrentPlayer.alive == false) then
                {System.show 'Le joueur : '#Index# ' est deja mort.'}
                {InLoopTurnByTurn GameState I+1}          
            
            %1                   
            elseif (CurrentPlayer.turnAtSurface \= Input.turnSurface) then %the player can't play
            %NOTE : pas sur que ca fonctionnne A DISCUTER car CurrentPlayer.turnAtSurface ne sera jamais a 0 :/
                NewPlayerState NewPlayersState NewGameState in
                NewPlayerState = {AdjoinList CurrentPlayer [turnAtSurface#(CurrentPlayer.turnAtSurface +1)]}
                NewPlayersState = {Change GameState.playersState Index NewPlayerState }
                NewGameState = {AdjoinList GameState [playersState#NewPlayersState]}
                {System.show 'Fin du tour pour le joueur'}
                {System.show Index}
                {InLoopTurnByTurn NewGameState I+1}

            %2
            {System.show '%2.'}
            elseif(I=<Input.nbPlayer orelse CurrentPlayer.turnAtSurface == Input.turnSurface) then %si c'est le premier tour ou si le sous marin vient de plonger au tour d'avant 
                NewPlayerState NewPlayersState NewGameState ID Position Direction GameStateFire GameStateMine NewPlayerStateSurface
                in
                {Send CurrentPlayer.port dive}
                NewPlayerState = {AdjoinList CurrentPlayer [isAtSurface #false]}

                %3. Ask the direction 
                {System.show '%3.'}
                {Send NewPlayerState.port move(ID Position Direction)}
                {Wait ID} {Wait Position} {Wait Direction}
                if(Direction == surface) then
                    %4. the player want to go at surface 
                    {System.show '%4.'}
                    NewPlayerStateSurface = {AdjoinList CurrentPlayer [turnAtSurface#1]}
                    NewPlayersState = {Change GameState.playersState Index NewPlayerStateSurface }
                    NewGameState = {AdjoinList GameState [playersState#NewPlayersState]}
                    {Broadcast PLAYER_PORTS saySurface(ID)}
                    {Send GUIPORT surface(ID)}
                    {System.show 'Fin du tour pour le joueur'}
                    {System.show Index}
                    {InLoopTurnByTurn NewGameState I+1}
                else
                    %5. the player want to move to a direction
                    {System.show '%5.'}
                    %{Broadcast PLAYER_PORTS sayMove(ID Direction)}
                    {Send GUIPORT movePlayer(ID Position)}
                    %6. the player charge an item
                    {System.show '%6.'}
                    ID KindItem
                    in
                    {Send NewPlayerState.port chargeItem(ID KindItem)}
                    {Wait ID} {Wait KindItem}
                    {Broadcast PLAYER_PORTS sayCharge(ID KindItem)}
                    %7. the player fire the item
                    {System.show '%7.'}
                    local ID KindFire
                    in
                        {Send NewPlayerState.port fireItem(ID KindFire)}
                        {Wait ID} {Wait KindFire}
                        {System.show 'KindFire is '}
                        {System.show KindFire}

                        GameStateFire = {WhichFireItem KindFire ID NewPlayerState GameState}
                    end

                    %8. the player can explode a mine after fire a item (GameStateFire)
                    {System.show '%8.'}
                    local ID Mine
                    in
                        {Send NewPlayerState.port fireMine(ID Mine)} %Mine = position of the mine NOT mine(Position)
                        {Wait ID} {Wait Mine}
                        GameStateMine = {ExplodeMine Mine ID NewPlayerState GameStateFire}
                    end

                    NewGameState = GameStateMine

                    {System.show 'Fin du tour pour le joueur'}
                    {System.show Index}
                    {InLoopTurnByTurn NewGameState I+1}
                    

                end                                   
            else
                {System.show 'probleme dans les conditions turnbyturn'}
                skip
            end
        else
            LastPlayer DisplayWinner in 
            /** DisplayWinner
            @pre 
                PlayersState = liste de playerState
            @post
                Affiche un message pour indiquer le gagnant de la partie
            */
            proc{DisplayWinner PlayersState}
                case PlayersState
                of H|T then 
                    if(H == nil) then {DisplayWinner T}
                    else
                        {System.show 'The winner is the player number : ' #LastPlayer.id.id# ' '}
                    end
                else
                    skip
                end
            end
            
            {DisplayWinner GameState.playersState}
            {System.show 'EndGame'} 

        end
    end
    

    /** #TreatGame
    */
    proc{TurnByTurn}
        InitialState in
        InitialState = {StartGame}
        {InLoopTurnByTurn InitialState 1}
    end

in
    {System.show '----------------------------------------------------- GAME LAUNCHED ------------------------------------------------'}

    GUIPORT = {GUI.portWindow} %Create the port for the GUI
    {Send GUIPORT buildWindow} %Launch its interface

    PLAYER_PORTS = {CreateEachPlayer Input.nbPlayer Input.players Input.colors 1} %Initialize players (assign id, color, initial position) 

    %Launch the game in the correct mode
    if(Input.isTurnByTurn) then
        {TurnByTurn}
    else
        {Simultaneous}
    end

    {System.show '----------------------------------------------------- GAME ENDED ------------------------------------------------'}
end

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

    proc{BroadCast PLAYER_PORTS M}
        case PLAYER_PORTS
        of H|T then
            {Send H M}
            {BroadCast T M}
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
                                                turnAtSurface:0
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
    @post
    */
    proc{WhichFireItem KindFire ID GameState}
        case KindFire
        of nil then skip
        [] missile(Position) then {Missile Position ID GameState}
        /*[] mine(Position) then {Mine Position GameState}
        [] sonar then {Sonar GameState}
        [] drone(RowOrColumn Index) then {Drone RowOrColumn Index GameState}*/
        else
            skip
        end
    end
    
    /** Missile
    @pre 
        Position
        GameState
    @post
    */
    proc{Missile Position ID GameState}
        case GameState.playersState 
        of playerState(port:P alive:A isAtSurface:IAS turnAtSurface:TAS)|T then
            Message in
            {Send P sayMissileExplode(ID Position Message)}
            {Wait Message}

            case Message
            of sayDeath(ID) then 
                NewGameState NewPlayersState NewPlayerState
                in
                {BroadCast PLAYER_PORTS sayDeath(ID)}
                {Send GUIPORT removePlayer(ID)}
                %mettre a false alive du joueur mort
                NewPlayerState = {Get NewGameState.playersState ID}
                NewPlayersState = {AdjoinList NewPlayerState [alive#false]}
                NewGameState = {AdjoinList GameState [playersState#NewPlayersState nbPlayersAlive#(GameState.nbPlayersAlive -1)]}                
            
            [] sayDamageTaken(ID Damage LifeLeft) then
                NewGameState NewPlayersState NewPlayerState
                in
                {BroadCast PLAYER_PORTS sayDamageTaken(ID Damage LifeLeft)}
                {Send GUIPORT lifeUpdate(ID LifeLeft)}
            else
                skip
            end

        else
            skip
        end
    end

    /** InLoopTurnByTurn
    @pre
        Gamestate = current game state
        I = I in the playersState of the player that will play
    @post
    */
    proc{InLoopTurnByTurn GameState I}
        
        if(GameState.nbPlayersAlive >1) then
            Index CurrentPlayer in 
            Index = I mod Input.GameState.nbPlayersAlive
            CurrentPlayer = {Get GameState.playersState I}

            %1                   
            if (CurrentPlayer.turnAtSurface \= 0) then %the player can't play
                NewPlayerState NewPlayersState NewGameState in
                NewPlayerState = {AdjoinList CurrentPlayer [turnAtSurface#(CurrentPlayer.turnAtSurface +1)]}
                NewPlayersState = {Change GameState.playersState Index NewPlayerState }
                NewGameState = {AdjoinList GameState [playersState#NewPlayersState]}
                {InLoopTurnByTurn NewGameState I+1}

            %2
            elseif(I<Input.nbPlayer orelse CurrentPlayer.turnAtSurface == Input.turnSurface) then %si c'est le premier tour ou si le sous marin vient de plonger au tour d'avant 
                NewPlayerState NewPlayersState NewGameState ID Position Direction
                in
                {Send CurrentPlayer.port dive}
                NewPlayerState = {AdjoinList CurrentPlayer [isAtSurface #false]}

                {Send NewPlayerState.port move(ID Position Direction)}
                {Wait ID} {Wait Position} {Wait Direction}
                if(Direction == surface) then
                    %4. the player want to go at surface 
                    NewPlayerState = {AdjoinList CurrentPlayer [turnAtSurface#1]}
                    NewPlayersState = {Change GameState.playersState Index NewPlayerState }
                    NewGameState = {AdjoinList GameState [playersState#NewPlayersState]}
                    {BroadCast PLAYER_PORTS saySurface(ID)}
                    {Send GUIPORT surface(ID)}
                    {InLoopTurnByTurn NewGameState I+1}
                else
                    %5. the player want to move to a direction
                    {BroadCast PLAYER_PORTS sayMove(ID Direction)}
                    {Send GUIPORT movePlayer(ID Position)}
                    %6. the player charge an item
                    ID KindItem
                    in
                    {Send NewPlayerState.port chargeItem(ID KindItem)}
                    {Wait ID} {Wait KindItem}
                    {BroadCast PLAYER_PORTS sayCharge(ID KindItem)}
                    %7. the player fire the item
                    local ID KindFire
                    in
                        {Send NewPlayerState.port fireItem(ID KindFire)}
                        {Wait ID} {Wait KindFire}

                        {WhichFireItem KindFire ID GameState}
                    end
                    

                end                                   
            else
                skip
            end
        else
            {System.show {OS.Append 'VAINQUEUR: ' GameState.playersState.1}}
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
    {System.show 'Start'}

    %%%% 1 - Create the port for the GUI and launch its interface %%%%
    GUIPORT = {GUI.portWindow} %Create the port for the GUI
    {Send GUIPORT buildWindow} %Launch its interface

    %%%% 2-3 - Initialize players (assign id, color, initial position) %%%%
    PLAYER_PORTS = {CreateEachPlayer Input.nbPlayer Input.players Input.colors 1}

    %%%% 4 - Launch the game in the correct mode %%%%
    if(Input.isTurnByTurn) then
        {TurnByTurn}
    else
        {Simultaneous}
    end

    {System.show 'Stop'}
end

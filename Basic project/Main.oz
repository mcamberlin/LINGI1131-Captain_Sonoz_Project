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
define
    GUIPORT
    PLAYER_PORTS
    
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
        fun{StartPlayers NbPlayer}
            if(NbPlayers ==0) then
                nil
            else
                NewPlayerState 
                in
                    NewPlayerState = playerState(
                                                alive:true 
                                                isAtSurface:true 
                                                turnRemaining:0
                                                )
                    NewPlayerState | {StartPlayer NbPlayer-1}
            end
        end

        InitialState
    in
        InitialState = gameState(
                                nbPlayersAlive: Input.nbPlayers
                                playersState: {StartPlayers Input.nbPlayer}
                                )
        InitialState
        {InLoopTurnByTurn InitialState}
    end

    proc{InLoopTurnByTurn GameState}
        skip
    end

    /** #TreatGame
    */
    proc{TurnByTurn}
        InitialState in
            InitialState = {StartPlayers}
            {InLoopTurnByTurn InitialState}
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
        {TurnByTurn Input.nbPlayer}
    else
        {Simultaneous}
    end

    {System.show 'Stop'}
end

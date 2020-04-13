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
            if(NbPlayer ==0) then
                nil
            else
                NewPlayerState 
                in
                    NewPlayerState = playerState(
                                                alive:true 
                                                isAtSurface:true 
                                                turnRemaining:0
                                                )
                    NewPlayerState | {StartPlayers NbPlayer-1}
            end
        end

        InitialState
    in
        InitialState = gameState(
                                nbPlayersAlive: Input.nbPlayer
                                playersState: {StartPlayers Input.nbPlayer}
                                )
        InitialState
    end

    /** InLoopTurnByTurn
    @pre
        Gamestate = current game state
        I = I in the playersState of the player that will play
    @post
    */
    proc{InLoopTurnByTurn GameState I}
        
        if(GameState.nbPlayersAlive >1) then
            Index NewGameState CurrentPlayer in 
                Index = I mod Input.GameState.nbPlayersAlive
                CurrentPlayer = {Get GameState.playersState I}
                
                if(CurrentPlayer.isAtSurface == true) then
                    {InLoopTurnByTurn GameState I+1}
                else
                    
                end




            
            {InLoopTurnByTurn NewGameState I+1}
        else
            {System.show {OS.Append 'VAINQUEUR: ' GameState.playersState.1}}
        end
    end

    /** #TreatGame
    */
    proc{TurnByTurn}
        InitialState in
        InitialState = {StartGame}
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
        {TurnByTurn}
    else
        {Simultaneous}
    end

    {System.show 'Stop'}
end

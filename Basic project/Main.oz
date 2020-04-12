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
    
    /** CreatePlayer
        bind PLAYER_PORTS to a list of Ports representing each player and place them on the Map
    */

    /** CreatePlayer
    */
    fun {CreatePlayer}
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
    in
        {CreateEachPlayer Input.nbPlayer Input.players Input.colors 1}
    end
in
    {System.show 'Start'}

    %%%% 1 - Create the port for the GUI and launch its interface %%%%
    GUIPORT = {GUI.portWindow} %Create the port for the GUI
    {Send GUIPORT buildWindow} %Launch its interface

    %%%% 2 - Initialize players %%%%
    PLAYER_PORTS = {CreatePlayer}





    %%%% 3 - Ask every player to set up (choose initial point at the surface) %%%%

    %%%% 4 - Launch the game in the correct mode %%%%

    {System.show 'Stop'}
end

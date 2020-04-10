/* 
Command in the terminal
    Compiling
        ozc -c Input.oz GUI.oz Main.oz Player018Basic1.oz Player018Basic2.oz PlayerManager.oz
    Executing
        ozengine Main.ozf 
*/
functor
import
    GUI
    Input
    PlayerManager
define
    GUIPORT

    /*
    fun {GeneratePlayers NbPlayers}
    {
        if(NbPlayers > 0)
        {
            {PlayerManager.playerGenerator Input.players Input.colors 1}
            
        }
    }
     */
in

    %%%% 1 - Create the port for the GUI and launch its interface %%%%
    GUIPORT = {GUI.portWindow} %Create the port for the GUI
    {Send GUIPORT buildWindow} %Launch its interface

    %%%% 2 - Create the port for every player using the PlayerManager and assigne a unique id %%%%

    
    {PlayerManager.playerGenerator Input.players Input.colors 1}

    %%%% 3 - Ask every player to set up (choose initial point at the surface) %%%%

    %%%% 4 - Launch the game in the correct mode %%%%

    
end

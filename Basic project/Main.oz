/* 
Command in the terminal
    Compiling
        ozc -c Input.oz GUI.oz Main.oz Player.oz PlayerManager.oz
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
in
    %Setting up config

    %%%% 1 - Create the port for the GUI and launch its interface %%%%
    GUIPORT = {GUI.portWindow}

    {Send GUIPORT buildWindow}

    %%%% 2 - Create the port for every player using the PlayerManager and assigne a unique id %%%%

    %%%% 3 - Ask every player to set up (choose initial point at the surface) %%%%

    %%%% 4 - Launch the game in the correct mode %%%%

    
end

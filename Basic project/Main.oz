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
    Port1
    Port2
    ID1
    ID2
    Position1
    Position2

    proc{CreatePlayer}
        Port1 = {PlayerManager.playerGenerator player018basic1 Input.colors.1 1}
        Port2 = {PlayerManager.playerGenerator player018basic1 Input.colors.2.1 2} %j'ai changé parce que je vois pas pourquoi créer 2 fois le meme fichier si c'est les meme :/

        {Send Port1 initPosition(ID1 Position1)}
        {Send Port2 initPosition(ID2 Position2)}

        {Wait ID1}
        {Wait ID2}
        {Wait Position1}
        {Wait Position2}

        {Send GUIPORT initPlayer(ID1 Position1)}
        {Send GUIPORT initPlayer(ID2 Position2)}

    end
in
    {System.show 'Debut'}
    %%%% 1 - Create the port for the GUI and launch its interface %%%%
    GUIPORT = {GUI.portWindow} %Create the port for the GUI
    {Send GUIPORT buildWindow} %Launch its interface

    %%%% 2 - Create the port for every player using the PlayerManager and assigne a unique id %%%%
    {CreatePlayer}

    
    

    
    


    %%%% 3 - Ask every player to set up (choose initial point at the surface) %%%%

    %%%% 4 - Launch the game in the correct mode %%%%

    
end

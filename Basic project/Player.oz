functor
import
    Input
    QTk at 'x-oz://system/wp/QTk.ozf'
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
    InitPosition
    State
    AskPosition
    X Y
    Move
in

    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream State}
        end
        Port
    end

    /*Stream = le stream de donnée entrant 
    State = un tuple contenant (id score submarine mines path lastPos)*/
    proc{TreatStream Stream State} 
        case Stream 
        of nil then skip
        [] initPosition(ID Position)|T then {TreatStream T {InitPosition ID Position State}}
        [] move(ID Position Direction)|T then {TreatStream T {Move ID Position Direction State}}
        end
    end

    %%%InitPosition

    /*le joueur doit choisir sa position initiale en liant son id à ID et sa position à Position. */
    fun{InitPosition ID Position State}
        ID = State.id
        Position = {AskPosition}%pt(x:1 y:1) si mon truc fonctionne pas :(
        {AdjoinList State [pos#Position]} %return le nouvel etat
    end

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
    
    %%%Move 

    fun{Move ID Position Direction State}
        NewState NewPosition in
        case Direction 
            of surface then NewState = State  %What the fuck is surface ???
            [] north then NewPosition = pt(x:Position.x-1 y:Position.y) NewState = {AdjoinList State [pos#NewPosition]}
            [] east then NewPosition = pt(x:Position.x y:Position.y+1) NewState = {AdjoinList State [pos#NewPosition]}
            [] south then NewPosition = pt(x:Position.x+1 y:Position.y) NewState = {AdjoinList State [pos#NewPosition]}
            [] west then NewPosition = pt(x:Position.x y:Position.y-1) NewState = {AdjoinList State [pos#NewPosition]}
        end 
        ID = State.id
        NewState
    end

end

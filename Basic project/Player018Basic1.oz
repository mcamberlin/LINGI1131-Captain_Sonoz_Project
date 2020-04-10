functor
import
    Input
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    OS 
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
    RandomPosition
in
    fun{RandomPosition}
        X Y LookIsland in
        /** LookIsland
            verifie()    
        */
        fun{LookIsland X Y Map}
            case Map
            of H1|T1 then 
                if(X ==1) then
                    case H1 
                    of H2|T2 then 
                        if(Y==1) then
                            if(H2 == 1) then %Sur une ile
                                true
                            else
                                false
                            end
                        else
                            {LookIsland X Y-1 T2}
                        end
                    else
                        false
                    end
                else
                    {LookIsland X-1 Y T1}
                end
            else
                false
            end
        end          


        X = {OS.rand} mod Input.nRow+1
        {System.show X}
        Y = {OS.rand} mod Input.nColumn+1
        {System.show Y}
        %Check if on water
        if {LookIsland X Y Input.map} then {RandomPosition}
        else
            pt(x:X y:Y)
        end
    end

    fun{StartPlayer Color ID}
        Stream
        Port
        InitialState
    in
        {NewPort Stream Port}
        InitialState = state(id:id(id:ID color:Color name:'name') position:pt(x:1 y:1)))
        thread
            {TreatStream Stream InitialState}
        end
        Port
    end

    /** TreatStream
        Stream = a stream of input data for the player
        State = a record including (id score submarine mines path lastPos)
    */
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
        {System.show 'Initposition 0'}
        ID = State.id
        {System.show 'Init Position apres id'}
        Position = {RandomPosition} %{AskPosition}%pt(x:1 y:1) si mon truc fonctionne pas :(
        {System.show 'InitPosition'}
        {AdjoinList State [position#Position]} %return le nouvel etat
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

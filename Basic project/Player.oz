functor
import
    Input
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
in
    /*Stream = le stream de donnée entrant 
    State = un tuple contenant (id score submarine mines path lastPos)*/
    proc{TreatStream Stream State} 
        case Stream 
        of nil then nil
        [] initPosition(?ID ?Position)|T then {TreatStream T {InitPosition ID Position State}}
        end
    end


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

    /*le joueur doit choisir sa position initiale en liant son id à ID et sa position à Position. */
    fun{InitPosition ID Position State}
        ID = State.id
        Position = {AskPosition}
        

    end

    /*Ouvre une fenetre pour demander la position initiale */
    fun{AskPosition}
        {QTk.dialogbox load(defaultextension:"qdw" 
                            initialdir:"." 
                           title:"Choose a initiale position : " 
                           initialfile:"" 
                           filetypes:q("Position" q("X" X) q("Y" Y) ) ) }  %ormalement ouvre une fenetre mais pas sur
    end
end

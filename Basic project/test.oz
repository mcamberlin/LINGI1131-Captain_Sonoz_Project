declare
fun{MapGenerator NRow NColumn}
    fun{LineGenerator Acc Islands}
        if(Acc=<NRow *NColumn) then
            {Contains Acc Islands} | {LineGenerator Acc+1 Islands}            
        else
            nil
        end
    end

    /**
    @pre 
        return a list of random number representing
    */
    fun{ListIsland NIslands}
        if(NIslands >0) then
            Pos in 
                Pos = {OS.rand}  mod (NRow * NColumn) 
                if(Pos == 0) then 
                    1| {ListIsland NIslands -1}
                else
                    Pos|{ListIsland NIslands-1}
                end
        else
            nil
        end
    end
    
    fun{Contains Pos Islands}
        case Islands
        of H |T then 
            if(H == Pos) then
                1
            else
                {Contains Pos T}
            end
        else
            0
        end 
    end
    
    fun{Append L I}
        case L 
        of H|nil then
            local L1 in
                L1 = H|I
                L1 | {Append nil I}
            end
        []H|T then
            H|{Append T I}
        else
            nil
        end
    end


    fun{LineToMatrix LL AccX L}
        fun{Append L I}
            case L 
            of H|nil then
                H|I|{Append nil I}

            []H|T then
                H|{Append T I}
            else
                nil
            end
        end
    in
        case LL
        of H|T then
            if(AccX == 1) then
                {LineToMatrix T AccX+1 H}
            elseif(AccX ==2) then
                {LineToMatrix T AccX+1 {Append [L] H}}
            elseif(AccX <NRow) then
                {LineToMatrix T AccX+1 {Append L H}}
            else%if(AccX == NRow) then
                {Append L H} | {LineToMatrix T 1  1}
            end
        else
            nil
        end
    end
    
    NIslands
    Islands
    LongList
    Ratio
in
    Ratio = 25.0 / 100.0 % The approximative ratio of islands on the map (Ratio = numberOfIsland/(NRow*NColumn))
    NIslands = {FloatToInt {IntToFloat NRow}  * {IntToFloat NColumn} * Ratio }
    Islands = {ListIsland NIslands}

    LongList = {LineGenerator 1 Islands}

    {LineToMatrix LongList 1 1}
end
declare
NIslands = {FloatToInt {IntToFloat 10}  * {IntToFloat 10} * 0.33333 }
{Browse NIslands}
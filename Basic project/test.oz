declare
fun{ManhattanDistance Position1 Position2}
    if(Position1 == nil orelse Position2 == nil) then nil
    else
        {Abs Position1.x-Position2.x} + {Abs Position1.y-Position2.y}
    end
end

fun{ChangeEnemy L ID NewEnemy}
    case L
    of H|T then
        if(H.id == ID) then 
            NewEnemy|T
        else
            H|{ChangeEnemy T ID NewEnemy}
        end
    else 
        nil
    end
end


fun{Remove L Item}
    case L
    of H|T then
        if (H == Item)  then
            {Remove T Item}
        else
            H|{Remove T Item}
        end
    else
        nil
    end
end

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
    
fun{ExplodeMine State ?Enemy}

    /** SameY
    @pre 
        Y = the y position to compare
        List = list of mines
    @post
        return a list of mine that are on the column Y
    */
    fun{NearY Y List}
        case List
        of H|T then 
            if(H.y == Y orelse H.y == Y-1 orelse H.y == Y+1) then
                H|{NearY Y T}
            else
                {NearY Y T}
            end
        else
            nil
        end
    end

    /** SameX
    @pre 
        X = the x position to compare
        List = list of mines
    @post
        return a list of mine that are on the row X
    */
    fun{NearX X List}
        case List
        of H|T then 
            if(H.x == X orelse H.x == X-1 orelse H.x == X+1) then
                H|{NearX X T}
            else
                {NearX X T}
            end
        else
            nil
        end
    end

    
    /** ReachableByMine
    @pre
        EnemyPosition = presice position of the enemy
        List = list of mines
    @post
        return a list mines able to damage the enemy located in EnemyPosition
    */
    fun{ReachableByMine EnemyPosition List}
        case List
        of H|T then
            %Exploding the mine H can damage the enemy
            if( {ManhattanDistance H EnemyPosition}  <2) then
                H|{ReachableByMine EnemyPosition T}
            else
                {ReachableByMine EnemyPosition T}
            end
        else
            nil
        end
    end

    /** TooClose
    @pre 
        List = list of mines
    @post
        return a list of mines where the mines able to damage ourself have been removed
    */
    fun{TooClose List State} 
        case List
        of H|T then
            if( {ManhattanDistance H State.position} >1  ) then
                H|{TooClose T State}
            else
                {TooClose T State}
            end
        else
            nil
        end
    end 
    
    /** GetRandomMine
    @pre 
        L = list of mines
    @post
        return randomly a mine in L
    */
    fun{GetRandomMine L}
        fun{Length L Acc}
            case L 
            of H|T then {Length T Acc+1}
            else
                Acc
            end
        end
        Longueur
    in  
        Longueur = {Length L 0}
        if(Longueur >0) then
            {Get L (1+{OS.rand} mod ({Length L 0}) ) }
        else
            nil
        end
    end

    /** RecursiveExplodeMine
    @pre
        List = list of enemies
        State = state of the current player
        Enemy = unbound
    @post
        bound Enemy to the enemy supposed to be fired
        return a position of mine to explode without damaging ourself 
    */
    fun{RecursiveExplodeMine List State ?Enemy }
        case List              
        of enemy(id:I position: P)|T then
            case P 
            of pt(x:0 y:0) then
                {RecursiveExplodeMine T State ?Enemy }
            [] pt(x:0 y:Y) then
                L1 L2 Mine in   

                %1. return a list of mines in the column Y
                L1 = {NearY Y State.mines}
                {Browse 'L1'}
                {Browse L1}
                {Delay 3000}
                %2. remove those that are too close of me
                L2 = {TooClose L1 State}
                {Browse 'L2'}
                {Browse L2}
                {Delay 3000}
                %3. select randomly one to explode
                Mine = {GetRandomMine L2}
                {Browse 'Mine'}
                {Browse Mine}
                {Delay 3000}
                
                if(Mine == nil) then
                    {RecursiveExplodeMine T State Enemy}
                else
                    %4. reset position of the enemy
                    Enemy = enemy(id:I position: P)
                    Mine                        
                end

            []pt(x:X y:0) then
                L1 L2 Mine in 
                
                %1. return a list of mines in the row X
                L1 = {NearX X State.mines}
                %2. remove those that are too close of me 
                L2 = {TooClose L1 State}
                %3. select randomly one to explode
                Mine = {GetRandomMine L2}                 
                
                if(Mine == nil) then
                    {RecursiveExplodeMine T State Enemy}
                else
                    %4. reset position of the enemy
                    Enemy = enemy(id:I position: P)
                    Mine                        
                end

            else /** Both coordinates of the enemy are known */
                L1 L2 Mine in 
                %1. return a list of mines able to damage the Enemy
                L1 = {ReachableByMine P State.mines}
                %2. remove those that are too close of me 
                L2 = {TooClose L1 State}
                %3. select randomly one to explode
                Mine = {GetRandomMine L2}                 
                
                if(Mine == nil) then
                    {RecursiveExplodeMine T State Enemy}
                else
                    %4. reset position of the enemy
                    Enemy = enemy(id:I position: P)
                    Mine                        
                end
            end
        else
            Enemy = null
            null
        end
    end
    
in
    {RecursiveExplodeMine State.enemies State ?Enemy}
end


fun{FireMine ID Mine State}
    TargetMine Enemy
in
        
    TargetMine = {ExplodeMine State ?Enemy}
    {Wait Enemy}

    if(TargetMine \= null ) then
        NewEnemy NewEnemies NewMines NewState in 
        NewEnemy = {AdjoinList Enemy [position# pt(x:0 y:0)]}
        NewEnemies = {ChangeEnemy State.enemies Enemy.id NewEnemy}
        NewMines = {Remove State.mines TargetMine}
        NewState = {AdjoinList State [mines#NewMines enemies#NewEnemies]}
        ID = State.id
        Mine = TargetMine
        NewState
    else % None mine to place
        Mine = null
        ID = State.id
        State
    end
end



declare
M = pt(x:5 y:2) | pt(x:10 y:10) | pt(x:10 y:10) | pt(x:10 y:10) | nil
L = enemy(id:1 position:pt(x:5 y:0)) | enemy(id:2 position:pt(x:0 y:1)) | enemy(id:1 position:pt(x:5 y:2)) | nil

State = state(position:pt(x:8 y:4) enemies: L mines: M)
local Enemy in
{Browse {ExplodeMine State ?Enemy}}
end
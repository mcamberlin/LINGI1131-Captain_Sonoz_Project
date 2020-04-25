declare 
proc{LaunchThread L}
    case L
    of H|T then thread {Trhead H} end {LaunchThread T}
    else
        skip
    end
end

proc{Trhead H}
    {Time.delay {OS.rand} mod 5000}
    {Browse H}
end

{LaunchThread [1 2 3]}













declare

fun{ManhattanDistance Position1 Position2}
    if(Position1 == nil orelse Position2 == nil) then nil
    else
        {Abs Position1.x-Position2.x} + {Abs Position1.y-Position2.y}
    end
end
%-----
fun{IsDamageableByMine EnemyPosition Position }
    ManDistance in
    ManDistance = {ManhattanDistance Position EnemyPosition}
    if(ManDistance < 2) then
        true
    else
        false
    end
end

fun{CanDamageEnemy L Enemies}
    fun{RecursiveCanDamageEnemy L Enemy}
        case L
        of pt(x:X y:Y)| T then
            %if(Enemy.position == pt(x:X y:Y)) then % Achanger cette condition
            if( {IsDamageableByMine Enemy.position pt(x:X y:Y)}) then
                pt(x:X y:Y)
            else
                {RecursiveCanDamageEnemy T Enemy}
            end
        else
            false
        end
    end
in
    case Enemies
    of enemy(id:I position:P)|T then
        R in 
        R = {RecursiveCanDamageEnemy L enemy(id:I position:P)}
        if(R == false) then
            {CanDamageEnemy L T}
        else 
            R
        end
    else
        false
    end
end
%Mines = [pt(x:1 y:1)  pt(x:2 y:2) pt(x:3 y:3) pt(x:4 y:4) pt(x:5 y:5)]

%Enemies = [enemy(id:1 position:pt(x:3 y:4)) enemy(id:2 position:pt(x:2 y:1)) enemy(id:3 position:pt(x:3 y:1)) enemy(id:4 position:pt(x:4 y:2)) enemy(id:5 position:pt(x:5 y:1))]


Mines = [pt(x:1 y:1)  pt(x:5 y:2) pt(x:2 y:1) pt(x:0 y:4) pt(x:5 y:5)]

Enemies = [enemy(id:1 position:pt(x:3 y:4)) enemy(id:2 position: pt(x:2 y:2))]


{Browse {CanDamageEnemy Mines Enemies}}







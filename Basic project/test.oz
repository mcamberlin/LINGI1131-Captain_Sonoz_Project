declare 
proc{LaunchThread L}
    case L
    of H|T then thread {Trhead H} end {LaunchThread T}
    else
        skip
    end
end

proc{Trhead H}
    {Browse H}
end

{LaunchThread [1 2 3]}
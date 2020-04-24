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
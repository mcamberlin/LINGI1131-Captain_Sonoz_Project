functor
import
	Player018Basic1
	Player018Basic2
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player018basic1 then {Player018Basic1.portPlayer Color ID}
		[] player018basic2 then {Player018Basic2.portPlayer Color ID}
		end
	end
end

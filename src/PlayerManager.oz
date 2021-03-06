functor
import
	Player018Basic
	Player018Medium
	Player018Hard
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player018basic then {Player018Basic.portPlayer Color ID}
		[] player018medium then {Player018Medium.portPlayer Color ID}
		[] player018hard then {Player018Hard.portPlayer Color ID}
		else
			nil
		end
	end
end

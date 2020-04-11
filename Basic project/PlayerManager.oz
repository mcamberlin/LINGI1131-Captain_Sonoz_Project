functor
import
	Player018Basic1
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player018basic1 then {Player018Basic1.portPlayer Color ID}
		else
			nil
		end
	end
end

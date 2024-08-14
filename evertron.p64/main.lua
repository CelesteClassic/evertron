--[[pod_format="raw",created="2024-03-24 00:48:06",modified="2024-08-11 10:30:55",revision=440]]
-- E V E R T R O N --
-- equinox's port of evercore to picotron

-- based on evercore+ v2.0.1, which is based on evercore v2.3.0, which is based on smalleste, which is based on celeste classic

--[[ Credits
	Celeste Classic
		Maddy Thorson
		Noel Berry
	Evercore
		petra
		meep
		gonengazit
		akliant
	Evercore+
		equinox
	Evertron
		equinox
		pancelor
--]]

-- vid(0) should be supported if you really want more pixels (but I think it looks bad.)
-- vid(4) works except for the title screen.
vid(3)
game_w, game_h = get_display():attribs()

include "initialization.lua"
include "update.lua"
include "draw.lua"
include "player.lua"
include "objects.lua"
include "levels.lua"
include "metadata.lua"
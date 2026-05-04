--[[pod_format="raw",created="2024-03-24 00:48:06",modified="2026-05-04 23:40:53",revision=613,xstickers={}]]
-- E V E R T R O N --
-- ooooggll's port of evercore to picotron
-- v1.3

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
		ooooggll
	Evertron
		ooooggll
		pancelor
--]]

config = {
	-- vid_mode changes the resolution
	-- 0: 480x270 (should be supported if you want more pixels, but you'll need big levels)
	-- 1 and 2: picotron hasn't implemented them yet
	-- 3: 240x135 (default for evertron)
	-- 4: 160x90 (should work except for title screen)
	vid_mode = 3,
	
	-- when set to false, balloon and berry hitboxes move up and down (default)
	-- when set to true, the movement is only visual
	-- note: does not affect flying berries
	static_balloons = false,
	
	-- when set to true, if all chest berries in a level are collected,
	-- keys will no longer persist
	fix_evercore_keys = true,
	
	-- when set to true, keys don't appear to wobble back and forth a single
	-- pixel every time they flip horizontally
	fix_key_wobble = false,
	
	-- when set to true, if you're holding up/down while walking,
	-- it will show the walk animation instead of the sprite looking up/down
	fix_player_anim_slide = false,
	
	-- when set to true, levels can be skipped with shift+e and shift+q
	-- shift+e and shift+q can skip the title screen (to first and last level)
	-- you can also toggle debug mode with f1
	-- debug mode renders hitboxes and log() outputs
	dev_mode = true,
	
	-- hair colors depending on dash amount
	-- you can either use a number, or a list of numbers to flash between
	hair_colors = {
		[0] = 12,
		[1] = 8,
		[2] = {11, 7}
	},
	
	-- should match the color of the player's hair in the sprite itself
	default_hair_color = 8,
	
	-- when set to true, death particles are circles the same color as
	-- the player's hair (similar to newleste)
	circle_death_particles = false,
	
	-- when set to true, the map will behave more like newleste
	-- meaning you can go back and forth between levels via multiple sides
	-- instead of enter/exit, you must provide left/right/up/down in the levels table
	-- the levels table must be set up correctly to use this! otherwise it'll break
	connected_map_mode = false,
	
	-- when set to true, berries will follow you once touched (newleste-style)
	-- multiple can be in a train, and will collect after enough ground time
	-- they will transfer between levels too
	train_berries = false,
	
	-- the amount of berries you need to collect in a row to get a 1up
	-- (only used for train_berries mode)
	oneup_streak_required = 6,
}


vid(config.vid_mode)
game_w, game_h = get_display():attribs()

debug_mode = false
debug_output = {}

include "initialization.lua"
include "update.lua"
include "draw.lua"
include "player.lua"
include "objects.lua"
include "levels.lua"
include "metadata.lua"

--[[pod_format="raw",created="2024-07-29 20:13:01",modified="2026-05-04 23:25:03",revision=691,xstickers={}]]
-- [metadata]

-- level table
-- {map, title, music, exit, enter, bg_col, cloud_col}
-- default exit is upwards
-- if enter is not provided, it will use the direction of last level's exit 
-- (or default to "up")
levels = {
	{
		map = "0",
	},
	{
		map = "2",
		title = "evergreen foothills",
		music = 20,
		exit = "right",
		bg_col = 21,
		cloud_col = 22
	},
	{
		map = "1",
		title = "summit",
		music = 30
	},
}

--[[
 config.connected_map_mode demonstration below
 enable config.connected_map_mode to see how it works!
 and if you're not using it, you can delete it
 to use:
 * provide a table of exits per direction
   where each one tells you which map that direction takes you to
 * by default, for vertical exits, the left side of both levels are aligned,
   and for horizontal exits, the top side of both levels are aligned,
   but if you provide a field like [dir]_offset, you can change the alignment
 * on vertical exits, it slides the level you're exiting into to the right by that amt
 * on horizontal exits, it slides the level you're exiting into down by that amt
 * also, if A exits into B, an exit from B -> A will automatically be created
--]]
if config.connected_map_mode then
	levels = {
		{
			map = "3",
			exits = {
				left = "5",
				down = "4",
				left_offset = 3,
			},
		},
		{
			map = "4",
		},
		{
			map = "5",
		},
	}
end

-- tiles stack
-- assigned objects will spawn from tiles set here
tiles = {
	[1] = player_spawn,
	[3] = player_spawn, -- forces the player to spawn in connected_map_mode, rather than serving as a respawn point
	[8] = spring, -- right-facing (make a left-facing one by flipping the map tile)
	[9] = spring, -- up-facing
	[11] = chest,
	[12] = message,
	[13] = big_chest,
	[14] = fake_wall,
	[15] = platform,
	[16] = flag,
	[19] = balloon,
	[20] = fruit,
	[24] = berry_key,
	[32] = fall_floor,
	[40] = fly_fruit,
}

-- allow the reverse lookup, like fruit.tile
-- note: if an object spawns from multiple tiles, it will set to the latter one
for tile, type in pairs(tiles) do
	type.tile = tile
end

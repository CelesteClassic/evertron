--[[pod_format="raw",created="2024-07-29 20:11:31",modified="2026-05-04 05:37:07",revision=639,xstickers={}]]
-- [level loading]

local game_map

-- is there a exit to the level in a given direction?
function is_exit(dir)
	if config.connected_map_mode then
		if (not level.exits) return false
		return level.exits[dir] != nil
	else
		return level.exit == dir
	end
end

function should_exit_level(x, y)
	-- don't exit level at the summit
	-- (doesn't apply on connected map mode)
	if not config.connected_map_mode and not levels[level.id + 1] then
		return false
	end
	
	if is_exit("up") and y < -4 then
		return "up"
	elseif is_exit("right") and x > level.pw - 4 then
		return "right"
	elseif is_exit("left") and x < -4 then
		return "left"
	elseif is_exit("down") and y > level.ph - 4 then
		return "down"
	end
end

function next_level()
	local next_lvl = level.id + 1

	load_level(next_lvl)
end

-- player_obj and enter_dir are only used for config.connected_map_mode
function load_level(id, player_obj, enter_dir)
	has_dashed, has_key = false

	-- remove existing objects
	objects = {}

	-- reset camera speed
	cam.spdx, cam.spdy = 0, 0
	
	-- save the previous level to check if it was different
	local first_level = not level
	local prev_level = level or {exits = {}}
	local diff_level = prev_level.id ~= id

	-- set level globals
	level = read_lvl_data(id)
	
	if diff_level then
		-- check for music trigger
		if levels[id].music then
			music(levels[id].music, 100, 7)
		end
		-- check for bg_col trigger
		if levels[id].bg_col then
			bg_col = levels[id].bg_col
		end
		-- check for cloud_col trigger
		if levels[id].cloud_col then
			cloud_col = levels[id].cloud_col
		end
	end

	-- level title setup
	ui_timer = 5
	
	-- objects can be spawned from any layer that starts with "objects"
	-- e.g. "objects2"
	-- this allows overlapping object spawns
	local spawn_layers = {}
	for layer in all(level.map) do
		if sub(layer.name, 1, 7) == "objects" then
			add(spawn_layers, layer)
		end
	end

	-- spawn objects
	for layer in all(spawn_layers) do
		for tx = 0, level.w - 1 do
			for ty = 0, level.h - 1 do
				local tile = tile_at(tx, ty, layer.name)
				
				-- horizontally mirrored map tiles have the 15th bit flipped (aka 0x4000)
				local object_type = tiles[tile] or tiles[tile - 0x4000]
				
				if object_type then
					if config.connected_map_mode and object_type == player_spawn then
						-- If respawning in the same level, don't spawn player_spawn
						if (not diff_level) goto continue
						
						-- On the first level, only spawn player_spawns with tile 3
						-- (tile 3 represents the spawn point as opposed to respawn point)
						if (first_level and tile != 3) goto continue
						
						-- If it's a different level, we can proceed to spawn player_spawns
						-- to see which is closest to the player and set spawn_point there
					end
					
					-- spawn the object
					local obj = init_object(object_type, tx * 8, ty * 8, tile)
				end
				
				::continue::
			end
		end
	end
	
	-- trigger obj.ready if objects have it
	-- (ready is called once all objects are created/initialized)
	for obj in all(objects) do
		if (obj.ready) obj:ready()
	end
	
	if config.connected_map_mode then
		-- transfer player from last level
		if diff_level and player_obj then
			-- tile positions of new_lvl - old_lvl
			local relative = get_lvl_relative_pos(level, prev_level, enter_dir)
			
			-- translate coordinates based on relative level positions
			player_obj.x -= relative.x * 8
			player_obj.y -= relative.y * 8
			for h in all(player_obj.hair) do
				h.x -= relative.x * 8
				h.y -= relative.y * 8
			end
			
			-- move camera onto the player
			move_camera(player_obj, 1)
			
			-- if entering upward, give the player a lil boost
			if enter_dir == "up" and player_obj.spd.y > -2 then
				player_obj.spd.y = -2
			end
			
			-- set spawn point to closest player_spawn
			-- and then delete all player_spawns
			local min_dist = 1/0 -- infinity
			local closest_spawn
			for obj in all(objects) do
				if obj.type == player_spawn then
					local dist = (player_obj.x - obj.x)^2 + (player_obj.y - obj.target)^2
					if dist < min_dist then
						min_dist = dist
						closest_spawn = obj
					end
					destroy_object(obj)
				end
			end
			
			spawn_point = {
				x = closest_spawn.x,
				y = closest_spawn.target,
				flip = closest_spawn.flip.x,
				enter_dir = enter_dir,
			}
			
			add(objects, player_obj)
		elseif spawn_point and not first_level then
			-- spawn player from saved spawn point
			local spawn = init_object(
				player_spawn,
				spawn_point.x,
				spawn_point.y,
				1,
				{enter_dir = spawn_point.enter_dir}
			)
			if (spawn_point.flip) spawn.flip.x = true
		end
	end
end

function read_lvl_data(id)
	local level_data = levels[id]
	local prev_level_data = levels[id - 1] or {}
	local lvl = {}
	lvl.id = id
	lvl.title = level_data.title -- may be nil
	lvl.map_name = level_data.map
	lvl.path = "map/" .. level_data.map .. ".map"
	
	if config.connected_map_mode then
		lvl.exits = level_data.exits
	else
		-- choose player enter direction based on last level, if it's not assigned manually
		lvl.enter = level_data.enter or prev_level_data.exit or "up"
		lvl.exit = level_data.exit or "up"
	end
	
	lvl.map = fetch(lvl.path)
	lvl.layers = {}
	
	-- cache map layers by their name
	for layer in all(lvl.map) do
		lvl.layers[layer.name] = layer.bmp
	end

	lvl.w, lvl.h = lvl.map[1].bmp:attribs()
	-- width and height of the level measured in pixels
	lvl.pw, lvl.ph = lvl.w * 8, lvl.h * 8
	
	return lvl
end

-- (for config.connected_map_mode only)
-- get the relative position (in tiles) of two levels (new minus old)
-- [old] must exit into [new] in the direction [dir]
function get_lvl_relative_pos(new, old, enter_dir)
	local relative_x, relative_y = 0, 0
	
	if enter_dir == "up" then
		relative_y = -new.h
		relative_x = old.exits.up_offset or 0
	elseif enter_dir == "down" then
		relative_y = old.h
		relative_x = old.exits.down_offset or 0
	elseif enter_dir == "left" then
		relative_x = -new.w
		relative_y = old.exits.left_offset or 0
	elseif enter_dir == "right" then
		relative_x = old.w
		relative_y = old.exits.right_offset or 0
	end
	
	return vec(relative_x, relative_y)
end

-- (for config.connected_map_mode only)
-- loop through levels and create backwards exits corresponding with existing exits
-- e.g. if lvl A can exit to lvl B to the right,
-- then create an exit from lvl B to lvl A to the left
function generate_reciprocal_exits()
	local exits = {}
	
	for lvl in all(levels) do
		if (not lvl.exits) lvl.exits = {}
		
		for dir, map in pairs(lvl.exits) do
			add(exits, {
				from_map = lvl.map,
				to_map = map,
				dir = dir,
				offset = lvl.exits[dir .. "_offset"] or 0
			})
		end
	end
	
	local opposites = {
		left = "right",
		right = "left",
		up = "down",
		down = "up",
	}
	
	for exit_data in all(exits) do
		for lvl in all(levels) do
			if lvl.map == exit_data.to_map then
				-- copy the transition in reverse
				local dir = opposites[exit_data.dir]
				lvl.exits[dir] = exit_data.from_map
				lvl.exits[dir .. "_offset"] = -exit_data.offset
			end
		end
	end
end

-- get the level from the levels table associated with a given map
-- provide the name as a string like "3"
function get_lvl_id_for_map(map)
	for id, lvl in pairs(levels) do
		if (lvl.map == map) return id
	end
end

-- does the given tile exist within this level?
-- (or in connected_map_mode, does it exist within an adjacent one?)
function is_tile_in_lvl(x, y)
	local lvl = level
	
	if x >= 0 and y >= 0 and x < lvl.w and y < lvl.h then
		return true
	end
	
	if (not config.connected_map_mode) return false
	
	-- check if there's a level to exit to in this direction
	local dir = should_exit_level(x * 8, y * 8)
	if (not dir) return false
	
	local other_id = get_lvl_id_for_map(lvl.exits[dir])
	local other_lvl = read_lvl_data(other_id)
	
	local relative = get_lvl_relative_pos(other_lvl, lvl, dir)
	x -= relative.x
	y -= relative.y
	
	if x >= 0 and y >= 0 and x < other_lvl.w and y < other_lvl.h then
		return true
	end
	return false
end

-- get the tile at a given position in the current level
function tile_at(x, y, layer)
	local lvl = level
	
	-- out of bounds - return 0 
	-- or in connected map mode, check if there's another level there
	if x < 0 or y < 0 or x >= lvl.w or y >= lvl.h then
		if (not config.connected_map_mode) return 0
		
		-- check if there's a level to exit to in this direction
		local dir = should_exit_level(x * 8, y * 8)
		if (not dir) return 0
		
		local other_id = get_lvl_id_for_map(lvl.exits[dir])
		local other_lvl = read_lvl_data(other_id)
		
		local relative = get_lvl_relative_pos(other_lvl, lvl, dir)
		
		-- continue to check the corresponding tile in the other level
		lvl = other_lvl
		x -= relative.x
		y -= relative.y
	end
	
	-- get layer by name
	if (lvl.layers[layer]) return lvl.layers[layer]:get(x, y)
	
	-- or by index
	return lvl.map[layer or 1].bmp:get(x, y)
end

function draw_layer(layer, ...)
	if type(layer) == "string" and level.layers[layer] then
		-- name ("background", "foreground"...)
		map(level.layers[layer], ...)
	else
		-- index (1, 2, 3...)
		map(level.map[layer].bmp, ...)
	end
end

function spikes_at(x1, y1, x2, y2, xspd, yspd)
	-- clamp positions and convert pixels to tiles
	local left = max(0, x1 \ 8)
	local right = min(level.w - 1, x2 \ 8)
	local top = max(0, y1 \ 8)
	local bottom = min(level.h - 1, y2 \ 8)
	
	-- loop through tiles the player is touching
	for i = left, right do
		for j = top, bottom do
			local tile = tile_at(i, j, "ground")
			if (tile == 62 and y2 % 8 >= 6 and yspd >= 0) return true
			if (tile == 55 and y1 % 8 <= 2 and yspd <= 0) return true
			if (tile == 54 and x1 % 8 <= 2 and xspd <= 0) return true
			if (tile == 63 and x2 % 8 >= 6 and xspd >= 0) return true
			
			-- spinners
			if tile_at(i, j, "objects") == 43 then
				return true
			end
		end
	end
end

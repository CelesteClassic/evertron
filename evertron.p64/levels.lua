--[[pod_format="raw",created="2024-07-29 20:11:31",modified="2026-04-26 20:05:02",revision=544,xstickers={}]]
-- [level loading]

local game_map

function should_exit_level(x, y)
	-- don't exit level at the summit
	if (not levels[level.id + 1]) return false
	
	if level.exit == "up" then
		return y < -4
	elseif level.exit == "right" then
		return x > level.pw - 4
	elseif level.exit == "left" then
		return x < -4
	elseif level.exit == "down" then
		return y > level.ph - 4
	end
end

function next_level()
	local next_lvl = level.id + 1

	-- check for music trigger
	if levels[next_lvl].music then
		music(levels[next_lvl].music, 100, 7)
	end
	-- check for bg_col trigger
	if levels[next_lvl].bg_col then
		bg_col = levels[next_lvl].bg_col
	end
	-- check for cloud_col trigger
	if levels[next_lvl].cloud_col then
		cloud_col = levels[next_lvl].cloud_col
	end

	load_level(next_lvl)
end

function load_level(id)
	has_dashed, has_key = false

	-- remove existing objects
	objects = {}

	-- reset camera speed
	cam.spdx, cam.spdy = 0, 0
	
	-- save the previous level to check if it was different
	local prev_level = level or {}
	local diff_level = prev_level.id ~= id

	-- set level globals
	local level_data = levels[id]
	local prev_level_data = levels[id - 1] or {}
	level = {}
	level.id = id
	level.title = level_data.title -- may be nil
	level.map_name = level_data.map
	level.path = "map/" .. level_data.map .. ".map"
	
	-- choose player enter direction based on last level (or it's assigned manually)
	level.enter = diff_level and (level_data.enter or prev_level_data.exit) or prev_level_data.enter or "up"
	level.exit = level_data.exit or "up"
	
	level.map = fetch(level.path)
	level.layers = {}
	
	-- cache map layers by their name
	for layer in all(level.map) do
		level.layers[layer.name] = layer.bmp
	end

	level.w, level.h = level.map[1].bmp:attribs()
	-- width and height of the level measured in pixels
	level.pw, level.ph = level.w * 8, level.h * 8

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
				local object_type = tiles[tile] or tiles[tile - 0x4000]
				-- horizontally mirrored map tiles have the 15th bit flipped (aka 0x4000)
				if object_type then
					local obj = init_object(object_type, tx * 8, ty * 8, tile)
					
					-- start camera on player
					if object_type == player_spawn then
						move_camera(obj, 1)
					end
				end
			end
		end
	end
end

-- get the tile at a given position in the current level
function tile_at(x, y, layer)
	-- get layer by name
	if (level.layers[layer]) return level.layers[layer]:get(x, y)
	
	-- or by index
	return level.map[layer or 1].bmp:get(x, y)
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

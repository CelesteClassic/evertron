--[[pod_format="raw",created="2024-07-29 20:11:31",modified="2024-08-14 16:33:55",revision=523]]
-- [level loading]

local game_map

function should_exit_level(x, y)
	-- don't exit level at the summit
	if (not levels[lvl_id + 1]) return false
	
	if lvl_exit == "up" then
		return y < -4
	elseif lvl_exit == "right" then
		return x > lvl_pw - 4
	elseif lvl_exit == "left" then
		return x < -4
	elseif lvl_exit == "down" then
		return y > lvl_ph - 4
	end
end

function next_level()
	local next_lvl = lvl_id + 1

	-- check for music trigger
	if levels[next_lvl].music then
		music(levels[next_lvl].music, 100, 7)
	end

	load_level(next_lvl)
end

function load_level(id)
	has_dashed, has_key = false

	-- remove existing objects
	foreach(objects, destroy_object)

	-- reset camera speed
	cam_spdx, cam_spdy = 0, 0

	local diff_level = lvl_id ~= id

	-- set level index
	lvl_id = id

	-- set level globals
	local level = levels[lvl_id]
	lvl_title = level.title -- may be nil
	
	-- choose player enter direction based on last level (or it's assigned manually)
	lvl_enter = diff_level and (level.enter or lvl_exit) or lvl_enter or "up"
	lvl_exit = level.exit or "up"
	
	game_map = fetch(level.map)

	lvl_x, lvl_y, lvl_w, lvl_h = 0, 0, game_map[1].bmp:attribs()
	lvl_pw, lvl_ph = lvl_w * 8, lvl_h * 8

	-- level title setup
	ui_timer = 5

	-- spawn objects
	for tx = 0, lvl_w - 1 do
		for ty = 0, lvl_h - 1 do
			local tile = tile_at(tx, ty)
			local object_type = tiles[tile] or tiles[tile - 0x4000]
			-- horizontally mirrored map tiles have the 15th bit flipped (aka 0x4000)
			if object_type then
				local obj = init_object(object_type, tx * 8, ty * 8, tile)
			end
		end
	end
end

-- copy mapdata string to clipboard
-- TODO: this is a bit broken -- flipped tiles will lose their flip data
-- I also don't know how necessary it is because we have basically infinite map space now
function get_mapdata(x, y, w, h)
	local reserve = ""
	for i = 0, w * h - 1 do
		local tile = mget(x + i % w, y + i \ w)&0xff --16 bits, but ignore the upper 8 (flip data)
		reserve ..= string.format("%02x",tile)
	end
	set_clipboard(reserve)
end

-- replace mapdata with hex
function replace_mapdata(x, y, w, h, data)
	for i = 1, #data, 2 do
		mset(x + i \ 2 % w, y + i \ 2 \ w, "0x" .. sub(data, i, i + 1))
	end
end

function tile_at(x, y, layer)
	return game_map[layer or 1].bmp:get(x, y)
end

function draw_layer(layer, ...)
	map(game_map[layer].bmp, ...)
end

function spikes_at(x1, y1, x2, y2, xspd, yspd)
	for i = max(0, x1 \ 8), min(lvl_w - 1, x2 / 8) do
		for j = max(0, y1 \ 8), min(lvl_h - 1, y2 / 8) do
			if({[62] = y2 % 8 >= 6 and yspd >= 0,
				[55] = y1 % 8 <= 2 and yspd <= 0,
				[54] = x1 % 8 <= 2 and xspd <= 0,
				[63] = x2 % 8 >= 6 and xspd >= 0})[tile_at(i, j, 2)] then
					return true
			end
		end
	end
end

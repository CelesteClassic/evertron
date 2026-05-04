--[[pod_format="raw",created="2024-07-29 19:52:34",modified="2026-05-03 21:52:20",revision=421,xstickers={}]]
-- [initialization]

-- global tables
objects = {}
got_fruit = {}

-- global timers
freeze = 0
delay_restart = 0
music_timer = 0
ui_timer = -99

-- global camera values
draw_x, draw_y = 0, 0
cam = {
	x = 0,
	y = 0,
	spdx = 0,
	spdy = 0,
	gain = 0.25,
}

-- [entry point]

function _init()
	picotron_frames = 0
	frames = 0
	start_game_flash = 0
	
	if config.connected_map_mode then
		generate_reciprocal_exits()
	end

	music(40, 0, 7)
	is_title = true
	
	set_font("p8")
end

function begin_game()
	max_djump = 1
	deaths = 0
	frames, seconds, minutes = 0, 0, 0
	music_timer = 0
	time_ticking = true
	fruit_count = 0
	bg_col, cloud_col = 0, 1
	is_title = false
	
	music(0, 0, 7)
	load_level(1)
end

-- [effects]

clouds = {}
for i = 0, 32 do
	add(clouds, {
		x = rnd(game_w), 
		y = rnd(game_h), 
		spd = 1 + rnd(4), 
		w = 32 + rnd(32)})
end

particles = {}
for i = 0, 32 do
	add(particles, {
		x = rnd(game_w), 
		y = rnd(game_h), 
		s = flr(rnd(1.25)), 
		spd = 0.25 + rnd(5), 
		off = rnd(), 
		c = 6 + rnd(2), 
	})
end

dead_particles = {}

-- [function library]

-- create a new rectangle object with a position and dimensions
function rectangle(x, y, w, h)
	return {x = x, y = y, w = w, h = h}
end

-- round x to the nearest integer
function round(x)
	return flr(x + 0.5)
end

-- move val closer to target by amount
-- if the distance from val to target is less than amount,
-- clamps the result to target
function appr(val, target, amount)
	return val > target and max(val - amount, target) or min(val + amount, target)
end

-- if v > 0, return 1
-- if v < 0, return -1
-- if v == 0, return 0
function sign(v)
	return v ~= 0 and sgn(v) or 0
end

-- if x is a single digit, prepend a 0 to make it a 2-digit string
function two_digit_str(x)
	return x < 10 and "0"..x or x
end

-- print a string centered at x
function center_print(text, x, y, c)
	local w = print(text, 0, -1000)
	print(text, x - w / 2, y, c)
end

-- change the font when printing
-- pass in "lil", "lil_mono", or "p8"
function set_font(font)
	fetch("/system/fonts/" .. font .. ".font"):poke(0x4000)
	game_font = font
end

_keyd_last = {}
_keyd_keys = {}
-- similar to keyp, but without the repeat
-- (only triggers on the first frame the key is down)
function keyd(k)
	if (not _keyd_keys[k]) _keyd_keys[k] = true
	return key(k) and not _keyd_last[k]
end
function _keyd_update()
	for k, _ in pairs(_keyd_keys) do
		_keyd_last[k] = key(k)
	end
end

-- log a string to the debug output
function log(str)
	add(debug_output, str)
	if #debug_output > 10 then
		deli(debug_output, 1)
	end
end

-- check if a table contains a value
function contains(tbl, val)
	for k, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end
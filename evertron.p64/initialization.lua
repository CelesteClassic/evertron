--[[pod_format="raw",created="2024-07-29 19:52:34",modified="2024-08-12 08:08:16",revision=413]]
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
draw_x, draw_y, cam_x, cam_y, cam_spdx, cam_spdy = 0, 0, 0, 0, 0, 0
cam_gain = 0.25

-- [entry point]

function _init()
	picotron_frames = 0
	frames = 0
	start_game_flash = 0

	music(40, 0, 7)
	lvl_id = 0
	
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
	
	music(0, 0, 7)
	load_level(1)
end

function is_title()
	return lvl_id == 0
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

function rectangle(x, y, w, h)
	return {x = x, y = y, w = w, h = h}
end

function round(x)
	return flr(x + 0.5)
end

function appr(val, target, amount)
	return val > target and max(val - amount, target) or min(val + amount, target)
end

function sign(v)
	return v ~= 0 and sgn(v) or 0
end

function two_digit_str(x)
	return x < 10 and "0"..x or x
end

function center_print(text, x, y, c)
	local w = print(text, 0, -1000)
	print(text, x - w / 2, y, c)
end

-- pass in "lil", "lil_mono", or "p8"
function set_font(font)
	fetch("/system/fonts/" .. font .. ".font"):poke(0x4000)
	game_font = font
end

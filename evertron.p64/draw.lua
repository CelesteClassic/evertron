--[[pod_format="raw",created="2024-07-29 19:55:38",modified="2024-08-12 08:08:16",revision=466]]
-- [draw loop]

function _draw()
	-- Skip every other frame for 30fps
	-- NOTE: btnp() will not work
	if (picotron_frames % 2 == 0) return

	-- freeze frames
	if freeze > 0 then
		return
	end

	-- reset all palette values
	pal()

	-- start game flash
	if is_title() then
		if start_game then
			for i = 1, 15 do
				pal(i, start_game_flash <= 10 and ceil(max(start_game_flash) / 5) or frames % 10 < 5 and 7 or i)
			end
		end

		cls()

		-- "CELESTE"
		if game_w == 240 then
			spr(47, game_w / 2 - 28, game_h / 2 - 32)
		elseif game_w == 480 then
			sspr(47, 0, 0, 56, 32, game_w / 2 - 56, game_h / 2 - 48, 112, 64)
		end
		
		-- credits
		center_print("\142 / \151", game_w / 2, game_h * 0.75 - 20, 5)
		center_print("maddy thorson", game_w / 2, game_h * 0.75, 5)
		center_print("noel berry", game_w / 2, game_h * 0.75 + 10, 5)

		-- particles
		foreach(particles, draw_particle)

		return
	end

	-- draw bg color
	cls(flash_bg and frames / 5 or bg_col)

	-- bg clouds effect
	foreach(clouds, function(c)
		c.x += c.spd - cam_spdx
		rectfill(c.x, c.y, c.x + c.w, c.y + 16 - c.w * 0.1875, cloud_col)
		if c.x > game_w then
			c.x = -c.w
			c.y = rnd(game_h)
		end
	end)
	
	-- set cam draw position
	draw_x = round(cam_x) - game_w / 2
	draw_y = round(cam_y) - game_h / 2
	camera(draw_x, draw_y)
	
	-- draw bg terrain
	draw_layer(4, lvl_x, lvl_y, 0, 0, lvl_w, lvl_h) -- background walls
	draw_layer(3, lvl_x, lvl_y, 0, 0, lvl_w, lvl_h) -- deco
	
	-- set draw layering
	-- positive layers draw after player
	-- layer 0 draws before player, after terrain
	-- negative layers draw before terrain
	local pre_draw, post_draw = {}, {}
	foreach(objects, function(obj)
		local draw_grp = obj.layer < 0 and pre_draw or post_draw
		
		::sort::
		for k, v in ipairs(draw_grp) do
			if obj.layer <= v.layer then
				add(draw_grp, obj, k)
				goto done_sorting
			end
		end
		add(draw_grp, obj)
		
		::done_sorting::
		if draw_grp == post_draw and obj.draw_below then
			draw_grp = pre_draw
			goto sort
		end
	end)

	-- draw bg objects
	for obj in all(pre_draw) do
		-- some objects can kind of draw on multiple layers, like the memorial for example
		-- if you define a draw_below function for it, it calls that here (and then calls obj:draw() like normal later)
		if obj.draw_below then
			obj:draw_below()
		else
			obj:draw()
		end
	end
	
	-- draw terrain
	draw_layer(2, lvl_x, lvl_y, 0, 0, lvl_w, lvl_h, 2)
	
	-- draw fg objects
	for obj in all(post_draw) do 
		obj:draw()
	end

	-- draw jumpthroughs
	draw_layer(2, lvl_x, lvl_y, 0, 0, lvl_w, lvl_h, 8)

	-- particles
	foreach(particles, draw_particle)

	-- dead particles
	foreach(dead_particles, function(p)
		p.x += p.dx
		p.y += p.dy
		p.t -= 0.2
		if p.t <= 0 then
			del(dead_particles, p)
		end
		rectfill(p.x - p.t, p.y - p.t, p.x + p.t, p.y + p.t, 14 + 5 * p.t % 2)
	end)

	-- draw level title
	camera()
	if ui_timer >= -30 then
		if ui_timer < 0 then
			draw_ui()
		end
		ui_timer -= 1
	end
end

function draw_particle(p)
	p.x += p.spd - cam_spdx
	p.y += sin(p.off) - cam_spdy
	p.off += min(0.05, p.spd / 32)
	rectfill(p.x + draw_x, p.y % game_h + draw_y, p.x + p.s + draw_x, p.y % game_h + p.s + draw_y, p.c)
	if p.x > game_w + 4 then
		p.x = -4
		p.y = rnd(game_h)
	elseif p.x < -4 then
		p.x = game_w
		p.y = rnd(game_h)
	end
end

function draw_time(x, y)
	rectfill(x, y, x + 32, y + 6, 0)
	?two_digit_str(minutes \ 60) .. ":" .. two_digit_str(minutes % 60) .. ":" .. two_digit_str(seconds), x + 1, y + 1, 7
end

function draw_ui()
	rectfill(game_w / 2 - 40, game_h / 2 - 6, game_w / 2 + 40, game_h / 2 + 4, 0)
	local title = lvl_title or lvl_id .. "00 m"
	center_print(title, game_w / 2, game_h / 2 - 2, 7)
	draw_time(4, 4)
end
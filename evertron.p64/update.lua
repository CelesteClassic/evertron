--[[pod_format="raw",created="2024-07-29 19:55:07",modified="2024-08-11 10:30:55",revision=349]]
-- [update loop]


function _update()
	-- Skip every other frame for 30fps
	picotron_frames += 1
	if (picotron_frames % 2 == 0) return
	
	frames += 1
	
	if time_ticking then
		seconds += frames \ 30
		minutes += seconds \ 60
		seconds %= 60
	end
	frames %= 30

	if music_timer > 0 then
		music_timer -= 1
		if music_timer <= 0 then
			music(10, 0, 7)
		end
	end

	-- cancel if freeze
	if freeze > 0 then
		freeze -= 1
		return
	end

	-- restart (soon)
	if delay_restart > 0 then
		cam_spdx, cam_spdy = 0, 0
		delay_restart -= 1
		if delay_restart == 0 then
			load_level(lvl_id)
		end
	end

	-- update each object
	foreach(objects, function(obj)
		obj.move(obj.spd.x, obj.spd.y, 0);
		obj:update()
		
		-- clamp objects that need to be clamped
		if obj.clamps then
			local clamped = obj.x
			if (lvl_exit ~= "left") clamped = max(-1, clamped)
			if (lvl_exit ~= "right") clamped = min(lvl_pw - 7, clamped)
			
			if obj.x ~= clamped then
				obj.x = clamped
				obj.spd.x = 0
			end
			-- clamp on top if it's not the exit
			if lvl_exit ~= "up" and obj.y < -1 then
				obj.y = -1
				obj.spd.y = 0
			end
		end
	end)

	-- move camera to player
	foreach(objects, function(obj)
		if obj.type == player or obj.type == player_spawn then
			move_camera(obj)
		end
	end)

	-- start game
	if is_title() then
		if start_game then
			start_game_flash -= 1
			if start_game_flash <= -30 then
				begin_game()
			end
		elseif btn(4) or btn(5) then
			music(-1)
			start_game_flash, start_game = 50, true
			sfx(38)
		end
	end
end
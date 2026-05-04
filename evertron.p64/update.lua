--[[pod_format="raw",created="2024-07-29 19:55:07",modified="2026-05-04 23:31:46",revision=366,xstickers={}]]
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
	
	-- debug mode
	if config.dev_mode and keyd("`") then
		debug_mode = not debug_mode
	end

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
		cam.spdx, cam.spdy = 0, 0
		delay_restart -= 1
		if delay_restart == 0 then
			load_level(level.id)
		end
	end

	-- update each object
	foreach(objects, function(obj)
		obj.move(obj.spd.x, obj.spd.y, 0);
		obj:update()
		
		-- clamp objects that need to be clamped
		if obj.clamps then
			obj.clamp()
		end
	end)

	-- move camera to player
	camera_follow()

	-- start game
	if is_title then
		if start_game then
			start_game_flash -= 1
			if start_game_flash <= -30 then
				begin_game()
			end
		elseif btn(4) or btn(5) then
			music(-1)
			start_game_flash = 50
			start_game = true
			sfx(38)
		end
		if config.dev_mode and key("shift") then
			if keyd("e") then
				-- load first level with shift+e (no title screen flash)
				begin_game()
				goto inputs
			elseif keyd("q") then
				-- load last level with shift+q
				begin_game()
				load_level(#levels)
				goto inputs
			end
		end
	end
	
	-- skip levels
	if config.dev_mode and key("shift") then
		if keyd("e") and level.id < #levels then
			next_level()
		end
		if keyd("q") and level.id > 1 then
			load_level(level.id - 1)
		end
	end
	
	::inputs::
	_keyd_update()
end
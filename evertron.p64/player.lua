--[[pod_format="raw",created="2024-07-29 19:55:57",modified="2024-08-12 08:08:16",revision=367]]
-- [player class]

player = {
	layer = 1,
	collides = true,
	clamps = true,
}
function player:init()
	self.grace, self.jbuffer = 0, 0
	self.djump = max_djump
	self.dash_time, self.dash_effect_time = 0, 0
	self.dash_target_x, self.dash_target_y = 0, 0
	self.dash_accel_x, self.dash_accel_y = 0, 0
	self.hitbox = rectangle(1, 3, 6, 5)
	self.spr_off = 0
end
function player:update()
	if pause_player then
		return
	end

	-- input (horizontal and vertical)
	local h_input = btn(1) and 1 or btn(0) and -1 or 0
	local v_input = btn(2) and -1 or btn(3) and 1 or 0

	-- spike collision
	if spikes_at(self.left(), self.top(), self.right(), self.bottom(), self.spd.x, self.spd.y) then
		kill_player(self)
	end
	
	-- fall into pit (unless level exit is down)
	if self.y > lvl_ph and lvl_exit ~= "down" then
		kill_player(self)
	end

	-- on ground checks
	local on_ground = self.is_solid(0, 1)

	-- landing smoke
	if on_ground and not self.was_on_ground then
		self.init_smoke(0, 4)
	end

	-- jump and dash input
	local jump, dash = btn(4) and not self.p_jump, btn(5) and not self.p_dash
	self.p_jump, self.p_dash = btn(4), btn(5)

	-- jump buffer
	if jump then
		self.jbuffer = 4
	elseif self.jbuffer > 0 then
		self.jbuffer -= 1
	end

	-- grace frames and dash restoration
	if on_ground then
		self.grace = 6
		if self.djump < max_djump then
			sfx(54)
			self.djump = max_djump
		end
	elseif self.grace > 0 then
		self.grace -= 1
	end

	-- dash effect timer (for dash-triggered events, e.g., berry blocks)
	self.dash_effect_time -= 1

	-- dash startup period, accel toward dash target speed
	if self.dash_time > 0 then
		self.init_smoke()
		self.dash_time -= 1
		self.spd = vec(appr(self.spd.x, self.dash_target_x, self.dash_accel_x), appr(self.spd.y, self.dash_target_y, self.dash_accel_y))
	else
		-- x movement
		local maxrun = 1
		local accel = self.is_ice(0, 1) and 0.05 or on_ground and 0.6 or 0.4
		local deccel = 0.15

		-- set x speed
		self.spd.x = abs(self.spd.x) <= 1 and
		appr(self.spd.x, h_input * maxrun, accel) or
		appr(self.spd.x, sign(self.spd.x) * maxrun, deccel)

		-- facing direction
		if self.spd.x ~= 0 then
			self.flip.x = self.spd.x < 0
		end

		-- y movement
		local maxfall = 2

		-- wall slide
		if h_input ~= 0 and self.is_solid(h_input, 0) and not self.is_ice(h_input, 0) then
			maxfall = 0.4
			-- wall slide smoke
			if rnd(10) < 2 then
				self.init_smoke(h_input * 6)
			end
		end

		-- apply gravity
		if not on_ground then
			self.spd.y = appr(self.spd.y, maxfall, abs(self.spd.y) > 0.15 and 0.21 or 0.105)
		end

		-- jump
		if self.jbuffer > 0 then
			if self.grace > 0 then
				-- normal jump
				sfx(1)
				self.jbuffer = 0
				self.grace = 0
				self.spd.y = -2
				self.init_smoke(0, 4)
			else
				-- wall jump
				local wall_dir = (self.is_solid(-3, 0) and -1 or self.is_solid(3, 0) and 1 or 0)
				if wall_dir ~= 0 then
					sfx(2)
					self.jbuffer = 0
					self.spd = vec(wall_dir * (-1 - maxrun), -2)
					if not self.is_ice(wall_dir * 3, 0) then
						-- wall jump smoke
						self.init_smoke(wall_dir * 6)
					end
				end
			end
		end

		-- dash
		local d_full = 5
		-- 5 * sqrt(2) = 3.5355339059
		local d_half = 3.5355339059

		if self.djump > 0 and dash then
			self.init_smoke()
			self.djump -= 1
			self.dash_time = 4
			has_dashed = true
			self.dash_effect_time = 10
			
			-- calculate dash speeds
			local no_vert = v_input == 0
			if h_input == 0 then
				-- empty dash (no input) or vertical dash
				self.spd = vec(no_vert and (self.flip.x and -1 or 1) or 0, v_input * d_full)
			else
				-- full horizontal or diagonal dash
				self.spd = vec(h_input * (no_vert and d_full or d_half), v_input * d_half)
			end
			
			-- effects
			sfx(3)
			freeze = 2
			
			-- dash target speeds and accels
			self.dash_target_x = 2 * sign(self.spd.x)
			self.dash_target_y = (self.spd.y >= 0 and 2 or 1.5) * sign(self.spd.y)
			self.dash_accel_x = self.spd.y == 0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
			self.dash_accel_y = self.spd.x == 0 and 1.5 or 1.06066017177
		elseif self.djump <= 0 and dash then
			-- failed dash smoke
			sfx(9)
			self.init_smoke()
		end
	end

	-- animation
	self.spr_off += 0.25
	self.spr = not on_ground and (self.is_solid(h_input, 0) and 5 or 3) or -- wall slide or mid air
	btn(3) and 6 or -- crouch
	btn(2) and 7 or -- look up
	self.spd.x ~= 0 and h_input ~= 0 and 1 + self.spr_off % 4 or 1 -- walk or stand

	if should_exit_level(self.x,self.y) then
		next_level()
	end

	-- was on the ground
	self.was_on_ground = on_ground
end
function player:draw()
	-- draw player hair and sprite
	set_hair_color(self.djump)
	draw_hair(self)
	self:draw_sprite()
	pal()
end

function create_hair(obj)
	obj.hair = {}
	for i = 1, 5 do
		add(obj.hair, vec(obj.x, obj.y))
	end
end

function set_hair_color(djump)
	pal(8, djump == 1 and 8 or djump == 2 and 7 + frames \ 3 % 2 * 4 or 12)
end

function draw_hair(obj)
	local last = vec(obj.x + (obj.flip.x and 6 or 2), obj.y + (obj.spr == 6 and 4 or 3))
	for i, h in ipairs(obj.hair) do
		h.x += (last.x - h.x) / 1.5
		h.y += (last.y + 0.5 - h.y) / 1.5
		circfill(h.x, h.y, mid(4 - i, 1, 2), 8)
		last = h
	end
end

function kill_player(obj)
	sfx(0)
	deaths += 1
	destroy_object(obj)
	
	for dir = 0, 0.875, 0.125 do
		add(dead_particles, {
			x = obj.x + 4,
			y = obj.y + 4,
			t = 2,
			dx = sin(dir) * 3,
			dy = cos(dir) * 3
		})
	end
	delay_restart = 15
end

player_spawn = {
	layer = 6, 
	draw = player.draw
}
function player_spawn:init()
	sfx(4)
	self.spr = 3
	self.target = self.y
	
	if lvl_enter == "up" then
		self.y = min(self.y + 48, lvl_ph)
		self.spd.y = -4
	elseif lvl_enter == "down" then
		self.y = max(self.y - 48, -4)
		self.spd.y = 1
	elseif lvl_enter == "right" then
		self.spd = vec(2, -1)
		self.x -= 20
	elseif lvl_enter == "left" then
		self.spd = vec(-2, -1)
		self.x += 20
		self.flip.x = true
	end
	
	cam_x, cam_y = mid(self.x + 4, 64, lvl_pw - 64), mid(self.y, 64, lvl_ph - 64)
	
	self.state = 0
	self.delay = 0
	
	create_hair(self)
	self.djump = max_djump
end 
function player_spawn:update()
	if self.state == 0 and self.y < self.target + 16 then
		-- jumping up
		self.state = 1
		if (lvl_enter ~= "down") self.delay = 3
	elseif self.state == 1 then
		-- falling
		self.spd.y += 0.5
		self.spd.y = min(self.spd.y, 3)
			
		if self.spd.y > 0 then
			if self.delay > 0 then
				-- stall at peak
				self.spd.y = 0
				self.delay -= 1
			elseif self.y > self.target then
				-- clamp at target y
				self.y = self.target
				self.spd = vec(0, 0)
				self.state = 2
				self.delay = 5
				self.init_smoke(0, 4)
				sfx(5)
			end
		end
	elseif self.state == 2 then
 		-- landing and spawning player object
		self.delay -= 1
		self.spr = 6
		if self.delay < 0 then
			destroy_object(self)
			local p = init_object(player, self.x, self.y)
			p.hair = self.hair
			p.flip.x = self.flip.x
		end
	end
end
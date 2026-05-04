--[[pod_format="raw",created="2024-07-29 20:10:42",modified="2026-05-04 04:49:54",revision=651,xstickers={}]]
-- [objects]

spring = {
	layer = -1,
}
function spring:init()
	self.delta = 0
	self.dir = self.flip.x and -1 or self.spr == 9 and 0 or 1
	self.show = true
end
function spring:update()
	self.delta = self.delta * 0.75
	local hit = self.player_here()
	
	if self.show and hit and self.delta <= 1 then
		if self.dir == 0 then
			hit.move(0, self.y - hit.y - 4, 1)
			hit.spd.x *= 0.2
			hit.spd.y = -3
		else
			hit.move(self.x + self.dir * 4 - hit.x, 0, 1)
			hit.spd = vec(self.dir * 3, -1.5)
		end
		hit.dash_time = 0
		hit.dash_effect_time = 0
		hit.djump = max_djump
		self.delta = 8
		sfx(8)
		self.init_smoke()
		
		break_fall_floor(self.check(fall_floor, -self.dir, self.dir == 0 and 1 or 0))
	end
end
function spring:draw()
	if self.show then
		local delta = min(flr(self.delta), 4)
		if self.dir == 0 then
			spr(9, self.x, self.y + delta)
		else
			spr(8, self.x + delta * -self.dir, self.y, self.flip.x)
		end
	end
end

fall_floor = {
	solid_obj = true,
	state = 0,
}
function fall_floor:update()
	-- idling
	if self.state == 0 then
		for i = 0, 2 do
			if self.check(player, i - 1, -(i % 2)) then
				break_fall_floor(self)
			end
		end
	-- shaking
	elseif self.state == 1 then
		self.delay -= 1
		if self.delay <= 0 then
			self.state = 2
			self.delay = 60 -- how long it hides for
			self.collideable = false
			set_springs(self, false)
		end
	-- invisible, waiting to reset
	elseif self.state == 2 then
		self.delay -= 1
		if self.delay <= 0 and not self.player_here() then
			sfx(7)
			self.state = 0
			self.collideable = true
			self.init_smoke()
			set_springs(self, true)
		end
	end
end
function fall_floor:draw()
	if self.state ~= 2 then
		spr(self.state == 1 and 35 - self.delay / 5 or self.state == 0 and 32, self.x, self.y)
	end
end

function break_fall_floor(obj)
	if obj and obj.state == 0 then
		sfx(15)
		obj.state = 1
		obj.delay = 15 -- how long until it falls
		obj.init_smoke()
	end
end

function set_springs(obj, state)
	obj.hitbox = rectangle(-2, -2, 12, 8)
	local springs = obj.check_all(spring, 0, 0)
	foreach(springs, function(s) s.show = state end)
	obj.hitbox = rectangle(0, 0, 8, 8)
end

balloon = {}
function balloon:init()
	self.offset = rnd()
	self.start = self.y
	self.timer = 0
	self.hitbox = rectangle(-1, -1, 10, 10)
	self.show = true
end
function balloon:update()
	if self.show then
		self.offset += 0.01
		if not config.static_balloons then
			self.y = self.start + sin(self.offset) * 2
		end
		
		local hit = self.player_here()
		if hit and hit.djump < max_djump then
			sfx(6)
			self.init_smoke()
			hit.djump = max_djump
			self.show = false
			self.timer = 60
		end
	elseif self.timer > 0 then
		self.timer -= 1
	else
		sfx(7)
		self.init_smoke()
		self.show = true
	end
end
function balloon:draw()
	if self.show then
		local y = self.y
		if config.static_balloons then
			y += sin(self.offset) * 2
		end
		
		-- string
		for i = 7, 13 do
			pset(self.x + 4 + sin(self.offset * 2 + i / 10), y + i, 6)
		end
		-- balloon itself
		spr(self.spr, self.x, y)
	end
end

smoke = {
	layer = 3
}
function smoke:init()
	self.spd = vec(0.3 + rnd(0.2), -0.1)
	self.x += -1 + rnd(2)
	self.y += -1 + rnd(2)
	self.flip = {x = rnd() < 0.5, y = rnd() < 0.5}
end
function smoke:update()
	self.spr += 0.2
	if self.spr >= 24 then
		destroy_object(self)
	end
end

fruit = {
	check_fruit = true
}
function fruit:init()
	self.start = self.y
	self.off = 0
end
function fruit:update()
	check_fruit(self)
	self.off += 0.025
	if not config.static_balloons then
		self.y = self.start + sin(self.off) * 2.5
	end
end
function fruit:draw()
	local y = self.y
	if (config.static_balloons) y += sin(self.off) * 2.5
	spr(self.spr, self.x, y)
end

fly_fruit = {
	check_fruit = true
}
function fly_fruit:init()
	self.start = self.y
	self.step = 0.5
	self.sfx_delay = 8
end
function fly_fruit:update()
	if has_dashed then
		-- fly away
		if self.sfx_delay > 0 then
			self.sfx_delay -= 1
			if self.sfx_delay <= 0 then
				sfx(14)
			end
		end
		self.spd.y = appr(self.spd.y, -3.5, 0.25)
		if self.y < -16 then
			destroy_object(self)
		end
	else
		-- wait
		self.step += 0.05
		self.spd.y = sin(self.step) * 0.5
	end
	-- collect
	check_fruit(self)
end
function fly_fruit:draw()
	spr(20, self.x, self.y)
	-- wings
	for ox = -6, 6, 12 do
		spr((has_dashed or sin(self.step) >= 0) and 40 or self.y > self.start and 42 or 41, self.x + ox, self.y - 2, ox == -6)
	end
end

function check_fruit(self)
	local hit = self.player_here()
	if hit then
		hit.djump = max_djump
		sfx(13)
		got_fruit[self.fruit_id] = true
		init_object(lifeup, self.x, self.y)
		destroy_object(self)
		if time_ticking then
			fruit_count += 1
		end
	end
end

lifeup = {}
function lifeup:init()
	self.spd.y = -0.25
	self.duration = 30
	self.flash = 0
end
function lifeup:update()
	self.duration -= 1
	if self.duration <= 0 then
		destroy_object(self)
	end
end
function lifeup:draw()
	self.flash += 0.5
	?"1000", self.x - 4, self.y - 4, 7 + self.flash % 2
end

fake_wall = {
	check_fruit = true,
	solid_obj = true
}
function fake_wall:init()
	self.solid_obj = true
	self.hitbox = rectangle(0, 0, 16, 16)
end
function fake_wall:update()
	self.hitbox = rectangle(-1, -1, 18, 18)
	local hit = self.player_here()
	if hit and hit.dash_effect_time > 0 then
		hit.spd = vec(sign(hit.spd.x) * -1.5, -1.5)
		hit.dash_time = -1
		for ox = 0, 8, 8 do
			for oy = 0, 8, 8 do
				self.init_smoke(ox, oy)
			end
		end
		init_fruit(self, 4, 4)
	end
	self.hitbox = rectangle(0, 0, 16, 16)
end
function fake_wall:draw()
	spr(14, self.x, self.y)
end

function init_fruit(self, ox, oy)
	sfx(16)
	init_object(fruit, self.x + ox, self.y + oy, 20).fruit_id = self.fruit_id
	destroy_object(self)
end

berry_key = {}
function berry_key:ready()
	if (not config.fix_evercore_keys) return
	
	for other in all(objects) do
		if other.type == chest then
			return
		end
	end
	
	-- destroy key if no chests exist (take that, evercore keys!)
	destroy_object(self)
end
function berry_key:update()
	self.spr = flr(25.5 + sin(frames / 30))
	if frames == 18 then
		self.flip.x = not self.flip.x
	end
	if self.player_here() then
		sfx(23)
		destroy_object(self)
		has_key = true
	end
end
function berry_key:draw()
	if config.fix_key_wobble then
		spr(self.spr, self.x + (self.flip.x and 1 or 0), self.y, self.flip.x)
	else
		self:draw_sprite()
	end
end

chest = {
	check_fruit = true
}
function chest:init()
	self.x -= 4
	self.start = self.x
	self.timer = 20
end
function chest:update()
	if has_key then
		self.timer -= 1
		self.x = self.start - 1 + rnd(3)
		if self.timer <= 0 then
			init_fruit(self, 0, -4)
		end
	end
end

platform = {
	layer = 2
}
function platform:init()
	self.x -= 4
	self.hitbox.w = 16
	self.dir = self.flip.x and -1 or 1
	self.semisolid_obj = true
end
function platform:update()
	self.spd.x = self.dir * 0.65
	-- screenwrap
	if self.x < -16 then
		self.x = level.pw
	elseif self.x > level.pw then
		self.x = -16
	end
end
function platform:draw()
	spr(15, self.x, self.y - 1)
end

message = {
	layer = 10
}
function message:init()
	self.text = "-- celeste mountain --#this memorial to those# perished on the climb"
	self.hitbox.x += 4
	self.hitbox.y += 8
end
function message:draw()
	if self.check(player, 4, 0) then
		if self.index < #self.text then
			self.index += 0.5
			if self.index >= self.last + 1 then
				self.last += 1
				sfx(35)
			end
		end
		local _x, _y = game_w / 2 - 56, game_h - 32
		local _x0 = _x
		camera()
		for i = 1, self.index do
			if sub(self.text, i, i) ~= "#" then
				rectfill(_x - 2, _y - 2, _x + 7, _y + 6, 7)
				print(sub(self.text, i, i), _x, _y, 0)
				_x += 5
			else
				_x = _x0
				_y += 7
			end
		end
		camera(draw_x, draw_y)
	else
		self.index = 0
		self.last = 0
	end
end
function message:draw_below()
	spr(12, self.x, self.y)
end

big_chest = {}
function big_chest:init()
	self.state = max_djump > 1 and 2 or 0
	self.hitbox.w = 16
end
function big_chest:update()
	if self.state == 0 then
		local hit = self.check(player, 0, 8)
		if hit and hit.is_solid(0, 1) then
			music(-1, 500, 7)
			sfx(37)
			pause_player = true
			hit.spd = vec(0, 0)
			self.state = 1
			self.init_smoke()
			self.init_smoke(8)
			self.timer = 60
			self.particles = {}
		end
	elseif self.state == 1 then
		self.timer -= 1
		flash_bg = true
		if self.timer <= 45 and #self.particles < 50 then
			add(self.particles, {
				x = 1 + rnd(14),
				y = 0,
				h = 32 + rnd(32),
				spd = 8 + rnd(8)
			})
		end
		if self.timer < 0 then
			self.state = 2
			self.particles = {}
			flash_bg, bg_col, cloud_col = false, 2, 14
			init_object(orb, self.x + 4, self.y + 4, 48)
			pause_player = false
		end
	end
end
function big_chest:draw()
	if self.state == 0 then
		self:draw_sprite()
	elseif self.state == 1 then
		foreach(self.particles, function(p)
			p.y += p.spd
			line(self.x + p.x, self.y + 8 - p.y, self.x + p.x, min(self.y + 8 - p.y + p.h, self.y + 8), 7)
		end)
	end
	sspr(self.spr, 0, 8, 16, 8, self.x, self.y + 8)
end

orb = {}
function orb:init()
	self.spd.y = -4
end
function orb:update()
	self.spd.y = appr(self.spd.y, 0, 0.5)
	local hit = self.player_here()
	if self.spd.y == 0 and hit then
		music_timer = 45
		sfx(51)
		freeze = 10
		destroy_object(self)
		max_djump = 2
		hit.djump = 2
	end
end
function orb:draw()
	self:draw_sprite()
	for i=0, 0.875, 0.125 do
		circfill(self.x + 4 + cos(frames / 30 + i) * 8, self.y + 4 + sin(frames / 30 + i) * 8, 1, 7)
	end
end

flag = {
	layer = 10,
}
function flag:init()
	self.x += 5
end
function flag:update()
	if not self.show and self.player_here() then
		sfx(55)
		self.show = true
		time_ticking = false
	end
end
function flag:draw()
	if self.show then
		camera()
		rectfill(game_w / 2 - 32, 2, game_w / 2 + 32, 31, 0)
		spr(20, game_w / 2 - 9, 6)
		?"x" .. fruit_count, game_w / 2, 9, 7
		draw_time(game_w / 2 - 15, 16)
		?"deaths:" .. deaths, game_w / 2 - 16, 24, 7
		camera(draw_x, draw_y)
	end
end
function flag:draw_below()
	spr(16 + frames / 5 % 3, self.x, self.y)
end

-- [object class]

function init_object(type, x, y, tile, extra_data)
	-- generate and check berry id
	local id = x .. "," .. y .. "," .. level.id
	if type.check_fruit and got_fruit[id] then
		return
	end

	local obj = {
		type = type,
		collideable = true,
		spr = tile,
		flip = {x = false, y = false},
		x = x,
		y = y,
		hitbox = rectangle(0, 0, 8, 8),
		spd = vec(0, 0),
		rem = vec(0, 0),
		layer = 0,
		
		fruit_id = id,
	}
	
	if tile and tile & 0x4000 > 0 then
		obj.flip.x = true
		obj.spr -= 0x4000
	end
	
	if extra_data then
		for k, v in pairs(extra_data) do
			obj[k] = v
		end
	end

	function obj.left() return obj.x + obj.hitbox.x end
	function obj.right() return obj.left() + obj.hitbox.w - 1 end
	function obj.top() return obj.y + obj.hitbox.y end
	function obj.bottom() return obj.top() + obj.hitbox.h - 1 end

	function obj.is_solid(ox, oy)
		ox = ox or 0
		oy = oy or 0
		
		for o in all(objects) do
			if o != obj and (o.solid_obj or o.semisolid_obj and not obj.objcollide(o, ox, 0) and oy > 0) and obj.objcollide(o, ox, oy) then
				return true
			end
		end
		
		-- jumpthrough
		return oy > 0 and not obj.is_flag(ox, 0, 3) and obj.is_flag(ox, oy, 3)
		-- solid terrain
		or obj.is_flag(ox, oy, 0)
	end

	function obj.is_ice(ox, oy)
		ox = ox or 0
		oy = oy or 0
		
		return obj.is_flag(ox, oy, 4)
	end
	
	function obj.is_flag(ox, oy, flag)
		for i = max(-1, (obj.left() + ox) \ 8), min(level.w, (obj.right() + ox) / 8) do
			for j = max(-1, (obj.top() + oy) \ 8), min(level.h, (obj.bottom() + oy) / 8) do
				if fget(tile_at(i, j, 2), flag) then
					return true
				end
			end
		end
	end

	function obj.objcollide(other, ox, oy)
		ox = ox or 0
		oy = oy or 0
		
		return other.collideable and
		other.right() >= obj.left() + ox and
		other.bottom() >= obj.top() + oy and
		other.left() <= obj.right() + ox and
		other.top() <= obj.bottom() + oy
	end

	-- returns first object of type colliding with obj
	function obj.check(type, ox, oy)
		for other in all(objects) do
			if other and other.type == type and other ~= obj and obj.objcollide(other, ox, oy) then
				return other
			end
		end
	end
	
	-- returns all objects of type colliding with obj
	function obj.check_all(type, ox, oy)
		local tbl = {}
		for other in all(objects) do
			if other and other.type == type and other ~= obj and obj.objcollide(other, ox, oy) then
				add(tbl, other)
			end
		end
		
		if #tbl > 0 then return tbl end
	end

	function obj.player_here()
		return obj.check(player, 0, 0)
	end

	function obj.move(ox, oy, start)
		for axis in all{"x", "y"} do
			obj.rem[axis] += axis == "x" and ox or oy
			local amt = round(obj.rem[axis])
			obj.rem[axis] -= amt
			local upmoving = axis == "y" and amt < 0
			local riding = not obj.player_here() and obj.check(player, 0, upmoving and amt or -1)
			local movamt
			if obj.collides then
				local step = sign(amt)
				local d = axis == "x" and step or 0
				local p = obj[axis]
				for i = start, abs(amt) do
					if not obj.is_solid(d, step - d) then
						obj[axis] += step
					else
						obj.spd[axis], obj.rem[axis] = 0, 0
						break
					end
				end
				movamt = obj[axis] - p -- save how many px moved to use later for solids
			else
				movamt = amt
				if (obj.solid_obj or obj.semisolid_obj) and upmoving and riding then
					movamt += obj.top() - riding.bottom() - 1
					local hamt = round(riding.spd.y + riding.rem.y)
					hamt += sign(hamt)
					if movamt < hamt then
						riding.spd.y = max(riding.spd.y, 0)
					else
						movamt = 0
					end
				end
				obj[axis] += amt
			end
			if (obj.solid_obj or obj.semisolid_obj) and obj.collideable then
				obj.collideable = false
				local hit = obj.player_here()
				if hit and obj.solid_obj then
					hit.move(axis == "x" and (amt > 0 and obj.right() + 1 - hit.left() or amt < 0 and obj.left() - hit.right() - 1) or 0,
							axis == "y" and (amt > 0 and obj.bottom() + 1 - hit.top() or amt < 0 and obj.top() - hit.bottom() - 1) or 0,
							1)
					if obj.player_here() then
						kill_player(hit)
					end
				elseif riding then
					riding.move(axis == "x" and movamt or 0, axis == "y" and movamt or 0, 1)
				end
				obj.collideable = true
			end
		end
	end
	
	function obj.clamp()
		local clamped = obj.x
		if config.connected_map_mode then
			if not is_tile_in_lvl(obj.left() \ 8, obj.y \ 8) then
				-- left side clamp
				clamped = max(-1, clamped)
			end
			if not is_tile_in_lvl(obj.right() \ 8, obj.y \ 8) then
				-- right side clamp
				clamped = min(level.pw - 7, clamped)
			end
		else
			-- left side clamp
			if (not is_exit("left")) clamped = max(-1, clamped)
			
			-- right side clamp
			if (not is_exit("right")) clamped = min(level.pw - 7, clamped)
		end
		
		if obj.x ~= clamped then
			obj.x = clamped
			obj.spd.x = 0
		end
		-- clamp on top if it's not the exit
		if not is_exit("up") and obj.y < -1 then
			obj.y = -1
			obj.spd.y = max(obj.spd.y, 0)
		end
	end

	function obj.init_smoke(ox, oy)
		init_object(smoke, obj.x + (ox or 0), obj.y + (oy or 0), 21)
	end
	
	function obj:init() end
	
	function obj:update() end
	
	function obj:draw()
		spr(obj.spr, obj.x, obj.y, obj.flip.x, obj.flip.y)
	end
	
	-- this is the replacement for draw_obj_sprite
	-- useful if you override obj.draw but still use the default draw function
	obj.draw_sprite = obj.draw
	
	-- copy functions and other variables from type
	-- these functions can also override functions from the obj class
	-- for instance, obj.is_solid can be redefined per object
	for k, v in pairs(type) do
		obj[k] = v
	end

	add(objects, obj)

	obj:init()

	return obj
end

function destroy_object(obj)
	del(objects, obj)
end

function camera_follow()
	foreach(objects, function(obj)
		if obj.type == player or obj.type == player_spawn then
			move_camera(obj)
		end
	end)
end

function move_camera(obj, gain)
	if (not gain) gain = cam.gain
	
	-- don't target camera directly on the player,
	-- only follow if the player gets too far from the center
	local target_x = appr(obj.x + 4, cam.x, 16)
	local target_y = appr(obj.y, cam.y, 16)
	
	cam.spdx = gain * (target_x - cam.x)
	cam.spdy = gain * (target_y - cam.y)

	cam.x += cam.spdx
	cam.y += cam.spdy

	-- clamp camera to level boundaries
	local clamped = mid(cam.x, game_w / 2, level.pw - game_w / 2)
	if cam.x ~= clamped then
		cam.spdx = 0
		cam.x = clamped
	end
	
	local height = level.ph
	-- don't scroll vertically if there's less than a tile of height to scroll
	if (height - game_h < 8) height = game_h
	clamped = mid(cam.y, game_h / 2, height - game_h / 2)
	if cam.y ~= clamped then
		cam.spdy = 0
		cam.y = clamped
	end
end

function draw_object(obj)
	obj:draw()
end
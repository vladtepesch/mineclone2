--basic settings
local item_drop_settings                 = {} --settings table
item_drop_settings.age                   = 1.0 --how old a dropped item (_insta_collect==false) has to be before collecting
item_drop_settings.radius_magnet         = 2.0 --radius of item magnet. MUST BE LARGER THAN radius_collect!
item_drop_settings.radius_collect        = 0.2 --radius of collection
item_drop_settings.player_collect_height = 1.0 --added to their pos y value
item_drop_settings.collection_safety     = false --do this to prevent items from flying away on laggy servers
item_drop_settings.random_item_velocity  = true --this sets random item velocity if velocity is 0
item_drop_settings.drop_single_item      = false --if true, the drop control drops 1 item instead of the entire stack, and sneak+drop drops the stack
-- drop_single_item is disabled by default because it is annoying to throw away items from the intentory screen

item_drop_settings.magnet_time           = 0.75 -- how many seconds an item follows the player before giving up

local get_gravity = function()
	return tonumber(minetest.setting_get("movement_gravity")) or 9.81
end

local check_pickup_achievements = function(object, player)
	local itemname = ItemStack(object:get_luaentity().itemstring):get_name()
	if minetest.get_item_group(itemname, "tree") ~= 0 then
		awards.unlock(player:get_player_name(), "mcl:mineWood")
	elseif itemname == "mcl_mobitems:blaze_rod" then
		awards.unlock(player:get_player_name(), "mcl:blazeRod")
	elseif itemname == "mcl_mobitems:leather" then
		awards.unlock(player:get_player_name(), "mcl:killCow")
	elseif itemname == "mcl_core:diamond" then
		awards.unlock(player:get_player_name(), "mcl:diamonds")
	end
end

local enable_physics = function(object, luaentity, ignore_check)
	if luaentity.physical_state == false or ignore_check == true then
		luaentity.physical_state = true
		object:set_properties({
			physical = true
		})
		object:set_velocity({x=0,y=0,z=0})
		object:set_acceleration({x=0,y=-get_gravity(),z=0})
	end
end

local disable_physics = function(object, luaentity, ignore_check, reset_movement)
	if luaentity.physical_state == true or ignore_check == true then
		luaentity.physical_state = false
		object:set_properties({
			physical = false
		})
		if reset_movement ~= false then
			object:set_velocity({x=0,y=0,z=0})
			object:set_acceleration({x=0,y=0,z=0})
		end
	end
end

minetest.register_globalstep(function(dtime)
	for _,player in ipairs(minetest.get_connected_players()) do
		if player:get_hp() > 0 or not minetest.setting_getbool("enable_damage") then
			local pos = player:getpos()
			local inv = player:get_inventory()
			local checkpos = {x=pos.x,y=pos.y + item_drop_settings.player_collect_height,z=pos.z}

			--magnet and collection
			for _,object in ipairs(minetest.get_objects_inside_radius(checkpos, item_drop_settings.radius_magnet)) do
				if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" and (object:get_luaentity()._insta_collect or (object:get_luaentity().age > item_drop_settings.age)) then
					object:get_luaentity()._magnet_timer = object:get_luaentity()._magnet_timer + dtime
					local collected = false
					if object:get_luaentity()._magnet_timer >= 0 and object:get_luaentity()._magnet_timer < item_drop_settings.magnet_time and inv and inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then

						-- Collection
						if vector.distance(checkpos, object:getpos()) <= item_drop_settings.radius_collect then

							if object:get_luaentity().itemstring ~= "" then
								inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
								minetest.sound_play("item_drop_pickup", {
									pos = pos,
									max_hear_distance = 16,
									gain = 1.0,
								})
								check_pickup_achievements(object, player)
								object:get_luaentity().itemstring = ""
								object:remove()
								collected = true
							end

						-- Magnet
						else

							object:get_luaentity()._magnet_active = true
							object:get_luaentity()._collector_timer = 0

							--modified simplemobs api

							-- Move object to player
							local opos = object:getpos()
							local vec = vector.subtract(checkpos, opos)
							vec = vector.add(opos, vector.divide(vec, 2))
							object:moveto(vec)

							disable_physics(object, object:get_luaentity(), false, false)

							--fix eternally falling items
							minetest.after(0, function(object)
								local lua = object:get_luaentity()
								if lua then
									object:setacceleration({x=0, y=0, z=0})
								end
							end, object)


							--this is a safety to prevent items flying away on laggy servers
							if item_drop_settings.collection_safety == true then
								if object:get_luaentity().init ~= true then
									object:get_luaentity().init = true
									minetest.after(1, function(args)
										local player = args[1]
										local object = args[2]
										local lua = object:get_luaentity()
										if player == nil or not player:is_player() or object == nil or lua == nil or lua.itemstring == nil then
											return
										end
										if inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
											inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
											if object:get_luaentity().itemstring ~= "" then
												minetest.sound_play("item_drop_pickup", {
													pos = pos,
													max_hear_distance = 16,
													gain = 1.0,
												})
											end
											check_pickup_achievements(object, player)
											object:get_luaentity().itemstring = ""
											object:remove()
										else
											enable_physics(object, object:get_luaentity())
										end
									end, {player, object})
								end
							end
						end
					end

					if not collected then
						if object:get_luaentity()._magnet_timer > 1 then
							object:get_luaentity()._magnet_timer = -item_drop_settings.magnet_time
							object:get_luaentity()._magnet_active = false
						elseif object:get_luaentity()._magnet_timer < 0 then
							object:get_luaentity()._magnet_timer = object:get_luaentity()._magnet_timer + dtime
						end
					end

				end
			end

		end
	end
end)

function minetest.handle_node_drops(pos, drops, digger)
	if minetest.setting_getbool("creative_mode") or minetest.setting_getbool("mcl_doTileDrops") == false then
		return
	end
	for _,item in ipairs(drops) do
		local count, name
		if type(item) == "string" then
			count = 1
			name = item
		else
			count = item:get_count()
			name = item:get_name()
		end
		for i=1,count do
			local obj = minetest.add_item(pos, name)
			if obj ~= nil then
				local x = math.random(1, 5)
				if math.random(1,2) == 1 then
					x = -x
				end
				local z = math.random(1, 5)
				if math.random(1,2) == 1 then
					z = -z
				end
				obj:setvelocity({x=1/x, y=obj:getvelocity().y, z=1/z})
			end
		end
	end
end

-- Drop single items by default
function minetest.item_drop(itemstack, dropper, pos)
	if dropper and dropper:is_player() then
		local v = dropper:get_look_dir()
		local p = {x=pos.x, y=pos.y+1.2, z=pos.z}
		local cs = itemstack:get_count()
		if dropper:get_player_control().sneak then
			cs = 1
		end
		local item = itemstack:take_item(cs)
		local obj = core.add_item(p, item)
		if obj then
			v.x = v.x*4
			v.y = v.y*4 + 2
			v.z = v.z*4
			obj:setvelocity(v)
			-- Force collection delay
			obj:get_luaentity()._insta_collect = false
			return itemstack
		end
	end
end

--modify builtin:item

local time_to_live = tonumber(core.setting_get("item_entity_ttl"))
if not time_to_live then
	time_to_live = 300
end

core.register_entity(":__builtin:item", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
		visual = "wielditem",
		visual_size = {x = 0.4, y = 0.4},
		textures = {""},
		spritediv = {x = 1, y = 1},
		initial_sprite_basepos = {x = 0, y = 0},
		is_visible = false,
		infotext = "",
	},

	itemstring = '',
	physical_state = true,
	_flowing = false, -- item entity is currently flowing
	-- States:
	-- * "magnet": Attracted to a nearby player or item
	-- * "flowing": Moving in a flowing liquid
	-- * "normal": Affected by gravitiy
	age = 0,

	set_item = function(self, itemstring)
		self.itemstring = itemstring
		local stack = ItemStack(itemstring)
		local count = stack:get_count()
		local max_count = stack:get_stack_max()
		if count > max_count then
			count = max_count
			self.itemstring = stack:get_name().." "..max_count
		end
		local s = 0.2 + 0.1 * (count / max_count)
		local c = s
		local itemtable = stack:to_table()
		local itemname = nil
		local description = ""
		if itemtable then
			itemname = stack:to_table().name
		end
		local item_texture = nil
		local item_type = ""
		if core.registered_items[itemname] then
			item_texture = core.registered_items[itemname].inventory_image
			item_type = core.registered_items[itemname].type
			description = core.registered_items[itemname].description
		end
		local prop = {
			is_visible = true,
			visual = "wielditem",
			textures = {itemname},
			visual_size = {x = s, y = s},
			collisionbox = {-c, -c, -c, c, c, c},
			automatic_rotate = math.pi * 0.5,
			infotext = description,
		}
		self.object:set_properties(prop)
		if item_drop_settings.random_item_velocity == true then
			minetest.after(0, function(self)
				if not self or not self.object or not self.object:get_luaentity() then
					return
				end
				local vel = self.object:getvelocity()
				if vel and vel.x == 0 and vel.z == 0 then
					local x = math.random(1, 5)
					if math.random(1,2) == 1 then
						x = -x
					end
					local z = math.random(1, 5)
					if math.random(1,2) == 1 then
						z = -z
					end
					local y = math.random(2,4)
					self.object:setvelocity({x=1/x, y=y, z=1/z})
				end
			end, self)
		end

	end,

	get_staticdata = function(self)
		return core.serialize({
			itemstring = self.itemstring,
			always_collect = self.always_collect,
			age = self.age,
			_insta_collect = self._insta_collect,
			_flowing = self._flowing,
		})
	end,

	on_activate = function(self, staticdata, dtime_s)
		if string.sub(staticdata, 1, string.len("return")) == "return" then
			local data = core.deserialize(staticdata)
			if data and type(data) == "table" then
				self.itemstring = data.itemstring
				self.always_collect = data.always_collect
				if data.age then
					self.age = data.age + dtime_s
				else
					self.age = dtime_s
				end
				--remember collection data
				-- If true, can collect item without delay
				self._insta_collect = data._insta_collect
				self._flowing = data._flowing
			end
		else
			self.itemstring = staticdata
		end
		if self._insta_collect == nil then
			-- Intentionally default, since delayed collection is rare
			self._insta_collect = true
		end
		if self._flowing == nil then
			self._flowing = false
		end
		self._magnet_timer = 0
		self._magnet_active = false
		-- How long ago the last possible collector was detected. nil = none in this session
		self._collector_timer = nil
		-- Used to apply additional force
		self._force = nil
		self._forcestart = nil
		self._forcetimer = 0

		self.object:set_armor_groups({immortal = 1})
		self.object:setvelocity({x = 0, y = 2, z = 0})
		self.object:setacceleration({x = 0, y = -get_gravity(), z = 0})
		self:set_item(self.itemstring)
	end,

	try_merge_with = function(self, own_stack, object, obj)
		local stack = ItemStack(obj.itemstring)
		if own_stack:get_name() == stack:get_name() and stack:get_free_space() > 0 then
			local overflow = false
			local count = stack:get_count() + own_stack:get_count()
			local max_count = stack:get_stack_max()
			if count > max_count then
				overflow = true
				count = count - max_count
			else
				self.itemstring = ''
			end
			local pos = object:getpos()
			pos.y = pos.y + (count - stack:get_count()) / max_count * 0.15
			object:moveto(pos, false)
			local s, c
			local max_count = stack:get_stack_max()
			local name = stack:get_name()
			if not overflow then
				obj.itemstring = name .. " " .. count
				s = 0.2 + 0.1 * (count / max_count)
				c = s
				object:set_properties({
					visual_size = {x = s, y = s},
					collisionbox = {-c, -c, -c, c, c, c}
				})
				self.object:remove()
				-- merging succeeded
				return true
			else
				s = 0.4
				c = 0.3
				object:set_properties({
					visual_size = {x = s, y = s},
					collisionbox = {-c, -c, -c, c, c, c}
				})
				obj.itemstring = name .. " " .. max_count
				s = 0.2 + 0.1 * (count / max_count)
				c = s
				self.object:set_properties({
					visual_size = {x = s, y = s},
					collisionbox = {-c, -c, -c, c, c, c}
				})
				self.itemstring = name .. " " .. count
			end
		end
		-- merging didn't succeed
		return false
	end,

	on_step = function(self, dtime)
		self.age = self.age + dtime
		if self._collector_timer ~= nil then
			self._collector_timer = self._collector_timer + dtime
		end
		if time_to_live > 0 and self.age > time_to_live then
			self.itemstring = ''
			self.object:remove()
			return
		end
		local p = self.object:getpos()
		local node = core.get_node_or_nil(p)
		local in_unloaded = (node == nil)

		-- If no collector was found for a long enough time, declare the magnet as disabled
		if self._magnet_active and (self._collector_timer == nil or (self._collector_timer > item_drop_settings.magnet_time)) then
			self._magnet_active = false
			enable_physics(self.object, self)
			return
		end
		if in_unloaded then
			-- Don't infinetly fall into unloaded map
			disable_physics(self.object, self)
			return
		end

		-- Destroy item in lava or special nodes
		local nn = node.name
		local def = minetest.registered_nodes[nn]
		if (def and def.groups and (def.groups.lava or def.groups.destroys_items == 1)) then
			-- Special effect for lava
			if def.groups.lava then
				minetest.sound_play("builtin_item_lava", {pos = self.object:getpos(), gain = 0.5})
			end
			self.object:remove()
			return
		end

		-- Push item out when stuck inside solid opaque node
		if def and def.walkable and def.groups and def.groups.opaque == 1 then
			local shootdir
			local cx = p.x % 1
			local cz = p.z % 1
			local order = {}

			-- First prepare the order in which the 4 sides are to be checked.
			-- 1st: closest
			-- 2nd: other direction
			-- 3rd and 4th: other axis
			local cxcz = function(o, cw, one, zero)
				if cw > 0 then
					table.insert(o, { [one]=1, y=0, [zero]=0 })
					table.insert(o, { [one]=-1, y=0, [zero]=0 })
				else
					table.insert(o, { [one]=-1, y=0, [zero]=0 })
					table.insert(o, { [one]=1, y=0, [zero]=0 })
				end
				return o
			end
			if math.abs(cx) > math.abs(cz) then
				order = cxcz(order, cx, "x", "z")
				order = cxcz(order, cz, "z", "x")
			else
				order = cxcz(order, cz, "z", "x")
				order = cxcz(order, cx, "x", "z")
			end

			-- Check which one of the 4 sides is free
			for o=1, #order do
				local nn = minetest.get_node(vector.add(p, order[o])).name
				local def = minetest.registered_nodes[nn]
				if def and def.walkable == false and nn ~= "ignore" then
					shootdir = order[o]
					break
				end
			end
			-- If none of the 4 sides is free, shoot upwards
			if shootdir == nil then
				shootdir = { x=0, y=1, z=0 }
				local nn = minetest.get_node(vector.add(p, shootdir)).name
				if nn == "ignore" then
					-- Do not push into ignore
					return
				end
			end

			-- Set new item moving speed accordingly
			local newv = vector.multiply(shootdir, 3)
			self.object:setacceleration({x = 0, y = 0, z = 0})
			self.object:setvelocity(newv)

			disable_physics(self.object, self, false, false)

			if shootdir.y == 0 then
				self._force = newv
				p.x = math.floor(p.x)
				p.y = math.floor(p.y)
				p.z = math.floor(p.z)
				self._forcestart = p
				self._forcetimer = 1
			end
			return
		end

		-- This code is run after the entity got a push from above “push away” code.
		-- It is responsible for making sure the entity is entirely outside the solid node
		-- (with its full collision box), not just its center.
		if self._forcetimer > 0 then
			local cbox = self.object:get_properties().collisionbox
			local ok = false
			if self._force.x > 0 and (p.x > (self._forcestart.x + 0.5 + (cbox[4] - cbox[1])/2)) then ok = true
			elseif self._force.x < 0 and (p.x < (self._forcestart.x + 0.5 - (cbox[4] - cbox[1])/2)) then ok = true
			elseif self._force.z > 0 and (p.z > (self._forcestart.z + 0.5 + (cbox[6] - cbox[3])/2)) then ok = true
			elseif self._force.z < 0 and (p.z < (self._forcestart.z + 0.5 - (cbox[6] - cbox[3])/2)) then ok = true end
			-- Item was successfully forced out. No more pushing
			if ok then
				self._forcetimer = -1
				self._force = nil
				enable_physics(self.object, self)
			else
				self._forcetimer = self._forcetimer - dtime
			end
			return
		elseif self._force then
			self._force = nil
			enable_physics(self.object, self)
			return
		end

		-- Move item around on flowing liquids
		if def and def.liquidtype == "flowing" then

			--[[ Get flowing direction (function call from flowlib), if there's a liquid.
			NOTE: According to Qwertymine, flowlib.quickflow is only reliable for liquids with a flowing distance of 7.
			Luckily, this is exactly what we need if we only care about water, which has this flowing distance. ]]
			local vec = flowlib.quick_flow(p, node)
			-- Just to make sure we don't manipulate the speed for no reason
			if vec.x ~= 0 or vec.y ~= 0 or vec.z ~= 0 then
				-- Minecraft Wiki: Flowing speed is "about 1.39 meters per second"
				local f = 1.39
				-- Set new item moving speed into the direciton of the liquid
				local newv = vector.multiply(vec, f)
				self.object:setacceleration({x = 0, y = 0, z = 0})
				self.object:setvelocity({x = newv.x, y = -0.22, z = newv.z})

				self.physical_state = true
				self._flowing = true
				self.object:set_properties({
					physical = true
				})
				return
			end
		elseif self._flowing == true then
			-- Disable flowing physics if not on/in flowing liquid
			self._flowing = false
			enable_physics(self.object, self, true)
			return
		end

		-- If node is not registered or node is walkably solid and resting on nodebox
		local nn = minetest.get_node({x=p.x, y=p.y-0.5, z=p.z}).name
		local v = self.object:getvelocity()

		if not core.registered_nodes[nn] or core.registered_nodes[nn].walkable and v.y == 0 then
			if self.physical_state then
				local own_stack = ItemStack(self.object:get_luaentity().itemstring)
				-- Merge with close entities of the same item
				for _, object in ipairs(core.get_objects_inside_radius(p, 0.8)) do
					local obj = object:get_luaentity()
					if obj and obj.name == "__builtin:item"
							and obj.physical_state == false then
						if self:try_merge_with(own_stack, object, obj) then
							return
						end
					end
				end
				disable_physics(self.object, self)
			end
		else
			if self._magnet_active == false then
				enable_physics(self.object, self)
			end
		end
	end,

	-- Note: on_punch intentionally left out. The player should *not* be able to collect items by punching
})

if minetest.setting_get("log_mods") then
	minetest.log("action", "mcl_item_entity loaded")
end

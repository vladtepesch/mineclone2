-- Minetest 0.4 mod: default
-- See README.txt for licensing and other information.
local init = os.clock()
flower_tmp={}

-- Simple flower template
local smallflowerlongdesc = "This is a small flower. Small flowers are mainly used for dye production and can also be potted."

local function add_simple_flower(name, desc, image, simple_selection_box)
	minetest.register_node("mcl_flowers:"..name, {
		description = desc,
		_doc_items_longdesc = smallflowerlongdesc,
		drawtype = "plantlike",
		tiles = { image..".png" },
		inventory_image = image..".png",
		wield_image = image..".png",
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		stack_max = 64,
		groups = {dig_immediate=3,flammable=2,flower=1,attached_node=1,dig_by_water=1,deco_block=1},
		sounds = mcl_sounds.node_sound_leaves_defaults(),
		buildable_to = true,
		selection_box = {
			type = "fixed",
			fixed = simple_selection_box,
		},
	})
end

local box_tulip = { -0.15, -0.5, -0.15, 0.15, 5/16, 0.15 }

add_simple_flower("poppy", "Poppy", "mcl_flowers_poppy", { -0.15, -0.5, -0.15, 0.15, 3/16, 0.15 })
add_simple_flower("dandelion", "Dandelion", "flowers_dandelion_yellow", { -0.15, -0.5, -0.15, 0.15, 0, 0.15 })
add_simple_flower("oxeye_daisy", "Oxeye Daisy", "mcl_flowers_oxeye_daisy", { -0.15, -0.5, -0.15, 0.15, 5/16, 0.15 })
add_simple_flower("tulip_orange", "Orange Tulip", "flowers_tulip", box_tulip)
add_simple_flower("tulip_pink", "Pink Tulip", "mcl_flowers_tulip_pink", box_tulip)
add_simple_flower("tulip_red", "Red Tulip", "mcl_flowers_tulip_red", box_tulip)
add_simple_flower("tulip_white", "White Tulip", "mcl_flowers_tulip_white", box_tulip)
add_simple_flower("allium", "Allium", "mcl_flowers_allium", { -0.2, -0.5, -0.2, 0.2, 6/16, 0.2 })
add_simple_flower("azure_bluet", "Azure Bluet", "mcl_flowers_azure_bluet", { -3/16, -0.5, -3/16, 3/16, 2/16, 3/16 })
add_simple_flower("blue_orchid", "Blue Orchid", "mcl_flowers_blue_orchid", { -5/16, -0.5, -5/16, 5/16, 6/16, 5/16 })


local wheat_seed_drop = {
	max_items = 1,
	items = {
		{
			items = {'mcl_farming:wheat_seeds'},
			rarity = 8,
		},
	}
},

-- Tall Grass
minetest.register_node("mcl_flowers:tallgrass", {
	description = "Tall Grass",
	_doc_items_longdesc = "Tall grass is a small plant which often occours on the surface of grasslands. It can be harvested for wheat seeds. By using bone meal, tall grass can be turned into double tallgrass which is two blocks high.",
	drawtype = "plantlike",
	tiles = {"mcl_flowers_tallgrass.png"},
	inventory_image = "mcl_flowers_tallgrass.png",
	wield_image = "mcl_flowers_tallgrass.png",
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	is_ground_content = true,
	groups = {dig_immediate=3, flammable=3,attached_node=1,dig_by_water=1,deco_block=1},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	drop = wheat_seed_drop,
	after_dig_node = function(pos, oldnode, oldmetadata, user)
		local item = user:get_wielded_item()
		if item:get_name() == "mcl_tools:shears" then
			minetest.add_item(pos, oldnode.name)
		end
	end,
	_mcl_blast_resistance = 0,
	_mcl_hardness = 0,
})

--- Fern ---
minetest.register_node("mcl_flowers:fern", {
	description = "Fern",
	_doc_items_longdesc = "Ferns are small plants which occour naturally in grasslands. They can be harvested for wheat seeds. By using bone meal, a fern can be turned into a large fern which is two blocks high.",
	drawtype = "plantlike",
	tiles = { "mcl_flowers_fern.png" },
	inventory_image = "mcl_flowers_fern.png",
	wield_image = "mcl_flowers_fern.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	stack_max = 64,
	groups = {dig_immediate=3,flammable=2,attached_node=1,dig_by_water=1,deco_block=1},
	buildable_to = true,
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	after_dig_node = function(pos, oldnode, oldmetadata, user)
		local item = user:get_wielded_item()
		if item:get_name() == "mcl_tools:shears" then
			minetest.add_item(pos, oldnode.name)
		end
	end,
	drop = wheat_seed_drop,
	selection_box = {
		type = "fixed",
		fixed = { -4/16, -0.5, -4/16, 4/16, 7/16, 4/16 },
	},
})

local function add_large_plant(name, desc, longdesc, bottom_img, top_img, inv_img, drop)
	if not inv_img then
		inv_img = top_img
	end
	minetest.register_node("mcl_flowers:"..name, {
		description = desc,
		_doc_items_longdesc = longdesc,
		drawtype = "plantlike",
		tiles = { bottom_img },
		inventory_image = inv_img,
		wield_image = inv_img,
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		drop = drop,
		node_placement_prediction = "",
		on_place = function(itemstack, placer, pointed_thing)
			-- We can only place on nodes
			if pointed_thing.type ~= "node" then
				--return
			end
			-- Check for a floor and a space of 1×2×1
			local ptu_node = minetest.get_node(pointed_thing.under)
			local bottom
			if minetest.registered_nodes[ptu_node.name].buildable_to then
				bottom = pointed_thing.under
			else
				bottom = pointed_thing.above
			end
			local top = { x = bottom.x, y = bottom.y + 1, z = bottom.z }
			local bottom_buildable = minetest.registered_nodes[minetest.get_node(bottom).name].buildable_to
			local top_buildable = minetest.registered_nodes[minetest.get_node(top).name].buildable_to
			local floorname = minetest.get_node({x=bottom.x, y=bottom.y-1, z=bottom.z}).name
			if minetest.registered_nodes[floorname].walkable and bottom_buildable and top_buildable then
				-- Success! We can now place the flower
				minetest.sound_play(minetest.registered_nodes["mcl_flowers:"..name].sounds.place, {pos = bottom, gain=1})
				minetest.set_node(bottom, {name="mcl_flowers:"..name})
				minetest.set_node(top, {name="mcl_flowers:"..name.."_top"})
				if not minetest.setting_getbool("creative_mode") then
					itemstack:take_item()
				end
			end
			return itemstack
		end,
		after_destruct = function(pos, oldnode)
			-- Remove top half of flower (if it exists)
			local bottom = pos
			local top = { x = bottom.x, y = bottom.y + 1, z = bottom.z }
			if minetest.get_node(top).name == "mcl_flowers:"..name.."_top" then
				minetest.remove_node(top)
			end
		end,
		groups = {dig_immediate=3,flammable=2,flower=1,attached_node=1, dig_by_water=1, double_plant=1,deco_block=1},
		sounds = mcl_sounds.node_sound_leaves_defaults(),
	})

	-- Top
	minetest.register_node("mcl_flowers:"..name.."_top", {
		description = desc.." (Top Part)",
		_doc_items_create_entry = false,
		drawtype = "plantlike",
		tiles = { top_img },
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		drop = "",
		after_destruct = function(pos, oldnode)
			-- "Dig" bottom half of flower (if it exists)
			local top = pos
			local bottom = { x = top.x, y = top.y - 1, z = top.z }
			if minetest.get_node(bottom).name == "mcl_flowers:"..name then
				minetest.dig_node(bottom)
			end
		end,
		groups = {dig_immediate=3,flammable=2,flower=1, dig_by_water=1, not_in_creative_inventory = 1, double_plant=2},
		sounds = mcl_sounds.node_sound_leaves_defaults(),
	})
end

add_large_plant("peony", "Peony", nil, "mcl_flowers_double_plant_paeonia_bottom.png", "mcl_flowers_double_plant_paeonia_top.png")
add_large_plant("rose_bush", "Rose Bush", nil, "mcl_flowers_double_plant_rose_bottom.png", "mcl_flowers_double_plant_rose_top.png")
add_large_plant("lilac", "Lilac", nil, "mcl_flowers_double_plant_syringa_bottom.png", "mcl_flowers_double_plant_syringa_top.png")

add_large_plant("double_grass", "Double Tallgrass", nil, "mcl_flowers_double_plant_grass_bottom.png", "mcl_flowers_double_plant_grass_top.png", nil, wheat_seed_drop)
add_large_plant("double_fern", "Large Fern", nil, "mcl_flowers_double_plant_fern_bottom.png", "mcl_flowers_double_plant_fern_top.png", nil, wheat_seed_drop)

-- Lily Pad
minetest.register_node("mcl_flowers:waterlily", {
	description = "Lily Pad",
	_doc_items_longdesc = "A lily pad is a flat plant block which can be walked on. They can be placed on water sources, ice and frosted ice.",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	tiles = {"flowers_waterlily.png", "flowers_waterlily.png^[transformFY"},
	inventory_image = "flowers_waterlily.png",
	wield_image = "flowers_waterlily.png",
	liquids_pointable = true,
	walkable = true,
	sunlight_propagates = true,
	groups = {dig_immediate = 3, dig_by_water = 1, deco_block=1},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	node_placement_prediction = "",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -31/64, -0.5, 0.5, -15/32, 0.5}
	},
	selection_box = {
		type = "fixed",
		fixed = {-7 / 16, -0.5, -7 / 16, 7 / 16, -15 / 32, 7 / 16}
	},

	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local node = minetest.get_node(pointed_thing.under)
		local nodename = node.name
		local def = minetest.registered_nodes[nodename]
		local node_above = minetest.get_node(pointed_thing.above).name
		local def_above = minetest.registered_nodes[node_above]
		local player_name = placer:get_player_name()

		if def then
			-- Use pointed node's on_rightclick function first, if present
			if placer and not placer:get_player_control().sneak then
				if def and def.on_rightclick then
					return def.on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
				end
			end

			if (pointed_thing.under.x == pointed_thing.above.x and pointed_thing.under.z == pointed_thing.above.z) and
					((def.liquidtype == "source" and minetest.get_item_group(nodename, "water") > 0) or
					(nodename == "mcl_core:ice") or
					(minetest.get_item_group(nodename, "frosted_ice") > 0)) and
					(def_above.buildable_to and minetest.get_item_group(node_above, "liquid") == 0) then
				if not minetest.is_protected(pos, player_name) then
					minetest.set_node(pos, {name = "mcl_flowers:waterlily",
						param2 = math.random(0, 3)})
					if not minetest.setting_getbool("creative_mode") then
						itemstack:take_item()
					end
				else
					minetest.chat_send_player(player_name, "Node is protected")
					minetest.record_protection_violation(pos, player_name)
				end
			end
		end

		return itemstack
	end
})

-- Legacy support
minetest.register_alias("mcl_core:tallgrass", "mcl_flowers:tallgrass")

-- Show loading time
local time_to_load= os.clock() - init
print(string.format("[MOD] "..minetest.get_current_modname().." loaded in %.4f s", time_to_load))

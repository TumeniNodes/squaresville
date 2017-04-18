-- Squaresville nodes.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


minetest.register_node("squaresville:road", {
  description = "Road",
  tiles = {"squaresville_tarmac.png"},
  sounds = default.node_sound_stone_defaults(),
  groups = {cracky = 2, level = 1},
})
newnode = squaresville.clone_node("squaresville:road")
newnode.tiles = {"squaresville_tarmac.png^[brighten"}
minetest.register_node("squaresville:road_white", newnode)

minetest.register_node("squaresville:road_broken", {
  description = "Road",
  tiles = {"squaresville_tarmac.png^squaresville_broken_3.png"},
  paramtype = "light",
  drawtype = "nodebox",
  node_box = { type = "fixed",
  fixed = {
    {0.5, 0.3, 0.5, -0.5, -0.5, -0.5}
  }
},
sounds = default.node_sound_stone_defaults(),
groups = {cracky = 2, level = 1},
})

minetest.register_node("squaresville:road_yellow_line", {
  description = "Road",
  tiles = {"squaresville_tarmac_yellow_line.png"},
  paramtype2 = "facedir",
  sounds = default.node_sound_stone_defaults(),
  groups = {cracky = 2, level = 1},
})

local newnode = squaresville.clone_node("default:stone")
newnode.description = 'Concrete'
newnode.drop = 'default:cobble'
minetest.register_node("squaresville:concrete", newnode)

minetest.register_node("squaresville:light_panel", {
  description = "Light Panel",
  tiles = {"default_sandstone.png"},
  light_source = 8,
  paramtype = "light",
  paramtype2 = "facedir",
  drawtype = "nodebox",
  node_box = { type = "fixed",
  fixed = {
    {-0.5, -0.5, -0.5, 0.5, -0.48, 0.5},
  } },
  groups = {cracky = 3, level=1, oddly_breakable_by_hand = 1},
  on_place = minetest.rotate_and_place,
  sounds = default.node_sound_stone_defaults(),
})
newnode = squaresville.clone_node("squaresville:light_panel")


-- ice, thin -- transparent
minetest.register_node("squaresville:thin_ice", {
  description = "Thin Ice",
  tiles = {"caverealms_thin_ice.png"},
  is_ground_content = true,
  groups = {cracky=3},
  sounds = default.node_sound_glass_defaults(),
  use_texture_alpha = true,
  light_source = 1,
  drawtype = "glasslike",
  sunlight_propagates = true,
  freezemelt = "default:water_source",
  paramtype = "light",
})


minetest.register_node("squaresville:plate_glass", {
	description = "Plate Glass",
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = {"squaresville_plate_glass.png"},
	light_source = 1,
	use_texture_alpha = true,
	is_ground_content = false,
	groups = {cracky = 3, level=1},
	sounds = default.node_sound_stone_defaults(),
})
newnode = squaresville.clone_node("squaresville:plate_glass")
newnode.tiles = {"squaresville_plate_glass_broken.png"}
newnode.walkable = false
minetest.register_node("squaresville:plate_glass_broken", newnode)
minetest.register_alias("squaresville:glass_broken", "squaresville:plate_glass_broken")


minetest.register_node("squaresville:floor_ceiling", {
	description = "Floor/Ceiling",
	tiles = {"squaresville_floor.png", "squaresville_ceiling.png", "default_stone.png"},
	paramtype2 = "facedir",
	groups = {cracky = 3, level=1, flammable = 3},
	drop = "default:cobble",
	drop = {
		max_items = 3,
		items = {
			{
				items = {"default:cobble",},
				rarity = 1,
			},
			{
				items = {"default:copper_ingot",},
				rarity = 6,
			},
		},
	},
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})
newnode = squaresville.clone_node("squaresville:floor_ceiling")
newnode.tiles = {"squaresville_floor.png^squaresville_broken_3.png", "squaresville_ceiling.png^squaresville_broken_3.png", "default_stone.png^squaresville_broken_3.png"}
minetest.register_node("squaresville:floor_ceiling_broken", newnode)


minetest.register_node("squaresville:roof", {
	description = "Roof",
	tiles = {"squaresville_tarmac.png", "squaresville_ceiling.png", "default_stone.png"},
	paramtype2 = "facedir",
	groups = {cracky = 3, level=1, flammable = 3},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})
minetest.register_node("squaresville:roof_broken", {
	description = "Roof",
	tiles = {"squaresville_tarmac.png^squaresville_broken_3.png", "squaresville_ceiling.png^squaresville_broken_3.png", "default_stone.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	drop = "default:cobble",
	node_box = { type = "fixed",
		fixed = {
			{0.5, 0.3, 0.5, -0.5, -0.5, -0.5}
		}
	},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 3, level=1, flammable = 3},
	is_ground_content = false,
})


minetest.register_node("squaresville:sidewalk", {
	description = "Sidewalk",
	tiles = {"squaresville_sidewalk.png"},
	groups = {cracky = 3, level=1, stone = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})
newnode = squaresville.clone_node("squaresville:sidewalk")
newnode.tiles = {"squaresville_sidewalk.png^squaresville_broken_3.png"}
minetest.register_node("squaresville:sidewalk_broken", newnode)

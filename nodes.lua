-- Squaresville nodes.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local newnode
local light_max = default.light_max or 10

local darkening = 0
if squaresville.desolation > 0 then
  darkening = 100
end

newnode = squaresville.clone_node("default:stone")
newnode.diggable = false
newnode.groups = {}
minetest.register_node("squaresville:bedrock", newnode)


minetest.register_node('squaresville:road', {
  description = 'Road',
  tiles = {'squaresville_tarmac.png'},
  sounds = default.node_sound_stone_defaults(),
  groups = {cracky = 2, level = 1},
  is_ground_content = false,
})
newnode = squaresville.clone_node('squaresville:road')
newnode.tiles = {'squaresville_tarmac.png^[brighten'}
minetest.register_node('squaresville:road_white', newnode)

minetest.register_node('squaresville:road_broken', {
  description = 'Road',
  tiles = {'squaresville_tarmac.png^squaresville_broken_3.png'},
  paramtype = 'light',
  drawtype = 'nodebox',
  node_box = { type = 'fixed',
  fixed = {
    {0.5, 0.3, 0.5, -0.5, -0.5, -0.5}
  },
  is_ground_content = false,
},
sounds = default.node_sound_stone_defaults(),
groups = {cracky = 2, level = 1},
})

minetest.register_node('squaresville:road_yellow_line', {
  description = 'Road',
  tiles = {'squaresville_tarmac_yellow_line.png'},
  paramtype2 = 'facedir',
  sounds = default.node_sound_stone_defaults(),
  groups = {cracky = 2, level = 1},
  is_ground_content = false,
})

--minetest.register_node('squaresville:concrete', {
--	description = 'Concrete',
--	tiles = {'default_stone.png'},
--	groups = {cracky = 3, level=1, stone = 1},
--	drop = 'default:cobble',
--	sounds = default.node_sound_stone_defaults(),
--	is_ground_content = false,
--})
newnode = squaresville.clone_node('default:stone')
newnode.description = 'Concrete'
newnode.is_ground_content = false
newnode.drop = 'default:cobble'
minetest.register_node('squaresville:concrete', newnode)
newnode = squaresville.clone_node('squaresville:concrete')
newnode.tiles = {'default_stone.png^squaresville_broken_3_low.png'}
minetest.register_node('squaresville:concrete_broken', newnode)

newnode = squaresville.clone_node('squaresville:concrete')
newnode.tiles = {'default_stone.png^[colorize:#964B00:40'}
minetest.register_node('squaresville:concrete2', newnode)
newnode.tiles = {'default_stone.png^[colorize:#FF0000:20'}
minetest.register_node('squaresville:concrete3', newnode)
newnode.tiles = {'default_stone.png^[colorize:#4682B4:10'}
minetest.register_node('squaresville:concrete4', newnode)
newnode.tiles = {'default_stone.png^[colorize:#000000:40'}
minetest.register_node('squaresville:concrete5', newnode)

newnode = squaresville.clone_node('squaresville:concrete_broken')
newnode.tiles = {'default_stone.png^[colorize:#964B00:40^squaresville_broken_3_low.png'}
minetest.register_node('squaresville:concrete2_broken', newnode)
newnode.tiles = {'default_stone.png^[colorize:#FF0000:20^squaresville_broken_3_low.png'}
minetest.register_node('squaresville:concrete3_broken', newnode)
newnode.tiles = {'default_stone.png^[colorize:#4682B4:10^squaresville_broken_3_low.png'}
minetest.register_node('squaresville:concrete4_broken', newnode)
newnode.tiles = {'default_stone.png^[colorize:#000000:40^squaresville_broken_3_low.png'}
minetest.register_node('squaresville:concrete5_broken', newnode)

minetest.register_node('squaresville:light_panel', {
  description = 'Light Panel',
  tiles = {'default_sandstone.png'},
  light_source = 14,
  paramtype = 'light',
  paramtype2 = 'facedir',
  drawtype = 'nodebox',
  node_box = { type = 'fixed',
  fixed = {
    {-0.5, -0.5, -0.5, 0.5, -0.48, 0.5},
  } },
  groups = {cracky = 3, level=1, oddly_breakable_by_hand = 1},
  on_place = minetest.rotate_and_place,
  sounds = default.node_sound_stone_defaults(),
  is_ground_content = false,
})
newnode = squaresville.clone_node('squaresville:light_panel')
newnode = squaresville.clone_node("squaresville:light_panel")
newnode.light_source = 0
minetest.register_node("squaresville:light_panel_broken", newnode)


-- ice, thin -- transparent
minetest.register_node('squaresville:thin_ice', {
  description = 'Thin Ice',
  tiles = {'caverealms_thin_ice.png'},
  is_ground_content = true,
  groups = {cracky=3},
  sounds = default.node_sound_glass_defaults(),
  use_texture_alpha = true,
  light_source = 1,
  drawtype = 'glasslike',
  sunlight_propagates = true,
  freezemelt = 'default:water_source',
  paramtype = 'light',
})


minetest.register_node('squaresville:plate_glass', {
  description = 'Plate Glass',
  drawtype = 'glasslike',
  paramtype = 'light',
  sunlight_propagates = true,
  tiles = {'squaresville_plate_glass.png'},
  light_source = 1,
  use_texture_alpha = true,
  is_ground_content = false,
  groups = {cracky = 3, level=1},
  sounds = default.node_sound_stone_defaults(),
  is_ground_content = false,
})
newnode = squaresville.clone_node('squaresville:plate_glass')
newnode.tiles = {'squaresville_plate_glass_broken.png'}
newnode.walkable = false
minetest.register_node('squaresville:plate_glass_broken', newnode)
minetest.register_alias('squaresville:glass_broken', 'squaresville:plate_glass_broken')


minetest.register_node('squaresville:floor_ceiling', {
  description = 'Floor/Ceiling',
  tiles = {'squaresville_floor.png^[colorize:#000000:'..darkening, 'squaresville_ceiling.png', 'default_stone.png'},
  paramtype2 = 'facedir',
  groups = {cracky = 3, level=1, flammable = 3},
  drop = 'default:cobble',
  drop = {
    max_items = 3,
    items = {
      {
        items = {'default:cobble',},
        rarity = 1,
      },
      {
        items = {'default:copper_ingot',},
        rarity = 6,
      },
    },
  },
  sounds = default.node_sound_stone_defaults(),
  is_ground_content = false,
})
newnode = squaresville.clone_node('squaresville:floor_ceiling')
newnode.tiles = {'squaresville_floor.png^[colorize:#000000:'..darkening..'^squaresville_broken_3.png', 'squaresville_ceiling.png^squaresville_broken_3.png', 'default_stone.png^squaresville_broken_3.png'}
minetest.register_node('squaresville:floor_ceiling_broken', newnode)


minetest.register_node('squaresville:roof', {
  description = 'Roof',
  tiles = {'squaresville_tarmac.png', 'squaresville_ceiling.png', 'default_stone.png'},
  paramtype2 = 'facedir',
  groups = {cracky = 3, level=1, flammable = 3},
  drop = 'default:cobble',
  sounds = default.node_sound_stone_defaults(),
  is_ground_content = false,
})
minetest.register_node('squaresville:roof_broken', {
  description = 'Roof',
  tiles = {'squaresville_tarmac.png^squaresville_broken_3.png', 'squaresville_ceiling.png^squaresville_broken_3.png', 'default_stone.png'},
  paramtype = 'light',
  paramtype2 = 'facedir',
  drawtype = 'nodebox',
  drop = 'default:cobble',
  node_box = { type = 'fixed',
  fixed = {
    {0.5, 0.3, 0.5, -0.5, -0.5, -0.5}
  }
},
sounds = default.node_sound_stone_defaults(),
groups = {cracky = 3, level=1, flammable = 3},
is_ground_content = false,
})


minetest.register_node('squaresville:sidewalk', {
  description = 'Sidewalk',
  tiles = {'squaresville_sidewalk.png'},
  groups = {cracky = 3, level=1, stone = 1},
  drop = 'default:cobble',
  sounds = default.node_sound_stone_defaults(),
  is_ground_content = false,
})
newnode = squaresville.clone_node('squaresville:sidewalk')
newnode.tiles = {'squaresville_sidewalk.png^squaresville_broken_3.png'}
minetest.register_node('squaresville:sidewalk_broken', newnode)


minetest.register_node('squaresville:gargoyle', {
  description = 'Concrete',
  tiles = {'default_stone.png^[colorize:#000000:60'},
  paramtype = 'light',
  paramtype2 = 'facedir',
  drawtype = 'nodebox',
  node_box = { type = 'fixed',
  fixed = {
    {0.2, 0.23, -0.17, -0.1, -0.5, 0.17},   -- body f
    {-0.1, -0.07, -0.17, -0.27, -0.5, 0.17},   -- body r
    {0.17, 0.5, -0.07, 0, 0.23, 0.07}, -- head
    {0.27, 0.2, 0.1, 0.13, -0.5, 0.23}, -- leg fl
    {0.27, 0.2, -0.23, 0.13, -0.5, -0.1}, -- leg fr
    {0.03, -0.1, 0.17, -0.2, -0.5, 0.27}, -- leg rl
    {0.03, -0.1, -0.27, -0.2, -0.5, -0.17}, -- leg rl
    {-0.1, 0.23, -0.4, -0.17, 0.13, 0.4}, -- wing u
    {-0.1, 0.13, -0.3, -0.17, 0.03, 0.3}, -- wing u
  } },
  groups = {cracky = 3, level=1, stone = 1},
  drop = 'default:cobble',
  on_place = minetest.rotate_and_place,
  sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("squaresville:plaster", {
  description = "Plaster",
  tiles = {"default_desert_stone.png^[colorize:#8C8175:225"},
  sounds = default.node_sound_stone_defaults(),
  groups = {cracky = 3, level = 0, flammable = 2, oddly_breakable_by_hand = 1},
})
newnode = squaresville.clone_node("squaresville:plaster")
newnode.tiles = {"(default_desert_stone.png^[colorize:#8C8175:225)^squaresville_broken_3_low.png"}
minetest.register_node("squaresville:plaster_broken", newnode)


newnode = squaresville.clone_node("stairs:stair_stone")
newnode.description = "Concrete Stair"
newnode.groups.flammable = 3
newnode.drop = "stairs:stair_stone"
minetest.register_node("squaresville:concrete_stair", newnode)


minetest.register_node("squaresville:carpet", {
  description = "Carpet",
  tiles = {"wool_blue.png", "default_stone.png", "default_stone.png"},
  sounds = default.node_sound_stone_defaults(),
  groups = {cracky = 2, level = 1},
})
minetest.register_alias("squaresville:carpet_broken", "default:stone")


newnode = squaresville.clone_node("default:glass")
newnode.description = "Glowing Crystal"
--newnode.tiles = {"squaresville_plate_glass.png^colorize:#FFFF00,150",}
newnode.tiles = {"squaresville_crystal.png",}
newnode.light_source = LIGHT_MAX - 4
minetest.register_node("squaresville:crystal_glow", newnode)


if minetest.registered_items['underworlds:glowing_fungal_stone'] then
  minetest.register_alias("squaresville:glowing_fungal_stone", 'underworlds:glowing_fungal_stone')
  minetest.register_alias("squaresville:glowing_fungus", 'underworlds:glowing_fungus')
else
  -- Glowing fungal stone provides an eerie light.
  minetest.register_node("squaresville:glowing_fungal_stone", {
    description = "Glowing Fungal Stone",
    tiles = {"default_stone.png^vmg_glowing_fungal.png",},
    is_ground_content = true,
    light_source = light_max - 4,
    groups = {cracky=3, stone=1},
    drop = {items={ {items={"default:cobble"},}, {items={"squaresville:glowing_fungus",},},},},
    sounds = default.node_sound_stone_defaults(),
  })

  -- Glowing fungus grows underground.
  minetest.register_craftitem("squaresville:glowing_fungus", {
    description = "Glowing Fungus",
    drawtype = "plantlike",
    paramtype = "light",
    tiles = {"vmg_glowing_fungus.png"},
    inventory_image = "vmg_glowing_fungus.png",
    groups = {dig_immediate = 3},
  })
end


minetest.register_node("squaresville:wet_fungus", {
	description = "Leaves",
	--drawtype = "allfaces_optional",
	--waving = 1,
	tiles = {"wet_fungus_2.png"},
	--special_tiles = {"wet_fungus_2.png"},
	--paramtype = "light",
	--is_ground_content = false,
	groups = {snappy = 3},
	drop = '',
	sounds = default.node_sound_leaves_defaults(),
})

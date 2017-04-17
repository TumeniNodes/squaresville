-- Squaresville init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local water_level = 1

local math_floor = math.floor
local math_ceil = math.ceil
local math_abs = math.abs
local math_random = math.random
local soil_depth_max = 3

local csize

local heat_1_p = {offset = 50, scale = 50, seed = 5349, spread = {x = 750, y = 750, z = 750}, octaves = 3, persist = 0.5, lacunarity = 2}
local heat_2_p = {offset = 0, scale = 1.5, seed = 13, spread = {x = 8, y = 8, z = 8}, octaves = 2, persist = 1.0, lacunarity = 2}
local humidity_1_p = {offset = 50, scale = 50, seed = 842, spread = {x = 750, y = 750, z = 750}, octaves = 3, persist = 0.5, lacunarity = 2}
local humidity_2_p = {offset = 0, scale = 1.5, seed = 90003, spread = {x = 8, y = 8, z = 8}, octaves = 2, persist = 1.0, lacunarity = 2}
local heat_1_map, heat_2_map, humidity_1_map, humidity_2_map = {}, {}, {}, {}
local heat_1_noise, heat_2_noise, humidity_1_noise, humidity_2_noise

local avgt, countt = 0,0


do
	local biome_mod = {
		coniferous_forest_dunes = { heat_point = 35, humidity_point = 60, },
		coniferous_forest = { heat_point = 35, humidity_point = 60, },
		coniferous_forest_ocean = { heat_point = 35, humidity_point = 60, },
		deciduous_forest = { heat_point = 60, humidity_point = 60, },
		deciduous_forest_ocean = { heat_point = 60, humidity_point = 60, },
		deciduous_forest_swamp = { heat_point = 60, humidity_point = 60, },
		desert = { heat_point = 80, humidity_point = 10, },
		desert_ocean = { heat_point = 80, humidity_point = 10, },
		glacier = {},
		glacier_ocean = {},
		rainforest = { heat_point = 85, humidity_point = 70, },
		rainforest_ocean = { heat_point = 85, humidity_point = 70, },
		rainforest_swamp = { heat_point = 85, humidity_point = 70, },
		sandstone_grassland_dunes = { heat_point = 55, humidity_point = 40, },
		sandstone_grassland = { heat_point = 55, humidity_point = 40, },
		sandstone_grassland_ocean = { heat_point = 55, humidity_point = 40, },
		savanna = { heat_point = 80, humidity_point = 25, },
		savanna_ocean = { heat_point = 80, humidity_point = 25, },
		savanna_swamp = { heat_point = 80, humidity_point = 25, },
		stone_grassland_dunes = { heat_point = 35, humidity_point = 40, },
		stone_grassland = { heat_point = 35, humidity_point = 40, },
		stone_grassland_ocean = { heat_point = 35, humidity_point = 40, },
		taiga = {},
		taiga_ocean = {},
		--tundra = { node_river_water = "squaresville:thin_ice", },
		--tundra_beach = { node_river_water = "squaresville:thin_ice", },
		tundra_ocean = {},
	}
	local rereg = {}

	for n, bi in pairs(biome_mod) do
		for i, rbi in pairs(minetest.registered_biomes) do
			if rbi.name == n then
				rereg[#rereg+1] = table.copy(rbi)
				for j, prop in pairs(bi) do
					rereg[#rereg][j] = prop
				end
			end
		end
	end

	minetest.clear_registered_biomes()

	for _, bi in pairs(rereg) do
		minetest.register_biome(bi)
	end

	rereg = {}
	for _, dec in pairs(minetest.registered_decorations) do
		rereg[#rereg+1] = dec
	end
	minetest.clear_registered_decorations()
	for _, dec in pairs(rereg) do
		minetest.register_decoration(dec)
	end
	rereg = nil


	minetest.register_biome({
		name = "desertstone_grassland",
		--node_dust = "",
		node_top = "default:dirt_with_grass",
		depth_top = 1,
		node_filler = "default:dirt",
		depth_filler = 1,
		node_stone = "default:desert_stone",
		node_riverbed = "default:sand",
		depth_riverbed = 2,
		--node_water_top = "",
		--depth_water_top = ,
		--node_water = "",
		--node_river_water = "",
		y_min = 6,
		y_max = 31000,
		heat_point = 80,
		humidity_point = 55,
	})


	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"default:dirt_with_grass"},
		sidelen = 80,
		fill_ratio = 0.1,
		biomes = {"desertstone_grassland", },
		y_min = 1,
		y_max = 31000,
		decoration = "default:junglegrass",
	})
end


flowers.register_decorations()


squaresville.decorations = {}
local bad_deco = {}
for _, i in pairs({"apple_tree", "pine_tree", "jungle_tree", "acacia_tree", "aspen_tree", }) do
	bad_deco[i] = true
end

do
	for _, odeco in pairs(minetest.registered_decorations) do
		if not odeco.schematic then
			local deco = {}
			if odeco.biomes then
				deco.biomes = {}
				for _, b in pairs(odeco.biomes) do
					deco.biomes[b] = true
				end
			end

			deco.deco_type = odeco.deco_type
			deco.decoration = odeco.decoration
			deco.schematic = odeco.schematic
			deco.fill_ratio = odeco.fill_ratio

			if odeco.noise_params then
				deco.fill_ratio = math.max(0.001, (odeco.noise_params.scale + odeco.noise_params.offset) / 4)
			end

			local nod = minetest.registered_nodes[deco.decoration]
			if nod and nod.groups and nod.groups.flower then
				deco.flower = true
			end

			squaresville.decorations[#squaresville.decorations+1] = deco
		end
	end
end

minetest.clear_registered_decorations()


local function register_flower(name, desc, biomes, chance)
	local groups = {}
	groups.snappy = 3
	groups.flammable = 2
	groups.flower = 1
	groups.flora = 1
	groups.attached_node = 1

	minetest.register_node("squaresville:" .. name, {
		description = desc,
		drawtype = "plantlike",
		waving = 1,
		tiles = {"squaresville_" .. name .. ".png"},
		inventory_image = "squaresville_" .. name .. ".png",
		wield_image = "flowers_" .. name .. ".png",
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		stack_max = 99,
		groups = groups,
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		}
	})

	local bi = {}
	if biomes then
		bi = {}
		for _, b in pairs(biomes) do
			bi[b] = true
		end
	end

	squaresville.decorations[#squaresville.decorations+1] = {
		deco_type = "simple",
		place_on = {"default:dirt_with_grass"},
		biomes = bi,
		fill_ratio = chance,
		flower = true,
		decoration = "squaresville:"..name,
	}
end

register_flower("orchid", "Orchid", {"rainforest", "rainforest_swamp"}, 0.025)
register_flower("bird_of_paradise", "Bird of Paradise", {"rainforest", "desertstone_grassland"}, 0.025)
register_flower("gerbera", "Gerbera", {"savanna", "rainforest", "desertstone_grassland"}, 0.005)


local function register_decoration(deco, place_on, biomes, chance)
	local bi = {}
	if biomes then
		bi = {}
		for _, b in pairs(biomes) do
			bi[b] = true
		end
	end

	squaresville.decorations[#squaresville.decorations+1] = {
		deco_type = "simple",
		place_on = place_on,
		biomes = bi,
		fill_ratio = chance,
		decoration = deco,
	}
end


squaresville.biomes = {}
local biomes = squaresville.biomes
local biome_names = {}
do
	--local biome_terrain_scale = {}
	--biome_terrain_scale["coniferous_forest"] = 0.75
	--biome_terrain_scale["rainforest"] = 0.33
	--biome_terrain_scale["underground"] = 1.5

	local tree_biomes = {}
	tree_biomes["deciduous_forest"] = {"apple_tree", 'aspen_tree'}
	tree_biomes["coniferous_forest"] = {"pine_tree"}
	tree_biomes["taiga"] = {"pine_tree"}
	tree_biomes["rainforest"] = {"jungle_tree"}
	tree_biomes["rainforest_swamp"] = {"jungle_tree"}
	tree_biomes["coniferous_forest"] = {"pine_tree"}
	tree_biomes["savanna"] = {"acacia_tree"}

	for i, obiome in pairs(minetest.registered_biomes) do
		local biome = table.copy(obiome)
		biome.special_tree_prob = 2 * 25
		if string.match(biome.name, "^rainforest") then
			biome.special_tree_prob = 0.8 * 25
		end
		if biome.name == "savanna" then
			biome.special_tree_prob = 30 * 25
		end
		--biome.terrain_scale = biome_terrain_scale[biome] or 0.5
		--if string.find(biome.name, "ocean") then
		--	biome.terrain_scale = 1
		--end
		--if string.find(biome.name, "swamp") then
		--	biome.terrain_scale = 0.25
		--end
		--if string.find(biome.name, "beach") then
		--	biome.terrain_scale = 0.25
		--end
		--if string.find(biome.name, "^underground$") then
		--	biome.node_top = "default:stone"
		--end
		biome.special_trees = tree_biomes[biome.name]
		biomes[biome.name] = biome
		biome_names[#biome_names+1] = biome.name
	end
end


local function get_decoration(biome_name)
	for i, deco in pairs(squaresville.decorations) do
		if not deco.biomes or deco.biomes[biome_name] then
			local range = 1000
			if deco.deco_type == "simple" then
				if deco.fill_ratio and math.random(range) - 1 < deco.fill_ratio * 1000 then
					return deco.decoration
				end
			else
				-- nop
			end
		end
	end
end


squaresville.decorate = function(minp, maxp, data, p2data, area, node, heightmap, river_1)
	if not (minp and maxp and data and p2data and area and node and type(data) == 'table' and type(p2data) == 'table') then
		return
	end

	if not csize then
		csize = vector.add(vector.subtract(maxp, minp), 1)
	end

  if not (heat_1_noise and heat_2_noise and humidity_1_noise and humidity_2_noise) then
    heat_1_noise = minetest.get_perlin_map(heat_1_p, {x=csize.x, y=csize.z})
    heat_2_noise = minetest.get_perlin_map(heat_2_p, {x=csize.x, y=csize.z})
    humidity_1_noise = minetest.get_perlin_map(humidity_1_p, {x=csize.x, y=csize.z})
    humidity_2_noise = minetest.get_perlin_map(humidity_2_p, {x=csize.x, y=csize.z})

    if not (heat_1_noise and heat_2_noise and humidity_1_noise and humidity_2_noise) then
      return
    end
  end

	heat_1_map = heat_1_noise:get2dMap_flat({x=minp.x, y=minp.z}, heat_1_map)
	heat_2_map = heat_2_noise:get2dMap_flat({x=minp.x, y=minp.z}, heat_2_map)
	humidity_1_map = humidity_1_noise:get2dMap_flat({x=minp.x, y=minp.z}, humidity_1_map)
	humidity_2_map = humidity_2_noise:get2dMap_flat({x=minp.x, y=minp.z}, humidity_2_map)

	--local avg1, avg2, count = 0,0,0

	local index = 0
	local pos = {x=0, y=0, z=0}
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			index = index + 1
			local ivm = area:index(x, maxp.y, z)
			local clear = 0
			local water = 0
			local shadow = false

			heat_1_map[index] = heat_1_map[index] + heat_2_map[index]
			-- river_1 has already been changed to absolute value.
			--avg1 = avg1 + humidity_1_map[index] + humidity_2_map[index]
			--count = count + 1
			humidity_1_map[index] = (humidity_1_map[index] + humidity_2_map[index]) * (2.5 - river_1[index] / 15) / 2
			--avg2 = avg2 + humidity_1_map[index]

			local height = heightmap[index]
			local biome_name = 'deciduous_forest'
			local biome_diff = 1000
			for name, biome in pairs(biomes) do
        local eff = height

        if height > 0 then
          eff = eff + 4
        end

				if biome.y_min <= eff and biome.y_max >= eff then
					local diff = math_abs(biome.heat_point - heat_1_map[index]) + math_abs(biome.humidity_point - humidity_1_map[index])

					if diff < biome_diff then
						biome_name = name
						biome_diff = diff
					end
				end
			end

      local depth_top = biomes[biome_name].depth_top
      local depth_filler = biomes[biome_name].depth_filler

      --if y > 0 then
      --  soil_depth = soil_depth_max / math_ceil(y * 2 / terrain_scale)
      --end

      --if soil_depth < 2 then
      --  soil_depth = math_random(2) - 1
      --end

			for y = maxp.y, minp.y, -1 do
				for deco_non_loop = 1, 1 do
					--if water == 0 and not shadow and clear > 0 and data[ivm] == node['dirt'] then
					if data[ivm] == node['default:sand'] and y <= height and y > height - 2 then
            data[ivm] = node[biomes[biome_name].node_riverbed]
          elseif data[ivm] == node['default:stone'] then
            if y <= height and y > height - depth_top then
              data[ivm] = node[biomes[biome_name].node_top]
            elseif y <= height - depth_top and y > height - depth_top - depth_filler then
              data[ivm] = node[biomes[biome_name].node_filler]
            end
					end

					if water == 0 and not shadow and clear > 0 and y > water_level - 3 and (data[ivm] == node['dirt'] or data[ivm] == node[biomes[biome_name].node_top] or data[ivm] == node['default:cobble']) then
						if biomes[biome_name].special_trees and math_random(biomes[biome_name].special_tree_prob) == 1 then
							local tree_y = y + (string.match(biome_name, '^rainforest') and 0 or 1)
							squaresville.place_schematic(minp, maxp, data, p2data, area, node, {x=x,y=tree_y,z=z}, squaresville.schematics[biomes[biome_name].special_trees[math_random(#biomes[biome_name].special_trees)]], true)
							clear = 0
							shadow = true
						else
							local deco = get_decoration(biome_name)
							if deco then
								data[ivm + area.ystride] = node[deco]
								clear = 0
								shadow = true
							end
						end
					elseif water == 0 and shadow and clear > 0 and data[ivm] == node['dirt'] and (biome_name == 'deciduous_forest' or biome_name == 'coniferous_forest') then
						local r = math_random(20)
						if r <= 4 then
							data[ivm + area.ystride] = node['flowers:mushroom_red']
							clear = 0
						elseif r <= 8 then
							data[ivm + area.ystride] = node['flowers:mushroom_brown']
							clear = 0
						end
					end

					if data[ivm] == node['default:water_source'] then
						clear = clear + 1
						water = water + 1
					elseif data[ivm] == node['air'] then
						clear = clear + 1
					elseif data[ivm] ~= node['ignore'] then
						clear = 0
						shadow = true
					end
				end

				ivm = ivm - area.ystride
			end
		end
	end
	avgt = avgt + avg2/avg1
	countt = countt + 1
end

--minetest.register_on_shutdown(function()
--	print('total change: '..(avgt / countt))
--end)


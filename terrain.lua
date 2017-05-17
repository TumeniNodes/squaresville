-- Squaresville terrain.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local baseline = squaresville.baseline
local extent_bottom = squaresville.extent_bottom
local block_size = squaresville.block_size
local breaker = squaresville.breaker
local city_blocks = 3
local max_depth = 31000
local river_cutoff = 3
local river_scale = 15
local road_size = 7
local suburb_blocks = 2
local terrain_scale = 50
local tree_spacing = 4
local water_level_base = baseline - 2
local water_level_town = baseline - 10
local wild_size = 6

local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random

local attenuation = block_size
local block_plus_road_size = road_size + block_size
local interior_limit = block_plus_road_size * suburb_blocks
local city_limits = interior_limit + (block_plus_road_size * city_blocks)
local city_limits_plus_road_size = city_limits + road_size
local suburb_limits = city_limits + block_plus_road_size * suburb_blocks
local suburb_limits_plus_road_size = suburb_limits + road_size
local csize
local ground_1_map = {}
local ground_1_noise, river_noise
local ground_1_p = {offset = 10, scale = terrain_scale, seed = 4382, spread = {x = 251, y = 251, z = 251}, octaves = 5, persist = 0.6, lacunarity = 2.0}
local half_road_size = math_floor(road_size / 2)
local heat_1_map, heat_2_map, humidity_1_map, humidity_2_map = {}, {}, {}, {}
local heat_1_noise, heat_2_noise, humidity_1_noise, humidity_2_noise
local heat_1_p = {offset = 50, scale = 50, seed = 5349, spread = {x = 1000, y = 1000, z = 1000}, octaves = 3, persist = 0.5, lacunarity = 2}
local heat_2_p = {offset = 0, scale = 1.5, seed = 13, spread = {x = 8, y = 8, z = 8}, octaves = 2, persist = 1.0, lacunarity = 2}
local humidity_1_p = {offset = 50, scale = 50, seed = 842, spread = {x = 1000, y = 1000, z = 1000}, octaves = 3, persist = 0.5, lacunarity = 2}
local humidity_2_p = {offset = 0, scale = 1.5, seed = 90003, spread = {x = 8, y = 8, z = 8}, octaves = 2, persist = 1.0, lacunarity = 2}
local map_max, map_min
local river_map = {}
local river_p = {offset = 0, scale = river_scale, seed = -6819, spread = {x = 451, y = 451, z = 451}, octaves = 3, persist = 1, lacunarity = 2.0}
local river_scale_less_one = river_scale - 0.99
local river_zone = river_scale + river_cutoff - 1
local wild_limits = suburb_limits * wild_size

squaresville.block_plus_road_size = block_plus_road_size
squaresville.block_size = block_size
squaresville.city_limits_plus_road_size = city_limits_plus_road_size
squaresville.interior_limit = interior_limit
squaresville.half_road_size = half_road_size
squaresville.river_p = river_p
squaresville.river_cutoff = river_cutoff
squaresville.road_size = road_size
squaresville.suburb_limits_plus_road_size = suburb_limits_plus_road_size
squaresville.wild_limits = wild_limits

squaresville.decorations = {}

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

squaresville.biomes = {}
local biomes = squaresville.biomes
local biome_names = {}
do
  local biome_mod = {
    cold_desert = { y_min = 1, },
    cold_desert_ocean = { y_min = -max_depth, y_max = 0, },
    coniferous_forest = { y_min = 1, },
    coniferous_forest_ocean = { y_min = -max_depth, y_max = 0, },
    deciduous_forest = {},
    deciduous_forest_ocean = { y_min = -max_depth, },
    deciduous_forest_shore = {},
    desert = { y_min = 1, },
    desert_ocean = { y_min = -max_depth, y_max = 0, },
    --glacier = { y_min = 1, node_water_top = 'squaresville:thin_ice', depth_water_top = 1, },
    glacier = { y_min = 1, depth_water_top = 1, },
    glacier_ocean = { y_min = -max_depth, y_max = 0, },
    grassland = { y_min = 1, },
    grassland_ocean = { y_min = -max_depth, y_max = 0, },
    icesheet = { y_min = 1, },
    icesheet_ocean = { y_min = -max_depth, y_max = 0, },
    rainforest = {},
    rainforest_ocean = { y_min = -max_depth, },
    rainforest_swamp = {},
    sandstone_desert = { y_min = 1, },
    sandstone_desert_ocean = { y_min = -max_depth, y_max = 0, },
    savanna = {},
    savanna_ocean = { y_min = -max_depth, },
    savanna_shore = {},
    snowy_grassland = { y_min = 1, },
    snowy_grassland_ocean = { y_min = -max_depth, y_max = 0, },
    --taiga = { y_min = 1, node_water_top = 'squaresville:thin_ice', depth_water_top = 1, },
    taiga = { y_min = 1, depth_water_top = 1, },
    taiga_ocean = { y_min = -max_depth, y_max = 0, },
    --tundra = { node_river_water = "squaresville:thin_ice", },
    --tundra_beach = { node_river_water = "squaresville:thin_ice", },
    --tundra = { node_top = 'default:snowblock', depth_top = 1,  y_min = 1, node_water_top = 'squaresville:thin_ice', depth_water_top = 1, },
    tundra = { node_top = 'default:snowblock', depth_top = 1,  y_min = 1, depth_water_top = 1, },
    tundra_ocean = { y_min = -max_depth, y_max = 0, },
    underground = {},
  }

  do
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

      biome.special_trees = tree_biomes[biome.name]
      biomes[biome.name] = biome
      biome_names[#biome_names+1] = biome.name

      for n, bi in pairs(biome_mod) do
        for i, rbi in pairs(biomes) do
          if rbi.name == n then
            for j, prop in pairs(bi) do
              biomes[i][j] = prop
            end
          end
        end
      end
    end
  end

  biomes["desertstone_grassland"] = {
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
    y_max = max_depth,
    heat_point = 80,
    humidity_point = 55,
  }

  squaresville.decorations[#squaresville.decorations+1] = {
    deco_type = "simple",
    place_on = {"default:dirt_with_grass"},
    sidelen = 80,
    fill_ratio = 0.1,
    biomes = {"desertstone_grassland", },
    y_min = 1,
    y_max = max_depth,
    decoration = "default:junglegrass",
  }
end


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


local function get_decoration(biome_name)
  for i, deco in pairs(squaresville.decorations) do
    if not deco.biomes or deco.biomes[biome_name] then
      if deco.deco_type == "simple" then
        if deco.fill_ratio and math.random(1000) - 1 < deco.fill_ratio * 1000 then
          return deco.decoration
        end
      end
    end
  end
end


squaresville.terrain = function(minp, maxp, data, p2data, area, node)
  if not (minp and maxp and data and p2data and area and node and type(data) == 'table' and type(p2data) == 'table') then
    return
  end

  if not csize then
    csize = vector.add(vector.subtract(maxp, minp), 1)

    --map_max = {x = csize.x, y = csize.y + 2, z = csize.z}
    --map_min = {x = minp.x, y = minp.y - 1, z = minp.z}

    if not csize then
      return
    end
  end

  if not (ground_1_noise and river_noise) then
    ground_1_noise = minetest.get_perlin_map(ground_1_p, {x=csize.x, y=csize.z})
    river_noise = minetest.get_perlin_map(river_p, {x=csize.x, y=csize.z})

    if not (ground_1_noise and river_noise) then
      return
    end
  end

  ground_1_map = ground_1_noise:get2dMap_flat({x=minp.x, y=minp.z}, ground_1_map)
  river_map = river_noise:get2dMap_flat({x=minp.x, y=minp.z}, river_map)

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
  squaresville.humidity = humidity_1_map

  local tree_map = {}
  for z = minp.z, maxp.z, tree_spacing do
    for x = minp.x, maxp.x, tree_spacing do
      tree_map[ (x + math_random(tree_spacing)) .. ',' .. (z + math_random(tree_spacing)) ] = true
    end
  end

  squaresville.in_town = nil
  squaresville.suburbs = nil

  local index = 0
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      index = index + 1
      local ivm = area:index(x, minp.y - 1, z)
      local road_here = true
      local sidewalk_here = false
      local town = true
      local suburb = true
      local height = 1
      local water_level = water_level_base
      local river = math_abs(river_map[index])
      local heat = heat_1_map[index] + heat_2_map[index]
      local dist_x = (x + max_depth + half_road_size) % wild_limits
      local dist_z = (z + max_depth + half_road_size) % wild_limits
      local dist_block_x = x + max_depth + half_road_size
      local dist_block_z = z + max_depth + half_road_size
      local humidity = (humidity_1_map[index] + humidity_2_map[index]) * (2.5 - (river / river_scale)) / 2
      humidity_1_map[index] = humidity

      if dist_x >= suburb_limits_plus_road_size and dist_z >= suburb_limits_plus_road_size then
        town = false
        suburb = false
        road_here = false
      elseif ((dist_x < interior_limit or dist_z < interior_limit) and not (dist_x < city_limits_plus_road_size and dist_z < city_limits_plus_road_size)) or (dist_x >= city_limits_plus_road_size and dist_z >= city_limits_plus_road_size) then
        if dist_x < suburb_limits_plus_road_size and dist_z < suburb_limits_plus_road_size then
          suburb = false
          road_here = false
        elseif dist_x >= suburb_limits_plus_road_size and dist_block_x % block_plus_road_size >= road_size then
          town = false
          road_here = false
        elseif dist_z >= suburb_limits_plus_road_size and dist_block_z % block_plus_road_size >= road_size then
          town = false
          road_here = false
        else
          town = false
        end
      elseif dist_block_x % block_plus_road_size >= road_size and dist_block_z % block_plus_road_size >= road_size then
        suburb = false
        road_here = false
      end

      if town and not road_here and (dist_block_x % block_plus_road_size < road_size + 2 or dist_block_z % block_plus_road_size < road_size + 2) then
        sidewalk_here = true
      elseif town and ((dist_block_x % block_plus_road_size >= block_plus_road_size - 2 and dist_block_z % block_plus_road_size >= road_size) or (dist_block_z % block_plus_road_size >= block_plus_road_size - 2 and dist_block_x % block_plus_road_size >= road_size)) then
        road_here = false
        sidewalk_here = true
      elseif suburb and not road_here and ((dist_x > dist_z and dist_block_x % block_plus_road_size < road_size + 2) or (dist_z > dist_x and dist_block_z % block_plus_road_size < road_size + 2)) then
        sidewalk_here = true
      elseif suburb and not road_here and ((dist_x > dist_z and dist_block_x % block_plus_road_size >= block_plus_road_size - 2) or (dist_z > dist_x and dist_block_z % block_plus_road_size >= block_plus_road_size - 2)) then
        road_here = false
        sidewalk_here = true
      end

      if town or suburb then
        squaresville.in_town = true
      end

      -- Slope the terrain at the edges of town to let it blend better.
      if not (town or suburb or sidewalk_here) then
        local abs = {x + max_depth, z + max_depth}
        local att = {attenuation, attenuation}

        for i = 1, 2 do
          local xz_off = (abs[i] + half_road_size - suburb_limits) % wild_limits

          if xz_off < attenuation then
            att[i] = xz_off
          else
            xz_off = (abs[i] - road_size + half_road_size + attenuation) % wild_limits
            if xz_off > 0 and xz_off < attenuation then
              att[i] = attenuation - xz_off
            end
          end

          att[i] = att[i] / attenuation
        end

        height = math_floor(ground_1_map[index] * math_min(att[1], att[2]))
      elseif not (road_here or sidewalk_here) then
        -- Slightly alter flat terrain.
        if ground_1_map[index] > terrain_scale / 2 then
          height = height + 1
        elseif ground_1_map[index] < terrain_scale / -2 then
          height = height + 1
        end
      end

      local biome_height = height

      if height > -river_cutoff and river < river_cutoff then
        height = math_floor((river - river_cutoff) * 2)
      elseif town or suburb then
        water_level = water_level_town
      elseif height > (water_level - baseline) and river < river_zone then
        height = math_max((water_level - baseline), math_floor(height * math_max((water_level - baseline), river - river_cutoff) / river_scale_less_one))
        biome_height = height
      end

      heat = heat - 20 * height / terrain_scale

      local biome_name
      local biome_diff = 1000
      for name, biome in pairs(biomes) do
        if (biome.y_min or -31000) <= (biome_height - (water_level_base - baseline)) and (biome.y_max or 31000) >= (biome_height - (water_level_base - baseline)) then
          local diff = math_abs(biome.heat_point - heat) + math_abs(biome.humidity_point - humidity)

          if diff < biome_diff and ((not (town or suburb)) or name == 'grassland' or name == 'snowy_grassland' or name == 'grassland_ocean' or name == 'snowy_grassland_ocean') then
            biome_name = name
            biome_diff = diff
          end
        end
      end

      height = height + baseline

      local fill_1 = height - (biomes[biome_name].depth_top or 0)
      local fill_2 = fill_1 - (biomes[biome_name].depth_filler or 0)
      local water_fill_1 = water_level - (biomes[biome_name].depth_water_top or 0)
      local deco

      for y = minp.y-1, maxp.y+1 do
        if data[ivm] == node['air'] then
          if (town or suburb) and y == baseline + 1 and road_here then
            if squaresville.cobble then
              data[ivm] = node[breaker('squaresville:road', 100 - squaresville.humidity[index] + (y - baseline))]
            else
              data[ivm] = node[breaker('squaresville:road')]
            end
          elseif y == baseline + 1 and sidewalk_here then
            if squaresville.cobble then
              data[ivm] = node[breaker('squaresville:sidewalk', 100 - squaresville.humidity[index] + (y - baseline))]
            else
              data[ivm] = node[breaker('squaresville:sidewalk')]
            end
          elseif river < river_cutoff and y < water_level_base and y <= height and y > height - (biomes[biome_name].depth_riverbed or 0) then
            data[ivm] = node[biomes[biome_name].node_riverbed or 'default:sand']
          elseif y <= height and y > fill_1 then
            data[ivm] = node[biomes[biome_name].node_top or 'default:stone']
            deco = y
          elseif y <= fill_1 and y > fill_2 then
            data[ivm] = node[biomes[biome_name].node_filler or 'default:stone']
          elseif y < height then
            data[ivm] = node[biomes[biome_name].node_stone or 'default:stone']
          elseif river < river_cutoff and y <= water_level then
            data[ivm] = node[biomes[biome_name].node_river_water or 'default:water_source']
          elseif y <= water_level and y > water_fill_1 then
            data[ivm] = node[biomes[biome_name].node_water_top or 'default:water_source']
          elseif y <= water_level then
            data[ivm] = node[biomes[biome_name].node_water or 'default:water_source']
          else
            data[ivm] = node['air']
          end
        end

        ivm = ivm + area.ystride
      end

      if deco then
        if biomes[biome_name].special_trees and tree_map[ x .. ',' .. z ] and (biome_name ~= 'savanna' or math.random(20) == 1) then
          local tree_y = deco + (string.match(biome_name, '^rainforest') and 0 or 1)
          squaresville.place_schematic(minp, maxp, data, p2data, area, node, {x=x,y=tree_y,z=z}, squaresville.schematics[biomes[biome_name].special_trees[math_random(#biomes[biome_name].special_trees)]], true)
        else
          local decoration = get_decoration(biome_name)
          if decoration then
            ivm = area:index(x, deco, z)
            if data[ivm + area.ystride] == node['air'] then
              data[ivm + area.ystride] = node[decoration]
            end
          end
        end
      end
    end
  end
end

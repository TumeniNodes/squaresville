-- Squaresville terrain.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local stone = {}
stone[minetest.get_content_id('default:stone')] = true
stone[minetest.get_content_id('default:sandstone')] = true
stone[minetest.get_content_id('default:desert_stone')] = true
local cave_fill = {}
cave_fill[minetest.get_content_id('air')] = true
cave_fill[minetest.get_content_id('default:water_source')] = true


--minetest.register_ore({
--  ore_type       = "scatter",
--  ore            = "default:meselamp",
--  wherein         = {"default:stone", "default:sandstone"},
--  clust_scarcity = DEBUG and (2 * 2 * 2) or (6 * 6 * 6),
--  clust_num_ores = 1,
--  clust_size     = 1,
--  y_min           = squaresville.baseline + squaresville.extent_bottom,
--  y_max           = squaresville.baseline - 200,
--})

minetest.register_ore({
  ore_type        = "blob",
  ore             = "default:desert_stone",
  wherein         = {"default:stone", "default:sandstone"},
  clust_scarcity  = 14 * 14 * 14,
  clust_size      = 15,
  y_min           = squaresville.baseline + squaresville.extent_bottom,
  y_max           = squaresville.baseline - 200,
  noise_threshold = 0.0,
  noise_params    = {
    offset = 0.2,
    scale = 0.2,
    spread = {x = 15, y = 15, z = 15},
    seed = 8401,
    octaves = 1,
    persist = 0.0
  },
})

minetest.register_ore({
  ore_type        = "blob",
  ore             = "default:sandstone",
  wherein         = {"default:stone", "default:desert_stone"},
  clust_scarcity  = 14 * 14 * 14,
  clust_size      = 15,
  y_min           = squaresville.baseline + squaresville.extent_bottom,
  y_max           = squaresville.baseline - 200,
  noise_threshold = 0.0,
  noise_params    = {
    offset = 0.2,
    scale = 0.2,
    spread = {x = 15, y = 15, z = 15},
    seed = -8771,
    octaves = 1,
    persist = 0.0
  },
})

minetest.register_ore({
  ore_type        = "blob",
  ore             = "default:desert_stone",
  wherein         = {"default:stone", "default:sandstone"},
  clust_scarcity  = 14 * 14 * 14,
  clust_size      = 15,
  y_min           = squaresville.baseline_ruin + squaresville.extent_bottom_ruin,
  y_max           = squaresville.baseline_ruin - 200,
  noise_threshold = 0.0,
  noise_params    = {
    offset = 0.5,
    scale = 0.3,
    spread = {x = 15, y = 15, z = 15},
    seed = 8401,
    octaves = 1,
    persist = 0.0
  },
})

minetest.register_ore({
  ore_type        = "blob",
  ore             = "default:sandstone",
  wherein         = {"default:stone", "default:desert_stone"},
  clust_scarcity  = 14 * 14 * 14,
  clust_size      = 15,
  y_min           = squaresville.baseline_ruin + squaresville.extent_bottom_ruin,
  y_max           = squaresville.baseline_ruin - 200,
  noise_threshold = 0.0,
  noise_params    = {
    offset = 0.5,
    scale = 0.3,
    spread = {x = 15, y = 15, z = 15},
    seed = -8771,
    octaves = 1,
    persist = 0.0
  },
})

local max_depth = 31000

local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random

local csize
local cave_1_map = {}
local cave_1_noise, river_noise
local cave_1_p = {offset = 0, scale = 1, seed = 4382, spread = {x = 41, y = 41, z = 41}, octaves = 3, persist = 1.0, lacunarity = 2.0}
local cave_2_map = {}
local cave_2_noise, river_noise
local cave_2_p = {offset = 0, scale = 1, seed = -6119, spread = {x = 41, y = 41, z = 41}, octaves = 3, persist = 1.0, lacunarity = 2.0}


squaresville.caves = function(minp, maxp, data, p2data, area, node, baseline, heightmap)
  if not (minp and maxp and data and p2data and area and node and type(data) == 'table' and type(p2data) == 'table') then
    return
  end

  local max_height = -31000
  for i = 1, #heightmap do
    if heightmap[i] and heightmap[i] > max_height then
      max_height = heightmap[i]
    end
  end

  if minp.y > math_max(max_height, baseline) then
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

  if not (cave_1_noise and cave_2_noise) then
    cave_1_noise = minetest.get_perlin_map(cave_1_p, {x=csize.x, y=csize.z})
    cave_2_noise = minetest.get_perlin_map(cave_2_p, {x=csize.y + 2, y=csize.z})

    if not (cave_1_noise and cave_2_noise) then
      return
    end
  end

  cave_1_map = cave_1_noise:get2dMap_flat({x=minp.x, y=minp.z}, cave_1_map)
  cave_2_map = cave_2_noise:get2dMap_flat({x=minp.y - 1, y=math.floor(minp.z / csize.z)}, cave_2_map)

  local index1 = 0
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      index1 = index1 + 1
      local ivm = area:index(x, minp.y - 1, z)
      local index2 = 0

      for y = minp.y - 1, maxp.y + 1 do
        index2 = index2 + 1
        if y < (heightmap[index1] or baseline) - 17 then
          if cave_1_map[index1] * cave_2_map[index2] > 0.2 then
            if cave_2_map[index2] > 0 then
              data[ivm] = node['air']
            elseif y % 1000 > math_floor(math_abs(y) / 25) then
              data[ivm] = node['default:water_source']
            else
              data[ivm] = node['default:lava_source']
            end
          elseif cave_2_map[index2] > 0.65 then
            data[ivm] = node['default:sandstone']
          end
        end

        ivm = ivm + area.ystride
      end

      ivm = area:index(x, minp.y - 1, z)
      local glow
      for y = minp.y - 1, maxp.y + 1 do
        if y > maxp.y or (glow and math_random(20) == 1) then
          glow = nil
        elseif not glow and math_random(200) == 1 then
          glow = true
        end

        if y < (heightmap[index1] or baseline) - 17 then
          if stone[data[ivm]] and cave_fill[data[ivm + area.ystride]] and math_random(5) == 1 then
            data[ivm] = node['default:dirt']
            if data[ivm + area.ystride] == node['air'] then
              local sr = math_random(5)
              if sr == 1 then
                data[ivm + area.ystride] = node['flowers:mushroom_brown']
              elseif sr == 2 then
                data[ivm + area.ystride] = node['flowers:mushroom_red']
              end
            elseif math_random(4) == 1 then
              data[ivm + area.ystride] = node['squaresville:wet_fungus']
            end
          elseif stone[data[ivm]] and (cave_fill[data[ivm - 1]] or cave_fill[data[ivm + 1]] or cave_fill[data[ivm - area.zstride]] or cave_fill[data[ivm + area.zstride]] or ((cave_fill[data[ivm - area.ystride]] or cave_fill[data[ivm + area.ystride]]) and math_random(6) == 1)) and glow then
            data[ivm] = node['squaresville:crystal_glow']
          end
        end

        ivm = ivm + area.ystride
      end
    end
  end
end

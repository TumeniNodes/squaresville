local block_size = 60
local city_blocks = 7
local river_cutoff = 3
local river_scale = 15
local road_size = 7
local terrain_scale = 50
local wild_size = 5

local math_abs = math.abs
local math_floor = math.floor
local math_min = math.min
local math_max = math.max

local attenuation = block_size
local block_plus_road_size = road_size + block_size
local city_limits = block_plus_road_size * city_blocks
local city_limits_plus_road_size = (block_plus_road_size * city_blocks) + road_size
local wild_limits = city_limits * wild_size
local csize
local ground_1_map = {}
local ground_1_noise, river_noise
local ground_1_p = {offset = 10, scale = terrain_scale, seed = 4382, spread = {x = 251, y = 251, z = 251}, octaves = 5, persist = 0.6, lacunarity = 2.0}
local half_road_size = math_floor(road_size / 2)
local map_max, map_min
local river_p = {offset = 0, scale = river_scale, seed = -6819, spread = {x = 451, y = 451, z = 451}, octaves = 3, persist = 1, lacunarity = 2.0}
local river_scale_less_one = river_scale - 0.99
local river_zone = river_scale + river_cutoff - 1


squaresville.terrain = function(minp, maxp, data, p2data, area, node, heightmap, river_map)
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

	local index = 0
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			index = index + 1
			local ivm = area:index(x, minp.y - 1, z)
      local road_here = true
      local town = true
      local ground = 1
      local water = 1
      local river = math_abs(river_map[index])
      river_map[index] = river

      if (math_abs(x) + half_road_size) % wild_limits >= city_limits_plus_road_size and (math_abs(z) + half_road_size) % wild_limits >= city_limits_plus_road_size then
        town = false
        road_here = false
      elseif (math_abs(x) + half_road_size) % block_plus_road_size >= road_size and (math_abs(z) + half_road_size) % block_plus_road_size >= road_size then
        road_here = false
      end

      -- Slope the terrain at the edges of town to let it blend better.
      if not town then
        local abs = {math_abs(x), math_abs(z)}
        local att = {attenuation, attenuation}

        for i = 1, 2 do
          local xz_off = (abs[i] + half_road_size - city_limits) % wild_limits

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

        ground = math_floor(ground_1_map[index] * math_min(att[1], att[2]))
      elseif not road_here then
        -- Slightly alter flat terrain.
        if ground_1_map[index] > terrain_scale / 2 then
          ground = ground + 1
        elseif ground_1_map[index] < terrain_scale / -2 then
          ground = ground + 1
        end
      end

      heightmap[index] = ground

      if ground > -river_cutoff and river < river_cutoff then
        ground = math_floor(river - river_cutoff)
      elseif town then
        water = -10
      elseif ground > water and river < river_zone then
        ground = math_floor(ground * math_max(water, river - river_cutoff) / river_scale_less_one)
        heightmap[index] = ground
      end

			for y = minp.y-1, maxp.y+1 do
        if town and y == 1 and road_here then
          data[ivm] = node['squaresville:road']
        elseif river < river_cutoff and y <= ground and y > ground - 2 then
          data[ivm] = node['default:sand']
        elseif y <= ground then
          data[ivm] = node['default:stone']
        elseif y <= water then
          data[ivm] = node['default:water_source']
        else
          data[ivm] = node['air']
        end

				ivm = ivm + area.ystride
			end
		end
	end
end

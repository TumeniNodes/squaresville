local max_river = 4

local baseline = squaresville.baseline
local extent_bottom = squaresville.extent_bottom
local block_plus_road_size = squaresville.block_plus_road_size
local block_size = squaresville.block_size
local breaker = squaresville.breaker
local city_limits_plus_road_size = squaresville.city_limits_plus_road_size
local interior_limit = squaresville.interior_limit
local half_road_size = squaresville.half_road_size
local max_height = 31000
local node = squaresville.node
local suburb_limits_plus_road_size = squaresville.suburb_limits_plus_road_size
local road_size = squaresville.road_size
local wild_limits = squaresville.wild_limits
local river_p = squaresville.river_p
local river_cutoff = squaresville.river_cutoff

local csize
local ruin_map = {}
local ruin_noise
local ruin_p = {offset = 25, scale = 15, seed = 4877, spread = {x = 240, y = 240, z = 240}, octaves = 4, persist = 1, lacunarity = 2.0}

local math_abs = math.abs
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_sin = math.sin

local seed = minetest.get_mapgen_setting('seed')
local seed_int = 0
while seed:len() > 0 do
  seed_int = seed_int + tonumber(seed:sub(1,2))
  seed = seed:sub(3)
end
squaresville.seed_int = seed_int


function b_rand(s)
  local x
  repeat
    x = math_sin(s) * 10000
    x = x - math_floor(x)
    s = s + 1
  until not (x < 0.15 or x > 0.9)
  return (x-0.15) * 1 / 0.75 
end


local hash = ''
local function hash_rand(max)
  if hash:len() < 2 then
    return
  end

  local n = tonumber(hash:sub(1,2))
  --print(hash:sub(1,2))
  --print(hash:sub(3))
  --print('n = '..n)
  hash = hash:sub(3)

  return (n % max) + 1
end


local function crates(data, pos1, pos2)
	local y = math.min(pos2.y, pos1.y)
	for z = pos1.z,pos2.z do
		for x = pos1.x,pos2.x do
			if (data[x][y][z] == node['air'] or data[x][y][z] == nil) and math.random(1000) == 1 then
				data[x][y][z] = node['squaresville:crate']
			end
		end
	end
end


local function lights(write, read, pos1, pos2)
  if not squaresville.light_panels then
    return
  end

	local y = math_max(pos2.y, pos1.y)
	for z = pos1.z,pos2.z do
		for x = pos1.x,pos2.x do
			if (read(x, y, z) == node['air'] or read(x, y, z) == nil) and (read(x,y+1,z) == node['squaresville:floor_ceiling'] or read(x, y+1, z) == node['squaresville:roof']) and (x % 3 == 1 and z % 3 == 1) then
        write(x, y, z, 'squaresville:light_panel', 20) -- 20-23
			end
		end
	end
end


local function roof_box(write, size, off, sy, tex)
	for z = off,size-off+1 do
		for x = off,size-off+1 do
			for y = sy+1,sy+3 do
				if z == off or z == size-off+1 or x == off or x == size-off+1 then
					if y < sy + 3 and x == size - off + 1 and z == math_floor(size / 2) then
						write(x, y, z, 'air')
					else
						write(x, y, z, tex)
					end
				end
			end
			if z > off and z < size-off+1 and x > off and x < size-off+1 then
				write(x, sy+3, z, 'squaresville:roof')
			end
		end
	end
end


local function stairwell(write, pos1, pos2, left)
	local size, px, py, pz
	size = (left and 0 or 2)

	px = math_floor((pos2.x - pos1.x - 4) / 2)
	py = math_min(pos2.y, pos1.y)
	pz = math_floor((pos2.z - pos1.z - 6) / 2)
	local walls = px > 2 and pz > 2

	if walls then
		for z = 1+size,6+size do
			for x = 1,4 do
				for y = 1,3 do
					if z == 1+size or z == 6+size or x == 1 or x == 4 then
						if left and x == 2 and z == 1 and y < 3 then
							write(x + px, y + py, z + pz, 'air')
						elseif not left and x == 3 and z == 6+size and y < 3 then
							write(x + px, y + py, z + pz, 'air')
						else
							write(x + px, y + py, z + pz, 'squaresville:plaster')
						end
					end
				end
			end
		end
	end

	if left then
		for i = 1,4 do
			write(2 + px, i + py, 2 + i + pz, 'squaresville:concrete_stair')
		end
		for i = 1,3 do
			write(2 + px, 4 + py, 2 + i + pz, 'air')
		end
	else
		for i = 1,4 do
			write(3 + px, i + py, 7 - i + pz, 'squaresville:concrete_stair', 4)
		end
		for i = 1,3 do
			write(3 + px, 4 + py, 7 - i + pz, 'air')
		end
	end
end


local function gotham(write, read, size)
	local develop, wall_x, wall_x_2, wall_z, wall_z_2
	local dir, y, floors, conc

	local c = hash_rand(5)
	if c == 1 then
		conc = 'squaresville:concrete'
	else
		conc = 'squaresville:concrete'..c
	end

	local ra = hash_rand(2) - 1
	floors = hash_rand(20) + 1

	-- all this for gargoyles...
	if hash_rand(2) == 1 and floors > 5 then
		for z = -1,size+1 do
			for x = -1,size+1 do
				y = floors * 4
				y = y - (y % 4)
				if (x == -1 or x == size + 1) and z % 5 == 3 and z > -1 then
					dir = (x == -1 and 18 or 12)
					write(x, y, z, 'squaresville:gargoyle', dir)
				elseif (z == -1 or z == size + 1) and x % 5 == 3 and x > -1 then
					dir = (z == -1 and 9 or 7)
					write(x, y, z, 'squaresville:gargoyle', dir)
				end
			end
		end
	end

	for z = 0,size do
		for x = 0,size do
			develop = x > 0 and x < size and z > 0 and z < size
			wall_x = x == 0 or x == size
			wall_z = z == 0 or z == size
			wall_x_2 = x == 1 or x == size - 1
			wall_z_2 = z == 1 or z == size - 1
			for y = 0,(floors * 4) do
				if y % 4 == 0 and x > 1 and z > 1 and x < size - 1 and z < size - 1 then
					if floors * 4 - y < 4 then
						write(x, y, z, 'squaresville:roof')
					else
						write(x, y, z, 'squaresville:floor_ceiling')
					end
				elseif wall_x then
					if y == 0 then
						write(x, y, z, conc)
					elseif z % 5 == 3 then
						write(x, y, z, conc)
					else
						write(x, y, z, 'air')
					end
				elseif wall_x_2 and develop then
					if y == 0 then
						write(x, y, z, conc)
					elseif z % 12 == 2 and y <= 2 and y > 0 then
						write(x, y, z, 'air')
					elseif y % 4 ~= 2 or z % 5 == 3 then
						write(x, y, z, conc)
					else
						write(x, y, z, 'squaresville:plate_glass')
					end
				elseif wall_z then
					if y == 0 then
						write(x, y, z, conc)
					elseif x % 5 == 3 then
						write(x, y, z, conc)
					else
						write(x, y, z, 'air')
					end
				elseif wall_z_2 and develop then
					if y == 0 then
						write(x, y, z, conc)
					elseif x % 12 == 2 and y <= 2 and y > 0 then
						write(x, y, z, 'air')
					elseif y % 4 ~= 2 or x % 5 == 3 then
						write(x, y, z, conc)
					else
						write(x, y, z, 'squaresville:plate_glass')
					end
				else
					write(x, y, z, 'air')
				end
			end
		end
	end

	for f = 1,floors-ra do
		stairwell(write, {x=2,y=((f-1)*4),z=2}, {x=size-1,y=(f*4-1),z=size-1}, (f / 2 == math_floor(f / 2)))
		lights(write, read, {x=3,y=((f-1)*4),z=3}, {x=size-2,y=(f*4-1),z=size-2})
		--crates(data, {x=3,y=((f-1)*4+1),z=3}, {x=size-2,y=((f-1)*4+1),z=size-2})
	end

	if ra == 0 then
		roof_box(write, size, 15, floors * 4, conc)
	end
end


local function glass_and_steel(write, read, size)
	local develop, wall_x, wall_z, floors, conc
	local c = hash_rand(5)
	if c == 1 then
		conc = 'squaresville:concrete'
	else
		conc = 'squaresville:concrete'..c
	end

	local ra = hash_rand(2) - 1
	floors = hash_rand(50) + 1

	for z = 0,size do
		for x = 0,size do
			wall_x = x == 0 or x == size
			wall_z = z == 0 or z == size
			for y = 0,(floors * 4) do
				if y % 4 == 0 and x > 0 and z > 0 and x < size and z < size then
					if floors * 4 - y < 4 then
						write(x, y, z, 'squaresville:roof')
					else
						write(x, y, z, 'squaresville:floor_ceiling')
					end
				elseif wall_x then
					if (z - 2) % 5 == 2 then
						write(x, y, z, conc)
					elseif y == 0 then
						write(x, y, z, conc)
					elseif z == 6 and y <= 2 then
						write(x, y, z, 'air')
					else
						write(x, y, z, 'squaresville:plate_glass')
					end
				elseif wall_z then
					if (x - 2) % 5 == 2 then
						write(x, y, z, conc)
					elseif y == 0 then
						write(x, y, z, conc)
					elseif x == 6 and y <= 2 then
						write(x, y, z, 'air')
					else
						write(x, y, z, 'squaresville:plate_glass')
					end
				end
			end
		end
	end

	for f = 1,floors-ra do
		stairwell(write, {x=1,y=((f-1)*4),z=1}, {x=size,y=(f*4-1),z=size}, (f / 2 == math_floor(f / 2)))
		lights(write, read, {x=1,y=((f-1)*4),z=1}, {x=size,y=(f*4-1),z=size})
		--crates(data, {x=1,y=((f-1)*4+1),z=1}, {x=size,y=((f-1)*4+1),z=size})
	end

	if ra == 0 then
		roof_box(write, size, 15, floors * 4, conc)
	end
end


local function simple(write, read, size, slit)
	local develop, wall_x, wall_z, floors, conc, c

	local ra = hash_rand(2) - 1
	floors = hash_rand(10) + 1

	if floors < 6 then
		c = hash_rand(9)
	else
		c = hash_rand(5)
	end

	if c == 1 then
		conc = 'squaresville:concrete'
	elseif c == 6 then
		conc = 'default:brick'
	elseif c == 7 then
		conc = 'default:sandstonebrick'
	elseif c == 8 then
		conc = 'default:stonebrick'
	elseif c == 9 then
		conc = 'default:desert_stonebrick'
	else
		conc = 'squaresville:concrete'..c
	end

	for z = 0,size do
		for x = 0,size do
			wall_x = x == 0 or x == size
			wall_z = z == 0 or z == size
			for y = 0,(floors * 4) do
				if y % 4 == 0 and x > 0 and z > 0 and x < size and z < size then
					if floors * 4 == y then
						write(x, y, z, 'squaresville:roof')
					else
						write(x, y, z, 'squaresville:floor_ceiling')
					end
				elseif wall_x then
					if z == 6 and y <= 2 and y > 0 then
						write(x, y, z, 'air')
					elseif slit and z % 2 == 0 and y % 4 > 1 then
						write(x, y, z, 'squaresville:plate_glass')
					elseif not slit and math_floor(z / 2) % 2 == 1 and y % 4 > 1 then
						write(x, y, z, 'squaresville:plate_glass')
					else
						write(x, y, z, conc)
					end
				elseif wall_z then
					if x == 6 and y <= 2 and y > 0 then
						write(x, y, z, 'air')
					elseif slit and x % 2 == 0 and y % 4 > 1 then
						write(x, y, z, 'squaresville:plate_glass')
					elseif not slit and math_floor(x / 2) % 2 == 1 and y % 4 > 1 then
						write(x, y, z, 'squaresville:plate_glass')
					else
						write(x, y, z, conc)
					end
				end
			end
		end
	end

	for f = 1,floors-ra do
		stairwell(write, {x=1,y=((f-1)*4),z=1}, {x=size,y=(f*4-1),z=size}, (f / 2 == math_floor(f / 2)))
		lights(write, read, {x=1,y=((f-1)*4),z=1}, {x=size,y=(f*4-1),z=size})
		--crates(data, {x=1,y=((f-1)*4+1),z=1}, {x=size,y=((f-1)*4+1),z=size})
	end

	if ra == 0 then
		roof_box(write, size, 15, floors * 4, conc)
	end
end


local function shacks(write, read, size, slit)
	local develop, wall_x, wall_z, floors, conc, c

	local ra = hash_rand(2) - 1
  local yard = 28
  local space = 6
  local floors = 2
  local plot = math_floor((size - 4) / yard)

	for pz = 0, plot do
		for px = 0, plot do
      for z = 0, yard do
        for x = 0, yard do
          write(x + px * yard, 0, z + pz * yard, 'default:dirt_with_grass')
        end
      end

      for z = space, yard - space do
        for x = space, yard - space do
          wall_x = x == space or x == yard - space
          wall_z = z == space or z == yard - space
          for y = 0,(floors * 4) do
            if y % 4 == 0 and x > space and z > space and x < yard - space and z < yard - space then
              if floors * 4 == y then
                write(x + px * yard, y, z + pz * yard, 'default:wood')
              else
                write(x + px * yard, y, z + pz * yard, 'default:wood')
              end
            elseif wall_x then
              write(x + px * yard, y, z + pz * yard, 'default:wood')
            elseif wall_z then
              write(x + px * yard, y, z + pz * yard, 'default:wood')
            end
          end
        end
			end
		end
	end
end


-- This is probably a bad idea...
local function simple_tree(data, px, pz)
	local r
	local h = math.random(4,6)
	for y = 1,h do
		data[px][y][pz] = node('default:tree')
	end
	for z = -2,2 do
		for y = -2,2 do
			for x = -2,2 do
				r = math.sqrt(x ^ 2 + y ^ 2 + z ^ 2)
				if data[x + px][y + h][z + pz] ~= node('default:tree') and math.random(4,6) > r * 2 then
					data[x + px][y + h][z + pz] = node('default:leaves')
				end
			end
		end
	end
end

local function park(data, param, dx, dy, dz)
	local sr

	for z = 1,dz do
		for x = 1,dx do
			data[x][0][z] = node('default:dirt_with_grass')
			if squaresville.desolation > 0 then
				sr = math.random(14)
				if sr < 6 then
					data[x][1][z] = node('default:grass_'..sr)
				elseif sr == 6 then
					data[x][1][z] = node('default:dry_shrub')
				end
			end
		end
	end

	for qz = 1,math_floor(dz / 5) do
		for qx = 1,math_floor(dx / 5) do
			sr = math.random(5)
			if sr == 1 then
				simple_tree(data, qx * 5 - 2, qz * 5 - 2)
			elseif sr == 2 then
				data[qx * 5 - 2][1][qz * 5 - 2] = node('squaresville:park_bench')
				pstore(param, qx * 5 - 2, 1, qz * 5 - 2, math.random(4) - 1)
			elseif sr == 3 then
				data[qx * 5 - 2][1][qz * 5 - 2] = node('squaresville:swing_set')
				pstore(param, qx * 5 - 2, 1, qz * 5 - 2, math.random(4) - 1)
			else
				sr = math.random(30)
				if sr == 1 then
					data[qx * 5 - 2][1][qz * 5 - 2] = node('squaresville:doll')
					pstore(param, qx * 5 - 2, 1, qz * 5 - 2, math.random(4) - 1)
				end
			end
		end
	end
end


function squaresville.build(minp, maxp, data, p2data, area, node)
  local size = block_size - road_size + 2

	if not csize then
		csize = vector.add(vector.subtract(maxp, minp), 1)
	end

  if not ruin_noise then
    ruin_noise = minetest.get_perlin_map(ruin_p, {x=csize.x, y=csize.z})
    if not ruin_noise then
      return
    end
  end
  
  ruin_map = ruin_noise:get2dMap_flat({x=minp.x, y=minp.z})

  for bz = minp.z - 2 * block_size + 1, maxp.z + block_size - 1 do
    for bx = minp.x - 2 * block_size + 1, maxp.x + block_size - 1 do
      for non_loop = 1, 1 do
        local dist_x = (bx + max_height + half_road_size) % wild_limits
        local dist_z = (bz + max_height + half_road_size) % wild_limits

        local town = true
        local suburb = true

        if (bx + max_height + half_road_size) % block_plus_road_size ~= road_size + 2 or (bz + max_height + half_road_size) % block_plus_road_size ~= road_size + 2 then
          break
        end

        if dist_x >= suburb_limits_plus_road_size and dist_z >= suburb_limits_plus_road_size then
          break
        elseif ((dist_x < interior_limit or dist_z < interior_limit) and not (dist_x < city_limits_plus_road_size and dist_z < city_limits_plus_road_size)) or (dist_x >= city_limits_plus_road_size and dist_z >= city_limits_plus_road_size) then
          if dist_x < suburb_limits_plus_road_size and dist_z < suburb_limits_plus_road_size then
            suburb = false
          elseif dist_x >= suburb_limits_plus_road_size and (bx + max_height + half_road_size) % block_plus_road_size >= road_size then
            town = false
          elseif dist_z >= suburb_limits_plus_road_size and (bz + max_height + half_road_size) % block_plus_road_size >= road_size then
            town = false
          else
            town = false
          end
        elseif (bx + max_height + half_road_size) % block_plus_road_size >= road_size and (bz + max_height + half_road_size) % block_plus_road_size >= road_size then
          suburb = false
        end

        if not (suburb or town) then
          print('error')
        end

        -- Don't use bx, bz from this point.
        local pos = {x=bx, y=baseline + 1, z=bz}

        hash = string.format('%20.19f', b_rand(minetest.hash_node_position(pos) + seed_int))
        hash = hash:sub(3)

        -- This function burns lots of CPU time in order to save the
        -- memory that would be necessary when using buffers.
        local write = function(rx, ry, rz, node_name, p2)
          local x = pos.x + rx
          local y = pos.y + ry
          local z = pos.z + rz

          if x >= minp.x and x <= maxp.x and y >= minp.y and y <= maxp.y and z >= minp.z and z <= maxp.z and (squaresville.desolation == 0 or y <= baseline + ruin_map[((z - minp.z) * csize.x + (x - minp.x) + 1)]) then
            local ivm = area:index(x, y, z)
            if squaresville.cobble then
              local h_i = (z - minp.z) * csize.x + (x - minp.x) + 1
              data[ivm] = node[breaker(node_name, 100 - squaresville.humidity[h_i] + (y - baseline))]
            else
              data[ivm] = node[breaker(node_name)]
            end
            p2data[ivm] = p2
          end
        end

        local read = function(rx, ry, rz)
          local x = pos.x + rx
          local y = pos.y + ry
          local z = pos.z + rz

          if x >= minp.x and x <= maxp.x and y >= minp.y and y <= maxp.y and z >= minp.z and z <= maxp.z then
            local ivm = area:index(x, y, z)
            return data[ivm]
          end
        end

        local function clear(miny, maxy)
          for z = pos.z - 2, pos.z + size + 2 do
            for x = pos.x - 2, pos.x + size + 2 do
              for y = miny, maxy do
                write(x - pos.x, y, z - pos.z, 'air')
              end
            end
          end
        end

        local river = 0

        for rz = pos.z, pos.z + size, 5 do
          for rx = pos.x, pos.x + size, 5 do
            local river_n = math_abs(minetest.get_perlin(river_p):get2d({x=rx, y=rz}))
            if river_n < river_cutoff then
              river = river + 1

              if river > max_river then
                break
              end
            end
          end

          if river > max_river then
            break
          end
        end

        if river > max_river then
          -- nop
        elseif town then
          local sr = hash_rand(13)
          if sr <= 3 then
            clear(1, 5)
            gotham(write, read, size)
          elseif sr <= 6 then
            clear(1, 5)
            glass_and_steel(write, read, size)
          elseif sr <= 9 then
            clear(1, 5)
            simple(write, read, size)
          elseif sr <= 12 then
            clear(1, 5)
            simple(write, read, size, true)
          else
            --park(write, dx, dy, dz)
          end
        elseif suburb then
          local sr = hash_rand(13)
          if sr <= 13 then
            clear(1, 5)
            shacks(write, read, size, true)
          end
        end
      end
    end
  end
end

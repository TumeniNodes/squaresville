local block_plus_road_size = squaresville.block_plus_road_size
local block_size = squaresville.block_size
local breaker = squaresville.breaker
local city_limits_plus_road_size = squaresville.city_limits_plus_road_size
local half_road_size = squaresville.half_road_size
local road_size = squaresville.road_size
local wild_limits = squaresville.wild_limits

local math_abs = math.abs


function b_rand(s)
  local x
  repeat
    x = math.sin(s) * 10000
    x = x - math.floor(x)
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
			if (data[x][y][z] == node('air') or data[x][y][z] == nil) and math.random(1000) == 1 then
				data[x][y][z] = node('squaresville:crate')
			end
		end
	end
end


local function lights(data, param, pos1, pos2)
	local y = math.max(pos2.y, pos1.y)
	for z = pos1.z,pos2.z do
		for x = pos1.x,pos2.x do
			if (data[x][y][z] == node('air') or data[x][y][z] == nil) and (data[x][y+1][z] == node('squaresville:floor_ceiling') or data[x][y+1][z] == node('squaresville:roof')) and math.random(20) == 1 then
				if squaresville.desolation > 0 then
					data[x][y][z] = node('squaresville:light_panel_broken')
				else
					data[x][y][z] = node('squaresville:light_panel')
				end
				pstore(param, x, y, z, 20) -- 20-23
			end
		end
	end
end


local function roof_box(data, off, sy, dx, dz, tex)
	for z = off,dz-off+1 do
		for x = off,dx-off+1 do
			for y = sy+1,sy+3 do
				if z == off or z == dz-off+1 or x == off or x == dx-off+1 then
					if y < sy + 3 and x == dx - off + 1 and z == math.floor(dz / 2) then
						data[x][y][z] = node('air')
					else
						data[x][y][z] = node(breaker(tex))
					end
				end
			end
			if z > off and z < dz-off+1 and x > off and x < dx-off+1 then
				data[x][sy+3][z] = node(breaker('squaresville:roof'))
			end
		end
	end
end


local function stairwell(data, param, pos1, pos2, left)
	local dz, px, py, pz
	dz = (left and 0 or 2)

	px = math.floor((pos2.x - pos1.x - 4) / 2)
	py = math.min(pos2.y, pos1.y)
	pz = math.floor((pos2.z - pos1.z - 6) / 2)
	local walls = px > 2 and pz > 2

	if walls then
		for z = 1+dz,6+dz do
			for x = 1,4 do
				for y = 1,3 do
					if z == 1+dz or z == 6+dz or x == 1 or x == 4 then
						if left and x == 2 and z == 1 and y < 3 then
							data[x + px][y + py][z + pz] = node('air')
						elseif not left and x == 3 and z == 6+dz and y < 3 then
							data[x + px][y + py][z + pz] = node('air')
						else
							data[x + px][y + py][z + pz] = node(breaker('squaresville:plaster'))
						end
					end
				end
			end
		end
	end

	if left then
		for i = 1,4 do
			data[2 + px][i + py][2 + i + pz] = node('squaresville:concrete_stair')
		end
		for i = 1,3 do
			data[2 + px][4 + py][2 + i + pz] = node('air')
		end
	else
		for i = 1,4 do
			data[3 + px][i + py][7 - i + pz] = node('squaresville:concrete_stair')
			pstore(param, 3+px, i+py, 7-i+pz, 4)
		end
		for i = 1,3 do
			data[3 + px][4 + py][7 - i + pz] = node('air')
		end
	end
end


local function gotham(write, size)
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
		for z = 0,size+1 do
			for x = 0,size+1 do
				y = floors * 4
				y = y - (y % 4)
				if (x == 0 or x == size + 1) and z % 5 == 4 then
					dir = (x == 0 and 18 or 12)
					write(x, y, z, 'squaresville:gargoyle', dir)
				elseif (z == 0 or z == size + 1) and x % 5 == 4 then
					dir = (z == 0 and 9 or 7)
					write(x, y, z, 'squaresville:gargoyle', dir)
				end
			end
		end
	end

	for z = 1,size do
		for x = 1,size do
			develop = x > 1 and x < size and z > 1 and z < size
			wall_x = x == 1 or x == size
			wall_z = z == 1 or z == size
			wall_x_2 = x == 2 or x == size - 1
			wall_z_2 = z == 2 or z == size - 1
			for y = 0,(floors * 4) do
				if y % 4 == 0 and x > 2 and z > 2 and x < size - 1 and z < size - 1 then
					if floors * 4 - y < 4 then
						write(x, y, z, 'squaresville:roof')
					else
						write(x, y, z, 'squaresville:floor_ceiling')
					end
				elseif wall_x then
					if y == 0 then
						write(x, y, z, conc)
					elseif z % 5 == 4 then
						write(x, y, z, conc)
					else
						write(x, y, z, 'air')
					end
				elseif wall_x_2 and develop then
					if y == 0 then
						write(x, y, z, conc)
					elseif z % 12 == 3 and y <= 2 and y > 0 then
						write(x, y, z, 'air')
					elseif y % 4 ~= 2 or z % 5 == 4 then
						write(x, y, z, conc)
					else
						write(x, y, z, 'squaresville:plate_glass')
					end
				elseif wall_z then
					if y == 0 then
						write(x, y, z, conc)
					elseif x % 5 == 4 then
						write(x, y, z, conc)
					else
						write(x, y, z, 'air')
					end
				elseif wall_z_2 and develop then
					if y == 0 then
						write(x, y, z, conc)
					elseif x % 12 == 3 and y <= 2 and y > 0 then
						write(x, y, z, 'air')
					elseif y % 4 ~= 2 or x % 5 == 4 then
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
		--stairwell(data, param, {x=2,y=((f-1)*4),z=2}, {x=size-1,y=(f*4-1),z=size-1}, (f / 2 == math.floor(f / 2)))
		--lights(data, param, {x=3,y=((f-1)*4),z=3}, {x=size-2,y=(f*4-1),z=size-2})
		--crates(data, {x=3,y=((f-1)*4+1),z=3}, {x=size-2,y=((f-1)*4+1),z=size-2})
	end

	if ra == 0 then
		--roof_box(data, 10, floors * 4, size, size, conc)
	end
end


local function glass_and_steel(write, size)
	local develop, wall_x, wall_z, floors, conc
	local c = hash_rand(5)
	if c == 1 then
		conc = 'squaresville:concrete'
	else
		conc = 'squaresville:concrete'..c
	end

	local ra = hash_rand(2) - 1
	floors = hash_rand(20) + 1

	for z = 1,size do
		for x = 1,size do
			wall_x = x == 1 or x == size
			wall_z = z == 1 or z == size
			for y = 0,(floors * 4) do
				if y % 4 == 0 and x > 1 and z > 1 and x < size and z < size then
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
		--stairwell(data, param, {x=1,y=((f-1)*4),z=1}, {x=dx,y=(f*4-1),z=dz}, (f / 2 == math.floor(f / 2)))
		--lights(data, param, {x=1,y=((f-1)*4),z=1}, {x=dx,y=(f*4-1),z=dz})
		--crates(data, {x=1,y=((f-1)*4+1),z=1}, {x=dx,y=((f-1)*4+1),z=dz})
	end

	if ra == 0 then
		--roof_box(data, 10, floors * 4, dx, dz, conc)
	end
end


local function simple(write, size, slit)
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
					elseif not slit and math.floor(z / 2) % 2 == 1 and y % 4 > 1 then
						write(x, y, z, 'squaresville:plate_glass')
					else
						write(x, y, z, conc)
					end
				elseif wall_z then
					if x == 6 and y <= 2 and y > 0 then
						write(x, y, z, 'air')
					elseif slit and x % 2 == 0 and y % 4 > 1 then
						write(x, y, z, 'squaresville:plate_glass')
					elseif not slit and math.floor(x / 2) % 2 == 1 and y % 4 > 1 then
						write(x, y, z, 'squaresville:plate_glass')
					else
						write(x, y, z, conc)
					end
				end
			end
		end
	end

  if true then
    return
  end

	for f = 1,floors-ra do
		stairwell(data, param, {x=1,y=((f-1)*4),z=1}, {x=size,y=(f*4-1),z=size}, (f / 2 == math.floor(f / 2)))
		lights(data, param, {x=1,y=((f-1)*4),z=1}, {x=size,y=(f*4-1),z=size})
		crates(data, {x=1,y=((f-1)*4+1),z=1}, {x=size,y=((f-1)*4+1),z=size})
	end

	if ra == 0 then
		roof_box(data, 10, floors * 4, size, size, conc)
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

	for qz = 1,math.floor(dz / 5) do
		for qx = 1,math.floor(dx / 5) do
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


function squaresville.build(minp, maxp, data, p2data, area, node, heightmap)
  local size = block_size - road_size + 2

  for bz = minp.z - 2 * block_size + 1, maxp.z + block_size - 1 do
    for bx = minp.x - 2 * block_size + 1, maxp.x + block_size - 1 do
      for non_loop = 1, 1 do
        if (math_abs(bx) + half_road_size) % wild_limits >= city_limits_plus_road_size and (math_abs(bz) + half_road_size) % wild_limits >= city_limits_plus_road_size then
          break
        elseif (math_abs(bx) + half_road_size) % block_plus_road_size == road_size + 2 and (math_abs(bz) + half_road_size) % block_plus_road_size == road_size + 2 then
          -- nop
        else
          break
        end

        -- Don't use bx, bz from this point.
        local pos = {x=bx, y=1, z=bz}

        if pos.x < 0 then
          pos.x = pos.x - block_size + road_size - 2
        end

        if pos.z < 0 then
          pos.z = pos.z - block_size + road_size - 2
        end

        hash = string.format('%20.19f', b_rand(minetest.hash_node_position(pos)))
        hash = hash:sub(3)

        -- This function burns lots of CPU time in order to save the
        -- memory that would be necessary when using buffers.
        local write = function(rx, ry, rz, node_name, p2)
          local x = pos.x + rx
          local y = pos.y + ry
          local z = pos.z + rz

          if x >= minp.x and x <= maxp.x and y >= minp.y and y <= maxp.y and z >= minp.z and z <= maxp.z then
            local ivm = area:index(x, y, z)
            data[ivm] = node[breaker(node_name)]
            p2data[ivm] = p2
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

        for z = pos.z - 2, pos.z + size + 2 do
          for x = pos.x - 2, pos.x + size + 2 do
            write(x - pos.x, 0, z - pos.z, 'squaresville:sidewalk')
          end
        end

        local sr = hash_rand(13)
        if sr <= 3 then
          clear(1, 5)
          gotham(write, size)
        elseif sr <= 6 then
          clear(1, 5)
          glass_and_steel(write, size)
        elseif sr <= 9 then
          clear(1, 5)
          simple(write, size)
        elseif sr <= 12 then
          clear(1, 5)
          simple(write, size, true)
        else
          --park(write, dx, dy, dz)
        end
      end
    end
  end
end

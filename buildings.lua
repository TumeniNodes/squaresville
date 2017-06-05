-- Squaresville buildings.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local max_river = 4

local biomes = squaresville.biomes
local block_plus_road_size = squaresville.block_plus_road_size
local block_size = squaresville.block_size
local breaker = squaresville.breaker
local city_limits_plus_road_size = squaresville.city_limits_plus_road_size
local cobble = squaresville.cobble
local desolation = squaresville.desolation
local get_biome = squaresville.get_biome
local get_decoration = squaresville.get_decoration
local ground_nodes = squaresville.ground_nodes
local half_road_size = squaresville.half_road_size
local humidity_1_map = squaresville.humidity_1_map
local interior_limit = squaresville.interior_limit
local max_height = 31000
local node = squaresville.node
local place_schematic = squaresville.place_schematic
local river_cutoff = squaresville.river_cutoff
local river_p = squaresville.river_p
local road_size = squaresville.road_size
local schematics = squaresville.schematics
local suburb_limits_plus_road_size = squaresville.suburb_limits_plus_road_size
local town_tree_thinning = 5
local tree_map = squaresville.tree_map
local wild_limits = squaresville.wild_limits

local csize
local ruin_map = {}
local ruin_noise
local ruin_p = {offset = 25, scale = 15, seed = 4877, spread = {x = 240, y = 240, z = 240}, octaves = 4, persist = 1, lacunarity = 2.0}

local math_abs = math.abs
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random
local math_sin = math.sin

local seed = minetest.get_mapgen_setting('seed')
local seed_int = 0
while seed:len() > 0 do
  seed_int = seed_int + tonumber(seed:sub(1,2))
  seed = seed:sub(3)
end
squaresville.seed_int = seed_int


local drotn = {[0]=3, 0, 1, 2, 16, 17, 18, 19, 12, 13, 14, 15, 4, 5, 6, 7, 8, 9, 10, 11, 23, 20, 21, 22}
local drotp = {}
for i = 0, 23 do
  for j = 0, 23 do
    if drotn[j] == i then
      drotp[i] = j
      break
    end
  end
end
-- 7, 19, 11, 15
-- 9, 13, 5, 17
-- 15, 11
-- 17, 5
--print(dump(drotp))
--local drotp = {[0]=1, 2, 3, 0, 12, 13, 14, 15, 16, 17, 18, 19, 8, 9, 10, 11, 4, 5, 6, 7, 21, 22, 23, 20}


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
  hash = hash:sub(3)

  return (n % max) + 1
end


local unbroken = true
local unbreak_this = "house_with_pool"
local house_schematics = {}
for _, filename in pairs(minetest.get_dir_list(squaresville.path.."/schematics/")) do
  if string.find(filename, "^[%a%d_]+%.house$") then
    local file = io.open(squaresville.path.."/schematics/"..filename, "rb")
    if file then
      local data = file:read("*all")
      file:close()
      local new_data = minetest.deserialize(data)
      house_schematics[#house_schematics+1] = new_data
      print("Squaresville: loaded "..filename)
      if not unbroken and string.find(filename, unbreak_this) then
        local new_data = data
        new_data = minetest.deserialize(new_data)
        for _, i in pairs(new_data.data) do
          i.name = string.gsub(i.name, "_broken", "")
          if string.find(i.name, "default:dry_shrub") then
            i.name = "air"
            i.prob = 0
          end
          if string.find(i.name, "default:grass") then
            i.name = "air"
            i.prob = 0
          end
        end
        new_data = minetest.serialize(new_data)
        house_schematics[#house_schematics] = new_data

        filename = minetest.get_worldpath().."/"..unbreak_this..".house"
        local file = io.open(filename, "wb")
        if file then
          file:write(new_data)
          file:close()
        end
        unbroken = true
      end
    end
  end
end
squaresville.house_schematics = house_schematics

minetest.register_privilege('saveplot', {description = 'Allow user to save squaresville plots.'})
minetest.register_chatcommand("saveplot", {
  params = "[filename]",
  description = "save the plot you're in as a schematic file",
  privs = {saveplot=true}, -- Require the "saveplot" privilege to run
  func = function(name, param)
    local filename = param
    if not filename or filename == "" or string.find(filename, "[^%a%d_]") then
      print("* Squaresville: Specify a simple filename containing digits and letters. The suffix will be added automatically. Paths are not allowed.")
      return
    end

    filename = minetest.get_worldpath().."/"..filename..".house"
    local pos = minetest.get_player_by_name(name):getpos()

    local dist_x = math_floor(pos.x + max_height + half_road_size) % wild_limits
    local dist_z = math_floor(pos.z + max_height + half_road_size) % wild_limits

    local suburb = true
    local suburb_orient = 0
    local max_schem_height = 10
    local size = math.floor(block_size / 2)

    local p1, p2 = {}, {}
    local px, pz = 0, 0
    p1.x = math.floor((pos.x + max_height + half_road_size) / block_plus_road_size) * block_plus_road_size - max_height - half_road_size + road_size + 0
    if pos.x - p1.x >= size then
      p1.x = p1.x + size
      px = 1
    end
    if pos.y >= squaresville.baseline and pos.y <= squaresville.baseline + max_schem_height then
      p1.y = squaresville.baseline
    elseif pos.y >= squaresville.baseline_ruin and pos.y <= squaresville.baseline_ruin + max_schem_height then
      p1.y = squaresville.baseline_ruin
    end
    p1.z = math.floor((pos.z + max_height + half_road_size) / block_plus_road_size) * block_plus_road_size - max_height - half_road_size + road_size + 0
    if pos.z - p1.z >= size then
      p1.z = p1.z + size
      pz = 1
    end
    p2.x = p1.x + size - 1
    p2.y = p1.y + max_schem_height
    p2.z = p1.z + size - 1

    if dist_x >= suburb_limits_plus_road_size and dist_z >= suburb_limits_plus_road_size then
      suburb = false
    elseif ((dist_x < interior_limit or dist_z < interior_limit) and not (dist_x < city_limits_plus_road_size and dist_z < city_limits_plus_road_size)) or (dist_x >= city_limits_plus_road_size and dist_z >= city_limits_plus_road_size) then
      if dist_x < suburb_limits_plus_road_size and dist_z < suburb_limits_plus_road_size then
        suburb = false
      elseif dist_x >= suburb_limits_plus_road_size and (p1.x + max_height + half_road_size) % block_plus_road_size >= road_size then
        suburb_orient = 1
      end
    elseif (p1.x + max_height + half_road_size) % block_plus_road_size >= road_size and (p1.z + max_height + half_road_size) % block_plus_road_size >= road_size then
      suburb = false
    end

    if not suburb then
      print("* Squaresville cannot determine coordinates for plotsave.")
      return
    end

    local rot
    if suburb_orient == 0 then
      if pz == 0 then
        rot = 0
      else
        rot = 2
      end
    else
      if px == 0 then
        rot = 1
      else
        rot = 3
      end
    end
    print('rotation: '..rot)

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(p1, p2)
    local data = vm:get_data()
    local p2data = vm:get_param2_data()
    local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    local y2
    if param ~= 'prep' then
      for y = emax.y, emin.y, -1 do
        for z = p1.z, p2.z do
          local ivm = a:index(p1.x, y, z)
          for x = p1.x, p2.x do
            if not y2 and data[ivm] ~= squaresville.node["air"] and data[ivm] ~= squaresville.node["ignore"] then
              y2 = y
            end

            ivm = ivm + 1
          end
        end
      end
    end

    if y2 or param == 'prep' then
      if param ~= 'prep' then
        p2.y = y2
      end
      local height = p2.y - p1.y + 1

      local schem = {size=vector.add(vector.subtract(p2, p1), 1)}
      schem.data = {}
      for z1 = 0, size - 1 do
        for x1 = 0, size - 1 do
          local x, z
          if rot == 0 then
            x, z = x1, z1
          elseif rot == 1 then
            x, z = z1, size - x1 - 1
          elseif rot == 2 then
            x, z = size - x1 - 1, size - z1 - 1
          elseif rot == 3 then
            x, z = size - z1 - 1, x1
          end

          local isch = z1 * height * size + x1 + 1
          local ivm = a:index(p1.x + x, p1.y, p1.z + z)
          for y = p1.y, p2.y do
            if param == 'prep' then
              if y == p1.y then
                data[ivm] = squaresville.node['default:dirt']
              elseif y == p1.y + 1 and z1 < 2 then
                data[ivm] = squaresville.node['squaresville:sidewalk']
                --elseif y == p1.y + 1 and z1 >= size - 2 then
                --  data[ivm] = squaresville.node['default:glass']
              elseif y == p1.y + 1 then
                data[ivm] = squaresville.node['default:dirt_with_grass']
              elseif y == p1.y + 2 and (x1 == 0 or x1 == size - 1) and (z1 == 0 or z1 == size - 1) then
                data[ivm] = squaresville.node['default:dirt']
              else
                data[ivm] = squaresville.node['air']
              end
            else
              local node = {}
              node.name = minetest.get_name_from_content_id(data[ivm])
              if node.name == "air" then
                node.prob = 0
              end
              node.param2 = p2data[ivm] or 0
              if node.param2 < 4 then
                node.param2 = ((node.param2 % 4) - rot) % 4
              else
                local dir = node.param2 % 24
                for i = 1, rot do
                  dir = drotn[dir]
                end
                node.param2 = dir
              end

              local pos = {x=p1.x + x, y=p1.y, z=p1.z + z}
              local meta = minetest.get_meta(pos):to_table()
              if next(meta.inventory) or next(meta.fields) then
                node.meta = meta
              end
              schem.data[isch] = node
            end

            isch = isch + size
            ivm = ivm + a.ystride
          end
        end
      end

      if param == 'prep' then
        vm:set_data(data)
        vm:calc_lighting()
        vm:update_liquids()
        vm:write_to_map()
      else
        local file = io.open(filename, "wb")
        if file then
          local data = minetest.serialize(schem)
          --local data = dump(schem)
          file:write(data)
          file:close()
        end
        print("Squaresville saved a schematic to \""..filename.."\"")
      end
    else
      print("* Squaresville cannot determine coordinates for plotsave.")
    end
  end,
})


local function crates(data, pos1, pos2)
  local y = math.min(pos2.y, pos1.y)
  for z = pos1.z,pos2.z do
    for x = pos1.x,pos2.x do
      if (data[x][y][z] == node['air'] or data[x][y][z] == nil) and math_random(1000) == 1 then
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


--squaresville.overgrow = function(write, read, size)
--	local sr
--	if desolation > 0 then
--    for z = 0,size do
--      for x = 0,size do
--				sr = math_random(10)
--				if sr < 6 then
--          write(x, 1, z, "default:grass_"..sr)
--				elseif sr == 6 then
--          write(x, 1, z, "default:dry_shrub")
--				end
--			end
--		end
--	end
--end


local function shacks(write, read, get_index, size, suburb_orient)
  local rot
  local house_type = hash_rand(#house_schematics)
  local yard = 28
  local space = 6
  local floors = 2
  local plot = math_floor((size - 4) / yard)

  for pz = 0, plot do
    for px = 0, plot do
      if suburb_orient == 0 then
        if pz == 0 then
          rot = 0
        else
          rot = 2
        end
      else
        if px == 0 then
          rot = 1
        else
          rot = 3
        end
      end

      local house = house_schematics[(house_type + pz * 2 + px) % #house_schematics + 1]
      for z1 = 0, house.size.z - 1 do
        for x1 = 0, house.size.x - 1 do
          local x, z
          if rot == 0 then
            x, z = x1, z1
          elseif rot == 1 then
            x, z = z1, house.size.x - x1 - 1
          elseif rot == 2 then
            x, z = house.size.x - x1 - 1, house.size.z - z1 - 1
          elseif rot == 3 then
            x, z = house.size.z - z1 - 1, x1
          end

          local isch = z1 * house.size.y * house.size.x + x1 + 1
          local deco = nil
          local last_node = nil
          local index_2d = get_index(x + px * house.size.x - 2, z + pz * house.size.z - 2)

          if index_2d then
            local biome_name = get_biome(index_2d, 1, true)

            for y = 0, house.size.y - 1 do
              local prob = house.data[isch].prob or house.data[isch].param1 or 255
              if prob >= math_random(255) and house.data[isch].name ~= "air" then
                local param2 = house.data[isch].param2 or 0
                if param2 < 4 then
                  param2 = ((param2 % 4) + rot) % 4
                else
                  local dir = param2 % 24
                  for i = 1, rot do
                    dir = drotp[dir]
                  end
                  param2 = dir
                end
                local name = string.gsub(house.data[isch].name, 'cityscape', 'squaresville')
                local top = biomes[biome_name].node_top or 'default:dirt'
                --if top == 'default:dirt_with_rainforest_litter' then
                --  top = 'default:dirt_with_grass'
                --end
                if name == 'default:dirt_with_grass' then
                  name = top
                end
                write(x + px * house.size.x - 2, y - 1, z + pz * house.size.z - 2, name, param2)
                last_node = name
              elseif desolation > 0 and ground_nodes[node[last_node]] and not deco then
                deco = true
                local decoration = get_decoration(biome_name)
                if decoration then
                  write(x + px * house.size.x - 2, y - 1, z + pz * house.size.z - 2, decoration)
                end
              end
              isch = isch + house.size.x
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
  local h = math_random(4,6)
  for y = 1,h do
    data[px][y][pz] = node('default:tree')
  end
  for z = -2,2 do
    for y = -2,2 do
      for x = -2,2 do
        r = math.sqrt(x ^ 2 + y ^ 2 + z ^ 2)
        if data[x + px][y + h][z + pz] ~= node('default:tree') and math_random(4,6) > r * 2 then
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
      if desolation > 0 then
        sr = math_random(14)
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
      sr = math_random(5)
      if sr == 1 then
        simple_tree(data, qx * 5 - 2, qz * 5 - 2)
      elseif sr == 2 then
        data[qx * 5 - 2][1][qz * 5 - 2] = node('squaresville:park_bench')
        pstore(param, qx * 5 - 2, 1, qz * 5 - 2, math_random(4) - 1)
      elseif sr == 3 then
        data[qx * 5 - 2][1][qz * 5 - 2] = node('squaresville:swing_set')
        pstore(param, qx * 5 - 2, 1, qz * 5 - 2, math_random(4) - 1)
      else
        sr = math_random(30)
        if sr == 1 then
          data[qx * 5 - 2][1][qz * 5 - 2] = node('squaresville:doll')
          pstore(param, qx * 5 - 2, 1, qz * 5 - 2, math_random(4) - 1)
        end
      end
    end
  end
end


function squaresville.build(minp, maxp, data, p2data, area, node, baseline, heightmap)
  local size = block_size - road_size + 2
  if baseline == squaresville.baseline then
    desolation = 0
  elseif desolation == 0 then
    desolation = 1
  end

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
        local dist_x = math_floor(bx + max_height + half_road_size) % wild_limits
        local dist_z = math_floor(bz + max_height + half_road_size) % wild_limits

        local town = true
        local suburb = true
        local suburb_orient = 0

        if (bx + max_height + half_road_size) % block_plus_road_size ~= road_size + 2 or (bz + max_height + half_road_size) % block_plus_road_size ~= road_size + 2 then
          break
        end

        if dist_x >= suburb_limits_plus_road_size and dist_z >= suburb_limits_plus_road_size then
          break
        elseif ((dist_x < interior_limit or dist_z < interior_limit) and not (dist_x < city_limits_plus_road_size and dist_z < city_limits_plus_road_size)) or (dist_x >= city_limits_plus_road_size and dist_z >= city_limits_plus_road_size) then
          if dist_x < suburb_limits_plus_road_size and dist_z < suburb_limits_plus_road_size then
            suburb = false
          elseif dist_x >= suburb_limits_plus_road_size and (bx + max_height + half_road_size) % block_plus_road_size >= road_size then
            suburb_orient = 1
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
          print('Squaresville: Failed attempt to build in the wild.')
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

          if x >= minp.x and x <= maxp.x and y >= minp.y and y <= maxp.y and z >= minp.z and z <= maxp.z and (desolation == 0 or y <= baseline + ruin_map[((z - minp.z) * csize.x + (x - minp.x) + 1)]) then
            local ivm = area:index(x, y, z)
            if cobble then
              local h_i = (z - minp.z) * csize.x + (x - minp.x) + 1
              data[ivm] = node[breaker(node_name, desolation, 100 - humidity_1_map[h_i] + (y - baseline))]
            else
              data[ivm] = node[breaker(node_name, desolation)]
            end
            p2data[ivm] = p2 or 0
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

        local get_index = function(rx, rz)
          local x = pos.x + rx
          local z = pos.z + rz

          if x >= minp.x and x <= maxp.x and z >= minp.z and z <= maxp.z then
            return (z - minp.z) * csize.x + (x - minp.x) + 1
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
          for k, v in pairs(tree_map) do
            if math_random(town_tree_thinning) == 1 then
              local x, z = string.match(k, '(-?%d+),(-?%d+)')
              x = tonumber(x)
              z = tonumber(z)
              if not (x and z) then
                print('Squaresville: Cannot parse '..dump(k))
              else
                if x > pos.x and x < pos.x + size and z > pos.z and z < pos.z + size then
                  local index_2d = get_index(x - pos.x, z - pos.z)
                  if index_2d then
                    local biome_name = get_biome(index_2d, 1, true)
                    if biomes[biome_name].special_trees and (biome_name ~= 'savanna' or math_random(5) == 1) then
                      local tree_y
                      local ivm = area:index(x, baseline + 10, z)
                      for y = baseline + 10, baseline - 1, -1 do
                        if data[ivm] == node['default:water_source'] then
                          break
                        elseif ground_nodes[data[ivm]] then
                          tree_y = y
                          break
                        end

                        ivm = ivm - area.ystride
                      end

                      if tree_y then
                        tree_y = tree_y + (string.match(biome_name, '^rainforest') and 0 or 1)
                        ivm = area:index(x, tree_y, z)
                        if data[ivm] == node['air'] then
                          place_schematic(minp, maxp, data, p2data, area, node, {x=x,y=tree_y,z=z}, schematics[biomes[biome_name].special_trees[math_random(#biomes[biome_name].special_trees)]], true)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        elseif town then
          local sr = hash_rand(13)
          if sr <= 3 then
            clear(1, 10)
            gotham(write, read, size)
          elseif sr <= 6 then
            clear(1, 10)
            glass_and_steel(write, read, size)
          elseif sr <= 9 then
            clear(1, 10)
            simple(write, read, size)
          elseif sr <= 12 then
            clear(1, 10)
            simple(write, read, size, true)
          else
            --park(write, dx, dy, dz)
          end
        elseif suburb then
          local sr = hash_rand(13)
          if sr <= 13 then
            clear(1, 10)
            shacks(write, read, get_index, size, suburb_orient)
          end
        end
      end
    end
  end
end

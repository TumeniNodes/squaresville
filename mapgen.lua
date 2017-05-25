-- Squaresville mapgen.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local DEBUG
local baseline = squaresville.baseline
local extent_bottom = squaresville.extent_bottom
local extent_top = squaresville.extent_top
local node = squaresville.node


local data = {}
local p2data = {}  -- vm rotation data buffer


local function generate(p_minp, p_maxp, seed)
  if not (p_minp and p_maxp and seed) then
    return
  end

  local minp, maxp = p_minp, p_maxp
  baseline = squaresville.baseline
  if maxp.y >= baseline + squaresville.dim_sep + extent_bottom and minp.y <= baseline + squaresville.dim_sep + extent_top then
    baseline = baseline + squaresville.dim_sep
  elseif maxp.y < baseline + extent_bottom or minp.y > baseline + extent_top then
    return
  end

  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  if not (vm and emin and emax) then
    return
  end

  vm:get_data(data)
  p2data = vm:get_param2_data()
  local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
  local csize = vector.add(vector.subtract(maxp, minp), 1)

  for fake_loop = 1, 1 do
    squaresville.terrain(minp, maxp, data, p2data, area, node, baseline)

    if minp.y < baseline + 800 and maxp.y > baseline - 25 then
      squaresville.build(minp, maxp, data, p2data, area, node, baseline)
    end
  end


  vm:set_data(data)
  vm:set_param2_data(p2data)
  minetest.generate_ores(vm, minp, maxp)

  if DEBUG then
    vm:set_lighting({day = 15, night = 15})
  else
    vm:set_lighting({day = 0, night = 0}, minp, maxp)
    vm:calc_lighting()
  end
  vm:update_liquids()
  vm:write_to_map()

  -- Clear any tables that won't be reused.
  squaresville.tree_map = nil
end


if squaresville.path then
  dofile(squaresville.path .. "/terrain.lua")
  dofile(squaresville.path .. "/buildings.lua")
end


local function pgenerate(...)
  --local status, err = pcall(generate, ...)
  local status, err = true
  generate(...)
  if not status then
    print('Squaresville: Could not generate terrain:')
    print(dump(err))
    collectgarbage("collect")
  end
end


-- Inserting helps to ensure that squaresville operates first.
table.insert(minetest.registered_on_generateds, 1, pgenerate)

-- Squaresville init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


squaresville = {}
squaresville.version = '1.0'
squaresville.path = minetest.get_modpath(minetest.get_current_modname())
squaresville.world = minetest.get_worldpath()

squaresville.baseline = 8000  -- the altitude of the squaresville "dimension"
squaresville.baseline_ruin = 10000  -- how far up to the ruin "dimension"
squaresville.extent_bottom = -500  -- how far down to make the squaresville
squaresville.extent_bottom_ruin = -500  -- how far down to make the squaresville
squaresville.extent_top = 500  -- how far up to make it
squaresville.extent_top_ruin = 500  -- how far up to make it

local baseline = squaresville.baseline
local extent_bottom = squaresville.extent_bottom
local extent_top = squaresville.extent_top


--squaresville.block_size = tonumber(minetest.setting_get('squaresville_block_size')) or 60
--if squaresville.block_size < 20 or squaresville.block_size > 200 then
--	squaresville.block_size = 60
--end

squaresville.vacancies = tonumber(minetest.setting_get('squaresville_vacancies')) or 0
if squaresville.vacancies < 0 or squaresville.vacancies > 10 then
	squaresville.vacancies = 0
end

squaresville.desolation = tonumber(minetest.setting_get('squaresville_desolation')) or 0
if squaresville.desolation < 0 or squaresville.desolation > 10 then
	squaresville.desolation = 0
end

--squaresville.suburbs = tonumber(minetest.setting_get('squaresville_suburbs')) or 5
--if squaresville.suburbs < 0 or squaresville.suburbs > 10 then
--	squaresville.suburbs = 5
--end

squaresville.light_panels = minetest.setting_getbool('squaresville_light_panels')
if squaresville.light_panels == nil then
	squaresville.light_panels = true
end

squaresville.single_node = minetest.setting_getbool('squaresville_single_node')
if squaresville.single_node == nil then
	squaresville.single_node = false
end

squaresville.single_node_ruin = minetest.setting_getbool('squaresville_single_node_ruin')
if squaresville.single_node_ruin == nil then
	squaresville.single_node_ruin = false
end

squaresville.no_buildings = minetest.setting_getbool('squaresville_no_buildings')
if squaresville.no_buildings == nil then
	squaresville.no_buildings = false
end


--if not minetest.set_mapgen_setting then
--  return
--end


if squaresville.single_node_ruin then
	-- Set mapgen parameters to singlenode
  squaresville.baseline_ruin = 0
  squaresville.extent_bottom_ruin = -31000
	minetest.register_on_mapgen_init(function(mgparams)
		minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
	end)
elseif squaresville.single_node then
	-- Set mapgen parameters to singlenode
  squaresville.baseline_ruin = 8000
  squaresville.baseline = 0
  squaresville.extent_bottom = -31000
	minetest.register_on_mapgen_init(function(mgparams)
		minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
	end)
end


local math_random = math.random


-- Modify a node to add a group
function minetest.add_group(node, groups)
  local def = minetest.registered_items[node]
  if not (node and def and groups and type(groups) == 'table') then
    return false
  end
  local def_groups = def.groups or {}
  for group, value in pairs(groups) do
    if value ~= 0 then
      def_groups[group] = value
    else
      def_groups[group] = nil
    end
  end
  minetest.override_item(node, {groups = def_groups})
  return true
end


function squaresville.clone_node(name)
  if not (name and type(name) == 'string') then
    return
  end

  local node = minetest.registered_nodes[name]
  local node2 = table.copy(node)
  return node2
end


squaresville.surround = function(node, data, area, ivm)
  if not (node and data and area and ivm and type(data) == 'table' and type(ivm) == 'number') then
    return
  end

  -- Check to make sure that a plant root is fully surrounded.
  -- This is due to the kludgy way you have to make water plants
  --  in minetest, to avoid bubbles.
  for x1 = -1,1,2 do
    local n = data[ivm+x1] 
    if n == node['default:river_water_source'] or n == node['default:water_source'] or n == node['air'] then
      return false
    end
  end
  for z1 = -area.zstride,area.zstride,2*area.zstride do
    local n = data[ivm+z1] 
    if n == node['default:river_water_source'] or n == node['default:water_source'] or n == node['air'] then
      return false
    end
  end

  return true
end


-- This table looks up the names of broken nodes.
local broken_name = setmetatable({}, {
  __index = function(t, k)
    if not (t and k and type(t) == 'table' and type(k) == 'string') then
      return
    end

    t[k] = string.gsub(k, '.*:', 'squaresville:')..'_broken'
    if not minetest.registered_nodes[t[k]] then
      t[k] = k
    end

    return t[k]
  end
})


-- This table looks up the properties of nodes.
local groups = setmetatable({}, {
  __index = function(t, k)
    if not (t and k and type(t) == 'table' and type(k) == 'string') then
      return
    end

    t[k] = minetest.registered_items[k].groups
    return t[k]
  end
})


-- This table looks up nodes that aren't already stored.
local node = setmetatable({}, {
  __index = function(t, k)
    if not (t and k and type(t) == 'table') then
      return
    end

    t[k] = minetest.get_content_id(k)
    return t[k]
  end
})
squaresville.node = node


local ground_nodes = {}
ground_nodes[node['default:dirt']] = true
ground_nodes[node['default:stone']] = true
ground_nodes[node['default:dirt_with_grass']] = true
ground_nodes[node['default:dirt_with_snow']] = true
squaresville.ground_nodes = ground_nodes

function squaresville.breaker(node, desolation, dry)
  if desolation == 0 then
    return node
  end

  local sr = math_random(50)
  local goff = 1

  if not dry then
    dry = 50
  end

  if node == 'squaresville:light_panel' then
    sr = 1
  elseif node == 'squaresville:plate_glass' then
    goff = 3
  end

  if not ground_nodes[node[node]] and sr <= desolation * goff then
    return 'air'
  elseif squaresville.cobble and sr <= desolation * 3 and groups[node].cracky then
    sr = math_random(700)
    if sr == 1 then
      sr = math_random(4)
      if sr == 1 then
        return 'default:stone_with_copper'
      else
        return 'default:stone_with_iron'
      end
    elseif sr <= 15 then
      return 'squaresville:glowing_fungal_stone'
    elseif sr <= 40 then
      return 'default:gravel'
    elseif sr <= 140 then
      return 'default:dirt'
    else
      if sr <= dry * 10 then
        return 'default:cobble'
      else
        return 'default:mossycobble'
      end
    end
  elseif sr <= desolation * 5 then
    return broken_name[node]
  else
    return node
  end
end


dofile(squaresville.path .. '/nodes.lua')
dofile(squaresville.path .. '/schematics.lua')
dofile(squaresville.path .. '/mapgen.lua')
dofile(squaresville.path .. '/trans.lua')

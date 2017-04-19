-- Squaresville init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


squaresville = {}
squaresville.version = '1.0'
squaresville.path = minetest.get_modpath(minetest.get_current_modname())
squaresville.world = minetest.get_worldpath()


--squaresville.quick_leaf_decay = minetest.setting_getbool('squaresville_quick_leaf_decay')
--if squaresville.quick_leaf_decay == nil then
--	squaresville.quick_leaf_decay = false
--end


squaresville.desolation = 5


if not minetest.set_mapgen_setting then
  return
end

minetest.register_on_mapgen_init(function(mgparams)
  minetest.set_mapgen_params({mgname='singlenode', flags='nolight'})
end)


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
    return t[k]
  end
})


function squaresville.breaker(node)
  if squaresville.desolation == 0 then
    return node
  end

  local sr = math.random(50)
  local goff = 1

  if node == 'squaresville:light_panel' then
    sr = 1
  elseif node == 'squaresville:plate_glass' then
    goff = 3
  end

  if sr <= squaresville.desolation * goff then
    return 'air'
  elseif minetest.registered_nodes[broken_name[node]] and sr <= squaresville.desolation * 5 then
    return broken_name[node]
  else
    return node
  end
end


dofile(squaresville.path .. '/nodes.lua')
dofile(squaresville.path .. '/schematics.lua')
dofile(squaresville.path .. '/mapgen.lua')


----------------------------------------------------------------------


if squaresville.quick_leaf_decay then
  for name, node in pairs(minetest.registered_nodes) do
    if node.groups.leafdecay then
      node.groups.leafdecay = 0
      node.groups.qfc_leafdecay = 0
    end
  end
end

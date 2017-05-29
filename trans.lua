-- Squaresville trans.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local function teleport(user, ruin)
  if not (user) then
    return
  end

  local name = user:get_player_name()
  local pos = user:getpos()
  if not (name and pos and name ~= '' and type(name) == 'string') then
    return
  end


  local newpos = {x=0,y=squaresville.baseline+2,z=0}
  local wl = squaresville.wild_limits
  local y = squaresville.baseline + 2
  local extent_bottom = squaresville.extent_bottom
  local extent_top = squaresville.extent_top
  if ruin then
    y = squaresville.baseline_ruin + 2
    extent_bottom = squaresville.extent_bottom_ruin
    extent_top = squaresville.extent_top_ruin
  end

  local tdx = math.floor((pos.x + wl / 2) / wl) * wl - 0
  local tdz = math.floor((pos.z + wl / 2) / wl) * wl - 0
  if pos.y < y + extent_bottom or pos.y > y + extent_top then
    newpos = {x=tdx, y=y, z=tdz}
  else
    newpos = {x=tdx, y=120, z=tdz}
  end

  user:setpos(newpos)
  print('Squaresville: '..name..' teleported to ('..newpos.x..','..newpos.y..','..newpos.z..')')

  user:set_physics_override({gravity=0.1})

  minetest.after(20, function()
    user:set_physics_override({gravity=1})
  end)
end


minetest.register_craftitem('squaresville:key', {
  description = 'Key To The City',
  drawtype = "plantlike",
  paramtype = "light",
  tiles = {'squaresville_key.png'},
  inventory_image = 'squaresville_key.png',
  groups = {dig_immediate = 3},
  sounds = default.node_sound_stone_defaults(),
  on_use = function(itemstack, user, pointed_thing)
    teleport(user, false)
  end,
})

minetest.register_craftitem('squaresville:broken_key', {
  description = 'Broken Key To The City',
  drawtype = "plantlike",
  paramtype = "light",
  tiles = {'squaresville_broken_key.png'},
  inventory_image = 'squaresville_broken_key.png',
  groups = {dig_immediate = 3},
  sounds = default.node_sound_stone_defaults(),
  on_use = function(itemstack, user, pointed_thing)
    teleport(user, true)
  end,
})

minetest.register_craft({
  output = 'squaresville:key',
  recipe = {
    {'','default:obsidian_shard','default:copper_ingot'},
    {'','default:steel_ingot',''},
    {'','default:mese_crystal_fragment',''},
  }
})

minetest.register_craft({
  output = 'squaresville:broken_key',
  recipe = {
    {'','default:obsidian_shard','default:coal_lump'},
    {'','default:steel_ingot',''},
    {'','default:mese_crystal_fragment',''},
  }
})

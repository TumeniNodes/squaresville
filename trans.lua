-- Squaresville trans.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local function teleport(user)
	if not (user) then
		return
	end

	local name = user:get_player_name()
	local pos = user:getpos()
	if not (name and pos and name ~= '' and type(name) == 'string') then
		return
	end


  local newpos = {x=0,y=squaresville.baseline+2,z=0}
  for r = 0, 10 do
    local tdx = math.floor((pos.x + squaresville.wild_limits / 2) / squaresville.wild_limits) * squaresville.wild_limits - 0
    local tdz = math.floor((pos.z + squaresville.wild_limits / 2) / squaresville.wild_limits) * squaresville.wild_limits - 0
    if pos.y < squaresville.baseline + squaresville.extent_bottom or pos.y > squaresville.baseline + squaresville.extent_top then
      newpos = {x=tdx, y=squaresville.baseline+2, z=tdz}
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
    teleport(user)
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

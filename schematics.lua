-- Squaresville schematics.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local math_random = math.random


-- Create and initialize a table for a schematic.
function squaresville.schematic_array(width, height, depth)
  if not (width and height and depth and type(width) == 'number' and type(height) == 'number' and type(depth) == 'number') then
    return
  end

  -- Dimensions of data array.
  local s = {size={x=width, y=height, z=depth}}
  s.data = {}

  for z = 0,depth-1 do
    for y = 0,height-1 do
      for x = 0,width-1 do
        local i = z*width*height + y*width + x + 1
        s.data[i] = {}
        s.data[i].name = "air"
        s.data[i].param1 = 000
      end
    end
  end

  s.yslice_prob = {}

  return s
end


squaresville.place_schematic = function(minp, maxp, data, p2data, area, node, pos, schem, center)
  if not (minp and maxp and data and p2data and area and node and pos and schem and type(data) == 'table' and type(p2data) == 'table' and type(schem) == 'table') then
    return
  end

  local rot = math.random(4) - 1
  local yslice = {}  -- true if the slice should be removed
  if schem.yslice_prob then
    for _, ys in pairs(schem.yslice_prob) do
      yslice[ys.ypos] = ((ys.prob or 255) < math_random(255))
    end
  end

  if center then
    pos.x = pos.x - math.floor(schem.size.x / 2)
    pos.z = pos.z - math.floor(schem.size.z / 2)
  end

  for z1 = 0, schem.size.z - 1 do
    for x1 = 0, schem.size.x - 1 do
      local x, z
      if rot == 0 then
        x, z = x1, z1
      elseif rot == 1 then
        x, z = schem.size.z - z1 - 1, x1
      elseif rot == 2 then
        x, z = schem.size.x - x1 - 1, schem.size.z - z1 - 1
      elseif rot == 3 then
        x, z = z1, schem.size.x - x1 - 1
      end
      local dz = pos.z - minp.z + z
      local dx = pos.x - minp.x + x
      --if pos.x + x > minp.x and pos.x + x < maxp.x and pos.z + z > minp.z and pos.z + z < maxp.z then
      if true then
        local ivm = area:index(pos.x + x, pos.y, pos.z + z)
        local isch = z1 * schem.size.y * schem.size.x + x1 + 1
        for y = 0, schem.size.y - 1 do
          local dy = pos.y - minp.y + y
          if not yslice[y] then
            if data[ivm] == node['air'] or data[ivm] == node['ignore'] then
              local prob = schem.data[isch].prob or schem.data[isch].param1 or 255
              if prob >= math_random(255) and schem.data[isch].name ~= "air" then
                data[ivm] = node[schem.data[isch].name]
              end
              local param2 = schem.data[isch].param2 or 0
              p2data[ivm] = param2
            end

            ivm = ivm + area.ystride
          end
          isch = isch + schem.size.x
        end
      end
    end
  end
end


squaresville.schematics = {}


do
  local w, h, d = 5, 8, 5
  local s = squaresville.schematic_array(w, h, d)

  for y = 0, math.floor(h/2)-1 do
    s.data[2*d*h + y*d + 2 + 1].name = 'default:tree'
    s.data[2*d*h + y*d + 2 + 1].param1 = 255
  end

  for z = 0, d-1 do
    for y = math.floor(h/2), h-1 do
      for x = 0, w-1 do
        if y < h - 1 or (x ~= 0 and x ~= w-1 and z ~= 0 and z ~= d-1) then
          s.data[z*d*h + y*d + x + 1].name = 'default:leaves'

          if y == h-1 or x == 0 or x == w-1 or z == 0 or z == d-1 then
            s.data[z*d*h + y*d + x + 1].param1 = 150
          else
            s.data[z*d*h + y*d + x + 1].param1 = 225
          end
        end
      end
    end
  end

  for z = math.floor(d/2)-1, math.floor(d/2)+1 do
    for x = math.floor(w/2)-1, math.floor(w/2)+1 do
      local y = math.floor(h/2)
      if z ~= math.floor(d/2) or x ~= math.floor(d/2) then
        s.data[z*d*h + y*d + x + 1].name = 'default:apple'
        s.data[z*d*h + y*d + x + 1].param1 = 150
      end
    end
  end

  for z = math.floor(d/2)-1, math.floor(d/2)+1, 2 do
    for x = math.floor(w/2)-1, math.floor(w/2)+1, 2 do
      s.data[z*d*h + math.floor(h/2)*d + x + 1].name = 'default:tree'
      s.data[z*d*h + math.floor(h/2)*d + x + 1].param1 = 150
    end
  end

  for y = 0, h-1 do
    if y / 3 == math.floor(y / 3) then
      s.yslice_prob[#s.yslice_prob+1] = {ypos=y,prob=170}
    end
  end

  squaresville.schematics['apple_tree'] = s
end

do
  squaresville.schematics['aspen_tree'] = table.copy(squaresville.schematics['apple_tree'])
  local s = squaresville.schematics['aspen_tree']
  for i = 1, #s.data do
    if s.data[i].name == 'default:apple' then
      s.data[i].name = 'default:leaves'
    end
  end
end


-- the default pine schematic
do
  local height = 13 + 1
  local width = 5
  local s = squaresville.schematic_array(width, height, width)

  -- the main trunk
  local probs = {255,220,190}

  for p = 0,2 do
    local c = math.floor(width / 2)
    local y = height - p * 3 - 1
    for r = 0,2 do
      for z = c-r,c+r do
        for x = c-r,c+r do
          local i = z*width*height + (y-r)*width + x + 1
          s.data[i].name = 'default:pine_needles'
          s.data[i].param1 = probs[r]
        end
      end
    end

    s.yslice_prob = {}
    for y = 0,height-3 do
      local i = 2*width*height + y*width + 2 + 1
      if squaresville.glow and math.random(1,10) == 1 then
        s.data[i].name = "squaresville:pine_tree_glowing_moss"
      else
        s.data[i].name = 'default:pine_tree'
      end

      s.data[i].param1 = 255
      s.data[i].force_place = true

      local j = (height - y - 1) / 3
      if j == 0 or j == 1 or j == 2 or y <= height - 11 then
        s.yslice_prob[#s.yslice_prob+1] = {ypos=y,prob=170}
      end
    end
  end

  squaresville.schematics['pine_tree'] = s
end


local mz = 9
local mx = 9
local my = 7
local s = squaresville.schematic_array(mx, my, mz)
for i = 1, #s.data do
  s.data[i] = { name = "air", prob = 0 }
end

local y1 = 5
for z1 = 0, 5, 5 do
  for x1 = 0, 5, 5 do
    if x1 ~= z1 then
      for z = 0, 3 do
        for x = 0, 3 do
          local i = (z + z1) * mx * my + y1 * mx + x1 + x + 1
          s.data[i] = { name = "default:acacia_leaves", prob = 240 }
        end
      end
    end
  end
end
y1 = 6
for z1 = 4, 0, -4 do
  for x1 = 0, 4, 4 do
    if x1 == z1 then
      for z = 0, 4 do
        for x = 0, 4 do
          local i = (z + z1) * mx * my + y1 * mx + x1 + x + 1
          s.data[i] = { name = "default:acacia_leaves", prob = 240 }
        end
      end
    end
  end
end
local trunk = {{4,0,4}, {4,1,4}, {4,2,4}, {4,3,4}, {3,4,3}, {5,4,5}, {3,3,5}, {5,3,3}, {2,5,2}, {6,5,6}, {2,4,6}, {6,4,2}}
for _, p in pairs(trunk) do
  local i = p[3] * mx * my + p[2] * mx + p[1] + 1
  s.data[i] = { name = "default:acacia_tree", prob = 255 }
end
squaresville.schematics['acacia_tree'] = s


-- Create a canopy of leaves.
function generate_canopy(s, leaf, pos)
  local height = s.size.y
  local width = s.size.x
  local rx = math.floor(s.size.x / 2)
  local rz = math.floor(s.size.z / 2)
  local r1 = 3  -- leaf decay radius
  local probs = {255,200,150,100,75}

  for z = -r1,r1 do
    for y = 0,1 do
      for x = -r1,r1 do
        if x+pos.x >= -rx and x+pos.x <= rx and y+pos.y >= 0 and y+pos.y < height and z+pos.z >= -rz and z+pos.z <= rz then
          local i = (z+pos.z+rz)*width*height + (y+pos.y)*width + (x+pos.x+rx) + 1
          local dist1 = math.sqrt(x^2 + y^2 + z^2)
          local dist2 = math.sqrt((x+pos.x)^2 + (z+pos.z)^2)
          if dist1 <= r1 then
            local newprob = probs[math.max(1, math.ceil(dist1))]
            if s.data[i].name == "air" then
              s.data[i].name = leaf
              s.data[i].param1 = newprob
            elseif s.data[i].name == leaf then
              s.data[i].param1 = math.max(s.data[i].param1, newprob)
            end
          end
        end
      end
    end
  end
end

-- Create a schematic for a jungle tree.
do
  local trunk_height = 8
  local height = trunk_height * 2 + 1
  local radius = 6
  local width = 2 * radius + 1
  local trunk_top = height - 4

  local s = squaresville.schematic_array(width, height, width)

  -- roots, trunk, and extra leaves
  for z = -1,1 do
    for y = 0,trunk_top do
      for x = -1,1 do
        local i = (z+radius)*width*height + y*width + (x+radius) + 1
        if x == 0 and z == 0 then
          s.data[i].name = 'default:jungletree'
          s.data[i].param1 = 255
          s.data[i].force_place = true
        elseif (x == 0 or z == 0) and y < 3 then
          s.data[i].name = 'default:jungletree'
          s.data[i].param1 = 255
          s.data[i].force_place = true
        elseif y > 3 then
          s.data[i].name = 'default:jungleleaves'
          s.data[i].param1 = 50
        end
      end
    end
  end

  -- canopies
  for y = 0,trunk_top+2 do
    if y > trunk_height and (y == trunk_top or math.random(1,height - y) == 1) then
      local x, z = 0, 0
      while x == 0 and z == 0 do
        x = math.random(-1,1) * 2
        z = math.random(-1,1) * 2
      end
      for j = -1,1,2 do
        local i = (j*z + radius)*width*height + y*width + (j*x + radius) + 1
        s.data[i].name = 'default:jungletree'
        s.data[i].param1 = 255
        s.data[i].force_place = true
        generate_canopy(s, 'default:jungleleaves', {x=j*x, y=y, z=j*z})
      end
    end
  end

  squaresville.schematics['jungle_tree'] = s
end

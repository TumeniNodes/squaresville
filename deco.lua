-- Squaresville init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


squaresville.decorate = function(minp, maxp, data, p2data, area, node, heightmap, river_1)
	if not (minp and maxp and data and p2data and area and node and type(data) == 'table' and type(p2data) == 'table') then
		return
	end

	if not csize then
		csize = vector.add(vector.subtract(maxp, minp), 1)
	end
end

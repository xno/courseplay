--[[
A* algorithm for LUA
Ported to LUA by Altair
21 septembre 2006
courseplay edit by hummel 2011
--]]


function round(num, idp)
	return math.floor(num / idp) * idp
end

function CalcMoves(px, py, tx, ty, fruit_type) -- Based on some code of LMelior but made it work and improved way beyond his code, still thx LMelior!
	if not courseplay:is_field(py, px) then
		return nil
	end

	local interval = 5
	local vertical_costs = 10
	local diagnoal_costs = 14

	px = round(px, interval)
	py = round(py, interval)
	tx = round(tx, interval)
	ty = round(ty, interval)

	--[[ PRE:
mapmat is a 2d array
px is the player's current x
py is the player's current y
tx is the target x
ty is the target y

Note: all the x and y are the x and y to be used in the table.
By this I mean, if the table is 3 by 2, the x can be 1,2,3 and the y can be 1 or 2.
--]]

	--[[ POST:
closedlist is a list with the checked nodes.
It will return nil if all the available nodes have been checked but the target hasn't been found.
--]]

	-- variables
	local openlist = {} -- Initialize table to store possible moves
	local closedlist = {} -- Initialize table to store checked gridsquares
	local listk = 1 -- List counter
	local closedk = 0 -- Closedlist counter
	local tempH = math.abs(px - tx) + math.abs(py - ty)
	local tempG = 0
	openlist[1] = { x = px, y = py, g = 0, h = tempH, f = 0 + tempH, par = 1 } -- Make starting point in list
	local xsize = 1024 -- horizontal map size
	local ysize = 1024 -- vertical map size
	local curbase = {} -- Current square from which to check possible moves
	local basis = 1 -- Index of current base
	local max_tries = 2000
	local max_distance_factor = 10
	local air_distance = tempH

	-- Growing loop
	while listk > 0 do

		-- Get the lowest f of the openlist
		local lowestF = openlist[listk].f
		basis = listk
		for k = listk, 1, -1 do
			if openlist[k].f < lowestF then
				lowestF = openlist[k].f
				basis = k
			end
		end

		if closedk >= max_tries then
			return nil
		end

		closedk = closedk + 1
		table.insert(closedlist, closedk, openlist[basis])

		curbase = closedlist[closedk] -- define current base from which to grow list

		--courseplay:debug(string.format("a star check x: %f y %f - closedk: %d", curbase.x, curbase.y, closedk ), 4)

		local wOK = true
		local eOK = true -- Booleans defining if they're OK to add
		local sOK = true -- (must be reset for each while loop)
		local nOK = true

		local nwOK = true
		local seOK = true
		local swOK = true
		local noOK = true

		-- Look through closedlist
		if closedk > 0 then
			for k = 1, closedk do
				if closedlist[k].x == curbase.x + interval and closedlist[k].y == curbase.y then
					wOK = false
				end
				if closedlist[k].x == curbase.x - interval and closedlist[k].y == curbase.y then
					eOK = false
				end
				if closedlist[k].x == curbase.x and closedlist[k].y == curbase.y + interval then
					sOK = false
				end
				if closedlist[k].x == curbase.x and closedlist[k].y == curbase.y - interval then
					nOK = false
				end

				if closedlist[k].x == curbase.x + interval and closedlist[k].y == curbase.y - interval then
					nwOK = false
				end

				if closedlist[k].x == curbase.x - interval and closedlist[k].y == curbase.y - interval then
					neOK = false
				end

				if closedlist[k].x == curbase.x + interval and closedlist[k].y == curbase.y + interval then
					swOK = false
				end

				if closedlist[k].x == curbase.x - interval and closedlist[k].y == curbase.y + interval then
					seOK = false
				end
			end
		end

		-- Check if next points are on the map and within moving distance
		if curbase.x + interval > xsize then
			wOK = false
			nwOK = false
			swOK = false
		end
		if curbase.x - interval < -1024 then
			eOK = false
			neOK = false
			seOK = false
		end
		if curbase.y + interval > ysize then
			sOK = false
			swOK = false
			seOK = false
		end
		if curbase.y - interval < -1024 then
			nOK = false
			nwOK = false
			neOK = false
		end

		-- If it IS on the map, check map for obstacles
		--(Lua returns an error if you try to access a table position that doesn't exist, so you can't combine it with above)
		if wOK and curbase.x + interval <= xsize and courseplay:area_has_fruit(curbase.y, curbase.x + interval, fruit_type) then
			wOK = false
		end
		if eOK and curbase.x - interval >= -1024 and courseplay:area_has_fruit(curbase.y, curbase.x - interval, fruit_type) then
			eOK = false
		end
		if sOK and curbase.y + interval <= ysize and courseplay:area_has_fruit(curbase.y + interval, curbase.x, fruit_type) then
			sOK = false
		end
		if nOK and curbase.y - interval >= -1024 and courseplay:area_has_fruit(curbase.y - interval, curbase.x, fruit_type) then
			nOK = false
		end

		-- check if the move from the current base is shorter then from the former parrent
		tempG = curbase.g + interval
		for k = 1, listk do
			if wOK and openlist[k].x == curbase.x + interval and openlist[k].y == curbase.y then
				if openlist[k].g > tempG then
					--courseplay:debug("right OK 1", 4)
					tempH = math.abs((curbase.x + interval) - tx) + math.abs(curbase.y - ty)
					table.insert(openlist, k, { x = curbase.x + interval, y = curbase.y, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
				end
				wOK = false
			end

			if eOK and openlist[k].x == curbase.x - interval and openlist[k].y == curbase.y then
				if openlist[k].g > tempG then
					--courseplay:debug("left OK 1", 4)
					tempH = math.abs((curbase.x - interval) - tx) + math.abs(curbase.y - ty)
					table.insert(openlist, k, { x = curbase.x - interval, y = curbase.y, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
				end
				eOK = false
			end

			if sOK and openlist[k].x == curbase.x and openlist[k].y == curbase.y + interval then
				if openlist[k].g > tempG then
					--courseplay:debug("down OK 1", 4)
					tempH = math.abs((curbase.x) - tx) + math.abs(curbase.y + interval - ty)

					table.insert(openlist, k, { x = curbase.x, y = curbase.y + interval, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
				end
				sOK = false
			end

			if nOK and openlist[k].x == curbase.x and openlist[k].y == curbase.y - interval then
				if openlist[k].g > tempG then
					--courseplay:debug("up OK 1", 4)
					tempH = math.abs((curbase.x) - tx) + math.abs(curbase.y - interval - ty)
					table.insert(openlist, k, { x = curbase.x, y = curbase.y - interval, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
				end
				nOK = false
			end
		end

		-- Add points to openlist
		-- Add point to the right of current base point
		if wOK then
			--courseplay:debug("right OK", 4)
			listk = listk + 1
			tempH = math.abs((curbase.x + interval) - tx) + math.abs(curbase.y - ty)

			table.insert(openlist, listk, { x = curbase.x + interval, y = curbase.y, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
		end

		-- Add point to the left of current base point
		if eOK then
			--courseplay:debug("left OK", 4)
			listk = listk + 1
			tempH = math.abs((curbase.x - interval) - tx) + math.abs(curbase.y - ty)
			table.insert(openlist, listk, { x = curbase.x - interval, y = curbase.y, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
		end

		-- Add point on the top of current base point
		if sOK then
			--courseplay:debug("down OK", 4)
			listk = listk + 1
			tempH = math.abs(curbase.x - tx) + math.abs((curbase.y + interval) - ty)

			table.insert(openlist, listk, { x = curbase.x, y = curbase.y + interval, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
		end

		-- Add point on the bottom of current base point
		if nOK then
			--courseplay:debug("up OK", 4)
			listk = listk + 1
			tempH = math.abs(curbase.x - tx) + math.abs((curbase.y - interval) - ty)

			table.insert(openlist, listk, { x = curbase.x, y = curbase.y - interval, g = tempG, h = tempH, f = tempG + tempH, par = closedk })
		end

		table.remove(openlist, basis)
		listk = listk - 1

		if closedlist[closedk].x == tx and closedlist[closedk].y == ty then
			return CalcPath(closedlist)
		end
	end

	return nil
end

function CalcPath(closedlist)
	--[[ PRE:
closedlist is a list with the checked nodes.
OR nil if all the available nodes have been checked but the target hasn't been found.
--]]

	--[[ POST:
path is a list with all the x and y coords of the nodes of the path to the target.
OR nil if closedlist==nil
--]]

	if closedlist == nil then
		return nil
	end
	local path = {}
	local pathIndex = {}
	local last = table.getn(closedlist)
	table.insert(pathIndex, 1, last)

	local i = 1
	while pathIndex[i] > 1 do
		i = i + 1
		table.insert(pathIndex, i, closedlist[pathIndex[i - 1]].par)
	end

	for n = table.getn(pathIndex), 1, -1 do
		table.insert(path, { x = closedlist[pathIndex[n]].x, y = closedlist[pathIndex[n]].y })
	end

	closedlist = nil
	return path
end


courseplay.algo = {};


--[[
A* Algorithm
Alternative Implementation
-- A*: Best-First Search (Dijkstra) with lower bound --
by Horoman 2013
--]]

function courseplay.algo.a_star(start, destination, nodes, costs)
--[[ PRE
	start: start node id
	destination: destination node id
	nodes: array with all nodes { id1={x=x1, y=y1}, id2={x=x2, y=y2} }
	costs: non negative costs form one node to the other (costs[i][j] = cost from i to j; nil or negative numbers are treated as infinity)
--]]
--[[ POST
	path: if success: path {1=start, 2=i, ... ,n=destination}, if no success: empty matrix
--]]

-- todo: use binary heap instead of sorted array
		
	local _nodes = {};
	local dx, dy, pos, k;
	local path = {};
	
	-- initialize
	local openBin = {start};
	_nodes[start] = {d=0, parent=0, inBin=true};
	_nodes[destination] = {d=math.huge, parent=nil, h=0};
	
	-- find path
	while #openBin > 0 do
		-- remove last element in bin -> order bin in a way the element, that should be removed is at the end...
		current = table.remove(openBin);
		_nodes[current].inBin = false;
		
		-- check for children
		if costs[current] ~= nil then -- else no children...
			-- loop through all children
			for i,a in pairs(costs[current]) do -- child with id i and cost a from current to i
				if a >= 0 then -- otherways it is treated as infinity -> no path / not a child
					
					if not _nodes[i] then
						dx = nodes[i].x - nodes[current].x;
						dy = nodes[i].y - nodes[current].y;
						_nodes[i] = {d=math.huge, parent=nil, inBin=false h=math.sqrt(dx*dx+dy*dy) };
					end
					
					if _nodes[current].d + a < _nodes[i].d and _nodes[current].d + a + _nodes[i].h < _nodes[destination].d then
						-- update total costs (distance)
						_nodes[i].d = _nodes[current].d + a;
						-- update parent
						_nodes[i].parent = current;
						-- put into open bin if not already there and not destination
						if i~= destination then
							if (not _nodes[i].inBin) then
								pos = courseplay.algo.special_interpolation_search(openBin, _nodes, _nodes[i].d);
								table.insert(openBin, pos, i);
								_nodes[i].inBin = true;
							else
								--todo: else: as the costs for the node were updated, also its position in the Bin might have to be updated...
							end
						end
					end
									
				end
			end -- for i,a in pairs(costs[current])
		end -- if costs[current] ~= nil
		
	end -- while #openBin > 0	
	
	-- get path
	if _nodes[destination].d < math.huge then -- totalCosts of destination have to be less than infinity otherwise no path was found.
		k = destination;
		while _nodes[k].parent > 0 do
			table.insert(path, 1, _nodes[k].parent);
			k = _nodes[k].parent;
		end
	end
	
	return path
	
end

function courseplay.algo.special_interpolation_search(bin, _nodes, X)
--[[ PRE
	bin: the sorted list to be search in, the ordering of the ids is not by id but by the linked value. (bin = {1=i, 2=j, ... , n=k})
	_nodes: the values of the sorted list. (_nodes = {j={d=x}, k={d=z}, ... i={d=y}} , i,j,k are ids and x > y > z !!)
	X: value to be found
--]]
--[[ POST
	the index where the value X should be inserted
--]]
	local left = 1;
	local right = #bin;
	local mid = 0;
	
	if X <= _nodes[bin[right]].d then
		mid = right + 1;
	elseif X > _nodes[bin[1]].d then
		mid = 1;
	else
	
		while left < right-1 do
		
			if _nodes[bin[right]].d - _nodes[bin[left]].d == 0 then
				mid = right + 1;
				break;
			end
			
			mid = left + ((X - _nodes[bin[left]].d * (right - left)) / (_nodes[bin[right]].d - _nodes[bin[left]].d);
			mid = math.floor(mid + 0.5);
		
			if X < _nodes[bin[mid]].d then
				left = mid;
			elseif X > _nodes[bin[mid]].d then
				right = mid;
			else
				mid = mid + 1;
				break;
			end
			
		end --end while
		
		if right - left == 1 then
			mid = right;
		end
	
	end -- else (X was to find in the array)
	
	return mid;
end

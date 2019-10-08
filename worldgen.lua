function connectCities()
   function positionIsOpenFunc(x, y)
      local height = world[x][y][4]
      if  (height >= 0 and height < 0.4) then
	 return true
      else
	 return false
      end
   end

   function positionIsOpenFuncRender(x, y)
      world[x][y][1] = colors.dark_gray
      world[x][y][2] = colors.white
      world[x][y][3] = chars.single_horizontal
      return true
   end

   for ci=1, #cities do
      local city = cities[ci]
      local start = {x=city.x, y=city.y}
      for cj=1, #cities do
	 local city2 = cities[cj]
	 local goal = {x=city2.x, y=city2.y}
	 if (ci ~= cj and distance(start.x, start.y, goal.x, goal.y) < 30 ) then

	    local los = bresenham.los(start.x,start.y,goal.x,goal.y, positionIsOpenFunc)
	    if (los) then
	       bresenham.los(
		  start.x,start.y,goal.x,goal.y,positionIsOpenFuncRender

	       )
	    end
	 end

      end
   end

   for i=1, worldWidth do
      for j = 1, worldHeight do
	 beSmartAboutTile(i,j)
	 local score = getCountAround(i, j) -- 0,1,2,3,4
	 --if (score  == 1) then world[i][j][1] = colors.yellow end
	 --if (score  == 2) then world[i][j][1] = colors.orange end
	 if (score  == 3) then world[i][j][1] = colors.red end
	 if (score  == 4) then world[i][j][1] = colors.dark_purple end
      end
   end


end

function createZoomedinWorld(width, height, scalein, offsetX, offsetY)
   local grid = {}
   --local cities = {}
   --local water_waves = {}
   local scale = 1.0 / scalein

   for i = 1, width do
      grid[i] = {}
      for j = 1, height do
	 local bg = (i==1 or i==width or j==1 or j==height ) and colors.yellow or colors.black
	 local fg = colors.dark_green
	 local char = 0 -- randChar({".", " ", " ", " ", ","})

	 --local offsetX = 0
	 --local offsetY = 0
	 local x1 = perlin:noise((i + offsetX)/100  * scale,(j+ offsetY)/100 * scale, 0)
	 local x2 = perlin:noise((i + offsetX)/10 * scale, (j+ offsetY)/10 * scale, 0)
	 local x3 = perlin:noise((i + offsetX)/30 * scale, (j+ offsetY)/30 * scale, 0)
	 local x4 = perlin:noise((i + offsetX)/3 * scale, (j+ offsetY)/3 * scale, 0)
	 local x5 = perlin:noise((i + offsetX)/.2 * scale, (j+ offsetY)/.2 * scale, 0)

	 local x = 0.6*x1 + 0.3*x3 +  0.1*x2
	 if (scalein == 8 or scalein == 64) then

	    x = (x + x4/40) -- nice!!
	 end
	 if (scalein == 64) then
	    x = (x + x5/800) -- nice!!
	 end

	 x = x + 0.1 -- raise the world level

	 if x < -0.0 then
	    bg = colors.blue
	 elseif x < 0.01 then
	    bg = colors.yellow
	 elseif x < 0.05 then
	    bg = colors.orange
	 elseif x < 0.1 then
	    bg = colors.pink
	 elseif x < 0.2 then
	    bg = colors.green
	 elseif x < 0.3 then
	    bg = colors.dark_green
	 elseif x < 0.4 then
	    bg = colors.brown
	 elseif x < 0.45 then
	    bg = colors.dark_gray
	 elseif x < 0.8 then
	    bg = colors.light_gray
	 end

	 if x>= -0.01 and x<= 0 then
	    char = randOf( {chars.double_tilde, chars.single_tilde,  0,0,0,0,0,0}) --randChar({" ", "~"})
	    fg = randOf({colors.white, colors.dark_blue})
	    if (char ~= 0) then
	        table.insert( water_waves, {x=i, y=j})
	    end

	 elseif x < 0.01 then
	    char = randOf( {chars.double_tilde, chars.single_tilde, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}) --randChar({" ", "~"})
	    fg = randOf({colors.white, colors.dark_blue})
	    if (char ~= 0) then
	       table.insert( water_waves, {x=i, y=j})
	    end

	 end

	 grid[i][j] = {bg,fg, char, x}
      end
   end
   return grid
end


function createWorld(width, height)
   local grid = {}
   local cities = {}
   local water_waves = {}
   local scale = 1.0 --/ (8 * 16)

   for i = 1, width do
      grid[i] = {}
      for j = 1, height do
	 local bg = (i==1 or i==width or j==1 or j==height ) and colors.yellow or colors.black
	 local fg = colors.dark_green
	 local char = 0 -- randChar({".", " ", " ", " ", ","})

	 local offsetX = 0
	 local offsetY = 0
	 local x1 = perlin:noise((i + offsetX)/100  * scale,(j+ offsetY)/100 * scale, 0)
	 local x2 = perlin:noise((i + offsetX)/10 * scale, (j+ offsetY)/10 * scale, 0)
	 local x3 = perlin:noise((i + offsetX)/30 * scale, (j+ offsetY)/30 * scale, 0)
	 local x4 = perlin:noise((i + offsetX)/3 * scale, (j+ offsetY)/3 * scale, 0)

	 local x = 0.6*x1 + 0.3*x3 +  0.1*x2
	 --x = (x + x4/30) -- nice!!


	 x = x + 0.1 -- raise the world level

	 if x < -0.0 then
	    bg = colors.blue
	 elseif x < 0.01 then
	    bg = colors.yellow
	 elseif x < 0.05 then
	    bg = colors.orange
	 elseif x < 0.1 then
	    bg = colors.pink
	 elseif x < 0.2 then
	    bg = colors.green
	 elseif x < 0.3 then
	    bg = colors.dark_green
	 elseif x < 0.4 then
	    bg = colors.brown
	 elseif x < 0.45 then
	    bg = colors.dark_gray
	 elseif x < 0.8 then
	    bg = colors.light_gray
	 end

	 if x>= -0.01 and x<= 0 then
	    char = randOf( {chars.double_tilde, chars.single_tilde,  0,0,0,0,0,0}) --randChar({" ", "~"})
	    fg = randOf({colors.white, colors.dark_blue})
	    if (char ~= 0) then
	        table.insert( water_waves, {x=i, y=j})
	    end

	 elseif x < 0.01 then
	    char = randOf( {chars.double_tilde, chars.single_tilde, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}) --randChar({" ", "~"})
	    fg = randOf({colors.white, colors.dark_blue})
	    if (char ~= 0) then
	       table.insert( water_waves, {x=i, y=j})
	    end

	 end

	 grid[i][j] = {bg,fg, char, x}
      end
   end

   -- cities
   -- the rough thing
   for i = 1, width do
      for j = 1, height do
	 local x = grid[i][j][4]
	    if (x>= 0) then
	       local cityrandom = math.random()
	       if (x< 0.05) then
		  if (cityrandom > 0.01 and cityrandom < 0.02) then
		     table.insert(cities, {x=i, y=j})
		  end
	       elseif(x < 0.4) then
		  if (cityrandom > 0.01 and cityrandom < 0.011) then
		     table.insert(cities, {x=i, y=j})
		  end
	       end
	 end
      end
   end

   -- position in a grid and then offsetting
   local rndOffset = function(offset)
      return math.floor(math.random() * (offset*2) - offset)
   end
   local cs = 16
   for i = 1, (width/cs)-1 do
      for j = 1, (height/cs) - 1 do
	 local avg = 0
	 for ii = 1, cs do
	    for jj = 1, cs do
	       local xr = ii + (i-1) * cs
	       local yr = jj + (j-1) * cs
	       local x = grid[xr][yr][4]
	       avg = avg+x
	    end
	 end
	 avg = avg/(cs*cs)
	 if (avg > -0.05 and avg <= 0.2 and math.random() < 0.4) then
	    local pos = {x=(i*cs)+rndOffset(8) , y=(j*cs)+rndOffset(8)}
	    local h = grid[pos.x][pos.y][4]
	    if (h > 0) then  table.insert(cities,{x=pos.x, y=pos.y} ) end
	 elseif (avg > 0.1 and math.random() < 0.4) then
	    local pos = {x=(i*cs)+rndOffset(8) , y=(j*cs)+rndOffset(8)}
	    local h = grid[pos.x][pos.y][4]
	    if (h > 0) then table.insert(cities, {x=pos.x, y=pos.y}) end
	 elseif (avg > 0.2) then
	 elseif (avg < 0) then
	 end

       end
   end

   cities = {}
   return grid, cities, water_waves
end

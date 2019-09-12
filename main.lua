inspect = require "vendor.inspect"
Vector = require "vendor.brinevector"
--Pool = require "pool"
--binser = require "vendor.binser"
--luastar = require "vendor.lua-star"
bresenham = require "vendor.bresenham"

require "vehicle_pooled"

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   if key == "space" then
      perlin:load(  )
      world, cities = createWorld(worldWidth, worldHeight)
      connectCities()
   end
   
   if key == "left" then
      camera.x = camera.x - 1*charWidth
   end
   if key == "right" then
      camera.x = camera.x + 1*charWidth
   end
   if key == "up" then
      camera.y = camera.y - 1*charHeight
   end
   if key == "down" then
      camera.y = camera.y + 1*charHeight
   end
   if key == "tab" then
      followIndex = (followIndex + 1) % #boids
   end
   if key == "e" then
      isMapEditing = not isMapEditing
      startDrawRectX = -1
      startDrawRectY = -1
      endDrawRectX = -1
      endDrawRectY = -1
   end
   
   
end

function getWorldPosition(lx, ly)
   --   print(inspect(camera), world_render_scale )
end

function distance(x1,y1,x2,y2)
   local dx = x1 - x2
   local dy = y1 - y2
   return math.sqrt((dx*dx) + (dy*dy) )

end


function love.wheelmoved(x,y)

   local posx, posy = love.mouse.getPosition()
   local wx = camera.x + ( posx / world_render_scale)
   local wy = camera.y + ( posy / world_render_scale)
   
   world_render_scale =  world_render_scale * ((y>0) and 1.1 or 0.9)

   local wx2 = camera.x + ( posx / world_render_scale)
   local wy2 = camera.y + ( posy / world_render_scale)

   camera.x = camera.x + (wx-wx2)
   camera.y = camera.y + (wy-wy2)
end



function love.mousepressed(x,y)
   camera.dragging = true
   -- hittest
   local tx = (camera.x * world_render_scale ) + x
   local tx2 = math.floor(tx / (charWidth * world_render_scale)) + 1
   local ty = (camera.y*world_render_scale ) + y
   local ty2 = math.floor(ty / (charHeight*world_render_scale))+ 1
   if (not isMapEditing) then
      for i = 1, #boids do
	 local b = boids[i]
	 local d = distance(tx/world_render_scale,ty/world_render_scale, b.position.x, b.position.y)
	 if (d < 4 ) then
	    boids[i].color = randOf({colors.red, colors.yellow })
	 end
      end
      
      if (tx2> 0 and tx2 <= worldWidth) then
	 if (ty2> 0 and ty2 <= worldHeight) then
	    --	 world[tx2][ty2][3] = randInt2(34,56)
	 end
      end
   else
      startDrawRectX = tx2
      startDrawRectY = ty2
      endDrawRectX = tx2
      endDrawRectY = ty2

      --print ('init some wild stuff', startDrawRectX, startDrawRectY)
   end
end


function neighbourTileValue(x,y, dx, dy)
   return world[x+dx][y+dy]
end
function valueIsSingleLine(value)
   local singles = {179, 196,180,195,193,194, 197, 218, 191, 217, 192}
   for i = 1, #singles do
      if singles[i] == value then
   	 return true
      end
   end
   return false
end
function valueIsDoubleLine(value)
   local doubles = {186,205,185,204,202,203,206,201,187,188,200}
   for i = 1, #doubles do
      if doubles[i] == value then
   	 return true
      end
   end
   return false
end

function beSmartAboutTile(x,y)
   --print(x,y)
   if x <= 0 or y <= 0 then return end
   if x > worldWidth or y > worldHeight then return end
   if (not valueIsSingleLine(world[x][y][3])) then return end
   
   local score = 0
   if (y > 1) then
      if valueIsSingleLine(world[x][y-1][3]) then
	 score = score + 8
      end
   end
   if (y < worldHeight) then
      if valueIsSingleLine(world[x][y+1][3]) then
	 score = score + 4
      end
   end

   if x > 1 then
      if valueIsSingleLine(world[x-1][y][3]) then
	 score = score + 2
      end
   end
   if x < worldWidth then
      if valueIsSingleLine(world[x+1][y][3]) then
	 score = score + 1
      end
   end


   if score == 1 then -- x + 1
      world[x][y][3] = chars.single_horizontal
   end
   if score == 2 then -- x - 1
      world[x][y][3] = chars.single_horizontal
   end
   if score == 1 + 2 then
      world[x][y][3] = chars.single_horizontal
   end
   if score == 4 then -- y + 1
      world[x][y][3] = chars.single_vertical
   end
   if score == 4 + 1 then 
      world[x][y][3] = chars.single_up_left_corner
   end
   if score == 4 + 2 then 
      world[x][y][3] = chars.single_up_right_corner
   end
   if score == 4 + 1 + 2 then 
      world[x][y][3] = chars.single_horizontal_and_down
   end
   if score == 8 then -- y - 1
      world[x][y][3] = chars.single_vertical
   end
   if score == 8 + 1 then 
      world[x][y][3] = chars.single_low_left_corner
   end
   if score == 8 + 2 then 
      world[x][y][3] = chars.single_low_right_corner
   end
   if score == 8 + 1+ 2 then 
      world[x][y][3] = chars.single_horizontal_and_up
   end
   if score == 4 + 8 then
      world[x][y][3] = chars.single_vertical
   end
   if score == 4 + 8 + 1 then
      world[x][y][3] = chars.single_vertical_and_right
   end
   if score == 4 + 8 + 2 then
      world[x][y][3] = chars.single_vertical_and_left
   end
   if score == 1 + 2 + 4 + 8 then
      world[x][y][3] = chars.single_horizontal_and_vertical
   end

   if score > 0 then
      world[x][y][1] = colors.black
   end

   -- patching some stuff
   if (world[x][y][3] == chars.single_vertical_and_left and world[x-1][y][3] == chars.single_vertical_and_right ) then
      world[x][y][3] = chars.single_vertical
      world[x-1][y][3] = chars.single_vertical
   end
   if (world[x][y][3] == chars.single_horizontal_and_up and world[x][y-1][3] == chars.single_horizontal_and_down ) then
      world[x][y][3] = chars.single_horizontal
      world[x][y-1][3] = chars.single_horizontal
   end
   
   
   
   
end



function love.mousereleased(x,y)
   camera.dragging = false
   if isMapEditing then
      local tx = (camera.x * world_render_scale ) + x
      local tx2 = math.floor(tx / (charWidth * world_render_scale)) + 1
      local ty = (camera.y*world_render_scale ) + y
      local ty2 = math.floor(ty / (charHeight*world_render_scale))+ 1
      --print ('end doing some wild stuff, aka comit the stuff into the world baby')

      local minX = math.min(startDrawRectX, endDrawRectX)
      local minY = math.min(startDrawRectY, endDrawRectY)
      local maxX = math.max(startDrawRectX, endDrawRectX)
      local maxY = math.max(startDrawRectY, endDrawRectY)
      if (minX>0 and maxX>0 and minY>0 and maxY>0 and maxY <= worldHeight and maxX <= worldWidth) then
	 for i = minX, maxX do
	    world[i][minY][2] = colors.dark_gray
	    world[i][maxY][2] = colors.dark_gray
	    world[i][minY][3] = chars.single_horizontal
	    world[i][maxY][3] = chars.single_horizontal
	 end
	 for i = minY, maxY do
	    world[minX][i][2] = colors.dark_gray
	    world[maxX][i][2] = colors.dark_gray
	    world[minX][i][3] = chars.single_horizontal
	    world[maxX][i][3] = chars.single_horizontal
	 end
      end
      
      -- now i want to check their neighbours and make them more fitting
      for i = minX, maxX do
	 beSmartAboutTile(i, minY)
	 beSmartAboutTile(i, maxY)
      end
      for i = minY, maxY do
	 beSmartAboutTile(minX, i)
	 beSmartAboutTile(maxX, i)
      end
      
      for x = 1, worldWidth do
	 for y = 1, worldHeight do
	    beSmartAboutTile(x,y)
	 end
      end
      
      
      startDrawRectX = -1
      startDrawRectY = -1
      endDrawRectX = -1
      endDrawRectY = -1
   end
   
end
function love.mousemoved(x,y,dx,dy)
   if (not isMapEditing and camera.dragging) then
      camera.x = camera.x - dx/world_render_scale
      camera.y = camera.y - dy/world_render_scale
   end
   if isMapEditing  and camera.dragging  then
      local tx = (camera.x * world_render_scale ) + x
      local tx2 = math.floor(tx / (charWidth * world_render_scale)) + 1
      local ty = (camera.y*world_render_scale ) + y
      local ty2 = math.floor(ty / (charHeight*world_render_scale))+ 1
      --print ('doing some wild stuff', tx2, ty2)
      endDrawRectX = tx2
      endDrawRectY = ty2

   end
   
end



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
      --world[i][maxY][2] = colors.dark_gray
      --world[i][minY][3] = chars.single_horizontal
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
      end
   end
   

end


function love.load()

   --local chunk = {}
   --for i =1, 1000000 do
   --   chunk[i]= i % 66
   --end
   
   
   --local mydata = binser.serialize(chunk)
   --local mydata = binser.serialize(45, {4, 8, 12, 16}, "Hello, World!")
   --local de = binser.deserialize(mydata)
   --print(de)
   --print(inspect(de))
   --love.filesystem.write( "test.txt", mydata )
   --binser.writeFile("test,txt", "test")

   love.window.setMode(1850, 1000, {resizable=true, vsync=false})
   love.keyboard.setKeyRepeat( true )
   palette={
      {0,  0,  0,  255}, 
      {29, 43, 83, 255}, 
      {126,37, 83, 255}, 
      {0,  135,81, 255}, 
      {171,82, 54, 255}, 
      {95, 87, 79, 255}, 
      {194,195,199,255},
      {255,241,232,255},
      {255,0,  77, 255},
      {255,163,0,  255},
      {255,240,36, 255},
      {0,  231,86, 255},
      {41, 173,255,255},
      {131,118,156,255},
      {255,119,168,255}, 
      {255,204,170,255} 
   }
   for i = 1, #palette do
      palette[i] = {
	 palette[i][1]/255,
	 palette[i][2]/255,
	 palette[i][3]/255,
	 palette[i][4]/255
      }
   end
   colors = {
      black=1,  dark_blue=2,  dark_purple=3, dark_green= 4,
      brown= 5, dark_gray= 6, light_gray=7,  white=8,
      red= 9,   orange=10,    yellow=11,     green=12, 
      blue=13,  indigo=14,    pink= 15,      peach=16,
   }

   chars = {
      single_vertical = 179,
      single_horizontal = 196,
      single_vertical_and_left = 180,
      single_vertical_and_right = 195,
      single_horizontal_and_up = 193,
      single_horizontal_and_down = 194,
      single_horizontal_and_vertical = 197,
      single_up_left_corner = 218,
      single_up_right_corner = 191,
      single_low_right_corner = 217,
      single_low_left_corner = 192,

      double_vertical = 186,
      double_horizontal = 205,
      double_vertical_and_left = 185,
      double_vertical_and_right = 204,
      double_horizontal_and_up = 202,
      double_horizontal_and_down = 203,
      double_horizontal_and_vertical = 206,
      double_up_left_corner = 201,
      double_up_right_corner = 187,
      double_low_right_corner = 188,
      double_low_left_corner = 200,

      block = 219,
      block_bottom = 220,
      block_left = 221,
      block_right = 222,
      block_top = 223,

      dotted_1 = 176,
      dotted_2 = 177,
      dotted_3 = 178,

   }
   
   font = love.graphics.newImage("resources/8x8.png")
   font:setFilter('nearest', 'nearest')
   charWidth = 8
   charHeight = 8
   quads = createQuadsFromFont(font, charWidth, charHeight)
   
   worldWidth = 1024/4
   worldHeight = 1024/4
   perlin:load()
   world, cities = createWorld(worldWidth, worldHeight)
   connectCities()
   
   
   
   --print((#cities))
   --for i=1,worldWidth do
   --for j=1,worlHeight do
   
   --print(x)
   --end
   --end
   
   
   
   --world = createWorld(worldWidth, worldHeight)
   world_render_scale = 4

   camera = {x=0, y=0, dragging=false}

   time_modifier = 1-- 1/16 --/16
   boids = {}
   local amount = 100
   for i = 1, amount do
      boids[i] = Steering:new(love.math.random(charWidth*worldWidth), love.math.random(charHeight*worldHeight), vectorPool)
      boids[i].type = "prey"
      boids[i].maxspeed = (.5 + love.math.random()*.2)
      boids[i].color = randOf({colors.white, colors.black })
   end

   --followIndex = 1
   
   cars = {}
   for i = 0, 100 do
      table.insert(
	 cars,
	 {
	    x = randInt(worldWidth*charWidth),
	    y = randInt(worldHeight*charHeight),
	    rotation = love.math.random() * math.pi *2 ,
	    color = colors.yellow,
	    lightColor = colors.orange
	 }
      )
   end

   isMapEditing = false
   startDrawRectX = -1
   startDrawRectY = -1
   endDrawRectX = -1
   endDrawRectY = -1
end

function randInt(max)
   return math.floor((love.math.random() * max))+1
end

function randInt2(min, max)
   return min + math.floor(love.math.random() * (max-min))+1
end

function randOf(collection)
   local index = math.floor(love.math.random() * #collection)+1
   return collection[index]
end

function randChar(collection)
   return charCode(randOf(collection))
end

function charCode(char)
   return string.byte(char,1)
end

---
-- original code by Ken Perlin: http://mrl.nyu.edu/~perlin/noise/
local function BitAND(a,b)--Bitwise and
   local p,c=1,0
   while a>0 and b>0 do
      local ra,rb=a%2,b%2
      if ra+rb>1 then c=c+p end
      a,b,p=(a-ra)/2,(b-rb)/2,p*2
   end
   return c
end

perlin = {}
perlin.p = {}
perlin.permutation = { 151,160,137,91,90,15,
		       131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
		       190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
		       88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
		       77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
		       102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
		       135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
		       5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
		       223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
		       129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
		       251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
		       49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
		       138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}
perlin.size = 256
perlin.gx = {}
perlin.gy = {}
perlin.randMax = 256

function perlin:load(  )
   for i=1,self.size do
      self.p[i] = math.floor(love.math.random() * 256) --self.permutation[i]
      self.p[255+i] = self.p[i]
   end
end

function perlin:noise( x, y, z )
   local X = BitAND(math.floor(x), 255) + 1
   local Y = BitAND(math.floor(y), 255) + 1
   local Z = BitAND(math.floor(z), 255) + 1

   x = x - math.floor(x)
   y = y - math.floor(y)
   z = z - math.floor(z)
   local u = fade(x)
   local v = fade(y)
   local w = fade(z)
   local A  = self.p[X]+Y
   local AA = self.p[A]+Z
   local AB = self.p[A+1]+Z
   local B  = self.p[X+1]+Y
   local BA = self.p[B]+Z
   local BB = self.p[B+1]+Z

   return lerp(w, lerp(v, lerp(u, grad(self.p[AA  ], x  , y  , z  ),
			       grad(self.p[BA  ], x-1, y  , z  )),
		       lerp(u, grad(self.p[AB  ], x  , y-1, z  ),
			    grad(self.p[BB  ], x-1, y-1, z  ))),
	       lerp(v, lerp(u, grad(self.p[AA+1], x  , y  , z-1),
			    grad(self.p[BA+1], x-1, y  , z-1)),
		    lerp(u, grad(self.p[AB+1], x  , y-1, z-1),
			 grad(self.p[BB+1], x-1, y-1, z-1))))
end


function fade( t )
   return t * t * t * (t * (t * 6 - 15) + 10)
end

function lerp( t, a, b )
   return a + t * (b - a)
end

function grad( hash, x, y, z )
   local h = BitAND(hash, 15)
   local u = h < 8 and x or y
   local v = h < 4 and y or ((h == 12 or h == 14) and x or z)
   return ((h and 1) == 0 and u or -u) + ((h and 2) == 0 and v or -v)
end

---
-- should invetigate this seamless stuff somewehre too
-- https://gamedev.stackexchange.com/questions/23625/how-do-you-generate-tileable-perlin-noise
function createWorld(width, height)
   local grid = {}
   local cities = {}
   for i = 1, width do
      grid[i] = {}
      for j = 1, height do
	 local bg = (i==1 or i==width or j==1 or j==height ) and colors.yellow or colors.black
	 local fg = colors.dark_green
	 local char = 0 -- randChar({".", " ", " ", " ", ","})
	 local x1 = perlin:noise(i/100, j/100, 0)
	 local x2 = perlin:noise(i/10, j/10, 0)
	 local x3 = perlin:noise(i/30, j/30, 0)
	 local x = 0.6*x1 + 0.3*x3 +  0.1*x2

	 --local x4 = perlin:noise(j/100, i/100, 0)
	 --x = (x + x4 ) / 1.2
	 
	 --colors = {
	 -- black=1,  dark_blue=2,  dark_purple=3, dark_green= 4,
	 -- brown= 5, dark_gray= 6, light_gray=7,  white=8,
	 --red= 9,   orange=10,    yellow=11,     green=12, 
	 --blue=13,  indigo=14,    pink= 15,      peach=16,
	 --}
	 x = x + 0.1
	 
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
	    char = randOf( {256-9, charCode("~")}) --randChar({" ", "~"})
	    fg = randOf({colors.white, colors.dark_blue})
	 elseif x < 0.01 then
	    char = randOf( {256-9, charCode("~"), 0,0,0,0,0,0,0,0,0,0,0}) --randChar({" ", "~"})
	    fg = randOf({colors.white, colors.dark_blue})
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
	 --local x = grid[-7 + i*8][-7 + j*8][4]
	 --print(i*8, j*8)

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
	    table.insert(cities, {x=(i*cs)+rndOffset(8) , y=(j*cs)+rndOffset(8)})
	 elseif (avg > 0.1 and math.random() < 0.4) then
	    table.insert(cities, {x=(i*cs)+rndOffset(8), y=(j*cs)+rndOffset(8)})
	 elseif (avg > 0.2) then
	 elseif (avg < 0) then
	 end

       end
   end
   
   
   return grid, cities
end


function createWorldOld(width, height)
   local grid = {}
   for i = 1, width do
      grid[i] = {}
      for j = 1, height do
	 local bg = (i==1 or i==width or j==1 or j==height ) and colors.yellow or colors.black
	 local fg = colors.dark_green
	 local char = randChar({".", " ", " ", " ", ","})
	 
	 
	 if (math.random() < 0.005) then
	    -- we make a flower, you hippie
	    fg = randOf({ colors.green,  colors.green,  colors.green,  colors.green,  colors.green, colors.yellow, colors.orange, colors.peach})
	    --fg = colors.green
	    char = randChar({"+", "x", "*"})
	 end
	 if (math.random() < 0.6) then
	    bg = randOf({colors.orange, colors.light_gray})
	    fg = randOf({colors.brown, colors.peach})
	    char = randOf({chars.dotted_1, chars.dotted_2, chars.dotted_3})
	 end
	 
	 grid[i][j] = {bg,fg, char}
      end
   end

   return grid
end



function createQuadsFromFont(font, charWidth, charHeight)
   local result = {}
   local fontWidth = font:getWidth()
   local fontHeight = font:getHeight()
   for y=0, 15 do
      for x=0, 15  do
	 local i = (y * 16) + x
	 result[i] = love.graphics.newQuad(x*charWidth, y*charHeight, charWidth, charHeight,  fontWidth, fontHeight)
      end
   end
   return result
end

function drawText(str, x, y)
   for i=1, string.len(str) do
      local char = string.sub(str, i , i)
      local char_code = string.byte(char,1)
      love.graphics.draw(font, quads[char_code], ((x+i-1)*charWidth), (y*charHeight))
   end
end

function drawTextpx(str, x, y, px, py)
   for i=1, string.len(str) do
      local char = string.sub(str, i , i)
      local char_code = string.byte(char,1)
      love.graphics.draw(font, quads[char_code],px+ ((x+i-1)*charWidth),py+ (y*charHeight))
   end
end

function love.update(dt)
   for i= 1, #boids do
      local v=  boids[i]
      --local x = math.floor(v.position.x / cellsize) + 1
      --local y = math.floor(v.position.y/cellsize) + 1
      --local testAgainst = bins[math.max(1, math.min(x, w))][math.max(math.min(y, h),1)]
      --print("will check aginats", #testAgainst)
      --      if false then
      local force = Vector(0,0)
      --local separateForce = v:separate(boids, v.radius * 2)
      --force = force + 0.5*separateForce

      local steering = v:boundaries(charWidth*worldWidth, charHeight*worldHeight, 20) * 2
      steering = steering + v:wander() * 0.5
      -- steering = steering + v:followPath(path)
      steering = steering + v:separate(boids, v.radius * 2) * 0.5
      steering = steering + v:evade(boids[1]) * 0.3

      force = steering
      if force.length > v.maxforce then
   	 force.length = v.maxforce
      end
      v:applyForce(force)
      --     end
      --releaseVector(force)
      v:update(dt * time_modifier)
      --boidPositions[i] = {v.position.x, v.position.y, v.velocity.angle}
      --table.insert(positions, {v.position.x, v.position.y, v.velocity.angle})
   end
   --print(inspect(boids[1]))
   if (followIndex) then
      camera.x = boids[followIndex].position.x - (love.graphics.getWidth()/2)/world_render_scale
      camera.y = boids[followIndex].position.y  - (love.graphics.getHeight()/2)/world_render_scale
   end
end


function love.draw()
   -- world rendering
   -- this whole thing is more or less inverted....
   -- insetad i should probably start from the camera, get the tiles and draw them
   love.graphics.clear(palette[colors.dark_blue])
   love.graphics.push()
   love.graphics.scale(world_render_scale ,world_render_scale )
   --love.graphics.translate(-camera.x ,-camera.y )
   local endX =  2 + math.floor(love.graphics.getWidth() / (charWidth* world_render_scale))
   local endY = 2 + math.floor(love.graphics.getHeight() / (charHeight* world_render_scale))
   local count = 0;

   
   



   
   for x = 1, endX do
      for y = 1,endY  do
	 local xb = x+math.floor(camera.x/charWidth)
	 local yb = y+math.floor(camera.y/charHeight)
	 if (xb > 0 and yb > 0 and xb <= worldWidth and yb <= worldHeight) then
	    local tx = math.min(worldWidth, math.max(xb, 1))
	    local ty = math.min(worldHeight,math.max(yb, 1))
	    local tile = world[tx][ty]
	    --print(tx, ty)
	    local xoffset = camera.x % charWidth
	    local yoffset = camera.y % charHeight
	    love.graphics.setColor(palette[tile[1]])
	    love.graphics.draw(font, quads[219], -xoffset + (x-1)*charWidth,-yoffset +  (y-1)*charHeight)

	    love.graphics.setColor(palette[tile[2]])
	    love.graphics.draw(font, quads[tile[3]],-xoffset +  (x-1)*charWidth, -yoffset +  (y-1)*charHeight)

	    
	    


	    for ci = 1, #cities do
	       local city = cities[ci]
	       if tx == city.x and ty == city.y then
		  love.graphics.setColor(palette[colors.red])
		  love.graphics.draw(font, quads[219], -xoffset + (x-1)*charWidth,-yoffset +  (y-1)*charHeight)
		  love.graphics.setColor(palette[colors.white])
		  love.graphics.draw(font, quads[charCode('^')],-xoffset +  (x-1)*charWidth, -yoffset +  (y-1)*charHeight)
	       end
	       
	    end
	    
	    if isMapEditing and startDrawRectX >= 0 and startDrawRectY >= 0 and endDrawRectX >= 0 and endDrawRectY >= 0 then
	       if ty == startDrawRectY or ty == endDrawRectY then
		  local minX = math.min(startDrawRectX, endDrawRectX)
		  local maxX = math.max(startDrawRectX, endDrawRectX)

	    	  if tx >= minX and tx <= minX + (maxX - minX) then
	    	     love.graphics.setColor(palette[colors.pink])
	    	     love.graphics.draw(font, quads[4],-xoffset +  (x-1)*charWidth, -yoffset +  (y-1)*charHeight)
		     love.graphics.setColor(palette[tile[2]])
	    	  end
	       end
	       if tx == startDrawRectX or tx == endDrawRectX then
		  local minY = math.min(startDrawRectY, endDrawRectY)
		  local maxY = math.max(startDrawRectY, endDrawRectY)
	    	  if ty >= minY and ty <= minY + (maxY - minY) then
	    	     love.graphics.setColor(palette[colors.pink])
	    	     love.graphics.draw(font, quads[4],-xoffset +  (x-1)*charWidth, -yoffset +  (y-1)*charHeight)
		     love.graphics.setColor(palette[tile[2]])
	    	  end
	       end
	    end
	    count = count+1
	 end
      end
   end

   love.graphics.pop()

   -- -- draw guys in thi world
   love.graphics.push()
   love.graphics.scale(world_render_scale ,world_render_scale )
   love.graphics.translate(-camera.x ,-camera.y )
   
   for k,guy in pairs(boids) do
      --guy.rotation = guy.rotation + 0.001
      love.graphics.push()
      love.graphics.setColor(guy.color == colors.black and palette[colors.white] or palette[colors.black])
      love.graphics.translate(guy.position.x, guy.position.y )
      --love.graphics.rotate((guy.velocity.angle) - math.pi/2)

      love.graphics.translate(-4, -4 )
      love.graphics.draw(font, quads[219], 0,0)
      love.graphics.setColor(palette[guy.color])
      love.graphics.draw(font, quads[1], 0, 0)
      love.graphics.pop()
   end

   -- draw boids


   --draw some cars
   if false then
      for k,guy in pairs(cars) do
	 guy.rotation = guy.rotation + 0.01
	 love.graphics.push()
	 
	 love.graphics.translate(guy.x, guy.y )
	 love.graphics.rotate(guy.rotation)

	 love.graphics.translate(-(4*8)/2, -(6*8)/2 )
	 love.graphics.setColor(palette[guy.color])
	 for x=0, 3 do
	    for y = 0, 6 do
	       love.graphics.draw(font, quads[219], x*8,y*8)
	    end
	 end
	 
	 love.graphics.setColor(palette[guy.lightColor] or palette[colors.white])
	 
	 -- love.graphics.draw(font, quads[chars.dotted_2], 0, 0)
	 -- love.graphics.draw(font, quads[chars.dotted_2], 8, 0)
	 -- love.graphics.draw(font, quads[chars.dotted_2], 16, 0)
	 -- love.graphics.draw(font, quads[chars.dotted_2], 24, 0)
	 
	 love.graphics.draw(font, quads[chars.double_up_left_corner], 0, 8)
	 love.graphics.draw(font, quads[chars.double_horizontal], 8, 8)
	 love.graphics.draw(font, quads[chars.double_horizontal], 16, 8)
	 love.graphics.draw(font, quads[chars.double_up_right_corner], 24, 8)

	 love.graphics.draw(font, quads[chars.single_vertical], 0, 16)
	 love.graphics.draw(font, quads[chars.block], 8, 16)
	 love.graphics.draw(font, quads[chars.block], 16, 16)
	 love.graphics.draw(font, quads[chars.single_vertical], 24, 16)
	 
	 love.graphics.draw(font, quads[chars.double_vertical], 0, 24)
	 love.graphics.draw(font, quads[chars.block], 8,24)
	 love.graphics.draw(font, quads[chars.block], 16, 24)
	 love.graphics.draw(font, quads[chars.double_vertical], 24, 24)

	 love.graphics.draw(font, quads[chars.single_vertical], 0, 32)
	 love.graphics.draw(font, quads[chars.block], 8,32)
	 love.graphics.draw(font, quads[chars.block], 16, 32)
	 love.graphics.draw(font, quads[chars.single_vertical], 24, 32)

	 love.graphics.draw(font, quads[chars.double_low_left_corner], 0, 40)
	 love.graphics.draw(font, quads[chars.double_horizontal], 8, 40)
	 love.graphics.draw(font, quads[chars.double_horizontal], 16, 40)
	 love.graphics.draw(font, quads[chars.double_low_right_corner], 24, 40)
	 
	 love.graphics.pop()
      end
   end
   love.graphics.pop()	      


   
   -- ui rendering
   local fps = tostring(love.timer.getFPS( ))
   love.graphics.push()
   love.graphics.scale(2,2 )
   love.graphics.setColor(palette[colors.black])
   drawText(fps.." "..count,1, 1)
   love.graphics.setColor(palette[colors.white])
   drawTextpx(fps.." "..count,1, 1,-1,-1)
   if isMapEditing ==  true then
      love.graphics.setColor(palette[colors.black])
      drawText("EDIT",1, 2)
      love.graphics.setColor(palette[colors.white])
      drawTextpx("EDIT",1, 2,-1,-1)
      
   end
   
   love.graphics.pop()

end



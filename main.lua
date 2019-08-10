inspect = require "vendor.inspect"
Vector = require "vendor.brinevector"
require "vehicle"

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
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
end
function love.wheelmoved(x,y)
   world_render_scale =  world_render_scale * ((y>0) and 1.1 or 1.0/1.1)
end
function love.mousepressed(x,y)
   camera.dragging = true
  
   -- hittest
   local tx = (camera.x*world_render_scale ) + x
   local tx2 = math.floor(tx / (charWidth*world_render_scale)) + 1
   local ty = (camera.y*world_render_scale ) + y
   local ty2 = math.floor(ty / (charHeight*world_render_scale))+ 1
   print(tx2, ty2)
   if (tx2> 0 and tx2 <= worldWidth) then
      if (ty2> 0 and ty2 <= worldHeight) then
	 
	 world[tx2][ty2][3] = randInt2(34,56)
      end
   end
   
end
function love.mousereleased(x,y)
   camera.dragging = false
end
function love.mousemoved(x,y,dx,dy)
   if (camera.dragging) then
      camera.x = camera.x - dx/world_render_scale
      camera.y = camera.y - dy/world_render_scale
   end
end

function love.load()
   love.window.setMode(1024, 1024, {resizable=true, vsync=false})
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
   worldWidth = 320
   worldHeight = 320
   
   world = createWorld(worldWidth, worldHeight)
   world_render_scale = 4

   camera = {x=0, y=0, dragging=false}

   
   guys = {
      {x=100, y=100, rotation=math.pi/3},
      {x=140, y=100, rotation=-math.pi/3}
   }
   boids = {}
   --for i = 1, 1200 do
      --boids[i] = Steering:new(love.math.random(w), love.math.random(h))
      --boids[i].type = "prey"
      --boids[1].maxspeed = 10
      --boids[1].maxforce = 1
   --end

   thread = love.thread.newThread( 'boids-thread.lua' )
   local boidCount = 200
   thread:start(charWidth, charHeight, worldWidth, worldHeight, boidCount)
   channel 	= {};
   channel.boids2Main	= love.thread.getChannel ( "boids2Main" ); 
   channel.main2Boids	= love.thread.getChannel ( "main2Boids" );
   
   cars = {
   }

  boidPositions = {}
   -- for i = 1, boidCount do
   --    table.insert(boidPositions, {randInt(worldWidth*charWidth),randInt(worldHeight*charHeight)})
   -- end
   
   -- for i = 0, 100 do
   --    table.insert(cars, {x = randInt(worldWidth*charWidth),
   -- 			  y=randInt(worldHeight*charHeight),
   -- 			  rotation = love.math.random() * math.pi *2 ,
   -- 			  color=colors.yellow, lightColor=colors.orange})
   -- end
   
   
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




function createWorld(width, height)
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
	 local i = (y*16)+x
	 result[i] = love.graphics.newQuad(x*charWidth, y*charHeight, charWidth, charHeight,  fontWidth, fontHeight)
      end
   end
   return result;
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
  
end


function love.draw()
    local v = channel.boids2Main:pop();
    if (v) then
       
      if v[1] == 'update-positions' then
	 boidPositions = v[2]
      end
   end
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
	    local xoffset = camera.x % charWidth
	    local yoffset = camera.y % charHeight
	    
	    --if (tile[3] > 0 ) then
	    love.graphics.setColor(palette[tile[1]])
	    love.graphics.draw(font, quads[219], -xoffset + (x-1)*charWidth,-yoffset +  (y-1)*charHeight)
	    love.graphics.setColor(palette[tile[2]])
	    love.graphics.draw(font, quads[tile[3]],-xoffset +  (x-1)*charWidth, -yoffset +  (y-1)*charHeight)
	    --end
	    count = count+1
	 --else
	 --   print("not rendering something")
	 end
	 
	 --end
      end
   end
   love.graphics.pop()

   -- -- draw guys in thi world
   love.graphics.push()
   love.graphics.scale(world_render_scale ,world_render_scale )
   love.graphics.translate(-camera.x ,-camera.y )
   for k,guy in pairs(guys) do
      guy.rotation = guy.rotation + 0.001
      love.graphics.push()
      love.graphics.setColor(palette[colors.black])
      love.graphics.translate(guy.x, guy.y )
      love.graphics.rotate(guy.rotation)

      love.graphics.translate(-4, -4 )
      love.graphics.draw(font, quads[219], 0,0)
      love.graphics.setColor(palette[colors.red])
      love.graphics.draw(font, quads[2], 0, 0)
      love.graphics.pop()
   end

   for k,guy in pairs(boidPositions) do
      --guy.rotation = guy.rotation + 0.001
      love.graphics.push()
      love.graphics.setColor(palette[colors.black])
      love.graphics.translate(guy[1], guy[2] )
      --print(guy[3])
      love.graphics.rotate((guy[3] or 0) - math.pi/2)

      love.graphics.translate(-4, -4 )
      love.graphics.draw(font, quads[219], 0,0)
      love.graphics.setColor(palette[colors.red])
      love.graphics.draw(font, quads[2], 0, 0)
      love.graphics.pop()
   end
   -- draw boids


   --draw some cars
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
   
   love.graphics.pop()	      


   
   -- ui rendering
   local fps = tostring(love.timer.getFPS( ))
   love.graphics.push()
   love.graphics.scale(2,2 )
   love.graphics.setColor(palette[colors.black])
   drawText(fps.." "..count,1, 1)
   love.graphics.setColor(palette[colors.white])
   drawTextpx(fps.." "..count,1, 1,-1,-1)
   love.graphics.pop()

end



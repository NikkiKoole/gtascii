inspect = require "inspect"

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
   if (tx2> 0 and tx2 <= worldWidth) then
      if (ty2> 0 and ty2 <= worldHeight) then
	 --world[tx2][ty2][3] = randInt2(34,56)
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
   love.window.setMode(800, 600, {resizable=true, vsync=false})
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

   font = love.graphics.newImage("8x8.png")
   font:setFilter('nearest', 'nearest')
   charWidth = 8
   charHeight = 8
   quads = createQuadsFromFont(font, charWidth, charHeight)
   worldWidth = 512
   worldHeight = 256
   
   world = createWorld(worldWidth, worldHeight)
   world_render_scale = 2

   camera = {x=0, y=0, dragging=false}
   
end

function randInt(max)
   return math.floor((love.math.random() * max))+1
end
function randInt2(min, max)
   return min + math.floor(love.math.random() * (max-min))+1
end

function createWorld(width, height)
   local grid = {}
   for i = 1, width do
      grid[i] = {}
      for j = 1, height do
	 local char = math.random() < 0.3 and randInt2(23,46) or 0
	 grid[i][j] = {randInt(16),randInt(16), char } -- Fill the values here
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

function love.draw()

   -- world rendering
   
   love.graphics.push()
   love.graphics.scale(world_render_scale ,world_render_scale )
   love.graphics.clear(palette[colors.dark_blue])

   local width_in_tiles = 2 + math.floor(love.graphics.getWidth() / (charWidth* world_render_scale))
   local height_in_tiles =2 + math.floor(love.graphics.getHeight() / (charHeight* world_render_scale))
  
   for x = 1, math.min(worldWidth, width_in_tiles) do
      for y = 1, math.min(worldHeight, height_in_tiles) do
	 local tile = world[math.min(worldWidth, math.max(x+math.floor(camera.x/charWidth), 1))][math.min(worldHeight,math.max(y+math.floor(camera.y/charHeight), 1))] -- here i want to fetch another tile

	 local xoffset = camera.x % charWidth
	 local yoffset = camera.y % charHeight
	 if (tile[3] > 0 ) then
	    love.graphics.setColor(palette[tile[1]])
	    love.graphics.draw(font, quads[219], -xoffset + (x-1)*charWidth,-yoffset +  (y-1)*charHeight)
	    love.graphics.setColor(palette[tile[2]])
	    love.graphics.draw(font, quads[tile[3]],-xoffset +  (x-1)*charWidth, -yoffset +  (y-1)*charHeight)
	 end
      end
   end
   love.graphics.pop()

   -- ui rendering
   local fps = tostring(love.timer.getFPS( ))
   love.graphics.push()
   love.graphics.scale(2,2 )
   love.graphics.setColor(palette[colors.black])
   drawText(fps,1, 1)
   love.graphics.setColor(palette[colors.white])
   drawTextpx(fps,1, 1,-1,-1)
   love.graphics.pop()

end



inspect = require "vendor.inspect"
Vector = require "vendor.brinevector"
bresenham = require "vendor.bresenham"

require 'perlin'
require "vehicle_pooled"
require 'utils'
require 'asciigrid'
require 'worldgen'

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   if key == "space" then
      love.math.setRandomSeed(100)
      perlin:load(  )
      world, cities, water_waves = createWorld(worldWidth, worldHeight)
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

   -- figure out if i am over one of the two smaller worldviews

   sw, sh = love.graphics.getDimensions( )

   local margin = 20
   local smallSize = (sh/2)-(margin/2)*3
   local worldScale = smallSize / (worldWidth *  charWidth)

   if (x > margin and x < margin + smallSize) then
      if (y > margin and y < margin + smallSize) then
	 local cell = worldWidth*charWidth/16
	 worldViewRect = {x = math.floor(((x-margin)/worldScale)/ cell) * cell,
			  y = math.floor(((y-margin)/worldScale)/ cell) * cell}
	 love.math.setRandomSeed(100)
	 perlin:load()
	 worldZoomed = createZoomedinWorld(worldWidth, worldHeight, 8*2, worldViewRect.x*2, worldViewRect.y*2)
	 zoomedCanvas = generateOverViewCanvas(worldZoomed)
	 worldZoomedComplete =  createZoomedinWorld(worldWidth, worldHeight, 8*8*2, worldViewRect.x * 8*2 + worldCompleteRect.x , worldViewRect.y * 8*2 + worldCompleteRect.y )
	 worldCompleteCanvas = generateOverViewCanvas(worldZoomedComplete)
      end
      if (y >  smallSize + (margin*2) and y <  smallSize + (margin*2) + smallSize) then
	 local cell = worldWidth*charWidth/8
	 worldCompleteRect = {x = math.floor(((x-margin)/worldScale)/ cell) * cell,
			       y = math.floor(((y-( smallSize + (margin*2)))/worldScale)/ cell) * cell}
	 love.math.setRandomSeed(100)
	 perlin:load()
	 worldZoomedComplete =  createZoomedinWorld(worldWidth, worldHeight, 8*8*2, worldViewRect.x * 8*2 + worldCompleteRect.x , worldViewRect.y * 8*2 + worldCompleteRect.y )
	 worldCompleteCanvas = generateOverViewCanvas(worldZoomedComplete)
      end

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



   sw, sh = love.graphics.getDimensions( )

   local margin = 20
   local smallSize = (sh/2)-(margin/2)*3
   local worldScale = smallSize / (worldWidth *  charWidth)

   if (x > margin and x < margin + smallSize) then
      if (y > margin and y < margin + smallSize) then
	 local cell = worldWidth*charWidth/16
	 worldViewRect2 = {x = math.floor(((x-margin)/worldScale)/ cell) * cell,
			  y = math.floor(((y-margin)/worldScale)/ cell) * cell}
      end
      if (y >  smallSize + (margin*2) and y <  smallSize + (margin*2) + smallSize) then
	 local cell = worldWidth*charWidth/8
	 worldCompleteRect2 = {x = math.floor(((x-margin)/worldScale)/ cell) * cell,
			       y = math.floor(((y-( smallSize + (margin*2)))/worldScale)/ cell) * cell}

      end
   end



end

function love.load()
   love.math.setRandomSeed(100)
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

      double_tilde = 247,
      single_tilde = 126

   }

   font = love.graphics.newImage("resources/8x8.png")
   font:setFilter('nearest', 'nearest')
   charWidth = 8
   charHeight = 8
   quads = createQuadsFromFont(font, charWidth, charHeight, false)

   worldWidth = 1024/4
   worldHeight = 1024/4

   perlin:load()
   world = createZoomedinWorld(worldWidth, worldHeight,1 , 0, 0)
   --connectCities()

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
   followIndex = 0
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

   worldViewRect = {x=0, y=0}
   worldViewRect2 = {x=0, y=0}
   love.math.setRandomSeed(100)
   perlin:load()
   worldZoomed = createZoomedinWorld(worldWidth, worldHeight, 8*2, worldViewRect.x, worldViewRect.y)
   overviewCanvas = generateOverViewCanvas(world)
   zoomedCanvas = generateOverViewCanvas(worldZoomed)

   worldCompleteRect = {x=0, y=0}
   worldCompleteRect2 = {x=0, y=0}
   worldZoomedComplete =  createZoomedinWorld(worldWidth, worldHeight, 8*8*2, worldViewRect.x*8*2 +  worldCompleteRect.x, worldViewRect.y*8*2 +  worldCompleteRect.y)
   worldCompleteCanvas = generateOverViewCanvas(worldZoomedComplete)
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
      steering = steering + v:wander() * 0.2
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
   if (followIndex > 0) then
      camera.x = boids[followIndex].position.x - (love.graphics.getWidth()/2)/world_render_scale
      camera.y = boids[followIndex].position.y  - (love.graphics.getHeight()/2)/world_render_scale
   end
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


function generateOverViewCanvas(grid)
   sw, sh = love.graphics.getDimensions( )
   local margin = 20
   local smallSize = (sh/2)-(margin/2)*3
   local canvas = love.graphics.newCanvas( (worldWidth *  charWidth),  (worldWidth *  charWidth))
   love.graphics.setCanvas(canvas)
   love.graphics.push()
   local worldScale = smallSize / (worldWidth *  charWidth)
   --love.graphics.scale(worldScale , worldScale )
   for x = 1, worldWidth do
      for y = 1, worldHeight do
	 local tile = grid[x][y]
	  love.graphics.setColor(palette[tile[1]])
	  love.graphics.draw(font, quads[219], (x-1)*charWidth, (y-1)*charHeight)
	  love.graphics.setColor(palette[tile[2]])
	  love.graphics.draw(font, quads[tile[3]],(x-1)*charWidth, (y-1)*charHeight)
      end
   end

   love.graphics.pop()
   love.graphics.setCanvas()
   return canvas
end

function drawRect(color, x,y, w, h)
   love.graphics.setColor(color)
   love.graphics.rectangle("line", x, y, w, h )
   love.graphics.rectangle("line", x + 1, y + 1, -2 + w,-2+ h )
end

function love.draw()
   sw, sh = love.graphics.getDimensions( )

   local margin = 20
   local smallSize = (sh/2)-(margin/2)*3
   local bigSize =  sh - (margin*2)
   local worldScale = smallSize / (worldWidth *  charWidth)
   local bigScale = bigSize / (worldWidth *  charWidth)
   love.graphics.clear(palette[colors.dark_blue])
   --love.graphics.setColor(palette[colors.dark_gray])
   --love.graphics.rectangle("fill", margin, margin, smallSize, smallSize )
   --love.graphics.rectangle("fill", margin, smallSize + (margin*2) , smallSize, smallSize )
   --love.graphics.rectangle("fill",  smallSize + (margin*2), margin, bigSize, bigSize )

   love.graphics.push()
   love.graphics.translate( margin, margin )
   love.graphics.scale(worldScale , worldScale )
   love.graphics.setColor(palette[colors.white])
   love.graphics.draw(overviewCanvas)
   drawRect(palette[colors.white], worldViewRect.x, worldViewRect.y, (worldWidth*charWidth)/16, (worldWidth*charWidth)/16)
   drawRect(palette[colors.dark_gray], worldViewRect2.x, worldViewRect2.y, (worldWidth*charWidth)/16, (worldWidth*charWidth)/16)
   love.graphics.setColor(palette[colors.white])
   love.graphics.pop()


   love.graphics.push()
   love.graphics.translate( margin, smallSize + (margin*2) )
   love.graphics.scale(worldScale , worldScale )
   love.graphics.draw(zoomedCanvas)
   drawRect(palette[colors.white], worldCompleteRect.x, worldCompleteRect.y, (worldWidth*charWidth)/8, (worldWidth*charWidth)/8)
   drawRect(palette[colors.dark_gray], worldCompleteRect2.x, worldCompleteRect2.y, (worldWidth*charWidth)/8, (worldWidth*charWidth)/8)
   love.graphics.pop()
   print(worldCompleteRect.x, worldCompleteRect.y)
   love.graphics.push()
   love.graphics.translate(  smallSize + (margin*2), margin )
   love.graphics.scale(bigScale , bigScale )
   love.graphics.setColor(palette[colors.white])
   love.graphics.draw(worldCompleteCanvas)
   love.graphics.pop()

   -- ui rendering
   local count = 0
   local fps = tostring(love.timer.getFPS( ))
   love.graphics.push()
   love.graphics.scale(2,2 )
   love.graphics.setColor(palette[colors.black])
   drawText(fps.." "..count,0, 0)
   love.graphics.setColor(palette[colors.white])
   drawTextpx(fps.." "..count,0, 0,-1,-1)
   love.graphics.pop()
end





function love.draw2()
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

   for wi = 1, #water_waves do
      local wave = water_waves[wi]
      if (love.math.random() < 0.03) then
	  world[wave.x][wave.y][3] = randOf({chars.single_tilde, chars.double_tilde, 0, 0, 0})
	  world[wave.x][wave.y][2] = randOf({colors.white, colors.dark_blue})
      end
   end

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
      love.graphics.rotate((guy.velocity.angle) - math.pi/2)

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
   love.graphics.setColor(palette[colors.black])
   drawText(world_render_scale,1, 2)
   love.graphics.setColor(palette[colors.white])
   drawTextpx(world_render_scale,1, 2,-1,-1)

   if isMapEditing ==  true then
      love.graphics.setColor(palette[colors.black])
      drawText("EDIT",1, 2)
      love.graphics.setColor(palette[colors.white])
      drawTextpx("EDIT",1, 2,-1,-1)

   end

   love.graphics.pop()

end

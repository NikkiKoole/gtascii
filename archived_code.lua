
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

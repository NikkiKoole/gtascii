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

function getCountAround(x, y)
   if x <= 0 or y <= 0 then return end
   if x > worldWidth or y > worldHeight then return end
   if (not valueIsSingleLine(world[x][y][3])) then return end
   
   local score = 0
   if (y > 1) then
      if valueIsSingleLine(world[x][y-1][3]) then
	 score = score + 1
      end
   end
   if (y < worldHeight) then
      if valueIsSingleLine(world[x][y+1][3]) then
	 score = score + 1
      end
   end
   if x > 1 then
      if valueIsSingleLine(world[x-1][y][3]) then
	 score = score + 1
      end
   end
   if x < worldWidth then
      if valueIsSingleLine(world[x+1][y][3]) then
	 score = score + 1
      end
   end
   return score
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

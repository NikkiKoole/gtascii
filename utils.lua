
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

function createQuadsFromFont(font, charWidth, charHeight)
   local result = {}
   local fontWidth = font:getWidth()
   local fontHeight = font:getHeight()
   for y=0, 15 do
      for x=0, 15  do
	 local i = (y * 16) + x
	 result[i] = love.graphics.newQuad(x*(charWidth+1), y*(charHeight+1), charWidth+1, charHeight+1,  fontWidth, fontHeight)
      end
   end
   return result
end

function distance(x1,y1,x2,y2)
   local dx = x1 - x2
   local dy = y1 - y2
   return math.sqrt((dx*dx) + (dy*dy) )
end

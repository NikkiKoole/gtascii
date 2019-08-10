inspect = require "inspect"

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
end



function love.load()
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
   colors = {
      black=1,  dark_blue=2,  dark_purple=3, dark_green= 4,
      brown= 5, dark_gray= 6, light_gray=7,  white=8,
      red= 9,   orange=10,    yellow=11,     green=12, 
      blue=13,  indigo=14,    pink= 15,      peach=16,
   }
   for i = 1, #palette do
      palette[i] = {
	 palette[i][1]/255,
	 palette[i][2]/255,
	 palette[i][3]/255,
	 palette[i][4]/255
      }
   end
  
end

function love.draw()
   for i = 1, #palette do
      local c = palette[i]
      love.graphics.setColor(c[1],c[2],c[3])
      love.graphics.rectangle("fill", 20 + (1*30), i*20, 50, 20)
      love.graphics.setColor(palette[colors.dark_green])
      love.graphics.print("yo", 20 + (1*30), i*20 )
   end

   
end


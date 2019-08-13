require('love.timer')
require('love.math')
require('vehicle')

local inspect = require('vendor.inspect')
local now = love.timer.getTime()
local charWidth, charHeight, worldWidth, worldHeight, amount = ...
local time = 0
local boids = {}

for i = 1, amount do
   boids[i] = Steering:new(love.math.random(charWidth*worldWidth), love.math.random(charHeight*worldHeight))
   boids[i].type = "prey"
   boids[i].maxspeed = (1 + love.math.random()*2)
end

channel = {};
channel.boids2Main = love.thread.getChannel("boids2Main"); 
channel.main2Boids = love.thread.getChannel("main2Boids");


local positions = {}
local bins = {}
for i =1, #boids do
   table.insert(positions, {boids[i].position.x, boids[i].position.y})
end


--love.thread.getChannel( 'boids2Main' ):push({"init-positions", positions})
while(false) do
   
   
   local n = love.timer.getTime()
   local delta = n - now
   now = n
   time = time + delta

   bins = {}
   local w = charWidth*worldWidth/32
   local h = charHeight*worldHeight/32
   local cellsize = 32
   -- for x=0, w do
   --    local row = {}
   --    for y=0,  h do
   -- 	 table.insert(row, {})
   --    end
   --    table.insert(bins, row)
   -- end
   
   -- for i=1, #boids do
   --    local b = boids[i]
   --    local x = math.floor(b.position.x / cellsize) + 1
   --    local y = math.floor(b.position.y/cellsize) + 1
   --    table.insert(bins[math.max(1, math.min(x, w))][math.max(math.min(y, h),1)], b)
   -- end
   
   -- for i=1, #bins do
--       for j = 1, #bins[i] do
-- 	 if (#bins[i][j] > 0) then
-- --	    print(i,j, 'amount here', #bins[i][j])
-- 	 end
	 
--       end
--    end
   
   --print(inspect(bins))
   
   for i= 1, #boids do
      local v=  boids[i]
      local x = math.floor(v.position.x / cellsize) + 1
      local y = math.floor(v.position.y/cellsize) + 1
      --local testAgainst = bins[math.max(1, math.min(x, w))][math.max(math.min(y, h),1)]
      --print("will check aginats", #testAgainst)
      local force = Vector(0,0)
      --local separateForce = v:separate(boids, v.radius * 2)
      --force = force + 0.5*separateForce

      local steering = v:boundaries(charWidth*worldWidth, charHeight*worldHeight, 20) * 2
      steering = steering + v:wander() * 0.1
      -- steering = steering + v:followPath(path)
      
      --steering = steering + v:separate(boids, v.radius * 2) * 0.5
      force = steering
      --steering = steering + v:evade(boids[1]) * 0.3
      if force.length > v.maxforce then
   	 force.length = v.maxforce
      end
      v:applyForce(force )
      v:update(delta)
      
      table.insert(positions, {v.position.x, v.position.y, v.velocity.angle})
   end
  
   
   love.thread.getChannel( 'boids2Main' ):push({"update-positions", positions})
   positions = {}
   
   love.timer.sleep(0.001)
   --collectgarbage("cycle") 
  

   
end



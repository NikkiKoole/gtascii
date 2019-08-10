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
      boids[1].maxspeed = 10
      boids[1].maxforce = 1
   end

channel = {};
channel.boids2Main = love.thread.getChannel("boids2Main"); 
channel.main2Boids = love.thread.getChannel("main2Boids");


local positions = {}
for i =1, #boids do
   table.insert(positions, {boids[i].position.x, boids[i].position.y})
end

--love.thread.getChannel( 'boids2Main' ):push({"init-positions", positions})
while(true) do
   
   local n = love.timer.getTime()
   local delta = n - now
   now = n
   time = time + delta
   
   for i= 1, #boids do
      local v=  boids[i]
      local force = Vector(0,0)
      local separateForce = v:separate(boids, v.radius * 2)
      force = force + 0.5*separateForce

      local steering = v:boundaries(charWidth*worldWidth, charHeight*worldHeight, 20) * 2
      steering = steering + v:wander() * 0.1
      -- steering = steering + v:followPath(path) 
      steering = steering + v:separate(boids, v.radius * 2) * 0.5
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
   
   
end


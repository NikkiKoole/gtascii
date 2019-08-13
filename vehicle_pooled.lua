class = require 'vendor.middleclass'
Vector = require "vendor.brinevector"
Steering =  class('Steering')


function map(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end





function Steering:initialize(x, y)

   self.acceleration = Vector(0,0)
   self.velocity = Vector(0,0)
   self.position = Vector(x,y)
   self.radius = 12
   self.maxspeed = 2 + love.math.random(2)
   self.maxforce = self.maxspeed / 30
   self.pathGoalNodeIndex = 1
   self.wanderAngle = 0

   --print(pool)
end

function Steering:update(dt)
   self.velocity = self.velocity + self.acceleration
   if self.velocity.length > self.maxspeed then
      self.velocity.length = self.maxspeed
   end
   self.position = self.position + (self.velocity * dt * 32)
   self.acceleration = self.acceleration * 0
end

function Steering:applyForce(force)
   self.acceleration = self.acceleration + force
end

function Steering:seek(point)
   local desired = point - self.position
   desired.length = self.maxspeed
   return desired - self.velocity
end

function Steering:pursuit(vehicle)
   local d = (self.position - vehicle.position).length
   local updatesAhead = (d / self.maxspeed)
   local future = vehicle.position + vehicle.velocity * updatesAhead
   return self:seek(future)
end

function Steering:flee(point)
   local desired = self.position - point
   desired.length = self.maxspeed
   return desired - self.velocity
end

function Steering:evade(vehicle)
   local d = (vehicle.position - self.position).length
   local updatesAhead = (d / self.maxspeed)
   local future = vehicle.position + vehicle.velocity * updatesAhead
   return self:flee(future)
end

function Steering:arrive(point, radius)
   local desired = point - self.position
   local d = desired.length

   if (d < radius) then
      local m = map(d, 0, 100, 0, self.maxspeed)
      desired.length = m
   else
      desired.length = self.maxspeed
   end

   return desired - self.velocity
end

function Steering:isOnLeaderSight(leader, leaderAhead)
   local LEADER_SIGHT_RADIUS = 100
   local d1 = (leaderAhead - self.position).length
   local d2 = (leader.position - self.position).length
   local result = (d1 <= LEADER_SIGHT_RADIUS or d2 <= LEADER_SIGHT_RADIUS)
   return result
end

function Steering:follow(vehicle)
   -- follows a leader and tries to say out of its way 
   local LEADER_BEHIND_DIST = 0
   local tv = vehicle.velocity
   local force = Vector(0,0)

   tv = tv:getNormalized(tv)
   tv = tv * LEADER_BEHIND_DIST
   local ahead = vehicle.position + tv
   tv = tv * -1
   local behind = vehicle.position + tv
   
   if self:isOnLeaderSight(vehicle, ahead) then
      force = force + self:evade(vehicle)*1.5
   end
   
   force = force + self:arrive(behind, 50)
   return force
end

function lineIntersectsCircle(ahead, ahead2 , obstacle )
    local d1 = (Vector(obstacle.x, obstacle.y) - ahead).length
    local d2 = (Vector(obstacle.x, obstacle.y) - ahead2).length
    return d1 <= obstacle.radius or d2 <= obstacle.radius
end

function Steering:findMostThreateningObstacle(ahead, ahead2, obstacles)
   local result = nil

   for i=1, #obstacles do
      local o = obstacles[i]
      local collision = lineIntersectsCircle(ahead, ahead2, o)
      local inside = (Vector(o.x, o.y) - self.position).length < (o.radius + self.radius)
      
      if inside or (collision and (result == null or  (Vector(o.x, o.y) - self.position).length  <  (self.position - Vector(result.x, result.y)).length)) then
	 result = o
      end
   end
   return result
end
   
function Steering:collisionAvoidance(obstacles)
   local MAX_AVOID_FORCE = 10
   
   local nv = self.velocity:getNormalized(self.velocity)
   local dynamic_length = self.velocity.length / (self.maxspeed)
   local ahead = self.position + (nv * dynamic_length * 10)
   local ahead2 = ahead * 0.5
   local mostThreatening = self:findMostThreateningObstacle(ahead, ahead2, obstacles)
   local avoidance = Vector(0,0)
   
   if mostThreatening then
      avoidance.x = ahead.x - mostThreatening.x
      avoidance.y = ahead.y - mostThreatening.y
      avoidance = avoidance:getNormalized(avoidance)
      avoidance = avoidance * MAX_AVOID_FORCE
   end
   return avoidance
end

function Steering:getNeighborAhead(vehicles, exclude)
   local MAX_QUEUE_AHEAD = self.radius * 1
   local MAX_QUEUE_RADIUS = self.radius * 1.5
   local result = nil
   local qa = self.velocity.copy
   qa = qa:getNormalized(qa)
   qa = qa * MAX_QUEUE_AHEAD 

   local ahead = self.position + qa
   
   for i=1, #vehicles do
      local n = vehicles[i]
      local d = (ahead - n.position).length
      if ( n ~= exclude and n ~= self and d <= MAX_QUEUE_RADIUS) then
	 result = n
	 break
      end
   end
   return result
end

function Steering:wander()
   local CIRCLE_DISTANCE = self.radius * 2
   local CIRCLE_RADIUS = self.radius
   local ANGLE_CHANGE = 0.6
   
   local circleCenter = self.velocity.copy
   circleCenter = circleCenter:getNormalized(circleCenter)
   circleCenter = circleCenter * CIRCLE_DISTANCE
   local displacement = Vector(0, -1)
   displacement = displacement * CIRCLE_RADIUS

   displacement.angle = self.wanderAngle

   self.wanderAngle = self.wanderAngle + (love.math.random() * ANGLE_CHANGE - ANGLE_CHANGE * 0.5)

   local wanderForce = circleCenter + displacement
   return wanderForce
end


function Steering:queue(vehicles, exclude, steering)
   local MAX_QUEUE_RADIUS = self.radius * 1.5
   local brake = Vector(0,0)
   local v = self.velocity.copy
   local neighbour = self:getNeighborAhead(vehicles, exclude)

   if neighbour ~= nil  then
      brake.x = -steering.x * 0.99
      brake.y = -steering.y * 0.99
      v = v * -1
      brake = brake + v
      brake = brake + self:separate(vehicles,  MAX_QUEUE_RADIUS)
      if ((self.position - neighbour.position).length <= MAX_QUEUE_RADIUS) then
	 self.velocity = self.velocity * 0.99
      end
   end

   return brake
end


function Steering:boundaries(width, height, d)
   local desired = nil
   local maxspeed = self.maxspeed
   local velocity = self.velocity
   local position = self.position
   local result = Vector(0,0)
   
   if position.x < d then
      desired = Vector(maxspeed, velocity.y)
   elseif position.x > width - d then
      desired = Vector(-maxspeed, velocity.y)
   end

   if position.y < d then
      desired = Vector(velocity.x, maxspeed)
   elseif self.position.y > height - d then
      desired = Vector(velocity.x, -maxspeed)
   end

   if desired then
      desired.length = maxspeed
      result = desired - velocity
   end
   return result
end


function Steering:separate(vehicles, desiredSeparation)
   local dsm =  desiredSeparation*desiredSeparation
   local sum = Vector(0,0)
   local result = Vector(0,0)
   
   --print(inspect(sum), inspect(result))
   local count = 0

   for i=1, #vehicles do
      local other = vehicles[i]
      local d = (self.position - other.position).length2
      if ((d > 0) and (d < dsm)) then
      	 local diff = self.position - other.position
      	 diff = diff:getNormalized(diff)
      	 diff = diff / d
      	 sum = sum + diff
      	 count = count + 1
      end
   end
   
   if count > 0 then
      sum = sum / count
      sum.length = self.maxspeed
      result = sum - self.velocity
   end
   
   return result
end



function Steering:followPath(path)
   local target = Vector(0,0)
   if path and self.pathGoalNodeIndex ~= nil then
      target = Vector(path.points[(self.pathGoalNodeIndex)*2-1],
		      path.points[(self.pathGoalNodeIndex)*2])
      local d = (target - self.position).length
      if d < path.radius then
	 self.pathGoalNodeIndex = self.pathGoalNodeIndex + 1

	 -- loop around path
	 if self.pathGoalNodeIndex > (#path.points)/2 then
	    self.pathGoalNodeIndex = 1
	 end
      end
   end

   return self:seek(target)
      
end


function Steering:draw()
   if self.type == 'hunter' then
      love.graphics.setColor(0.7,0,0)
   elseif self.type == 'prey' then
      love.graphics.setColor(0,0.7,0)
   else
      love.graphics.setColor(0.5,0.5,0.5)
   end
   
   
   love.graphics.circle("fill", self.position.x, self.position.y, self.radius)
   --love.graphics.setColor(.6,.7,.7, 1)

   local a = {x=self.position.x, y= self.position.y}


   -- local r = self.velocity.angle + math.pi/2
   -- local d = self.radius
   -- local t1x, t1y = a.x+math.cos(r + 0) * d, a.y+math.sin(r + 0) * d
   -- local t2x, t2y = a.x+math.cos(r - math.pi/2) * d, a.y+math.sin(r - math.pi/2) * d
   -- local t3x, t3y = a.x+math.cos(r - math.pi) * d, a.y+math.sin(r - math.pi ) * d
   
   -- local vertices = {t1x, t1y,
   -- 		     t2x, t2y,
   -- 		     t3x,t3y}
   -- love.graphics.polygon('fill', vertices)

   
   love.graphics.push()
   love.graphics.translate(a.x, a.y)
   
   love.graphics.rotate(self.velocity.angle - math.pi/2)
   love.graphics.scale(2,2)
   -- draw a body below?
   
   love.graphics.setColor(1,1,1, 1)
   love.graphics.draw(font, quads[2],-4, -4)
   love.graphics.pop()
   
end

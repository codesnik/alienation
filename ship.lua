Ship = {
  x = 0, y = 0, dx = 0, dy = 0, tilt = 0, radius = ShipRadius, life = MaxLife,
  laser_power = 0, laser_charge = 0,
  r = 1, g = 1, b = 1
}

function Ship:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end

-- distance of ship s1 from laser of s2
-- uses equal-sided triangle instead of right triangle.
-- not ideal when very close from s1 to s2
local function get_distance_from_laser(s1, s2)
  local ship_dist = math.sqrt((s1.x - s2.x)^2 + (s1.y - s2.y)^2)
  local projection_x = s2.x + ship_dist * math.cos(s2.angle)
  local projection_y = s2.y + ship_dist * math.sin(s2.angle)
  return math.sqrt((s1.x - projection_x)^2 + (s1.y - projection_y)^2)
end

local function get_angle(x, y)
  if x == 0 and y == 0 then
    return nil
  elseif x < 0 and y == 0 then
    return math.pi
  else
    return 2 * math.atan(y / (x + math.sqrt(x^2 + y^2)))
  end
end

-- up to 10 lasers simultaneously. Plays the first laser and puts it at the end of the array
local function play_laser(power)
  local laser = table.remove(Lasers, 1)
  laser:stop()
  laser:setPitch(1 + math.random()*0.3 - power/MaxCharge*0.6)
  laser:setVolume(0.7 + power/MaxCharge*0.3)
  laser:play()
  table.insert(Lasers, laser)
end

local function play_crash()
  Crash:stop()
  Crash:setPitch(1 + math.random()*0.2)
  Crash:play()
end

function Ship:damage(_dt, damage)
  self.life = math.max(0, self.life - damage)
  self.tilt = self.tilt + (math.random() - 0.5)*damage * 0.5
  for _=1, math.max(damage*5, 2) do
    table.insert(Game.debris, {
      self.x, self.y, math.random(), math.random(), math.random(), 1, {
        dx = self.dx + (math.random() - 0.5)*(5 + damage*5),
        dy = self.dy + (math.random() - 0.5)*(5 + damage*5),
      }
    })
  end
end

  -- inflict damage on s1 from laser
function Ship:update_laser_damage(dt, s1)
  if self.laser_power == 0 or not self.angle then return end
  if get_distance_from_laser(s1, self) < s1.radius + 5 * self.laser_power/MaxCharge then
    s1:damage(dt, self.laser_power * dt * LaserDamage)
  end
end

function Ship:up(dt)
  self.dy = self.dy - dt * Acceleration
end

function Ship:down(dt)
  self.dy = self.dy + dt * Acceleration
end

function Ship:left(dt)
  self.dx = self.dx - dt * Acceleration
  self.tilt = math.max(self.tilt - dt * TiltSpeed, -MaxTilt)
end

function Ship:right(dt)
  self.dx = self.dx + dt * Acceleration
  self.tilt = math.min(self.tilt + dt * TiltSpeed, MaxTilt)
end

function Ship:idle(dt)
  if math.abs(self.tilt) < dt * TiltSpeed then
    self.tilt = 0
  elseif self.tilt ~= 0 then
    self.tilt = self.tilt - self.tilt / math.abs(self.tilt) * dt * TiltSpeed
  end
end

function Ship:move(dt)
  self.x = self.x + self.dx
  self.y = self.y + self.dy
  if self.x < 0 then
    self.x = -self.x
    self:damage(dt, math.abs(self.dx) * CollisionDamage)
    play_crash()
    self.dx = -self.dx
  end
  if self.y < 0 then
    self.y = -self.y
    self:damage(dt, math.abs(self.dy) * CollisionDamage)
    play_crash()
    self.dy = -self.dy
  end
  if self.x > Width then
    self.x = Width - (self.x - Width) * Damping
    self:damage(dt, math.abs(self.dx) * CollisionDamage)
    play_crash()
    self.dx = -self.dx * Damping
  end
  if self.y > Height then
    self.y = Height - (self.y - Height) * Damping
    self:damage(dt, math.abs(self.dy) * CollisionDamage)
    play_crash()
    self.dy = -self.dy * Damping
  end
  self.angle = get_angle(self.dx, self.dy)
end

function Ship:tumble(dt)
  self:damage(dt, 0.01)
  self.tilt = self.tilt + (self.dx) * dt * 2
end

function Ship:fade_laser(dt)
  self.laser_power = self.laser_power - dt * LaserDamping
  if self.laser_power < 0 then
    self.laser_power = 0
  end
end

function Ship:release(dt)
  if self.laser_charge > MinSuperCharge then
    self.laser_power = self.laser_charge
    self.laser_charge = 0
    play_laser(self.laser_power)
  else
    self.laser_charge = 0
  end
end

function Ship:charge(dt)
  if self.laser_charge == 0 then
    self.laser_power = MinPower
    play_laser(self.laser_power)
  end
  self.laser_charge = math.min(MaxCharge, self.laser_charge + dt * ChargeSpeed)
end

function Ship:check_collision(dt, s2)
  local dist = math.sqrt((self.x - s2.x)^2 + (self.y - s2.y)^2)
  -- already close and getting even closer?
  if dist < self.radius + s2.radius and dist > math.sqrt((self.x + self.dx - s2.x - s2.dx)^2 + (self.y + self.dy - s2.y - s2.dy)^2) then
    local boop_speed = math.sqrt((self.dx - s2.dx)^2 + (self.dy - s2.dy)^2)
    self:damage(dt, boop_speed * CollisionDamage)
    s2:damage(dt, boop_speed * CollisionDamage)
    self.dx, s2.dx = s2.dx * (Damping^0.5), self.dx * (Damping^0.5)
    self.dy, s2.dy = s2.dy * (Damping^0.5), self.dy * (Damping^0.5)
    play_crash()
  end
end

local function is_down_any(keys)
  for _, key in ipairs(keys) do
    if love.keyboard.isDown(key) then return true end
  end
  return false
end

function Ship:control(dt, mapping)
  if self.life == 0 then
    self:tumble(dt)
  else
    if is_down_any(mapping.up) then
      self:up(dt)
    elseif is_down_any(mapping.down) then
      self:down(dt)
    end

    if is_down_any(mapping.left) then
      self:left(dt)
    elseif is_down_any(mapping.right) then
      self:right(dt)
    else
      self:idle(dt)
    end

    if is_down_any(mapping.fire) then
      self:charge(dt)
    else
      self:release(dt)
    end
  end
end

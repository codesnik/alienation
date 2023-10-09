StarsDx = 0
StarsDy = 0.1
MaxTilt = 0.7
TiltSpeed = 3
Acceleration = 5
Damping = 0.2
LaserDamping = 35
MinPower = 3
MaxCharge = 10
MinSuperCharge = 3
ChargeSpeed = 5
MaxLife = 100
ShipRadius = 8
LaserDamage = 10
CollisionDamage = 1
GloatTime = 5

Keys1 = { up = {'up'}, down = {'down'}, left = {'left'}, right = {'right'}, fire = {'space', ','}}
Keys2 = { up = {'w'}, down = {'s'}, left = {'a'}, right = {'d'}, fire = {'tab', '`'}}

require 'ship'

Game = {
  mode = 'menu',
  gloat = 0,
  stars = {},
  debris = {}
}

function Game.restart()
  Game.mode = 'game'
  Game.gloat = 0
  Game.ships = {
    Ship:new{ x = Width/2 - 100, y = Height/2, r = 1, g = 0, b = 0 },
    Ship:new{ x = Width/2 + 100, y = Height/2, r = 0, g = 0, b = 1 }
  }
end

function Game.menu()
  Game.mode = 'menu'
  Game.debris = {}
end

function love.load()
    love.mouse.setVisible(false)
    love.window.setFullscreen(true)
    Width, Height = love.graphics.getDimensions()

    Game.stars = {}
    for i=1, 200 do
       Game.stars[i] = {
         math.random(0, Width-1),  -- x
         math.random(0, Height-1), -- y
         math.random(), -- r
         math.random(), -- g
         math.random(), -- b
         math.random(), -- a
         math.random(0, 2) * 2 - 1, -- 1/-1, direction of blinking
       }
    end

    local laser = love.audio.newSource('sounds/laser.mp3', 'static')
    local bg = love.audio.newSource('sounds/bg.wav', 'static')
    Crash = love.audio.newSource('sounds/crash.mp3', 'static')
    bg:setLooping(true)
    bg:play()
    Lasers = {}
    for i=1, 5 do
      Lasers[i] = laser:clone()
    end

    Game.menu()
end

function love.update(dt)


  local function update_stars()
    for _, star in ipairs(Game.stars) do
      -- blink stars
      star[6] = star[6] + star[7] * 0.01
      if star[6] < 0 then
        star[6] = 0
        star[7] = 1
      end
      if star[6] > 1 then
        star[6] = 1
        star[7] = -1
      end
      -- move starfield
      star[1] = (star[1] + Width + StarsDx) % Width
      star[2] = (star[2] + Height + StarsDy) % Height
    end
  end

  local function update_debris()
    for i, dot in ipairs(Game.debris) do
      dot[1] = dot[1] + dot[7].dx
      dot[2] = dot[2] + dot[7].dy
      dot[6] = dot[6] - 2 * dt -- fade out
      if dot[6] <= 0 then
        table.remove(Game.debris, i)
      end
    end
  end


  if Game.mode == 'game' then
    update_stars()
    update_debris()

    Game.ships[1]:fade_laser(dt)
    Game.ships[2]:fade_laser(dt)

    Game.ships[1]:control(dt, Keys1)
    Game.ships[2]:control(dt, Keys2)

    Game.ships[1]:move(dt)
    Game.ships[2]:move(dt)

    Game.ships[1]:update_laser_damage(dt, Game.ships[2])
    Game.ships[2]:update_laser_damage(dt, Game.ships[1])

    Game.ships[1]:check_collision(dt, Game.ships[2])

    if Game.ships[1].life == 0 or Game.ships[2].life == 0 then
      Game.gloat = Game.gloat + dt
      if Game.gloat > GloatTime then
        Game.menu()
      end
    end

  elseif Game.mode == 'menu' then
    update_stars()
    if love.keyboard.isDown('space') then
      Game.restart()
    end
  end
end

function love.draw()

  local function draw_ship(ship)
    love.graphics.push()
    local max_shake = ship.laser_charge < MinSuperCharge and 0 or 4 * ship.laser_charge / MaxCharge
    love.graphics.translate(
      ship.x + (math.random()-0.5) * max_shake,
      ship.y + (math.random()-0.5) * max_shake
    )
    love.graphics.rotate(ship.tilt)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.ellipse('fill', 0, -4, 5, 4)
    love.graphics.setColor(ship.r, ship.g, ship.b, 1)
    love.graphics.ellipse('fill', 0, 0, 10, 5)
    love.graphics.reset()
    love.graphics.pop()
  end

  local function draw_laser(ship)
    -- not firing or staying still
    if ship.laser_power < 0.1 or not(ship.angle) then
      return
    end

    local line = {
      ship.x + math.cos(ship.angle)*10,
      ship.y + math.sin(ship.angle)*10,
      ship.x + math.cos(ship.angle)*(Width+Height),
      ship.y + math.sin(ship.angle)*(Width+Height)
    }

    love.graphics.setColor(ship.r, ship.g, ship.b, 1)
    love.graphics.push()
    love.graphics.setLineWidth(3 + 10 * ship.laser_power / MaxCharge)
    love.graphics.line(unpack(line))
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(1 + 3 * ship.laser_power / MaxCharge)
    love.graphics.line(unpack(line))
    love.graphics.pop()
  end

  local function draw_stats(ship, point, direction)
    local length = 200
    love.graphics.push()
    love.graphics.setColor(ship.r, ship.g, ship.b, 1)
    love.graphics.setLineWidth(5)
    love.graphics.line(point, 30, point + ship.life / MaxLife * length * direction, 30)
    love.graphics.setLineWidth(2)
    love.graphics.line(point, 40, point + ship.laser_charge / MaxCharge * length * direction, 40)
    love.graphics.line(point, 50, point + ship.laser_power / MaxCharge * length * direction, 50)
    love.graphics.pop()
  end

  local function draw_stars()
    love.graphics.points(Game.stars)
  end

  local function draw_debris()
    love.graphics.setPointSize(2)
    love.graphics.points(Game.debris)
    love.graphics.setPointSize(1)
  end

  if Game.mode == 'game' then
    draw_stars()
    draw_debris()
    draw_stats(Game.ships[1], 30, 1)
    draw_stats(Game.ships[2], Width-30, -1)
    draw_ship(Game.ships[1])
    draw_ship(Game.ships[2])
    draw_laser(Game.ships[1])
    draw_laser(Game.ships[2])

  elseif Game.mode == 'menu' then
    draw_stars()
    local font = love.graphics.newFont(100)
    love.graphics.setColor(0.5, 1, 0.5, 1)
    love.graphics.printf('ALIENATION', font, 0, Height/4, Width, 'center') -- , 20, 0, 0, 10, 0)
  end
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

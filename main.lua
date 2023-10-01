function love.load()
    love.mouse.setVisible(false)
    love.window.setFullscreen(true)
    -- success = love.window.setFullscreen(true, "exclusive")
    Width, Height = love.graphics.getDimensions()

    StarsDx = 0
    StarsDy = 0.1
    MaxTilt = 0.7
    TiltSpeed = 3
    PowerUp = 2
    Acceleration = 5
    Damping = 0.2
    LaserDamping = 18
    MaxCharge = 10
    MinSuperCharge = 3
    ChargeSpeed = 5
    MaxLife = 50

    Stars = {}
    for i=1, 200 do
       Stars[i] = {
         math.random(0, Width-1),  -- x
         math.random(0, Height-1), -- y
         math.random(), -- r
         math.random(), -- g
         math.random(), -- b
         math.random(), -- a
         math.random(0, 2) * 2 - 1, -- 1/-1, direction of blinking
       }
    end

    Ships = {
      {
        x = Width/2 - 100, y = Height/2, dx = 0, dy = 0, tilt = 0,
        life = MaxLife, laser = { power = 0, charge=0 },
        r = 1, g = 0, b = 0
      },
      {
        x = Width/2 + 100, y = Height/2, dx = 0, dy = 0, tilt = 0,
        life = MaxLife, laser = { power = 0, charge=0 },
        r = 0, g = 0, b = 1
      }
    }

    local laser = love.audio.newSource('sounds/laser.mp3', 'static')
    local bg = love.audio.newSource('sounds/bg.wav', 'static')
    bg:setLooping(true)
    bg:play()
    Lasers = {}
    for i=1, 5 do
      Lasers[i] = laser:clone()
    end
end

function love.update(dt)

  local function get_angle(x, y)
    if x == 0 and y == 0 then
      return nil
    elseif x < 0 and y == 0 then
      return math.pi
    else
      return 2 * math.atan(y / (x + math.sqrt(x*x + y*y)))
    end
  end

  -- up to 10 lasers simultaneously. Plays the first laser and puts it at the end of the array
  local function play_laser(power)
    local laser = table.remove(Lasers, 1)
    laser:stop()
    laser:setPitch(1 + math.random()*0.3 - power/MaxCharge*0.6)
    laser:play()
    table.insert(Lasers, laser)
  end

  local function ship_up(ship)
    ship.dy = ship.dy - dt * Acceleration
  end

  local function ship_down(ship)
    ship.dy = ship.dy + dt * Acceleration
  end

  local function ship_left(ship)
    ship.dx = ship.dx - dt * Acceleration
    ship.tilt = math.max(ship.tilt - dt * TiltSpeed, -MaxTilt)
  end

  local function ship_right(ship)
    ship.dx = ship.dx + dt * Acceleration
    ship.tilt = math.min(ship.tilt + dt * TiltSpeed, MaxTilt)
  end

  local function ship_idle(ship)
    if math.abs(ship.tilt) < dt * TiltSpeed then
      ship.tilt = 0
    elseif ship.tilt ~= 0 then
      ship.tilt = ship.tilt - ship.tilt / math.abs(ship.tilt) * dt * TiltSpeed
    end
  end

  local function ship_move(ship)
    ship.x = ship.x + ship.dx
    ship.y = ship.y + ship.dy
    if ship.x < 0 then
      ship.x = -ship.x
      ship.life = ship.life - math.abs(ship.dx)
      ship.dx = -ship.dx
    end
    if ship.y < 0 then
      ship.y = -ship.y
      ship.life = ship.life - math.abs(ship.dy)
      ship.dy = -ship.dy
    end
    if ship.x > Width then
      ship.x = Width - (ship.x - Width) * Damping
      ship.life = ship.life - math.abs(ship.dx)
      ship.dx = -ship.dx * Damping
    end
    if ship.y > Height then
      ship.y = Height - (ship.y - Height) * Damping
      ship.life = ship.life - math.abs(ship.dy)
      ship.dy = -ship.dy * Damping
    end
    ship.angle = get_angle(ship.dx, ship.dy)
  end

  local function fade_laser(ship)
    ship.laser.power = ship.laser.power - dt * LaserDamping
    if ship.laser.power < 0 then
      ship.laser.power = 0
    end
  end

  local function ship_release(ship)
    if ship.laser.charge > MinSuperCharge then
      ship.laser.power = ship.laser.charge
      ship.laser.charge = 0
      play_laser(ship.laser.power)
    else
      ship.laser.charge = 0
    end
  end

  local function ship_charge(ship)
    if ship.laser.charge == 0 then
      ship.laser.power = 1
      play_laser(ship.laser.power)
    end
    ship.laser.charge = math.min(MaxCharge, ship.laser.charge + dt * ChargeSpeed)
  end

  for i=1, #Stars do
    local star = Stars[i]
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

  fade_laser(Ships[1])
  fade_laser(Ships[2])

  if love.keyboard.isDown('up') then
    ship_up(Ships[1])
  elseif love.keyboard.isDown('down') then
    ship_down(Ships[1])
  end

  if love.keyboard.isDown('left') then
    ship_left(Ships[1])
  elseif love.keyboard.isDown('right') then
    ship_right(Ships[1])
  else
    ship_idle(Ships[1])
  end

  if love.keyboard.isDown('space') or love.keyboard.isDown(',') then
    ship_charge(Ships[1])
  else
    ship_release(Ships[1])
  end

  if love.keyboard.isDown('1') or love.keyboard.isDown('`') then
    ship_charge(Ships[2])
  else
    ship_release(Ships[2])
  end

  if love.keyboard.isDown('w') then
    ship_up(Ships[2])
  elseif love.keyboard.isDown('s') then
    ship_down(Ships[2])
  end

  if love.keyboard.isDown('a') then
    ship_left(Ships[2])
  elseif love.keyboard.isDown('d') then
    ship_right(Ships[2])
  else
    ship_idle(Ships[2])
  end

  ship_move(Ships[1])
  ship_move(Ships[2])
end

function love.draw()

  local function draw_ship(ship)
    love.graphics.push()
    love.graphics.translate(ship.x, ship.y)
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
    if ship.laser.power < 0.1 or not(ship.angle) then
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
    love.graphics.setLineWidth(3 + 10 * ship.laser.power / MaxCharge)
    love.graphics.line(unpack(line))
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(1 + 3 * ship.laser.power / MaxCharge)
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
    love.graphics.line(point, 40, point + ship.laser.charge / MaxCharge * length * direction, 40)
    love.graphics.line(point, 50, point + ship.laser.power / MaxCharge * length * direction, 50)
    love.graphics.pop()
  end

  love.graphics.origin()
  love.graphics.points(Stars)

  draw_stats(Ships[1], 30, 1)
  draw_stats(Ships[2], Width-30, -1)
  draw_ship(Ships[1])
  draw_ship(Ships[2])
  draw_laser(Ships[1])
  draw_laser(Ships[2])
end

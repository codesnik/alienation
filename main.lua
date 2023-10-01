function love.load()
    love.window.setFullscreen(true)
    -- success = love.window.setFullscreen(true, "exclusive")
    Width, Height = love.graphics.getDimensions()
    love.mouse.setVisible(false)

    Stars = {}
    for i=1, 1000 do
       Stars[i] = {
         math.random(5, Width-5),  -- x
         math.random(5, Height-5), -- y
         math.random(), -- r
         math.random(), -- g
         math.random(), -- b
         math.random(), -- a
         math.random(0, 2) * 2 - 1, -- 1/-1, direction of blinking
       }
    end

    Ships = {
      {x = Width/2 - 100, y = Height/2, dx = 0, dy = 0, tilt = 0, laser = {power = 0, phase=0}},
      {x = Width/2 + 100, y = Height/2, dx = 0, dy = 0, tilt = 0, laser = {power = 0, phase=0}}
    }

    MaxTilt = 0.7
    TiltSpeed = 3
    MaxPower = 5
    PowerUp = 2
    Acceleration = 5
    Damping = 0.2

    -- Laser1 = love.audio.newSource('sounds/laser.mp3', 'static')
    -- Laser2 = love.audio.newSource('sounds/laser.mp3', 'static')
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

  local function play_laser()
    --[[
    if Laser1:isPlaying() then
      Laser2:stop()
      Laser2:setPitch(1 + math.random()*0.5)
      Laser2:play()
    else
      Laser1:stop()
      Laser1:setPitch(1 + math.random()*0.5)
      Laser1:play()
    end
    --]]
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
      ship.dx = -ship.dx
    end
    if ship.y < 0 then
      ship.y = -ship.y
      ship.dy = -ship.dy
    end
    if ship.x > Width then
      ship.x = Width - (ship.x - Width) * Damping
      ship.dx = -ship.dx * Damping
    end
    if ship.y > Height then
      ship.y = Height - (ship.y - Height) * Damping
      ship.dy = -ship.dy * Damping
    end
    ship.angle = get_angle(ship.dx, ship.dy)
  end

  local function ship_unfire(ship)
    ship.laser.phase = 0
  end

  local function ship_fire(ship)
    if ship.laser.phase == 0 then
      ship.laser.phase = 1
      play_laser()
    -- else
      -- ship_unfire(ship)
    end
  end

  -- blink stars
  for i=1, #Stars do
    local star = Stars[i]
    star[6] = star[6] + star[7] * 0.01
    if star[6] < 0 then
      star[6] = 0
      star[7] = 1
    end
    if star[6] > 1 then
      star[6] = 1
      star[7] = -1
    end
  end

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
    ship_fire(Ships[1])
  else
    ship_unfire(Ships[1])
  end

  if love.keyboard.isDown('1') or love.keyboard.isDown('`') then
    ship_fire(Ships[2])
  else
    ship_unfire(Ships[2])
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

  local function draw_ship(ship, color)
    love.graphics.push()
    love.graphics.translate(ship.x, ship.y)
    love.graphics.rotate(ship.tilt)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.ellipse('fill', 0, -4, 5, 4)
    if color == 'red' then
      love.graphics.setColor(1, 0, 0, 1)
    elseif color == 'blue' then
      love.graphics.setColor(0, 0, 1, 1)
    end
    love.graphics.ellipse('fill', 0, 0, 10, 5)
    love.graphics.reset()
    love.graphics.pop()
  end

  local function draw_laser(ship, color)
    if ship.laser.phase == 0 or not(ship.angle) then
      return
    end

    local line = {
      ship.x + math.cos(ship.angle)*10,
      ship.y + math.sin(ship.angle)*10,
      ship.x + math.cos(ship.angle)*(Width+Height),
      ship.y + math.sin(ship.angle)*(Width+Height)
    }

    if color == 'red' then
      love.graphics.setColor(1, 0, 0)
    elseif color == 'blue' then
      love.graphics.setColor(0, 0, 1)
    end
    love.graphics.push()
    love.graphics.setLineWidth(3)
    love.graphics.line(unpack(line))
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(1)
    love.graphics.line(unpack(line))
    love.graphics.pop()
  end

  love.graphics.origin()
  love.graphics.points(Stars)
  draw_ship(Ships[1], 'red')
  draw_ship(Ships[2], 'blue')
  draw_laser(Ships[1], 'red')
  draw_laser(Ships[2], 'blue')
end


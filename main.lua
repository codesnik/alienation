function love.load()
    love.window.setFullscreen(true)
    -- success = love.window.setFullscreen(true, "exclusive")
    Width, Height = love.graphics.getDimensions()
    local max_stars = 1000  -- how many stars we want

    Stars = {}   -- table which will hold our stars

    for i=1, max_stars do   -- generate the coords of our stars
       local x = math.random(5, Width-5)   -- generate a "random" number for the x coord of this star
       local y = math.random(5, Height-5)   -- both coords are limited to the screen size, minus 5 pixels of padding
       local r = math.random()
       local g = math.random()
       local b = math.random()
       local a = math.random()
       Stars[i] = {x, y, r, g, b, a, math.random(0, 2) * 2 - 1}   -- stick the values into the table
    end

    Ships = {
        {x=Width/2 - 100, y=Height/2, dx=0, dy=0, tilt=0},
        {x=Width/2 + 100, y=Height/2, dx=0, dy=0, tilt=0}
    }

    MaxTilt = 0.7
    TiltSpeed = 3
    Acceleration = 2
    Damping = 0.3
end

function love.update(dt)

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
    love.graphics.ellipse('fill', 0, -4, 5, 4)
    if color == 'red' then
      love.graphics.setColor(1, 0, 0)
    elseif color == 'blue' then
      love.graphics.setColor(0, 0, 1)
    end
    love.graphics.ellipse('fill', 0, 0, 10, 5)
    love.graphics.reset()
    love.graphics.pop()
  end
  love.graphics.origin()
  love.graphics.points(Stars)
  draw_ship(Ships[1], 'red')
  draw_ship(Ships[2], 'blue')
end


function love.load()
    Width, Height = love.graphics.getDimensions()
    -- success = love.window.setFullscreen(true, "exclusive")
    local max_stars = 100   -- how many stars we want

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
end

function love.update(dt)
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
    Ships[1].dy = Ships[1].dy - dt
  elseif love.keyboard.isDown('down') then
    Ships[1].dy = Ships[1].dy + dt
  end

  if love.keyboard.isDown('left') then
    Ships[1].dx = Ships[1].dx - dt
    Ships[1].tilt = math.max(Ships[1].tilt - dt * TiltSpeed, -MaxTilt)
  elseif love.keyboard.isDown('right') then
    Ships[1].dx = Ships[1].dx + dt
    Ships[1].tilt = math.min(Ships[1].tilt + dt * TiltSpeed, MaxTilt)
  else
    if math.abs(Ships[1].tilt) < dt * TiltSpeed then
      Ships[1].tilt = 0
    elseif Ships[1].tilt ~= 0 then
      Ships[1].tilt = Ships[1].tilt - Ships[1].tilt / math.abs(Ships[1].tilt) * dt * TiltSpeed
    end
  end

  Ships[1].x = Ships[1].x + Ships[1].dx
  Ships[1].y = Ships[1].y + Ships[1].dy
  Ships[2].x = Ships[2].x + Ships[2].dx
  Ships[2].y = Ships[2].y + Ships[2].dy

end

function love.draw()
    love.graphics.origin()
    love.graphics.points(Stars)
    draw_ship(Ships[1], 'red')
    draw_ship(Ships[2], 'blue')
end

function draw_ship(ship, color)
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

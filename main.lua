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
end

function love.update(_dt)
  -- blink stars
  for i=1, #Stars do
    Stars[i][6] = Stars[i][6] + Stars[i][7] * 0.01
    if Stars[i][6] < 0 then
      Stars[i][6] = 0
      Stars[i][7] = 1
    end
    if Stars[i][6] > 1 then
      Stars[i][6] = 1
      Stars[i][7] = -1
    end
  end
end

function love.draw()
    love.graphics.origin()
    love.graphics.points(Stars)
end

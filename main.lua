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

local game = {
  mode = 'menu',
  gloat = 0,
  stars = {},
  debris = {}
}

function game.restart()
  game.mode = 'game'
  game.gloat = 0
  game.ships = {
    {
      x = Width/2 - 100, y = Height/2, dx = 0, dy = 0, tilt = 0, radius = ShipRadius,
      life = MaxLife, laser = { power = 0, charge=0 },
      r = 1, g = 0, b = 0
    },
    {
      x = Width/2 + 100, y = Height/2, dx = 0, dy = 0, tilt = 0, radius = ShipRadius,
      life = MaxLife, laser = { power = 0, charge=0 },
      r = 0, g = 0, b = 1
    }
  }
end

function game.menu()
  game.mode = 'menu'
  game.debris = {}
end

function love.load()
    love.mouse.setVisible(false)
    love.window.setFullscreen(true)
    Width, Height = love.graphics.getDimensions()

    game.stars = {}
    for i=1, 200 do
       game.stars[i] = {
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

    game.menu()
end

function love.update(dt)

  local function ship_damage(ship, damage)
    ship.life = math.max(0, ship.life - damage)
    ship.tilt = ship.tilt + (math.random() - 0.5)*damage * 0.5
    for _=1, math.max(damage*5, 2) do
      table.insert(game.debris, {
        ship.x, ship.y, math.random(), math.random(), math.random(), 1, {
          dx = ship.dx + (math.random() - 0.5)*(5 + damage*5),
          dy = ship.dy + (math.random() - 0.5)*(5 + damage*5),
        }
      })
    end
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

  -- distance of ship s1 from laser of s2
  -- uses equal-sided triangle instead of right triangle.
  -- not ideal when very close from s1 to s2
  local function get_distance_from_laser(s1, s2)
    local ship_dist = math.sqrt((s1.x - s2.x)^2 + (s1.y - s2.y)^2)
    local projection_x = s2.x + ship_dist * math.cos(s2.angle)
    local projection_y = s2.y + ship_dist * math.sin(s2.angle)
    return math.sqrt((s1.x - projection_x)^2 + (s1.y - projection_y)^2)
  end

  -- inflict damage on s1 from laser of s2
  local function update_laser_damage(s1, s2)
    if s2.laser.power == 0 or not s2.angle then return end
    if get_distance_from_laser(s1, s2) < s1.radius + 5 * s2.laser.power/MaxCharge then
      ship_damage(s1, s2.laser.power * dt * LaserDamage)
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
      ship_damage(ship, math.abs(ship.dx) * CollisionDamage)
      play_crash()
      ship.dx = -ship.dx
    end
    if ship.y < 0 then
      ship.y = -ship.y
      ship_damage(ship, math.abs(ship.dy) * CollisionDamage)
      play_crash()
      ship.dy = -ship.dy
    end
    if ship.x > Width then
      ship.x = Width - (ship.x - Width) * Damping
      ship_damage(ship, math.abs(ship.dx) * CollisionDamage)
      play_crash()
      ship.dx = -ship.dx * Damping
    end
    if ship.y > Height then
      ship.y = Height - (ship.y - Height) * Damping
      ship_damage(ship, math.abs(ship.dy) * CollisionDamage)
      play_crash()
      ship.dy = -ship.dy * Damping
    end
    ship.angle = get_angle(ship.dx, ship.dy)
  end

  local function ship_tumble(ship)
    ship_damage(ship, 0.01)
    ship.tilt = ship.tilt + (ship.dx) * dt * 2
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
      ship.laser.power = MinPower
      play_laser(ship.laser.power)
    end
    ship.laser.charge = math.min(MaxCharge, ship.laser.charge + dt * ChargeSpeed)
  end

  local function check_collision(s1, s2)
    local dist = math.sqrt((s1.x - s2.x)^2 + (s1.y - s2.y)^2)
    -- already close and getting even closer?
    if dist < s1.radius + s2.radius and dist > math.sqrt((s1.x + s1.dx - s2.x - s2.dx)^2 + (s1.y + s1.dy - s2.y - s2.dy)^2) then
      local boop_speed = math.sqrt((s1.dx - s2.dx)^2 + (s1.dy - s2.dy)^2)
      ship_damage(s1, boop_speed * CollisionDamage)
      ship_damage(s2, boop_speed * CollisionDamage)
      s1.dx, s2.dx = s2.dx * (Damping^0.5), s1.dx * (Damping^0.5)
      s1.dy, s2.dy = s2.dy * (Damping^0.5), s1.dy * (Damping^0.5)
      play_crash()
    end
  end

  local function update_stars()
    for _, star in ipairs(game.stars) do
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
    for i, dot in ipairs(game.debris) do
      dot[1] = dot[1] + dot[7].dx
      dot[2] = dot[2] + dot[7].dy
      dot[6] = dot[6] - 2 * dt -- fade out
      if dot[6] <= 0 then
        table.remove(game.debris, i)
      end
    end
  end

  if game.mode == 'game' then
    update_stars()
    update_debris()

    fade_laser(game.ships[1])
    fade_laser(game.ships[2])

    if game.ships[1].life == 0 then
      ship_tumble(game.ships[1])
    else
      if love.keyboard.isDown('up') then
        ship_up(game.ships[1])
      elseif love.keyboard.isDown('down') then
        ship_down(game.ships[1])
      end

      if love.keyboard.isDown('left') then
        ship_left(game.ships[1])
      elseif love.keyboard.isDown('right') then
        ship_right(game.ships[1])
      else
        ship_idle(game.ships[1])
      end

      if love.keyboard.isDown('space') or love.keyboard.isDown(',') then
        ship_charge(game.ships[1])
      else
        ship_release(game.ships[1])
      end
    end

    if game.ships[2].life == 0 then
      ship_tumble(game.ships[2])
    else
      if love.keyboard.isDown('1') or love.keyboard.isDown('`') then
        ship_charge(game.ships[2])
      else
        ship_release(game.ships[2])
      end

      if love.keyboard.isDown('w') then
        ship_up(game.ships[2])
      elseif love.keyboard.isDown('s') then
        ship_down(game.ships[2])
      end

      if love.keyboard.isDown('a') then
        ship_left(game.ships[2])
      elseif love.keyboard.isDown('d') then
        ship_right(game.ships[2])
      else
        ship_idle(game.ships[2])
      end
    end

    ship_move(game.ships[1])
    ship_move(game.ships[2])
    update_laser_damage(game.ships[1], game.ships[2])
    update_laser_damage(game.ships[2], game.ships[1])
    check_collision(game.ships[1], game.ships[2])

    if game.ships[1].life == 0 or game.ships[2].life == 0 then
      game.gloat = game.gloat + dt
      if game.gloat > GloatTime then
        game.menu()
      end
    end

  elseif game.mode == 'menu' then
    update_stars()
    if love.keyboard.isDown('space') then
      game.restart()
    end
  end
end

function love.draw()

  local function draw_ship(ship)
    love.graphics.push()
    local max_shake = ship.laser.charge < MinSuperCharge and 0 or 4 * ship.laser.charge / MaxCharge
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

  local function draw_stars()
    love.graphics.points(game.stars)
  end

  local function draw_debris()
    love.graphics.setPointSize(2)
    love.graphics.points(game.debris)
    love.graphics.setPointSize(1)
  end

  if game.mode == 'game' then
    draw_stars()
    draw_debris()
    draw_stats(game.ships[1], 30, 1)
    draw_stats(game.ships[2], Width-30, -1)
    draw_ship(game.ships[1])
    draw_ship(game.ships[2])
    draw_laser(game.ships[1])
    draw_laser(game.ships[2])

  elseif game.mode == 'menu' then
    draw_stars()
    local font = love.graphics.newFont(100)
    love.graphics.setColor(0.5, 1, 0.5, 1)
    love.graphics.printf('ALIENATION', font, 0, Height/4, Width, 'center') -- , 20, 0, 0, 10, 0)
  end
end

-- enemyDictionary.lua --

--------- BEHAVIOURS ---------

-- RUNNER --
local function runBehaviour(dt, entity, world)
    if entity.direction == "right" and entity.isDead == false then
      entity.dx = entity.speed * dt
    elseif entity.direction == "left" and entity.isDead == false then
      entity.dx = -(entity.speed * dt)
    end

    if entity.isDead and checkTimer("death", entity.timers) == false then
      addTimer(0.3, "death", entity.timers)
      entity.curAnim = 2
      entity.dy = -3.75
      entity.dx = 0
      entity.type = "dead"
    elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
      entity.playDead = true
    end

    -- handle/update current animation running
    entity.animations[entity.curAnim]:update(dt)
end

-- GRENADE --
local function grenadeBehaviour(dt, entity, world)
  if checkTimer("start", entity.timers) == false then
    entity.dy = -3.75
    addTimer(0.0, "start", entity.timers)
  end

  if entity.direction == "right" and entity.isDead == false then
    entity.dx = entity.speed * dt
  elseif entity.direction == "left" and entity.isDead == false then
    entity.dx = -(entity.speed * dt)
  end

  if entity.isDead and checkTimer("death", entity.timers) == false then
    addTimer(0.3, "death", entity.timers)
    entity.curAnim = 2
    entity.gravity = 0
    entity.dx, entity.dy = 0, 0
  elseif  entity.isDead and updateTimer(dt, "death", entity.timers) then
    entity.playDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- PRONE SHOOTER --
local function proneShooterBehaviour(dt, entity, world)
  if player.x > entity.x - 160 and checkTimer("beginShooting", entity.timers) == false then
    addTimer(0.8, "beginShooting", entity.timers)
    --entity.type = "enemy" -- shooter cannot be hit until within range of the player
  elseif checkTimer("beginShooting", entity.timers) == true and updateTimer(dt, "beginShooting", entity.timers) == true and entity.isDead == false then
    addTimer(0.0, "shoot", entity.timers)
    addTimer(0.2, "resetShot", entity.timers)
  end

  if checkTimer("shoot", entity.timers) and updateTimer(dt, "shoot", entity.timers) and entity.isDead == false then
    entity.curAnim = 2
    local deviation = love.math.random(0.1, 1) * 0.02
    addBullet(true, entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, math.pi + deviation)
    resetTimer(2.2, "shoot", entity.timers)
    resetTimer(0.2, "resetShot", entity.timers)
  elseif entity.curAnim == 2 and updateTimer(dt, "resetShot", entity.timers) then
    entity.curAnim = 1
  end

  if entity.isDead and checkTimer("death", entity.timers) == false then
    addTimer(0.5, "death", entity.timers)
    entity.curAnim = 3
    entity.type = "dead"
  elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
    entity.playDead = true
  end

  entity.animations[entity.curAnim]:update(dt)
end

-- LASER WALL --
local function laserWallBehaviour(dt, entity, world)
    if entity.isDead == false and world:hasItem(laserRect) == false then
      laserRect = {
        hp = 0, -- just so pBullet has something to subtract
        type = "enemy",
        name = "laserRect",
        filter = function(item, other) if other.type == "player" then return 'cross' end end,
        w = 2,
        h = 170,
        x = entity.x + entity.shootPoint.x,
        y = entity.y + entity.shootPoint.y
      }

      world:add(laserRect, laserRect.x, laserRect.y, laserRect.w, laserRect.h)
    end

    if world:hasItem(laserRect) then
      laserRect.x, laserRect.y, cols, len = world:move(laserRect, laserRect.x, laserRect.y, laserRect.filter)

      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(laserRect.name)
        end
      end
    end

    if entity.isDead and checkTimer("death", entity.timers) == false then
      laserRect.type = "dead"
      addTimer(0.3, "death", entity.timers)
      entity.curAnim = 2
      world:remove(laserRect) -- remove laser from world
    end

    --elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
      --entity.playDead = true -- get rid of this so laserWall doesnt disappear after death ... or make a new bool called permanence
      -- .. if permanence set to true body stays after death animation and is only removed from the world
      -- .. if enemy is no longer visible in the playing field remove this player from the enemy list

    -- handle/update current animation running
    entity.animations[entity.curAnim]:update(dt)
end

-- LASER WALL SPECIAL DRAW --
local function laserWallDraw(entity, world) -- not sure if i'll need world or not?

  if entity.isDead then -- if laserWall is dead, draw burn mark and return false
    setColor({ 0, 0, 0, 50})
    love.graphics.rectangle("fill", entity.x + entity.shootPoint.x - 1, entity.y + 170 + 5, 4.5, 2)
    setColor({ 255, 255, 255, 255})
    return false
  end

  local drawing, index, groundLevel = true, 0, 155

  while drawing do
      --setColor({ 255, 0, 0, 50})
      --love.graphics.rectangle("fill", entity.x + entity.shootPoint.x - 1, entity.y + entity.shootPoint.y + index, 4.5, 10) -- transparent

      setColor({ love.math.random(200, 255), 0, 0, 255})
      love.graphics.rectangle("fill", entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y + index, 2.5, 10) -- laser segments

      if index >= groundLevel then drawing = false end -- stop drawing upon reaching the ground

      index = index + 10 -- increase the index after each segment
  end

  love.graphics.rectangle("fill", entity.x + entity.shootPoint.x - 1, entity.y + index + 5, 2.5, 2)
  love.graphics.rectangle("fill", entity.x + entity.shootPoint.x + 1, entity.y + index + 5, 2.5, 2)

  setColor({ 255, 255, 255, 255})
end

-- WIZARD --
local function wizardBehaviour(dt, entity, world)
    if checkTimer("followPlayer", entity.timers) == false and player.x > entity.x - 320 and player.x < entity.x + 320 then
      addTimer(0.0, "followPlayer", entity.timers)
      addTimer(0.0, "buffer", entity.timers)
      addTimer(2.0, "shoot", entity.timers)

      frames = {
        x = nil,
        y = nil,
        curFrame = 0 -- for wizard's shoot animation
      }
    elseif checkTimer("followPlayer", entity.timers) and entity.isDead == false then
      if player.x > entity.x + 50 and entity.isDead == false then
        entity.dx = 10 * dt

        if entity.direction == "left" then
          entity.direction = "right"
          for i = 1, #entity.animations do
            entity.animations[i]:flipH()
          end
        end

      elseif player.x < entity.x - 50 and entity.isDead == false then
        entity.dx = -(10 * dt)

        if entity.direction == "right" then
          entity.direction = "left"
          for i = 1, #entity.animations do
            entity.animations[i]:flipH()
          end
        end

      elseif entity.isDead == false then -- apply deceleration
        if entity.direction == "right" then -- moving right
          entity.dx = math.max((entity.dx - 0.2 * dt), 0)
        else -- moving left
          entity.dx = math.min((entity.dx + 0.2 * dt), 0)
        end
      end

      if updateTimer(dt, "shoot", entity.timers) and entity.curAnim ~= 2 then
        entity.curAnim = 2
        entity.animations[2]:gotoFrame(1)
        entity.animations[2]:resume()
      end

      if entity.curAnim == 2 and updateTimer(dt, "shoot", entity.timers) then
        local quad = entity.animations[entity.curAnim]:getFrameInfo()
        local x, y = quad:getViewport()

        if frames.x ~= x or frames.y ~= y then
          frames.x, frames.y = x, y
          frames.curFrame = frames.curFrame + 1
        end

        if updateTimer(dt, "buffer", entity.timers) and frames.curFrame == 9 then
          local deviation = love.math.random(40, 50) * 0.01
          local destination = math.atan2(player.y + 30 - entity.y + entity.shootPoint.y, player.x + 5 - entity.x + entity.shootPoint.y)

          if entity.direction == "right" then
            addBullet(true, entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, destination)
            addBullet(true, entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, destination + deviation)
            addBullet(true, entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, destination - deviation)
          else
            addBullet(true, entity.x - entity.shootPoint.x, entity.y - entity.shootPoint.y, "right", world, destination)
            addBullet(true, entity.x - entity.shootPoint.x, entity.y - entity.shootPoint.y, "right", world, destination + deviation)
            addBullet(true, entity.x - entity.shootPoint.x, entity.y - entity.shootPoint.y, "right", world, destination - deviation)
          end
          resetTimer(0.2, "buffer", entity.timers)
        elseif frames.curFrame == 13 then
          frames.x, frames.y, frames.curFrame = nil, nil, 0
          resetTimer(2.0, "shoot", entity.timers)
          entity.curAnim = 1
        end
      end

      entity.dy = 0.25 * math.sin(love.timer.getTime() * 4.1 * math.pi)
    end


    if entity.isDead and checkTimer("death", entity.timers) == false then
      addTimer(1.0, "death", entity.timers)
      entity.curAnim = 3
      entity.dy = -2
      entity.dx = 0
      entity.gravity = 9.8
      entity.type = "dead"
    elseif entity.isDead and updateTimer(dt, "death 2", entity.timers) then
      entity.playDead = true
    end

    -- handle/update current animation running
    entity.animations[entity.curAnim]:update(dt)
end

-- GROUND SLIME --
local function gSlimeBehaviour(dt, entity, world)
    if entity.direction == "right" and entity.isDead == false then
      entity.dx = 50 * dt
    elseif entity.direction == "left" and entity.isDead == false then
      entity.dx = -(50 * dt)
    end

    if entity.isDead and checkTimer("death", entity.timers) == false then
      addTimer(0.3, "death", entity.timers)
      entity.curAnim = 2
      entity.dx = 0

      entity.type = "dead"
      entity.filter = function(item, other)
        if other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
          return 'slide'
        end
      end
    elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
      --entity.playDead = true -- so slime stays after dying
    end

    -- handle/update current animation running
    entity.animations[entity.curAnim]:update(dt)
end

-- CEILING SLIME --
local function cSlimeBehaviour(dt, entity, world)
    if entity.isDead == false and world:hasItem(groundRect) == false then -- on entity load
      groundRect = {
        type = "slimeBuffer",
        name = "groundRect",
        filter = function(item, other) if other.type == "ground" then return 'slide' end end,
        w = entity.w,
        h = 30,
        x = entity.x + entity.w / 2,
        y = entity.y + entity.h + 5
      }

      world:add(groundRect, groundRect.x, groundRect.y, groundRect.w, groundRect.h)
    end

    if world:hasItem(groundRect) then
      groundRect.x, groundRect.y, cols, len = world:move(groundRect, entity.x + entity.w / 2, entity.y + entity.h + 5, groundRect.filter)

      for i = 1, len do
        if cols[i].other.type == "ground" then
          entity.curAnim = 3
        end
      end
    end

    if entity.direction == "right" and entity.isDead == false then
      entity.dx = 50 * dt
    elseif entity.direction == "left" and entity.isDead == false then
      entity.dx = -(50 * dt)
    end

    if entity.isDead and checkTimer("death", entity.timers) == false then
      addTimer(0.3, "death", entity.timers)
      entity.curAnim = 2
      entity.dx = 0
      entity.gravity = 9.8

      entity.type = "dead"
      entity.filter = function(item, other)
        if other.type == "block" or other.type == "ground" or other.type == "slimeBuffer" then
          return 'slide'
        end
      end
    end

    -- handle/update current animation running
    entity.animations[entity.curAnim]:update(dt)
end

-- TURRET WALL --
local function turretWallBehaviour(dt, entity, world)
  if player.x > entity.x - 120 and checkTimer("wakeUp1", entity.timers) == false then
    addTimer(0.3, "wakeUp1", entity.timers)
    entity.curAnim = 2
  elseif checkTimer("wakeUp2", entity.timers) == false and updateTimer(dt, "wakeUp1", entity.timers) then
    addTimer(0.9, "wakeUp2", entity.timers)
    entity.curAnim = 3
  elseif checkTimer("wakeUp3", entity.timers) == false and updateTimer(dt, "wakeUp2", entity.timers) then
    addTimer(0.5, "wakeUp3", entity.timers)
    entity.curAnim = 4
  elseif checkTimer("idle", entity.timers) == false and updateTimer(dt, "wakeUp3", entity.timers) then
    addTimer(1.0, "idle", entity.timers)
    addTimer(1.0, "bubbleIdle", entity.timers)
    entity.curAnim = 5
  end

  if updateTimer(dt, "idle", entity.timers) and checkTimer("bubble1", entity.timers) == false and entity.isDead == false then
    addTimer(0.4, "bubble1", entity.timers)
    entity.curAnim = 6
  elseif checkTimer("bubble2", entity.timers) == false and updateTimer(dt, "bubble1", entity.timers) and entity.isDead == false then
    addTimer(2.0, "bubble2", entity.timers)
    addTimer(0.2, "shoot", entity.timers)
    entity.curAnim = 7
  elseif checkTimer("bubble3", entity.timers) == false and updateTimer(dt, "bubble2", entity.timers) and entity.isDead == false then
    addTimer(0.4, "bubble3", entity.timers)
    deleteTimer("shoot", entity.timers)
    entity.curAnim = 8
  elseif entity.curAnim == 8 and updateTimer(dt, "bubble3", entity.timers) and entity.isDead == false then
    addTimer(4.0, "bubbleIdle", entity.timers)
    entity.curAnim = 5

    entity.animations[6]:gotoFrame(1)
    entity.animations[6]:resume()
    entity.animations[8]:gotoFrame(1)
    entity.animations[8]:resume()
  end

  -- !!! ADD LASER SHOWER TO THIS FIGHT (THE ONE FROM SUPER C)

  if checkTimer("bubbleIdle", entity.timers) and updateTimer(dt, "bubbleIdle", entity.timers) and entity.isDead == false then
    deleteTimer("bubble1", entity.timers)
    deleteTimer("bubble2", entity.timers)
    deleteTimer("bubble3", entity.timers)
    deleteTimer("bubbleIdle", entity.timers)
  end

  if entity.curAnim == 7 and updateTimer(dt, "shoot", entity.timers) then
    local direction = math.atan2(love.math.random(0, 100) - entity.y, entity.shootPoint.x - entity.x) -- entity.shootPoint.y
    local deviation = love.math.random(-1.0, 1.0) * 0.15
    addBubble(2, entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, direction + deviation, world)
    resetTimer(0.2, "shoot", entity.timers)
  end

  if entity.isDead and checkTimer("death", entity.timers) == false then
    entity.curAnim = 9
    addTimer(0.8, "death", entity.timers)
  end

  if updateTimer(dt, "death", entity.timers) and entity.isDead then
    entity.curAnim = 10
  end

  entity.animations[entity.curAnim]:update(dt)
end

-- TUTORIAL MESSAGE --
local function tutMsgBehaviour(dt, entity, world)
  if checkTimer("start", entity.timers) == false then
    local loadBlockRect = {
      x = entity.x + 30.5,
      y = entity.y + 16,
      w = 5, -- 2
      h = 5 -- 2
    }

    entity.uniqueStorage = copy(loadBlockRect, entity.uniqueStorage)

    ogY = entity.y

    addTimer(0.0, "start", entity.timers)
  end

  if entity.y > ogY + 12 or entity.y < ogY - 6 then entity.y = ogY end -- due to alt-tab bug, this is a temporary fix

  entity.dy = 0.05 * math.sin(love.timer.getTime() * .35 * math.pi)

  if player.x < entity.x + entity.w + 50 and player.x > entity.x - 50 then
    if checkTimer("loadBlock", entity.timers) == false then
      addTimer(0.0, "loadBlock", entity.timers)
      entity.curAnim = 2
    end
  end

  if updateTimer(dt, "loadBlock", entity.timers) then
    if entity.uniqueStorage.h ~= 50 then
      entity.uniqueStorage.y = entity.uniqueStorage.y - 1.25
      entity.uniqueStorage.h = entity.uniqueStorage.h + 2.5
    elseif entity.uniqueStorage.w ~= 165 then
      entity.uniqueStorage.x = entity.uniqueStorage.x - 2.5
      entity.uniqueStorage.w = entity.uniqueStorage.w + 5
    end
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- TUTORIAL MESSAGE --
local function tutMsgDraw(entity, world)
  if entity.curAnim == 2 then
    setColor({255, 255, 255, 175})
    love.graphics.rectangle("line", entity.uniqueStorage.x, entity.uniqueStorage.y, entity.uniqueStorage.w, entity.uniqueStorage.h, 1, 1)
    love.graphics.rectangle("fill", entity.uniqueStorage.x, entity.uniqueStorage.y, entity.uniqueStorage.w, entity.uniqueStorage.h, 1, 1)

    if entity.uniqueStorage.w > 160 then
      love.graphics.setFont(bigFont)
      setColor({0, 0, 0, 255})
      love.graphics.printf(entity.uniqueParam, entity.uniqueStorage.x + 1, entity.uniqueStorage.y + 2, entity.uniqueStorage.w * 10 - 4, "left", 0, 0.1, 0.1)
      love.graphics.setFont(smallFont)
    end

    setColor({255, 255, 255, 255})
  end
end

-- TARGET --
local function targetBehaviour(dt, entity, world)
  if checkTimer("start", entity.timers) == false then
    entity.type = "invincible"
    addTimer(0.0, "start", entity.timers)
  end

  if player.x < entity.x + entity.w + 50 and player.x > entity.x - 50 and checkTimer("spawn", entity.timers) == false then
    entity.curAnim = 2
    entity.type = "enemy"
    addTimer(0.0, "spawn", entity.timers)
  end

  if entity.isDead and checkTimer("death", entity.timers) == false then
    addTimer(0.4, "death", entity.timers)
    entity.curAnim = 3
    entity.type = "dead"
  elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
    entity.playDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- MATRIX TURRET --
local function matrixTurretBehaviour(dt, entity, world)
  if checkTimer("start", entity.timers) == false then
    entity.type = "invincible"
    addTimer(0.0, "start", entity.timers)
  end

  if player.x < entity.x + entity.w + 180 and player.x > entity.x - 180 and checkTimer("spawn", entity.timers) == false then
    entity.curAnim = 2
    entity.type = "enemy"
    addTimer(0.0, "spawn", entity.timers)
    addTimer(1.5, "shoot", entity.timers)
    addTimer(0.0, "shootAnim", entity.timers)
  end

  if checkTimer("shoot", entity.timers) and updateTimer(dt, "shoot", entity.timers) then
    addBullet(true, entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, math.pi)
    entity.curAnim = 3
    resetTimer(0.3, "shoot", entity.timers)
    resetTimer(0.1, "shootAnim", entity.timers)
  end

  if checkTimer("shootAnim", entity.timers) and updateTimer(dt, "shootAnim", entity.timers) then
    entity.curAnim = 2
  end

  if entity.isDead and checkTimer("death", entity.timers) == false then
    entity.curAnim = 4
    entity.type = "invincible"

    deleteTimer("shoot", entity.timers)
    deleteTimer("shootAnim", entity.timers)
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- UPGRADE POD --
local function upgradeBehaviour(dt, entity, world)
    if entity.direction == "right" and entity.isDead == false then
      --entity.dx = entity.speed * dt
      entity.dx = 80 * dt
    elseif entity.direction == "left" and entity.isDead == false then
      --entity.dx = -(entity.speed * dt)
      entity.dx = -(80 * dt)
    end

    if entity.isDead == false then
      entity.dy = 0.17 * math.sin(love.timer.getTime() * .55 * math.pi)
    end

    if entity.isDead and checkTimer("death", entity.timers) == false then
      addTimer(0.3, "death", entity.timers)
      addEnemy(entity.uniqueParam, entity.x + 4, entity.y, entity.direction, world)
      entity.curAnim = 2
      entity.dy = 0
      entity.dx = 0
      entity.type = "dead"
    elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
      entity.playDead = true
    end

    -- handle/update current animation running
    entity.animations[entity.curAnim]:update(dt)
end

-- MACHINE GUN UPGRADE --
local function mgUPBehaviour(dt, entity, world)
  if checkTimer("spawn", entity.timers) == false then
    entity.dy = -2.5
    addTimer(0.0, "spawn", entity.timers)
  end

    if entity.isDead then
      entity.type = "dead"
      entity.playDead = true
    end

    -- handle/update current animation running
    entity.animations[entity.curAnim]:update(dt)
end

-- WALL --
local function wallBehaviour(dt, entity, world)
  if checkTimer("spawn", entity.timers) == false then
    addTimer(0.0, "spawn", entity.timers)
    entity.uniqueStorage = {}
    entity.uniqueStorage.x = entity.x
    entity.uniqueStorage.hp = entity.hp
  end

  if entity.hp < entity.uniqueStorage.hp then
    if entity.direction == "right" and entity.isDead == false then
      entity.dx = -10
    elseif entity.direction == "left" and entity.isDead == false then
      entity.dx = 10
    end

    entity.uniqueStorage.hp = entity.uniqueStorage.hp - 1
  else
    if entity.direction == "right" and entity.isDead == false then
      entity.dx = 3 * dt
    elseif entity.direction == "left" and entity.isDead == false then
      entity.dx = -(3 * dt)
    end
  end

  if entity.isDead and entity.x ~= entity.uniqueStorage.x then
    entity.dx = math.max(entity.uniqueStorage.x - entity.x) * 2 * dt
    if checkTimer("wait", entity.timers) == false then
      addTimer(15.0, "wait", entity.timers)
    end
  end

  if updateTimer(dt, "wait", entity.timers) then
    entity.dx = 0
    entity.isDead = false
    entity.hp = 10
    entity.uniqueStorage.hp = entity.hp
    deleteTimer("wait", entity.timers)
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- EYE --
local function eyeBehaviour(dt, entity, world)
  entity.dy = 0.5 * math.sin(love.timer.getTime() * 2 * math.pi)

  if checkTimer("bomb", entity.timers) == false then
    addTimer(1.3, "bomb", entity.timers)
  end

  if updateTimer(dt, "bomb", entity.timers) then
    addEnemy("grenade", entity.x, entity.y, entity.direction, world)

    resetTimer(1.3, "bomb", entity.timers)
  end

  if entity.direction == "right" and entity.isDead == false then
    entity.dx = 120 * dt
  elseif entity.direction == "left" and entity.isDead == false then
    entity.dx = -(120 * dt)
  end

  if entity.direction == "left" and entity.x < -100 then
    entity.direction = "right"

    for i = 1, #entity.animations do
      entity.animations[i]:flipH()
    end
  elseif entity.direction == "right" and entity.x > 650 then
    entity.direction = "left"

    for i = 1, #entity.animations do
      entity.animations[i]:flipH()
    end
  end

  if entity.isDead then entity.playDead = true end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- DED RUNNER --
local function dedRunBehaviour(dt, entity, world)
  if checkTimer("spawn", entity.timers) == false then
    addTimer(1.0, "spawn", entity.timers)
  end

  if checkTimer("turnAround", entity.timers) and updateTimer(dt, "turnAround", entity.timers) then
    if entity.direction == "right" and entity.isDead == false then
      entity.direction = "left"
    elseif entity.direction == "left" and entity.isDead == false then
      entity.direction = "right"
    end

    deleteTimer("turnAround", entity.timers)
  end

  if updateTimer(dt, "spawn", entity.timers) then
    if entity.direction == "right" and entity.isDead == false then
      entity.dx = 50 * dt
    elseif entity.direction == "left" and entity.isDead == false then
      entity.dx = -(50 * dt)
    end
  end

  if entity.isDead and checkTimer("death", entity.timers) == false then
    addTimer(0.3, "death", entity.timers)
    --entity.curAnim = 2
    entity.dy = -3.75
    entity.dx = 0
    entity.type = "dead"
  elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
    entity.playDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

--  CUBE --
local function cubeBehaviour(dt, entity, world)
  if entity.isDead == false then
    entity.dy = 0.05 * math.sin(love.timer.getTime() * 0.25 * math.pi)
    entity.dx = 0.05 * math.cos(love.timer.getTime() * 0.05 * math.pi)
  end

  if checkTimer("spawn1", entity.timers) == false then
    addTimer(3.0, "spawn1", entity.timers)
  end

  if updateTimer(dt, "spawn1", entity.timers) and entity.isDead == false then
    addEnemy("skull", entity.x + 5, entity.y, "left", world)
    addTimer(0.15, "spawn2", entity.timers)
    resetTimer(4.5, "spawn1", entity.timers)
  elseif updateTimer(dt, "spawn2", entity.timers) and entity.isDead == false then
    addEnemy("skull", entity.x + 12, entity.y, "right", world)
    addTimer(0.15, "spawn3", entity.timers)
    deleteTimer("spawn2", entity.timers)
  elseif updateTimer(dt, "spawn3", entity.timers) and entity.isDead == false then
    addEnemy("skull", entity.x + 5, entity.y, "left", world)
    addTimer(0.15, "spawn4", entity.timers)
    deleteTimer("spawn3", entity.timers)
  elseif updateTimer(dt, "spawn4", entity.timers) and entity.isDead == false then
    addEnemy("skull", entity.x + 12, entity.y, "right", world)
    deleteTimer("spawn4", entity.timers)
  end

  if entity.isDead and checkTimer("fall", entity.timers) == false then
    entity.curAnim = 2
    entity.type = "dead"
    entity.gravity = 10
    addTimer(0.63, "fall", entity.timers)
  elseif entity.isDead and updateTimer(dt, "fall", entity.timers) and checkTimer("dead", entity.timers) == false then
    entity.curAnim = 3
    addTimer(0.6, "dead", entity.timers)

    local shake = love.math.random(-4, 4) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)
    addEnemy("xp", entity.x + 5, entity.y, "left", world)
  elseif entity.isDead and updateTimer(dt, "dead", entity.timers) then
    entity.playDead = true;
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- SKULL --
local function skullBehaviour(dt, entity, world)
  if checkTimer("spawn", entity.timers) == false then
    entity.curAnim = 1
    addTimer(0.0, "spawn", entity.timers)
  end

  if checkTimer("turnAround", entity.timers) == true then
    if entity.direction == "right" and entity.isDead == false and checkTimer("turn", entity.timers) == false then
      entity.direction = "left"

      for i = 1, #entity.animations do
        entity.animations[i]:flipH()
      end

      addTimer(0.1, "turn", entity.timers)
    elseif entity.direction == "left" and entity.isDead == false and checkTimer("turn", entity.timers) == false then
      entity.direction = "right"

      for i = 1, #entity.animations do
        entity.animations[i]:flipH()
      end

      addTimer(0.1, "turn", entity.timers)
    end

    deleteTimer("turnAround", entity.timers)
  elseif updateTimer(dt, "turn", entity.timers) then
    deleteTimer("turn", entity.timers)
  end

  if updateTimer(dt, "regular", entity.timers) then
    if entity.direction == "right" and entity.isDead == false then
      entity.curAnim = 2
      entity.gravity = 0

      entity.dy = 0.05 * math.sin(love.timer.getTime() * 0.25 * math.pi)
      entity.dy = entity.dy - dt
      entity.dx = 75 * dt
    elseif entity.direction == "left" and entity.isDead == false then
      entity.curAnim = 2
      entity.gravity = 0

      entity.dy = 0.05 * math.sin(love.timer.getTime() * 0.25 * math.pi)
      entity.dy = entity.dy - dt
      entity.dx = -(75 * dt) -- 50
    end
  end

  if entity.isDead and checkTimer("death", entity.timers) == false then
    addTimer(0.6, "death", entity.timers)
    entity.curAnim = 3
    entity.dx = 0
    entity.gravity = 0
    entity.dy = 0
    entity.type = "dead"

    local shake = love.math.random(-4, 4) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)
  elseif entity.isDead and updateTimer(dt, "death", entity.timers) then
    entity.playDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- BIG CUBE --
local function bigcubeBehaviour(dt, entity, world)
  if entity.isDead == false then
    entity.dy = 0.05 * math.sin(love.timer.getTime() * 0.25 * math.pi)
  end

  if checkTimer("spawn1", entity.timers) == false then
    addTimer(3.0, "spawn1", entity.timers)
  end

  if updateTimer(dt, "spawn1", entity.timers) and entity.isDead == false then
    addEnemy("big skull", entity.x + 5, entity.y, "right", world)
    addTimer(0.3, "spawn2", entity.timers)
    resetTimer(6.5, "spawn1", entity.timers)
  elseif updateTimer(dt, "spawn2", entity.timers) and entity.isDead == false then
    addEnemy("skull", entity.x + 5, entity.y, "right", world)
    addEnemy("skull", entity.x + 5, entity.y, "left", world)
    deleteTimer("spawn2", entity.timers)
  end

  if entity.isDead and checkTimer("fall", entity.timers) == false then
    entity.curAnim = 2
    entity.type = "dead"
    entity.gravity = 10
    addTimer(0.63, "fall", entity.timers)
  elseif entity.isDead and updateTimer(dt, "fall", entity.timers) and checkTimer("dead", entity.timers) == false then
    entity.curAnim = 3
    addTimer(0.6, "dead", entity.timers)

    local shake = love.math.random(-4, 4) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)
    addEnemy("xp", entity.x + 5, entity.y, "left", world)
  elseif entity.isDead and updateTimer(dt, "dead", entity.timers) then
    entity.playDead = true;
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- XP --
local function xpBehaviour(dt, entity, world)
  if checkTimer("spawn", entity.timers) == false then
    entity.dy = -2.5
    addTimer(0.0, "spawn", entity.timers)
    addTimer(10.0, "life", entity.timers)
  end

  if entity.isDead then
    entity.type = "dead"
    entity.curAnim = 3
    entity.dy = 0
    addTimer(0.6, "dead", entity.timers)
  end

  if updateTimer(dt, "dead", entity.timers) == true then
    entity.playDead = true
  end

  if updateTimer(dt, "life", entity.timers) then
    entity.isDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- TRIANGLE --
local function triangleBehaviour(dt, entity, world)
  if checkTimer("spawn", entity.timers) == false and entity.isDead == false then
    addTimer(love.math.random(6, 8) * 0.2, "firstShot", entity.timers)
  end

  if entity.isDead == false then
    entity.dy = 0.05 * math.sin(love.timer.getTime() * 1 * math.pi)
  end

  if updateTimer(dt, "firstShot", entity.timers) and entity.isDead == false and checkTimer("secondShot", entity.timers) == false then
    --addEnemy("charge shot", entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, (math.pi / 2) + 0.15, (math.pi / 2) + 0.15)
    addEnemy("charge shot", entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, (math.pi / 2) + 0.04, (math.pi / 2) + 0.04)
    addTimer(0.1, "secondShot", entity.timers)
  elseif updateTimer(dt, "secondShot", entity.timers) and entity.isDead == false and checkTimer("thirdShot", entity.timers) == false then
    addEnemy("charge shot", entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, (math.pi / 2), (math.pi / 2))
    addTimer(0.1, "thirdShot", entity.timers)
  elseif updateTimer(dt, "thirdShot", entity.timers) and entity.isDead == false and checkTimer("reset", entity.timers) == false then
    --addEnemy("charge shot", entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, (math.pi / 2) - 0.15, (math.pi / 2) - 0.15)
    addEnemy("charge shot", entity.x + entity.shootPoint.x, entity.y + entity.shootPoint.y, "right", world, (math.pi / 2) - 0.04, (math.pi / 2) - 0.04)
    addTimer(2.0, "reset", entity.timers)
  elseif updateTimer(dt, "reset", entity.timers) and entity.isDead == false then
    resetTimer(0.7, "firstShot", entity.timers)
    deleteTimer("secondShot", entity.timers)
    deleteTimer("thirdShot", entity.timers)
    deleteTimer("reset", entity.timers)
  end

  if entity.isDead and checkTimer("fall", entity.timers) == false then
    entity.curAnim = 2
    entity.type = "dead"
    entity.gravity = 10
    addTimer(0.63, "fall", entity.timers)
  elseif entity.isDead and updateTimer(dt, "fall", entity.timers) and checkTimer("dead", entity.timers) == false then
    entity.curAnim = 3
    addTimer(0.6, "dead", entity.timers)

    local shake = love.math.random(-4, 4) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)
    addEnemy("xp", entity.x + 5, entity.y, "left", world)
  elseif entity.isDead and updateTimer(dt, "dead", entity.timers) then
    entity.playDead = true;
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- CHARGED SHOT --
local function chargeShotBehaviour(dt, entity, world)
  if checkTimer("charge", entity.timers) == false then
    addTimer(0.15, "charge", entity.timers)
  end

  if updateTimer(dt, "charge", entity.timers) == true and entity.isDead == false then
    entity.type = "enemy"
    entity.curAnim = 2
    entity.dy = math.sin(entity.uniqueParam) * 500 * dt
    entity.dx = math.cos(entity.uniqueParam) * 500 * dt
  end

  if entity.isDead and checkTimer("dead", entity.timers) == false then
    entity.curAnim = 3
    entity.dx, entity.dy = 0, 0
    entity.type = "dead"

    local shake = love.math.random(-4, 4) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)

    addTimer(0.6, "dead", entity.timers)
  elseif updateTimer(dt, "dead", entity.timers) == true then
    entity.playDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

local ogreHead = {
  x = 0,
  y = 0,
  status = "alive",
  rightHand = true,
  leftHand = true
}

-- OGRE --
local function ogreBehaviour(dt, entity, world)
  if checkTimer("spawn", entity.timers) == false then
    addTimer(2.0, "spawn", entity.timers)
  elseif updateTimer(dt, "spawn", entity.timers) and entity.curAnim == 1 then
    entity.curAnim = 2

    addTimer(0.0, "follow", entity.timers)
    addTimer(0.4, "spawnHand1", entity.timers)
  end

  if checkTimer("follow", entity.timers) and entity.isDead == false then
    entity.dx = math.max(player.x - (entity.x + entity.w / 2)) * 1 * dt
    ogreHead.x = entity.x
    entity.dy = 0.05 * math.sin(love.timer.getTime() * 1 * math.pi)
  end

  if updateTimer(dt, "spawnHand1", entity.timers) then
    deleteTimer("spawnHand1", entity.timers)
    addTimer(1.4, "spawnHand2", entity.timers)
    addEnemy("ogreHandLeft", entity.x - 120, entity.y + 25, "right", world)
  elseif updateTimer(dt, "spawnHand2", entity.timers) then
    addEnemy("ogreHandRight", entity.x + 120, entity.y + 25, "left", world)
    deleteTimer("spawnHand2", entity.timers)
  end

  if ogreHead.rightHand == false and ogreHead.leftHand == false and checkTimer("in pain", entity.timers) == false then
    entity.dx = 0
    entity.dy = 0
    deleteTimer("follow", entity.timers)
    addTimer(1.2, "in pain", entity.timers)
    entity.curAnim = 3
  end

  if updateTimer(dt, "in pain", entity.timers) and checkTimer("rise", entity.timers) == false then
    entity.curAnim = 2
    if entity.type ~= "enemy" then entity.type = "enemy" end
    addTimer(0.5, "rise", entity.timers)
  end

  if checkTimer("rise", entity.timers) and updateTimer(dt, "rise", entity.timers) == false then
    entity.dy = math.max(ogreHead.y - 20) * 4 * dt
  elseif updateTimer(dt, "rise", entity.timers) and checkTimer("smash", entity.timers) == false then
    entity.curAnim = 4
    addTimer(0.0, "smash", entity.timers)
  end

  if checkTimer("smash", entity.timers) and checkTimer("hit", entity.timers) == false then
    entity.dy = entity.dy + 50 * dt
  end

  if checkTimer("hit", entity.timers) and checkTimer("rise2", entity.timers) == false then
    entity.curAnim = 5
    addTimer(0.3, "rise2", entity.timers)
  end

  if updateTimer(dt, "rise2", entity.timers) and checkTimer("rise3", entity.timers) == false then
    addTimer(1.0, "rise3", entity.timers)
  end

  if checkTimer("rise3", entity.timers) then
    entity.dy = math.max(ogreHead.y - 20) * 4 * dt
    entity.dx = math.max(player.x - (entity.x + entity.w / 2)) * 1 * dt
  end

  if updateTimer(dt, "rise3", entity.timers) then
    deleteTimer("rise", entity.timers)
    deleteTimer("smash", entity.timers)
    deleteTimer("hit", entity.timers)
    deleteTimer("rise2", entity.timers)
    deleteTimer("rise3", entity.timers)

    entity.animations[4]:gotoFrame(1)
    entity.animations[4]:resume()

    entity.animations[5]:gotoFrame(1)
    entity.animations[5]:resume()
    entity.curAnim = 2
  end

  if updateTimer(dt, "shake", entity.timers) then
    addTimer(0.05, "second shake", entity.timers)
    deleteTimer("shake", entity.timers)
    local shake = love.math.random(5, 10) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)
  elseif updateTimer(dt, "second shake", entity.timers) then
    deleteTimer("second shake", entity.timers)
    local shake = love.math.random(3, 5) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(-shake, -shake)
  end

  if entity.isDead then
    ogreHead.alive = false
    entity.playDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

-- OGRE HAND --
local function ogreHandBehaviour(dt, entity, world)
  if entity.isDead == false then
    if checkTimer("spawn", entity.timers) == false then
      addTimer(0.6, "spawn", entity.timers)
      entity.uniqueStorage = 1
    elseif updateTimer(dt, "spawn", entity.timers) and checkTimer("spawnSkull", entity.timers) == false then
      if entity.type ~= "enemy" then entity.type = "enemy" end
      entity.dx = 0

      addTimer(0.15, "spawnSkull", entity.timers)
    elseif updateTimer(dt, "spawnSkull", entity.timers) and checkTimer("spawnSkull2", entity.timers) == false then
      entity.curAnim = 6
      addEnemy("skull", entity.x + 13, entity.y + 15, "left", world)
      addTimer(0.15, "spawnSkull2", entity.timers)
    elseif updateTimer(dt, "spawnSkull2", entity.timers) and checkTimer("spawnSkull3", entity.timers) == false then
      addEnemy("skull", entity.x + 13, entity.y + 15, "right", world)
      addTimer(0.15, "spawnSkull3", entity.timers)
    elseif updateTimer(dt, "spawnSkull3", entity.timers) and checkTimer("spawnSkull4", entity.timers) == false then
      addEnemy("skull", entity.x + 13, entity.y + 15, "left", world)
      addTimer(0.15, "spawnSkull4", entity.timers)
    elseif updateTimer(dt, "spawnSkull4", entity.timers) and checkTimer("spawnSkull5", entity.timers) == false then
      addEnemy("skull", entity.x + 13, entity.y + 15, "right", world)
      addTimer(0.15, "spawnSkull5", entity.timers)
    elseif updateTimer(dt, "spawnSkull5", entity.timers) and entity.curAnim == 6 then
      entity.curAnim = 2
      addTimer(1.0, "idle", entity.timers)
    end

    if checkTimer("idle", entity.timers) then
      if entity.direction == "right" then
        entity.dx = math.max(ogreHead.x - entity.x - 120 / entity.uniqueStorage) * (4 + entity.uniqueStorage) * dt
      else
        entity.dx = math.max(ogreHead.x - entity.x + 120 / entity.uniqueStorage) * (4 + entity.uniqueStorage) * dt
      end
    elseif checkTimer("reset", entity.timers) then
      if entity.direction == "right" then
        entity.dx = math.max(ogreHead.x - entity.x - 120) * 4 * dt
      else
        entity.dx = math.max(ogreHead.x - entity.x + 120) * 4 * dt
      end

      if updateTimer(dt, "reset", entity.timers) then
        entity.dx = 0

        entity.animations[2]:gotoFrame(1)
        entity.animations[2]:resume()

        entity.animations[5]:gotoFrame(1)
        entity.animations[5]:resume()
        entity.curAnim = 5


        entity.animations[6]:gotoFrame(1)
        entity.animations[6]:resume()

        entity.timers = {}
      end
    end

    if updateTimer(dt, "idle", entity.timers) and checkTimer("crush", entity.timers) == false then
      entity.dx = 0
      addTimer(0.2, "crush", entity.timers)
      deleteTimer("idle", entity.timers)
    elseif updateTimer(dt, "crush", entity.timers) == false and checkTimer("crush", entity.timers) then
      entity.dy = (30 - entity.y) * 4 * dt
    elseif updateTimer(dt, "crush", entity.timers) and checkTimer("idle", entity.timers) == false then
      entity.curAnim = 3
      entity.dy = entity.dy + 30 * dt
    elseif updateTimer(dt, "slam", entity.timers) and checkTimer("crush", entity.timers) == false and checkTimer("rise", entity.timers) == false then
      deleteTimer("slam", entity.timers)
      addTimer(0.5, "rise", entity.timers)
    elseif checkTimer("rise", entity.timers) and checkTimer("slam", entity.timers) == false and updateTimer(dt, "rise", entity.timers) == false then
      entity.dy = (30 - entity.y) * 4 * dt
    elseif updateTimer(dt, "rise", entity.timers) then
      entity.dy = 0
      entity.uniqueStorage = entity.uniqueStorage + 1

      entity.animations[3]:gotoFrame(1)
      entity.animations[3]:resume()

      deleteTimer("rise", entity.timers)

      if entity.uniqueStorage > 2 then
        addTimer(0.5, "reset", entity.timers)
      else
        addTimer(0.3, "idle", entity.timers)
      end
    end
  end

  if updateTimer(dt, "shake", entity.timers) then
    addTimer(0.05, "second shake", entity.timers)
    deleteTimer("shake", entity.timers)
    local shake = love.math.random(5, 10) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)
  elseif updateTimer(dt, "second shake", entity.timers) then
    deleteTimer("second shake", entity.timers)
    local shake = love.math.random(3, 5) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(-shake, -shake)
  end

  if ogreHead.alive == false then
    entity.isDead = true
  end

  if entity.isDead == false and checkTimer("idle", entity.timers) then
    entity.dy = 0.025 * math.sin(love.timer.getTime() * 0.5 * math.pi)
  end

  if entity.isDead and checkTimer("dead", entity.timers) == false then
    if entity.direction == "right" then ogreHead.leftHand = false else ogreHead.rightHand = false end

    entity.type = "dead"
    addTimer(1.2, "dead", entity.timers)

    local shake = love.math.random(-5, 5) * 0.5
    if shake == 0 then shake = 1 end
    camera:move(shake, shake)

    entity.dx = 0
    entity.dy = 0
    entity.curAnim = 7
    entity.gravity = 2
  end

  if updateTimer(dt, "dead", entity.timers) then
    entity.playDead = true
  end

  -- handle/update current animation running
  entity.animations[entity.curAnim]:update(dt)
end

local dictionary = {
  {
    name = "runner",
    hp = 1,
    w = 10,
    h = 42,
    update = runBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 10, offY = 15},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/runner2BIG.png",
    grid = {x = 32, y = 64, w = 96, h = 256},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(3, 1, '1-3', 2, '1-2', 3), 0.1), -- 1 running
        anim8.newAnimation(grid(3, 3, 1, 4), 0.15), -- 2 dying
      }
      return animations
    end,
    filter = nil,
    collision = nil,
    gravity = 9.8
  },

  {
    name = "grenade",
    hp = 1,
    w = 10,
    h = 10,
    update = grenadeBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 11, offY = 11},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/grenades/grenade.png",
    grid = {x = 32, y = 32, w = 96, h = 64},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      local animations = {
        anim8.newAnimation(grid('1-3', 1, 1, 2), 0.1), -- 1 thrown
        anim8.newAnimation(grid('2-3', 2), 0.1), -- 2 exploding
      }
      return animations
    end,
    filter = function(item, other)
      if other.type == "player" or other.type == "block" or other.type == "ground" then
        return 'cross'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "ground" or cols[i].other.type == "block" then
          entity.isDead = true
        elseif cols[i].other.type == "player" then
          cols[i].other.killPlayer()
          entity.isDead = true
        end
      end
    end,
    gravity = 9.8
  },

  {
    name = "prone-shooter",
    hp = 5,
    w = 52,
    h = 12,
    update = proneShooterBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 6, offY = 20},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/prone-shooter/prone-shooterBIG.png",
    grid = {x = 64, y = 32, w = 192, h = 32},
    shootPoint = {x = -20, y = 2},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1), -- 1 static
        anim8.newAnimation(grid(2, 1), .2), -- 2 shooting
        anim8.newAnimation(grid(3, 1), 0.15), -- 3 dying -- should have another empty frame for blinking?
      }
      return animations
    end,
    filter = nil,
    collision = nil,
    gravity = 9.8
  },

  {
    name = "laser-wall",
    hp = 10,
    w = 24,
    h = 20,
    update = laserWallBehaviour,
    specialDraw = laserWallDraw,
    scale = {x = 1, y = 1, offX = 0, offY = 0},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/laser-wall/laser-wallBIG.png",
    grid = {x = 64, y = 32, w = 192, h = 160},
    shootPoint = {x = 48, y = 6},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1), -- 1 active
        anim8.newAnimation(grid('1-3', '2-4', '1-2', 5), 0.1, "pauseAtEnd"), -- 2 dying
      }
      return animations
    end,
    filter = nil,
    collision = nil,
    gravity = 0
  },

  {
    name = "wizard",
    hp = 15,
    w = 10,
    h = 35,
    update = wizardBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 10.75, offY = 20},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/wizard/wizardBIG.png",
    grid = {x = 32, y = 64, w = 96, h = 512},
    shootPoint = {x = 16, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid('1-2', 1), 0.8), -- 1 floating
        anim8.newAnimation(grid('1-3', '2-5', 1, 1), 0.1, "pauseAtEnd"), -- 2 shooting
        anim8.newAnimation(grid('1-3', '6-7'), 0.1, "pauseAtEnd"), -- 3 dying
        anim8.newAnimation(grid('2-3', 8), 0.1), -- 4 ded
      }
      return animations
    end,
    filter = function(item, other)
      if other.type == "ground" then
        return 'slide'
      --elseif other.type == "player" then
        --return 'cross'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "ground" and entity.isDead and checkTimer("death 2", entity.timers) == false then
          entity.curAnim = 4
          addTimer(0.5, "death 2", entity.timers)
        end
      end
    end,
    gravity = 0
  },

  {
    name = "gSlime",
    hp = 3,
    w = 35,
    h = 30,
    update = gSlimeBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 10, offY = 27},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/slime/slimeBIG.png",
    grid = {x = 64, y = 64, w = 192, h = 256},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid('1-3', 1, 1, 2), 0.12), -- 1 running
        anim8.newAnimation(grid('1-3', '3-4'), 0.15, "pauseAtEnd"), -- 2 dying
      }
      return animations
    end,
    filter = nil,
    collision = nil,
    gravity = 9.8
  },

  {
    name = "cSlime",
    hp = 1, -- 3
    w = 35,
    h = 25,
    update = cSlimeBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 10, offY = 0},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/slime/cSlimeBIG.png",
    grid = {x = 64, y = 64, w = 192, h = 384},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid('1-3', 1, 1, 2), 0.12), -- 1 running
        anim8.newAnimation(grid('1-3', 3), 0.15, "pauseAtEnd"), -- 2 dying
        anim8.newAnimation(grid('1-3', '5-6'), 0.07, "pauseAtEnd"), -- 3 ded
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "slimeBuffer" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        end
      end
    end,
    gravity = 0
  },

  {
    name = "turret-wall",
    hp = 50,
    w = 16,
    h = 148,
    update = turretWallBehaviour, -- nil
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 10, offY = 0},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/mini-bosses/turret-wall/newTurret-wallBIG.png",
    grid = {x = 32, y = 160, w = 96, h = 2560},
    shootPoint = {x = -15, y = 110},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1), -- 1 static

        -- Waking:
        anim8.newAnimation(grid('1-3', 2), 0.1, "pauseAtEnd"), -- 2  stage-1
        anim8.newAnimation(grid('1-2', 3), 0.1), -- 3  stage-2
        anim8.newAnimation(grid(3, 3, '1-3', 4, 1, 5), 0.1, "pauseAtEnd"), -- 4  stage-3

        anim8.newAnimation(grid('1-3', '6-7'), 0.1), -- 5 idle

        anim8.newAnimation(grid(3, 8, '1-3', 9), 0.1, "pauseAtEnd"), -- 6 bubble-attack1
        anim8.newAnimation(grid('1-3', 10), 0.1), -- 7 bubble-attack2
        anim8.newAnimation(grid('1-3', 11), 0.1, "pauseAtEnd"), -- 8 bubble-attack3


        anim8.newAnimation(grid('1-3', '12-13', '1-2', 14), 0.1, "pauseAtEnd"), -- 7 dying 9
        anim8.newAnimation(grid('1-3', '15-16'), 0.1), -- 8 death idle 10
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" then
        return 'cross'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        end
      end
    end,
    gravity = 0
  },

  {
    name = "tutMsg",
    type = "message",
    hp = 1,
    w = 64,
    h = 32,
    update = tutMsgBehaviour,
    specialDraw = tutMsgDraw,
    scale = {x = 1, y = 1, offX = 0, offY = 0},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/other/message indicatorBIG.png",
    grid = {x = 64, y = 32, w = 192, h = 32},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1), -- 1 static
        anim8.newAnimation(grid('2-3', 1), 0.4, "pauseAtEnd"), -- 2 morph
        anim8.newAnimation(grid(3, 1, 2, 1, 1, 1), 0.4, "pauseAtEnd"), -- 3 morph back
      }
      return animations
    end,
    filter = function(item, other)
      -- nothing to see here
    end,
    collision = function(cols, len, entity, world)
      -- or here
    end,
    gravity = 0
  },

  {
    name = "target",
    hp = 2,
    w = 30,
    h = 30,
    update = targetBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 1, offY = 1},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/target/target.png",
    grid = {x = 32, y = 32, w = 96, h = 64},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(2, 2), 0.1), -- 1 invisible
        anim8.newAnimation(grid('1-3', 1, 1, 2), 0.1, "pauseAtEnd"), -- 2 spawn
        anim8.newAnimation(grid(2, 2, 1, 2), 0.1), -- 3 dying
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      -- do nothing
    end,
    collision = function(cols, len, entity, world)
      -- do nothing
    end,
    gravity = 0
  },

  {
    name = "matrix-turret",
    hp = 15,
    w = 25,
    h = 56,
    update = matrixTurretBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 25, offY = 8},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/matrix turret/matrix turretBIG.png",
    grid = {x = 64, y = 64, w = 192, h = 320},
    shootPoint = {x = -20, y = 16},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1), -- 1 idle
        anim8.newAnimation(grid('1-3', '1-4', '1-2', 5), 0.1, "pauseAtEnd"), -- 2 spawn
        anim8.newAnimation(grid(3, 5), 0.1), -- 3 shoot
        anim8.newAnimation(grid('2-1', 5, '3-1', '4-1'), 0.1, "pauseAtEnd"), -- 4 despawn

      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" then
        return 'cross'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
        end
      end
    end,
    gravity = 0
  },

  {
    name = "upgrade",
    type = "enemy",
    hp = 1,
    w = 16,
    h = 16,
    update = upgradeBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 0, offY = 0},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/upgrade pod/upgradePod.png",
    grid = {x = 16, y = 16, w = 48, h = 48},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 3, '3-1', '2-1'), 0.075), -- 1 floating
        anim8.newAnimation(grid('2-3', 3), 0.1), -- 2 dying
      }
      return animations
    end,
    filter = function(item, other)
      -- nothing to see here
    end,
    collision = function(cols, len, entity, world)
      -- or here
    end,
    gravity = 0
  },

  {
    name = "machineGun",
    type = "machineGun",
    hp = 1,
    w = 8,
    h = 8,
    update = mgUPBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 3.5, offY = 2},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/upgrades/upgrades.png",
    grid = {x = 16, y = 16, w = 16, h = 16},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1), -- 1 alive
      }
      return animations
    end,
    filter = function(item, other)
      if other.type == "player" then
        return 'cross'
      elseif other.type == "ground" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          if player.upgrade ~= "mg" then
            player.upgrade = "mg"
            player.shootTimerMax = player.shootTimerMax - 0.03
            player.bulletsMax = player.bulletsMax + 1
          end

          entity.isDead = true
        elseif cols[i].other.type == "ground" and entity.isDead == false and checkTimer("bounce", entity.timers) == false then
          entity.dy = -1
          addTimer(0.0, "bounce", entity.timers)
        end
      end
    end,
    gravity = 9.8
  },

  {
    name = "wall",
    hp = 10,
    w = 58,
    h = 192,
    update = wallBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 5, offY = 0},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/wall/wallBIG.png",
    grid = {x = 64, y = 192, w = 64, h = 192},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1),
      }
      return animations
    end,
    filter = function(item, other)
      if other.type == "player" or other.type == "bullet" then
        return 'cross'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
        end
      end
    end,
    gravity = 0
  },

  {
    name = "eye",
    hp = 2,
    w = 32,
    h = 16,
    update = eyeBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 0, offY = 0},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/eye/eye.png",
    grid = {x = 32, y = 16, w = 32, h = 16},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1),
      }
      return animations
    end,
    filter = nil,
    collision = nil,
    gravity = 0
  },

  {
    name = "ded runner",
    hp = 1,
    w = 10,
    h = 42,
    update = dedRunBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 10, offY = 15},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/ded runner/dedrunner.png",
    grid = {x = 32, y = 64, w = 32, h = 64},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1),
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" or other.type == "wall" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        elseif cols[i].other.type == "wall" and entity.isDead == false then
          addTimer(0.5, "turnAround", entity.timers)
        end
      end
    end,
    gravity = 2
  },

  {
    name = "cube",
    hp = 5,
    w = 22,
    h = 20,
    update = cubeBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 7, offY = 6},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/cube/cube.png",
    grid = {x = 36, y = 32, w = 108, h = 160},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid('1-3', '1-2', '1-2', 3), 0.15),
        anim8.newAnimation(grid('1-3', '1-2', '1-2', 3), 0.25),
        anim8.newAnimation(grid('1-3', '4-5', 3, 3), 0.1, "pauseAtEnd")
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" or other.name == "wall" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        elseif cols[i].other.name == "wall" and entity.isDead == false then
          entity.isDead = true
          entity.curAnim = 3
          addTimer(0.6, "dead", entity.timers)
          addTimer(0.0, "fall", entity.timers)
        end
      end
    end,
    gravity = 0
  },

  {
    name = "skull",
    hp = 1,
    w = 10,
    h = 20,
    update = skullBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 5, offY = -2},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/skull/skull.png",
    grid = {x = 16, y = 16, w = 48, h = 80},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid('1-3', 1, '1-2', 2), 0.1, "pauseAtEnd"), -- 1 spawn
        anim8.newAnimation(grid('1-3', 3), 0.1), -- 2 idle
        anim8.newAnimation(grid('1-3', '4-5', 3, 2), 0.08, "pauseAtEnd"), -- 3 dying
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" or other.name == "wall" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          entity.isDead = true
          print(entity.name)
        elseif cols[i].other.name == "wall" and entity.isDead == false then
          addTimer(0.0, "turnAround", entity.timers)
        elseif cols[i].other.type == "ground" and entity.isDead == false and checkTimer("up", entity.timers) == false then
          entity.dy = -2

          if entity.direction == "right" then
            entity.dx = 0.5
          else
            entity.dx = -0.5
          end

          addTimer(0.0, "up", entity.timers)
          addTimer(0.2, "regular", entity.timers)
        end
      end
    end,
    gravity = 3.8
  },

  {
    name = "big cube",
    hp = 8,
    w = 44,
    h = 40,
    update = bigcubeBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 14, offY = 12},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/cube/cubeBIG.png",
    grid = {x = 72, y = 64, w = 216, h = 320},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid('1-3', '1-2', '1-2', 3), 0.15),
        anim8.newAnimation(grid('1-3', '1-2', '1-2', 3), 0.25),
        anim8.newAnimation(grid('1-3', '4-5', 3, 3), 0.1, "pauseAtEnd")
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" or other.name == "wall" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        elseif cols[i].other.name == "wall" and entity.isDead == false then
          entity.isDead = true
          entity.curAnim = 3
          addTimer(0.6, "dead", entity.timers)
          addTimer(0.0, "fall", entity.timers)
        end
      end
    end,
    gravity = 0
  },

  {
    name = "big skull",
    hp = 3,
    w = 20,
    h = 40,
    update = skullBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 10, offY = -4},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/skull/skullBIG.png",
    grid = {x = 32, y = 32, w = 96, h = 160},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid('1-3', 1, '1-2', 2), 0.1, "pauseAtEnd"), -- 1 spawn
        anim8.newAnimation(grid('1-3', 3), 0.1), -- 2 idle
        anim8.newAnimation(grid('1-3', '4-5', 3, 2), 0.08, "pauseAtEnd"), -- 3 dying
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" or other.name == "wall" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          entity.isDead = true
          print(entity.name)
        elseif cols[i].other.name == "wall" and entity.isDead == false then
          addTimer(0.0, "turnAround", entity.timers)
        elseif cols[i].other.type == "ground" and entity.isDead == false and checkTimer("up", entity.timers) == false then
          entity.dy = -2
          addTimer(0.0, "up", entity.timers)
          addTimer(0.2, "regular", entity.timers)
        end
      end
    end,
    gravity = 3.8
  },

  {
    name = "xp",
    type = "xp",
    hp = 1,
    w = 6,
    h = 8,
    update = xpBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 1, offY = -2},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/xp/xpTest.png",
    grid = {x = 8, y = 8, w = 24, h = 32},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid(1, 1), 0.1),
        anim8.newAnimation(grid("2-3", 1, "1-3", 2), 0.1),
        anim8.newAnimation(grid("1-3", "3-4"), 0.1, "pauseAtEnd"),
      }
      return animations
    end,
    filter = function(item, other)
      if other.type == "player" or other.type == "invincible" then
        return 'cross'
      elseif other.type == "ground" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false or cols[i].other.type == "invincible" and entity.isDead == false then
          player.xp = player.xp + 1

          entity.isDead = true
        elseif cols[i].other.type == "ground" and entity.isDead == false and checkTimer("bounce", entity.timers) == false then
          entity.dy = -1
          addTimer(0.0, "bounce", entity.timers)
        elseif cols[i].other.type == "ground" and entity.isDead == false and checkTimer("bounce", entity.timers) == true then
          entity.curAnim = 2
        end
      end
    end,
    gravity = 9.8
  },

  {
    name = "triangle",
    hp = 5,
    w = 22,
    h = 20,
    update = triangleBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 7, offY = 6},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/triangle/triangle.png",
    grid = {x = 36, y = 32, w = 108, h = 128},
    shootPoint = {x = 9, y = 26},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid("1-3", 1, 1, 2, 3, 1, 2, 1, -- 1 floating
          "1-3", 1, 1, 2, 3, 1, 2, 1), {love.math.random(1, 10) * 0.2, 0.05, 0.05, 0.05, 0.05, 0.05,
          love.math.random(1, 10) * 0.2, 0.05, 0.05, 0.05, 0.05, 0.05}),
        -- ...
        anim8.newAnimation(grid(1, 2), 0.1), -- 2 falling
        anim8.newAnimation(grid("1-3", "3-4", 2, 2), 0.1, "pauseAtEnd"), -- 3 dying
      }
      return animations
    end,
    filter = nil,
    collision = nil,
    gravity = 0
  },

  {
    name = "charge shot",
    type = "charging",
    hp = 1,
    w = 5,
    h = 5,
    update = chargeShotBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 11, offY = 12},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/triangle/chargeShotnew.png",
    grid = {x = 20, y = 20, w = 60, h = 120},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid("1-3", 1, 1, 2), 0.1), -- 1 charging
        --anim8.newAnimation(grid("1-3", 3, "1-2", 4), 0.1), -- 2 shot
        anim8.newAnimation(grid(1, 3), 0.1), -- 2 shot
        anim8.newAnimation(grid("1-3", "5-6", 2, 2), 0.1, "pauseAtEnd"), -- 3 dying
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          entity.isDead = true
          print(entity.name)
        elseif cols[i].other.type == "ground" and entity.isDead == false then
          entity.isDead = true
        end
      end
    end,
    gravity = 0
  },

  {
    name = "ogre",
    type = "notEnemy",
    hp = 3,
    w = 56,
    h = 54,
    update = ogreBehaviour,
    specialDraw = nil,
    scale = {x = 1, y = 1, offX = 20, offY = 23},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/ogre/ogreBIG.png",
    grid = {x = 96, y = 96, w = 288, h = 960},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid("1-3", "1-2", "1-2", 3, "2-1", 3, "3-2", 2, 3, 3, "1-3", 4),
                                {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1}, "pauseAtEnd"), -- 1 spawning
        anim8.newAnimation(grid("1-3", 6, 2, 6, "1-3", 6, 2, 6), {love.math.random(5, 10) * 0.2, 0.05, 0.05, 0.05, love.math.random(1, 10) * 0.2, 0.05, 0.05, 0.05}), -- 2 blinking
        anim8.newAnimation(grid("1-3", "7-8", "3-1", "8-7"), 0.1, "pauseAtEnd"), -- 3 in pain
        anim8.newAnimation(grid(1, 9), 0.1, "pauseAtEnd"), -- 4 falling
        anim8.newAnimation(grid("2-3", 9, "1-3", 10), 0.1, "pauseAtEnd"), -- 5 smash
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        elseif cols[i].other.type == "ground" and entity.isDead == false and entity.curAnim ~= 5 then
          if checkTimer("hit", entity.timers) == false then
            addTimer(0.0, "hit", entity.timers)
            addTimer(0.0, "shake", entity.timers)
          end
        end
      end
    end,
    gravity = 0
  },

  {
    name = "ogreHandLeft",
    type = "notEnemy",
    hp = 2,
    w = 42,
    h = 32,
    update = ogreHandBehaviour,
    specialDraw = nil,
    scale = {x = 0.75, y = 0.75, offX = 20, offY = 23},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/ogre/handBIG.png",
    grid = {x = 96, y = 96, w = 288, h = 1344},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid("1-3", 8, "1-2", 9), 0.1, "pauseAtEnd"), -- 1 spawning
        anim8.newAnimation(grid(2, 1, 1, 1), 0.2, "pauseAtEnd"), -- 2 hand to fist
        anim8.newAnimation(grid("1-3", 4, 1, 5), 0.1, "pauseAtEnd"), -- 3 moving down
        anim8.newAnimation(grid("2-3", 6, "1-2", 7), 0.1, "pauseAtEnd"), -- 4 slam
        anim8.newAnimation(grid(2, 1, 2, 9), 0.2, "pauseAtEnd"), -- 5 fist to hand
        anim8.newAnimation(grid("1-2", 10, 1, 10, 2, 9), {0.1, 0.2, 0.1, 0.1}, "pauseAtEnd"), -- 6 spawn enemies
        anim8.newAnimation(grid("1-3", "11-14"), 0.1, "pauseAtEnd"), -- 7 dying
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        elseif cols[i].other.type == "ground" and entity.isDead == false and entity.curAnim ~= 4 then
          entity.animations[4]:gotoFrame(1)
          entity.animations[4]:resume()

          entity.curAnim = 4
          if checkTimer("crush", entity.timers) then
            deleteTimer("crush", entity.timers)
            addTimer(0.6, "slam", entity.timers)
            addTimer(0.0, "shake", entity.timers)
          end
        end
      end
    end,
    gravity = 0
  },

  {
    name = "ogreHandRight",
    type = "notEnemy",
    hp = 2,
    w = 42,
    h = 32,
    update = ogreHandBehaviour,
    specialDraw = nil,
    scale = {x = 0.75, y = 0.75, offX = 20, offY = 23},
    worldOffSet = {offX = 0, offY = 0},
    sprite = "img/enemies/ogre/handRightBIG.png",
    grid = {x = 96, y = 96, w = 288, h = 1344},
    shootPoint = {x = 0, y = 0},
    animations = function(grid)
      animations = {
        anim8.newAnimation(grid("1-3", 8, "1-2", 9), 0.1, "pauseAtEnd"), -- 1 spawning
        anim8.newAnimation(grid(2, 1, 1, 1), 0.2, "pauseAtEnd"), -- 2 hand to fist
        anim8.newAnimation(grid("1-3", 4, 1, 5), 0.1, "pauseAtEnd"), -- 3 moving down
        anim8.newAnimation(grid("2-3", 6, "1-2", 7), 0.1, "pauseAtEnd"), -- 4 slam
        anim8.newAnimation(grid(2, 1, 2, 9), 0.2, "pauseAtEnd"), -- 5 fist to hand
        anim8.newAnimation(grid("1-2", 10, 1, 10, 2, 9), {0.1, 0.2, 0.1, 0.1}, "pauseAtEnd"), -- 6 spawn enemies
        anim8.newAnimation(grid("1-3", "11-14"), 0.1, "pauseAtEnd"), -- 7 dying
      }
      return animations
    end,
    filter = function(item, other) -- default enemy filter
      if other.type == "player" then
        return 'cross'
      elseif other.type == "block" or other.type == "ground" or other.type == "enemyPlatform" then
        return 'slide'
      end
    end,
    collision = function(cols, len, entity, world)
      for i = 1, len do
        if cols[i].other.type == "player" and entity.isDead == false then
          cols[i].other.killPlayer(world)
          print(entity.name)
        elseif cols[i].other.type == "ground" and entity.isDead == false and entity.curAnim ~= 4 then
          entity.animations[4]:gotoFrame(1)
          entity.animations[4]:resume()

          entity.curAnim = 4
          if checkTimer("crush", entity.timers) then
            deleteTimer("crush", entity.timers)
            addTimer(0.6, "slam", entity.timers)
            addTimer(0.0, "shake", entity.timers)
          end
        end
      end
    end,
    gravity = 0
  },
}

function getEnemy(newEnemy) -- create some sort of clever dictionary look up function later on..if A > B etc... dictionary stuff
  for i=1, #dictionary do
    if newEnemy.name == dictionary[i].name then
      newEnemy.hp, newEnemy.w, newEnemy.h = dictionary[i].hp, dictionary[i].w, dictionary[i].h

      -- type
      if dictionary[i].type ~= nil then newEnemy.type = dictionary[i].type end

      -- scale and offsets
      newEnemy.scale = dictionary[i].scale
      newEnemy.worldOffSet = dictionary[i].worldOffSet

      -- functions
      newEnemy.behaviour = dictionary[i].update
      newEnemy.specialDraw = dictionary[i].specialDraw

      -- animation stuff
      newEnemy.spriteSheet = love.graphics.newImage(dictionary[i].sprite)
      newEnemy.spriteGrid = anim8.newGrid(dictionary[i].grid.x, dictionary[i].grid.y, dictionary[i].grid.w, dictionary[i].grid.h, 0, 0, 0)
      newEnemy.animations = dictionary[i].animations(newEnemy.spriteGrid)
      newEnemy.gravity = dictionary[i].gravity

      -- shootPoint
      newEnemy.shootPoint = dictionary[i].shootPoint

      -- filter
      if dictionary[i].filter ~= nil then
        newEnemy.filter = dictionary[i].filter
        newEnemy.collision = dictionary[i].collision
      end
    end
  end
end

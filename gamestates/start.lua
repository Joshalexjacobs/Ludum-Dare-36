start = {}

function start:keypressed(key, code)
  if key == "escape" then love.event.quit()
  else Gamestate.switch(game) end
end

function start:enter()

end

function start:update(dt)

end

function start:draw()
  love.graphics.scale(windowScale, windowScale)
  love.graphics.printf("Press Space", 0, 0, 1000)

end

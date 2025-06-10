PowerUp = Class{}

function PowerUp:init(x, y, type)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 16

    -- Ensure type is valid (defaulting to 1 if nil or invalid)
    self.type = type or 1 

    -- Falling speed
    self.dy = 50  
end

function PowerUp:update(dt)
    -- Ensure dt is never nil
    if dt == nil then
        dt = 0
    end
    
    -- Move power-up down
    self.y = self.y + self.dy * dt

    -- Optional: Remove power-up if it falls out of bounds
    if self.y > VIRTUAL_HEIGHT then
        self.remove = true  -- Mark for removal in PlayState
    end
end

function PowerUp:render()
    love.graphics.draw(gTextures['powerups'], gFrames['powerups'][self.type], self.x, self.y)
end

-- Optional: Collision Check with Paddle
function PowerUp:collides(paddle)
    return not (
        self.x > paddle.x + paddle.width or 
        self.x + self.width < paddle.x or 
        self.y > paddle.y + paddle.height or 
        self.y + self.height < paddle.y
    )
end

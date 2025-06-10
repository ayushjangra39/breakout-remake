PlayState = Class{__includes = BaseState}

function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.powerups = {} -- Store power-ups

    self.recoverPoints = 5000

    -- Set random ball velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
end

function PlayState:update(dt)
    -- Pause handling
    if love.keyboard.wasPressed('space') then
        self.paused = not self.paused
        gSounds['pause']:play()
    end
    if self.paused then return end

    self.paddle:update(dt)
    self.ball:update(dt)

    -- Update power-ups
    for i = #self.powerups, 1, -1 do
        local powerup = self.powerups[i]
        powerup:update(dt)

        -- Remove power-up if it falls below screen
        if powerup.y >= VIRTUAL_HEIGHT then
            table.remove(self.powerups, i)
        -- Check collision with paddle
        elseif powerup:collides(self.paddle) then
            if powerup.type == 1 then
                self.health = math.min(3, self.health + 1) -- Extra life
            elseif powerup.type == 2 then
                self.paddle.width = math.min(96, self.paddle.width + 16) -- Increase paddle size
            end
            table.remove(self.powerups, i) -- Remove power-up after collection
        end
    end

    -- Ball collision with paddle
    if self.ball:collides(self.paddle) then
        self.ball.y = self.paddle.y - 8
        self.ball.dy = -self.ball.dy

        -- Adjust ball direction based on paddle movement
        local diff = (self.ball.x + 4) - (self.paddle.x + self.paddle.width / 2)
        self.ball.dx = diff * 8

        gSounds['paddle-hit']:play()
    end

    -- Ball collision with bricks
    for k, brick in pairs(self.bricks) do
        if brick.inPlay and self.ball:collides(brick) then
            self.score = self.score + (brick.tier * 200 + brick.color * 25)
            brick:hit()

            -- Check for level completion
            if self:checkVictory() then
                gSounds['victory']:play()
                gStateMachine:change('victory', {
                    level = self.level + 1,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball
                })
            end

            -- Ball collision response
            if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x - 8
            elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x + 32
            elseif self.ball.y < brick.y then
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y - 8
            else
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y + 16
            end

            -- Slightly increase ball speed
            self.ball.dy = self.ball.dy * 1.03

            break -- Only hit one brick per frame
        end
    end

    -- Ball falls below screen
    if self.ball.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level
            })
        end
    end

    -- Update bricks
    for _, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    -- Exit game
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- Render bricks and particles
    for _, brick in pairs(self.bricks) do
        brick:render()
        brick:renderParticles()
    end

    -- Render paddle, ball, and power-ups
    self.paddle:render()
    self.ball:render()
    for _, powerup in pairs(self.powerups) do
        powerup:render()
    end

    -- Render UI
    renderScore(self.score)
    renderHealth(self.health)

    -- Pause text
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for _, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end
    return true
end

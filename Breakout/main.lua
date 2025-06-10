--[[ 
    Breakout Remake 

    Originally developed by Atari in 1976. 
    This version is inspired by the NES-style visuals with a modern widescreen resolution.

    Credits:
    - Graphics: https://opengameart.org/users/buch
    - Music: http://freesound.org/people/joshuaempyre/sounds/251461/
]]

-- Load dependencies
Class = require 'lib/Class'
require 'src/Dependencies'
require 'src/PowerUp'

-- Game variables
gPowerUps = {}  -- Table to store active power-ups

--[[ Initialize game objects and settings ]]
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    math.randomseed(os.time())

    love.window.setTitle('Breakout')

    -- Load fonts
    gFonts = {
        ['small']  = love.graphics.newFont('fonts/font.ttf', 8),
        ['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
        ['large']  = love.graphics.newFont('fonts/font.ttf', 32)
    }
    love.graphics.setFont(gFonts['small'])

    -- Load textures and quads
    gTextures = {
        ['background'] = love.graphics.newImage('graphics/background.png'),
        ['main']       = love.graphics.newImage('graphics/breakout.png'),
        ['arrows']     = love.graphics.newImage('graphics/arrows.png'),
        ['hearts']     = love.graphics.newImage('graphics/hearts.png'),
        ['particle']   = love.graphics.newImage('graphics/particle.png'),
        ['powerups']   = love.graphics.newImage('graphics/powerups.png')
    }

    gFrames = {
        ['arrows']   = GenerateQuads(gTextures['arrows'], 24, 24),
        ['paddles']  = GenerateQuadsPaddles(gTextures['main']),
        ['balls']    = GenerateQuadsBalls(gTextures['main']),
        ['bricks']   = GenerateQuadsBricks(gTextures['main']),
        ['hearts']   = GenerateQuads(gTextures['hearts'], 10, 9),
        ['powerups'] = GenerateQuads(gTextures['powerups'], 16, 16)
    }

    -- Setup screen
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- Load sounds
    gSounds = {
        ['paddle-hit']  = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score']       = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall-hit']    = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['confirm']     = love.audio.newSource('sounds/confirm.wav', 'static'),
        ['select']      = love.audio.newSource('sounds/select.wav', 'static'),
        ['no-select']   = love.audio.newSource('sounds/no-select.wav', 'static'),
        ['brick-hit-1'] = love.audio.newSource('sounds/brick-hit-1.wav', 'static'),
        ['brick-hit-2'] = love.audio.newSource('sounds/brick-hit-2.wav', 'static'),
        ['hurt']        = love.audio.newSource('sounds/hurt.wav', 'static'),
        ['victory']     = love.audio.newSource('sounds/victory.wav', 'static'),
        ['recover']     = love.audio.newSource('sounds/recover.wav', 'static'),
        ['high-score']  = love.audio.newSource('sounds/high_score.wav', 'static'),
        ['pause']       = love.audio.newSource('sounds/pause.wav', 'static'),
        ['music']       = love.audio.newSource('sounds/music.wav', 'static')
    }

    -- Setup game state machine
    gStateMachine = StateMachine {
        ['start']           = function() return StartState() end,
        ['play']            = function() return PlayState() end,
        ['serve']           = function() return ServeState() end,
        ['game-over']       = function() return GameOverState() end,
        ['victory']         = function() return VictoryState() end,
        ['high-scores']     = function() return HighScoreState() end,
        ['enter-high-score'] = function() return EnterHighScoreState() end,
        ['paddle-select']   = function() return PaddleSelectState() end
    }
    gStateMachine:change('start', { highScores = loadHighScores() })

    -- Start background music
    gSounds['music']:setLooping(true)
    gSounds['music']:play()

    love.keyboard.keysPressed = {}
end

--[[ Handles window resizing ]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[ Updates game state ]]
function love.update(dt)
    gStateMachine:update(dt)
    love.keyboard.keysPressed = {}
end

--[[ Key press handler ]]
function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

--[[ Checks if a key was pressed ]]
function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key] or false
end

--[[ Renders the game ]]
function love.draw()
    push:apply('start')

    -- Draw background
    local bgWidth, bgHeight = gTextures['background']:getWidth(), gTextures['background']:getHeight()
    love.graphics.draw(gTextures['background'], 0, 0, 0, VIRTUAL_WIDTH / (bgWidth - 1), VIRTUAL_HEIGHT / (bgHeight - 1))

    -- Render game state
    gStateMachine:render()

    -- Render power-ups
    for _, powerup in pairs(gPowerUps) do
        powerup:render()
    end

    -- Display FPS
    displayFPS()

    push:apply('end')
end

_G.renderScore = function(score)
    love.graphics.setFont(gFonts['small'])
    love.graphics.print('Score:', VIRTUAL_WIDTH - 60, 5)
    love.graphics.printf(tostring(score), VIRTUAL_WIDTH - 50, 5, 40, 'right')
end


--[[ Loads high scores from a file ]]
function loadHighScores()
    love.filesystem.setIdentity('breakout')

    if not love.filesystem.exists('breakout.lst') then
        local scores = ''
        for i = 10, 1, -1 do
            scores = scores .. 'CTO\n' .. tostring(i * 1000) .. '\n'
        end
        love.filesystem.write('breakout.lst', scores)
    end

    local scores = {}
    local name = true
    local counter = 1

    for i = 1, 10 do
        scores[i] = { name = nil, score = nil }
    end

    for line in love.filesystem.lines('breakout.lst') do
        if name then
            scores[counter].name = string.sub(line, 1, 3)
        else
            scores[counter].score = tonumber(line)
            counter = counter + 1
        end
        name = not name
    end

    return scores
end

--[[ Renders player's health ]]
function renderHealth(health)
    local healthX = VIRTUAL_WIDTH - 100
    for i = 1, health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][1], healthX, 4)
        healthX = healthX + 11
    end
    for i = 1, 3 - health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][2], healthX, 4)
        healthX = healthX + 11
    end
end

--[[ Displays FPS ]]
function displayFPS()
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 5, 5)
end

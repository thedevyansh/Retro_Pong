push = require 'push'
Class = require 'class'
require 'Paddle'
require 'Ball'
-- calling required classes and libraries 

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- SPEED OF THE PADDLE
PADDLE_SPEED = 200

function love.load()

    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('PONG')

    --  seed the random no. generator so that calls to random are always random 
    -- use the current time , since that will vary on start up everytime 
    math.randomseed(os.time())

    smallfont = love.graphics.newFont('font.ttf', 8)

    scorefont = love.graphics.newFont('font.ttf', 32)

    largefont = love.graphics.newFont('font.ttf', 16)

    love.graphics.setFont(smallfont)

    sound = {
        ['paddle_hit'] = love.audio.newSource('sound/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sound/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sound/wall_hit.wav', 'static')
    }

    -- initialize window with virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT,
                     {fullscreen = false, resizble = false, vsync = true})

    -- initialize  scores of players
    player1score = 0
    player2score = 0

    servingPlayer = 1
    -- initializing player's paddles

    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- placement of the ball in the middle 
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    gamestate = 'start'
end

function love.update(dt)

    if gamestate == 'serve' then
        -- before switching to play initializing ball's velocity based on the player who scored last
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gamestate == 'play' then

        if ball:collide(player1) then
            ball.dx = -ball.dx * 1.04
            ball.x = player1.x + 5

            -- keep velocity in same direction but randomize it 
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sound['paddle_hit']:play()
        end

        if ball:collide(player2) then
            ball.dx = -ball.dx * 1.04
            ball.x = player2.x - 5

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sound['paddle_hit']:play()
        end
        -- detecting lower and upper bounds ; reversing if collided 
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sound['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sound['wall_hit']:play()
        end

        -- if we reach left or right edge of the screen ,
        -- go back to start and update the score
        if ball.x < 0 then
            servingPlayer = 1
            player2score = player2score + 1
            sound['score']:play()

            if player2score == 10 then
                winningPlayer = 2
                gamestate = 'done'
            else
                gamestate = 'serve'
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1score = player1score + 1
            sound['score']:play()
            if player1score == 10 then
                winningPlayer = 1
                gamestate = 'done'
            else
                gamestate = 'serve'
                ball:reset()
            end
        end
    end

    -- player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end
    -- player 2 movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- update the ball only when we are in playstate
    if gamestate == 'play' then ball:update(dt) end

    player1:update(dt)
    player2:update(dt)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gamestate == 'start' then
            gamestate = 'serve'
        elseif gamestate == 'serve' then
            gamestate = 'play'
        elseif gamestate == 'done' then
            gamestate = 'serve' -- game comes in the restart phase
            -- but it sets the service to losing player    

            ball:reset()

            -- reset scores to 0
            player2score = 0
            player1score = 0

            -- decide the player to service
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

function love.draw()
    push:apply('start')

    love.graphics.clear(0, 0, 0, 255) -- rgba format
    displayScore()

    if gamestate == 'start' then
        love.graphics.setFont(smallfont)
        love.graphics.printf('WELCOME TO PONG !!', 0, 10, VIRTUAL_WIDTH,
                             'center')
        love.graphics.printf('PRESS ENTER TO START !!', 0, 20, VIRTUAL_WIDTH,
                             'center')
    elseif gamestate == 'serve' then
        love.graphics.setFont(smallfont)
        love.graphics.printf(
            'PLAYER ' .. tostring(servingPlayer) .. "'S SERVE!", 0, 10,
            VIRTUAL_WIDTH, 'center')
        love.graphics.printf('PRESS ENTER TO SERVE !!', 0, 20, VIRTUAL_WIDTH,
                             'center')
    elseif gamestate == 'play' then

    elseif gamestate == 'done' then

        love.graphics.setFont(largefont)
        love.graphics.printf('PLAYER ' .. tostring(winningPlayer) ..
                                 ' WINS!!!!!!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallfont)
        love.graphics.printf(
            'PRESS ENTER TO RESTART THE GAME AND ESC. TO TERMINATE THE APP ', 0,
            30, VIRTUAL_WIDTH, 'center')
    end

    player1:render()
    player2:render()
    ball:render()

    -- function to demonstrate frames per seconds in love 2d
    displayFPS()

    push:apply('end')
end

function displayFPS()

    love.graphics.setFont(smallfont)
    love.graphics.setColor(0, 255, 0, 255) -- green color
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end
function displayScore()
    -- drawing scores of the players on left and right sides of the screen
    love.graphics.setFont(scorefont)
    love.graphics.print(tostring(player1score), VIRTUAL_WIDTH / 2 - 50,
                        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2score), VIRTUAL_WIDTH / 2 + 30,
                        VIRTUAL_HEIGHT / 3)
end

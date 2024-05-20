local Skeleton = require("Skeleton")
local inputManager = require("inputManager")




function love.load()

    local windowWidth, windowHeight = 1600, 800
    love.window.setMode(windowWidth, windowHeight)

    WORLD = {}
    local objects = {} -- table to hold all our physical objects
    local worldWidth, worldHeight = 2000, 2000

    local platform = {
        x = windowWidth / 2,
        y = windowHeight / 1.25,
        length = windowWidth,
        height = 15,
    }

    -- let's create the ground
    -- the height of a meter our worlds will be 64px
    love.physics.setMeter(30)

    objects.ground = {}

    -- of 0 and vertical gravity of 9.81
    WORLD = love.physics.newWorld(0, 9.81*30, true)
    objects.ground.body = love.physics.newBody(WORLD, platform.x, platform.y, "static")
    objects.ground.shape = love.physics.newRectangleShape(platform.length, platform.height)
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)
    objects.ground.fixture:setFriction(.5)

    skeletons = Skeleton.new("player")

end

local systemRunTime = 0
local gameTick = {
    tickDuration = .333,
    tickUpdate = false,
    tickTimer = 0,
    tickCount = 0,
}


function love.update(dt)

    if love.keyboard.isDown("escape") then
        love.event.quit()        
    end

    WORLD:update(dt)
    local delta = inputManager.get_direction_delta()
    local multi = 20
    local force = 100 * multi
    skeletons.player.torso.core.chest.body:applyForce(delta.x * force, delta.y * force)
    skeletons.player.arms.left.forearm.body:applyForce(delta.x * force, delta.y * force)
    skeletons.player.arms.right.forearm.body:applyForce(delta.x * force, delta.y * force)


    love.keyboard.resetKeyStates()
end



local function draw_physics()
    local mode = "line"
    love.graphics.setColor(1,1,1,1)
    for _, body in pairs(WORLD:getBodies()) do
        for __, fixture in pairs(body:getFixtures()) do
            local shape = fixture:getShape()
            if shape:typeOf("CircleShape") then
                local cx, cy = body:getWorldPoints(shape:getPoint())
                love.graphics.circle(mode, cx, cy, shape:getRadius())
                local radius = shape:getRadius()
                local angle = body:getAngle()
                local angleOffset = math.rad(-90)
                local x1 = cx
                local y1 = cy
                local x2 = cx + radius * math.cos(angle + angleOffset)
                local y2 = cy + radius * math.sin(angle + angleOffset)
                love.graphics.line(x1, y1, x2, y2)
            elseif shape:typeOf("PolygonShape") then
                love.graphics.polygon(mode, body:getWorldPoints(shape:getPoints()))
            else
                love.graphics.line(body:getWorldPoints(shape:getPoints()))
            end
        end
    end
end


function love.draw()
    draw_physics()
end
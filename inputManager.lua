local inputManger = {}

local inputManager = {}
local KeyStates  = {}

local keybinds = {
    -- keystates 
    moveLeft = "a",
    moveRight = "d",

    moveUp = "w",
    moveDown = "s",

    jump = "space",

    escape = "escape",

}

local mousebinds = {
    mouseOne = "1",
    mouseTwo = "2",
    mouseThree = "3",

    mouseX1 = "4",
    mouseX2 = "5",
}


local maximumScale = 5
local minimumScale = 0
local scaleStep = .125
local scrollX = 1
local scrollY = 1


function love.wheelmoved(x, y)
    if x > 0 and scrollX > maximumScale then
        scrollX = scrollX + scaleStep
    elseif x < 0 and scrollX > minimumScale then
        scrollX = scrollX - scaleStep
    end

    if y > 0 and scrollY < maximumScale then
        scrollY = scrollY + scaleStep
    elseif y < 0 and scrollY > minimumScale then
        scrollY = scrollY - scaleStep
    end
end



function inputManager.get_scroll_values()
    return scrollX, scrollY
end

function inputManager.get_direction_delta()
    local delta = {x = 0, y = 0}

    if love.keyboard.isDown(keybinds.moveLeft) then
        delta.x = -1
    end

    if love.keyboard.isDown(keybinds.moveRight) then
        delta.x = 1
    end

    if love.keyboard.isReleased(keybinds.jump) then
        delta.y = -30
    end

    return delta
end


love.keyboard.isPressed = function(k)
    local now = love.keyboard.isDown(k)
    if KeyStates[k] then
        local last = KeyStates[k].last
        KeyStates[k].now = now
        return now and not last
    else
        KeyStates[k] = { now = now, last = false}
        return now
    end
end


love.keyboard.isReleased = function(k)
    local now = love.keyboard.isDown(k)
    if KeyStates[k] then
        local last = KeyStates[k].last
        KeyStates[k].now = now
        return not now and last
    else
        KeyStates[k] = { now = now, last = false}
        return now
    end
end


love.keyboard.resetKeyStates = function()
    for k, _ in pairs(KeyStates) do
        KeyStates[k].last = KeyStates[k].now
    end
end

return inputManager
local Skeleton = {}

function Skeleton.create_limb_data(width, height)

    local points = {          -- center is 0, 0
        -width, height, -- top left corner 
        -width, -height, -- bottom left corner
        width, -height, -- bottom right corner
        width, height, -- top right corner
    }
    return points
end


function Skeleton.create_joint_data(radius)
    return radius
end


local function get_limb_width_and_length(limb)
    local x1, y1, x2, y2 = limb.body:getWorldPoints(limb.shape:getPoints())
    local width = math.abs(x2 - x1)
    local height = math.abs(y2 - y1)
    return width, height
end


local function create_physics_body(x, y, physicsBodyType, type, width, height, radius)

    local container = {}
    if type == "polygon" then
        container.body = love.physics.newBody(WORLD, x, y, physicsBodyType)
        container.shape = love.physics.newPolygonShape(Skeleton.create_limb_data(width, height))
        container.fixture = love.physics.newFixture(container.body, container.shape)
    else
        container.body = love.physics.newBody(WORLD, x, y, physicsBodyType)
        container.shape = love.physics.newCircleShape(Skeleton.create_joint_data(radius))
        container.fixture = love.physics.newFixture(container.body, container.shape)
    end

    container.body:setInertia(500)
    return container

end


local function create_skeleton_section(section1, section2, link)

    local skeleton = {left = {}, right = {}}

    local width, height = 15, 30
    local radius = 15
    local ox, oy = 200, 200
    local thighOffset = -300
    local biceptOffset = -200
    local overlap = 0


    if section1 == "thigh" then
        oy = oy - thighOffset
    end

    if section1 == "bicept" then
        oy = oy - biceptOffset
    end

    local physicsBodyType = "dynamic"
    local physicsBodyTypeLowerSection = "dynamic"
    local limb = "polygon"
    local joint = "circle"
    skeleton.left[section1] = create_physics_body(ox, oy, physicsBodyType, limb, width, height, radius)
    skeleton.right[section1] = create_physics_body(ox, oy , physicsBodyType, limb, width, height, radius)

    skeleton.left[section2] = create_physics_body(ox, oy, physicsBodyTypeLowerSection, limb, width, height, radius)
    skeleton.right[section2] = create_physics_body(ox, oy, physicsBodyType, limb, width, height, radius)

    skeleton.left["bottom" .. link] = create_physics_body(ox, oy, physicsBodyType, joint, width, height, radius)
    skeleton.right["bottom" .. link] = create_physics_body(ox, oy, physicsBodyType, joint, width, height, radius)

    skeleton.left["top" .. link] = create_physics_body(ox, oy, physicsBodyType, joint, width, height, radius)
    skeleton.right["top" .. link] = create_physics_body(ox, oy, physicsBodyType, joint, width, height, radius)

    width, height = get_limb_width_and_length(skeleton.left[section1])
    radius = skeleton.left["bottom" .. link].shape:getRadius()
    local diameter = radius * 2

    if width == 0 then
        width = radius * 3
    end

    local x, y = ox - width, oy
    skeleton.left[section1].body:setPosition(x, y)
    x, y = ox + width, oy 
    skeleton.right[section1].body:setPosition(x, y)

    x, y = ox - width, oy - radius + height - overlap
    skeleton.left["bottom" .. link].body:setPosition(x, y)
    x, y = ox + width, oy - radius + height - overlap
    skeleton.right["bottom" .. link].body:setPosition(x, y)

    x, y = ox - width, oy - radius + height - overlap
    skeleton.left["top" .. link].body:setPosition(x, y)
    x, y = ox + width, oy - radius + height - overlap
    skeleton.right["top" .. link].body:setPosition(x, y)

    x, y = ox - width, oy + height + diameter - overlap * 2
    skeleton.left[section2].body:setPosition(x, y)
    x, y = ox + width, oy + height + diameter - overlap * 2
    skeleton.right[section2].body:setPosition(x, y)

    skeleton.joints = {revolute = {}, weld = {}}

    skeleton.joints.revolute["left" .. link] = love.physics.newRevoluteJoint(skeleton.left["bottom" .. link].body, skeleton.left["top" .. link].body, skeleton.left["bottom" .. link].body:getWorldPoints(skeleton.left["bottom" .. link].shape:getPoint()))
    skeleton.joints.revolute["right" .. link] = love.physics.newRevoluteJoint(skeleton.right["bottom" .. link].body, skeleton.right["top" .. link].body, skeleton.right["bottom" .. link].body:getWorldPoints(skeleton.right["bottom" .. link].shape:getPoint()))

    skeleton.joints.weld["left" .. section1 .. "To" .. link] = love.physics.newWeldJoint(skeleton.left[section1].body, skeleton.left["bottom" .. link].body, skeleton.left["bottom" .. link].body:getWorldPoints(skeleton.left["bottom" .. link].shape:getPoint()))
    skeleton.joints.weld["right" .. section1 .. "To" .. link] = love.physics.newWeldJoint(skeleton.right[section1].body, skeleton.right["bottom" .. link].body, skeleton.right["bottom" .. link].body:getWorldPoints(skeleton.right["bottom" .. link].shape:getPoint()))

    skeleton.joints.weld["left" .. section2 .. "To" .. link] = love.physics.newWeldJoint(skeleton.left[section2].body, skeleton.left["top" .. link].body, skeleton.left["top" .. link].body:getWorldPoints(skeleton.left["top" .. link].shape:getPoint()))
    skeleton.joints.weld["right" .. section2 .. "To" .. link] = love.physics.newWeldJoint(skeleton.right[section2].body, skeleton.right["top" .. link].body, skeleton.right["top" .. link].body:getWorldPoints(skeleton.right["top" .. link].shape:getPoint()))

    return skeleton
end


local function create_skeleton_torso_section()
    local skeleton = {core = {}}
    local width, height = 25, 45
    local radius = 25
    local ox, oy = 200, 200
    local physicsBodyType = "dynamic"
    local torsoType = "polygon"
    local headType = "circle"
    skeleton.joints = {revolute = {}, weld = {}}
    skeleton.core.chest = create_physics_body(ox, oy, physicsBodyType, torsoType, width, height, radius)
    skeleton.core.head = create_physics_body(ox, oy - height - radius, physicsBodyType, headType, width, height, radius)
    skeleton.joints.weld.coreTorsoToHead = love.physics.newWeldJoint(skeleton.core.chest.body, skeleton.core.head.body, skeleton.core.head.body:getWorldPoints(skeleton.core.head.shape:getPoint()))

    return skeleton
end


local function create_section_links(skeleton, linkName1, linkName2)
    local links = {linkName1, linkName2}

    local width, height = 15, 15
    local radius = 15
    local points = {}
    points.x1, points.y1, points.x2, points.y2, points.x3, points.y3, points.x4, points.y4 = skeleton.torso.core.chest.body:getWorldPoints(skeleton.torso.core.chest.shape:getPoints())
    local ox, oy = 0, 0
    local offsetX, offsetY = 0, 0
    local physicsBodyType = "dynamic"
    local joint = "circle"
    local hipOffset = 8

    for _, link in ipairs(links) do
        if link == linkName1 then
           ox, oy = points.x4 - radius, points.y4 + radius
        else
            ox, oy = points.x3 - radius / hipOffset, points.y3 + radius
        end
        skeleton[link] = {left = {}, right = {}, joints = {revolute = {}, weld = {}}}
        skeleton[link].left["bottom" .. link] = create_physics_body(ox + offsetX, oy + offsetY, physicsBodyType, joint, width, height, radius)
        skeleton[link].left["top" .. link] = create_physics_body(ox, oy, physicsBodyType, joint, width, height, radius)
        if link == linkName1 then
            ox, oy = points.x1 + radius, points.y1 + radius
        else
            ox, oy = points.x2 + radius / hipOffset, points.y2 + radius
        end
        skeleton[link].right["bottom" .. link] = create_physics_body(ox + offsetX, oy + offsetY, physicsBodyType, joint, width, height, radius)
        skeleton[link].right["top" .. link] = create_physics_body(ox + offsetX, oy + offsetY, physicsBodyType, joint, width, height, radius)
        
        skeleton[link].joints.revolute["left" .. link] = love.physics.newRevoluteJoint(skeleton[link].left["bottom" .. link].body, skeleton[link].left["top" .. link].body, skeleton[link].left["bottom" .. link].body:getWorldPoints(skeleton[link].left["bottom" .. link].shape:getPoint()))
        skeleton[link].joints.revolute["right" .. link] = love.physics.newRevoluteJoint(skeleton[link].right["bottom" .. link].body, skeleton[link].right["top" .. link].body, skeleton[link].right["bottom" .. link].body:getWorldPoints(skeleton[link].right["bottom" .. link].shape:getPoint()))

    end

    return skeleton
end

local function link_skeleton_sections(skeleton)
    local jointNames = {"leftShoulderToChest",  "rightShoulderToChest", "leftHipToChest", "rightHipToChest"}
    local sectionLinks, torso, arms, legs = skeleton.sectionLinks, skeleton.torso, skeleton.arms, skeleton.legs
    local joints = {revolute = {}, weld = {}}

    joints.weld[jointNames[1]] = love.physics.newWeldJoint(torso.core.chest.body, sectionLinks.shoulder.left.bottomshoulder.body, sectionLinks.shoulder.left.bottomshoulder.body:getWorldPoints(sectionLinks.shoulder.left.bottomshoulder.shape:getPoint()))
    joints.weld[jointNames[2]] = love.physics.newWeldJoint(torso.core.chest.body, sectionLinks.shoulder.right.bottomshoulder.body,sectionLinks.shoulder.right.bottomshoulder.body:getWorldPoints(sectionLinks.shoulder.right.bottomshoulder.shape:getPoint()))
    joints.weld[jointNames[3]] = love.physics.newWeldJoint(torso.core.chest.body, sectionLinks.hip.left.bottomhip.body, sectionLinks.hip.left.bottomhip.body:getWorldPoints(sectionLinks.hip.left.bottomhip.shape:getPoint()))
    joints.weld[jointNames[4]] = love.physics.newWeldJoint(torso.core.chest.body,sectionLinks.hip.right.bottomhip.body, sectionLinks.hip.right.bottomhip.body:getWorldPoints(sectionLinks.hip.right.bottomhip.shape:getPoint()))
    
    local x, y = sectionLinks.shoulder.left.topshoulder.body:getWorldPoints(sectionLinks.shoulder.left.topshoulder.shape:getPoint())
    local width, height = get_limb_width_and_length(arms.left.bicept)
    local radius = sectionLinks.shoulder.left.topshoulder.shape:getRadius()
    y = y + height - radius

    arms.left.bicept.body:setPosition(x, y)


    joints.weld[jointNames[1]] = love.physics.newWeldJoint(arms.left.bicept.body, sectionLinks.shoulder.left.topshoulder.body, sectionLinks.shoulder.left.topshoulder.body:getWorldPoints(sectionLinks.shoulder.left.topshoulder.shape:getPoint()))
    
    x, y = sectionLinks.shoulder.right.topshoulder.body:getWorldPoints(sectionLinks.shoulder.right.topshoulder.shape:getPoint())
    y = y + height - radius
    arms.right.bicept.body:setPosition(x, y)
    joints.weld[jointNames[2]] = love.physics.newWeldJoint(arms.right.bicept.body, sectionLinks.shoulder.right.topshoulder.body,sectionLinks.shoulder.right.bottomshoulder.body:getWorldPoints(sectionLinks.shoulder.right.topshoulder.shape:getPoint()))

    x, y = sectionLinks.hip.left.tophip.body:getWorldPoints(sectionLinks.hip.left.tophip.shape:getPoint())
    y = y + height - radius
    legs.left.thigh.body:setPosition(x, y)
    joints.weld[jointNames[3]] = love.physics.newWeldJoint(legs.left.thigh.body, sectionLinks.hip.left.tophip.body, sectionLinks.hip.left.tophip.body:getWorldPoints(sectionLinks.hip.left.tophip.shape:getPoint()))

    x, y = sectionLinks.hip.right.tophip.body:getWorldPoints(sectionLinks.hip.right.tophip.shape:getPoint())
    y = y + height - radius
    legs.right.thigh.body:setPosition(x, y)
    joints.weld[jointNames[4]] = love.physics.newWeldJoint(legs.right.thigh.body,sectionLinks.hip.right.tophip.body, sectionLinks.hip.right.tophip.body:getWorldPoints(sectionLinks.hip.right.tophip.shape:getPoint()))

    for key, value in ipairs(joints.weld) do
        -- value:enableMotor()
        -- value:setMaxMotorTorque(2)
        -- value:setMotorSpeed(2)
    end
    return skeleton
end

function Skeleton.new(name)
    local skeletons = {
        [name] = {
            legs = {},
            arms = {},
            torso = {},
            sectionLink = {
                left = {}, right = {}
            },
        }
    }

    skeletons[name].legs = create_skeleton_section("thigh", "calf", "knee")
    skeletons[name].arms = create_skeleton_section("bicept", "forearm", "elbow")
    skeletons[name].torso = create_skeleton_torso_section()
    skeletons[name].sectionLinks = create_section_links(skeletons[name], "shoulder", "hip")
    skeletons[name] = link_skeleton_sections(skeletons[name])
    return skeletons
end





return Skeleton
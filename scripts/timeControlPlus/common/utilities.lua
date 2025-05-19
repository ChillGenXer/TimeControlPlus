local notificationsUI = mjrequire "mainThread/ui/notificationsUI"
local notification = mjrequire "common/notification"
local localPlayer = mjrequire "mainThread/localPlayer"
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3

-- Set up as a module
local utilities = {}

--local testView = nil
--local logCounter = os.clock()

--Constants
local earthRadius = 8388608.0 -- Globe radius in meters

-- Rounds the given number
function utilities:round(n)
    return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

-- Calculate the straight-line distance between two vec3 positions in meters
function utilities:getDistance(startPos, targetPos)
    if not startPos or not targetPos then
        mj:log("utilities::getDistance: Error: startPos or targetPos is nil")
        return 0
    end

    -- Calculate the difference vector
    local diff = targetPos - startPos

    -- Use mjm.length to get the straight-line distance
    local distance = mjm.length(diff)

    -- Scale the distance to meters
    local distanceInMeters = distance * earthRadius

    return utilities:round(distanceInMeters)
end

-- Calculate scale3D for known ratio panels. Returns a vec3 scale3D value
function utilities:calculatePanelScale3D(width, height, modelHeight, prioritizeWidth)
    -- width: Desired width in pixels
    -- height: Desired height in pixels
    -- modelHeight: Height of the model in Blender units (assumes a width of 1 unit)
    -- prioritizeWidth: Boolean, true to base uniform scale on width (stretch height), false to base on height (stretch width).

    prioritizeWidth = (prioritizeWidth ~= false) -- Default to true if not specified

    local modelWidth = 1.0 -- All panels are 1 unit wide in Blender
    local scaleX, scaleY, scaleZ

    if prioritizeWidth then
        -- Base uniform scale on width
        local uniformScale = width / (modelWidth * 2)
        scaleX = uniformScale
        -- Stretch height to fit desired height
        scaleY = height / (modelHeight * 2)
        scaleZ = scaleX
    else
        -- Base uniform scale on height
        local uniformScale = height / (modelHeight * 2)
        scaleY = uniformScale
        -- Stretch width to fit desired width
        scaleX = width / (modelWidth * 2)
        scaleZ = scaleX
    end

    return vec3(scaleX, scaleY, scaleZ)
end

return utilities
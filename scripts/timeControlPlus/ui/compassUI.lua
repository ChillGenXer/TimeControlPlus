local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4
local mat3Rotate = mjm.mat3Rotate
local mat3Identity = mjm.mat3Identity
local material = mjrequire "common/material"
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local weather = mjrequire "common/weather"

local compassUI = {}
local geoPositionPanel = nil
local temperatureTextView = nil

local spinCompassNeedle = true -- Set to true for the compass needle to spin, false for the background to spin

-- Translate the player pre-render position to a latitude, longitude, elevation and bearing
local function getPlayerGeoCoords(position, lookDirection)
    local earthRadius = 8388608.0 -- Defined in the mj module. Meters from center of earth to sea level

    -- Calculate the magnitude of the position vector
    local r = math.sqrt(position.x^2 + position.y^2 + position.z^2)

    -- Latitude in degrees: angle from equatorial plane
    local lat_value = math.asin(position.y / r) * (180 / math.pi)
    local lat_num = string.format("%.4f", math.abs(lat_value))
    local latitude = lat_num .. (lat_value >= 0 and "°N" or "°S")

    -- Longitude in degrees: angle around the y-axis from (1,0,0)
    local long_value = -math.atan2(position.z, position.x) * (180 / math.pi)
    local long_num = string.format("%.4f", math.abs(long_value))
    local longitude = long_num .. (long_value >= 0 and "°E" or "°W")

    -- Elevation: height above/below sea level
    local elevation_m = (r - 1.0) * earthRadius 
    elevation_m = math.floor(elevation_m + 0.5) -- Round to nearest meter
    local elevation
    if math.abs(elevation_m) > 10000 then
        local elevation_km = math.floor(elevation_m / 1000 + 0.5)
        elevation = elevation_km .. " km"
    else
        elevation = elevation_m .. "m"
    end

    -- Calculate bearing and direction
    -- The player's position defines the local "up" direction (radial from the sphere's center)
    local up = mjm.normalize(position)

    -- Project the look direction onto the tangent plane (remove the component along the up direction)
    local lookProjected = lookDirection - up * mjm.dot(lookDirection, up)
    if mjm.length(lookProjected) < 1e-6 then
        -- If the look direction is parallel to up, return a default bearing
        return {
            latitude = latitude,
            longitude = longitude,
            elevation = elevation,
            bearing = 0,
            direction = "North"
        }
    end
    lookProjected = mjm.normalize(lookProjected)

    -- Define North as the direction toward the North Pole (0, 1, 0) in world space
    local north = vec3(0, 1, 0)

    -- Project North onto the same tangent plane
    local northProjected = north - up * mjm.dot(north, up)
    northProjected = mjm.normalize(northProjected)

    -- Define East in the tangent plane (perpendicular to up and northProjected)
    local east = mjm.cross(up, northProjected)
    east = mjm.normalize(east)

    -- Compute the components of lookProjected in the tangent plane's coordinate system
    local northComponent = mjm.dot(lookProjected, northProjected)
    local eastComponent = mjm.dot(lookProjected, east)

    -- Calculate the angle using atan2
    local angleRad = math.atan2(eastComponent, northComponent)

    -- Convert to degrees and normalize to 0-360
    local bearing = math.deg(angleRad)
    bearing = (bearing + 360) % 360

    -- Map the bearing to a cardinal direction
    local direction
    if bearing >= 337.5 or bearing < 22.5 then
        direction = "N"
    elseif bearing >= 22.5 and bearing < 67.5 then
        direction = "NW"
    elseif bearing >= 67.5 and bearing < 112.5 then
        direction = "W"
    elseif bearing >= 112.5 and bearing < 157.5 then
        direction = "SW"
    elseif bearing >= 157.5 and bearing < 202.5 then
        direction = "S"
    elseif bearing >= 202.5 and bearing < 247.5 then
        direction = "SE"
    elseif bearing >= 247.5 and bearing < 292.5 then
        direction = "E"
    elseif bearing >= 292.5 and bearing < 337.5 then
        direction = "NE"
    end

    -- Return the combined coordinates, bearing, and direction
    return {
        latitude = latitude,
        latitudeNum = lat_value,
        latitudeDir = lat_value >= 0 and "°N" or "°S",
        longitude = longitude,
        longitudeNum = long_value,
        longitudeDir = long_value >= 0 and "°E" or "°W",
        elevation = elevation,
        bearing = bearing,
        direction = direction
    }
end

-- Get the region of the globe that the player is in
local function getGlobeRegion(lat, lon)
    -- Check for nil inputs
    if lat == nil or lon == nil then
        return "Space"
    end

    -- Constants
    local range = 0.1                   -- Tolerance for special zones
    local northTropic = 23.5            -- Tropic of Cancer
    local southTropic = -23.5           -- Tropic of Capricorn
    local northPolarCircle = 66.5       -- Arctic Circle
    local southPolarCircle = -66.5      -- Antarctic Circle
    local poleThreshold = 89.9          -- Threshold for poles
    local primeMeridianThreshold = 0.1  -- Threshold for Prime Meridian
    local antimeridianThreshold = 179.9 -- Threshold for Antimeridian

    -- 1. Check for poles
    if lat >= poleThreshold then
        return "North Pole"
    elseif lat <= -poleThreshold then
        return "South Pole"
    end

    -- 2. Check for special longitudes
    if math.abs(lon) <= primeMeridianThreshold then
        return "Prime Meridian"
    elseif math.abs(lon) >= antimeridianThreshold then
        return "Antimeridian"
    end

    -- 3. Check for special latitude lines
    if math.abs(lat) <= range then
        return "Equator"
    elseif math.abs(lat - northPolarCircle) <= range then
        return "Arctic Circle"
    elseif math.abs(lat - southPolarCircle) <= range then
        return "Antarctic Circle"
    end

    -- 4. General latitude zones
    if lat > northPolarCircle then
        return "Arctic"
    elseif lat < southPolarCircle then
        return "Antarctic"
    elseif lat > northTropic then
        return "North Temperate"
    elseif lat < southTropic then
        return "South Temperate"
    elseif lat >= 0 then
        return "North Tropics"
    else
        return "South Tropics"
    end
end

-- Handler for the vanilla function to receive updated player temperature information
function compassUI:playerTemperatureZoneChanged(newTemperatureZoneIndex)
    -- Set the text to the temperature zone name
    temperatureTextView.text = weather.temperatureZones[newTemperatureZoneIndex].name

    -- Define temperature colors as vec4 (RGBA)
    local temperatureColors = {
        [1] = vec4(0.2, 0.6, 1.0, 1.0), -- Very Cold: Icy blue
        [2] = vec4(0.4, 0.8, 1.0, 1.0), -- Cold: Sky blue
        [3] = vec4(0.8, 1.0, 0.4, 1.0), -- Warm: Yellowish-green
        [4] = vec4(1.0, 0.6, 0.2, 1.0), -- Hot: Orange
        [5] = vec4(1.0, 0.2, 0.2, 1.0)  -- Very Hot: Red
    }

    -- Set the text color based on the temperature zone index
    temperatureTextView.color = temperatureColors[newTemperatureZoneIndex] or vec4(0.0, 0.0, 0.0, 1.0)
end

-- Create the compass
function compassUI:init(gameUI, world)

    local geoPositionPanelSize = vec2(300.0, 60.0)
    local geoPanelScaleToUseX = geoPositionPanelSize.x * 0.5
    local geoPanelScaleToUsey = geoPositionPanelSize.y * 0.5 / 0.2
    local geoPositionPanelScale = vec3(geoPanelScaleToUseX, geoPanelScaleToUsey, geoPanelScaleToUseX)
    local geoPositionPanelBaseOffset = vec3(0, -10, 0)
    local geoPositionPanelAlpha = 0.9

    geoPositionPanel = ModelView.new(gameUI.view)
    geoPositionPanel:setModel(model:modelIndexForName("ui_panel_10x2"))
    geoPositionPanel.hidden = false
    geoPositionPanel.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    geoPositionPanel.baseOffset = geoPositionPanelBaseOffset
    geoPositionPanel.scale3D = geoPositionPanelScale
    geoPositionPanel.size = geoPositionPanelSize
    geoPositionPanel.alpha = geoPositionPanelAlpha

    --Latitude  Text
    local blueHighlightColor = vec4(0.6,0.8,1.0,1.0)
    local xPosTextBaseOffset = vec3(10, -4, 0)
    local xPosText = TextView.new(geoPositionPanel)
    xPosText.font = Font(uiCommon.fontName, 18)
    xPosText.color = blueHighlightColor
    xPosText.relativeView = geoPositionPanel
    xPosText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    xPosText.baseOffset = xPosTextBaseOffset
    xPosText.text = "--"

    --Longitude Text
    local yPosTextBaseOffset = vec3(-10, -4, 0)
    local yPosText = TextView.new(geoPositionPanel)
    yPosText.font = Font(uiCommon.fontName, 18)
    yPosText.color = blueHighlightColor
    yPosText.relativeView = geoPositionPanel
    yPosText.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    yPosText.baseOffset =  yPosTextBaseOffset
    yPosText.text = "--"

    --Local Temperature
    temperatureTextView = TextView.new(geoPositionPanel)
    temperatureTextView.font = Font(uiCommon.fontName, 14)
    temperatureTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    temperatureTextView.baseOffset = vec3(10,-2,0)
    temperatureTextView.text = ""    

    --Global Region
    local globalRegionTextBaseOffset = vec3(10, 14, 0)
    local globalRegionText = TextView.new(geoPositionPanel)
    globalRegionText.color = vec4(1.0, 1.0, 1.0, 1.0)
    globalRegionText.font = Font(uiCommon.fontName, 14)
    globalRegionText.relativeView = geoPositionPanel
    globalRegionText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    globalRegionText.baseOffset = globalRegionTextBaseOffset
    globalRegionText.text = "--"    

    --Elevation Text
    local zPosTextBaseOffset = vec3(-10, 14, 0)
    local zPosText = TextView.new(geoPositionPanel)
    zPosText.color = vec4(1.0, 1.0, 1.0, 1.0)
    zPosText.font = Font(uiCommon.fontName, 14)
    zPosText.relativeView = geoPositionPanel
    zPosText.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    zPosText.baseOffset = zPosTextBaseOffset
    zPosText.text = "--"

    geoPositionPanel.update = function(dt)
        -- Where in the world is the player
        local rawPlayerPos = world:getRealPlayerHeadPos()
        local rawPlayerDirection = world:getRealPlayerLookDirection()
        local playerPosition = getPlayerGeoCoords(rawPlayerPos, rawPlayerDirection)

        -- Update the UI
        if playerPosition then
            xPosText.text = playerPosition.latitude
            yPosText.text = playerPosition.longitude
            zPosText.text = "Elev: " .. playerPosition.elevation
            globalRegionText.text = getGlobeRegion(playerPosition.latitudeNum, playerPosition.longitudeNum)
        else
            xPosText.text = "--"
            yPosText.text = "--"
            zPosText.text = "--"
            globalRegionText.text = "--"
        end
    end

    -- compass
    local compassCircleViewSize = 55.0
    local compassBackgroundModel = "ui_circleBackgroundLarge"
    local compassBackgroundSize = vec2(compassCircleViewSize, compassCircleViewSize)
    local compassCircleBackgroundScale = compassCircleViewSize * 0.5
    local compassBackgroundScale3D = vec3(compassCircleBackgroundScale, compassCircleBackgroundScale, compassCircleBackgroundScale)
    local compassBackgroundBaseOffset = vec3(0.0, 0.0, 1.0)
    local compassBackgroundAlpha = 1.0
    local compassHandModel = "ui_clockHand"
    local compassHandSize = vec2(compassCircleViewSize, compassCircleViewSize)

    local compassBackground = ModelView.new(geoPositionPanel)
    compassBackground:setModel(model:modelIndexForName(compassBackgroundModel), {default = material.types.star1.index})
    compassBackground.relativeView = geoPositionPanel
    compassBackground.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    compassBackground.scale3D = compassBackgroundScale3D
    compassBackground.size = compassBackgroundSize
    compassBackground.baseOffset = compassBackgroundBaseOffset
    compassBackground.alpha = compassBackgroundAlpha
    compassBackground.update = function(dt)
        -- Get the player's position and look direction
        local rawPlayerPos = world:getRealPlayerHeadPos()
        local rawPlayerDirection = world:getRealPlayerLookDirection()
        
        -- Get the player's geographical coordinates and bearing
        local playerPosition = getPlayerGeoCoords(rawPlayerPos, rawPlayerDirection)
        
        if playerPosition and playerPosition.bearing then
            if spinCompassNeedle then
                -- Original design: background static
                compassBackground.rotation = mat3Rotate(mat3Identity, 0, vec3(0.0, 0.0, 1.0))
            else
                -- New design: background spins
                local zRotation = math.rad(-playerPosition.bearing)
                compassBackground.rotation = mat3Rotate(mat3Identity, zRotation, vec3(0.0, 0.0, 1.0))
            end
        end
    end

    -- geoPosition Icon
    local worldIcon = ModelView.new(compassBackground)
    worldIcon:setModel(model:modelIndexForName("icon_map"), {default = material.types.ui_standard.index})
    local worldIconSizeBase = 30.5
    local worldIconSize = vec2(worldIconSizeBase, worldIconSizeBase) * 2.0
    local worldIconScale = vec3(worldIconSizeBase, worldIconSizeBase, worldIconSizeBase)
    worldIcon.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    worldIcon.relativeView = compassBackground
    worldIcon.baseOffset = vec3(0.0, 0.0, 2.0)
    worldIcon.scale3D = worldIconScale
    worldIcon.size = worldIconSize
    worldIcon.masksEvents = false
    worldIcon.hidden = false

    -- Compass Hand
    local compassHandBaseOffset = vec3(0.0, -1.0, 4)
    local compassHand = ModelView.new(geoPositionPanel)
    compassHand:setModel(model:modelIndexForName(compassHandModel), {default = material.types.ui_bronze.index})
    compassHand.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    compassHand.relativeView = geoPositionPanel
    compassHand.scale3D = compassBackgroundScale3D
    compassHand.size = compassHandSize
    compassHand.baseOffset = compassHandBaseOffset
    compassHand.update = function(dt)
        -- Get the player's position and look direction
        local rawPlayerPos = world:getRealPlayerHeadPos()
        local rawPlayerDirection = world:getRealPlayerLookDirection()
        
        -- Get the player's geographical coordinates and bearing
        local playerPosition = getPlayerGeoCoords(rawPlayerPos, rawPlayerDirection)
        
        if playerPosition and playerPosition.bearing then
            if spinCompassNeedle then
                -- Original design: needle spins
                local zRotation = math.rad(playerPosition.bearing)
                compassHand.rotation = mat3Rotate(mat3Identity, zRotation, vec3(0.0, 0.0, 1.0))
            else
                -- New design: needle static
                compassHand.rotation = mat3Rotate(mat3Identity, 0, vec3(0.0, 0.0, 1.0))
            end
        end
    end

    --Compass Cardinal Directions Text
    local compassTextColor = vec4(0.0,0.0,0.0,2.0)
    local compassTextFontSize = 12

    -- NORTH
    local compassNorthTextBaseOffset = vec3(-1, 0.0, 2.2)
    local compassNorthText = TextView.new(compassBackground)
    compassNorthText.color = compassTextColor
    compassNorthText.font = Font(uiCommon.fontName, compassTextFontSize)
    compassNorthText.relativeView = compassBackground
    compassNorthText.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    compassNorthText.baseOffset = compassNorthTextBaseOffset
    compassNorthText.text = "N"

    -- SOUTH
    local compassSouthTextBaseOffset = vec3(-1.0, -3.0, 2.2)
    local compassSouthText = TextView.new(compassBackground)
    compassSouthText.color = compassTextColor
    compassSouthText.font = Font(uiCommon.fontName, compassTextFontSize)
    compassSouthText.relativeView = compassBackground
    compassSouthText.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    compassSouthText.baseOffset = compassSouthTextBaseOffset
    compassSouthText.text = "S"

    -- WEST
    local compassWestTextBaseOffset = vec3(0.0, 17.0, 2.2)
    local compassWestText = TextView.new(compassBackground)
    compassWestText.color = compassTextColor
    compassWestText.font = Font(uiCommon.fontName, compassTextFontSize)
    compassWestText.relativeView = compassBackground
    compassWestText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    compassWestText.baseOffset = compassWestTextBaseOffset
    compassWestText.text = "W"

    -- EAST
    local compassEastTextBaseOffset = vec3(-3.0, 17.0, 2.2)
    local compassEastText = TextView.new(compassBackground)
    compassEastText.color = compassTextColor
    compassEastText.font = Font(uiCommon.fontName, compassTextFontSize)
    compassEastText.relativeView = compassBackground
    compassEastText.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    compassEastText.baseOffset = compassEastTextBaseOffset
    compassEastText.text = "E"
end

-- Show the compass control
function compassUI:show()
    if geoPositionPanel then
        geoPositionPanel.hidden = false
    end
end

-- Hide the compass control
function compassUI:hide()
    if geoPositionPanel then
        geoPositionPanel.hidden = true
    end
end

return compassUI
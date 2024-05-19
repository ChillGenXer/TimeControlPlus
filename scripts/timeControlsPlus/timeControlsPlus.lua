local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local mat3Rotate = mjm.mat3Rotate
local mat3Identity = mjm.mat3Identity
local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local weather = mjrequire "common/weather"
local gameConstants = mjrequire "common/gameConstants"
local material = mjrequire "common/material"
local audio = mjrequire "mainThread/audio"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local timeControls = {}
local mainView = nil
local buttonsBySpeedIndex = {}
local currentServerSpeedIndex = nil
local currentLocalSpeedIndex = nil
local temperatureTextView = nil
local panelView = nil
local currentlyUltraSpeed = false
local toolTipOffset = vec3(0,-10,0)
local connectionAlertIcon = nil -- Declare a local variable to store the connection alert icon, initially nil (not created).

--TimeControlPlus Imports
local localPlayer = mjrequire "mainThread/localPlayer"
local dot = mjm.dot

--TimeControlPlus Functions

---Rounds the given number
local function round(n)
    return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

-- ******************** VANILLA FUNCTIONS ********************

-- Define a local function to handle changes in server speed multipliers.
local function serverSpeedMultiplierChanged(speedMultiplier, speedMultiplierIndex)
    -- Commented out logging statement that could be used for debugging
    -- mj:log("speedMultiplierChanged:", speedMultiplier, " speedMultiplierIndex:", speedMultiplierIndex, " currentSpeedIndex:", currentSpeedIndex)

    -- Initialize a flag to check if the new speed is considered "Ultra Speed"
    local newIsUltraSpeed = false

    -- If the new speed multiplier exceeds the defined fast speed threshold by 0.5, set newIsUltraSpeed to true
    if speedMultiplier > gameConstants.fastSpeed + 0.5 then
        newIsUltraSpeed = true
    end

    -- Check if there is a change in the ultra speed status
    if newIsUltraSpeed ~= currentlyUltraSpeed then
        -- Update the current ultra speed status
        currentlyUltraSpeed = newIsUltraSpeed

        -- Play the appropriate sound effect based on whether the new speed is ultra or not
        if newIsUltraSpeed then
            audio:playUISound("audio/sounds/ui/speedup.wav")
        else
            audio:playUISound("audio/sounds/ui/slowdown.wav")
        end
    end

    -- Check if the current server speed index has changed
    if currentServerSpeedIndex ~= speedMultiplierIndex then
        -- If the current server speed index is not nil, deselect the previously selected button
        if currentServerSpeedIndex ~= nil then
            local button = buttonsBySpeedIndex[currentServerSpeedIndex]
            uiStandardButton:setSelected(button, false)
        end

        -- Update the current server speed index
        currentServerSpeedIndex = speedMultiplierIndex

        -- Ensure that the button index does not exceed predefined bounds (hardcoded to 1 and 2 here)
        if not buttonsBySpeedIndex[currentServerSpeedIndex] then
            if currentServerSpeedIndex > 2 then
                currentServerSpeedIndex = 2
            else
                currentServerSpeedIndex = 1
            end
        end

        -- Select the button corresponding to the new server speed index
        local button = buttonsBySpeedIndex[currentServerSpeedIndex]
        uiStandardButton:setSelected(button, true)
    end
end

-- Define a function within the timeControls table to update the local speed preference based on a given index.
function timeControls:updateLocalSpeedPreference(speedMultiplierIndex)
    -- Check if the provided speedMultiplierIndex is different from the current local speed index.
    if speedMultiplierIndex ~= currentLocalSpeedIndex then
        -- If the current local speed index is not nil, meaning there is a previously selected speed, proceed to deselect it.
        if currentLocalSpeedIndex ~= nil then
            -- Retrieve the button corresponding to the current local speed index.
            local button = buttonsBySpeedIndex[currentLocalSpeedIndex]
            -- Deselect the button by setting its secondary selected state to false.
            uiStandardButton:setSecondarySelected(button, false)
        end

        -- Update the current local speed index to the new value.
        currentLocalSpeedIndex = speedMultiplierIndex

        -- Retrieve the button corresponding to the new local speed index.
        local button = buttonsBySpeedIndex[currentLocalSpeedIndex]
        -- Select this button by setting its secondary selected state to true.
        uiStandardButton:setSecondarySelected(button, true)
    end
end

function timeControls:getLocalSpeedPreference()
    return currentLocalSpeedIndex or 0
end

function timeControls:init(gameUI, world)

    mainView = View.new(gameUI.view)
    mainView.hidden = false
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    mainView.baseOffset = vec3(10.0, -10.0, 0.0)

    local circleViewSize = 60.0
    local panelSizeToUse = vec2(170.0, 60.0)
    local panelXOffset = -30.0
    mainView.size = vec2(circleViewSize + panelSizeToUse.x - panelXOffset, 60.0)

    local circleBackgroundScale = circleViewSize * 0.5

    local clockBackground = ModelView.new(mainView)
    clockBackground:setModel(model:modelIndexForName("ui_clockBackground"))
    clockBackground.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    clockBackground.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
    clockBackground.size = vec2(circleViewSize, circleViewSize)
    clockBackground.baseOffset = vec3(0.0, 0.0, 0.0)
    clockBackground.alpha = 0.9

    local clockHand = ModelView.new(mainView)
    clockHand:setModel(model:modelIndexForName("ui_clockMark"))
    clockHand.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    clockHand.relativeView = clockBackground
    clockHand.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
    clockHand.size = vec2(circleViewSize, circleViewSize)
    clockHand.baseOffset = vec3(0.0, 0.0, 0.02 * circleBackgroundScale)

    clockHand.update = function(dt)
        local timeOfDayFraction = world:getTimeOfDayFraction()
        local zRotation = (timeOfDayFraction + 0.5) * math.pi * 2.0
        clockHand.rotation = mat3Rotate(mat3Identity, zRotation, vec3(0.0,0.0,-1.0))
    end

    local panelScaleToUseX = panelSizeToUse.x * 0.5
    local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2
    
    panelView = ModelView.new(mainView)
    panelView:setModel(model:modelIndexForName("ui_panel_10x2"))
    panelView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    panelView.relativeView = clockBackground
    panelView.baseOffset = vec3(panelXOffset, 0.0, -2)
    panelView.scale3D = vec3(panelScaleToUseX,panelScaleToUseY,panelScaleToUseX)
    panelView.size = panelSizeToUse
    panelView.alpha = 0.9

    local timeButtonSize = 30.0
    local timeButtonInitialXOffsetWithinPanel = 45.0
    local timeButtonInitialYOffsetWithinPanel = -6.0
    local timeButtonXPadding = 10.0

    
    temperatureTextView = TextView.new(panelView)
    temperatureTextView.font = Font(uiCommon.fontName, 16)
    temperatureTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    temperatureTextView.baseOffset = vec3(0,-4,0)
    temperatureTextView.text = ""
    
    local pauseButton = uiStandardButton:create(panelView, vec2(timeButtonSize,timeButtonSize), uiStandardButton.types.timeControl)
    pauseButton.userData.selectionCircleMaterial = material.types.ui_red.index
    pauseButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    pauseButton.baseOffset = vec3(timeButtonInitialXOffsetWithinPanel, timeButtonInitialYOffsetWithinPanel, 2)
    uiStandardButton:setIconModel(pauseButton, "icon_pause")
    buttonsBySpeedIndex[0] = pauseButton
    uiStandardButton:setClickFunction(pauseButton, function()
        world:setPaused()
        timeControls:updateLocalSpeedPreference(0)
    end)
    uiToolTip:add(pauseButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_pause"), nil, toolTipOffset, nil, pauseButton)
    uiToolTip:addKeyboardShortcut(pauseButton.userData.backgroundView, "game", "pause", nil, nil)
    
    local playButton = uiStandardButton:create(panelView, vec2(timeButtonSize,timeButtonSize), uiStandardButton.types.timeControl)
    playButton.relativeView = pauseButton
    playButton.userData.selectionCircleMaterial = material.types.ui_green.index
    playButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    playButton.baseOffset = vec3(timeButtonXPadding, 0, 0)
    uiStandardButton:setIconModel(playButton, "icon_play")
    buttonsBySpeedIndex[1] = playButton
    uiStandardButton:setClickFunction(playButton, function()
        world:setPlay()
        timeControls:updateLocalSpeedPreference(1)
    end)
    uiToolTip:add(playButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_play"), nil, toolTipOffset, nil, playButton)
    
    
    local ffButton = uiStandardButton:create(panelView, vec2(timeButtonSize,timeButtonSize), uiStandardButton.types.timeControl)
    ffButton.relativeView = playButton
    ffButton.userData.selectionCircleMaterial = material.types.ui_selected.index
    ffButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    ffButton.baseOffset = vec3(timeButtonXPadding, 0, 0)
    uiStandardButton:setIconModel(ffButton, "icon_fastForward")
    buttonsBySpeedIndex[2] = ffButton
    uiStandardButton:setClickFunction(ffButton, function()
        world:setFastForward()
        timeControls:updateLocalSpeedPreference(2)
    end)
    uiToolTip:add(ffButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_fastForward"), nil, toolTipOffset, nil, ffButton)
    uiToolTip:addKeyboardShortcut(ffButton.userData.backgroundView, "game", "speedFast", nil, nil)


    temperatureTextView.relativeView = pauseButton
    


    world:addSpeedChangeListener(serverSpeedMultiplierChanged)
    timeControls:updateLocalSpeedPreference(1)
    serverSpeedMultiplierChanged(world:getSpeedMultiplier(), world:getSpeedMultiplierIndex())
end

function timeControls:setHiddenForTribeSelection(newHidden)
    mainView.hidden = newHidden
end

function timeControls:playerTemperatureZoneChanged(newTemperatureZoneIndex)
    --temperatureTextView.text = weather.temperatureZones[newTemperatureZoneIndex].name
    temperatureTextView.text = "0.5 Baseline"
end

-- Define a function within the timeControls table to handle changes in ping value.
function timeControls:setPingValue(currentPingValue)
    -- Check if the current ping value exceeds 10.0 milliseconds.
    if currentPingValue > 10.0 then
        -- If the connection alert icon does not exist yet, create it.
        if not connectionAlertIcon then
            -- Create a new model view for the alert icon within the main view.
            connectionAlertIcon = ModelView.new(mainView)
            -- Define the size of the icon.
            local iconSize = 30
            -- Set the position of the icon relative to another view (panelView).
            connectionAlertIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
            connectionAlertIcon.relativeView = panelView
            -- Set the base offset of the icon.
            connectionAlertIcon.baseOffset = vec3(10, 0.0, 0)
            -- Set the scale of the icon.
            connectionAlertIcon.scale3D = vec3(iconSize, iconSize, iconSize) * 0.5
            -- Set the size of the icon.
            connectionAlertIcon.size = vec2(iconSize, iconSize)

            -- Add a tooltip to the icon to provide more information on hover.
            uiToolTip:add(connectionAlertIcon, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_slowConnection"), nil, toolTipOffset, nil, nil)

            -- Initialize an animation timer.
            local animationTimer = 0.0
            -- Define an update function for the icon to handle animations.
            connectionAlertIcon.update = function(dt)
                local timerValue = animationTimer or 0.0
                timerValue = timerValue + dt
                animationTimer = timerValue
                local animationAddition = (1.0 + math.sin(timerValue * 5.0)) * 0.5
                -- Uncomment the following lines to scale the icon size based on animationAddition.
                -- local iconSizeAnimated = iconSize * (1.0 + animationAddition * 0.1)
                -- connectionAlertIcon.scale3D = vec3(iconSizeAnimated, iconSizeAnimated, iconSizeAnimated) * 0.5
                -- connectionAlertIcon.size = vec2(iconSizeAnimated, iconSizeAnimated)
                -- Set the transparency of the icon based on the animation.
                connectionAlertIcon.alpha = 1.0 + animationAddition
            end
        end
        -- Make the icon visible if it was previously hidden.
        connectionAlertIcon.hidden = false
        -- Change the icon's appearance based on the severity of the ping value.
        if currentPingValue > gameConstants.disconnectDelayThreshold * 0.5 then
            connectionAlertIcon:setModel(model:modelIndexForName("icon_connectionAlert"), {
                [material.types.ui_standard.index] = material.types.ui_red.index,
            })
        else
            connectionAlertIcon:setModel(model:modelIndexForName("icon_connectionAlert"), {
                [material.types.ui_standard.index] = material.types.ui_yellow.index,
            })
        end
    -- If the ping is within an acceptable range, hide the connection alert icon.
    elseif connectionAlertIcon then
        connectionAlertIcon.hidden = true
    end
end

return timeControls
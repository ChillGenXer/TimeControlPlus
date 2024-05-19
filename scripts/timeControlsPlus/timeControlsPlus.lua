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

--local keyMapping = mjrequire "mainThread/keyMapping"
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


local function serverSpeedMultiplierChanged(speedMultiplier, speedMultiplierIndex)

    --mj:log("speedMultiplierChanged:", speedMultiplier, " speedMultiplierIndex:", speedMultiplierIndex, " currentSpeedIndex:", currentSpeedIndex)

    local newIsUltraSpeed = false
    if speedMultiplier > gameConstants.fastSpeed + 0.5 then
        newIsUltraSpeed = true
    end

    if newIsUltraSpeed ~= currentlyUltraSpeed then
        currentlyUltraSpeed = newIsUltraSpeed
        if newIsUltraSpeed then
            audio:playUISound("audio/sounds/ui/speedup.wav")
        else
            audio:playUISound("audio/sounds/ui/slowdown.wav")
        end
    end

    if currentServerSpeedIndex ~= speedMultiplierIndex then
        if currentServerSpeedIndex ~= nil then
            local button = buttonsBySpeedIndex[currentServerSpeedIndex]
            uiStandardButton:setSelected(button, false)
        end

        currentServerSpeedIndex = speedMultiplierIndex
        if not buttonsBySpeedIndex[currentServerSpeedIndex] then
            if currentServerSpeedIndex > 2 then
                currentServerSpeedIndex = 2
            else
                currentServerSpeedIndex = 1
            end
        end

        local button = buttonsBySpeedIndex[currentServerSpeedIndex]
        uiStandardButton:setSelected(button, true)

    end
end


function timeControls:updateLocalSpeedPreference(speedMultiplierIndex)
    if speedMultiplierIndex ~= currentLocalSpeedIndex then
        if currentLocalSpeedIndex ~= nil then
            local button = buttonsBySpeedIndex[currentLocalSpeedIndex]
            uiStandardButton:setSecondarySelected(button, false)
        end

        currentLocalSpeedIndex = speedMultiplierIndex

        local button = buttonsBySpeedIndex[currentLocalSpeedIndex]
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

local connectionAlertIcon = nil
function timeControls:setPingValue(currentPingValue)
    if currentPingValue > 10.0 then
        if not connectionAlertIcon then

            connectionAlertIcon = ModelView.new(mainView)
            local iconSize = 30
            connectionAlertIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
            connectionAlertIcon.relativeView = panelView
            connectionAlertIcon.baseOffset = vec3(10, 0.0, 0)
            connectionAlertIcon.scale3D = vec3(iconSize,iconSize,iconSize) * 0.5
            connectionAlertIcon.size = vec2(iconSize, iconSize)

            uiToolTip:add(connectionAlertIcon, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_slowConnection"), nil, toolTipOffset, nil, nil)

            local animationTimer = 0.0
            connectionAlertIcon.update = function(dt)
                local timerValue = animationTimer or 0.0
                timerValue = timerValue + dt
                animationTimer = timerValue
                local animationAddition = (1.0 + math.sin(timerValue * 5.0)) * 0.5
                --local iconSizeAnimated = iconSize * (1.0 + animationAddition * 0.1)
                --connectionAlertIcon.scale3D = vec3(iconSizeAnimated,iconSizeAnimated,iconSizeAnimated) * 0.5
                --connectionAlertIcon.size = vec2(iconSizeAnimated, iconSizeAnimated)
                connectionAlertIcon.alpha = 1.0 + animationAddition
            end
        end
        connectionAlertIcon.hidden = false
        if currentPingValue > gameConstants.disconnectDelayThreshold * 0.5 then
            connectionAlertIcon:setModel(model:modelIndexForName("icon_connectionAlert"), {
                [material.types.ui_standard.index] = material.types.ui_red.index,
            })
        else
            connectionAlertIcon:setModel(model:modelIndexForName("icon_connectionAlert"), {
                [material.types.ui_standard.index] = material.types.ui_yellow.index,
            })
        end
    elseif connectionAlertIcon then
        connectionAlertIcon.hidden = true
    end
end


return timeControls
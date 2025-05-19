local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4
local dot = mjm.dot
local mat3Rotate = mjm.mat3Rotate
local mat3Identity = mjm.mat3Identity
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local material = mjrequire "common/material"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local audio = mjrequire "mainThread/audio"
local gameConstants = mjrequire "common/gameConstants"
local gameObject = mjrequire "common/gameObject"
local notification = mjrequire "common/notification"
local locale = mjrequire "common/locale"

local buttonsBySpeedIndex = {}
local currentServerSpeedIndex = nil
local currentLocalSpeedIndex = nil
local currentlyUltraSpeed = false
local panelView = nil
local ffButton = nil
local fffButton = nil
local clockBookend = nil
local clockBackground = nil
local timeClockText = nil -- The digital clock
local epochText = nil
local chronoView = nil
local seasonText = nil
local currentSeason = nil
local localWorld = nil
local localGameUI = nil
local toolTipOffset = vec3(0, -10, 0)

local timeUI = {}

--- Returns a season object with the appropriate tree model and season name.
local function getSeason()
    -- Object to hold the attributes
    local seasonObject = {
        treeModel = nil,
        seasonText = nil,
        currentYear = nil,
        notificationType = nil,
        notificationObject = nil,
    }

    local playerPosition = localWorld:getRealPlayerHeadPos()
    -- Get the player's position to determine if they are in the southern hemisphere
    local isSouthHemisphere = dot(playerPosition, vec3(0.0, 1.0, 0.0)) < 0.0

    -- Calculate the seasonal fraction: 0.0 is spring, 0.25 summer, 0.5 is autumn, >0.75 winter
    local seasonFraction = math.fmod(localWorld.yearSpeed * localWorld:getWorldTime(), 1.0)

    -- Get the index & HemisphereOffset we need for the lookup table
    local index = math.floor(seasonFraction * 4) % 4 + 1
    local hemisphereOffset = isSouthHemisphere and 2 or 1

    -- Lookup table for getting the right tree model, text, and notification
    local seasonLookupTable = {
        {
            treeModel = { "appleTreeSpring", "appleTreeAutumn" },
            seasonText = { "Spring", "Autumn" },
            seasonNotificationType = { notification.types.newYear.index, notification.types.newYear.index },
            seasonNotificationObject = { { objectTypeIndex = gameObject.types.appleTree.index }, { objectTypeIndex = gameObject.types.appleTree.index } },
        },
        {
            treeModel = { "appleTree", "appleTreeWinter" },
            seasonText = { "Summer", "Winter" },
            seasonNotificationType = { notification.types.summerStarting.index, notification.types.winterStarting.index },
            seasonNotificationObject = { { objectTypeIndex = gameObject.types.appleTree.index }, { objectTypeIndex = gameObject.types.appleTree.index } },
        },
        {
            treeModel = { "appleTreeAutumn", "appleTreeSpring" },
            seasonText = { "Autumn", "Spring" },
            seasonNotificationType = { notification.types.autumnStarting.index, notification.types.springStarting.index },
            seasonNotificationObject = { { objectTypeIndex = gameObject.types.appleTree.index }, { objectTypeIndex = gameObject.types.appleTree.index } },
        },
        {
            treeModel = { "appleTreeWinter", "appleTree" },
            seasonText = { "Winter", "Summer" },
            seasonNotificationType = { notification.types.winterStarting.index, notification.types.summerStarting.index },
            seasonNotificationObject = { { objectTypeIndex = gameObject.types.appleTree.index }, { objectTypeIndex = gameObject.types.appleTree.index } },
        },
    }

    -- Set the season object
    seasonObject.treeModel = seasonLookupTable[index].treeModel[hemisphereOffset]
    seasonObject.seasonText = seasonLookupTable[index].seasonText[hemisphereOffset]
    seasonObject.notificationType = seasonLookupTable[index].seasonNotificationType[hemisphereOffset]
    seasonObject.notificationObject = seasonLookupTable[index].seasonNotificationObject[hemisphereOffset]
    seasonObject.currentYear = tostring(math.floor(math.floor(localWorld:getWorldTime() / localWorld:getDayLength()) / 8) + 1)

    return seasonObject
end

-- MajicJungle
function timeUI:updateLocalSpeedPreference(speedMultiplierIndex)
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

-- MajicJungle
function timeUI:getLocalSpeedPreference()
    return currentLocalSpeedIndex or 0
end

local function serverSpeedMultiplierChanged(speedMultiplier, speedMultiplierIndex)
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

-- MajicJungle: Disables FF if the server doesn't allow it.
function timeUI:setFastForwardDisabledByServer(newIsThrottled)
    if newIsThrottled then
        uiStandardButton:setDisabled(ffButton, true)
        uiToolTip:remove(ffButton.userData.backgroundView)
        uiToolTip:add(ffButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_fastForwardDisabledDueToServerLoad"), nil, toolTipOffset, nil, ffButton)
    else
        uiStandardButton:setDisabled(ffButton, false)
        uiToolTip:remove(ffButton.userData.backgroundView)
        uiToolTip:add(ffButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_fastForward"), nil, toolTipOffset, nil, ffButton)
        uiToolTip:addKeyboardShortcut(ffButton.userData.backgroundView, "game", "speedFast", nil, nil)
    end
end

function timeUI:initializeTimeUI(gameUI, world)

    localWorld = world
    localGameUI = gameUI

    --local daysInYear = localWorld:getYearLength() / localWorld:getDayLength() -- Calculate the number of days in the year
    local gameHourInSeconds = localWorld:getDayLength() / 24 -- Calculate this to future-proof for server owners changing it
    local gameMinuteInSeconds = localWorld:getDayLength() / 1440 -- Calculate how long a game minute is in real-world seconds

    --chronoView
    local chronoViewWidth = 250
    local chronoViewSizeHeight = 200.0
    local chronoViewBaseOffset = vec3(20.0, 10.0, 0.0)
    
    chronoView = View.new(localGameUI.view) -- ColorView.new(localGameUI.view)--
    --chronoView.color = vec4(1.0,1.0,1.0,1.0)
    chronoView.hidden = false
    chronoView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    chronoView.baseOffset = chronoViewBaseOffset
    chronoView.size = vec2(chronoViewWidth, chronoViewSizeHeight)

    -- Clock Background
    local circleViewSize = 100.0
    local clockBackgroundModel = "ui_clockBackground"
    local clockBackgroundSize = vec2(circleViewSize, circleViewSize)
    local circleBackgroundScale = circleViewSize * 0.5
    local clockBackgroundScale3D = vec3(circleBackgroundScale, circleBackgroundScale, circleBackgroundScale)
    local clockBackgroundBaseOffset = vec3(-5.0, 0.0, 1.5)
    local clockBackgroundAlpha = 0.9

    clockBackground = ModelView.new(chronoView)
    clockBackground:setModel(model:modelIndexForName(clockBackgroundModel))
    clockBackground.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    clockBackground.scale3D = clockBackgroundScale3D
    clockBackground.size = clockBackgroundSize
    clockBackground.baseOffset = clockBackgroundBaseOffset
    clockBackground.alpha = clockBackgroundAlpha

    -- Digital Clock
    local timeClockTextBaseOffset = vec3(-4.0, -1.0, 1.8)
    timeClockText = TextView.new(clockBackground)
    timeClockText.font = Font(uiCommon.fontName, 14)
    timeClockText.color = vec4(0.0, 0.0, 0.0, 2.0)
    timeClockText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    --timeClockText.relativeView = myPanelView
    timeClockText.baseOffset = timeClockTextBaseOffset
    timeClockText.update = function(dt)
        local secondsElapsedInDay = localWorld:getWorldTime() % localWorld:getDayLength() -- How many real-world seconds have elapsed in this day
        local gameTimeHour = math.floor(secondsElapsedInDay / gameHourInSeconds) -- The hour to display
        local gameTimeMinute = math.floor((secondsElapsedInDay % gameHourInSeconds) / gameMinuteInSeconds) -- The minute to display
        -- Format the clock digits to add a leading 0 and set the text field
        local txtGameTimeHour = string.format("%02d", gameTimeHour)
        local txtGameTimeMinute = string.format("%02d", gameTimeMinute)
        timeClockText.text = txtGameTimeHour .. ":" .. txtGameTimeMinute
    end

    -- Clock Hand
    local clockHandModel = "ui_clockMark"
    local clockHandSize = vec2(circleViewSize, circleViewSize)
    local clockHandBaseOffset = vec3(0.0, 0.0, 0.02 * circleBackgroundScale)
    local clockHand = ModelView.new(chronoView)
 
    clockHand:setModel(model:modelIndexForName(clockHandModel))
    clockHand.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    clockHand.relativeView = clockBackground
    clockHand.scale3D = clockBackgroundScale3D
    clockHand.size = clockHandSize
    clockHand.baseOffset = clockHandBaseOffset
    clockHand.update = function(dt)
        -- This updates the clock hand on every game tick
        local timeOfDayFraction = localWorld:getTimeOfDayFraction()
        local zRotation = (timeOfDayFraction + 0.5) * math.pi * 2.0
        clockHand.rotation = mat3Rotate(mat3Identity, zRotation, vec3(0.0, 0.0, -1.0))
    end

    -- Speed Control Panel
    local panelSizeToUse = vec2(171.0, 50.0)
    --local panelXOffset = 0.0
    local panelScaleToUseX = panelSizeToUse.x * 0.5
    local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2
    local panelViewModel = "ui_panel_10x2"
    local panelViewBaseOffset = vec3(0, 0.0, -1)
    local panelViewScale3D = vec3(panelScaleToUseX+2, panelScaleToUseY, panelScaleToUseX)
    local panelViewAlpha = 0.9

    panelView = ModelView.new(chronoView)
    panelView:setModel(model:modelIndexForName(panelViewModel))
    panelView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    --panelView.relativeView = clockBookend
    panelView.baseOffset = panelViewBaseOffset
    panelView.scale3D = panelViewScale3D
    panelView.size = panelSizeToUse
    panelView.alpha = panelViewAlpha

    -- Clock Bookend
    local clockBookendModel = "ui_inspectExtraSingle"
    local clockBookendBaseSize = 171
    local clockBookendSize = vec2(clockBookendBaseSize, clockBookendBaseSize/2)
    local clockBookendScale = clockBookendBaseSize * 0.5
    local clockBookendScale3D = vec3(clockBookendScale, clockBookendScale+50, clockBookendScale-70)
    local clockBookendBaseOffset = vec3(0, -35.0, 0.0)
    local clockBookendAlpha = 0.9

    clockBookend = ModelView.new(chronoView)
    clockBookend:setModel(model:modelIndexForName(clockBookendModel))
    clockBookend.relativeView = panelView
    clockBookend.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)
    clockBookend.scale3D = clockBookendScale3D
    clockBookend.size = clockBookendSize
    clockBookend.baseOffset = clockBookendBaseOffset
    clockBookend.alpha = clockBookendAlpha

    -- Season Text
    local seasonTextBaseOffset = vec3(-3.0, 30.0, 1.8)
    seasonText = TextView.new(clockBookend)
    seasonText.font = Font(uiCommon.fontName, 18)
    seasonText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    --timeClockText.relativeView = myPanelView
    seasonText.baseOffset = seasonTextBaseOffset
    local seasonUpdateTimer = 0
    
    local epochTextBaseOffset = vec3(-3.0, 10.0, 1.8)
    epochText = TextView.new(clockBookend)
    epochText.color = mj.textColor
    epochText.font = Font(uiCommon.fontName, 12)
    epochText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    epochText.baseOffset = epochTextBaseOffset
    
    seasonText.update = function(dt)
        -- Accumulate delta time
        seasonUpdateTimer = seasonUpdateTimer + dt
        -- Only update if at least 1 second has passed
        if seasonUpdateTimer >= 1.0 then
            currentSeason = getSeason()
            seasonText.text = currentSeason.seasonText
            if currentSeason.seasonText == "Spring" then
                seasonText.color = vec4(0.68, 0.85, 0.47, 2.0) -- Light "new sprout" green
            elseif currentSeason.seasonText == "Summer" then
                seasonText.color = vec4(0.24, 0.55, 0.31, 2.0) -- Darker richer green
            elseif currentSeason.seasonText == "Autumn" then 
                seasonText.color = vec4(0.82, 0.41, 0.20, 2.0) -- Rusty leaf color
            elseif currentSeason.seasonText == "Winter" then
                seasonText.color = vec4(0.53, 0.81, 0.92, 2.0) -- Icy blue
            else
                seasonText.color = vec4(1.0, 1.0, 1.0, 2.0) -- Default to white if season is unrecognized
            end
            
            epochText.text = "Year " .. currentSeason.currentYear .. " - Genesis Epoch" 
            -- Reset timer
            seasonUpdateTimer = 0
        end
    end

    local timeButtonSize = 30.0
    local timeButtonInitialXOffsetWithinPanel = 10.0
    local timeButtonInitialYOffsetWithinPanel = -9.0
    local timeButtonXPadding = 10.0

    -- Pause Button
    local pauseButton = uiStandardButton:create(chronoView, vec2(timeButtonSize, timeButtonSize), uiStandardButton.types.timeControl)
    pauseButton.userData.selectionCircleMaterial = material.types.ui_red.index
    pauseButton.relativeView = panelView
    pauseButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    pauseButton.baseOffset = vec3(timeButtonInitialXOffsetWithinPanel, timeButtonInitialYOffsetWithinPanel, 2)
    uiStandardButton:setIconModel(pauseButton, "icon_pause")
    buttonsBySpeedIndex[0] = pauseButton
    uiStandardButton:setClickFunction(pauseButton, function()
        localWorld:setPaused()
        timeUI:updateLocalSpeedPreference(0)
    end)
    uiToolTip:add(pauseButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_pause"), nil, toolTipOffset, nil, pauseButton)
    uiToolTip:addKeyboardShortcut(pauseButton.userData.backgroundView, "game", "pause", nil, nil)

    -- Play Button
    local playButton = uiStandardButton:create(chronoView, vec2(timeButtonSize, timeButtonSize), uiStandardButton.types.timeControl)
    playButton.relativeView = pauseButton
    playButton.userData.selectionCircleMaterial = material.types.ui_green.index
    playButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    playButton.baseOffset = vec3(timeButtonXPadding, 0, 0)
    uiStandardButton:setIconModel(playButton, "icon_play")
    buttonsBySpeedIndex[1] = playButton
    uiStandardButton:setClickFunction(playButton, function()
        localWorld:setPlay()
        timeUI:updateLocalSpeedPreference(1)
    end)
    uiToolTip:add(playButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_play"), nil, toolTipOffset, nil, playButton)

    -- FastForward Button
    ffButton = uiStandardButton:create(chronoView, vec2(timeButtonSize, timeButtonSize), uiStandardButton.types.timeControl)
    ffButton.relativeView = playButton
    ffButton.userData.selectionCircleMaterial = material.types.ui_selected.index
    ffButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    ffButton.baseOffset = vec3(timeButtonXPadding, 0, 0)
    uiStandardButton:setIconModel(ffButton, "icon_fastForward")
    buttonsBySpeedIndex[2] = ffButton
    uiStandardButton:setClickFunction(ffButton, function()
        localWorld:setFastForward()
        timeUI:updateLocalSpeedPreference(2)
    end)
    uiToolTip:add(ffButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_fastForward"), nil, toolTipOffset, nil, ffButton)
    uiToolTip:addKeyboardShortcut(ffButton.userData.backgroundView, "game", "speedFast", nil, nil)

    -- TODO: ExtraFastForward Button
    fffButton = uiStandardButton:create(chronoView, vec2(timeButtonSize, timeButtonSize), uiStandardButton.types.timeControl)
    fffButton.relativeView = ffButton
    fffButton.userData.selectionCircleMaterial = material.types.ui_selected.index
    fffButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    fffButton.baseOffset = vec3(timeButtonXPadding, 0, 0)
    uiStandardButton:setIconModel(fffButton, "icon_fastForward")
    buttonsBySpeedIndex[3] = fffButton
    uiStandardButton:setClickFunction(fffButton, function()
        localWorld:setFastForward()
        timeUI:updateLocalSpeedPreference(3)
    end)
    uiToolTip:add(fffButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_fastForward"), nil, toolTipOffset, nil, ffButton)
    uiToolTip:addKeyboardShortcut(fffButton.userData.backgroundView, "game", "speedFast", nil, nil)

    world:addSpeedChangeListener(serverSpeedMultiplierChanged)
    timeUI:updateLocalSpeedPreference(1)
    serverSpeedMultiplierChanged(world:getSpeedMultiplier(), world:getSpeedMultiplierIndex())
end


return timeUI

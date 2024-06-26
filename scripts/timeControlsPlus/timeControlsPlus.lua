-- Vanilla Imports
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
local connectionAlertIcon = nil

--TimeControlPlus Imports
local localPlayer = mjrequire "mainThread/localPlayer"
local dot = mjm.dot
local notificationsUI = mjrequire "mainThread/ui/notificationsUI"
local notification = mjrequire "common/notification"
local gameObject = mjrequire "common/gameObject"

--TimeControlPlus Objects
local currentSeason = nil
local currentYear = nil

--Custom UI components for displaying calendar information.
local seasonTreeImage = nil                             --The tree season icon

--Information labels
local yearTextView = nil                                --The year label
local dayTextView = nil                                 --The day label
local timeClockText = nil                               --The digital clock
local timeClockUnitLabel = nil                          --Time unit label. Seperate so it doesn't bounce around when the clock is updating

--Dimensions of the UI objects
local seasonTreeImageSize = 60.0                        --Size of the model

--Positioning things - vec3(x, y, z)
local yearBaseOffset = vec3(282,58,0)                    --offset for the year text control.
local dayBaseOffset = vec3(283,42,0)                     --offset for the day text control.
local timeClockTextBaseOffset = vec3(283,20,0)
local timeClockUnitLabelBaseOffset = vec3(317,20,0)
local seasonCircleBaseOffset = vec3(380.0, 59.0, 1.0)    --offset for the circle panel bookend
local seasonTreeBaseOffset = vec3(0.0, 0.0, 1.0)       --offset for the seasonal tree icon
local seasonCircleBack = nil                            --Circle the tree icon sits inside of


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

-- Initializes time control interface elements in the game UI.
function timeControls:init(gameUI, world)

    --Time Variables
    local yearTextView = nil                                        --The year label
    local dayTextView = nil                                         --The day label
    local timeClockText = nil                                       --The digital clock
    local timeClockUnitLabel = nil                                  --Time unit label. Seperate so it doesn't bounce around when the clock is updating
    local timeUnitLabel = "WT"                                      --The time units to display on the screen
    local daysInYear = world:getYearLength() / world:getDayLength() --Calculate the number of days in the year.
    local gameHourInSeconds = world:getDayLength()/24               --Calculate this to future-proof for server owners changing it
    local gameMinuteInSeconds = world:getDayLength()/1440           --Calculate how long a game minute is in real world seconds
    local mainPanelLength = 350.0

    --TimeControlPlus: Rounds the given number
    local function round(n)
        return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
    end

    --TimeControlPlus: Determine season and set tree model
    local function getSeason()
        
        --Object to hold the attributes
        local seasonObject = {
            treeModel = nil,
            seasonText = nil,
            currentYear = nil
        }

        --Get the players position to determine if they are in the southern hemisphere
        local playerPosition = localPlayer:getPos()
        local isSouthHemisphere = dot(playerPosition, vec3(0.0,1.0,0.0)) < 0.0

        --Calculate the seasonal fraction. 0.0 is spring, 0.25 summer, 0.5 is autumn, >0.75 winter.
        local seasonFraction = math.fmod(world.yearSpeed * world:getWorldTime(), 1.0)
        
        --Get the index & HemisphereOffset we need for the lookup table
        local index = math.floor(seasonFraction * 4) % 4 + 1
        local hemisphereOffset = isSouthHemisphere and 2 or 1

        --Lookup table for getting the right tree model and text.  The pair of values represent the northern hemisphere and
        --southern hemisphere naming.
        local seasonLookupTable = {
            {
                treeModel = { "appleTreeSpring", "appleTreeAutumn" },
                seasonText = { "Spring", "Autumn" },
                seasonNotificationType = {notification.types.newYear.index, notification.types.newYear.index},
                seasonNotificationObject = {{objectTypeIndex=gameObject.types.appleTree.index}, {objectTypeIndex=gameObject.types.appleTree.index}}
            },
            {
                treeModel = { "appleTree", "appleTreeWinter" },
                seasonText = { "Summer", "Winter" },
                seasonNotificationType = {notification.types.summerStarting.index, notification.types.winterStarting.index},
                seasonNotificationObject = {{objectTypeIndex=gameObject.types.appleTree.index}, {objectTypeIndex=gameObject.types.appleTree.index}}
            },
            {
                treeModel = { "appleTreeAutumn", "appleTreeSpring" },
                seasonText = { "Autumn", "Spring" },
                seasonNotificationType = {notification.types.autumnStarting.index, notification.types.springStarting.index},
                seasonNotificationObject = {{objectTypeIndex=gameObject.types.appleTree.index}, {objectTypeIndex=gameObject.types.appleTree.index}}
            },
            {
                treeModel = { "appleTreeWinter", "appleTree" },
                seasonText = { "Winter", "Summer" },
                seasonNotificationType = {notification.types.winterStarting.index, notification.types.summerStarting.index},
                seasonNotificationObject = {{objectTypeIndex=gameObject.types.appleTree.index}, {objectTypeIndex=gameObject.types.appleTree.index}}
            }
        }
        --Set the season object
        seasonObject.treeModel = seasonLookupTable[index].treeModel[hemisphereOffset]
        seasonObject.seasonText = seasonLookupTable[index].seasonText[hemisphereOffset]
        seasonObject.notificationType = seasonLookupTable[index].seasonNotificationType[hemisphereOffset]
        seasonObject.notificationObject = seasonLookupTable[index].seasonNotificationObject[hemisphereOffset]
        seasonObject.currentYear = tostring(math.floor(math.floor(world:getWorldTime()/world:getDayLength())/8) + 1)

        return seasonObject
    end

    --TimeControlPlus: Send a UI notification when the seasons change.
    local function sendNotification(seasonNotifyInfo)
        --[[
            notificationsUI:displayNotification({
                typeIndex = seasonNotifyInfo.notificationType,
                objectInfo = seasonNotifyInfo.notificationObject,
                currentYear = seasonNotifyInfo.currentYear,
            })
        ]] 
            notificationsUI:displayObjectNotification({
                typeIndex = seasonNotifyInfo.notificationType,
                objectInfo = seasonNotifyInfo.notificationObject,
                currentYear = seasonNotifyInfo.currentYear,
            })
        
    end

    -- Create a new view inside the game UI to hold all time control elements.
    mainView = View.new(gameUI.view)
    mainView.hidden = false
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    mainView.baseOffset = vec3(10.0, -10.0, 0.0)

    -- Define dimensions and positioning for the main time control elements.
    local circleViewSize = 60.0
    local panelSizeToUse = vec2(mainPanelLength, 60.0)
    local panelXOffset = -30.0
    mainView.size = vec2(circleViewSize + panelSizeToUse.x - panelXOffset, 60.0)

    -- Scaling factor for the circle background of the clock.
    local circleBackgroundScale = circleViewSize * 0.5

    -- Create and set up the clock background view.
    local clockBackground = ModelView.new(mainView)
    clockBackground:setModel(model:modelIndexForName("ui_clockBackground"))
    clockBackground.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    clockBackground.scale3D = vec3(circleBackgroundScale, circleBackgroundScale, circleBackgroundScale)
    clockBackground.size = vec2(circleViewSize, circleViewSize)
    clockBackground.baseOffset = vec3(0.0, 0.0, 0.0)
    clockBackground.alpha = 0.9

    -- Create and set up the clock hand view.
    local clockHand = ModelView.new(mainView)
    clockHand:setModel(model:modelIndexForName("ui_clockMark"))
    clockHand.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    clockHand.relativeView = clockBackground
    clockHand.scale3D = vec3(circleBackgroundScale, circleBackgroundScale, circleBackgroundScale)
    clockHand.size = vec2(circleViewSize, circleViewSize)
    clockHand.baseOffset = vec3(0.0, 0.0, 0.02 * circleBackgroundScale)

    -- Function to update the clock hand based on the current time of day.
    clockHand.update = function(dt)
        local timeOfDayFraction = world:getTimeOfDayFraction()
        local zRotation = (timeOfDayFraction + 0.5) * math.pi * 2.0
        clockHand.rotation = mat3Rotate(mat3Identity, zRotation, vec3(0.0, 0.0, -1.0))
    end

    -- Set dimensions and scaling for a side panel next to the clock.
    local panelScaleToUseX = panelSizeToUse.x * 0.5
    local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2
    
    -- Create and set up the panel view.
    panelView = ModelView.new(mainView)
    panelView:setModel(model:modelIndexForName("ui_panel_10x2"))
    panelView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    panelView.relativeView = clockBackground
    panelView.baseOffset = vec3(panelXOffset, 0.0, -2)
    panelView.scale3D = vec3(panelScaleToUseX, panelScaleToUseY, panelScaleToUseX)
    panelView.size = panelSizeToUse
    panelView.alpha = 0.9               --This affects transparency.

    -- Define dimensions and offsets for time control buttons.
    local timeButtonSize = 30.0
    local timeButtonInitialXOffsetWithinPanel = 45.0
    local timeButtonInitialYOffsetWithinPanel = -6.0
    local timeButtonXPadding = 10.0

    -- Create a text view for displaying temperature (or other info).
    temperatureTextView = TextView.new(panelView)
    temperatureTextView.font = Font(uiCommon.fontName, 16)
    temperatureTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    temperatureTextView.baseOffset = vec3(0, -4, 0)
    temperatureTextView.text = ""
    
    -- Create a button for pausing the game.
    local pauseButton = uiStandardButton:create(panelView, vec2(timeButtonSize, timeButtonSize), uiStandardButton.types.timeControl)
    pauseButton.userData.selectionCircleMaterial = material.types.ui_red.index
    pauseButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    pauseButton.baseOffset = vec3(timeButtonInitialXOffsetWithinPanel, timeButtonInitialYOffsetWithinPanel, 2)
    uiStandardButton:setIconModel(pauseButton, "icon_pause")
    buttonsBySpeedIndex[0] = pauseButton
    uiStandardButton:setClickFunction(pauseButton, function()
        world:setPaused()
        timeControls:updateLocalSpeedPreference(0)
    end)
    -- Add a tooltip to the pause button.
    uiToolTip:add(pauseButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_pause"), nil, toolTipOffset, nil, pauseButton)
    uiToolTip:addKeyboardShortcut(pauseButton.userData.backgroundView, "game", "pause", nil, nil)
    
    -- Create the play button.
    local playButton = uiStandardButton:create(panelView, vec2(timeButtonSize, timeButtonSize), uiStandardButton.types.timeControl)
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
    -- Add a tooltip to the play button.
    uiToolTip:add(playButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_play"), nil, toolTipOffset, nil, playButton)
    
    -- Create a button for fast-forwarding the game.
    local ffButton = uiStandardButton:create(panelView, vec2(timeButtonSize, timeButtonSize), uiStandardButton.types.timeControl)
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
    -- Add a tooltip to the fast-forward button.
    uiToolTip:add(ffButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_Toggle") .. " " .. locale:get("ui_fastForward"), nil, toolTipOffset, nil, ffButton)
    uiToolTip:addKeyboardShortcut(ffButton.userData.backgroundView, "game", "speedFast", nil, nil)

    -- Position temperature text relative to the pause button.
    temperatureTextView.relativeView = pauseButton

    -- Add a speed change listener to the world object.
    world:addSpeedChangeListener(serverSpeedMultiplierChanged)
    -- Set and update local speed preference initially.
    timeControls:updateLocalSpeedPreference(1)
    -- Update UI based on the current speed multiplier from the server.
    serverSpeedMultiplierChanged(world:getSpeedMultiplier(), world:getSpeedMultiplierIndex())

    -- TimeControlPlus Stuff
    --Circular Model to hold the tree icon
    seasonCircleBack = ModelView.new(mainView)
    seasonCircleBack:setModel(model:modelIndexForName("ui_circleBackgroundLargeOutline",
    {
        [material.types.ui_background.index] = material.types.ui_background_blue.index,
        [material.types.ui_standard.index] = material.types.ui_selected.index
    }))
    seasonCircleBack.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    seasonCircleBack.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
    seasonCircleBack.size = vec2(circleViewSize, circleViewSize)
    seasonCircleBack.baseOffset = seasonCircleBaseOffset
    seasonCircleBack.alpha = 0.70

    -- Updates to the vanilla panelView
    uiToolTip:add(panelView, ViewPosition(MJPositionCenter, MJPositionBelow), "", nil, toolTipOffset, nil, panelView)
    panelView.update = function(dt)
        local season = getSeason()
        uiToolTip:updateText(panelView, season.seasonText, nil, false)
    end

    --A GameObjectlView to show the tree to represent the season
    seasonTreeImage = GameObjectView.new(panelView, vec2(128, 128)) --this second argument is the texture image size in pixels that the tree is rendered into
    seasonTreeImage.size = vec2(seasonTreeImageSize, seasonTreeImageSize)
    seasonTreeImage.baseOffset = seasonTreeBaseOffset
    seasonTreeImage.relativeView = seasonCircleBack
    seasonTreeImage.alpha = 1.0
    seasonTreeImage.update = function(dt)
        --Update the image based on what season it is.
        local season = getSeason()
        if currentSeason ~= season.seasonText then
            if currentSeason ~= nil then
                --The season is changing, play a sound
                --sendNotification(season)
            end
            currentSeason = season.seasonText
            seasonTreeImage:setModel(model:modelIndexForName(season.treeModel))
        end
    end

    --The year text, and the update function to keep it refreshed with the correct value
    yearTextView = TextView.new(panelView)
    yearTextView.font = Font(uiCommon.fontName, 16)
    yearTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    yearTextView.relativeView = panelView
    yearTextView.baseOffset = yearBaseOffset
    yearTextView.update = function(dt)
        currentYear = tostring(math.floor(math.floor(world:getWorldTime()/world:getDayLength())/daysInYear) + 1)
        yearTextView.text = "Year " .. currentYear
    end

    --The day of year text, and the update function to keep it refreshed with the correct value
    dayTextView = TextView.new(panelView)
    dayTextView.font = Font(uiCommon.fontName, 16)
    dayTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    dayTextView.relativeView = panelView
    dayTextView.baseOffset = dayBaseOffset
    dayTextView.update = function(dt)
        --Calculate the day of the year.
        local elapsedDays = round(world:getWorldTime()/world:getDayLength())
        local currentDay = elapsedDays % daysInYear + 1
        dayTextView.text = "Day " .. tostring(currentDay)
        --dayTextView.text = "Day  " .. tostring((math.floor(world:getWorldTime()/world:getDayLength())) % daysInYear + 1)
    end

    --Digital Clock
    timeClockText = TextView.new(panelView)
    timeClockText.font = Font(uiCommon.fontName, 14)
    timeClockText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    timeClockText.relativeView = panelView
    timeClockText.baseOffset = timeClockTextBaseOffset
    timeClockText.update = function(dt)
        local secondsElapsedInDay = world:getWorldTime() % world:getDayLength() --How many real world seconds have elapsed in this day
        local gameTimeHour = math.floor(secondsElapsedInDay / gameHourInSeconds)                            --The hour to display
        local gameTimeMinute = math.floor((secondsElapsedInDay % gameHourInSeconds)/gameMinuteInSeconds)    --The minute to display
        --Format the clock digits to add a leading 0 and set the text field
        local txtGameTimeHour = string.format("%02d", gameTimeHour)
        local txtGameTimeMinute = string.format("%02d", gameTimeMinute)
        timeClockText.text = txtGameTimeHour .. ":" .. txtGameTimeMinute
    end

    --Time Unit label for the clock
    timeClockUnitLabel = TextView.new(panelView)
    timeClockUnitLabel.font = Font(uiCommon.fontName, 11)
    timeClockUnitLabel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    timeClockUnitLabel.relativeView = panelView
    timeClockUnitLabel.baseOffset = timeClockUnitLabelBaseOffset
    timeClockUnitLabel.text = timeUnitLabel
end

function timeControls:setHiddenForTribeSelection(newHidden)
    mainView.hidden = newHidden
end

function timeControls:playerTemperatureZoneChanged(newTemperatureZoneIndex)
    temperatureTextView.text = weather.temperatureZones[newTemperatureZoneIndex].name
    --temperatureTextView.text = "Just Making sure"
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
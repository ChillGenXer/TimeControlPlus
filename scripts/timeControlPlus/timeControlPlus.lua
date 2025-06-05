-- imports
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4
local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local gameConstants = mjrequire "common/gameConstants"
local material = mjrequire "common/material"
--local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
--local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
--local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
--local resource = mjrequire "common/resource"
--local gameObject = mjrequire "common/gameObject"
--local medicine = mjrequire "common/medicine"
--local foodUI = mjrequire "timeControlPlus/ui/foodUI"
--local settingsUI = mjrequire "timeControlPlus/ui/settingsUI"
local menuPanelsUI = mjrequire "timeControlPlus/ui/menuPanelsUI"
local compassUI = mjrequire "timeControlPlus/ui/compassUI"
local populationUI = mjrequire "timeControlPlus/ui/populationUI"
local timeUI = mjrequire "timeControlPlus/ui/timeUI"
local uiFoodButton = mjrequire "timeControlPlus/ui/uiFoodButton"

-- Initialize globals
local timeControls = {}

--TimeControlPlus UI Components
--local settingsUIView = nil
local panels = {} -- Track all panels and their associated buttons for managing visibility
local toolTipOffset = vec3(0, -10, 0)
local leftMenuPanel = nil
local rightMenuPanel = nil -- New container for right-side elements
local connectionAlertIcon = nil
local foodMenu = nil

-- MajicJungle Functions

-- MajicJungle: Set the local speed preference based on server vote (Redirect)
function timeControls:updateLocalSpeedPreference(speedMultiplierIndex)
    timeUI:updateLocalSpeedPreference(speedMultiplierIndex)
end

-- MajicJungle: Provide the server with the local speed preference
function timeControls:getLocalSpeedPreference()
    return timeUI:getLocalSpeedPreference()
end

-- MajicJungle: Provides function for the game to hide TimeControls during tribe selection
function timeControls:setHiddenForTribeSelection(newHidden)
    leftMenuPanel.hidden = newHidden
    rightMenuPanel.hidden = newHidden
end

-- MajicJungle (Modified): Provides a function for the game to notify that the player's temperature zone has changed.
function timeControls:playerTemperatureZoneChanged(newTemperatureZoneIndex)
    --Redirect to the compass handling function
    compassUI:playerTemperatureZoneChanged(newTemperatureZoneIndex)
end

-- MajicJungle: Disables FF if the server doesn't allow it.
function timeControls:setFastForwardDisabledByServer(newIsThrottled)
    timeUI:setFastForwardDisabledByServer(newIsThrottled)
end

--MajicJungle: Game sends a ping value to drive display of connectionAlertIcon
function timeControls:setPingValue(currentPingValue)
    if currentPingValue > 10.0 then
        if not connectionAlertIcon then
            connectionAlertIcon = ModelView.new(leftMenuPanel)
            local iconSize = 30
            connectionAlertIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
            connectionAlertIcon.relativeView = leftMenuPanel
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
        connectionAlertIcon.hidden = false
    end
end

-- Starting point and initialization
function timeControls:init(gameUI, world)

    -- Create the timeUI (bottom right corner of the screen)
    timeUI:initializeTimeUI(gameUI, world)

    -- Create the top menu bars
    leftMenuPanel = menuPanelsUI:initLeftMenuPanel(gameUI.view)
    rightMenuPanel = menuPanelsUI:initRightMenuPanel(gameUI.view)

    -- Setup the compass
    compassUI:init(gameUI, world)

    -- Create the food menu
    foodMenu = uiFoodButton:init(gameUI, world, leftMenuPanel, leftMenuPanel)

    -- Setup the population button
    populationUI:init(world, leftMenuPanel, foodMenu, panels)


    -- ### MajicJungle:Connection Alert Icon ### --
    if connectionAlertIcon then
        connectionAlertIcon.relativeView = leftMenuPanel
    end

end

return timeControls
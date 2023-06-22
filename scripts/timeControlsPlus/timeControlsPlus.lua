--- TimeControlsPlus: timeControlsPlus.lua
--- @author ChillGenXer
--- Mod for displaying a calendar and time in Sapiens.

--Create the module object so it can be returned
local timeControlsPlus = {}

--Imports
local mjm = mjrequire "common/mjm"
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local material = mjrequire "common/material"
local localPlayer = mjrequire "mainThread/localPlayer"

local vec2 = mjm.vec2
local vec3 = mjm.vec3
local dot = mjm.dot
local mat3Identity = mjm.mat3Identity

local gameUI = nil
local world = nil
local currentSeason = nil
local currentYear = nil

local notificationsUI = mjrequire "mainThread/ui/notificationsUI"
local notification = mjrequire "common/notification"
local gameObject = mjrequire "common/gameObject"

---Rounds the given number
local function round(n)
    return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

---Returns a season object with the appropriate tree model and season name.
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

---Send a UI notification when the seasons change.
local function sendNotification(seasonNotifyInfo)

    notificationsUI:displayObjectNotification({
        typeIndex = seasonNotifyInfo.notificationType,
		objectInfo = seasonNotifyInfo.notificationObject,
        currentYear = seasonNotifyInfo.currentYear,
	})
end

--Main function ran from the shadow file
function timeControlsPlus:init(gameUI_, world_)
    --Grab our game context objects and store them locally.
    gameUI = gameUI_
    world = world_

    --mj:log(gameUI)
    --mj:log(world)

    --Custom UI components for displaying calendar information.
    local myMainView = nil                                  --Invisible anchor to the GameUI
    local myPanelView = nil                                 --Panel where year, day and time are displayed
    local seasonCircleBack = nil                            --Circle the tree icon sits inside of
    local seasonTreeImage = nil                             --The tree season icon

    --Information labels
    local yearTextView = nil                                --The year label
    local dayTextView = nil                                 --The day label
    local timeClockText = nil                               --The digital clock
    local timeClockUnitLabel = nil                          --Time unit label. Seperate so it doesn't bounce around when the clock is updating

    --Time Variables
    local timeUnitLabel = "WT"                                              --The time units to display on the screen
    local daysInYear = world:getYearLength() / world:getDayLength()         --Calculate the number of days in the year.
    local gameHourInSeconds = world:getDayLength()/24                       --Calculate this to future-proof for server owners changing it
    local gameMinuteInSeconds = world:getDayLength()/1440                   --Calculate how long a game minute is in real world seconds

    --Dimensions of the UI objects
    local panelSizeToUse = vec2(110.0, 61.0)                --Added 1 more than the time control as the edge is a little bumpy and this creates a better seam
    local circleViewSize = 60.0                             --Size of the circle the tree sits in
    local seasonTreeImageSize = 60.0                        --Size of the model

    --Positioning things - vec3(x, y, z)
    --TODO I should figure out how to offset from the timeControl itself.  Actually I should just shadow the whole thing, it's not big.
    local offsetFromGamePanel = 206.0                       --The offset from the vanilla timeControl panel 
    local myPanelBaseOffset = vec3(0, 0.0, -2)              --offset for the invisible anchor panel I will attach the rest of my objects to
    local yearBaseOffset = vec3(12,58,0)                    --offset for the year text control.
    local dayBaseOffset = vec3(13,42,0)                     --offset for the day text control.
    local timeClockTextBaseOffset = vec3(13,20,0)
    local timeClockUnitLabelBaseOffset = vec3(47,20,0)
    local seasonCircleBaseOffset = vec3(75.0, 59.0, 0.1)    --offset for the circle panel bookend
    local seasonTreeBaseOffset = vec3(0.0, 0.0, 0.01)       --offset for the seasonal tree icon
    local toolTipOffset = vec3(0,-10,0)                     --offset for tooltips

    --3D Scaling
    local panelScaleToUseX = panelSizeToUse.x * 0.5
    local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2
    local circleBackgroundScale = circleViewSize * 0.5
    local seasonTreeImageScale = seasonTreeImageSize * 0.5

    --UI anchor to the main game screen.  This is invisible and will be used to attach the new visible components.
    myMainView = View.new(gameUI.view)
    myMainView.hidden = false
    myMainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    myMainView.baseOffset = vec3(offsetFromGamePanel, -10.0, 0.0)
    myMainView.size = panelSizeToUse

    --Circular Model to hold the tree icon
    seasonCircleBack = ModelView.new(myMainView)
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

    --The background panel for the text.  It is snuggled up to the rightmost edge of the vanilla time control
    myPanelView = ModelView.new(myMainView)
    myPanelView:setModel(model:modelIndexForName("ui_panel_10x2"))
    myPanelView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    myPanelView.relativeView = myMainView
    myPanelView.baseOffset = myPanelBaseOffset
    myPanelView.scale3D = vec3(panelScaleToUseX,panelScaleToUseY,panelScaleToUseX)
    myPanelView.size = panelSizeToUse
    myPanelView.alpha = 0.9     --This affects transparency.
    uiToolTip:add(myPanelView, ViewPosition(MJPositionCenter, MJPositionBelow), "", nil, toolTipOffset, nil, myPanelView)
    myPanelView.update = function(dt)
        local season = getSeason(world)
        uiToolTip:updateText(myPanelView, season.seasonText, nil, false)
    end
    --A ModelView to show the tree to represent the season
    seasonTreeImage = GameObjectView.new(myPanelView, vec2(128, 128)) --this second argument is the texture image size in pixels that the tree is rendered into
    seasonTreeImage.size = vec2(seasonTreeImageSize, seasonTreeImageSize)
    seasonTreeImage.baseOffset = seasonTreeBaseOffset
    seasonTreeImage.relativeView = seasonCircleBack
    seasonTreeImage.alpha = 1.0
    seasonTreeImage.update = function(dt)
        --Update the image based on what season it is.
        local season = getSeason(world)
        if currentSeason ~= season.seasonText then
            if currentSeason ~= nil then
                --The season is changing, play a sound
                sendNotification(season)
            end
            currentSeason = season.seasonText
            seasonTreeImage:setModel(model:modelIndexForName(season.treeModel))
        end
    end

    --The year text, and the update function to keep it refreshed with the correct value
    yearTextView = TextView.new(myPanelView)
    yearTextView.font = Font(uiCommon.fontName, 16)
    yearTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    yearTextView.relativeView = myPanelView
    yearTextView.baseOffset = yearBaseOffset
    yearTextView.update = function(dt)
        currentYear = tostring(math.floor(math.floor(world:getWorldTime()/world:getDayLength())/daysInYear) + 1)
        yearTextView.text = "Year " .. currentYear
    end

    --The day of year text, and the update function to keep it refreshed with the correct value
    dayTextView = TextView.new(myPanelView)
    dayTextView.font = Font(uiCommon.fontName, 16)
    dayTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    dayTextView.relativeView = myPanelView
    dayTextView.baseOffset = dayBaseOffset
    dayTextView.update = function(dt)
        --Calculate the day of the year.
        local elapsedDays = round(world:getWorldTime()/world:getDayLength())
        local currentDay = elapsedDays % daysInYear + 1
        dayTextView.text = "Day " .. tostring(currentDay)
        --dayTextView.text = "Day  " .. tostring((math.floor(world:getWorldTime()/world:getDayLength())) % daysInYear + 1)
    end

    --Digital Clock
    timeClockText = TextView.new(myPanelView)
    timeClockText.font = Font(uiCommon.fontName, 14)
    timeClockText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    timeClockText.relativeView = myPanelView
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
    timeClockUnitLabel = TextView.new(myPanelView)
    timeClockUnitLabel.font = Font(uiCommon.fontName, 11)
    timeClockUnitLabel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    timeClockUnitLabel.relativeView = myPanelView
    timeClockUnitLabel.baseOffset = timeClockUnitLabelBaseOffset
    timeClockUnitLabel.text = timeUnitLabel
end

--Return the module object
return timeControlsPlus

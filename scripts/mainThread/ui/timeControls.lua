--timeControlsPlus
--Mod for displaying the current year, day and season ontop of the vanilla time control.

--All the imports from the original, clean up what you don't need
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local mat3Rotate = mjm.mat3Rotate
local mat3Identity = mjm.mat3Identity
local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local weather = mjrequire "common/weather"
local gameConstants = mjrequire "common/gameConstants"
local audio = mjrequire "mainThread/audio"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
--local logic = mjrequire "logicThread/logic"
--local playerPosition = logic.playerPos
--local seasonFraction = logic:getSeasonFraction()

local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    local superTimeControls = timeControls.init

    timeControls.init = function(timeControls_, gameUI_, world_)
        
        --That's it for the custom code, hand back control to timeControls.lua to continue
	    superTimeControls(timeControls_, gameUI_, world_)

        --local worldTime = nil
        --local dayLength = nil
        --local yearLength = nil
        --local worldAgeInDays = nil
        --local currentYear = nil
        --local currentDayOfYear = nil
--[[
        --Calculations for the calendar.
        local function updateCalendar()
            worldTime = world_:getWorldTime()
            dayLength = world_:getDayLength()
            yearLength = world_:getYearLength()
            worldAgeInDays = math.floor(world_:getWorldTime()/world_:getDayLength())
            currentYear = math.floor(math.floor(world_:getWorldTime()/world_:getDayLength())/8) + 1 --Adding 1 to make the year counting start at 1
            currentDayOfYear = worldAgeInDays % 8 + 1 --Same for days.
            --(math.floor(world_:getWorldTime()/world_:getDayLength())) % 8 + 1
        end
--]]
        local function getSeason()
            --Calculate which season it is.
            --TODO Add southern hemisphere check.  Not sure where to get it properly, had a few crashes
--]]
           local seasonFraction = math.fmod(world_.yearSpeed * world_:getWorldTime(), 1.0)
           --0.0 is spring, 0.25 summer, 0.5 is autumn, >0.75 winter.
           if (seasonFraction >= 0) and (seasonFraction < 0.25) then
                return "appleTreeSpring"
            elseif (seasonFraction >= 0.25) and (seasonFraction < 0.50) then
                return "appleTree"
            elseif (seasonFraction >= 0.50) and (seasonFraction < 0.75) then
                return "appleTreeAutumn"
            else
                return "appleTreeWinter"
            end
        end

        --Custom views for displaying the additional information.

        local panelSizeToUse = vec2(110.0, 61.0)
        local offsetFromGamePanel = 206.0 --The offset from the vanilla timeControl panel       
        local circleViewSize = 60.0
        
        --Positioning things
        local myPanelBaseOffset = vec3(0, 0.0, -2)
        local yearBaseOffset = vec3(15,58,0)
        local dayBaseOffset = vec3(15,42,0)
        local seasonBaseOffset = vec3(15,25,0)
        
        local circleBackgroundScale = circleViewSize * 0.48
        local seasonTreeImageScale = circleViewSize * 0.1
        local seasonCircleBaseOffset = vec3(80.0, 60.0, 1.0)
        local seasonTreeBaseOffset = vec3(90.0, 30.0, 20.0)

        --Do I need these
        local panelScaleToUseX = panelSizeToUse.x * 0.5
        local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2

        --This is the main view coming from the gameIU object.  I'm not sure why I need this.
        myMainView = View.new(gameUI_.view)
        myMainView.hidden = false
        myMainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myMainView.baseOffset = vec3(offsetFromGamePanel, -10.0, 0.0)
        myMainView.size = panelSizeToUse
        
        local myPanelView = ModelView.new(myMainView)
        myPanelView:setModel(model:modelIndexForName("ui_panel_10x2"))
        myPanelView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myPanelView.relativeView = myMainView
        myPanelView.baseOffset = myPanelBaseOffset
        myPanelView.scale3D = vec3(panelScaleToUseX,panelScaleToUseY,panelScaleToUseX)
        myPanelView.size = panelSizeToUse
        myPanelView.alpha = 0.9     --I think this is transparency.

        yearTextView = TextView.new(myPanelView)
        yearTextView.font = Font(uiCommon.fontName, 16)
        yearTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        yearTextView.relativeView = myPanelView
        yearTextView.baseOffset = yearBaseOffset
        yearTextView.update = function(dt)
            yearTextView.text = "Year " .. tostring(math.floor(math.floor(world_:getWorldTime()/world_:getDayLength())/8) + 1)
        end

        dayTextView = TextView.new(myPanelView)
        dayTextView.font = Font(uiCommon.fontName, 16)
        dayTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        dayTextView.relativeView = myPanelView
        dayTextView.baseOffset = dayBaseOffset
        dayTextView.update = function(dt)
            --Calculate the day of the year.
            dayTextView.text = "Day  " .. tostring((math.floor(world_:getWorldTime()/world_:getDayLength())) % 8 + 1)
        end

        --mj:log("Creating SeasonTextView)")
        seasonTextView = TextView.new(myPanelView)
        seasonTextView.font = Font(uiCommon.fontName, 18)
        seasonTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTextView.relativeView = myPanelView
        seasonTextView.baseOffset = seasonBaseOffset
       -- seasonTextView.update = function(dt)
            --Update the 
            --seasonTreeImage:setModel(model:modelIndexForName(getSeason()))
        --end

        local seasonCircle = ModelView.new(myPanelView)
        seasonCircle:setModel(model:modelIndexForName("ui_circleBackgroundSmall"))
        seasonCircle.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonCircle.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
        seasonCircle.size = vec2(circleViewSize, circleViewSize)
        seasonCircle.baseOffset = seasonCircleBaseOffset
        seasonCircle.alpha = 0.9
        --seasonCircle.color = vec3(0.6,0.8,1.0)

        local seasonTreeImage = ModelView.new(myPanelView)
        seasonTreeImage:setModel(model:modelIndexForName("appleTreeAutumn"))
        seasonTreeImage.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTreeImage.scale3D = vec3(seasonTreeImageScale,seasonTreeImageScale,seasonTreeImageScale)
        seasonTreeImage.size = vec2(circleViewSize, circleViewSize)
        seasonTreeImage.baseOffset = seasonTreeBaseOffset
        seasonTreeImage.alpha = 1.0
        seasonTreeImage.update = function(dt)
            --Update the 
            seasonTreeImage:setModel(model:modelIndexForName(getSeason()))
        end
    end
end

return mod

--[[


function weather:getRainfall(rainfallValues, normalizedPos, worldTime, yearSpeed)
    
    local isSouthHemisphere = dot(normalizedPos, vec3(0.0,1.0,0.0)) < 0.0
    local seasonFraction = getSeasonFraction(worldTime, yearSpeed, isSouthHemisphere)

    local mixFraction = math.cos((seasonFraction - 0.25) * math.pi * 2.0) * 0.5 + 0.5
    local result = mjm.mix(rainfallValues[2], rainfallValues[1], mixFraction)

    --mj:log("getRainfall seasonFraction:", seasonFraction, " mixFraction:", 1.0 - mixFraction, " summer:", rainfallValues[1], " winter:", rainfallValues[2], " result:", result)

    return result
end






]]



--Is this related to my code?  Trying a vanilla play through to test.
--[[
4724.299898:Exception calling lua function logicinterface.cpp:409 ...on/Sapiens/GameResources/scripts/common/notification.lua:238: attempt to index field 'userData' (a nil value)
    stack traceback:
        ...on/Sapiens/GameResources/scripts/common/notification.lua:238: in function 'titleFunction'
        .../GameResources/scripts/mainThread/ui/notificationsUI.lua:283: in function 'displayNotificationWithInfo'
        .../GameResources/scripts/mainThread/ui/notificationsUI.lua:352: in function 'displayObjectNotification'
        ...iens/GameResources/scripts/mainThread/logicInterface.lua:273: in function <...iens/GameResources/scripts/mainThread/logicInterface.lua:255>
--]]

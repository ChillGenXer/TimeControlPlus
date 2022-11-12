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

--local keyMapping = mjrequire "mainThread/keyMapping"
local audio = mjrequire "mainThread/audio"

local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"

local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    local superTimeControls = timeControls.init

    timeControls.init = function(timeControls_, gameUI_, world_)
        
        local worldTime = nil
        local dayLength = nil
        local yearLength = nil
        local worldAgeInDays = nil
        local currentYear = nil
        local currentDayOfYear = nil

        --Calculations for the calendar.
        local function updateCalendar()
            worldTime = world_:getWorldTime()
            dayLength = world_:getDayLength()
            yearLength = world_:getYearLength()
            worldAgeInDays = math.floor(worldTime/dayLength)
            currentYear = math.floor(worldAgeInDays/8) + 1 --Adding 1 to make the year counting start at 1
            currentDayOfYear = worldAgeInDays % 8 + 1 --Same for days.
        end

        local function getSeason()
            --Calculate which season it is.  For now I am just using a basic calendar approach,
            --not using the game engine to inquire for the exact season, but it seems to produce
            --a decent result for what it's intended for.
            if currentDayOfYear < 3 then
                return "Spring"
            elseif currentDayOfYear < 5 then
                return "Summer"
            elseif currentDayOfYear < 7 then
                return "Autumn"
            else
                return "Winter"
            end
        end

        --Custom views for displaying the additional information.
        --TODO: I have no idea how the hierarchy is working and the effect of the actual
        --timeControls.lua UI elements once they are rendered after mine.  Need to figure
        --this out.
        myMainView = View.new(gameUI_.view)
        myMainView.hidden = false
        myMainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myMainView.baseOffset = vec3(10.0, -10.0, 0.0)
        local circleViewSize = 60.0
        local panelSizeToUse = vec2(170.0, 60.0)
        local panelXOffset = 55.0
        myMainView.size = vec2(circleViewSize + panelSizeToUse.x - panelXOffset, 60.0)
        
        local panelScaleToUseX = panelSizeToUse.x * 0.5
        local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2

        local myPanelView = ModelView.new(myMainView)
        local myPanelViewSize = vec2(30.0, 60.0)
        
        local myPanelXOffset = 75
        myPanelView:setModel(model:modelIndexForName("ui_panel_10x2"))
        myPanelView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
        myPanelView.relativeView = myMainView
        myPanelView.baseOffset = vec3(myPanelXOffset, 0.0, -2)
        myPanelView.scale3D = vec3(panelScaleToUseX,panelScaleToUseY,panelScaleToUseX)
        myPanelView.size = myPanelViewSize
        myPanelView.alpha = 0.9

        --timeControlsPlus.init(world_)

        mj:log("Creating YearTextView)")
        yearTextView = TextView.new(myPanelView)
        yearTextView.font = Font(uiCommon.fontName, 16)
        yearTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        yearTextView.relativeView = myPanelView
        yearTextView.baseOffset = vec3(-30,60,0)
        yearTextView.update = function(dt)
            updateCalendar()
            yearTextView.text = "Year " .. tostring(currentYear) --timeControlsPlus:getCurrentYear()
        end

        mj:log("Creating DayTextView)")
        dayTextView = TextView.new(myPanelView)
        dayTextView.font = Font(uiCommon.fontName, 16)
        dayTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        dayTextView.relativeView = myPanelView
        dayTextView.baseOffset = vec3(-30,45,0)
        dayTextView.update = function(dt)
            updateCalendar()
            dayTextView.text = "Day  " .. tostring(currentDayOfYear) --timeControlsPlus:getDayOfYear()
        end

        mj:log("Creating SeasonTextView)")
        seasonTextView = TextView.new(myPanelView)
        seasonTextView.font = Font(uiCommon.fontName, 18)
        seasonTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTextView.relativeView = myPanelView
        seasonTextView.baseOffset = vec3(-30,30,0)
        seasonTextView.update = function(dt)
            updateCalendar()
            seasonTextView.text = getSeason()
        end
		mj:log("Executing UI Render on)")

        --That's it for the custom code, hand back control to timeControls.lua to continue
	    superTimeControls(timeControls_, gameUI_, world_)
    end
end

return mod

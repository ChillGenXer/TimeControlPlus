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

local timeControlsPlus = mjrequire "timeControlsPlus"

local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    local superTimeControls = timeControls.init

    timeControls.init = function(timeControls_, gameUI_, world_)
        
        mj:log("Creating myMainView)")
        
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

        mj:log("Creating myPanelView)")
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
        yearTextView.text = "Year " .. timeControlsPlus:getCurrentYear()

        mj:log("Creating DayTextView)")
        dayTextView = TextView.new(myPanelView)
        dayTextView.font = Font(uiCommon.fontName, 16)
        dayTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        dayTextView.relativeView = myPanelView
        dayTextView.baseOffset = vec3(-30,45,0)
        dayTextView.text = "Day  " .. timeControlsPlus:getDayOfYear()

        mj:log("Creating SeasonTextView)")
        seasonTextView = TextView.new(myPanelView)
        seasonTextView.font = Font(uiCommon.fontName, 18)
        seasonTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTextView.relativeView = myPanelView
        seasonTextView.baseOffset = vec3(-30,30,0)
        seasonTextView.text = timeControlsPlus:getSeason()

		mj:log("Executing UI Render on)")

	    superTimeControls(timeControls_, gameUI_, world_) -- Run game vanilla time control to overlay what we have shown
    end
end

return mod

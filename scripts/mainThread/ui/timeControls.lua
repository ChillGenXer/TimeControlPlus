--timeControlsPlus
--Mod for displaying the current year, day and season ontop of the vanilla time control.
local gameObject = mjrequire "common/gameObject"


local mod = {
    loadOrder = 1 -- The load order determines which mods get loaded first.
}

function mod:onload(timeControls)
    local superTimeControls = timeControls.init

    --Redefine the function

    timeControls.init = function(self) --function(gameUI, world)
		mj:log("Executing UI Render on)")
    --[[
        mainView = View.new(gameUI.view)
        mainView.hidden = false
        mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        mainView.baseOffset = vec3(10.0, -10.0, 0.0)
    
        local circleViewSize = 60.0
        local panelSizeToUse = vec2(170.0, 60.0)
        local panelXOffset = -30.0
        mainView.size = vec2(circleViewSize + panelSizeToUse.x - panelXOffset, 60.0)
    
        local panelView = ModelView.new(mainView)
        panelView:setModel(model:modelIndexForName("ui_panel_10x2"))
        panelView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
        panelView.relativeView = clockBackground
        panelView.baseOffset = vec3(panelXOffset, 0.0, -2)
        panelView.scale3D = vec3(panelScaleToUseX,panelScaleToUseY,panelScaleToUseX)
        panelView.size = panelSizeToUse
        panelView.alpha = 0.9

        temperatureTextView = TextView.new(panelView)
        temperatureTextView.font = Font(uiCommon.fontName, 16)
        temperatureTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        temperatureTextView.baseOffset = vec3(0,-4,0)
        temperatureTextView.text = ""
    --]]
	    superTimeControls(self) -- Run game vanilla time control to overlay what we have shown
    end
end  

--[[
local function getSeasonIndex(worldTime, yearSpeed, position) -- 1 spring, 2 summer, 3 autumn, 4 winter
    local isSouthHemisphere = dot(position, vec3(0.0,1.0,0.0)) < 0.0
    local seasonFraction = getSeasonFraction(worldTime, yearSpeed, isSouthHemisphere)
    return mjm.clamp(math.floor(seasonFraction * 4.0) + 1, 1, 4)
end

--Chillgenxer I added this
function weather:getSeason(worldTime, yearSpeed, position) -- 1 spring, 2 summer, 3 autumn, 4 winter
    return getSeasonIndex(worldTime, yearSpeed, position)
end
--]]


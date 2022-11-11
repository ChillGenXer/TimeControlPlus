--timeControlsPlus
--Mod for displaying the current year, day and season ontop of the vanilla time control.
local gameObject = mjrequire "common/gameObject"

local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    local superTimeControls = timeControls.init

    timeControls.init = function(gameUI_, world_)
        
        testingTextView = TextView.new(gameUI_)
        testingTextView.font = Font(uiCommon.fontName, 16)
        testingTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        testingTextView.baseOffset = vec3(0,-4,0)
        testingTextView.text = "Hello World"

		mj:log("Executing UI Render on)")

	    superTimeControls(gameUI_, world_) -- Run game vanilla time control to overlay what we have shown
    end
end

return mod

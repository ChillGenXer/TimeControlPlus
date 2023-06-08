--- TimeControlsPlus: timeControls.lua
--- @author ChillGenXer
--- Mod for displaying a calendar and time in Sapiens.

--Default mod load order
local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    local timeControlsPlus = mjrequire "timeControlsPlus/timeControlsPlus"
    
    local super_timeControls = timeControls.init

    timeControls.init = function(timeControls_, gameUI_, world_)
        --Run the vanilla control first before our code.  Our changes will be additive to the existing UI.
	    mj:log("Run the super")
        super_timeControls(timeControls_, gameUI_, world_)
        
        --Initialize the TimeControlPlus addition
        mj:log(timeControlsPlus)
        mj:log(gameUI_)
        mj:log(world_)
        timeControlsPlus:init(gameUI_, world_)
    end
end

return mod

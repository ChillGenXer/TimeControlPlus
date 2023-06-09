--- TimeControlsPlus: timeControls.lua
--- @author ChillGenXer
--- Mod for displaying a calendar and time in Sapiens.

--Default mod load order
local mod = {
    loadOrder = 1
}

--Import our custom code
local timeControlsPlus = mjrequire "timeControlsPlus/timeControlsPlus"

function mod:onload(timeControls)
    --create a local copy of the init function of timeControls    
    local super_timeControls = timeControls.init

    --Redefine the function to also run the custom code
    timeControls.init = function(timeControls_, gameUI_, world_)
        --Run the game timeControl.init
        super_timeControls(timeControls_, gameUI_, world_)
        --Run the TimeControlPlus addition
        timeControlsPlus:init(gameUI_, world_)
    end
end

return mod

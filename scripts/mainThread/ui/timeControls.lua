--- TimeControlsPlus: timeControls.lua
--- @author ChillGenXer
--- Mod for displaying a calendar and time in Sapiens.

--Default mod load order
local mod = {
    loadOrder = 1
}

local legacyCreationWorldTimeHandlerExtended = false

--Import our custom code
local timeControlsPlus = mjrequire "timeControlsPlus/timeControlsPlus"

function mod:onload(timeControls)
    --create a local copy of the init function of timeControls
    local super_timeControls = timeControls.init

    --Redefine the function to also run the custom code
    timeControls.init = function(timeControls_, gameUI_, world_)
        -- 0.6 forwards the authoritative creation time to this handler but
        -- does not retain it on world. Preserve its weather update and extend
        -- it with the state needed for 0.7-equivalent Legacy Day semantics.
        if not world_.getTribeAge and not legacyCreationWorldTimeHandlerExtended then
            local super_creationWorldTimeChanged = world_.creationWorldTimeChanged
            world_.creationWorldTimeChanged = function(world__, creationWorldTime)
                super_creationWorldTimeChanged(world__, creationWorldTime)
                world__.creationWorldTime = creationWorldTime
            end
            legacyCreationWorldTimeHandlerExtended = true
        end

        --Run the game timeControl.init
        super_timeControls(timeControls_, gameUI_, world_)
        --Run the TimeControlPlus addition
        timeControlsPlus:init(gameUI_, world_)
    end
end

return mod

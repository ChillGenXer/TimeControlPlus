--- TimeControlPlus: timeControl.lua
--- @author ChillGenXer
--- A replacement for the OOTB TimeControls HUD

--Default mod load order
local mod = {
    loadOrder = 1
}

-- Import timeControlPlus module that will replace the game version
local timeControlsPlus = mjrequire "timeControlPlus/timeControlPlus"

function mod:onload(timeControls)
    --mj:log("[CHILLGENXER] mod:Onload: Attempting to swap file")
    -- Clear the original timeControls table
    for k in pairs(timeControls) do
        timeControls[k] = nil
    end

    -- Replace the timeControls table with timeControlPlus
    for k, v in pairs(timeControlsPlus) do
        timeControls[k] = v
    end
end

return mod
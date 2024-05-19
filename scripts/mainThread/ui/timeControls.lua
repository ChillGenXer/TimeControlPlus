--- TimeControlsPlus: timeControls.lua
--- @author ChillGenXer
--- This is the entry file for the mod.  When timeControls is attempted to be loaded, this code will intercept
--- and replace with the modded code. 

--Default mod load order
local mod = {
    loadOrder = 1
}

-- Import your custom timeControlsPlus module
local timeControlsPlus = mjrequire "timeControlsPlus/timeControlsPlus"

-- Replace the contents of the vanilla timeControls file with the TimeControlsPlus code.
function mod:onload(timeControls)
    -- Replace the timeControls table with timeControlsPlus
    for k, v in pairs(timeControlsPlus) do
        timeControls[k] = v
    end
end

return mod

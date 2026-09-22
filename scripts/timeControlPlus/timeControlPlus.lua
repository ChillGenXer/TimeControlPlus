local compassUI = mjrequire "timeControlPlus/ui/compassUI"
local timeUI = mjrequire "timeControlPlus/ui/timeUI"

local timeControls = {}

function timeControls:updateLocalSpeedPreference(speedMultiplierIndex)
    timeUI:updateLocalSpeedPreference(speedMultiplierIndex)
end

function timeControls:getLocalSpeedPreference()
    return timeUI:getLocalSpeedPreference()
end

function timeControls:init(gameUI, world)
    compassUI:init(gameUI, world)
    timeUI:initializeTimeUI(gameUI, world)
end

-- The removed top menu panels had the only tribe-selection visibility policy.
-- Keep this native callback callable without imposing new behavior on Compass or Clock.
function timeControls:setHiddenForTribeSelection(newHidden)
end

function timeControls:playerTemperatureZoneChanged(newTemperatureZoneIndex)
    compassUI:playerTemperatureZoneChanged(newTemperatureZoneIndex)
end

function timeControls:setFastForwardDisabledByServer(newIsThrottled)
    timeUI:setFastForwardDisabledByServer(newIsThrottled)
end

-- Population and connection-warning presentation were intentionally removed.
-- These compatibility callbacks remain because native callers still invoke them.
function timeControls:setPopulation(newPopulation)
end

function timeControls:setPingValue(currentPingValue)
end

return timeControls

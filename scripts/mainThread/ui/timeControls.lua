-- TimeControlPlus
-- Author: chillgenxer@gmail.com

local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    superplayerTemperatureZoneChanged = timeControls.playerTemperatureZoneChanged

    --My overridden code
    timeControls.playerTemperatureZoneChanged = function(self, newTemperatureZoneIndex)
        temperatureTextView.text = "Testing 123"

    superplayerTemperatureZoneChanged(self)

end

return mod

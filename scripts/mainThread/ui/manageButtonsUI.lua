--- TimeControlsPlus: timeControls.lua
--- @author ChillGenXer
--- Mod for displaying a calendar and time in Sapiens.

local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3

--Default mod load order
local mod = {
    loadOrder = 1
}


function mod:onload(manageButtonsUI)
    --create a local copy of the init function of manageButtonsUI    
    local super_manageButtonsUI = manageButtonsUI.init

    --Redefine the function to also run the custom code
    manageButtonsUI.init = function(self_, gameUI_, manageUI_, hubUI_, world)
        --Run the game manageButtonsUI.init
        super_manageButtonsUI(self_, gameUI_, manageUI_, hubUI_, world)
        --Move the menu buttons down a smidge
        manageButtonsUI.menuButtonsView.baseOffset = vec3(0.0, -80.0, 0.0) 
    end
end

return mod
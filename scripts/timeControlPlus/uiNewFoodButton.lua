local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local uiMenuView = mjrequire "timeControlPlus/ui/uicommon/uiMenuView"

local uiNewFoodButton = {}

function uiNewFoodButton:init(parentView)
    
    -- Create the menu, positioned below the button
    local foodMenu = uiMenuView:create(parentView, vec2(80.0, 35.0), MJPositionInnerLeft, MJPositionCenter, vec3(0, 0, 0))
                  -- uiMenuView:create(parentView, buttonSize, horizontalPosition, verticalPosition, buttonOffset, width)
    -- Add menu items
    -- foodMenu:insertRow(foodMenu, {
    --     text = "Option 1",
    --     onClick = function()
    --         mj:log("Clicked Option 1")
    --     end
    -- })

    -- foodMenu:insertRow(foodMenu, {
    --     text = "Option 2",
    --     onClick = function()
    --         mj:log("Clicked Option 2")
    --     end
    -- })

    -- foodMenu:insertRow(foodMenu, {
    --     text = "Option 3"
    -- })

    return foodMenu
end

return uiNewFoodButton

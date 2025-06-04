local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local uiMenuView = mjrequire "timeControlPlus/ui/uicommon/uiMenuView"

local uiNewFoodButton = {}

-- Note: Assumes 'mj' is a global provided by Sapiens for logging (e.g., mj:log)

function uiNewFoodButton:init(parentView)
    -- Step 1: Create the menu structure with a button
    local menuStructure = uiMenuView:create(
        parentView,
        vec2(80.0, 40.0),
        MJPositionInnerLeft,
        MJPositionTop,
        vec3(0, 0, 0)
    )

    -- Step 2: Populate the mainMenu panel with menuItems
    menuStructure.menuPanels["MainMenu"].menuItems[1] = uiMenuView:insertRow("MainMenu", {
        text = "MI1.ItemA",
        onClick = function()
            mj:log("Clicked MI1.ItemA")
        end
    })

    menuStructure.menuPanels["MainMenu"].menuItems[2] = uiMenuView:insertRow("MainMenu", {
        text = "MI2.ItemB",
        submenuPanelName = "subMenuMenuItem2" -- Specify the submenu this item controls
    })

    menuStructure.menuPanels["MainMenu"].menuItems[3] = uiMenuView:insertRow("MainMenu", {
        text = "MI3.ItemC",
        submenuPanelName = "subMenuMenuItem3" -- Specify another submenu
    })

    menuStructure.menuPanels["MainMenu"].menuItems[4] = uiMenuView:insertRow("MainMenu", {
        text = "MI4.ItemD",
        onClick = function()
            mj:log("Clicked MI4.ItemD")
        end
    })

    -- Step 3: Create subMenuMenuItem2 and its menuItems, specifying the parent menuItem
    local parentMenuItem2 = menuStructure.menuPanels["MainMenu"].menuItems[2]
    uiMenuView:createMenuPanel("subMenuMenuItem2", parentMenuItem2.colorView, parentMenuItem2, "MainMenu")
    menuStructure.menuPanels["subMenuMenuItem2"].menuItems[1] = uiMenuView:insertRow("subMenuMenuItem2", {
        text = "MI2.ItemB1",
        onClick = function()
            mj:log("Clicked MI2.ItemB1")
        end
    })
    menuStructure.menuPanels["subMenuMenuItem2"].menuItems[2] = uiMenuView:insertRow("subMenuMenuItem2", {
        text = "MI2.ItemB2",
        onClick = function()
            mj:log("Clicked MI2.ItemB2")
        end
    })

    -- Create subMenuMenuItem3 and its menuItems
    local parentMenuItem3 = menuStructure.menuPanels["MainMenu"].menuItems[3]
    uiMenuView:createMenuPanel("subMenuMenuItem3", parentMenuItem3.colorView, parentMenuItem3, "MainMenu")
    menuStructure.menuPanels["subMenuMenuItem3"].menuItems[1] = uiMenuView:insertRow("subMenuMenuItem3", {
        text = "MI3.ItemC1",
        onClick = function()
            mj:log("Clicked MI3.ItemC1")
        end
    })
    menuStructure.menuPanels["subMenuMenuItem3"].menuItems[2] = uiMenuView:insertRow("subMenuMenuItem3", {
        text = "MI3.ItemC2",
        onClick = function()
            mj:log("Clicked MI3.ItemC2")
        end
    })

    -- Step 4: Initialize hover event functionality
    uiMenuView:initialize()

    local testObject = {
        menuStructure = menuStructure,
        update = function(self, dt)
            -- No state updates needed; visibility is handled by events
        end,
        cleanup = function(self)
            -- Remove all menu items
            for _, panel in pairs(self.menuStructure.menuPanels) do
                for _, menuItem in ipairs(panel.menuItems) do
                    panel.menuPanelView:removeSubview(menuItem.colorView)
                    if menuItem.iconPlayView then
                        panel.menuPanelView:removeSubview(menuItem.iconPlayView)
                    end
                end
                panel.menuItems = {}
            end
        end
    }

    return testObject
end

return uiNewFoodButton
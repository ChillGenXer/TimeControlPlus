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

    menuStructure.menuPanels["MainMenu"].menuItems[5] = uiMenuView:insertRow("MainMenu", {
        text = "MI5.ItemE",
        onClick = function()
            mj:log("Clicked MI5.ItemE")
        end
    })

    menuStructure.menuPanels["MainMenu"].menuItems[6] = uiMenuView:insertRow("MainMenu", {
        text = "MI6.ItemF",
        onClick = function()
            mj:log("Clicked MI6.ItemF")
        end
    })

    -- Step 3: Create subMenuMenuItem2 and its menuItems, specifying the parent menuItem
    local parentMenuItem2 = menuStructure.menuPanels["MainMenu"].menuItems[2]
    uiMenuView:createMenuPanel("subMenuMenuItem2", parentMenuItem2.colorView, parentMenuItem2, "MainMenu")
    menuStructure.menuPanels["subMenuMenuItem2"].menuItems[1] = uiMenuView:insertRow("subMenuMenuItem2", {
        text = "MI2.ItemB1",
        submenuPanelName = "subSubMenuItemB1" -- Add a third level submenu
    })
    menuStructure.menuPanels["subMenuMenuItem2"].menuItems[2] = uiMenuView:insertRow("subMenuMenuItem2", {
        text = "MI2.ItemB2",
        onClick = function()
            mj:log("Clicked MI2.ItemB2")
        end
    })
    menuStructure.menuPanels["subMenuMenuItem2"].menuItems[3] = uiMenuView:insertRow("subMenuMenuItem2", {
        text = "MI2.ItemB3",
        onClick = function()
            mj:log("Clicked MI2.ItemB3")
        end
    })

    -- Create subSubMenuItemB1 under MI2.ItemB1
    local parentMenuItemB1 = menuStructure.menuPanels["subMenuMenuItem2"].menuItems[1]
    uiMenuView:createMenuPanel("subSubMenuItemB1", parentMenuItemB1.colorView, parentMenuItemB1, "subMenuMenuItem2")
    menuStructure.menuPanels["subSubMenuItemB1"].menuItems[1] = uiMenuView:insertRow("subSubMenuItemB1", {
        text = "MI2.ItemB1.1",
        onClick = function()
            mj:log("Clicked MI2.ItemB1.1")
        end
    })
    menuStructure.menuPanels["subSubMenuItemB1"].menuItems[2] = uiMenuView:insertRow("subSubMenuItemB1", {
        text = "MI2.ItemB1.2",
        onClick = function()
            mj:log("Clicked MI2.ItemB1.2")
        end
    })

    -- Create subMenuMenuItem3 and its menuItems
    local parentMenuItem3 = menuStructure.menuPanels["MainMenu"].menuItems[3]
    uiMenuView:createMenuPanel("subMenuMenuItem3", parentMenuItem3.colorView, parentMenuItem3, "MainMenu")
    menuStructure.menuPanels["subMenuMenuItem3"].menuItems[1] = uiMenuView:insertRow("subMenuMenuItem3", {
        text = "MI3.ItemC1",
        submenuPanelName = "subSubMenuItemC1" -- Add a third level submenu
    })
    menuStructure.menuPanels["subMenuMenuItem3"].menuItems[2] = uiMenuView:insertRow("subMenuMenuItem3", {
        text = "MI3.ItemC2",
        onClick = function()
            mj:log("Clicked MI3.ItemC2")
        end
    })
    menuStructure.menuPanels["subMenuMenuItem3"].menuItems[3] = uiMenuView:insertRow("subMenuMenuItem3", {
        text = "MI3.ItemC3",
        onClick = function()
            mj:log("Clicked MI3.ItemC3")
        end
    })

    -- Create subSubMenuItemC1 under MI3.ItemC1
    local parentMenuItemC1 = menuStructure.menuPanels["subMenuMenuItem3"].menuItems[1]
    uiMenuView:createMenuPanel("subSubMenuItemC1", parentMenuItemC1.colorView, parentMenuItemC1, "subMenuMenuItem3")
    menuStructure.menuPanels["subSubMenuItemC1"].menuItems[1] = uiMenuView:insertRow("subSubMenuItemC1", {
        text = "MI3.ItemC1.1",
        onClick = function()
            mj:log("Clicked MI3.ItemC1.1")
        end
    })
    menuStructure.menuPanels["subSubMenuItemC1"].menuItems[2] = uiMenuView:insertRow("subSubMenuItemC1", {
        text = "MI3.ItemC1.2",
        onClick = function()
            mj:log("Clicked MI3.ItemC1.2")
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
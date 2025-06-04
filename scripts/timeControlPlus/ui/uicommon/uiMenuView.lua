local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local material = mjrequire "common/material"

local uiMenuView = {}

-- Module-level global menuStructure
local menuStructure = nil

-- Constants for menu panel sizing
local borderWidth = 5.0
local contentPaddingHorizontal = 5.0
local contentPaddingVertical = 5.0

-- Constants for menu item creation
local rowHeight = 30.0
local metricsRowHeight = 60.0
local rowInsetHorizontal = 11.0
local fontSize = 16
local backgroundColor = vec4(0.3, 0.3, 0.3, 1.0) -- Brighter gray for testing visibility, with alpha
local defaultBackgroundColors = { vec4(0.5, 0.5, 0.5, 1.0), vec4(0.2, 0.2, 0.2, 1.0) } -- Brighter for testing, with alpha
local textOffsetX = 10
local iconPlayOffsetX = 10 -- Offset for IconPlay model from right edge

-- Local function to update Y offsets for rows and resize the menu panel
local function updateYOffsets(self, rowStartIndex)
    local menuItems = self.menuItems
    local menuPanelView = self.menuPanelView
    local panelWidth = self.panelWidth

    -- Update Y offsets for rows starting from rowStartIndex
    for i = rowStartIndex, #menuItems do
        local menuItem = menuItems[i]
        local aboveMenuItem = menuItems[i - 1]
        if aboveMenuItem then
            menuItem.yOffsetFromTop = aboveMenuItem.yOffsetFromTop + aboveMenuItem.rowHeight
        else
            menuItem.yOffsetFromTop = contentPaddingVertical -- Start with padding for the first item
        end
        menuItem.colorView.baseOffset = vec3(0, -menuItem.yOffsetFromTop, 0)
        if menuItem.iconPlayView then
            menuItem.iconPlayView.baseOffset = vec3((panelWidth - 2 * contentPaddingHorizontal - 2 * rowInsetHorizontal) / 2 - iconPlayOffsetX, 0, 1)
        end
    end

    -- Calculate total content height
    local numRows = #menuItems
    local totalContentHeight = 0
    for i = 1, numRows do
        totalContentHeight = totalContentHeight + menuItems[i].rowHeight
    end

    -- Update the menu panel (menuPanelView) size
    local contentWidth = panelWidth - 2 * contentPaddingHorizontal - 2 * rowInsetHorizontal
    local contentHeight = math.max(totalContentHeight, rowHeight) -- Ensure at least one row height
    local menuViewWidth = contentWidth + 2 * contentPaddingHorizontal
    local menuViewHeight = contentHeight + 2 * contentPaddingVertical
    menuPanelView.size = vec2(menuViewWidth, menuViewHeight)
end

-- Function to create a new menu panel
function uiMenuView:createMenuPanel(menuPanelName, parentView, parentMenuItem, parentMenuName)
    local panelWidth = 180 + borderWidth -- Width for better fit
    local newMenuPanel = {
        menuPanelName = menuPanelName,
        panelWidth = panelWidth,
        menuPanelView = nil,
        positionHierarchy = parentMenuName and (menuStructure.menuPanels[parentMenuName].positionHierarchy + 1) or 0,
        menuItems = {},
        backgroundColorCounter = 1,
        parentMenuName = parentMenuName -- Track parent menu for visibility
    }

    -- Create the menu panel view (ColorView)
    local menuPanelView = ColorView.new(parentView)
    menuPanelView.color = backgroundColor
    if menuPanelName == "MainMenu" then
        menuPanelView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        menuPanelView.baseOffset = vec3(0, 0, 0)
    else
        -- Position relative to the parent menu item
        menuPanelView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
        menuPanelView.relativeView = parentMenuItem.colorView
        menuPanelView.baseOffset = vec3(0, 0 + contentPaddingVertical, 0)
    end
    menuPanelView.size = vec2(
        panelWidth - 2 * contentPaddingHorizontal,
        rowHeight + 2 * contentPaddingVertical
    ) -- Initial size, adjusted dynamically
    menuPanelView.hidden = true
    menuPanelView.masksEvents = true
    newMenuPanel.menuPanelView = menuPanelView

    menuStructure.menuPanels[menuPanelName] = newMenuPanel

    return newMenuPanel
end

-- Function to create a new menu instance with a button
function uiMenuView:create(parentView, buttonSize, horizontalPosition, verticalPosition, buttonOffset)
    -- Initialize the module-level menuStructure
    menuStructure = {
        button = nil,
        menuPanels = {},
        visibilityStack = {}
    }

    -- Create the main button
    local button = uiStandardButton:create(parentView, buttonSize, uiStandardButton.types.slim_1x1, {
        default = material.types.ui_background.index
    })
    button.relativePosition = ViewPosition(horizontalPosition, verticalPosition)
    button.size = buttonSize
    button.baseOffset = buttonOffset
    button.masksEvents = true
    menuStructure.button = button

    -- Create the main menu panel
    local mainMenuPanel = self:createMenuPanel("MainMenu", button)

    -- Attach click handler to toggle the main menu
    uiStandardButton:setClickFunction(button, function()
        local menuPanelView = menuStructure.menuPanels["MainMenu"].menuPanelView
        if menuPanelView.hidden then
            menuPanelView.hidden = false
            menuStructure.visibilityStack = {"MainMenu"}
        else
            -- Hide all menu panels when toggling off
            for _, panel in pairs(menuStructure.menuPanels) do
                panel.menuPanelView.hidden = true
            end
            menuStructure.visibilityStack = {}
        end
    end)

    -- Attach hover handlers to the button to show the main menu
    button.hoverStart = function()
        local menuPanelView = menuStructure.menuPanels["MainMenu"].menuPanelView
        if menuPanelView.hidden then
            menuPanelView.hidden = false
            menuStructure.visibilityStack = {"MainMenu"}
        end
    end
    button.hoverEnd = function()
        -- Do not hide on hover end; visibility is managed by click or clickDownOutside
    end

    return menuStructure
end

-- Function to insert a new item into a specific menu panel
function uiMenuView:insertRow(menuPanelName, itemParams)
    -- Retrieve the menu panel by name
    local menuPanel = menuStructure.menuPanels[menuPanelName]
    if not menuPanel then
        error("Menu panel '" .. tostring(menuPanelName) .. "' not found in menuStructure.menuPanels")
    end

    local menuItems = menuPanel.menuItems
    local rowIndex = #menuItems + 1

    -- Create the row view with the correct parent
    local rowHeightToUse = (itemParams.useMetricsHeight and metricsRowHeight) or rowHeight
    local menuItem = {
        colorView = ColorView.new(menuPanel.menuPanelView), -- Parent is menuPanelView
        textView = nil,
        rowHeight = rowHeightToUse,
        yOffsetFromTop = 0,
        submenuPanelName = itemParams.submenuPanelName, -- Optional: name of submenu panel this item controls
        iconPlayView = nil -- Will be set if submenuPanelName exists
    }
    menuItem.colorView.size = vec2(
        menuPanel.panelWidth - 2 * contentPaddingHorizontal - 2 * rowInsetHorizontal,
        rowHeightToUse
    )
    menuItem.colorView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

    local colorIndex = menuPanel.backgroundColorCounter % 2 + 1
    menuItem.colorView.color = defaultBackgroundColors[colorIndex]
    menuPanel.backgroundColorCounter = menuPanel.backgroundColorCounter + 1

    -- Add the text for the menu item
    local textView = TextView.new(menuItem.colorView)
    textView.font = Font(uiCommon.fontName, fontSize)
    if itemParams.useMetricsHeight then
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        textView.baseOffset = vec3(textOffsetX, -5, 1)
    else
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        textView.baseOffset = vec3(textOffsetX, 0, 1)
    end
    textView.text = itemParams.text or "Unknown Item"
    textView.color = mj.textColor
    menuItem.textView = textView

    -- Add the IconPlay model if this menu item has a child
    if itemParams.submenuPanelName then
        local iconPlayView = ModelView.new(menuItem.colorView)
        iconPlayView:setModel(model:modelIndexForName("icon_play"))
        iconPlayView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
        -- Position will be updated in updateYOffsets
        iconPlayView.baseOffset = vec3((menuPanel.panelWidth - 2 * contentPaddingHorizontal - 2 * rowInsetHorizontal) / 2 - iconPlayOffsetX, 0, 1)
        iconPlayView.scale3D = vec3(0.5, 0.5, 0.5) -- Small scale for the icon
        iconPlayView.hidden = false
        menuItem.iconPlayView = iconPlayView
    end

    -- Add a click handler if provided
    if itemParams.onClick then
        menuItem.colorView.masksEvents = true
        menuItem.colorView.click = function(buttonIndex)
            itemParams.onClick()
        end
    end

    -- Attach clickDownOutside handler to keep parent menu visible while submenu is open
    menuItem.colorView.clickDownOutside = function(buttonIndex)
        -- Hide all menu panels when clicking outside
        for _, panel in pairs(menuStructure.menuPanels) do
            panel.menuPanelView.hidden = true
        end
        menuStructure.visibilityStack = {}
    end

    -- Insert the menu item into the menuItems table
    table.insert(menuItems, rowIndex, menuItem)

    -- Update positions and resize the menu panel
    updateYOffsets(menuPanel, rowIndex)

    return menuItem
end

-- Function to initialize hover event functionality
function uiMenuView:initialize()
    -- Attach hover handlers to all menu panels and items
    for panelName, panel in pairs(menuStructure.menuPanels) do
        local menuPanelView = panel.menuPanelView
        local menuItems = panel.menuItems
        local positionHierarchy = panel.positionHierarchy
        local parentMenuName = panel.parentMenuName

        -- Attach hover handlers to the menuPanelView
        menuPanelView.hoverStart = function()
            menuPanelView.hidden = false
            -- Ensure the menu is in the visibility stack
            if panelName == "MainMenu" and not menuStructure.visibilityStack[1] then
                menuStructure.visibilityStack[1] = "MainMenu"
            elseif panelName ~= "MainMenu" and not menuStructure.visibilityStack[positionHierarchy + 1] then
                menuStructure.visibilityStack[positionHierarchy + 1] = panelName
            end
        end
        menuPanelView.hoverEnd = function()
            -- Only apply to submenus; MainMenu visibility is managed by clicks
            if panelName ~= "MainMenu" then
                -- Hide this panel and all its descendants if the mouse isn't over a child
                local shouldHide = true
                for i = positionHierarchy + 2, #menuStructure.visibilityStack do
                    if menuStructure.visibilityStack[i] then
                        shouldHide = false
                        break
                    end
                end
                if shouldHide then
                    -- Hide this panel and all descendants
                    for _, otherPanel in pairs(menuStructure.menuPanels) do
                        if otherPanel.positionHierarchy >= positionHierarchy then
                            otherPanel.menuPanelView.hidden = true
                        end
                    end
                    -- Clear the visibility stack for this level and below
                    for i = positionHierarchy + 1, #menuStructure.visibilityStack do
                        menuStructure.visibilityStack[i] = nil
                    end
                end
            end
        end

        -- Attach clickDownOutside handler to the menuPanelView to hide all panels
        menuPanelView.clickDownOutside = function(buttonIndex)
            -- Hide all menu panels when clicking outside
            for _, otherPanel in pairs(menuStructure.menuPanels) do
                otherPanel.menuPanelView.hidden = true
            end
            menuStructure.visibilityStack = {}
        end

        -- Attach hover handlers to menu items
        for _, menuItem in ipairs(menuItems) do
            menuItem.colorView.hoverStart = function()
                -- Hide submenus of sibling menu items in the same panel
                for _, siblingItem in ipairs(menuItems) do
                    if siblingItem ~= menuItem and siblingItem.submenuPanelName then
                        local siblingSubmenu = menuStructure.menuPanels[siblingItem.submenuPanelName]
                        if siblingSubmenu and not siblingSubmenu.menuPanelView.hidden then
                            siblingSubmenu.menuPanelView.hidden = true
                            -- Clear the visibility stack for that submenu's level and below
                            for i = positionHierarchy + 2, #menuStructure.visibilityStack do
                                if menuStructure.visibilityStack[i] == siblingItem.submenuPanelName then
                                    menuStructure.visibilityStack[i] = nil
                                end
                            end
                        end
                    end
                end

                -- Show this item's submenu if it exists
                if menuItem.submenuPanelName then
                    local submenuPanel = menuStructure.menuPanels[menuItem.submenuPanelName]
                    if submenuPanel then
                        submenuPanel.menuPanelView.hidden = false
                        -- Add to visibility stack
                        if panelName == "MainMenu" and not menuStructure.visibilityStack[1] then
                            menuStructure.visibilityStack[1] = "MainMenu"
                        end
                        if not menuStructure.visibilityStack[positionHierarchy + 2] then
                            menuStructure.visibilityStack[positionHierarchy + 2] = menuItem.submenuPanelName
                        end
                    end
                end
            end
            menuItem.colorView.hoverEnd = function()
                -- Do not hide immediately; let the submenu's hover handlers manage visibility
            end
        end
    end
end

return uiMenuView
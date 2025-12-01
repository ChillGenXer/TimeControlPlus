local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local material = mjrequire "common/material"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"

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
local backgroundColor = vec4(0.3, 0.3, 0.3, 1.0)
local defaultBackgroundColors = { vec4(0.5, 0.5, 0.5, 1.0), vec4(0.2, 0.2, 0.2, 1.0) }
local textOffsetX = 10

-- Local function to update Y offsets for rows and resize the menu panel
local function updateYOffsets(self, rowStartIndex)
    local menuItems = self.menuItems
    local menuPanelView = self.menuPanelView
    local panelWidth = self.panelWidth

    for i = rowStartIndex, #menuItems do
        local menuItem = menuItems[i]
        local aboveMenuItem = menuItems[i - 1]
        if aboveMenuItem then
            menuItem.yOffsetFromTop = aboveMenuItem.yOffsetFromTop + aboveMenuItem.rowHeight
        else
            menuItem.yOffsetFromTop = contentPaddingVertical
        end
        menuItem.colorView.baseOffset = vec3(0, -menuItem.yOffsetFromTop, 0)
        if menuItem.iconPlayView then
            menuItem.iconPlayView.baseOffset = vec3(0, 0, 2)
        end
        if menuItem.gameObjectView then
            menuItem.gameObjectView.baseOffset = vec3(8, 0, 1)
        end
    end

    local numRows = #menuItems
    local totalContentHeight = 0
    for i = 1, numRows do
        totalContentHeight = totalContentHeight + menuItems[i].rowHeight
    end

    local contentWidth = panelWidth - 2 * contentPaddingHorizontal - 2 * rowInsetHorizontal
    local contentHeight = math.max(totalContentHeight, rowHeight)
    local menuViewWidth = contentWidth + 2 * contentPaddingHorizontal
    local menuViewHeight = contentHeight + 2 * contentPaddingVertical
    menuPanelView.size = vec2(menuViewWidth, menuViewHeight)
end

-- Function to create a new menu panel with optional custom width
function uiMenuView:createMenuPanel(menuPanelName, parentView, parentMenuItem, parentMenuName, customPanelWidth)
    local panelWidth = customPanelWidth or (180 + borderWidth)
    local newMenuPanel = {
        menuPanelName = menuPanelName,
        panelWidth = panelWidth,
        menuPanelView = nil,
        positionHierarchy = parentMenuName and (menuStructure.menuPanels[parentMenuName].positionHierarchy + 1) or 0,
        menuItems = {},
        backgroundColorCounter = 1,
        parentMenuName = parentMenuName
    }

    local menuPanelView = ColorView.new(parentView)
    menuPanelView.color = backgroundColor
    if menuPanelName == "MainMenu" then
        menuPanelView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        menuPanelView.baseOffset = vec3(0, 0, 0)
    else
        menuPanelView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
        menuPanelView.relativeView = parentMenuItem.colorView
        menuPanelView.baseOffset = vec3(0, 0 + contentPaddingVertical, 0)
    end
    menuPanelView.size = vec2(
        panelWidth - 2 * contentPaddingHorizontal,
        rowHeight + 2 * contentPaddingVertical
    )
    menuPanelView.hidden = true
    menuPanelView.masksEvents = true
    newMenuPanel.menuPanelView = menuPanelView

    menuStructure.menuPanels[menuPanelName] = newMenuPanel

    return newMenuPanel
end

-- Function to create a new menu instance with a button, accepting custom main menu width
function uiMenuView:create(parentView, buttonSize, horizontalPosition, verticalPosition, buttonOffset, mainMenuPanelWidth)
    menuStructure = {
        button = nil,
        menuPanels = {},
        isMainMenuVisible = false,
        isClickProcessed = false
    }

    local button = uiStandardButton:create(parentView, buttonSize, uiStandardButton.types.slim_1x1, {
        default = material.types.ui_background.index
    })
    button.relativePosition = ViewPosition(horizontalPosition, verticalPosition)
    button.size = buttonSize
    button.baseOffset = buttonOffset
    button.masksEvents = true
    menuStructure.button = button

    self:createMenuPanel("MainMenu", button, nil, nil, mainMenuPanelWidth)

    uiStandardButton:setClickFunction(button, function()
        if menuStructure.isClickProcessed then
            mj:log("Button click ignored: click already processed")
            return
        end
        menuStructure.isClickProcessed = true

        local mainMenuPanel = menuStructure.menuPanels["MainMenu"]
        mj:log("Button clicked: isMainMenuVisible = " .. tostring(menuStructure.isMainMenuVisible) .. ", mainMenu.hidden = " .. tostring(mainMenuPanel.menuPanelView.hidden))

        if menuStructure.isMainMenuVisible then
            for _, panel in pairs(menuStructure.menuPanels) do
                panel.menuPanelView.hidden = true
            end
            menuStructure.isMainMenuVisible = false
            mj:log("Hiding all panels: mainMenu.hidden = " .. tostring(mainMenuPanel.menuPanelView.hidden))
        else
            mainMenuPanel.menuPanelView.hidden = false
            menuStructure.isMainMenuVisible = true
            mj:log("Showing main menu: mainMenu.hidden = " .. tostring(mainMenuPanel.menuPanelView.hidden))
        end

        menuStructure.isClickProcessed = false
    end)

    button.clickDownOutside = function(buttonIndex)
        local isAnyPanelVisible = false
        for _, panel in pairs(menuStructure.menuPanels) do
            if not panel.menuPanelView.hidden then
                isAnyPanelVisible = true
                break
            end
        end

        if not isAnyPanelVisible then
            mj:log("Button clickDownOutside: no panels visible, ignoring")
            return
        end

        mj:log("Button clickDownOutside: click is outside button and all panels, hiding all panels")
        for _, panel in pairs(menuStructure.menuPanels) do
            panel.menuPanelView.hidden = true
            panel.menuPanelView.hidden = false
            panel.menuPanelView.hidden = true
        end
        menuStructure.isMainMenuVisible = false
        mj:log("After button clickDownOutside: isMainMenuVisible = " .. tostring(menuStructure.isMainMenuVisible) .. ", mainMenu.hidden = " .. tostring(menuStructure.menuPanels["MainMenu"].menuPanelView.hidden))
    end

    return menuStructure
end

-- Function to insert a new item into a specific menu panel
function uiMenuView:insertRow(menuPanelName, itemParams)
    local menuPanel = menuStructure.menuPanels[menuPanelName]
    if not menuPanel then
        error("Menu panel '" .. tostring(menuPanelName) .. "' not found in menuStructure.menuPanels")
    end

    local menuItems = menuPanel.menuItems
    local rowIndex = #menuItems + 1

    local rowHeightToUse = (itemParams.useMetricsHeight and metricsRowHeight) or rowHeight
    local menuItem = {
        colorView = ColorView.new(menuPanel.menuPanelView),
        textView = nil,
        rowHeight = rowHeightToUse,
        yOffsetFromTop = 0,
        submenuPanelName = itemParams.submenuPanelName,
        iconPlayView = nil,
        gameObjectView = nil
    }
    menuItem.colorView.size = vec2(
        menuPanel.panelWidth - 2 * contentPaddingHorizontal - 2 * rowInsetHorizontal,
        rowHeightToUse
    )
    menuItem.colorView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    menuItem.colorView.hidden = false

    local colorIndex = menuPanel.backgroundColorCounter % 2 + 1
    menuItem.colorView.color = defaultBackgroundColors[colorIndex]
    menuPanel.backgroundColorCounter = menuPanel.backgroundColorCounter + 1

    if itemParams.gameObjectTypeIndex then
        local iconSize = vec2(30.0, 30.0)
        local gameObjectView = uiGameObjectView:create(menuItem.colorView, iconSize, uiGameObjectView.types.standard)
        gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        uiGameObjectView:setObject(gameObjectView, {
            objectTypeIndex = itemParams.gameObjectTypeIndex
        }, nil, nil)
        gameObjectView.masksEvents = false
        gameObjectView.alpha = 1.0
        gameObjectView.hidden = false
        menuItem.gameObjectView = gameObjectView
    end

    local textView = TextView.new(menuItem.colorView)
    textView.font = Font(uiCommon.fontName, fontSize)
    if itemParams.useMetricsHeight then
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        textView.baseOffset = vec3(textOffsetX, -5, 1)
    else
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        if itemParams.gameObjectTypeIndex then
            textView.baseOffset = vec3(textOffsetX + 30, 0, 1)
        else
            textView.baseOffset = vec3(textOffsetX, 0, 1)
        end
    end
    textView.text = itemParams.text or "Unknown Item"
    textView.color = mj.textColor
    textView.hidden = false
    menuItem.textView = textView

    if itemParams.onClick then
        menuItem.colorView.masksEvents = true
        menuItem.colorView.click = function(buttonIndex)
            itemParams.onClick()
        end
    end

    table.insert(menuItems, rowIndex, menuItem)

    updateYOffsets(menuPanel, rowIndex)

    return menuItem
end

-- Function to initialize hover event functionality and add submenu indicators
function uiMenuView:initialize()
    for panelName, panel in pairs(menuStructure.menuPanels) do
        local menuPanelView = panel.menuPanelView
        local menuItems = panel.menuItems
        local positionHierarchy = panel.positionHierarchy
        local parentMenuName = panel.parentMenuName

        menuPanelView.hoverStart = function()
            menuPanelView.hidden = false
        end
        menuPanelView.hoverEnd = function()
            if panelName ~= "MainMenu" then
                local shouldHide = true
                for _, otherPanel in pairs(menuStructure.menuPanels) do
                    if otherPanel.positionHierarchy > positionHierarchy and not otherPanel.menuPanelView.hidden then
                        shouldHide = false
                        break
                    end
                end
                if shouldHide then
                    for _, otherPanel in pairs(menuStructure.menuPanels) do
                        if otherPanel.positionHierarchy > 0 then -- Only hide submenus, not MainMenu
                            otherPanel.menuPanelView.hidden = true
                        end
                    end
                end
            end
        end

        for _, menuItem in ipairs(menuItems) do
            if menuItem.submenuPanelName and menuStructure.menuPanels[menuItem.submenuPanelName] then
                if not menuItem.iconPlayView then
                    local iconPlayView = ModelView.new(menuItem.colorView)
                    local modelIndex = model:modelIndexForName("icon_play")
                    iconPlayView:setModel(modelIndex)
                    iconPlayView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
                    iconPlayView.scale3D = vec3(10, 10, 10)
                    iconPlayView.size = vec2(20, 20)
                    iconPlayView.masksEvents = false
                    iconPlayView.hidden = false
                    iconPlayView.alpha = 1.0
                    menuItem.iconPlayView = iconPlayView
                    updateYOffsets(panel, 1)
                end
            end

            menuItem.colorView.hoverStart = function()
                for _, siblingItem in ipairs(menuItems) do
                    if siblingItem ~= menuItem and siblingItem.submenuPanelName then
                        local siblingSubmenu = menuStructure.menuPanels[siblingItem.submenuPanelName]
                        if siblingSubmenu and not siblingSubmenu.menuPanelView.hidden then
                            siblingSubmenu.menuPanelView.hidden = true
                            for _, otherPanel in pairs(menuStructure.menuPanels) do
                                if otherPanel.positionHierarchy > siblingSubmenu.positionHierarchy then
                                    otherPanel.menuPanelView.hidden = true
                                end
                            end
                        end
                    end
                end

                if menuItem.submenuPanelName then
                    local submenuPanel = menuStructure.menuPanels[menuItem.submenuPanelName]
                    if submenuPanel then
                        submenuPanel.menuPanelView.hidden = false
                    end
                end
            end
            menuItem.colorView.hoverEnd = function()
            end
        end
    end
end

return uiMenuView
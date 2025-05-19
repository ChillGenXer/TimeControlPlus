local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"

local uiMenuView = {}

-- Constants aligned with base game style
local rowHeight = 30.0
local padding = 20.0
local borderWidth = 20.0
local indicatorSize = 16.0
local indicatorScale = 8.0
local modelHeight = 1.0
local fontSize = 16
local defaultBackgroundColors = { vec4(0.05, 0.05, 0.05, 1.0), vec4(0.0, 0.0, 0.0, 1.0) }
local iconHalfSize = 8 -- Standardized icon size (16x16 pixels)
local rightButtonIconHalfSize = 10 -- Adjusted for smaller button (20x20 pixels)
local textOffsetX = 10 -- Offset for text without left icon
local textOffsetXWithIcon = 25 -- Offset for text with left icon
local iconOffsetX = 5 -- Offset for icons (left, right, submenu)

-- Helper function to calculate scale3D for the panel
local function calculateScale3D(width, height, modelHeight)
    local scaleX = width / 2
    local scaleY = height / (modelHeight * 2)
    local scaleZ = scaleX
    return vec3(scaleX, scaleY, scaleZ)
end

-- Helper function to determine opening direction based on screen edge
local function determineOpenDirection(gameUI, menuWidth, menuLevel, defaultPosX, menuHeight, defaultPosY)
    local openDirection = { horizontal = "right", vertical = "below" } -- Default to right and below
    if gameUI and gameUI.view and gameUI.view.size then
        local screenSize = gameUI.view.size
        local screenWidth = screenSize.x
        local screenHeight = screenSize.y

        -- Horizontal adjustment
        local approxMenuX = defaultPosX + (menuLevel * menuWidth)
        openDirection.horizontal = (approxMenuX + menuWidth > screenWidth) and "left" or "right"

        -- Vertical adjustment (for submenus)
        if menuLevel > 0 then
            local approxMenuY = defaultPosY + (menuHeight / 2)
            openDirection.vertical = (approxMenuY + (menuHeight / 2) > screenHeight) and "above" or "below"
        end

        mj:log("determineOpenDirection - screenWidth:", screenWidth, "screenHeight:", screenHeight, 
               "menuWidth:", menuWidth, "menuHeight:", menuHeight, 
               "approxMenuX:", approxMenuX, "approxMenuY:", approxMenuY, 
               "menuLevel:", menuLevel, "openDirection:", openDirection)
    else
        mj:log("determineOpenDirection - Error: gameUI or its view/size is nil, defaulting to openDirection = right, below")
    end
    return openDirection
end

-- Helper function to create a menu panel and its items recursively
local function createMenuPanel(menuConfig, parentView, relativeView, menuLevel, gameUI)
    if not menuConfig.menuItems then
        mj:log("createMenuPanel - Warning: menuConfig.menuItems is nil or empty")
    end

    local userTable = {
        panelWidth = menuConfig.width + borderWidth,
        width = menuConfig.width,
        minHeight = menuConfig.minHeight or 42.0,
        rowInfos = {},
        backgroundColorCounter = 1,
        hoverState = { isHovering = false, hasActiveSubmenu = false },
        parentHoverState = nil,
        menuLevel = menuLevel,
        gameUI = gameUI,
        openDirection = { horizontal = "right", vertical = "below" },
        horizontalAlignment = (menuLevel == 0) and MJPositionInnerLeft or MJPositionOuterRight,
        verticalAlignment = (menuLevel == 0) and MJPositionBelow or MJPositionTop,
        positionAdjusted = false,
        backgroundColors = menuConfig.backgroundColors or defaultBackgroundColors
    }

    -- Create the panel (background) with ui_bg_lg_1x1
    local panel = ModelView.new(parentView)
    panel:setModel(model:modelIndexForName("ui_bg_lg_1x1"))
    panel.relativePosition = ViewPosition(userTable.horizontalAlignment, userTable.verticalAlignment)
    panel.relativeView = relativeView
    -- Adjust baseOffset for submenus to align the tops of the menu items (rowViews)
    if menuLevel > 0 and relativeView.baseOffset then
        panel.baseOffset = vec3(0, -relativeView.baseOffset.y + padding, 0) -- Align tops of rowViews
    else
        panel.baseOffset = vec3(0, 0, 0)
    end
    panel.size = vec2(userTable.panelWidth, userTable.minHeight)
    panel.scale3D = calculateScale3D(userTable.panelWidth, userTable.minHeight, modelHeight)
    panel.hidden = true
    panel.masksEvents = true
    panel.click = function(buttonIndex)
        mj:log("panel.click - Level:", menuLevel, "buttonIndex:", buttonIndex)
    end
    userTable.panel = panel

    -- Create the baseItemView to hold rows, centered both horizontally and vertically
    local baseItemView = View.new(panel)
    baseItemView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    baseItemView.size = vec2(userTable.width, userTable.minHeight - padding)
    baseItemView.masksEvents = true
    baseItemView.click = function(buttonIndex)
        mj:log("baseItemView.click - Level:", menuLevel, "buttonIndex:", buttonIndex)
    end
    userTable.baseItemView = baseItemView

    -- Setup hover for the panel
    panel.masksEvents = true
    panel.hoverStart = function()
        mj:log("panel.hoverStart - Level:", menuLevel, "isHovering:", userTable.hoverState.isHovering)
        userTable.hoverState.isHovering = true
        panel.hidden = false
        if userTable.parentHoverState then
            userTable.parentHoverState.isHovering = true
            userTable.parentHoverState.hasActiveSubmenu = true
        end
    end
    panel.hoverEnd = function()
        mj:log("panel.hoverEnd - Level:", menuLevel, "isHovering:", userTable.hoverState.isHovering)
        userTable.hoverState.isHovering = false
        local isAnyRowHovered = false
        for _, rowInfo in ipairs(userTable.rowInfos) do
            if rowInfo.isHovering then
                isAnyRowHovered = true
                break
            end
        end
        if not isAnyRowHovered then
            panel.hidden = true
            -- Close all submenus recursively
            for _, rowInfo in ipairs(userTable.rowInfos) do
                if rowInfo.hasSubMenu then
                    rowInfo.subMenu.userData.panel.hidden = true
                    local function closeSubmenus(menuPanel)
                        for _, subRowInfo in ipairs(menuPanel.userData.rowInfos) do
                            if subRowInfo.hasSubMenu then
                                subRowInfo.subMenu.userData.panel.hidden = true
                                subRowInfo.submenuHovered = false
                                closeSubmenus(subRowInfo.subMenu)
                            end
                        end
                    end
                    closeSubmenus(rowInfo.subMenu)
                end
            end
        end
    end

    -- Process menu items
    local rowIndex = 1
    for _, itemConfig in ipairs(menuConfig.menuItems or {}) do
        -- Create the row view
        local rowView = ColorView.new(baseItemView)
        rowView.size = vec2(userTable.width - 10, rowHeight)
        rowView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

        -- Set alternating background color
        local colorIndex = userTable.backgroundColorCounter % 2 + 1
        rowView.color = userTable.backgroundColors[colorIndex]
        userTable.backgroundColorCounter = userTable.backgroundColorCounter + 1

        -- Position the row
        local yOffsetFromTop = (rowIndex - 1) * rowHeight
        rowView.baseOffset = vec3(0, -yOffsetFromTop, 0)

        -- Create the row components
        local rowInfo = {
            rowView = rowView,
            yOffsetFromTop = yOffsetFromTop,
            hasSubMenu = (itemConfig.menu ~= nil),
            isHovering = false,
            submenuHovered = false -- Track if submenu is currently hovered
        }

        -- Left icon (optional)
        if itemConfig.menuItemLeftIcon then
            local leftIcon = ModelView.new(rowView)
            local success, modelIndex = pcall(model.modelIndexForName, model, itemConfig.menuItemLeftIcon)
            if success and modelIndex then
                leftIcon:setModel(modelIndex)
                leftIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                leftIcon.baseOffset = vec3(iconOffsetX, 0, 1)
                leftIcon.scale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
                leftIcon.size = vec2(iconHalfSize * 2, iconHalfSize * 2)
                leftIcon.masksEvents = false
                rowInfo.leftIcon = leftIcon
            else
                mj:log("createMenuPanel - Error: Failed to load model for menuItemLeftIcon:", itemConfig.menuItemLeftIcon)
            end
        end

        -- Text
        local textView = TextView.new(rowView)
        textView.font = Font(uiCommon.fontName, fontSize)
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        textView.baseOffset = vec3(itemConfig.menuItemLeftIcon and textOffsetXWithIcon or textOffsetX, 0, 1)
        textView.text = itemConfig.menuItemText or ("Item " .. rowIndex)
        textView.color = mj.textColor
        rowInfo.textView = textView

        -- Right button (optional)
        if itemConfig.menuItemRightButton then
            local rightButtonSize = vec2(30, 30) -- Adjusted to match rowHeight
            local rightButton = uiStandardButton:create(rowView, rightButtonSize, uiStandardButton.types.slim_1x1)
            rightButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            rightButton.baseOffset = vec3(itemConfig.menu and -15 or -5, 0, 1) -- Adjusted for better alignment
            -- Add a colored background to visualize the hitbox (temporary for debugging)
            local buttonBackground = ColorView.new(rightButton)
            buttonBackground.color = vec4(1.0, 0.0, 0.0, 0.5) -- Red with 50% opacity
            buttonBackground.size = rightButtonSize
            buttonBackground.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
            buttonBackground.baseOffset = vec3(0, 0, -1) -- Behind the icon
            uiStandardButton:setIconModel(rightButton, itemConfig.menuItemRightButton.menuItemRightIcon, {
                default = material.types.ui_standard.index
            }, rightButtonIconHalfSize)
            uiStandardButton:setText(rightButton, nil)
            -- Use uiStandardButton's built-in click handling
            rightButton.masksEvents = true
            uiStandardButton:setClickFunction(rightButton, itemConfig.menuItemRightButton.menuItemRightFunction)
            mj:log("createMenuPanel - Set click function for right button on menu item:", itemConfig.menuItemText)
            rowInfo.rightButton = rightButton
        end

        -- Submenu indicator (if applicable)
        if itemConfig.menu then
            local indicator = ModelView.new(rowView)
            indicator:setModel(model:modelIndexForName("icon_play"))
            indicator.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            indicator.baseOffset = vec3(-iconOffsetX, 0, 1)
            indicator.scale3D = vec3(indicatorScale, indicatorScale, indicatorScale)
            indicator.size = vec2(indicatorSize, indicatorSize)
            indicator.masksEvents = false
            rowInfo.subMenuIcon = indicator
        end

        -- Create submenu if specified
        if itemConfig.menu then
            rowInfo.subMenu = createMenuPanel(itemConfig.menu, parentView, rowView, menuLevel + 1, gameUI)
            rowInfo.subMenu.userData.parentHoverState = userTable.hoverState
        end

        -- Setup hover for the row
        rowView.masksEvents = true
        rowView.click = function(buttonIndex)
            mj:log("rowView.click - Item:", itemConfig.menuItemText, "Level:", menuLevel, "buttonIndex:", buttonIndex)
        end
        rowView.hoverStart = function()
            mj:log("rowView.hoverStart - Item:", itemConfig.menuItemText, "Level:", menuLevel, "isHovering:", rowInfo.isHovering)
            rowInfo.isHovering = true
            if rowInfo.hasSubMenu then
                -- Close other submenus at the same level
                for j, otherRow in ipairs(userTable.rowInfos) do
                    if j ~= rowIndex and otherRow.hasSubMenu and not otherRow.subMenu.userData.panel.hidden then
                        mj:log("rowView.hoverStart - Closing other submenu for item:", userTable.rowInfos[j].textView.text)
                        otherRow.isHovering = false
                        otherRow.submenuHovered = false
                        otherRow.subMenu.userData.panel.hidden = true
                        -- Recursively close all descendants
                        local function closeSubmenus(menuPanel)
                            for _, subRowInfo in ipairs(menuPanel.userData.rowInfos) do
                                if subRowInfo.hasSubMenu then
                                    subRowInfo.subMenu.userData.panel.hidden = true
                                    subRowInfo.submenuHovered = false
                                    closeSubmenus(subRowInfo.subMenu)
                                end
                            end
                        end
                        closeSubmenus(otherRow.subMenu)
                    end
                end
                mj:log("rowView.hoverStart - Opening submenu for item:", itemConfig.menuItemText)
                rowInfo.subMenu.userData.panel.hidden = false
            end
            userTable.hoverState.isHovering = true
            if userTable.parentHoverState then
                userTable.parentHoverState.isHovering = true
            end
        end
        rowView.hoverEnd = function()
            mj:log("rowView.hoverEnd - Item:", itemConfig.menuItemText, "Level:", menuLevel, "isHovering:", rowInfo.isHovering)
            rowInfo.isHovering = false
            if rowInfo.hasSubMenu then
                -- Check if the submenu or any of its descendants are hovered
                local function isSubmenuHovered(menuPanel)
                    if menuPanel.userData.hoverState.isHovering then
                        return true
                    end
                    for _, subRowInfo in ipairs(menuPanel.userData.rowInfos) do
                        if subRowInfo.isHovering then
                            return true
                        end
                        if subRowInfo.hasSubMenu and isSubmenuHovered(subRowInfo.subMenu) then
                            return true
                        end
                    end
                    return false
                end
                rowInfo.submenuHovered = isSubmenuHovered(rowInfo.subMenu)
                if not rowInfo.submenuHovered then
                    mj:log("rowView.hoverEnd - Closing submenu for item:", itemConfig.menuItemText, "submenuHovered:", rowInfo.submenuHovered)
                    rowInfo.subMenu.userData.panel.hidden = true
                    -- Recursively close all descendants
                    local function closeSubmenus(menuPanel)
                        for _, subRowInfo in ipairs(menuPanel.userData.rowInfos) do
                            if subRowInfo.hasSubMenu then
                                subRowInfo.subMenu.userData.panel.hidden = true
                                subRowInfo.submenuHovered = false
                                closeSubmenus(subRowInfo.subMenu)
                            end
                        end
                    end
                    closeSubmenus(rowInfo.subMenu)
                else
                    mj:log("rowView.hoverEnd - Keeping submenu open for item:", itemConfig.menuItemText, "submenuHovered:", rowInfo.submenuHovered)
                end
            end
        end

        table.insert(userTable.rowInfos, rowIndex, rowInfo)
        rowIndex = rowIndex + 1
    end

    -- Update the panel size
    local numRows = #userTable.rowInfos
    local height = math.max(numRows * rowHeight + padding, userTable.minHeight)
    userTable.panel.size = vec2(userTable.panelWidth, height)
    userTable.panel.scale3D = calculateScale3D(userTable.panelWidth, height, modelHeight)
    userTable.baseItemView.size = vec2(userTable.width, height - padding)

    return { userData = userTable }
end

-- Initialize the uiMenuView
function uiMenuView:init(menuConfig, menuParent, menuOffset)
    if not menuParent then
        mj:log("uiMenuView:init - Error: menuParent is nil, cannot create menu button")
        return nil
    end
    if not menuConfig.gameUI then
        mj:log("uiMenuView:init - Error: menuConfig.gameUI is nil, screen size adjustments will not work")
    end

    local menuObject = {}
    local userTable = {
        menuConfig = menuConfig,
        hoverState = { isHovering = false, hasActiveSubmenu = false },
        gameUI = menuConfig.gameUI,
        menuButtonPosX = nil -- To store the menu button's position
    }
    menuObject.userData = userTable

    -- Create the menu button (slim_1x1, 80x40 pixels)
    local buttonSize = vec2(80.0, 40.0)
    local buttonType = uiStandardButton.types.slim_1x1
    local backgroundMaterialRemapTable = {}
    if menuConfig.menuButtonIcon and menuConfig.menuButtonIcon.backgroundColor then
        backgroundMaterialRemapTable[material.types.ui_standard.index] = menuConfig.menuButtonIcon.backgroundColor
    end
    local menuButton = uiStandardButton:create(menuParent, buttonSize, buttonType, backgroundMaterialRemapTable)
    menuButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    menuButton.baseOffset = menuOffset or vec3(0, 0, 0)

    -- Set the button icon (left-justified)
    if menuConfig.menuButtonIcon and menuConfig.menuButtonIcon.model then
        local icon = ModelView.new(menuButton)
        local success, modelIndex = pcall(model.modelIndexForName, model, menuConfig.menuButtonIcon.model)
        if success and modelIndex then
            icon:setModel(modelIndex)
            if menuConfig.menuButtonIcon.color then
                icon:setModel(modelIndex, { default = menuConfig.menuButtonIcon.color })
            end
            icon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            icon.baseOffset = vec3(iconOffsetX, 0, 1)
            icon.scale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
            icon.size = vec2(iconHalfSize * 2, iconHalfSize * 2)
            icon.masksEvents = false
        else
            mj:log("uiMenuView:init - Error: Failed to load model for menuButtonIcon:", menuConfig.menuButtonIcon.model)
        end
    end

    -- Set the button text (updated by menuButtonFunction)
    local buttonText = TextView.new(menuButton)
    buttonText.font = Font(uiCommon.fontName, fontSize)
    buttonText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    buttonText.baseOffset = vec3(0, 0, 1)
    buttonText.text = menuConfig.menuButtonName or "Menu"
    buttonText.color = mj.textColor
    userTable.buttonText = buttonText

    -- Store button in userData
    userTable.menuButton = menuButton

    -- Store menuObject in userTable for access in zoomFunction
    userTable.menuObject = menuObject

    -- Create the menu tree
    userTable.menuTree = createMenuPanel(menuConfig.menu, menuParent, menuButton, 0, menuConfig.gameUI)

    -- Setup hover for the button
    menuButton.masksEvents = true
    menuButton.hoverStart = function()
        mj:log("menuButton.hoverStart - isHovering:", userTable.hoverState.isHovering)
        userTable.hoverState.isHovering = true
        userTable.menuTree.userData.panel.hidden = false
    end
    menuButton.hoverEnd = function()
        mj:log("menuButton.hoverEnd - isHovering:", userTable.hoverState.isHovering)
        userTable.hoverState.isHovering = false
    end

    -- Add clickDownOutside handler to close the menu tree
    menuButton.clickDownOutside = function(buttonIndex)
        mj:log("menuButton.clickDownOutside - Closing menu tree, buttonIndex:", buttonIndex)
        userTable.hoverState.isHovering = false
        userTable.menuTree.userData.panel.hidden = true
        -- Close all submenus recursively
        local function closeSubmenus(menuPanel)
            for _, rowInfo in ipairs(menuPanel.userData.rowInfos) do
                if rowInfo.hasSubMenu then
                    rowInfo.isHovering = false
                    rowInfo.submenuHovered = false
                    rowInfo.subMenu.userData.panel.hidden = true
                    closeSubmenus(rowInfo.subMenu)
                end
            end
        end
        closeSubmenus(userTable.menuTree)
    end

    -- Update function for dynamic adjustments
    menuObject.update = function(dt)
        -- Update button text if menuButtonFunction is provided
        if menuConfig.menuButtonFunction then
            local result = menuConfig.menuButtonFunction()
            if result and result.text then
                userTable.buttonText.text = result.text
            end
        end

        -- Update menu items with dynamic functions
        local function updateMenuItems(menuPanel)
            for _, rowInfo in ipairs(menuPanel.userData.rowInfos) do
                if rowInfo.menuItemFunction then
                    local result = rowInfo.menuItemFunction(rowInfo)
                    if result then
                        if result.text then
                            rowInfo.textView.text = result.text
                        end
                        if rowInfo.rightButton and result.rightButtonEnabled ~= nil then
                            rowInfo.rightButton.hidden = not result.rightButtonEnabled
                        end
                    end
                end
                if rowInfo.hasSubMenu then
                    updateMenuItems(rowInfo.subMenu)
                end
            end
        end
        updateMenuItems(userTable.menuTree)

        -- Check if any submenu is active (based on hover state)
        local function checkSubmenuActive(menuPanel)
            for _, rowInfo in ipairs(menuPanel.userData.rowInfos) do
                if rowInfo.hasSubMenu and (rowInfo.isHovering or rowInfo.submenuHovered) then
                    mj:log("checkSubmenuActive - Submenu active for item:", rowInfo.textView.text, "isHovering:", rowInfo.isHovering, "submenuHovered:", rowInfo.submenuHovered)
                    return true
                end
                if rowInfo.hasSubMenu and checkSubmenuActive(rowInfo.subMenu) then
                    return true
                end
            end
            return false
        end
        userTable.hoverState.hasActiveSubmenu = checkSubmenuActive(userTable.menuTree)
        mj:log("update - hasActiveSubmenu:", userTable.hoverState.hasActiveSubmenu)

        -- Close the menu if not hovering and no submenu is active
        if not userTable.hoverState.isHovering and not userTable.hoverState.hasActiveSubmenu then
            mj:log("update - Closing top-level menu: isHovering:", userTable.hoverState.isHovering, "hasActiveSubmenu:", userTable.hoverState.hasActiveSubmenu)
            userTable.menuTree.userData.panel.hidden = true
            -- Recursively close all submenus
            local function closeSubmenus(menuPanel)
                for _, rowInfo in ipairs(menuPanel.userData.rowInfos) do
                    if rowInfo.hasSubMenu then
                        rowInfo.subMenu.userData.panel.hidden = true
                        rowInfo.submenuHovered = false
                        closeSubmenus(rowInfo.subMenu)
                    end
                end
            end
            closeSubmenus(userTable.menuTree)
        end

        -- Adjust menu positions to stay on-screen
        local function adjustMenuPositions(menuPanel, baseX, baseY)
            if not menuPanel.userData.positionAdjusted then
                local newOpenDirection = determineOpenDirection(menuPanel.userData.gameUI, menuPanel.userData.panelWidth, menuPanel.userData.menuLevel, baseX, menuPanel.userData.panel.size.y, baseY)
                menuPanel.userData.openDirection = newOpenDirection
                menuPanel.userData.positionAdjusted = true -- Set immediately to avoid redundant updates

                local newHorizontalAlignment = menuPanel.userData.horizontalAlignment
                if newOpenDirection.horizontal == "left" then
                    if menuPanel.userData.menuLevel == 0 then
                        if newHorizontalAlignment == MJPositionInnerLeft then
                            newHorizontalAlignment = MJPositionInnerRight
                        end
                    else
                        if newHorizontalAlignment == MJPositionOuterRight then
                            newHorizontalAlignment = MJPositionOuterLeft
                        end
                    end
                end

                local newVerticalAlignment = menuPanel.userData.verticalAlignment
                if newOpenDirection.vertical == "above" then
                    if newVerticalAlignment == MJPositionTop then
                        newVerticalAlignment = MJPositionBottom
                    end
                end

                menuPanel.userData.panel.relativePosition = ViewPosition(newHorizontalAlignment, newVerticalAlignment)

                -- Update text alignment for all rows
                for _, rowInfo in ipairs(menuPanel.userData.rowInfos) do
                    local textAlignment = (newOpenDirection.horizontal == "right") and MJPositionInnerLeft or MJPositionInnerRight
                    local textOffset = (newOpenDirection.horizontal == "right") and vec3(rowInfo.leftIcon and textOffsetXWithIcon or textOffsetX, 0, 1) or vec3(-(rowInfo.leftIcon and textOffsetXWithIcon or textOffsetX), 0, 1)
                    rowInfo.textView.relativePosition = ViewPosition(textAlignment, MJPositionCenter)
                    rowInfo.textView.baseOffset = textOffset

                    if rowInfo.rightButton then
                        local rightOffset = (newOpenDirection.horizontal == "right") and vec3(rowInfo.hasSubMenu and -15 or -5, 0, 1) or vec3(rowInfo.hasSubMenu and 15 or 5, 0, 1)
                        rowInfo.rightButton.baseOffset = rightOffset
                    end

                    if rowInfo.subMenuIcon then
                        local subMenuOffset = (newOpenDirection.horizontal == "right") and vec3(-iconOffsetX, 0, 1) or vec3(iconOffsetX, 0, 1)
                        rowInfo.subMenuIcon.baseOffset = subMenuOffset
                    end
                end
            end

            -- Recursively adjust submenus
            local panelPos = menuPanel.userData.panel.baseOffset
            local newBaseX = baseX + (menuPanel.userData.openDirection.horizontal == "right" and menuPanel.userData.panelWidth or -menuPanel.userData.panelWidth)
            local newBaseY = baseY - menuPanel.userData.panel.size.y / 2
            for _, rowInfo in ipairs(menuPanel.userData.rowInfos) do
                if rowInfo.hasSubMenu then
                    adjustMenuPositions(rowInfo.subMenu, newBaseX, newBaseY - rowInfo.yOffsetFromTop)
                end
            end
        end

        if userTable.gameUI and userTable.gameUI.view then
            local screenSize = userTable.gameUI.view.size
            -- Use the menu button's position as the starting point
            if not userTable.menuButtonPosX then
                userTable.menuButtonPosX = menuButton.baseOffset.x -- Approximate starting position
                mj:log("update - menuButtonPosX:", userTable.menuButtonPosX)
            end
            local defaultPosX = userTable.menuButtonPosX
            local defaultPosY = screenSize.y / 2
            adjustMenuPositions(userTable.menuTree, defaultPosX, defaultPosY)
        end
    end

    -- Public methods
    menuObject.open = function()
        userTable.hoverState.isHovering = true
        userTable.menuTree.userData.panel.hidden = false
    end

    menuObject.close = function()
        userTable.hoverState.isHovering = false
        userTable.menuTree.userData.panel.hidden = true
        local function closeSubmenus(menuPanel)
            for _, rowInfo in ipairs(menuPanel.userData.rowInfos) do
                if rowInfo.hasSubMenu then
                    rowInfo.isHovering = false
                    rowInfo.submenuHovered = false
                    rowInfo.subMenu.userData.panel.hidden = true
                    closeSubmenus(rowInfo.subMenu)
                end
            end
        end
        closeSubmenus(userTable.menuTree)
    end

    menuObject.toggle = function()
        if userTable.menuTree.userData.panel.hidden then
            menuObject:open()
        else
            menuObject:close()
        end
    end

    return menuObject
end

return uiMenuView
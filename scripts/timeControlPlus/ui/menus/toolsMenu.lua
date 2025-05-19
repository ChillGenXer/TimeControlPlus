local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4
local toolsMenu = {}
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local material = mjrequire "common/material"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local model = mjrequire "common/model"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local utilities = mjrequire "timeControlPlus/common/utilities"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local resource = mjrequire "common/resource"
local gameObject = mjrequire "common/gameObject"
local medicine = mjrequire "common/medicine"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local logicInterface = mjrequire "mainThread/logicInterface"
local locale = mjrequire "common/locale"

local toolsPanel = nil
local localWorld = nil
local localGameUI = nil

-- Helper function to populate the storage list view for a specific food item
local function populateStorageListView(storageListView, storageAreas, playerPos, storageListViewSize, menuPanel)
    local backgroundColorCounter = 1
    local backgroundColors = {vec4(0.03, 0.03, 0.03, 0.5), vec4(0.0, 0.0, 0.0, 0.5)}
    local listViewItemHeight = 30.0
    local storageIconSize = vec2(30.0, 30.0)

    -- Ensure storageAreas is valid and has entries
    if not storageAreas or type(storageAreas) ~= "table" then
        return
    end

    -- Clear any existing rows to prevent residual content
    uiScrollView:removeAllRows(storageListView)

    for storageID, storageInfo in pairs(storageAreas) do
        -- Skip invalid entries using structured control flow
        if storageInfo and storageInfo.pos and storageInfo.count then
            local rowBackgroundView = ColorView.new(storageListView)
            local defaultColor = backgroundColors[backgroundColorCounter % 2 + 1]
            rowBackgroundView.color = defaultColor
            rowBackgroundView.size = vec2(storageListViewSize.x - 22, listViewItemHeight)
            rowBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
            uiScrollView:insertRow(storageListView, rowBackgroundView, nil)
            backgroundColorCounter = backgroundColorCounter + 1

            -- Add storage icon
            local storageIcon = ModelView.new(rowBackgroundView)
            storageIcon:setModel(model:modelIndexForName("icon_store"))
            storageIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            storageIcon.baseOffset = vec3(8, 0, 1)
            storageIcon.scale3D = vec3(12, 12, 12)
            storageIcon.size = storageIconSize
            storageIcon.masksEvents = false

            -- Add storage name (initially set to placeholder, updated via callback)
            local storageNameTextView = TextView.new(rowBackgroundView)
            storageNameTextView.font = Font(uiCommon.fontName, 14)
            storageNameTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            storageNameTextView.relativeView = storageIcon
            storageNameTextView.baseOffset = vec3(10, 0, 1)
            storageNameTextView.text = "Storage Area" -- Placeholder
            storageNameTextView.color = mj.textColor

            -- Retrieve the actual storage area name using logicInterface
            logicInterface:callLogicThreadFunction("retrieveObject", storageID, function(result)
                if result and result.found then
                    if result.sharedState and result.sharedState.name then
                        storageNameTextView.text = result.sharedState.name
                    else
                        -- Use the default name from gameObject.types
                        local objectType = gameObject.types[result.objectTypeIndex]
                        storageNameTextView.text = objectType and objectType.name or "Storage Area"
                    end
                else
                    storageNameTextView.text = "Storage Area"
                end
            end)

            -- Add count and distance
            local countDistanceTextView = TextView.new(rowBackgroundView)
            countDistanceTextView.font = Font(uiCommon.fontName, 14)
            countDistanceTextView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            countDistanceTextView.baseOffset = vec3(-10, 0, 1)
            local distance = utilities:getDistance(playerPos, storageInfo.pos)
            countDistanceTextView.text = string.format("%d (%dm)", storageInfo.count, distance)
            countDistanceTextView.color = mj.textColor

            -- Add teleport button
            local teleportButtonSize = 22
            local teleportButton = uiStandardButton:create(rowBackgroundView, vec2(teleportButtonSize, teleportButtonSize), uiStandardButton.types.slim_1x1)
            teleportButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            teleportButton.baseOffset = vec3(10, 0, 2)
            teleportButton.relativeView = countDistanceTextView
            uiStandardButton:setIconModel(teleportButton, "icon_inspect")
            uiStandardButton:setClickFunction(teleportButton, function()
                -- Retrieve the object and follow it, falling back to teleport if not found
                logicInterface:callLogicThreadFunction("retrieveObject", storageID, function(result)
                    if result and result.found then
                        localGameUI:followObject(result, false, {dismissAnyUI = true, showInspectUI = true})
                    else
                        localGameUI:teleportToLookAtPos(storageInfo.pos)
                    end
                    -- Hide the menu panel after teleporting/following
                    if menuPanel then
                        menuPanel.hidden = true
                    end
                end)
            end)
            uiToolTip:add(teleportButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_zoom"), nil, vec3(0, -8, 10), nil, teleportButton)
        end
    end
end

-- Function to fetch and filter resources based on a category
local function getResourceListItems(world, filterKey, callback)
    world:getResourceObjectCountsFromServer(function(resourceData)
        local listItems = {}

        for i, resourceType in ipairs(resource.alphabeticallyOrderedTypes) do
            local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
            local storedCount = 0
            for j, gameObjectTypeIndex in ipairs(gameObjectTypes) do
                local thisCount = resourceData[gameObjectTypeIndex] and resourceData[gameObjectTypeIndex].count or 0
                storedCount = storedCount + thisCount
            end
            local matchesFilter = false
            if filterKey == "medicineList" then
                matchesFilter = medicine.medicinesByResourceType[resourceType.index] ~= nil
            else
                matchesFilter = resourceType[filterKey]
            end
            if matchesFilter then
                table.insert(listItems, {
                    resourceType = resourceType,
                    storedCount = storedCount,
                    resourceData = resourceData,
                    gameObjectTypeIndex = gameObjectTypes[1]
                })
            end
        end

        callback(listItems)
    end)
end

-- Helper function to populate the resource list view in the menus with items
local function populateListView(listView, listItems, listViewSize)
    local backgroundColorCounter = 1
    local backgroundColors = {vec4(0.03, 0.03, 0.03, 0.5), vec4(0.0, 0.0, 0.0, 0.5)}
    local listViewItemHeight = 30.0
    local listViewItemObjectImageViewSize = vec2(30.0, 30.0)

    for i, item in ipairs(listItems) do
        -- Create row background with alternating colors
        local rowBackgroundView = ColorView.new(listView)
        local defaultColor = backgroundColors[backgroundColorCounter % 2 + 1]
        rowBackgroundView.color = defaultColor
        rowBackgroundView.size = vec2(listViewSize.x - 22, listViewItemHeight)
        rowBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        uiScrollView:insertRow(listView, rowBackgroundView, nil)
        backgroundColorCounter = backgroundColorCounter + 1

        -- Add item icon
        local gameObjectView = uiGameObjectView:create(rowBackgroundView, listViewItemObjectImageViewSize, uiGameObjectView.types.standard)
        gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        uiGameObjectView:setObject(gameObjectView, {
            objectTypeIndex = item.resourceType.displayGameObjectTypeIndex
        }, nil, nil)
        gameObjectView.masksEvents = false

        -- Add item name and count
        local objectTitleTextView = TextView.new(rowBackgroundView)
        objectTitleTextView.font = Font(uiCommon.fontName, 16)
        objectTitleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        objectTitleTextView.relativeView = gameObjectView
        local textString = string.format("%s (%d)", item.resourceType.plural, item.storedCount)
        objectTitleTextView.text = textString
        objectTitleTextView.color = mj.textColor

        -- Only show submenu and indicator if item count is greater than 0
        if item.storedCount > 0 then
            -- Add submenu indicator (ui_clockMark)
            local submenuIndicator = ModelView.new(rowBackgroundView)
            submenuIndicator:setModel(model:modelIndexForName("ui_clockMark"), {default = material.types.ui_bronze.index})
            submenuIndicator.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            submenuIndicator.baseOffset = vec3(-10, 0, 2)
            submenuIndicator.scale3D = vec3(10, 10, 10)
            submenuIndicator.size = vec2(20, 20)
            submenuIndicator.masksEvents = false
            submenuIndicator.hidden = false

            -- Create a hover panel for storage areas (submenu)
            local storageAreas = item.resourceData[item.gameObjectTypeIndex] and item.resourceData[item.gameObjectTypeIndex].storageAreas or {}
            local storageCount = 0
            for _, storageInfo in pairs(storageAreas) do
                if storageInfo and storageInfo.pos and storageInfo.count then
                    storageCount = storageCount + 1
                end
            end
            local storagePanelHeight = math.max(storageCount * 30.0, 32.0) -- Add slight padding to avoid rendering quirk
            local storagePanelSize = vec2(300, storagePanelHeight)
            local storageListViewSize = vec2(storagePanelSize.x - 10, storagePanelHeight)
            local storagePanel = ModelView.new(listView)
            storagePanel:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
            storagePanel.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
            storagePanel.relativeView = rowBackgroundView -- Align with the specific row
            storagePanel.baseOffset = vec3(0, 0, 2)
            local storagePanelScaleX = storagePanelSize.x * 0.5 / (2.0/3.0)
            local storagePanelScaleY = storagePanelSize.y * 0.5
            storagePanel.scale3D = vec3(storagePanelScaleX, storagePanelScaleY, storagePanelScaleX)
            storagePanel.size = storagePanelSize
            storagePanel.alpha = 0.9
            storagePanel.hidden = true

            -- Create a scroll view for storage areas
            local storageListView = uiScrollView:create(storagePanel, storageListViewSize, MJPositionInnerLeft)
            storageListView.baseOffset = vec3(0, 0, 2)

            -- Populate the storage list with data from resourceData
            local playerPos = localWorld:getRealPlayerHeadPos()
            populateStorageListView(storageListView, storageAreas, playerPos, storageListViewSize, listView.parent)

            -- Track hover state for cascading menu
            local isHoveringRow = false
            local isHoveringSubmenu = false
            local closeTimer = 0.0
            local closeDelay = 0.3 -- Delay in seconds before closing the submenu

            -- Add hover event handlers to the row background (main menu item)
            rowBackgroundView.masksEvents = true
            rowBackgroundView.hoverStart = function()
                isHoveringRow = true
                closeTimer = 0.0
                storagePanel.hidden = false
            end
            rowBackgroundView.hoverEnd = function()
                isHoveringRow = false
                closeTimer = 0.0 -- Start the timer to close the submenu
            end

            -- Add hover event handlers to the storage panel (submenu)
            storagePanel.masksEvents = true
            storagePanel.hoverStart = function()
                isHoveringSubmenu = true
                closeTimer = 0.0
                storagePanel.hidden = false
            end
            storagePanel.hoverEnd = function()
                isHoveringSubmenu = false
                closeTimer = 0.0 -- Start the timer to close the submenu
            end

            -- Update function to handle delayed closing
            rowBackgroundView.update = function(dt)
                if not isHoveringRow and not isHoveringSubmenu then
                    closeTimer = closeTimer + dt
                    if closeTimer >= closeDelay then
                        storagePanel.hidden = true
                        closeTimer = 0.0
                    end
                else
                    closeTimer = 0.0
                end
            end
        else
            -- If item count is 0, ensure no submenu or indicator is created
            rowBackgroundView.masksEvents = false
        end
    end
end

function toolsMenu:initializeToolsMenu(parentView, relativeView, panels)
    -- Tools Menu
    local toolsButtonWidth = 80.0    -- Width for the new Tools button (same as Food)
    local toolsButtonSize = vec2(toolsButtonWidth, 40.0)
    local toolsButtonBaseOffset = vec3(10, 0, 0)
    local toolsIconModel = "icon_toolAssembly"
    local toolsIconBaseOffset = vec3(10, 0, 0)
    local iconHalfSize = 9
    local toolsIconScale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
    local toolsIconSize = vec2(9, 9) * 2.0
    local toolsInfoViewBaseOffset = vec3(6, -2, 0)
    local toolsInfoViewText = "0" -- Placeholder, can be updated later
    local toolsInfoViewColor = vec4(0.6, 1.0, 0.6, 1.0) -- Green color, matching Food
    local toolsInfoToolTip = "Tools"
    local toolsInfoToolTipOffset = vec3(0, -8, 4)

    local toolsButton = uiStandardButton:create(parentView, toolsButtonSize, uiStandardButton.types.favor_10x3, {
        default = material.types.ui_background.index
    })
    toolsButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    toolsButton.relativeView = relativeView -- Position to the right of the Food button
    toolsButton.baseOffset = toolsButtonBaseOffset

    -- Tools icon
    local toolsIcon = ModelView.new(toolsButton)
    toolsIcon:setModel(model:modelIndexForName(toolsIconModel))
    toolsIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    toolsIcon.baseOffset = toolsIconBaseOffset
    toolsIcon.scale3D = toolsIconScale3D
    toolsIcon.size = toolsIconSize
    toolsIcon.masksEvents = false
    -- Tools Menu Main Info
    local toolsInfoView = TextView.new(toolsButton)
    toolsInfoView.font = Font(uiCommon.fontName, 14)
    toolsInfoView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    toolsInfoView.relativeView = toolsIcon
    toolsInfoView.baseOffset = toolsInfoViewBaseOffset
    toolsInfoView.text = toolsInfoViewText
    toolsInfoView.color = toolsInfoViewColor
    toolsInfoView.masksEvents = false
    -- Tools Menu Infotip
    uiToolTip:add(toolsButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), toolsInfoToolTip, nil, toolsInfoToolTipOffset, nil, toolsButton)
    -- Define toolsListViewSize at a higher scope
    local toolsPanelSize = vec2(250, 680.0) -- Same as Food menu
    local toolsListViewSize = vec2(toolsPanelSize.x - 10, toolsPanelSize.y - 10)
    -- Handle Click Event
    uiStandardButton:setClickFunction(toolsButton, function()
        -- Close all other panels and restore their tooltips
        for _, panelInfo in pairs(panels) do
            if panelInfo.panel and panelInfo.panel ~= toolsPanel and not panelInfo.panel.hidden then
                panelInfo.panel.hidden = true
                uiToolTip:add(panelInfo.button.userData.backgroundView, panelInfo.tooltip.position, panelInfo.tooltip.text, panelInfo.tooltip.description, panelInfo.tooltip.offset, nil, panelInfo.button)
            end
        end

        if not toolsPanel then
            -- Create the tools panel on first click
            toolsPanel = ModelView.new(relativeView)
            toolsPanel:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
            toolsPanel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
            toolsPanel.relativeView = toolsButton
            toolsPanel.baseOffset = vec3(0, 0, 0)
            local toolsPanelScaleX = toolsPanelSize.x * 0.5 / (2.0/3.0)
            local toolsPanelScaleY = toolsPanelSize.y * 0.5
            toolsPanel.scale3D = vec3(toolsPanelScaleX, toolsPanelScaleY, toolsPanelScaleX)
            toolsPanel.size = toolsPanelSize
            toolsPanel.alpha = 0.9
            toolsPanel.hidden = false

            -- Create a scroll view inside the panel
            local toolsListView = uiScrollView:create(toolsPanel, toolsListViewSize, MJPositionInnerLeft)
            toolsListView.baseOffset = vec3(0, 0, 2)
            toolsButton.userData.toolsListView = toolsListView -- Store for later access

            -- Populate the list for the first time
            utilities:getResourceListItems("isTool", function(toolsListItems)
                uiScrollView:removeAllRows(toolsListView) -- Clear any existing rows
                populateListView(toolsListView, toolsListItems, toolsListViewSize)
            end)

            -- Store panel info
            panels.tools = {
                panel = toolsPanel,
                button = toolsButton,
                tooltip = {
                    position = ViewPosition(MJPositionCenter, MJPositionBelow),
                    text = toolsInfoToolTip,
                    description = nil,
                    offset = toolsInfoToolTipOffset
                }
            }
        else
            -- Toggle visibility and refresh if about to be shown
            local willBeShown = toolsPanel.hidden -- True if currently hidden
            toolsPanel.hidden = not toolsPanel.hidden
            if not toolsPanel.hidden and willBeShown then
                -- Refresh the list when the panel is about to be shown
                local toolsListView = toolsButton.userData.toolsListView
                getResourceListItems("isTool", function(toolsListItems)
                    uiScrollView:removeAllRows(toolsListView) -- Clear existing rows
                    populateListView(toolsListView, toolsListItems, toolsListViewSize)
                end)
            end
        end

        -- Manage tooltip visibility
        if not toolsPanel.hidden then
            uiToolTip:remove(toolsButton.userData.backgroundView)
        else
            uiToolTip:add(toolsButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), toolsInfoToolTip, nil, toolsInfoToolTipOffset, nil, toolsButton)
        end
    end)
end

return toolsMenu
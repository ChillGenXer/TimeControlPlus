-- imports
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local resource = mjrequire "common/resource"
local gameObject = mjrequire "common/gameObject"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local logicInterface = mjrequire "mainThread/logicInterface"
local foodConfig = mjrequire "timeControlPlus/ui/foodConfig"
local utilities = mjrequire "timeControlPlus/common/utilities"
local playerSapiens = mjrequire "mainThread/playerSapiens"
local need = mjrequire "common/need"
local localPlayer = mjrequire "mainThread/localPlayer"

-- Initialize module
local foodUI = {}

-- Game state objects
local localWorld = nil
local localGameUI = nil

-- Colors
local backgroundColors = {vec4(0.03, 0.03, 0.03, 1.0), vec4(0.0, 0.0, 0.0, 1.0)}

-- Constants for UI
local hoverCloseDelay = 0.1 -- Single hover delay for all submenus (in seconds)
local metricsRowHeight = 60.0 -- Height of the top-level metrics row
local categoryHeaderHeight = 30.0 -- Height of each category header
local foodButtonWidth = 80.0 -- Width for the Food button
local foodButtonHeight = 40.0 -- Height for the Food button
local foodPanelWidth = 300.0 -- Width for the food panel
local toolTipOffset = vec3(0, -10, 0)
local updateInterval = 5.0 -- Update interval for food button title (in seconds)

-- Helper function to calculate the total hunger demand of the tribe
local function calculateTribeHungerDemand()
    -- Get the list of Sapiens in the tribe
    local sapienList = playerSapiens:getDistanceOrderedSapienList(localPlayer:getNormalModePos())
    
    -- Sum up the hunger values and log each Sapien's hunger
    local totalHungerDemand = 0.0
    for _, sapienInfo in ipairs(sapienList) do
        local sapien = sapienInfo.sapien
        local sharedState = sapien.sharedState
        -- Access the food need value (ranges from 0.0 to 1.0)
        local hungerValue = sharedState.needs[need.types.food.index] or 0.0
        mj:log("Sapien:", sharedState.name, "Hunger value:", hungerValue)
        totalHungerDemand = totalHungerDemand + hungerValue
    end
    
    -- Log the total for debugging
    mj:log("calculateTribeHungerDemand: Total hunger demand:", totalHungerDemand)
    
    -- Return the total (rounded to the nearest integer for display)
    return math.floor(totalHungerDemand + 0.5)
end

-- Helper function to populate the storage list view for a specific item
local function populateStorageListView(storageListView, storageAreas, playerPos, storageListViewSize, menuPanel, storageHoverState, parentHoverState)
    local backgroundColorCounter = 1
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
            rowBackgroundView.masksEvents = false -- Don’t consume hover events
            rowBackgroundView.alpha = 1.0 -- Ensure full opacity
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
            storageIcon.alpha = 1.0 -- Ensure full opacity

            -- Add storage name (initially set to placeholder, updated via callback)
            local storageNameTextView = TextView.new(rowBackgroundView)
            storageNameTextView.font = Font(uiCommon.fontName, 14)
            storageNameTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            storageNameTextView.relativeView = storageIcon
            storageNameTextView.baseOffset = vec3(10, 0, 1)
            storageNameTextView.text = "Storage Area" -- Placeholder
            storageNameTextView.color = mj.textColor
            storageNameTextView.masksEvents = false

            -- Add count and distance
            local countDistanceTextView = TextView.new(rowBackgroundView)
            countDistanceTextView.font = Font(uiCommon.fontName, 14)
            countDistanceTextView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            countDistanceTextView.baseOffset = vec3(-10, 0, 1)
            local distance = utilities:getDistance(playerPos, storageInfo.pos) -- Using utilities:getDistance
            countDistanceTextView.text = string.format("%d (%dm)", storageInfo.count, distance)
            countDistanceTextView.color = mj.textColor
            countDistanceTextView.masksEvents = false

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
            uiToolTip:add(teleportButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), "Zoom", nil, toolTipOffset, nil, teleportButton)

            -- Ensure hover events propagate to the parent
            teleportButton.userData.backgroundView.masksEvents = false
            teleportButton.userData.backgroundView.hoverStart = function()
                storageHoverState.isHovering = true
                parentHoverState.isHovering = true
            end
            teleportButton.userData.backgroundView.hoverEnd = function()
                storageHoverState.isHovering = false
            end
        end
    end
end

-- Helper function to calculate total food value for an item
local function calculateItemFoodValue(item)
    if not item.resourceType.foodValue then
        return 0
    end
    local foodPortionCount = item.resourceType.foodPortionCount or 1
    local foodValue = item.resourceType.foodValue
    return foodPortionCount * foodValue * item.storedCount
end

-- Fetch food items (with foodValue) and non-food items (from foodConfig.foods)
function foodUI:fetchFoodItems(callback)
    localWorld:getResourceObjectCountsFromServer(function(resourceData)
        local foodListItems = {}
        local totalFoodValue = 0
        local foodConfigKeys = {}

        -- Build a lookup table of foodConfig keys
        for foodKey, _ in pairs(foodConfig.foods) do
            foodConfigKeys[foodKey] = true
        end

        -- Iterate through all resource types
        for i, resourceType in ipairs(resource.alphabeticallyOrderedTypes) do
            local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
            local storedCount = 0
            for j, gameObjectTypeIndex in ipairs(gameObjectTypes) do
                local thisCount = resourceData[gameObjectTypeIndex] and resourceData[gameObjectTypeIndex].count or 0
                storedCount = storedCount + thisCount
            end

            -- Include items that either have a foodValue or are in foodConfig.foods
            local hasFoodValue = resourceType.foodValue ~= nil
            local isInFoodConfig = foodConfigKeys[resourceType.key] ~= nil
            if hasFoodValue or isInFoodConfig then
                local storageAreas = gameObjectTypes[1] and resourceData[gameObjectTypes[1]] and resourceData[gameObjectTypes[1]].storageAreas or {}
                local item = {
                    resourceType = resourceType,
                    storedCount = storedCount,
                    storageAreas = storageAreas,
                    gameObjectTypeIndex = gameObjectTypes[1],
                }
                item.foodValue = calculateItemFoodValue(item)
                totalFoodValue = totalFoodValue + item.foodValue
                table.insert(foodListItems, item)
            end
        end

        callback(foodListItems, totalFoodValue)
    end)
end

-- Render a submenu for a specific category
local function populateCategorySubmenu(listView, category, items, listViewSize, parentHoverState)
    if not items or #items == 0 then
        return
    end

    -- Calculate totals for the category
    local totalFoodValue = 0
    for _, item in ipairs(items) do
        totalFoodValue = totalFoodValue + item.foodValue
    end

    -- Define hover state variables at the top to ensure they are in scope for all closures
    local isHoveringHeader = false
    local isHoveringItems = false
    local closeTimer = 0.0

    -- Category header
    local headerRow = ColorView.new(listView)
    headerRow.color = vec4(0.1, 0.1, 0.1, 1.0)
    headerRow.size = vec2(listViewSize.x - 22, categoryHeaderHeight)
    headerRow.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    headerRow.alpha = 1.0
    uiScrollView:insertRow(listView, headerRow, nil)

    -- Add category icon using uiGameObjectView with specific resource types
    local resourceType
    if category == "flatBread" then
        resourceType = resource.types["flatbread"]
    elseif category == "cookedFoods" then
        -- Use the first item in the category, since we know its icon renders correctly
        if #items > 0 then
            resourceType = items[1].resourceType
        end
    elseif category == "rawFoods" then
        resourceType = resource.types["alpacaMeat"]
    elseif category == "naturalFoods" then
        resourceType = resource.types["apple"]
    elseif category == "otherFoods" then
        if #items > 0 then
            resourceType = items[1].resourceType
        end
    end

    if resourceType and resourceType.displayGameObjectTypeIndex then
        local categoryIcon = uiGameObjectView:create(headerRow, vec2(30.0, 30.0), uiGameObjectView.types.standard)
        categoryIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        uiGameObjectView:setObject(categoryIcon, {
            objectTypeIndex = resourceType.displayGameObjectTypeIndex
        }, nil, nil)
        categoryIcon.masksEvents = false
        categoryIcon.alpha = 1.0
    end

    local categoryTitle = TextView.new(headerRow)
    categoryTitle.font = Font(uiCommon.fontName, 16)
    categoryTitle.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    if resourceType and resourceType.displayGameObjectTypeIndex then
        categoryTitle.baseOffset = vec3(30, 0, 1) -- Offset to the right of the icon
    else
        categoryTitle.baseOffset = vec3(10, 0, 1)
    end

    -- Use hardcoded category names
    local categoryDisplayName
    if category == "flatBread" then
        categoryDisplayName = "Flatbread"
    elseif category == "cookedFoods" then
        categoryDisplayName = "Cooked Food"
    elseif category == "rawFoods" then
        categoryDisplayName = "Raw Food"
    elseif category == "naturalFoods" then
        categoryDisplayName = "Natural Food"
    elseif category == "otherFoods" then
        categoryDisplayName = "Other Food"
    else
        categoryDisplayName = category
    end

    categoryTitle.text = categoryDisplayName .. ": " .. totalFoodValue .. " u"
    categoryTitle.color = mj.textColor

    -- Submenu indicator (for category)
    local submenuIndicator = ModelView.new(headerRow)
    submenuIndicator:setModel(model:modelIndexForName("icon_circle"), {default = material.types.ui_bronze.index})
    submenuIndicator.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    submenuIndicator.baseOffset = vec3(-10, 0, 2)
    submenuIndicator.scale3D = vec3(10, 10, 10)
    submenuIndicator.size = vec2(20, 20)
    submenuIndicator.masksEvents = false
    submenuIndicator.hidden = false
    submenuIndicator.alpha = 1.0

    -- Create a panel for the category items
    local itemCount = #items
    local panelHeight = math.max(itemCount * 30.0, 32.0) + 20.0 -- Increased padding to avoid scrollbar in itemListView
    local panelSize = vec2(300, panelHeight)
    local itemListViewSize = vec2(panelSize.x - 10, panelHeight)
    local categoryPanel = ModelView.new(listView)
    categoryPanel:setModel(model:modelIndexForName("ui_panel_10x2"))
    categoryPanel.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    categoryPanel.relativeView = headerRow
    categoryPanel.baseOffset = vec3(0, 0, 2)
    local panelScaleX = panelSize.x * 0.5 / (2.0/3.0)
    local panelScaleY = panelSize.y * 0.5
    categoryPanel.scale3D = vec3(panelScaleX, panelScaleY, panelScaleX)
    categoryPanel.size = panelSize
    categoryPanel.alpha = 1.0 -- Fully opaque
    categoryPanel.hidden = true

    -- Create a scroll view for the items
    local itemListView = uiScrollView:create(categoryPanel, itemListViewSize, MJPositionInnerLeft)
    itemListView.baseOffset = vec3(0, 0, 2)
    itemListView.alpha = 1.0 -- Ensure scroll view is fully opaque

    -- Track hover state for the category panel
    local categoryHoverState = { isHovering = false, hasActiveSubmenu = false }

    -- Keep track of all storage panels for this category to manage hasActiveSubmenu
    local storagePanels = {}

    -- Populate the items
    local backgroundColorCounter = 1
    for _, item in ipairs(items) do
        local rowBackgroundView = ColorView.new(itemListView)
        local defaultColor = backgroundColors[backgroundColorCounter % 2 + 1]
        rowBackgroundView.color = defaultColor
        rowBackgroundView.size = vec2(itemListViewSize.x - 22, 30.0)
        rowBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        rowBackgroundView.alpha = 1.0
        uiScrollView:insertRow(itemListView, rowBackgroundView, nil)
        backgroundColorCounter = backgroundColorCounter + 1

        -- Add item icon
        local gameObjectView = uiGameObjectView:create(rowBackgroundView, vec2(30.0, 30.0), uiGameObjectView.types.standard)
        gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        uiGameObjectView:setObject(gameObjectView, {
            objectTypeIndex = item.resourceType.displayGameObjectTypeIndex
        }, nil, nil)
        gameObjectView.masksEvents = false
        gameObjectView.alpha = 1.0

        -- Add item name, count, and food value
        local objectTitleTextView = TextView.new(rowBackgroundView)
        objectTitleTextView.font = Font(uiCommon.fontName, 16)
        objectTitleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        objectTitleTextView.relativeView = gameObjectView
        local textString = string.format("%s (%d, %.1f)", item.resourceType.plural, item.storedCount, item.foodValue)
        objectTitleTextView.text = textString
        objectTitleTextView.color = mj.textColor

        -- Storage submenu for items with storedCount > 0
        if item.storedCount > 0 then
            local storageIndicator = ModelView.new(rowBackgroundView)
            storageIndicator:setModel(model:modelIndexForName("icon_circle"), {default = material.types.ui_bronze.index})
            storageIndicator.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            storageIndicator.baseOffset = vec3(-5, 0, 3)
            storageIndicator.scale3D = vec3(8, 8, 8)
            storageIndicator.size = vec2(16, 16)
            storageIndicator.masksEvents = false
            storageIndicator.hidden = false
            storageIndicator.alpha = 1.0

            -- Log storageAreas data for debugging
            mj:log("Storage areas for item:", item.resourceType.key)
            for storageID, storageInfo in pairs(item.storageAreas) do
                mj:log("Storage ID:", storageID, "Pos:", storageInfo.pos, "Count:", storageInfo.count)
            end

            local storageCount = 0
            for _, storageInfo in pairs(item.storageAreas) do
                if storageInfo and storageInfo.pos and storageInfo.count then
                    storageCount = storageCount + 1
                end
            end
            local storagePanelHeight = math.max(storageCount * 30.0, 32.0) + 10.0
            local storagePanelSize = vec2(300, storagePanelHeight)
            local storageListViewSize = vec2(storagePanelSize.x - 10, storagePanelHeight)
            -- Make storagePanel a child of listView, not itemListView
            local storagePanel = ModelView.new(listView)
            storagePanel:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
            storagePanel.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
            storagePanel.relativeView = rowBackgroundView
            storagePanel.baseOffset = vec3(5, 0, 5)
            local storagePanelScaleX = storagePanelSize.x * 0.5 / (2.0/3.0)
            local storagePanelScaleY = storagePanelSize.y * 0.5
            storagePanel.scale3D = vec3(storagePanelScaleX, storagePanelScaleY, storagePanelScaleX)
            storagePanel.size = storagePanelSize
            storagePanel.alpha = 1.0 -- Fully opaque
            storagePanel.hidden = true

            local storageListView = uiScrollView:create(storagePanel, storageListViewSize, MJPositionInnerLeft)
            storageListView.baseOffset = vec3(0, 0, 2)
            storageListView.alpha = 1.0 -- Ensure scroll view is fully opaque

            -- Track hover state for the storage panel
            local storageHoverState = { isHovering = false }

            local playerPos = localWorld:getRealPlayerHeadPos()
            populateStorageListView(storageListView, item.storageAreas, playerPos, storageListViewSize, listView.parent, storageHoverState, categoryHoverState)

            -- Hover logic for storage submenu
            local isHoveringRow = false
            local closeTimer = 0.0

            rowBackgroundView.masksEvents = true
            rowBackgroundView.hoverStart = function()
                isHoveringRow = true
                closeTimer = 0.0
                storagePanel.hidden = false
                categoryHoverState.isHovering = true
                categoryHoverState.hasActiveSubmenu = true
                if parentHoverState then
                    parentHoverState.isHovering = true
                end
            end
            rowBackgroundView.hoverEnd = function()
                isHoveringRow = false
                closeTimer = 0.0
            end

            -- Remove hover events from storageListView to avoid conflicts
            -- storageListView.masksEvents = true
            -- storageListView.hoverStart = function()
            --     storageHoverState.isHovering = true
            --     closeTimer = 0.0
            --     storagePanel.hidden = false
            --     categoryHoverState.isHovering = true
            --     categoryHoverState.hasActiveSubmenu = true
            --     if parentHoverState then
            --         parentHoverState.isHovering = true
            --     end
            -- end
            -- storageListView.hoverEnd = function()
            --     storageHoverState.isHovering = false
            --     closeTimer = 0.0
            -- end

            storagePanel.masksEvents = true
            storagePanel.hoverStart = function()
                storageHoverState.isHovering = true
                closeTimer = 0.0
                storagePanel.hidden = false
                categoryHoverState.isHovering = true
                categoryHoverState.hasActiveSubmenu = true
                if parentHoverState then
                    parentHoverState.isHovering = true
                end
            end
            storagePanel.hoverEnd = function()
                storageHoverState.isHovering = false
                closeTimer = 0.0
            end

            -- Track this storagePanel to manage hasActiveSubmenu
            table.insert(storagePanels, storagePanel)

            rowBackgroundView.update = function(dt)
                if not isHoveringRow and not storageHoverState.isHovering then
                    closeTimer = closeTimer + dt
                    if closeTimer >= hoverCloseDelay then
                        storagePanel.hidden = true
                        closeTimer = 0.0
                        -- Only set hasActiveSubmenu to false if no storage panels are visible
                        local anyStoragePanelVisible = false
                        for _, panel in ipairs(storagePanels) do
                            if not panel.hidden then
                                anyStoragePanelVisible = true
                                break
                            end
                        end
                        if not anyStoragePanelVisible then
                            categoryHoverState.hasActiveSubmenu = false
                        end
                        if not isHoveringItems and not isHoveringHeader and not categoryHoverState.hasActiveSubmenu then
                            categoryHoverState.isHovering = false
                            if parentHoverState then
                                parentHoverState.isHovering = false
                            end
                        end
                    end
                else
                    closeTimer = 0.0
                end
            end
        else
            rowBackgroundView.masksEvents = false
        end
    end

    -- Hover logic for category submenu
    headerRow.masksEvents = true
    headerRow.hoverStart = function()
        isHoveringHeader = true
        closeTimer = 0.0
        categoryPanel.hidden = false
        categoryHoverState.isHovering = true
        if parentHoverState then
            parentHoverState.isHovering = true
        end
    end
    headerRow.hoverEnd = function()
        isHoveringHeader = false
        closeTimer = 0.0
    end

    categoryPanel.masksEvents = true
    categoryPanel.hoverStart = function()
        isHoveringItems = true
        closeTimer = 0.0
        categoryPanel.hidden = false
        categoryHoverState.isHovering = true
        if parentHoverState then
            parentHoverState.isHovering = true
        end
    end
    categoryPanel.hoverEnd = function()
        isHoveringItems = false
        closeTimer = 0.0
    end

    headerRow.update = function(dt)
        if not isHoveringHeader and not isHoveringItems and not categoryHoverState.hasActiveSubmenu then
            closeTimer = closeTimer + dt
            if closeTimer >= hoverCloseDelay then
                categoryPanel.hidden = true
                closeTimer = 0.0
                categoryHoverState.isHovering = false
                if parentHoverState then
                    parentHoverState.isHovering = false
                end
            end
        else
            closeTimer = 0.0
        end
    end
end

-- Populate the Food menu panel
local function populateFoodMenu(foodPanel, listView, updateFoodInfoTextCallback)
    -- Calculate the tribe's total hunger demand
    local tribeFoodDemand = calculateTribeHungerDemand()

    -- Track hover state for the main panel
    local mainHoverState = { isHovering = false }

    -- Fetch food items
    foodUI:fetchFoodItems(function(foodListItems, totalFoodValue)
        -- Update the button's food info text
        if updateFoodInfoTextCallback then
            updateFoodInfoTextCallback(totalFoodValue)
        end

        -- Clear existing rows
        uiScrollView:removeAllRows(listView)

        -- Group items by category
        local groupedItems = {}
        for _, category in ipairs(foodConfig.categoryOrder) do
            groupedItems[category] = {}
        end
        groupedItems.otherFoods = {}

        for _, item in ipairs(foodListItems) do
            local category = foodConfig:getCategory(item.resourceType.key)
            table.insert(groupedItems[category], item)
        end

        -- Calculate the total height of the list view based on content
        local totalCategories = 0
        for _, items in pairs(groupedItems) do
            if #items > 0 then
                totalCategories = totalCategories + 1
            end
        end
        local totalHeight = metricsRowHeight + (totalCategories * categoryHeaderHeight)
        listView.size = vec2(foodPanelWidth - 10, totalHeight)

        -- Adjust foodPanel size based on listView size
        foodPanel.size = vec2(foodPanelWidth, listView.size.y + 10) -- Add small padding
        local adjustedScaleX = foodPanel.size.x * 0.5 / (2.0/3.0)
        local adjustedScaleY = foodPanel.size.y * 0.5
        foodPanel.scale3D = vec3(adjustedScaleX, adjustedScaleY, adjustedScaleX)

        -- Top-level metrics
        local metricsRow = ColorView.new(listView)
        metricsRow.color = vec4(0.1, 0.1, 0.1, 1.0)
        metricsRow.size = vec2(foodPanelWidth - 22, metricsRowHeight)
        metricsRow.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        metricsRow.masksEvents = false
        metricsRow.alpha = 1.0
        uiScrollView:insertRow(listView, metricsRow, nil)

        local availableText = TextView.new(metricsRow)
        availableText.font = Font(uiCommon.fontName, 14)
        availableText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        availableText.baseOffset = vec3(10, -5, 1)
        availableText.text = "Available Food Units (u): " .. totalFoodValue
        availableText.color = mj.textColor
        availableText.masksEvents = false

        local demandText = TextView.new(metricsRow)
        demandText.font = Font(uiCommon.fontName, 14)
        demandText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
        demandText.baseOffset = vec3(10, 5, 1)
        demandText.text = "Current Food Demand: " .. tribeFoodDemand
        demandText.color = mj.textColor
        demandText.masksEvents = false

        -- Render categorized submenus
        for _, category in ipairs(foodConfig.categoryOrder) do
            if #groupedItems[category] > 0 then
                populateCategorySubmenu(listView, category, groupedItems[category], listView.size, mainHoverState)
            end
        end
        -- Render "Other Foods" if it has items
        if #groupedItems.otherFoods > 0 then
            populateCategorySubmenu(listView, "otherFoods", groupedItems.otherFoods, listView.size, mainHoverState)
        end
    end)

    return mainHoverState
end

-- Initialize the Food UI button and panel
function foodUI:initFoodButton(parentView, relativeView, panels)
    -- Food Button
    local foodButtonSize = vec2(foodButtonWidth, foodButtonHeight)
    local foodButtonBaseOffset = vec3(50, -3, 0)

    local foodButton = uiStandardButton:create(parentView, foodButtonSize, uiStandardButton.types.favor_10x3, {
        default = material.types.ui_background.index
    })
    foodButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    foodButton.relativeView = relativeView
    foodButton.baseOffset = foodButtonBaseOffset

    -- Food icon
    local foodIconModel = "icon_food"
    local foodIconBaseOffset = vec3(10, 0, 0)
    local iconHalfSize = 9
    local foodIconScale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
    local foodIconSize = vec2(9, 9) * 2.0
    local foodIcon = ModelView.new(foodButton)
    foodIcon:setModel(model:modelIndexForName(foodIconModel))
    foodIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    foodIcon.baseOffset = foodIconBaseOffset
    foodIcon.scale3D = foodIconScale3D
    foodIcon.size = foodIconSize
    foodIcon.masksEvents = false
    foodIcon.alpha = 1.0

    -- Food Info Text View
    local foodInfoTextView = TextView.new(foodButton)
    foodInfoTextView.font = Font(uiCommon.fontName, 14)
    foodInfoTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    foodInfoTextView.relativeView = foodIcon
    foodInfoTextView.baseOffset = vec3(5, 0, 0)
    foodInfoTextView.color = vec4(0.6, 1.0, 0.6, 1.0) -- Green color

    -- Food Panel
    local foodPanel = ModelView.new(parentView)
    foodPanel:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
    foodPanel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow) -- Align left edge with foodButton
    foodPanel.relativeView = foodButton
    foodPanel.baseOffset = vec3(0, 0, 0)
    foodPanel.size = vec2(foodPanelWidth, 200) -- Initial size, will be adjusted
    foodPanel.alpha = 1.0 -- Fully opaque
    foodPanel.hidden = true

    -- Food List View
    local listViewSize = vec2(foodPanelWidth - 10, 200)
    local listView = uiScrollView:create(foodPanel, listViewSize, MJPositionInnerLeft)
    listView.baseOffset = vec3(0, 0, 2)
    listView.alpha = 1.0 -- Ensure scroll view is fully opaque

    -- Function to update the food info text on the button
    local updateTimer = 0.0
    local function updateFoodInfoText(totalFoodValue)
        foodInfoTextView.text = tostring(totalFoodValue)
    end

    -- Populate Food Menu and get hover state, passing the update function
    local mainHoverState = populateFoodMenu(foodPanel, listView, updateFoodInfoText)

    -- Add update function to refresh the food info text every 5 seconds
    foodInfoTextView.update = function(dt)
        updateTimer = updateTimer + dt
        if updateTimer >= updateInterval then
            foodUI:fetchFoodItems(function(_, totalFoodValue)
                updateFoodInfoText(totalFoodValue)
            end)
            updateTimer = 0.0
        end
    end

    -- Set click function for Food button
    uiStandardButton:setClickFunction(foodButton, function()
        if foodPanel.hidden then
            for _, panelInfo in pairs(panels) do
                panelInfo.panel.hidden = true
            end
            foodPanel.hidden = false
            -- Refresh the menu and button text
            populateFoodMenu(foodPanel, listView, updateFoodInfoText)
        elseif not foodButton.userData.mainHoverState.isHovering then
            foodPanel.hidden = true
        end
    end)

    -- Store hover state and panel in foodButton userData
    foodButton.userData.mainHoverState = mainHoverState
    foodButton.userData.panel = foodPanel

    return foodButton, updateFoodInfoText
end

-- Initialize the module
function foodUI:init(gameUI, world)
    localWorld = world
    localGameUI = gameUI
end

return foodUI
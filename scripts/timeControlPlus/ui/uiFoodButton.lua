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
local resource = mjrequire "common/resource"
local gameObject = mjrequire "common/gameObject"
local logicInterface = mjrequire "mainThread/logicInterface"
local foodConfig = mjrequire "timeControlPlus/ui/foodConfig"
local utilities = mjrequire "timeControlPlus/common/utilities"
local playerSapiens = mjrequire "mainThread/playerSapiens"
local need = mjrequire "common/need"
local localPlayer = mjrequire "mainThread/localPlayer"
local uiMenuView = mjrequire "timeControlPlus/ui/uicommon/uiMenuView"

-- Initialize module
local foodUI = {}

-- Game state objects
local localWorld = nil
local localGameUI = nil

-- Constants for UI
local updateInterval = 5.0 -- Update interval for food button title (in seconds)
local foodButtonWidth = 80.0 -- Width for the Food button
local foodButtonHeight = 40.0 -- Height for the Food button
local foodPanelWidth = 300.0 -- Width for the food panel
local toolTipOffset = vec3(0, -10, 0)

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

-- Helper function to calculate total food value for an item
local function calculateItemFoodValue(item)
    if not item.resourceType.foodValue then
        mj:log("No foodValue for item: " .. tostring(item.resourceType.key) .. ", returning 0")
        return 0
    end
    local foodPortionCount = item.resourceType.foodPortionCount or 1
    local foodValue = item.resourceType.foodValue
    local storedCount = item.storedCount or 0
    local calculatedValue = foodPortionCount * foodValue * storedCount
    mj:log("Calculated food value for item: " .. tostring(item.resourceType.key) .. ", foodValue = " .. tostring(foodValue) .. ", foodPortionCount = " .. tostring(foodPortionCount) .. ", storedCount = " .. tostring(storedCount) .. ", total = " .. tostring(calculatedValue))
    return calculatedValue
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
                mj:log("Fetched item: " .. tostring(resourceType.key) .. ", storedCount = " .. tostring(storedCount) .. ", foodValue = " .. tostring(item.foodValue) .. ", hasStorageAreas = " .. tostring(next(storageAreas) ~= nil))
            end
        end

        callback(foodListItems, totalFoodValue)
    end)
end

-- Populate the storage submenu for a specific item
local function populateStorageSubmenu(menuStructure, storageMenuPanelName, storageAreas, playerPos, parentMenuItem, parentMenuName)
    if not storageAreas or type(storageAreas) ~= "table" then
        mj:log("No storage areas for item, skipping submenu creation")
        return
    end

    -- Check if there are any valid storage areas
    local hasValidStorage = false
    for storageID, storageInfo in pairs(storageAreas) do
        if storageInfo and storageInfo.pos and storageInfo.count then
            hasValidStorage = true
            break
        end
    end

    if not hasValidStorage then
        mj:log("No valid storage areas found, skipping submenu creation for panel: " .. tostring(storageMenuPanelName))
        return
    end

    uiMenuView:createMenuPanel(storageMenuPanelName, parentMenuItem.colorView, parentMenuItem, parentMenuName, foodPanelWidth)

    local rowIndex = 0
    for storageID, storageInfo in pairs(storageAreas) do
        if storageInfo and storageInfo.pos and storageInfo.count then
            local distance = utilities:getDistance(playerPos, storageInfo.pos)
            local storageItemText = string.format("Storage Area: %d (%dm)", storageInfo.count, distance)
            local storageMenuItem = uiMenuView:insertRow(storageMenuPanelName, {
                text = storageItemText,
                onClick = function()
                    -- Retrieve the object and follow it, falling back to teleport if not found
                    logicInterface:callLogicThreadFunction("retrieveObject", storageID, function(result)
                        if result and result.found then
                            localGameUI:followObject(result, false, {dismissAnyUI = true, showInspectUI = true})
                        else
                            localGameUI:teleportToLookAtPos(storageInfo.pos)
                        end
                        -- Hide all panels after teleporting/following
                        for _, panel in pairs(menuStructure.menuPanels) do
                            panel.menuPanelView.hidden = true
                        end
                    end)
                end
            })
            rowIndex = rowIndex + 1

            -- Add teleport icon (icon_inspect) to the storage menu item
            local teleportIcon = ModelView.new(storageMenuItem.colorView)
            local modelIndex = model:modelIndexForName("icon_inspect")
            teleportIcon:setModel(modelIndex)
            teleportIcon.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            teleportIcon.baseOffset = vec3(0, 0, 5) -- z=5 to be above background
            teleportIcon.scale3D = vec3(10, 10, 10)
            teleportIcon.size = vec2(20, 20)
            teleportIcon.masksEvents = false
            teleportIcon.hidden = false
            teleportIcon.alpha = 1.0
            mj:log("Added teleport icon for storage item: " .. tostring(storageItemText) .. ", modelIndex = " .. tostring(modelIndex) .. ", baseOffset = " .. tostring(teleportIcon.baseOffset) .. ", hidden = " .. tostring(teleportIcon.hidden) .. ", parent colorView.hidden = " .. tostring(storageMenuItem.colorView.hidden))
        end
    end
end

-- Populate a category submenu with items
local function populateCategorySubmenu(menuStructure, categoryMenuPanelName, category, items, parentMenuItem, parentMenuName)
    if not items or #items == 0 then
        return
    end

    -- Create the category submenu panel
    uiMenuView:createMenuPanel(categoryMenuPanelName, parentMenuItem.colorView, parentMenuItem, parentMenuName, foodPanelWidth)

    -- Populate items in the category submenu
    for i, item in ipairs(items) do
        local itemText = string.format("%s (%d, %.1f)", item.resourceType.plural, item.storedCount, item.foodValue)
        local storageMenuPanelName = categoryMenuPanelName .. "_Storage_" .. i
        uiMenuView:insertRow(categoryMenuPanelName, {
            text = itemText,
            submenuPanelName = item.storedCount > 0 and storageMenuPanelName or nil,
            gameObjectTypeIndex = item.resourceType.displayGameObjectTypeIndex
        })

        if item.storedCount > 0 then
            local playerPos = localWorld:getRealPlayerHeadPos()
            local parentStorageItem = menuStructure.menuPanels[categoryMenuPanelName].menuItems[i]
            populateStorageSubmenu(menuStructure, storageMenuPanelName, item.storageAreas, playerPos, parentStorageItem, categoryMenuPanelName)
        end
    end
end

-- Populate the main food menu
local function populateFoodMenu(menuStructure, updateFoodInfoTextCallback)
    -- Calculate the tribe's total hunger demand
    local tribeFoodDemand = calculateTribeHungerDemand()

    -- Fetch food items
    foodUI:fetchFoodItems(function(foodListItems, totalFoodValue)
        -- Update the button's food info text
        if updateFoodInfoTextCallback then
            updateFoodInfoTextCallback(totalFoodValue)
        end

        -- Clear existing menu items
        for _, panel in pairs(menuStructure.menuPanels) do
            for _, menuItem in ipairs(panel.menuItems) do
                panel.menuPanelView:removeSubview(menuItem.colorView)
                if menuItem.iconPlayView then
                    panel.menuPanelView:removeSubview(menuItem.iconPlayView)
                end
                if menuItem.gameObjectView then
                    panel.menuPanelView:removeSubview(menuItem.gameObjectView)
                end
            end
            panel.menuItems = {}
        end
        menuStructure.menuPanels = {}
        menuStructure.menuPanels["MainMenu"] = uiMenuView:createMenuPanel("MainMenu", menuStructure.button, nil, nil, foodPanelWidth)

        -- Add metrics row
        uiMenuView:insertRow("MainMenu", {
            text = "Available Food Units (u): " .. totalFoodValue .. "\nCurrent Food Demand: " .. tribeFoodDemand,
            useMetricsHeight = true
        })

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

        -- Render categorized submenus
        local rowIndex = 2
        for _, category in ipairs(foodConfig.categoryOrder) do
            if #groupedItems[category] > 0 then
                local categoryFoodValue = 0
                for _, item in ipairs(groupedItems[category]) do
                    categoryFoodValue = categoryFoodValue + item.foodValue
                end
                local categoryDisplayName
                local resourceType
                if category == "flatBread" then
                    categoryDisplayName = "Flatbread"
                    resourceType = resource.types["flatbread"]
                elseif category == "cookedFoods" then
                    categoryDisplayName = "Cooked Food"
                    if #groupedItems[category] > 0 then
                        resourceType = groupedItems[category][1].resourceType
                    end
                elseif category == "rawFoods" then
                    categoryDisplayName = "Raw Food"
                    resourceType = resource.types["alpacaMeat"]
                elseif category == "naturalFoods" then
                    categoryDisplayName = "Natural Food"
                    resourceType = resource.types["apple"]
                elseif category == "otherFoods" then
                    categoryDisplayName = "Other Food"
                    if #groupedItems[category] > 0 then
                        resourceType = groupedItems[category][1].resourceType
                    end
                else
                    categoryDisplayName = category
                end
                local categoryMenuPanelName = "Category_" .. category
                menuStructure.menuPanels["MainMenu"].menuItems[rowIndex] = uiMenuView:insertRow("MainMenu", {
                    text = categoryDisplayName .. ": " .. categoryFoodValue .. " u",
                    submenuPanelName = categoryFoodValue > 0 and categoryMenuPanelName or nil,
                    gameObjectTypeIndex = resourceType and resourceType.displayGameObjectTypeIndex or nil
                })
                if categoryFoodValue > 0 then
                    populateCategorySubmenu(menuStructure, categoryMenuPanelName, category, groupedItems[category], menuStructure.menuPanels["MainMenu"].menuItems[rowIndex], "MainMenu")
                end
                rowIndex = rowIndex + 1
            end
        end
        -- Render "Other Foods" if it has items
        if #groupedItems.otherFoods > 0 then
            local otherFoodsValue = 0
            for _, item in ipairs(groupedItems.otherFoods) do
                otherFoodsValue = otherFoodsValue + item.foodValue
            end
            local resourceType = #groupedItems.otherFoods > 0 and groupedItems.otherFoods[1].resourceType or nil
            local categoryMenuPanelName = "Category_otherFoods"
            menuStructure.menuPanels["MainMenu"].menuItems[rowIndex] = uiMenuView:insertRow("MainMenu", {
                text = "Other Food: " .. otherFoodsValue .. " u",
                submenuPanelName = otherFoodsValue > 0 and categoryMenuPanelName or nil,
                gameObjectTypeIndex = resourceType and resourceType.displayGameObjectTypeIndex or nil
            })
            if otherFoodsValue > 0 then
                populateCategorySubmenu(menuStructure, categoryMenuPanelName, "otherFoods", groupedItems.otherFoods, menuStructure.menuPanels["MainMenu"].menuItems[rowIndex], "MainMenu")
            end
        end

        -- Reinitialize hover events
        uiMenuView:initialize()
    end)
end

-- Initialize the module and create the Food UI button and panel
function foodUI:init(gameUI, world, parentView, relativeView)
    localWorld = world
    localGameUI = gameUI

    -- Create the menu structure with the button
    local foodButtonSize = vec2(foodButtonWidth, foodButtonHeight)
    local foodButtonBaseOffset = vec3(50, -3, 0)
    local menuStructure = uiMenuView:create(
        parentView,
        foodButtonSize,
        MJPositionInnerLeft,
        MJPositionTop,
        foodButtonBaseOffset,
        foodPanelWidth
    )

    -- Use the button provided by uiMenuView
    local foodButton = menuStructure.button

    -- Food icon
    local foodIconModel = "icon_food"
    local foodIconBaseOffset = vec3(10, -5, 5) -- z=5 to be above background
    local iconHalfSize = 9
    local foodIconScale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
    local foodIconSize = vec2(9, 9) * 2.0
    local foodIcon = ModelView.new(foodButton)
    local foodIconModelIndex = model:modelIndexForName(foodIconModel)
    foodIcon:setModel(foodIconModelIndex)
    foodIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    foodIcon.baseOffset = foodIconBaseOffset
    foodIcon.scale3D = foodIconScale3D
    foodIcon.size = foodIconSize
    foodIcon.masksEvents = false
    foodIcon.hidden = false
    foodIcon.alpha = 1.0
    mj:log("Added food icon to button: modelIndex = " .. tostring(foodIconModelIndex) .. ", baseOffset = " .. tostring(foodIcon.baseOffset) .. ", hidden = " .. tostring(foodIcon.hidden))

    -- Food Info Text View
    local foodInfoTextView = TextView.new(foodButton)
    foodInfoTextView.font = Font(uiCommon.fontName, 14)
    foodInfoTextView.relativeView = foodIcon    
    foodInfoTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    foodInfoTextView.baseOffset = vec3(10, -5, 5) -- Adjusted x-offset to 2 for better alignment, z=5
    foodInfoTextView.color = vec4(0.6, 1.0, 0.6, 1.0) -- Green color
    foodInfoTextView.hidden = false
    mj:log("Added food info text: baseOffset = " .. tostring(foodInfoTextView.baseOffset) .. ", hidden = " .. tostring(foodInfoTextView.hidden))

    -- Function to update the food info text on the button
    local updateTimer = 0.0
    local function updateFoodInfoText(totalFoodValue)
        foodInfoTextView.text = tostring(totalFoodValue)
    end

    -- Populate Food Menu initially
    populateFoodMenu(menuStructure, updateFoodInfoText)

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

    -- Store panel in foodButton userData
    foodButton.userData.panel = menuStructure.menuPanels["MainMenu"].menuPanelView

    return foodButton, updateFoodInfoText
end

return foodUI
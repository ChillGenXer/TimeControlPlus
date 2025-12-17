-- imports
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local resource = mjrequire "common/resource"
local gameObject = mjrequire "common/gameObject"
local utilities = mjrequire "timeControlPlus/common/utilities"
local need = mjrequire "common/need"
local uiMenuView = mjrequire "timeControlPlus/ui/uicommon/uiMenuView"
local foodConfig = mjrequire "timeControlPlus/ui/foodConfig"

-- Initialize module
local menuFood = {}

-- Game state objects
local localWorld = nil
local localGameUI = nil
local playerSapiens = nil
local logicInterface = nil
local localPlayer = nil

local function getPlayerSapiens()
    if playerSapiens then
        return playerSapiens
    end

    local ok, result = pcall(mjrequire, "mainThread/playerSapiens")
    if ok then
        playerSapiens = result
    end

    return playerSapiens
end

local function getLogicInterface()
    if logicInterface then
        return logicInterface
    end

    local ok, result = pcall(mjrequire, "mainThread/logicInterface")
    if ok then
        logicInterface = result
    end

    return logicInterface
end

local function getLocalPlayer()
    if localPlayer then
        return localPlayer
    end

    local ok, result = pcall(mjrequire, "mainThread/localPlayer")
    if ok then
        localPlayer = result
    end

    return localPlayer
end

-- Constants for UI
local updateInterval = 2.0 -- Unified 2-second update interval for both button text and menu
local foodButtonWidth = 80.0 -- Width for the Food button
local foodButtonHeight = 40.0 -- Height for the Food button
local foodPanelWidth = 300.0 -- Width for the food panel

-- Helper function to calculate the total hunger demand of the tribe
local function calculateTribeHungerDemand()
    local playerSapiensRef = getPlayerSapiens()
    local localPlayerRef = getLocalPlayer()
    if not localPlayerRef then
        return 0
    end
    if not playerSapiensRef then
        return 0
    end

    -- Get the list of Sapiens in the tribe
    local sapienList = playerSapiensRef:getDistanceOrderedSapienList(localPlayerRef:getNormalModePos())
    
    -- Sum up the hunger values
    local totalHungerDemand = 0.0
    for _, sapienInfo in ipairs(sapienList) do
        local sapien = sapienInfo.sapien
        local sharedState = sapien.sharedState
        local hungerValue = sharedState.needs[need.types.food.index] or 0.0
        totalHungerDemand = totalHungerDemand + hungerValue
    end
    
    return math.floor(totalHungerDemand + 0.5)
end

-- Helper function to calculate total food value for an item
local function calculateItemFoodValue(item)
    if not item.resourceType.foodValue then
        return 0
    end
    local foodPortionCount = item.resourceType.foodPortionCount or 1
    local foodValue = item.resourceType.foodValue
    local storedCount = item.storedCount or 0
    local calculatedValue = foodPortionCount * foodValue * storedCount
    return calculatedValue
end

-- Fetch food items (with foodValue) and non-food items (from foodConfig.foods)
function menuFood:fetchFoodItems(callback)
    localWorld:getResourceObjectCountsFromServer(function(resourceData)
        local foodListItems = {}
        local totalFoodValue = 0
        local foodConfigKeys = {}

        for foodKey, _ in pairs(foodConfig.foods) do
            foodConfigKeys[foodKey] = true
        end

        for i, resourceType in ipairs(resource.alphabeticallyOrderedTypes) do
            local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
            local storedCount = 0
            for j, gameObjectTypeIndex in ipairs(gameObjectTypes) do
                local thisCount = resourceData[gameObjectTypeIndex] and resourceData[gameObjectTypeIndex].count or 0
                storedCount = storedCount + thisCount
            end

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

-- Populate the storage submenu for a specific item
local function populateStorageSubmenu(menuStructure, storageMenuPanelName, storageAreas, playerPos, parentMenuItem, parentMenuName)
    if not storageAreas or type(storageAreas) ~= "table" then
        return
    end

    local hasValidStorage = false
    for storageID, storageInfo in pairs(storageAreas) do
        if storageInfo and storageInfo.pos and storageInfo.count then
            hasValidStorage = true
            break
        end
    end

    if not hasValidStorage then
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
                    local logicInterfaceRef = getLogicInterface()
                    if not logicInterfaceRef then
                        return
                    end

                    logicInterfaceRef:callLogicThreadFunction("retrieveObject", storageID, function(result)
                        if result and result.found then
                            localGameUI:followObject(result, false, {dismissAnyUI = true, showInspectUI = true})
                        else
                            localGameUI:teleportToLookAtPos(storageInfo.pos)
                        end
                        for _, panel in pairs(menuStructure.menuPanels) do
                            panel.menuPanelView.hidden = true
                        end
                    end)
                end
            })
            rowIndex = rowIndex + 1

            local teleportIcon = ModelView.new(storageMenuItem.colorView)
            local modelIndex = model:modelIndexForName("icon_inspect")
            teleportIcon:setModel(modelIndex)
            teleportIcon.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            teleportIcon.baseOffset = vec3(0, 0, 5)
            teleportIcon.scale3D = vec3(10, 10, 10)
            teleportIcon.size = vec2(20, 20)
            teleportIcon.masksEvents = false
            teleportIcon.hidden = false
            teleportIcon.alpha = 1.0
        end
    end
end

-- Populate a category submenu with items
local function populateCategorySubmenu(menuStructure, categoryMenuPanelName, category, items, parentMenuItem, parentMenuName)
    if not items or #items == 0 then
        return
    end

    uiMenuView:createMenuPanel(categoryMenuPanelName, parentMenuItem.colorView, parentMenuItem, parentMenuName, foodPanelWidth)

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
    local mainMenuPanel = menuStructure.menuPanels["MainMenu"]
    if mainMenuPanel then
        mainMenuPanel.menuItems = {}
    else
        menuStructure.menuPanels = {}
        menuStructure.menuPanels["MainMenu"] = uiMenuView:createMenuPanel("MainMenu", menuStructure.button, nil, nil, foodPanelWidth)
        mainMenuPanel = menuStructure.menuPanels["MainMenu"]
    end

    for _, panel in pairs(menuStructure.menuPanels) do
        panel.menuPanelView.hidden = true
    end

    local tribeFoodDemand = calculateTribeHungerDemand()

    menuFood:fetchFoodItems(function(foodListItems, totalFoodValue)
        if updateFoodInfoTextCallback then
            updateFoodInfoTextCallback(totalFoodValue)
        end

        for panelName, panel in pairs(menuStructure.menuPanels) do
            if panelName ~= "MainMenu" then
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
        end

        if #mainMenuPanel.menuItems == 0 or mainMenuPanel.menuItems[1].textView.text ~= ("Available Food Units (u): " .. totalFoodValue .. "\nCurrent Food Demand: " .. tribeFoodDemand) then
            for i = #mainMenuPanel.menuItems, 1, -1 do
                mainMenuPanel.menuPanelView:removeSubview(mainMenuPanel.menuItems[i].colorView)
                table.remove(mainMenuPanel.menuItems, i)
            end
            uiMenuView:insertRow("MainMenu", {
                text = "Available Food Units (u): " .. totalFoodValue .. "\nCurrent Food Demand: " .. tribeFoodDemand,
                useMetricsHeight = true
            })
        end

        local groupedItems = {}
        for _, category in ipairs(foodConfig.categoryOrder) do
            groupedItems[category] = {}
        end
        groupedItems.otherFoods = {}

        for _, item in ipairs(foodListItems) do
            local category = foodConfig:getCategory(item.resourceType.key)
            table.insert(groupedItems[category], item)
        end

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
                local existingItem = mainMenuPanel.menuItems[rowIndex]
                if not existingItem or existingItem.textView.text ~= (categoryDisplayName .. ": " .. categoryFoodValue .. " u") then
                    if existingItem then
                        mainMenuPanel.menuPanelView:removeSubview(existingItem.colorView)
                        table.remove(mainMenuPanel.menuItems, rowIndex)
                    end
                    mainMenuPanel.menuItems[rowIndex] = uiMenuView:insertRow("MainMenu", {
                        text = categoryDisplayName .. ": " .. categoryFoodValue .. " u",
                        submenuPanelName = categoryFoodValue > 0 and categoryMenuPanelName or nil,
                        gameObjectTypeIndex = resourceType and resourceType.displayGameObjectTypeIndex or nil
                    })
                    if categoryFoodValue > 0 then
                        populateCategorySubmenu(menuStructure, categoryMenuPanelName, category, groupedItems[category], mainMenuPanel.menuItems[rowIndex], "MainMenu")
                    end
                elseif categoryFoodValue > 0 and not existingItem.submenuPanelName then
                    existingItem.submenuPanelName = categoryMenuPanelName
                    populateCategorySubmenu(menuStructure, categoryMenuPanelName, category, groupedItems[category], existingItem, "MainMenu")
                end
                rowIndex = rowIndex + 1
            elseif mainMenuPanel.menuItems[rowIndex] and mainMenuPanel.menuItems[rowIndex].submenuPanelName then
                mainMenuPanel.menuPanelView:removeSubview(mainMenuPanel.menuItems[rowIndex].colorView)
                table.remove(mainMenuPanel.menuItems, rowIndex)
            end
        end
        if #groupedItems.otherFoods > 0 then
            local otherFoodsValue = 0
            for _, item in ipairs(groupedItems.otherFoods) do
                otherFoodsValue = otherFoodsValue + item.foodValue
            end
            local resourceType = #groupedItems.otherFoods > 0 and groupedItems.otherFoods[1].resourceType or nil
            local categoryMenuPanelName = "Category_otherFoods"
            local existingItem = mainMenuPanel.menuItems[rowIndex]
            if not existingItem or existingItem.textView.text ~= ("Other Food: " .. otherFoodsValue .. " u") then
                if existingItem then
                    mainMenuPanel.menuPanelView:removeSubview(existingItem.colorView)
                    table.remove(mainMenuPanel.menuItems, rowIndex)
                end
                mainMenuPanel.menuItems[rowIndex] = uiMenuView:insertRow("MainMenu", {
                    text = "Other Food: " .. otherFoodsValue .. " u",
                    submenuPanelName = otherFoodsValue > 0 and categoryMenuPanelName or nil,
                    gameObjectTypeIndex = resourceType and resourceType.displayGameObjectTypeIndex or nil
                })
                if otherFoodsValue > 0 then
                    populateCategorySubmenu(menuStructure, categoryMenuPanelName, "otherFoods", groupedItems.otherFoods, mainMenuPanel.menuItems[rowIndex], "MainMenu")
                end
            elseif otherFoodsValue > 0 and not existingItem.submenuPanelName then
                existingItem.submenuPanelName = categoryMenuPanelName
                populateCategorySubmenu(menuStructure, categoryMenuPanelName, "otherFoods", groupedItems.otherFoods, existingItem, "MainMenu")
            end
        elseif mainMenuPanel.menuItems[rowIndex] and mainMenuPanel.menuItems[rowIndex].submenuPanelName then
            mainMenuPanel.menuPanelView:removeSubview(mainMenuPanel.menuItems[rowIndex].colorView)
            table.remove(mainMenuPanel.menuItems, rowIndex)
        end

        uiMenuView:initialize()
        if not menuStructure.isMainMenuVisible then
            mainMenuPanel.menuPanelView.hidden = true
        end
    end)
end

-- Initialize the module and create the Food UI button and panel
function menuFood:init(gameUI, world, parentView, relativeView)
    localWorld = world
    localGameUI = gameUI

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

    local foodButton = menuStructure.button

    local foodIconModel = "icon_food"
    local foodIconBaseOffset = vec3(10, -5, 5)
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

    local foodInfoTextView = TextView.new(foodButton)
    foodInfoTextView.font = Font(uiCommon.fontName, 14)
    foodInfoTextView.relativeView = foodIcon    
    foodInfoTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    foodInfoTextView.baseOffset = vec3(10, -5, 5)
    foodInfoTextView.color = vec4(0.6, 1.0, 0.6, 1.0)
    foodInfoTextView.hidden = false

    local function updateFoodInfoText(totalFoodValue)
        foodInfoTextView.text = tostring(totalFoodValue)
    end

    menuStructure.userData = menuStructure.userData or {}
    menuStructure.userData.foodInfoTextView = foodInfoTextView
    menuStructure.userData.updateFoodInfoTextCallback = updateFoodInfoText
    menuStructure.userData.updateTimer = 0

    populateFoodMenu(menuStructure, updateFoodInfoText)

    foodInfoTextView.update = function(dt)
        local submenuOpen = false
        for _, panel in pairs(menuStructure.menuPanels) do
            if panel.positionHierarchy > 0 and not panel.menuPanelView.hidden then
                submenuOpen = true
                break
            end
        end

        menuStructure.userData.updateTimer = (menuStructure.userData.updateTimer or 0) + dt
        if menuStructure.userData.updateTimer >= updateInterval and not submenuOpen then
            menuFood:fetchFoodItems(function(foodListItems, totalFoodValue)
                if menuStructure.userData.updateFoodInfoTextCallback then
                    menuStructure.userData.updateFoodInfoTextCallback(totalFoodValue)
                end
                if menuStructure.isMainMenuVisible then
                    populateFoodMenu(menuStructure, menuStructure.userData.updateFoodInfoTextCallback)
                end
            end)
            menuStructure.userData.updateTimer = 0
        end
    end

    foodButton.userData.panel = menuStructure.menuPanels["MainMenu"].menuPanelView

    return foodButton, updateFoodInfoText
end

return menuFood

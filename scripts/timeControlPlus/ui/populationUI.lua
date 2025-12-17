local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4
local sapienConstants = mjrequire "common/sapienConstants"
local uiAnimation = mjrequire "mainThread/ui/uiAnimation"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local material = mjrequire "common/material"
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"

local populationUI = {}
local populationPanel = nil
local populationInfoView = nil
local playerSapiens = nil

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

-- Function to get population counts and representative sapiens for each category
local function getPopulationData(world)
    local populationData = {
        totalPopulation = 0,
        maleChildren = { count = 0, representative = nil },
        femaleChildren = { count = 0, representative = nil },
        maleAdults = { count = 0, representative = nil },
        femaleAdults = { count = 0, representative = nil },
        pregnantFemales = { count = 0, representative = nil },
        femalesWithInfants = { count = 0, representative = nil },
        maleElders = { count = 0, representative = nil },
        femaleElders = { count = 0, representative = nil }
    }

    local playerSapiensRef = getPlayerSapiens()
    if not playerSapiensRef then
        return populationData
    end

    -- Get total population
    populationData.totalPopulation = playerSapiensRef:getPopulationCountIncludingBabies()

    -- Get the list of sapiens, passing the player's position
    local playerPos = world:getRealPlayerHeadPos()
    local sapiensList = playerSapiensRef:getDistanceOrderedSapienList(playerPos)

    -- Iterate through sapiens to categorize them
    for _, sapienInfo in ipairs(sapiensList) do
        local sapien = sapienInfo.sapien
        local sharedState = sapien.sharedState

        -- Determine gender
        local isFemale = sharedState.isFemale
        local isMale = not isFemale

        -- Determine life stage
        local lifeStageIndex = sharedState.lifeStageIndex
        local isChild = lifeStageIndex == sapienConstants.lifeStages.child.index
        local isAdult = lifeStageIndex == sapienConstants.lifeStages.adult.index
        local isElder = lifeStageIndex == sapienConstants.lifeStages.elder.index

        -- Check pregnancy and infant status (only for females)
        local isPregnant = isFemale and sharedState.pregnant
        local hasInfant = isFemale and sharedState.hasBaby

        -- Increment counts and set representative sapien for the icon (first one found in each category)
        if isMale and isChild then
            populationData.maleChildren.count = populationData.maleChildren.count + 1
            if not populationData.maleChildren.representative then
                populationData.maleChildren.representative = sapien
            end
        elseif isFemale and isChild then
            populationData.femaleChildren.count = populationData.femaleChildren.count + 1
            if not populationData.femaleChildren.representative then
                populationData.femaleChildren.representative = sapien
            end
        elseif isMale and isAdult then
            populationData.maleAdults.count = populationData.maleAdults.count + 1
            if not populationData.maleAdults.representative then
                populationData.maleAdults.representative = sapien
            end
        elseif isFemale and isAdult then
            populationData.femaleAdults.count = populationData.femaleAdults.count + 1
            if not populationData.femaleAdults.representative then
                populationData.femaleAdults.representative = sapien
            end
            if isPregnant then
                populationData.pregnantFemales.count = populationData.pregnantFemales.count + 1
                if not populationData.pregnantFemales.representative then
                    populationData.pregnantFemales.representative = sapien
                end
            end
            if hasInfant then
                populationData.femalesWithInfants.count = populationData.femalesWithInfants.count + 1
                if not populationData.femalesWithInfants.representative then
                    populationData.femalesWithInfants.representative = sapien
                end
            end
        elseif isMale and isElder then
            populationData.maleElders.count = populationData.maleElders.count + 1
            if not populationData.maleElders.representative then
                populationData.maleElders.representative = sapien
            end
        elseif isFemale and isElder then
            populationData.femaleElders.count = populationData.femaleElders.count + 1
            if not populationData.femaleElders.representative then
                populationData.femaleElders.representative = sapien
            end
        end
    end

    return populationData
end

-- Helper function to populate the population list view
local function populatePopulationListView(listView, populationData, listViewSize)
    local backgroundColorCounter = 1
    local backgroundColors = {vec4(0.03, 0.03, 0.03, 0.5), vec4(0.0, 0.0, 0.0, 0.5)}
    local listViewItemHeight = 40.0
    local listViewItemObjectImageViewSize = vec2(30.0, 30.0)

    local categories = {
        { key = "totalPopulation", label = "Total Population", count = populationData.totalPopulation, representative = nil },
        { key = "maleChildren", label = "Male Children", count = populationData.maleChildren.count, representative = populationData.maleChildren.representative },
        { key = "femaleChildren", label = "Female Children", count = populationData.femaleChildren.count, representative = populationData.femaleChildren.representative },
        { key = "maleAdults", label = "Male Adults", count = populationData.maleAdults.count, representative = populationData.maleAdults.representative },
        { key = "femaleAdults", label = "Female Adults", count = populationData.femaleAdults.count, representative = populationData.femaleAdults.representative },
        { key = "pregnantFemales", label = "Pregnant Females", count = populationData.pregnantFemales.count, representative = populationData.pregnantFemales.representative },
        { key = "femalesWithInfants", label = "Females with Infants", count = populationData.femalesWithInfants.count, representative = populationData.femalesWithInfants.representative },
        { key = "maleElders", label = "Male Elders", count = populationData.maleElders.count, representative = populationData.maleElders.representative },
        { key = "femaleElders", label = "Female Elders", count = populationData.femaleElders.count, representative = populationData.femaleElders.representative },
    }

    for _, category in ipairs(categories) do
        -- Create row background with alternating colors
        local rowBackgroundView = ColorView.new(listView)
        local defaultColor = backgroundColors[backgroundColorCounter % 2 + 1]
        rowBackgroundView.color = defaultColor
        rowBackgroundView.size = vec2(listViewSize.x - 22, listViewItemHeight)
        rowBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        uiScrollView:insertRow(listView, rowBackgroundView, nil)
        backgroundColorCounter = backgroundColorCounter + 1

        -- Add icon (either a tribe icon for Total Population or a representative sapien)
        if category.key == "totalPopulation" then
            local icon = ModelView.new(rowBackgroundView)
            icon:setModel(model:modelIndexForName("icon_tribe"))
            icon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            icon.baseOffset = vec3(8, 0, 1)
            icon.scale3D = vec3(12, 12, 12)
            icon.size = vec2(24, 24)
            icon.masksEvents = false
        else
            local gameObjectView = GameObjectView.new(rowBackgroundView, listViewItemObjectImageViewSize)
            gameObjectView.size = listViewItemObjectImageViewSize
            gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            gameObjectView.baseOffset = vec3(8, 0, 1)
            if category.representative then
                local animationInstance = uiAnimation:getUIAnimationInstance(sapienConstants:getAnimationGroupKey(category.representative.sharedState))
                -- if not animationInstance then
                --     mj:log("[Chillgenxer] Warning: Animation instance is nil for category", category.key)
                -- end
                uiCommon:setGameObjectViewObject(gameObjectView, category.representative, animationInstance)
            else
                -- Fallback to placeholder icon if no representative
                local placeholderIcon = ModelView.new(rowBackgroundView)
                placeholderIcon:setModel(model:modelIndexForName("icon_sapien"))
                placeholderIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                placeholderIcon.baseOffset = vec3(8, 0, 1)
                placeholderIcon.scale3D = vec3(12, 12, 12)
                placeholderIcon.size = vec2(24, 24)
                placeholderIcon.masksEvents = false
            end
            gameObjectView.masksEvents = false
        end

        -- Add category name and count
        local titleTextView = TextView.new(rowBackgroundView)
        titleTextView.font = Font(uiCommon.fontName, 16)
        titleTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        titleTextView.baseOffset = vec3(40, 0, 1)
        titleTextView.text = category.label
        titleTextView.color = mj.textColor

        local countTextView = TextView.new(rowBackgroundView)
        countTextView.font = Font(uiCommon.fontName, 16)
        countTextView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
        countTextView.baseOffset = vec3(-10, 0, 1)
        countTextView.text = tostring(category.count)
        -- Color-code counts: green for Pregnant Females and Females with Infants if >0, white otherwise
        if (category.key == "pregnantFemales" or category.key == "femalesWithInfants") and category.count > 0 then
            countTextView.color = vec4(0.6, 1.0, 0.6, 1.0) -- Green
        else
            countTextView.color = mj.textColor -- White
        end
    end
end

function populationUI:init(world, parentView, relativeView, panels)
    -- Population Menu
    local iconHalfSize = 9
    local populationButtonWidth = 80.0    -- Width for the new Population button (same as others)
    local populationButtonSize = vec2(populationButtonWidth, 40.0)
    local populationButtonBaseOffset = vec3(10, 0, 0)
    local populationIconModel = "icon_tribe"
    local populationIconBaseOffset = vec3(10, 0, 0)
    local populationIconScale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
    local populationIconSize = vec2(9, 9) * 2.0
    local populationInfoViewBaseOffset = vec3(6, -2, 0)
    local populationInfoViewText = "0" -- Will be updated dynamically
    local populationInfoViewColor = vec4(0.6, 1.0, 0.6, 1.0) -- Green color, matching others
    local populationInfoToolTip = "Population Details"
    local populationInfoToolTipOffset = vec3(0, -8, 4)

    local populationButton = uiStandardButton:create(parentView, populationButtonSize, uiStandardButton.types.favor_10x3, {
        default = material.types.ui_background.index
    })
    populationButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    populationButton.relativeView = relativeView -- Position to the right of the relative view
    populationButton.baseOffset = populationButtonBaseOffset
    -- Population icon
    local populationIcon = ModelView.new(populationButton)
    populationIcon:setModel(model:modelIndexForName(populationIconModel))
    populationIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    populationIcon.baseOffset = populationIconBaseOffset
    populationIcon.scale3D = populationIconScale3D
    populationIcon.size = populationIconSize
    populationIcon.masksEvents = false
    -- Population Menu Main Info
    populationInfoView = TextView.new(populationButton)
    populationInfoView.font = Font(uiCommon.fontName, 14)
    populationInfoView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    populationInfoView.relativeView = populationIcon
    populationInfoView.baseOffset = populationInfoViewBaseOffset
    populationInfoView.text = populationInfoViewText
    populationInfoView.color = populationInfoViewColor
    populationInfoView.masksEvents = false
    -- Population Menu Infotip
    uiToolTip:add(populationButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), populationInfoToolTip, nil, populationInfoToolTipOffset, nil, populationButton)
    -- Define populationListViewSize at a higher scope
    local populationPanelSize = vec2(250, 370.0) -- Same as other menus
    local populationListViewSize = vec2(populationPanelSize.x - 10, populationPanelSize.y - 10)
    
    -- Update function to refresh the population count
    populationButton.update = function(dt)
        local populationData = getPopulationData(world)
        populationInfoView.text = string.format("%d", populationData.totalPopulation)
    end
    
    -- Handle Click Event
    -- In the Population Button click function
    uiStandardButton:setClickFunction(populationButton, function()
        -- Close all other panels and restore their tooltips
        for _, panelInfo in pairs(panels) do
            if panelInfo.panel and panelInfo.panel ~= populationPanel and not panelInfo.panel.hidden then
                panelInfo.panel.hidden = true
                uiToolTip:add(panelInfo.button.userData.backgroundView, panelInfo.tooltip.position, panelInfo.tooltip.text, panelInfo.tooltip.description, panelInfo.tooltip.offset, nil, panelInfo.button)
            end
        end

        if not populationPanel then
            -- Create the population panel on first click
            populationPanel = ModelView.new(parentView)
            populationPanel:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
            populationPanel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
            populationPanel.relativeView = populationButton
            populationPanel.baseOffset = vec3(0, 0, 0)
            local populationPanelScaleX = populationPanelSize.x * 0.5 / (2.0/3.0)
            local populationPanelScaleY = populationPanelSize.y * 0.5
            populationPanel.scale3D = vec3(populationPanelScaleX, populationPanelScaleY, populationPanelScaleX)
            populationPanel.size = populationPanelSize
            populationPanel.alpha = 0.9
            populationPanel.hidden = false

            -- Create a scroll view inside the panel
            local populationListView = uiScrollView:create(populationPanel, populationListViewSize, MJPositionInnerLeft)
            if not populationListView then
                --mj:log("[Chillgenxer] Error: Failed to create populationListView")
                return -- Prevent further execution if scroll view creation fails
            end
            populationListView.baseOffset = vec3(0, 0, 2)
            populationButton.userData.populationListView = populationListView -- Store for later access

            -- Populate the list for the first time
            local populationData = getPopulationData(world)
            uiScrollView:removeAllRows(populationListView) -- Clear any existing rows
            populatePopulationListView(populationListView, populationData, populationListViewSize)
            -- Update the button text with total population
            populationInfoView.text = string.format("%d", populationData.totalPopulation)

            -- Store panel info
            panels.population = {
                panel = populationPanel,
                button = populationButton,
                tooltip = {
                    position = ViewPosition(MJPositionCenter, MJPositionBelow),
                    text = populationInfoToolTip,
                    description = nil,
                    offset = populationInfoToolTipOffset
                }
            }
        else
            -- Toggle visibility and refresh if about to be shown
            local willBeShown = populationPanel.hidden -- True if currently hidden
            populationPanel.hidden = not populationPanel.hidden
            if not populationPanel.hidden and willBeShown then
                -- Refresh the list when the panel is about to be shown
                local populationListView = populationButton.userData.populationListView
                if not populationListView then
                    --mj:log("[Chillgenxer] Error: populationListView is nil in userData")
                    return
                end
                local populationData = getPopulationData(world)
                uiScrollView:removeAllRows(populationListView) -- Clear existing rows
                populatePopulationListView(populationListView, populationData, populationListViewSize)
                -- Update the button text with total population
                populationInfoView.text = string.format("%d", populationData.totalPopulation)
            end
        end

        -- Manage tooltip visibility
        if not populationPanel.hidden then
            uiToolTip:remove(populationButton.userData.backgroundView)
        else
            uiToolTip:add(populationButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), populationInfoToolTip, nil, populationInfoToolTipOffset, nil, populationButton)
        end
    end)

end

function populationUI:setPopulation(newPopulation)
    if populationInfoView and newPopulation then
        populationInfoView.text = tostring(newPopulation)
    end
end

function populationUI:showPanel()
    populationPanel.hidden = false
end

function populationUI:hidePanel()
    populationPanel.hidden = true
end

return populationUI

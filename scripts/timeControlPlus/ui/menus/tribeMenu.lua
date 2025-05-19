-- Tribe
    -- Total Population         106
    -- Overall Hunger Level:    5 Stars   
    -- Tribe Overall Health:    5 Stars
    ---------------------------------------
    -- Demographics
        -- Male Children
        -- Female Children
        -- Male Adults
        -- Female Adults
        -- Pregnant Females
        -- Females with Infants
        -- Male Elders
        -- Female Elders
    -- Tribe Health
        -- Ailments
            -- Injured (4)
                -- Poka [Z]
                -- Mico [Z]
                -- Wanaqa [Z]
            -- Stomach Sick (3)
                -- sapienName [zoom]
            -- Virus Infection (17)
                -- sapienName [zoom]
            -- Burned (4)
                -- sapienName [zoom]
        -- Medicine
            -- Fired Brun Medicine (4)
            -- Unfired Burn Medicine (3)
            -- Fired Food Poisoning Medicine
            -- Unfired Food Poisoning Medicine
        -- Medical Supplies
            -- Echinacia
            -- Garlic
            -- ..
            -- Quern-stones



 -- Medicine Menu
    local medicineButtonWidth = 80.0    -- Width for the new Medicine button (same as Tools)
    local medicineButtonSize = vec2(medicineButtonWidth, 40.0)
    local medicineButtonBaseOffset = vec3(10, 0, 0)
    local medicineIconModel = "icon_injury"
    local medicineIconBaseOffset = vec3(10, 0, 0)
    local medicineIconScale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
    local medicineIconSize = vec2(9, 9) * 2.0
    local medicineInfoViewBaseOffset = vec3(6, -2, 0)
    local medicineInfoViewText = "0" -- Placeholder, can be updated later
    local medicineInfoViewColor = vec4(0.6, 1.0, 0.6, 1.0) -- Green color, matching Tools
    local medicineInfoToolTip = "Medicine"
    local medicineInfoToolTipOffset = vec3(0, -8, 4)

    local medicineButton = uiStandardButton:create(leftMainView, medicineButtonSize, uiStandardButton.types.favor_10x3, {
        default = material.types.ui_background.index
    })
    medicineButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    medicineButton.relativeView = toolsButton -- Position to the right of the Tools button
    medicineButton.baseOffset = medicineButtonBaseOffset
    -- Medicine icon
    local medicineIcon = ModelView.new(medicineButton)
    medicineIcon:setModel(model:modelIndexForName(medicineIconModel))
    medicineIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    medicineIcon.baseOffset = medicineIconBaseOffset
    medicineIcon.scale3D = medicineIconScale3D
    medicineIcon.size = medicineIconSize
    medicineIcon.masksEvents = false
    -- Medicine Menu Main Info
    local medicineInfoView = TextView.new(medicineButton)
    medicineInfoView.font = Font(uiCommon.fontName, 14)
    medicineInfoView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    medicineInfoView.relativeView = medicineIcon
    medicineInfoView.baseOffset = medicineInfoViewBaseOffset
    medicineInfoView.text = medicineInfoViewText
    medicineInfoView.color = medicineInfoViewColor
    medicineInfoView.masksEvents = false
    -- Medicine Menu Infotip
    uiToolTip:add(medicineButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), medicineInfoToolTip, nil, medicineInfoToolTipOffset, nil, medicineButton)
    -- Define medicineListViewSize at a higher scope
    local medicinePanelSize = vec2(250, 680.0) -- Same as Tools menu
    local medicineListViewSize = vec2(medicinePanelSize.x - 10, medicinePanelSize.y - 10)
    -- Handle Click Event
    uiStandardButton:setClickFunction(medicineButton, function()
        -- Close all other panels and restore their tooltips
        for _, panelInfo in pairs(panels) do
            if panelInfo.panel and panelInfo.panel ~= medicinePanel and not panelInfo.panel.hidden then
                panelInfo.panel.hidden = true
                uiToolTip:add(panelInfo.button.userData.backgroundView, panelInfo.tooltip.position, panelInfo.tooltip.text, panelInfo.tooltip.description, panelInfo.tooltip.offset, nil, panelInfo.button)
            end
        end

        if not medicinePanel then
            -- Create the medicine panel on first click
            medicinePanel = ModelView.new(leftMenuBarPanel)
            medicinePanel:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
            medicinePanel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
            medicinePanel.relativeView = medicineButton
            medicinePanel.baseOffset = vec3(0, 0, 0)
            local medicinePanelScaleX = medicinePanelSize.x * 0.5 / (2.0/3.0)
            local medicinePanelScaleY = medicinePanelSize.y * 0.5
            medicinePanel.scale3D = vec3(medicinePanelScaleX, medicinePanelScaleY, medicinePanelScaleX)
            medicinePanel.size = medicinePanelSize
            medicinePanel.alpha = 0.9
            medicinePanel.hidden = false

            -- Create a scroll view inside the panel
            local medicineListView = uiScrollView:create(medicinePanel, medicineListViewSize, MJPositionInnerLeft)
            medicineListView.baseOffset = vec3(0, 0, 2)
            medicineButton.userData.medicineListView = medicineListView -- Store for later access

            -- Populate the list for the first time
            getResourceListItems("medicineList", function(medicineListItems)
                uiScrollView:removeAllRows(medicineListView) -- Clear any existing rows
                populateListView(medicineListView, medicineListItems, medicineListViewSize)
            end)

            -- Store panel info
            panels.medicine = {
                panel = medicinePanel,
                button = medicineButton,
                tooltip = {
                    position = ViewPosition(MJPositionCenter, MJPositionBelow),
                    text = medicineInfoToolTip,
                    description = nil,
                    offset = medicineInfoToolTipOffset
                }
            }
        else
            -- Toggle visibility and refresh if about to be shown
            local willBeShown = medicinePanel.hidden -- True if currently hidden
            medicinePanel.hidden = not medicinePanel.hidden
            if not medicinePanel.hidden and willBeShown then
                -- Refresh the list when the panel is about to be shown
                local medicineListView = medicineButton.userData.medicineListView
                getResourceListItems("medicineList", function(medicineListItems)
                    uiScrollView:removeAllRows(medicineListView) -- Clear existing rows
                    populateListView(medicineListView, medicineListItems, medicineListViewSize)
                end)
            end
        end

        -- Manage tooltip visibility
        if not medicinePanel.hidden then
            uiToolTip:remove(medicineButton.userData.backgroundView)
        else
            uiToolTip:add(medicineButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), medicineInfoToolTip, nil, medicineInfoToolTipOffset, nil, medicineButton)
        end
    end)    
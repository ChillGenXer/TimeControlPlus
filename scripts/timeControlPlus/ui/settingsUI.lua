local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
--local vec4 = mjm.vec4
local model = mjrequire "common/model"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local material = mjrequire "common/material"
local uiMenuView = mjrequire "timeControlPlus/ui/uiMenuView"
--local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"

local settingsUI = {}
local localGameUI = nil

local settingsView = nil
local settingsViewSize = vec2(800.0, 600.0)
local settingsViewOffset = vec3(0.0, 0.0, 0.0)

local settingsPanel = nil
local settingsPanelSize = vec2(800.0, 600.0)
local settingsPanelScaleX = 400
local settingsPanelScaleY = 400
local settingsPanelModel = "ui_bg_lg_4x3"
local settingsPanelOffset = vec3(0.0, 0.0, 0.0)
local settingsPanelScale3D = vec3(settingsPanelScaleX, settingsPanelScaleY, settingsPanelScaleX)
local settingsPanelAlpha = 1.0

local actionButton = nil
local testMenuView = nil

local function createTestMenu()
    testMenuView = uiMenuView:create(settingsPanel, actionButton, 300, 42, vec3(0, 0, 0), localGameUI)

    -- Main menu with 25 items
    for i = 1, 25 do
        local rowView = ColorView.new(testMenuView.userData.baseItemView)
        rowView.size = vec2(290, 30)
        uiMenuView:insertRow(testMenuView, rowView, nil, "Item " .. i)
    end

    -- Item 2: Submenu with 1 item
    local subMenu2 = uiMenuView:create(testMenuView.userData.panel, testMenuView.userData.rowInfos[2].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for j = 1, 1 do
        local subRow = ColorView.new(subMenu2.userData.baseItemView)
        subRow.size = vec2(190, 30)
        uiMenuView:insertRow(subMenu2, subRow, nil, "Subitem " .. j)
    end
    uiMenuView:addSubMenu(testMenuView, 2, subMenu2)

    -- Item 3: Submenu with 5 items, 3rd item has a sub-submenu with 3 items
    local subMenu3 = uiMenuView:create(testMenuView.userData.panel, testMenuView.userData.rowInfos[3].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for j = 1, 5 do
        local subRow = ColorView.new(subMenu3.userData.baseItemView)
        subRow.size = vec2(190, 30)
        uiMenuView:insertRow(subMenu3, subRow, nil, "Subitem " .. j)
    end
    
    local subSubMenu3 = uiMenuView:create(subMenu3.userData.panel, subMenu3.userData.rowInfos[3].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for k = 1, 3 do
        local subSubRow = ColorView.new(subSubMenu3.userData.baseItemView)
        subSubRow.size = vec2(190, 30)
        uiMenuView:insertRow(subSubMenu3, subSubRow, nil, "Sub-subitem " .. k)
    end
    uiMenuView:addSubMenu(subMenu3, 3, subSubMenu3)
    uiMenuView:addSubMenu(testMenuView, 3, subMenu3)

    -- Item 5: Submenu with 10 items
    local subMenu5 = uiMenuView:create(testMenuView.userData.panel, testMenuView.userData.rowInfos[5].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for j = 1, 10 do
        local subRow = ColorView.new(subMenu5.userData.baseItemView)
        subRow.size = vec2(190, 30)
        uiMenuView:insertRow(subMenu5, subRow, nil, "Subitem " .. j)
    end
    uiMenuView:addSubMenu(testMenuView, 5, subMenu5)

    -- Item 6: Submenu with 15 items, 10th item has a sub-submenu with 8 items
    local subMenu6 = uiMenuView:create(testMenuView.userData.panel, testMenuView.userData.rowInfos[6].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for j = 1, 15 do
        local subRow = ColorView.new(subMenu6.userData.baseItemView)
        subRow.size = vec2(190, 30)
        uiMenuView:insertRow(subMenu6, subRow, nil, "Subitem " .. j)
    end
    local subSubMenu6 = uiMenuView:create(subMenu6.userData.panel, subMenu6.userData.rowInfos[10].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for k = 1, 8 do
        local subSubRow = ColorView.new(subSubMenu6.userData.baseItemView)
        subSubRow.size = vec2(190, 30)
        uiMenuView:insertRow(subSubMenu6, subSubRow, nil, "Sub-subitem " .. k)
    end
    uiMenuView:addSubMenu(subMenu6, 10, subSubMenu6)
    uiMenuView:addSubMenu(testMenuView, 6, subMenu6)

    -- Item 16: Submenu with 20 items
    local subMenu16 = uiMenuView:create(testMenuView.userData.panel, testMenuView.userData.rowInfos[16].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for j = 1, 20 do
        local subRow = ColorView.new(subMenu16.userData.baseItemView)
        subRow.size = vec2(190, 30)
        uiMenuView:insertRow(subMenu16, subRow, nil, "Subitem " .. j)
    end
    uiMenuView:addSubMenu(testMenuView, 16, subMenu16)

    -- Item 17: Submenu with 25 items
    local subMenu17 = uiMenuView:create(testMenuView.userData.panel, testMenuView.userData.rowInfos[17].rowView, 200, 42, vec3(0, 0, 2), localGameUI)
    for j = 1, 25 do
        local subRow = ColorView.new(subMenu17.userData.baseItemView)
        subRow.size = vec2(190, 30)
        uiMenuView:insertRow(subMenu17, subRow, nil, "Subitem " .. j)
    end
    uiMenuView:addSubMenu(testMenuView, 17, subMenu17)
end

local function createActionButton()
    local actionButtonSize = vec2(80.0, 40.0)
    local actionButtonBaseOffset = vec3(50, -3, 0)

    actionButton = uiStandardButton:create(settingsPanel, actionButtonSize, uiStandardButton.types.favor_10x3, {
        default = material.types.ui_background.index
    })
    actionButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    actionButton.relativeView = settingsPanel
    actionButton.baseOffset = actionButtonBaseOffset

    local settingsIconModel = "icon_settings"
    local settingsIconBaseOffset = vec3(0, 0, 0)
    local iconHalfSize = 9
    local settingsIconScale3D = vec3(iconHalfSize, iconHalfSize, iconHalfSize)
    local settingsIconSize = vec2(9, 9) * 2.0
    local settingsIcon = ModelView.new(actionButton)
    settingsIcon:setModel(model:modelIndexForName(settingsIconModel))
    settingsIcon.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    settingsIcon.baseOffset = settingsIconBaseOffset
    settingsIcon.scale3D = settingsIconScale3D
    settingsIcon.size = settingsIconSize
    settingsIcon.masksEvents = false
    settingsIcon.alpha = 1.0

    uiStandardButton:setClickFunction(actionButton, function()
        if testMenuView then
            testMenuView:toggle()
        end
    end)
end

function settingsUI:init(gameUI)
    localGameUI = gameUI

    settingsView = View.new(localGameUI.view)
    settingsView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    settingsView.baseOffset = settingsViewOffset
    settingsView.size = settingsViewSize
    settingsView.hidden = true
    settingsUI.hidden = settingsView.hidden

    settingsPanel = ModelView.new(settingsView)
    settingsPanel:setModel(model:modelIndexForName(settingsPanelModel))
    settingsPanel.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    settingsPanel.baseOffset = settingsPanelOffset
    settingsPanel.scale3D = settingsPanelScale3D
    settingsPanel.size = settingsPanelSize
    settingsPanel.alpha = settingsPanelAlpha
    settingsPanel.hidden = false

    createActionButton()
    createTestMenu()

    return settingsView
end

return settingsUI
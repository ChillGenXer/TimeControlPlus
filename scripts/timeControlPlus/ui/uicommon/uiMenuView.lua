local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local material = mjrequire "common/material"

local uiMenuView = {}
local menuStructure = {}
local uiMenuPanel = nil


-- Debug mode for verbose logging in this module only
local debugMode = false -- Toggle debugging for uiMenuView.lua here

-- Constants aligned with base game style (adapted from uiScrollView and prior uiMenuView)
local rowHeight = 30.0
local metricsRowHeight = 60.0
local borderWidth = 20.0
local contentPaddingHorizontal = 5.0
local contentPaddingVertical = 5.0
local rowInsetHorizontal = 11.0
local fontSize = 16
local defaultBackgroundColors = { vec4(0.05, 0.05, 0.05, 1.0), vec4(0.0, 0.0, 0.0, 1.0) }
local textOffsetX = 10
local button = nil

-- Function to calculate scale3D for the panel
local function calculateScale3D(width, height)
    local adjustedScaleX = width * 0.5 / (2.0/3.0)
    local adjustedScaleY = height * 0.5
    return vec3(adjustedScaleX, adjustedScaleY, adjustedScaleX)
end

-- Function to update Y offsets for rows
local function updateYOffsets(menuView, rowStartIndex)
    local userTable = menuView.userData
    for i = rowStartIndex, #userTable.rowInfos do
        local rowInfo = userTable.rowInfos[i]
        local aboveRowInfo = userTable.rowInfos[i - 1]
        if aboveRowInfo then
            rowInfo.yOffsetFromTop = aboveRowInfo.yOffsetFromTop + aboveRowInfo.rowHeight
        else
            rowInfo.yOffsetFromTop = 0
        end
        rowInfo.rowView.baseOffset = vec3(0, -rowInfo.yOffsetFromTop, 0)
    end

    -- Update the menu's size and scale to fit all items
    local numRows = #userTable.rowInfos
    local totalContentHeight = 0
    for i = 1, numRows do
        totalContentHeight = totalContentHeight + userTable.rowInfos[i].rowHeight
    end
    local height = totalContentHeight + 2 * contentPaddingVertical + 10
    userTable.panel.size = vec2(userTable.panelWidth, height)
    userTable.panel.scale3D = calculateScale3D(userTable.panelWidth, height)
    userTable.baseItemView.size = vec2(userTable.width - 2 * contentPaddingHorizontal, totalContentHeight)
end

-- Function to create a new menu panel instance
function uiMenuView:create(parentView, buttonSize, horizontalPosition, verticalPosition, buttonOffset)

    -- Create the main button that will be shown on the UI
    button = uiStandardButton:create(parentView, buttonSize, uiStandardButton.types.slim_1x1, {
        default = material.types.ui_background.index
    })
    button.relativePosition = ViewPosition(horizontalPosition, verticalPosition)
    button.baseOffset = buttonOffset

    -- Create the menuStructure = {}
    local menuPanel = ModelView.new(button)
    menuPanel:setModel(model:modelIndexForName("ui_bg_lg_4x3"))
    menuPanel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

end
    -- local menuView = ModelView.new(parentView)
    -- menuView.userData = userTable
    -- menuView:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
    -- menuView.relativePosition = ViewPosition(userTable.horizontalAlignment, userTable.verticalAlignment)
    -- menuView.relativeView = parentView
    -- menuView.baseOffset = userTable.baseOffset
    -- menuView.size = vec2(userTable.panelWidth, userTable.minHeight)
    -- menuView.scale3D = calculateScale3D(userTable.panelWidth, userTable.minHeight)
    -- menuView.hidden = true
    -- menuView.masksEvents = true

    -- local userTable = {
    --     width = (width or 300) + borderWidth,
    --     minHeight = 42.0,
    --     backgroundColors = defaultBackgroundColors,
    --     rowInfos = {},
    --     backgroundColorCounter = 1,
    --     panelWidth = (width or 300) + borderWidth,
    --     contentHorizontalAlignment = MJPositionCenter,
    --     horizontalAlignment = horizontalPosition or MJPositionInnerLeft,
    --     verticalAlignment = verticalPosition or MJPositionBottom,
    --     baseOffset = vec3(-14, 0, 0),
    -- }

--     local menuView = ModelView.new(parentView)
--     menuView.userData = userTable
--     menuView:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
--     menuView.relativePosition = ViewPosition(userTable.horizontalAlignment, userTable.verticalAlignment)
--     menuView.relativeView = parentView
--     menuView.baseOffset = userTable.baseOffset
--     menuView.size = vec2(userTable.panelWidth, userTable.minHeight)
--     menuView.scale3D = calculateScale3D(userTable.panelWidth, userTable.minHeight)
--     menuView.hidden = true
--     menuView.masksEvents = true
--     userTable.panel = menuView

--     local baseItemView = View.new(menuView)
--     baseItemView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
--     baseItemView.size = vec2(userTable.width - 2 * contentPaddingHorizontal, userTable.minHeight - 2 * contentPaddingVertical)
--     baseItemView.masksEvents = true
--     userTable.baseItemView = baseItemView


--         -- Attach hover handlers to the button
--     button.masksEvents = true
--     button.hoverStart = function()
--         menuView.hidden = false
--         if debugMode then
--             mj:log("TestButton hoverStart: Menu opened")
--         end
--     end
--     button.hoverEnd = function()
--         -- Do nothing; menu stays open until click outside
--     end

--     -- Attach click handler to toggle the menu
--     uiStandardButton:setClickFunction(button, function()
--         if menuView.hidden then
--             menuView.hidden = false
--             if debugMode then
--                 mj:log("TestButton clicked: Menu opened")
--             end
--         else
--             menuView.hidden = true
--             if debugMode then
--                 mj:log("TestButton clicked: Menu hidden")
--             end
--         end
--     end)



--     -- Attach clickDownOutside handler to hide the menu
--     menuView.clickDownOutside = function(buttonIndex)
--         menuView.hidden = true
--         if debugMode then
--             mj:log("uiMenuView clickDownOutside: Menu hidden")
--         end
--     end

--     return menuView
-- end

-- Function to insert a new item (row) into the menu
function uiMenuView:insertRow(menuView, itemParams)
    local userTable = menuView.userData
    local rowIndex = #userTable.rowInfos + 1

    -- Create the row view
    local rowView = ColorView.new(userTable.baseItemView)
    local rowHeightToUse = (itemParams.useMetricsHeight and metricsRowHeight) or rowHeight
    rowView.size = vec2(userTable.width - 2 * contentPaddingHorizontal - 2 * rowInsetHorizontal, rowHeightToUse)
    rowView.relativePosition = ViewPosition(userTable.contentHorizontalAlignment, MJPositionTop)

    local colorIndex = userTable.backgroundColorCounter % 2 + 1
    rowView.color = userTable.backgroundColors[colorIndex]
    userTable.backgroundColorCounter = userTable.backgroundColorCounter + 1

    local rowInfo = {
        rowView = rowView,
        rowHeight = rowHeightToUse,
        yOffsetFromTop = 0, -- Will be updated by updateYOffsets
    }

    -- Add the text for the menu item
    local textView = TextView.new(rowView)
    textView.font = Font(uiCommon.fontName, fontSize)
    if itemParams.useMetricsHeight then
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        textView.baseOffset = vec3(itemParams.textOffsetX or textOffsetX, -5, 1)
    else
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        textView.baseOffset = vec3(itemParams.textOffsetX or textOffsetX, 0, 1)
    end
    textView.text = itemParams.text or "Unknown Item"
    textView.color = mj.textColor
    rowInfo.textView = textView

    -- Add a click handler if provided
    if itemParams.onClick then
        rowView.masksEvents = true
        rowView.click = function(buttonIndex)
            itemParams.onClick()
        end
    end

    table.insert(userTable.rowInfos, rowIndex, rowInfo)

    -- Update positions and resize the menu
    updateYOffsets(menuView, rowIndex)

    if debugMode then
        mj:log("uiMenuView insertRow: rowIndex =", rowIndex, "text =", textView.text)
    end

    return rowInfo
end

return uiMenuView
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"

local UIManager = {}

-- Panel Management
local panels = {}

function UIManager:registerPanel(panelInfo)
    panels[panelInfo.panel] = panelInfo
end

function UIManager:showPanel(panelToShow)
    for panel, panelInfo in pairs(panels) do
        if panel ~= panelToShow and not panel.hidden then
            panel.hidden = true
            uiToolTip:add(panelInfo.button.userData.backgroundView, panelInfo.tooltip.position, panelInfo.tooltip.text, panelInfo.tooltip.description, panelInfo.tooltip.offset, nil, panelInfo.button)
        end
    end
    panelToShow.hidden = false
    uiToolTip:remove(panels[panelToShow].button.userData.backgroundView)
end

function UIManager:hidePanel(panelToHide)
    panelToHide.hidden = true
    uiToolTip:add(panels[panelToHide].button.userData.backgroundView, panels[panelToHide].tooltip.position, panels[panelToHide].tooltip.text, panels[panelToHide].tooltip.description, panels[panelToHide].tooltip.offset, nil, panels[panelToHide].button)
end

-- Layout Management
local buttonConfigs = {}
local buttonSpacing = 10

function UIManager:registerButton(button, parentView, config)
    table.insert(buttonConfigs, {
        button = button,
        parentView = parentView,
        config = config or {}
    })
end

function UIManager:layoutButtons()
    local xOffset = 50 -- Starting position
    for i, config in ipairs(buttonConfigs) do
        config.button.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        config.button.baseOffset = vec3(xOffset, -3, 0)
        config.button.parentView = config.parentView
        if i > 1 then
            config.button.relativeView = buttonConfigs[i-1].button
            config.button.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
            config.button.baseOffset = vec3(buttonSpacing, 0, 0)
        end
        xOffset = xOffset + (config.config.width or 80) + buttonSpacing
    end
end

return UIManager
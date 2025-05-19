----------------------------------------------------------------------------------------------------------------
-- menuBars.lua - Module for rendering the left and right menu panels at the top of the screen
----------------------------------------------------------------------------------------------------------------

local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local model = mjrequire "common/model"

local menuBars = {}
local leftMenuPanel = nil
local rightMenuPanel = nil

function menuBars:initLeftMenuPanel(parentView)    
    local leftMenuPanelSize = vec2(700.0, 50.0)
    local panelScaleToUseX = 350 --leftMenuBarPanelSize.x * 0.5
    local panelScaleToUseY = 58 --leftMenuBarPanelSize.y * 0.5 / 0.15--* 0.5
    local panelViewModel = "menuBar" --"ui_panel_10x2"
    local panelViewBaseOffset = vec3(0.0, 0.0, 0.0)
    local panelViewScale3D = vec3(panelScaleToUseX, panelScaleToUseY, 58)--52panelScaleToUseX-30)--panelScaleToUseX)
    local panelViewAlpha = 0.9

    leftMenuPanel = ModelView.new(parentView)
    leftMenuPanel:setModel(model:modelIndexForName(panelViewModel))
    leftMenuPanel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    leftMenuPanel.baseOffset = panelViewBaseOffset
    leftMenuPanel.scale3D = panelViewScale3D
    leftMenuPanel.size = leftMenuPanelSize
    leftMenuPanel.alpha = panelViewAlpha

    --Return the configured leftMenuPanel object
    return leftMenuPanel
end

function menuBars:initRightMenuPanel(parentView)    
    local rightMenuPanelSize = vec2(700.0, 50.0)
    local panelScaleToUseX = 350 --leftMenuBarPanelSize.x * 0.5
    local panelScaleToUseY = 58 --leftMenuBarPanelSize.y * 0.5 / 0.15--* 0.5
    local panelViewModel = "menuBar" --"ui_panel_10x2"
    local panelViewBaseOffset = vec3(0.0, 0.0, 0.0)
    local panelViewScale3D = vec3(panelScaleToUseX, panelScaleToUseY, 58)--52panelScaleToUseX-30)--panelScaleToUseX)
    local panelViewAlpha = 0.9

    rightMenuPanel = ModelView.new(parentView)
    rightMenuPanel:setModel(model:modelIndexForName(panelViewModel))
    rightMenuPanel.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    rightMenuPanel.baseOffset = panelViewBaseOffset
    rightMenuPanel.scale3D = panelViewScale3D
    rightMenuPanel.size = rightMenuPanelSize
    rightMenuPanel.alpha = panelViewAlpha

    --Return the configured leftMenuPanel object
    return rightMenuPanel
end

return menuBars
--TimeControlsPlus
--Mod for displaying the current year, day and season alongside the vanilla in-game time control.
--
--Author: chillgenxer@gmail.com
--@ChillGenXer

--Imports
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local material = mjrequire "common/material"

--Default mod load order
local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    local superTimeControls = timeControls.init

    timeControls.init = function(timeControls_, gameUI_, world_)
        
        --Run the vanilla control first before our code.  Our changes will be additive to the existing ones.
	    superTimeControls(timeControls_, gameUI_, world_)

        local function getSeason()
        --Calculate which season it is.
--[[          
            local season = {
                treeModel = nil,
                seasonText = nil
            }

        ]]
        --TODO Add southern hemisphere check.  Not sure where to get it properly, had a few crashes
           local seasonFraction = math.fmod(world_.yearSpeed * world_:getWorldTime(), 1.0)
           
           --0.0 is spring, 0.25 summer, 0.5 is autumn, >0.75 winter.  There's probably a more elegant
           --way to do this.
           if (seasonFraction >= 0) and (seasonFraction < 0.25) then
                return "appleTreeSpring"
            elseif (seasonFraction >= 0.25) and (seasonFraction < 0.50) then
                return "appleTree"
            elseif (seasonFraction >= 0.50) and (seasonFraction < 0.75) then
                return "appleTreeAutumn"
            else
                return "appleTreeWinter"
            end
        end

        --Custom UI components for displaying the additional information.

        --Dimensions of the UI objects
        local panelSizeToUse = vec2(110.0, 61.0)                --Added 1 more than the time control as the edge is a little bumpy and this creates a better seam
        local circleViewSize = 60.0
        local seasonTreeImageSize = 14.0

        --Positioning things - vec3(x, y, z)
        local offsetFromGamePanel = 206.0                       --The offset from the vanilla timeControl panel 
        local myPanelBaseOffset = vec3(0, 0.0, -2)              --offset for the invisible anchor panel I will attach the rest of my objects to
        local yearBaseOffset = vec3(12,50,0)                    --offset for the year text control.
        local dayBaseOffset = vec3(12,34,0)                     --offset for the day text control.
        local seasonCircleBaseOffset = vec3(75.0, 60.0, 1.0)    --offset for the circle panel bookend
        local seasonTreeBaseOffset = vec3(27.0, 13.0, 1.02)      --offset for the seasonal tree icon

        --Scaling
        local circleBackgroundScale = circleViewSize * 0.5
        local seasonTreeImageScale = seasonTreeImageSize * 0.5
        local panelScaleToUseX = panelSizeToUse.x * 0.5
        local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2

        --UI anchor to the main game screen.  This is invisible and will be used to attach the new visible components.
        myMainView = View.new(gameUI_.view)
        myMainView.hidden = false
        myMainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myMainView.baseOffset = vec3(offsetFromGamePanel, -10.0, 0.0)
        myMainView.size = panelSizeToUse

        --Circular Model to hold the tree icon
        local seasonCircleBack = ModelView.new(myMainView)
        seasonCircleBack:setModel(model:modelIndexForName("ui_circleBackgroundLargeOutline",
        {
            [material.types.ui_background.index] = material.types.ui_background_blue.index,
            [material.types.ui_standard.index] = material.types.ui_selected.index
        }))
        seasonCircleBack.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonCircleBack.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
        seasonCircleBack.size = vec2(circleViewSize, circleViewSize)
        seasonCircleBack.baseOffset = seasonCircleBaseOffset
        seasonCircleBack.alpha = 0.70

        --The background panel for the text.  It is snuggled up to the rightmost edge of the vanilla time control
        local myPanelView = ModelView.new(myMainView)
        myPanelView:setModel(model:modelIndexForName("ui_panel_10x2"))
        myPanelView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myPanelView.relativeView = myMainView
        myPanelView.baseOffset = myPanelBaseOffset
        myPanelView.scale3D = vec3(panelScaleToUseX,panelScaleToUseY,panelScaleToUseX)
        myPanelView.size = panelSizeToUse
        myPanelView.alpha = 0.9     --This affects transparency.
       
        --A ModelView to show the tree to represent the season
        local seasonTreeImage = ModelView.new(myPanelView)
        seasonTreeImage:setModel(model:modelIndexForName("appleTreeAutumn"))
        seasonTreeImage.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTreeImage.scale3D = vec3(seasonTreeImageScale,seasonTreeImageScale,seasonTreeImageScale)
        seasonTreeImage.size = vec2(seasonTreeImageSize, seasonTreeImageSize)
        seasonTreeImage.baseOffset = seasonTreeBaseOffset
        seasonTreeImage.relativeView = seasonCircleBack
        seasonTreeImage.alpha = 1.0
        seasonTreeImage.update = function(dt)
            --Update the image based on what season it is.
            seasonTreeImage:setModel(model:modelIndexForName(getSeason()))
        end

        --The year text, and the update function to keep it refreshed with the correct value
        yearTextView = TextView.new(myPanelView)
        yearTextView.font = Font(uiCommon.fontName, 16)
        yearTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        yearTextView.relativeView = myPanelView
        yearTextView.baseOffset = yearBaseOffset
        --Is this the best way to keep these updated in near-real time?  I really am not even sure how this works and what "dt" is... Server ticks?
        yearTextView.update = function(dt)
            yearTextView.text = "Year " .. tostring(math.floor(math.floor(world_:getWorldTime()/world_:getDayLength())/8) + 1)
        end

        --The day of year text, and the update function to keep it refreshed with the correct value
        dayTextView = TextView.new(myPanelView)
        dayTextView.font = Font(uiCommon.fontName, 16)
        dayTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        dayTextView.relativeView = myPanelView
        dayTextView.baseOffset = dayBaseOffset
        dayTextView.update = function(dt)
            --Calculate the day of the year.
            dayTextView.text = "Day  " .. tostring((math.floor(world_:getWorldTime()/world_:getDayLength())) % 8 + 1)
        end
    end
end

return mod

--Is this related to my code?  Not sure how this is getting impacted by what I have implemented here.
--It seems to be after playing for a long time period, memory leak somewhere maybe?
--
--Resolved!  Fix was introduced in Sapiens 0.3.7
--
--[[
4724.299898:Exception calling lua function logicinterface.cpp:409 ...on/Sapiens/GameResources/scripts/common/notification.lua:238: attempt to index field 'userData' (a nil value)
    stack traceback:
        ...on/Sapiens/GameResources/scripts/common/notification.lua:238: in function 'titleFunction'
        .../GameResources/scripts/mainThread/ui/notificationsUI.lua:283: in function 'displayNotificationWithInfo'
        .../GameResources/scripts/mainThread/ui/notificationsUI.lua:352: in function 'displayObjectNotification'
        ...iens/GameResources/scripts/mainThread/logicInterface.lua:273: in function <...iens/GameResources/scripts/mainThread/logicInterface.lua:255>
--]]
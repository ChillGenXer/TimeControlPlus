--timeControlsPlus
--Mod for displaying the current year, day and season alongside the vanilla in-game time control.
--Author: chillgenxer@gmail.com

--All the imports from the original, clean up what you don't need
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local mat3Rotate = mjm.mat3Rotate
local mat3Identity = mjm.mat3Identity
local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local weather = mjrequire "common/weather"
local gameConstants = mjrequire "common/gameConstants"
local audio = mjrequire "mainThread/audio"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
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

        --Custom views for displaying the additional information.
        
        --Dimensions of the UI objects
        local panelSizeToUse = vec2(110.0, 61.0)
        local circleViewSize = 60.0
        local circuleBackSize = 60.0
        local offsetFromGamePanel = 206.0 --The offset from the vanilla timeControl panel       
              
        --Positioning things - vec3(x, y, z)
        local myPanelBaseOffset = vec3(0, 0.0, -2)              --offset for the invisible anchor panel I will attach the rest of my objects to
        local yearBaseOffset = vec3(12,50,0)                    --offset for the year text control.
        local dayBaseOffset = vec3(12,34,0)                     --offset for the day text control.
        local seasonBaseOffset = vec3(15,25,0)                  --offset for the season image control.
        local seasonCircleBaseOffset = vec3(75.0, 59.0, 1.0)    --offset for the circle panel bookend
        local seasonCircleBackBaseOffset = vec3(75.0, 59.0, 10.0)
        local seasonTreeBaseOffset = vec3(90.0, 26.0, 20.0)     --offset for the seasonal tree icon

        local skyBlue = vec3(0.05,0.2,0.0)
        --Scaling
        local circleBackgroundScale = circleViewSize * 0.48     --Not sure how this works but played with this number till it lined up
        local seasonTreeImageScale = circleViewSize * 0.11
        --These are legacy from the code in the vanilla timeControls implementation.  I am not sure when the flexibility they bring is used
        local panelScaleToUseX = panelSizeToUse.x * 0.5
        local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2

        --UI anchor to the main game screen.  This is invisible and will be used to attach the new visible components.
        myMainView = View.new(gameUI_.view)
        myMainView.hidden = false
        myMainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myMainView.baseOffset = vec3(offsetFromGamePanel, -10.0, 0.0)
        myMainView.size = panelSizeToUse


        local function mat(key, color, roughness, metal)
            return {key = key, color = color, roughness = roughness, metal = metal or 0.0}
        end

        --White background for the circular panel
        local seasonCircleBack = ModelView.new(myMainView)
        seasonCircleBack:setModel(model:modelIndexForName("ui_circleBackgroundLargeOutline",
        {
            [material.types.ui_background.index] = material.types.ui_background_blue.index,
            [material.types.ui_standard.index] = material.types.ui_selected.index,
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
        seasonTreeImage.size = vec2(circleViewSize, circleViewSize)
        seasonTreeImage.baseOffset = seasonTreeBaseOffset
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
        --Is this the best way to keep these updated in near-real time?  I really am not even sure how this works and what dt is :)  Server ticks?
        yearTextView.update = function(dt)
            yearTextView.text = "Year " .. tostring(math.floor(math.floor(world_:getWorldTime()/world_:getDayLength())/8) + 1)
        end

        --The day text, and the update function to keep it refreshed with the correct value
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

--[[      
        --Circlular panel to create a bookend to the clock icon on the vanilla time control
        local seasonCircle = ModelView.new(myMainView)
        seasonCircle:setModel(model:modelIndexForName("ui_circleBackgroundSmall"))
        seasonCircle.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonCircle.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
        seasonCircle.size = vec2(circuleBackSize, circuleBackSize)
        seasonCircle.baseOffset = seasonCircleBackBaseOffset
        seasonCircle.alpha = 0.9
--]]


        --[[
        --Circlular backdrop for the tree
        local seasonBackgroundCircle = ModelView.new(myPanelView)
        seasonBackgroundCircle:setModel(model:modelIndexForName("timeControlSeasonBackground"), {
            [material.types.ui_background.index] = backgroundMaterialText,
            [material.types.ui_background.color] = vec3(0.05,0.2,0.4),
            [material.types.ui_standard.index] = materialCircle
            --[material.types.timeControlSeasonBackground.color] = vec3(0.05,0.2,0.4),
            --[material.types.timeControlSeasonBackground.metal] = 1.0
        })
        seasonBackgroundCircle.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonBackgroundCircle.relativeView = seasonCircle
        seasonBackgroundCircle.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
        seasonBackgroundCircle.size = vec2(circleViewSize, circleViewSize)
        --seasonBackgroundCircle.baseOffset = seasonBackgroundCircleBaseOffset
        seasonBackgroundCircle.alpha = 0.9
        --]]



--Is this related to my code?  Not sure how this is getting impacted by what I have implemented here.
--It seems to be after playing for a long time period, memory leak somewhere maybe?

--[[
4724.299898:Exception calling lua function logicinterface.cpp:409 ...on/Sapiens/GameResources/scripts/common/notification.lua:238: attempt to index field 'userData' (a nil value)
    stack traceback:
        ...on/Sapiens/GameResources/scripts/common/notification.lua:238: in function 'titleFunction'
        .../GameResources/scripts/mainThread/ui/notificationsUI.lua:283: in function 'displayNotificationWithInfo'
        .../GameResources/scripts/mainThread/ui/notificationsUI.lua:352: in function 'displayObjectNotification'
        ...iens/GameResources/scripts/mainThread/logicInterface.lua:273: in function <...iens/GameResources/scripts/mainThread/logicInterface.lua:255>
--]]

--At this point there isn't text with the season name.  Hoping just using the icon will be enough to avoid clutter on the UI.
--[[
        seasonTextView = TextView.new(myPanelView)
        seasonTextView.font = Font(uiCommon.fontName, 18)
        seasonTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTextView.relativeView = myPanelView
        seasonTextView.baseOffset = seasonBaseOffset
        seasonTextView.update = function(dt)
            --Update the season text
            --seasonTextView.text = "Implement this if you are uncommenting this section"
        end
--]]
--- TimeControlsPlus: timeControls.lua
--- @author ChillGenXer
--Mod for displaying a calendar and time in Sapiens.

--Imports
local mjm = mjrequire "common/mjm"
local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local material = mjrequire "common/material"
local localPlayer = mjrequire "mainThread/localPlayer"

local vec2 = mjm.vec2
local vec3 = mjm.vec3
local dot = mjm.dot

--Other Variables
local currentSeason = nil
local timeUTCLabel = "CT"
local updateInterval = 1                                --Set the tree to only update on this update interval
local timeAccumulator = 0                               --Accumulator for reducing UI updates
local myPanelAccumulator = 0
local yearTextAccumulator = 0
local dayTextAccumulator = 0
local timeTextAccumulator = 0

--Default mod load order
local mod = {
    loadOrder = 1
}

function mod:onload(timeControls)
    local super_timeControls = timeControls.init

    timeControls.init = function(timeControls_, gameUI_, world_)
        
        --Run the vanilla control first before our code.  Our changes will be additive to the existing UI.
	    super_timeControls(timeControls_, gameUI_, world_)
        
        ---Calculate which season it is.
        local function getSeason()
            
            --Object to hold the attributes
            local seasonObject = {
                treeModel = nil,
                seasonText = nil
            }

            --Get the players position to determine if they are in the southern hemisphere
            local playerPosition = localPlayer:getPos()
            local isSouthHemisphere = dot(playerPosition, vec3(0.0,1.0,0.0)) < 0.0

            --Calculate the seasonal fraction. 0.0 is spring, 0.25 summer, 0.5 is autumn, >0.75 winter.
            local seasonFraction = math.fmod(world_.yearSpeed * world_:getWorldTime(), 1.0)
            
            --Lookup table for getting the right tree model and text.
            local seasonLookupTable = {
                {
                    treeModel = { "appleTreeSpring", "appleTreeAutumn" },
                    seasonText = { "Spring", "Autumn" }
                },
                {
                    treeModel = { "appleTree", "appleTreeWinter" },
                    seasonText = { "Summer", "Winter" }
                },
                {
                    treeModel = { "appleTreeAutumn", "appleTreeSpring" },
                    seasonText = { "Autumn", "Spring" }
                },
                {
                    treeModel = { "appleTreeWinter", "appleTree" },
                    seasonText = { "Winter", "Summer" }
                }
            }
            
            --Get the index & HemisphereOffset we need for the lookup table
            local index = math.floor(seasonFraction * 4) % 4 + 1
            local hemisphereOffset = isSouthHemisphere and 2 or 1
            
            --Set the season object
            seasonObject.treeModel = seasonLookupTable[index].treeModel[hemisphereOffset]
            seasonObject.seasonText = seasonLookupTable[index].seasonText[hemisphereOffset]

            return seasonObject
        end

        --Custom UI components for displaying calendar information.
        
        --UI Components
        local myMainView = nil                                  --Invisible anchor to the GameUI
        local seasonCircleBack = nil                            --Circle the tree icon sits inside of
        local myPanelView = nil                                 --Panel where year, day and time are displayed
        local seasonTreeImage = nil                             --The tree season icon
        local yearTextView = nil                                --The year label
        local dayTextView = nil                                 --The day label
        local timeClockText = nil                               --The digital clock
        local timeClockUTCLabel = nil                           --UTC label. Seperate so it doesn't bounce around when the clock is updating

        --Dimensions of the UI objects
        local panelSizeToUse = vec2(110.0, 61.0)                --Added 1 more than the time control as the edge is a little bumpy and this creates a better seam
        local circleViewSize = 60.0                             --Size of the circle the tree sits in
        local seasonTreeImageSize = 14.0                        --Size of the model

        --Positioning things - vec3(x, y, z)
        local offsetFromGamePanel = 206.0                       --The offset from the vanilla timeControl panel 
        local myPanelBaseOffset = vec3(0, 0.0, -2)              --offset for the invisible anchor panel I will attach the rest of my objects to
        local yearBaseOffset = vec3(12,58,0)                    --offset for the year text control.
        local dayBaseOffset = vec3(13,42,0)                     --offset for the day text control.
        local timeClockTextBaseOffset = vec3(13,20,0)            --offset for the clock
        local timeClockUTCLabelBaseOffset = vec3(45,20,0)       --offset for the clock time UTC Label
        local seasonCircleBaseOffset = vec3(75.0, 59.0, 0.1)    --offset for the circle panel bookend
        local seasonTreeBaseOffset = vec3(30.0, 10.0, 5.02)     --offset for the seasonal tree icon
        local toolTipOffset = vec3(0,-10,0)                     --offset for tooltips

        --3D Scaling
        local panelScaleToUseX = panelSizeToUse.x * 0.5
        local panelScaleToUseY = panelSizeToUse.y * 0.5 / 0.2
        local circleBackgroundScale = circleViewSize * 0.5
        local seasonTreeImageScale = seasonTreeImageSize * 0.5

        --UI anchor to the main game screen.  This is invisible and will be used to attach the new visible components.
        myMainView = View.new(gameUI_.view)
        myMainView.hidden = false
        myMainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myMainView.baseOffset = vec3(offsetFromGamePanel, -10.0, 0.0)
        myMainView.size = panelSizeToUse

        --Circular Model to hold the tree icon
        seasonCircleBack = ModelView.new(myMainView)
        seasonCircleBack:setModel(model:modelIndexForName("ui_circleBackgroundLargeOutline" ,
        {
            [material.types.ui_background.index] = material.types.ui_background_blue.index,
            [material.types.ui_standard.index] = material.types.ui_selected.index
        }
        ))
        seasonCircleBack.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonCircleBack.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
        seasonCircleBack.size = vec2(circleViewSize, circleViewSize)
        seasonCircleBack.baseOffset = seasonCircleBaseOffset
        seasonCircleBack.alpha = 0.70

        --The background panel for the text.  It is snuggled up to the rightmost edge of the vanilla time control
        myPanelView = ModelView.new(myMainView)
        myPanelView:setModel(model:modelIndexForName("ui_panel_10x2"))
        myPanelView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        myPanelView.relativeView = myMainView
        myPanelView.baseOffset = myPanelBaseOffset
        myPanelView.scale3D = vec3(panelScaleToUseX,panelScaleToUseY,panelScaleToUseX)
        myPanelView.size = panelSizeToUse
        myPanelView.alpha = 0.9     --This affects transparency.
        uiToolTip:add(myPanelView, ViewPosition(MJPositionCenter, MJPositionBelow), "", nil, toolTipOffset, nil, myPanelView)
        myPanelView.update = function(dt)
            myPanelAccumulator = myPanelAccumulator + dt
            if myPanelAccumulator >= updateInterval then           -- Check if our target update time has been reached
                myPanelAccumulator = 0                                 -- Reset the interval
                local season = getSeason()
                uiToolTip:updateText(myPanelView, season.seasonText, nil, false)
            end

        end

        --A ModelView to show the tree to represent the season
        seasonTreeImage = ModelView.new(myPanelView)
        --seasonTreeImage = GameObjectView.new(myPanelView, vec2(128, 128)) --this second argument is the texture image size in pixels that the tree is rendered into
        seasonTreeImage.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTreeImage.scale3D = vec3(seasonTreeImageScale,seasonTreeImageScale,seasonTreeImageScale)
        seasonTreeImage.size = vec2(seasonTreeImageSize, seasonTreeImageSize)
        seasonTreeImage.baseOffset = seasonTreeBaseOffset
        seasonTreeImage.relativeView = seasonCircleBack
        seasonTreeImage.alpha = 1.0
        seasonTreeImage.update = function(dt)
            --Update the image based on what season it is.
            local season = getSeason()
            if currentSeason ~= season.seasonText then
                --mj:log("Registering New Season")
                currentSeason = season.seasonText
                seasonTreeImage:setModel(model:modelIndexForName(season.treeModel))
            end
        end

--[[        This is driving me nuts.  For new games it seems to work fine and I haven't seen any flickering but 
            I have an old save where I can reproduce this, and people still report it so it's a thing.  
Any advice how to swap out my ModelView with a GameObjectView?  I am trying but I am falling down the rabbit 
hole of the UI components and how they interact.  Here is how I am instantiating the tree now:

`        --A ModelView to show the tree to represent the season
        seasonTreeImage = ModelView.new(myPanelView)
        seasonTreeImage.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        seasonTreeImage.scale3D = vec3(seasonTreeImageScale,seasonTreeImageScale,seasonTreeImageScale)
        seasonTreeImage.size = vec2(seasonTreeImageSize, seasonTreeImageSize)
        seasonTreeImage.baseOffset = seasonTreeBaseOffset
        seasonTreeImage.relativeView = seasonCircleBack
        seasonTreeImage.alpha = 1.0
        seasonTreeImage.update = function(dt)
            --Update the image based on what season it is.
            local season = getSeason()
            if currentSeason ~= season.seasonText then
                --mj:log("Registering New Season")
                currentSeason = season.seasonText
                seasonTreeImage:setModel(model:modelIndexForName(season.treeModel))
            end
        end
` ]]

        --The year text, and the update function to keep it refreshed with the correct value
        yearTextView = TextView.new(myPanelView)
        yearTextView.font = Font(uiCommon.fontName, 15)
        yearTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        yearTextView.relativeView = myPanelView
        yearTextView.baseOffset = yearBaseOffset
        --Is this the best way to keep these updated in near-real time?  I really am not even sure how this works and what "dt" is... Server ticks?
        yearTextView.update = function(dt)
            yearTextAccumulator = yearTextAccumulator + dt
            if yearTextAccumulator >= updateInterval then               -- Check if our target update time has been reached
                yearTextAccumulator = 0                                 -- Reset the interval
                yearTextView.text = "Year " .. tostring(math.floor(math.floor(world_:getWorldTime()/world_:getDayLength())/8) + 1)
            end
        end

        --The day of year text, and the update function to keep it refreshed with the correct value
        dayTextView = TextView.new(myPanelView)
        dayTextView.font = Font(uiCommon.fontName, 15)
        dayTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        dayTextView.relativeView = myPanelView
        dayTextView.baseOffset = dayBaseOffset
        dayTextView.update = function(dt)
            dayTextAccumulator = dayTextAccumulator + dt
            if dayTextAccumulator >= updateInterval then                -- Check if our target update time has been reached
                dayTextAccumulator = 0                                  -- Reset the interval
                --Calculate the day of the year.
                dayTextView.text = "Day  " .. tostring((math.floor(world_:getWorldTime()/world_:getDayLength())) % 8 + 1)
            end
        end

        --Digital Clock
        timeClockText = TextView.new(myPanelView)
        timeClockText.font = Font(uiCommon.fontName, 13)
        timeClockText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        timeClockText.relativeView = myPanelView
        timeClockText.baseOffset = timeClockTextBaseOffset
        timeClockText.update = function(dt)
            timeTextAccumulator = timeTextAccumulator + dt
            if timeTextAccumulator >= updateInterval then                                                           -- Check if our target update time has been reached
                timeTextAccumulator = 0                                                                             -- Reset the interval
                local secondsElapsedInDay = world_:getWorldTime() % world_:getDayLength()                           --How many real world seconds have elapsed in this day
                local gameHourInSeconds = world_:getDayLength()/24                                                  --Calculate this to future-proof for server owners changing it
                local gameMinuteInSeconds = world_:getDayLength()/1440                                              --Calculate how long a game minute is in real world seconds
                local gameTimeHour = math.floor(secondsElapsedInDay / gameHourInSeconds)                            --The hour to display
                local gameTimeMinute = math.floor((secondsElapsedInDay % gameHourInSeconds)/gameMinuteInSeconds)    --The minute to display
                --Format the clock digits to add a leading 0 and set the text field
                local txtGameTimeHour = string.format("%02d", gameTimeHour)
                local txtGameTimeMinute = string.format("%02d", gameTimeMinute)
                timeClockText.text = txtGameTimeHour .. ":" .. txtGameTimeMinute
            end
        end

        --UTC label for the clock
        timeClockUTCLabel = TextView.new(myPanelView)
        timeClockUTCLabel.font = Font(uiCommon.fontName, 11)
        timeClockUTCLabel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        timeClockUTCLabel.relativeView = myPanelView
        timeClockUTCLabel.baseOffset = timeClockUTCLabelBaseOffset
        timeClockUTCLabel.text = timeUTCLabel
    end
end

return mod
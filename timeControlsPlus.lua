--local world = mjrequire "mainThread/world"
--local mjm = mjrequire "common/mjm"

local worldTime = 1 --world:getWorldTime()
local dayLength = 1 --world:getDayLength()
local yearLength = 1 --world:getYearLength()
local worldAgeInDays = math.floor(worldTime/dayLength)
local currentYear = math.floor(worldAgeInDays/8) + 1 --Adding 1 to make the year counting start at 1
local currentDayOfYear = worldAgeInDays % 8 + 1

local timeControlsPlus = {}

function timeControlsPlus:getCurrentYear()
    --return tostring(currentYear)
    return "1972"
end

function timeControlsPlus:getDayOfYear()
    --return tostring(currentDayOfYear)
    return "22"
end

function timeControlsPlus:getSeason()
--Starting with a manual calculation that doesn't take the hemisphere into account
--local seasonFraction = logic:getSeasonFraction() -- 0.0 is spring equinox in north, 0.25 longest day, 0.5 is autumn, 0.75 winter. Offset by 0.5 for south.
    return "¯\\_(ツ)_/¯"
    --local SeasonIndex = 1 --weather:getSeason(world:getWorldTime(), world.yearSpeed, logic.playerPos)
    --[[
    if SeasonIndex == 1 then
        return "Spring"
    elseif SeasonIndex == 2 then
        return "Summer"
    elseif SeasonIndex == 3 then
        return "Autumn"
    elseif SeasonIndex == 4 then
        return "Winter"
    else
        return "¯\\_(ツ)_/¯"
    end
    --]]
end

return timeControlsPlus
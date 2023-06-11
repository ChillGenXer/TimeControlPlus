local typeMaps = mjrequire "common/typeMaps"
local notificationSound = mjrequire "common/notificationSound"

local mod = {
    loadOrder = 1,
}

function mod:onload(notification)
    mj:log("notification shadow start")
 
    typeMaps:insert("notification", notification.types, {
        key = "springStarting",
        titleFunction = function(notificationInfo)
            return "Spring has started."
        end,
        soundTypeIndex = notificationSound.types.springStarting.index,
    })

    typeMaps:insert("notification", notification.types, {
        key = "summerStarting",
        titleFunction = function(notificationInfo)
            return "Summer has started."
        end,
        soundTypeIndex = notificationSound.types.summerStarting.index,
    })

    typeMaps:insert("notification", notification.types, {
        key = "autumnStarting",
        titleFunction = function(notificationInfo)
            return "Autumn has started."
        end,
        soundTypeIndex = notificationSound.types.autumnStarting.index,
    })

    typeMaps:insert("notification", notification.types, {
        key = "winterStarting",
        titleFunction = function(notificationInfo)
            return "Winter has started."
        end,
        soundTypeIndex = notificationSound.types.winterStarting.index,
    })

    typeMaps:insert("notification", notification.types, {
        key = "newYear",
        titleFunction = function(notificationInfo)
            return "A New Year has started."
            --return "Year " .. notificationInfo.year .. "has started."
        end,
        soundTypeIndex = notificationSound.types.newYear.index,
    })

    mj:log("notification shadow end")

end

return mod
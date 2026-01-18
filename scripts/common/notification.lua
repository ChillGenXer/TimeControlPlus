local typeMaps = mjrequire "common/typeMaps"
local notificationSound = mjrequire "common/notificationSound"

local mod = {
    loadOrder = 1,
}

function mod:onload(notification)
--[[ TypeMaps for the notifications.  The new year notification is used instead of the spring notification in the northern hemisphere,
and the autumn one in the southern hemisphere.  They are included in the pairs regardless for consistency and possible future use. ]]

typeMaps:insert("notification", notification.types, {
    key = "springStarting",
    titleFunction = function(userData)
        return "Spring has started."
    end,
    soundTypeIndex = notificationSound.types.springStarting.index,
    displayGroupTypeIndex = notification.displayGroups.standard.index,
})

typeMaps:insert("notification", notification.types, {
    key = "summerStarting",
    titleFunction = function(userData)
        return "Summer has started."
    end,
    soundTypeIndex = notificationSound.types.summerStarting.index,
    displayGroupTypeIndex = notification.displayGroups.standard.index,
})

typeMaps:insert("notification", notification.types, {
    key = "autumnStarting",
    titleFunction = function(userData)
        return "Autumn has started."
    end,
    soundTypeIndex = notificationSound.types.autumnStarting.index,
    displayGroupTypeIndex = notification.displayGroups.standard.index,
})

typeMaps:insert("notification", notification.types, {
    key = "winterStarting",
    titleFunction = function(userData)
        return "Winter has started."
    end,
    soundTypeIndex = notificationSound.types.winterStarting.index,
    displayGroupTypeIndex = notification.displayGroups.standard.index,
})

typeMaps:insert("notification", notification.types, {
    key = "newYear",
    titleFunction = function(userData)
        local year = userData and userData.currentYear or "?"
        return "Year " .. tostring(year) .. " has begun."
    end,
    soundTypeIndex = notificationSound.types.newYear.index,
    displayGroupTypeIndex = notification.displayGroups.standard.index,
})

end

return mod

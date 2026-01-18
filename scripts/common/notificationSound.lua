local typeMaps = mjrequire "common/typeMaps"

local mod = {
    loadOrder = 1,
}

function mod:onload(notificationSound)
    --Currently using two unused sound files in the base game.
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "springStarting",
            path = "uncertain1.mp3",
        }
    )
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "summerStarting",
            path = "uncertain1.mp3",
        }
    )       
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "autumnStarting",
            path = "uncertain1.mp3",
        }
    )
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "winterStarting",
            path = "uncertain1.mp3",
        }
    )
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "newYear",
            path = "uncertain1.mp3",
        }
    )
end

return mod

local typeMaps = mjrequire "common/typeMaps"

local mod = {
    loadOrder = 1,
}

function mod:onload(notificationSound)
    mj:log("notificationSound Override")
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "springStarting",
            path = "percussive1_unused.wav",
        }
    )
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "summerStarting",
            path = "percussive1_unused.wav",
        }
    )       
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "autumnStarting",
            path = "percussive1_unused.wav",
        }
    )
    typeMaps:insert("notificationSound", notificationSound.types,
        {
            key = "winterStarting",
            path = "percussive1_unused.wav",
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

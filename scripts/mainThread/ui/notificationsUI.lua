-- imports and globals
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3

local mod = {
    loadOrder = 1
}

function mod:onload(notificationsUI)
    --mj:log("[TimeControlPlus] Shadow file for notificationsUI loaded")

    -- Store the original setPosition function
    --local superSetPosition = notificationsUI.setPosition

    -- Override the setPosition function
    notificationsUI.setPosition = function(self_, messageViewInfo)
        local aboveMessageInfo = notificationsUI.messageViewInfos[messageViewInfo.index - 1]
        local yOffset = -60.0
        if aboveMessageInfo then
            yOffset = aboveMessageInfo.backgroundView.baseOffset.y - aboveMessageInfo.backgroundView.size.y - 4
        else
            if messageViewInfo.fadeOutValue and messageViewInfo.fadeOutValue > 0.5 then
                local offsetMix = (messageViewInfo.fadeOutValue - 0.5) * 2.0
                offsetMix = math.pow(offsetMix, 0.7)
                yOffset = mjm.mix(-2, messageViewInfo.backgroundView.size.y - 10, offsetMix)
            end
        end
        messageViewInfo.backgroundView.baseOffset = vec3(-10, yOffset, -8)
    end

    -- Log the modified setPosition function
    --mj:log("[TimeControlPlus] Modified notificationsUI.setPosition:", tostring(notificationsUI.setPosition))

    return notificationsUI
end

return mod
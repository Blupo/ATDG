local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

return function(limits)
    local description = ""

    local playerLimit = limits[GameEnum.SpecialActionLimitType.PlayerLimit]
    local gameLimit = limits[GameEnum.SpecialActionLimitType.GameLimit]
    local playerCooldown = limits[GameEnum.SpecialActionLimitType.PlayerCooldown]
    local gameCooldown = limits[GameEnum.SpecialActionLimitType.GameCooldown]

    if (playerLimit) then
        description = description .. string.format(
            "%sYou can only use this action %s per game.",
            (description == "") and "" or "\n\n",
            (playerLimit == 1) and "once" or (playerLimit .. " times")
        )
    end

    if (gameLimit) then
        description = description .. string.format(
            "%sThis action can only be used %s per game, regardless of player.",
            (description == "") and "" or "\n\n",
            (gameLimit == 1) and "once" or (gameLimit .. " times")
        )
    end

    if (playerCooldown) then
        description = description .. string.format(
            "%sYou can only use this action every %d seconds.",
            (description == "") and "" or "\n\n",
            playerCooldown
        )
    end

    if (gameCooldown) then
        description = description .. string.format(
            "%sThis action can only be used every %d seconds, regardless of player.",
            (description == "") and "" or "\n\n",
            gameCooldown
        )
    end

    return description
end
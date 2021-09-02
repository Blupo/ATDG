local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

---

local PlayMenu = Roact.PureComponent:extend("PlayMenu")

PlayMenu.render = function(self)
end

return PlayMenu
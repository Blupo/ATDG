local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

---

local InventoryMenu = Roact.PureComponent:extend("InventoryMenu")

InventoryMenu.render = function(self)
end

return InventoryMenu
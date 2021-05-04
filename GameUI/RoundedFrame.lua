local root = script.Parent
local Roact = require(root:WaitForChild("Roact"))

---

local copy
copy = function(t)
    local tCopy = {}

    for k, v in pairs(t) do
        if (k ~= Roact.Children) then
            tCopy[k] = (type(v) == "table") and copy(v) or v
        end
    end

    tCopy[Roact.Children] = t[Roact.Children]
    return tCopy
end

---

local RoundedFrame = Roact.PureComponent:extend("RoundedFrame")

RoundedFrame.render = function(self)
    local props = copy(self.props)
    
    if (not props[Roact.Children]) then
        props[Roact.Children] = {}
    end

    props[Roact.Children]["UICorner"] = Roact.createElement("UICorner", {
        CornerRadius = UDim.new(self.props.radiusScale or 0, self.props.radiusOffset or 0)
    })

    props.radiusScale = nil
    props.radiusOffset = nil
    return Roact.createElement("Frame", props)
end

return RoundedFrame
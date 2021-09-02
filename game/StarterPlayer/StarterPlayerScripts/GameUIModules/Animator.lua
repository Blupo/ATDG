-- wrapper around an Otter motor and a Roact binding

local root = script.Parent

local Otter = require(root:WaitForChild("Otter"))
local Roact = require(root:WaitForChild("Roact"))

---

local shallowCopy = function(t)
    local copy = {}

    for k, v in pairs(t) do
        copy[k] = v
    end

    return copy
end

---

local Animator = {}

Animator.new = function(initialValues)
    local motor = Otter.createGroupMotor(shallowCopy(initialValues))
    local binding, updateBinding = Roact.createBinding(shallowCopy(initialValues))
    local disconnectOnStep = motor:onStep(updateBinding)

    return {
        Motor = motor,
        Binding = binding,
        Update = updateBinding,
        Disconnect = disconnectOnStep
    }
end

---

return Animator
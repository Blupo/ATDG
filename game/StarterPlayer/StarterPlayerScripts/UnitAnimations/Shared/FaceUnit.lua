return function(thisUnit, targetUnit)
    local thisUnitModel = thisUnit.Model
    local targetUnitModel = targetUnit.Model
    if (not (thisUnitModel and targetUnitModel)) then return end

    local thisUnitModelPrimaryPart = thisUnitModel.PrimaryPart
    local targetUnitModelPrimaryPart = targetUnitModel.PrimaryPart
    if (not (thisUnitModelPrimaryPart and targetUnitModelPrimaryPart)) then return end

    thisUnitModel:SetPrimaryPartCFrame(CFrame.lookAt(
        thisUnitModelPrimaryPart.Position,
        Vector3.new(targetUnitModelPrimaryPart.Position.X, thisUnitModelPrimaryPart.Position.Y, targetUnitModelPrimaryPart.Position.Z)
    ))
end
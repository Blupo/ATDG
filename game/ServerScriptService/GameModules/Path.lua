local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService(("ServerScriptService"))
local Workspace = game:GetService("Workspace")

---

local Paths = Workspace:WaitForChild("Paths")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Unit = require(GameModules:FindFirstChild("Unit"))

local PursuitBeganEvent = Instance.new("BindableEvent")
local PursuitEndedEvent = Instance.new("BindableEvent")

---

export type PursuitInfo = {
    Path: number,
    Progress: number,
    AbsoluteProgress: number,
    Direction: string,
    
    NextWaypoint: number,
    Paused: boolean,
}

local activePursuits: {[string]: PursuitInfo} = {}

local getPathDistance = function(pathNumber: number, pathType: string, direction: string?, upToWaypoint: number?): number
    direction = direction or GameEnum.PursuitDirection.Forward 
        
    local waypoints = Paths:FindFirstChild(pathType):FindFirstChild(pathNumber)
    if (not waypoints) then return -1 end
    
    local distance = 0
    
    if (direction == GameEnum.PursuitDirection.Forward) then
        for i = 0, (upToWaypoint or (#waypoints:GetChildren() - 2)) do
            local waypoint = waypoints:FindFirstChild(tostring(i))
            local nextWaypoint = waypoints:FindFirstChild(tostring(i + 1))
            
            distance = distance + (nextWaypoint.Position - waypoint.Position).Magnitude
        end
    else
        for i = (#waypoints:GetChildren() - 1), (upToWaypoint or 1), -1 do
            local waypoint = waypoints:FindFirstChild(tostring(i))
            local nextWaypoint = waypoints:FindFirstChild(tostring(i - 1))

            distance = distance + (nextWaypoint.Position - waypoint.Position).Magnitude
        end
    end
    
    return distance
end

---

local Path = {
    PursuitBegan = PursuitBeganEvent.Event,
    PursuitEnded = PursuitEndedEvent.Event,
}

Path.GetPursuitInfo = function(unit): PursuitInfo?
    return activePursuits[unit.Id]
end

Path.PursuePath = function(unit, pathNumber: number, direction: string?)
    direction = direction or GameEnum.PursuitDirection.Forward
    
    if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return end
    if (activePursuits[unit.Id] ~= nil) then return end
    
    local waypoints = Paths:FindFirstChild(unit:GetAttribute("PathType")):FindFirstChild(pathNumber)
    if (not waypoints) then return end
    
    local unitModel = unit.Model
    local boundingPart = unitModel:FindFirstChild("_BoundingPart")
    local heightOffset = boundingPart.Size.Y / 2

    local boundingPartAttachment = Instance.new("Attachment")
    local waypointAttachment = Instance.new("Attachment")
    local boundingPartAlignPosition = Instance.new("AlignPosition")
    local boundingPartAlignOrientation = Instance.new("AlignOrientation")

    local firstWaypointNum = (direction == GameEnum.PursuitDirection.Forward) and 0 or (#waypoints:GetChildren() - 1)
    local secondWaypointNum = firstWaypointNum + ((direction == GameEnum.PursuitDirection.Forward) and 1 or -1)
    
    local unitSPDChanged = unit.AttributeChanged:Connect(function(attributeName: string, newValue: any)
        if (attributeName ~= "SPD") then return end
        
        boundingPartAlignPosition.MaxVelocity = newValue
        boundingPartAlignOrientation.MaxAngularVelocity = newValue
    end)
    
    local setWaypointAttachmentWorldCFrame = function(thisWaypoint, nextWaypoint)
        local thisWaypointPart = waypoints:FindFirstChild(tostring(thisWaypoint))
        local nextWaypointPart = waypoints:FindFirstChild(tostring(nextWaypoint))
        
        -- rotate waypointAttachment so that the Unit is facing the right way
        local nextWaypointPosOffset = nextWaypointPart.Position - thisWaypointPart.Position

        if ((math.abs(nextWaypointPosOffset.X) + math.abs(nextWaypointPosOffset.Z)) > 0) then
            waypointAttachment.WorldCFrame = CFrame.lookAt(
                thisWaypointPart.Position,
                Vector3.new(nextWaypointPart.Position.X, thisWaypointPart.Position.Y, nextWaypointPart.Position.Z)
            ) + nextWaypointPosOffset + Vector3.new(0, heightOffset, 0)
        else
            waypointAttachment.Position = Vector3.new(0, heightOffset, 0)
        end
    end
    
    waypointAttachment.Name = unit.Id .. "_PursuitAttachment"
    waypointAttachment.Position = Vector3.new(0, heightOffset, 0)
    waypointAttachment.Parent = waypoints:FindFirstChild(tostring(secondWaypointNum))

    boundingPartAttachment.Name = "PursuitAttachment"
    boundingPartAttachment.Parent = boundingPart

    boundingPartAlignPosition.RigidityEnabled = false
    boundingPartAlignPosition.MaxForce = 10000
    boundingPartAlignPosition.Responsiveness = 200
    boundingPartAlignPosition.MaxVelocity = unit:GetAttribute("SPD")
    boundingPartAlignPosition.Attachment0 = boundingPartAttachment
    boundingPartAlignPosition.Attachment1 = waypointAttachment
    boundingPartAlignPosition.Parent = boundingPart
    
    boundingPartAlignOrientation.RigidityEnabled = false
    boundingPartAlignOrientation.MaxTorque = 10000
    boundingPartAlignOrientation.Responsiveness = 200
    boundingPartAlignOrientation.MaxAngularVelocity = unit:GetAttribute("SPD")
    boundingPartAlignOrientation.Attachment0 = boundingPartAttachment
    boundingPartAlignOrientation.Attachment1 = waypointAttachment
    boundingPartAlignOrientation.Parent = boundingPart
    
    setWaypointAttachmentWorldCFrame(firstWaypointNum, secondWaypointNum)
    boundingPart:SetNetworkOwner(nil)
    boundingPart.CFrame = CFrame.new(waypoints:FindFirstChild(tostring(firstWaypointNum)).Position) + Vector3.new(0, heightOffset, 0)
    
    activePursuits[unit.Id] = {
        Path = pathNumber,
        Progress = 0,
        AbsoluteProgress = 0,
        Direction = direction,
        
        NextWaypoint = secondWaypointNum,
        Paused = false,
    }
    
    coroutine.resume(coroutine.create(function()
        local cleanup = function(destinationReached)
            local pursuitInfo = activePursuits[unit.Id]
            
            unitSPDChanged:Disconnect()
            boundingPartAlignPosition:Destroy()
            boundingPartAlignOrientation:Destroy()
            boundingPartAttachment:Destroy()
            waypointAttachment:Destroy()

            activePursuits[unit.Id] = nil
            PursuitEndedEvent:Fire(unit.Id, destinationReached, pursuitInfo and pursuitInfo.Direction or nil)
        end
        
        while (activePursuits[unit.Id]) do            
            local pursuitInfo = activePursuits[unit.Id]
            
            if (pursuitInfo.Paused) then
                RunService.Heartbeat:Wait()
            else
                local originalDirection = pursuitInfo.Direction
                
                boundingPartAlignPosition.Enabled = true
                boundingPartAlignOrientation.Enabled = true
                
                Promise.new(function(resolve)
                    while (
                        activePursuits[unit.Id] and -- pursuit is abandoned
                        (not pursuitInfo.Paused) and -- pursuit is paused
                        (originalDirection == pursuitInfo.Direction) -- direction changes
                    ) do
                        if (boundingPartAttachment.WorldPosition:FuzzyEq(waypointAttachment.WorldPosition, 10E-4)) then
                            resolve(true)
                            return
                        end
                        
                        RunService.Heartbeat:Wait()
                    end
                    
                    resolve(false)
                end):andThen(function(waypointReached)
                    if (not activePursuits[unit.Id]) then
                        cleanup(false)
                    end
                    
                    if (waypointReached) then
                        if (
                            (
                                (pursuitInfo.NextWaypoint == (#waypoints:GetChildren() - 1)) and 
                                (pursuitInfo.Direction == GameEnum.PursuitDirection.Forward)
                            ) or (
                                (pursuitInfo.NextWaypoint == 0) and 
                                (pursuitInfo.Direction == GameEnum.PursuitDirection.Reverse)
                            )
                        ) then
                            -- done
                            cleanup(true)
                        else
                            local thisWaypoint = pursuitInfo.NextWaypoint
                            local nextWaypoint = thisWaypoint + ((pursuitInfo.Direction == GameEnum.PursuitDirection.Forward) and 1 or -1)
                            
                            pursuitInfo.NextWaypoint = nextWaypoint
                            waypointAttachment.Parent = waypoints:FindFirstChild(tostring(nextWaypoint))
                            setWaypointAttachmentWorldCFrame(thisWaypoint, nextWaypoint)
                        end
                    elseif (pursuitInfo.Paused) then
                        boundingPartAlignPosition.Enabled = false
                        boundingPartAlignOrientation.Enabled = false
                    end
                end):await()
            end
        end
    end))
    
    PursuitBeganEvent:Fire(unit.Id)
end

Path.SwitchPursuitDirection = function(unit)
    if (not activePursuits[unit.Id]) then return end
    
    local oldDirection = activePursuits[unit.Id].Direction
    
    activePursuits[unit.Id].Direction = (oldDirection == GameEnum.PursuitDirection.Forward) and
        GameEnum.PursuitDirection.Reverse
    or GameEnum.PursuitDirection.Forward 
end

Path.PausePursuit = function(unit)
    if (not activePursuits[unit.Id]) then return end
    
    activePursuits[unit.Id].Paused = true
end

Path.ResumePursuit = function(unit)
    if (not activePursuits[unit.Id]) then return end

    activePursuits[unit.Id].Paused = false
end

Path.StopPursuit = function(unit)
    if (not activePursuits[unit.Id]) then return end
    
    activePursuits[unit.Id] = nil
    PursuitEndedEvent:Fire(unit.Id, false)
end

---

Unit.UnitRemoving:Connect(function(unitId)
    local unit = Unit.fromId(unitId)
    if (not Path.GetPursuitInfo(unit)) then return end
    
    Path.StopPursuit(unit)
end)

coroutine.resume(coroutine.create(function()
    while true do
        for id, pursuitInfo in pairs(activePursuits) do
            if (not pursuitInfo.Paused) then
                local unit = Unit.fromId(id)
                local pathType = unit:GetAttribute("PathType")
                
                local unitModel = unit.Model
                local boundingBoxCFrame, boundingBoxSize = unitModel:GetBoundingBox()
                local currentPosition = boundingBoxCFrame.Position - Vector3.new(0, boundingBoxSize.Y / 2, 0)

                local waypoints = Paths:FindFirstChild(pathType):FindFirstChild(tostring(pursuitInfo.Path))
                local pathDistance = getPathDistance(pursuitInfo.Path, pathType)
                
                local nextWaypoint = pursuitInfo.NextWaypoint
                local currentWaypoint = nextWaypoint + ((pursuitInfo.Direction == GameEnum.PursuitDirection.Forward) and -1 or 1)
                local currentWaypointPosition = waypoints:FindFirstChild(tostring(currentWaypoint)).Position
                local distanceUpToLastWaypoint = getPathDistance(pursuitInfo.Path, pathType, pursuitInfo.Direction,
                    nextWaypoint + ((pursuitInfo.Direction == GameEnum.PursuitDirection.Forward) and -2 or 2))                
                
                pursuitInfo.Progress = (distanceUpToLastWaypoint + (currentPosition - currentWaypointPosition).Magnitude) / pathDistance
                pursuitInfo.AbsoluteProgress = (pursuitInfo.Direction == GameEnum.PursuitDirection.Forward) and pursuitInfo.Progress or (1 - pursuitInfo.Progress)
            end
        end
        
        RunService.Stepped:Wait()
    end
end))

return Path
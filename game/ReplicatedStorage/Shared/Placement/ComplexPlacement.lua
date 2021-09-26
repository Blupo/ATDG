local AABB = require(script.Parent:WaitForChild("AABB"))
local WorldBoundingBox = require(script.Parent:WaitForChild("WorldBoundingBox"))

---

local ZERO = Vector3.new(0, 0, 0)

local getOverlap = function(cfA: CFrame, sizeA: Vector3, cfB: CFrame, sizeB: Vector3): number
    local rbCF = cfA:Inverse() * cfB
    local A = AABB.fromPositionSize(ZERO, sizeA)
    local B = AABB.fromPositionSize(rbCF.Position, WorldBoundingBox(rbCF, sizeB))

    local union = A:Union(B)
    local area = union and (union.Max - union.Min) or ZERO

    return area.X * area.Y * area.Z
end

---

local ComplexPlacement = {}

ComplexPlacement.new = function(placements)
    for i = 1, #placements do
        placements[i].GetPlacementCFrame = function(self, modelBounds: Vector3, position: Vector3, rotation: number?)
            rotation = rotation or 0
            
            local thisCanvas = self:GetCanvas()
            local thisCanvasCFrame, thisCanvasSize = thisCanvas.CFrame, thisCanvas.Size
            local modelSize = WorldBoundingBox(CFrame.Angles(0, rotation, 0), modelBounds)

            -- use AABB to make sure the model has no 2D area on other canvases
            local sum = 0
            
            for j = 1, #placements do
                local canvas = placements[j]:GetCanvas()
                local canvasCFrame, canvasSize = canvas.CFrame, canvas.Size
                
                local volume = getOverlap(
                    CFrame.new(position) * (canvasCFrame - canvasCFrame.Position), Vector3.new(modelSize.X, modelSize.Z, 1),
                    canvasCFrame, Vector3.new(canvasSize.X, canvasSize.Y, 1)
                )
                
                sum = sum + volume
            end

            -- only clamp we're fully covered (margin of error included)
            local area = modelSize.X * modelSize.Z
            local clamp = (sum < (area - 0.1))
            
            local lpos = thisCanvasCFrame:PointToObjectSpace(position)
            local size2 = (thisCanvasSize - Vector2.new(modelSize.X, modelSize.Z)) / 2

            local x = clamp and math.clamp(lpos.X, -size2.X, size2.X) or lpos.X
            local y = clamp and math.clamp(lpos.Y, -size2.Y, size2.Y) or lpos.Y

            local gridSnap = self.GridSnap

            if (gridSnap > 0) then
                x = math.sign(x) * ((math.abs(x) - math.abs(x) % gridSnap) + (size2.X % gridSnap))
                y = math.sign(y) * ((math.abs(y) - math.abs(y) % gridSnap) + (size2.Y % gridSnap))
            end

            return thisCanvasCFrame * CFrame.new(x, y, -modelSize.Y / 2) * CFrame.Angles(-math.pi / 2, rotation, 0)
        end
    end
end

---

return ComplexPlacement
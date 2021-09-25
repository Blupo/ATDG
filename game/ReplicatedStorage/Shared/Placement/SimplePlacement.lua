local WorldBoundingBox = require(script.Parent:WaitForChild("WorldBoundingBox"))

---

local SimplePlacement = {}

SimplePlacement.new = function(canvasPart: BasePart, gridSnap: number?, surface: Enum.NormalId?)
	return setmetatable({
		CanvasPart = canvasPart,
		GridSnap = math.max(gridSnap or 0, 5/100),
		Surface = surface or Enum.NormalId.Top,
	}, { __index = SimplePlacement })
end

SimplePlacement.GetCanvas = function(self)
	local up = Vector3.new(0, 1, 0)
	local back = -Vector3.FromNormalId(self.Surface)

	local dot = back:Dot(Vector3.new(0, 1, 0))
	local axis = (math.abs(dot) == 1) and Vector3.new(-dot, 0, 0) or up
	
	local right = CFrame.fromAxisAngle(axis, math.pi / 2) * back
	local top = back:Cross(right).Unit
	
	local canvasSize = self.CanvasPart.Size
	local cf = self.CanvasPart.CFrame * CFrame.fromMatrix(-back * canvasSize / 2, right, top, back)
	local size = Vector2.new((canvasSize * right).Magnitude, (canvasSize * top).Magnitude)

	return {
		CFrame = cf,
		Size = size
	}
end

SimplePlacement.GetPlacementCFrame = function(self, model: Model, position: Vector3, rotation: number?): CFrame
	rotation = rotation or 0
	
	local canvas = self:GetCanvas()
	local canvasCFrame, canvasSize = canvas.CFrame, canvas.Size

	local _, modelBounds = model:GetBoundingBox()
	local modelSize = WorldBoundingBox(CFrame.Angles(0, rotation, 0), modelBounds)
	
	local lpos = canvasCFrame:PointToObjectSpace(position)
	local size2 = (canvasSize - Vector2.new(modelSize.X, modelSize.Z)) / 2
	
	local x = math.clamp(lpos.X, -size2.X, size2.X)
	local y = math.clamp(lpos.Y, -size2.Y, size2.Y)
	
	local gridSnap = self.GridSnap

	if (gridSnap > 0) then
		x = math.sign(x) * ((math.abs(x) - math.abs(x) % gridSnap) + (size2.X % gridSnap))
		y = math.sign(y) * ((math.abs(y) - math.abs(y) % gridSnap) + (size2.Y % gridSnap))
	end
	
	return canvasCFrame * CFrame.new(x, y, -modelSize.Y / 2) * CFrame.Angles(-math.pi / 2, rotation, 0)
end

---

return SimplePlacement
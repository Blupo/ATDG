local vec3Compare = function(a: Vector3, b: Vector3, callback: (number, number) -> number)
	return Vector3.new(
		callback(a.X, b.X),
		callback(a.Y, b.Y),
		callback(a.Z, b.Z)
	)
end

--

local AABB = {}

--- Static

AABB.new = function(a: Vector3, b: Vector3)
	return setmetatable({
		Min = vec3Compare(a, b, math.min),
		Max = vec3Compare(a, b, math.max)
	}, { __index = AABB })
end

AABB.fromPositionSize = function(pos: Vector3, size: Vector3)
	return AABB.new(pos + size / 2, pos - size / 2)
end

--- Class

AABB.Intersects = function(self, aabb)
	local aMax, aMin = self.Max, self.Min
	local bMax, bMin = aabb.Max, aabb.Min

	if (
		(bMin.X > aMax.X) or
		(bMin.Y > aMax.Y) or
		(bMin.Z > aMax.Z) or
		(bMax.X < aMin.X) or
		(bMax.Y < aMin.Y) or
		(bMax.Z < aMin.Z)
	) then
		return false
	else
		return true
	end
end

AABB.Union = function(self, aabb)
	if (not self:Intersects(aabb)) then
		return nil
	end

	local min = vec3Compare(aabb.Min, self.Min, math.max)
	local max = vec3Compare(aabb.Max, self.Max, math.min)

	return AABB.new(min, max)
end

--

return AABB
return function(cf: CFrame, size: Vector3): Vector3
	local size2 = size / 2

	local c1 = cf:VectorToWorldSpace(Vector3.new( size2.X,  size2.Y,  size2.Z))
	local c2 = cf:VectorToWorldSpace(Vector3.new(-size2.X,  size2.Y,  size2.Z))
	local c3 = cf:VectorToWorldSpace(Vector3.new(-size2.X, -size2.Y,  size2.Z))
	local c4 = cf:VectorToWorldSpace(Vector3.new(-size2.X, -size2.Y, -size2.Z))
	local c5 = cf:VectorToWorldSpace(Vector3.new( size2.X, -size2.Y, -size2.Z))
	local c6 = cf:VectorToWorldSpace(Vector3.new( size2.X,  size2.Y, -size2.Z))
	local c7 = cf:VectorToWorldSpace(Vector3.new( size2.X, -size2.Y,  size2.Z))
	local c8 = cf:VectorToWorldSpace(Vector3.new(-size2.X,  size2.Y, -size2.Z))

	local max = Vector3.new(
		math.max(c1.X, c2.X, c3.X, c4.X, c5.X, c6.X, c7.X, c8.X),
		math.max(c1.Y, c2.Y, c3.Y, c4.Y, c5.Y, c6.Y, c7.Y, c8.Y),
		math.max(c1.Z, c2.Z, c3.Z, c4.Z, c5.Z, c6.Z, c7.Z, c8.Z)
	)

	local min = Vector3.new(
		math.min(c1.X, c2.X, c3.X, c4.X, c5.X, c6.X, c7.X, c8.X),
		math.min(c1.Y, c2.Y, c3.Y, c4.Y, c5.Y, c6.Y, c7.Y, c8.Y),
		math.min(c1.Z, c2.Z, c3.Z, c4.Z, c5.Z, c6.Z, c7.Z, c8.Z)
	)

	return max - min
end
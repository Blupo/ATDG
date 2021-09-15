local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

---

local Terrain = Workspace.Terrain

---

return function(environment)
	local world = environment:FindFirstChild("World")
	local lighting = environment:FindFirstChild("Lighting")
	local terrain = environment:FindFirstChild("Terrain")

	if (lighting) then
		local lightingProperties = lighting:GetAttributes()
		local lightingChildren = lighting:GetChildren()

		for property, value in pairs(lightingProperties) do
			pcall(function()
				Lighting[property] = value
			end)
		end

		for i = 1, #lightingChildren do
			lightingChildren[i].Parent = Lighting
		end
	end

	if (terrain) then
		local terrainProperties = terrain:GetAttributes()
		local terrainCells = terrain:GetChildren()

		for property, value in pairs(terrainProperties) do
			local material = string.match(property, "^MaterialColors%.(%a+)")
			
			if (material) then
				pcall(function()
					Terrain:SetMaterialColor(Enum.Material[material], value)
				end)
			else
				pcall(function()
					Terrain[property] = value
				end)
			end
		end

		for i = 1, #terrainCells do
			local cell = terrainCells[i]

			local cellCFrame = cell.CFrame
			local cellSize = cell.Size
			local cellMaterial = cell.Material

			if (cell:IsA("Part")) then
				local shape = cell.Shape

				if (shape == Enum.PartType.Block) then
					Terrain:FillBlock(cellCFrame, cellSize, cellMaterial)
				elseif (shape == Enum.PartType.Ball) then
					-- I'm pretty sure the engine makes sure the size is uniform for Ball, so math.min is redundant

					Terrain:FillBall(cellCFrame.Position, math.min(cellSize.X, cellSize.Y, cellSize.Z) / 2, cellMaterial)
				elseif (shape == Enum.PartType.Cylinder) then
					Terrain:FillCylinder(cellCFrame * CFrame.Angles(0, 0, math.pi / 2), cellSize.X, math.min(cellSize.Y, cellSize.Z) / 2, cellMaterial)
				end
			elseif (cell:IsA("WedgePart")) then
				-- todo: verify that this works as intended

				Terrain:FillWedge(cellCFrame, cellSize, cellMaterial)
			else
				warn("Unsupported terrain cell type " .. cell.ClassName)
			end
		end
	end

	world.Parent = Workspace
end
-- todo: replace this with a more Roblox-like Enum implementation (such as raphtalia/Enum or buildthomas/EnumExtender)

local makeEnum = function(name, enumItems)
	local enum = {}

	for i = 1, #enumItems do
		local enumItem = enumItems[i]

		enum[enumItem] = enumItem
	end

	return setmetatable(enum, {
		__index = function(_, key)
			error(tostring(key) .. " is not a valid member of enum " .. name)
		end,

		__newindex = function()
			error(name .. " cannot be modified")
		end,
	})
end

return setmetatable({
	PursuitDirection = makeEnum("GameEnums.PursuitDirection", { "Forward", "Reverse" }),
	UnitType = makeEnum("GameEnums.UnitType", { "FieldUnit", "TowerUnit" }),
	ObjectType = makeEnum("GameEnums.ObjectType", { "Unit", "Roadblock" }),
	PathType = makeEnum("GameEnums.PathType", { "Ground", "Air", "GroundAndAir", "*" }),
	UnitTargeting = makeEnum("GameEnums.UnitTargeting", { "Closest", "Farthest", "First", "Last", "Strongest", "Fastest", "Random", "None" }),
	Difficulty = makeEnum("GameEnums.Difficulty", { "Easy", "Normal", "Hard", "Special" }),
	SurfaceType = makeEnum("GameEnums.SurfaceType", { "Path", "Terrain", "ElevatedTerrain" }),
	StatusEffectType = makeEnum("GameEnums.StatusEffectType", { "Instant", "Periodic", "Lingering" }),
	AttributeModifierType = makeEnum("GameEnums.AttributeModifierType", { "Multiplicative", "Additive", "Set" }),
	StatusEffectInteractionResult = makeEnum("GameEnums.StatusEffectInteractionResult", { "DoNotApply", "None" }),
	AbilityType = makeEnum("GameEnums.AbilityType", { "RoundStart", "RoundEnd", "OnHit", "OnDied", "Intrinsic" }),
	AbilityActionResult = makeEnum("GameRnums.AbilityActionResult", { "CancelEvent", "None" }),
	GamePhase = makeEnum("GameEnums.GamePhase", { "NotStarted", "Preparation", "Round", "Intermission", "FinalIntermission", "Ended" }),
	GameMode = makeEnum("GameEnums.GameMode", { "TowerDefense", "Endless" }),
	PlacementFailureReason = makeEnum("GameEnums.PlacementFailureReason", { "ObjectDoesNotExist", "InvalidPosition", "IncorrectSurfaceType", "NotPointingUp", "NotBounded", "NoVerticalClearance", "ObjectCollision", "LimitExceeded", "None", "Fallback" }),
	CurrencyType = makeEnum("GameEnums.CurrencyType", { "Tickets", "Points" }),
	ItemType = makeEnum("GameEnums.ItemType", { "Unit", "Roadblock", "SpecialAction" }),
	PurchaseFailureReason = makeEnum("GameEnum.PurchaseFailureReason", { "None", "CannotAcquireProfile", "AlreadyPurchased" }),
	ObjectViewportTitleType = makeEnum("GameEnum.UnitViewportTitleType", { "PlacementPrice", "ObjectName" })
}, {
	__index = function(_, key)
		error(tostring(key) .. " is not a valid enum")
	end,

	__newindex = function()
		error("Enum table cannot be modified")
	end
})
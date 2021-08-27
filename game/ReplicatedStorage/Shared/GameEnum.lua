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
	PursuitDirection = makeEnum("GameEnum.PursuitDirection", { "Forward", "Reverse" }),
	UnitType = makeEnum("GameEnum.UnitType", { "FieldUnit", "TowerUnit" }),
	ObjectType = makeEnum("GameEnum.ObjectType", { "Unit", "Roadblock" }),
	PathType = makeEnum("GameEnum.PathType", { "Ground", "Air", "GroundAndAir", "*" }),
	UnitTargeting = makeEnum("GameEnum.UnitTargeting", { "Closest", "Farthest", "First", "Last", "Strongest", "Fastest", "Random", "AreaOfEffect", "None" }),
	Difficulty = makeEnum("GameEnum.Difficulty", { "Easy", "Normal", "Hard", "Special" }),
	SurfaceType = makeEnum("GameEnum.SurfaceType", { "Path", "Terrain", "ElevatedTerrain" }),
	StatusEffectType = makeEnum("GameEnum.StatusEffectType", { "Instant", "Periodic", "Lingering" }),
	AttributeModifierType = makeEnum("GameEnum.AttributeModifierType", { "Multiplicative", "Additive", "Set" }),
	StatusEffectInteractionResult = makeEnum("GameEnum.StatusEffectInteractionResult", { "DoNotApply", "None" }),
	AbilityType = makeEnum("GameEnum.AbilityType", { "RoundStart", "RoundEnd", "OnHit", "Manual" }),
	AbilityActionResult = makeEnum("GameRnums.AbilityActionResult", { "CancelEvent", "None" }),
	GamePhase = makeEnum("GameEnum.GamePhase", { "NotStarted", "Preparation", "Round", "Intermission", "FinalIntermission", "Ended" }),
	GameMode = makeEnum("GameEnum.GameMode", { "TowerDefense", "Endless" }),
	PlacementFailureReason = makeEnum("GameEnum.PlacementFailureReason", { "ObjectDoesNotExist", "InvalidPosition", "IncorrectSurfaceType", "NotPointingUp", "NotBounded", "NoVerticalClearance", "ObjectCollision", "LimitExceeded" }),
	CurrencyType = makeEnum("GameEnum.CurrencyType", { "Tickets", "Points" }),
	ItemType = makeEnum("GameEnum.ItemType", { "SpecialAction" }),
	PurchaseFailureReason = makeEnum("GameEnum.PurchaseFailureReason", { "CannotAcquireProfile", "AlreadyPurchased" }),
	ObjectViewportTitleType = makeEnum("GameEnum.ObjectViewportTitleType", { "PlacementPrice", "ObjectName" }),
	DamageSourceType = makeEnum("GameEnum.DamageSourceType", { "Unit", "Almighty" }),
	PromotionalPricing = makeEnum("GameEnum.PromotionalPricing", { "None", "Summer" }),
	DevProductType = makeEnum("GameEnum.DevProductType", { "Ticket", "ValuePack" }),
	TransactionType = makeEnum("GameEnum.DevProductType", { "DevProductPurchase", "TicketSpending" }),
	TransactionRecordingFailureReason = makeEnum("GameEnum.TransactionRecordingFailureReason", { "CannotAcquireProfile", "TransactionAlreadyRecorded" }),
	GenericActionResult = makeEnum("GameEnum.GenericActionResult", { "None" }),
	SpecialActionUsageResult = makeEnum("GameEnum.SpecialActionUsageResult", { "InvalidActionName", "NoInventory", "PlayerLimited", "GameLimited", "PlayerCooldown", "GameCooldown" }),
	SpecialActionLimitType = makeEnum("GameEnum.SpecialActionLimitType", { "PlayerLimit", "GameLimit", "PlayerCooldown", "GameCooldown" }),
	GameStat = makeEnum("GameEnum.GameStat", { "TimePlayed" }),
	PlayerStat = makeEnum("GameEnum.PlayerStat", { "TotalDMG" }),
}, {
	__index = function(_, key)
		error(tostring(key) .. " is not a valid enum")
	end,

	__newindex = function()
		error("Enum table cannot be modified")
	end
})
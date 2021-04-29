return {
	ConnectPlayerDebounce = function(callback: (any) -> any)
		local debounceTable: {[number]: boolean} = {}
		
		return function(player: Player, ...): any?
			if (debounceTable[player.UserId]) then return end
			debounceTable[player.UserId] = true
			
			local result: any = callback(player, ...)
			
			debounceTable[player.UserId] = nil
			return result
		end
	end,
	
	-- Used to connect RemoteEvent.OnServerEvent to supress the invocation queue exhaustion errors
	NoOp = function() end,
}
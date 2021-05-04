return function(remoteFunction)
	return function(...)
		return remoteFunction:InvokeServer(...)
	end
end
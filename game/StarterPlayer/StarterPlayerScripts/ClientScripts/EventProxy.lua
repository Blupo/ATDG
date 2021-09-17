return function(originalEvent, callback)
    local proxyBindableEvent = Instance.new("BindableEvent")

    originalEvent:Connect(function(...)
        callback(...)
        proxyBindableEvent:Fire(...)
    end)

    return proxyBindableEvent.Event
end
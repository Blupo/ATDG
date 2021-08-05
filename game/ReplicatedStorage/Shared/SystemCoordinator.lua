local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---

local SystemsFolder

local systems = {}

---

local System = {}

if (RunService:IsServer()) then
    System.new = function(name)
        if (systems[name]) then return end
        systems[name] = true

        local systemFolder = Instance.new("Folder")
        systemFolder.Name = name

        local self = {
            SystemFolder = systemFolder,
        }

        self.addFunction = function(functionName, callback, playerDebounce)
            if (systemFolder:FindFirstChild(functionName)) then return end
    
            local newRemoteFunction = Instance.new("RemoteFunction")
            newRemoteFunction.Name = functionName
    
            local debounceTable = playerDebounce and {} or nil

            newRemoteFunction.OnServerInvoke = function(player, ...)
                if (playerDebounce) then
                    if (debounceTable[player.UserId]) then
                        return
                    else
                        debounceTable[player.UserId] = true
                    end 
                end

                local result = callback(player, ...)

                if (playerDebounce) then
                    debounceTable[player.UserId] = nil
                end

                return result
            end
    
            newRemoteFunction.Parent = systemFolder
            return newRemoteFunction
        end
    
        self.addEvent = function(eventName, onServerEvent)
            if (systemFolder:FindFirstChild(eventName)) then return end
    
            local newRemoteEvent = Instance.new("RemoteEvent")
            newRemoteEvent.Name = eventName
            newRemoteEvent.OnServerEvent:Connect(onServerEvent or function() end)
            
            newRemoteEvent.Parent = systemFolder
            return newRemoteEvent
        end

        systems[name] = self
        systemFolder.Parent = SystemsFolder
        return self
    end
end

---

local SystemCoordinator = {}

SystemCoordinator.getSystem = function(systemName: string)
    return systems[systemName]
end

SystemCoordinator.waitForSystem = function(systemName: string)
    local system = systems[systemName]
    if (system) then return system end

    local elapsed = 0
    local notifiedInfiniteWait = false

    repeat
        system = systems[systemName]
        elapsed = elapsed + RunService.Heartbeat:Wait()

        if ((not notifiedInfiniteWait) and (elapsed >= 5)) then
            notifiedInfiniteWait = true
            warn("Infinite yield possible on system " .. systemName)
        end
    until (system)
    
    return system
end

if (RunService:IsServer()) then
    SystemCoordinator.newSystem = function(systemName)
        if (systems[systemName]) then return end

        return System.new(systemName)
    end
end

---

if (RunService:IsServer()) then
    SystemsFolder = Instance.new("Folder")
    SystemsFolder.Name = "Systems"
    SystemsFolder.Parent = ReplicatedStorage
elseif (RunService:IsClient()) then
    SystemsFolder = ReplicatedStorage:WaitForChild("Systems")

    local systemFolderItemAdded = function(system)
        return function(systemItem)
            local itemName = systemItem.Name
            if (system[itemName]) then return end

            if (systemItem:IsA("RemoteFunction")) then
                system[itemName] = function(...)
                    return systemItem:InvokeServer(...)
                end
            elseif (systemItem:IsA("RemoteEvent")) then
                system[itemName] = systemItem.OnClientEvent
            end
        end
    end

    local systemFolderAdded = function(systemFolder)
        if (not systemFolder:IsA("Folder")) then return end
        
        local systemName = systemFolder.Name
        if (systems[systemName]) then return end

        local newSystem = {}
        local folderItemAdded = systemFolderItemAdded(newSystem)
        local systemItems = systemFolder:GetChildren()

        for i = 1, #systemItems do
            folderItemAdded(systemItems[i])
        end

        systemFolder.ChildAdded:Connect(folderItemAdded)
        systems[systemName] = newSystem
    end

    -- init systems
    local systemFolders = SystemsFolder:GetChildren()

    for i = 1, #systemFolders do
        systemFolderAdded(systemFolders[i])
    end

    SystemsFolder.ChildAdded:Connect(systemFolderAdded)
end

return SystemCoordinator
local StarterGui = game:GetService("StarterGui")

---

local notificationIcons = {
    Party = "rbxassetid://7440497724",
    Game = "rbxassetid://6868396182",
    Teleport = "rbxassetid://6869244717",
}

---

local Notifications = {}

Notifications.SendCoreNotification = function(title, text, icon)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = notificationIcons[icon] or icon
    })
end

Notifications.SendNotification = function(topic: string, message: string)

end

return Notifications
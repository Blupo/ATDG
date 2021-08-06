local Players = game:GetService("Players")

---

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local GameUIDir = PlayerScripts:WaitForChild("GameUI")
local GameUI = require(GameUIDir:WaitForChild("GameUI"))
local Roact = require(GameUIDir:WaitForChild("Roact"))

---

Roact.mount(Roact.createElement(GameUI), PlayerGui, "GameUI")
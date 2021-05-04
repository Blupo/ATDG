local Players = game:GetService("Players")

---

local PlayerScripts = script.Parent
local GameUIDir = PlayerScripts:WaitForChild("GameUI")
local GameUI = require(GameUIDir:WaitForChild("GameUI"))
local Roact = require(GameUIDir:WaitForChild("Roact"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

---

Roact.mount(Roact.createElement(GameUI), PlayerGui, "GameUI")
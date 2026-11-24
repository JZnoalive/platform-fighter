-- StarterPlayer.StarterPlayerScripts.Client.Main
-- Punto de entrada del cliente: arranca los controladores en orden.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Controllers = script.Parent:WaitForChild("Controllers")
local CameraController = require(Controllers.CameraController)
local InputController = require(Controllers.InputController)
local MovementController = require(Controllers.MovementController)

InputController.Start()
CameraController.Start()
MovementController.Start()

print(`[Client] listo — {Players.LocalPlayer.Name} — versión {GameConfig.Version}`)

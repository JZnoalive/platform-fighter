-- ServerScriptService.Server.Main
-- Punto de entrada del servidor: arranca los servicios en orden.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Services = script.Parent:WaitForChild("Services")
local FighterService = require(Services.FighterService)
local CombatService = require(Services.CombatService)
local TrainingService = require(Services.TrainingService)
local MatchService = require(Services.MatchService)

FighterService.Start()
CombatService.Start()
TrainingService.Start()
MatchService.Start()

print(`[Server] listo — versión {GameConfig.Version}`)

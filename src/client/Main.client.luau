-- StarterPlayer.StarterPlayerScripts.Client.Main
-- Punto de entrada del cliente: arranca los controladores en orden.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Controllers = script.Parent:WaitForChild("Controllers")
local CameraController = require(Controllers.CameraController)
local InputController = require(Controllers.InputController)
local MovementController = require(Controllers.MovementController)
local CombatController = require(Controllers.CombatController)
local HudController = require(Controllers.HudController)
local PracticeController = require(Controllers.PracticeController)
local PoseController = require(Controllers.PoseController)
local EffectsController = require(Controllers.EffectsController)
local AnimationController = require(Controllers.AnimationController)
local DebugController = require(Controllers.DebugController)

-- La cámara va primero: si otro controlador falla, al menos se ve el juego.
CameraController.Start()
InputController.Start()
MovementController.Start()
CombatController.Start()
HudController.Start()
PracticeController.Start()
AnimationController.Start() -- animaciones reales
PoseController.Start() -- poses por código como respaldo (después, en Stepped)
EffectsController.Start()
DebugController.Start() -- panel de la sala de prueba (F2)

print(`[Client] listo — {Players.LocalPlayer.Name} — versión {GameConfig.Version}`)

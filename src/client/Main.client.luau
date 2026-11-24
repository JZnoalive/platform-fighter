-- StarterPlayer.StarterPlayerScripts.Client.Main
-- Punto de entrada del cliente. En M0 solo confirma que Rojo sincroniza bien.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

print(`[Client] listo — {Players.LocalPlayer.Name} — versión {GameConfig.Version}`)

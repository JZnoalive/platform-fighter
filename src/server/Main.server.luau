-- ServerScriptService.Server.Main
-- Punto de entrada del servidor. En M0 solo confirma que Rojo sincroniza bien.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

print(`[Server] listo — versión {GameConfig.Version}`)

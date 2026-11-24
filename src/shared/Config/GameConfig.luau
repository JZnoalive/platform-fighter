-- ReplicatedStorage.Shared.Config.GameConfig
-- Reglas generales de la partida. Solo datos, sin lógica.

local GameConfig = {
	Version = "0.0.4-m3",
	Stocks = 3,
	RespawnInvulnerability = 1.5, -- segundos

	-- Combate
	HitstunPerForce = 0.004, -- segundos de hitstun por cada punto de fuerza de knockback
	MinHitstun = 0.1,
	MaxHitstun = 1.0,

	-- Depuración: muestra las hitboxes como cajas rojas mientras están activas
	DebugHitboxes = true,
}

return GameConfig

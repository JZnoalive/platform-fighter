-- ReplicatedStorage.Shared.Config.GameConfig
-- Reglas generales de la partida. Solo datos, sin lógica.

local GameConfig = {
	Version = "0.0.6-m4b",

	-- Partida
	MinPlayersForMatch = 2, -- con menos jugadores: modo libre (KO sin perder vidas)
	Stocks = 3,
	RespawnDelay = 1.0, -- segundos congelado arriba antes de volver a jugar
	RespawnInvulnerability = 1.5, -- segundos invulnerable después de soltarse
	VictoryDelay = 5, -- segundos mostrando al ganador antes de reiniciar

	-- Combate
	HitstunPerForce = 0.004, -- segundos de hitstun por cada punto de fuerza de knockback
	MinHitstun = 0.1,
	MaxHitstun = 1.0,

	-- Depuración: muestra las hitboxes como cajas rojas mientras están activas
	DebugHitboxes = true,
}

return GameConfig

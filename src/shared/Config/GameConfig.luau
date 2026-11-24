-- ReplicatedStorage.Shared.Config.GameConfig
-- Reglas generales de la partida. Solo datos, sin lógica.

local GameConfig = {
	Version = "0.0.7-m4c",

	-- Partida
	MinPlayersForMatch = 2, -- con menos jugadores: modo libre (KO sin perder vidas)
	Stocks = 3,
	RespawnDelay = 1.0, -- segundos congelado arriba antes de volver a jugar
	RespawnInvulnerability = 1.5, -- segundos invulnerable después de soltarse
	VictoryDelay = 5, -- segundos mostrando al ganador antes de reiniciar

	-- Combate
	-- Para que haya combos, el rival debe quedar aturdido MÁS tiempo del que
	-- tarda el atacante en volver a golpear.
	HitstunPerForce = 0.009, -- segundos de hitstun por cada punto de fuerza de knockback
	MinHitstun = 0.25,
	MaxHitstun = 1.2,
	RecoveryOnHitMultiplier = 0.5, -- si el ataque acierta, su recovery dura la mitad
	AttackBufferWindow = 0.2, -- si pulsas atacar hasta 0.2 s antes de poder, el golpe sale en cuanto puedas

	-- Depuración: muestra las hitboxes como cajas rojas mientras están activas
	DebugHitboxes = true,
}

return GameConfig

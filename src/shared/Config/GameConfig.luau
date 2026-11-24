-- ReplicatedStorage.Shared.Config.GameConfig
-- Reglas generales de la partida. Solo datos, sin lógica.

local GameConfig = {
	Version = "0.3.0-smash",

	-- Presentación
	ShowOverheadPercent = false, -- etiqueta de % encima de la cabeza (el HUD de abajo ya lo muestra)
	BuildDecor = true, -- DecorService monta el escenario de atardecer (false si se decora a mano en Studio)

	-- Partida
	MinPlayersForMatch = 2, -- con menos jugadores: modo libre (KO sin perder vidas)
	Stocks = 3,
	RespawnDelay = 1.0, -- segundos congelado arriba antes de volver a jugar
	RespawnInvulnerability = 1.5, -- segundos invulnerable después de soltarse
	VictoryDelay = 5, -- segundos mostrando al ganador antes de reiniciar
	StartCountdown = 3, -- "3, 2, 1, ¡YA!": segundos congelados al empezar una partida

	-- Combate
	-- Para que haya combos, el rival debe quedar aturdido MÁS tiempo del que
	-- tarda el atacante en volver a golpear.
	HitstunPerForce = 0.009, -- segundos de hitstun por cada punto de fuerza de knockback
	MinHitstun = 0.25,
	MaxHitstun = 1.2,
	RecoveryOnHitMultiplier = 0.5, -- si el ataque acierta, su recovery dura la mitad
	AttackBufferWindow = 0.2, -- si pulsas atacar hasta 0.2 s antes de poder, el golpe sale en cuanto puedas

	-- Hitlag (estilo Smash): atacante y golpeado se congelan un instante al impactar
	HitlagBase = 0.035,
	HitlagPerDamage = 0.0065, -- un pesado de 15 % congela ~0.13 s
	HitlagMax = 0.17,

	-- Esquiva (estilo Brawlhalla): invulnerable mientras dura, luego enfriamiento
	DodgeDuration = 0.3, -- segundos de esquiva (invulnerable)
	DodgeCooldown = 1.0, -- segundos desde que empieza una esquiva hasta poder hacer otra
	ChaseDodgeWindow = 0.6, -- si acertaste un golpe hace menos de esto...
	ChaseDodgeCooldown = 0.35, -- ...la esquiva recarga mucho antes (para perseguir)

	-- Depuración: muestra las hitboxes como cajas rojas mientras están activas.
	-- Es el valor inicial; en modo práctica se puede cambiar desde el menú.
	DebugHitboxes = false,
}

return GameConfig

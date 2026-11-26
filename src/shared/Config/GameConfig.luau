-- ReplicatedStorage.Shared.Config.GameConfig
-- Reglas generales de la partida. Solo datos, sin lógica.

local GameConfig = {
	Version = "0.9.0-game-feel",

	-- SALA DE PRUEBA (game feel): 1 personaje, 1 arma y un rival de prueba que se
	-- reinicia solo para repetir combos. Enabled = false vuelve al modo normal.
	TestRoom = {
		Enabled = true,
		PlayerFighter = "Blade", -- Vórtice con Espada
		CpuFighter = "Brawler", -- rival de prueba (Forja, quieto)
		AutoResetDelay = nil, -- (antes 2.5: la CPU volvía sola a su sitio y parecía bugueada; usa "Reiniciar posiciones")
	},

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
	AttackBufferWindow = 0.35, -- búfer: si pulsas atacar hasta 0,35 s antes de poder, el golpe sale en cuanto puedas
	-- Cadena de ligeros (golpe 1 → 2 → 3) con el ataque neutro en el suelo (ChainLogic)
	LightChain = { Moves = { "Jab", "Jab2", "Jab3" }, Window = 0.55 },

	-- Hitlag (estilo Smash): atacante y golpeado se congelan un instante al impactar
	-- Lanzado y aturdido (hitstun) en el aire: pesa menos, flota más (para poder perseguir
	-- y hacer combos aéreos, como en el género). 1 = gravedad normal.
	HitstunGravityMultiplier = 0.45,
	HitlagBase = 0.03,
	HitlagPerDamage = 0.0045, -- un pesado de 15 % congela ~0.1 s (ágil, estilo Brawlhalla)
	HitlagMax = 0.11,

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

-- ReplicatedStorage.Shared.Config.Weapons.Sword
-- Moveset del arma "Espada" (la de Blade por defecto): MÁS alcance pero MÁS lenta
-- que los guanteletes. Mismos 12 ataques y campos que Gauntlets.luau (ver su cabecera).

return {
	---------------------------------------------------------------- LIGEROS EN EL SUELO
	-- GAME FEEL (prueba 1). lunge = desplazamiento propio del ataque:
	--   speed = studs/s hacia delante, time = cuánto dura, delay = cuándo empieza
	--   (desde que empieza el ataque), vy = impulso vertical opcional.
	-- Startups algo más largos que antes (0,10-0,14 s) para que la anticipación SE VEA.

	-- CADENA DE LIGEROS (ataque neutro en el suelo, pulsando J varias veces):
	--   Jab (golpe 1) → Jab2 (golpe 2, con avance) → Jab3 (remate) → recuperación.
	-- Campos de golpe SEPARADOS (Knockback.luau): knockback = Vector2(horizontal, vertical)
	-- al 0 %, knockbackGrowth = cuánto crece por punto de %, hitstun y hitstop en segundos.

	-- Golpe 1: tajo corto de arriba abajo, paso corto. Empuja poco: el rival queda cerca.
	Jab = {
		startup = 0.1,
		active = 0.08,
		recovery = 0.18,
		damage = 4,
		baseKnockback = 14, -- (respaldo si no hubiera knockback)
		knockbackScale = 0.05,
		angle = 35,
		knockback = Vector2.new(11, 8),
		knockbackGrowth = 0.004,
		hitstun = 0.42, -- antes 0.3: el rival salía del hitstun justo antes del golpe 2
		hitstop = 0.05,
		lunge = { speed = 16, time = 0.08, delay = 0.05 },
		hitbox = { offset = Vector2.new(3.5, 0.8), size = Vector3.new(6, 4, 6) },
		animationId = nil,
	},

	-- Golpe 2: tajo ascendente con AVANCE (alcanza al rival empujado por el golpe 1).
	Jab2 = {
		startup = 0.09,
		active = 0.08,
		recovery = 0.2,
		damage = 4,
		baseKnockback = 15,
		knockbackScale = 0.05,
		angle = 35,
		knockback = Vector2.new(12, 9),
		knockbackGrowth = 0.004,
		hitstun = 0.44, -- antes 0.32
		hitstop = 0.05,
		lunge = { speed = 24, time = 0.1, delay = 0.04 },
		hitbox = { offset = Vector2.new(3.6, 0.8), size = Vector3.new(6, 4, 6) },
	},

	-- Golpe 3 (remate): tajo grande con paso largo; lanza en diagonal y termina la cadena.
	Jab3 = {
		startup = 0.13,
		active = 0.1,
		recovery = 0.3,
		damage = 7,
		baseKnockback = 30,
		knockbackScale = 0.4,
		angle = 40,
		knockback = Vector2.new(30, 22),
		knockbackGrowth = 0.012,
		hitstop = 0.08,
		lunge = { speed = 26, time = 0.12, delay = 0.07 },
		hitbox = { offset = Vector2.new(4, 0.8), size = Vector3.new(7, 5, 6) },
	},

	-- SLight: tajo horizontal con un AVANCE largo (~3,5 studs): llega al rival que
	-- salió despedido por el NLight y lo lanza en diagonal para perseguirlo en el aire.
	SideLight = {
		startup = 0.14,
		active = 0.1,
		recovery = 0.24,
		damage = 8,
		baseKnockback = 26,
		knockbackScale = 0.35,
		angle = 32,
		knockback = Vector2.new(26, 12), -- sobre todo horizontal
		knockbackGrowth = 0.01,
		hitstop = 0.06,
		lunge = { speed = 30, time = 0.12, delay = 0.06 },
		hitbox = { offset = Vector2.new(4.5, 0.5), size = Vector3.new(7, 4, 6) },
		animationId = nil,
	},

	-- Ataque ARRIBA en el suelo: LANZADOR VERTICAL (sube al rival ~6 studs para seguir en el aire).
	UpLight = {
		startup = 0.1,
		active = 0.12,
		recovery = 0.2,
		damage = 6,
		baseKnockback = 26,
		knockbackScale = 0.35,
		angle = 85,
		knockback = Vector2.new(5, 58),
		knockbackGrowth = 0.006,
		hitstun = 0.45,
		hitstop = 0.06,
		hitbox = { offset = Vector2.new(1.5, 3), size = Vector3.new(6, 6, 6) },
		animationId = nil,
	},

	-- Barrida que LEVANTA (estilo Brawlhalla): abre el combo verdadero DLight > SAir
	-- (salta y pega con el aéreo antes de que el rival pueda esquivar). Comprobado con
	-- el simulador: entra de 0 % a 120 %. También DLight > Recovery para rematar arriba.
	DownLight = {
		startup = 0.07,
		active = 0.1,
		recovery = 0.19,
		damage = 6,
		baseKnockback = 50, -- con el salto nuevo (~7 studs) sube ~4,5 studs: a tu alcance
		knockbackScale = 0.06, -- casi igual a cualquier % (golpe de combo, no de remate)
		lunge = { speed = 22, time = 0.1, delay = 0.04 },
		angle = 80,
		hitbox = { offset = Vector2.new(4.5, -2), size = Vector3.new(7, 2, 6) },
		animationId = nil,
	},

	---------------------------------------------------------------- LIGEROS EN EL AIRE
	-- Aéreo NEUTRO: gran arco por encima; lanza arriba-delante (para seguir subiendo).
	AirLight = {
		startup = 0.1,
		active = 0.12,
		recovery = 0.18,
		damage = 6,
		baseKnockback = 24,
		knockbackScale = 0.3,
		angle = 40,
		knockback = Vector2.new(14, 30),
		knockbackGrowth = 0.008,
		hitstop = 0.05,
		lunge = { speed = 14, time = 0.08, delay = 0.05 },
		-- arco grande que llega por debajo: atrapa al rival que sube
		hitbox = { offset = Vector2.new(3.5, -1), size = Vector3.new(8, 8, 6) },
		animationId = nil,
	},

	-- Aéreo LATERAL (A/D + J en el aire): estocada horizontal con impulso adelante;
	-- empuja en horizontal para perseguir.
	AirSideLight = {
		startup = 0.1,
		active = 0.1,
		recovery = 0.2,
		damage = 7,
		baseKnockback = 26,
		knockbackScale = 0.3,
		angle = 25,
		knockback = Vector2.new(30, 10),
		knockbackGrowth = 0.01,
		hitstop = 0.06,
		lunge = { speed = 26, time = 0.1, delay = 0.04 },
		hitbox = { offset = Vector2.new(4.5, 0), size = Vector3.new(7, 4, 6) },
	},

	-- Aéreo ARRIBA: tajo ascendente; sube al rival (seguir con otro aéreo o el recovery).
	AirUpLight = {
		startup = 0.08,
		active = 0.12,
		recovery = 0.16,
		damage = 6,
		baseKnockback = 24,
		knockbackScale = 0.3,
		angle = 80,
		knockback = Vector2.new(4, 46),
		knockbackGrowth = 0.006,
		hitstop = 0.05,
		hitbox = { offset = Vector2.new(1, 4.5), size = Vector3.new(7, 5, 6) },
		animationId = nil,
	},

	-- Descendente: estocada en PICADO en diagonal (baja hacia delante). Lanza al rival
	-- hacia arriba-delante para poder seguir (en vez de clavarlo contra el suelo).
	AirDownLight = {
		startup = 0.12,
		active = 0.16,
		recovery = 0.2,
		damage = 8,
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = 45,
		lunge = { speed = 20, time = 0.14, delay = 0.1, vy = -45 },
		hitbox = { offset = Vector2.new(2, -2.5), size = Vector3.new(6, 6, 6) },
		animationId = nil,
	},

	---------------------------------------------------------------- PESADOS
	-- FIRMA "Embestida": cruza hacia delante con un tajo cargado
	Heavy = {
		startup = 0.26,
		active = 0.2,
		recovery = 0.42,
		damage = 16,
		baseKnockback = 46,
		knockbackScale = 1.0,
		angle = 35,
		selfImpulse = Vector2.new(75, 3),
		impulseAtStartup = true,
		hitbox = { offset = Vector2.new(4, 0.5), size = Vector3.new(8, 4, 6) },
	},

	UpHeavy = {
		startup = 0.34,
		active = 0.16,
		recovery = 0.45,
		damage = 16,
		baseKnockback = 44,
		knockbackScale = 1.0,
		angle = 88,
		hitbox = { offset = Vector2.new(0, 5.5), size = Vector3.new(8, 7, 6) },
		animationId = nil,
	},

	-- FIRMA "Torbellino": giro a ras de suelo con 2 tajos a los dos lados
	DownHeavy = {
		startup = 0.3,
		active = 0.28,
		recovery = 0.5,
		hits = 2,
		damage = 8,
		baseKnockback = 42,
		knockbackScale = 0.95,
		angle = 28,
		awayFromAttacker = true,
		hitbox = { offset = Vector2.new(0, -1.5), size = Vector3.new(13, 3, 6) },
	},

	-- Recovery en diagonal (un poco hacia delante)
	Recovery = {
		startup = 0.06,
		active = 0.3,
		recovery = 0.4,
		damage = 9,
		baseKnockback = 36,
		knockbackScale = 0.5,
		angle = 75,
		selfImpulse = Vector2.new(6, 78),
		hitbox = { offset = Vector2.new(2, 2), size = Vector3.new(6, 6, 6) },
		animationId = nil,
	},

	GroundPound = {
		startup = 0.14,
		active = 0.35,
		recovery = 0.35,
		damage = 12,
		baseKnockback = 36,
		knockbackScale = 0.65,
		angle = 45,
		awayFromAttacker = true,
		selfImpulse = Vector2.new(0, -85),
		hitbox = { offset = Vector2.new(0, -3), size = Vector3.new(8, 4, 6) },
		animationId = nil,
	},
}

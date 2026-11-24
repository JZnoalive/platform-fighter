-- ReplicatedStorage.Shared.Config.Fighters.Brawler
-- Moveset de "Brawler" (nombre en clave). Solo datos, sin lógica.
--
-- Qué ataque sale (lo decide CombatController en el cliente):
--   Ligero (J / clic izq.)        suelo: Jab · SideLight (A/D) · UpLight (W) · DownLight (S)
--                                 aire:  AirLight · AirUpLight (W) · AirDownLight (S)
--   Pesado (K / clic der.)        suelo: Heavy · UpHeavy (W) · DownHeavy (S)
--                                 aire:  Heavy · Recovery (W, 1 vez por vuelo) · GroundPound (S)
--
-- Campos:
--   startup / active / recovery : segundos (antes de la hitbox / hitbox activa / después)
--   damage                      : % que suma
--   baseKnockback, knockbackScale: fuerza = base + % del rival * scale
--   angle                       : 0 = horizontal hacia delante, 90 = arriba, negativo = hacia abajo
--   hitbox.offset               : X = hacia delante (según hacia dónde mira), Y = arriba
--   awayFromAttacker (opcional) : true = empuja hacia el lado donde está el rival
--                                 (para golpes que pegan a los dos lados)
--   selfImpulse (opcional)      : Vector2(adelante, arriba) que se da el ATACANTE al usarlo
--   animationId                 : se rellena cuando existan las animaciones (M7)

return {
	---------------------------------------------------------------- LIGEROS EN EL SUELO
	-- Golpe rápido sin dirección
	Jab = {
		startup = 0.06,
		active = 0.08,
		recovery = 0.14,
		damage = 4,
		baseKnockback = 28,
		knockbackScale = 0.25,
		angle = 30,
		hitbox = { offset = Vector2.new(2.5, 0.5), size = Vector3.new(4, 4, 6) },
		animationId = nil,
	},

	-- Ligero con A/D: más alcance
	SideLight = {
		startup = 0.1,
		active = 0.1,
		recovery = 0.22,
		damage = 7,
		baseKnockback = 34,
		knockbackScale = 0.45,
		angle = 25,
		hitbox = { offset = Vector2.new(3.5, 0.5), size = Vector3.new(5, 3, 6) },
		animationId = nil,
	},

	-- Ligero con W: anti-aéreo, pega por encima de la cabeza
	UpLight = {
		startup = 0.08,
		active = 0.1,
		recovery = 0.18,
		damage = 6,
		baseKnockback = 30,
		knockbackScale = 0.35,
		angle = 85,
		hitbox = { offset = Vector2.new(0.5, 4), size = Vector3.new(5, 4, 6) },
		animationId = nil,
	},

	-- Ligero con S: barrida baja
	DownLight = {
		startup = 0.07,
		active = 0.1,
		recovery = 0.2,
		damage = 5,
		baseKnockback = 26,
		knockbackScale = 0.3,
		angle = 20,
		hitbox = { offset = Vector2.new(3, -2), size = Vector3.new(5, 2, 6) },
		animationId = nil,
	},

	---------------------------------------------------------------- LIGEROS EN EL AIRE
	AirLight = {
		startup = 0.07,
		active = 0.12,
		recovery = 0.18,
		damage = 6,
		baseKnockback = 30,
		knockbackScale = 0.35,
		angle = 50,
		hitbox = { offset = Vector2.new(2.5, 0), size = Vector3.new(5, 5, 6) },
		animationId = nil,
	},

	AirUpLight = {
		startup = 0.07,
		active = 0.12,
		recovery = 0.18,
		damage = 6,
		baseKnockback = 28,
		knockbackScale = 0.35,
		angle = 80,
		hitbox = { offset = Vector2.new(0.5, 4), size = Vector3.new(5, 4, 6) },
		animationId = nil,
	},

	-- Pega hacia abajo (spike): manda al rival hacia el vacío
	AirDownLight = {
		startup = 0.1,
		active = 0.12,
		recovery = 0.22,
		damage = 7,
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = -65,
		hitbox = { offset = Vector2.new(0.5, -3.5), size = Vector3.new(4, 4, 6) },
		animationId = nil,
	},

	---------------------------------------------------------------- PESADOS
	-- Pesado hacia delante (suelo o aire): el que hace KO de lado
	Heavy = {
		startup = 0.3,
		active = 0.12,
		recovery = 0.4,
		damage = 15,
		baseKnockback = 45,
		knockbackScale = 1.0,
		angle = 40,
		hitbox = { offset = Vector2.new(3.5, 0.5), size = Vector3.new(6, 4, 6) },
		animationId = nil,
	},

	-- Pesado con W en el suelo: manda hacia arriba
	UpHeavy = {
		startup = 0.28,
		active = 0.14,
		recovery = 0.4,
		damage = 14,
		baseKnockback = 42,
		knockbackScale = 0.95,
		angle = 88,
		hitbox = { offset = Vector2.new(0, 5), size = Vector3.new(6, 6, 6) },
		animationId = nil,
	},

	-- Pesado con S en el suelo: golpe al suelo que pega a los dos lados
	DownHeavy = {
		startup = 0.25,
		active = 0.14,
		recovery = 0.45,
		damage = 13,
		baseKnockback = 40,
		knockbackScale = 0.9,
		angle = 30,
		awayFromAttacker = true,
		hitbox = { offset = Vector2.new(0, -1.5), size = Vector3.new(10, 3, 6) },
		animationId = nil,
	},

	-- Pesado con W en el aire: impulso hacia arriba para volver al escenario.
	-- Solo 1 vez por vuelo (se recarga al tocar el suelo o al recibir un golpe).
	Recovery = {
		startup = 0.05,
		active = 0.3,
		recovery = 0.35,
		damage = 8,
		baseKnockback = 35,
		knockbackScale = 0.5,
		angle = 80,
		selfImpulse = Vector2.new(0, 80),
		hitbox = { offset = Vector2.new(1, 2), size = Vector3.new(5, 6, 6) },
		animationId = nil,
	},

	-- Pesado con S en el aire: cae en picado y golpea al aterrizar
	GroundPound = {
		startup = 0.12,
		active = 0.35,
		recovery = 0.3,
		damage = 10,
		baseKnockback = 34,
		knockbackScale = 0.6,
		angle = 45,
		awayFromAttacker = true,
		selfImpulse = Vector2.new(0, -85),
		hitbox = { offset = Vector2.new(0, -3), size = Vector3.new(6, 4, 6) },
		animationId = nil,
	},
}

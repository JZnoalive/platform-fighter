-- ReplicatedStorage.Shared.Config.Fighters.Brawler
-- Moveset de "Brawler" (nombre en clave). Solo datos, sin lógica.
--
-- Tiempos en segundos:
--   startup  = antes de que salga la hitbox
--   active   = hitbox activa
--   recovery = después, sin poder actuar
-- hitbox.offset: X = hacia delante (según hacia dónde mira), Y = arriba
-- angle: 0 = horizontal hacia delante, 90 = vertical hacia arriba
-- animationId: se rellena cuando existan las animaciones (M7)

return {
	-- Ligero sin dirección, en el suelo
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

	-- Ligero con dirección (A/D), en el suelo
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

	-- Ligero en el aire
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

	-- Pesado (el que hace KO)
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
}

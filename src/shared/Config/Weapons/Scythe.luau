-- ReplicatedStorage.Shared.Config.Weapons.Scythe
-- Moveset del arma "Guadaña": mucho alcance, golpes en arco y un lateral que
-- ENGANCHA y tira al rival hacia atrás (ángulo > 90 = hacia el lado contrario).
-- Mismos 12 ataques y campos que Gauntlets.luau (ver su cabecera).

return {
	---------------------------------------------------------------- LIGEROS EN EL SUELO
	Jab = {
		startup = 0.08,
		active = 0.1,
		recovery = 0.18,
		damage = 5,
		baseKnockback = 14,
		knockbackScale = 0.14,
		angle = 30,
		hitbox = { offset = Vector2.new(4, 0.5), size = Vector3.new(7, 4, 6) },
	},

	-- Gancho: tira al rival por detrás de ti (ideal para empezar combos)
	SideLight = {
		startup = 0.12,
		active = 0.12,
		recovery = 0.24,
		damage = 8,
		baseKnockback = 18,
		knockbackScale = 0.3,
		angle = 150,
		hitbox = { offset = Vector2.new(5, 0), size = Vector3.new(8, 4, 6) },
	},

	-- Arco por encima de la cabeza
	UpLight = {
		startup = 0.1,
		active = 0.14,
		recovery = 0.22,
		damage = 7,
		baseKnockback = 24,
		knockbackScale = 0.3,
		angle = 95,
		hitbox = { offset = Vector2.new(1, 5), size = Vector3.new(8, 5, 6) },
	},

	DownLight = {
		startup = 0.1,
		active = 0.12,
		recovery = 0.24,
		damage = 6,
		baseKnockback = 18,
		knockbackScale = 0.16,
		angle = 55,
		hitbox = { offset = Vector2.new(5, -2), size = Vector3.new(9, 2, 6) },
	},

	---------------------------------------------------------------- LIGEROS EN EL AIRE
	-- Molinete en el aire: hitbox grande alrededor
	AirLight = {
		startup = 0.09,
		active = 0.16,
		recovery = 0.2,
		damage = 7,
		baseKnockback = 20,
		knockbackScale = 0.3,
		angle = 45,
		hitbox = { offset = Vector2.new(3, 0), size = Vector3.new(8, 7, 6) },
	},

	AirUpLight = {
		startup = 0.09,
		active = 0.16,
		recovery = 0.2,
		damage = 7,
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = 85,
		hitbox = { offset = Vector2.new(0, 4.5), size = Vector3.new(8, 5, 6) },
	},

	AirDownLight = {
		startup = 0.12,
		active = 0.14,
		recovery = 0.24,
		damage = 8,
		baseKnockback = 18,
		knockbackScale = 0.3,
		angle = -70,
		hitbox = { offset = Vector2.new(1.5, -4), size = Vector3.new(6, 5, 6) },
	},

	---------------------------------------------------------------- PESADOS
	Heavy = {
		startup = 0.36,
		active = 0.16,
		recovery = 0.45,
		damage = 16,
		baseKnockback = 46,
		knockbackScale = 1.0,
		angle = 40,
		hitbox = { offset = Vector2.new(5.5, 0.5), size = Vector3.new(9, 5, 6) },
	},

	UpHeavy = {
		startup = 0.34,
		active = 0.18,
		recovery = 0.45,
		damage = 15,
		baseKnockback = 44,
		knockbackScale = 0.98,
		angle = 88,
		hitbox = { offset = Vector2.new(0, 6), size = Vector3.new(10, 7, 6) },
	},

	-- Barrido enorme a los dos lados
	DownHeavy = {
		startup = 0.3,
		active = 0.18,
		recovery = 0.5,
		damage = 14,
		baseKnockback = 40,
		knockbackScale = 0.92,
		angle = 30,
		awayFromAttacker = true,
		hitbox = { offset = Vector2.new(0, -1.5), size = Vector3.new(15, 3, 6) },
	},

	Recovery = {
		startup = 0.06,
		active = 0.3,
		recovery = 0.4,
		damage = 9,
		baseKnockback = 34,
		knockbackScale = 0.5,
		angle = 80,
		selfImpulse = Vector2.new(4, 80),
		hitbox = { offset = Vector2.new(2, 2), size = Vector3.new(7, 7, 6) },
	},

	GroundPound = {
		startup = 0.14,
		active = 0.35,
		recovery = 0.35,
		damage = 11,
		baseKnockback = 34,
		knockbackScale = 0.62,
		angle = 45,
		awayFromAttacker = true,
		selfImpulse = Vector2.new(0, -85),
		hitbox = { offset = Vector2.new(0, -3), size = Vector3.new(8, 4, 6) },
	},
}

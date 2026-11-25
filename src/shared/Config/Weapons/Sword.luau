-- ReplicatedStorage.Shared.Config.Weapons.Sword
-- Moveset del arma "Espada" (la de Blade por defecto): MÁS alcance pero MÁS lenta
-- que los guanteletes. Mismos 12 ataques y campos que Gauntlets.luau (ver su cabecera).

return {
	---------------------------------------------------------------- LIGEROS EN EL SUELO
	Jab = {
		startup = 0.06,
		active = 0.08,
		recovery = 0.14,
		damage = 5,
		baseKnockback = 16,
		knockbackScale = 0.14,
		angle = 20,
		hitbox = { offset = Vector2.new(3.5, 0.5), size = Vector3.new(6, 3, 6) },
		animationId = nil,
	},

	SideLight = {
		startup = 0.10,
		active = 0.1,
		recovery = 0.21,
		damage = 8,
		baseKnockback = 22,
		knockbackScale = 0.4,
		angle = 25,
		hitbox = { offset = Vector2.new(5, 0.5), size = Vector3.new(7, 3, 6) },
		animationId = nil,
	},

	UpLight = {
		startup = 0.07,
		active = 0.12,
		recovery = 0.18,
		damage = 7,
		baseKnockback = 26,
		knockbackScale = 0.35,
		angle = 85,
		hitbox = { offset = Vector2.new(1, 4.5), size = Vector3.new(6, 5, 6) },
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
		baseKnockback = 72, -- sube casi vertical ~13 studs: a la altura de tu salto
		knockbackScale = 0.06, -- casi igual a cualquier % (golpe de combo, no de remate)
		angle = 80,
		hitbox = { offset = Vector2.new(4.5, -2), size = Vector3.new(7, 2, 6) },
		animationId = nil,
	},

	---------------------------------------------------------------- LIGEROS EN EL AIRE
	AirLight = {
		startup = 0.06,
		active = 0.14,
		recovery = 0.16,
		damage = 7,
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = 40,
		-- arco grande que llega por debajo: atrapa al rival que sube tras la barrida
		hitbox = { offset = Vector2.new(3.5, -1.5), size = Vector3.new(9, 9, 6) },
		animationId = nil,
	},

	AirUpLight = {
		startup = 0.06,
		active = 0.14,
		recovery = 0.16,
		damage = 7,
		baseKnockback = 24,
		knockbackScale = 0.3,
		angle = 80,
		hitbox = { offset = Vector2.new(1, 4.5), size = Vector3.new(7, 5, 6) },
		animationId = nil,
	},

	AirDownLight = {
		startup = 0.08,
		active = 0.14,
		recovery = 0.19,
		damage = 8,
		baseKnockback = 20,
		knockbackScale = 0.3,
		angle = -65,
		hitbox = { offset = Vector2.new(1, -4), size = Vector3.new(5, 5, 6) },
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

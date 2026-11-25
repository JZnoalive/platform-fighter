-- ReplicatedStorage.Shared.Config.CharacterStyles
-- Aspecto de cada luchador en estilo "bloque estilizado" (Opción A, M6).
-- Solo datos, sin lógica. Lo usa AppearanceService (servidor).
-- Diseños y paletas: docs/PERSONAJES.md.
--
-- bodyColors: color (HEX) de cabeza, torso, brazos y piernas del cuerpo R15.
-- gear: piezas que se pegan al cuerpo. Cada pieza:
--   part     = parte del cuerpo R15 a la que se pega ("RightHand", "Head"...)
--   size     = { scale = Vector3, add = Vector3 }  → tamaño = tamañoDeLaParte * scale + add
--   offset   = { scale = Vector3, add = Vector3 }  → posición relativa a la parte
--              (X = derecha, Y = arriba, Z = espalda; el frente de la cara es Z negativo)
--   color    = HEX
--   material = nombre de Enum.Material ("SmoothPlastic", "Metal", "Neon", "Glass"...)
-- Las piezas NO chocan ni cuentan para las hitboxes (CanCollide/CanQuery = false).
--
-- Truco para ajustar: cambia un número, dale Play y mira. Nada más depende de esto.

local ZERO = Vector3.zero

return {
	---------------------------------------------------------------- BRAWLER
	-- "Forja Cinética": guanteletes neumáticos, gafas de soldador, mono gris, botas.
	Brawler = {
		displayName = "Forja",
		-- Estilo leyenda: 2 armas + 4 stats (Fuerza/Destreza/Defensa/Velocidad, suman 22).
		-- Idea de referencia: leyendas de fuerza y remate (tipo Cross). Kit y look propios.
		weapons = { "Gauntlets", "Blasters" },
		stats = { strength = 7, dexterity = 4, defense = 6, speed = 5 },
		hudColor = "D94E28", -- color de su tarjeta en el HUD
		defaultWeapon = "Gauntlets", -- arma con la que aparece (ver WeaponStyles.luau)
		headScale = 1.6, -- cabeza GRANDE (proporción chibi ~1:2,5, legible a distancia)
		bodyColors = {
			head = "E8B796", -- piel
			torso = "EDE6D6", -- camiseta blanco hueso
			arms = "E8B796", -- brazos al aire (camiseta sin mangas)
			legs = "4A4E54", -- mono gris ceniza
		},
		gear = {
			-- (Los guanteletes son un ARMA: están en WeaponStyles.luau)

			-- Pelo oscuro revuelto
			{ name = "Hair", part = "Head",
				size = { scale = Vector3.new(1.06, 0.3, 1.06), add = ZERO },
				offset = { scale = Vector3.new(0, 0.55, 0.03), add = ZERO },
				color = "2B2522", material = "SmoothPlastic" },

			-- Gafas de soldador sobre la frente (cinta de latón + 2 lentes)
			{ name = "GoggleBand", part = "Head",
				size = { scale = Vector3.new(1.08, 0.16, 1.08), add = ZERO },
				offset = { scale = Vector3.new(0, 0.3, 0), add = ZERO },
				color = "C87D4B", material = "Metal" },
			{ name = "LensR", part = "Head",
				size = { scale = Vector3.new(0.24, 0.18, 0.1), add = ZERO },
				offset = { scale = Vector3.new(0.22, 0.3, -0.55), add = ZERO },
				color = "3B3F45", material = "Glass" },
			{ name = "LensL", part = "Head",
				size = { scale = Vector3.new(0.24, 0.18, 0.1), add = ZERO },
				offset = { scale = Vector3.new(-0.22, 0.3, -0.55), add = ZERO },
				color = "3B3F45", material = "Glass" },

			-- Mangas del mono anudadas a la cintura
			{ name = "WaistTie", part = "LowerTorso",
				size = { scale = Vector3.new(1.06, 1.4, 1.12), add = ZERO },
				offset = { scale = ZERO, add = ZERO },
				color = "3E4247", material = "SmoothPlastic" },

			-- Botas industriales
			{ name = "BootR", part = "RightFoot",
				size = { scale = Vector3.new(1.12, 1.4, 1.15), add = ZERO },
				offset = { scale = ZERO, add = Vector3.new(0, 0.05, 0) },
				color = "1E2022", material = "SmoothPlastic" },
			{ name = "BootL", part = "LeftFoot",
				size = { scale = Vector3.new(1.12, 1.4, 1.15), add = ZERO },
				offset = { scale = ZERO, add = Vector3.new(0, 0.05, 0) },
				color = "1E2022", material = "SmoothPlastic" },
		},
	},

	---------------------------------------------------------------- BLADE
	-- "Vórtice Amatista": traje obsidiana, bolero titanio, pelo lavanda, espadón violeta.
	Blade = {
		displayName = "Vórtice",
		-- Idea de referencia: espadachines veloces y frágiles (tipo Jiro). Kit y look propios.
		weapons = { "Sword", "Scythe" },
		stats = { strength = 5, dexterity = 7, defense = 3, speed = 7 },
		hudColor = "7C3AED",
		defaultWeapon = "Sword",
		headScale = 1.55, -- chibi
		bodyColors = {
			head = "F2D7C9", -- piel
			torso = "1E1B2E", -- chaqueta bolero titanio oscuro
			arms = "1E1B2E",
			legs = "110E1B", -- traje obsidiana
		},
		gear = {
			-- Pelo corto en capas, blanco lavanda
			{ name = "HairTop", part = "Head",
				size = { scale = Vector3.new(1.08, 0.35, 1.08), add = ZERO },
				offset = { scale = Vector3.new(0, 0.52, 0.03), add = ZERO },
				color = "DDD6FE", material = "SmoothPlastic" },
			{ name = "HairBack", part = "Head",
				size = { scale = Vector3.new(1.06, 0.65, 0.25), add = ZERO },
				offset = { scale = Vector3.new(0, 0.1, 0.55), add = ZERO },
				color = "DDD6FE", material = "SmoothPlastic" },

			-- Cuello alto estructurado y franja de energía en el pecho
			{ name = "Collar", part = "UpperTorso",
				size = { scale = Vector3.new(0.7, 0.22, 1.15), add = ZERO },
				offset = { scale = Vector3.new(0, 0.58, 0), add = ZERO },
				color = "2A2640", material = "Metal" },
			{ name = "ChestGlow", part = "UpperTorso",
				size = { scale = Vector3.new(0.07, 0.75, 0.06), add = ZERO },
				offset = { scale = Vector3.new(0.25, 0, -0.52), add = ZERO },
				color = "F43F8E", material = "Neon" },

			-- (El espadón es un ARMA: está en WeaponStyles.luau)
		},
	},

	---------------------------------------------------------------- UMBRA
	-- "Umbra": vigía encapuchada que defiende el borde. Idea de referencia: la leyenda
	-- defensiva de guadaña + pistolas (tipo Nix) que pidió el usuario. Diseño PROPIO:
	-- capucha y bufanda turquesa sobre ropa gris pizarra (nada de pelo rubio ni guadaña
	-- de segadora clásica). Paleta 60-30-10: pizarra / turquesa / blanco hueso.
	Umbra = {
		displayName = "Umbra",
		weapons = { "Scythe", "Blasters" },
		stats = { strength = 4, dexterity = 5, defense = 7, speed = 6 },
		hudColor = "2BB5A8",
		defaultWeapon = "Scythe",
		headScale = 1.55, -- chibi
		bodyColors = {
			head = "D9B8A0", -- piel
			torso = "3A4250", -- abrigo pizarra
			arms = "3A4250",
			legs = "262B35",
		},
		gear = {
			-- Capucha (cubre la cabeza por arriba y por detrás)
			{ name = "Hood", part = "Head",
				size = { scale = Vector3.new(1.16, 0.62, 1.12), add = ZERO },
				offset = { scale = Vector3.new(0, 0.34, 0.08), add = ZERO },
				color = "2BB5A8", material = "SmoothPlastic" },
			{ name = "HoodBack", part = "Head",
				size = { scale = Vector3.new(1.1, 0.8, 0.3), add = ZERO },
				offset = { scale = Vector3.new(0, 0, 0.6), add = ZERO },
				color = "23968B", material = "SmoothPlastic" },
			-- Ojos brillantes bajo la capucha (acento del 10 %)
			{ name = "EyeGlowR", part = "Head",
				size = { scale = Vector3.new(0.14, 0.08, 0.06), add = ZERO },
				offset = { scale = Vector3.new(0.2, 0.05, -0.53), add = ZERO },
				color = "F2F6E9", material = "Neon" },
			{ name = "EyeGlowL", part = "Head",
				size = { scale = Vector3.new(0.14, 0.08, 0.06), add = ZERO },
				offset = { scale = Vector3.new(-0.2, 0.05, -0.53), add = ZERO },
				color = "F2F6E9", material = "Neon" },
			-- Bufanda larga turquesa
			{ name = "Scarf", part = "UpperTorso",
				size = { scale = Vector3.new(0.9, 0.25, 1.15), add = ZERO },
				offset = { scale = Vector3.new(0, 0.5, 0), add = ZERO },
				color = "2BB5A8", material = "SmoothPlastic" },
			{ name = "ScarfTail", part = "UpperTorso",
				size = { scale = Vector3.new(0.25, 0.8, 0.12), add = ZERO },
				offset = { scale = Vector3.new(0.25, 0.05, 0.6), add = ZERO },
				color = "23968B", material = "SmoothPlastic" },
			-- Botas altas
			{ name = "BootR", part = "RightFoot",
				size = { scale = Vector3.new(1.1, 1.5, 1.12), add = ZERO },
				offset = { scale = ZERO, add = Vector3.new(0, 0.08, 0) },
				color = "1B1F27", material = "SmoothPlastic" },
			{ name = "BootL", part = "LeftFoot",
				size = { scale = Vector3.new(1.1, 1.5, 1.12), add = ZERO },
				offset = { scale = ZERO, add = Vector3.new(0, 0.08, 0) },
				color = "1B1F27", material = "SmoothPlastic" },
		},
	},

	---------------------------------------------------------------- VOLTA
	-- "Volta": velocista eléctrica, artes marciales con puños y espada corta.
	-- Idea de referencia (solo mecánica): leyendas rápidas de puños + espada que viven
	-- de la presión y la movilidad. Diseño PROPIO: chaqueta corta amarilla eléctrica,
	-- mallas azul marino, coleta blanca y rayos neón. Paleta 60-30-10:
	-- azul marino / amarillo / blanco-cian.
	Volta = {
		displayName = "Volta",
		weapons = { "Gauntlets", "Sword" },
		stats = { strength = 5, dexterity = 6, defense = 4, speed = 7 },
		hudColor = "F5C518",
		defaultWeapon = "Gauntlets",
		headScale = 1.55, -- chibi
		bodyColors = {
			head = "F1C7A5", -- piel
			torso = "F5C518", -- chaqueta amarilla
			arms = "1F2A44", -- mangas azul marino
			legs = "1F2A44",
		},
		gear = {
			-- Pelo blanco con coleta alta
			{ name = "HairTop", part = "Head",
				size = { scale = Vector3.new(1.08, 0.3, 1.08), add = ZERO },
				offset = { scale = Vector3.new(0, 0.56, 0.03), add = ZERO },
				color = "F4F7FB", material = "SmoothPlastic" },
			{ name = "Ponytail", part = "Head",
				size = { scale = Vector3.new(0.3, 0.75, 0.3), add = ZERO },
				offset = { scale = Vector3.new(0, 0.35, 0.68), add = ZERO },
				color = "F4F7FB", material = "SmoothPlastic" },
			-- Cinta en la frente (rayo)
			{ name = "Headband", part = "Head",
				size = { scale = Vector3.new(1.1, 0.12, 1.1), add = ZERO },
				offset = { scale = Vector3.new(0, 0.28, 0), add = ZERO },
				color = "7DF9FF", material = "Neon" },
			-- Rayo neón en el pecho
			{ name = "ChestBolt", part = "UpperTorso",
				size = { scale = Vector3.new(0.12, 0.6, 0.06), add = ZERO },
				offset = { scale = Vector3.new(-0.2, 0, -0.52), add = ZERO },
				color = "7DF9FF", material = "Neon" },
			-- Zapatillas
			{ name = "ShoeR", part = "RightFoot",
				size = { scale = Vector3.new(1.12, 1.25, 1.15), add = ZERO },
				offset = { scale = ZERO, add = Vector3.new(0, 0.04, 0) },
				color = "F4F7FB", material = "SmoothPlastic" },
			{ name = "ShoeL", part = "LeftFoot",
				size = { scale = Vector3.new(1.12, 1.25, 1.15), add = ZERO },
				offset = { scale = ZERO, add = Vector3.new(0, 0.04, 0) },
				color = "F4F7FB", material = "SmoothPlastic" },
		},
	},
}

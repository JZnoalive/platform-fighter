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
		hudColor = "D94E28", -- color de su tarjeta en el HUD
		defaultWeapon = "Gauntlets", -- arma con la que aparece (ver WeaponStyles.luau)
		headScale = 1.18, -- cabeza algo más grande (estilo juego de lucha / anime)
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
		hudColor = "7C3AED",
		defaultWeapon = "Sword",
		headScale = 1.15,
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
}

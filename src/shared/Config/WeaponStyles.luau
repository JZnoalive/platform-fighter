-- ReplicatedStorage.Shared.Config.WeaponStyles
-- Aspecto de cada ARMA (las piezas que se pegan a las manos) y su nombre en el menú.
-- Solo datos. Lo usa AppearanceService (servidor) y el menú de práctica (cliente).
-- Los ataques de cada arma están en Config/Weapons/<Arma>.luau.
--
-- Formato de cada pieza: igual que CharacterStyles.luau, más:
--   rotation = Vector3 en grados (opcional), para piezas inclinadas
--   trail    = HEX (opcional): deja una estela de ese color al moverse (estilo Smash)
-- Mano en reposo: Z negativo = hacia delante, Y negativo = hacia abajo.

local ZERO = Vector3.zero

return {
	-- Orden en el menú de práctica
	Order = { "Gauntlets", "Sword", "Scythe", "Blasters" },

	Gauntlets = {
		label = "Puños",
		gear = {
			{ name = "GauntletR", part = "RightHand",
				size = { scale = Vector3.new(1.45, 0, 1.45), add = Vector3.new(0, 1.15, 0) },
				offset = { scale = ZERO, add = Vector3.new(0, 0.2, 0) },
				color = "D94E28", material = "Metal" },
			{ name = "GauntletL", part = "LeftHand",
				size = { scale = Vector3.new(1.45, 0, 1.45), add = Vector3.new(0, 1.15, 0) },
				offset = { scale = ZERO, add = Vector3.new(0, 0.2, 0) },
				color = "D94E28", material = "Metal" },
			{ name = "CuffR", part = "RightLowerArm",
				size = { scale = Vector3.new(1.25, 0.3, 1.25), add = ZERO },
				offset = { scale = Vector3.new(0, 0.15, 0), add = ZERO },
				color = "C87D4B", material = "Metal" },
			{ name = "CuffL", part = "LeftLowerArm",
				size = { scale = Vector3.new(1.25, 0.3, 1.25), add = ZERO },
				offset = { scale = Vector3.new(0, 0.15, 0), add = ZERO },
				color = "C87D4B", material = "Metal" },
		},
	},

	Sword = {
		label = "Espada",
		gear = {
			-- Espadón apuntando HACIA DELANTE: se ve entero desde la cámara lateral.
			{ name = "SwordGrip", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.3, 0.3, 0.9) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.2, -0.25) },
				color = "1E1B2E", material = "Metal" },
			{ name = "SwordGuard", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.22, 1.0, 0.2) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.2, -0.8) },
				color = "7C3AED", material = "Metal" },
			{ name = "SwordBlade", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.12, 0.6, 4.2) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.2, -3.0) },
				color = "7C3AED", material = "Metal", trail = "F43F8E" },
			{ name = "SwordGlow", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.16, 0.12, 3.6) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.2, -3.1) },
				color = "F43F8E", material = "Neon" },
		},
	},

	Scythe = {
		label = "Guadaña",
		gear = {
			-- Mango largo hacia delante y hoja curvada hacia abajo en la punta.
			{ name = "ScytheShaft", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.25, 0.25, 6) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.2, -1.8) },
				color = "3A2E2A", material = "Wood" },
			{ name = "ScytheCollar", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.4, 0.4, 0.4) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.2, -4.7) },
				color = "C87D4B", material = "Metal" },
			{ name = "ScytheBlade", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.12, 3.2, 0.7) },
				offset = { scale = ZERO, add = Vector3.new(0, -1.5, -4.2) },
				rotation = Vector3.new(-35, 0, 0),
				color = "C9CED6", material = "Metal", trail = "B8F2FF" },
			{ name = "ScytheEdge", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.14, 3.0, 0.1) },
				offset = { scale = ZERO, add = Vector3.new(0, -1.5, -3.85) },
				rotation = Vector3.new(-35, 0, 0),
				color = "7DF9FF", material = "Neon" },
		},
	},

	Blasters = {
		label = "Pistolas",
		gear = {
			{ name = "BlasterBodyR", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.35, 0.6, 1.1) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.3, -0.45) },
				color = "2B2D33", material = "Metal" },
			{ name = "BlasterBarrelR", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.25, 0.25, 0.8) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.15, -1.3) },
				color = "9AA3AE", material = "Metal" },
			{ name = "BlasterGlowR", part = "RightHand",
				size = { scale = ZERO, add = Vector3.new(0.12, 0.12, 0.15) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.15, -1.75) },
				color = "7DF9FF", material = "Neon" },
			{ name = "BlasterBodyL", part = "LeftHand",
				size = { scale = ZERO, add = Vector3.new(0.35, 0.6, 1.1) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.3, -0.45) },
				color = "2B2D33", material = "Metal" },
			{ name = "BlasterBarrelL", part = "LeftHand",
				size = { scale = ZERO, add = Vector3.new(0.25, 0.25, 0.8) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.15, -1.3) },
				color = "9AA3AE", material = "Metal" },
			{ name = "BlasterGlowL", part = "LeftHand",
				size = { scale = ZERO, add = Vector3.new(0.12, 0.12, 0.15) },
				offset = { scale = ZERO, add = Vector3.new(0, -0.15, -1.75) },
				color = "7DF9FF", material = "Neon" },
		},
	},
}

-- ReplicatedStorage.Shared.Config.Poses
-- "Animaciones por código": poses de cada ataque y estado. Solo datos.
-- Las usa PoseController (cliente) para mover las articulaciones R15 sin
-- necesitar animaciones subidas a Roblox.
--
-- Cada ataque tiene 2 poses:
--   windup = preparación (se llega a ella durante el startup)
--   strike = golpe (durante el active; luego vuelve a neutral en el recovery)
-- Valores = grados de giro (X, Y, Z) de cada articulación:
--   X positivo: hombro/cadera → brazo/pierna hacia DELANTE
--               codo → dobla el antebrazo hacia delante · rodilla → NEGATIVO dobla
--               Waist/Neck → NEGATIVO inclina hacia delante
--   Y: gira (torso) · Z: abre el brazo hacia fuera (+ derecho, - izquierdo)
-- Articulaciones: RightShoulder, RightElbow, LeftShoulder, LeftElbow,
--   RightHip, RightKnee, LeftHip, LeftKnee, Waist, Neck
--
-- Para retocar: cambia un número, dale Play y mira. Nada más depende de esto.

local V = Vector3.new

return {
	Moves = {
		Jab = {
			windup = { RightShoulder = V(40, 0, 0), RightElbow = V(70, 0, 0), Waist = V(0, 15, 0) },
			strike = { RightShoulder = V(90, 0, 0), LeftShoulder = V(20, 0, 0), Waist = V(-5, -20, 0) },
		},
		SideLight = {
			windup = { RightShoulder = V(20, 0, 0), RightElbow = V(90, 0, 0), Waist = V(5, 30, 0) },
			strike = {
				RightShoulder = V(95, 0, 0),
				Waist = V(-15, -35, 0),
				RightHip = V(-20, 0, 0),
				LeftHip = V(25, 0, 0),
				LeftKnee = V(-20, 0, 0),
			},
		},
		UpLight = {
			windup = { RightShoulder = V(30, 0, 0), RightElbow = V(90, 0, 0), Waist = V(-10, 0, 0) },
			strike = { RightShoulder = V(170, 0, 0), Waist = V(12, 0, 0), Neck = V(15, 0, 0) },
		},
		DownLight = {
			windup = { Waist = V(-15, 0, 0), RightHip = V(30, 0, 0), LeftKnee = V(-40, 0, 0) },
			strike = { Waist = V(-25, 0, 0), RightHip = V(75, 0, 0), LeftHip = V(-10, 0, 0), LeftKnee = V(-60, 0, 0) },
		},
		AirLight = {
			windup = { RightHip = V(40, 0, 0), RightKnee = V(-70, 0, 0) },
			strike = { RightHip = V(85, 0, 0), Waist = V(10, 0, 0), LeftShoulder = V(-30, 0, 0) },
		},
		AirUpLight = {
			windup = { RightShoulder = V(60, 0, 0), RightElbow = V(60, 0, 0) },
			strike = { RightShoulder = V(175, 0, 0), LeftShoulder = V(150, 0, 0), Waist = V(15, 0, 0) },
		},
		AirDownLight = {
			windup = { RightHip = V(60, 0, 0), RightKnee = V(-90, 0, 0), Waist = V(-10, 0, 0) },
			strike = {
				RightHip = V(-10, 0, 0),
				Waist = V(-30, 0, 0),
				RightShoulder = V(-30, 0, 20),
				LeftShoulder = V(-30, 0, -20),
			},
		},
		Heavy = {
			windup = {
				RightShoulder = V(-40, 0, 0),
				RightElbow = V(80, 0, 0),
				LeftShoulder = V(60, 0, 0),
				Waist = V(10, 40, 0),
			},
			strike = {
				RightShoulder = V(95, 0, 0),
				LeftShoulder = V(-20, 0, 0),
				Waist = V(-20, -45, 0),
				RightHip = V(-25, 0, 0),
				LeftHip = V(30, 0, 0),
			},
		},
		UpHeavy = {
			windup = {
				Waist = V(-20, 0, 0),
				RightShoulder = V(-30, 0, 0),
				LeftShoulder = V(-30, 0, 0),
				RightHip = V(40, 0, 0),
				LeftHip = V(40, 0, 0),
				RightKnee = V(-50, 0, 0),
				LeftKnee = V(-50, 0, 0),
			},
			strike = { RightShoulder = V(180, 0, 0), LeftShoulder = V(170, 0, 0), Waist = V(20, 0, 0), Neck = V(25, 0, 0) },
		},
		DownHeavy = {
			windup = { RightShoulder = V(170, 0, 0), LeftShoulder = V(170, 0, 0), Waist = V(15, 0, 0) },
			strike = {
				RightShoulder = V(70, 0, 0),
				LeftShoulder = V(70, 0, 0),
				Waist = V(-45, 0, 0),
				RightHip = V(40, 0, 0),
				LeftHip = V(40, 0, 0),
				RightKnee = V(-40, 0, 0),
				LeftKnee = V(-40, 0, 0),
			},
		},
		Recovery = {
			windup = { Waist = V(-10, 0, 0) },
			strike = {
				RightShoulder = V(175, 0, 0),
				LeftShoulder = V(-20, 0, 0),
				Waist = V(10, 0, 0),
				RightHip = V(-10, 0, 0),
				LeftHip = V(40, 0, 0),
				LeftKnee = V(-60, 0, 0),
			},
		},
		GroundPound = {
			windup = {
				RightHip = V(80, 0, 0),
				LeftHip = V(80, 0, 0),
				RightKnee = V(-100, 0, 0),
				LeftKnee = V(-100, 0, 0),
				RightShoulder = V(120, 0, 0),
				LeftShoulder = V(120, 0, 0),
			},
			strike = { RightShoulder = V(-40, 0, 0), LeftShoulder = V(-40, 0, 0), Waist = V(-20, 0, 0) },
		},
	},

	-- Poses de estados (se mantienen mientras dura el estado)
	States = {
		Hitstun = {
			Waist = V(25, 0, 0),
			Neck = V(20, 0, 0),
			RightShoulder = V(-40, 0, 40),
			LeftShoulder = V(-40, 0, -40),
			RightHip = V(-20, 0, 0),
			LeftHip = V(30, 0, 0),
		},
		Dodging = {
			Waist = V(-30, 0, 0),
			RightHip = V(70, 0, 0),
			LeftHip = V(70, 0, 0),
			RightKnee = V(-90, 0, 0),
			LeftKnee = V(-90, 0, 0),
			RightShoulder = V(60, 0, 0),
			LeftShoulder = V(60, 0, 0),
		},
	},

	-- Movimiento de la CPU (Roblox no le pone animaciones de andar a los NPC)
	Locomotion = {
		RunHipSwing = 35, -- grados que balancean las piernas al correr
		RunArmSwing = 30,
		RunCycleSpeed = 0.35, -- ciclos por stud recorrido
		Air = {
			RightHip = V(25, 0, 0),
			LeftHip = V(-10, 0, 0),
			RightKnee = V(-40, 0, 0),
			LeftKnee = V(-20, 0, 0),
			RightShoulder = V(20, 0, 20),
			LeftShoulder = V(20, 0, -20),
		},
	},
}

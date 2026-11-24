-- ReplicatedStorage.Shared.Config.Poses
-- "Animaciones por código" estilo Smash: poses exageradas con anticipación
-- (windup), golpe (strike) y vuelta a neutral. Solo datos.
-- Las usa PoseController (cliente), que gira las articulaciones R15.
--
--   Moves   = poses generales (las usan los Puños y cualquier arma sin pose propia)
--   Weapons = poses propias de cada arma (Sword, Scythe, Blasters)
--   spin    = giro de TODO el cuerpo durante el golpe (grados, se reparte en el active)
--
-- Valores = grados (X, Y, Z) de cada articulación:
--   Hombro/cadera X+  → brazo/pierna hacia DELANTE (90 = horizontal, 180 = arriba)
--   Codo X+           → dobla el antebrazo hacia delante · Rodilla X−  → dobla la rodilla
--   Muñeca X−90       → con el brazo estirado, el arma apunta hacia delante
--   Waist/Neck/Root X− → inclina hacia delante · Y → gira el torso · Z → abre de lado
--   Root = todo el cuerpo (inclinarse, voltereta)
-- Articulaciones: Root, Waist, Neck, RightShoulder, RightElbow, RightWrist,
--   LeftShoulder, LeftElbow, LeftWrist, RightHip, RightKnee, LeftHip, LeftKnee
--
-- Para retocar: cambia un número, dale Play y mira. Nada más depende de esto.

local V = Vector3.new

-- Postura agachada de preparación (se mezcla en muchas poses)
local CROUCH = { RightHip = V(25, 0, 0), LeftHip = V(-10, 0, 0), RightKnee = V(-35, 0, 0), LeftKnee = V(-25, 0, 0) }

local function with(base, extra)
	local result = table.clone(base)
	for k, v in extra do
		result[k] = v
	end
	return result
end

return {
	Moves = {
		Jab = {
			windup = with(CROUCH, { RightShoulder = V(45, 0, 0), RightElbow = V(100, 0, 0), Waist = V(0, 25, 0) }),
			strike = {
				Root = V(-8, 0, 0),
				RightShoulder = V(95, 0, 0),
				LeftShoulder = V(30, 0, 0),
				LeftElbow = V(90, 0, 0),
				Waist = V(-8, -30, 0),
				RightHip = V(-15, 0, 0),
				LeftHip = V(25, 0, 0),
				LeftKnee = V(-20, 0, 0),
			},
		},
		SideLight = {
			windup = with(CROUCH, { RightShoulder = V(10, 0, 0), RightElbow = V(110, 0, 0), Waist = V(5, 45, 0), Root = V(5, 0, 0) }),
			strike = {
				Root = V(-15, 0, 0),
				RightShoulder = V(100, 0, 0),
				LeftShoulder = V(-40, 0, 0),
				Waist = V(-15, -50, 0),
				RightHip = V(-30, 0, 0),
				LeftHip = V(45, 0, 0),
				LeftKnee = V(-30, 0, 0),
			},
		},
		UpLight = {
			windup = with(CROUCH, { RightShoulder = V(20, 0, 0), RightElbow = V(110, 0, 0), Waist = V(-15, 0, 0) }),
			strike = { Root = V(10, 0, 0), RightShoulder = V(175, 0, 0), LeftShoulder = V(-20, 0, -20), Waist = V(15, 0, 0), Neck = V(20, 0, 0), LeftHip = V(15, 0, 0) },
		},
		DownLight = {
			windup = { Root = V(-10, 0, 0), Waist = V(-20, 0, 0), RightHip = V(40, 0, 0), RightKnee = V(-60, 0, 0), LeftKnee = V(-50, 0, 0) },
			strike = {
				Root = V(-15, 0, 0),
				Waist = V(-30, 0, 0),
				RightHip = V(85, 0, 0),
				LeftHip = V(-15, 0, 0),
				LeftKnee = V(-70, 0, 0),
				RightShoulder = V(-40, 0, 25),
				LeftShoulder = V(40, 0, -10),
			},
		},
		AirLight = {
			windup = { RightHip = V(50, 0, 0), RightKnee = V(-100, 0, 0), LeftHip = V(20, 0, 0), LeftKnee = V(-60, 0, 0), Root = V(10, 0, 0) },
			strike = { Root = V(-10, 0, 0), RightHip = V(95, 0, 0), LeftHip = V(-20, 0, 0), Waist = V(15, 0, 0), RightShoulder = V(-50, 0, 30), LeftShoulder = V(-50, 0, -30) },
		},
		AirUpLight = {
			windup = { RightShoulder = V(50, 0, 0), RightElbow = V(90, 0, 0), RightHip = V(30, 0, 0), RightKnee = V(-60, 0, 0) },
			strike = { Root = V(15, 0, 0), RightShoulder = V(180, 0, 0), LeftShoulder = V(160, 0, 0), Waist = V(20, 0, 0), Neck = V(25, 0, 0) },
		},
		AirDownLight = {
			windup = { RightHip = V(80, 0, 0), RightKnee = V(-120, 0, 0), Waist = V(-15, 0, 0), RightShoulder = V(60, 0, 20), LeftShoulder = V(60, 0, -20) },
			strike = {
				Root = V(-20, 0, 0),
				RightHip = V(-15, 0, 0),
				RightKnee = V(0, 0, 0),
				Waist = V(-35, 0, 0),
				RightShoulder = V(-40, 0, 30),
				LeftShoulder = V(-40, 0, -30),
			},
		},
		Heavy = {
			windup = with(CROUCH, {
				Root = V(10, 0, 0),
				RightShoulder = V(-60, 0, 0),
				RightElbow = V(100, 0, 0),
				LeftShoulder = V(80, 0, 0),
				Waist = V(10, 60, 0),
			}),
			strike = {
				Root = V(-20, 0, 0),
				RightShoulder = V(100, 0, 0),
				LeftShoulder = V(-30, 0, 0),
				Waist = V(-20, -60, 0),
				RightHip = V(-35, 0, 0),
				LeftHip = V(50, 0, 0),
				LeftKnee = V(-35, 0, 0),
			},
		},
		UpHeavy = {
			windup = {
				Root = V(-10, 0, 0),
				Waist = V(-25, 0, 0),
				RightShoulder = V(-40, 0, 20),
				LeftShoulder = V(-40, 0, -20),
				RightHip = V(60, 0, 0),
				LeftHip = V(60, 0, 0),
				RightKnee = V(-80, 0, 0),
				LeftKnee = V(-80, 0, 0),
			},
			strike = { Root = V(15, 0, 0), RightShoulder = V(180, 0, 0), LeftShoulder = V(175, 0, 0), Waist = V(25, 0, 0), Neck = V(30, 0, 0), RightHip = V(-10, 0, 0) },
		},
		DownHeavy = {
			windup = { Root = V(10, 0, 0), RightShoulder = V(175, 0, 0), LeftShoulder = V(175, 0, 0), Waist = V(20, 0, 0) },
			strike = {
				Root = V(-25, 0, 0),
				RightShoulder = V(60, 0, 20),
				LeftShoulder = V(60, 0, -20),
				Waist = V(-50, 0, 0),
				RightHip = V(60, 0, 0),
				LeftHip = V(60, 0, 0),
				RightKnee = V(-70, 0, 0),
				LeftKnee = V(-70, 0, 0),
			},
		},
		Recovery = {
			windup = { Root = V(-10, 0, 0), RightHip = V(60, 0, 0), LeftHip = V(60, 0, 0), RightKnee = V(-90, 0, 0), LeftKnee = V(-90, 0, 0) },
			strike = { RightShoulder = V(180, 0, 0), LeftShoulder = V(-20, 0, -30), Waist = V(10, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-70, 0, 0) },
			spin = V(-360, 0, 0), -- voltereta hacia delante mientras sube
		},
		GroundPound = {
			windup = {
				Root = V(-20, 0, 0),
				RightHip = V(90, 0, 0),
				LeftHip = V(90, 0, 0),
				RightKnee = V(-120, 0, 0),
				LeftKnee = V(-120, 0, 0),
				RightShoulder = V(150, 0, 0),
				LeftShoulder = V(150, 0, 0),
			},
			strike = { RightShoulder = V(-50, 0, 30), LeftShoulder = V(-50, 0, -30), Waist = V(-25, 0, 0), RightHip = V(10, 0, 0), LeftHip = V(-10, 0, 0) },
		},
	},

	-- Poses propias de cada arma (las que no estén aquí usan Moves)
	Weapons = {
		------------------------------------------------------------ ESPADA
		Sword = {
			Jab = { -- estocada
				windup = with(CROUCH, { RightShoulder = V(60, 0, 0), RightElbow = V(90, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(0, 25, 0) }),
				strike = { Root = V(-12, 0, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(-10, -30, 0), RightHip = V(-20, 0, 0), LeftHip = V(35, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			SideLight = { -- tajo horizontal amplio
				windup = with(CROUCH, { RightShoulder = V(90, 0, 70), RightWrist = V(-90, 0, 0), Waist = V(0, 60, 0) }),
				strike = { Root = V(-15, 0, 0), RightShoulder = V(90, 0, -30), RightWrist = V(-90, 0, 0), Waist = V(-15, -55, 0), RightHip = V(-30, 0, 0), LeftHip = V(45, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			UpLight = { -- tajo hacia arriba
				windup = with(CROUCH, { RightShoulder = V(0, 0, 0), RightWrist = V(0, 0, 0), Waist = V(-15, 0, 0) }),
				strike = { Root = V(10, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-30, 0, 0), Waist = V(15, 0, 0), Neck = V(20, 0, 0) },
			},
			Heavy = { -- tajo cargado de arriba abajo
				windup = with(CROUCH, { Root = V(10, 0, 0), RightShoulder = V(190, 0, 0), RightWrist = V(-40, 0, 0), LeftShoulder = V(170, 0, 0), Waist = V(15, 30, 0) }),
				strike = { Root = V(-25, 0, 0), RightShoulder = V(60, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(40, 0, 0), Waist = V(-30, -40, 0), RightHip = V(-35, 0, 0), LeftHip = V(55, 0, 0), LeftKnee = V(-40, 0, 0) },
			},
			DownHeavy = {
				windup = { Root = V(5, 0, 0), RightShoulder = V(120, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(10, 40, 0) },
				strike = { Root = V(-15, 0, 0), RightShoulder = V(60, 0, 40), RightWrist = V(-90, 0, 0), Waist = V(-30, 0, 0), RightKnee = V(-70, 0, 0), LeftKnee = V(-70, 0, 0), RightHip = V(60, 0, 0), LeftHip = V(60, 0, 0) },
				spin = V(0, 360, 0), -- giro sobre sí misma barriendo los dos lados
			},
		},

		------------------------------------------------------------ GUADAÑA
		Scythe = {
			Jab = {
				windup = with(CROUCH, { RightShoulder = V(40, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(60, 0, 0), Waist = V(0, 30, 0) }),
				strike = { Root = V(-10, 0, 0), RightShoulder = V(85, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(70, 0, 0), Waist = V(-10, -30, 0), LeftHip = V(30, 0, 0) },
			},
			SideLight = { -- gancho: lanza la hoja lejos y tira hacia atrás
				windup = { Root = V(5, 0, 0), RightShoulder = V(150, 0, 0), RightWrist = V(-40, 0, 0), LeftShoulder = V(120, 0, 0), Waist = V(10, 40, 0) },
				strike = { Root = V(10, 0, 0), RightShoulder = V(70, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(50, 0, 0), Waist = V(15, -20, 0), RightHip = V(20, 0, 0), LeftHip = V(-20, 0, 0) },
			},
			AirLight = { -- molinete
				windup = { RightShoulder = V(90, 0, 0), RightWrist = V(-90, 0, 0) },
				strike = { RightShoulder = V(90, 0, 0), RightWrist = V(-90, 0, 0), RightHip = V(30, 0, 0), LeftHip = V(30, 0, 0), RightKnee = V(-60, 0, 0), LeftKnee = V(-60, 0, 0) },
				spin = V(-360, 0, 0),
			},
			Heavy = {
				windup = with(CROUCH, { Root = V(10, 0, 0), RightShoulder = V(200, 0, 0), RightWrist = V(-30, 0, 0), LeftShoulder = V(180, 0, 0), Waist = V(20, 40, 0) }),
				strike = { Root = V(-25, 0, 0), RightShoulder = V(50, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(40, 0, 0), Waist = V(-35, -40, 0), RightHip = V(-35, 0, 0), LeftHip = V(55, 0, 0), LeftKnee = V(-40, 0, 0) },
			},
			DownHeavy = {
				windup = { Root = V(5, 0, 0), RightShoulder = V(110, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(10, 50, 0) },
				strike = { Root = V(-10, 0, 0), RightShoulder = V(70, 0, 30), RightWrist = V(-100, 0, 0), Waist = V(-25, 0, 0), RightKnee = V(-60, 0, 0), LeftKnee = V(-60, 0, 0), RightHip = V(50, 0, 0), LeftHip = V(50, 0, 0) },
				spin = V(0, 360, 0),
			},
		},

		------------------------------------------------------------ PISTOLAS
		Blasters = {
			Jab = { -- disparo rápido con la derecha
				windup = { RightShoulder = V(80, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(0, -10, 0) },
				strike = { Root = V(5, 0, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-80, 0, 0), RightElbow = V(10, 0, 0), Waist = V(5, -20, 0) },
			},
			SideLight = { -- disparo a dos manos con retroceso
				windup = with(CROUCH, { RightShoulder = V(85, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(85, 0, 0), LeftWrist = V(-90, 0, 0) }),
				strike = { Root = V(12, 0, 0), RightShoulder = V(100, 0, 0), RightWrist = V(-80, 0, 0), LeftShoulder = V(100, 0, 0), LeftWrist = V(-80, 0, 0), Waist = V(10, 0, 0), RightHip = V(-15, 0, 0), LeftHip = V(20, 0, 0) },
			},
			UpLight = { -- disparo en diagonal arriba
				windup = { RightShoulder = V(140, 0, 0), RightWrist = V(-90, 0, 0) },
				strike = { Root = V(8, 0, 0), RightShoulder = V(155, 0, 0), RightWrist = V(-85, 0, 0), Waist = V(10, 0, 0), Neck = V(15, 0, 0) },
			},
			AirLight = {
				windup = { RightShoulder = V(85, 0, 0), RightWrist = V(-90, 0, 0), RightKnee = V(-60, 0, 0), LeftKnee = V(-30, 0, 0) },
				strike = { Root = V(8, 0, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-80, 0, 0), RightKnee = V(-60, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			AirUpLight = { -- disparo vertical
				windup = { RightShoulder = V(170, 0, 0), RightWrist = V(-90, 0, 0) },
				strike = { RightShoulder = V(180, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(180, 0, 0), LeftWrist = V(-90, 0, 0), Waist = V(10, 0, 0) },
			},
			AirDownLight = { -- disparo hacia abajo
				windup = { RightShoulder = V(10, 0, 0), RightWrist = V(-90, 0, 0), RightHip = V(40, 0, 0), LeftHip = V(40, 0, 0) },
				strike = { Root = V(-10, 0, 0), RightShoulder = V(0, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(0, 0, 0), LeftWrist = V(-90, 0, 0), RightHip = V(50, 0, 0), LeftHip = V(50, 0, 0), RightKnee = V(-70, 0, 0), LeftKnee = V(-70, 0, 0) },
			},
			Heavy = { -- disparo cargado a dos manos
				windup = with(CROUCH, { Root = V(-8, 0, 0), RightShoulder = V(60, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(60, 0, 0), LeftWrist = V(-90, 0, 0), Waist = V(-10, 0, 0) }),
				strike = { Root = V(18, 0, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(95, 0, 0), LeftWrist = V(-85, 0, 0), Waist = V(15, 0, 0), RightHip = V(-25, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-25, 0, 0) },
			},
			DownHeavy = {
				windup = { Root = V(5, 0, 0), RightShoulder = V(90, 0, 60), LeftShoulder = V(90, 0, -60), Waist = V(0, 30, 0) },
				strike = { Root = V(-15, 0, 0), RightShoulder = V(90, 0, 80), LeftShoulder = V(90, 0, -80), Waist = V(-20, 0, 0), RightKnee = V(-70, 0, 0), LeftKnee = V(-70, 0, 0), RightHip = V(60, 0, 0), LeftHip = V(60, 0, 0) },
				spin = V(0, 360, 0),
			},
			Recovery = { -- dispara hacia abajo y sale disparado
				windup = { RightShoulder = V(10, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(10, 0, 0), LeftWrist = V(-90, 0, 0) },
				strike = { Root = V(10, 0, 0), RightShoulder = V(0, 0, 15), RightWrist = V(-90, 0, 0), LeftShoulder = V(0, 0, -15), LeftWrist = V(-90, 0, 0), RightKnee = V(-40, 0, 0), LeftKnee = V(-20, 0, 0) },
			},
		},
	},

	-- Poses de estados (se mantienen mientras dura el estado)
	States = {
		Hitstun = {
			Root = V(20, 0, 0),
			Waist = V(25, 0, 0),
			Neck = V(25, 0, 0),
			RightShoulder = V(-50, 0, 50),
			LeftShoulder = V(-50, 0, -50),
			RightElbow = V(40, 0, 0),
			LeftElbow = V(40, 0, 0),
			RightHip = V(-25, 0, 0),
			LeftHip = V(35, 0, 0),
			LeftKnee = V(-40, 0, 0),
		},
		Dodging = {
			Root = V(-30, 0, 0),
			Waist = V(-30, 0, 0),
			RightHip = V(90, 0, 0),
			LeftHip = V(90, 0, 0),
			RightKnee = V(-110, 0, 0),
			LeftKnee = V(-110, 0, 0),
			RightShoulder = V(70, 0, 0),
			LeftShoulder = V(70, 0, 0),
			RightElbow = V(90, 0, 0),
			LeftElbow = V(90, 0, 0),
		},
	},

	-- Movimiento de la CPU (Roblox no le pone animaciones de andar a los NPC)
	Locomotion = {
		RunHipSwing = 40, -- grados que balancean las piernas al correr
		RunArmSwing = 35,
		RunCycleSpeed = 0.35, -- ciclos por stud recorrido
		Air = {
			RightHip = V(35, 0, 0),
			LeftHip = V(-10, 0, 0),
			RightKnee = V(-60, 0, 0),
			LeftKnee = V(-25, 0, 0),
			RightShoulder = V(30, 0, 25),
			LeftShoulder = V(30, 0, -25),
		},
	},
}

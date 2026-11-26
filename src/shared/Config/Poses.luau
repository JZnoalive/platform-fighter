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

-- Las 7 fases de un ataque con los tiempos estándar (guardia → 6 poses → guardia):
--   1 anticipación (60 % del arranque) · 2 inicio del avance (fin del arranque)
--   3 extensión (empieza el golpe) · 4 impacto (mitad del golpe)
--   5 seguimiento (30 % de la recuperación) · 6 recuperación (75 %) · 7 neutral
local function sevenKeys(anticipation, start, extension, impact, follow, recover)
	return {
		{ phase = "startup", at = 0, pose = "guard" },
		{ phase = "startup", at = 0.6, pose = anticipation },
		{ phase = "startup", at = 1, pose = start },
		{ phase = "active", at = 0, pose = extension },
		{ phase = "active", at = 0.5, pose = impact },
		{ phase = "recovery", at = 0.3, pose = follow },
		{ phase = "recovery", at = 0.75, pose = recover },
		{ phase = "recovery", at = 1, pose = "guard" },
	}
end

return {
	-- true = TODOS los ataques usan estas poses por código (diseñadas a partir de los
	-- vídeos de referencia) en vez de las animaciones generadas por IA. Las animaciones
	-- de IA solo quedan para guardia, carrera, recibir golpe y esquiva.
	CodePosesForAllAttacks = true,
	-- true = golpe recibido por código (Flinch / voltereta) en vez de la animación de IA.
	CodePosesForStates = true,

	-- GUARDIA de cada arma (pose neutral; PoseController le añade respiración).
	Guard = {
		Sword = { -- agachado, espada baja apuntando adelante-abajo, mano libre en guardia
			Root = V(-4, 0, 0),
			Waist = V(-4, 20, 0),
			RightShoulder = V(30, 0, 10),
			RightElbow = V(35, 0, 0),
			RightWrist = V(-100, 0, 0),
			LeftShoulder = V(35, 0, -15),
			LeftElbow = V(70, 0, 0),
			RightHip = V(18, 0, 0),
			RightKnee = V(-28, 0, 0),
			LeftHip = V(-12, 0, 0),
			LeftKnee = V(-22, 0, 0),
		},
	},

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
			-- GAME FEEL (prueba 1): ataques por FOTOGRAMAS CLAVE en 7 fases. keys manda
			-- sobre windup/strike. phase = "startup" | "active" | "recovery", at = 0..1.
			-- Inclinación de la hoja ≈ Hombro + Codo + Muñeca (0 adelante, 90 arriba,
			-- 180 atrás, negativo abajo).
			Jab = { -- NLight: tajo de arriba hacia delante con paso corto
				keys = {
					{ phase = "startup", at = 0, pose = "guard" },
					{ phase = "startup", at = 0.65, pose = { -- 1 anticipación: hoja atrás y arriba
						Root = V(6, 0, 0), Waist = V(8, 10, 0), RightShoulder = V(155, 0, 5), RightElbow = V(30, 0, 0), RightWrist = V(-20, 0, 0),
						LeftShoulder = V(50, 0, -20), LeftElbow = V(80, 0, 0), RightHip = V(25, 0, 0), RightKnee = V(-40, 0, 0), LeftHip = V(-10, 0, 0), LeftKnee = V(-30, 0, 0) } },
					{ phase = "startup", at = 1, pose = { -- 2 inicio del avance
						Root = V(-6, 0, 0), Waist = V(0, 15, 0), RightShoulder = V(165, 0, 5), RightElbow = V(10, 0, 0), RightWrist = V(-60, 0, 0),
						LeftShoulder = V(40, 0, -20), LeftElbow = V(70, 0, 0), RightHip = V(-5, 0, 0), LeftHip = V(25, 0, 0), LeftKnee = V(-25, 0, 0) } },
					{ phase = "active", at = 0, pose = { -- 3 extensión: la hoja baja por delante
						Root = V(-10, 0, 0), Waist = V(-6, -10, 0), RightShoulder = V(125, 0, 0), RightWrist = V(-85, 0, 0),
						LeftShoulder = V(10, 0, -25), RightHip = V(-20, 0, 0), LeftHip = V(35, 0, 0), LeftKnee = V(-30, 0, 0) } },
					{ phase = "active", at = 0.5, pose = { -- 4 impacto: hoja horizontal al frente
						Root = V(-12, 0, 0), Waist = V(-10, -10, 0), RightShoulder = V(92, 0, 0), RightWrist = V(-92, 0, 0),
						LeftShoulder = V(-20, 0, -25), RightHip = V(-28, 0, 0), RightKnee = V(-10, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-35, 0, 0) } },
					{ phase = "recovery", at = 0.25, pose = { -- 5 seguimiento: la hoja sigue hacia abajo
						Root = V(-10, 0, 0), Waist = V(-14, -14, 0), RightShoulder = V(55, 0, -10), RightWrist = V(-105, 0, 0),
						LeftShoulder = V(-25, 0, -25), RightHip = V(-28, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-35, 0, 0) } },
					{ phase = "recovery", at = 0.7, pose = { -- 6 recuperación
						Root = V(-5, 0, 0), Waist = V(-6, -10, 0), RightShoulder = V(40, 0, 0), RightElbow = V(20, 0, 0), RightWrist = V(-100, 0, 0),
						LeftShoulder = V(20, 0, -20), LeftElbow = V(40, 0, 0), RightHip = V(5, 0, 0), LeftHip = V(10, 0, 0), LeftKnee = V(-25, 0, 0) } },
					{ phase = "recovery", at = 1, pose = "guard" }, -- 7 neutral
				},
				windup = with(CROUCH, { RightShoulder = V(60, 0, 0), RightElbow = V(90, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(0, 25, 0) }),
				strike = { Root = V(-12, 0, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(-10, -30, 0) },
			},
			-- SLight: tajo con AVANCE largo. El arco va EN EL PLANO DE LA PANTALLA (lo que se
			-- ve desde la cámara lateral): de ABAJO-ATRÁS → al frente → ARRIBA (al revés que el
			-- NLight, que baja). Nada de giros hacia la cámara: no se ven de lado.
			SideLight = {
				keys = {
					{ phase = "startup", at = 0, pose = "guard" },
					{ phase = "startup", at = 0.6, pose = { -- 1 anticipación: espada atrás y baja, cuerpo cargado atrás
						Root = V(8, 0, 0), Waist = V(8, 10, 0), RightShoulder = V(-35, 0, 10), RightElbow = V(15, 0, 0), RightWrist = V(-150, 0, 0),
						LeftShoulder = V(70, 0, -15), LeftElbow = V(50, 0, 0), RightHip = V(35, 0, 0), RightKnee = V(-60, 0, 0), LeftHip = V(-15, 0, 0), LeftKnee = V(-40, 0, 0) } },
					{ phase = "startup", at = 1, pose = { -- 2 inicio del avance: se lanza adelante, la espada empieza a subir
						Root = V(-12, 0, 0), Waist = V(-5, 5, 0), RightShoulder = V(20, 0, 5), RightWrist = V(-120, 0, 0),
						LeftShoulder = V(40, 0, -15), LeftElbow = V(40, 0, 0), RightHip = V(-15, 0, 0), LeftHip = V(35, 0, 0), LeftKnee = V(-30, 0, 0) } },
					{ phase = "active", at = 0, pose = { -- 3 extensión: la hoja barre por delante, baja
						Root = V(-18, 0, 0), Waist = V(-10, -5, 0), RightShoulder = V(65, 0, 0), RightWrist = V(-100, 0, 0),
						LeftShoulder = V(-15, 0, -20), RightHip = V(-30, 0, 0), RightKnee = V(-10, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-40, 0, 0) } },
					{ phase = "active", at = 0.5, pose = { -- 4 impacto: hoja horizontal al frente, brazo estirado
						Root = V(-18, 0, 0), Waist = V(-10, -10, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-90, 0, 0),
						LeftShoulder = V(-30, 0, -20), RightHip = V(-30, 0, 0), RightKnee = V(-10, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-40, 0, 0) } },
					{ phase = "recovery", at = 0.25, pose = { -- 5 seguimiento: la hoja sigue subiendo
						Root = V(-10, 0, 0), Waist = V(-4, -10, 0), RightShoulder = V(140, 0, 0), RightWrist = V(-75, 0, 0),
						LeftShoulder = V(-25, 0, -20), RightHip = V(-25, 0, 0), LeftHip = V(45, 0, 0), LeftKnee = V(-35, 0, 0) } },
					{ phase = "recovery", at = 0.7, pose = { -- 6 recuperación: baja la espada
						Root = V(-5, 0, 0), Waist = V(-3, 10, 0), RightShoulder = V(70, 0, 5), RightElbow = V(25, 0, 0), RightWrist = V(-110, 0, 0),
						LeftShoulder = V(25, 0, -15), LeftElbow = V(50, 0, 0), RightHip = V(5, 0, 0), LeftHip = V(10, 0, 0), LeftKnee = V(-25, 0, 0) } },
					{ phase = "recovery", at = 1, pose = "guard" }, -- 7 neutral
				},
				windup = with(CROUCH, { RightShoulder = V(90, 0, 70), RightWrist = V(-90, 0, 0), Waist = V(0, 60, 0) }),
				strike = { Root = V(-15, 0, 0), RightShoulder = V(90, 0, -30), RightWrist = V(-90, 0, 0), Waist = V(-15, -55, 0) },
			},
			-- Golpe 2 de la cadena: tajo ASCENDENTE (abajo-atrás → arriba-delante) con avance.
			Jab2 = {
				keys = sevenKeys(
					{ Root = V(6, 0, 0), Waist = V(6, 5, 0), RightShoulder = V(-25, 0, 10), RightElbow = V(15, 0, 0), RightWrist = V(-150, 0, 0),
						LeftShoulder = V(60, 0, -15), LeftElbow = V(50, 0, 0), RightHip = V(30, 0, 0), RightKnee = V(-55, 0, 0), LeftHip = V(-12, 0, 0), LeftKnee = V(-35, 0, 0) },
					{ Root = V(-8, 0, 0), RightShoulder = V(15, 0, 0), RightWrist = V(-120, 0, 0), LeftShoulder = V(40, 0, -15),
						RightHip = V(-10, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-30, 0, 0) },
					{ Root = V(-12, 0, 0), Waist = V(-6, -5, 0), RightShoulder = V(70, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(-10, 0, -20),
						RightHip = V(-25, 0, 0), RightKnee = V(-10, 0, 0), LeftHip = V(42, 0, 0), LeftKnee = V(-35, 0, 0) },
					{ Root = V(-12, 0, 0), Waist = V(-6, -5, 0), RightShoulder = V(110, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(-25, 0, -20),
						RightHip = V(-25, 0, 0), RightKnee = V(-10, 0, 0), LeftHip = V(42, 0, 0), LeftKnee = V(-35, 0, 0) },
					{ Root = V(-6, 0, 0), RightShoulder = V(150, 0, 0), RightWrist = V(-70, 0, 0), LeftShoulder = V(-20, 0, -20),
						RightHip = V(-20, 0, 0), LeftHip = V(38, 0, 0), LeftKnee = V(-30, 0, 0) },
					{ Root = V(-3, 0, 0), RightShoulder = V(70, 0, 5), RightElbow = V(25, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(25, 0, -15),
						LeftElbow = V(50, 0, 0), RightHip = V(5, 0, 0), LeftHip = V(10, 0, 0), LeftKnee = V(-25, 0, 0) }
				),
			},
			-- Golpe 3 (remate): tajo GRANDE por encima con las dos manos y paso largo.
			Jab3 = {
				keys = sevenKeys(
					{ Root = V(12, 0, 0), Waist = V(14, 5, 0), Neck = V(10, 0, 0), RightShoulder = V(175, 0, 5), RightElbow = V(20, 0, 0), RightWrist = V(-10, 0, 0),
						LeftShoulder = V(150, 0, -10), RightHip = V(30, 0, 0), RightKnee = V(-55, 0, 0), LeftHip = V(-15, 0, 0), LeftKnee = V(-40, 0, 0) },
					{ Root = V(0, 0, 0), RightShoulder = V(175, 0, 0), RightWrist = V(-50, 0, 0), LeftShoulder = V(140, 0, 0),
						RightHip = V(-5, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-30, 0, 0) },
					{ Root = V(-15, 0, 0), Waist = V(-10, 0, 0), RightShoulder = V(130, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(100, 0, 0),
						RightHip = V(-30, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-40, 0, 0) },
					{ Root = V(-22, 0, 0), Waist = V(-15, -5, 0), RightShoulder = V(80, 0, 0), RightWrist = V(-95, 0, 0), LeftShoulder = V(60, 0, 0),
						RightHip = V(-35, 0, 0), RightKnee = V(-10, 0, 0), LeftHip = V(55, 0, 0), LeftKnee = V(-45, 0, 0) },
					{ Root = V(-25, 0, 0), Waist = V(-18, -5, 0), RightShoulder = V(30, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(20, 0, 0),
						RightHip = V(-35, 0, 0), RightKnee = V(-10, 0, 0), LeftHip = V(55, 0, 0), LeftKnee = V(-45, 0, 0) },
					{ Root = V(-10, 0, 0), RightShoulder = V(35, 0, 5), RightElbow = V(25, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(25, 0, -15),
						LeftElbow = V(50, 0, 0), RightHip = V(0, 0, 0), LeftHip = V(20, 0, 0), LeftKnee = V(-30, 0, 0) }
				),
			},
			-- Aéreo lateral: ESTOCADA horizontal (espada recogida al pecho → brazo estirado).
			AirSideLight = {
				keys = sevenKeys(
					{ Root = V(4, 0, 0), Waist = V(5, 5, 0), RightShoulder = V(30, 0, 0), RightElbow = V(100, 0, 0), RightWrist = V(-130, 0, 0), LeftShoulder = V(50, 0, -20),
						RightHip = V(55, 0, 0), RightKnee = V(-95, 0, 0), LeftHip = V(25, 0, 0), LeftKnee = V(-70, 0, 0) },
					{ Root = V(-5, 0, 0), RightShoulder = V(50, 0, 0), RightElbow = V(70, 0, 0), RightWrist = V(-120, 0, 0), LeftShoulder = V(30, 0, -20),
						RightHip = V(50, 0, 0), RightKnee = V(-85, 0, 0), LeftHip = V(20, 0, 0), LeftKnee = V(-60, 0, 0) },
					{ Root = V(-10, 0, 0), RightShoulder = V(80, 0, 0), RightElbow = V(20, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(-10, 0, -25),
						RightHip = V(30, 0, 0), RightKnee = V(-50, 0, 0), LeftHip = V(-10, 0, 0), LeftKnee = V(-35, 0, 0) },
					{ Root = V(-12, 0, 0), RightShoulder = V(92, 0, 0), RightWrist = V(-92, 0, 0), LeftShoulder = V(-30, 0, -25),
						RightHip = V(20, 0, 0), RightKnee = V(-35, 0, 0), LeftHip = V(-20, 0, 0), LeftKnee = V(-30, 0, 0) },
					{ Root = V(-10, 0, 0), RightShoulder = V(90, 0, 0), RightWrist = V(-92, 0, 0), LeftShoulder = V(-25, 0, -25),
						RightHip = V(30, 0, 0), RightKnee = V(-50, 0, 0), LeftHip = V(0, 0, 0), LeftKnee = V(-40, 0, 0) },
					{ Root = V(-4, 0, 0), RightShoulder = V(50, 0, 0), RightElbow = V(30, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(25, 0, -20),
						RightHip = V(45, 0, 0), RightKnee = V(-80, 0, 0), LeftHip = V(25, 0, 0), LeftKnee = V(-60, 0, 0) }
				),
			},
			_JabOld = { -- estocada (versión anterior, sin uso)
				windup = with(CROUCH, { RightShoulder = V(60, 0, 0), RightElbow = V(90, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(0, 25, 0) }),
				strike = { Root = V(-12, 0, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-90, 0, 0), Waist = V(-10, -30, 0), RightHip = V(-20, 0, 0), LeftHip = V(35, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			_SideLightOld = { -- tajo horizontal amplio (versión anterior, sin uso)
				windup = with(CROUCH, { RightShoulder = V(90, 0, 70), RightWrist = V(-90, 0, 0), Waist = V(0, 60, 0) }),
				strike = { Root = V(-15, 0, 0), RightShoulder = V(90, 0, -30), RightWrist = V(-90, 0, 0), Waist = V(-15, -55, 0), RightHip = V(-30, 0, 0), LeftHip = V(45, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			UpLight = { -- LANZADOR VERTICAL: agachado → tajo de abajo hacia arriba por encima de la cabeza
				keys = sevenKeys(
					{ Root = V(-8, 0, 0), Waist = V(-12, 0, 0), RightShoulder = V(20, 0, 0), RightWrist = V(-130, 0, 0), LeftShoulder = V(40, 0, -15), LeftElbow = V(60, 0, 0),
						RightHip = V(45, 0, 0), RightKnee = V(-75, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-65, 0, 0) },
					{ Root = V(-4, 0, 0), RightShoulder = V(60, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(30, 0, -15),
						RightHip = V(25, 0, 0), RightKnee = V(-45, 0, 0), LeftHip = V(15, 0, 0), LeftKnee = V(-40, 0, 0) },
					{ Root = V(4, 0, 0), Waist = V(5, 0, 0), RightShoulder = V(120, 0, 0), RightWrist = V(-80, 0, 0), LeftShoulder = V(0, 0, -20),
						RightHip = V(5, 0, 0), RightKnee = V(-15, 0, 0), LeftHip = V(0, 0, 0), LeftKnee = V(-15, 0, 0) },
					{ Root = V(10, 0, 0), Waist = V(12, 0, 0), Neck = V(15, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(-20, 0, -25),
						RightHip = V(-5, 0, 0), LeftHip = V(10, 0, 0) },
					{ Root = V(12, 0, 0), Waist = V(12, 0, 0), Neck = V(18, 0, 0), RightShoulder = V(185, 0, 0), RightWrist = V(-30, 0, 0), LeftShoulder = V(-20, 0, -25),
						RightHip = V(-5, 0, 0), LeftHip = V(10, 0, 0) },
					{ Root = V(2, 0, 0), RightShoulder = V(80, 0, 0), RightElbow = V(25, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(25, 0, -15),
						RightHip = V(10, 0, 0), RightKnee = V(-20, 0, 0), LeftHip = V(5, 0, 0), LeftKnee = V(-20, 0, 0) }
				),
				windup = with(CROUCH, { RightShoulder = V(0, 0, 0), RightWrist = V(0, 0, 0), Waist = V(-15, 0, 0) }),
				strike = { Root = V(10, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-30, 0, 0), Waist = V(15, 0, 0), Neck = V(20, 0, 0) },
			},
			-- Del vídeo (DLight > salto > SAir): ESTOCADA BAJA agachada. Guardia con la espada
			-- atrás y baja → lunge con la pierna de delante doblada, la de atrás estirada y
			-- la hoja barriendo a ras de suelo.
			DownLight = {
				codePose = true,
				windup = { Root = V(-10, 0, 0), Waist = V(-10, 30, 0), RightShoulder = V(-20, 0, 20), RightWrist = V(-150, 0, 0), LeftShoulder = V(30, 0, -20), RightHip = V(30, 0, 0), RightKnee = V(-55, 0, 0), LeftHip = V(-15, 0, 0), LeftKnee = V(-35, 0, 0) },
				strike = { Root = V(-25, 0, 0), Waist = V(-15, -35, 0), RightShoulder = V(70, 0, 0), RightWrist = V(-58, 0, 0), LeftShoulder = V(-30, 0, -30), RightHip = V(75, 0, 0), RightKnee = V(-85, 0, 0), LeftHip = V(-40, 0, 0), LeftKnee = V(-10, 0, 0) },
			},
			-- Rec/NAir hacia arriba: tajo ascendente en el aire.
			AirUpLight = {
				windup = { Root = V(-5, 0, 0), RightShoulder = V(30, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(20, 0, -20), RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-70, 0, 0) },
				strike = { Root = V(12, 0, 0), Waist = V(15, 0, 0), Neck = V(15, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-35, 0, 0), LeftShoulder = V(-20, 0, -30), RightHip = V(20, 0, 0), RightKnee = V(-40, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-80, 0, 0) },
			},
			-- DAir (prueba 1): estocada en PICADO en diagonal, por fotogramas clave.
			AirDownLight = {
				keys = {
					{ phase = "startup", at = 0, pose = "guard" },
					{ phase = "startup", at = 0.6, pose = { -- 1 anticipación: espada alzada, piernas recogidas
						Root = V(10, 0, 0), Waist = V(10, 20, 0), RightShoulder = V(150, 0, 10), RightWrist = V(-40, 0, 0), LeftShoulder = V(60, 0, -20),
						RightHip = V(70, 0, 0), RightKnee = V(-110, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-100, 0, 0) } },
					{ phase = "startup", at = 1, pose = { -- 2 empieza el picado
						Root = V(-10, 0, 0), Waist = V(0, 10, 0), RightShoulder = V(110, 0, 0), RightWrist = V(-70, 0, 0), LeftShoulder = V(40, 0, -20),
						RightHip = V(40, 0, 0), RightKnee = V(-70, 0, 0), LeftHip = V(20, 0, 0), LeftKnee = V(-60, 0, 0) } },
					{ phase = "active", at = 0, pose = { -- 3 extensión: la hoja apunta abajo-delante
						Root = V(-25, 0, 0), Waist = V(-12, -10, 0), RightShoulder = V(60, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(-20, 0, -30),
						RightHip = V(-10, 0, 0), RightKnee = V(-20, 0, 0), LeftHip = V(-25, 0, 0), LeftKnee = V(-35, 0, 0) } },
					{ phase = "active", at = 0.5, pose = { -- 4 impacto
						Root = V(-30, 0, 0), Waist = V(-15, -15, 0), RightShoulder = V(45, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(-30, 0, -30),
						RightHip = V(-10, 0, 0), RightKnee = V(-15, 0, 0), LeftHip = V(-30, 0, 0), LeftKnee = V(-30, 0, 0) } },
					{ phase = "recovery", at = 0.3, pose = { -- 5 seguimiento
						Root = V(-15, 0, 0), Waist = V(-8, -20, 0), RightShoulder = V(30, 0, 0), RightWrist = V(-95, 0, 0), LeftShoulder = V(-10, 0, -25),
						RightHip = V(20, 0, 0), RightKnee = V(-40, 0, 0), LeftHip = V(10, 0, 0), LeftKnee = V(-40, 0, 0) } },
					{ phase = "recovery", at = 0.7, pose = { -- 6 recuperación
						Root = V(-5, 0, 0), Waist = V(-4, 5, 0), RightShoulder = V(30, 0, 5), RightElbow = V(25, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(25, 0, -15),
						RightHip = V(25, 0, 0), RightKnee = V(-45, 0, 0), LeftHip = V(15, 0, 0), LeftKnee = V(-40, 0, 0) } },
					{ phase = "recovery", at = 1, pose = "guard" }, -- 7 neutral
				},
				windup = { Root = V(10, 0, 0), RightShoulder = V(140, 0, 0), RightWrist = V(-40, 0, 0), LeftShoulder = V(60, 0, -20), RightHip = V(60, 0, 0), RightKnee = V(-100, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-80, 0, 0) },
				strike = { Root = V(-25, 0, 0), Waist = V(-15, -20, 0), RightShoulder = V(45, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(-30, 0, -30), RightHip = V(10, 0, 0), RightKnee = V(-20, 0, 0), LeftHip = V(-20, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			-- Pesado arriba: gran tajo ascendente desde abajo.
			UpHeavy = {
				windup = with(CROUCH, { Root = V(-10, 0, 0), Waist = V(-15, 25, 0), RightShoulder = V(-20, 0, 15), RightWrist = V(-150, 0, 0), RightKnee = V(-70, 0, 0), LeftKnee = V(-60, 0, 0) }),
				strike = { Root = V(15, 0, 0), Waist = V(20, -15, 0), Neck = V(20, 0, 0), RightShoulder = V(175, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(-30, 0, -30), RightHip = V(-15, 0, 0), LeftHip = V(25, 0, 0) },
			},
			Recovery = { -- sube girando con la espada en alto
				windup = { Root = V(-10, 0, 0), RightShoulder = V(20, 0, 0), RightWrist = V(-90, 0, 0), RightHip = V(60, 0, 0), LeftHip = V(60, 0, 0), RightKnee = V(-90, 0, 0), LeftKnee = V(-90, 0, 0) },
				strike = { RightShoulder = V(175, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(-20, 0, -30), Waist = V(10, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-70, 0, 0) },
				spin = V(0, 360, 0),
			},
			GroundPound = { -- cae clavando la espada hacia abajo
				windup = { Root = V(10, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(160, 0, 0), RightHip = V(80, 0, 0), LeftHip = V(80, 0, 0), RightKnee = V(-110, 0, 0), LeftKnee = V(-110, 0, 0) },
				strike = { Root = V(-10, 0, 0), RightShoulder = V(25, 0, 0), RightWrist = V(-115, 0, 0), LeftShoulder = V(20, 0, 0), Waist = V(-20, 0, 0), RightHip = V(10, 0, 0), LeftHip = V(-10, 0, 0) },
			},
			-- SAir: tajo horizontal amplio en el aire (espada por encima del hombro → barrido).
			-- Prueba 1: por fotogramas clave (7 fases), piernas recogidas.
			AirLight = {
				codePose = true,
				keys = {
					{ phase = "startup", at = 0, pose = "guard" },
					-- Arco grande EN EL PLANO DE LA PANTALLA: atrás-arriba → al frente → abajo.
					{ phase = "startup", at = 0.6, pose = { -- 1 anticipación: espada atrás por encima de la cabeza, cuerpo arqueado
						Root = V(10, 0, 0), Waist = V(12, 5, 0), Neck = V(8, 0, 0), RightShoulder = V(170, 0, 10), RightWrist = V(-15, 0, 0), LeftShoulder = V(40, 0, -25),
						RightHip = V(55, 0, 0), RightKnee = V(-95, 0, 0), LeftHip = V(25, 0, 0), LeftKnee = V(-70, 0, 0) } },
					{ phase = "startup", at = 1, pose = { -- 2 impulso hacia delante
						Root = V(-2, 0, 0), Waist = V(4, 0, 0), RightShoulder = V(150, 0, 5), RightWrist = V(-55, 0, 0), LeftShoulder = V(20, 0, -25),
						RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(20, 0, 0), LeftKnee = V(-60, 0, 0) } },
					{ phase = "active", at = 0, pose = { -- 3 extensión: la hoja baja por delante
						Root = V(-10, 0, 0), Waist = V(-6, -5, 0), RightShoulder = V(120, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(-5, 0, -30),
						RightHip = V(40, 0, 0), RightKnee = V(-60, 0, 0), LeftHip = V(-5, 0, 0), LeftKnee = V(-40, 0, 0) } },
					{ phase = "active", at = 0.5, pose = { -- 4 impacto: hoja al frente, cuerpo estirado
						Root = V(-14, 0, 0), Waist = V(-10, -8, 0), RightShoulder = V(92, 0, 0), RightWrist = V(-92, 0, 0), LeftShoulder = V(-25, 0, -30),
						RightHip = V(30, 0, 0), RightKnee = V(-40, 0, 0), LeftHip = V(-15, 0, 0), LeftKnee = V(-35, 0, 0) } },
					{ phase = "recovery", at = 0.3, pose = { -- 5 seguimiento: la hoja sigue hacia abajo
						Root = V(-12, 0, 0), Waist = V(-12, -10, 0), RightShoulder = V(45, 0, 0), RightWrist = V(-105, 0, 0), LeftShoulder = V(-20, 0, -30),
						RightHip = V(45, 0, 0), RightKnee = V(-75, 0, 0), LeftHip = V(15, 0, 0), LeftKnee = V(-55, 0, 0) } },
					{ phase = "recovery", at = 0.75, pose = { -- 6 recuperación
						Root = V(-4, 0, 0), Waist = V(-4, 5, 0), RightShoulder = V(45, 0, 5), RightElbow = V(25, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(25, 0, -20),
						RightHip = V(45, 0, 0), RightKnee = V(-80, 0, 0), LeftHip = V(25, 0, 0), LeftKnee = V(-60, 0, 0) } },
					{ phase = "recovery", at = 1, pose = "guard" }, -- 7 neutral
				},
				windup = { Root = V(5, 0, 0), Waist = V(10, 40, 0), RightShoulder = V(150, 0, 40), RightWrist = V(-40, 0, 0), LeftShoulder = V(40, 0, -30), RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(20, 0, 0), LeftKnee = V(-60, 0, 0) },
				strike = { Root = V(-10, 0, 0), Waist = V(-10, -50, 0), RightShoulder = V(90, 0, -40), RightWrist = V(-90, 0, 0), LeftShoulder = V(-20, 0, -40), RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(-10, 0, 0), LeftKnee = V(-40, 0, 0) },
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

		------------------------------------------------------------ PUÑOS
		-- Del vídeo (sección de puños/garras: DLight > SAir): DLight = lanzamiento bajísimo
		-- con el puño por delante; SAir = gran arco circular alrededor del cuerpo.
		Gauntlets = {
			DownLight = {
				codePose = true,
				windup = with(CROUCH, { Root = V(-10, 0, 0), Waist = V(-10, 30, 0), RightShoulder = V(-30, 0, 15), RightElbow = V(60, 0, 0), LeftShoulder = V(40, 0, -15), LeftElbow = V(90, 0, 0) }),
				strike = { Root = V(-35, 0, 0), Waist = V(-15, -30, 0), RightShoulder = V(80, 0, 0), RightElbow = V(5, 0, 0), LeftShoulder = V(-35, 0, -20), LeftElbow = V(40, 0, 0), RightHip = V(85, 0, 0), RightKnee = V(-95, 0, 0), LeftHip = V(-45, 0, 0), LeftKnee = V(-5, 0, 0) },
			},
			SideLight = { -- puñetazo con todo el cuerpo hacia delante
				codePose = true,
				windup = with(CROUCH, { Root = V(5, 0, 0), Waist = V(5, 45, 0), RightShoulder = V(20, 0, 0), RightElbow = V(120, 0, 0), LeftShoulder = V(60, 0, 0), LeftElbow = V(90, 0, 0) }),
				strike = { Root = V(-20, 0, 0), Waist = V(-12, -50, 0), RightShoulder = V(98, 0, 0), RightElbow = V(0, 0, 0), LeftShoulder = V(-30, 0, -15), LeftElbow = V(70, 0, 0), RightHip = V(-30, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-35, 0, 0) },
			},
			AirLight = { -- arco circular: el puño sube por detrás y baja por delante
				codePose = true,
				windup = { Root = V(10, 0, 0), Waist = V(10, 30, 0), RightShoulder = V(190, 0, 0), RightElbow = V(10, 0, 0), LeftShoulder = V(-20, 0, -20), RightHip = V(60, 0, 0), RightKnee = V(-100, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-70, 0, 0) },
				strike = { Root = V(-15, 0, 0), Waist = V(-15, -30, 0), RightShoulder = V(60, 0, 0), RightElbow = V(0, 0, 0), LeftShoulder = V(-40, 0, -25), RightHip = V(20, 0, 0), RightKnee = V(-30, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-80, 0, 0) },
				spin = V(-360, 0, 0), -- voltereta hacia delante durante el golpe (el arco del vídeo)
			},
		},

		------------------------------------------------------------ GUADAÑA
		-- GANCHOS (codePose = pose diseñada a mano: manda sobre la animación de IA).
		-- Sacados fotograma a fotograma del vídeo de referencia (gancho de guadaña):
		--   windup  = prepara (hoja atrás)          strike = estira la guadaña hacia el rival
		--   hookUp  = la hoja sube y engancha        pull   = recoge los brazos y lo atrae
		--   throw   = gira y lo lanza (adelante o atrás según el active input)
		-- Inclinación del mango ≈ Hombro + Codo + Muñeca (0 = adelante, 90 = arriba,
		-- 180 = atrás, negativo = hacia abajo). La hoja cuelga en la punta del mango.
		Scythe = {
			Jab = { -- gancho POR ARRIBA: alza la guadaña y la baja delante, engancha y tira
				codePose = true,
				windup = with(CROUCH, { Root = V(8, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-50, 0, 0), LeftShoulder = V(160, 0, 0), Waist = V(12, 20, 0), Neck = V(10, 0, 0) }),
				strike = { Root = V(-18, 0, 0), RightShoulder = V(85, 0, 0), RightWrist = V(-120, 0, 0), LeftShoulder = V(75, 0, 0), Waist = V(-15, -15, 0), RightHip = V(-15, 0, 0), LeftHip = V(35, 0, 0), LeftKnee = V(-30, 0, 0) },
				hookUp = { Root = V(8, 0, 0), RightShoulder = V(150, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(140, 0, 0), Waist = V(15, 10, 0), Neck = V(10, 0, 0) },
				pull = with(CROUCH, { Root = V(15, 0, 0), RightShoulder = V(30, 0, 0), RightElbow = V(90, 0, 0), RightWrist = V(60, 0, 180), LeftShoulder = V(20, 0, 0), LeftElbow = V(100, 0, 0), Waist = V(10, 45, 0) }),
				throw = { Root = V(-8, 0, 0), RightShoulder = V(100, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(80, 0, 0), Waist = V(-15, -55, 0), RightHip = V(-25, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			SideLight = { -- gancho LATERAL: estira la guadaña lejos, engancha, arrastra y lanza
				codePose = true,
				windup = with(CROUCH, { Root = V(-5, 0, 0), RightShoulder = V(70, 0, 0), RightWrist = V(130, 0, 180), LeftShoulder = V(70, 0, 0), Waist = V(5, 35, 0) }),
				strike = { Root = V(-20, 0, 0), RightShoulder = V(100, 0, 0), RightWrist = V(-80, 0, 0), LeftShoulder = V(95, 0, 0), Waist = V(-12, -25, 0), RightHip = V(-25, 0, 0), LeftHip = V(45, 0, 0), LeftKnee = V(-35, 0, 0) },
				hookUp = { Root = V(10, 0, 0), RightShoulder = V(150, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(140, 0, 0), Waist = V(15, 10, 0), Neck = V(10, 0, 0), RightHip = V(-10, 0, 0), LeftHip = V(20, 0, 0) },
				pull = with(CROUCH, { Root = V(15, 0, 0), RightShoulder = V(30, 0, 0), RightElbow = V(90, 0, 0), RightWrist = V(60, 0, 180), LeftShoulder = V(20, 0, 0), LeftElbow = V(100, 0, 0), Waist = V(10, 45, 0) }),
				throw = { Root = V(-8, 0, 0), RightShoulder = V(100, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(80, 0, 0), Waist = V(-15, -55, 0), RightHip = V(-25, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-30, 0, 0) },
			},
			AirLight = { -- gancho AÉREO: como en el vídeo (hoja atrás → engancha arriba → atrae → lanza)
				codePose = true,
				windup = { Root = V(-10, 0, 0), RightShoulder = V(70, 0, 0), RightWrist = V(130, 0, 180), LeftShoulder = V(70, 0, 0), Waist = V(0, 30, 0), RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-70, 0, 0) },
				strike = { Root = V(-15, 0, 0), RightShoulder = V(100, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(95, 0, 0), Waist = V(-10, -20, 0), RightHip = V(40, 0, 0), RightKnee = V(-80, 0, 0), LeftHip = V(-10, 0, 0), LeftKnee = V(-30, 0, 0) },
				hookUp = { Root = V(12, 0, 0), RightShoulder = V(150, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(140, 0, 0), Waist = V(15, 10, 0), RightHip = V(30, 0, 0), RightKnee = V(-60, 0, 0), LeftHip = V(10, 0, 0), LeftKnee = V(-50, 0, 0) },
				pull = { Root = V(15, 0, 0), RightShoulder = V(30, 0, 0), RightElbow = V(90, 0, 0), RightWrist = V(60, 0, 180), LeftShoulder = V(20, 0, 0), LeftElbow = V(100, 0, 0), Waist = V(10, 50, 0), RightHip = V(60, 0, 0), RightKnee = V(-100, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-90, 0, 0) },
				throw = { Root = V(-10, 0, 0), RightShoulder = V(100, 0, 0), RightWrist = V(-85, 0, 0), LeftShoulder = V(80, 0, 0), Waist = V(-15, -60, 0), RightHip = V(20, 0, 0), RightKnee = V(-40, 0, 0), LeftHip = V(45, 0, 0), LeftKnee = V(-50, 0, 0) },
			},
			AirDownLight = { -- gancho HACIA ABAJO: la hoja baja, engancha por debajo y lo clava
				codePose = true,
				windup = { Root = V(10, 0, 0), RightShoulder = V(150, 0, 0), RightWrist = V(-40, 0, 0), LeftShoulder = V(140, 0, 0), RightHip = V(40, 0, 0), RightKnee = V(-80, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-80, 0, 0) },
				strike = { Root = V(-25, 0, 0), RightShoulder = V(30, 0, 0), RightWrist = V(-55, 0, 0), LeftShoulder = V(25, 0, 0), Waist = V(-20, 0, 0), RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-90, 0, 0) },
				hookUp = { Root = V(-10, 0, 0), RightShoulder = V(80, 0, 0), RightWrist = V(-80, 0, 0), LeftShoulder = V(70, 0, 0), Waist = V(-10, 15, 0), RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-90, 0, 0) },
				pull = { Root = V(10, 0, 0), RightShoulder = V(30, 0, 0), RightElbow = V(90, 0, 0), RightWrist = V(40, 0, 180), LeftShoulder = V(20, 0, 0), LeftElbow = V(100, 0, 0), Waist = V(10, 40, 0), RightHip = V(60, 0, 0), RightKnee = V(-100, 0, 0), LeftHip = V(60, 0, 0), LeftKnee = V(-100, 0, 0) },
				throw = { Root = V(-30, 0, 0), RightShoulder = V(40, 0, 0), RightWrist = V(-110, 0, 0), LeftShoulder = V(30, 0, 0), Waist = V(-25, -40, 0), RightHip = V(30, 0, 0), RightKnee = V(-50, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-60, 0, 0) },
			},
			UpLight = { -- arco por encima de la cabeza: la hoja sube desde delante hacia atrás
				windup = with(CROUCH, { Root = V(-5, 0, 0), RightShoulder = V(40, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(35, 0, 0), Waist = V(-10, 0, 0) }),
				strike = { Root = V(10, 0, 0), Waist = V(12, 0, 0), Neck = V(15, 0, 0), RightShoulder = V(175, 0, 0), RightWrist = V(-20, 0, 0), LeftShoulder = V(165, 0, 0), RightHip = V(-10, 0, 0), LeftHip = V(15, 0, 0) },
			},
			AirUpLight = { -- el mismo arco en el aire
				windup = { Root = V(-5, 0, 0), RightShoulder = V(40, 0, 0), RightWrist = V(-100, 0, 0), LeftShoulder = V(35, 0, 0), RightHip = V(50, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-70, 0, 0) },
				strike = { Root = V(12, 0, 0), Waist = V(12, 0, 0), RightShoulder = V(175, 0, 0), RightWrist = V(-20, 0, 0), LeftShoulder = V(165, 0, 0), RightHip = V(30, 0, 0), RightKnee = V(-60, 0, 0), LeftHip = V(50, 0, 0), LeftKnee = V(-90, 0, 0) },
			},
			-- FIRMA "Rueda celeste": la guadaña gira en horizontal por encima de la cabeza.
			UpHeavy = {
				windup = with(CROUCH, { RightShoulder = V(120, 0, 0), RightWrist = V(-120, 0, 0), LeftShoulder = V(110, 0, 0) }),
				strike = { Root = V(5, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-170, 0, 0), LeftShoulder = V(165, 0, 0), Neck = V(15, 0, 0), RightHip = V(-10, 0, 0), LeftHip = V(15, 0, 0) },
				spin = V(0, 720, 0),
			},
			Recovery = { -- sube girando con la guadaña en alto
				windup = { Root = V(-10, 0, 0), RightShoulder = V(40, 0, 0), RightWrist = V(-100, 0, 0), RightHip = V(60, 0, 0), LeftHip = V(60, 0, 0), RightKnee = V(-90, 0, 0), LeftKnee = V(-90, 0, 0) },
				strike = { Root = V(8, 0, 0), RightShoulder = V(175, 0, 0), RightWrist = V(-20, 0, 0), LeftShoulder = V(165, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-60, 0, 0) },
				spin = V(0, 360, 0),
			},
			GroundPound = { -- cae con la hoja apuntando abajo
				windup = { Root = V(10, 0, 0), RightShoulder = V(170, 0, 0), RightWrist = V(-50, 0, 0), LeftShoulder = V(160, 0, 0), RightHip = V(80, 0, 0), LeftHip = V(80, 0, 0), RightKnee = V(-110, 0, 0), LeftKnee = V(-110, 0, 0) },
				strike = { Root = V(-15, 0, 0), RightShoulder = V(30, 0, 0), RightWrist = V(-120, 0, 0), LeftShoulder = V(25, 0, 0), Waist = V(-20, 0, 0) },
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
			-- Del vídeo (DLight > SLight): guardia con las dos pistolas EN ALTO junto a los
			-- hombros → SLight: brazo derecho estirado al frente disparando, la otra pistola
			-- sigue en alto.
			SideLight = {
				codePose = true,
				windup = { RightShoulder = V(30, 0, 0), RightElbow = V(120, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(30, 0, 0), LeftElbow = V(120, 0, 0), LeftWrist = V(-60, 0, 0), Waist = V(0, 10, 0) },
				strike = { Root = V(5, 0, 0), Waist = V(0, -25, 0), RightShoulder = V(95, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(30, 0, 0), LeftElbow = V(120, 0, 0), LeftWrist = V(-60, 0, 0), RightHip = V(-15, 0, 0), LeftHip = V(20, 0, 0) },
			},
			-- FIRMA "Cometa oblicuo": disparo cargado doble en DIAGONAL hacia arriba.
			UpHeavy = {
				windup = with(CROUCH, { Root = V(-8, 0, 0), RightShoulder = V(20, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(20, 0, 0), LeftWrist = V(-90, 0, 0), Waist = V(-10, 0, 0) }),
				strike = { Root = V(12, 0, 0), Waist = V(12, 0, 0), RightShoulder = V(135, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(130, 0, 0), LeftWrist = V(-90, 0, 0), RightHip = V(-20, 0, 0), LeftHip = V(25, 0, 0) },
			},
			-- FIRMA "Lluvia de balas": gira disparando adelante y atrás a la vez.
			DownHeavy = {
				windup = with(CROUCH, { RightShoulder = V(30, 0, 0), RightElbow = V(120, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(30, 0, 0), LeftElbow = V(120, 0, 0), LeftWrist = V(-60, 0, 0) }),
				strike = with(CROUCH, { RightShoulder = V(85, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(-80, 0, 0), LeftWrist = V(-90, 0, 0), Waist = V(0, 0, 0) }),
				spin = V(0, 360, 0),
			},
			Recovery = { -- dispara las dos hacia abajo y sale impulsada
				windup = { RightShoulder = V(60, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(60, 0, 0), LeftWrist = V(-90, 0, 0), RightHip = V(50, 0, 0), LeftHip = V(50, 0, 0), RightKnee = V(-80, 0, 0), LeftKnee = V(-80, 0, 0) },
				strike = { Root = V(5, 0, 0), RightShoulder = V(5, 0, 10), RightWrist = V(-90, 0, 0), LeftShoulder = V(5, 0, -10), LeftWrist = V(-90, 0, 0), RightHip = V(20, 0, 0), LeftHip = V(-10, 0, 0), RightKnee = V(-40, 0, 0), LeftKnee = V(-20, 0, 0) },
			},
			GroundPound = { -- cae en picado disparando abajo
				windup = { Root = V(10, 0, 0), RightShoulder = V(150, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(150, 0, 0), LeftWrist = V(-90, 0, 0), RightHip = V(80, 0, 0), LeftHip = V(80, 0, 0), RightKnee = V(-110, 0, 0), LeftKnee = V(-110, 0, 0) },
				strike = { Root = V(-15, 0, 0), RightShoulder = V(0, 0, 15), RightWrist = V(-90, 0, 0), LeftShoulder = V(0, 0, -15), LeftWrist = V(-90, 0, 0), Waist = V(-15, 0, 0) },
			},
			-- DLight: agachada, dispara las DOS pistolas al suelo delante (explosión a ras de
			-- suelo que levanta al rival).
			DownLight = {
				codePose = true,
				windup = with(CROUCH, { RightShoulder = V(30, 0, 0), RightElbow = V(120, 0, 0), RightWrist = V(-60, 0, 0), LeftShoulder = V(30, 0, 0), LeftElbow = V(120, 0, 0), LeftWrist = V(-60, 0, 0) }),
				strike = with(CROUCH, { Root = V(-12, 0, 0), Waist = V(-15, 0, 0), RightShoulder = V(55, 0, 0), RightWrist = V(-90, 0, 0), LeftShoulder = V(50, 0, 0), LeftWrist = V(-90, 0, 0), RightKnee = V(-55, 0, 0), LeftKnee = V(-45, 0, 0) }),
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
		-- Golpe recibido (por código): cuerpo doblado hacia atrás, cabeza atrás, brazos
		-- lanzados. PoseController lo exagera el primer instante y lo orienta según el empujón.
		Flinch = {
			Root = V(14, 0, 0),
			Waist = V(16, 0, 0),
			Neck = V(22, 0, 0),
			RightShoulder = V(55, 0, 35),
			RightElbow = V(45, 0, 0),
			LeftShoulder = V(50, 0, -35),
			LeftElbow = V(45, 0, 0),
			RightHip = V(-20, 0, 0),
			LeftHip = V(25, 0, 0),
			RightKnee = V(-25, 0, 0),
			LeftKnee = V(-30, 0, 0),
		},
		TumbleForce = 55, -- desde esta fuerza de knockback, el golpeado da vueltas
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

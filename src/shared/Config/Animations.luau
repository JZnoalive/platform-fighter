-- ReplicatedStorage.Shared.Config.Animations
-- Animaciones REALES (generadas con la IA de animación de Roblox Studio y publicadas
-- en la cuenta del juego). Solo datos. Las reproduce AnimationController (cliente).
-- Si un ataque no tiene animación aquí, se usa la pose por código (Poses.luau).
--
-- Cada animación se acelera o frena para durar EXACTAMENTE lo que dura el ataque
-- (startup + active + recovery del arma).
--
-- Para cambiar una: genera otra (MCP generate_animation o Animation Editor),
-- publícala y pega aquí su número.

local function id(n: string): string
	return "rbxassetid://" .. n
end

-- Puños y cualquier arma que no tenga animación propia para ese ataque
local Generic = {
	Jab = id("76014938078107"),
	SideLight = id("133360031205335"),
	UpLight = id("116478083673590"),
	DownLight = id("89968651640734"),
	AirLight = id("132189254264617"),
	AirUpLight = id("137303595544589"),
	AirDownLight = id("109410855431473"),
	Heavy = id("131910110710240"),
	UpHeavy = id("92814675104539"),
	DownHeavy = id("124485361819962"),
	Recovery = id("108465923845727"),
	GroundPound = id("99684280119349"),
}

return {
	Generic = Generic,

	Weapons = {
		Sword = {
			Jab = id("109135252300662"), -- estocada
			SideLight = id("82609297914310"), -- tajo horizontal
			Heavy = id("104874432987752"), -- tajo de arriba abajo
			UpHeavy = id("140698507131074"), -- tajo ascendente
			DownHeavy = id("73745453402403"), -- barrido giratorio
			AirLight = id("102763966056762"), -- tajo aéreo
		},
		Scythe = {
			Jab = id("109135252300662"),
			SideLight = id("118566435346767"), -- gancho
			Heavy = id("127228647128175"), -- siega
			UpHeavy = id("140698507131074"),
			DownHeavy = id("73745453402403"),
			AirLight = id("95291582466285"), -- molinete
		},
		Blasters = {
			Jab = id("100487347006444"), -- disparo
			SideLight = id("140597224218137"), -- disparo a dos manos
			UpLight = id("106843415329953"), -- disparo en diagonal
			AirLight = id("100487347006444"),
			AirUpLight = id("106843415329953"),
			AirDownLight = id("79800723593387"), -- disparo hacia abajo
			Heavy = id("138878990500930"), -- disparo cargado
			UpHeavy = id("106843415329953"), -- "Cometa oblicuo": disparo en diagonal
			Recovery = id("79800723593387"),
		},
	},

	States = {
		Hurt = id("96869492742527"), -- recibir golpe (hitstun)
		Dodge = id("70768391376247"), -- esquiva
		Idle = id("81974576353404"), -- guardia (en bucle)
		Run = id("92951788262415"), -- correr (en bucle)
		Victory = id("122727500701735"), -- pose de victoria
	},
}

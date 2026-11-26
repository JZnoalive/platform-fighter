-- ReplicatedStorage.Shared.Config.AudioConfig
-- IDs de sonido. Vacío ("") = no suena (no da error). Solo números.
-- Todos son audios GRATIS reales de la Creator Store de Roblox (buscados con el MCP
-- de Studio el 2026-11-25). Si alguno deja de cargar, cámbialo por otro de la tienda.

return {
	Volume = 0.6,

	-- "Sword Slash / Sword Hit" (creador 1dTb4)
	HitLight = "106888836265705",
	-- "Hit - Punch - Impact - Blunt - Debris - Downslam" (creador lorenzosaudiostash)
	HitHeavy = "79476956608476",
	-- "Wood Whoosh Slicing Air Quick Swings 1 (SFX)" (ProSoundEffects): tajo al aire
	Swing = "9120972444",
	KO = "",
	FightStart = "",
	Victory = "",
	Dodge = "",

	-- Música de combate (en bucle). Vacío = sin música.
	MusicBattle = "",
	MusicVolume = 0.25,
}

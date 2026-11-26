-- ReplicatedStorage.Shared.Config.CameraConfig
-- Ajustes de la cámara lateral. Solo datos, sin lógica.

local CameraConfig = {
	-- Look 2D estilo Brawlhalla: cámara MUY lejos con FOV muy bajo = casi sin perspectiva
	-- (parece un plano dibujado), y totalmente de lado.
	-- GAME FEEL (prueba 1): cámara CERCANA para leer cada acción. Con FOV 20 a 62 studs
	-- se ven ~22 studs de alto (antes ~35): los personajes salen el doble de grandes.
	FieldOfView = 20, -- grados; bajo = poca perspectiva (look plano)
	MinDistance = 62, -- lo más cerca que puede estar la cámara
	MaxDistance = 160, -- lo más lejos (cuando los luchadores se separan mucho)
	Padding = 8, -- espacio libre alrededor de los luchadores (studs)
	HeightOffset = 3, -- sube un poco el encuadre
	VerticalSmoothing = 2.5, -- la altura sigue MÁS DESPACIO que el lado (sin tirones al saltar)
	VerticalFollow = 0.55, -- 0..1: cuánto sube la cámara cuando alguien salta (1 = todo)
	Pitch = 1.5, -- casi de lado puro (en 2D no se ve el suelo desde arriba)
	FocusRadius = 45, -- zona nítida alrededor del plano de pelea (studs)
	BackgroundBlur = 0.35, -- desenfoque del fondo (0 = nada, 1 = mucho)
	Smoothing = 6, -- mayor = la cámara sigue más rápido
	EmptyFocus = Vector3.new(0, 10, 0), -- a dónde mira si no hay nadie
}

return CameraConfig

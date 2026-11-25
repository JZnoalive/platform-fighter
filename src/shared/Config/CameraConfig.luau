-- ReplicatedStorage.Shared.Config.CameraConfig
-- Ajustes de la cámara lateral. Solo datos, sin lógica.

local CameraConfig = {
	-- Look 2D estilo Brawlhalla: cámara MUY lejos con FOV muy bajo = casi sin perspectiva
	-- (parece un plano dibujado), y totalmente de lado.
	FieldOfView = 16, -- grados; bajo = menos efecto de perspectiva (look plano 2D)
	MinDistance = 175, -- lo más cerca que puede estar la cámara (escala con el FOV)
	MaxDistance = 320, -- lo más lejos que puede estar la cámara
	Padding = 14, -- espacio libre alrededor de los luchadores (studs)
	HeightOffset = 9, -- encuadre más alto: se ve la isla entera y mucho cielo
	Pitch = 1.5, -- casi de lado puro (en 2D no se ve el suelo desde arriba)
	FocusRadius = 45, -- zona nítida alrededor del plano de pelea (studs)
	BackgroundBlur = 0.35, -- desenfoque del fondo (0 = nada, 1 = mucho)
	Smoothing = 6, -- mayor = la cámara sigue más rápido
	EmptyFocus = Vector3.new(0, 10, 0), -- a dónde mira si no hay nadie
}

return CameraConfig

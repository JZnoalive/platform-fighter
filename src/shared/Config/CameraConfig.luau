-- ReplicatedStorage.Shared.Config.CameraConfig
-- Ajustes de la cámara lateral. Solo datos, sin lógica.

local CameraConfig = {
	FieldOfView = 35, -- grados; bajo = menos efecto de perspectiva
	MinDistance = 55, -- lo más cerca que puede estar la cámara
	MaxDistance = 120, -- lo más lejos que puede estar la cámara
	Padding = 12, -- espacio libre alrededor de los luchadores (studs)
	HeightOffset = 4, -- sube un poco el encuadre
	Pitch = 9, -- grados mirando desde arriba (estilo Smash: se ve el suelo de las plataformas)
	FocusRadius = 45, -- zona nítida alrededor del plano de pelea (studs)
	BackgroundBlur = 0.35, -- desenfoque del fondo (0 = nada, 1 = mucho)
	Smoothing = 6, -- mayor = la cámara sigue más rápido
	EmptyFocus = Vector3.new(0, 10, 0), -- a dónde mira si no hay nadie
}

return CameraConfig

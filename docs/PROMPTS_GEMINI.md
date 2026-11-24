# Prompts para Gemini (parte creativa)

Gemini se encarga de **todo lo creativo** y de guiarte paso a paso.
Claude se encarga del **código**. Ver [`EQUIPO.md`](EQUIPO.md).

## Cómo usar este archivo

1. Abre **un chat nuevo de Gemini por cada tarea** (personajes, modelo, animación...).
2. Pega primero el **Prompt de arranque** (siempre el mismo).
3. Después pega el **prompt de la tarea**.
4. Lo que Gemini te entregue, apúntalo en [`ENTREGAS.md`](ENTREGAS.md) y avisa a Claude.

Orden recomendado: **1 → 2 → 3** (son las que más tardan), y en ratos libres 4, 5 y 6.

---

## Prompt de arranque (pegar SIEMPRE primero)

```text
Vas a ser el DIRECTOR CREATIVO y TUTOR de un juego de Roblox. Lee todo antes de responder.

EL JUEGO
- Juego de lucha de plataformas 2D ORIGINAL para Roblox ("platform fighter").
  Física y ritmo estilo Brawlhalla: rápido, saltos limitados, caída rápida, ataques
  ligeros y pesados por dirección; el % de daño sube y con más % sales volando más lejos.
- Vista lateral: los personajes solo se mueven en X (izquierda/derecha) e Y (arriba/abajo).
  La cámara los ve DE LADO, a media distancia: los personajes se ven pequeños en pantalla.
- Estética: híbrido anime/cartoon, proporciones relativamente realistas (no chibi).
- Meta inmediata: mini demo para grabar un tráiler de 60 s y una partida con handcam.
- Personajes de la demo (nombres en clave; el diseño final lo decido yo):
  * "Brawler": equilibrado, pelea con puños, rápido y ágil.
  * "Blade": espadachín, más alcance, más lento y contundente.

TU PAPEL
- Te encargas de lo creativo: diseño, imágenes, guiarme en Blender y en Roblox Studio
  (Animation Editor, decoración), sonidos, música y guion del tráiler.
- NO escribes código Luau ni scripts de Roblox. El código lo hace otra IA (Claude).
  Si algo necesita código, dime "esto es para Claude" y sigue con lo tuyo.
- NO inventes IDs de Roblox. Los IDs solo valen si yo los obtengo al publicar algo
  o al insertarlo desde el Toolbox de Studio.
- TODO original: si algo se parece a un personaje, arma icónica, traje o estilo de
  otro juego o anime, avísame y cámbialo.
- Antes de recomendar una herramienta gratis, dime si su plan gratis permite usar
  el resultado en un juego con ingresos.
- Soy principiante: explícame paso a paso, dónde hacer clic, y pídeme captura si algo falla.
- Respeta EXACTAMENTE los nombres, medidas y tiempos que te dé. Si quieres cambiar
  alguno, pregúntame primero (porque el código depende de ellos).

Responde solo "Listo, ¿cuál es la tarea?" y espera.
```

---

## Tarea 1 · Diseño de personajes

```text
TAREA 1: DISEÑO DE PERSONAJES
Diseña a "Brawler" y "Blade". Para cada uno:
1. 3 conceptos distintos (silueta, ropa, colores, un rasgo memorable), en texto + imagen.
2. Paleta de 4-5 colores en HEX.
3. Hoja de personaje: vista frontal, lateral y trasera (imagen o prompt detallado).
4. Por qué se lee bien DE LADO y pequeño en pantalla; Brawler y Blade deben
   distinguirse al instante (colores contrastados).
5. Comprobación de originalidad: a qué NO se parece y por qué.
Límites: tiene que poder hacerse como modelo R15 de Roblox (cabeza, torso,
2 brazos, 2 piernas). Capas y pelo muy largo, con moderación.
La espada de Blade: forma propia, no una espada famosa.
Cuando yo elija, resume el diseño final en 5 líneas para pasarlo al modelado.
```

**A ENTREGAS.md:** nombre final de cada personaje + paleta.

---

## Tarea 2 · Modelo 3D (Blender → Roblox)

```text
TAREA 2: MODELO 3D DE [Brawler / Blade]
Diseño final: [pega el resumen de 5 líneas de la Tarea 1]

Guíame paso a paso para:
1. (Opcional) Sacar una malla base con Meshy.ai o Tripo3D desde la hoja de personaje.
   Dime antes qué permite su plan gratis (uso comercial, atribución).
2. En Blender: limpiar y hacer retopología a MENOS de 10.000 triángulos en total;
   texturas de 1024×1024 o menos.
3. Ajustarlo al rig R15 oficial de Roblox (mismos nombres de partes/huesos que un
   avatar R15), con skinning correcto.
4. Altura total de 5 a 5.5 studs (como un avatar normal de Roblox): el juego tiene
   hitboxes calculadas para ese tamaño.
5. Exportar e importar en Roblox Studio: pestaña Avatar → Import 3D, como
   personaje R15.
6. Dejarlo en Studio EXACTAMENTE así:
   ServerStorage > FighterModels (Folder) > Brawler (Model)
   con un Humanoid y una HumanoidRootPart dentro. (Para Blade: ... > Blade)
7. Comprobar que el Animation Editor lo acepta (seleccionarlo y abrir el editor).
Pídeme captura en cada paso donde suele fallar.
```

**A ENTREGAS.md:** marcar "Modelo listo" y mandar a Claude captura del Explorer con
`ServerStorage > FighterModels > Brawler` desplegado.

---

## Tarea 3 · Animaciones (tutor en vivo)

```text
TAREA 3: ANIMACIONES DE [Brawler / Blade]
El modelo ya está en ServerStorage > FighterModels > [nombre]. Guíame en vivo en el
Animation Editor de Roblox Studio (o Moon Animator si es mejor para principiantes).
Tú no puedes poner keyframes: yo animo y tú me dices qué pose hacer en cada momento.

Reglas:
- El personaje se ve DE LADO: las poses deben leerse de perfil.
- Ataques: Priority = Action, Loop = NO. La duración total y el momento del
  impacto deben ser EXACTOS a la tabla (el código usa esos tiempos).
  "Impacto" = el puño/pie/espada en su máxima extensión.
- Idle, Run y Fall: Loop = SÍ.
- Al terminar cada animación: Publish to Roblox (en el dueño indicado: mi cuenta
  o el Grupo del juego) y copiar su ID.

Animaciones base: Idle (loop), Run (loop), Jump (0.3 s), AirJump (0.3 s, voltereta),
Fall (loop), Hurt (0.4 s, recibe un golpe), Victory (1.5 s).

Ataques (duración total / impacto, en segundos):
[pega aquí la tabla del personaje]

Empecemos por Idle y luego Jab. Para cada animación dime: poses clave, en qué
segundo va cada una y qué partes mover.
```

### Tabla de Brawler

| Ataque | Qué es | Duración total | Impacto en |
|---|---|---|---|
| Jab | puñetazo rápido | 0.28 | 0.06 |
| SideLight | golpe largo hacia delante | 0.42 | 0.10 |
| UpLight | gancho hacia arriba | 0.36 | 0.08 |
| DownLight | barrida baja | 0.37 | 0.07 |
| AirLight | patada en el aire hacia delante | 0.37 | 0.07 |
| AirUpLight | golpe en el aire hacia arriba | 0.37 | 0.07 |
| AirDownLight | pisotón en el aire hacia abajo | 0.44 | 0.10 |
| Heavy | puñetazo cargado fuerte | 0.82 | 0.30 |
| UpHeavy | uppercut fuerte | 0.82 | 0.28 |
| DownHeavy | golpe al suelo (a los dos lados) | 0.84 | 0.25 |
| Recovery | impulso hacia arriba girando | 0.70 | 0.05 |
| GroundPound | caída en picado | 0.77 | 0.12 |

### Tabla de Blade

| Ataque | Qué es | Duración total | Impacto en |
|---|---|---|---|
| Jab | estocada corta | 0.35 | 0.09 |
| SideLight | tajo horizontal largo | 0.50 | 0.14 |
| UpLight | tajo hacia arriba | 0.44 | 0.10 |
| DownLight | tajo bajo | 0.44 | 0.10 |
| AirLight | tajo en el aire hacia delante | 0.43 | 0.09 |
| AirUpLight | tajo en arco hacia arriba | 0.43 | 0.09 |
| AirDownLight | estocada hacia abajo | 0.50 | 0.12 |
| Heavy | tajo cargado | 0.97 | 0.38 |
| UpHeavy | tajo vertical fuerte | 0.95 | 0.34 |
| DownHeavy | barrido a los dos lados | 0.96 | 0.30 |
| Recovery | salto en diagonal con tajo | 0.76 | 0.06 |
| GroundPound | caída clavando la espada | 0.84 | 0.14 |

> Estas tablas salen de `src/shared/Config/Fighters/*.luau`. Si Claude cambia un
> tiempo, actualiza también esta tabla y avisa.

**A ENTREGAS.md:** el ID de cada animación en su fila.

---

## Tarea 4 · Decoración del escenario

```text
TAREA 4: DECORAR LA ARENA EN ROBLOX STUDIO
Estilo: [describe, p. ej. "templo flotante al atardecer"]. Que luzca en un tráiler.
Puedes usar el Material Generator y el Assistant de Studio.

REGLAS QUE NO SE PUEDEN ROMPER (el juego depende de ellas):
- NO mover, escalar, renombrar ni borrar nada de Workspace > Arena
  (Platforms, SpawnPoints, BlastZone). Solo puedo cambiar Color y Material
  de las piezas de Arena > Platforms.
- Toda la decoración va en una carpeta nueva: Workspace > Decor.
- Todo lo de Decor: Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false.
- La cámara mira desde Z positivo hacia Z = 0: la decoración va DETRÁS (Z negativo),
  nunca delante (Z positivo).
- Zona de pelea: X de -40 a 40, Y de 0 a 30. No tapar esa zona.
- Menos de ~300 piezas en Decor.
- Lighting y Sky: libres.
Guíame paso a paso.
```

**A ENTREGAS.md:** nada; solo avisar a Claude si cambiaste Lighting.

---

## Tarea 5 · Sonidos y música

```text
TAREA 5: SONIDOS Y MÚSICA ORIGINALES
Necesito: golpe ligero, golpe pesado, tajo de espada ligero, tajo de espada pesado,
salto, salto aéreo, aterrizaje, esquiva, KO (explosión), respawn, inicio de pelea,
victoria, y una música de combate en loop (enérgica).
- Efectos: dime cómo crearlos con jsfxr (gratis) o ElevenLabs Sound Effects
  (avísame de su licencia del plan gratis). Máximo 1.5 s cada uno.
- Música: prefiero el catálogo de música con licencia que publica Roblox en el
  Toolbox (libre dentro de Roblox). Si propones Suno, dime si su plan gratis
  permite uso comercial.
- Explícame cómo subir cada archivo como Audio en Roblox Studio (en el dueño
  correcto: mi cuenta o el Grupo) y dónde ver su ID.
- No inventes IDs: los apunto yo cuando los obtenga.
```

**A ENTREGAS.md:** el ID de cada sonido en su fila.

---

## Tarea 6 · Tráiler, nombre, miniatura e icono

```text
TAREA 6: TRÁILER Y PRESENTACIÓN
1. 10 nombres ORIGINALES para el juego (cortos, fáciles de buscar en Roblox,
   que no mencionen ni se parezcan a otros juegos).
2. Guion del tráiler de 60 s, plano a plano (segundos, qué se ve, texto, sonido).
   Debe mostrar en orden: correr y saltar, combo de ligeros, ataques arriba/abajo,
   el % subiendo, pesado que manda lejos, Recovery para volver, esquiva, KO
   espectacular, victoria, y cierre con nombre + "Próximamente".
3. Guion de 3 clips verticales de 15 s para TikTok/Shorts.
4. Miniatura (1920×1080) e icono (512×512) del juego, con el texto del nombre limpio.
5. Plan para grabar la partida con handcam: posición de la cámara de manos,
   luz, y configuración de OBS para juntar pantalla + manos.
```

**A ENTREGAS.md:** nombre elegido del juego.

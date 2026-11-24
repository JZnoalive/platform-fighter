# Prompts para trabajar en paralelo con otra IA

Claude programa el código (`src/`). Estas tareas **no tocan código** y se pueden
hacer a la vez con otra IA (ChatGPT, etc.) o con tus amigos.

**Regla de oro:** la otra IA **nunca** escribe ni cambia archivos de `src/`.
Entrega **datos** (IDs, tablas, modelos, imágenes) y tú se los pasas a Claude.

Cada prompt empieza con el mismo bloque de contexto. Cópialo entero.

---

## Bloque de contexto (pegar al inicio de CADA prompt)

```text
CONTEXTO DEL PROYECTO
- Juego de lucha de plataformas 2D ORIGINAL para Roblox, estilo "platform fighter"
  (física y ritmo tipo Brawlhalla: rápido, saltos limitados, caída rápida, golpes
  ligeros y pesados por dirección, el % de daño sube y cuanto más % más lejos vuelas).
- Vista lateral 2D: los personajes se mueven solo en X (izquierda/derecha) e Y (arriba/abajo).
  La cámara los ve de LADO.
- TODO es original: no copiar personajes, nombres, armas icónicas, trajes, colores
  ni estilos reconocibles de otros juegos o animes. Si algo se parece a un personaje
  existente, cámbialo.
- Estética: híbrido anime/cartoon, proporciones relativamente realistas (no chibi).
- Meta inmediata: una mini demo para grabar un tráiler de 60 s y una partida con handcam.
- Personajes de la demo (nombres en clave, el diseño final lo decide el autor):
  * "Brawler": luchador equilibrado, pelea con puños, rápido y ágil.
  * "Blade": espadachín, más alcance, más lento y contundente.
- Tú NO escribes código Luau ni scripts. Tu trabajo es el que se describe abajo.
  Entrega el resultado exactamente en el formato pedido.
```

---

## 1. Diseño de personajes (concept art)

```text
[pega aquí el BLOQUE DE CONTEXTO]

TAREA: ayúdame a diseñar a "Brawler" y "Blade" como personajes originales.
Para cada uno entrega:
1. 3 propuestas de concepto distintas (silueta, ropa, colores, rasgo memorable).
2. Paleta de 4-5 colores en HEX.
3. Una hoja de personaje (vista frontal, lateral y trasera) como prompt detallado
   para un generador de imágenes, o la imagen si puedes generarla.
4. Lista de lo que hace que el diseño sea legible de LADO y pequeño en pantalla
   (silueta clara, colores contrastados entre los dos personajes).
5. Comprobación: explica por qué no se parece a ningún personaje conocido.
Restricción: el personaje debe poder construirse como modelo R15 de Roblox
(cabeza, torso, 2 brazos, 2 piernas). Accesorios grandes (capas, pelo largo)
con moderación porque estorban en combate.
```

**Entregar a Claude:** solo el nombre final y la paleta (el arte es para ti y el modelador).

---

## 2. Modelo 3D e importación a Roblox

```text
[pega aquí el BLOQUE DE CONTEXTO]

TAREA: guíame paso a paso (soy principiante) para crear el modelo 3D de
[Brawler / Blade] a partir de este diseño: [pega el diseño elegido].
Requisitos técnicos obligatorios:
- Herramienta: Blender (gratis), partiendo de la plantilla/rig R15 oficial de Roblox.
- Rig R15 estándar (mismos nombres de huesos/partes que un avatar R15 de Roblox),
  para que funcionen las animaciones de Roblox.
- Altura total parecida a un avatar normal de Roblox (unos 5–5.5 studs), para
  que las hitboxes del juego encajen.
- Máximo ~10.000 triángulos en total; texturas de 1024×1024 o menos.
- El personaje mira hacia -Z (el "frente" de Roblox).
- Importar en Roblox Studio con: pestaña Avatar → Import 3D (o Avatar Setup),
  como personaje R15 con skinning.
Entrega final en Roblox Studio:
- Un Model llamado exactamente "Brawler" (o "Blade") con Humanoid y HumanoidRootPart,
  guardado en: ServerStorage > FighterModels > Brawler (crear la carpeta FighterModels).
- Comprobar que se puede animar con el Animation Editor (pestaña Avatar).
Explícame cada paso con dónde hacer clic. Si algo falla, pídeme captura.
```

**Entregar a Claude:** captura del Explorer mostrando `ServerStorage > FighterModels > Brawler`
desplegado (con `Humanoid` y `HumanoidRootPart`).

---

## 3. Animaciones

```text
[pega aquí el BLOQUE DE CONTEXTO]

TAREA: guíame para crear las animaciones de [Brawler / Blade] en Roblox Studio
(Animation Editor, o Moon Animator si lo recomiendas) sobre su modelo R15 en
ServerStorage > FighterModels > [nombre]. Soy principiante: paso a paso.

Reglas:
- El personaje se ve de LADO: las poses deben leerse bien de perfil.
- Ataques: Priority = Action, NO loop. Duración EXACTA = la de la tabla.
  El golpe debe "impactar" (brazo/espada extendidos al máximo) en el segundo indicado.
- Idle, Run, Fall: Priority = Idle/Movement, Loop = sí.
- Al terminar cada una: publicar en Roblox (Publish to Roblox) y copiar su ID.

Animaciones base (todas): Idle (loop), Run (loop), Jump (0.3 s), AirJump (0.3 s,
voltereta), Fall (loop), Hurt (0.4 s, recibe golpe), Victory (1.5 s, pose de victoria).

Ataques — duración total y momento del impacto (segundos):
[pega la tabla del personaje de abajo]

Entrega final: una tabla "Nombre de animación → ID numérico" con TODAS las filas.
```

### Tabla de Brawler (pegar en el prompt)

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

### Tabla de Blade (pegar en el prompt)

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

**Entregar a Claude:** la tabla "Nombre → ID" de cada personaje. Claude la pone en
`Brawler.luau` / `Blade.luau` (campo `animationId`) y programa la reproducción.

> Si cambian los tiempos de un ataque en el código, Claude avisa y se actualiza esta tabla.

---

## 4. Decoración del escenario

```text
[pega aquí el BLOQUE DE CONTEXTO]

TAREA: guíame para decorar la arena en Roblox Studio con un estilo [describe:
p. ej. "templo flotante al atardecer"], para que se vea bien en un tráiler.
REGLAS QUE NO SE PUEDEN ROMPER:
- NO mover, cambiar de tamaño, renombrar ni borrar nada dentro de Workspace > Arena
  (Platforms, SpawnPoints, BlastZone). El juego depende de esas medidas exactas.
- Puedo cambiar el Color y el Material de las plataformas de Arena > Platforms.
- Toda la decoración nueva va en una carpeta nueva: Workspace > Decor.
- Todo lo de Decor: Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false.
- Nada de Decor entre la cámara y la zona de pelea: la cámara mira desde Z positivo
  hacia Z = 0. Decorado de fondo en Z negativo (detrás), nunca en Z positivo.
- La zona de pelea va de X = -40 a 40 (plataforma principal) y de Y = 0 a 30.
- Iluminación (Lighting) y cielo (Sky): libres.
- Rendimiento: menos de ~300 piezas en Decor.
```

**Entregar a Claude:** nada (no afecta al código). Solo avisar si se tocó Lighting.

---

## 5. Sonidos

```text
[pega aquí el BLOQUE DE CONTEXTO]

TAREA: ayúdame a encontrar en la Creator Store de Roblox (Toolbox → Audio)
sonidos GRATUITOS y de uso libre en Roblox para:
golpe ligero, golpe pesado, golpe de espada ligero, golpe de espada pesado,
salto, salto aéreo, aterrizaje, KO (explosión/estruendo), respawn, "¡A pelear!"
(inicio), victoria, música de fondo de combate (loop, enérgica).
Para cada uno: nombre, ID numérico y duración. Máximo 1.5 s salvo la música.
Evita audios que suenen a juegos conocidos.
Entrega final: tabla "Nombre del sonido → ID".
```

**Entregar a Claude:** la tabla "Nombre → ID" (se usa en el pulido, M7).

---

## 6. Tráiler, nombre y miniatura

```text
[pega aquí el BLOQUE DE CONTEXTO]

TAREA:
1. Propón 10 nombres ORIGINALES para el juego (cortos, fáciles de buscar en Roblox,
   que no mencionen ni se parezcan a otros juegos) y comprueba que no existan ya.
2. Guion del tráiler de 60 s, plano a plano (segundo inicio–fin, qué se ve, texto
   en pantalla, sonido). Debe mostrar en orden: correr y saltar, combo de ligeros,
   ataques arriba/abajo, el % subiendo, golpe pesado que manda lejos, Recovery para
   volver, KO espectacular, victoria, y cierre con nombre + "Próximamente".
3. Guion de 3 clips verticales de 15 s para TikTok/Shorts.
4. Prompt para la miniatura (1920×1080) y el icono (512×512) del juego.
5. Plan para grabar la partida con handcam (posición de la cámara, luz, OBS).
```

**Entregar a Claude:** el nombre elegido (para el README y el HUD).

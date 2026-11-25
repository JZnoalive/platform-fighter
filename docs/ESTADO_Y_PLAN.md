# Estado y plan del juego — Luchador de plataformas (Roblox)

> Actualizado: 25 de noviembre de 2026 · Versión del juego: **0.8.0-poses-video**
> Fecha límite de la demo: **antes del 4 de diciembre de 2026** (quedan ~9 días)

---

## 1. Lo que queremos lograr

**Una demo jugable que la gente vea y piense: "esto parece Brawlhalla / Smash".**

- **Jugabilidad estilo Brawlhalla:** combos verdaderos, esquiva, chase dodge, armas con
  ataques propios, firmas por arma, gancho de guadaña, ritmo rápido y sin retraso.
- **Aspecto 2D estilo Brawlhalla:** cámara plana de lado, colores vivos, personajes chibi
  con contorno, escenario de isla flotante, HUD con retratos.
- **Personajes parecidos (nunca iguales)** a las leyendas: mismas ideas y mecánicas
  (2 armas + 4 stats + firmas), con nombre, aspecto y diseño propios.
- **Para grabar:** un **tráiler** y una **partida contra la CPU con handcam**.
- **Reglas legales:** se copian mecánicas e ideas, **nunca** personajes, nombres, arte,
  música ni código de otros juegos (ni "ports" de Brawlhalla, Smash o MK).

---

## 2. Lo que llevamos (hecho y probado en Studio)

### Combate
- ✅ 4 armas con 12 ataques cada una: **Puños, Espada, Guadaña, Pistolas**.
- ✅ **Combos verdaderos de la wiki** comprobados: Espada `DLight > SAir` (0 % y 60 %),
  Puños `DLight > SLight`, ráfaga de 3 golpes de los Puños.
- ✅ **Gancho de guadaña** estilo Brawlhalla: engancha, arrastra con cadena y lanza
  hacia donde mantengas (adelante o atrás). En NLight, SLight, NAir y DAir.
- ✅ **Active input** (elegir dirección del lanzamiento durante el golpe).
- ✅ Firmas por arma (Ráfaga de pistones, Embestida, Trampa del abismo, Cometa oblicuo…).
- ✅ Hitlag, hitstun, búfer de ataques, chase dodge, esquiva, fast fall, salto instantáneo.
- ✅ **Compensación de latencia**: la hitbox sale donde está el jugador de verdad y hacia
  donde miraba al pulsar.
- ✅ Plataformas flotantes **de un solo sentido** (se atraviesan desde abajo; S para bajar).
- ✅ Arreglado el bug que hacía golpear en bucle infinito en las firmas de varios golpes.

### Personajes (sistema de leyendas)
| Personaje | Armas | FUE/DES/DEF/VEL | Idea de referencia (solo mecánica) |
|---|---|---|---|
| **Forja** | Puños / Pistolas | 7 / 4 / 6 / 5 | leyenda de fuerza y remate |
| **Vórtice** | Espada / Guadaña | 5 / 7 / 3 / 7 | espadachín veloz y frágil |
| **Umbra** | Guadaña / Pistolas | 4 / 5 / 7 / 6 | defensiva de borde (idea de Nix) |
| **Volta** | Puños / Espada | 5 / 6 / 4 / 7 | velocista de presión |

- ✅ Los stats cambian daño, knockback, rapidez de ligeros y velocidad (comprobado).
- ✅ Elegir mi personaje y el de la CPU en el menú de práctica.

### Gráficos y animación
- ✅ **Look 2D**: cámara FOV 16 muy lejos, luz plana de día, isla con hierba, fondo en
  capas, nubes planas.
- ✅ Personajes **chibi** (cabeza grande) con contorno negro.
- ✅ **Chispa de impacto** estilo Brawlhalla (núcleo blanco, rayos, fragmentos, luz) y
  **tinte blanco/celeste** del golpeado mientras está aturdido.
- ✅ **Poses por código diseñadas desde los vídeos** para TODOS los ataques (sustituyen a
  las animaciones de IA, que no se parecían). Copiadas fotograma a fotograma: gancho de
  guadaña, DLight/SAir de espada, DLight/SLight de pistolas, DLight/SLight/SAir de puños.
- ✅ **HUD estilo Brawlhalla**: retratos redondos arriba a la derecha, aro de color según
  el daño que tiembla al recibir golpes, medalla de vidas.
- ✅ Limpieza del motor gráfico: StreamingEnabled apagado, efectos duplicados apagados.

### Modos
- ✅ Modo práctica con menú (comportamientos de la CPU, %, hitboxes, armas, personajes).
- ✅ Partida contra la CPU a 3 vidas, cuenta atrás, KO, ¡GAME!, victoria.

### Herramientas que usamos
- Rojo (sincroniza el código con Studio), GitHub (todo subido), MCP de Roblox Studio
  (pruebas automáticas), simulador de combos, grabadora de golpes, **probador de poses**
  en modo edición y lector de vídeos de referencia.

---

## 3. Lo que falta (por prioridad)

### 🔴 Imprescindible para la demo (antes del 4 de diciembre)
1. **Que pruebes tú** las poses y el gancho y me digas qué ataque se ve peor → lo copio
   del vídeo pose a pose.
2. **Probador automático de todos los combos de la wiki** con las 4 armas (que salgan
   todos a la vez, no uno por uno) y ajustar números.
3. **Mecánicas técnicas que faltan** para varias rutas de la wiki: **dash jump**
   (salto con impulso desde carrera) y **GC** (esquivar en el aire y sacar un ataque de suelo).
4. **Sonidos**: golpes, KO, música (hacen falta IDs de audio de Roblox, ver AudioConfig).
5. **CPU más lista** en modo Pelear (que haga combos y use el gancho) para la partida grabada.
6. **Pantalla de selección de personaje** y transición antes de la partida (para el tráiler).
7. Ensayo final: partida completa sin errores + preparar tomas del tráiler.

### 🟡 Muy recomendable
- Poses del vídeo para los ataques que diseñé "a ojo" (pesados, Recovery, ataques arriba).
- Efectos de arma: estelas más grandes tipo arco en tajos, fogonazo en los disparos.
- Escenario: más detalle (decoración, segundo escenario).
- Firmas propias por personaje (como las leyendas: cada uno con sus pesados).

### 🟢 Futuro (después de la demo)
- Las **otras 11 armas** de la wiki (martillo, lanza, katars, hacha, arco, lanza cohete,
  cañón, orbe, mandoble, botas, chakram). El código ya está preparado para añadirlas.
- Recoger armas del escenario (como Brawlhalla).
- Multijugador online 1v1 / 2v2.

---

## 4. Pendientes TUYOS (yo no puedo hacerlos)
- [ ] En Studio: **Lighting → Technology = Future** (mejora las luces de los impactos).
- [ ] **Guardar el place** (Archivo → Guardar en Roblox) para conservar StreamingEnabled
      apagado y los cambios del place.
- [ ] Probar el juego y decirme qué no se parece a Brawlhalla.
- [ ] Si quieres sonidos: buscar/elegir audios en la Toolbox o Creator Store.

## 5. Problemas conocidos
- Tras varias pruebas seguidas, a veces la **vista 3D de Studio sale negra** en mis
  capturas → reiniciar Studio lo arregla (el juego en sí funciona).
- Mis teclas automáticas del MCP llegan con ~130 ms de retraso: los combos finos los
  compruebo con mensajes exactos o contigo jugando.
- La sección de Puños del vídeo no tiene cartel: las poses de puños se basan en un
  personaje de garras parecido.

---

## 6. Cómo trabajamos
- Una cosa a la vez, probada en Studio y subida a GitHub con su commit.
- Combos y mecánicas: **reglas comunes** que hacen posibles todos los combos de la wiki.
- Animaciones: **poses por código copiadas de los vídeos** (no animaciones de IA).
- Referencias: `Downloads/wiki_completa_smash_bros_ultimate_y_brawlhalla.md`,
  `arquitectura_grafica_smash_vs_brawlhalla.md`, `gdd_diseno_arte_y_programacion_de_personajes.md`
  y los vídeos de `Desktop/combos_mp4`.

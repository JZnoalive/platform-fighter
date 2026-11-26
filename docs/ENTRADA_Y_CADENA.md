# Entrada real y cadena Light 1 → 2 → 3 (bloqueo inmediato)

> **Estado: pendiente de la prueba manual de Jesús y de su grabación de 20 s.**
> Las pruebas de abajo usan el teclado simulado de Roblox Studio. Esas pulsaciones
> pasan por todo el camino real: ContextActionService → cliente → servidor → golpe.
> Aun así no sustituyen a una persona jugando.

## Cómo hacer el combo (secuencia exacta)

1. En el menú de práctica pulsa **Reiniciar posiciones**: el rival queda quieto (sin congelar: reacciona y sale volando) y
   tú a 5 studs, mirándolo.
2. **Sin tocar A/D/W/S**, pulsa **J, J, J** a ritmo normal.
   - Si pulsas J mientras sale un golpe, el siguiente queda **guardado** y sale al terminar.
   - Después de que termine un golpe tienes **0,55 s** para pulsar J y seguir la cadena.
     Más tarde vuelve a Light 1.
   - Tras Light 3 la cadena termina y la siguiente J empieza en Light 1 (no hay bucle infinito).
3. **Alternativa:** **mantén J** (más de 0,22 s) y salen los 3 golpes solos. Suelta para empezar de nuevo.
4. Con A/D, S o W pulsado, J **no** es la cadena: sale el ataque lateral, el de abajo o el de arriba.
   El panel lo dice ("dirección: D pulsada → ataque lateral").

Teclas reales (comprobadas en `InputController`): J o clic izquierdo = ligero, K o clic derecho =
fuerte, Shift o L = esquiva, Espacio o W = saltar, F2 = ocultar paneles. El recuadro **CONTROLES**
(abajo a la derecha) las muestra dentro del juego.

## Panel ENTRADA (arriba a la derecha)

Línea fija: última tecla y hace cuánto · dirección · estado · ataque solicitado → ataque elegido ·
índice de la cadena · **tiempo que queda de ventana** · motivo.

Registro, para tres pulsaciones de J (captura real):

```
INPUT J · dir ninguna · estado Idle · suelo
ATTACK Sword Jab (Light 1)
CHAIN 1
SERVIDOR ejecuta Jab (CHAIN 1)
HIT OK Jab · rival combo x1 · 4%
ventana abierta 0.55 s → pulsa J para CHAIN 2
INPUT J · ...
ATTACK Sword Jab2 (Light 2)
CHAIN 2 · dentro de ventana (0.07 s)
SERVIDOR ejecuta Jab2 (CHAIN 2)
HIT OK Jab2 · rival combo x2 · 8%
ventana abierta ...
ATTACK Sword Jab3 (Light 3)
CHAIN 3 · dentro de ventana (0.09 s)
SERVIDOR ejecuta Jab3 (CHAIN 3)
HIT OK Jab3 · rival combo x3 · 15%
```

Motivos de rechazo que puede mostrar:
- `fuera de ventana (0.97 s > 0.55 s): vuelve a CHAIN 1`
- `estado incorrecto: Hitstun` (también Dodging, KO…)
- `INPUT NO RECIBIDO: J llegó pero la capturó la interfaz` (un cuadro de texto o el chat tiene el foco)
- `dirección: S pulsada → ataque abajo (suelta S para la cadena)`
- `ataque bloqueado: ya hay un golpe guardado en el búfer` / `Jab3 en curso` / `estás en Heavy`
- `rival fuera de rango (x studs, alcance y)` / `rival DETRÁS`
- `el SERVIDOR no ejecutó Jab (estado en el servidor: …)`
- `el golpe del búfer no salió (pulsado demasiado pronto)`
- Si J no hace **nada** en el panel, la tecla no llegó al juego: haz clic dentro de la ventana del juego en Studio.

## Fallos encontrados y corregidos

| Archivo | Problema | Antes → después |
|---|---|---|
| `InputController.luau` | Las teclas se guardaban como "pulsada/soltada". Si Roblox perdía el aviso de soltar (soltar el ratón encima del menú, cambiar de ventana), **J dejaba de funcionar** y W/S podían quedarse "pegadas" y convertir J en otro ataque. | Se pregunta al teclado (`IsKeyDown`) cada vez y cada pulsación cuenta. |
| `CombatController.luau` | El índice de la cadena se contaba con las pulsaciones del cliente. Con pulsaciones rápidas o lentas se desincronizaba (salía Jab3 sin Jab2, o Jab1 repetido). | El índice sale del ataque que **el servidor ejecuta** (`Move`), con 1 golpe en el búfer como máximo. |
| `MovementController.luau` + `MovementConfig.LungeStopDistance = 3` | El avance de los golpes y las embestidas **atravesaban al rival**. Tras una cadena quedabas detrás de él y la siguiente fallaba. | El avance se para si el rival está a menos de 3 studs delante. |
| `TrainingService.luau` | Al congelar al rival se anclaba en el aire (4 studs arriba). Además, **tu pantalla lo seguía viendo flotando** aunque el servidor lo tenía en el suelo: veías al rival en un sitio y los golpes se calculaban en otro. | Se ancla al tocar el suelo y se fuerza a que todos vean la posición real. |
| `Sword.luau` UpLight | La zona de golpe empezaba demasiado alta y no tocaba a un rival en el suelo a 3 studs. | offset (1, 4.5) tamaño 6×5 → offset (1.5, 3) tamaño 6×6. |
| `PracticeController.luau` | No había forma rápida de volver a una posición conocida. | Botón **Reiniciar posiciones**. |
| `DebugController.luau` | No se veía qué pasaba con cada tecla. | Paneles **ENTRADA** y **CONTROLES**. |

## Pruebas de integración (teclado simulado en Play, 25-nov-2026)

| Prueba | Resultado |
|---|---|
| J J J (toques de 90 ms, cada 0,3 s) desde Reiniciar | Jab → Jab2 → Jab3 conectan: **combo x3**, 4 → 8 → 15 % ✔ |
| Tres cadenas seguidas sin reiniciar (toques y J mantenida) | 9/9 golpes, x3 cada vez; no atraviesas al rival ✔ |
| J lenta (1,2 s entre pulsaciones) | Jab, Jab y "fuera de ventana" en el panel ✔ |
| S+J, W+J, D+J, K, S+K, W+K | DownLight, UpLight, SideLight, Heavy, DownHeavy (2 golpes), UpHeavy: todos distintos y conectan ✔ |
| Saltos | Suelo + 2 aéreos; el 4.º Espacio se ignora; se recargan al aterrizar ✔ |
| Caída rápida (S bajando) | Acelera de −84 a −110 sin saltos (máx. 1,6 studs/fotograma) ✔ |
| Salto → salto → aéreo lateral → aéreo arriba → recovery | Todo en el aire; el recovery sube hasta y 17,6 ✔ |
| Esquiva aérea | 1 por vuelo (la 2.ª se ignora); se recarga al aterrizar ✔ |
| Reiniciar posiciones | Rival en el suelo, 0 %, quieto; cliente y servidor coinciden (y 5,45) ✔ |
| Pruebas unitarias (CoreTests) | 19/19 ✔ (solo matemáticas; no cuentan como prueba de entrada) |

## Checklist manual para Jesús (20–60 s, sin comandos)

1. Play → **Reiniciar posiciones**.
2. J, J, J → el panel muestra CHAIN 1, 2, 3 y el HUD COMBO x3.
3. Mantén J → salen los 3 solos.
4. Espera 1 s entre J y J → el panel dice "fuera de ventana".
5. D+J, S+J, W+J → tres ataques distintos.
6. W+J (lanza) → Espacio → J en el aire → W+K (recovery).
7. En el aire: Shift + dirección (esquiva aérea).
8. **Reiniciar posiciones** y repetir: nada debe quedar roto.
9. Graba 20 s y dime en qué paso falló, si falló alguno, y qué dijo el panel ENTRADA.

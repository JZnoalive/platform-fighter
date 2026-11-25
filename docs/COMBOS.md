# Combos (estilo Brawlhalla)

Los combos salen de 4 reglas del juego:

1. **Hitstun**: el golpeado queda aturdido al menos 0.25 s (más cuanto más fuerte).
2. **Recovery corto al acertar**: si tu golpe conecta, recuperas el control antes.
3. **Búfer**: si pulsas el siguiente ataque un poco antes, sale en cuanto puedas.
4. **Ligero abajo (S + J) levanta un poco** al rival → puedes saltar y seguir en el aire.

Además:
- **Chase dodge**: justo después de acertar, la esquiva (Shift) recarga en 0.35 s en vez
  de 1 s → esquiva **hacia** el rival para perseguirle y seguir el combo.
- **Hitlag**: en cada golpe los dos se congelan un instante → da tiempo a reaccionar.
- El contador **"COMBO xN · %"** (arriba a la derecha) solo cuenta golpes seguidos de verdad.

Notación: `J` ligero, `K` pesado, `S`/`W`/`A-D` dirección, `Space` saltar, `Shift` esquiva.
`→` = encadenar en cuanto puedas.

## Puños (Brawler)

| Combo | Cómo | Para qué |
|---|---|---|
| Jab x2 → lateral | `J → J → D+J` | Básico, empuja al final |
| Levantar y aéreo | `S+J → Space → J` | El clásico ligero abajo → aéreo |
| Levantar y arriba | `S+J → Space → W+J` | Lleva al rival hacia arriba |
| Persecución | `S+J → Shift+W (chase dodge) → W+J` | Le sigues al aire |
| Remate | cualquiera de arriba → `K` o `W+K` | Con más de ~90 % suele ser KO |

## Espada (Blade)

| Combo | Cómo | Para qué |
|---|---|---|
| Estocadas | `J → J → D+J` | Mucho alcance |
| Levantar y tajo aéreo | `S+J → Space → J` | Aéreo largo |
| Barrido | `S+J → S+K` | Barrido a los dos lados (gira) |
| Remate arriba | `S+J → Space → W+J → W+K (Recovery)` | Lleva arriba y remata subiendo |

## Guadaña

| Combo | Cómo | Para qué |
|---|---|---|
| **Gancho** | `D+J` (tira al rival por detrás de ti) `→ J` | Empezar combos: lo traes hacia ti |
| Gancho y giro | `D+J → S+K` | Lo traes y barres a los dos lados |
| Molinete | `S+J → Space → J (molinete en el aire)` | Golpe aéreo grande con voltereta |
| Pincho | En el aire encima del rival: `S+J` | Lo manda hacia abajo (fuera del escenario = KO) |

## Pistolas

| Combo | Cómo | Para qué |
|---|---|---|
| Ráfaga | `J → J → J` desde lejos | Sumar % sin acercarte |
| Ráfaga y carga | `J → J → K` | Disparo cargado para rematar |
| Antiaéreo | Rival encima: `W+J` | Disparo en diagonal hacia arriba |
| Desde arriba | En el aire: `S+J` | Disparo hacia abajo |

## Consejos para el vídeo

- En el menú de práctica pon la CPU en **Quieta** y su % en **50** para que los combos se
  vean largos sin que salga volando enseguida.
- Para mostrar un KO bonito: % de la CPU en **150** y un **pesado** (`K`) → rayo de KO.
- Activa **Hitboxes** solo si quieres explicar cómo funciona; para el tráiler, apagadas.

> Los combos los descubren los jugadores: estos son un punto de partida.
> Si encuentras uno nuevo que mole, apúntalo aquí.

## Combos verdaderos COMPROBADOS en Studio (v0.6, guiados por la wiki)

Probados con teclas reales contra la CPU (el rival seguía aturdido = no podía esquivar):

| Arma | Combo | Teclas | Resultado |
|---|---|---|---|
| Espada | DLight > SAir | `S+J → Space (+D) → J` | ✅ a 0 % y a 60 % (COMBO x2) |
| Puños | DLight > SLight | `S+J → D+J` | ✅ a 0 % |
| Puños | Firma "Ráfaga de pistones" | `K` | ✅ los 3 golpes conectan |
| Guadaña | SLight con active input | `D+J` y mantener `A` durante el golpe | ✅ tira al rival hacia ti en vez de empujarlo |

Qué lo hizo posible:
- La hitbox de un golpe único se apaga al acertar → la recuperación empieza ya.
- El salto despega al instante y un salto pulsado al final de un ataque no se pierde.
- La hitbox sale desde la posición REAL del jugador (el servidor la ve con retraso).
- Las plataformas flotantes se atraviesan desde abajo (antes el rival chocaba con ellas).

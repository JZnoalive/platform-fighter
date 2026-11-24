# Personajes de la demo — diseños finales

Diseños aprobados por JZnoalive (Tarea 1, con Gemini). Este es el resumen que se
pega en la **Tarea 2 (modelo 3D)** de [`PROMPTS_GEMINI.md`](PROMPTS_GEMINI.md).
Los nombres en código siguen siendo `Brawler` y `Blade`.

---

## Brawler · "Forja Cinética" (concepto B3)

1. **Silueta y proporciones:** luchador atlético de **5.2 studs** de alto, proporciones
   realistas (híbrido anime/cartoon, no chibi), torso robusto y volumen concentrado
   en los antebrazos.
2. **Vestimenta:** camiseta sin mangas blanco hueso (`#EDE6D6`) bajo un mono de trabajo
   gris ceniza (`#4A4E54`) con las mangas anudadas a la cintura (pieza rígida pegada al
   `LowerTorso`) y botas industriales carbón (`#1E2022`).
3. **Rasgo clave:** dos guanteletes neumáticos sobredimensionados en bermellón quemado
   (`#D94E28`) y bronce cobre (`#C87D4B`) en antebrazos y manos; gafas de soldador de
   latón sobre la frente; pelo oscuro revuelto.
4. **R15:** sin capas ni telas sueltas; las 15 partes estándar de Roblox; < 10.000 triángulos.
5. **Paleta:** `#D94E28` (primario) · `#C87D4B` (secundario) · `#4A4E54` (traje) ·
   `#EDE6D6` (camiseta) · `#1E2022` (botas/detalles).

---

## Blade · "Vórtice Amatista" (concepto S3)

1. **Silueta y proporciones:** espadachina estilizada de **5.4 studs** de alto,
   proporciones atléticas realistas, postura erguida, alcance largo gracias al espadón.
2. **Vestimenta:** traje táctico ajustado obsidiana violeta (`#110E1B`) bajo una chaqueta
   bolero acorazada corta en titanio oscuro (`#1E1B2E`) de cuello alto; botas angulares
   de combate; pelo corto en capas blanco lavanda (`#DDD6FE`).
3. **Arma propia:** espadón geométrico de prisma hexagonal con punta plana, hoja violeta
   real (`#7C3AED`) con ranuras emisivas inclinadas magenta neón (`#F43F8E`).
   Malla separada o unida a `RightHand`.
4. **R15:** ceñido, sin capas ni faldas que interfieran con las piernas;
   < 10.000 triángulos en total (personaje + espada).
5. **Paleta:** `#7C3AED` (primario) · `#F43F8E` (energía) · `#1E1B2E` (armadura) ·
   `#DDD6FE` (pelo/acentos) · `#110E1B` (traje base).

---

## Notas para el código (Claude)

- Alturas 5.2 y 5.4 studs: dentro del rango previsto; las hitboxes actuales sirven.
- La espada de Blade se modela con el personaje, pero **la hitbox la decide el código**
  (`Weapons/Sword.luau`), no la malla. Si la espada final es mucho más larga o corta que
  ~5 studs, avisar para ajustar los `offset` de sus ataques.
- Contraste en pantalla: Brawler cálido (naranja/cobre) vs Blade frío (violeta/magenta). ✔

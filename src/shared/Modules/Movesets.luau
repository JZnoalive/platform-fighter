-- ReplicatedStorage.Shared.Modules.Movesets
-- Lista única de movesets POR ARMA (estilo Brawlhalla: el arma da los ataques).
-- La usan el servidor (CombatService, CpuService) y el cliente (CombatController,
-- PoseController), así nunca se desincronizan.
-- El arma de cada luchador está en su atributo "Weapon".
-- Para añadir un arma: crear Config/Weapons/<Nombre>.luau, su aspecto en
-- Config/WeaponStyles.luau y añadirla aquí.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = ReplicatedStorage.Shared.Config.Weapons

return {
	Gauntlets = require(Weapons.Gauntlets),
	Sword = require(Weapons.Sword),
	Scythe = require(Weapons.Scythe),
	Blasters = require(Weapons.Blasters),
}

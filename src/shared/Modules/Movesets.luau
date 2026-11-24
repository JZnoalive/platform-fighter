-- ReplicatedStorage.Shared.Modules.Movesets
-- Lista única de movesets por FighterId. La usan el servidor (CombatService)
-- y el cliente (CombatController), así nunca se desincronizan.
-- Para añadir un luchador: crear Config/Fighters/<Nombre>.luau y añadirlo aquí.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fighters = ReplicatedStorage.Shared.Config.Fighters

return {
	Brawler = require(Fighters.Brawler),
}

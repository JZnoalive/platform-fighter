-- ServerScriptService.Server.Services.FighterService
-- Registro de TODOS los luchadores (jugadores, dummy y, más adelante, CPU),
-- su estado (atributos) y cómo reciben un golpe.
-- El combate solo puede golpear lo que esté registrado aquí.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knockback = require(ReplicatedStorage.Shared.Modules.Knockback)
local Remotes = require(script.Parent.Parent.Remotes)

local FighterService = {}

export type Fighter = {
	model: Model,
	kind: string, -- "Player" | "Dummy" | "Cpu"
	fighterId: string, -- "Brawler", "Blade", "Dummy"
	player: Player?,
	root: BasePart,
	humanoid: Humanoid,
	hitToken: number, -- cambia con cada golpe recibido (invalida temporizadores viejos)
	attackToken: number, -- cambia con cada ataque iniciado
	queuedAttack: any?, -- ataque pedido durante otro ataque (búfer de combos)
	queuedAt: number, -- cuándo se pidió
}

local fighters: { [Model]: Fighter } = {}

local function createPercentLabel(fighter: Fighter)
	-- Etiqueta provisional de % encima del luchador (el HUD real llega en M7).
	local gui = Instance.new("BillboardGui")
	gui.Name = "PercentLabel"
	gui.Size = UDim2.fromOffset(120, 36)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui

	local function refresh()
		local text = `{math.floor(fighter.model:GetAttribute("Percent") or 0)}%`
		local stocks = fighter.model:GetAttribute("Stocks")
		if stocks then
			text ..= "  " .. string.rep("●", math.max(stocks, 0))
		end
		label.Text = text
	end
	refresh()
	fighter.model:GetAttributeChangedSignal("Percent"):Connect(refresh)
	fighter.model:GetAttributeChangedSignal("Stocks"):Connect(refresh)

	gui.Parent = fighter.root
end

function FighterService.Register(model: Model, kind: string, fighterId: string, player: Player?): Fighter?
	local root = model:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	local humanoid = model:WaitForChild("Humanoid", 10) :: Humanoid?
	if not root or not humanoid then
		warn(`[FighterService] {model.Name} no tiene HumanoidRootPart o Humanoid; no se registra`)
		return nil
	end

	model:SetAttribute("FighterId", fighterId)
	model:SetAttribute("Percent", 0)
	model:SetAttribute("State", "Idle")

	local fighter: Fighter = {
		model = model,
		kind = kind,
		fighterId = fighterId,
		player = player,
		root = root,
		humanoid = humanoid,
		hitToken = 0,
		attackToken = 0,
		queuedAttack = nil,
		queuedAt = 0,
	}
	fighters[model] = fighter
	createPercentLabel(fighter)

	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			fighters[model] = nil
		end
	end)

	return fighter
end

function FighterService.Get(model: Model?): Fighter?
	if not model then
		return nil
	end
	return fighters[model]
end

-- Dada cualquier pieza (brazo, accesorio...), devuelve su luchador registrado o nil.
function FighterService.GetFromInstance(instance: Instance): Fighter?
	local current: Instance? = instance
	while current do
		local fighter = fighters[current :: any]
		if fighter then
			return fighter
		end
		current = current.Parent
	end
	return nil
end

function FighterService.GetModels(): { Model }
	local list = {}
	for model in fighters do
		table.insert(list, model)
	end
	return list
end

function FighterService.SetState(fighter: Fighter, state: string)
	fighter.model:SetAttribute("State", state)
end

function FighterService.GetState(fighter: Fighter): string
	return fighter.model:GetAttribute("State") or "Idle"
end

-- Invalida cualquier hitstun o ataque en curso (sus temporizadores ya no harán nada).
function FighterService.CancelTimers(fighter: Fighter)
	fighter.hitToken += 1
	fighter.attackToken += 1
	fighter.queuedAttack = nil
end

-- Vuelve a dejar al luchador como nuevo (0 %, Idle). Lo usan el dummy y el respawn.
function FighterService.Reset(fighter: Fighter)
	FighterService.CancelTimers(fighter)
	fighter.model:SetAttribute("Percent", 0)
	fighter.model:SetAttribute("State", "Idle")
end

-- Aplica un golpe: suma %, calcula knockback y pone en hitstun.
-- facing: hacia dónde mira el ATACANTE (1 derecha, -1 izquierda).
function FighterService.ApplyHit(target: Fighter, attack, facing: number)
	local state = FighterService.GetState(target)
	if target.model:GetAttribute("Invulnerable") or state == "KO" or state == "Respawning" or state == "Eliminated" then
		return
	end

	local percent = (target.model:GetAttribute("Percent") or 0) + attack.damage
	target.model:SetAttribute("Percent", percent)

	local velocity, hitstun = Knockback.Compute(attack, percent, facing)

	target.hitToken += 1
	local token = target.hitToken
	target.queuedAttack = nil -- un golpe recibido borra el ataque que tenía en cola
	target.model:SetAttribute("State", "Hitstun")

	if target.player then
		-- El jugador es dueño de la física de su personaje: el knockback lo aplica su cliente.
		Remotes.ApplyKnockback:FireClient(target.player, velocity, hitstun)
	else
		-- Dummy / CPU: el servidor es su dueño, se aplica aquí.
		target.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		target.root.AssemblyLinearVelocity = velocity
	end

	task.delay(hitstun, function()
		if target.hitToken ~= token or not target.model.Parent then
			return -- recibió otro golpe o ya no existe
		end
		target.model:SetAttribute("State", "Idle")
		if not target.player then
			target.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		FighterService.Register(character, "Player", "Brawler", player)
	end)
	if player.Character then
		task.spawn(FighterService.Register, player.Character, "Player", "Brawler", player)
	end
end

function FighterService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return FighterService

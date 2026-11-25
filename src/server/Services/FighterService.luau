-- ServerScriptService.Server.Services.FighterService
-- Registro de TODOS los luchadores (jugadores, dummy y, más adelante, CPU),
-- su estado (atributos) y cómo reciben un golpe.
-- El combate solo puede golpear lo que esté registrado aquí.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStyles = require(ReplicatedStorage.Shared.Config.CharacterStyles)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Knockback = require(ReplicatedStorage.Shared.Modules.Knockback)
local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)
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
	queuedMove: string?, -- su nombre ("Jab"...)
	queuedAt: number, -- cuándo se pidió
	lastDodgeAt: number, -- para el enfriamiento de la esquiva
	lastLandedAt: number, -- último golpe acertado (chase dodge)
	inputDir: number, -- dirección que pulsaba al pedir el ataque (-1, 0, 1): "active input"
	queuedDir: number, -- la del ataque en cola
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
	model:SetAttribute("DisplayName", if player then player.DisplayName else model.Name)
	if model:GetAttribute("Weapon") == nil then
		-- Arma por defecto del personaje (AppearanceService la cambia y pone su aspecto).
		local style = CharacterStyles[fighterId]
		model:SetAttribute("Weapon", if style then style.defaultWeapon else "Gauntlets")
	end

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
		queuedMove = nil,
		queuedAt = 0,
		lastDodgeAt = -math.huge,
		lastLandedAt = -math.huge,
		inputDir = 0,
		queuedDir = 0,
	}
	fighters[model] = fighter
	if GameConfig.ShowOverheadPercent then
		createPercentLabel(fighter)
	end

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

function FighterService.GetAll(): { Fighter }
	local list = {}
	for _, fighter in fighters do
		table.insert(list, fighter)
	end
	return list
end

function FighterService.GetModels(): { Model }
	local list = {}
	for model in fighters do
		table.insert(list, model)
	end
	return list
end

-- Ataques del arma que lleva ahora el luchador (atributo "Weapon").
function FighterService.GetMoveset(fighter: Fighter)
	return Movesets[fighter.model:GetAttribute("Weapon")]
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

-- Hitlag (estilo Smash): congelación breve al impactar, más larga cuanto más daño.
function FighterService.ComputeHitlag(attack): number
	return math.min(GameConfig.HitlagBase + attack.damage * GameConfig.HitlagPerDamage, GameConfig.HitlagMax)
end

-- Aplica un golpe: suma %, congela un instante (hitlag), y luego knockback + hitstun.
-- facing: hacia dónde mira el ATACANTE (1 derecha, -1 izquierda).
-- attacker: quien golpea (se congela también); nil para proyectiles.
function FighterService.ApplyHit(target: Fighter, attack, facing: number, attacker: Fighter?)
	local state = FighterService.GetState(target)
	if
		target.model:GetAttribute("Invulnerable")
		or state == "Dodging"
		or state == "KO"
		or state == "Respawning"
		or state == "Eliminated"
	then
		return
	end

	local percent = (target.model:GetAttribute("Percent") or 0) + attack.damage
	target.model:SetAttribute("Percent", percent)

	-- Contador de combo: si ya estaba aturdido, este golpe suma al combo.
	if state == "Hitstun" then
		target.model:SetAttribute("ComboHits", (target.model:GetAttribute("ComboHits") or 0) + 1)
		target.model:SetAttribute("ComboDamage", (target.model:GetAttribute("ComboDamage") or 0) + attack.damage)
	else
		target.model:SetAttribute("ComboHits", 1)
		target.model:SetAttribute("ComboDamage", attack.damage)
	end

	local velocity, hitstun = Knockback.Compute(attack, percent, facing)
	local hitlag = FighterService.ComputeHitlag(attack)

	-- Congelar a los dos durante el hitlag (lo leen MovementController y CpuService).
	local frozenUntil = workspace:GetServerTimeNow() + hitlag
	target.model:SetAttribute("FrozenUntil", frozenUntil)
	if attacker then
		attacker.model:SetAttribute("FrozenUntil", frozenUntil)
		attacker.lastLandedAt = os.clock() -- para la chase dodge
	end

	-- Efectos visuales (chispa, destello, sacudida, estela de humo): los pinta cada cliente.
	Remotes.HitEvent:FireAllClients(
		target.model,
		target.root.Position,
		velocity.Magnitude,
		hitlag + hitstun,
		if attacker then attacker.model else nil
	)

	target.hitToken += 1
	local token = target.hitToken
	target.queuedAttack = nil -- un golpe recibido borra el ataque que tenía en cola
	target.model:SetAttribute("State", "Hitstun")

	if target.player then
		-- El jugador es dueño de la física de su personaje: el knockback lo aplica su cliente
		-- después del hitlag.
		Remotes.ApplyKnockback:FireClient(target.player, velocity, hitstun, hitlag)
	else
		-- Dummy / CPU: el servidor es su dueño. Quieto durante el hitlag, luego sale volando.
		target.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		target.root.AssemblyLinearVelocity = Vector3.zero
		task.delay(hitlag, function()
			if target.hitToken == token and target.model.Parent then
				target.root.AssemblyLinearVelocity = velocity
			end
		end)
	end

	task.delay(hitlag + hitstun, function()
		if target.hitToken ~= token or not target.model.Parent then
			return -- recibió otro golpe o ya no existe
		end
		target.model:SetAttribute("State", "Idle")
		if not target.player then
			target.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end)
end

-- Esquiva: solo desde Idle y respetando el enfriamiento. Mientras dura, State = "Dodging"
-- y ApplyHit no hace nada. El MOVIMIENTO de la esquiva lo pone quien controla el cuerpo:
-- el cliente (jugador) o CpuService (CPU). Devuelve true si empezó.
function FighterService.TryStartDodge(fighter: Fighter): boolean
	if FighterService.GetState(fighter) ~= "Idle" then
		return false
	end
	local now = os.clock()
	-- Chase dodge (Brawlhalla): justo después de acertar un golpe, el enfriamiento es corto.
	local cooldown = if now - fighter.lastLandedAt <= GameConfig.ChaseDodgeWindow
		then GameConfig.ChaseDodgeCooldown
		else GameConfig.DodgeCooldown
	if now - fighter.lastDodgeAt < cooldown then
		return false
	end
	fighter.lastDodgeAt = now
	fighter.queuedAttack = nil
	FighterService.SetState(fighter, "Dodging")
	local token = fighter.hitToken

	-- Brillo azulado para que se vea la esquiva.
	local highlight = Instance.new("Highlight")
	highlight.Name = "DodgeHighlight"
	highlight.FillColor = Color3.fromRGB(140, 200, 255)
	highlight.FillTransparency = 0.6
	highlight.OutlineColor = Color3.fromRGB(140, 200, 255)
	highlight.Parent = fighter.model

	if not fighter.player then
		fighter.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	task.delay(GameConfig.DodgeDuration, function()
		highlight:Destroy()
		if fighter.hitToken ~= token or not fighter.model.Parent then
			return -- KO o respawn en medio: otro sistema manda
		end
		if FighterService.GetState(fighter) == "Dodging" then
			FighterService.SetState(fighter, "Idle")
			if not fighter.player then
				fighter.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end
	end)
	return true
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

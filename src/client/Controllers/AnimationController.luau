-- StarterPlayer.StarterPlayerScripts.Client.Controllers.AnimationController
-- Reproduce las animaciones REALES (Shared.Config.Animations) de TODOS los luchadores
-- que ve este cliente, leyendo sus atributos (State, Move, MoveTime, Weapon):
--   Atacando  → animación del ataque, ajustada a su duración exacta
--   Hitstun   → recibir golpe · Esquivando → esquiva
--   Resto     → guardia (quieto) o carrera (moviéndose) en bucle
--   Victoria  → pose de victoria del ganador
-- Lo que no tenga animación lo cubre PoseController con poses por código.
-- Desactiva el script "Animate" de Roblox del personaje local para que mande esto.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Animations = require(ReplicatedStorage.Shared.Config.Animations)
local Poses = require(ReplicatedStorage.Shared.Config.Poses)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)
local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)

local AnimationController = {}

type ModelState = {
	tracks: { [string]: AnimationTrack },
	current: AnimationTrack?, -- pista "de acción" sonando (ataque / golpe / esquiva / victoria)
	currentKey: string?,
	loop: AnimationTrack?, -- pista de locomoción sonando (guardia / carrera)
	loopKey: string?,
	predictedAt: number?, -- cuándo se predijo el último ataque (respuesta instantánea)
	duration: number?, -- duración que debe tener la pista de acción actual
}

local states: { [Model]: ModelState } = {}

-- Animación para un ataque de un arma (o la general), o nil.
function AnimationController.GetAttackAnimation(weapon: string?, move: string?): string?
	if not move then
		return nil
	end
	-- Si el ataque tiene pose diseñada a mano (codePose), la dibuja PoseController.
	local weaponPoses = weapon and Poses.Weapons[weapon]
	if weaponPoses and weaponPoses[move] and weaponPoses[move].codePose then
		return nil
	end
	local byWeapon = weapon and Animations.Weapons[weapon]
	return (byWeapon and byWeapon[move]) or Animations.Generic[move]
end

local function getAnimator(model: Model): Animator?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function getTrack(model: Model, st: ModelState, animationId: string): AnimationTrack?
	local track = st.tracks[animationId]
	if track then
		return track
	end
	local animator = getAnimator(model)
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, result = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		return nil
	end
	st.tracks[animationId] = result
	return result
end

-- Velocidad para que la animación dure "duration" segundos.
local function speedFor(track: AnimationTrack, duration: number): number
	if track.Length > 0 and duration > 0 then
		return math.clamp(track.Length / duration, 0.25, 6)
	end
	return 1
end

local function playAction(model: Model, st: ModelState, key: string, animationId: string, duration: number?, looped: boolean)
	if st.currentKey == key then
		return -- ya suena (la velocidad la ajusta applyActionSpeed cada frame)
	end
	if st.current then
		st.current:Stop(0.06)
	end
	local track = getTrack(model, st, animationId)
	st.current = track
	st.currentKey = key
	st.duration = duration
	if track then
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = looped
		track:Play(0.05, 1, if duration then speedFor(track, duration) else 1)
	end
end

-- Velocidad que debe llevar la pista de acción (0 durante el hitlag: "congelada").
local function applyActionSpeed(model: Model, st: ModelState)
	local track = st.current
	if not track or not track.IsPlaying then
		return
	end
	local frozenUntil = model:GetAttribute("FrozenUntil")
	if type(frozenUntil) == "number" and workspace:GetServerTimeNow() < frozenUntil then
		track:AdjustSpeed(0)
	else
		track:AdjustSpeed(if st.duration then speedFor(track, st.duration) else 1)
	end
end

local function stopAction(st: ModelState)
	if st.current then
		st.current:Stop(0.12)
	end
	st.current = nil
	st.currentKey = nil
end

local function playLoop(model: Model, st: ModelState, key: string, animationId: string, speed: number)
	if st.loopKey ~= key then
		if st.loop then
			st.loop:Stop(0.2)
		end
		local track = getTrack(model, st, animationId)
		st.loop = track
		st.loopKey = key
		if track then
			-- Movement: por encima de cualquier animación de reposo que haya dejado Roblox
			track.Priority = Enum.AnimationPriority.Movement
			track.Looped = true
			track:Play(0.2)
		end
	end
	if st.loop then
		st.loop:AdjustSpeed(speed)
	end
end

local function attackDuration(model: Model): number?
	local moveset = FighterStats.Moveset(model:GetAttribute("Weapon"), model:GetAttribute("FighterId"))
	local data = moveset and moveset[model:GetAttribute("Move")]
	if not data then
		return nil
	end
	return data.startup + data.active + data.recovery
end

local function updateModel(model: Model)
	local st = states[model]
	if not st then
		st = { tracks = {} }
		states[model] = st
	end

	local state = model:GetAttribute("State")
	if state == "Attacking" then
		local move = model:GetAttribute("Move")
		local animationId = AnimationController.GetAttackAnimation(model:GetAttribute("Weapon"), move)
		if animationId then
			local key = `atk:{move}:{model:GetAttribute("MoveId")}`
			if st.currentKey == `pred:{move}` and os.clock() - (st.predictedAt or 0) < 0.5 then
				-- Ya la empezamos al pulsar (predicción): no reiniciarla.
				st.currentKey = key
			else
				playAction(model, st, key, animationId, attackDuration(model), false)
			end
		else
			stopAction(st)
		end
	elseif st.currentKey and string.sub(st.currentKey, 1, 5) == "pred:" and os.clock() - (st.predictedAt or 0) < 0.35 then
		-- Predicción en curso: el servidor aún no ha confirmado el ataque. Se deja sonar.
	elseif state == "Hitstun" and Animations.States.Hurt then
		playAction(model, st, "hurt", Animations.States.Hurt, nil, true)
	elseif state == "Dodging" and Animations.States.Dodge then
		playAction(model, st, "dodge", Animations.States.Dodge, GameConfig.DodgeDuration, false)
	elseif st.currentKey ~= "victory" then
		stopAction(st)
	end
	applyActionSpeed(model, st)

	-- Locomoción: guardia o carrera según la velocidad (solo en el suelo).
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local vel = root.AssemblyLinearVelocity
		local onGround = math.abs(vel.Y) < 4
		if onGround and math.abs(vel.X) > 2 and Animations.States.Run then
			playLoop(model, st, "run", Animations.States.Run, math.clamp(math.abs(vel.X) / 20, 0.6, 1.8))
		elseif Animations.States.Idle then
			playLoop(model, st, "idle", Animations.States.Idle, 1)
		end
	end
end

-- Respuesta instantánea: al pulsar un ataque, MI personaje empieza la animación YA,
-- sin esperar al servidor (como en Brawlhalla). Cuando llega la confirmación, sigue
-- la misma animación sin reiniciarla.
function AnimationController.PredictAttack(moveName: string)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local animationId = AnimationController.GetAttackAnimation(character:GetAttribute("Weapon"), moveName)
	local moveset = FighterStats.Moveset(character:GetAttribute("Weapon"), character:GetAttribute("FighterId"))
	local data = moveset and moveset[moveName]
	if not animationId or not data then
		return
	end
	local st = states[character]
	if not st then
		st = { tracks = {} }
		states[character] = st
	end
	st.predictedAt = os.clock()
	playAction(character, st, `pred:{moveName}`, animationId, data.startup + data.active + data.recovery, false)
end

-- El ganador hace su pose de victoria.
function AnimationController.PlayVictory(displayName: string)
	for model, st in states do
		if model.Parent and model:GetAttribute("DisplayName") == displayName and Animations.States.Victory then
			st.currentKey = nil
			playAction(model, st, "victory", Animations.States.Victory, nil, false)
		end
	end
end

local function disableDefaultAnimate(character: Model)
	local animate = character:WaitForChild("Animate", 5)
	if animate and animate:IsA("LocalScript") then
		animate.Enabled = false
	end
	states[character] = nil
	-- Parar lo que hubiera dejado sonando el Animate de Roblox (ahora y un poco después,
	-- por si arrancó una animación justo antes de apagarse).
	for _, delay in { 0, 0.5, 1.5 } do
		task.delay(delay, function()
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			local st = states[character]
			if not animator then
				return
			end
			for _, track in animator:GetPlayingAnimationTracks() do
				local ours = false
				if st then
					for _, t in st.tracks do
						if t == track then
							ours = true
							break
						end
					end
				end
				if not ours then
					track:Stop(0.1)
				end
			end
		end)
	end
end

function AnimationController.Start()
	local player = Players.LocalPlayer
	if player.Character then
		task.spawn(disableDefaultAnimate, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(disableDefaultAnimate, character)
	end)

	RunService.Heartbeat:Connect(function()
		for _, other in Players:GetPlayers() do
			local character = other.Character
			if character and character.Parent and character:GetAttribute("FighterId") then
				updateModel(character)
			end
		end
		for _, model in CollectionService:GetTagged("CameraTarget") do
			if model:IsA("Model") and model:IsDescendantOf(workspace) then
				updateModel(model)
			end
		end
	end)

	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local matchEvent = remotes:WaitForChild("MatchEvent") :: RemoteEvent
		matchEvent.OnClientEvent:Connect(function(kind, data)
			if kind == "Victory" and data and data.name then
				task.delay(0.5, AnimationController.PlayVictory, data.name)
			end
		end)
	end)

	-- Limpieza de modelos que ya no existen
	task.spawn(function()
		while true do
			task.wait(5)
			for model in states do
				if not model.Parent then
					states[model] = nil
				end
			end
		end
	end)
end

return AnimationController

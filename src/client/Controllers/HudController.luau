-- StarterPlayer.StarterPlayerScripts.Client.Controllers.HudController
-- M4: mensajes grandes de partida en el centro de la pantalla
-- ("¡A pelear!", "¡KO!", "¡X gana!"). El HUD completo llega en M7.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudController = {}

local label: TextLabel
local showToken = 0

local function createGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MatchHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.3)
	label.Size = UDim2.fromScale(0.6, 0.12)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Visible = false
	label.Parent = gui

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- duration = nil → se queda hasta el próximo mensaje.
local function show(text: string, duration: number?)
	showToken += 1
	local token = showToken
	label.Text = text
	label.Visible = true
	if duration then
		task.delay(duration, function()
			if showToken == token then
				label.Visible = false
			end
		end)
	end
end

local function onMatchEvent(kind: string, data: { [string]: any })
	if kind == "Start" then
		show("¡A pelear!", 1.5)
	elseif kind == "KO" then
		local text = `¡KO! {data.name}`
		if data.stocks ~= nil then
			text ..= ` — quedan {data.stocks}`
		end
		show(text, 1.5)
	elseif kind == "Victory" then
		show(if data.name then `¡{data.name} gana!` else "Sin ganador", nil)
	end
end

function HudController.Start()
	-- En segundo plano para no bloquear a nadie.
	task.spawn(function()
		createGui()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local matchEvent = remotes:WaitForChild("MatchEvent") :: RemoteEvent
		matchEvent.OnClientEvent:Connect(onMatchEvent)
	end)
end

return HudController

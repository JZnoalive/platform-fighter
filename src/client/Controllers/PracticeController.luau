-- StarterPlayer.StarterPlayerScripts.Client.Controllers.PracticeController
-- Menú de práctica (panel a la izquierda). Solo aparece en modo práctica
-- (Workspace.PracticeActive = true). Tecla P para ocultarlo/mostrarlo.
-- El menú solo PIDE cosas al servidor (remote PracticeCommand); el servidor decide.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CpuConfig = require(ReplicatedStorage.Shared.Config.CpuConfig)
local WeaponStyles = require(ReplicatedStorage.Shared.Config.WeaponStyles)

local PracticeController = {}

local COLOR_PANEL = Color3.fromRGB(20, 20, 28)
local COLOR_BUTTON = Color3.fromRGB(45, 45, 60)
local COLOR_SELECTED = Color3.fromRGB(217, 78, 40) -- naranja de Brawler
local COLOR_CPU = Color3.fromRGB(124, 58, 237) -- violeta de Blade
local COLOR_TEXT = Color3.new(1, 1, 1)

local hiddenByUser = false
local panel: Frame
local behaviorButtons: { [string]: TextButton } = {}
local myWeaponButtons: { [string]: TextButton } = {}
local cpuWeaponButtons: { [string]: TextButton } = {}
local hitboxButton: TextButton

local function makeLabel(parent: Instance, text: string, order: number)
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = COLOR_TEXT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
end

local function makeButton(parent: Instance, text: string, order: number, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.LayoutOrder = order
	button.Size = size
	button.BackgroundColor3 = COLOR_BUTTON
	button.AutoButtonColor = true
	button.Font = Enum.Font.Gotham
	button.TextSize = 14
	button.TextColor3 = COLOR_TEXT
	button.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	button.Parent = parent
	return button
end

local function refreshVisibility()
	panel.Visible = workspace:GetAttribute("PracticeActive") == true and not hiddenByUser
end

local function refreshBehavior()
	local current = workspace:GetAttribute("CpuBehavior")
	for name, button in behaviorButtons do
		button.BackgroundColor3 = if name == current then COLOR_SELECTED else COLOR_BUTTON
	end
end

local function refreshHitboxes()
	hitboxButton.Text = if workspace:GetAttribute("DebugHitboxes") then "Hitboxes: SÍ" else "Hitboxes: NO"
end

-- Fila de 4 botones de arma. onClick(weaponId). Devuelve los botones por arma.
local function makeWeaponRow(order: number, onClick: (string) -> ()): { [string]: TextButton }
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundTransparency = 1
	row.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 3)
	layout.Parent = row

	local buttons = {}
	local count = #WeaponStyles.Order
	for index, weaponId in WeaponStyles.Order do
		local button = makeButton(
			row,
			WeaponStyles[weaponId].label,
			index,
			UDim2.new(1 / count, -3 * (count - 1) / count, 1, 0)
		)
		button.TextSize = 11
		button.Activated:Connect(function()
			onClick(weaponId)
		end)
		buttons[weaponId] = button
	end
	return buttons
end

-- Resalta el arma actual de cada fila (lee el atributo "Weapon").
local function refreshWeapons()
	local character = Players.LocalPlayer.Character
	local myWeapon = character and character:GetAttribute("Weapon")
	local cpu = CollectionService:GetTagged("CameraTarget")[1]
	local cpuWeapon = cpu and cpu:GetAttribute("Weapon")
	for weaponId, button in myWeaponButtons do
		button.BackgroundColor3 = if weaponId == myWeapon then COLOR_SELECTED else COLOR_BUTTON
	end
	for weaponId, button in cpuWeaponButtons do
		button.BackgroundColor3 = if weaponId == cpuWeapon then COLOR_CPU else COLOR_BUTTON
	end
end

local function build(practiceCommand: RemoteEvent)
	local gui = Instance.new("ScreenGui")
	gui.Name = "PracticeMenu"
	gui.ResetOnSpawn = false

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 12, 0.5, 0)
	panel.Size = UDim2.new(0, 200, 0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = COLOR_PANEL
	panel.BackgroundTransparency = 0.15
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = panel

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	makeLabel(panel, "PRÁCTICA   (P = ocultar)", nextOrder())

	-- Partida de verdad contra la CPU (3 vidas). Al terminar, vuelve la práctica.
	local vsCpuButton = makeButton(panel, "⚔ Pelear contra la CPU (3 vidas)", nextOrder(), UDim2.new(1, 0, 0, 32))
	vsCpuButton.BackgroundColor3 = Color3.fromRGB(124, 58, 237) -- violeta de Blade
	vsCpuButton.Font = Enum.Font.GothamBold
	vsCpuButton.Activated:Connect(function()
		practiceCommand:FireServer("StartVsCpu")
	end)

	-- Armas (estilo Brawlhalla): cada arma tiene sus propios ataques.
	makeLabel(panel, "Mi arma:", nextOrder())
	myWeaponButtons = makeWeaponRow(nextOrder(), function(weaponId)
		practiceCommand:FireServer("Weapon", weaponId)
	end)
	makeLabel(panel, "Arma de la CPU:", nextOrder())
	cpuWeaponButtons = makeWeaponRow(nextOrder(), function(weaponId)
		practiceCommand:FireServer("CpuWeapon", weaponId)
	end)

	-- Comportamiento de la CPU en 2 columnas para que el panel no sea tan alto.
	makeLabel(panel, "CPU:", nextOrder())
	local grid = Instance.new("Frame")
	grid.LayoutOrder = nextOrder()
	grid.Size = UDim2.new(1, 0, 0, math.ceil(#CpuConfig.Behaviors / 2) * 30)
	grid.BackgroundTransparency = 1
	grid.Parent = panel
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -2, 0, 26)
	gridLayout.CellPadding = UDim2.fromOffset(4, 4)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid
	for index, name in CpuConfig.Behaviors do
		local button = makeButton(grid, CpuConfig.Labels[name] or name, index, UDim2.new(0.5, -2, 0, 26))
		button.Activated:Connect(function()
			practiceCommand:FireServer("Behavior", name)
		end)
		behaviorButtons[name] = button
	end

	makeLabel(panel, "% de la CPU:", nextOrder())
	local row = Instance.new("Frame")
	row.LayoutOrder = nextOrder()
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundTransparency = 1
	row.Parent = panel
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 4)
	rowLayout.Parent = row
	local presetCount = #CpuConfig.PercentPresets
	for index, percent in CpuConfig.PercentPresets do
		local button = makeButton(
			row,
			`{percent}`,
			index,
			UDim2.new(1 / presetCount, -4 * (presetCount - 1) / presetCount, 1, 0)
		)
		button.Activated:Connect(function()
			practiceCommand:FireServer("Percent", percent)
		end)
	end

	local resetButton = makeButton(panel, "Reiniciar CPU y mi %", nextOrder(), UDim2.new(1, 0, 0, 26))
	resetButton.Activated:Connect(function()
		practiceCommand:FireServer("Reset")
	end)

	hitboxButton = makeButton(panel, "Hitboxes", nextOrder(), UDim2.new(1, 0, 0, 26))
	hitboxButton.Activated:Connect(function()
		practiceCommand:FireServer("Hitboxes", not workspace:GetAttribute("DebugHitboxes"))
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	refreshVisibility()
	refreshBehavior()
	refreshHitboxes()
	workspace:GetAttributeChangedSignal("PracticeActive"):Connect(refreshVisibility)
	workspace:GetAttributeChangedSignal("CpuBehavior"):Connect(refreshBehavior)
	workspace:GetAttributeChangedSignal("DebugHitboxes"):Connect(refreshHitboxes)
	task.spawn(function()
		while gui.Parent do
			refreshWeapons()
			task.wait(0.25)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
			hiddenByUser = not hiddenByUser
			refreshVisibility()
		end
	end)
end

function PracticeController.Start()
	-- En segundo plano para no bloquear a nadie.
	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local practiceCommand = remotes:WaitForChild("PracticeCommand") :: RemoteEvent
		build(practiceCommand)
	end)
end

return PracticeController

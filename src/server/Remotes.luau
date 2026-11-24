-- ServerScriptService.Server.Remotes
-- Crea los RemoteEvents al arrancar el servidor, en ReplicatedStorage.Shared.Remotes.
-- El cliente los busca con WaitForChild (siempre existen porque los crea el servidor).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local function make(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local Remotes = {
	ActionRequest = make("ActionRequest"), -- cliente → servidor: { action = "Attack", move = "Jab" } o { action = "Dodge" }
	PracticeCommand = make("PracticeCommand"), -- cliente → servidor: (command, value) del menú de práctica
	ApplyKnockback = make("ApplyKnockback"), -- servidor → cliente víctima: (velocity, hitstun)
	FighterReset = make("FighterReset"), -- servidor → cliente: "te acabo de recolocar, reinicia tu movimiento"
	MatchEvent = make("MatchEvent"), -- servidor → todos: (kind, data) con kind = "Start" | "KO" | "Victory"
}

folder.Parent = ReplicatedStorage.Shared

return Remotes

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
	ActionRequest = make("ActionRequest"), -- cliente → servidor: { action = "Attack", move = "Jab" }
	ApplyKnockback = make("ApplyKnockback"), -- servidor → cliente víctima: (velocity, hitstun)
}

folder.Parent = ReplicatedStorage.Shared

return Remotes

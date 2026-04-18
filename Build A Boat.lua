local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/NightSyste/UI.lua/refs/heads/main/orion.lua'))()

local Window = OrionLib:MakeWindow({
    Name = "Bootsbau & Schatzsuche - DarkScripterX",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "BABFT_FullAutoFarm"
})

local AutoTab = Window:MakeTab({ Name = "Auto Farm", Icon = "rbxassetid://6031094678", PremiumOnly = false })
local VisualsTab = Window:MakeTab({ Name = "Visuals", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local PlayerTab = Window:MakeTab({ Name = "Player", Icon = "rbxassetid://6031094680", PremiumOnly = false })
local SettingsTab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://6031094667", PremiumOnly = false })

-- ====================== PAYLOAD SYSTEM ======================
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local PAYLOAD_FILE = "BABFT_Payload.lua"
local PAYLOAD_FLAG = "BABFT_PayloadFlag.json"

-- Das komplette Script als Payload speichern
local SELF_SCRIPT = [[
loadstring(game:HttpGet('https://raw.githubusercontent.com/NightSyste/UI.lua/refs/heads/main/orion.lua'))()
]] -- <-- Hier deine eigene Script-URL rein falls du eine hast

local function savePayload()
    pcall(function()
        writefile(PAYLOAD_FILE, SELF_SCRIPT)
        writefile(PAYLOAD_FLAG, HttpService:JSONEncode({ execute = true }))
    end)
end

local function clearPayload()
    pcall(function()
        writefile(PAYLOAD_FLAG, HttpService:JSONEncode({ execute = false }))
    end)
end

local function checkAndRunPayload()
    local ok, flagData = pcall(function()
        return HttpService:JSONDecode(readfile(PAYLOAD_FLAG))
    end)
    if ok and flagData and flagData.execute == true then
        clearPayload()
        local payloadOk, payloadContent = pcall(function()
            return readfile(PAYLOAD_FILE)
        end)
        if payloadOk and payloadContent and payloadContent ~= "" then
            spawn(function()
                wait(3)
                local runOk, err = pcall(function()
                    loadstring(payloadContent)()
                end)
                if not runOk then
                    warn("[Payload] Fehler beim Ausführen: " .. tostring(err))
                end
            end)
        end
    end
end

-- Beim Start direkt checken ob ein Payload wartet
checkAndRunPayload()

-- ====================== AUTO FARM ======================
local points = {
    Vector3.new(-51, 287, 388), Vector3.new(-51, 70, 773), Vector3.new(-51, 13, 1574),
    Vector3.new(-51, 13, 2106), Vector3.new(-51, 13, 2249), Vector3.new(-51, 13, 2864),
    Vector3.new(-51, 13, 3212), Vector3.new(-51, 13, 3647), Vector3.new(-51, 13, 4000),
    Vector3.new(-51, 13, 4542), Vector3.new(-51, 13, 5573), Vector3.new(-51, 13, 6000),
    Vector3.new(-51, 13, 6700), Vector3.new(-51, 13, 7000), Vector3.new(-51, 30, 7467),
    Vector3.new(-51, 30, 8000), Vector3.new(-51, 30, 8400), Vector3.new(-51, 13, 8691),
    Vector3.new(-51, -330, 8693), Vector3.new(-51, -357, 9485),
    Vector3.new(-51, -357, 9490), Vector3.new(-51, -357, 9509)
}

local autoFarmRunning = false
local antiAFKConnection = nil

local function startAntiAFK()
    if antiAFKConnection then return end
    local VirtualUser = game:GetService("VirtualUser")
    antiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function stopAntiAFK()
    if antiAFKConnection then antiAFKConnection:Disconnect() antiAFKConnection = nil end
end

local function resetCharacter()
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = 0
    end
end

local function startAutoFarm()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.PlatformStand = true

    for _, targetPos in ipairs(points) do
        if not autoFarmRunning then break end
        local currentSpeed = 450
        if targetPos == Vector3.new(-51, -330, 8693) or targetPos == Vector3.new(-51, -357, 9485) or
           targetPos == Vector3.new(-51, -357, 9490) or targetPos == Vector3.new(-51, -357, 9509) then
            currentSpeed = 180
        end
        while autoFarmRunning and (root.Position - targetPos).Magnitude > 20 do
            root.Velocity = (targetPos - root.Position).Unit * currentSpeed
            game:GetService("RunService").Heartbeat:Wait()
        end
    end

    if autoFarmRunning then
        autoFarmRunning = false
        wait(10)
        resetCharacter()
        player.CharacterAdded:Wait()
        wait(5)
        if autoFarmRunning == false then
            autoFarmRunning = true
            spawn(startAutoFarm)
        end
    end
end

-- ====================== ESP ======================
local espEnabled = false
local connections = {}

local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Adornee = player.Character and player.Character:FindFirstChild("Head")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 140, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = game.CoreGui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.GothamSemibold
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0.6
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Parent = billboard

    local function updateESP()
        if not player.Character or not player.Character:FindFirstChild("Head") then return end
        billboard.Adornee = player.Character.Head
        local teamColor = player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
        local teamName = player.Team and player.Team.Name or "Solo"
        local teamId = player.Team and player.Team:GetAttribute("TeamId") or "?"
        text.Text = player.Name .. "\n" .. teamName .. " (" .. teamId .. ")"
        text.TextColor3 = teamColor
    end

    updateESP()
    table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(updateESP))
    table.insert(connections, player.CharacterAdded:Connect(updateESP))
end

local function enableESP()
    if espEnabled then return end
    espEnabled = true
    for _, plr in ipairs(game.Players:GetPlayers()) do createESP(plr) end
    table.insert(connections, game.Players.PlayerAdded:Connect(createESP))
end

local function disableESP()
    espEnabled = false
    for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
    connections = {}
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        if gui.Name:find("ESP_") then gui:Destroy() end
    end
end

-- ====================== FLY ======================
local flying = false
local bodyVelocity, bodyGyro

local function startFly()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    humanoid.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    bodyGyro.P = 12500
    bodyGyro.D = 500
    bodyGyro.Parent = root

    flying = true

    spawn(function()
        while flying and root and root.Parent do
            local cam = workspace.CurrentCamera
            local moveDirection = Vector3.new(0, 0, 0)

            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then moveDirection += cam.CFrame.LookVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then moveDirection -= cam.CFrame.LookVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then moveDirection -= cam.CFrame.RightVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then moveDirection += cam.CFrame.RightVector end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0, 1, 0) end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection -= Vector3.new(0, 1, 0) end

            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
            end

            bodyVelocity.Velocity = moveDirection * 160
            bodyGyro.CFrame = cam.CFrame

            game:GetService("RunService").Heartbeat:Wait()
        end
    end)
end

local function stopFly()
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.PlatformStand = false
    end
end

-- ====================== SERVER HOP ======================
local serverHopRunning = false

local function hopServer()
    local placeId = game.PlaceId
    local currentJobId = game.JobId

    -- Payload speichern VOR dem Hop
    savePayload()

    local ok, result = pcall(function()
        return HttpService:GetAsync(
            "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        )
    end)

    if ok and result then
        local data = HttpService:JSONDecode(result)
        local candidates = {}

        for _, server in ipairs(data.data) do
            if server.id ~= currentJobId and server.playing < server.maxPlayers then
                table.insert(candidates, server.id)
            end
        end

        if #candidates > 0 then
            local target = candidates[math.random(1, #candidates)]
            TeleportService:TeleportToPlaceInstance(placeId, target, game.Players.LocalPlayer)
        else
            warn("[Server Hop] Kein freier Server – Fallback.")
            TeleportService:Teleport(placeId, game.Players.LocalPlayer)
        end
    else
        TeleportService:Teleport(placeId, game.Players.LocalPlayer)
    end
end

-- ====================== AUTO FARM TAB ======================
AutoTab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(Value)
        autoFarmRunning = Value
        if Value then
            startAntiAFK()
            spawn(startAutoFarm)
        else
            stopAntiAFK()
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
        end
    end
})

-- ====================== VISUALS TAB ======================
VisualsTab:AddToggle({
    Name = "ESP aktivieren (Team Check)",
    Default = false,
    Callback = function(Value)
        if Value then enableESP() else disableESP() end
    end
})

-- ====================== PLAYER TAB ======================
PlayerTab:AddToggle({
    Name = "Fly aktivieren",
    Default = false,
    Callback = function(Value)
        if Value then startFly() else stopFly() end
    end
})

PlayerTab:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 500,
    Default = 100,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 5,
    Callback = function(Value)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Value end
    end
})

PlayerTab:AddToggle({
    Name = "Infinity Jump",
    Default = false,
    Callback = function(Value)
        if Value then
            game:GetService("UserInputService").JumpRequest:Connect(function()
                local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then hum:ChangeState("Jumping") end
            end)
        end
    end
})

PlayerTab:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(Value)
        local character = game.Players.LocalPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not Value
            end
        end
    end
})

-- ====================== SETTINGS TAB ======================
SettingsTab:AddButton({
    Name = "Server Hop",
    Callback = function()
        hopServer()
    end
})

SettingsTab:AddToggle({
    Name = "Auto Server Hop (alle 5 Min)",
    Default = false,
    Callback = function(Value)
        serverHopRunning = Value
        if Value then
            spawn(function()
                while serverHopRunning do
                    wait(300)
                    if serverHopRunning then hopServer() end
                end
            end)
        end
    end
})

SettingsTab:AddButton({
    Name = "Rejoin",
    Callback = function()
        savePayload()
        TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

SettingsTab:AddParagraph("Auto Execute", "Payload wird nach jedem Server Hop & Rejoin automatisch ausgeführt.")

-- ====================== INIT ======================
OrionLib:Init()

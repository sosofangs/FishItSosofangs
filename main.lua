-- LocalScript di StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- URL JSON dari GitHub
local jsonURL = "https://raw.githubusercontent.com/username/FishItSosofang/main/rareFish.json"

-- Fetch daftar ikan langka
local function fetchRareFish()
    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(jsonURL))
    end)
    if success then return data else warn("Gagal fetch JSON:", data) return {} end
end

local rareFish = fetchRareFish()
local paused = false
local webhookURL

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))

-- Main Frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 400, 0, 350)
frame.Position = UDim2.new(0.55,0,0.25,0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true

-- Shadow Effect
local uiStroke = Instance.new("UIStroke", frame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(80,80,255)
uiStroke.Transparency = 0.4

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.Position = UDim2.new(0,0,0,0)
title.Text = "🎣 Fish It Auto-Fishing"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1

-- Branding Sosofang
local branding = Instance.new("TextLabel", frame)
branding.Size = UDim2.new(1,0,0,20)
branding.Position = UDim2.new(0,0,0,40)
branding.Text = "By Sosofang"
branding.TextColor3 = Color3.fromRGB(255, 200, 50)
branding.BackgroundTransparency = 1
branding.TextScaled = true
branding.Font = Enum.Font.GothamBold

-- Status Label
local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(0.9,0,0,25)
statusLabel.Position = UDim2.new(0.05,0,0,70)
statusLabel.TextColor3 = Color3.fromRGB(200,200,255)
statusLabel.BackgroundTransparency = 1
statusLabel.TextScaled = true
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.Gotham

-- Webhook Input
local textBox = Instance.new("TextBox", frame)
textBox.Size = UDim2.new(0.9,0,0,30)
textBox.Position = UDim2.new(0.05,0,0,105)
textBox.PlaceholderText = "Masukkan Webhook Discord"
textBox.TextColor3 = Color3.fromRGB(255,255,255)
textBox.BackgroundColor3 = Color3.fromRGB(40,40,50)
textBox.Font = Enum.Font.Gotham
textBox.TextScaled = true

-- Buttons
local function createButton(parent, text, posY, color)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.42,0,0,35)
    btn.Position = UDim2.new(#parent:GetChildren()%2*0.5 + 0.05,0,posY,0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    btn.AutoButtonColor = false
    -- Hover Effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3 = color + Color3.fromRGB(30,30,30)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3 = color}):Play()
    end)
    return btn
end

local submitButton = createButton(frame, "Submit Webhook", 145, Color3.fromRGB(60,60,160))
local pauseButton = createButton(frame, "Pause", 190, Color3.fromRGB(160,60,60))

-- Teleport Buttons Container
local tpFrame = Instance.new("Frame", frame)
tpFrame.Size = UDim2.new(0.9,0,0.4,0)
tpFrame.Position = UDim2.new(0.05,0,0,240)
tpFrame.BackgroundTransparency = 1

-- Pulau & Koordinat
local islands = {
    ["Spawn Island"] = Vector3.new(0,10,0),
    ["Shark Island"] = Vector3.new(200,10,50),
    ["Treasure Island"] = Vector3.new(-150,10,300)
}

-- Buat tombol teleport
local idx = 0
for name,pos in pairs(islands) do
    idx = idx + 1
    local btn = createButton(tpFrame, name, (idx-1)*40, Color3.fromRGB(50,50,120))
    btn.Size = UDim2.new(1,0,0,35)
    btn.Position = UDim2.new(0,0,(idx-1)*0.15,0)
    btn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(pos)
            statusLabel.Text = "Teleported to "..name
        end
    end)
end

-- ===== Tombol Fungsi =====
submitButton.MouseButton1Click:Connect(function()
    webhookURL = textBox.Text
    if webhookURL ~= "" then
        textBox:Destroy()
        submitButton:Destroy()
        statusLabel.Text = "Status: Fishing..."
    else
        warn("Masukkan webhook dulu!")
    end
end)

pauseButton.MouseButton1Click:Connect(function()
    paused = not paused
    pauseButton.Text = paused and "Resume" or "Pause"
    statusLabel.Text = paused and "Status: Paused" or "Status: Fishing..."
end)

-- ===== Fungsi kirim Discord =====
local function sendDiscordEmbed(title, description, color, imageUrl)
    if not webhookURL then return end
    local data = {
        content = "",
        embeds = {{
            title = title,
            description = description,
            color = color,
            footer = { text = "Fish It Auto Webhook 🎣" },
            timestamp = DateTime.now():ToIsoDate(),
            image = imageUrl and { url = imageUrl } or nil
        }}
    }
    pcall(function()
        (http_request or request or syn.request)({
            Url = webhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- ===== Auto-Fishing =====
local function autoFishing()
    local backpack = player:WaitForChild("Backpack")
    local tool = player:WaitForChild("StarterGear"):FindFirstChild("FishingRod") or backpack:FindFirstChild("FishingRod")

    if not tool then
        warn("Fishing Rod tidak ditemukan!")
        return
    end
    tool.Parent = backpack

    RunService.Heartbeat:Connect(function()
        if paused then return end
        if tool and tool.Parent == backpack then
            tool.Parent = player.Character
            tool:Activate()
            task.wait(0.25)
            tool:Deactivate()
        end
    end)

    backpack.ChildAdded:Connect(function(item)
        local fishData = rareFish[item.Name]
        if fishData then
            statusLabel.Text = "Ikan Langka: "..item.Name
            sendDiscordEmbed(
                "🐟 Ikan Langka Didapat!",
                "**"..player.Name.."** menangkap **"..item.Name.."**!",
                fishData.color,
                fishData.image
            )
            task.delay(5,function()
                if not paused then
                    statusLabel.Text = "Status: Fishing..."
                end
            end)
        end
    end)
end

delay(2,function()
    statusLabel.Text = "Status: Fishing..."
    autoFishing()
end)

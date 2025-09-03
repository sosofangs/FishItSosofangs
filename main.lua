-- LocalScript di StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- URL JSON dari GitHub
local jsonURL = "https://raw.githubusercontent.com/username/FishItWebhookHub/main/rareFish.json"

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
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 400, 0, 320)
frame.Position = UDim2.new(0.55,0,0.25,0)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.Active = true
frame.Draggable = true

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Position = UDim2.new(0,0,0,0)
title.Text = "Fish It Auto-Fishing 🎣"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.TextScaled = true

-- Branding Sosofang
local branding = Instance.new("TextLabel", frame)
branding.Size = UDim2.new(1,0,0,20)
branding.Position = UDim2.new(0,0,0,30)
branding.Text = "By Sosofang"
branding.TextColor3 = Color3.fromRGB(255, 200, 50)
branding.BackgroundTransparency = 1
branding.TextScaled = true

-- Webhook
local textBox = Instance.new("TextBox", frame)
textBox.Size = UDim2.new(0.9,0,0,30)
textBox.Position = UDim2.new(0.05,0,0,60)
textBox.PlaceholderText = "Masukkan Webhook Discord"

local submitButton = Instance.new("TextButton", frame)
submitButton.Size = UDim2.new(0.4,0,0,30)
submitButton.Position = UDim2.new(0.05,0,0,100)
submitButton.Text = "Submit"
submitButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
submitButton.TextColor3 = Color3.fromRGB(255,255,255)

-- Pause/Resume
local pauseButton = Instance.new("TextButton", frame)
pauseButton.Size = UDim2.new(0.4,0,0,30)
pauseButton.Position = UDim2.new(0.55,0,0,100)
pauseButton.Text = "Pause"
pauseButton.BackgroundColor3 = Color3.fromRGB(120,40,40)
pauseButton.TextColor3 = Color3.fromRGB(255,255,255)

-- Status
local localNotif = Instance.new("TextLabel", frame)
localNotif.Size = UDim2.new(0.9,0,0.1,0)
localNotif.Position = UDim2.new(0.05,0,0,140)
localNotif.TextColor3 = Color3.fromRGB(255,255,255)
localNotif.BackgroundTransparency = 1
localNotif.TextWrapped = true
localNotif.Text = "Status: Idle"

-- Teleport Frame
local tpFrame = Instance.new("Frame", frame)
tpFrame.Size = UDim2.new(0.9,0,0.4,0)
tpFrame.Position = UDim2.new(0.05,0,0,160)
tpFrame.BackgroundTransparency = 1

-- Daftar pulau (ubah sesuai koordinat game)
local islands = {
    ["Spawn Island"] = Vector3.new(0,10,0),
    ["Shark Island"] = Vector3.new(200,10,50),
    ["Treasure Island"] = Vector3.new(-150,10,300)
}

-- Buat tombol teleport
for i,name in pairs(islands) do
    local btn = Instance.new("TextButton", tpFrame)
    btn.Size = UDim2.new(0.9,0,0,30)
    btn.Position = UDim2.new(0,0,0,(i-1)*35)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(50,50,120)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(islands[name])
            localNotif.Text = "Teleported to "..name
        end
    end)
end

-- ===== Tombol interaksi =====
submitButton.MouseButton1Click:Connect(function()
    webhookURL = textBox.Text
    if webhookURL ~= "" then
        textBox:Destroy()
        submitButton:Destroy()
        localNotif.Text = "Status: Fishing..."
    else
        warn("Masukkan webhook dulu!")
    end
end)

pauseButton.MouseButton1Click:Connect(function()
    paused = not paused
    pauseButton.Text = paused and "Resume" or "Pause"
    localNotif.Text = paused and "Status: Paused" or "Status: Fishing..."
end)

-- ===== Fungsi kirim embed =====
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

    -- Perfect cast loop
    RunService.Heartbeat:Connect(function()
        if paused then return end
        if tool and tool.Parent == backpack then
            tool.Parent = player.Character
            tool:Activate()
            task.wait(0.25) -- adjust timing for perfect cast
            tool:Deactivate()
        end
    end)

    -- Listener ikan langka
    backpack.ChildAdded:Connect(function(item)
        local fishData = rareFish[item.Name]
        if fishData then
            localNotif.Text = "Ikan Langka: "..item.Name
            sendDiscordEmbed(
                "🐟 Ikan Langka Didapat!",
                "**"..player.Name.."** menangkap **"..item.Name.."**!",
                fishData.color,
                fishData.image
            )
            task.delay(5,function()
                if not paused then
                    localNotif.Text = "Status: Fishing..."
                end
            end)
        end
    end)
end

-- Jalankan auto-fishing
delay(2,function()
    localNotif.Text = "Status: Fishing..."
    autoFishing()
end)

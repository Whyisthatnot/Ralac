--== Services ==--
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera            = workspace.CurrentCamera
local player            = Players.LocalPlayer

--== Packages ==--
local FishingController = require(ReplicatedStorage.Controllers.FishingController)
local Replion           = require(ReplicatedStorage.Packages.Replion).Client
local Net               = require(ReplicatedStorage.Packages.Net)
local ItemUtility       = require(ReplicatedStorage.Shared.ItemUtility)
local TierUtility       = require(ReplicatedStorage.Shared.TierUtility)

--== Net remotes ==--
local PurchaseFishingRod = Net:RemoteFunction("PurchaseFishingRod")
local EquipItem          = Net:RemoteEvent("EquipItem")
local PurchaseBait       = Net:RemoteFunction("PurchaseBait")
local EquipBait          = Net:RemoteEvent("EquipBait")
local Config = getgenv().Config

--== sleitnick_net remotes ==--
local NetRoot = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local RE_EquipToolFromHotbar = NetRoot:FindFirstChild("RE/EquipToolFromHotbar")
local RF_SellAllItems        = NetRoot:FindFirstChild("RF/SellAllItems")
local RE_FishingCompleted    = NetRoot:FindFirstChild("RE/FishingCompleted")
local RE_FavoriteItem        = NetRoot:FindFirstChild("RE/FavoriteItem")
local miniGameRemote = NetRoot:WaitForChild("RF/RequestFishingMinigameStarted")

--== Data ==--
local Data = Replion:WaitReplion("Data")

--== Fishing constants ==--
local TARGET_POS  = Vector3.new(-1372.34, 5.25, 4072.17)
local TARGET_LOOK = Vector3.new(1.00, -0.00, 0.02).Unit
local POS_TOLERANCE = 3
local DIR_TOL_DEG   = 15
local HOTBAR_SLOT   = 1

local POST_EQUIP_CAST_DELAY  = 0.05
local BITE_TIMEOUT           = 1
local CHECK_INTERVAL         = 0.02
local RETRY_CASTS            = 2
--// FPS Booster Script (Giảm đồ họa)
-- Đặt trong StarterPlayerScripts để auto chạy

local Lighting = game:GetService("Lighting")

-- Giảm chất lượng render
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 -- thấp nhất

-- Tắt bóng và công nghệ ánh sáng nặng
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 1
pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)

-- Xóa hiệu ứng nặng trong Lighting
for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect")
    or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
        v:Destroy()
    end
end


-- Ẩn cây/cỏ Terrain
workspace.Terrain.WaterReflectance = 0
workspace.Terrain.WaterTransparency = 1
workspace.Terrain.WaterWaveSize = 0
workspace.Terrain.WaterWaveSpeed = 0

-- Tắt hiệu ứng particle
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Enabled = false
    end
end

-- Tắt mesh LOD xa (giữ low poly)
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("MeshPart") then
        v.RenderFidelity = Enum.RenderFidelity.Performance
    end
end

print("✅ FPS Booster Activated - Graphics Reduced")

local function hideUI()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") then
            gui.Enabled = false
        end
    end
end
hideUI()
local startTime = os.clock()

local function setupSimpleUI()
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local player = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Replion = require(ReplicatedStorage.Packages.Replion).Client
    local Data = Replion:WaitReplion("Data")

    -- Ẩn topbar mặc định
    pcall(function()
        StarterGui:SetCore("TopbarEnabled", false)
    end)

    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.DisplayOrder = 2147483647
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Background che toàn màn hình
    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundTransparency = 1 -- mờ nhẹ (20%)
    bgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- xám đậm
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = screenGui

    -- Layout căn giữa
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = bgFrame

    -- Hàm tạo label + gradient
    local function createLabel(name, text, gradientColors, size)
        local lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Size = UDim2.new(1, -100, 0, size or 40)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255) -- cần có base trắng để gradient đẹp
        lbl.Parent = bgFrame

        -- Gradient cho text
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new(gradientColors)
        gradient.Rotation = 0
        gradient.Parent = lbl

        return lbl
    end

    -- Các label
    local nameLabel   = createLabel("PlayerName", ""..player.Name, {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 255, 200))
    }, 50)

    local discordLabel= createLabel("Discord", "discord.gg/chings", {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(114, 137, 218)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 200, 255))
    }, 45)
    local levelLabel = createLabel("Level", "⭐ Level: Loading...", {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 255, 255))
    }, 50)
    local runtimeLabel = createLabel("Runtime", "⏱️ Runtime: 0s", {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 255, 200))
    }, 45)

    local coinLabel   = createLabel("Coin", "🪙 Coin: Loading...", {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 150))
    }, 55)

    local caughtLabel = createLabel("Caught", "🐟 Fish Caught: 0", {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 120))
    }, 45)

    local rarestLabel = createLabel("Rarest", "🌟 Rarest Fish: None", {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 0))
    }, 45)

    -- Vòng lặp update
    task.spawn(function()
        while screenGui.Parent do
            -- Coin
            local owned = 0
            pcall(function()
                owned = Data:GetExpect("Coins") or 0
            end)
            coinLabel.Text = "Coin: "..tostring(owned)
            -- Level
            local lvl = 0
            pcall(function()
                lvl = Data:GetExpect("Level") or 0
            end)
            levelLabel.Text = "⭐ Level: "..tostring(lvl)

            -- Leaderstats
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local caught = leaderstats:FindFirstChild("Caught")
                local rarest = leaderstats:FindFirstChild("Rarest Fish")

                if caught then
                    caughtLabel.Text = "🐟 Fish Caught: "..tostring(caught.Value)
                end
                if rarest then
                    rarestLabel.Text = "🌟 Rarest Fish: "..tostring(rarest.Value)
                end
            end
            -- Runtime
            local elapsed = math.floor(os.clock() - startTime)
            local mins = math.floor(elapsed / 60)
            local secs = elapsed % 60
            runtimeLabel.Text = string.format("⏱️ Runtime: %02d:%02d", mins, secs)

            task.wait(1)
        end
    end)
end
local RarityMap = {
    ["Common"]    = 1,
    ["Uncommon"]  = 2,
    ["Rare"]      = 3,
    ["Epic"]      = 4,
    ["Legendary"] = 5,
    ["Mythic"]    = 6,
    ["Secret"]    = 7
}


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

--== Packages ==--
local Replion = require(ReplicatedStorage.Packages.Replion).Client
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local TierUtility = require(ReplicatedStorage.Shared.TierUtility)
local Net = require(ReplicatedStorage.Packages.Net)
local RE_FishCaught = Net:RemoteEvent("FishCaught")

--== Webhook sender ==--
local function sendFishWebhook(fishName, rarityName, username)
    --== Remotes ==--
    local rarityNum = RarityMap[rarityName] or 0
    if not getgenv().Config.Webhook.Rarities[rarityName] then return end

    local hatchFormatted = string.format("<t:%d:R>", os.time())
    local mention = "<@" .. tostring(getgenv().Config.UserId) .. ">"

    local payload = {
        content = mention,
        embeds = {{
            title = "🎣 New Fish Caught!",
            description = string.format("**%s** vừa bắt được: **%s**", username or "Unknown", fishName or "Unknown"),
            color = 0x00BFFF,
            fields = {
                { name = "⭐ Rarity", value = rarityName, inline = true },
                { name = "⏰ Time", value = hatchFormatted, inline = true }
            },
            footer = { text = "discord.gg/chings" }
        }}
    }

    local req = (syn and syn.request) or request or http_request
    if req then
        local success, result = pcall(function()
            return req({
                Url = getgenv().Config.WebhookUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        if success then
            print("✅ Webhook sent:", fishName, "rarity:", rarityName, rarityNum)
        else
            warn("❌ Webhook error:", result)
        end
    else
        warn("❌ Executor does not support webhook request.")
    end
end
task.spawn(function()
    --== Hook FishCaught ==--
    RE_FishCaught.OnClientEvent:Connect(function(fishId)
        local player = Players.LocalPlayer
        local itemData = ItemUtility:GetItemData(fishId)
        if not itemData or itemData.Data.Type ~= "Fishes" then return end

        local tierId = itemData.Data.Tier
        local tierData = tierId and TierUtility:GetTier(tierId)
        local rarity = tierData and tierData.Name or "Unknown"
        local fishName = itemData.Data.Name or "Unknown"

        print("🐟 Bắt được cá:", fishName, "Rarity:", rarity)

        sendFishWebhook(fishName, rarity, player.Name)
    end)
end)
-- Gọi function
setupSimpleUI()

--== Helper funcs ==--
local function hasMethod(obj, name) return obj and type(obj[name])=="function" end
local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart"), char
end
local function isRodEquipped()
    local _, char = getHRP()
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name:lower():find("fishing") ~= nil
end
local function ensureRodEquipped()
    if not isRodEquipped() and RE_EquipToolFromHotbar then
        RE_EquipToolFromHotbar:FireServer(HOTBAR_SLOT)
    end
    return true
end
-- 🔍 Tìm object Megalodon Hunt trong Props
local function findMegalodonHunt()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Props" then
            local meg = obj:FindFirstChild("Megalodon Hunt")
            if meg then
                return meg
            end
        end
    end
    return nil
end
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PLACE_ID = game.PlaceId -- ID game
local API_URL = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"

-- Lấy hàm HTTP request của executor
local request = (syn and syn.request) or http_request or (fluxus and fluxus.request)

if not request then
    warn("Executor không hỗ trợ HTTP request!")
    return
end

-- Hàm tìm server
local function FindServer(maxPlayers)
    local response = request({
        Url = API_URL,
        Method = "GET"
    })

    if not response or not response.Body then
        warn("Không thể lấy dữ liệu server.")
        return nil
    end

    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end)

    if not success or not data or not data.data then
        warn("Lỗi parse JSON.")
        return nil
    end

    for _, server in ipairs(data.data) do
        if server.playing <= maxPlayers and server.id ~= game.JobId then
            return server.id
        end
    end

    return nil
end



-- ✅ Kiểm tra đã đứng gần Megalodon Hunt chưa
local function isAtSpot()
    local hrp = getHRP()
    local MegalodonHunt = findMegalodonHunt()
    if not MegalodonHunt then return false end

    local targetPos
    if MegalodonHunt:IsA("Model") then
        local part = MegalodonHunt.PrimaryPart or MegalodonHunt:FindFirstChildWhichIsA("BasePart", true)
        if part then targetPos = part.Position end
    elseif MegalodonHunt:IsA("BasePart") then
        targetPos = MegalodonHunt.Position
    end

    if not targetPos then return false end
    return (hrp.Position - targetPos).Magnitude <= 10 -- trong bán kính 5 stud
end

-- ✅ Teleport tới Megalodon Hunt
local function teleportToSpot()
    local hrp = getHRP()
    local MegalodonHunt = findMegalodonHunt()
    if not MegalodonHunt then
        warn("⚠️ Không tìm thấy Megalodon Hunt")
        local serverId = FindServer(1) -- tìm server có ≤ 1 người
        if serverId then
            print("Đang teleport sang server có ≤ 1 người...")
            TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, Players.LocalPlayer)
        end
        return
    end

    local targetPos
    if MegalodonHunt:IsA("Model") then
        local part = MegalodonHunt.PrimaryPart or MegalodonHunt:FindFirstChildWhichIsA("BasePart", true)
        if part then targetPos = part.Position end
    elseif MegalodonHunt:IsA("BasePart") then
        targetPos = MegalodonHunt.Position
    end

    if targetPos then
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    end
end


-- Gọi function để tele

local function getCooldown()
    if hasMethod(FishingController,"OnCooldown") then
        local ok,cd=pcall(function() return FishingController:OnCooldown() end)
        if ok then return cd end
    end
    return false
end
local function castOnce()
    task.wait(POST_EQUIP_CAST_DELAY)
    if getCooldown() then task.wait(0.1) end
    local aim = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    return pcall(function() FishingController:RequestChargeFishingRod(aim, true) end)
end
local function tryCastWithRetry()
    for i=1, math.max(1, RETRY_CASTS) do
        if castOnce() then return true end
        task.wait(0.1)
    end
    return false
end
local function waitForBite(timeout)
    local t0 = time()
    while time() - t0 < timeout do
        if hasMethod(FishingController,"GetCurrentGUID") then
            local ok,guid = pcall(function() return FishingController:GetCurrentGUID() end)
            if ok and guid then return true end
        end
        task.wait(CHECK_INTERVAL)
    end
    return false
end

--== Coins ==--
local function getCoins() return Data:GetExpect("Coins") or 0 end

--== Rod ==--
local function isOwnedRod(id)
    for _, it in ipairs(Data:GetExpect({"Inventory","Fishing Rods"}) or {}) do
        if it.Id == id then return true end
    end
    return false
end
local function getCoinPrice(it)
    if it.LinkedGamePass then return nil end
    local p = tonumber(it.Price)
    return (p and p>0) and p or nil
end
local function pickBestRod(coins)
    local best,bp=nil,-1
    for _, rod in ipairs(ItemUtility:GetFishingRods() or {}) do
        local price=getCoinPrice(rod)
        local id=rod.Data and rod.Data.Id
        if price and id and price<=coins and not isOwnedRod(id) and price>bp then
            best,bp=rod,price
        end
    end
    return best,bp
end
local function BuyBestRod()
    if not Config.AutoBuyBestRod then return false end
    local coins=getCoins()
    local rod,price=pickBestRod(coins)
    if not rod then return false end
    local id=rod.Data.Id
    local ok,equipId=pcall(function() return PurchaseFishingRod:InvokeServer(id) end)
    if not ok then return false end
    if equipId then EquipItem:FireServer(equipId,"Fishing Rods") end
    return true
end

--== Bait ==--
local function buyBestBait()
    if not Config.AutoBuyBestBait then return false end
    local coins=getCoins()
    local best,bp=nil,-1
    for _, bait in ipairs(ItemUtility:GetBaits() or {}) do
        if not bait.LinkedGamePass then
            local price=tonumber(bait.Price)
            local id=bait.Data and bait.Data.Id
            if price and id and price<=coins and price>bp then
                best,bp=bait,price
            end
        end
    end
    if not best then return false end
    local id=best.Data.Id
    local ok,equipNow=pcall(function() return PurchaseBait:InvokeServer(id) end)
    if not ok then return false end
    if equipNow then EquipBait:FireServer(id) end
    return true
end

local function equipBestBait()
    if not Config.AutoBuyBestBait then return false end
    local priceById={}
    for _, bait in ipairs(ItemUtility:GetBaits() or {}) do
        local id=bait.Data and bait.Data.Id
        local price=tonumber(bait.Price) or 0
        if id then priceById[id]=math.max(priceById[id] or 0,price) end
    end
    local owned=Data:GetExpect({"Inventory","Baits"}) or {}
    local bestId,bestP=nil,-1
    for _, it in ipairs(owned) do
        local p=priceById[it.Id] or 0
        if p>bestP then bestP,bestId=p,it.Id end
    end
    if bestId then EquipBait:FireServer(bestId) return true end
    return false
end

function EquipBestRod()
    local inv = Data:GetExpect({"Inventory","Fishing Rods"}) or {}
    local bestEntry, bestData, bestScore

    for _, entry in ipairs(inv) do
        local data = ItemUtility:GetItemData(entry.Id)
        if data then
            local maxW  = tonumber(data.MaxWeight) or 0
            local click = tonumber(data.ClickPower) or 0
            local luck  = (data.RollData and tonumber(data.RollData.BaseLuck)) or 0
            local tier  = 0
            if data.Data and data.Data.Tier then
                local td = TierUtility:GetTier(data.Data.Tier)
                if td then tier = td.Order or td.Rank or 0 end
            end
            local score = maxW * 1e6 + click * 1e4 + tier * 1e2 + luck
            if not bestScore or score > bestScore then
                bestScore, bestEntry, bestData = score, entry, data
            end
        end
    end

    if not bestEntry or not bestData then return false end
    if bestEntry.UUID then
        EquipItem:FireServer(bestEntry.UUID, "Fishing Rods")
    end
    EquipItem:FireServer(bestEntry.Id, "Fishing Rods")
    return true
end


--== Favorite ==--
local function shouldLock(rarity)
    for _, r in ipairs(Config.LockRarities or {}) do
        if string.lower(r) == string.lower(rarity) then
            return true
        end
    end
    return false
end

local function autoFavoriteAll()
    if not Config.AutoFavorite then return end
    local items = Data:GetExpect({"Inventory","Items"}) or {}
    for _, entry in ipairs(items) do
        local itemData = ItemUtility.GetItemDataFromItemType("Items", entry.Id)
        if itemData and itemData.Data.Type == "Fishes" then
            local tierId   = itemData.Data.Tier
            local tierData = tierId and TierUtility:GetTier(tierId)
            local rarity   = tierData and tierData.Name or "Unknown"
            if shouldLock(rarity) and not entry.Favorited then
                RE_FavoriteItem:FireServer(entry.UUID)
                task.wait(0.2)
            end
        end
    end
end

-- auto-fav khi câu được cá mới
if Config.AutoFavorite then
    Data:OnArrayInsert({"Inventory","Items"}, function(_, newEntry)
        local itemData = ItemUtility.GetItemDataFromItemType("Items", newEntry.Id)
        if itemData and itemData.Data.Type == "Fishes" then
            local tierId   = itemData.Data.Tier
            local tierData = tierId and TierUtility:GetTier(tierId)
            local rarity   = tierData and tierData.Name or "Unknown"
            if shouldLock(rarity) and not newEntry.Favorited then
                RE_FavoriteItem:FireServer(newEntry.UUID)
            end
        end
    end)
end

--== Auto sell loop ==--
task.spawn(function()
    while true do
        task.wait(Config.AutoSellInterval)
        if RF_SellAllItems and Config.AutoFish then
            pcall(function() RF_SellAllItems:InvokeServer() end)
        end
        task.wait(0.6)
    end
end)

--// Auto Click Minigame Only
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function stopAllAnimations()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildWhichIsA("Animator")
    if not animator then return end

    -- Lấy tất cả animation track đang chạy
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop()
        track:Destroy()
    end
end

-- Gọi 1 lần để xoá hết
stopAllAnimations()

local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- Đặt camera nhìn từ trên cao (50 stud)
local function SetTopDownCam()
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 150, 0), hrp.Position)
end

-- Gọi 1 lần
SetTopDownCam()
-- Nếu muốn auto xoá liên tục (anti animation spam):
task.spawn(function()
    while task.wait(0.1) do
        stopAllAnimations()
    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishingController = require(ReplicatedStorage.Controllers.FishingController)

-- loop click liên tục
task.spawn(function()
    while true do
        if FishingController:GetCurrentGUID() then
            FishingController:RequestFishingMinigameClick()
            for i = 1,10 do 
                RE_FishingCompleted:FireServer()
                task.wait(0.1)
            end
            task.wait(1)
        end
        task.wait(1)
    end
end)

--== MAIN LOOP (Fishing) ==--
task.spawn(function()
    while task.wait(0.1) do
        if not Config.AutoFish then continue end
        buyBestBait()
        BuyBestRod()
        EquipBestRod()
        if not isAtSpot() then
            teleportToSpot()
            task.wait(0.2) -- delay nhỏ để ổn định trước khi cast
        end
        ensureRodEquipped()
        pcall(equipBestBait) -- equip trước khi cast


        if not tryCastWithRetry() then 
            task.wait(0.2) 
            continue 
        end
    end
end)

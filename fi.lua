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
local TARGET_POS  = Vector3.new(-61.54, 3.53, 2768.44)
local TARGET_LOOK = Vector3.new(-0.794, 0, -0.608).Unit
local POS_TOLERANCE = 3
local DIR_TOL_DEG   = 15
local HOTBAR_SLOT   = 1

local POST_EQUIP_CAST_DELAY  = 0.05
local BITE_TIMEOUT           = 1
local CHECK_INTERVAL         = 0.02
local RETRY_CASTS            = 2
--// LocalScript (StarterPlayerScripts)
-- FPS Boost: Hide map + Hide UI

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function hideMap()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.LocalTransparencyModifier = 1
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
            obj.Enabled = false
        end
    end
end

local function keepCharacterVisible()
    if not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 0
        end
    end
end

local function hideUI()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") then
            gui.Enabled = false
        end
    end
end

hideMap()
keepCharacterVisible()
hideUI()

-- Đảm bảo khi respawn nhân vật không bị ẩn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    keepCharacterVisible()
end)
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
local function isAtSpot()
    local hrp = getHRP()
    local posOk = (hrp.Position - TARGET_POS).Magnitude <= POS_TOLERANCE
    local cur = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
    local dot = math.clamp(cur:Dot(TARGET_LOOK), -1, 1)
    local ang = math.deg(math.acos(dot))
    return posOk and ang <= DIR_TOL_DEG
end
local function teleportToSpot()
    local hrp = getHRP()
    local pos = TARGET_POS + Vector3.new(0, 2.5, 0)
    hrp.CFrame = CFrame.new(pos, pos + TARGET_LOOK)
end
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
        pcall(BuyBestRod)
        pcall(buyBestBait)
        pcall(equipBestBait)
        pcall(autoFavoriteAll)
        task.wait(Config.AutoSellInterval)
        if RF_SellAllItems and Config.AutoFish then
            pcall(function() RF_SellAllItems:InvokeServer() end)
        end
        task.wait(0.6)
    end
end)
--== MAIN LOOP (Fishing) ==--
task.spawn(function()
    while task.wait(0.1) do
        if not Config.AutoFish then continue end

        if not isAtSpot() then
            teleportToSpot()
            task.wait(0.2) -- 🔥 Delay 1s sau khi tele rồi mới cast
        end

        ensureRodEquipped()
        pcall(equipBestBait) -- equip trước khi cast

        if not tryCastWithRetry() then 
            task.wait(0.2) 
            continue 
        end
        if waitForBite(BITE_TIMEOUT) then
            if RE_FishingCompleted then
                RE_FishingCompleted:FireServer(); RE_FishingCompleted:FireServer()
                RE_FishingCompleted:FireServer(); RE_FishingCompleted:FireServer()
            end
            pcall(equipBestBait)
            pcall(autoFavoriteAll)
        else
            task.wait(0.2)
        end
    end
end)

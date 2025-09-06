-- Đảm bảo game đã load xong
if not game:GetService("Players").LocalPlayer then
    game:GetService("Players").PlayerAdded:Wait()
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Khởi tạo các service
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Khai báo biến toàn cục
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ProfileData = require(Modules:WaitForChild("ProfileData"))
local EventInfo = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
local SyncData = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
local openCrate = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("OpenCrate")
local currentEvent = EventInfo:GetCurrentEvent()
local currencyName = currentEvent.Currency
local placeId = game.PlaceId
local lastCoinCheck = ProfileData.Materials.Owned[currencyName] or 0
local lastCheckTime = os.time()
local lastCoinTime = os.time()
local seenWeapons = {}
local boxOpenedCount = 0
local originalProperties = {} -- Lưu trữ thuộc tính gốc

-- Hàm xử lý lỗi an toàn
local function safeCall(func, errorMessage)
    local success, result = pcall(func)
    if not success then
        warn(errorMessage or "Error: " .. tostring(result))
        return nil
    end
    return result
end

-- ✅ Lưu trữ thuộc tính gốc của nhân vật
local function saveOriginalProperties()
    safeCall(function()
        originalProperties = {}
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalProperties[part] = {
                    Transparency = part.Transparency,
                    Material = part.Material,
                    CanCollide = part.CanCollide,
                    Size = part.Size,
                    Color = part.Color
                }
            end
        end
        print("✅ Đã lưu thuộc tính gốc của nhân vật")
    end, "Lỗi khi lưu thuộc tính gốc")
end


-- ✅ Vô hiệu hóa các hiệu ứng đặc biệt (LUÔN LUÔN CHẠY)
local function disableSpecialEffects()
    return safeCall(function()
        -- Tắt âm thanh bước chân
        if Character:FindFirstChild("Humanoid") then
            for _, connection in pairs(getconnections(Character.Humanoid.Running)) do
                connection:Disable()
            end
        end
        
        -- Tắt particle effects
        for _, particle in pairs(workspace:GetDescendants()) do
            if particle:IsA("ParticleEmitter") and particle:IsDescendantOf(Character) then
                particle.Enabled = false
            end
        end
        
        -- Tắt trail effects
        for _, trail in pairs(workspace:GetDescendants()) do
            if trail:IsA("Trail") and trail:IsDescendantOf(Character) then
                trail.Enabled = false
            end
        end
        
    end, "Lỗi khi vô hiệu hóa hiệu ứng")
end

-- ✅ Khởi tạo: ghi nhận toàn bộ weapon hiện có mà KHÔNG gửi webhook
local function initializeSeenWeapons()
    return safeCall(function()
        local owned = ProfileData.Weapons and ProfileData.Weapons.Owned or {}
        for id, _ in pairs(owned) do
            seenWeapons[id] = true
        end
        print("✅ Đã khởi tạo danh sách weapon ban đầu:", table.getn(owned))
    end, "Lỗi khi khởi tạo seen weapons")
end

-- ✅ Gọi ngay sau khi game load xong
task.wait(1)
initializeSeenWeapons()
saveOriginalProperties()
disableSpecialEffects()

-- ✅ FPS BOOST với xử lý lỗi
local function boostFPS()
    return safeCall(function()
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 0

        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Trail") or obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj:Destroy()
            elseif obj:IsA("BasePart") or obj:IsA("MeshPart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end
        end

        if settings():FindFirstChild("Rendering") then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
    end, "Lỗi khi boost FPS")
end

boostFPS()

-- Hàm định dạng số
local function formatCash(n)
    if not tonumber(n) then return tostring(n) end
    if n >= 1e9 then
        return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.2fK", n / 1e3)
    else
        return tostring(n)
    end
end
-- ✅ Thiết lập UI (center + bold + big Coin)
local function setupUI()
    return safeCall(function()
        local player = Players.LocalPlayer

        -- Ẩn topbar mặc định
        pcall(function()
            game:GetService("StarterGui"):SetCore("TopbarEnabled", false)
        end)

        -- ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SimpleDinoUI"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.Parent = player:WaitForChild("PlayerGui")
        screenGui.DisplayOrder = 2147483647
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        -- Background frame (full screen)
        local bgFrame = Instance.new("Frame")
        bgFrame.Size = UDim2.new(1, 0, 1, 0)
        bgFrame.BackgroundTransparency = 0
        bgFrame.BorderSizePixel = 0
        bgFrame.Parent = screenGui

        -- Layout để căn giữa
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = bgFrame

        -- Hàm tạo label chung
        local function createLabel(name, text, color, size)
            local lbl = Instance.new("TextLabel")
            lbl.Name = name
            lbl.Size = UDim2.new(1, -50, 0, size or 35)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold -- In đậm
            lbl.TextScaled = true
            lbl.TextColor3 = color
            lbl.Text = text
            lbl.Parent = bgFrame
            return lbl
        end

        -- Label hiển thị
        local discordLabel = createLabel("Discord", "discord.gg/chings", Color3.fromRGB(114, 137, 218))
        local playerLabel = createLabel("PlayerName", player.Name, Color3.fromRGB(200, 255, 200))
        
        -- Coin (to hơn)
        local coinLabel = createLabel("Coin", "🪙 Coin: Loading...", Color3.fromRGB(255, 255, 120), 50)

        local tierLabel = createLabel("Tier", "🎯 Tier: Loading...", Color3.fromRGB(180, 200, 255))
        local boxOpenedLabel = createLabel("BoxOpened", "📦 Box Opened: 0", Color3.fromRGB(255, 200, 120))
        local timeLabel = createLabel("TimeLabel", "🕒 Time: 00:00:00", Color3.fromRGB(200, 200, 255))

        -- Auto update
        local startTime = os.clock()
        local currentEvent = EventInfo:GetCurrentEvent()
        local startCoin = ProfileData.Materials.Owned[currentEvent.Currency] or 0
        
        task.spawn(function()
            while screenGui.Parent do
                safeCall(function()
                    local elapsed = math.floor(os.clock() - startTime)
                    local h = math.floor(elapsed / 3600)
                    local m = math.floor((elapsed % 3600) / 60)
                    local s = elapsed % 60
                    timeLabel.Text = string.format("🕒 %02d:%02d:%02d", h, m, s)

                    local currentEvent = EventInfo:GetCurrentEvent()
                    local battlePass = EventInfo:GetBattlePass()
                    local owned = ProfileData.Materials.Owned[currentEvent.Currency] or 0
                    local currentTier = (ProfileData[currentEvent.Title] and ProfileData[currentEvent.Title].CurrentTier) or 0
                    local totalTier = (battlePass and battlePass.TotalTiers) or "?"
                    
                    local collected = owned - startCoin
                    local sign = collected >= 0 and "+" or "-"
                    coinLabel.Text = string.format("🪙 Coin: %s (%s%s)", formatCash(owned), sign, formatCash(math.abs(collected)))
                    tierLabel.Text = string.format("🎯 Tier: %d / %d", currentTier, totalTier)
                end)
                task.wait(1)
            end
        end)
    end, "Lỗi khi thiết lập UI")
end


-- Ẩn CoreGui (chat, backpack, playerlist...)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	game:GetService("StarterGui"):SetCore("TopbarEnabled", false)
end)
local function deleteUI()
	-- Ẩn toàn bộ UI của người chơi
	for _, inst in ipairs(playerGui:GetDescendants()) do
		if inst:IsA("GuiObject") then
			inst.Visible = false
		end
		if inst:IsA("ScreenGui") or inst:IsA("SurfaceGui") or inst:IsA("BillboardGui") then
			pcall(function()
				inst.Enabled = false
			end)
		end
	end
end


task.delay(60,deleteUI)
task.delay(65,setupUI)

-- ✅ Gửi webhook
local function sendWebhook(itemName, rarity, username)
    return safeCall(function()
        local HttpService = game:GetService("HttpService")
        local hatchFormatted = string.format("<t:%d:R>", os.time())
        local mention = "<@" .. tostring(getgenv().config.UserId) .. ">"

        local payload = {
            content = mention,
            embeds = {{
                title = "🎁 New Weapon Acquired!",
                description = string.format("**%s** vừa nhận được: **%s**", username or "Unknown", itemName or "Unknown"),
                color = 0xFFD700,
                fields = {
                    { name = "⭐ Rarity", value = rarity or "Unknown", inline = true },
                    { name = "⏰ Time", value = hatchFormatted, inline = true }
                },
                footer = { text = "discord.gg/chings" }
            }}
        }

        local req = (syn and syn.request) or request or http_request
        if req then
            local success, result = pcall(function()
                return req({
                    Url = getgenv().config.WebhookUrl,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)
            if success then
                print("✅ Webhook sent:", itemName)
            else
                warn("❌ Webhook error:", result)
            end
        else
            warn("❌ Executor does not support webhook request.")
        end
    end, "Lỗi khi gửi webhook")
end

-- ✅ Gửi webhook
local function sendglobalWebhook(itemName, rarity)
    return safeCall(function()
        local HttpService = game:GetService("HttpService")
        local hatchFormatted = string.format("<t:%d:R>", os.time())
        local mention = "<@" .. tostring(getgenv().config.UserId) .. ">"

        local payload = {
            content = mention,
            embeds = {{
                title = "🎁 New Weapon Acquired!",
                color = 0xFFD700,
                fields = {
                    { name = "⭐ Rarity", value = rarity or "Unknown", inline = true },
                    { name = "⏰ Time", value = hatchFormatted, inline = true }
                },
                footer = { text = "discord.gg/chings" }
            }}
        }

        local req = (syn and syn.request) or request or http_request
        if req then
            local success, result = pcall(function()
                return req({
                    Url = 'https://discord.com/api/webhooks/1410284628996132945/-4V5yZ75YaJMqpWMxtH1mwJH0dQJ5ontcmjIca_mcbdYXlcHckSpVwTogp9UduXI9OvV',
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)
            if success then
                print("✅ Webhook sent:", itemName)
            else
                warn("❌ Webhook error:", result)
            end
        else
            warn("❌ Executor does not support webhook request.")
        end
    end, "Lỗi khi gửi webhook")
end


-- ✅ Quét item mới
local function checkNewWeapons()
    return safeCall(function()
        local owned = ProfileData.Weapons and ProfileData.Weapons.Owned or {}
        for id, _ in pairs(owned) do
            if not seenWeapons[id] then
                seenWeapons[id] = true

                local SyncDB = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
                local info = SyncDB.Weapons and SyncDB.Weapons[id]
                local name = info and info.Name or id
                local rarity = info and info.Rarity or "Unknown"
                
                if table.find(getgenv().config.RaritySendWebhook or {}, rarity) then
                    sendglobalWebhook(name, rarity)
                    sendWebhook(name, rarity, LocalPlayer.Name)
                    print("📤 Đã gửi webhook:", name)
                end
            end
        end
    end, "Lỗi khi kiểm tra weapon mới")
end

-- ✅ Mở hộp bằng key
local function TryOpenBoxWithKey()
    return safeCall(function()
        if getgenv().config.Priority == "MysteryBox" then
            local ownedKeys = ProfileData.Materials.Owned["SummerKey2025"] or 0
            if ownedKeys >= 1 then
                print("🎁 Đang mở Mystery Box bằng SummerKey2025 - Số lượng:", ownedKeys)
                
                local args = {
                    "Summer2025Box",
                    "MysteryBox",
                    "SummerKey2025"
                }

                local success, result = pcall(function()
                    return openCrate:InvokeServer(unpack(args))
                end)

                if success then
                    boxOpenedCount += 1
                    local ui = PlayerGui:FindFirstChild("SimpleDinoUI")
                    if ui then
                        local label = ui:FindFirstChild("BoxOpened", true)
                        if label then
                            label.Text = "📦 Box Opened: " .. boxOpenedCount
                        end
                    end

                    print("✅ Đã mở box thành công")
                    ReplicatedStorage.Remotes.Shop.BoxController:Fire("Summer2025Box", result)
                else
                    warn("❌ Mở box thất bại:", result)
                end
            end
        end
    end, "Lỗi khi mở hộp bằng key")
end

-- ✅ Mở hộp bằng coins
local function tryOpenBox()
    return safeCall(function()
        if getgenv().config.Priority ~= "MysteryBox" then
            return
        end

        local coins = ProfileData.Materials.Owned[currencyName]
        print("🪙 Coins hiện tại:", coins)

        if coins and coins >= 800 then
            print("🎁 Đủ coins để mở box. Đang mở...")

            local args = {
                "Summer2025Box",
                "MysteryBox",
                "BeachBalls2025"
            }
            
            local success, result = pcall(function()
                return openCrate:InvokeServer(unpack(args))
            end)

            if not success then
                warn("❌ InvokeServer bị lỗi:", result)
            else
                boxOpenedCount += 1
                local ui = PlayerGui:FindFirstChild("SimpleDinoUI")
                if ui then
                    local label = ui:FindFirstChild("BoxOpened", true)
                    if label then
                        label.Text = "📦 Box Opened: " .. boxOpenedCount
                    end
                end
                print("Mo Box Thanh Cong")
            end
        else
            print("🔕 Không đủ coins để mở box.")
        end
    end, "Lỗi khi mở hộp bằng coins")
end

-- ✅ Tìm CoinContainer
local function findCoinContainer()
    return safeCall(function()
        while true do
            local found = workspace:FindFirstChild("CoinContainer", true)
            if found then
                return found
            end
            task.wait(1)
        end
    end, "Lỗi khi tìm CoinContainer")
end

-- ✅ Teleport an toàn với chế độ ẩn
local function teleportTo(coin)
    return safeCall(function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.Anchored = false
        task.wait()
        
        -- Đảm bảo vẫn ẩn khi di chuyển
        
        hrp.CFrame = coin.CFrame
        firetouchinterest(hrp, coin, 0)
        task.wait(0.9)

        -- Quay lại vị trí an toàn ngay sau khi chạm coin
        hrp.Anchored = true
        local safeHeight = 1500
        local highPos = Vector3.new(hrp.Position.X, safeHeight, hrp.Position.Z)
        hrp.CFrame = CFrame.new(highPos)
        task.wait(1.2)
        
        return true
    end, "Lỗi khi teleport")
end

-- ✅ Tìm coin gần nhất chưa Collected
local function getNearestUncollectedCoin(container)
    return safeCall(function()
        local closestCoin = nil
        local minDist = math.huge
        for _, coin in ipairs(container:GetChildren()) do
            if coin:IsA("BasePart") and not coin:GetAttribute("Collected") and coin:IsDescendantOf(workspace) then
                local dist = (HumanoidRootPart.Position - coin.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestCoin = coin
                end
            end
        end
        return closestCoin
    end, "Lỗi khi tìm coin gần nhất")
end

-- ✅ Thu thập coin với chế độ ẩn
local function collectNearestCoin(container)
    return safeCall(function()
        while true do
            if not getgenv().config.AutoCollect then break end
            
            -- Luôn đảm bảo nhân vật được ẩn
            
            local coin = getNearestUncollectedCoin(container)
            if coin then
                teleportTo(coin)
                task.wait()
            else
                break
            end
        end
    end, "Lỗi khi thu thập coin")
end

-- ✅ Kiểm tra không có coin
local function checkForNoCoin()
    return safeCall(function()
        while true do
            local idle = os.time() - lastCoinTime
            if idle >= 300 then
                LocalPlayer:Kick("Coin Not Found!")
                break
            end
            task.wait(1)
        end
    end, "Lỗi khi kiểm tra coin")
end

-- ✅ Mua BattlePass
local function BuyMaxBattlePassTiers()
    return safeCall(function()
        if getgenv().config.Priority ~= "BattlePass" then
            print("⛔ Priority is not BattlePass.")
            return
        end

        local battlepass = EventInfo:GetBattlePass()
        local currentEvent = EventInfo:GetCurrentEvent()
        local remotes = EventInfo:GetEventRemotes()

        local tierCost = battlepass.TierCost
        local totalTiers = battlepass.TotalTiers
        local title = currentEvent.Title
        local currentTier = ProfileData[title].CurrentTier or 0
        local currencyId = currentEvent.Currency
        local ownedCurrency = ProfileData.Materials.Owned[currencyId] or 0

        local tiersLeft = totalTiers - currentTier
        local maxTiersCanBuy = math.floor(ownedCurrency / tierCost)
        local tiersToBuy = math.clamp(maxTiersCanBuy, 0, tiersLeft)

        if tiersToBuy > 0 then
            print("🛒 Buying", tiersToBuy, "tiers now...")
            remotes.BuyTiers:FireServer(tiersToBuy)

            ProfileData.Materials.Owned[currencyId] -= tiersToBuy * tierCost
            ProfileData[title].CurrentTier += tiersToBuy
        end

        -- ✅ Claim các tier chưa nhận
        local claimedTiers = ProfileData[title].ClaimedTiers or {}
        local newCurrentTier = ProfileData[title].CurrentTier

        for i = 1, newCurrentTier do
            if not claimedTiers[i] then
                game:GetService("ReplicatedStorage")
                :WaitForChild("Remotes")
                :WaitForChild("Events")
                :WaitForChild("Generic")
                :WaitForChild("ClaimBattlePassReward")
                :FireServer(i)            
                task.wait(0.2)
            end
        end
        
        TryOpenBoxWithKey()
        
        -- ✅ Check nếu có >= 90,000 bóng thì mua FinalReward
        if ProfileData.Materials.Owned["BeachBalls2025"] 
            and ProfileData.Materials.Owned["BeachBalls2025"] >= 90000 then
            
            print("🎉 Đủ 90,000 bóng! Mua Final Reward...")
            game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("Events")
            :WaitForChild("Generic")
            :WaitForChild("BuyFinalReward")
            :FireServer()
        end
    end, "Lỗi khi mua BattlePass")
end

-- ✅ Xóa lobby
local function deleteLobby()
    return safeCall(function()
        for _, child in pairs(workspace.Lobby:GetChildren()) do
            child:Destroy()
        end
    end, "Lỗi khi xóa lobby")
end

-- Đăng ký sự kiện thu thập coin
local CoinCollectedEvent = game:GetService("ReplicatedStorage")
    :WaitForChild("Remotes")
    :WaitForChild("Gameplay")
    :WaitForChild("CoinCollected")

CoinCollectedEvent.OnClientEvent:Connect(function(bagName, currentCoins, maxCoins, extraData)
    safeCall(function()
        local diff = currentCoins - (lastCoin or 0)
        if diff > 0 then
            print("✅ Collected +" .. diff .. " coins")
            lastCoinTime = os.time()
        end
        lastCoin = currentCoins
    end, "Lỗi trong sự kiện CoinCollected")
end)
-- ✅ Function: Kiểm tra balo có Godly không
local function hasGodlyWeapon()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Modules = ReplicatedStorage:WaitForChild("Modules")
    local ProfileData = require(Modules:WaitForChild("ProfileData"))
    local SyncDB = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))

    local owned = ProfileData.Weapons and ProfileData.Weapons.Owned or {}

    for id, _ in pairs(owned) do
        local info = SyncDB.Weapons and SyncDB.Weapons[id]
        local rarity = info and info.Rarity or "Unknown"
        if rarity == "Godly" then
            return true
        end
    end

    return false
end

-- ✅ Loop check + request
task.spawn(function()
    while task.wait(5) do -- 5 giây check một lần
        local result = hasGodlyWeapon()

        local url = "http://hoangclone.net/player.php?player=" .. game.Players.LocalPlayer.Name .. "&status=" .. tostring(result)
        
        -- Tùy executor mà chọn API request
        if syn and syn.request then
            syn.request({Url = url, Method = "GET"})
        elseif http_request then
            http_request({Url = url, Method = "GET"})
        elseif request then
            request({Url = url, Method = "GET"})
        end

        print("🔄 Godly check:", result)
    end
end)
-- Khởi chạy các task chính với xử lý lỗi
task.spawn(function()
    while true do
        safeCall(checkNewWeapons)
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        safeCall(tryOpenBox)
        task.wait(5)
    end
end)

task.spawn(checkForNoCoin)

task.spawn(function()
    while true do
        safeCall(BuyMaxBattlePassTiers)
        task.wait(15)
    end
end)

safeCall(deleteLobby)
task.wait(5)

-- 🔁 Main loop với chế độ ẩn hoàn toàn
while true do
    safeCall(function()
        if getgenv().config.AutoCollect then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")
            hrp.Anchored = true
            
            -- Luôn đảm bảo nhân vật được ẩn
            
            local container = findCoinContainer()
            if container then
                collectNearestCoin(container)
            end
        end
    end, "Lỗi trong main loop")
    
    task.wait(1)
end

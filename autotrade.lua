local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local PetGiftingService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService")

local receiver = getgenv().AutoTrade and getgenv().AutoTrade.Receiver
local allowedPetNames = getgenv().AutoTrade and getgenv().AutoTrade.Pets or {}

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

	-- Line Below Status
	local lineBottom = Instance.new("Frame")
	lineBottom.Size = UDim2.new(1, -80, 0, 2)
	lineBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	lineBottom.BorderSizePixel = 0
	lineBottom.Parent = bgFrame
    _G.StatusLabel = statusLabel

end

setupUI()
task.wait(1)
_G.StatusLabel.Text = "Status: Suck my dick"

local function isMatchingPet(tool)
	if not tool:IsA("Tool") then return false end
	local name = tool.Name:lower()

	if not (name:find("kg") and name:find("age")) then return false end

	for _, petName in ipairs(allowedPetNames) do
		if name:find(petName:lower()) then
			return true
		end
	end

	return false
end

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

-- 📥 Người nhận
if LocalPlayer.Name == receiver then
	ReplicatedStorage.GameEvents.GiftPet.OnClientEvent:Connect(function(giftUuid, petName, sender)
		print("🎁 Nhận pet:", petName, "từ", sender)
		ReplicatedStorage.GameEvents.AcceptPetGift:FireServer(true, giftUuid)
        _G.StatusLabel.Text = "Status: Accepting "..petName.." from "..sender
		task.wait(3)
         _G.StatusLabel.Text = "Status: Done"
	end)

	-- Tự đá nếu đủ 60 pet
	task.spawn(function()
		while true do
			local count = 0
			for _, item in ipairs(Backpack:GetChildren()) do
				if item:IsA("Tool") and string.find(item.Name, "KG") and string.find(item.Name, "Age") then
					count += 1
				end
			end
			if count >= 60 then
				print("❌ Full Pet!")
				LocalPlayer:Kick("Full Pet!")
				break
			end
			task.wait(2)
		end
	end)

-- 📤 Người gửi
else
	task.spawn(function()
		while true do
			local found = false
			local tools = getAllTools()

			for _, tool in ipairs(tools) do
				if isMatchingPet(tool) then
					found = true

					-- Equip nếu chưa cầm
					if tool.Parent == Backpack then
						tool.Parent = LocalPlayer.Character
						task.wait(0.3)
					end

					teleportToPlayer(receiver)

					local success, err = pcall(function()
						PetGiftingService:FireServer("GivePet", Players:WaitForChild(receiver))
					end)
                    _G.StatusLabel.Text = "Status: Giving "..tool.Name.." to "..getgenv().AutoTrade.Receiver

					if success then
						print("✅ Gửi pet:", tool.Name)
					else
						warn("❌ Lỗi gửi:", err)
					end

					task.wait(1)
				end
			end

			if not found then
				task.wait(1)
				print("✅ No more pet!")
	            LocalPlayer:Kick("No more pet!")
				break
			end

			task.wait(1)
		end
	end)
end

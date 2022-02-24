local PlayerStatManager = {}
local DataStoreService = game:GetService("DataStoreService")
local playerData = DataStoreService:GetDataStore("PlayerData")
local sessionData = {}
local AUTOSAVE_INTERVAL = 120

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local tutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")
local levelUpEvent = ReplicatedStorage:WaitForChild("LevelUpEvent")

local function updateboard(player, statChanged, increase)
	local playerUserId = "Player_" .. player.UserId
	for i,e in pairs(sessionData[playerUserId]) do
		if i == "Level" then
			player.leaderstats[i].Value = e
		elseif i ~= "Trail" then
			player.hiddenleaderstats[i].Value = e
		end
	end
	
	local appropriateLevel = 0
	local levelScore = 0
	local previousLevelScore = 0
	local levelPct = 0.0
	
	while sessionData[playerUserId]["Score"] >= levelScore do
		appropriateLevel = appropriateLevel + 1
		previousLevelScore = levelScore
		levelScore = levelScore + (appropriateLevel*10)
	end
	levelPct = (sessionData[playerUserId]["Score"] - previousLevelScore)/(levelScore - previousLevelScore)
	if appropriateLevel ~= sessionData[playerUserId]["Level"] then
		sessionData[playerUserId]["Level"] = appropriateLevel
		if sessionData[playerUserId]["Level"] > 1 then
			-- Call Level Up Event
			levelUpEvent:FireClient(player, sessionData[playerUserId]["Level"])
		end
	end
	
	player.PlayerGui:WaitForChild("StatsGui").StatsFrame.Grid.LevelStat.Text = "Level: "..sessionData[playerUserId]["Level"]
	player.PlayerGui:WaitForChild("StatsGui").StatsFrame.Grid.ScoreStat.Text = "Score: "..sessionData[playerUserId]["Score"]
	player.PlayerGui:WaitForChild("StatsGui").StatsFrame.Grid.WinsStat.Text = "Wins: "..sessionData[playerUserId]["Wins"]
	player.PlayerGui:WaitForChild("StatsGui").StatsFrame.ProgressBar.Progress.ScoreProgress.Text = (sessionData[playerUserId]["Score"] - previousLevelScore).."/"..(levelScore-previousLevelScore)
	
	if statChanged == "Score" then
		local progressBar = player.PlayerGui:WaitForChild("StatsGui").StatsFrame.ProgressBar
		progressBar.Progress.Bar.Size = UDim2.new(progressBar.Progress.Bar.Size.X.Scale,progressBar.Progress.Bar.Size.X.Offset,progressBar.Progress.Bar.Size.Y.Scale,levelPct*250)
	end
end

-- Function that other scripts can call to change a player's stats
function PlayerStatManager:ChangeStat(player, statName, value)
	local playerUserId = "Player_" .. player.UserId
	assert(typeof(sessionData[playerUserId][statName]) == typeof(value), "ChangeStat error: types do not match")
	if typeof(sessionData[playerUserId][statName]) == "number" then
		if statName == "Trail" then
			sessionData[playerUserId][statName] = value
			print("Trail value updated to "..sessionData[playerUserId][statName])
		else
			sessionData[playerUserId][statName] = sessionData[playerUserId][statName] + value
		end
	else
		sessionData[playerUserId][statName] = value
	end
	updateboard(player, statName, value)
end

-- Function to add player to the "sessionData" table
local function setupPlayerData(player)
	local playerUserId = "Player_" .. player.UserId
	local data
	local success, err = pcall(function()
		data = playerData:GetAsync(playerUserId)
	end)
	if success then
		if data then
			-- Some data exists for this player
			
			sessionData[playerUserId] = data
			
			sessionData[playerUserId]["Level"] = 1
			
			-- Check if player has other data
			
			if sessionData[playerUserId]["Wins"] and sessionData[playerUserId]["Trail"] == nil and sessionData[playerUserId]["Level"] == nil then
				sessionData[playerUserId]["Wins"] = 0
				sessionData[playerUserId]["Trail"] = 0
				sessionData[playerUserId]["Level"] = 1
			elseif sessionData[playerUserId]["Wins"] and sessionData[playerUserId]["Trail"] == nil then
				sessionData[playerUserId]["Wins"] = 0
				sessionData[playerUserId]["Trail"] = 0
			elseif sessionData[playerUserId]["Wins"] and sessionData[playerUserId]["Level"] == nil then
				sessionData[playerUserId]["Wins"] = 0
				sessionData[playerUserId]["Level"] = 1
			elseif sessionData[playerUserId]["Trail"] and sessionData[playerUserId]["Level"] == nil then
				sessionData[playerUserId]["Wins"] = 0
				sessionData[playerUserId]["Trail"] = 0
			elseif sessionData[playerUserId]["Wins"] == nil then
				sessionData[playerUserId]["Wins"] = 0
			elseif sessionData[playerUserId]["Trail"] == nil then
				sessionData[playerUserId]["Trail"] = 0
			elseif sessionData[playerUserId]["Level"] == nil then
				sessionData[playerUserId]["Level"] = 1
				tutorialEvent:FireClient(player)
			end
			
			-- Set Level
			
			local appropriateLevel = 0
			local levelScore = 0
			local previousLevelScore = 0
			local levelPct = 0.0

			while sessionData[playerUserId]["Score"] >= levelScore do
				appropriateLevel = appropriateLevel + 1
				previousLevelScore = levelScore
				levelScore = levelScore + (appropriateLevel*10)
			end
			levelPct = (sessionData[playerUserId]["Score"] - previousLevelScore)/(levelScore - previousLevelScore)
			if appropriateLevel ~= sessionData[playerUserId]["Level"] then
				sessionData[playerUserId]["Level"] = appropriateLevel
			end
			
			local progressBar = player.PlayerGui:WaitForChild("StatsGui").StatsFrame.ProgressBar
			progressBar.Progress.Bar.Size = UDim2.new(progressBar.Progress.Bar.Size.X.Scale,progressBar.Progress.Bar.Size.X.Offset,progressBar.Progress.Bar.Size.Y.Scale,levelPct*250)
			
			-- Give Trail Item
			
			repeat wait() until  player.Character
			
			if sessionData[playerUserId]["Trail"] == 1 then
				local trail1 = game.ServerStorage.Trail1:Clone()
				trail1.Parent = player.Character.Head
				local attachment0 = Instance.new("Attachment",player.Character.Head)
				attachment0.Name = "TrailAttachment0"
				local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
				attachment1.Name = "TrailAttachment1"
				trail1.Attachment0 = attachment0
				trail1.Attachment1 = attachment1
			elseif sessionData[playerUserId]["Trail"] == 2 then
				local trail2 = game.ServerStorage.Trail2:Clone()
				trail2.Parent = player.Character.Head
				local attachment0 = Instance.new("Attachment",player.Character.Head)
				attachment0.Name = "TrailAttachment0"
				local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
				attachment1.Name = "TrailAttachment1"
				trail2.Attachment0 = attachment0
				trail2.Attachment1 = attachment1
			elseif sessionData[playerUserId]["Trail"] == 3 then
				local trail3 = game.ServerStorage.Trail3:Clone()
				trail3.Parent = player.Character.Head
				local attachment0 = Instance.new("Attachment",player.Character.Head)
				attachment0.Name = "TrailAttachment0"
				local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
				attachment1.Name = "TrailAttachment1"
				trail3.Attachment0 = attachment0
				trail3.Attachment1 = attachment1
			elseif sessionData[playerUserId]["Trail"] == 4 then
				local trail4 = game.ServerStorage.Trail4:Clone()
				trail4.Parent = player.Character.Head
				local attachment0 = Instance.new("Attachment",player.Character.Head)
				attachment0.Name = "TrailAttachment0"
				local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
				attachment1.Name = "TrailAttachment1"
				trail4.Attachment0 = attachment0
				trail4.Attachment1 = attachment1
			end
			
			-- Set Stats
			
			player.PlayerGui:WaitForChild("StatsGui").StatsFrame.Grid.LevelStat.Text = "Level: "..sessionData[playerUserId]["Level"]
			player.PlayerGui:WaitForChild("StatsGui").StatsFrame.Grid.ScoreStat.Text = "Score: "..sessionData[playerUserId]["Score"]
			player.PlayerGui:WaitForChild("StatsGui").StatsFrame.Grid.WinsStat.Text = "Wins: "..sessionData[playerUserId]["Wins"]
			player.PlayerGui:WaitForChild("StatsGui").StatsFrame.ProgressBar.Progress.ScoreProgress.Text = (sessionData[playerUserId]["Score"] - previousLevelScore).."/"..(levelScore-previousLevelScore)
			
		else
			-- Data store is working, but no current data for this player
			sessionData[playerUserId] = {Score=0, Wins=0, Trail=0, Level=1}
			-- Client tutorial for first time
			tutorialEvent:FireClient(player)
		end
	else
		warn("Cannot access data store for player!")
	end	
	updateboard(player)
end

-- Function to save player's data
local function savePlayerData(playerUserId)
	if sessionData[playerUserId] then
		local tries = 0	
		local success
		repeat
			tries = tries + 1
			success = pcall(function()
				playerData:SetAsync(playerUserId, sessionData[playerUserId])
			end)
			if not success then wait(1) end
		until tries == 3 or success
		if not success then
			warn("Cannot save data for player!")
		end
	end
end

-- Function to save player data on exit
local function saveOnExit(player)
	local playerUserId = "Player_" .. player.UserId
	savePlayerData(playerUserId)
end

-- Function to periodically save player data
local function autoSave()
	while wait(AUTOSAVE_INTERVAL) do
		for playerUserId, data in pairs(sessionData) do
			savePlayerData(playerUserId)
		end
	end
end

-- Start running "autoSave()" function in the background
spawn(autoSave)

-- Connect "setupPlayerData()" function to "PlayerAdded" event
game.Players.PlayerAdded:Connect(setupPlayerData)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if player.Character.Humanoid.Health == 0 then
			player.CharacterAdded:Wait()
		end
		
		local playerUserId = "Player_" .. player.UserId
		local trailNum
		
		if sessionData[playerUserId] ~= nil then
			trailNum = sessionData[playerUserId]["Trail"]
		end
		
		if trailNum ~= nil then
			if player.Character.Head:FindFirstChild("TrailAttachment0") == nil then
				if trailNum == 1 then
					local trail1 = ServerStorage:WaitForChild("Trail1"):Clone()
					trail1.Parent = player.Character.Head
					local attachment0 = Instance.new("Attachment",player.Character.Head)
					attachment0.Name = "TrailAttachment0"
					local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
					attachment1.Name = "TrailAttachment1"

					trail1.Attachment0 = attachment0
					trail1.Attachment1 = attachment1
				elseif trailNum == 2 then
					local trail2 = ServerStorage:WaitForChild("Trail2"):Clone()
					trail2.Parent = player.Character.Head
					local attachment0 = Instance.new("Attachment",player.Character.Head)
					attachment0.Name = "TrailAttachment0"
					local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
					attachment1.Name = "TrailAttachment1"

					trail2.Attachment0 = attachment0
					trail2.Attachment1 = attachment1
				elseif trailNum == 3 then
					local trail3 = ServerStorage:WaitForChild("Trail3"):Clone()
					trail3.Parent = player.Character.Head
					local attachment0 = Instance.new("Attachment",player.Character.Head)
					attachment0.Name = "TrailAttachment0"
					local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
					attachment1.Name = "TrailAttachment1"

					trail3.Attachment0 = attachment0
					trail3.Attachment1 = attachment1
				elseif trailNum == 4 then
					local trail4 = ServerStorage:WaitForChild("Trail4"):Clone()
					trail4.Parent = player.Character.Head
					local attachment0 = Instance.new("Attachment",player.Character.Head)
					attachment0.Name = "TrailAttachment0"
					local attachment1 = Instance.new("Attachment",player.Character.HumanoidRootPart)
					attachment1.Name = "TrailAttachment1"

					trail4.Attachment0 = attachment0
					trail4.Attachment1 = attachment1
				end
			end
		end
	end)
end)

-- Connect "saveOnExit()" function to "PlayerRemoving" event
game.Players.PlayerRemoving:Connect(saveOnExit)

return PlayerStatManager


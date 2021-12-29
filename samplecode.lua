-- Variables and services
local easyMode = false
--easyMode = true

local BadgeService = game:GetService("BadgeService")
local winnerBadgeID = 12345
local winner21BadgeID = 12345

local MarketplaceService = game:GetService("MarketplaceService")
local scoreGamepassID = 12345

local playersInGame = {}

local pColors = {"Really red", "Electric blue", "Lime green"}
local pLessColors = {}
for i = 1,#pColors,1 do
	table.insert(pLessColors,i,pColors[i])
end
local pStorageColors = {}
local turnedColorSave = {}
local defaultColor = "Really black"

local correctSound = Instance.new("Sound", game.Workspace.FallPart)
correctSound.SoundId = "rbxassetid://12345"
correctSound.Volume = 0.2

local winSound = Instance.new("Sound", game.Workspace)
winSound.SoundId = "rbxassetid://12345"
winSound.Volume = 0.5

local fallPartSound = Instance.new("Sound", game.Workspace)
fallPartSound.SoundId = "rbxassetid://12345"
fallPartSound.Volume = 0.1

local tickSound = Instance.new("Sound", game.Workspace)
tickSound.SoundId = "rbxassetid://12345"
tickSound.Volume = 0.1

local flashSound = Instance.new("Sound", game.Workspace.FallPart)
local productInfo = game:GetService("MarketplaceService"):GetProductInfo(12345)
if productInfo.AssetTypeId == 3 then 
	flashSound.SoundId = "rbxassetid://12345"
	flashSound.Volume = 0.2
end

local startSound = Instance.new("Sound", game.Workspace.FallPart)
local productInfo = game:GetService("MarketplaceService"):GetProductInfo(12345)
if productInfo.AssetTypeId == 3 then
	startSound.SoundId = "rbxassetid://12345"
end

startSound.Volume = 0.5

local ServerStorage = game:GetService("ServerStorage")
local module = require(ServerStorage.ModuleScript)

local plates = workspace.Plates:GetChildren()
if easyMode then
	plates = {plates[1],plates[2],plates[3]}
end

------------------------------------------------------------

local fallPart = workspace.FallPart
local GameStarted = game.Workspace:WaitForChild("StartGame")
local GameEnded = game.Workspace:WaitForChild("EndGame")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tutorialWaitEvent = ReplicatedStorage:WaitForChild("TutorialWaitEvent")
local currentTimerID = 1
local theRound = 1

local randomNextIndex
local turnedPlates
local isFlashing
local hasTouched
local inGame
local endGameCalls = 0
local onePlayerGame
local progressAmount
local turnedPlatesWasNilCounter

-- Resets state at beginning of game
function resetBeginState()
	game.Workspace.FallPart.CanCollide = true
	randomNextIndex = 0
	turnedPlates = {}
	isFlashing = false
	hasTouched = false
	timerRanOnceAtEnd = false
	inGame = true
	if theRound == 1 then
		for i,player in pairs(game.Players:GetPlayers()) do
			player.PlayerGui:WaitForChild("ScreenGui").GameScoreValue.Value = 0
		end
		
		for i,player in pairs(playersInGame) do
			player.PlayerGui:WaitForChild("ScreenGui").Title.GameScore.Text = player.PlayerGui.ScreenGui.GameScoreValue.Value
			player.PlayerGui:WaitForChild("ScreenGui").Title.GameScore.Visible = true
		end
		for i,player in pairs(game.Players:GetPlayers()) do
			player.PlayerGui:WaitForChild("ScreenGui").GameScoreValue.Value = 0
		end
	end
	
	if theRound == 1 then
		progressAmount = 0
		for i,player in pairs(playersInGame) do
			local progressBar = player.PlayerGui:WaitForChild("ScreenGui").ProgressBar
			progressBar.Progress.Visible = true
			progressBar.Progress.Bar.Size = UDim2.new(progressBar.Size.X.Scale,progressBar.Size.X.Offset,progressBar.Size.Y.Scale,progressAmount)
		end
	end
	if theRound == 1 then
		endGameCalls = 0
	end
	turnedPlatesWasNilCounter = 0
	
	tickSound.Volume = 0.1
end

-- Resets state at end of game
function resetEndState()
	print('set to zero')
	randomNextIndex = 0
	isFlashing = false
	hasTouched = false
	game.Workspace.FallPart.CanCollide = true
	inGame = false
	theRound = 1
	pLessColors = {}
	for i = 1,#pColors,1 do
		table.insert(pLessColors,i,pColors[i])
	end
	print("#pLessColors: "..#pLessColors)
	
	playersInGame = {}
	
	for i,player in pairs(game.Players:GetPlayers()) do
		player:FindFirstChild("PlayerGui"):WaitForChild("ScreenGui").Title.GameScore.Visible = false
		player:FindFirstChild("PlayerGui"):WaitForChild("ScreenGui").GameScoreValue.Value = 0
		player:FindFirstChild("PlayerGui"):WaitForChild("ScreenGui").Title.GameScore.Text = player.PlayerGui.ScreenGui.GameScoreValue.Value
	end
	
	progressAmount = 0
	
	for i,player in pairs(game.Players:GetPlayers()) do
		local progressBar = player.PlayerGui:WaitForChild("ScreenGui").ProgressBar
		progressBar.Progress.Visible = false
		progressBar.Progress.Bar.Size = UDim2.new(progressBar.Size.X.Scale,progressBar.Size.X.Offset,progressBar.Size.Y.Scale,progressAmount)
	end
	
	onePlayerGame = false
	
	for i,player in pairs(game.Players:GetPlayers()) do
		player.PlayerGui.ScreenGui.Title.RoundNumber.Visible = false
	end
	
	tickSound.Volume = 0
end

-- Teleports player for next game
function teleportPlayerForNext(h)
	local spawners = game.Workspace.Spawners:GetChildren()
	game.Workspace.FallPart.CanCollide = true
	for i,player in pairs(playersInGame) do
		if player then
			if player.Character then
				if player.Character:FindFirstChild("HumanoidRootPart") then
					local hum = player.Character:FindFirstChild("HumanoidRootPart")
					hum.CFrame = hum.CFrame + Vector3.new(0,5 + spawners[1].CFrame.Y, 0)
				end
			end
		end
	end
end

-- Finds the next block to turn
function findNextBlock() 
	randomNextIndex = math.random(#plates)
	print('set random to ' .. randomNextIndex)
	if turnedPlates[randomNextIndex] ~= nil then
		findNextBlock()
	end
end

-- Generates plate colors for the game
function generateColors()
	for i = 1,#plates,1 do
		pStorageColors[i] = pColors[math.random(#pColors)]
	end
end

-- Makes all of the not turned plates transparent
function makeNotTurnedPlatesTransparent()
	for i = 1,#plates,1 do
		if turnedPlates[i] == nil then
			plates[i].BrickColor = BrickColor.new(defaultColor)
			plates[i].Transparency = 0.8
			plates[i].SurfaceGui.Enabled = false
		end
	end
end

-- Sets the newest turned plate
function setNewTurnedPlates()
	turnedPlates[randomNextIndex] = plates[randomNextIndex]
	if theRound == 1 then
		turnedColorSave[randomNextIndex] = pColors[math.random(#pColors)]
	else
		turnedColorSave[randomNextIndex] = pLessColors[math.random(#pLessColors)]
		print("pLessColors is "..pLessColors[math.random(#pLessColors)])
	end
	
	turnedPlates[randomNextIndex].BrickColor = BrickColor.new(turnedColorSave[randomNextIndex])
	turnedPlates[randomNextIndex].Transparency = 0.6
	turnedPlates[randomNextIndex].SurfaceGui.Enabled = true
end

-- Sets all of the previously turned plates
function setOldTurnedPlates()
	for i = 1,#plates,1 do
		if turnedPlates[i] ~= nil then
			turnedPlates[i].Transparency = 0.6
			turnedPlates[i].BrickColor = BrickColor.new(turnedColorSave[i])
		end
	end
end

-- Makes all of the plates transparent
function setAllPlatesTransparent()
	for i = 1,#plates,1 do
		plates[i].BrickColor = BrickColor.new(defaultColor)
		plates[i].Transparency = 0.8
	end
end

-- Checks if game is running
function isGameRunning()
	return inGame and endGameCalls == 0
end

-- Flashes the plates (memory function)
function flash()
	for transp = 0.6,0,-0.1 do
		for j = 1,#plates,1 do
			plates[j].Transparency = transp
			plates[j].BrickColor = BrickColor.new(pStorageColors[j])
			plates[j].SurfaceGui.Enabled = true
		end
		wait(0.05)
		if not isGameRunning() then
			return
		end
	end
	
	for transp = 0,0.6,0.1 do
		for j = 1,#plates,1 do
			plates[j].Transparency = transp
		end
		wait(0.05)
		if not isGameRunning() then
			return
		end
	end
end

-- Prepares for next plate round of game
function setNextPlateRound()
	if not isGameRunning() then
		return
	end
	makeNotTurnedPlatesTransparent()
	findNextBlock()
	for i = 1,#playersInGame,1 do
		if playersInGame[i].Backpack:FindFirstChild("NextBlockActivated") ~= nil then
			playersInGame[i].PlayerGui:FindFirstChild("ScreenGui").NextBlockFrame.Visible = true
			playersInGame[i].PlayerGui.ScreenGui.NextBlockFrame.TextLabel.Text = "Turning block is "..randomNextIndex
			playersInGame[i].Backpack.NextBlockActivated:Destroy()
			playersInGame[i].StarterGear.NextBlockPowerup:Destroy()
			playersInGame[i].PlayerGui.ScreenGui.PowerupActivationFrame.ActivateButton.Text = "Click here if you would like to activate the powerup for the next block that turns!"
		elseif playersInGame[i].Character:FindFirstChild("NextBlockActivated") ~= nil then
			playersInGame[i].PlayerGui:FindFirstChild("ScreenGui").NextBlockFrame.Visible = true
			playersInGame[i].PlayerGui.ScreenGui.NextBlockFrame.TextLabel.Text = "Turning block is "..randomNextIndex
			playersInGame[i].Character.NextBlockActivated:Destroy()
			playersInGame[i].StarterGear.NextBlockPowerup:Destroy()
			playersInGame[i].PlayerGui.ScreenGui.PowerupActivationFrame.Visible = false
			playersInGame[i].PlayerGui.ScreenGui.PowerupActivationFrame.ActivateButton.Text = "Click here if you would like to activate the powerup for the next block that turns!"
		end
	end
	
	setAllPlatesTransparent()
	setOldTurnedPlates()
	if plateRound == 0 then
		wait(2)
		if not isGameRunning() then
			return
		end
		for i,player in pairs(playersInGame) do
			if theRound == 1 then
				player.PlayerGui:WaitForChild("ScreenGui").Title.RoundNumber.Text = "Round One"
			elseif theRound == 2 then
				player.PlayerGui:WaitForChild("ScreenGui").Title.RoundNumber.Text = "Round Two"
			end
			player.PlayerGui:WaitForChild("ScreenGui").Title.RoundNumber.Visible = true
		end
	end
	setNewTurnedPlates()
	if plateRound == 0 and theRound == 1 then
		startSound:Play()
	end
	if theRound == 1 then
		wait(1.75)
		fallPart.Transparency = 0.9
		fallPart.BrickColor = BrickColor.new("White")
		if not isGameRunning() then
			return
		end
		wait(0.25)
		fallPart.Transparency = 1
	else
		wait(1.25)
		fallPart.Transparency = 0.9
		fallPart.BrickColor = BrickColor.new("White")
		if not isGameRunning() then
			return
		end
		wait(0.25)
		fallPart.Transparency = 1
	end
	if not isGameRunning() then
		return
	end
	for i,player in pairs(playersInGame) do
		player.PlayerGui:WaitForChild("ScreenGui").Title.RoundNumber.Visible = false
	end
	fallPart.CanCollide = false
	plateRound=plateRound+1
	
	for j = 1,#playersInGame,1 do
		playersInGame[j].PlayerGui:WaitForChild("ScreenGui").NextBlockFrame.Visible = false
	end
end

-- Helper code for flash()
function flashNextPlate()
	if plateRound >= #plates and theRound == 2 then
		for i = 1,#plates,1 do
			plates[i].Transparency = 0
			wait(0.1)
			if not isGameRunning() then
				return
			end
		end
		endGame("won")
		return
	elseif plateRound >= #plates then
		theRound = theRound + 1
		table.remove(pLessColors,math.random(#pLessColors))
		table.remove(pLessColors,math.random(#pLessColors))
		print("removed a color!!!")
		beginGame()
		return
	end
	isFlashing = true
	flashSound:Play()
	flash()
	setNextPlateRound()
	isFlashing = false
end

-- Increases a specific player's score in game
function increaseGameScore(h,scoreIncreaseBy)
	local player = game.Players:GetPlayerFromCharacter(h.Parent)
	player.PlayerGui:WaitForChild("ScreenGui").GameScoreValue.Value = player.PlayerGui.ScreenGui.GameScoreValue.Value + scoreIncreaseBy
	module:ChangeStat(player,"Score",scoreIncreaseBy)
	player.PlayerGui.ScreenGui.Title.GameScore.Text = player.PlayerGui.ScreenGui.GameScoreValue.Value
	player.PlayerGui.ScreenGui.Title.GameScore.TextSize = player.PlayerGui.ScreenGui.Title.GameScore.TextSize + 25
	player.PlayerGui.ScreenGui.Title.GameScore.TextColor = BrickColor.new(0.135286, 1, 0.0424964)
	wait(0.1)
	if not isGameRunning() then
		return
	end
	player.PlayerGui:WaitForChild("ScreenGui").Title.GameScore.TextSize = player.PlayerGui.ScreenGui.Title.GameScore.TextSize - 25
	player.PlayerGui.ScreenGui.Title.GameScore.TextColor = BrickColor.new(1, 1, 1)
end

-- Increases all scores in game
function increaseGameScoreForAll(h)
	for i,player in pairs(playersInGame) do
		if player.Name ~= h.Parent.Name then
			player.PlayerGui:WaitForChild("ScreenGui").GameScoreValue.Value = player.PlayerGui.ScreenGui.GameScoreValue.Value + 1
			player.PlayerGui.ScreenGui.Title.GameScore.Text = player.PlayerGui.ScreenGui.GameScoreValue.Value
			module:ChangeStat(player,"Score",1)
		end
	end
end

-- Tells score value of the next turning plate to all players
function tellTheScoreForNext(scoreIncreaseBy)
	for i,player in pairs(playersInGame) do
		player.PlayerGui:WaitForChild("ScreenGui").Title.NextBlockGui.Next.Text = "Next block is worth "..scoreIncreaseBy.." points!"
		player.PlayerGui.ScreenGui.Title.NextBlockGui.Next.Visible = true
		
		local success, message = pcall(function()
			hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId,scoreGamepassID)
		end)

		if hasPass then
			player.PlayerGui.ScreenGui.Title.NextBlockGui.Next.Text = "Next block is worth "..scoreIncreaseBy.."+ points!"
		end
	end
end

-- Hides player score
function hideTheScoreForNext()
	for i,player in pairs(game.Players:GetPlayers()) do
		if player then
			player.PlayerGui:WaitForChild("ScreenGui").Title.NextBlockGui.Next.Visible = false
			print("Hiding score for next")
		end
	end
end

-- Begins round timer
function beginTimer()
	local timerID = currentTimerID
	print("timer " .. timerID)
	local timerValue = 5
	if theRound == 2 then
		timerValue = 2 --thingiupdated
	end
	local players = game.Players:GetPlayers()
	
	while timerValue >= 0 do
		if timerID ~= currentTimerID then
			break
		end
		for i,player in ipairs(players) do
			if timerID ~= currentTimerID then
				break				
			end
			if player:FindFirstChild("PlayerGui") then
				player.PlayerGui:WaitForChild("ScreenGui").Frame.Timer.Text = timerValue
				if timerValue <= 1 then
					player.PlayerGui:WaitForChild("ScreenGui").Frame.Timer.TextColor3 = Color3.new(0.901961, 0, 0.0352941)
				else
					player.PlayerGui:WaitForChild("ScreenGui").Frame.Timer.TextColor3 = Color3.new(1, 1, 1)
				end
			else
				break
			end
		end
		if timerID ~= currentTimerID then
			break
		end
		
		tickSound:Play()

		wait(1)
		timerValue = timerValue - 1
	end
	
	local lastPlayers = {}
	
	if timerValue == -1 and timerID == currentTimerID then
		endTimer()
		for i,player in ipairs(playersInGame) do
			local h = player.Character:FindFirstChild("Humanoid")
			h.Health = 0
			table.insert(lastPlayers,i,playersInGame[i])
		end
		playersInGame = {}
		endGame("lost",lastPlayers)
	end
end

-- Ends round timer
function endTimer()
	currentTimerID = currentTimerID + 1
end

local GamePlayers = game:GetService("Players")
GamePlayers.PlayerAdded:Connect(function(player)	
	
	player.CharacterRemoving:Connect(function(characterremoving)
		print("character removing...")
		print("There is/are "..#playersInGame.." player(s) in game")
		
		local lastPlayers = {}
		
		if #playersInGame == 1 then
			for j = 1,#playersInGame,1 do
				table.insert(lastPlayers,j,playersInGame[j])
			end
		end
		
		local progressBar = player.PlayerGui:WaitForChild("ScreenGui").ProgressBar
		progressBar.Progress.Visible = false
		
		for i = 1,#playersInGame,1 do
			if playersInGame[i] ~= nil then
				if playersInGame[i].Name == characterremoving.Name then
					table.remove(playersInGame,i)
					print("removed "..characterremoving.Name)
				end
			end
		end
		print("There is/are "..#playersInGame.." player(s) in game")
		if --[[inGame == true and ]] #playersInGame == 0 then
			endGame("lost",lastPlayers)
		end
	end)
	
	if #game.Players:GetPlayers() == 1 then
		if player.PlayerGui:WaitForChild("ScreenGui").TutorialFrame.Visible == false then
			player.PlayerGui:WaitForChild("ScreenGui").SoloModeFrame.Visible = true
		end
	elseif #game.Players:GetPlayers() > 1 then
		for i,aplayer in pairs(game.Players:GetPlayers()) do
			if aplayer:FindFirstChild("PlayerGui") ~= nil then
				if aplayer.PlayerGui:WaitForChild("ScreenGui").SoloModeFrame.Visible == true then
					aplayer.PlayerGui:WaitForChild("ScreenGui").SoloModeFrame.TextLabel.Text = "Another player has joined so the game mode is now set to multiplayer. Have fun!"
				end
			end
		end
	end
end)

-- Functionality for when player is removed
game.Players.PlayerRemoving:Connect(function(playerremoving)
	print("player leaving...")
	
	local lastPlayers = {}
	
	if #playersInGame == 1 then
		for j = 1,#playersInGame,1 do
			table.insert(lastPlayers,j,playersInGame[j])
		end
	end
	
	for i = 1,#playersInGame,1 do
		if playersInGame[i].Name == playerremoving.Name then
			print("removed "..playersInGame[i].Name)
			table.remove(playersInGame,i)
		end
	end
	if --[[inGame == true and ]] #playersInGame <1 then
		endGame("lost",lastPlayers)
	end
end)

-- Who got the plate?
function tellWhoGotIt(h)
	local checkEffect = Instance.new("ParticleEmitter")
	checkEffect.Name = "CheckEffect"
	if h.Parent:FindFirstChild("HumanoidRootPart") then
		checkEffect.Parent = h.Parent:FindFirstChild("HumanoidRootPart")
	end
	checkEffect.Lifetime = NumberRange.new(6,6)
	checkEffect.Texture = "rbxassetid://12345"
	checkEffect.LightEmission = 0 -- When particles overlap, multiply their color to be brighter
	checkEffect.LightInfluence = 1
	checkEffect.Rate = 8
end

-- Hide who got the plate
function hideWhoGotIt(h)
	local rootPart =  h.Parent:FindFirstChild("HumanoidRootPart")
	if rootPart then
		if rootPart:FindFirstChild("CheckEffect") then
			rootPart:FindFirstChild("CheckEffect"):Destroy()
		end
	end
end

-- Functionality for when a plate is touched
function plateTouched(plateIndex, hit)
	local h = hit.Parent:FindFirstChild("Humanoid")
	if not h then
		return
	end
	if #playersInGame == 0 then
		return
	end
	
	for i = 1,#playersInGame,1 do
		if playersInGame[i].Name == hit.Parent.Name then
			break
		elseif i == #playersInGame then
			return
		end
	end
	
	if h.Health == 0 then
		return
	end
	
	local plName = h.Parent.Name
	local player = game.Players:FindFirstChild(plName)
	
	if plateIndex == randomNextIndex then
		if not isFlashing and not hasTouched then
			endTimer()
			hasTouched = true
			correctSound:Play()
			
			teleportPlayerForNext()
			
			local checkEffectPlate = Instance.new("ParticleEmitter")
			checkEffectPlate.Name = "CheckEffectPlate"
			checkEffectPlate.Parent = plates[plateIndex]
			checkEffectPlate.Lifetime = NumberRange.new(6,6)
			checkEffectPlate.Texture = "rbxassetid://12345"
			checkEffectPlate.LightEmission = 0 -- When particles overlap, multiply their color to be brighter
			checkEffectPlate.LightInfluence = 1
			checkEffectPlate.Rate = 8
			
			if easyMode == true then
				progressAmount = progressAmount + (0+player.PlayerGui:WaitForChild("ScreenGui").ProgressBar.Progress.Size.Y.Offset/(3*2))
			else
				progressAmount = progressAmount + (0+player.PlayerGui:WaitForChild("ScreenGui").ProgressBar.Progress.Size.Y.Offset/(#plates*2))
			end
			
			for i,player in pairs(playersInGame) do
				local progressBar = player.PlayerGui:WaitForChild("ScreenGui").ProgressBar
				progressBar.Progress.Visible = true
				progressBar.Progress.Bar.Size = UDim2.new(progressBar.Progress.Bar.Size.X.Scale,progressBar.Progress.Bar.Size.X.Offset,progressBar.Progress.Bar.Size.Y.Scale,progressAmount)
			end
			
			local previousScore = player.PlayerGui:WaitForChild("ScreenGui").GameScoreValue.Value
			local scoreIncreaseBy
			local nextScoreIncreaseBy
			
			if plateRound == 1 and theRound == 1 then --Failsafe
				if #playersInGame == 1 then
					onePlayerGame = true
				end
			end
			
			if onePlayerGame == true then
				scoreIncreaseBy = (plateRound+theRound-1)
				nextScoreIncreaseBy = (plateRound+1+theRound-1)
			else
				scoreIncreaseBy = ((plateRound*theRound)+1+#playersInGame)
				nextScoreIncreaseBy = (((plateRound+1)*theRound)+1+#playersInGame)
			end
			
			print("previousScore: "..previousScore)
			print("scoreIncreaseBy: "..scoreIncreaseBy)
			
			increaseGameScore(h,scoreIncreaseBy)
			increaseGameScoreForAll(h)
			
			print("Increased to: "..player.PlayerGui.ScreenGui.GameScoreValue.Value)
			
			plates[plateIndex].Transparency = 0
			
			tellWhoGotIt(h)
			
			wait(0.5)

			local success, message = pcall(function()
				hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId,scoreGamepassID)
			end)
			
			if hasPass then
				local change
				local newScore = player.PlayerGui.ScreenGui.GameScoreValue.Value
				print(math.floor(newScore/10))
				print(math.floor(previousScore/10))
				if math.floor(newScore/10) ~= math.floor(previousScore/10) then
					if scoreIncreaseBy < 10 then
						change = 1
						module:ChangeStat(player,"Score",change)
						player.PlayerGui:WaitForChild("ScreenGui").GameScoreValue.Value = player.PlayerGui.ScreenGui.GameScoreValue.Value + change
						player.PlayerGui.ScreenGui.Title.GameScore.Text = player.PlayerGui.ScreenGui.GameScoreValue.Value
					else
						change = math.floor(scoreIncreaseBy/10)
						module:ChangeStat(player,"Score",change)
						player.PlayerGui:WaitForChild("ScreenGui").GameScoreValue.Value = player.PlayerGui.ScreenGui.GameScoreValue.Value + change
						player.PlayerGui.ScreenGui.Title.GameScore.Text = player.PlayerGui.ScreenGui.GameScoreValue.Value
					end
				end
			end
			
			wait(1)
			
			checkEffectPlate:Destroy()
			
			hideWhoGotIt(h)
			
			if plateRound < #plates then
				tellTheScoreForNext(nextScoreIncreaseBy)
			end
			
			if theRound == 1 then
				wait(2)
			else
				wait(1.5)
			end
			
			hideTheScoreForNext()
			plates[plateIndex].Transparency = 0.6
			flashNextPlate()
			hasTouched = false
			print(plateRound .. "<" .. #plates)
			if plateRound <= #plates then
				if plateRound == #plates and timerRanOnceAtEnd == false then
					timerRanOnceAtEnd = true
					beginTimer()
				elseif plateRound < #plates then
					beginTimer()
				end
			end
		end
	elseif --[[ plateIndex ~= randomBeforeIndex and --]] turnedPlates[plateIndex] ~= nil then
		if h then
			h.Health = 0
			
			local lastPlayers = {}
			
			if #playersInGame == 1 then
				for j = 1,#playersInGame,1 do
					table.insert(lastPlayers,j,playersInGame[j])
				end
			end
			
			for i = 1,#playersInGame,1 do
				if playersInGame[i] == game.Players:GetPlayerFromCharacter(h.Parent) then
					table.remove(playersInGame,i)
				end
			end
			
			local progressBar = player.PlayerGui:WaitForChild("ScreenGui").ProgressBar
			progressBar.Progress.Visible = false

			local lightray = Instance.new("Part")
			lightray.Name = "LightRay"
			lightray.Parent = workspace
			lightray.Anchored = true
			lightray.TopSurface = "Smooth"
			lightray.BottomSurface = "Smooth"
			lightray.Position = plates[plateIndex].Position + Vector3.new(0,10,0)
			lightray.Size = lightray.Size + Vector3.new(0,18,2)
			lightray.Material = "Ice"
			lightray.Transparency = 0.9
			lightray.BrickColor = BrickColor.new("White")
			local pointlight = Instance.new("PointLight")
			pointlight.Parent = lightray
			pointlight.Brightness = 10
			pointlight.Range = 8
			pointlight.Color = Color3.new(1, 1, 1)
			lightray.CanCollide = false
			
			local xEffect = Instance.new("ParticleEmitter")
			xEffect.Name = "xEffect"
			if h.Parent:FindFirstChild("HumanoidRootPart") then
				xEffect.Parent = h.Parent:FindFirstChild("HumanoidRootPart")
			end
			xEffect.Lifetime = NumberRange.new(6,6)
			xEffect.LightEmission = 0 -- When particles overlap, multiply their color to be brighter
			xEffect.LightInfluence = 1
			xEffect.Texture = "rbxassetid://12345"
			xEffect.Rate = 8
			
			wait(0.8)
			lightray:Destroy()
			xEffect:Destroy()
			if #playersInGame == 0 then
				endGame("lost",lastPlayers)
			end
		end
	end
end

-- Connect plate Touched event
function connectPlates() 
	for i = 1,#plates,1 do
		plates[i].Touched:connect(function(hit)
			plateTouched(i, hit)
		end)
	end
end

-- Start the game
function beginGame()
	if #playersInGame == 0 then
		return
	end
	print("beginGame() is called!")
	resetBeginState()
	generateColors()
	
	for i = 1,#plates,1 do
		plates[i].BrickColor = BrickColor.new(defaultColor)
	end
		
	flashSound:Play()

	for transp = 0,0.8,0.1 do
		for j = 1,#plates,1 do
			plates[j].Transparency = transp
		end
		wait(0.1)
		if not isGameRunning() then
			return
		end
	end
	
	for i = 1,#plates,1 do
		plates[i].BrickColor = BrickColor.new(pStorageColors[i])
	end
	
	flashSound:Play()

	for transp = 0,0.8,0.1 do
		for j = 1,#plates,1 do
			plates[j].Transparency = transp
		end
		wait(0.1)
		if not isGameRunning() then
			return
		end
	end
	
	for i = 1,#plates,1 do
		plates[i].BrickColor = BrickColor.new(defaultColor)
	end

	plateRound=0
	connectPlates()
	setNextPlateRound()
	if theRound == 1 then
		beginTimer()
		if #playersInGame == 1 then
			onePlayerGame = true
		end
	end
end

-- Flash the missed plate after game is over
function flashMissedOne()
	if randomNextIndex ~= nil then
		if turnedPlates[randomNextIndex] ~= nil then
			local partToFlash = turnedPlates[randomNextIndex]
			for i = 1,15,1 do
				partToFlash.Transparency = 0
				wait(0.5)
				partToFlash.Transparency = 0.6
				wait(0.5)
			end
			partToFlash.Transparency = 0.6
		end
	else
		return
	end
end

-- Who won the game?
function coloredWinnerGui()
	for i,player in pairs(game.Players:GetPlayers()) do
		if player:FindFirstChild("PlayerGui") then
			player.PlayerGui:WaitForChild("ScreenGui").GameOver.BackgroundColor3 = Color3.new(0.901961, 0, 0.0352941)
		end
	end
	wait(0.5)
	for i,player in pairs(game.Players:GetPlayers()) do
		if player:FindFirstChild("PlayerGui") then
			player.PlayerGui:WaitForChild("ScreenGui").GameOver.BackgroundColor3 = Color3.new(0.0823529, 0.603922, 0.839216)
		end
	end
	wait(0.5)
	for i,player in pairs(game.Players:GetPlayers()) do
		if player:FindFirstChild("PlayerGui") then
			player.PlayerGui:WaitForChild("ScreenGui").GameOver.BackgroundColor3 = Color3.new(0.188235, 1, 0.0235294)
		end
	end
	wait(0.5)
	for i,player in pairs(game.Players:GetPlayers()) do
		if player:FindFirstChild("PlayerGui") then
			player.PlayerGui:WaitForChild("ScreenGui").GameOver.BackgroundColor3 = Color3.new(1,1,1)
		end
	end
end

-- End the game
function endGame(status, theLastPlayers)
	print("endGameCalls: "..endGameCalls)
	if endGameCalls > 0 then
		return
	end
	endGameCalls = endGameCalls + 1
	print("game ended "..status)
	
	if status ~= "won" then
		spawn(flashMissedOne)
	end
	
	if status ~= "won" then
		while true do
			local isAnyoneSpawning = false
			for i,player in pairs(game.Players:GetPlayers()) do
				if player and player.Character then
					if player.Character.Humanoid.Health ~= 100 then
						isAnyoneSpawning = true
					end
				end
			end
			if not isAnyoneSpawning then
				break
			end
			wait(1)
		end
	end
	
	local lobbyspawners = game.Workspace.LobbySpawners:GetChildren()
	for i,player in pairs(playersInGame) do
		if player then
			if player.Character then
				if player.Character:FindFirstChild("HumanoidRootPart") then
					player.Character:FindFirstChild("HumanoidRootPart").CFrame = lobbyspawners[math.random(#lobbyspawners)].CFrame + Vector3.new(0,5,0)
				end
			end
		end
	end
	
	print("teleported players")
	
	--announce winning players
	if status == "won" then
		winSound:Play()
		
		--Confetti!
		game.Workspace.ConfettiBlue.ParticleEmitter.Enabled = true
		game.Workspace.ConfettiRed.ParticleEmitter.Enabled = true
		game.Workspace.ConfettiGreen.ParticleEmitter.Enabled = true
		
		if #playersInGame == 1 then
			
			game.Workspace.LastStanding.SurfaceGui.Title.Text = "Previous Game Winner"
			game.Workspace.LastStanding.SurfaceGui.Information.Text = playersInGame[1].Name
			
			for i,player in pairs(game.Players:GetPlayers()) do
				if player:FindFirstChild("PlayerGui") then
					player.PlayerGui:WaitForChild("ScreenGui").GameOver.WhoWon.Text = playersInGame[1].Name.." has won the game and received a score bonus!"
					player.PlayerGui.ScreenGui.GameOver.Visible = true
					game.Lighting.Blur.Size = 20
					spawn(coloredWinnerGui)
				end
			end
			
			for i,player in pairs(playersInGame) do
				local playerUserID = player.UserId
				BadgeService:AwardBadge(playerUserID, winnerBadgeID)
				module:ChangeStat(player,"Wins",1)
				module:ChangeStat(player,"Score",30)
			end
			
			for i,player in pairs(playersInGame) do
				local playerUserID = player.UserId
				if player.hiddenleaderstats.Wins.Value > 20 then
					local doesPlayerHaveWinner21Badge = BadgeService:UserHasBadgeAsync(playerUserID, winner21BadgeID)
					if doesPlayerHaveWinner21Badge == false then
						BadgeService:AwardBadge(playerUserID, winner21BadgeID)
						print("Awarded winner 21 badge to "..playerUserID)
					end
				end
			end
			
		else
			game.Workspace.LastStanding.SurfaceGui.Title.Text = "Previous Game Winners"
			
			local playerNamesThatWon = {}
			
			for i,player in pairs(playersInGame) do
				table.insert(playerNamesThatWon,i,playersInGame[i].Name)
				local playerUserID = player.UserId
				print(playerUserID)
				local doesPlayerHaveWinnerBadge = BadgeService:UserHasBadgeAsync(playerUserID, winnerBadgeID)
				if doesPlayerHaveWinnerBadge == false then
					BadgeService:AwardBadge(playerUserID, winnerBadgeID)
				end
				module:ChangeStat(player,"Wins",1)
				module:ChangeStat(player,"Score",30)
				
				if player.hiddenleaderstats.Wins.Value > 20 then
					local doesPlayerHaveWinner21Badge = BadgeService:UserHasBadgeAsync(playerUserID, winner21BadgeID)
					if doesPlayerHaveWinner21Badge == false then
						BadgeService:AwardBadge(playerUserID, winner21BadgeID)
						print("Awarded winner 21 badge to "..playerUserID)
					end
				end
			end
			
			for i,player in pairs(playersInGame) do
				game.Workspace.LastStanding.SurfaceGui.Information.Text = table.concat(playerNamesThatWon, " and ")
			end
			
			for i,player in pairs(game.Players:GetPlayers()) do
				if player:FindFirstChild("PlayerGui") then
					player.PlayerGui:WaitForChild("ScreenGui").GameOver.WhoWon.Text = table.concat(playerNamesThatWon, " and ").." have won the game and received a score bonus!"
					player.PlayerGui.ScreenGui.GameOver.Visible = true
					game.Lighting.Blur.Size = 20
					spawn(coloredWinnerGui)
				end
			end
		end
	else
		if theLastPlayers ~= nil then
			if #theLastPlayers == 1 then
				game.Workspace.LastStanding.SurfaceGui.Title.Text = "Previous Game Last Player Standing"
				game.Workspace.LastStanding.SurfaceGui.Information.Text = theLastPlayers[1].Name
			elseif #theLastPlayers > 1 then
				local playerNamesThatLastStanded = {}
				
				for i,player in pairs(theLastPlayers) do
					table.insert(playerNamesThatLastStanded,i,theLastPlayers[i].Name)
				end
				
				game.Workspace.LastStanding.SurfaceGui.Title.Text = "Previous Game Last Players Standing"
				for i,player in pairs(theLastPlayers) do
					game.Workspace.LastStanding.SurfaceGui.Information.Text = table.concat(playerNamesThatLastStanded, " and ")
				end
			end
		end
	end
	
	print("resetting state")
	resetEndState()
	endTimer()
	GameEnded:Fire()
end

-- Player tutorial
tutorialWaitEvent.OnServerEvent:Connect(function(player)
	for i,v in pairs(playersInGame) do
		if v == player then
			return
		end
	end
	if #playersInGame == 0 then
		return
	end
	player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("TutorialWaitingFrame").Visible = true
end)

----------------------------------------------------------------------------------

-- Calling code
GameStarted.Event:Connect(function(playersSentToGame)
	
	playersInGame = {}
	
	for i,player in pairs(playersSentToGame) do
		table.insert(playersInGame,player)
	end
	
	endGameCalls = 0
	
	for i = 1,#plates,1 do
		plates[i].BrickColor = BrickColor.new(defaultColor)
		plates[i].Transparency = 0.8
		plates[i].SurfaceGui.Enabled = false
	end
	
	wait(3)
	
	beginGame()

end)



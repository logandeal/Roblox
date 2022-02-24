local blur = game.Lighting.Blur
local tickSound = Instance.new("Sound", game.Workspace)
tickSound.SoundId = "rbxassetid://12345"
tickSound.Volume = 0.1

local whosNotPlayingCheck1
local whosNotPlayingCheck2
local playersSentToGame

function waitForPlayers()
	repeat wait(1) until game.Players.NumPlayers >= 1

	local spawners = game.Workspace.Spawners:GetChildren()
	local GameStarted = game.Workspace:WaitForChild("StartGame")
	
	for intermission = 5,0,-1 do
		for i,player in pairs(game.Players:GetPlayers()) do
			if player.PlayerGui:FindFirstChild("ScreenGui") ~= nil then
				player.PlayerGui:FindFirstChild("ScreenGui").Title.Waiting.Text = "Intermission: "..intermission
				player.PlayerGui:FindFirstChild("ScreenGui").Title.Waiting.Visible = true
			end
		end
		tickSound:Play()
		wait(1)
	end
	
	game.Workspace.ConfettiBlue.ParticleEmitter.Enabled = false
	game.Workspace.ConfettiRed.ParticleEmitter.Enabled = false
	game.Workspace.ConfettiGreen.ParticleEmitter.Enabled = false

	for i,player in pairs(game.Players:GetPlayers()) do
		player.PlayerGui:WaitForChild("ScreenGui",math.huge).Title.Waiting.Text = "Waiting for potential players"
		player.PlayerGui:WaitForChild("ScreenGui").Title.Waiting.Visible = true
	end

	repeat wait(1) until game.Players.NumPlayers >= 1

	wait(2)
	
	whosNotPlayingCheck1 = 0
	for i,player in pairs(game.Players:GetPlayers()) do
		if player.PlayerGui:WaitForChild("AFKGui").PlayingNotPlayingFrame.NotPlayingButton.Visible == true then
			whosNotPlayingCheck1 = whosNotPlayingCheck1 + 1
			
			print("**")
			print(whosNotPlayingCheck1)
			print(#game.Players:GetPlayers())
			
			if whosNotPlayingCheck1 == #game.Players:GetPlayers() then
				waitForPlayers()
				return
			end
		end
	end
	
	for i,player in pairs(game.Players:GetPlayers()) do
		player.PlayerGui:WaitForChild("ScreenGui").GameOver.Visible = false
	end
	blur.Size = 0 -- Make this a remote event and make blur size 0 if the menu gui is not open

	for i,player in pairs(game.Players:GetPlayers()) do
		player.PlayerGui:WaitForChild("ScreenGui").Title.Waiting.Text = "Starting a new game soon!"
		player.PlayerGui:WaitForChild("ScreenGui").Title.Waiting.Visible = true
	end
	
	wait(5)

	for starting = 5,0,-1 do
		for i,player in pairs(game.Players:GetPlayers()) do
			player.PlayerGui:WaitForChild("ScreenGui").Title.Waiting.Text = "Entering the game in "..starting
			player.PlayerGui:WaitForChild("ScreenGui").Title.Waiting.Visible = true
		end
		tickSound:Play()
		wait(1)
	end

	for i,player in pairs(game.Players:GetPlayers()) do
		player.PlayerGui:WaitForChild("ScreenGui").Title.Waiting.Visible = false
	end
	
	for i,player in pairs(game.Players:GetPlayers()) do
		player.PlayerGui:WaitForChild("ScreenGui").Title.GameScore.Visible = false
	end
	
	game.Workspace.FallPart.CanCollide = true -- Failsafe
	
	whosNotPlayingCheck2 = 0
	for i,player in pairs(game.Players:GetPlayers()) do
		if player.PlayerGui:WaitForChild("AFKGui").PlayingNotPlayingFrame.NotPlayingButton.Visible == true then
			whosNotPlayingCheck2 = whosNotPlayingCheck2 + 1
			
			if whosNotPlayingCheck2 == #game.Players:GetPlayers() then
				waitForPlayers()
				return
			end
		end
	end
	
	playersSentToGame = {}

	for i,player in pairs(game.Players:GetPlayers()) do
		if player then
			if player.Character then
				if player.Character:FindFirstChild("HumanoidRootPart") then
					if player.PlayerGui:WaitForChild("AFKGui").PlayingNotPlayingFrame.NotPlayingButton.Visible == false then
						player.Character:FindFirstChild("HumanoidRootPart").CFrame = spawners[math.random(#spawners)].CFrame + Vector3.new(0,5,0)
						table.insert(playersSentToGame,player)
					end
				end
			end
		end
	end
	
	if #playersSentToGame > 0 then
		GameStarted:Fire(playersSentToGame)
	else
		waitForPlayers()
		return
	end
end

waitForPlayers()

game.Workspace:WaitForChild("EndGame").Event:Connect(function()
	for i,player in pairs(game.Players:GetPlayers()) do
		player:FindFirstChild("PlayerGui"):WaitForChild("ScreenGui").Title.GameScore.Visible = false
	end
	waitForPlayers()
end)

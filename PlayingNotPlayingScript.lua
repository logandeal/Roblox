local clickSound = Instance.new("Sound", script.Parent)
clickSound.SoundId = "rbxassetid://12345"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playingButton = script.Parent.PlayingButton
local notPlayingButton = script.Parent.NotPlayingButton

local visibilityEvent = ReplicatedStorage:WaitForChild("PlayingNotPlayingVisibility")

local function boucePlayingButton()
	playingButton.Size = UDim2.new(playingButton.Size.X.Scale,playingButton.Size.X.Offset-3,playingButton.Size.Y.Scale,playingButton.Size.Y.Offset-3)
	wait(0.1)
	playingButton.Size = UDim2.new(playingButton.Size.X.Scale,playingButton.Size.X.Offset+3,playingButton.Size.Y.Scale,playingButton.Size.Y.Offset+3)
end

local function bounceNotPlayingButton()
	notPlayingButton.Size = UDim2.new(notPlayingButton.Size.X.Scale,notPlayingButton.Size.X.Offset-3,notPlayingButton.Size.Y.Scale,notPlayingButton.Size.Y.Offset-3)
	wait(0.1)
	notPlayingButton.Size = UDim2.new(notPlayingButton.Size.X.Scale,notPlayingButton.Size.X.Offset+3,notPlayingButton.Size.Y.Scale,notPlayingButton.Size.Y.Offset+3)
end

playingButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	boucePlayingButton()
	visibilityEvent:FireServer("clickedPlaying")
	print(game.Players.LocalPlayer.PlayerGui.ScreenGui.ProgressBar.Progress.Bar.Size)
	--game.Players.LocalPlayer.PlayerGui.ScreenGui.ProgressBar.Progress.Bar:Destroy()
end)

notPlayingButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	bounceNotPlayingButton()
	visibilityEvent:FireServer("clickedNotPlaying")
end)

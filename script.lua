local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- right side path
local rightWaypoints = {
    Vector3.new(-473.04, -6.99, 29.71),
    Vector3.new(-483.57, -5.10, 18.74),
    Vector3.new(-475.00, -6.99, 26.43),
    Vector3.new(-474.67, -6.94, 105.48),
}
-- left side path 
local leftWaypoints = {
    Vector3.new(-472.49, -7.00, 90.62),
    Vector3.new(-484.62, -5.10, 100.37),
    Vector3.new(-475.08, -7.00, 93.29),
    Vector3.new(-474.22, -6.96, 16.18),
}


local patrolMode = "none"
local floating = false
local currentWaypoint = 1
local heartbeatConn
local waitingForCountdownLeft = false
local waitingForCountdownRight = false
local AUTO_START_DELAY = 0.7

local function isCountdownNumber(text)
    local num = tonumber(text)
    if num and num >= 1 and num <= 5 then
        return true, num
    end
    return false
end

local function isTimerInCountdown(label)
    if not label then return false end
    local ok, num = isCountdownNumber(label.Text)
    return ok and num >= 1 and num <= 5
end

local function getCurrentSpeed()
    if patrolMode == "right" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    elseif patrolMode == "left" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    end
    return 0
end

local function getCurrentWaypoints()
    if patrolMode == "right" then
        return rightWaypoints
    elseif patrolMode == "left" then
        return leftWaypoints
    end
    return {}
end

local function startMovement(mode)
    patrolMode = mode
    currentWaypoint = 1
    if mode == "right" then
        rightBtn.Text = "STOP Right"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 40, 40)}):Play()
        print("AutoRight movement started")
    else
        leftBtn.Text = "STOP Left"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 40, 40)}):Play()
        print("AutoLeft movement started")
    end
end

local function updateWalking()
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    local currentVel = root.AssemblyLinearVelocity
    
    if floating then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {char}
        
        local raycastResult = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), raycastParams)
        
        if raycastResult then
            local groundY = raycastResult.Position.Y
            local targetY = groundY + 8
            local currentY = root.Position.Y
            local yDifference = targetY - currentY
            
            if math.abs(yDifference) > 0.3 then
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    yDifference * 15,
                    currentVel.Z
                )
            else
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    0,
                    currentVel.Z
                )
            end
        end
    end
    
    if patrolMode ~= "none" then
        local waypoints = getCurrentWaypoints()
        local targetPos = waypoints[currentWaypoint]
        local currentPos = root.Position
        
        local targetXZ = Vector3.new(targetPos.X, 0, targetPos.Z)
        local currentXZ = Vector3.new(currentPos.X, 0, currentPos.Z)
        local distanceXZ = (targetXZ - currentXZ).Magnitude
        
        if distanceXZ > 3 then
            local moveDirection = (targetXZ - currentXZ).Unit
            local currentSpeed = getCurrentSpeed()
            
            root.AssemblyLinearVelocity = Vector3.new(
                moveDirection.X * currentSpeed,
                root.AssemblyLinearVelocity.Y,
                moveDirection.Z * currentSpeed
            )
        else
            if currentWaypoint == #waypoints then
                local completedMode = patrolMode
                patrolMode = "none"
                currentWaypoint = 1
                waitingForCountdownLeft = false
                waitingForCountdownRight = false
                
                rightBtn.Text = "AutoRight"
                leftBtn.Text = "AutoLeft"
                TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
                TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
                
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                
                print("Path completed - auto stopped")
            else
                currentWaypoint = currentWaypoint + 1
                local speed = getCurrentSpeed()
                local modeText = (patrolMode == "right") and "AutoRight" or "AutoLeft"
                local speedText = (speed == 60) and "60" or "30"
                print("heading to " .. modeText .. " spot " .. currentWaypoint .. " @ " .. speedText)
            end
        end
    end
end

local sg = Instance.new("ScreenGui")
sg.Name = "Meloska AutoDuel"
sg.Parent = player:WaitForChild("PlayerGui")
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -80)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = sg

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(45, 45, 45)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.Position = UDim2.new(0, 0, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "Meloska Autoduel"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamSemibold
Title.Parent = MainFrame

local CreditText = Instance.new("TextLabel")
CreditText.Size = UDim2.new(1, 0, 0, 15)
CreditText.Position = UDim2.new(0, 0, 0, 28)
CreditText.BackgroundTransparency = 1
CreditText.Text = "made by tazyyy._"
CreditText.TextColor3 = Color3.fromRGB(140, 140, 140)
CreditText.TextSize = 10
CreditText.Font = Enum.Font.Gotham
CreditText.Parent = MainFrame

rightBtn = Instance.new("TextButton")
rightBtn.Size = UDim2.new(0.85, 0, 0, 30)
rightBtn.Position = UDim2.new(0.075, 0, 0, 48)
rightBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
rightBtn.Text = "AutoRight"
rightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rightBtn.TextSize = 11
rightBtn.Font = Enum.Font.GothamBold
rightBtn.BorderSizePixel = 0
rightBtn.Parent = MainFrame

local rightBtnCorner = Instance.new("UICorner")
rightBtnCorner.CornerRadius = UDim.new(0, 6)
rightBtnCorner.Parent = rightBtn

leftBtn = Instance.new("TextButton")
leftBtn.Size = UDim2.new(0.85, 0, 0, 30)
leftBtn.Position = UDim2.new(0.075, 0, 0, 83)
leftBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
leftBtn.Text = "AutoLeft"
leftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
leftBtn.TextSize = 11
leftBtn.Font = Enum.Font.GothamBold
leftBtn.BorderSizePixel = 0
leftBtn.Parent = MainFrame

local leftBtnCorner = Instance.new("UICorner")
leftBtnCorner.CornerRadius = UDim.new(0, 6)
leftBtnCorner.Parent = leftBtn

local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0.85, 0, 0, 30)
floatBtn.Position = UDim2.new(0.075, 0, 0, 118)
floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
floatBtn.Text = "Float OFF"
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.TextSize = 11
floatBtn.Font = Enum.Font.GothamBold
floatBtn.BorderSizePixel = 0
floatBtn.Parent = MainFrame

local floatBtnCorner = Instance.new("UICorner")
floatBtnCorner.CornerRadius = UDim.new(0, 6)
floatBtnCorner.Parent = floatBtn

rightBtn.MouseButton1Click:Connect(function()
    if patrolMode == "right" or waitingForCountdownRight then
        patrolMode = "none"
        currentWaypoint = 1
        waitingForCountdownRight = false
        rightBtn.Text = "AutoRight"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
        leftBtn.Text = "AutoLeft"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
        
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end
        print("AutoRight stopped")
    else
        local success, label = pcall(function()
            return player.PlayerGui
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame
                :FindFirstChild("Timer")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer
                :FindFirstChild("Label")
        end)
        
        if success and label and isTimerInCountdown(label) then
            waitingForCountdownRight = true
            rightBtn.Text = "Waiting..."
            TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 200, 50)}):Play()
            leftBtn.Text = "AutoLeft"
            TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            print("AutoRight waiting for countdown")
        else
            startMovement("right")
        end
    end
end)

leftBtn.MouseButton1Click:Connect(function()
    if patrolMode == "left" or waitingForCountdownLeft then
        patrolMode = "none"
        currentWaypoint = 1
        waitingForCountdownLeft = false
        leftBtn.Text = "AutoLeft"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
        rightBtn.Text = "AutoRight"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
        
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end
        print("AutoLeft stopped")
    else
        local success, label = pcall(function()
            return player.PlayerGui
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame
                :FindFirstChild("DuelsMachineTopFrame")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame
                :FindFirstChild("Timer")
                and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer
                :FindFirstChild("Label")
        end)
        
        if success and label and isTimerInCountdown(label) then
            waitingForCountdownLeft = true
            leftBtn.Text = "Waiting..."
            TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 200, 50)}):Play()
            rightBtn.Text = "AutoRight"
            TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            print("AutoLeft waiting for countdown")
        else
            startMovement("left")
        end
    end
end)

floatBtn.MouseButton1Click:Connect(function()
    floating = not floating
    
    if floating then
        floatBtn.Text = "Float ON"
        floatBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        print("Float ON")
    else
        floatBtn.Text = "Float OFF"
        floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            end
        end
        print("Float OFF")
    end
end)

heartbeatConn = RunService.Heartbeat:Connect(updateWalking)

player.CharacterAdded:Connect(function()
    task.wait(1)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    floating = false
    
    rightBtn.Text = "AutoRight"
    leftBtn.Text = "AutoLeft"
    floatBtn.Text = "Float OFF"
    TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
    TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
    floatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

sg.Destroying:Connect(function()
    if heartbeatConn then
        heartbeatConn:Disconnect()
    end
end)

local function onTextChanged(label)
    local text = label.Text
    local ok, number = isCountdownNumber(text)

    if ok then
        print("Countdown detected:", number)

        if number == 1 then
            if waitingForCountdownLeft then
                print("Countdown finished! Starting auto left in", AUTO_START_DELAY, "seconds")
                task.wait(AUTO_START_DELAY)
                waitingForCountdownLeft = false
                startMovement("left")
            end
            
            if waitingForCountdownRight then
                print("Countdown finished! Starting auto right in", AUTO_START_DELAY, "seconds")
                task.wait(AUTO_START_DELAY)
                waitingForCountdownRight = false
                startMovement("right")
            end
        end
    end
end

spawn(function()
    local success, label = pcall(function()
        return player.PlayerGui
            :FindFirstChild("DuelsMachineTopFrame")
            and player.PlayerGui.DuelsMachineTopFrame
            :FindFirstChild("DuelsMachineTopFrame")
            and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame
            :FindFirstChild("Timer")
            and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer
            :FindFirstChild("Label")
    end)
    
    if success and label then
        print("Timer label found! Countdown detection enabled.")
        onTextChanged(label)
        label:GetPropertyChangedSignal("Text"):Connect(function()
            onTextChanged(label)
        end)
    else
        print("Timer label not found. Auto movements will start immediately.")
    end
end)

print("AutoDuel ready")
print("made by elpapas091p")
print("Countdown detection enabled - will wait for timer if active")

--@rznnq ui 
--INF JUMP DISCORD @rznnq (working in all games uwu)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local infinityJumpEnabled = true
local jumpForce = 50
local clampFallSpeed = 80

RunService.Heartbeat:Connect(function()
	if not infinityJumpEnabled then return end
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp.Velocity.Y < -clampFallSpeed then
		hrp.Velocity = Vector3.new(hrp.Velocity.X, -clampFallSpeed, hrp.Velocity.Z)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if not infinityJumpEnabled then return end
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Velocity = Vector3.new(hrp.Velocity.X, jumpForce, hrp.Velocity.Z)
	end
end)
print("made by ylzk on dc")

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

--gui its ahh i coded it in 10mins
local gui = Instance.new("ScreenGui")
gui.Name = "PromptProgressGui"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.3, 0.035)
frame.Position = UDim2.fromScale(0.35, 0.9)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
bar.BorderSizePixel = 0
bar.Parent = frame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 12)
barCorner.Parent = bar

local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.Text = "0%"
text.TextColor3 = Color3.new(1, 1, 1)
text.TextScaled = true
text.Font = Enum.Font.GothamBold
text.Parent = frame

--SETTINGS
local activePrompt = nil
local startTime = 0
local holdDuration = 1.5 --CHANGE ONLY THIS!
local renderConn = nil

local function colorFromProgress(p)
	if p < 0.5 then
		return Color3.fromRGB(255, math.floor(p * 2 * 255), 0)
	else
		return Color3.fromRGB(math.floor((1 - p) * 2 * 255), 255, 0)
	end
end

local function stopBar()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	frame.Visible = false
	bar.Size = UDim2.fromScale(0, 1)
	text.Text = "0%"
	activePrompt = nil
end

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	activePrompt = prompt
	startTime = os.clock()
	holdDuration = prompt.HoldDuration

	frame.Visible = true
	bar.Size = UDim2.fromScale(0, 1)
	text.Text = "0%"

	renderConn = RunService.RenderStepped:Connect(function()
		if not activePrompt then return end

		
	    local progress = math.clamp(
			(os.clock() - startTime) / holdDuration,
			0,
			0.99
		)

		bar.Size = UDim2.fromScale(progress, 1)
		bar.BackgroundColor3 = colorFromProgress(progress)
		text.Text = math.floor(progress * 100) .. "%"
	end)
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function()
	stopBar()
end)

ProximityPromptService.PromptTriggered:Connect(function()
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	text.Text = "100%"
	task.wait(0.05)
	stopBar()
end)

ProximityPromptService.PromptHidden:Connect(function()
	stopBar()
end)

print("made by @ylzk on dc")
-- leaked by https://discord.gg/MT6BXdH9q

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local antiRagdollMode = nil
local ragdollConnections = {}
local cachedCharData = {}
local isBoosting = false 

-- Configuration
local BOOST_SPEED = 400 -- Extremely high speed boost
local DEFAULT_SPEED = 16

local function cacheCharacterData()
    local char = player.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return false end
    
    cachedCharData = {
        character = char,
        humanoid = hum,
        root = root
    }
    return true
end

local function disconnectAll()
    for _, conn in ipairs(ragdollConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollConnections = {}
end

local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    
    local ragdollStates = {
        [Enum.HumanoidStateType.Physics] = true,
        [Enum.HumanoidStateType.Ragdoll] = true,
        [Enum.HumanoidStateType.FallingDown] = true
    }
    
    if ragdollStates[state] then return true end
    
    local endTime = player:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then
        return true
    end
    
    return false
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    
    pcall(function()
        player:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
    end)
    
    -- Clear physics constraints locally
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint") or (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            descendant:Destroy()
        end
    end
    
    -- Apply the 400 speed boost
    if not isBoosting then
        isBoosting = true
        cachedCharData.humanoid.WalkSpeed = BOOST_SPEED
    end
    
    -- Force state back to running
    if cachedCharData.humanoid.Health > 0 then
        cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    cachedCharData.root.Anchored = false
end

local function v1HeartbeatLoop()
    while antiRagdollMode == "v1" do
        task.wait()
        
        local currentlyRagdolled = isRagdolled()
        
        if currentlyRagdolled then
            forceExitRagdoll()
        elseif isBoosting and not currentlyRagdolled then
            -- Reset to default speed once the stun/ragdoll ends
            isBoosting = false
            if cachedCharData.humanoid then
                cachedCharData.humanoid.WalkSpeed = DEFAULT_SPEED
            end
        end
    end
end

local function EnableAntiRagdoll()
    if antiRagdollMode == "v1" then return end
    if not cacheCharacterData() then return end
    
    antiRagdollMode = "v1"
    
    local camConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end)
    table.insert(ragdollConnections, camConn)
    
    local respawnConn = player.CharacterAdded:Connect(function()
        isBoosting = false 
        task.wait(0.5)
        cacheCharacterData()
    end)
    table.insert(ragdollConnections, respawnConn)

    task.spawn(v1HeartbeatLoop)
end

local function DisableAntiRagdoll()
    antiRagdollMode = nil
    if isBoosting and cachedCharData.humanoid then
        cachedCharData.humanoid.WalkSpeed = DEFAULT_SPEED
    end
    isBoosting = false
    disconnectAll()
    cachedCharData = {}
end

EnableAntiRagdoll()

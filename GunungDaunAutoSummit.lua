-- Mount Daun Auto Summit - Enhanced Teleport System
-- Modified by ZiaanFounder x IlhamHD
-- Enhanced with Player Movement Detection, Professional UI, and Improved Teleportation
-- Triple Loop Teleport System with Death Detection and Auto-Resume
-- Added Advanced Movement Routines: Circling, Forward/Backward Movement

if game.PlaceId == 102234703920418 then

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Daftar 5 lokasi teleport pertama
local teleportLocations = {
    Vector3.new(-622.5208129882812, 251.2251739501953, -382.360595703125),
    Vector3.new(-1202.83935546875, 262.5213928222656, -487.7074279785156),
    Vector3.new(-1399.1959228515625, 579.2965087890625, -949.181640625),
    Vector3.new(-1700.3348388671875, 816.13232421875, -1399.7440185546875),
    Vector3.new(-3229.90234375, 1714.6114501953125, -2593.095458984375)
}

-- Variabel untuk melacak progress dan status
local currentPhase = 1
local currentCycle = 1
local currentLocationIndex = 1
local isPlayerDead = false
local deathConnection = nil
local resumeAfterDeath = false
local hasCompletedFinalLoop = false -- Flag untuk menandai apakah loop terakhir telah selesai

-- Variabel untuk melacak gerakan pemain
local movementHistory = {}
local movementCheckInterval = 0.5
local lastPosition = nil
local isPlayerMoving = false
local movementThreshold = 2 -- Jarak minimum untuk dianggap bergerak

-- Variabel untuk bypass teleport
local teleportBypassEnabled = true
local networkOwnershipBypass = true

-- Fungsi untuk mendapatkan kepemilikan jaringan
local function setNetworkOwnership(part)
    if networkOwnershipBypass and part and part:IsA("BasePart") then
        pcall(function()
            part:SetNetworkOwner(nil)
        end)
    end
end

-- Fungsi untuk menyimpan progress saat ini
local function saveProgress(phase, cycle, locationIndex)
    currentPhase = phase
    currentCycle = cycle
    currentLocationIndex = locationIndex
end

-- Fungsi untuk membuat notifikasi profesional premium
local function createNotification(title, message, duration, notificationType)
    -- Hapus notifikasi sebelumnya jika ada
    if player.PlayerGui:FindFirstChild("TeleportNotification") then
        player.PlayerGui.TeleportNotification:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportNotification"
    screenGui.Parent = player.PlayerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false

    -- Container utama dengan efek glassmorphism premium
    local mainContainer = Instance.new("Frame")
    mainContainer.Size = UDim2.new(0, 450, 0, 160)
    mainContainer.Position = UDim2.new(0.5, -225, 0.1, 0)
    mainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainContainer.BackgroundTransparency = 0.15
    mainContainer.BorderSizePixel = 0
    
    -- Membuat sudut melengkung
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainContainer
    
    -- Efek glass premium dengan gradient
    local glassEffect = Instance.new("Frame")
    glassEffect.Size = UDim2.new(1, 0, 1, 0)
    glassEffect.BackgroundTransparency = 0.95
    glassEffect.BackgroundColor3 = Color3.fromRGB(150, 150, 200)
    glassEffect.BorderSizePixel = 0
    glassEffect.ZIndex = -1
    
    local glassCorner = Instance.new("UICorner")
    glassCorner.CornerRadius = UDim.new(0, 12)
    glassCorner.Parent = glassEffect
    glassEffect.Parent = mainContainer
    
    -- Border glow effect dengan animasi
    local glow = Instance.new("UIStroke")
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glow.Color = Color3.fromRGB(100, 100, 150)
    glow.Thickness = 2
    glow.Transparency = 0.7
    glow.Parent = mainContainer

    -- Animate glow
    spawn(function()
        while glow and glow.Parent do
            for i = 0, 1, 0.05 do
                if not glow then break end
                glow.Transparency = 0.3 + math.abs(math.sin(tick())) * 0.4
                wait(0.1)
            end
        end
    end)

    mainContainer.Parent = screenGui

    -- Header dengan gradient animasi
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 32)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BorderSizePixel = 0
    header.BackgroundTransparency = 1
    
    -- Tentukan warna header berdasarkan tipe notifikasi
    local gradientColor
    if notificationType == "success" then
        gradientColor = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 185, 90)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 145, 70))
        }
    elseif notificationType == "warning" then
        gradientColor = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 160, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 130, 40))
        }
    elseif notificationType == "error" then
        gradientColor = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 70, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 50, 50))
        }
    else -- info/default
        gradientColor = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 150, 220)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 120, 180))
        }
    end
    
    local uigradient = Instance.new("UIGradient")
    uigradient.Color = gradientColor
    uigradient.Rotation = -15
    uigradient.Parent = header
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    header.Parent = mainContainer

    -- Judul notifikasi
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextStrokeTransparency = 0.8
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Parent = header

    -- Icon berdasarkan tipe notifikasi
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 22, 0, 22)
    icon.Position = UDim2.new(1, -27, 0.5, -11)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    
    if notificationType == "success" then
        icon.Image = "rbxassetid://3926307971"
        icon.ImageRectOffset = Vector2.new(124, 204)
        icon.ImageRectSize = Vector2.new(36, 36)
    elseif notificationType == "warning" then
        icon.Image = "rbxassetid://3926307971"
        icon.ImageRectOffset = Vector2.new(524, 204)
        icon.ImageRectSize = Vector2.new(36, 36)
    elseif notificationType == "error" then
        icon.Image = "rbxassetid://3926307971"
        icon.ImageRectOffset = Vector2.new(924, 204)
        icon.ImageRectSize = Vector2.new(36, 36)
    else -- info/default
        icon.Image = "rbxassetid://3926307971"
        icon.ImageRectOffset = Vector2.new(324, 204)
        icon.ImageRectSize = Vector2.new(36, 36)
    end
    
    icon.Parent = header

    -- Isi pesan notifikasi
    local messageContainer = Instance.new("Frame")
    messageContainer.Size = UDim2.new(1, -20, 0, 75)
    messageContainer.Position = UDim2.new(0, 10, 0, 37)
    messageContainer.BackgroundTransparency = 1
    messageContainer.Parent = mainContainer

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, 0, 0.8, 0)
    messageLabel.Position = UDim2.new(0, 0, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 13
    messageLabel.LineHeight = 1.1
    messageLabel.Parent = messageContainer

    -- Progress bar container
    local progressContainer = Instance.new("Frame")
    progressContainer.Size = UDim2.new(1, -20, 0, 6)
    progressContainer.Position = UDim2.new(0, 10, 1, -25)
    progressContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    progressContainer.BorderSizePixel = 0
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progressContainer
    progressContainer.Parent = mainContainer

    -- Progress bar fill dengan gradient
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressBar.BorderSizePixel = 0
    
    local progressBarGradient = Instance.new("UIGradient")
    progressBarGradient.Color = gradientColor
    progressBarGradient.Rotation = 0
    progressBarGradient.Parent = progressBar
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(1, 0)
    progressBarCorner.Parent = progressBar
    
    progressBar.Parent = progressContainer

    -- Timer text
    local timerText = Instance.new("TextLabel")
    timerText.Size = UDim2.new(0, 40, 0, 16)
    timerText.Position = UDim2.new(1, -40, 0, -20)
    timerText.BackgroundTransparency = 1
    timerText.Text = duration .. "s"
    timerText.TextColor3 = Color3.fromRGB(180, 180, 180)
    timerText.Font = Enum.Font.GothamMedium
    timerText.TextSize = 11
    timerText.TextXAlignment = Enum.TextXAlignment.Right
    timerText.Parent = mainContainer

    -- Footer dengan informasi copyright
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -20, 0, 16)
    footer.Position = UDim2.new(0, 10, 1, -16)
    footer.BackgroundTransparency = 1
    footer.Text = "© ZiaanFounder x IlhamHD | Mount Daun Auto Summit | Discord .gg/zjSYu3YnCU"
    footer.TextColor3 = Color3.fromRGB(150, 150, 150)
    footer.TextWrapped = true
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 9
    footer.Parent = mainContainer

    -- Animasi masuk (slide dari atas dengan bounce)
    mainContainer.Position = UDim2.new(0.5, -225, 0, -200)
    local tweenIn = TweenService:Create(
        mainContainer,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
        {Position = UDim2.new(0.5, -225, 0.1, 0)}
    )
    tweenIn:Play()

    -- Animasi progress bar dan timer
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local remaining = math.max(0, duration - elapsed)
        
        -- Update progress bar
        local progress = elapsed / duration
        progressBar.Size = UDim2.new(progress, 0, 1, 0)
        
        -- Update timer text
        timerText.Text = string.format("%.1fs", remaining)
        
        if elapsed >= duration then
            connection:Disconnect()
        end
    end)

    -- Animasi keluar setelah durasi
    task.delay(duration, function()
        if not screenGui or not screenGui.Parent then return end
        
        local tweenOut = TweenService:Create(
            mainContainer,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -225, 0, -200)}
        )
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
        end)
    end)
    
    return screenGui
end

-- Fungsi untuk memastikan karakter siap
local function ensureCharacter()
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    local character = player.Character
    if not character:FindFirstChild("HumanoidRootPart") then
        repeat wait() until character:FindFirstChild("HumanoidRootPart")
    end
    
    if not character:FindFirstChild("Humanoid") then
        repeat wait() until character:FindFirstChild("Humanoid")
    end
    
    return character
end

-- Fungsi untuk mendapatkan posisi tanah di bawah titik tertentu
local function findGroundPosition(position)
    local rayOrigin = position + Vector3.new(0, 100, 0)  -- Naik lebih tinggi untuk memastikan
    local rayDirection = Vector3.new(0, -200, 0)  -- Raycast lebih jauh
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult then
        return raycastResult.Position + Vector3.new(0, 3, 0)  -- Naik sedikit di atas tanah
    end
    
    return position  -- Fallback ke posisi asli
end

-- Fungsi untuk membuat efek getar yang lebih halus
local function shakeCharacter(duration, intensity)
    local character = ensureCharacter()
    local hrp = character.HumanoidRootPart
    
    local startTime = os.clock()
    local originalPosition = hrp.Position
    
    while os.clock() - startTime < duration do
        local progress = (os.clock() - startTime) / duration
        local currentIntensity = intensity * (1 - progress)  -- Kurangi intensitas seiring waktu
        
        -- Buat offset yang lebih kecil dan halus
        local offset = Vector3.new(
            (math.random() - 0.5) * currentIntensity * 0.3,  -- Dikurangi intensitasnya
            0,
            (math.random() - 0.5) * currentIntensity * 0.3   -- Dikurangi intensitasnya
        )
        
        hrp.CFrame = CFrame.new(originalPosition + offset)
        RunService.Heartbeat:Wait()
    end
    
    -- Kembali ke posisi semula
    hrp.CFrame = CFrame.new(originalPosition)
end

-- Fungsi untuk membuat avatar bergerak-gerak di tempat dengan lebih halus
local function animateCharacterAtLocation(duration)
    local character = ensureCharacter()
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Simpan state awal
    local originalWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0  -- Set walk speed ke 0 agar tidak bisa bergerak
    
    local startTime = os.clock()
    local originalPosition = hrp.Position
    
    -- Animasi: 3 detik bergerak-gerak/getar di tempat dengan intensitas rendah
    createNotification("Area Scanning", "Analyzing environment for optimal path...", 3, "info")
    
    while os.clock() - startTime < 3 do
        -- Gerakan kecil acak yang lebih halus
        local offset = Vector3.new(
            (math.random() - 0.5) * 0.5,  -- Intensitas dikurangi
            0,
            (math.random() - 0.5) * 0.5   -- Intensitas dikurangi
        )
        
        -- Terapkan gerakan kecil
        hrp.CFrame = CFrame.new(originalPosition + offset)
        RunService.Heartbeat:Wait()
    end
    
    -- Animasi: 2 detik diam
    createNotification("Processing Data", "Calculating next optimal route...", 2, "info")
    wait(2)
    
    -- Animasi: 10 satu kali (opsional, bisa dihapus jika tidak perlu)
    createNotification("Energy Boost", "Preparing momentum for next location...", 1, "info")
    humanoid.Jump = true
    wait(0.5)
    
    -- Kembalikan walk speed
    humanoid.WalkSpeed = originalWalkSpeed
end

-- Fungsi untuk mendeteksi gerakan pemain
local function trackPlayerMovement()
    local character = player.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Simpan posisi saat ini
    local currentPosition = hrp.Position
    
    -- Bandingkan dengan posisi terakhir
    if lastPosition then
        local distance = (currentPosition - lastPosition).Magnitude
        
        -- Catat gerakan dalam history
        table.insert(movementHistory, 1, {
            position = currentPosition,
            distance = distance,
            time = os.clock()
        })
        
        -- Hapus data yang terlalu lama (hanya simpan 10 detik terakhir)
        while #movementHistory > 0 and os.clock() - movementHistory[#movementHistory].time > 10 do
            table.remove(movementHistory, #movementHistory)
        end
        
        -- Tentukan apakah pemain sedang bergerak
        isPlayerMoving = distance > movementThreshold
    end
    
    -- Update posisi terakhir
    lastPosition = currentPosition
    
    return isPlayerMoving
end

-- Fungsi untuk mendapatkan arah gerakan pemain
local function getMovementDirection()
    if #movementHistory < 2 then return Vector3.new(0, 0, 0) end
    
    local recentMovement = movementHistory[1]
    local previousMovement = movementHistory[2]
    
    local direction = (recentMovement.position - previousMovement.position).Unit
    return direction
end

-- Fungsi untuk memeriksa apakah pemain sedang bergerak menuju suatu lokasi
local function isMovingTowardLocation(targetLocation)
    local character = player.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or #movementHistory < 2 then return false end
    
    local currentPosition = hrp.Position
    local directionToTarget = (targetLocation - currentPosition).Unit
    local movementDirection = getMovementDirection()
    
    -- Hitung dot product untuk menentukan kesamaan arah
    local dotProduct = directionToTarget:Dot(movementDirection)
    
    -- Jika dot product > 0.7, artinya pemain bergerak ke arah target
    return dotProduct > 0.7
end

-- Fungsi untuk menghitung jarak ke lokasi target
local function getDistanceToLocation(targetLocation)
    local character = player.Character
    if not character then return math.huge end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end
    
    return (hrp.Position - targetLocation).Magnitude
end

-- Fungsi bypass teleport tingkat tinggi
local function advancedTeleport(position)
    local character = ensureCharacter()
    local hrp = character.HumanoidRootPart
    local humanoid = character.Humanoid
    
    -- Cari posisi tanah yang tepat
    local groundPosition = findGroundPosition(position)
    
    -- Aktifkan bypass teleport jika diaktifkan
    if teleportBypassEnabled then
        -- Method 1: Gunakan CFrame dengan set network ownership
        setNetworkOwnership(hrp)
        
        -- Method 2: Gunakan TweenService untuk gerakan halus
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(groundPosition)})
        tween:Play()
        
        -- Tunggu hingga tween selesai
        wait(0.5)
        
        -- Method 3: Pastikan posisi akhir tepat
        setNetworkOwnership(hrp)
        hrp.CFrame = CFrame.new(groundPosition)
        
        -- Method 4: Gunakan Velocity untuk menstabilkan
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        return true
    else
        -- Teleport biasa (fallback)
        hrp.CFrame = CFrame.new(groundPosition)
        return true
    end
end

-- Fungsi untuk membuat karakter berjalan memutar (muter) tiga kali dengan radius lebih kecil
local function circleMovement()
    local character = ensureCharacter()
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    local originalPosition = hrp.Position
    local originalWalkSpeed = humanoid.WalkSpeed
    
    -- Set walk speed untuk pergerakan yang terkontrol
    humanoid.WalkSpeed = 12
    
    createNotification("Movement Routine", "Performing circling movement (3 rounds)...", 5, "info")
    
    -- Radius lingkaran diperkecil dari 8 menjadi 4
    local radius = 4
    local center = originalPosition
    
    -- Lakukan 3 putaran
    for circle = 1, 3 do
        if isPlayerDead then break end
        
        createNotification("Circling", "Round " .. circle .. "/3", 1.5, "info")
        
        -- Hitung titik-titik di lingkaran
        local points = {}
        for i = 1, 24 do -- 24 titik untuk lingkaran halus (15 derajat per langkah)
            local angle = math.rad(i * 15)
            local x = center.X + radius * math.cos(angle)
            local z = center.Z + radius * math.sin(angle)
            table.insert(points, Vector3.new(x, center.Y, z))
        end
        
        -- Gerakkan karakter melalui titik-titik
        for _, point in ipairs(points) do
            if isPlayerDead then break end
            
            humanoid:MoveTo(point)
            
            -- Tunggu sampai karakter mendekati titik atau timeout
            local startTime = os.clock()
            while (hrp.Position - point).Magnitude > 2 and os.clock() - startTime < 0.8 do
                wait(0.1)
                if isPlayerDead then break end
            end
            
            if isPlayerDead then break end
        end
        
        if isPlayerDead then break end
    end
    
    -- Kembalikan ke walk speed semula
    humanoid.WalkSpeed = originalWalkSpeed
    
    -- Pastikan kembali ke posisi semula
    humanoid:MoveTo(originalPosition)
    wait(0.5)
end

-- Fungsi untuk membuat karakter jalan maju mundur dengan jarak lebih pendek
local function forwardBackwardMovement()
    local character = ensureCharacter()
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    local originalPosition = hrp.Position
    local originalWalkSpeed = humanoid.WalkSpeed
    
    -- Set walk speed untuk pergerakan yang terkontrol
    humanoid.WalkSpeed = 12
    
    createNotification("Movement Routine", "Performing forward/backward movement (2 passes)...", 4, "info")
    
    -- Tentukan arah hadap karakter
    local lookDirection = hrp.CFrame.LookVector
    lookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
    
    -- Jarak maju mundur diperpendek dari 12 menjadi 6
    local distance = 6
    
    -- Lakukan 2 kali maju mundur
    for pass = 1, 2 do
        if isPlayerDead then break end
        
        createNotification("Forward/Backward", "Pass " .. pass .. "/2", 1, "info")
        
        -- Posisi maju
        local forwardPosition = originalPosition + (lookDirection * distance)
        
        -- Maju
        humanoid:MoveTo(forwardPosition)
        
        -- Tunggu sampai karakter sampai di posisi maju atau timeout
        local startTime = os.clock()
        while (hrp.Position - forwardPosition).Magnitude > 2 and os.clock() - startTime < 1.5 do
            wait(0.1)
            if isPlayerDead then break end
        end
        
        if isPlayerDead then break end
        
        -- Mundur
        humanoid:MoveTo(originalPosition)
        
        -- Tunggu sampai karakter kembali ke posisi awal atau timeout
        startTime = os.clock()
        while (hrp.Position - originalPosition).Magnitude > 2 and os.clock() - startTime < 1.5 do
            wait(0.1)
            if isPlayerDead then break end
        end
        
        if isPlayerDead then break end
    end
    
    -- Kembalikan ke walk speed semula
    humanoid.WalkSpeed = originalWalkSpeed
    
    -- Pastikan kembali ke posisi semula
    humanoid:MoveTo(originalPosition)
    wait(0.5)
end

-- Fungsi untuk melakukan rutinitas gerakan khusus setelah tiba di lokasi
local function performMovementRoutine()
    if isPlayerDead then return end
    
    createNotification("Movement Sequence", "Starting special movement routine...", 2, "info")
    wait(1)
    
    -- 1. Berjalan memutar (muter) tiga kali
    circleMovement()
    if isPlayerDead then return end
    
    wait(0.5)
    
    -- 2. Jalan maju mundur melewati checkpoint 2 kali
    forwardBackwardMovement()
    if isPlayerDead then return end
    
    wait(0.5)
    
    -- 3. Efek getar (shaking)
    createNotification("Stabilizing", "Finalizing position with vibration...", 1.5, "info")
    shakeCharacter(1.5, 1.2)
    
    createNotification("Routine Complete", "Special movement sequence finished", 2, "success")
end

-- Fungsi untuk teleport dengan gerakan natural dan ground detection
local function adaptiveTeleport(position)
    local character = ensureCharacter()
    local hrp = character.HumanoidRootPart
    local humanoid = character.Humanoid
    
    -- Cari posisi tanah yang tepat
    local groundPosition = findGroundPosition(position)
    
    -- Periksa apakah pemain sudah dekat dengan lokasi target
    local distanceToTarget = getDistanceToLocation(groundPosition)
    if distanceToTarget < 20 then
        createNotification("Approaching Destination", "You are close to the target location.", 2, "info")
        
        -- Jika sudah dekat, biarkan pemain berjalan sendiri
        local checkInterval = 0.5
        local maxWaitTime = 10  -- Maksimal 10 detik menunggu
        
        for i = 1, maxWaitTime / checkInterval do
            if isPlayerDead then return false end
            
            local newDistance = getDistanceToLocation(groundPosition)
            
            if newDistance < 5 then
                createNotification("Destination Reached", "You have arrived at the target location.", 2, "success")
                return true
            end
            
            -- Berikan petunjuk arah jika pemain tidak menuju ke lokasi
            if not isMovingTowardLocation(groundPosition) then
                createNotification("Navigation Hint", "Head toward the marked location to complete the journey.", 2, "info")
            end
            
            wait(checkInterval)
        end
        
        -- Jika waktu tunggu habis, teleportasi ke lokasi
        createNotification("Auto-Assist Activated", "Teleporting to exact destination...", 1, "warning")
    end
    
    -- Efek shake yang lebih halus sebelum teleport
    createNotification("Teleport Preparation", "Stabilizing coordinates...", 0.5, "info")
    shakeCharacter(0.5, 0.8)  -- Durasi dan intensitas dikurangi
    
    -- Pastikan karakter tidak bergerak selama teleport
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    wait(0.1)
    
    -- Gunakan advanced teleport untuk bypass
    advancedTeleport(groundPosition)
    
    -- Tunggu sebentar setelah teleport untuk stabilisasi
    wait(0.2)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    
    -- Pastikan karakter benar-benar menyentuh tanah
    wait(0.3)
    if hrp.Position.Y > groundPosition.Y + 5 then
        -- Jika masih di udara, turunkan ke tanah
        hrp.CFrame = CFrame.new(groundPosition)
    end
    
    -- Jalankan rutinitas gerakan khusus setelah tiba di lokasi
    performMovementRoutine()
    
    return true
end

-- Fungsi untuk respawn karakter
local function respawnCharacter()
    createNotification("Respawn Initiated", "Preparing for character reset...", 1.5, "warning")
    
    -- Method 1: Panggil fungsi respawn melalui Humanoid
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end
    
    -- Tunggu karakter mati dan respawn
    wait(2)
    
    -- Method 2: Jika method 1 tidak bekerja, gunakan method alternatif
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        player.Character:BreakJoints()
    end
    
    -- Tunggu karakter respawn
    ensureCharacter()
    createNotification("Respawn Complete", "Character has been successfully reset", 2, "success")
end

-- Fungsi untuk memeriksa apakah lokasi aman untuk teleport
local function isLocationSafe(position)
    -- Periksa apakah ada part di sekitar posisi
    local region = Region3.new(position - Vector3.new(5, 5, 5), position + Vector3.new(5, 5, 5))
    local parts = workspace:FindPartsInRegion3(region, nil, 10)
    
    return #parts > 0  -- Jika ada part, lokasi dianggap aman
end

-- Fungsi untuk memulai pelacakan gerakan pemain
local function startMovementTracking()
    spawn(function()
        while true do
            trackPlayerMovement()
            wait(movementCheckInterval)
        end
    end)
end

-- Modifikasi fungsi setupDeathDetection untuk menangani kasus setelah selesai
local function setupDeathDetection()
    -- Hapus koneksi lama jika ada
    if deathConnection then
        deathConnection:Disconnect()
        deathConnection = nil
    end
    
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    
    if humanoid then
        deathConnection = humanoid.Died:Connect(function()
            -- Jangan lanjutkan jika loop terakhir sudah selesai
            if hasCompletedFinalLoop then
                createNotification("Journey Completed", "Your journey has already been completed. No auto-resume will be triggered.", 5, "info")
                return
            end
            
            isPlayerDead = true
            createNotification("Character Died", "Resuming operation after respawn...", 3, "warning")
            
            -- Tunggu hingga karakter respawn
            ensureCharacter()
            
            -- Set flag untuk melanjutkan dari titik terakhir
            resumeAfterDeath = true
            isPlayerDead = false
            
            -- Lanjutkan proses teleportasi
            createNotification("Resuming Process", "Continuing from last checkpoint...", 2, "info")
        end)
    end
end

-- Fungsi untuk melakukan satu siklus teleport ke lokasi tertentu
local function teleportToLocation(locationIndex, cycle, phase)
    if isPlayerDead then return false end
    
    createNotification("Cycle "..cycle.." - Navigating to Point "..locationIndex.."/5", 
        "Moving to Location "..locationIndex.." in Phase "..phase.."...", 2, "info")
    
    if adaptiveTeleport(teleportLocations[locationIndex]) then
        createNotification("Location Reached", "Successfully arrived at checkpoint "..locationIndex, 1.5, "success")
        wait(1.5)
        return true
    end
    
    return false
end

-- Fungsi teleport dengan triple loop sequence dengan sistem resume yang diperbaiki
local function tripleLoopTeleportSequence()
    -- Setup deteksi kematian
    setupDeathDetection()

    -- Phase 1: Triple Loop antara Lokasi 1 dan 2
    if currentPhase == 1 then
        createNotification("Phase 1: Triple Loop 1-2", 
            "Starting first triple loop between Location 1 and 2...", 
            2, "info")
        
        for cycle = currentCycle, 3 do
            if isPlayerDead then
                saveProgress(1, cycle, 1)
                return -- Keluar dari fungsi, akan dilanjutkan setelah respawn
            end
            
            -- Lokasi 1
            if not teleportToLocation(1, cycle, 1) then
                saveProgress(1, cycle, 1)
                return
            end
            
            if isPlayerDead then
                saveProgress(1, cycle, 2)
                return
            end
            
            -- Lokasi 2
            if not teleportToLocation(2, cycle, 1) then
                saveProgress(1, cycle, 2)
                return
            end
            
            -- Simpan progress setelah setiap cycle selesai
            saveProgress(1, cycle + 1, 1)
        end
        
        currentPhase = 2
        currentCycle = 1
        currentLocationIndex = 1
    end
    
    -- Phase 2: Triple Loop antara Lokasi 2 dan 3
    if currentPhase == 2 then
        createNotification("Phase 2: Triple Loop 2-3", 
            "Starting second triple loop between Location 2 and 3...", 
            2, "info")
        
        for cycle = currentCycle, 3 do
            if isPlayerDead then
                saveProgress(2, cycle, 3)
                return
            end
            
            -- Lokasi 3
            if not teleportToLocation(3, cycle, 2) then
                saveProgress(2, cycle, 3)
                return
            end
            
            if isPlayerDead then
                saveProgress(2, cycle, 2)
                return
            end
            
            -- Kembali ke Lokasi 2 (kecuali cycle terakhir)
            if cycle < 3 then
                if not teleportToLocation(2, cycle, 2) then
                    saveProgress(2, cycle, 2)
                    return
                end
            end
            
            -- Simpan progress setelah setiap cycle selesai
            saveProgress(2, cycle + 1, 3)
        end
        
        currentPhase = 3
        currentCycle = 1
        currentLocationIndex = 1
    end
    
    -- Phase 3: Triple Loop antara Lokasi 3 dan 4
    if currentPhase == 3 then
        createNotification("Phase 3: Triple Loop 3-4", 
            "Starting third triple loop between Location 3 and 4...", 
            2, "info")
        
        for cycle = currentCycle, 3 do
            if isPlayerDead then
                saveProgress(3, cycle, 4)
                return
            end
            
            -- Lokasi 4
            if not teleportToLocation(4, cycle, 3) then
                saveProgress(3, cycle, 4)
                return
            end
            
            if isPlayerDead then
                saveProgress(3, cycle, 3)
                return
            end
            
            -- Kembali ke Lokasi 3 (kecuali cycle terakhir)
            if cycle < 3 then
                if not teleportToLocation(3, cycle, 3) then
                    saveProgress(3, cycle, 3)
                    return
                end
            end
            
            -- Simpan progress setelah setiap cycle selesai
            saveProgress(3, cycle + 1, 4)
        end
        
        currentPhase = 4
        currentCycle = 1
        currentLocationIndex = 1
    end
    
    -- Phase 4: Triple Loop antara Lokasi 4 dan 5 (FINAL PHASE)
    if currentPhase == 4 then
        createNotification("Phase 4: Final Triple Loop 4-5", 
            "Starting final triple loop between Location 4 and 5...", 
            2, "info")
        
        for cycle = currentCycle, 3 do
            if isPlayerDead then
                saveProgress(4, cycle, 5)
                return
            end
            
            -- Lokasi 5
            if not teleportToLocation(5, cycle, 4) then
                saveProgress(4, cycle, 5)
                return
            end
            
            if isPlayerDead then
                saveProgress(4, cycle, 4)
                return
            end
            
            -- Kembali ke Lokasi 4 (hanya jika bukan cycle terakhir)
            if cycle < 3 then
                if not teleportToLocation(4, cycle, 4) then
                    saveProgress(4, cycle, 4)
                    return
                end
            end
            
            -- Simpan progress setelah setiap cycle selesai
            saveProgress(4, cycle + 1, 5)
        end
        
        -- Set flag bahwa loop terakhir telah selesai
        hasCompletedFinalLoop = true

        -- Notifikasi akhir dan respawn
        createNotification("Mission Complete!", 
            "All triple loop checkpoints have been successfully completed.\nMovement analysis complete.\nInitiating automatic respawn sequence...", 
            3, "success")
        wait(3)
        
        -- Reset progress setelah menyelesaikan semua
        currentPhase = 1
        currentCycle = 1
        currentLocationIndex = 1
        
        respawnCharacter()
    end
end

-- Fungsi utama untuk menjalankan script dengan sistem resume
local function main()
    -- Tunggu hingga game siap
    createNotification("System Booting", "Mount Daun Auto Summit initializing...\nTriple Loop System starting...\nAdvanced Bypass Enabled...", 2, "info")
    wait(2)
    
    -- Setup deteksi kematian awal
    setupDeathDetection()
    
    -- Mulai melacak gerakan pemain
    startMovementTracking()
    
    -- Jalankan script dengan triple loop sequence
    while true do
        tripleLoopTeleportSequence()
        
        -- Jika loop terakhir telah selesai, keluar dari loop
        if hasCompletedFinalLoop then
            createNotification("Journey Completed", "Thank you for using Mount Daun Auto Summit!\nScript will not restart automatically.", 5, "info")
            break
        end
        
        -- Jika mati, tunggu hingga respawn dan lanjutkan
        if resumeAfterDeath then
            resumeAfterDeath = false
            createNotification("Resuming Progress", 
                "Continuing from Phase "..currentPhase..", Cycle "..currentCycle..", Location "..currentLocationIndex, 
                3, "info")
            wait(3)
        else
            break -- Keluar dari loop jika tidak perlu resume
        end
    end
end

-- Jalankan fungsi utama
main()

end

local fov_max = 70.0
local fov_min = 5.0 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 10.0 -- camera zoom speed
local speed_lr = 8.0 -- speed by which the camera pans left-right
local speed_ud = 8.0 -- speed by which the camera pans up-down
-- Add these global variables at the top of your script
local cam, scaleform
local binoculars = false
local rangefinderEnabled = false
local enableFunctions = true
local binocularsActive = false
local fov = (fov_max + fov_min) * 0.5
local keybindEnabled = true

RegisterNetEvent('binoculars:Activate')
AddEventHandler('binoculars:Activate', function()
    binocularsActive = not binocularsActive
    if binocularsActive then
        StartBinoculars()
    else
        StopBinoculars()
    end
end)

function DrawTextOnScreen(text)
    if enableFunctions and binoculars then
        local font = 0
        local scale = 0.4
        local x, y = 0.5, 0.9

        SetTextFont(font)
        SetTextScale(scale, scale)
        SetTextWrap(0.0, 1.0)
        SetTextCentre(true)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

function DrawTextAtTop(text)
    if enableFunctions and binoculars then
        local font = 0
        local scale = 0.4
        local x, y = 0.5, 0.02

        SetTextFont(font)
        SetTextScale(scale, scale)
        SetTextWrap(0.0, 1.0)
        SetTextCentre(true)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x, y)
    end
end


function StartBinoculars()
    if enableFunctions then
        binoculars = true
        local lPed = GetPlayerPed(-1)

        if not (IsPedSittingInAnyVehicle(lPed)) then
            Citizen.CreateThread(function()
                TaskStartScenarioInPlace(lPed, "WORLD_HUMAN_BINOCULARS", 0, 1)
                PlayAmbientSpeech1(lPed, "GENERIC_CURSE_MED", "SPEECH_PARAMS_FORCE")
            end)
        end

        Wait(30)

        SetTimecycleModifier("default")
        SetTimecycleModifierStrength(0.3)
        scaleform = RequestScaleformMovie("BINOCULARS")

        while not HasScaleformMovieLoaded(scaleform) do
            Citizen.Wait(10)
        end

        cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
        AttachCamToEntity(cam, lPed, 0.0, 0.0, 1.0, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(lPed))
        SetCamFov(cam, fov)
        RenderScriptCams(true, false, 0, 1, 0)
        PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
        PushScaleformMovieFunctionParameterInt(0)
        PopScaleformMovieFunctionVoid()

        while binoculars and not IsEntityDead(lPed) do
            if IsControlJustPressed(0, storeBinoclarKey) or rightClickPressed then
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                ClearPedTasks(lPed)
                binoculars = false
                rightClickPressed = false
            end
            local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
            CheckInputRotation(cam, zoomvalue)
            HandleZoom(cam)
            HideHUDThisFrame()
			-- Inside the binoculars loop
			DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
			Set_2dLayer(4) -- Set the drawing layer to TOP level
			Citizen.Wait(0)

        end

        binoculars = false
        ClearTimecycleModifier()
        fov = (fov_max + fov_min) * 0.5
        RenderScriptCams(false, false, 0, 1, 0)
        SetScaleformMovieAsNoLongerNeeded(scaleform)
        DestroyCam(cam, true)
        SetNightvision(false)
        SetSeethrough(false)

        -- Re-enable controls here
        ClearPedTasks(lPed)
    end
end

function StartRayCasting()
    if enableFunctions then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(10)

                local lPed = GetPlayerPed(-1)

                if binoculars or rangefinderEnabled then
                    local coords = GetCamCoord(cam)
                    local rotation = GetCamRot(cam, 2)

                    local forwardVectorX = math.sin(math.rad(-rotation.z)) * math.abs(math.cos(math.rad(rotation.x)))
                    local forwardVectorY = math.cos(math.rad(-rotation.z)) * math.abs(math.cos(math.rad(rotation.x)))
                    local forwardVectorZ = math.sin(math.rad(rotation.x))
                    local forwardVector = vector3(forwardVectorX, forwardVectorY, forwardVectorZ)

                    local endCoords = vector3(
                        coords.x + forwardVector.x * 1000.0,
                        coords.y + forwardVector.y * 1000.0,
                        coords.z + forwardVector.z * 1000.0
                    )

                    local rayHandle = StartShapeTestRay(
                        coords.x, coords.y, coords.z,
                        endCoords.x, endCoords.y, endCoords.z,
                        -1, lPed, 0
                    )
                    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)

                    if hit then
                        local distance = math.floor(GetDistanceBetweenCoords(hitCoords.x, hitCoords.y, hitCoords.z, coords.x, coords.y, coords.z))
                        DrawTextOnScreen("Distance: " .. distance .. " meters")
                        local direction = vector3(hitCoords.x - coords.x, hitCoords.y - coords.y, 0)
                        local heading = math.deg(math.atan2(direction.y, direction.x)) + 90

                        if heading < 0 then
                            heading = heading + 360
                        end

                        heading = (heading + 180) % 360

                        -- Adjusted calculation of compass direction
                        local directions = {"N", "NW", "W", "SW", "S", "SE", "E", "NE"}
                        local index = math.floor((heading + 22.5) / 45) % 8 + 1
                        local compassDirection = directions[index]

                        -- Check if compassDirection is not nil before using it
                        if compassDirection then
                            DrawTextAtTop("Heading: " .. compassDirection)
                        else
                            DrawTextAtTop("Heading: Unknown")
                        end

                        if Config.markerUse then
                            DrawMarker(
                                Config.markerType,
                                hitCoords.x,
                                hitCoords.y,
                                hitCoords.z,
                                0,
                                0,
                                0,
                                0,
                                0,
                                -rotation.z,
                                Config.markerSize.x,
                                Config.markerSize.y,
                                Config.markerSize.z,
                                Config.markerColor[1],
                                Config.markerColor[2],
                                Config.markerColor[3],
                                Config.markerColor[4],
                                false,
                                false,
                                2,
                                false,
                                nil,
                                nil,
                                false
                            )
                        end
                    else
                        DrawTextOnScreen("No target")
                    end
                end
            end
        end)
    end
end

-- Add this helper function to convert rotation angles to a vector
function RotAnglesToVec(x, y, z)
    local rx = math.rad(x)
    local ry = math.rad(y)
    local rz = math.rad(z)

    local sx = math.sin(rx)
    local cx = math.cos(rx)
    local sy = math.sin(ry)
    local cy = math.cos(ry)
    local sz = math.sin(rz)
    local cz = math.cos(rz)

    local x = sx * sy * cz + cx * sz
    local y = sx * sy * sz - cx * cz
    local z = cx * sy

    return vector3(x, y, z)
end

--FUNCTIONS--
function HideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(1) -- Wanted Stars
    HideHudComponentThisFrame(2) -- Weapon icon
    HideHudComponentThisFrame(3) -- Cash
    HideHudComponentThisFrame(4) -- MP CASH
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(13) -- Cash Change
    HideHudComponentThisFrame(11) -- Floating Help Text
    HideHudComponentThisFrame(12) -- more floating help text
    HideHudComponentThisFrame(15) -- Subtitle Text
    HideHudComponentThisFrame(18) -- Game Stream
    HideHudComponentThisFrame(19) -- weapon wheel
end

function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * (speed_ud) * (zoomvalue + 0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * (speed_lr) * (zoomvalue + 0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
    end
end

function HandleZoom(cam)
    local lPed = GetPlayerPed(-1)
    if not IsPedSittingInAnyVehicle(lPed) then
        if IsControlJustPressed(0, 241) then -- Scrollup
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0, 242) then
            fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov - current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
    else
        if IsControlJustPressed(0, 17) then -- Scrollup
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0, 16) then
            fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov - current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
    end
end


--EVENTS--
RegisterNetEvent('binoculars:Activate')
AddEventHandler('binoculars:Activate', function()
    binoculars = not binoculars
end)

function StopBinoculars()
    local lPed = GetPlayerPed(-1)

    -- Re-enable controls here
    DisableControlAction(0, 22, false) -- Jump
    DisableControlAction(0, 36, false) -- Enter Vehicle

    if IsPedSittingInAnyVehicle(lPed) then
        DisableControlAction(0, 71, false) -- Accelerate (W)
        DisableControlAction(0, 72, false) -- Brake/Reverse (S)
        DisableControlAction(0, 75, false) -- Handbrake (Space)
    end

    binocularsActive = false
    rangefinderEnabled = false

    ClearTimecycleModifier()
    fov = (fov_max + fov_min) * 0.5
    RenderScriptCams(false, false, 0, 1, 0)
    SetScaleformMovieAsNoLongerNeeded(scaleform)
    DestroyCam(cam, false)
    SetNightvision(false)
    SetSeethrough(false)
    rangefinderEnabled = false -- Add this line to disable rangefinder

    -- Re-enable controls here
    ClearPedTasks(lPed)

    -- Show HUD components that were hidden
    for i = 1, 19 do
        ShowHudComponentThisFrame(i)
    end

    -- Remove any drawn text
	binoculars = false
	rangefinderEnabled = false
	enableFunctions = true
	binocularsActive = false
end


--EVENTS--
RegisterNetEvent('binoculars:Activate')
AddEventHandler('binoculars:Activate', function()
    binoculars = not binoculars
end)

RegisterNetEvent('rangefinder:Activate')
AddEventHandler('rangefinder:Activate', function()
    rangefinderEnabled = not rangefinderEnabled
end)

RegisterCommand("startbinoculars", function()
    StartBinoculars()
end)

RegisterCommand("stopbinoculars", function()
    StopBinoculars()
end)

StartRayCasting()
-- Binoculars item for inventory integration
exports("binoculars", function(data, slot)
    local playerPed = PlayerPedId()
    local binocularsActive = false

    -- Function to start the binoculars effect
    local function startBinoculars()
        -- Your binoculars activation logic goes here
        -- Example: StartBinoculars()
        StartBinoculars()
    end

    -- Function to stop the binoculars effect
    local function stopBinoculars()
        -- Your binoculars deactivation logic goes here
        -- Example: StopBinoculars()
        StopBinoculars()
        binocularsActive = false
    end

    -- Event listener for "ESC" key press
    Citizen.CreateThread(function()
        while binocularsActive do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 27) then  -- 27 is the code for "ESC" key
                stopBinoculars()
            end
        end
    end)

    -- Trigger binoculars effect and use the item
    startBinoculars()
    if data then exports.ox_inventory:useItem(data) end
    binocularsActive = true

    -- Optional: Return a value indicating the success of using binoculars
    return binocularsActive
end)

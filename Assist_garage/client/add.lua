local ResourceName = GetCurrentResourceName()
local ESX = exports['es_extended']:getSharedObject()
local allowedDimensions = Config.DimensionsAllow -- มิติที่ต้องการเช็ค

local locationIndex = {}
local locationPropspawn = {}
for id = 1, #Config.garageDetail do
    if Config.garageDetail[id].location then
        locationIndex[id] = Config.garageDetail[id].location
        locationPropspawn[id] = Config.garageDetail[id].Propspawn
    else
        locationIndex[id] = false
    end
    -- print(ESX.DumpTable(locationIndex))
end

local poundDetailIndex = {}
local poundPropspawn = {}
for id = 1, #Config.poundDetail do
    if Config.poundDetail[id].location then
        poundDetailIndex[id] = Config.poundDetail[id].location
        poundPropspawn[id] = Config.poundDetail[id].Propspawn
    else
        poundDetailIndex[id] = false
    end
end

local deletelocationDetailIndex = {}
local deletelocationPropspawn = {}
for id = 1, #Config.garageDetail do
    if Config.garageDetail[id].deletelocation then
        deletelocationDetailIndex[id] = Config.garageDetail[id].deletelocation
        deletelocationPropspawn[id] = Config.garageDetail[id].Propdelete
    else
        deletelocationDetailIndex[id] = false
    end
end

local DepositlocationDetailIndex = {}
for id = 1, #Config.depositvehicle do
    if Config.depositvehicle[id].location then
        DepositlocationDetailIndex[id] = Config.depositvehicle[id].location
    else
        DepositlocationDetailIndex[id] = false
    end
end

-- หา deposit ที่ใกล้สุดจาก coords แล้วอัปเดต active ตาม bool
function SetActiveDepositVehicle(coords, bool)
    if not coords then
        dprint("[Deposit] ❌ coords เป็น nil")
        return nil
    end

    local nearestIdx, nearestDist = nil, math.huge
    for i, data in ipairs(Config.depositvehicle or {}) do
        local loc = data.location
        if loc then
            local dist = #(coords - loc)
            if dist < nearestDist then
                nearestDist = dist
                nearestIdx  = i
            end
        end
    end

    if not nearestIdx then
        dprint("[Deposit] ❌ ไม่พบจุดฝากใน Config.depositvehicle")
        return nil
    end

    local label = Config.depositvehicle[nearestIdx].Label or ("Deposit_"..nearestIdx)
    local old   = Config.depositvehicle[nearestIdx].active
    Config.depositvehicle[nearestIdx].active = not not bool

    dprint(("[Deposit] %s (idx=%d) → active %s -> %s (dist=%.2fm)")
        :format(label, nearestIdx, tostring(old), tostring(Config.depositvehicle[nearestIdx].active), nearestDist))

    return nearestIdx, label, Config.depositvehicle[nearestIdx].active, nearestDist
end
exports("SetActiveDepositVehicle", SetActiveDepositVehicle)

-- หา "deposit garage" ใกล้ที่สุด + นับจำนวนรถที่ฝากไว้ในจุดนั้น (อิง Mystored.v.deposit)
function GetNearestDepositInfo(coords)
    local nearestIdx, nearestLabel, nearestDist = nil, nil, 1e9

    for i, data in ipairs(Config.depositvehicle) do
        if data.location then
            local dist = #(coords - data.location)
            if dist < nearestDist then
                nearestDist  = dist
                nearestIdx   = i
                nearestLabel = data.Label or ("Deposit_"..i)
            end
        end
    end

    if not nearestIdx then
        dprint("[Garage] ไม่พบ deposit vehicle ใน Config.depositvehicle")
        return nil, nil, nil, 0, {}
    end

    local count, plates = 0, {}
    if Mystored then
        for _, v in pairs(Mystored) do
            if v.deposit ~= nil and v.deposit == nearestIdx then
                -- ทำความสะอาด state ที่ฝากค้าง (ตามโค้ดเดิมของคุณ)
                local data_id = removeDeposit(v.plate)
                if data_id then
                    TriggerServerEvent(ResourceName..':removeDepositCar', v.plate, data_id)
                end
                -- ถ้าต้องการนับจริง ให้ปลดคอมเมนต์สองบรรทัดนี้:
                -- count = count + 1
                -- plates[#plates+1] = v.plate
            end
        end
    end

    if count > 0 then
        dprint(("[Garage] Deposit ใกล้สุด: %s (%.2fm) มีรถฝากอยู่ %d คัน")
            :format(nearestLabel, nearestDist, count))
    else
        dprint(("[Garage] Deposit ใกล้สุด: %s (%.2fm) ❌ ไม่มีรถฝาก")
            :format(nearestLabel, nearestDist))
    end

    return nearestIdx, nearestLabel, nearestDist, count, plates
end
exports("GetNearestDepositInfo", GetNearestDepositInfo)

-- AddEventHandler("myResource:enteredMarker", function(markerType, markerID)
--     TriggerEvent("mythic_notify:client:SendAlert", {
--         text = "Entered " .. markerType .. " Marker ID: " .. markerID,
--         type = "inform",
--         timeout = 3000,
--     })
-- end)

-- AddEventHandler("myResource:exitedMarker", function(markerType, markerID)
--     TriggerEvent("mythic_notify:client:SendAlert", {
--         text = "Exited " .. markerType .. " Marker ID: " .. markerID,
--         type = "error",
--         timeout = 3000,
--     })
-- end)

function GetClosestMarker(playerCoords, markerIndex)
    local closestMarker = nil
    local minDistance = nil

    for id = 1, #markerIndex do
        if markerIndex[id] then
            local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, markerIndex[id].x, markerIndex[id].y, markerIndex[id].z)
            if not minDistance or distance < minDistance then
                minDistance = distance
                closestMarker = id
            end
        end
    end
    return closestMarker, minDistance
end

hasEnteredGarageMarker = false
hasEnteredPoundMarker = false
hasEnteredDeleteMarker = false
hasEnteredDepositMarker = false
lastGarageMarker = nil
lastPoundMarker = nil
lastDeleteMarker = nil
lastDepositMarker = nil
markerRadius = 30.0

-- โปร่งใสเฉพาะรถในโซน Deposit (cfg.distDelete + 5.0)
local lastVeh = 0
local inGhostZone = false
local ghostOwned = false -- เราเป็นคนเปิด ghost อยู่ไหม

local function setAlphaSafe(ent, alpha)
    if ent ~= 0 and DoesEntityExist(ent) then
        if GetEntityAlpha(ent) ~= alpha then
            SetEntityAlpha(ent, alpha, false)
        end
    end
    -- เปิด ghost ถ้ายังไม่ได้เปิดโดยเราเอง
    if not ghostOwned then
        SetLocalPlayerAsGhost(true)
        ghostOwned = true
    end
end

local function clearGhostAndAlpha(ent)
    -- รีเซ็ตความโปร่งใสของรถ (ถ้ารถยังอยู่)
    if ent ~= 0 and DoesEntityExist(ent) then
        if GetEntityAlpha(ent) ~= 255 then
            ResetEntityAlpha(ent)
        end
    end

    -- ปลด ghost ที่เราตั้ง
    if ghostOwned then
        SetLocalPlayerAsGhost(false)
        ghostOwned = false
    end
end

local lastVeh = 0
local inGhostZone = false
local ghostOwned = false -- เราเป็นคนเปิด ghost อยู่ไหม

local function setAlphaSafe(ent, alpha)
    if ent ~= 0 and DoesEntityExist(ent) then
        if GetEntityAlpha(ent) ~= alpha then
            SetEntityAlpha(ent, alpha, false)
        end
    end
    -- เปิด ghost ถ้ายังไม่ได้เปิดโดยเราเอง
    if not ghostOwned then
        SetLocalPlayerAsGhost(true)
        ghostOwned = true
    end
end

local function clearGhostAndAlpha(ent)
    -- รีเซ็ตความโปร่งใสของรถ (ถ้ารถยังอยู่)
    if ent ~= 0 and DoesEntityExist(ent) then
        if GetEntityAlpha(ent) ~= 255 then
            ResetEntityAlpha(ent)
        end
    end

    -- ปลด ghost ที่เราตั้ง
    if ghostOwned then
        SetLocalPlayerAsGhost(false)
        ghostOwned = false
    end
end

-- helper เอาไว้เรียก export ให้ถูกจำนวนพารามิเตอร์
local function DrawGarageCircle(center, radius, colorMarker, colorLine)
    -- print("DrawGarageCircle", center, radius, colorMarker, colorLine)
    if colorMarker ~= nil and colorLine ~= nil then
        -- กรณีมีสีครบ ส่ง 4 ตัว
        exports['esx_core']:drawArenaCircleOnce(center, radius, colorMarker, colorLine)
    else
        -- กรณีไม่กำหนดสี ปล่อยให้ esx_core ใช้สี default
        exports['esx_core']:drawArenaCircleOnce(center, radius)
    end
end

-- วาดเฉพาะตอนมีจุดให้วาด + ลดความถี่การวาดลง
Citizen.CreateThread(function()
    local garageColorMarker = {r = 0, g = 255, b = 0, a = 100}
    local garageColorLine   = {r = 0, g = 255, b = 0, a = 255}

    while true do
        local sleep = 1500
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inVeh  = (GetVehiclePedIsUsing(ped) == 0)

        local hasAnyMarker =
            (lastGarageMarker ~= nil and not locationPropspawn[lastGarageMarker]) or
            (lastDeleteMarker ~= nil and not deletelocationPropspawn[lastDeleteMarker]) or
            (lastPoundMarker  ~= nil and not poundPropspawn[lastPoundMarker])
            -- print(lastDeleteMarker)
        -- print(deletelocationPropspawn[lastDeleteMarker])
        -- print(ESX.DumpTable(deletelocationPropspawn[lastDeleteMarker]))
        if hasAnyMarker then
            sleep = 0

            -- =======================================
            -- GARAGE (โชว์เฉพาะจุดที่ไม่มี prop)
            -- =======================================
            if inVeh then
                for id, location in pairs(locationIndex) do
                    if location and not locationPropspawn[id] then
                        local inout, dis = distance(coords, location, 10.0)
                        if inout then
                            local cfg = Config.garageDetail[id]
                            local radius = (cfg and cfg.Radius) or 2.0
                            local vehicletype = cfg.vehicletype or 'car'
                            local markerType = Config.MarkerType[vehicletype] or 36

                            DrawGarageCircle(location - vec3(0, 0, 0.5), radius, garageColorMarker, garageColorLine)
                            if dis <= radius then
                                DrawMarker(
                                    markerType,
                                    location.x, location.y, location.z,
                                    0.0, 0.0, 0.0,
                                    0.0, 0.0, 0.0,
                                    1.0, 1.0, 1.0,
                                    garageColorMarker.r, garageColorMarker.g, garageColorMarker.b,
                                    garageColorMarker.a * 3,
                                    true, true, 2, false, nil, nil, false
                                )
                            end
                        end
                    end
                end
            end

            -- =======================================
            -- DELETE (โชว์เฉพาะจุดที่ไม่มี prop)
            -- =======================================
            if not inVeh then
                for id, location in pairs(deletelocationDetailIndex) do
                    if location and not deletelocationPropspawn[id] then
                        local inout, dis = distance(coords, location, 10.0)
                        if inout then
                            local cfg = Config.garageDetail[id]
                            local radius = (cfg and cfg.DelRadius) or 2.0
                            -- print("radius:", radius)
                            local vehicletype = cfg.vehicletype or 'car'
                            local markerType = Config.MarkerType[vehicletype] or 36
                            local colorMarker = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 100}
                            local colorLine   = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 255}

                            DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
                            if dis <= radius then
                                DrawMarker(
                                    markerType,
                                    location.x, location.y, location.z,
                                    0.0, 0.0, 0.0,
                                    0.0, 0.0, 0.0,
                                    1.0, 1.0, 1.0,
                                    colorMarker.r, colorMarker.g, colorMarker.b,
                                    colorMarker.a * 3,
                                    true, true, 2, false, nil, nil, false
                                )
                            end
                        end
                    end
                end
            end

            -- =======================================
            -- POUND (โชว์เฉพาะจุดที่ไม่มี prop)
            -- =======================================
            if inVeh then
                for id, location in pairs(poundDetailIndex) do
                    if location and not poundPropspawn[id] then
                        local inout, dis = distance(coords, location, 10.0)
                        if inout then
                            local cfg = Config.poundDetail[id]
                            local radius = (cfg and cfg.Radius) or 1.5
                            local vehicletype = cfg.vehicletype or 'car'
                            local markerType = Config.MarkerType[vehicletype] or 36
                            local colorMarker = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 100}
                            local colorLine   = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 255}

                            DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
                            if dis <= radius then
                                DrawMarker(
                                    markerType,
                                    location.x, location.y, location.z,
                                    0.0, 0.0, 0.0,
                                    0.0, 0.0, 0.0,
                                    1.0, 1.0, 1.0,
                                    colorMarker.r, colorMarker.g, colorMarker.b,
                                    colorMarker.a * 3,
                                    true, true, 2, false, nil, nil, false
                                )
                            end
                        end
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Citizen.CreateThread(function()
--     -- สีใช้ซ้ำ
--     local garageColorMarker = {r = 0, g = 255, b = 0, a = 100}
--     local garageColorLine   = {r = 0, g = 255, b = 0, a = 255}

--     while true do
--         local sleep = 1500

--         local ped    = PlayerPedId()
--         local coords = GetEntityCoords(ped)
--         local inVeh  = (GetVehiclePedIsUsing(ped) == 0)
--         -- local hasAnyMarker =
--         --     (lastDepositMarker ~= nil) or
--         --     (lastDeleteMarker  ~= nil) or
--         --     (lastPoundMarker   ~= nil) or
--         --     (lastGarageMarker  ~= nil)
--                 -- ✅ ปลุกเฉพาะตอน marker ที่เข้าใกล้ “มี propspawn”
--         local hasAnyMarker =
--                 (lastGarageMarker ~= nil and not locationPropspawn[lastGarageMarker]) or
--                 (lastDeleteMarker ~= nil and not deletelocationPropspawn[lastDeleteMarker]) or
--                 (lastPoundMarker  ~= nil and not poundPropspawn[lastPoundMarker])
--                 print("hasAnyMarker:", hasAnyMarker)
--         if hasAnyMarker then
--             sleep = 0

--             -- ======================
--             -- GARAGE (โชว์เฉพาะที่ prop[id] = true)
--             -- ======================
--             if inVeh then
--                 for id, location in pairs(locationIndex) do
--                     -- ✅ เช็กว่า prop เปิดอยู่ไหม
--                     if location then
--                         local inout, dis = distance(coords, location, 10.0)
--                         if inout then
--                             -- local radius = 2.0
--                             local cfg    = Config.garageDetail[id]
--                             local radius = (cfg and cfg.Radius) or 2.0
--                             local vehicletype = cfg.vehicletype or 'car'
--                             DrawGarageCircle(location - vec3(0, 0, 0.5), radius, garageColorMarker, garageColorLine)
--                             if dis <= radius then
--                                 -- print(vehicletype)
--                                 -- print(Config.MarkerType)
--                                 -- print(ESX.DumpTable(Config.MarkerType[vehicletype]))
--                                 DrawMarker(
--                                     Config.MarkerType[vehicletype],
--                                     location.x, location.y, location.z,
--                                     0.0, 0.0, 0.0,
--                                     0.0, 0.0, 0.0,
--                                     1.0, 1.0, 1.0,
--                                     garageColorMarker.r, garageColorMarker.g, garageColorMarker.b,
--                                     garageColorMarker.a * 3,
--                                     true, true, 2, false, nil, nil, false
--                                 )
--                             end
--                         end
--                     end
--                 end
--             end

--             -- ======================
--             -- DELETE (โชว์เฉพาะที่ prop[id] = true)
--             -- ======================
--             if not inVeh then
--                 for id, location in pairs(deletelocationDetailIndex) do
--                     -- ✅ เช็กว่า prop เปิดอยู่ไหม
--                     if location then
--                         local inout, dis = distance(coords, location, 10.0)
--                         if inout then
--                             -- local radius = Config.DeleteMarker.x
--                             local cfg    = Config.garageDetail[id]
--                             local radius = (cfg and cfg.Radius) or 2.0
--                             local vehicletype = cfg.vehicletype or 'car'
--                             local colorMarker = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 100}
--                             local colorLine   = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 255}
--                             DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
--                             if dis <= 4.0 then
--                                 DrawMarker(
--                                     -- Config.SpawnMarker.type,
--                                     Config.MarkerType[vehicletype],

--                                     location.x, location.y, location.z,
--                                     0.0, 0.0, 0.0,
--                                     0.0, 0.0, 0.0,
--                                     1.0, 1.0, 1.0,
--                                     Config.DeleteMarker.r, Config.DeleteMarker.g, Config.DeleteMarker.b,
--                                     Config.DeleteMarker.a * 3,
--                                     true, true, 2, false, nil, nil, false
--                                 )
--                             end
--                         end
--                     end
--                 end
--             end

--             -- ======================
--             -- POUND (โชว์เฉพาะที่ prop[id] = true)
--             -- ======================
--             if inVeh then
--                 for id, location in pairs(poundDetailIndex) do
--                     -- ✅ เช็กว่า prop เปิดอยู่ไหม
--                     if location then
--                         local inout, dis = distance(coords, location, 10.0)
--                         if inout then
--                             -- local radius = 1.5
--                             local cfg    = Config.poundDetail[id]
--                             local radius = (cfg and cfg.Radius) or 1.5   -- 👈 ใช้ Radius จากจุด
--                             local vehicletype = cfg.vehicletype or 'car'
--                             local colorMarker = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 100}
--                             local colorLine   = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 255}
--                             DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
--                             if dis <= radius then
--                                 DrawMarker(
--                                     Config.MarkerType[vehicletype],

--                                     location.x, location.y, location.z,
--                                     0.0, 0.0, 0.0,
--                                     0.0, 0.0, 0.0,
--                                     1.0, 1.0, 1.0,
--                                     colorMarker.r, colorMarker.g, colorMarker.b,
--                                     colorMarker.a * 3,
--                                     true, true, 2, false, nil, nil, false
--                                 )
--                             end
--                         end
--                     end
--                 end
--             end
--         end

--         Citizen.Wait(sleep)
--     end
-- end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local veh = GetVehiclePedIsIn(ped, false)

        -- ถ้า lastVeh หายไปจากโลก ให้เคลียร์ ghost ทันที ป้องกันหลอน
        if inGhostZone then
            if lastVeh ~= 0 and not DoesEntityExist(lastVeh) then
                -- รถโดนลบ/หาย -> reset state ทั้งหมดทันที
                clearGhostAndAlpha(lastVeh)
                lastVeh = 0
                inGhostZone = false
            end
        else
            -- ถ้าเราไม่ได้อยู่ในโซนแล้ว แต่ ghostOwned ยัง true (failsafe)
            if ghostOwned then
                clearGhostAndAlpha(lastVeh)
                lastVeh = 0
            end
        end

        -- ====== garage ======
        local currentGarageMarker, garageDistance = GetClosestMarker(playerCoords, locationIndex)
        if currentGarageMarker and garageDistance < markerRadius then
            if not hasEnteredGarageMarker then
                hasEnteredGarageMarker = true
                lastGarageMarker = currentGarageMarker
            elseif lastGarageMarker ~= currentGarageMarker then
                lastGarageMarker = currentGarageMarker
            end
        else
            if hasEnteredGarageMarker then
                hasEnteredGarageMarker = false
                lastGarageMarker = nil
            end
        end

        -- ====== pound ======
        local currentPoundMarker, poundDistance = GetClosestMarker(playerCoords, poundDetailIndex)
        if currentPoundMarker and poundDistance < markerRadius then
            if not hasEnteredPoundMarker then
                hasEnteredPoundMarker = true
                lastPoundMarker = currentPoundMarker
            elseif lastPoundMarker ~= currentPoundMarker then
                lastPoundMarker = currentPoundMarker
            end
        else
            if hasEnteredPoundMarker then
                hasEnteredPoundMarker = false
                lastPoundMarker = nil
            end
        end

        -- ====== delete location ======
        local currentDeleteMarker, deleteDistance = GetClosestMarker(playerCoords, deletelocationDetailIndex)
        if currentDeleteMarker and deleteDistance < markerRadius then
            if not hasEnteredDeleteMarker then
                hasEnteredDeleteMarker = true
                lastDeleteMarker = currentDeleteMarker
            elseif lastDeleteMarker ~= currentDeleteMarker then
                lastDeleteMarker = currentDeleteMarker
            end
        else
            if hasEnteredDeleteMarker then
                hasEnteredDeleteMarker = false
                lastDeleteMarker = nil
            end
        end

        -- ====== deposit zone / ghost logic ======
        local currentDepositMarker, depositDistance = GetClosestMarker(playerCoords, DepositlocationDetailIndex)
        local mydimen = exports['Assist_Setdimen']:GetDimension()
        if not isStoryDimension(mydimen) then
            if currentDepositMarker and depositDistance < 150.0 then
                local cfg = Config.depositvehicle[currentDepositMarker]
                local triggerRadius = (cfg and cfg.distDelete or 0.0) + 15.0
                local shouldGhost = false
                if veh ~= 0 and cfg and cfg.active and cfg.GhostZone and (depositDistance < triggerRadius) then
                    shouldGhost = true
                end

                -- เข้าโซน ghost ครั้งแรก
                if shouldGhost and not inGhostZone then
                    inGhostZone = true
                    setAlphaSafe(veh, 150)
                    lastVeh = veh
                end

                -- อยู่ในโซนต่อเนื่อง
                if inGhostZone and shouldGhost then
                    -- สลับรถในโซน
                    if veh ~= 0 and veh ~= lastVeh then
                        clearGhostAndAlpha(lastVeh)
                        setAlphaSafe(veh, 150)
                        lastVeh = veh
                    end

                    -- ลงรถ (veh == 0)
                    if veh == 0 and lastVeh ~= 0 then
                        clearGhostAndAlpha(lastVeh)
                        lastVeh = 0
                    end
                end

                -- ออกจากเงื่อนไข ghost (ยังอยู่ในระยะ 150.0 แต่มันไม่ควร ghost แล้ว เช่น cfg.inactive)
                if inGhostZone and not shouldGhost then
                    inGhostZone = false
                    clearGhostAndAlpha(lastVeh)
                    lastVeh = 0
                end

                -- track deposit marker state
                if not hasEnteredDepositMarker then
                    hasEnteredDepositMarker = true
                    lastDepositMarker = currentDepositMarker
                elseif lastDepositMarker ~= currentDepositMarker then
                    lastDepositMarker = currentDepositMarker
                end

            else
                -- ไปไกลกว่า 150.0 / ไม่มี deposit เลย
                if inGhostZone then
                    inGhostZone = false
                    clearGhostAndAlpha(lastVeh)
                    lastVeh = 0
                else
                    -- failsafe เพิ่มเติม: ถ้าเราไม่อยู่โซนแล้ว แต่ยัง ghostOwned=true (เช่นรถโดนลบทิ้งกลางระหว่าง if)
                    if ghostOwned then
                        clearGhostAndAlpha(lastVeh)
                        lastVeh = 0
                    end
                end

                if hasEnteredDepositMarker then
                    hasEnteredDepositMarker = false
                    lastDepositMarker = nil
                end
            end
        end
    end
end)

function distance(Pcoords, location, redius)
    local coords = Pcoords
    local distance = Vdist(coords.x, coords.y, coords.z, location.x, location.y, location.z)
    if distance <= redius then
        return true , distance
    end
    return false
end

function isInDimension(dim)
    for _, v in ipairs(allowedDimensions) do
        dprint("[DimCheck]", v, dim)
        if v == dim then 
            return true 
        end
    end
    return false
end

function hasJob(jobReq, myJob)
    if jobReq == nil then return true end                 -- ไม่กำหนด = ผ่าน
    if not myJob then return false end                    -- ไม่มีอาชีพ = ไม่ผ่าน
    if type(jobReq) == "string" then
        return myJob == jobReq
    elseif type(jobReq) == "table" then
        for _, allowed in ipairs(jobReq) do
            if myJob == allowed then
                return true
            end
        end
        return false
    else
        -- ชนิดอื่นไม่รองรับ (กันพลาด)
        return false
    end
end

-- โหมดโปร่งใส/ghost ขณะอยู่ในระยะ UI (DDT_3d)
-- local isGhostActive = false
-- local ghostVeh = 0         -- รถคันที่กำลังถูกทำให้ใสอยู่

-- CreateThread(function()
--     while true do
--         Wait(200)
--         local ped = PlayerPedId()
--         local veh = GetVehiclePedIsIn(ped, false)

--         if showUIDisplaytext then
--             -- เปิดโหมด ghost หนึ่งครั้ง
--             if not isGhostActive {
--                 isGhostActive = true
--                 SetLocalPlayerAsGhost(true)     -- กันชนกับผู้เล่นอื่น
--             }

--             -- บังคับให้ตัวละครโปร่งใสตลอดช่วงที่ UI โชว์
--             if GetEntityAlpha(ped) ~= 150 then
--                 SetEntityAlpha(ped, 150, false)
--             end

--             -- ถ้าอยู่ในรถ ให้ทำรถใสด้วย และรองรับการ "ขึ้นรถทีหลัง/เปลี่ยนคัน"
--             if veh ~= 0 then
--                 if ghostVeh ~= 0 and ghostVeh ~= veh and DoesEntityExist(ghostVeh) then
--                     ResetEntityAlpha(ghostVeh)  -- รีเซ็ตคันเก่าทันทีเมื่อเปลี่ยนคัน
--                 end
--                 ghostVeh = veh
--                 if GetEntityAlpha(veh) ~= 150 then
--                     SetEntityAlpha(veh, 150, false)
--                 end
--             else
--                 -- ไม่ได้อยู่ในรถ ถ้ามีคันที่เคยทำใสอยู่ ให้รีเซ็ตกลับ
--                 if ghostVeh ~= 0 and DoesEntityExist(ghostVeh) then
--                     ResetEntityAlpha(ghostVeh)
--                 end
--                 ghostVeh = 0
--             end

--         else
--             -- ปิดโหมด ghost และรีเซ็ตทุกอย่างเมื่อ UI ไม่โชว์แล้ว
--             if isGhostActive then
--                 isGhostActive = false
--                 SetLocalPlayerAsGhost(false)
--                 if GetEntityAlpha(ped) ~= 255 then
--                     ResetEntityAlpha(ped)
--                 end
--                 if ghostVeh ~= 0 and DoesEntityExist(ghostVeh) then
--                     ResetEntityAlpha(ghostVeh)
--                 end
--                 ghostVeh = 0
--             end
--         end
--     end
-- end)

function SetAlphaandGhost(entity, alpha, isGhost)
    if GetEntityAlpha(entity) ~= alpha then
        SetEntityAlpha(entity, alpha, false)
    end
    SetLocalPlayerAsGhost(isGhost)
end

Citizen.CreateThread(function()
    Wait(500)
    while true do
        ::START::
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local pressE = false
        local mrcoords = nil
        local text = ''
        -- ลบรถ (delete spot) เมื่อนั่งรถอยู่
        if IsPedInAnyVehicle(ped, true) and lastDeleteMarker then
            if Config.garageDetail[lastDeleteMarker].deletelocation then
                if Vdist(coords, Config.garageDetail[lastDeleteMarker].deletelocation) <= Config.SeeMarker * 1.5 then
                    sleep = 0
                    local myJob = (PlayerData and PlayerData.job and PlayerData.job.name) or nil
                    local reqJob = Config.garageDetail[lastDeleteMarker].job
                    local delradius = Config.garageDetail[lastDeleteMarker].DelRadius or Config.DeleteMarker.x
                    if Vdist(coords, Config.garageDetail[lastDeleteMarker].deletelocation) <= delradius and CurrentPoint == nil and isInDimension(exports['Assist_Setdimen']:GetDimension()) and not openuigarage then

                        if not hasJob(reqJob, myJob) then
                            goto END
                        end

                        local veh = GetVehiclePedIsIn(ped, false)
                        local isDriver = (GetPedInVehicleSeat(veh, -1) == ped)
                        if not isDriver then
                            -- ไม่ใช่คนขับ = ไม่โชว์ UI, ไม่ให้กดอะไร
                            goto END
                        end

                        pressE = true
                        mrcoords = vector3(
                            Config.garageDetail[lastDeleteMarker].deletelocation.x,
                            Config.garageDetail[lastDeleteMarker].deletelocation.y,
                            Config.garageDetail[lastDeleteMarker].deletelocation.z - 0.3
                        )
                        text = 'STORED VEHICLE'
                        local success = exports["DDT_3d"]:showInteractionUI({
                            id = Config.garageDetail[lastDeleteMarker].deletelocation,
                            coords = Config.garageDetail[lastDeleteMarker].deletelocation,
                            keyNum = 38,
                            keyText = "E",
                            text = text,
                            dist = delradius,
                            duration = 600,
                            type = 2
                        })
                        if success then
                            -- if GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
                                if not fistLoad then
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    while not fistLoad do Wait(0) end
                                end
                                -- ผ่านแล้ว ไม่ต้องเช็กซ้ำ
                                CurrentPoint = 'stored'
                                CurrentType = Config.garageDetail[lastDeleteMarker].vehicletype
                                StoreOwnedVehicleMenu()
                                dprint("[UI] Store vehicle confirmed at delete spot")
                            -- end
                        end
                        goto END
                    end
                end
            end
        else
            -- เปิดเมนู Garage เมื่อเดินเท้า
            if not IsPedInAnyVehicle(ped, true) and lastGarageMarker then
                if Vdist(coords, Config.garageDetail[lastGarageMarker].location) <= Config.SeeMarker * 1.5 then
                    sleep = 0
                    local myJob = (PlayerData and PlayerData.job and PlayerData.job.name) or nil
                    local reqJob = Config.garageDetail[lastGarageMarker].job
                    local gcfg   = Config.garageDetail[lastGarageMarker]
                    local gpos   = gcfg.location
                    local gradius= gcfg.Radius or Config.SpawnMarker.x  -- 👈 ดึงจากจุด
                    if Vdist(coords, gpos) <= gradius and CurrentPoint == nil and isInDimension(exports['Assist_Setdimen']:GetDimension()) and not openuigarage then
                        
                        if not hasJob(reqJob, myJob) then goto END end

                        pressE = true
                        mrcoords = vector3(
                            Config.garageDetail[lastGarageMarker].location.x,
                            Config.garageDetail[lastGarageMarker].location.y,
                            Config.garageDetail[lastGarageMarker].location.z - 0.25
                        )
                        -- print(Config.SpawnMarker.x)
                        text = 'OPEN GARAGE'
                        local success = exports["DDT_3d"]:showInteractionUI({
                            id = gpos,
                            coords = gpos,
                            keyNum = 38,
                            keyText = "E",
                            text = text,
                            dist = gradius,     -- 👈 ส่งระยะตามจุด
                            duration = 600,
                            type = 2
                        })
                        if success then
                            if not fistLoad then
                                SetNuiFocus(true, true)
                                TriggerServerEvent(ResourceName..':reloadData')
                                while not fistLoad do Wait(0) end
                            end
                            CurrentPoint = 'garage'
                            CurrentType = Config.garageDetail[lastGarageMarker].vehicletype
                            this_GaragePoint = Config.garageDetail[lastGarageMarker].spawnlocation
                            this_GarageHeading = Config.garageDetail[lastGarageMarker].spawnheading
                            -- (คงพฤติกรรมเดิม) ถ้ามีการล็อก job ให้ส่ง reqJob ไปด้วย
                            if reqJob ~= nil then
                                openGarage(CurrentPoint, CurrentType, reqJob)
                            else
                                openGarage(CurrentPoint, CurrentType)
                            end
                            dprint("[UI] Open Garage menu")
                        end
                    end
                end
            end
        end

        -- พื้นที่ Pound
        -- print('lastPoundMarker', lastPoundMarker) -- ตามต้องการ
        if IsPedInAnyVehicle(ped, true) and lastPoundMarker then
            goto END
        else
            if lastPoundMarker then
                while not PlayerData do
                    PlayerData = ESX.GetPlayerData()
                    Wait(0)
                end
                local poundConfig = Config.poundDetail[lastPoundMarker]
                local myJob = (PlayerData and PlayerData.job and PlayerData.job.name) or nil
                local reqJob = poundConfig.job -- อาจเป็น string หรือ table
                -- ใช้ hasJob: ถ้ามี reqJob ต้องผ่าน, ถ้าไม่มี reqJob เปิดได้ทุกอาชีพ (รวม unemployed)
                -- print(hasJob(reqJob, myJob))
                local pradius = poundConfig.Radius or Config.PoundMarker.x

                if hasJob(reqJob, myJob) then
                    if Vdist(coords, poundConfig.location) <= Config.SeeMarker * 1.5 then
                        sleep = 0
                        if Vdist(coords, poundConfig.location) <= pradius and CurrentPoint == nil and isInDimension(exports['Assist_Setdimen']:GetDimension()) and not openuigarage then
                            pressE = true
                            mrcoords = vector3(poundConfig.location.x, poundConfig.location.y, poundConfig.location.z - 0.3)
                            text = 'OPEN POUND VEHICLE MENU'
                            local success = exports["DDT_3d"]:showInteractionUI({
                                id = poundConfig.location,
                                coords = poundConfig.location,
                                keyNum = 38,
                                keyText = "E",
                                text = text,
                                dist = pradius,     -- ใช้ระยะของจุด
                                duration = 600,
                                type = 2
                            })
                            if success then
                                if not fistLoad then
                                    SetNuiFocus(true, true)
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    while not fistLoad do Wait(0) end
                                end
                                CurrentPoint = 'pound'
                                CurrentType = poundConfig.vehicletype
                                this_GaragePoint = poundConfig.spawnlocation
                                this_GarageHeading = poundConfig.spawnheading
                                -- (คงพฤติกรรมเดิมของคุณ) ถ้าล็อก job อยู่ ให้ส่งชื่อ job ผู้เล่น
                                if reqJob then
                                    if myJob then
                                        openGarage(CurrentPoint, CurrentType, myJob)
                                    end
                                else
                                    openGarage(CurrentPoint, CurrentType)
                                end
                                dprint("[UI] Open Pound menu")
                            end
                            goto END
                        end
                    end
                end
            end
        end

        ::END::
        -- แสดง/ซ่อน UI ปุ่ม E (debug)
        if pressE then
            if not showUIDisplaytext then
                showUIDisplaytext = true
                -- print("[UI] show", text)
                dprint("[UI] show", text)
            end
        else
            if showUIDisplaytext then
                showUIDisplaytext = false
                -- print("[UI] hide", showUIDisplaytext)
                dprint("[UI] hide", showUIDisplaytext)
                Wait(200)
            end
        end
        Citizen.Wait(sleep)
    end
end)

function OpenGarageNear(coords)
    local nearestIdx, nearestLabel, nearestDist = nil, nil, 1e9

    for i, data in ipairs(Config.depositvehicle) do
        if data.location then
            local dist = #(coords - data.location)
            if dist < nearestDist then
                -- nearestDist  = dist
                -- nearestIdx   = i
                -- nearestLabel = data.Label or ("Deposit_"..i)
                if not fistLoad then
                    SetNuiFocus(true, true)
                    TriggerServerEvent(ResourceName..':reloadData')
                    while not fistLoad do Wait(0) end
                end
                local idx = lastDepositMarker
                local cfg = (idx and Config.depositvehicle[idx]) or nil
                CurrentPoint      = 'deposit'
                this_GaragePoint  = cfg.spawnlocation
                this_GarageHeading= cfg.spawnheading
                openGarage(CurrentPoint, idx)
            end
        end
    end
end

exports("OpenGarageNear", OpenGarageNear)

function isStoryDimension(dim)
    local WhitelistDimen = exports['Assist_Setdimen']:GetWhitelistDimen()
    for _, allowed in ipairs(WhitelistDimen) do
        if dim == allowed then
            return true
        end
    end
    return false
end

CreateThread(function()
    while true do 
        local sleep = 1100
        local ped   = PlayerPedId()
        local coords= GetEntityCoords(ped)

        local idx = lastDepositMarker
        local cfg = (idx and Config.depositvehicle[idx]) or nil
        if IsPedInAnyVehicle(ped, true) then
            if cfg and cfg.active then
                local dist = #(coords - cfg.deletelocation)
                if dist <= 150.0 then
                    sleep = 200
                    local inside = dist <= cfg.distDelete and (CurrentPoint == nil)
                    local veh = GetVehiclePedIsIn(ped, false)
                    local isDriver = (GetPedInVehicleSeat(veh, -1) == ped)
                    local mydimen = exports['Assist_Setdimen']:GetDimension()
                       
                    if inside and isInDimension(exports['Assist_Setdimen']:GetDimension()) and not openuigarage and isDriver and not isStoryDimension(mydimen) then
                        sleep = 0
                        -- DrawMarker(
                        --     Config.DepositMarker2.type,
                        --     cfg.deletelocation.x, cfg.deletelocation.y, cfg.deletelocation.z,
                        --     0.0,0.0,0.0, 0,0.0,0.0,
                        --     cfg.distDelete, cfg.distDelete, cfg.distDelete,
                        --     Config.DepositMarker2.r, Config.DepositMarker2.g, Config.DepositMarker2.b,
                        --     90,false,false,2,false,false,false,false
                        -- )
                        if not cfg.autodelete then
                            local ok = exports["DDT_3d"]:showInteractionUI({
                                id = cfg.deletelocation,
                                coords = coords,
                                keyNum = 38,
                                keyText = "E",
                                text = "ฝากรถ",
                                dist = 2.0,
                                duration = 600,
                                type = 2
                            })
                            if ok then
                                dprint("[Deposit] Success: hold E to deposit")
                                if not fistLoad then 
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    while not fistLoad do Wait(0) end 
                                end 
                                CurrentPoint = 'deposit'
                                this_GaragePoint = cfg.location
                                this_GarageHeading = cfg.spawnheading    
                                StoreVehicle_deposit(idx)
                            end
                        else
                            if not isStoryDimension(mydimen) then
                                if not fistLoad then 
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    while not fistLoad do Wait(0) end 
                                end 
                                CurrentPoint = 'deposit'
                                this_GaragePoint = cfg.location
                                this_GarageHeading = cfg.spawnheading    
                                StoreVehicle_deposit(idx)
                            end
                        end
                    end
                end
            end
        else
            -- เดินเท้า: จุดเปิดเมนูฝากรถ
            if idx then
                local dist = #(coords - cfg.location)
                if dist <= Config.DepositMarker1.x and not openuigarage then
                    sleep = 200
                    dprint("[DimCheck-foot]", isInDimension(exports['Assist_Setdimen']:GetDimension()))
                    if (CurrentPoint == nil) and isInDimension(exports['Assist_Setdimen']:GetDimension()) then
                        sleep = 0
                        local success = exports["DDT_3d"]:showInteractionUI({
                            id = cfg.location,
                            coords = cfg.location,
                            keyNum = 38,
                            keyText = "E",
                            text = "เปิดเมนูฝากรถ",
                            dist = 2.0,
                            duration = 600,
                            type = 2
                        })
                        if success then
                            if not fistLoad then
                                SetNuiFocus(true,true)
                                TriggerServerEvent(ResourceName..':reloadData')
                                while not fistLoad do Wait(0) end
                            end
                            CurrentPoint      = 'deposit'
                            this_GaragePoint  = cfg.spawnlocation
                            this_GarageHeading= cfg.spawnheading
                            openGarage(CurrentPoint, idx)
                            dprint("[UI] Open Deposit menu")
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)


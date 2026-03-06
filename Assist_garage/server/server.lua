local ESX = exports['es_extended'] and exports['es_extended']:getSharedObject() or nil
local ResourceName = GetCurrentResourceName()

CreateThread(function()
    if ESX then return end
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(200)
    end
end)

local function getPlayer(src)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(src)
end

local function fetchVehicles(identifier, cb)
    MySQL.Async.fetchAll('SELECT owner, plate, vehicle, type, stored, police, job, vehiclename, health_vehicles, deposit FROM owned_vehicles WHERE owner = @owner', {
        ['@owner'] = identifier
    }, function(result)
        local list = {}
        for i = 1, #(result or {}) do
            local r = result[i]
            list[#list+1] = {
                plate = r.plate,
                stored = r.stored == 1 or r.stored == true,
                police = r.police or 0,
                job = r.job or '',
                type = r.type or 'car',
                vehiclename = r.vehiclename,
                vehicle = r.vehicle,
                health_vehicles = r.health_vehicles,
                deposit = r.deposit
            }
        end
        cb(list)
    end)
end

local function sendWebhook(url, title, description, color)
    if not url or url == '' then return end
    local body = {
        username = 'Assist_garage',
        embeds = {
            {
                title = title,
                description = description,
                color = color or 16711680
            }
        }
    }

    PerformHttpRequest(url, function() end, 'POST', json.encode(body), {
        ['Content-Type'] = 'application/json'
    })
end

RegisterServerEvent(ResourceName..':logWebhook')
AddEventHandler(ResourceName..':logWebhook', function(payload)
    if type(payload) ~= 'table' then return end

    local src = source
    local xPlayer = getPlayer(src)
    local ownerName = (xPlayer and xPlayer.getName and xPlayer.getName()) or GetPlayerName(src) or ('ID '..tostring(src))
    local action = tostring(payload.action or payload.webhook or '')
    local plate = tostring(payload.plate or '-')
    local durability = tonumber(payload.durability or 0) or 0
    local fuel = tonumber(payload.fuel or 0) or 0

    local titleMap = {
        storevehicle = 'เก็บรถ',
        garage_spawn = 'เบิกรถ',
        garage_pound = 'พาวน์รถ'
    }

    local title = titleMap[action] or 'Garage Log'
    local desc = ('ชื่อเจ้าของรถ: %s\nทะเบียน: %s\nความคงทนรถ: %.1f\nน้ำมัน: %.1f')
        :format(ownerName, plate, durability, fuel)

    local webhookUrl = nil
    if Config.Webhooks then
        webhookUrl = Config.Webhooks[action]
    end

    sendWebhook(webhookUrl, title, desc, 16711680)
end)

RegisterServerEvent(ResourceName..':reloadData')
AddEventHandler(ResourceName..':reloadData', function()
    local src = source
    local xPlayer = getPlayer(src)
    if not xPlayer then return end
    fetchVehicles(xPlayer.getIdentifier() or xPlayer.identifier, function(vehicles)
        TriggerClientEvent(ResourceName..':reloadData:client', src, vehicles)
    end)
end)

RegisterServerEvent(ResourceName..':setStateVehicle')
AddEventHandler(ResourceName..':setStateVehicle', function(plate, stored, props)
    local src = source
    if type(plate) ~= 'string' or plate == '' then return end
    local s = stored and 1 or 0
    if props and type(props) == 'table' then
        MySQL.Async.execute('UPDATE owned_vehicles SET stored = @stored, vehicle = @vehicle WHERE plate = @plate', {
            ['@stored'] = s,
            ['@vehicle'] = json.encode(props),
            ['@plate'] = plate
        })
    else
        MySQL.Async.execute('UPDATE owned_vehicles SET stored = @stored WHERE plate = @plate', {
            ['@stored'] = s,
            ['@plate'] = plate
        })
    end
end)

RegisterServerEvent(ResourceName..':depositvehicles')
AddEventHandler(ResourceName..':depositvehicles', function(plate, depositId)
    if type(plate) ~= 'string' or plate == '' then return end
    MySQL.Async.execute('UPDATE owned_vehicles SET deposit = @deposit WHERE plate = @plate', {
        ['@deposit'] = tonumber(depositId) or nil,
        ['@plate'] = plate
    })
end)

RegisterServerEvent(ResourceName..':removeDepositCar')
AddEventHandler(ResourceName..':removeDepositCar', function(plate, depositId)
    if type(plate) ~= 'string' or plate == '' then return end
    MySQL.Async.execute('UPDATE owned_vehicles SET deposit = NULL WHERE plate = @plate', {
        ['@plate'] = plate
    })
end)

RegisterServerEvent(ResourceName..':deletePoundVehicle')
AddEventHandler(ResourceName..':deletePoundVehicle', function(plate)
    if type(plate) ~= 'string' or plate == '' then return end
    TriggerClientEvent(ResourceName..':deletePoundVehicleAll', -1, plate)
end)

RegisterServerEvent(ResourceName..':openTrunk')
AddEventHandler(ResourceName..':openTrunk', function(plate)
end)

RegisterServerEvent(ResourceName..':renamevehicle')
AddEventHandler(ResourceName..':renamevehicle', function(plate, rename)
    if type(plate) ~= 'string' or plate == '' then return end
    if type(rename) ~= 'string' or rename == '' then return end
    MySQL.Async.execute('UPDATE owned_vehicles SET vehiclename = @name WHERE plate = @plate', {
        ['@name'] = rename,
        ['@plate'] = plate
    })
end)

RegisterServerEvent(ResourceName..'::modifyDamage')
AddEventHandler(ResourceName..'::modifyDamage', function(plate, damage)
    if type(plate) ~= 'string' or plate == '' then return end
    if type(damage) ~= 'table' then return end
    MySQL.Async.execute('UPDATE owned_vehicles SET health_vehicles = @hv WHERE plate = @plate', {
        ['@hv'] = json.encode(damage),
        ['@plate'] = plate
    })
end)

CreateThread(function()
    while not ESX do Wait(200) end

    ESX.RegisterServerCallback(ResourceName..':payMoney', function(src, cb)
    local xPlayer = getPlayer(src)
    if not xPlayer then cb(false) return end
    local cost = tonumber(Config.poundCost or 0) or 0
    if cost <= 0 then cb(true) return end
    local money = xPlayer.getMoney()
    if money >= cost then
        xPlayer.removeMoney(cost)
        cb(true)
        return
    end
    local bank = xPlayer.getAccount('bank').money or 0
    if bank >= cost then
        xPlayer.removeAccountMoney('bank', cost)
        cb(true)
    else
        cb(false)
    end
end)

end)

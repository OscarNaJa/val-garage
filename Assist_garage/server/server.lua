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

local function fetchVehicles(identifier)
    local result = MySQL.Sync.fetchAll('SELECT owner, plate, vehicle, type, stored, police, job, vehiclename, health_vehicles, deposit FROM owned_vehicles WHERE owner = @owner', { ['@owner'] = identifier })
    local list = {}
    for i = 1, #result do
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
    return list
end

RegisterServerEvent(ResourceName..':reloadData')
AddEventHandler(ResourceName..':reloadData', function()
    local src = source
    local xPlayer = getPlayer(src)
    if not xPlayer then return end
    local vehicles = fetchVehicles(xPlayer.getIdentifier() or xPlayer.identifier)
    TriggerClientEvent(ResourceName..':reloadData:client', src, vehicles)
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

Config = {}

Config.SeeMarker = 25
Config.Debug = false

Config.activeColor = {r = 255, g = 0, b = 0}-- Marker ของจุดเก็บรถ

Config.activeColor2 = {r = 222, g = 222, b = 222} -- Marker ของจุดเบิกรถ

Config.MarkerType = {
    car         = 36,
    boat        = 35,
    helicopter  = 34,
}

Config.WhitelistDimen = {100, 101} -- มิติที่อนุญาตให้ใช้งานลานจอดรถ (ถ้าว่าง = ทุกมิติ)

Config.notification = function(type,text)
    -- type = 'success','error'
    -- text  = 'ALERT TEXT'
    TriggerEvent("pNotify:SendNotification",{
        text = text,
        type = type,
        timeout = 8000,
    })
end

Config.poundCost = 3000
-- Config.sendCost = 1200

Config.pounddeposit = true -- true = พาวรถจากจุดฝากได้ไหม

Config.healthPound = 100
Config.fuelPound = 100

Config.DimensionsAllow = {0,100} -- มิติที่ต้องการเช็ค

-- ระยะ Ghost รอบจุดเบิกรถ (ใช้เป็นค่า default ถ้าจุดนั้นไม่ได้กำหนด GhostRadius)
Config.GhostRadius = 7.5


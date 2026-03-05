local textcoords = nil 
local isShowUI = false
exports('DTT_show3d', function(text, isPress,coordsX)
	textcoords = coordsX

end)
exports('DTT_hide3d', function()
	HIDETEXT()
end)



exports('DTT_show2d', function(text, isPress)
	SHOWTEXT(isPress, text)
end)
exports('DTT_hide2d', function()
	HIDETEXT()
end)



SHOWTEXT = function(isPress , text)
	if not isShowUI then
		isShowUI = true
		-- Wait(100)
		SendNUIMessage({
			action = 'SHOW',
			text = text,
			isPress = isPress,
		})
		
	end
end

HIDETEXT = function()
	if isShowUI then
		SendNUIMessage({
			action = 'HIDE'
		})
		isShowUI = false
	end
end

-- Citizen.CreateThread(function()
--     while true do 
-- 		local sleep = 1000
		
-- 		if isShowUI then 
-- 			local mCoords = textcoords or GetEntityCoords(PlayerPedId())
-- 			sleep = 0
-- 			-- print('ok')
-- 			local x, y, z = table.unpack(mCoords)
-- 			local onScreen, DTT, yyy = GetHudScreenPositionFromWorldPosition(x, y, z +1.225)
--             SendNUIMessage({
--                 action = 'POS',
--                 left = DTT*100,
--                 top = yyy*100
--             })

-- 		end 
-- 		Citizen.Wait(sleep)
-- 	end 
-- end)
--Dan_BB Speed Cameras

--Define coordinates of Cameras  
local speedCameras = {

	["Vinewood Blvd / Alta St"]={
	x = 278.49673461914, y = 180.99287414551, z = 104.52822875977,
	maxSpeed=60.0,
	pointingDirection="W",
	additionalFine=0},

}

--Creating Blips for Cameras
Citizen.CreateThread(function()
    for _, create in pairs(speedCameras) do
      create.blip = AddBlipForCoord(create.x, create.y, create.z)
      SetBlipSprite(create.blip, 135)
      SetBlipDisplay(create.blip, 4)
      SetBlipScale(create.blip, 1.0)
      SetBlipColour(create.blip, 1)
      SetBlipAsShortRange(create.blip, true)
	  BeginTextCommandSetBlipName("STRING")
      AddTextComponentString("Speed Camera")
      EndTextCommandSetBlipName(create.blip)
    end
end)

--Main Camera Function
local alertAlready = false
Citizen.CreateThread(function()
	while true do
	Citizen.Wait(10)
		for x in pairs (speedCameras) do
			local playerCoordinates = GetEntityCoords(GetPlayerPed(-1), false)
			local distFromCam = Vdist(playerCoordinates.x, playerCoordinates.y, playerCoordinates.z, speedCameras[x].x, speedCameras[x].y, speedCameras[x].z)
			if (distFromCam <= 40) then
				local playerID = GetPlayerServerId(PlayerId())
				local player = GetPlayerPed(-1)
				local playerCar = GetVehiclePedIsIn(player, false)
				local plate = GetVehicleNumberPlateText(playerCar)
				local speedKM = math.floor((GetEntitySpeed(player)*3.6)+0.5)
				local maxSpeed = speedCameras[x].maxSpeed
				local cameraName, crossing = GetStreetNameFromHashKey(GetStreetNameAtCoord(speedCameras[x].x, speedCameras[x].y, speedCameras[x].z))
				local cameraFineAdd = speedCameras[x].additionalFine
				local class = GetVehicleClass(playerCar)
				local bumperOn = IsVehicleBumperBrokenOff(playerCar, true) 
				local directions = { [0] = 'N', [45] = 'NW', [90] = 'W', [135] = 'SW', [180] = 'S', [225] = 'SE', [270] = 'E', [315] = 'NE', [360] = 'N', }
				if (speedKM > maxSpeed) then 
					if IsPedInAnyVehicle(player, false) then
						if( class == 18) then
						else
							for k,v in pairs(directions)do
								direction = GetEntityHeading(playerCar)
								if(math.abs(direction - k) < 22.5)then
									direction = v
									break;
								end
							end
							cameraName = ''..cameraName..' '..direction..' bound'
							if (speedCameras[x].pointingDirection == direction) then
								if (GetPedInVehicleSeat(playerCar, -1) == player) then
									if (bumperOn == false) then
										local perOver = ((speedKM - maxSpeed)/maxSpeed)*100
										if (alertAlready==false) then
											if (perOver <= 20) then
												TriggerEvent('chat:addMessage', {
													color = { 255, 0, 0},
													multiline = false,
													args = {"SpeedCam", 'You were caught doing '..speedKM..' KM/H in a '..maxSpeed..' KM/H zone.'}
												})
												TriggerServerEvent('esx_billing:sendBill', playerID, 'society_police', 'Speeding ' .. speedKM .. ' KM/H in a '..maxSpeed..' KM/H Zone', (perOver*100)+cameraFineAdd)
												alertAlready = true
												Citizen.Wait(6000)
											else
												local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
												TriggerServerEvent('esx_phone:send', 'police', 'Vehicle '..plate..' speeding at '..cameraName..' going '..math.floor(perOver+0.5)..'% over the limit', true, {x =x, y =y, z =z})
												TriggerEvent('chat:addMessage', {
													color = { 255, 0, 0},
													multiline = false,
													args = {"SpeedCam", 'You were caught doing '..speedKM..' KM/H in a '..maxSpeed..' KM/H zone. Police have been informed'}
												})
												TriggerServerEvent('esx_billing:sendBill', playerID, 'society_police', 'Speeding ' .. speedKM .. ' KM/H in a '..maxSpeed..' KM/H Zone', (perOver*100)+cameraFineAdd)
												alertAlready = true
												Citizen.Wait(6000)
											end
										end
									end
								end
							end
						end
					end
					alertAlready = false
				end
			end
		end
	end
end)
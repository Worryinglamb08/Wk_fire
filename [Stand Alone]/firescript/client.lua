fireremover = {}
fireremoverParticles = {}
streetnames = {}


----------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------- CONFIG AREA -------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------
local chatStreetAlerts = true
local chanceForSpread = 700 -- basically a thousand sided dice is rolled and if it gets above this number then the fire spreads once
local randomFireCooldown = 2400000 -- how long for a location to be put back in the possible locations pool.
local randomFireLocations = { --  this is the format you need to put in for your possible locations.
	{ ['x'] = 620.95, ['y'] = 264.69, ['z'] = 103.28}, -- ved by Downtown
	{ ['x'] = -1388.61, ['y'] = -586.42, ['z'] = 34.11 }, -- ved by club
	{ ['x'] = -1185.59, ['y'] = -881.26, ['z'] = 13.85 }, -- ved by Burger shot
	{ ['x'] = -1066.29, ['y'] = -1146.14, ['z'] = 2.16 }, -- ved inventie cp
	{ ['x'] = 264.13, ['y'] = -1261.35, ['z'] = 29.29 },
	{ ['x'] = 1750.03, ['y'] = 3330.93, ['z'] = 41.13 },
	{ ['x'] = 1981.85, ['y'] = 3048.27, ['z'] = 47.22 },
	{ ['x'] = 2757.27, ['y'] = 1475.9, ['z'] = 30.79 },
	{ ['x'] = 2877.64, ['y'] = 1543.32, ['z'] = 24.72 },
	{ ['x'] = -70.35, ['y'] = 6263.5, ['z'] = 31.09 },
	{ ['x'] = -289.0, ['y'] = 6022.87, ['z'] = 31.47 },
	{ ['x'] = -314.44, ['y'] = 6312.94, ['z'] = 32.34 },
	{ ['x'] = 1548.89, ['y'] = 3586.53, ['z'] = 35.37 },
	{ ['x'] = 437.06, ['y'] = -982.32, ['z'] = 30.7 },
}

local fireHornLocation = {
  { x = 216.85, y = -1648.05, z = 30.72, name = "Davis Station"},
  { x = 1194.27, y = -1464.01, z = 36.65, name = "El Burro Station"},
  { x = -634.79, y = -124.02, z = 39.01, name = "Rockford Hills Station"},
  { x = -379.34, y = 6118.42, z = 31.85, name = "Paleto Fire Station"},
  { x = 1691.79, y = 3584.92, z = 36.6, name = "Sandy Shores Fire Station"},
  { x = -1030.88, y = -2374.77, z = 20.61, name = "Los Santos Airport Fire Station"},
  { x = -1189.27, y = -1784.38, z = 15.62, name = "Vespucci Beach LifeGuard Station"},
}
local FireModels = {
	[GetHashKey("S_M_Y_Fireman_01")] = true,
	[GetHashKey("s_f_y_paramedic_01")] = true,
}
local msg = function(text,ms)
	exports.pNotify:SendNotification({text = text,type = "error",timeout = (ms or 9000),layout = "centerLeft",queue = "right"})
end

------------------------------          ------------------------------
------------------------------ Dispatch ------------------------------
------------------------------          ------------------------------
RegisterNetEvent("triggerSound")
AddEventHandler("triggerSound", function()
  local plX, plY, plZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), true)) --Gets player XYZ
  local nearestStation

  for i = 1, #fireHornLocation, 1 do

    local distDiff = Vdist(plX, plY, plZ, fireHornLocation[i].x, fireHornLocation[i].y, fireHornLocation[i].z) --Gets distance between player and firestation[i]
    local nearestStationDiff

    if nearestStation == nil then --if there is no nearest station yet (first run) then...
      nearestStation = i
      nearestStationDiff = Vdist(plX, plY, plZ, fireHornLocation[i].x, fireHornLocation[i].y, fireHornLocation[i].z) --Gets distance between player and firestation[i]
    else -- if there already a value attached to "nearestStation"
      nearestStationDiff = Vdist(plX, plY, plZ, fireHornLocation[nearestStation].x, fireHornLocation[nearestStation].y, fireHornLocation[nearestStation].z) --Gets distance between player and nearest station so far
    end

    if distDiff <= nearestStationDiff then -- if new station is the closest yet
      nearestStation = i -- assign new closest station
    end
  end


  ---- PLAYING THE SOUND IN A RIDDM
  for i = 1, 10, 1 do -- repeat to make it sound like an alarm
    for i = 1, 10, 1 do -- used to make it louder
      PlaySoundFromCoord(i, "scanner_alarm_os", fireHornLocation[nearestStation].x, fireHornLocation[nearestStation].y, fireHornLocation[nearestStation].z, "dlc_xm_iaa_player_facility_sounds", 1, 500, 0) --Plays sound from nearest station
    end
    Wait(1000)
  end
  Wait(1000)
  for i = 1, 3, 1 do -- repeat to make it sound like an alarm
    for i = 1, 10, 1 do -- used to make it louder
      PlaySoundFromCoord(i, "scanner_alarm_os", fireHornLocation[nearestStation].x, fireHornLocation[nearestStation].y, fireHornLocation[nearestStation].z, "dlc_xm_iaa_player_facility_sounds", 1, 500, 0) --Plays sound from nearest station
    end
    Wait(2000)
  end
end)

local reportFire = function(x,y,z)
	--msg(string.format("FIRE AT %.2f, %.2f, %.2f.",x,y,z),3000)
	--xpcall(function()
		local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, x, y, z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
		TriggerServerEvent('fireInProgressPos', x, y, z)
		--msg("Yes it fucking triggered, just to be sure.")
		if s2 == 0 then
			TriggerServerEvent('fireInProgressS1', GetStreetNameFromHashKey(s1))
		else
			TriggerServerEvent("fireInProgress", GetStreetNameFromHashKey(s1), GetStreetNameFromHashKey(s2))
		end
    --end,function(m)
	--	msg(debug.traceback("FAILURE: "..tostring(m).."."))
	--end)
end
RegisterNetEvent("lol:askfireman")
RegisterNetEvent("lol:random")
AddEventHandler("lol:askfireman",function()
	if FireModels[GetEntityModel(GetPlayerPed(-1))] then
		TriggerServerEvent("lol:amfireman")
	end
end)
AddEventHandler("lol:random",function()
	local possibleLocations = #randomFireLocations
	if possibleLocations == 0 then
		return
	end
	local LocationID = math.random(1, possibleLocations)
	local location = table.remove(randomFireLocations,LocationID)
	local x = location.x
	local y = location.y
	local z = location.z
	FSData.originalfiremaker = tostring(GetPlayerPed(-1))
	CreateThread(function()
		Wait(randomFireCooldown)
		table.insert(randomFireLocations,location)
	end)
	
	if not HasNamedPtfxAssetLoaded("core") then
		RequestNamedPtfxAsset("core")
		while not HasNamedPtfxAssetLoaded("core") do
			Wait(0)
		end
	end
	SetPtfxAssetNextCall("core")
	
	
	
	table.insert(FSData.lastamnt, 20)
	
	local rand = math.random(1, 200)
	if rand > 100 then
		table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", x, y, z-0.8, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
	else
		table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_h_fire", x, y, z-0.8, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
	end
	table.insert(FSData.lastamnt, x)
	table.insert(FSData.lastamnt, y)
	table.insert(FSData.lastamnt, z-0.8)
	
	table.insert(fireremover, StartScriptFire (x, y, z-0.8, 25, false))
	table.insert(fireremover, x)
	table.insert(fireremover, y)
	table.insert(fireremover, z-0.8)
	local firec = {}
	local lastamnt = {}
	local deletedfires = {}
	for i=1,#FSData.firecoords do
		firec[i] = FSData.firecoords[i]
	end
	for i=1,#FSData.lastamnt do
		lastamnt[i] = FSData.lastamnt[i]
	end
	for i=1,#FSData.deletedfires do
		deletedfires[i] = FSData.deletedfires[i]
	end
	local original = tostring(FSData.originalfiremaker)
	if chatStreetAlerts == true then
		chatAlerts(x, y, z)
		TriggerServerEvent("fire:syncedAlarm") -- Starts fire alarm
		--TriggerServerEvent("Fire-EMS-Pager:PageTones", {"fire"}, true, {"Brand Ved:"})
		TriggerServerEvent("Fire-EMS-Pager:PageTones", {"fire"}, false)
	end
	TriggerServerEvent("lol:firesyncs", firec, lastamnt, deletedfires, original)
	reportFire(x,y,z)
end)
function chatAlerts(x, y, z)
	Citizen.CreateThread(function() 
		local text = "dette"
		local streetA, streetB = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, x, y, z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
		
		table.insert( streetnames, GetStreetNameFromHashKey( streetA ) )
		if tostring(streetB) ~= "0" then
			table.insert( streetnames, GetStreetNameFromHashKey( streetB ) )
		end
		if tostring(streetB) ~= "0" then
			text = table.concat( streetnames, " & " )
		else
			text = GetStreetNameFromHashKey( streetA ) 
		end
		TriggerServerEvent("fire:chatAlert", text)
		streetnames = {}
		
	end)
end


----------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------- Handles the use of /fire -----------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:firethings")
AddEventHandler("lol:firethings", function()
	local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
	FSData.removeallfires = false
    local coordis = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
    local count = math.random(3, 6)
	FSData.originalfiremaker = tostring(GetPlayerPed(-1))
    while (count > 0) do
        x = x + math.random(-5, 5)
        y = y + math.random(-5, 5)
        if not HasNamedPtfxAssetLoaded("core") then
	    	RequestNamedPtfxAsset("core")
	        while not HasNamedPtfxAssetLoaded("core") do
		        Wait(1)
	        end
        end
		SetPtfxAssetNextCall("core")

        table.insert(FSData.lastamnt, 20)
        local rand = math.random(1, 200)
		if rand > 100 then
			table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", x+5, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
		else
			table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_h_fire", x+5, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
		end
		table.insert(FSData.lastamnt, x+5)
        table.insert(FSData.lastamnt, y)
        table.insert(FSData.lastamnt, z-0.7)
        table.insert(fireremover, StartScriptFire (x+5, y, z-0.8, 24, false))
        table.insert(fireremover, x+5)
        table.insert(fireremover, y)
        table.insert(fireremover, z-0.8)
		count = count - 1
    end
    local firec = {}
		local lastamnt = {}
		local deletedfires = {}
		for i=1,#FSData.firecoords do
			firec[i] = FSData.firecoords[i]
		end
		for i=1,#FSData.lastamnt do
			lastamnt[i] = FSData.lastamnt[i]
		end
		for i=1,#FSData.deletedfires do
			deletedfires[i] = FSData.deletedfires[i]
		end
		local original = tostring(FSData.originalfiremaker)
		TriggerServerEvent("lol:firesyncs", firec, lastamnt, deletedfires, original)
                
        
        if chatStreetAlerts == true then
            chatAlerts(x, y, z)
			TriggerServerEvent("fire:syncedAlarm") -- Starts fire alarm
			TriggerServerEvent("Fire-EMS-Pager:PageTones", {"fire"}, false)
        end
		reportFire(x,y,z)
	--firehelper(fireremover)		
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------- Remove all fires currently not working ----------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:firestop")
AddEventHandler("lol:firestop", function()
		for i=1,#fireremover do
		     RemoveScriptFire(fireremover[i])
		end
        for i=1,#fireremoverParticles do
		   
			RemoveParticleFx(fireremoverParticles[i], true)
		end
		for i=1,#FSData.lastamnt do
		    RemoveParticleFx(FSData.lastamnt[i], true)
			
		end
		fireremoverParticles = {}
		fireremover = {}
end)
RegisterNetEvent("lol:fireremovesync")
AddEventHandler("lol:fireremovesync", function( firec, lastamnt, deletedfires, original )
		
			FSData.originalfiremaker = original
			
			for i=1,#firec do
					FSData.firecoords[i] = firec[i]
			end
			for i=1,#lastamnt do
					FSData.lastamnt[i] = lastamnt[i]
			end
			for i=1,#deletedfires do
					FSData.deletedfires[i] = deletedfires[i]
			end
			
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------- Thread to handle fire syncing --------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:firesyncs2")
AddEventHandler("lol:firesyncs2", function( firec, lastamnt, deletedfires, original )
		
			FSData.originalfiremaker = original
			
			for i=1,#firec do
					FSData.firecoords[i] = firec[i]
			end
			for i=1,#lastamnt do
					FSData.lastamnt[i] = lastamnt[i]
			end
			for i=1,#deletedfires do
					FSData.deletedfires[i] = deletedfires[i]
			end
				TriggerServerEvent("lol:firesyncs60")
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------- just a debug function ------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:test2")
AddEventHandler("lol:test2", function( test )
		TriggerEvent("chatMessage", "FIRE", {255, 0, 0},"test string: " .. tostring(test))
end)
function firehelper(fireremover)
for i=1,#fireremover do
		     PlaceObjectOnGroundProperly(fireremover[i])
		end

end

----------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------- Produces players coordinates in chat -----------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:coords")
AddEventHandler("lol:coords", function()
		local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
                TriggerEvent("chatMessage", "Coords", {255, 0, 0},"X: " .. tostring(x) .. " Y: " .. tostring(y) .. " Z: " .. tostring(z))
				
				
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------- Produces a count of all fires spawned sense last script restart --------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:firecounter")
AddEventHandler("lol:firecounter", function()
		local counter = 0
		for i=1,#FSData.lastamnt do
			if FSData.lastamnt[i-1] == 20 or  FSData.lastamnt[i-1] == 1 then
				counter = counter + 1
			end
		end
		TriggerEvent("chatMessage", "Coords", {255, 0, 0},"Der var " .. counter .. " brande i dag indtil videre.")
				
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------- Spawns all fires synced to client ------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:firesync3")
AddEventHandler("lol:firesync3", function()
	for i=1,#FSData.lastamnt do
		if FSData.lastamnt[i-1] == 20 then
	
			local x = FSData.lastamnt[i+1]
			local y = FSData.lastamnt[i+2]
			local z = FSData.lastamnt[i+3]
			SetPtfxAssetNextCall("core")
			if FSData.originalfiremaker ~= tostring(GetPlayerPed(-1)) then
				local rand = math.random(1, 200)
				if rand > 100 then
					table.insert(fireremoverParticles, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", x, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
				else
					table.insert(fireremoverParticles, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_h_fire", x, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
				end
				table.insert(fireremover, StartScriptFire (x, y, z-0.1, 25, false))
			end
		end
	end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------- Sets fires under the last vehicle ped was in --------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:carbomb")
AddEventHandler("lol:carbomb", function()
	FSData.removeallfires = false
		
	local vehicle = GetPlayersLastVehicle()
	if (vehicle == nil) then
	    return
	end
	FSData.originalfiremaker = tostring(GetPlayerPed(-1))
	local x, y, z = table.unpack(GetEntityCoords(vehicle, true))
    TriggerEvent("chatMessage", "FIRE", {255, 0, 0},"Du fik den bil til at gå BOOM!")
		
	local count = math.random(2,10)
    while (count > 0) do
        x = x + math.random(-1, 1)
        y = y + math.random(-1, 1)
		if not HasNamedPtfxAssetLoaded("core") then
			RequestNamedPtfxAsset("core")
			while not HasNamedPtfxAssetLoaded("core") do
				Wait(1)
			end
		end
		SetPtfxAssetNextCall("core")
		table.insert(FSData.lastamnt, 20)
                
				
        local rand = math.random(1, 200)
		if rand > 100 then
			table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", x, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
		else
			table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_h_fire", x, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
		end
		table.insert(FSData.lastamnt, x)
        table.insert(FSData.lastamnt, y)
        table.insert(FSData.lastamnt, z)
    	table.insert(fireremover, StartScriptFire (x, y, z-0.8, 24, false))
  		table.insert(fireremover, x)
        table.insert(fireremover, y)
        table.insert(fireremover, z)
		count = count - 1
    end
    local firec = {}
	local lastamnt = {}
	local deletedfires = {}
	for i=1,#FSData.firecoords do
		firec[i] = FSData.firecoords[i]
	end
	for i=1,#FSData.lastamnt do
		lastamnt[i] = FSData.lastamnt[i]
	end
	for i=1,#FSData.deletedfires do
		deletedfires[i] = FSData.deletedfires[i]
	end
	local original = tostring(FSData.originalfiremaker)
	TriggerServerEvent("lol:firesyncs", firec, lastamnt, deletedfires, original)
    if chatStreetAlerts == true then
        --chatAlerts(x, y, z)
		TriggerServerEvent("fire:syncedAlarm") -- Starts fire alarm
		TriggerServerEvent("Fire-EMS-Pager:PageTones", {"fire"}, true, {"Brand i en bil"})
    end
	reportFire(x,y,z)
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------- Responsible for syncing fires to all clients (deprecated) ----------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:firesync")
AddEventHandler("lol:firesync", function()

		local removedFires = FSData.removeallfires
		local fireCoords = FSData.firecoords

		if removedFires == true then
			for i=1,#fireremover do
				RemoveScriptFire(fireremover[i])
			end
			for i=1,#fireremoverParticles do
				RemoveParticleFx(fireremoverParticles[i], true)
			end
			fireremoverParticles = {}
			fireremover = {}
			removedFires = false
			FSData.originalfiremaker = nil
			local firec = {}
			local lastamnt = {}
			local deletedfires = {}
			for i=1,#FSData.firecoords do
					firec[i] = FSData.firecoords[i]
			end
			for i=1,#FSData.lastamnt do
					lastamnt[i] = FSData.lastamnt[i]
			end
			for i=1,#FSData.deletedfires do
					deletedfires[i] = FSData.deletedfires[i]
			end
			
				local original = tostring(FSData.originalfiremaker)
				TriggerServerEvent("lol:firesyncs", firec, lastamnt, deletedfires, original)
		end
		
		
	
		
		
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------- Mostly unused but still here for debuging ----------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent("lol:fireremovess")
AddEventHandler("lol:fireremovess", function( x, y, z, test )
		
	local l = test
		
	for i=1,#fireremoverParticles do
		if fireremoverParticles[l+1] == fireremoverParticles[i+1] then
			RemoveParticleFxInRange(fireremoverParticles[i+1], fireremoverParticles[i+2], fireremoverParticles[i+3], 1.5)
		end
	end
	for i=1,#FSData.lastamnt do
		if FSData.lastamnt[i+1] == FSData.lastamnt[l+1] then
			RemoveParticleFxInRange(FSData.lastamnt[i+1], FSData.lastamnt[i+2], FSData.lastamnt[i+3], 1.5)
			FSData.lastamnt[i-1] = 1
		end
	end
		
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------- Thread to handle spawning initial fire ---------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
Citizen.CreateThread(function() 
	while true do 
		Citizen.Wait(0)
		if IsControlJustPressed(1, 28) then -- button f7
			FSData.originalfiremaker = tostring(GetPlayerPed(-1))
				
			local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
			local coords = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
                                          
                
			if not HasNamedPtfxAssetLoaded("core") then
				RequestNamedPtfxAsset("core")
				while not HasNamedPtfxAssetLoaded("core") do
					Wait(1)
				end
			end
			SetPtfxAssetNextCall("core")
			
			
		
			table.insert(FSData.lastamnt, 20)
		
           	local rand = math.random(1, 200)
			if rand > 100 then
				table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", x+5, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
			else
				table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_h_fire", x+5, y, z-0.7, 0.0, 0.0, 0.0, 1.0, false, false, false, false))
			end
			table.insert(FSData.lastamnt, x+5)
      		table.insert(FSData.lastamnt, y)
           	table.insert(FSData.lastamnt, z-0.7)
		
           	table.insert(fireremover, StartScriptFire (x+5, y, z-0.8, 25, false))
           	table.insert(fireremover, x+5)
           	table.insert(fireremover, y)
           	table.insert(fireremover, z-0.8)
			local firec = {}
			local lastamnt = {}
			local deletedfires = {}
			for i=1,#FSData.firecoords do
				firec[i] = FSData.firecoords[i]
			end
			for i=1,#FSData.lastamnt do
				lastamnt[i] = FSData.lastamnt[i]
			end
			for i=1,#FSData.deletedfires do
				deletedfires[i] = FSData.deletedfires[i]
			end
			local original = tostring(FSData.originalfiremaker)
			if chatStreetAlerts == true then
            	chatAlerts(x, y, z)
        	end
			TriggerServerEvent("lol:firesyncs", firec, lastamnt, deletedfires, original)
			Citizen.Wait(2000)
		end
	end 
end)]]

----------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------- Thread to handle spreading of fires -----------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()

	while true do
				
				Wait(1000)
                for i=1,#FSData.lastamnt do
					Wait(50)
					
					if FSData.lastamnt[i-1] == 20 then
						
					
				    if not HasNamedPtfxAssetLoaded("core") then
						RequestNamedPtfxAsset("core")
						while not HasNamedPtfxAssetLoaded("core") do
							Wait(1)
						end
					end
					
					SetPtfxAssetNextCall("core")
					if DoesEntityExist(FSData.lastamnt[i]) then
						
						PlaceObjectOnGroundProperly(FSData.lastamnt[i])
					end
					
                        local x = FSData.lastamnt[i+1]
                        local y = FSData.lastamnt[i+2]
                        local z = FSData.lastamnt[i+3]
						
					--if FSData.originalfiremaker == tostring(GetPlayerPed(-1)) then					
                    	if GetNumberOfFiresInRange(x, y, z, 1) == 0 then
							if GetNumberOfFiresInRange(x, y, z, 1) == 0 then
								TriggerServerEvent("lol:removefires", x, y, z, i)							
							end
                   		end
					--end
																	
						local chances = math.random(1, 1000)
						if chances > chanceForSpread then
						if FSData.originalfiremaker == tostring(GetPlayerPed(-1)) then
						
							local xrand = FSData.lastamnt[i+1] + math.random(-6, 6)
							local yrand = FSData.lastamnt[i+2] + math.random(-6, 6)
							while xrand > -1 and xrand < 2 do
								xrand = xrand + math.random(2, 6)
							end
							while yrand > -1 and yrand < 2 do
								yrand = yrand + math.random(2, 6)
							end
							
							table.insert(FSData.lastamnt, 20)
							
							
							local rand = math.random(1, 200)
							if rand > 100 then
								table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", xrand, yrand, FSData.lastamnt[i+3], 0.0, 0.0, 0.0, 1.0, false, false, false, false))
							else
								table.insert(FSData.lastamnt, StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_h_fire", xrand, yrand, FSData.lastamnt[i+3], 0.0, 0.0, 0.0, 1.0, false, false, false, false))
							end
							table.insert(FSData.lastamnt, xrand)
							table.insert(FSData.lastamnt, yrand)
							table.insert(FSData.lastamnt, FSData.lastamnt[i+3])
							table.insert(fireremover, StartScriptFire (xrand, yrand, FSData.lastamnt[i+3]-0.1, 25, false))
							table.insert(fireremover, xrand)
							table.insert(fireremover, yrand)
							table.insert(fireremover, FSData.lastamnt[i+3]-0.1)
			local firec = {}
			local lastamnt = {}
			local deletedfires = {}
			for i=1,#FSData.firecoords do
					firec[i] = FSData.firecoords[i]
			end
			for i=1,#FSData.lastamnt do
					lastamnt[i] = FSData.lastamnt[i]
			end
			for i=1,#FSData.deletedfires do
					deletedfires[i] = FSData.deletedfires[i]
			end
	
				local original = tostring(FSData.originalfiremaker)
				TriggerServerEvent("lol:firesyncs", firec, lastamnt, deletedfires, original)
				end
						end
                   
		end
				end
				
		Citizen.Wait(50)
		    
	end
end)
local remotePeripherals = (...)

local function round(val, decimal)
	if decimal then
		return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
	else
		return math.floor(val+0.5)
	end
end

return {
	width = 170,
	height = 200,
	add = function(name, window)
		local fuelBar = advancedTiles.addComplexBar(window, 10, 100, 0, 60, 30, 0xdede6c, 1)
		fuelBar:SetRotation(270)
		fuelBar:GetBackground():SetClickable(false)
		window:AddText(10, 31, "Fuel", 0x000000)

		local wasteBar = advancedTiles.addComplexBar(window, 10, 100, 2, 60, 30, 0x4c99b2, 1)
		wasteBar:SetRotation(270)
		local wasteBackground = wasteBar:GetBackground()
		wasteBackground:SetClickable(false)
		wasteBackground:SetVisible(false)

		local caseBar = advancedTiles.addComplexBar(window, 50, 100, 0, 60, 30, 0x0000ff, 1)
		caseBar:SetRotation(270)
		caseBar:GetBackground():SetClickable(false)
		window:AddText(50, 21, "Case", 0x000000)
		window:AddText(50, 31, "Heat", 0x000000)

		local coreBar = advancedTiles.addComplexBar(window, 90, 100, 0, 60, 30, 0x0000ff, 1)
		coreBar:SetRotation(270)
		coreBar:GetBackground():SetClickable(false)
		window:AddText(90, 21, "Core", 0x000000)
		window:AddText(90, 31, "Heat", 0x000000)

		local energyBar = advancedTiles.addComplexBar(window, 130, 100, 0, 60, 30, 0xff0000, 1)
		energyBar:SetRotation(270)
		energyBar:GetBackground():SetClickable(false)
		window:AddText(130, 31, "RF", 0x000000)

		local fluidWindow = guiTiles.newBasicWindow(window:AddSubTile(170, 60, -3), 55, 95, false)
		fluidWindow:SetVisible(false)
		fluidWindow:SetClickable(false)
		guiTiles.makeDraggable(window, fluidWindow:GetBackground())

		fluidWindow:AddText(5, 6, "Coolant:", 0x000000)

		local coolantBar = advancedTiles.addSimpleFluidBar(fluidWindow, 5, 90, 0, 70, 20, "water", 1)
		coolantBar:SetRotation(270)
		coolantBar:GetBackground():SetClickable(false)

		local steamBar = advancedTiles.addSimpleFluidBar(fluidWindow, 30, 90, 0, 70, 20, "water", 1)
		steamBar:SetRotation(270)
		steamBar:GetBackground():SetClickable(false)

		local object = {
			windowID = window:GetUserdata()[2],
			displays = {
				fuelBar = fuelBar,
				wasteBar = wasteBar,
				caseBar = caseBar,
				coreBar = coreBar,
				energyBar = energyBar,
				statusText = window:AddText(10, 121, "Status: Offline", 0xff0000),
				rfText = window:AddText(10, 136, "Energy Output: 0 RF/t", 0x000000),
				fuelText = window:AddText(10, 151, "Fuel Usage: 0 mB/t", 0x000000),
				reactivityText = window:AddText(10, 166, "Reactivity: 0%", 0x000000),
				fluidWindow = fluidWindow,
				coolantBar = coolantBar,
				steamBar = steamBar,
			},
			curStatus = false,
			activelyCooled = false,
			coolantType = false,
			hotFluidType = false,
		}

		return object
	end,
	update = function(name, object)
		local data = remotePeripherals:GetMainData(name)
		if data then
			local fuelPercent = 0
			local wastePercent = 0
			local curFuel = data.getFuelAmount
			local curWaste = data.getWasteAmount
			local maxFuel = data.getFuelAmountMax
			if type(curFuel) == "number" and type(curWaste) == "number" and type(maxFuel) == "number" then
				fuelPercent = (curFuel + curWaste)/maxFuel
				wastePercent = curWaste/maxFuel
			end
			object.displays.fuelBar:SetPercent(fuelPercent)
			object.displays.wasteBar:SetPercent(wastePercent)

			local casePercent = 0
			local curCase = data.getCasingTemperature
			local maxCase = 2000
			if type(curCase) == "number" and type(maxCase) == "number" then
				casePercent = curCase/maxCase
			end
			object.displays.caseBar:SetPercent(casePercent)

			local corePercent = 0
			local curCore = data.getFuelTemperature
			local maxCore = 2000
			if type(curCore) == "number" and type(maxCore) == "number" then
				corePercent = curCore/maxCore
			end
			object.displays.coreBar:SetPercent(corePercent)

			local energyPercent = 0
			local curEnergy = data.getEnergyStored
			local maxEnergy = 10000000
			if type(curEnergy) == "number" and type(maxEnergy) == "number" then
				energyPercent = curEnergy/maxEnergy
			end
			object.displays.energyBar:SetPercent(energyPercent)

			if data.getActive ~= object.curStatus then
				object.curStatus = data.getActive
				if data.getActive == true then
					object.displays.statusText:SetText("Status: Online")
					object.displays.statusText:SetColor(0x00ff00)
				elseif data.getActive == false then
					object.displays.statusText:SetText("Status: Offline")
					object.displays.statusText:SetColor(0xff0000)
				end
			end

			if data.isActivelyCooled then
				-- update fluid subTile
				local coolantPercent = 0
				if type(data.getCoolantAmount) == "number" and type(data.getCoolantAmountMax) == "number" then
					coolantPercent = data.getCoolantAmount/data.getCoolantAmountMax
				end
				object.displays.coolantBar:SetPercent(coolantPercent)
				if object.coolantType ~= data.getCoolantType then
					object.coolantType = data.getCoolantType
					object.displays.coolantBar:GetBar():SetFluid(object.coolantType)
				end

				local hotFluidPercent = 0
				if type(data.getHotFluidAmount) == "number" and type(data.getHotFluidAmountMax) == "number" then
					hotFluidPercent = data.getHotFluidAmount/data.getHotFluidAmountMax
				end
				object.displays.steamBar:SetPercent(hotFluidPercent)
				if object.hotFluidType ~= data.getHotFluidType then
					object.hotFluidType = data.getHotFluidType
					object.displays.steamBar:GetBar():SetFluid(object.hotFluidType)
				end
			end

			if data.isActivelyCooled ~= object.activelyCooled then
				object.activelyCooled = data.isActivelyCooled
				object.displays.fluidWindow:SetVisible(object.activelyCooled)
				object.displays.fluidWindow:SetClickable(object.activelyCooled)
			end

			if data.isActivelyCooled and type(data.getHotFluidProducedLastTick) == "number" then
				object.displays.rfText:SetText("Steam Output: "..tostring(round(data.getHotFluidProducedLastTick)).." mB/t")
			elseif type(data.getEnergyProducedLastTick) == "number" then
				object.displays.rfText:SetText("Energy Output: "..tostring(round(data.getEnergyProducedLastTick)).." RF/t")
			end

			if type(data.getFuelConsumedLastTick) == "number" then
				object.displays.fuelText:SetText("Fuel Usage: "..tostring(round(data.getFuelConsumedLastTick, 3)).." mB/t")
			end

			if type(data.getFuelReactivity) == "number" then
				object.displays.reactivityText:SetText("Reactivity: "..tostring(data.getFuelReactivity).."%")
			end
		end
	end,
}

local updateOnly = (...) == "--update"

local noOverwrite = (...) == "true"

local rootURL = "https://raw.githubusercontent.com"
local githubUsername = "blunty666"

local mainURL = table.concat({rootURL, githubUsername}, "/")

local saveDir = "baseMonitor"
if fs.exists(saveDir) and not fs.isDir(saveDir) then
	printError("Invalid saveDir: ", saveDir)
	return
end

local fileList

if not updateOnly then
	fileList = {
		["baseMonitor"] = {"Tiles", "programs/baseMonitor/baseMonitor.lua"},

		["apis/tiles"] = {"Tiles", "tiles.lua"},
		["apis/guiTiles"] = {"Tiles", "apis/guiTiles.lua"},
		["apis/advancedTiles"] = {"Tiles", "apis/advancedTiles.lua"},
		["apis/remotePeripheralClient"] = {"CC-Programs-and-APIs", "remotePeripheral/remotePeripheralClient"},
	}
else
	fileList = {}
end

local peripheralListHandle = http.get(table.concat({mainURL, "Tiles", "master", "programs/baseMonitor/peripheralList"}, "/"))
if peripheralListHandle then
	local peripheralType = peripheralListHandle.readLine()
	while peripheralType do
		if not updateOnly or not fs.exists(fs.combine(saveDir, "peripherals/"..peripheralType)) then
			fileList["peripherals/"..peripheralType] = {"Tiles", "programs/baseMonitor/peripherals/"..peripheralType..".lua"}
		end
		peripheralType = peripheralListHandle.readLine()
	end
	peripheralListHandle.close()
else
	printError("Could not download peripheralList")
end

local sourceListHandle = http.get(table.concat({mainURL, "Tiles", "master", "programs/baseMonitor/sourceList"}, "/"))
if sourceListHandle then
	local sourceType = sourceListHandle.readLine()
	while sourceType do
		if not updateOnly or not fs.exists(fs.combine(saveDir, "sources/"..sourceType)) then
			fileList["sources/"..sourceType] = {"Tiles", "programs/baseMonitor/sources/"..sourceType..".lua"}
		end
		sourceType = sourceListHandle.readLine()
	end
	sourceListHandle.close()
else
	printError("Could not download sourceList")
end

local function get(url)
	local response = http.get(url)			
	if response then
		local fileData = response.readAll()
		response.close()
		return fileData
	end
	return false
end

local function save(fileData, path)
	local handle = fs.open(path, "w")
	if handle then
		handle.write(fileData)
		handle.close()
		return true
	else
		return false
	end
end

for localPath, remotePathDetails in pairs(fileList) do
	local url = table.concat({mainURL, remotePathDetails[1], "master", remotePathDetails[2]}, "/")
	local path = table.concat({saveDir, localPath}, "/")
	if not fs.exists(path) or not (fs.isDir(path) or noOverwrite) then
		local fileData = get(url)			
		if fileData then
			if save(fileData, path) then
				print("Download successful: ", localPath)
			else
				print("Save failed: ", localPath)
			end
		else
			print("Download failed: ", localPath)
		end
	else
		print("Skipping: ", localPath)
	end
end

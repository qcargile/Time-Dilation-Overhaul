local modName = "TDO"

function migrateSandysToVanillaSandyKeys(config, oldVersion)
	if oldVersion == nil or oldVersion >= 10.0 then return false end
	if type(config.sandys) ~= "table" then return false end

	local mapping = {
		[1] = { section = "zetatech",   hasCrit = false },
		[2] = { section = "tanto",      hasCrit = true  },
		[3] = { section = "warpDancer", hasCrit = false },
		[4] = { section = "falcon",     hasCrit = true  },
		[5] = { section = "apogee",     hasCrit = false },
	}

	local copied = false
	for sandyIdx, info in pairs(mapping) do
		local src = config.sandys[sandyIdx]
		local dst = config[info.section]
		if type(src) == "table" and type(dst) == "table" then
			if type(src.ts) == "table" then
				if src.ts.min ~= nil then dst.slowTimeMinPct = src.ts.min; copied = true end
				if src.ts.max ~= nil then dst.slowTimeMaxPct = src.ts.max; copied = true end
			end
			if type(src.dur) == "table" then
				if src.dur.min ~= nil then dst.durationMin = src.dur.min; copied = true end
				if src.dur.max ~= nil then dst.durationMax = src.dur.max; copied = true end
			end
			if type(src.rchrg) == "table" then
				if src.rchrg.min ~= nil then dst.rechargeMin = src.rchrg.min; copied = true end
				if src.rchrg.max ~= nil then dst.rechargeMax = src.rchrg.max; copied = true end
			end
			if info.hasCrit then
				if type(src.critCh) == "table" then
					if src.critCh.min ~= nil then dst.critChanceMin = src.critCh.min; copied = true end
					if src.critCh.max ~= nil then dst.critChanceMax = src.critCh.max; copied = true end
				end
				if type(src.critDmg) == "table" then
					if src.critDmg.min ~= nil then dst.critDmgMin = src.critDmg.min; copied = true end
					if src.critDmg.max ~= nil then dst.critDmgMax = src.critDmg.max; copied = true end
				end
			end
		end
	end

	config.sandys = nil
	if copied then
		print("[TDO] INFO: Migrated pre-v10.0 Sandy slider tunings to new per-Sandy keys.")
	end
	return copied
end

function ArraySize(tableArray)
	local count = 0
	for _ in pairs(tableArray) do count = count + 1 end
	return count
end

function saveSettings(stuff)
	local validJson, contents = pcall(function() return json.encode(stuff) end)

	if validJson and contents ~= nil then
		local file = io.open("config/nUISettings.json", "w+")
		if file ~= nil then
			file:write(contents)
			file:close()
			print("["..modName.."]: \"config/nUISettings.json\" successfully saved.")
		else
			print("["..modName.."] ERROR: Could not open/create \"config/nUISettings.json\" file to save settings.")
		end
	else
		print("["..modName.."] ERROR: Error encoding settings for \"config/nUISettings.json\". Settings not saved.")
	end

end

function loadSettings()
	local file = io.open("config/nUISettings.json", "r")

	if file == nil then
		print("["..modName.."] CAUTION: Could not open nUISettings.json file. Reverting to userConfig.lua settings. This is totally normal on the first run of this mod.")
		local config = require("config/userConfig.lua")
		saveSettings(config)
		return config
	else
		local jsonString = file:read("*all")
		local validJson, savedSettings = pcall(function() return json.decode(jsonString) end)
		file:close()
		if validJson and type(savedSettings) == "table" then
			if type(savedSettings.configVersion) ~= "number" then savedSettings.configVersion = nil end
			print("["..modName.."]: \"config/nUISettings.json\" successfully loaded.")
			return savedSettings
		else
			print("["..modName.."] ERROR: Contents of nUISettings.json are invalid. Reverting to userConfig.lua settings.")
			local config = require("config/userConfig.lua")
			saveSettings(config)
			return config
		end
	end
end

local function mergeSettings(old, defaults, missing, path)
	local merged = {}
	if type(old) ~= "table" then old = {} end
	for key, fallback in pairs(defaults) do
		local value = old[key]
		local keyPath = path == "" and tostring(key) or path .. "." .. tostring(key)
		if type(value) ~= type(fallback) then
			missing[#missing + 1] = keyPath
			value = nil
		end
		if type(fallback) == "table" then
			merged[key] = mergeSettings(value, fallback, missing, keyPath)
		else
			if value == nil then value = fallback end
			merged[key] = value
		end
	end
	return merged
end

function configUpdate(old, new)
	local updated = mergeSettings(old, new, {}, "")
	updated.configVersion = new.configVersion
	return updated
end

function configValidate(old, new)
	local missing = {}
	local updated = mergeSettings(old, new, missing, "")
	updated.configVersion = new.configVersion
	if #missing > 0 then
		print("["..modName.."] ERROR: Config had missing or invalid entries, which have been populated with defaults:")
		for _, key in ipairs(missing) do
			print("		" .. key)
		end
	else
		print("["..modName.."] STATUS: Config is valid.")
	end
	return #missing > 0, updated
end

function has_value(table, find)
	if type(table) == "table" then
		for i, v in ipairs(table) do
			if v == find then
				return true
			end
		end
	end
    return false
end

function find_index(table, find)
	if type(table) == "table" then
		for i, v in ipairs(table) do
			if v == find then
				return i
			end
		end
	end
    return 0
end

function addFlatsToFlatArr(flat, tdbids)
	local statMods = TweakDB:GetFlat(flat)
	local checkID

	if type(tdbids) ~= "table" then
		print(modName.." Function addFlatsFromFlatArr() Error: Expected 'tbdid' to be table.\nflat: "..flat.."\ntdbids: "..tostring(tdbids))
		return
	end

	if statMods == nil then
		statMods = {}
	end

	for i=1, #tdbids, 1 do
		checkID = TweakDBID(tdbids[i])
		if has_value(statMods, checkID) == false then
			table.insert(statMods, tdbids[i])
		end
	end
	TweakDB:SetFlat(TweakDBID.new(flat), statMods)
end

function removeFlatsFromFlatArr(flat, tdbids)
	local statMods = TweakDB:GetFlat(flat)
	local checkID
	if type(tdbids) ~= "table" then
		print(modName.." Function removeFlatsFromFlatArr() Error: Expected 'tbdid' to be table.\nflat: "..flat.."\ntdbids: "..tostring(tdbids))
		return
	end

	if statMods then
		for i=1, #tdbids, 1 do
			checkID = TweakDBID(tdbids[i])
			if has_value(statMods, checkID) == true then
				for p,q in pairs(statMods) do
					if q == checkID then
						table.remove(statMods,p)
						break
					end
				end
			end
		end
		TweakDB:SetFlat(TweakDBID.new(flat), statMods)
	end
end

function delRecord(record)
	if TweakDB:GetRecord(record) then
		TweakDB:DeleteRecord(record)
	end
end

function createConstMod(id, modifierType, statType, value)
	if TweakDB:GetRecord(id) == nil then
		TweakDB:CreateRecord(id, "gamedataConstantStatModifier_Record")
		TweakDB:SetFlat(id..".modifierType",modifierType)
		TweakDB:SetFlat(id..".statType",statType)
		TweakDB:SetFlat(id..".value",value)
	end
end

function createUI(id, ints, floats, localizedDescription)
	if TweakDB:GetRecord(id)== nil then
		TweakDB:CreateRecord(id,"gamedataGameplayLogicPackageUIData_Record")
		if floats ~= nil then
			if type(floats) == "table" then
				TweakDB:SetFlat(id..".floatValues", floats)
			else
				print(modName.." Function createUI() Error: Expected 'floats' to be table.\nfloats: "..floats)
			end
		end
		if ints ~= nil then
			if type(ints) == "table" then
				TweakDB:SetFlat(id..".intValues", ints)
			else
				print(modName.." Function createUI() Error: Expected 'ints' to be table.\nints: "..ints)
			end
		end
		TweakDB:SetFlat(id..".localizedDescription", localizedDescription)
	end
end

function createStatusEffectAbsentPrereq(id, se)
	if TweakDB:GetRecord(id) == nil then
		TweakDB:CreateRecord(id,"gamedataStatusEffectPrereq_Record")
		TweakDB:SetFlat(id..".prereqClassName", "StatusEffectAbsentPrereq")
		TweakDB:SetFlat(id..".statusEffect", se)
    end
end

function GetQualityText(quality, iconic)
	local plus = 0
	local qualityKey = "Gameplay-RPG-Stats-Tiers-Tier1"

	if quality == gamedataQuality.Uncommon or quality == gamedataQuality.UncommonPlus then
		qualityKey = "Gameplay-RPG-Stats-Tiers-Tier2"
	elseif quality == gamedataQuality.Rare or quality == gamedataQuality.RarePlus then
		qualityKey = "Gameplay-RPG-Stats-Tiers-Tier3"
	elseif quality == gamedataQuality.Epic or quality == gamedataQuality.EpicPlus then
		qualityKey = "Gameplay-RPG-Stats-Tiers-Tier4"
	elseif quality == gamedataQuality.Legendary or quality == gamedataQuality.LegendaryPlus  or quality == gamedataQuality.LegendaryPlusPlus then
		qualityKey = "Gameplay-RPG-Stats-Tiers-Tier5"
	end

	local qualityText = Game.GetLocalizedText(qualityKey)

	if quality == gamedataQuality.CommonPlus or quality == gamedataQuality.UncommonPlus or quality == gamedataQuality.RarePlus or quality == gamedataQuality.EpicPlus or quality == gamedataQuality.LegendaryPlus then
		plus = 1
	elseif  quality == gamedataQuality.LegendaryPlusPlus then
		plus = 2
	end

	if plus == 1 then
		qualityText = qualityText.."+"
	elseif plus == 2 then
		qualityText = qualityText.."++"
	end

	if iconic == true then
		qualityText = qualityText.." / "..Game.GetLocalizedText(UIItemsHelper.QualityToLocalizationKey(gamedataQuality.Iconic))
	end

	return qualityText
end

function Round(v, bracket)
	bracket = bracket or 1
	if v > 0 then
		return math.floor(v/bracket + 0.5) * bracket
	else
		return math.ceil(v/bracket - 0.5) * bracket
	end
end

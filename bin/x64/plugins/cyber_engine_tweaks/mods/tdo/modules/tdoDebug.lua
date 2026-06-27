function TDODumpSandyStructure()
	local sandyLines = {
		{prefix = "Items.AdvancedSandevistanC1", locKey = 92102, tiers = {"MK1", "MK1Plus", "MK2", "MK2Plus", "MK3", "MK3Plus", "MK4", "MK4Plus", "MK4PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanC2", locKey = 53584, tiers = {"MK1", "MK1Plus", "MK2", "MK2Plus", "MK3", "MK3Plus", "MK4", "MK4Plus", "MK4PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanC3", locKey = 92123, tiers = {"MK3", "MK3Plus", "MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanC4", locKey = 92103, tiers = {"MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanApogee", locKey = 91021, tiers = {"", "Plus", "PlusPlus"}}
	}
	print("[TDO-DUMP] === BEGIN SANDY UIDATA INLINE DUMP ===")
	for _, line in ipairs(sandyLines) do
		print("[TDO-DUMP] --- Line: "..line.prefix.." (vanilla LocKey: "..line.locKey..") ---")
		for _, tier in ipairs(line.tiers) do
			local itemFlat = line.prefix..tier
			local onEquip = TweakDB:GetFlat(itemFlat..".OnEquip")
			if type(onEquip) ~= "table" then
				print("[TDO-DUMP] "..itemFlat.." OnEquip: nil or not table")
			else
				local found = false
				for _, pkgFlat in ipairs(onEquip) do
					local uiDataRef = TweakDB:GetFlat(pkgFlat..".UIData")
					if uiDataRef ~= nil and TweakDB:GetRecord(uiDataRef) ~= nil then
						local locKeyRef = TweakDB:GetFlat(uiDataRef..".localizedDescription")
						if locKeyRef ~= nil then
							local locNum = string.match(tostring(locKeyRef), "#(%d+)$")
							if locNum ~= nil and tonumber(locNum) == line.locKey then
								print("[TDO-DUMP] "..itemFlat.." -> UIData: "..tostring(TDBID.ToStringDEBUG(uiDataRef)))
								found = true
								break
							end
						end
					end
				end
				if not found then
					print("[TDO-DUMP] "..itemFlat.." -> NO match for LocKey#"..line.locKey)
				end
			end
		end
	end
	print("[TDO-DUMP] === END SANDY UIDATA INLINE DUMP ===")
end

local function TDOFormatValue(v)
	if v == nil then return "nil" end
	if type(v) == "table" then
		return "table[" .. tostring(#v) .. "]"
	end
	if type(v) == "userdata" then
		local raw = tostring(v)
		if raw and string.find(raw, "ToCName", 1, true) then
			return "CName(" .. raw .. ")"
		end
		if raw and string.find(raw, "ToTweakDBID", 1, true) then
			return "TDBID(" .. raw .. ")"
		end
		local ok, s = pcall(function() return TDBID.ToStringDEBUG(v) end)
		if ok and s ~= nil and s ~= "" and s ~= "<UNKNOWN>" then return "TDBID(" .. tostring(s) .. ")" end
		local okN, name = pcall(function() return NameToString(v) end)
		if okN and name ~= nil and name ~= "" and name ~= "None" then return "CName(" .. tostring(name) .. ")" end
		local okR, ref = pcall(function() return ResRef.ToString(v) end)
		if okR and ref ~= nil and ref ~= "" then return "Res(" .. tostring(ref) .. ")" end
		local okH, hash = pcall(function() return ResRef.ToHash(v) end)
		if okH and hash ~= nil and hash ~= 0 then return "ResHash(0x" .. string.format("%X", hash) .. ")" end
		return "userdata(" .. raw .. ")"
	end
	return tostring(v)
end

local function TDODumpTableField(prefix, fieldName, tbl)
	print("[TDO-WEAPON-DUMP]   " .. prefix .. "." .. fieldName .. " (table size=" .. tostring(#tbl) .. "):")
	for i, item in ipairs(tbl) do
		print("[TDO-WEAPON-DUMP]       [" .. tostring(i) .. "] " .. tostring(item))
	end
end

function TDODumpRecord(tdbidStr, fieldList, label)
	if tdbidStr == nil then
		print("[TDO-WEAPON-DUMP] TDODumpRecord called with nil tdbidStr")
		return
	end
	label = label or tdbidStr
	print("[TDO-WEAPON-DUMP] >>>>>>>>>>>> " .. tostring(label) .. " (" .. tostring(tdbidStr) .. ")")
	fieldList = fieldList or {
		"name", "animationName", "category", "duration", "stackLimit",
		"audio", "audioEvent",
		"audioEventCharge", "audioEventCharging", "audioEventFire", "audioEventShoot",
		"audioEventCancelCharge", "audioEventStart", "audioEventStop", "audioEventEnd",
		"audioName", "audioNameCharge", "audioNameFire",
		"audioFireEvent", "chargeAudioEvent",
		"audioFireStart", "audioFireEnd", "audioChargeStart", "audioChargeEnd",
		"shoot", "muzzle", "trail", "projectileTrail",
		"vfx_charge", "vfx_charging", "vfx_charged", "vfx_charge_fail",
		"vfx_fire", "vfx_shoot", "vfx_muzzle", "vfx_muzzle_flash",
		"vfx_hitscan_trail", "vfx_hitscan_trail_ricochet", "vfx_hitscan_trail_pierce",
		"vfx_hitscan_trail_charged", "vfx_charged_trail",
		"vfx_projectile_trail", "vfx_projectile",
		"vfx_impact", "vfx_ricochet", "vfx_blood", "vfx_blood_screen",
		"vfx_environment", "vfx_ground", "vfx_glass",
		"vfxFire", "vfxCharge", "vfxShoot", "vfxImpact", "vfxRicochet",
		"impactVFX", "ricochetVFX", "shootVFX", "chargeVFX", "fireVFX",
		"projectileTemplateName", "projectileEntityTemplate",
		"projectileEffect", "effect", "effectName",
		"hitData", "hitEffect", "hitFx",
		"statModifiers",
		"chargeEffectPackage", "chargeEffectPackages",
		"effectPackage", "effectPackages",
		"playerEffectPackage", "playerEffectPackages",
		"weaponEffectPackage", "weaponEffectPackages",
		"defaultEffect", "defaultVFX", "baseEffect",
		"OnEquip", "OnAttach",
	}
	for _, f in ipairs(fieldList) do
		local v = TweakDB:GetFlat(tdbidStr .. "." .. f)
		if v ~= nil then
			if type(v) == "table" and #v > 0 then
				TDODumpTableField(label, f, v)
			elseif type(v) == "table" and #v == 0 then
				print("[TDO-WEAPON-DUMP]   " .. label .. "." .. f .. " = (empty table)")
			else
				print("[TDO-WEAPON-DUMP]   " .. label .. "." .. f .. " = " .. TDOFormatValue(v))
			end
		end
	end
end

function TDODumpWeapon()
	local player = Game.GetPlayer()
	if not player then
		print("[TDO-WEAPON-DUMP] No player")
		return
	end
	local ts = Game.GetTransactionSystem()
	if not ts then
		print("[TDO-WEAPON-DUMP] No transaction system")
		return
	end
	local weapon = ts:GetItemInSlot(player, TweakDBID.new("AttachmentSlots.WeaponRight"))
	if not weapon then
		print("[TDO-WEAPON-DUMP] No weapon equipped in right slot")
		return
	end

	local itemID = weapon:GetItemID()
	local tdb = ItemID.GetTDBID(itemID)
	local tdbStr = TDBID.ToStringDEBUG(tdb)
	print("[TDO-WEAPON-DUMP] ============================================================")
	print("[TDO-WEAPON-DUMP] Weapon TDBID: " .. tostring(tdbStr))

	local weaponFields = {
		"fxPackage", "weaponFXPackage", "weaponFxPackage", "playerWeaponFXPackage",
		"projectileTemplateName", "projectileEntityTemplate",
		"attacks", "triggerModes", "effectors",
		"OnEquip", "OnAttach",
		"audioBoneName", "chargeAudioEvent", "audioFireEvent",
		"category", "animationName",
	}
	TDODumpRecord(tdbStr, weaponFields, "Weapon")

	local fxPackageRef = TweakDB:GetFlat(tdbStr .. ".fxPackage")
		or TweakDB:GetFlat(tdbStr .. ".weaponFxPackage")
		or TweakDB:GetFlat(tdbStr .. ".weaponFXPackage")
	if fxPackageRef ~= nil then
		local ok, pkgStr = pcall(function() return TDBID.ToStringDEBUG(fxPackageRef) end)
		if ok and pkgStr ~= nil then
			TDODumpRecord(pkgStr, nil, "FxPackage")
		else
			print("[TDO-WEAPON-DUMP] FxPackage ref is not a TDBID: " .. tostring(fxPackageRef))
		end
	end

	local triggerModes = TweakDB:GetFlat(tdbStr .. ".triggerModes")
	if type(triggerModes) == "table" then
		for _, tm in ipairs(triggerModes) do
			local ok, tmStr = pcall(function() return TDBID.ToStringDEBUG(tm) end)
			if ok and tmStr ~= nil then
				TDODumpRecord(tmStr, nil, "TriggerMode")
			end
		end
	end

	print("[TDO-WEAPON-DUMP] === END DUMP ===")
end
function TDOZetatechDebug()
	local player = Game.GetPlayer()
	if not player then
		print("[TDO-DEBUG] No player")
		return
	end
	local statsSys = Game.GetStatsSystem()
	local statsID = player:GetEntityID()
	print("[TDO-DEBUG] === ZETATECH BONUS CHAIN ===")
	print("[TDO-DEBUG] Reflexes attr: " .. tostring(statsSys:GetStatValue(statsID, gamedataStatType.Reflexes)))
	print("[TDO-DEBUG] AttunementHelper: " .. tostring(statsSys:GetStatValue(statsID, gamedataStatType.AttunementHelper)))
	print("[TDO-DEBUG] CycleTimeBonus: " .. tostring(statsSys:GetStatValue(statsID, gamedataStatType.CycleTimeBonus)))
	print("[TDO-DEBUG] ReloadTimeBase: " .. tostring(statsSys:GetStatValue(statsID, gamedataStatType.ReloadTimeBase)))
	print("[TDO-DEBUG] EmptyReloadTime: " .. tostring(statsSys:GetStatValue(statsID, gamedataStatType.EmptyReloadTime)))
	print("[TDO-DEBUG] TimeDilationSandevistanDuration: " .. tostring(statsSys:GetStatValue(statsID, gamedataStatType.TimeDilationSandevistanDuration)))
	local hasSE = StatusEffectSystem.ObjectHasStatusEffect(player, TweakDBID.new("StatusEffects.TDO_ZetatechRangedBuff"))
	print("[TDO-DEBUG] TDO_ZetatechRangedBuff applied: " .. tostring(hasSE))
	print("[TDO-DEBUG] === END ===")
end

function TDODumpVanillaSandies()
	local sandyLines = {
		{prefix = "Items.AdvancedSandevistanC1", tiers = {"MK1", "MK1Plus", "MK2", "MK2Plus", "MK3", "MK3Plus", "MK4", "MK4Plus", "MK4PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanC2", tiers = {"MK1", "MK1Plus", "MK2", "MK2Plus", "MK3", "MK3Plus", "MK4", "MK4Plus", "MK4PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanC3", tiers = {"MK3", "MK3Plus", "MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanC4", tiers = {"MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}},
		{prefix = "Items.AdvancedSandevistanApogee", tiers = {"", "Plus", "PlusPlus"}}
	}
	local extraRoots = { "Attunements.ReflexesSandyProlong" }

	local scalarProps = {
		"value", "modifierType", "statType", "opSymbol", "refObject", "refStat",
		"effectorClassName", "operationType", "prereqClassName", "stateName",
		"isInState", "previousState", "localizedDescription", "localizedName",
		"displayName", "description", "maxFactor", "maxStacks", "quality",
		"stackable", "removeWithEffector", "removeAfterActionCall",
		"removeAfterPrereqCheck", "nextUpgradeItem", "floatValues", "intValues",
		"nameValues", "drawBasedOnStatType", "optimiseCombinedModifiers",
		"saveBasedOnStatType", "statModsLimit", "dynamicDuration",
		"isAffectedByTimeDilationNPC", "isAffectedByTimeDilationPlayer",
		"reapplyPackagesOnMaxStacks", "removeAllStacksWhenDurationEnds",
		"removeOnStoryTier", "replicated", "savable", "statusEffectType",
		"stopActiveSfxOnDeactivate", "gameplayTags", "iconPath", "priority"
	}
	local refProps = {
		"statModifiers", "statModifierGroups", "OnEquip", "OnAttach", "OnLooted",
		"effectors", "packages", "relatedModifierGroups", "stats",
		"UIData", "uiData", "statGroup", "effectorToApply", "prereqRecord", "duration"
	}

	local function resolveId(v)
		if type(v) ~= "userdata" then return nil end
		local ok, s = pcall(function() return TDBID.ToStringDEBUG(v) end)
		if ok and s ~= nil and s ~= "" and s ~= "<UNKNOWN>" then return s end
		return nil
	end

	local function recordType(idStr)
		local rec = TweakDB:GetRecord(idStr)
		if rec == nil then return nil end
		local ok, cn = pcall(function() return rec:GetClassName() end)
		if ok and cn ~= nil then
			local okN, s = pcall(function() return NameToString(cn) end)
			if okN and s ~= nil and s ~= "" then return s end
		end
		return nil
	end

	local seen = {}
	local queue = {}
	local lines = {}

	local function enqueue(idStr)
		if idStr == nil or seen[idStr] then return end
		if TweakDB:GetRecord(idStr) == nil then return end
		seen[idStr] = true
		table.insert(queue, idStr)
	end

	local function dumpRecord(idStr)
		local t = recordType(idStr)
		table.insert(lines, idStr .. ":")
		if t ~= nil then
			table.insert(lines, "  $type: " .. t)
		end
		for _, p in ipairs(scalarProps) do
			local v = TweakDB:GetFlat(idStr .. "." .. p)
			if v ~= nil then
				if type(v) == "table" then
					if #v > 0 then
						table.insert(lines, "  " .. p .. ":")
						for _, e in ipairs(v) do
							table.insert(lines, "    - " .. TDOFormatValue(e))
						end
					end
				else
					table.insert(lines, "  " .. p .. ": " .. TDOFormatValue(v))
				end
			end
		end
		for _, p in ipairs(refProps) do
			local v = TweakDB:GetFlat(idStr .. "." .. p)
			if v ~= nil then
				if type(v) == "table" then
					if #v > 0 then
						table.insert(lines, "  " .. p .. ":")
						for _, e in ipairs(v) do
							local cid = resolveId(e)
							table.insert(lines, "    - " .. (cid or TDOFormatValue(e)))
							if cid ~= nil then enqueue(cid) end
						end
					end
				else
					local cid = resolveId(v)
					table.insert(lines, "  " .. p .. ": " .. (cid or TDOFormatValue(v)))
					if cid ~= nil then enqueue(cid) end
				end
			end
		end
		table.insert(lines, "")
	end

	for _, line in ipairs(sandyLines) do
		for _, tier in ipairs(line.tiers) do
			enqueue(line.prefix .. tier)
		end
	end
	for _, r in ipairs(extraRoots) do enqueue(r) end

	local guard = 0
	while #queue > 0 and guard < 8000 do
		guard = guard + 1
		local idStr = table.remove(queue, 1)
		dumpRecord(idStr)
	end

	local path = "data/vanilla_sandy_dump.txt"
	local f = io.open(path, "w+")
	if f == nil then
		print("[TDO-VDUMP] ERROR: could not open " .. path .. " for writing")
		return
	end
	f:write(table.concat(lines, "\n"))
	f:close()
	print("[TDO-VDUMP] Dumped " .. tostring(guard) .. " records to mods/tdo/" .. path)
end

function TDODumpFullTweakDB(typeFilter)
	local outPath = "data/full_tweakdb_dump.txt"
	local f = io.open(outPath, "w+")
	if f == nil then
		print("[TDO-FULLDUMP] ERROR: could not open " .. outPath .. " for writing")
		return
	end
	if Reflection == nil then
		print("[TDO-FULLDUMP] ERROR: Codeware Reflection unavailable (is Codeware loaded?)")
		f:close()
		return
	end

	local baseSkip = {
		GetID = true, GetRecordID = true, GetClassName = true, IsA = true,
		IsExactlyA = true, ToString = true, DetectScriptableCycles = true
	}

	local function isFlatGetter(name)
		if baseSkip[name] then return false end
		if name:match("Contains$") then return false end
		if name:match("Handle$") then return false end
		if name:match("^Get.+Count$") then return false end
		if name:match("^Get.+Item$") then return false end
		return true
	end

	local function firstLower(s)
		return s:sub(1, 1):lower() .. s:sub(2)
	end

	local function camelAcronym(s)
		local run = s:match("^(%u+)")
		if run == nil or #run <= 1 then return firstLower(s) end
		local rest = s:sub(#run + 1)
		if rest:match("^%l") then
			return run:sub(1, #run - 1):lower() .. run:sub(#run) .. rest
		end
		return run:lower() .. rest
	end

	local function variantsFor(name)
		local out = {}
		local vseen = {}
		for _, c in ipairs({ firstLower(name), camelAcronym(name), name }) do
			if not vseen[c] then vseen[c] = true; out[#out + 1] = c end
		end
		return out
	end

	local typeSeen = {}
	local typeList = {}
	local function collectTypes(base)
		local derived = Reflection.GetDerivedClasses(base)
		if derived == nil then return end
		for _, cls in pairs(derived) do
			local nm = cls:GetName().value
			if nm ~= base and not typeSeen[nm] then
				typeSeen[nm] = true
				typeList[#typeList + 1] = nm
				collectTypes(nm)
			end
		end
	end
	collectTypes("gamedataTweakDBRecord")
	table.sort(typeList)

	local typeFlatNames = {}
	local function flatCandidates(typeName)
		if typeFlatNames[typeName] ~= nil then return typeFlatNames[typeName] end
		local names = {}
		local nameSeen = {}
		local cls = Reflection.GetClass(typeName)
		while cls ~= nil do
			local cn = cls:GetName().value
			if cn == "gamedataTweakDBRecord" or cn == "IScriptable" or cn == "ISerializable" then break end
			local fns = cls:GetFunctions()
			if fns ~= nil then
				for _, fn in pairs(fns) do
					local fname = fn:GetName().value
					if isFlatGetter(fname) and not nameSeen[fname] then
						nameSeen[fname] = true
						names[#names + 1] = fname
					end
				end
			end
			cls = cls:GetParent()
		end
		table.sort(names)
		typeFlatNames[typeName] = names
		return names
	end

	local casingCache = {}
	local function getFlat(typeName, recordId, candidate)
		local ck = casingCache[typeName]
		if ck == nil then ck = {}; casingCache[typeName] = ck end
		local known = ck[candidate]
		if known ~= nil then
			return TweakDB:GetFlat(recordId .. "." .. known), known
		end
		for _, variant in ipairs(variantsFor(candidate)) do
			local v = TweakDB:GetFlat(recordId .. "." .. variant)
			if v ~= nil then
				ck[candidate] = variant
				return v, variant
			end
		end
		return nil, nil
	end

	print("[TDO-FULLDUMP] Starting. " .. tostring(#typeList) .. " record types found. The game will freeze while this runs.")

	local totalRecords = 0
	local typesDumped = 0
	for _, typeName in ipairs(typeList) do
		if typeFilter == nil or string.find(typeName, typeFilter, 1, true) then
			local records = TweakDB:GetRecords(typeName)
			if records ~= nil and #records > 0 then
				local cands = flatCandidates(typeName)
				local buf = {}
				buf[#buf + 1] = "### " .. typeName .. "  (" .. tostring(#records) .. " records) ###"
				for _, rec in pairs(records) do
					local idOk, recId = pcall(function() return rec:GetID().value end)
					if idOk and recId ~= nil and recId ~= "" then
						buf[#buf + 1] = recId .. ":"
						buf[#buf + 1] = "  $type: " .. typeName
						for _, cand in ipairs(cands) do
							local v, fname = getFlat(typeName, recId, cand)
							if v ~= nil then
								local key = fname or firstLower(cand)
								if type(v) == "table" then
									if #v > 0 then
										buf[#buf + 1] = "  " .. key .. ":"
										for _, e in ipairs(v) do
											buf[#buf + 1] = "    - " .. TDOFormatValue(e)
										end
									end
								else
									buf[#buf + 1] = "  " .. key .. ": " .. TDOFormatValue(v)
								end
							end
						end
						buf[#buf + 1] = ""
						totalRecords = totalRecords + 1
						if #buf >= 5000 then
							f:write(table.concat(buf, "\n") .. "\n")
							buf = {}
						end
					end
				end
				if #buf > 0 then
					f:write(table.concat(buf, "\n") .. "\n")
				end
				typesDumped = typesDumped + 1
				print("[TDO-FULLDUMP] " .. typeName .. " (" .. tostring(#records) .. ")")
			end
		end
	end

	f:close()
	print("[TDO-FULLDUMP] DONE. " .. tostring(totalRecords) .. " records across " .. tostring(typesDumped) .. " types -> mods/tdo/" .. outPath)
end

function TDODumpApogeeConflict()
	print("[TDO-APOGEE-DUMP] === BEGIN ===")
	local apogeeItems = {
		"Items.AdvancedSandevistanApogee",
		"Items.AdvancedSandevistanApogeePlus",
		"Items.AdvancedSandevistanApogeePlusPlus",
	}
	for _, itemPath in ipairs(apogeeItems) do
		print("[TDO-APOGEE-DUMP] --- " .. itemPath .. " ---")
		local rec = TweakDB:GetRecord(itemPath)
		if rec == nil then
			print("[TDO-APOGEE-DUMP]   RECORD NIL")
		else
			print("[TDO-APOGEE-DUMP]   record exists: " .. tostring(rec))
		end
		local statMods = TweakDB:GetFlat(itemPath .. ".statModifiers")
		if statMods == nil then
			print("[TDO-APOGEE-DUMP]   statModifiers: NIL")
		else
			print("[TDO-APOGEE-DUMP]   statModifiers count: " .. tostring(#statMods))
			for i, ref in ipairs(statMods) do
				local refStr = "nil"
				if type(ref) == "userdata" then
					local ok, s = pcall(function() return TDBID.ToStringDEBUG(ref) end)
					if ok and s ~= nil and s ~= "" then refStr = s end
				else
					refStr = tostring(ref)
				end
				print(string.format("[TDO-APOGEE-DUMP]     [%d] %s", i, refStr))
			end
		end
		local onEquip = TweakDB:GetFlat(itemPath .. ".OnEquip")
		if onEquip == nil then
			print("[TDO-APOGEE-DUMP]   OnEquip: NIL")
		else
			print("[TDO-APOGEE-DUMP]   OnEquip count: " .. tostring(#onEquip))
			for i, ref in ipairs(onEquip) do
				local refStr = "nil"
				if type(ref) == "userdata" then
					local ok, s = pcall(function() return TDBID.ToStringDEBUG(ref) end)
					if ok and s ~= nil and s ~= "" then refStr = s end
				else
					refStr = tostring(ref)
				end
				print(string.format("[TDO-APOGEE-DUMP]     [%d] %s", i, refStr))
			end
		end
		for _, suffix in ipairs({"_inline1", "_inline18", "_inline19", "_inline20", "_inline21"}) do
			local inlinePath = itemPath .. suffix
			local inlineRec = TweakDB:GetRecord(inlinePath)
			if inlineRec == nil then
				print("[TDO-APOGEE-DUMP]   " .. inlinePath .. ": RECORD NIL")
			else
				local val = TweakDB:GetFlat(inlinePath .. ".value")
				local desc = TweakDB:GetFlat(inlinePath .. ".localizedDescription")
				local statType = TweakDB:GetFlat(inlinePath .. ".statType")
				local statTypeStr = "n/a"
				if statType ~= nil then
					if type(statType) == "userdata" then
						local ok, s = pcall(function() return TDBID.ToStringDEBUG(statType) end)
						if ok and s ~= nil and s ~= "" then statTypeStr = s end
					else
						statTypeStr = tostring(statType)
					end
				end
				print(string.format("[TDO-APOGEE-DUMP]   %s: value=%s desc=%s statType=%s", inlinePath, tostring(val), tostring(desc), statTypeStr))
			end
		end
	end
	print("[TDO-APOGEE-DUMP] === END ===")
end

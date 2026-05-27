local Sandy = {}

    function Sandy:New(baseFlat, AbilityDefs)
        local rec = TweakDB:GetRecord(baseFlat)
        local data = {
            flat = baseFlat,
            abilities = AbilityDefs.Abilities:New(),
            name = Game.GetLocalizedTextByKey(rec:DisplayName()),
            qualityStr = GetQualityText(rec:Quality():Type()),
            qaulityNum = rec:Quality():Value()
        }
        rec = nil
        setmetatable(data, self)
        self.__index = self
        return data
    end

    function Sandy:GetFlat()
        return self.flat
    end

    function Sandy:InitAbilities(TDOAbilityData, savedData)
        return self.abilities:FindAbilities(self.flat, TDOAbilityData, savedData)
    end

    function Sandy:GetUpgrade()
        return TweakDB:GetFlat(self.flat..".nextUpgradeItem")
    end

    function Sandy:GetAbilities()
        return self.abilities
    end

    function Sandy:GetAbilityVars()
        return self.abilities:GetAbilityVars()
    end

    function Sandy:PrintAbilities()
        print("   "..self.qualityStr..":")
        self.abilities:Print()
    end

    function Sandy:GetQualityNum()
        return self.qualityNum
    end

    function Sandy:GetQualityStr()
        return self.qualityStr
    end

    function Sandy:GetVanillaValue(TDOVariable, forUI)
        if forUI == true then
            return self.abilities:GetUIValue(TDOVariable, self.abilities:GetAbility(TDOVariable):VanillaValue())
        else
            return self.abilities:GetAbility(TDOVariable):VanillaValue()
        end
    end

    function Sandy:IsExistingAbility(TDOVariable)
        return self.abilities:GetAbility(TDOVariable):IsExisting()
    end

    function Sandy:UpdateAbility(TDOVariable, reset, value)
        self.abilities:UpdateAbility(TDOVariable, reset, value)
    end

    function Sandy:GrabAbilitiesData()
        return self.abilities:GrabAbilitiesData()
    end

local Sandys = {}

    function Sandys:New()
        local data = {
            sandys = {},
            names = {},
            updateQueue = {},
        }
        setmetatable(data, self)
        self.__index = self
        return data
    end

    
    
    
    function Sandys:AddExistingProductLine(index, firstFlat, TDOAbilityData, AbilityDefs)
        if self.sandys[index] == nil then
            self.names[index] = Game.GetLocalizedTextByKey(TweakDB:GetRecord(firstFlat):DisplayName())
            self.sandys[index] = {}

            local savedData = self:ReadFile()

            local cont = true
            local curFlat = firstFlat
            local sandyNum = 0
            while cont == true do
                
                sandyNum = sandyNum + 1
                self.sandys[index][sandyNum] = Sandy:New(curFlat, AbilityDefs)
                local specificData
                if type(savedData) == "table" then
                    if type(savedData[index]) == "table" then
                        if type(savedData[index][sandyNum]) == "table" then
                            specificData = savedData[index][sandyNum]
                        end
                    end
                end

                self.sandys[index][sandyNum]:InitAbilities(TDOAbilityData, specificData)
                print("[TDO] Line " .. index .. ": Tier " .. sandyNum .. " = " .. tostring(curFlat))
                curFlat = TDBID.ToStringDEBUG(self.sandys[index][sandyNum]:GetUpgrade())
                if TweakDB:GetRecord(curFlat) == nil then
                    cont = false
                end
            end
            print("[TDO] Line " .. index .. " (" .. tostring(self.names[index]) .. "): Total tiers = " .. sandyNum)
        else
            print("[TDO] Sandy Manufacturer already exits")
        end
    end

    function Sandys:ReadFile()
        local file = io.open("data/temp/sandyAbilityData.json", "r");
        if file ~= nil then
            local jsonString = file:read("*all")
            local validJson, contents = pcall(function() return json.decode(jsonString) end)
            file:close()
            if validJson and contents ~= nil then
                
                return contents
            else
                 print("[TDO]: Sandys:ReadFile() No saved ability data found. Normal to fire each time the game starts, should not fire if \"Reload All Mods\" is clicked.")
                return nil
            end
        end
        return nil
    end

    function Sandys:MinMaxQualitiesNum(index)
        return self.sandys[index][1]:GetQualityNum(), self.sandys[index][#self.sandys[index]]:GetQualityNum()
    end

    function Sandys:MinMaxQualitiesStr(index)
        return self.sandys[index][1]:GetQualityStr(), self.sandys[index][#self.sandys[index]]:GetQualityStr()
    end

    function Sandys:MinMaxVanillaValues(index, TDOVariable, forUI)
        return self.sandys[index][1]:GetVanillaValue(TDOVariable, forUI), self.sandys[index][#self.sandys[index]]:GetVanillaValue(TDOVariable, forUI)
    end

    function Sandys:IsExistingAbility(index, TDOVariable)
        return self.sandys[index][1]:IsExistingAbility(TDOVariable)
    end

    function Sandys:PrintProductLineDetails(index)
        local start, finish = self:MinMaxQualitiesStr(index)
        print("--------------------------------------------")
        print("[TDO] SANDEVISTAN START PRODUCT LINE PRINT: "..self.names[index])
        print("Min Quality = "..start.." / Max Quality: "..finish)
        for i=1, #self.sandys[index], 1 do
            self.sandys[index][i]:PrintAbilities()
        end
        print("[TDO] SANDEVISTAN END PRODUCT LINE PRINT: "..self.names[index])
        print("--------------------------------------------")
    end

    function Sandys:GetAbilityVars(index)
        return self.sandys[index][1]:GetAbilityVars()
    end

    function Sandy:LowestLine()
        if self.sandys[1] ~= nil then
            return 1
        else
            return 0
        end
    end

    function Sandy:HighestLine()
        if self.sandys[1] ~= nil then
            return 0
        else
            return #self.sandys
        end
    end

    function Sandys:CreateNUIMenus(nativeSettings, params, nuiTxt, config, default, arr, mechanicCreators, enableCreators)
        mechanicCreators = mechanicCreators or {}
        enableCreators = enableCreators or {}
        for lineIndex,_ in ipairs(self.sandys) do
            local path = "/tdo/C"..lineIndex
            nativeSettings.addSubcategory(path, self.names[lineIndex])

            if enableCreators[lineIndex] ~= nil then
                enableCreators[lineIndex](nativeSettings, path)
            end

            nativeSettings.addButton(path, nuiTxt.showHide.opt, nuiTxt.showHide.des, nuiTxt.showHide.button, nuiTxt.showHide.textSize, function()
                if config["sandys"][lineIndex].show == true then
                    config["sandys"][lineIndex].show = false
                    for var, lookupIndex in pairs(arr[lineIndex].orderLookup) do
                        for i=1, #arr[lineIndex].nuiOptions[lookupIndex], 1 do
                            nativeSettings.removeOption(arr[lineIndex].nuiOptions[lookupIndex][i])
                            arr[lineIndex].nuiOptions[lookupIndex][i] = nil
                        end
                        arr[lineIndex].orderLookup[var] = nil
                    end
                    if arr[lineIndex].mechanicOptions ~= nil then
                        for i=1, #arr[lineIndex].mechanicOptions, 1 do
                            nativeSettings.removeOption(arr[lineIndex].mechanicOptions[i])
                            arr[lineIndex].mechanicOptions[i] = nil
                        end
                        arr[lineIndex].mechanicOptions = nil
                    end
                    arr[lineIndex].orderLookup = nil
                    arr[lineIndex].nuiOptions = nil
                    arr[lineIndex] = nil
                else
                    config["sandys"][lineIndex].show = true
                    self:CreateNUIOptions(nativeSettings, params, nuiTxt, config, default, arr, lineIndex, path)
                    if mechanicCreators[lineIndex] ~= nil then
                        arr[lineIndex].mechanicOptions = mechanicCreators[lineIndex](nativeSettings, path)
                    end
                end
            end, 1)

            if config["sandys"][lineIndex].show == true then
                self:CreateNUIOptions(nativeSettings, params, nuiTxt, config, default, arr, lineIndex, path)
                if mechanicCreators[lineIndex] ~= nil then
                    arr[lineIndex].mechanicOptions = mechanicCreators[lineIndex](nativeSettings, path)
                end
            end

        end
    end

    function Sandys:CreateNUIOptions(nativeSettings, params, nuiTxt, config, default, arr, lineIndex, path)
              
            local minQual, maxQual = self:MinMaxQualitiesStr(lineIndex)
            local abilityVars = self:GetAbilityVars(lineIndex)

            if arr[lineIndex] == nil then
                arr[lineIndex] = {orderLookup = {}, nuiOptions = {}}
            end
            local orderIndex = 0
            for _, v in ipairs(params.menuOrder) do
                if abilityVars[v] ~= nil then

                    if config["sandys"][lineIndex][v] ~= nil then

                        orderIndex = orderIndex + 1

                        if arr[lineIndex].nuiOptions[orderIndex] == nil then
                            arr[lineIndex].orderLookup[v] = orderIndex
                            arr[lineIndex].nuiOptions[orderIndex] = {}
                        end

                        self:AddMinMaxOptionGroup(arr, path, minQual, maxQual, nuiTxt, v, params, config, default, lineIndex)

                    end
                end
            end
    end

    function Sandys:AddMinMaxOptionGroup(arr, path, minQual, maxQual, nuiTxt, v, params, config, default, lineIndex)
        local nuiIndex = 3
        local lookupIndex = arr[lineIndex].orderLookup[v]
        local subIndex = 1

        local desMin = nuiTxt.calcDes..nuiTxt["abilities"][v]["des"]
        local desMax = desMin

        if self:IsExistingAbility(lineIndex, v) then
            local minVan, maxVan = self:MinMaxVanillaValues(lineIndex,v, true)
            desMin = desMin..string.gsub(nuiTxt.vanillaDes, "{VALUE}", minVan)
            desMax = desMax..string.gsub(nuiTxt.vanillaDes, "{VALUE}", maxVan)
        end

        desMin = desMin..string.gsub(nuiTxt.TDODefaultDes, "{VALUE}", default["sandys"][lineIndex][v].min)
        desMax = desMax..string.gsub(nuiTxt.TDODefaultDes, "{VALUE}", default["sandys"][lineIndex][v].max)

        for i=(lookupIndex - 1), 1, -1 do
            nuiIndex = nuiIndex + #arr[lineIndex].nuiOptions[i]
        end

        if params[v]["type"] == "Int" then
            arr[lineIndex].nuiOptions[lookupIndex][subIndex] = nativeSettings.addRangeInt(path, "  >>["..minQual.."] "..nuiTxt["abilities"][v]["opt"]..nuiTxt["abilities"][v]["optUnit"], desMin, params[v]["min"], params[v]["max"], params[v]["inc"], config["sandys"][lineIndex][v].min, default["sandys"][lineIndex][v].min, function(value)
                config["sandys"][lineIndex][v].min = value
                self:AddToUpdateQueue(lineIndex, v)
            end, nuiIndex)

            nuiIndex = nuiIndex + 1
            subIndex = subIndex + 1

            arr[lineIndex].nuiOptions[lookupIndex][subIndex]  = nativeSettings.addRangeInt(path, "  >>["..maxQual.."] "..nuiTxt["abilities"][v]["opt"]..nuiTxt["abilities"][v]["optUnit"], desMax, params[v]["min"], params[v]["max"], params[v]["inc"], config["sandys"][lineIndex][v].max, default["sandys"][lineIndex][v].max, function(value)
                config["sandys"][lineIndex][v].max = value
                self:AddToUpdateQueue(lineIndex, v)
            end, nuiIndex)
        elseif params[v]["type"] == "Float" then

            arr[lineIndex].nuiOptions[lookupIndex][subIndex] = nativeSettings.addRangeFloat(path, "  >>["..minQual.."] "..nuiTxt["abilities"][v]["opt"]..nuiTxt["abilities"][v]["optUnit"], desMin, params[v]["min"], params[v]["max"], params[v]["inc"], params[v]["precision"], config["sandys"][lineIndex][v].min, default["sandys"][lineIndex][v].min, function(value)
                config["sandys"][lineIndex][v].min = value
                self:AddToUpdateQueue(lineIndex, v)
            end, nuiIndex)

            nuiIndex = nuiIndex + 1
            subIndex = subIndex + 1

            arr[lineIndex].nuiOptions[lookupIndex][subIndex] = nativeSettings.addRangeFloat(path, "  >>["..maxQual.."] "..nuiTxt["abilities"][v]["opt"]..nuiTxt["abilities"][v]["optUnit"], desMax, params[v]["min"], params[v]["max"], params[v]["inc"], params[v]["precision"], config["sandys"][lineIndex][v].max, default["sandys"][lineIndex][v].max, function(value)
                config["sandys"][lineIndex][v].max = value
                self:AddToUpdateQueue(lineIndex, v)
            end, nuiIndex)

        elseif params[v]["type"] == "Switch" then

        end
    end

    function Sandys:AddToUpdateQueue(lineIndex, TDOVariable)
        if self.updateQueue[lineIndex] == nil then
            self.updateQueue[lineIndex] = {}
        end

        self.updateQueue[lineIndex][TDOVariable] = true

    end

    function Sandys:PrintUpdateQueue(clear) 
        for lineIndex, queueTable in pairs(self.updateQueue) do
            print("Queued Updates for Line Index: "..lineIndex.." "..self.names[lineIndex])
            for TDOVariable,_ in pairs(queueTable) do
                print("       "..TDOVariable)
                if clear==true then
                    queueTable[TDOVariable] = nil
                end
            end
        end
    end

    function Sandys:ProcessUpdateQueue(config, skipLines)
        for lineIndex, queueTable in pairs(self.updateQueue) do
            for TDOVariable,_ in pairs(queueTable) do
                if skipLines == nil or skipLines[lineIndex] ~= true then
                    self:UpdateAbility(lineIndex, TDOVariable, config)
                end
                queueTable[TDOVariable] = nil
            end
            queueTable = nil
        end

    end

    function Sandys:ProcessAllAbilities(config, skipLines)
        for lineIndex, _ in pairs(self.sandys) do
            if skipLines == nil or skipLines[lineIndex] ~= true then
                for TDOVar, TDOVarData in pairs(config.sandys[lineIndex]) do
                    if type(TDOVarData) == "table" then
                        self:UpdateAbility(lineIndex, TDOVar, config)
                    end
                end
            end
        end
    end

    function Sandys:UpdateAbility(lineIndex, TDOVar, config)
        local minSandyQuality = 0
        local maxSandyQuality = 0
        if self.sandys[lineIndex] == nil then 
            print("[TDO] ERROR! Sandys:UpdateAbility() failed because there is no Sandevistan product line in lineIndex: "..tostring(lineIndex))
            return false
        end
        if self.sandys[lineIndex][1] ~= nil then
            minSandyQuality = 1
            maxSandyQuality = #self.sandys[lineIndex]
        else 
            print("[TDO] ERROR! Sandys:UpdateAbility() failed because there is no Sandevistan in the first entry for lineIndex: "..tostring(lineIndex))
            return false
        end

        if config.sandys[lineIndex] == nil then 
            print("[TDO] ERROR! Sandys:UpdateAbility() failed because there is no config data for lineIndex: "..tostring(lineIndex))
            return false
        elseif config.sandys[lineIndex][TDOVar] == nil then 
            print("[TDO] ERROR! Sandys:UpdateAbility() failed because there is no config data for TDOVar: "..tostring(TDOVar).." in lineIndex: "..tostring(lineIndex))
            return false
        end

        local minVal = config.sandys[lineIndex][TDOVar].min
        local maxVal = config.sandys[lineIndex][TDOVar].max

        if TDOVar == "ts" or TDOVar == "ts_Air" then
            if maxVal == 100 then
                maxVal = 99.9
            end
        end

        for index, _ in ipairs(self.sandys[lineIndex]) do
            local value = minVal
            if maxSandyQuality > minSandyQuality then
                value = Round(minVal + (maxVal - minVal) * (index - minSandyQuality) / (maxSandyQuality - minSandyQuality), 0.1)
            end
            self.sandys[lineIndex][index]:UpdateAbility(TDOVar, false, value)
        end
        return true
    end

    function Sandys:SaveAllAbilityData()
        local data = {}
        for lineIndex, _ in ipairs(self.sandys) do
            data[lineIndex] = {}
            for sandyIndex, sandyData in pairs(self.sandys[lineIndex]) do
                data[lineIndex][sandyIndex] = sandyData:GrabAbilitiesData()
            end
        end

        

        local validJson, contents = pcall(function() return json.encode(data) end)
        local fileName = "data/temp/sandyAbilityData.json"

        if validJson and contents ~= nil then

            local file = io.open(fileName, "w+")
            if file ~= nil then
                file:write(contents)
                file:close()
                print("[TDO]: \""..fileName.."\" successfully stored ability data.")
            else
                print("[TDO]: ERROR: Could not open/create \""..fileName.."\" file to store ability data.")	
            end
        else
            print("[TDO]: ERROR: Error encoding ability data for \""..fileName.."\". Abiltiy data not saved.")
            print("         validJson: "..tostring(validJson))
            print("         contents: "..tostring(contents))
        end

    end

    function Sandys:DeleteStoredAbilityData()
        os.remove("data/temp/sandyAbilityData.json")
    end

return {Sandys = Sandys, Sandy = Sandy}
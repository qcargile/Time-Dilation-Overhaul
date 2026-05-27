local Ability = {}

    
    
    
    
    
    
    
    
    
    
    
    function Ability:New(TDOVariableData, findFlat, valueFlat, uiFlat, uiValIndex, linkedVariable, existing, vanillaValue)
        local vf
        if findFlat == "metaStat" then
            vf = "metaStat"
        else
            vf = valueFlat
        end

        local vv
        if vanillaValue == nil then
            if existing == true then
                vv = Round(TweakDB:GetFlat(valueFlat),0.01)
            end
        else
            vv = vanillaValue
        end

        local data = {
            
            existing = existing or false,
            findFlat = findFlat,
            valueFlat = vf,
            vanillaValue = vv,
            uiFlat = uiFlat,
            uiValIndex = uiValIndex,
            uiModifier = TDOVariableData.UIModifier,
            valueModifier = TDOVariableData.valueModifier,
            linkedVariable = linkedVariable,
        }
        setmetatable(data, self)
        self.__index = self
        return data
    end

    function Ability:Delete()
        
        
        
        
    end

    function Ability:UpdateAbility(TDOValue, uiValue)
        
        if TDOValue ~= nil then
            
            
            TweakDB:SetFlat(self.valueFlat, self:ToGameValue(TDOValue))
            
        end
        
        if self.uiFlat ~= "Not Found" then
            local uiTable = TweakDB:GetFlat(self.uiFlat)
            
            uiTable[self.uiValIndex] = uiValue
            TweakDB:SetFlat(self.uiFlat, uiTable)
            
        else
            print("[TDO] ERROR! Ability:UpdateAbility() had no uiFlat location. self.uiFlat = "..tostring(self.uiFlat))
        end
    end

    function Ability:Print()
        
        print("         findFlat: "..self.findFlat)
        print("         valueFlat: "..self.valueFlat)
        print("         vanillaValue: "..self.vanillaValue)
        print("         uiFlat: "..self.uiFlat)
        print("         uiValIndex: "..self.uiValIndex)
        print("         uiModifier: "..self.uiModifier)
        print("         valueModifier: "..self.valueModifier)
        if self.linkedVariable ~= nil then
            if self.linkedVariable.metaStat ~= nil then
                print("         linkedVariable.metaStat: "..self.linkedVariable.metaStat)       
            elseif self.linkedVariable.metaStatVariables ~= nil then
                print("         linkedVariable.metaStatVariables:")  
                for i,v in pairs(self.linkedVariable.metaStatVariables) do
                    print("         "..i..": "..v)
                end 
            else
                print("         linkedVariable.variable: "..self.linkedVariable.variable)
                print("         linkedVariable.ui: "..tostring(self.linkedVariable.ui))
            end
        else
            print("         linkedVariable: nil")            
        end
        print("         existing: "..tostring(self.existing))
    end

    function Ability:IsPartOfMetaStat() 
        if type(self.linkedVariable) == "table" then
            if self.linkedVariable.metaStat ~= nil then
                return true
            end
        end

        return false
    end

    function Ability:IsMetaStat()
        if type(self.linkedVariable) == "table" then
            if self.linkedVariable.metaStatVariables ~= nil then
                return true
            end
        end

        return false
    end

    
    function Ability:GetMetaStatVariables()
        if self:IsMetaStat() then
            if self.linkedVariable.metaStatVariables ~= nil then
                return self.linkedVariable.metaStatVariables
            else
                return nil
            end
        else
            return nil
        end

    end

    function Ability:IsLinked()
        if self.linkedVariable ~= nil then
            return true
        else
            return false
        end
    end

    function Ability:IsLinkedFrom()
        if self:IsLinked() then
            if self.linkedVariable.ui ~= nil then
                if self.linkedVariable.ui == "From" then
                    return true, self.linkedVariable.variable
                else
                    return false, nil
                end
            else
                return false, nil
            end
        else
            return false, nil
        end
    end

    function Ability:IsLinkedTo()
        if self:IsLinked() then
            if self.linkedVariable.ui ~= nil then
                if self.linkedVariable.ui == "To" then
                    return true, self.linkedVariable.variable
                else
                    return false, nil
                end
            else
                return false, nil
            end
        else
            return false, nil
        end
    end

    function Ability:VanillaValue()
        return self.vanillaValue
    end

    function Ability:VanillaTDOValue()
        return self:ToTDOValue(self:VanillaValue())
    end

    function Ability:CurrentValue()
        return TweakDB:GetFlat(self.valueFlat)
    end

    function Ability:CurrentTDOValue()
        return self:ToTDOValue(self:CurrentValue())
    end

    function Ability:IsExisting()
        return self.existing
    end

    function Ability:GetUIMod()
        return self.uiModifier
    end

    function Ability:ToTDOValue(value)
        local val
        if value == nil then
            val = self:VanillaValue()
        else
            val = value
        end

        if self.valueModifier ~= nil then
            if self.valueModifier == "Percent" then
                return Round(val * 100,0.1)
            elseif self.valueModifier == "Percent_MinusOne" then
                return Round((val-1) * 100,0.1)
            elseif self.valueModifier == "MinusOne_Percent" then
                
                return Round((1-val) * 100,0.1)
            elseif self.valueModifier == "Negative_Percent" then
                
                return Round(-val * 100,0.1)
            else
                return val
            end
        else
            return val
        end
    end

    function Ability:ToGameValue(value)
        local val
        if value == nil then
            val = self:GetVanillaValue()
        else
            val = value
        end

        if self.valueModifier ~= nil then
            if self.valueModifier == "Percent" then
                return Round(val / 100,0.001)
            elseif self.valueModifier == "Percent_MinusOne" then
                return Round((val / 100) + 1,0.001)
            elseif self.valueModifier == "MinusOne_Percent" then
                return Round(1-(val/100),0.001)
            elseif self.valueModifier == "Negative_Percent" then
                
                return Round(-val / 100,0.001)
            else
                return val
            end
        else
            return val
        end
    end

    function Ability:GetData()
        return {
            existing = self.existing,
            findFlat = self.findFlat,
            valueFlat = self.valueFlat,
            vanillaValue = self.vanillaValue,
            uiFlat = self.uiFlat,
            uiValIndex = self.uiValIndex,
            linkedVariable = self.linkedVariable,
            TDOVariableData = {
                UIModifier = self.uiModifier,
                valueModifier = self.valueModifier
                }
            }
    end

local Abilities = {}

    function Abilities:New()
        local data = {
            abilities = {},
        }
        setmetatable(data, self)
        self.__index = self
        return data
    end

    function Abilities:GetUIValue(TDOVariable, value)
        if self.abilities[TDOVariable] ~= nil then
            local to, fromVariable = self.abilities[TDOVariable]:IsLinkedTo()
            
            if to == true then
                return self.abilities[TDOVariable]:ToTDOValue(value) + self.abilities[fromVariable]:ToTDOValue(self.abilities[fromVariable]:CurrentValue()) 
            else
                return self.abilities[TDOVariable]:ToTDOValue(value)
            end
        end
    end

    function Abilities:GetAbility(TDOVariable)
        return self.abilities[TDOVariable]
    end

    function Abilities:GetAbilityVars()
        local vars = {}
        for var, ability in pairs(self.abilities) do
            if ability:IsPartOfMetaStat() == false then
                vars[var] = true
            end
        end
        return vars
    end

    
    
    
    
    
    
    
    
    
    
    
    function Abilities:AddAbility(TDOVariable, TDOVariableData, findFlat, valueFlat, uiFlat, uiValIndex, linked, existing, vanillaValue)
        print("[TDO] Discovered ability: " .. tostring(TDOVariable) .. " at " .. tostring(valueFlat))
        self.abilities[TDOVariable] = Ability:New(TDOVariableData, findFlat, valueFlat, uiFlat, uiValIndex, linked, existing, vanillaValue)
    end

    function Abilities:DeleteAbility(TDOVariable)
        self.abilities[TDOVariable]:Delete()
        self.abilities[TDOVariable] = nil
    end

    function Abilities:UpdateAbility(TDOVariable, reset, TDOValue)
        if self.abilities[TDOVariable] ~= nil then
            
            local TDOVal_Working
            local TDOUIVal
            local TDOVal_Working_To
            local TDOVal_Working_To_Total
            local to, fromVariable = self.abilities[TDOVariable]:IsLinkedTo()
            local from, toVariable = self.abilities[TDOVariable]:IsLinkedFrom()

            if reset == true then
                TDOVal_Working = self.abilities[TDOVariable]:VanillaTDOValue()
                TDOUIVal = self.abilities[TDOVariable]:VanillaTDOValue()
                
                if to == true then
                    
                    TDOUIVal = TDOUIVal + self.abilities[fromVariable]:VanillaTDOValue()
                    TDOVal_Working = TDOUIVal - self.abilities[fromVariable]:CurrentTDOValue()
                    
                    

                elseif from == true then
                    
                    
                    

                    TDOVal_Working_To_Total = self.abilities[toVariable]:CurrentTDOValue() + self.abilities[TDOVariable]:CurrentTDOValue()
                    
                    TDOVal_Working_To = TDOVal_Working_To_Total - TDOVal_Working
                    
                elseif self.abilities[TDOVariable]:IsMetaStat() then 
                    for _, TDOSubVariable in ipairs(self.abilities[TDOVariable]:GetMetaStatVariables()) do
                        
                        
                        TDOVal_Working = self.abilities[TDOSubVariable]:VanillaTDOValue()
                        self.abilities[TDOSubVariable]:UpdateAbility(TDOVal_Working, TDOUIVal)
                    end
                end
            else
                
                TDOVal_Working = Round(TDOValue, 0.1)
                TDOUIVal = Round(TDOValue, 0.1)

                if to == true then
                    
                    TDOVal_Working = TDOVal_Working - self.abilities[fromVariable]:CurrentTDOValue()
                    
                    
                elseif from == true then
                    
                    
                    
                    TDOVal_Working_To_Total = self.abilities[toVariable]:CurrentTDOValue() + self.abilities[TDOVariable]:CurrentTDOValue()
                    
                    TDOVal_Working_To = TDOVal_Working_To_Total - TDOVal_Working
                    
                elseif self.abilities[TDOVariable]:IsMetaStat() then
                    
                    for _, TDOSubVariable in ipairs(self.abilities[TDOVariable]:GetMetaStatVariables()) do
                        
                        self.abilities[TDOSubVariable]:UpdateAbility(TDOVal_Working, TDOUIVal)
                    end
                    TDOVal_Working = nil
                end
            end
            
            self.abilities[TDOVariable]:UpdateAbility(TDOVal_Working, TDOUIVal)

            if TDOVal_Working_To ~= nil then
                
                self.abilities[toVariable]:UpdateAbility(TDOVal_Working_To, TDOVal_Working_To_Total)
            end
            

        else 
            print("[TDO] ERROR! Abilities:UpdateAbility() failed because no ability is present for the TDOVariable. TDOVariable: "..tostring(TDOVariable))
        end

    end

    
    
    
    function Abilities:FindAbilities(sandyFlat, TDOAbilityData, savedData)
        local recordFlats = {
            statModifiers = TweakDB:GetFlat(sandyFlat..".statModifiers"),
            OnEquip = TweakDB:GetFlat(sandyFlat..".OnEquip")
        }
        if recordFlats.statModifiers ~= nil then
            
            local ignoreList = {}
            if type(recordFlats.statModifiers) == "table" then
                for modIndex, modFlat in ipairs(recordFlats.statModifiers) do
                    if ignoreList[modIndex] == nil then
                        local modFlatString = TDBID.ToStringDEBUG(modFlat)
                        for TDOVariable, TDOVariableData in pairs(TDOAbilityData.statModifiers) do
                            self:FlatMatch(modFlatString, TDOVariable, TDOVariableData, recordFlats, TDOAbilityData.metaStats, savedData)
                        end
                    end
                end
            end
        end

        if recordFlats.OnEquip ~= nil then

            if type(recordFlats.OnEquip) == "table" then

                for _, glpFlat in ipairs(recordFlats.OnEquip) do

                    for TDOVariable, TDOVariableData in pairs(TDOAbilityData.OnEquip) do
                        
                        for _, effectorFlat in ipairs(TweakDB:GetFlat(glpFlat..".effectors")) do

                            if TDOVariableData.effectorClass == TweakDB:GetFlat(effectorFlat..".effectorClassName") then
                                
                                local preRec = TweakDB:GetRecord(TweakDB:GetFlat(effectorFlat..".prereqRecord"))
                                local prereqMatch = false
                                if preRec:GetClassName() == CName.new("gamedataMultiPrereq_Record") then
                                    if type(TDOVariableData.prereqFind) == "table" then
                                        local required = #TDOVariableData.prereqFind
                                        local hits = 0
                                        for _, nestedPR in ipairs(preRec:NestedPrereqs()) do
                                            for _,PR in ipairs(TDOVariableData.prereqFind) do
                                                if PR == nestedPR:PrereqClassName() then
                                                    hits = hits + 1
                                                    if hits == required then
                                                        prereqMatch = true
                                                        break
                                                    end
                                                end
                                            end
                                        end                                     

                                    end
                                else
                                    if TDOVariableData.prereqFind == preRec:PrereqClassName() then
                                        prereqMatch = true
                                    end
                                end
                                
                                if prereqMatch == true then
                                    if TDOVariableData.effectorClass == CName.new("ApplyStatGroupEffector") then
                                        for _, statModFlat in ipairs(TweakDB:GetFlat(TweakDB:GetFlat(effectorFlat..".statGroup")..".statModifiers")) do
                                            self:FlatMatch(statModFlat, TDOVariable, TDOVariableData, recordFlats, TDOAbilityData.metaStats, savedData)
                                        end
                                    elseif TDOVariableData.effectorClass == CName.new("ApplyEffectorEffector") then
                                        self:FlatMatch(TweakDB:GetFlat(effectorFlat..".effectorToApply"), TDOVariable, TDOVariableData, recordFlats, TDOAbilityData.metaStats, savedData)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        recordFlats = nil
    end

    function Abilities:FindUI(TDOVariableData, OnEquip, metaStatData)
        local uiFlat = "Not Found"
        local uiValIndex = 0
        local linked = {}
        local metaLinked = {}
        
        
        
        local tdoHashedLocKeyToVanilla = {
            ["13819718691745878578"] = 92102,
            ["2747526873593501739"] = 53584,
            ["18264447394481260021"] = 92123,
            ["302817202488974181"] = 92103,
            ["9892157732429628605"] = 91021,
        }
        for _, glpuiFlat in ipairs(OnEquip) do
            if TweakDB:GetRecord(TweakDB:GetFlat(glpuiFlat..".UIData")) ~= nil then
                local hashStr = string.match(tostring(TweakDB:GetFlat(TweakDB:GetFlat(glpuiFlat..".UIData")..".localizedDescription")), "LocKey#(%d+)")
                local locDes
                if hashStr ~= nil then
                    locDes = tdoHashedLocKeyToVanilla[hashStr]
                    if locDes == nil then
                        locDes = 1*hashStr
                    end
                end
                if type(TDOVariableData.existingUI) == "table" and locDes ~= nil then
                    if TDOVariableData.existingUI[locDes] ~= nil then
                        uiFlat = TDBID.ToStringDEBUG(TweakDB:GetFlat(glpuiFlat..".UIData"))..TDOVariableData.existingUILocation

                        if TDOVariableData.linkedUI ~= nil then
                            if TDOVariableData.linkedUI[locDes] ~= nil then
                                linked = TDOVariableData.linkedUI[locDes]
                                if TDOVariableData.linkedUI[locDes].metaStat ~= nil then
                                    metaLinked = metaStatData[TDOVariableData.linkedUI[locDes].metaStat].linkedUI[locDes]
                                    
                                        
                                    

                                else
                                    metaLinked = nil
                                end
                            else
                                linked = nil
                                metaLinked = nil
                            end

                        else
                            linked = nil
                            metaLinked = nil
                        end

                        uiValIndex = TDOVariableData.existingUI[locDes]
                        break
                    end
                end
            end
        end

        if uiFlat == "Not Found" then
            linked = nil
            metaLinked = nil
        end
        
        return uiFlat, uiValIndex, linked, metaLinked
    end

    function Abilities:Print()
        
        for TDOVariable, ab in pairs(self.abilities) do
            print("      "..TDOVariable)
            ab:Print()
        end
        
    end

    function Abilities:Exists(TDOVariable)
        if self.abilities[TDOVariable] ~= nil then
            return true
        end
        return false
    end

    function Abilities:FlatMatch(inputFlat, TDOVariable, TDOVariableData, recordFlats, metaStatsData, savedData)
        local fullFind = true
        if type(savedData) == "table" then
            if savedData[TDOVariable] ~= nil then
                self:AddAbility(TDOVariable, savedData[TDOVariable].TDOVariableData, savedData[TDOVariable].findFlat, savedData[TDOVariable].valueFlat, savedData[TDOVariable].uiFlat, savedData[TDOVariable].uiValIndex, savedData[TDOVariable].linkedVariable, savedData[TDOVariable].existing, savedData[TDOVariable].vanillaValue)
                if type(savedData[TDOVariable].linkedVariable) == "table" then
                    if savedData[TDOVariable].linkedVariable.metaStat ~= nil then
                        local metaStatVar = savedData[TDOVariable].linkedVariable.metaStat
                        if self:Exists(metaStatVar) == false then
                            self:AddAbility(metaStatVar, savedData[metaStatVar].TDOVariableData, savedData[metaStatVar].findFlat, savedData[metaStatVar].valueFlat, savedData[metaStatVar].uiFlat, savedData[metaStatVar].uiValIndex, savedData[metaStatVar].linkedVariable, savedData[metaStatVar].existing, savedData[metaStatVar].vanillaValue)
                        end
                    end
                end
                fullFind = false
            end
        end

        if fullFind == true then
            local findFlat = TweakDB:GetFlat(inputFlat..TDOVariableData.findLocation)

            if findFlat ~= nil then
                if TDOVariableData.find == findFlat then
                    if TDOVariableData.findLocation2 ~= nil then
                        local etaSubFlat = TweakDB:GetFlat(inputFlat..TDOVariableData.effectorGetFlat)

                        if type(etaSubFlat) == "table" then
                            if etaSubFlat ~= nil then      
                                for _, flat in ipairs(etaSubFlat) do
                                    local findFlat2 = TweakDB:GetFlat(flat..TDOVariableData.findLocation2)
                                    if findFlat2 ~= nil then
                                        if TDOVariableData.find2 == findFlat2 then
                                            
                                            local uiFlat, uiValIndex, linked, metaLinked = self:FindUI(TDOVariableData, recordFlats.OnEquip, metaStatsData)
                                            if type(linked) == "table" then
                                                if linked.metaStat ~= nil then
                                                    if self:Exists(linked.metaStat) == false then
                                                        self:AddAbility(linked.metaStat, metaStatsData[linked.metaStat], "metaStat", TDBID.ToStringDEBUG(flat)..TDOVariableData.valueLocation, uiFlat, uiValIndex, metaLinked, true)
                                                    end
                                                end
                                            end
                                            self:AddAbility(TDOVariable, TDOVariableData, TDBID.ToStringDEBUG(flat)..TDOVariableData.findLocation2, TDBID.ToStringDEBUG(flat)..TDOVariableData.valueLocation, uiFlat, uiValIndex, linked, true)
                                        end
                                    end
                                end
                            end
                        end 

                    else
                    
                    local uiFlat, uiValIndex, linked, metaLinked = self:FindUI(TDOVariableData, recordFlats.OnEquip, metaStatsData)
                    if type(linked) == "table" then
                        
                        if linked.metaStat ~= nil then
                            
                            if self:Exists(linked.metaStat) == false then
                                
                                self:AddAbility(linked.metaStat, metaStatsData[linked.metaStat], "metaStat", TDBID.ToStringDEBUG(inputFlat)..TDOVariableData.valueLocation, uiFlat, uiValIndex, metaLinked, true)
                            end
                        end
                    end
                    self:AddAbility(TDOVariable, TDOVariableData, TDBID.ToStringDEBUG(inputFlat)..TDOVariableData.findLocation, TDBID.ToStringDEBUG(inputFlat)..TDOVariableData.valueLocation, uiFlat, uiValIndex, linked, true)
                    end
                end
            end
        end
    end

    function Abilities:GrabAbilitiesData()
        local abilityData = {}
        for TDOVariable, ability in pairs(self.abilities) do
            abilityData[TDOVariable] = ability:GetData()
        end

        return abilityData
    end

return {Ability = Ability, Abilities = Abilities}

                            
                            
                                
                                    
                                    
                                    
                                    
                                   
                                
                            
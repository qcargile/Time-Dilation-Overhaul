local modName = "TDO"
local LoadedLanguage

local Localization = {}

function Localization.LoadLanguage()
    if LoadedLanguage == nil then
        LoadedLanguage = require("modules/languages/"..NameToString(GameSettings.Get("/language/OnScreen"))..".lua")
        if LoadedLanguage == nil then
                print("["..modName.."] LoadLanguage() WARNING: Could not locate a language file matching the game language setting. Loading english (\"en-us.lua\") language file.")
            LoadedLanguage = require("modules/languages/en-us.lua")
            if LoadedLanguage == nil then
                print("["..modName.."] LoadLanguage() ERROR: No language file found!")
                return
            else
                print("["..modName.."] LoadLanguage() SUCCESS: Language file loaded!")
            end
        end
    end
end

function Localization.GetTextWithKeys(key1, key2, key3, key4)
    if key1 ~= nil then
        if LoadedLanguage[key1] ~= nil then
            if key2 ~= nil then
                if LoadedLanguage[key1][key2] ~= nil then
                    if key3 ~= nil then
                        if LoadedLanguage[key1][key2][key3] ~= nil then
                            if key4 ~= nil then
                                if LoadedLanguage[key1][key2][key3][key4] ~= nil then
                                    return LoadedLanguage[key1][key2][key3][key4]
                                else
                                    print("["..modName.."] Localization.GetTextWithKeys() ERROR: Text not found at : \""..tostring(key1).."."..tostring(key2).."."..tostring(key3).."."..tostring(key4).."\"")
                                    return "ERROR: MISSING TRANSLATION TEXT"
                                end                                    
                            elseif LoadedLanguage[key1][key2][key3] ~= nil then
                                return LoadedLanguage[key1][key2][key3]
                            else
                                print("["..modName.."] Localization.GetTextWithKeys() ERROR: Text not found at : \""..tostring(key1).."."..tostring(key2).."."..tostring(key3).."\"")
                                return "ERROR: MISSING TRANSLATION TEXT"
                            end
                        end
                    elseif LoadedLanguage[key1][key2] ~= nil then
                        return LoadedLanguage[key1][key2]
                    else
                        print("["..modName.."] Localization.GetTextWithKeys() ERROR: Text not found at : \""..tostring(key1).."."..tostring(key2).."\"")
                        return "ERROR: MISSING TRANSLATION TEXT"
                    end
                else
                    print("["..modName.."] Localization.GetTextWithKeys() ERROR: Data not found at : \""..tostring(key1).."."..tostring(key2).."\"")
                    return "ERROR: MISSING TRANSLATION TEXT"
                end
            elseif LoadedLanguage[key1] ~= nil then
                return LoadedLanguage[key1]
            else
                print("["..modName.."] Localization.GetTextWithKeys() ERROR: Text not found at : \""..tostring(key1).."\"")
                return "ERROR: MISSING TRANSLATION TEXT"
            end
        else
            print("["..modName.."] Localization.GetTextWithKeys() ERROR: Data not found at : \""..tostring(key1).."\"")
            return "ERROR: MISSING TRANSLATION TEXT"
        end
    else
        print("["..modName.."] Localization.GetTextWithKeys() ERROR: No \"key1\" provided.")
        return "ERROR: MISSING TRANSLATION TEXT"
    end
end

return Localization
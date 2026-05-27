Cron = require("CETKit/Cron.lua")
GameUI = require("modules/external/GameUI")
GameSettings = require('CETKit/GameSettings.lua')
Localizer = require("modules/localizedText.lua")
require("modules/commonFunctions.lua")
local sandyData = require("data/sandyData.lua")
local AbilityDefs = require("definitions/abilities.lua")
local SandyDefs = require("definitions/sandevistan.lua")
local sandys = SandyDefs.Sandys:New()

local config = {}
local default = require("config/nUIDefaults.lua")
local options = { sandys = {} }
local isLoaded = false
local Initialized = false
local ExternalMods = {}
local TDOAbilityData = {}

local TDO_VERSION = "v0.3"
local ESR_VERSION = "d2026.5.25"

local function lerpTier(v1, vTop, tier, total)
	if total <= 1 then return v1 end
	return v1 + (vTop - v1) * (tier - 1) / (total - 1)
end

local function createShrikeMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "zetatech"
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["markRange"]["opt"]..nuiTxt[cat]["markRange"]["optUnit"], nuiTxt[cat]["markRange"]["des"], 5.0, 30.0, 1.0, "%.0f", config.zetatech.markRange, default.zetatech.markRange, function(value)
		config.zetatech.markRange = value
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgTrash"]["opt"]..nuiTxt[cat]["executeDmgTrash"]["optUnit"], nuiTxt[cat]["executeDmgTrash"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgTrash, default.zetatech.executeDmgTrash, function(value) config.zetatech.executeDmgTrash = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgWeak"]["opt"]..nuiTxt[cat]["executeDmgWeak"]["optUnit"], nuiTxt[cat]["executeDmgWeak"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgWeak, default.zetatech.executeDmgWeak, function(value) config.zetatech.executeDmgWeak = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgNormal"]["opt"]..nuiTxt[cat]["executeDmgNormal"]["optUnit"], nuiTxt[cat]["executeDmgNormal"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgNormal, default.zetatech.executeDmgNormal, function(value) config.zetatech.executeDmgNormal = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgRare"]["opt"]..nuiTxt[cat]["executeDmgRare"]["optUnit"], nuiTxt[cat]["executeDmgRare"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgRare, default.zetatech.executeDmgRare, function(value) config.zetatech.executeDmgRare = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgOfficer"]["opt"]..nuiTxt[cat]["executeDmgOfficer"]["optUnit"], nuiTxt[cat]["executeDmgOfficer"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgOfficer, default.zetatech.executeDmgOfficer, function(value) config.zetatech.executeDmgOfficer = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgElite"]["opt"]..nuiTxt[cat]["executeDmgElite"]["optUnit"], nuiTxt[cat]["executeDmgElite"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgElite, default.zetatech.executeDmgElite, function(value) config.zetatech.executeDmgElite = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgMaxTac"]["opt"]..nuiTxt[cat]["executeDmgMaxTac"]["optUnit"], nuiTxt[cat]["executeDmgMaxTac"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgMaxTac, default.zetatech.executeDmgMaxTac, function(value) config.zetatech.executeDmgMaxTac = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["executeDmgBoss"]["opt"]..nuiTxt[cat]["executeDmgBoss"]["optUnit"], nuiTxt[cat]["executeDmgBoss"]["des"], 0.0, 100.0, 1.0, "%.0f", config.zetatech.executeDmgBoss, default.zetatech.executeDmgBoss, function(value) config.zetatech.executeDmgBoss = value saveSettings(config) end))

	return handles
end

local function createTantoMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "tanto"
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["teleportBaseRange"]["opt"]..nuiTxt[cat]["teleportBaseRange"]["optUnit"], nuiTxt[cat]["teleportBaseRange"]["des"], 5.0, 100.0, 1.0, "%.0f", config.tanto.teleportBaseRange, default.tanto.teleportBaseRange, function(value)
		config.tanto.teleportBaseRange = value
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["teleportMaxRange"]["opt"]..nuiTxt[cat]["teleportMaxRange"]["optUnit"], nuiTxt[cat]["teleportMaxRange"]["des"], 5.0, 100.0, 1.0, "%.0f", config.tanto.teleportMaxRange, default.tanto.teleportMaxRange, function(value)
		config.tanto.teleportMaxRange = value
		saveSettings(config)
	end))

	return handles
end

local function createWarpDancerMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "warpDancer"

	local warpDancerTierSuffixes = {"MK3", "MK3Plus", "MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}

	local function applyWarpDancerStaggerPerTier()
		if config.warpDancer.enabled == false then return end
		local sMin = config.warpDancer.staggerDurationMinSec
		local sMax = config.warpDancer.staggerDurationMaxSec
		for i, suffix in ipairs(warpDancerTierSuffixes) do
			local t = (i - 1) / 6.0
			local staggerSec = sMax - (sMax - sMin) * t
			TweakDB:SetFlat("StatusEffects.TDO_WarpDancerStagger_" .. suffix .. "_DurMod.value", staggerSec)
		end
	end

	local function applyWarpDancerMoveSpeed()
		if config.warpDancer.enabled == false then return end
		local msMin = config.warpDancer.moveSpeedMin
		local msMax = config.warpDancer.moveSpeedMax
		for i, suffix in ipairs(warpDancerTierSuffixes) do
			local t = (i - 1) / 6.0
			local msPct = msMin + (msMax - msMin) * t
			TweakDB:SetFlat("StatusEffects.TDO_WarpDancerMoveSpeed_" .. suffix .. "_Mod.value", 1.0 + msPct / 100.0)
		end
	end

	local function applyWarpDancerCardValues()
		if config.warpDancer.enabled == false then return end
		local warpDancerActivationInline = { MK3 = 8, MK3Plus = 8, MK4 = 8, MK4Plus = 8, MK5 = 1, MK5Plus = 1, MK5PlusPlus = 1 }
		local msMin = config.warpDancer.moveSpeedMin
		local msMax = config.warpDancer.moveSpeedMax
		local stgMin = config.warpDancer.staggerDurationMinSec
		local stgMax = config.warpDancer.staggerDurationMaxSec
		for i, suffix in ipairs(warpDancerTierSuffixes) do
			local t = (i - 1) / 6.0
			local msPct = msMin + (msMax - msMin) * t
			local stgSec = stgMax - (stgMax - stgMin) * t
			local inlineNum = warpDancerActivationInline[suffix]
			local floatPath = "Items.AdvancedSandevistanC3" .. suffix .. "_inline" .. tostring(inlineNum) .. ".floatValues"
			local floats = TweakDB:GetFlat(floatPath)
			if type(floats) == "table" then
				while #floats < 7 do table.insert(floats, 0.0) end
				floats[6] = msPct
				floats[7] = stgSec
				TweakDB:SetFlat(floatPath, floats)
			end
		end
	end

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["moveSpeedMin"]["opt"]..nuiTxt[cat]["moveSpeedMin"]["optUnit"], nuiTxt[cat]["moveSpeedMin"]["des"], 0.0, 100.0, 0.5, "%.1f", config.warpDancer.moveSpeedMin, default.warpDancer.moveSpeedMin, function(value)
		config.warpDancer.moveSpeedMin = value
		applyWarpDancerMoveSpeed()
		applyWarpDancerCardValues()
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["moveSpeedMax"]["opt"]..nuiTxt[cat]["moveSpeedMax"]["optUnit"], nuiTxt[cat]["moveSpeedMax"]["des"], 0.0, 100.0, 0.5, "%.1f", config.warpDancer.moveSpeedMax, default.warpDancer.moveSpeedMax, function(value)
		config.warpDancer.moveSpeedMax = value
		applyWarpDancerMoveSpeed()
		applyWarpDancerCardValues()
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rewindDurationSec"]["opt"]..nuiTxt[cat]["rewindDurationSec"]["optUnit"], nuiTxt[cat]["rewindDurationSec"]["des"], 0.5, 10.0, 0.1, "%.1f", config.warpDancer.rewindDurationSec, default.warpDancer.rewindDurationSec, function(value)
		config.warpDancer.rewindDurationSec = value
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["staggerDurationMinSec"]["opt"]..nuiTxt[cat]["staggerDurationMinSec"]["optUnit"], nuiTxt[cat]["staggerDurationMinSec"]["des"], 0.0, 5.0, 0.05, "%.2f", config.warpDancer.staggerDurationMinSec, default.warpDancer.staggerDurationMinSec, function(value)
		config.warpDancer.staggerDurationMinSec = value
		applyWarpDancerStaggerPerTier()
		applyWarpDancerCardValues()
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["staggerDurationMaxSec"]["opt"]..nuiTxt[cat]["staggerDurationMaxSec"]["optUnit"], nuiTxt[cat]["staggerDurationMaxSec"]["des"], 0.0, 5.0, 0.05, "%.2f", config.warpDancer.staggerDurationMaxSec, default.warpDancer.staggerDurationMaxSec, function(value)
		config.warpDancer.staggerDurationMaxSec = value
		applyWarpDancerStaggerPerTier()
		applyWarpDancerCardValues()
		saveSettings(config)
	end))

	return handles
end

local function createApogeeMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "apogee"
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["strainMultiplierCap"]["opt"]..nuiTxt[cat]["strainMultiplierCap"]["optUnit"], nuiTxt[cat]["strainMultiplierCap"]["des"], 1.0, 32.0, 0.5, "%.1f", config.apogee.strainMultiplierCap, default.apogee.strainMultiplierCap, function(value)
		config.apogee.strainMultiplierCap = value
		saveSettings(config)
	end))
	return handles
end

local function createFusilladeMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "fusillade"

	local function applyFusilladeTweaks()
		TweakDB:SetFlat("Items.TDO_Fusillade_TimeScale.value", config.fusillade.timeScale)
		TweakDB:SetFlat("Items.TDO_Fusillade_Duration.value", config.fusillade.durationMin)
		TweakDB:SetFlat("Items.TDO_FusilladePlus_Duration.value", config.fusillade.durationMax)
		TweakDB:SetFlat("Items.TDO_Fusillade_Recharge.value", config.fusillade.cooldownMax)
		TweakDB:SetFlat("Items.TDO_FusilladePlus_Recharge.value", config.fusillade.cooldownMin)
		TweakDB:SetFlat("Items.TDO_Fusillade_RecoilKickMin.value", config.fusillade.recoil)
		TweakDB:SetFlat("Items.TDO_Fusillade_RecoilKickMax.value", config.fusillade.recoil)
	end
	applyFusilladeTweaks()

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["timeScale"]["opt"]..nuiTxt[cat]["timeScale"]["optUnit"], nuiTxt[cat]["timeScale"]["des"], 0.01, 1.0, 0.01, "%.2f", config.fusillade.timeScale, default.fusillade.timeScale, function(value) config.fusillade.timeScale = value applyFusilladeTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 1.0, 30.0, 0.5, "%.1f", config.fusillade.durationMin, default.fusillade.durationMin, function(value) config.fusillade.durationMin = value applyFusilladeTweaks() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 1.0, 30.0, 0.5, "%.1f", config.fusillade.durationMax, default.fusillade.durationMax, function(value) config.fusillade.durationMax = value applyFusilladeTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.fusillade.cooldownMin, default.fusillade.cooldownMin, function(value) config.fusillade.cooldownMin = value applyFusilladeTweaks() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.fusillade.cooldownMax, default.fusillade.cooldownMax, function(value) config.fusillade.cooldownMax = value applyFusilladeTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["fireRateMult"]["opt"]..nuiTxt[cat]["fireRateMult"]["optUnit"], nuiTxt[cat]["fireRateMult"]["des"], 1.0, 4.0, 0.1, "%.1f", config.fusillade.fireRateMult, default.fusillade.fireRateMult, function(value) config.fusillade.fireRateMult = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rampStartMin"]["opt"]..nuiTxt[cat]["rampStartMin"]["optUnit"], nuiTxt[cat]["rampStartMin"]["des"], 0.0, 1.0, 0.05, "%.2f", config.fusillade.rampStartMin, default.fusillade.rampStartMin, function(value) config.fusillade.rampStartMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rampStartMax"]["opt"]..nuiTxt[cat]["rampStartMax"]["optUnit"], nuiTxt[cat]["rampStartMax"]["des"], 0.0, 1.0, 0.05, "%.2f", config.fusillade.rampStartMax, default.fusillade.rampStartMax, function(value) config.fusillade.rampStartMax = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rampStep"]["opt"]..nuiTxt[cat]["rampStep"]["optUnit"], nuiTxt[cat]["rampStep"]["des"], 0.0, 1.0, 0.05, "%.2f", config.fusillade.rampStep, default.fusillade.rampStep, function(value) config.fusillade.rampStep = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["recoil"]["opt"]..nuiTxt[cat]["recoil"]["optUnit"], nuiTxt[cat]["recoil"]["des"], 0.0, 3.0, 0.1, "%.1f", config.fusillade.recoil, default.fusillade.recoil, function(value) config.fusillade.recoil = value applyFusilladeTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["ammoRefillMaxChancePct"]["opt"]..nuiTxt[cat]["ammoRefillMaxChancePct"]["optUnit"], nuiTxt[cat]["ammoRefillMaxChancePct"]["des"], 0.0, 100.0, 1.0, "%.0f", config.fusillade.ammoRefillMaxChancePct, default.fusillade.ammoRefillMaxChancePct, function(value) config.fusillade.ammoRefillMaxChancePct = value saveSettings(config) end))

	return handles
end

local function createKurosawaMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "kurosawa"

	local function applyKurosawaTweaks()
		TweakDB:SetFlat("Items.TDO_Kurosawa_Duration.value", 999.0) -- buff cap
		TweakDB:SetFlat("Items.TDO_Kurosawa_Recharge.value", config.kurosawa.cooldown)
		TweakDB:SetFlat("Items.TDO_Kurosawa_DamageReduction.value", config.kurosawa.drMin)
		TweakDB:SetFlat("Items.TDO_KurosawaPlus_DamageReduction.value", config.kurosawa.drMax)
	end
	applyKurosawaTweaks()

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["enemySlowMult"]["opt"]..nuiTxt[cat]["enemySlowMult"]["optUnit"], nuiTxt[cat]["enemySlowMult"]["des"], 0.01, 1.0, 0.01, "%.2f", config.kurosawa.enemySlowMult, default.kurosawa.enemySlowMult, function(value) config.kurosawa.enemySlowMult = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["duration"]["opt"]..nuiTxt[cat]["duration"]["optUnit"], nuiTxt[cat]["duration"]["des"], 1.0, 30.0, 0.5, "%.1f", config.kurosawa.duration, default.kurosawa.duration, function(value) config.kurosawa.duration = value applyKurosawaTweaks() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldown"]["opt"]..nuiTxt[cat]["cooldown"]["optUnit"], nuiTxt[cat]["cooldown"]["des"], 5.0, 120.0, 1.0, "%.0f", config.kurosawa.cooldown, default.kurosawa.cooldown, function(value) config.kurosawa.cooldown = value applyKurosawaTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["drMin"]["opt"]..nuiTxt[cat]["drMin"]["optUnit"], nuiTxt[cat]["drMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.drMin, default.kurosawa.drMin, function(value) config.kurosawa.drMin = value applyKurosawaTweaks() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["drMax"]["opt"]..nuiTxt[cat]["drMax"]["optUnit"], nuiTxt[cat]["drMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.drMax, default.kurosawa.drMax, function(value) config.kurosawa.drMax = value applyKurosawaTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["healMin"]["opt"]..nuiTxt[cat]["healMin"]["optUnit"], nuiTxt[cat]["healMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.healMin, default.kurosawa.healMin, function(value) config.kurosawa.healMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["healMax"]["opt"]..nuiTxt[cat]["healMax"]["optUnit"], nuiTxt[cat]["healMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.healMax, default.kurosawa.healMax, function(value) config.kurosawa.healMax = value saveSettings(config) end))

	return handles
end

local function createJuggernautMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "juggernaut"

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["lockDurationMin"]["opt"]..nuiTxt[cat]["lockDurationMin"]["optUnit"], nuiTxt[cat]["lockDurationMin"]["des"], 0.5, 30.0, 0.5, "%.1f", config.juggernaut.lockDurationMin, default.juggernaut.lockDurationMin, function(value) config.juggernaut.lockDurationMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["lockDurationMax"]["opt"]..nuiTxt[cat]["lockDurationMax"]["optUnit"], nuiTxt[cat]["lockDurationMax"]["des"], 0.5, 30.0, 0.5, "%.1f", config.juggernaut.lockDurationMax, default.juggernaut.lockDurationMax, function(value) config.juggernaut.lockDurationMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["radiusMin"]["opt"]..nuiTxt[cat]["radiusMin"]["optUnit"], nuiTxt[cat]["radiusMin"]["des"], 0.0, 100.0, 0.5, "%.1f", config.juggernaut.radiusMin, default.juggernaut.radiusMin, function(value) config.juggernaut.radiusMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["radiusMax"]["opt"]..nuiTxt[cat]["radiusMax"]["optUnit"], nuiTxt[cat]["radiusMax"]["des"], 0.0, 100.0, 0.5, "%.1f", config.juggernaut.radiusMax, default.juggernaut.radiusMax, function(value) config.juggernaut.radiusMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["damageMultMin"]["opt"], nuiTxt[cat]["damageMultMin"]["des"], 0.5, 5.0, 0.05, "%.2f", config.juggernaut.damageMultMin, default.juggernaut.damageMultMin, function(value) config.juggernaut.damageMultMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["damageMultMax"]["opt"], nuiTxt[cat]["damageMultMax"]["des"], 0.5, 5.0, 0.05, "%.2f", config.juggernaut.damageMultMax, default.juggernaut.damageMultMax, function(value) config.juggernaut.damageMultMax = value saveSettings(config) end))

	local function applyJuggernautCooldowns()
		TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T1_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 1, 5))
		TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T2_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 2, 5))
		TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T3_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 3, 5))
		TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T4_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 4, 5))
		TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T5_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 5, 5))
	end
	applyJuggernautCooldowns()

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.juggernaut.cooldownMin, default.juggernaut.cooldownMin, function(value) config.juggernaut.cooldownMin = value applyJuggernautCooldowns() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.juggernaut.cooldownMax, default.juggernaut.cooldownMax, function(value) config.juggernaut.cooldownMax = value applyJuggernautCooldowns() saveSettings(config) end))

	return handles
end

local function createPyrolithMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "pyrolith"

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 0.5, 30.0, 0.5, "%.1f", config.pyrolith.durationMin, default.pyrolith.durationMin, function(value) config.pyrolith.durationMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 0.5, 30.0, 0.5, "%.1f", config.pyrolith.durationMax, default.pyrolith.durationMax, function(value) config.pyrolith.durationMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["explosionDamageMin"]["opt"], nuiTxt[cat]["explosionDamageMin"]["des"], 0.0, 500.0, 5.0, "%.0f", config.pyrolith.explosionDamageMin, default.pyrolith.explosionDamageMin, function(value) config.pyrolith.explosionDamageMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["explosionDamageMax"]["opt"], nuiTxt[cat]["explosionDamageMax"]["des"], 0.0, 500.0, 5.0, "%.0f", config.pyrolith.explosionDamageMax, default.pyrolith.explosionDamageMax, function(value) config.pyrolith.explosionDamageMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["clusterCountMin"]["opt"], nuiTxt[cat]["clusterCountMin"]["des"], 0.0, 10.0, 1.0, "%.0f", config.pyrolith.clusterCountMin, default.pyrolith.clusterCountMin, function(value) config.pyrolith.clusterCountMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["clusterCountMax"]["opt"], nuiTxt[cat]["clusterCountMax"]["des"], 0.0, 10.0, 1.0, "%.0f", config.pyrolith.clusterCountMax, default.pyrolith.clusterCountMax, function(value) config.pyrolith.clusterCountMax = value saveSettings(config) end))

	local function applyPyrolithCooldowns()
		TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T1_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 1, 5))
		TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T2_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 2, 5))
		TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T3_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 3, 5))
		TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T4_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 4, 5))
		TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T5_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 5, 5))
	end
	applyPyrolithCooldowns()

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.pyrolith.cooldownMin, default.pyrolith.cooldownMin, function(value) config.pyrolith.cooldownMin = value applyPyrolithCooldowns() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.pyrolith.cooldownMax, default.pyrolith.cooldownMax, function(value) config.pyrolith.cooldownMax = value applyPyrolithCooldowns() saveSettings(config) end))

	return handles
end

local function createQuantumMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "quantum"
	table.insert(handles, nativeSettings.addRangeInt(path, nuiTxt[cat]["maxCharges"]["opt"], nuiTxt[cat]["maxCharges"]["des"], 1, 10, 1, config.quantum.maxCharges, default.quantum.maxCharges, function(value)
		config.quantum.maxCharges = value
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["plotFreezeStrength"]["opt"]..nuiTxt[cat]["plotFreezeStrength"]["optUnit"], nuiTxt[cat]["plotFreezeStrength"]["des"], 0.001, 0.05, 0.001, "%.3f", config.quantum.plotFreezeStrength, default.quantum.plotFreezeStrength, function(value) config.quantum.plotFreezeStrength = value saveSettings(config) end))

	local function applyQuantumDurations()
		TweakDB:SetFlat("Items.TDO_Quantum_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 1, 5))
		TweakDB:SetFlat("Items.TDO_QuantumPlus_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 2, 5))
		TweakDB:SetFlat("Items.TDO_QuantumAdvanced_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 3, 5))
		TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlus_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 4, 5))
		TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlusPlus_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 5, 5))
	end
	applyQuantumDurations()

	local function applyQuantumRecharge()
		TweakDB:SetFlat("Items.TDO_Quantum_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 1, 5))
		TweakDB:SetFlat("Items.TDO_QuantumPlus_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 2, 5))
		TweakDB:SetFlat("Items.TDO_QuantumAdvanced_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 3, 5))
		TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlus_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 4, 5))
		TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlusPlus_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 5, 5))
	end
	applyQuantumRecharge()

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.durationMin, default.quantum.durationMin, function(value) config.quantum.durationMin = value applyQuantumDurations() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.durationMax, default.quantum.durationMax, function(value) config.quantum.durationMax = value applyQuantumDurations() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 1.0, 120.0, 0.5, "%.1f", config.quantum.cooldownMin, default.quantum.cooldownMin, function(value) config.quantum.cooldownMin = value applyQuantumRecharge() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 1.0, 120.0, 0.5, "%.1f", config.quantum.cooldownMax, default.quantum.cooldownMax, function(value) config.quantum.cooldownMax = value applyQuantumRecharge() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["teleportRangeMin"]["opt"]..nuiTxt[cat]["teleportRangeMin"]["optUnit"], nuiTxt[cat]["teleportRangeMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.quantum.teleportRangeMin, default.quantum.teleportRangeMin, function(value) config.quantum.teleportRangeMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["teleportRangeMax"]["opt"]..nuiTxt[cat]["teleportRangeMax"]["optUnit"], nuiTxt[cat]["teleportRangeMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.quantum.teleportRangeMax, default.quantum.teleportRangeMax, function(value) config.quantum.teleportRangeMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareTargetsMin"]["opt"], nuiTxt[cat]["malwareTargetsMin"]["des"], 1.0, 20.0, 1.0, "%.0f", config.quantum.malwareTargetsMin, default.quantum.malwareTargetsMin, function(value) config.quantum.malwareTargetsMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareTargetsMax"]["opt"], nuiTxt[cat]["malwareTargetsMax"]["des"], 1.0, 20.0, 1.0, "%.0f", config.quantum.malwareTargetsMax, default.quantum.malwareTargetsMax, function(value) config.quantum.malwareTargetsMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareFreezeDurMin"]["opt"]..nuiTxt[cat]["malwareFreezeDurMin"]["optUnit"], nuiTxt[cat]["malwareFreezeDurMin"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.malwareFreezeDurMin, default.quantum.malwareFreezeDurMin, function(value) config.quantum.malwareFreezeDurMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareFreezeDurMax"]["opt"]..nuiTxt[cat]["malwareFreezeDurMax"]["optUnit"], nuiTxt[cat]["malwareFreezeDurMax"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.malwareFreezeDurMax, default.quantum.malwareFreezeDurMax, function(value) config.quantum.malwareFreezeDurMax = value saveSettings(config) end))

	return handles
end

local function createSogimsuMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "sogimsu"

	local function applySogimsuTweaks()
		TweakDB:SetFlat("StatusEffects.TDO_SogimsuCooldown_T1_DurMod.value", lerpTier(config.sogimsu.cooldownMax, config.sogimsu.cooldownMin, 1, 7))
		TweakDB:SetFlat("StatusEffects.TDO_SogimsuCooldown_T2_DurMod.value", lerpTier(config.sogimsu.cooldownMax, config.sogimsu.cooldownMin, 2, 7))
		TweakDB:SetFlat("StatusEffects.TDO_SogimsuCooldown_T3_DurMod.value", lerpTier(config.sogimsu.cooldownMax, config.sogimsu.cooldownMin, 3, 7))
		TweakDB:SetFlat("StatusEffects.TDO_SogimsuCooldown_T4_DurMod.value", lerpTier(config.sogimsu.cooldownMax, config.sogimsu.cooldownMin, 4, 7))
		TweakDB:SetFlat("StatusEffects.TDO_SogimsuCooldown_T5_DurMod.value", lerpTier(config.sogimsu.cooldownMax, config.sogimsu.cooldownMin, 5, 7))
		TweakDB:SetFlat("StatusEffects.TDO_SogimsuCooldown_T6_DurMod.value", lerpTier(config.sogimsu.cooldownMax, config.sogimsu.cooldownMin, 6, 7))
		TweakDB:SetFlat("StatusEffects.TDO_SogimsuCooldown_T7_DurMod.value", lerpTier(config.sogimsu.cooldownMax, config.sogimsu.cooldownMin, 7, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_DetSpeedRare.value", lerpTier(config.sogimsu.detSpeedMin, config.sogimsu.detSpeedMax, 1, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_DetSpeedRarePlus.value", lerpTier(config.sogimsu.detSpeedMin, config.sogimsu.detSpeedMax, 2, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_DetSpeedEpic.value", lerpTier(config.sogimsu.detSpeedMin, config.sogimsu.detSpeedMax, 3, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_DetSpeedEpicPlus.value", lerpTier(config.sogimsu.detSpeedMin, config.sogimsu.detSpeedMax, 4, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_DetSpeedLegendary.value", lerpTier(config.sogimsu.detSpeedMin, config.sogimsu.detSpeedMax, 5, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_DetSpeedLegendaryPlus.value", lerpTier(config.sogimsu.detSpeedMin, config.sogimsu.detSpeedMax, 6, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_DetSpeedLegendaryPlusPlus.value", lerpTier(config.sogimsu.detSpeedMin, config.sogimsu.detSpeedMax, 7, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_StealthDmgRare.value", lerpTier(config.sogimsu.stealthDmgMin, config.sogimsu.stealthDmgMax, 1, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_StealthDmgRarePlus.value", lerpTier(config.sogimsu.stealthDmgMin, config.sogimsu.stealthDmgMax, 2, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_StealthDmgEpic.value", lerpTier(config.sogimsu.stealthDmgMin, config.sogimsu.stealthDmgMax, 3, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_StealthDmgEpicPlus.value", lerpTier(config.sogimsu.stealthDmgMin, config.sogimsu.stealthDmgMax, 4, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_StealthDmgLegendary.value", lerpTier(config.sogimsu.stealthDmgMin, config.sogimsu.stealthDmgMax, 5, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_StealthDmgLegendaryPlus.value", lerpTier(config.sogimsu.stealthDmgMin, config.sogimsu.stealthDmgMax, 6, 7))
		TweakDB:SetFlat("Items.TDO_Sogimsu_StealthDmgLegendaryPlusPlus.value", lerpTier(config.sogimsu.stealthDmgMin, config.sogimsu.stealthDmgMax, 7, 7))
	end
	applySogimsuTweaks()

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.durationMin, default.sogimsu.durationMin, function(value) config.sogimsu.durationMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.durationMax, default.sogimsu.durationMax, function(value) config.sogimsu.durationMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.cooldownMin, default.sogimsu.cooldownMin, function(value) config.sogimsu.cooldownMin = value applySogimsuTweaks() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.cooldownMax, default.sogimsu.cooldownMax, function(value) config.sogimsu.cooldownMax = value applySogimsuTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["interventionsMin"]["opt"], nuiTxt[cat]["interventionsMin"]["des"], 1.0, 20.0, 1.0, "%.0f", config.sogimsu.interventionsMin, default.sogimsu.interventionsMin, function(value) config.sogimsu.interventionsMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["interventionsMax"]["opt"], nuiTxt[cat]["interventionsMax"]["des"], 1.0, 20.0, 1.0, "%.0f", config.sogimsu.interventionsMax, default.sogimsu.interventionsMax, function(value) config.sogimsu.interventionsMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["detSpeedMin"]["opt"]..nuiTxt[cat]["detSpeedMin"]["optUnit"], nuiTxt[cat]["detSpeedMin"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.detSpeedMin, default.sogimsu.detSpeedMin, function(value) config.sogimsu.detSpeedMin = value applySogimsuTweaks() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["detSpeedMax"]["opt"]..nuiTxt[cat]["detSpeedMax"]["optUnit"], nuiTxt[cat]["detSpeedMax"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.detSpeedMax, default.sogimsu.detSpeedMax, function(value) config.sogimsu.detSpeedMax = value applySogimsuTweaks() saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["stealthDmgMin"]["opt"]..nuiTxt[cat]["stealthDmgMin"]["optUnit"], nuiTxt[cat]["stealthDmgMin"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.stealthDmgMin, default.sogimsu.stealthDmgMin, function(value) config.sogimsu.stealthDmgMin = value applySogimsuTweaks() saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["stealthDmgMax"]["opt"]..nuiTxt[cat]["stealthDmgMax"]["optUnit"], nuiTxt[cat]["stealthDmgMax"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.stealthDmgMax, default.sogimsu.stealthDmgMax, function(value) config.sogimsu.stealthDmgMax = value applySogimsuTweaks() saveSettings(config) end))

	return handles
end

local function createCustomSandyShowHideMenu(nativeSettings, path, displayName, nuiTxt, config, showFlagKey, mechanicCreator)
	nativeSettings.addSubcategory(path, displayName)

	local mechanicHandles = nil

	local function clearMechanic()
		if mechanicHandles ~= nil then
			for i=1, #mechanicHandles, 1 do
				nativeSettings.removeOption(mechanicHandles[i])
				mechanicHandles[i] = nil
			end
			mechanicHandles = nil
		end
	end

	nativeSettings.addButton(path, nuiTxt.showHide.opt, nuiTxt.showHide.des, nuiTxt.showHide.button, nuiTxt.showHide.textSize, function()
		if config[showFlagKey] == true then
			config[showFlagKey] = false
			clearMechanic()
		else
			config[showFlagKey] = true
			mechanicHandles = mechanicCreator(nativeSettings, path)
		end
		saveSettings(config)
	end, 1)

	if config[showFlagKey] == true then
		mechanicHandles = mechanicCreator(nativeSettings, path)
	end
end

local function applySandyScreenEffect()
	if config.sandyVFX.useVanilla then
		TweakDB:SetFlat("playerStateMachineTimeDilation.timeDilationAcceptedReasons.sandevistanEffectReasons", {"sandevistan"})
	else
		TweakDB:SetFlat("playerStateMachineTimeDilation.timeDilationAcceptedReasons.sandevistanEffectReasons", {"none"})
	end
	TweakDB:Update("playerStateMachineTimeDilation.timeDilationAcceptedReasons.sandevistanEffectReasons")
end

local sandyGradEffects = {
	{ name = "tdo_sandy_grad_20",  path = "base\\fx\\player\\cyberware\\tdosandygradients\\sandy20gradient.effect" },
	{ name = "tdo_sandy_grad_40",  path = "base\\fx\\player\\cyberware\\tdosandygradients\\sandy40gradient.effect" },
	{ name = "tdo_sandy_grad_60",  path = "base\\fx\\player\\cyberware\\tdosandygradients\\sandy60gradient.effect" },
	{ name = "tdo_sandy_grad_80",  path = "base\\fx\\player\\cyberware\\tdosandygradients\\sandy80gradient.effect" },
	{ name = "tdo_sandy_grad_100", path = "base\\fx\\player\\cyberware\\tdosandygradients\\sandy100gradient.effect" },
}

local function tdoSandyGradHasDesc(effects, effectName)
	for _, e in pairs(effects) do
		if e.effectName == effectName then
			return true
		end
	end
	return false
end

local function initSandyGradEffects(player)
	if player == nil then return end
	local comp = player:FindComponentByName("fx_player")
	if comp == nil then return end
	local effects = comp.effectDescs
	for _, g in pairs(sandyGradEffects) do
		local cn = CName.new(g.name)
		if not tdoSandyGradHasDesc(effects, cn) then
			local d = entEffectDesc.new()
			d.effect = g.path
			d.effectName = cn
			table.insert(effects, d)
		end
	end
	comp.effectDescs = effects
end

local function sandyGradBand(player)
	local ts = Game.GetStatsSystem():GetStatValue(player:GetEntityID(), gamedataStatType.TimeDilationSandevistanTimeScale)
	local slow = (1.0 - ts) * 100.0
	if slow < 45.0 then return nil end
	if slow < 55.0 then return "tdo_sandy_grad_20" end
	if slow < 65.0 then return "tdo_sandy_grad_40" end
	if slow < 75.0 then return "tdo_sandy_grad_60" end
	if slow < 85.0 then return "tdo_sandy_grad_80" end
	return "tdo_sandy_grad_100"
end

local function applySandyGrad()
	if config.sandyVFX.useVanilla or not config.sandyVFX.enabled then return end
	local player = Game.GetPlayer()
	if player == nil then return end
	if Game.GetMountedVehicle(player) ~= nil then return end
	local band = sandyGradBand(player)
	if band == nil then return end
	GameObjectEffectHelper.StartEffectEvent(player, CName.new(band), true)
end

local function removeSandyGrad()
	local player = Game.GetPlayer()
	if player == nil then return end
	for _, g in pairs(sandyGradEffects) do
		GameObjectEffectHelper.BreakEffectLoopEvent(player, CName.new(g.name))
	end
end

registerForEvent("onInit", function()

	print("[TDO] Time Dilation Overhaul " .. TDO_VERSION .. " loaded")
	print("[TDO] Enemy Sandevistan Rework " .. ESR_VERSION .. " loaded")
	Localizer.LoadLanguage()
	TDOAbilityData = require("data/abilityData.lua")

	if Game.GetPlayer() then
		isLoaded = Game.GetPlayer():IsAttached() and not Game.GetSystemRequestsHandler():IsPreGame()
	end
	local nuiSandyParams = require("config/nUIParams.lua")

	local hardCodedMods = require("config/externalMods.lua") or {}
	for i, v in pairs(hardCodedMods) do
		ExternalMods[i] = v
	end

	
	sandys:DeleteStoredAbilityData()

	for productLine, firstFlat in ipairs(sandyData) do
		sandys:AddExistingProductLine(productLine, firstFlat, TDOAbilityData, AbilityDefs)
	end
	sandys.names[1] = Game.GetLocalizedTextByKey(CName.new("Item-TDO-C1Shrike-Name"))
	sandys.names[2] = Game.GetLocalizedTextByKey(CName.new("Item-TDO-C2Tanto-Name"))
	sandys.names[4] = Game.GetLocalizedTextByKey(CName.new("Item-TDO-Falcon-Name"))

	nativeSettings = GetMod("nativeSettings")
	if nativeSettings ~= nil then
		config = loadSettings()

		local oldVersion = config.configVersion or 0

		if config.configVersion ~= default.configVersion then
			print("[TDO] INFO: Updating existing config json to current config version.")
			local tempConfig = require("config/userConfig.lua")
			config = configUpdate(config, tempConfig)
			print("[TDO] INFO: Config json successfully converted to current config version.")
			saveSettings(config)
		else
			local tempConfig = require("config/userConfig.lua")
			local messedUpConfig = false
			messedUpConfig, config = configValidate(config, tempConfig)
			if messedUpConfig == true then
				saveSettings(config)
			end
		end

		
		local migrationManifest = require("config/migrationManifest.lua")
		local manifestApplied = false
		for _, entry in ipairs(migrationManifest) do
			if oldVersion < entry.version then
				local tempConfig = require("config/userConfig.lua")
				for _, keyPath in ipairs(entry.resetKeys) do
					local parts = {}
					for part in string.gmatch(keyPath, "[^.]+") do
						table.insert(parts, part)
					end
					local sourceVal = tempConfig
					for _, p in ipairs(parts) do
						if type(sourceVal) ~= "table" then sourceVal = nil; break end
						sourceVal = sourceVal[p]
					end
					if sourceVal ~= nil then
						local node = config
						for i = 1, #parts - 1 do
							if type(node[parts[i]]) ~= "table" then node = nil; break end
							node = node[parts[i]]
						end
						if node ~= nil then
							node[parts[#parts]] = sourceVal
							manifestApplied = true
							print("[TDO] INFO: Migration v" .. tostring(entry.version) .. " reset key: " .. keyPath)
						end
					end
				end
			end
		end
		if manifestApplied then
			saveSettings(config)
		end

		
		local skipLines = {}
		if config.warpDancer.enabled == false then skipLines[3] = true end -- 3 = C3 WarpDancer (sandyData[3])
		if config.zetatech.enabled == false then skipLines[1] = true end -- 1 = C1 Shrike (sandyData[1])
		if config.tanto.enabled == false then skipLines[2] = true end -- 2 = C2 Tanto (sandyData[2])
		if config.apogee.enabled == false then skipLines[5] = true end -- 5 = C5 Apogee (sandyData[5])
		if config.falcon.enabled == false then skipLines[4] = true end -- 4 = C4 Falcon (sandyData[4])
		sandys:ProcessAllAbilities(config, skipLines)
		sandys:SaveAllAbilityData()

		local nuiTxt = Localizer.GetTextWithKeys("nui", nil, nil, nil)

		nativeSettings.addTab("/tdo", "TDO", function()
			saveSettings(config)
			local queueSkip = {}
			if config.warpDancer.enabled == false then queueSkip[3] = true end -- 3 = C3 WarpDancer
			if config.zetatech.enabled == false then queueSkip[1] = true end -- 1 = C1 Shrike
			if config.tanto.enabled == false then queueSkip[2] = true end -- 2 = C2 Tanto
			if config.apogee.enabled == false then queueSkip[5] = true end -- 5 = C5 Apogee
			if config.falcon.enabled == false then queueSkip[4] = true end -- 4 = C4 Falcon
			sandys:ProcessUpdateQueue(config, queueSkip)
		end)

		nativeSettings.addSubcategory("/tdo/note", nuiTxt["reloadWarning"])

		
		local cat = "DOT"
		nativeSettings.addSubcategory("/tdo/DOT", nuiTxt[cat]["header"])

		nativeSettings.addSwitch("/tdo/DOT", nuiTxt[cat]["enabled"]["opt"], nuiTxt[cat]["enabled"]["des"], config.dot.enabled, default.dot.enabled, function(state)
			config.dot.enabled = state
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["baseRatePct"]["opt"]..nuiTxt[cat]["baseRatePct"]["optUnit"], nuiTxt[cat]["baseRatePct"]["des"], 0.0, 10.0, 0.1, "%.1f", config.dot.baseRatePct, default.dot.baseRatePct, function(value)
			config.dot.baseRatePct = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["slowThresholdPct"]["opt"]..nuiTxt[cat]["slowThresholdPct"]["optUnit"], nuiTxt[cat]["slowThresholdPct"]["des"], 0.0, 100.0, 1.0, "%.0f", config.dot.slowThresholdPct, default.dot.slowThresholdPct, function(value)
			config.dot.slowThresholdPct = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["slowRangeMinPct"]["opt"]..nuiTxt[cat]["slowRangeMinPct"]["optUnit"], nuiTxt[cat]["slowRangeMinPct"]["des"], 0.0, 100.0, 1.0, "%.0f", config.dot.slowRangeMinPct, default.dot.slowRangeMinPct, function(value)
			config.dot.slowRangeMinPct = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["slowRangeMaxPct"]["opt"]..nuiTxt[cat]["slowRangeMaxPct"]["optUnit"], nuiTxt[cat]["slowRangeMaxPct"]["des"], 0.0, 100.0, 1.0, "%.0f", config.dot.slowRangeMaxPct, default.dot.slowRangeMaxPct, function(value)
			config.dot.slowRangeMaxPct = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["tickMinInterval"]["opt"]..nuiTxt[cat]["tickMinInterval"]["optUnit"], nuiTxt[cat]["tickMinInterval"]["des"], 0.1, 3.0, 0.05, "%.2f", config.dot.tickMinInterval, default.dot.tickMinInterval, function(value)
			config.dot.tickMinInterval = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["tickMaxInterval"]["opt"]..nuiTxt[cat]["tickMaxInterval"]["optUnit"], nuiTxt[cat]["tickMaxInterval"]["des"], 0.1, 3.0, 0.05, "%.2f", config.dot.tickMaxInterval, default.dot.tickMaxInterval, function(value)
			config.dot.tickMaxInterval = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["mitigationCap"]["opt"]..nuiTxt[cat]["mitigationCap"]["optUnit"], nuiTxt[cat]["mitigationCap"]["des"], 0.0, 1.0, 0.05, "%.2f", config.dot.mitigationCap, default.dot.mitigationCap, function(value)
			config.dot.mitigationCap = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/DOT", nuiTxt[cat]["mitigationRefStatCap"]["opt"], nuiTxt[cat]["mitigationRefStatCap"]["des"], 1.0, 20.0, 1.0, "%.0f", config.dot.mitigationRefStatCap, default.dot.mitigationRefStatCap, function(value)
			config.dot.mitigationRefStatCap = value
			saveSettings(config)
		end)

		nativeSettings.addSwitch("/tdo/DOT", nuiTxt[cat]["canKill"]["opt"], nuiTxt[cat]["canKill"]["des"], config.dot.canKill, default.dot.canKill, function(state)
			config.dot.canKill = state
			saveSettings(config)
		end)

		Override("TDOConfig", "DOTEnabled;", function() return config.dot.enabled end)
		Override("TDOConfig", "DOTBaseRatePct;", function() return config.dot.baseRatePct end)
		Override("TDOConfig", "DOTSlowThresholdPct;", function() return config.dot.slowThresholdPct end)
		Override("TDOConfig", "DOTSlowRangeMinPct;", function() return config.dot.slowRangeMinPct end)
		Override("TDOConfig", "DOTSlowRangeMaxPct;", function() return config.dot.slowRangeMaxPct end)
		Override("TDOConfig", "DOTTickMinInterval;", function() return config.dot.tickMinInterval end)
		Override("TDOConfig", "DOTTickMaxInterval;", function() return config.dot.tickMaxInterval end)
		Override("TDOConfig", "DOTMitigationCap;", function() return config.dot.mitigationCap end)
		Override("TDOConfig", "DOTMitigationRefStatCap;", function() return config.dot.mitigationRefStatCap end)
		Override("TDOConfig", "DOTCanKill;", function() return config.dot.canKill end)


		cat = "sandyVFX"
		nativeSettings.addSubcategory("/tdo/sandyVFX", nuiTxt[cat]["header"])

		nativeSettings.addSwitch("/tdo/sandyVFX", nuiTxt[cat]["enabled"]["opt"], nuiTxt[cat]["enabled"]["des"], config.sandyVFX.enabled, default.sandyVFX.enabled, function(state)
			config.sandyVFX.enabled = state
			saveSettings(config)
		end)

		nativeSettings.addSwitch("/tdo/sandyVFX", nuiTxt[cat]["useVanilla"]["opt"], nuiTxt[cat]["useVanilla"]["des"], config.sandyVFX.useVanilla, default.sandyVFX.useVanilla, function(state)
			config.sandyVFX.useVanilla = state
			saveSettings(config)
			applySandyScreenEffect()
		end)

		Override("TDOConfig", "SandyVFXEnabled;", function() return config.sandyVFX.enabled end)
		Override("TDOConfig", "SandyVFXUseVanilla;", function() return config.sandyVFX.useVanilla end)

		cat = "scanning"
		nativeSettings.addSubcategory("/tdo/scanning", nuiTxt[cat]["header"])

		nativeSettings.addSwitch("/tdo/scanning", nuiTxt[cat]["enabled"]["opt"], nuiTxt[cat]["enabled"]["des"], config.scanning.enabled, default.scanning.enabled, function(state)
			config.scanning.enabled = state
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["strengthAtMinInt"]["opt"], nuiTxt[cat]["strengthAtMinInt"]["des"], 0.01, 1.0, 0.01, "%.2f", config.scanning.strengthAtMinInt, default.scanning.strengthAtMinInt, function(value)
			config.scanning.strengthAtMinInt = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["strengthAtMaxInt"]["opt"], nuiTxt[cat]["strengthAtMaxInt"]["des"], 0.01, 1.0, 0.01, "%.2f", config.scanning.strengthAtMaxInt, default.scanning.strengthAtMaxInt, function(value)
			config.scanning.strengthAtMaxInt = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["drainPerSec"]["opt"], nuiTxt[cat]["drainPerSec"]["des"], 0.01, 1.0, 0.01, "%.2f", config.scanning.drainPerSec, default.scanning.drainPerSec, function(value)
			config.scanning.drainPerSec = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["rechargePerSec"]["opt"], nuiTxt[cat]["rechargePerSec"]["des"], 0.01, 1.0, 0.01, "%.2f", config.scanning.rechargePerSec, default.scanning.rechargePerSec, function(value)
			config.scanning.rechargePerSec = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["intScaleMax"]["opt"], nuiTxt[cat]["intScaleMax"]["des"], 1.0, 5.0, 0.1, "%.1f", config.scanning.intScaleMax, default.scanning.intScaleMax, function(value)
			config.scanning.intScaleMax = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["barPosX"]["opt"]..nuiTxt[cat]["barPosX"]["optUnit"], nuiTxt[cat]["barPosX"]["des"], 0.0, 3840.0, 5.0, "%.0f", config.scanning.barPosX, default.scanning.barPosX, function(value)
			config.scanning.barPosX = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["barPosY"]["opt"]..nuiTxt[cat]["barPosY"]["optUnit"], nuiTxt[cat]["barPosY"]["des"], 0.0, 2160.0, 5.0, "%.0f", config.scanning.barPosY, default.scanning.barPosY, function(value)
			config.scanning.barPosY = value
			saveSettings(config)
		end)

		Override("TDOConfig", "ScanningEnabled;", function() return config.scanning.enabled end)
		Override("TDOConfig", "ScanningTickInterval;", function() return config.scanning.tickInterval end)
		Override("TDOConfig", "ScanningDrainPerSec;", function() return config.scanning.drainPerSec end)
		Override("TDOConfig", "ScanningRechargePerSec;", function() return config.scanning.rechargePerSec end)
		Override("TDOConfig", "ScanningStrengthAtMinInt;", function() return config.scanning.strengthAtMinInt end)
		Override("TDOConfig", "ScanningStrengthAtMaxInt;", function() return config.scanning.strengthAtMaxInt end)
		Override("TDOConfig", "ScanningBarWidth;", function() return config.scanning.barWidth end)
		Override("TDOConfig", "ScanningBarHeight;", function() return config.scanning.barHeight end)
		Override("TDOConfig", "ScanningBarPosX;", function() return config.scanning.barPosX end)
		Override("TDOConfig", "ScanningBarPosY;", function() return config.scanning.barPosY end)
		Override("TDOConfig", "ScanningIntScaleMax;", function() return config.scanning.intScaleMax end)

		cat = "vehicle"
		nativeSettings.addSubcategory("/tdo/vehicle", nuiTxt[cat]["header"])

		nativeSettings.addSwitch("/tdo/vehicle", nuiTxt[cat]["enabled"]["opt"], nuiTxt[cat]["enabled"]["des"], config.vehicle.enabled, default.vehicle.enabled, function(state)
			config.vehicle.enabled = state
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["worldScaleUncommon"]["opt"], nuiTxt[cat]["worldScaleUncommon"]["des"], 0.05, 1.0, 0.05, "%.2f", config.vehicle.worldScaleUncommon, default.vehicle.worldScaleUncommon, function(value)
			config.vehicle.worldScaleUncommon = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["worldScaleRare"]["opt"], nuiTxt[cat]["worldScaleRare"]["des"], 0.05, 1.0, 0.05, "%.2f", config.vehicle.worldScaleRare, default.vehicle.worldScaleRare, function(value)
			config.vehicle.worldScaleRare = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["worldScaleEpic"]["opt"], nuiTxt[cat]["worldScaleEpic"]["des"], 0.05, 1.0, 0.05, "%.2f", config.vehicle.worldScaleEpic, default.vehicle.worldScaleEpic, function(value)
			config.vehicle.worldScaleEpic = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["worldScaleLegendary"]["opt"], nuiTxt[cat]["worldScaleLegendary"]["des"], 0.05, 1.0, 0.05, "%.2f", config.vehicle.worldScaleLegendary, default.vehicle.worldScaleLegendary, function(value)
			config.vehicle.worldScaleLegendary = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["gripForce"]["opt"], nuiTxt[cat]["gripForce"]["des"], 0.0, 5.0, 0.05, "%.2f", config.vehicle.gripForce, default.vehicle.gripForce, function(value)
			config.vehicle.gripForce = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["damping"]["opt"], nuiTxt[cat]["damping"]["des"], 0.0, 3.0, 0.05, "%.2f", config.vehicle.damping, default.vehicle.damping, function(value)
			config.vehicle.damping = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["steerLead"]["opt"], nuiTxt[cat]["steerLead"]["des"], 0.0, 2.0, 0.05, "%.2f", config.vehicle.steerLead, default.vehicle.steerLead, function(value)
			config.vehicle.steerLead = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["slipThreshold"]["opt"], nuiTxt[cat]["slipThreshold"]["des"], 0.0, 4.0, 0.1, "%.1f", config.vehicle.slipThreshold, default.vehicle.slipThreshold, function(value)
			config.vehicle.slipThreshold = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["maxImpulse"]["opt"], nuiTxt[cat]["maxImpulse"]["des"], 1000.0, 40000.0, 500.0, "%.0f", config.vehicle.maxImpulse, default.vehicle.maxImpulse, function(value)
			config.vehicle.maxImpulse = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["downforce"]["opt"], nuiTxt[cat]["downforce"]["des"], 0.0, 1.0, 0.05, "%.2f", config.vehicle.downforce, default.vehicle.downforce, function(value)
			config.vehicle.downforce = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["bikeYaw"]["opt"], nuiTxt[cat]["bikeYaw"]["des"], 0.0, 10.0, 0.1, "%.1f", config.vehicle.bikeYaw, default.vehicle.bikeYaw, function(value)
			config.vehicle.bikeYaw = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["bikeGrip"]["opt"], nuiTxt[cat]["bikeGrip"]["des"], 0.0, 5.0, 0.05, "%.2f", config.vehicle.bikeGrip, default.vehicle.bikeGrip, function(value)
			config.vehicle.bikeGrip = value
			saveSettings(config)
		end)

		Override("TDOConfig", "HerbieEnabled;", function() return config.vehicle.enabled end)
		Override("TDOConfig", "HerbieTickInterval;", function() return config.vehicle.tickInterval end)
		Override("TDOConfig", "HerbieWorldScaleUncommon;", function() return config.vehicle.worldScaleUncommon end)
		Override("TDOConfig", "HerbieWorldScaleRare;", function() return config.vehicle.worldScaleRare end)
		Override("TDOConfig", "HerbieWorldScaleEpic;", function() return config.vehicle.worldScaleEpic end)
		Override("TDOConfig", "HerbieWorldScaleLegendary;", function() return config.vehicle.worldScaleLegendary end)
		Override("TDOConfig", "HerbieGripForce;", function() return config.vehicle.gripForce end)
		Override("TDOConfig", "HerbieDamping;", function() return config.vehicle.damping end)
		Override("TDOConfig", "HerbieSteerLead;", function() return config.vehicle.steerLead end)
		Override("TDOConfig", "HerbieSlipThreshold;", function() return config.vehicle.slipThreshold end)
		Override("TDOConfig", "HerbieMaxImpulse;", function() return config.vehicle.maxImpulse end)
		Override("TDOConfig", "HerbieDownforce;", function() return config.vehicle.downforce end)
		Override("TDOConfig", "HerbieBikeYaw;", function() return config.vehicle.bikeYaw end)
		Override("TDOConfig", "HerbieBikeGrip;", function() return config.vehicle.bikeGrip end)

		local mechanicCreators = {
			[1] = function(ns, p) return createShrikeMechanic(ns, p, nuiTxt, config, default) end,
			[2] = function(ns, p) return createTantoMechanic(ns, p, nuiTxt, config, default) end,
			[3] = function(ns, p) return createWarpDancerMechanic(ns, p, nuiTxt, config, default) end,
			[5] = function(ns, p) return createApogeeMechanic(ns, p, nuiTxt, config, default) end,
		}
		local enableCreators = {
			[1] = function(ns, p) ns.addSwitch(p, nuiTxt.zetatech.enabled.opt, nuiTxt.zetatech.enabled.des, config.zetatech.enabled, default.zetatech.enabled, function(state) config.zetatech.enabled = state saveSettings(config) end) end,
			[2] = function(ns, p) ns.addSwitch(p, nuiTxt.tanto.enabled.opt, nuiTxt.tanto.enabled.des, config.tanto.enabled, default.tanto.enabled, function(state) config.tanto.enabled = state saveSettings(config) end) end,
			[3] = function(ns, p) ns.addSwitch(p, nuiTxt.warpDancer.enabled.opt, nuiTxt.warpDancer.enabled.des, config.warpDancer.enabled, default.warpDancer.enabled, function(state) config.warpDancer.enabled = state saveSettings(config) end) end,
			[4] = function(ns, p) ns.addSwitch(p, nuiTxt.falcon.enabled.opt, nuiTxt.falcon.enabled.des, config.falcon.enabled, default.falcon.enabled, function(state) config.falcon.enabled = state saveSettings(config) end) end,
			[5] = function(ns, p) ns.addSwitch(p, nuiTxt.apogee.enabled.opt, nuiTxt.apogee.enabled.des, config.apogee.enabled, default.apogee.enabled, function(state) config.apogee.enabled = state saveSettings(config) end) end,
		}
		sandys:CreateNUIMenus(nativeSettings, nuiSandyParams, nuiTxt, config, default, options.sandys, mechanicCreators, enableCreators)

		
		createCustomSandyShowHideMenu(nativeSettings, "/tdo/fusillade", nuiTxt.fusillade.header, nuiTxt, config, "fusilladeShow", function(ns, p)
			return createFusilladeMechanic(ns, p, nuiTxt, config, default)
		end)

		Override("TDOConfig", "FusilladeAmmoRefillMaxChancePct;", function() return config.fusillade.ammoRefillMaxChancePct end)
		Override("TDOConfig", "FusilladeTimeScale;", function() return config.fusillade.timeScale end)
		Override("TDOConfig", "FusilladeDurationMin;", function() return config.fusillade.durationMin end)
		Override("TDOConfig", "FusilladeDurationMax;", function() return config.fusillade.durationMax end)
		Override("TDOConfig", "FusilladeCooldownMin;", function() return config.fusillade.cooldownMin end)
		Override("TDOConfig", "FusilladeCooldownMax;", function() return config.fusillade.cooldownMax end)
		Override("TDOConfig", "FusilladeFireRateMult;", function() return config.fusillade.fireRateMult end)
		Override("TDOConfig", "FusilladeRampStartMin;", function() return config.fusillade.rampStartMin end)
		Override("TDOConfig", "FusilladeRampStartMax;", function() return config.fusillade.rampStartMax end)
		Override("TDOConfig", "FusilladeRampStep;", function() return config.fusillade.rampStep end)
		Override("TDOConfig", "FusilladeRecoilAmount;", function() return config.fusillade.recoil end)

		
		createCustomSandyShowHideMenu(nativeSettings, "/tdo/juggernaut", nuiTxt.juggernaut.header, nuiTxt, config, "juggernautShow", function(ns, p)
			return createJuggernautMechanic(ns, p, nuiTxt, config, default)
		end)

		Override("TDOConfig", "JuggernautLockDurationMin;", function() return config.juggernaut.lockDurationMin end)
		Override("TDOConfig", "JuggernautLockDurationMax;", function() return config.juggernaut.lockDurationMax end)
		Override("TDOConfig", "JuggernautRadiusMin;", function() return config.juggernaut.radiusMin end)
		Override("TDOConfig", "JuggernautRadiusMax;", function() return config.juggernaut.radiusMax end)
		Override("TDOConfig", "JuggernautDamageMultMin;", function() return config.juggernaut.damageMultMin end)
		Override("TDOConfig", "JuggernautDamageMultMax;", function() return config.juggernaut.damageMultMax end)
		Override("TDOConfig", "JuggernautCooldownMin;", function() return config.juggernaut.cooldownMin end)
		Override("TDOConfig", "JuggernautCooldownMax;", function() return config.juggernaut.cooldownMax end)

		
		createCustomSandyShowHideMenu(nativeSettings, "/tdo/kurosawa", nuiTxt.kurosawa.header, nuiTxt, config, "kurosawaShow", function(ns, p)
			return createKurosawaMechanic(ns, p, nuiTxt, config, default)
		end)

		Override("TDOConfig", "KurosawaIndividualSlowMult;", function() return config.kurosawa.enemySlowMult end)
		Override("TDOConfig", "KurosawaDuration;", function() return config.kurosawa.duration end)
		Override("TDOConfig", "KurosawaRecharge;", function() return config.kurosawa.cooldown end)
		Override("TDOConfig", "KurosawaDamageReductionMin;", function() return config.kurosawa.drMin end)
		Override("TDOConfig", "KurosawaDamageReductionMax;", function() return config.kurosawa.drMax end)
		Override("TDOConfig", "KurosawaPOPHealPctBase;", function() return config.kurosawa.healMin end)
		Override("TDOConfig", "KurosawaPOPHealPctPlus;", function() return config.kurosawa.healMax end)

		
		createCustomSandyShowHideMenu(nativeSettings, "/tdo/pyrolith", nuiTxt.pyrolith.header, nuiTxt, config, "pyrolithShow", function(ns, p)
			return createPyrolithMechanic(ns, p, nuiTxt, config, default)
		end)

		Override("TDOConfig", "PyrolithDurationMin;", function() return config.pyrolith.durationMin end)
		Override("TDOConfig", "PyrolithDurationMax;", function() return config.pyrolith.durationMax end)
		Override("TDOConfig", "PyrolithExplosionDamageMin;", function() return config.pyrolith.explosionDamageMin end)
		Override("TDOConfig", "PyrolithExplosionDamageMax;", function() return config.pyrolith.explosionDamageMax end)
		Override("TDOConfig", "PyrolithClusterCountMin;", function() return config.pyrolith.clusterCountMin end)
		Override("TDOConfig", "PyrolithClusterCountMax;", function() return config.pyrolith.clusterCountMax end)
		Override("TDOConfig", "PyrolithCooldownMin;", function() return config.pyrolith.cooldownMin end)
		Override("TDOConfig", "PyrolithCooldownMax;", function() return config.pyrolith.cooldownMax end)

		createCustomSandyShowHideMenu(nativeSettings, "/tdo/quantum", nuiTxt.quantum.header, nuiTxt, config, "quantumShow", function(ns, p)
			return createQuantumMechanic(ns, p, nuiTxt, config, default)
		end)

		Override("TDOConfig", "QuantumMaxCharges;", function() return config.quantum.maxCharges end)
		Override("TDOConfig", "QuantumPlotFreezeStrength;", function() return config.quantum.plotFreezeStrength end)
		Override("TDOConfig", "QuantumDurationMin;", function() return config.quantum.durationMin end)
		Override("TDOConfig", "QuantumDurationMax;", function() return config.quantum.durationMax end)
		Override("TDOConfig", "QuantumCooldownMin;", function() return config.quantum.cooldownMin end)
		Override("TDOConfig", "QuantumCooldownMax;", function() return config.quantum.cooldownMax end)
		Override("TDOConfig", "QuantumTeleportRangeMin;", function() return config.quantum.teleportRangeMin end)
		Override("TDOConfig", "QuantumTeleportRangeMax;", function() return config.quantum.teleportRangeMax end)
		Override("TDOConfig", "QuantumMalwareTargetsMin;", function() return config.quantum.malwareTargetsMin end)
		Override("TDOConfig", "QuantumMalwareTargetsMax;", function() return config.quantum.malwareTargetsMax end)
		Override("TDOConfig", "QuantumMalwareFreezeDurMin;", function() return config.quantum.malwareFreezeDurMin end)
		Override("TDOConfig", "QuantumMalwareFreezeDurMax;", function() return config.quantum.malwareFreezeDurMax end)

		createCustomSandyShowHideMenu(nativeSettings, "/tdo/sogimsu", nuiTxt.sogimsu.header, nuiTxt, config, "sogimsuShow", function(ns, p)
			return createSogimsuMechanic(ns, p, nuiTxt, config, default)
		end)

		Override("TDOConfig", "SogimsuDurationMin;", function() return config.sogimsu.durationMin end)
		Override("TDOConfig", "SogimsuDurationMax;", function() return config.sogimsu.durationMax end)
		Override("TDOConfig", "SogimsuCooldownMin;", function() return config.sogimsu.cooldownMin end)
		Override("TDOConfig", "SogimsuCooldownMax;", function() return config.sogimsu.cooldownMax end)
		Override("TDOConfig", "SogimsuInterventionsMin;", function() return config.sogimsu.interventionsMin end)
		Override("TDOConfig", "SogimsuInterventionsMax;", function() return config.sogimsu.interventionsMax end)
		Override("TDOConfig", "SogimsuDetectionDecreaseMin;", function() return config.sogimsu.detSpeedMin end)
		Override("TDOConfig", "SogimsuDetectionDecreaseMax;", function() return config.sogimsu.detSpeedMax end)
		Override("TDOConfig", "SogimsuStealthHitDamageMin;", function() return config.sogimsu.stealthDmgMin end)
		Override("TDOConfig", "SogimsuStealthHitDamageMax;", function() return config.sogimsu.stealthDmgMax end)

		Override("TDOConfig", "TantoEnabled;", function() return config.tanto.enabled end)
		Override("TDOConfig", "TantoTeleportBaseRange;", function() return config.tanto.teleportBaseRange end)
		Override("TDOConfig", "TantoTeleportMaxRange;", function() return config.tanto.teleportMaxRange end)

		Override("TDOConfig", "ShrikeEnabled;", function() return config.zetatech.enabled end)
		Override("TDOConfig", "ShrikeMarkRange;", function() return config.zetatech.markRange end)
		Override("TDOConfig", "ShrikeExecuteDmgTrash;", function() return config.zetatech.executeDmgTrash end)
		Override("TDOConfig", "ShrikeExecuteDmgWeak;", function() return config.zetatech.executeDmgWeak end)
		Override("TDOConfig", "ShrikeExecuteDmgNormal;", function() return config.zetatech.executeDmgNormal end)
		Override("TDOConfig", "ShrikeExecuteDmgRare;", function() return config.zetatech.executeDmgRare end)
		Override("TDOConfig", "ShrikeExecuteDmgOfficer;", function() return config.zetatech.executeDmgOfficer end)
		Override("TDOConfig", "ShrikeExecuteDmgElite;", function() return config.zetatech.executeDmgElite end)
		Override("TDOConfig", "ShrikeExecuteDmgMaxTac;", function() return config.zetatech.executeDmgMaxTac end)
		Override("TDOConfig", "ShrikeExecuteDmgBoss;", function() return config.zetatech.executeDmgBoss end)

		Override("TDOConfig", "FalconEnabled;", function() return config.falcon.enabled end)
		Override("TDOConfig", "FalconPhaseRoundEnabled;", function() return config.falcon.enabled end)
		Override("TDOConfig", "FalconTrickShotEnabled;", function() return config.falcon.enabled end)
		Override("TDOConfig", "FalconTrickShotBlockReload;", function() return config.falcon.enabled end)
		Override("TDOConfig", "FalconSaturationLockEnabled;", function() return config.falcon.enabled end)

		Override("TDOConfig", "WarpDancerEnabled;", function() return config.warpDancer.enabled end)
		Override("TDOConfig", "WarpDancerRewindDurationSec;", function() return config.warpDancer.rewindDurationSec end)
		Override("TDOConfig", "WarpDancerStaggerDurationMinSec;", function() return config.warpDancer.staggerDurationMinSec end)
		Override("TDOConfig", "WarpDancerStaggerDurationMaxSec;", function() return config.warpDancer.staggerDurationMaxSec end)

		Override("TDOConfig", "ApogeeEnabled;", function() return config.apogee.enabled end)
		Override("TDOConfig", "ApogeeStrainMultiplierCap;", function() return config.apogee.strainMultiplierCap end)

		if config.warpDancer.enabled then
			local warpDancerTierSuffixes = {"MK3", "MK3Plus", "MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}
			local sMin = config.warpDancer.staggerDurationMinSec
			local sMax = config.warpDancer.staggerDurationMaxSec
			for i, suffix in ipairs(warpDancerTierSuffixes) do
				local t = (i - 1) / 6.0
				local staggerSec = sMax - (sMax - sMin) * t
				TweakDB:SetFlat("StatusEffects.TDO_WarpDancerStagger_" .. suffix .. "_DurMod.value", staggerSec)
			end
			local warpDancerActivationInline = { MK3 = 8, MK3Plus = 8, MK4 = 8, MK4Plus = 8, MK5 = 1, MK5Plus = 1, MK5PlusPlus = 1 }
			local msMin = config.warpDancer.moveSpeedMin
			local msMax = config.warpDancer.moveSpeedMax
			for i, suffix in ipairs(warpDancerTierSuffixes) do
				local t = (i - 1) / 6.0
				local msPct = msMin + (msMax - msMin) * t
				TweakDB:SetFlat("StatusEffects.TDO_WarpDancerMoveSpeed_" .. suffix .. "_Mod.value", 1.0 + msPct / 100.0)
				local stgSec = sMax - (sMax - sMin) * t
				local inlineNum = warpDancerActivationInline[suffix]
				local floatPath = "Items.AdvancedSandevistanC3" .. suffix .. "_inline" .. tostring(inlineNum) .. ".floatValues"
				local floats = TweakDB:GetFlat(floatPath)
				if type(floats) == "table" then
					while #floats < 7 do table.insert(floats, 0.0) end
					floats[6] = msPct
					floats[7] = stgSec
					TweakDB:SetFlat(floatPath, floats)
				end
			end
			local warpDancerOnEquipRemove = { MK3 = 9, MK3Plus = 9, MK4 = 9, MK4Plus = 9, MK5 = 2, MK5Plus = 2, MK5PlusPlus = 2 }
			local warpDancerStatStrip = { MK3 = 14, MK3Plus = 14, MK4 = 14, MK4Plus = 14, MK5 = 7, MK5Plus = 7, MK5PlusPlus = 7 }
			local wdLocActive = TweakDB:GetFlat("Attunements.TDO_WarpDancerLoc.localizedDescription")
			if wdLocActive ~= nil then wdLocActive = tostring(wdLocActive) end
			for i, suffix in ipairs(warpDancerTierSuffixes) do
				local itemPath = "Items.AdvancedSandevistanC3" .. suffix
				TweakDB:SetFlat(itemPath .. ".displayName", LocKey("Item-TDO-WarpDancer-Name"))
				TweakDB:SetFlat(itemPath .. ".localizedDescription", LocKey("Item-TDO-WarpDancer-Flavor"))
				removeFlatsFromFlatArr(itemPath .. ".OnEquip", { itemPath .. "_inline" .. tostring(warpDancerOnEquipRemove[suffix]), "Attunements.ReflexesSandyProlong" })
				addFlatsToFlatArr(itemPath .. ".OnEquip", { "Attunements.TDO_WarpDancer" })
				if wdLocActive ~= nil then TweakDB:SetFlat(itemPath .. "_inline" .. tostring(warpDancerActivationInline[suffix]) .. ".localizedDescription", wdLocActive) end
				TweakDB:SetFlat(itemPath .. "_inline" .. tostring(warpDancerStatStrip[suffix]) .. ".statModifiers", {})
			end
		end
		if config.zetatech.enabled then
			local shrikeTierSuffixes = {"MK1", "MK1Plus", "MK2", "MK2Plus", "MK3", "MK3Plus", "MK4", "MK4Plus", "MK4PlusPlus"}
			local shrikeRemove1 = { MK1 = 10, MK1Plus = 10, MK2 = 4, MK2Plus = 4, MK3 = 4, MK3Plus = 4, MK4 = 4, MK4Plus = 4, MK4PlusPlus = 4 }
			local shrikeRemove2 = { MK1 = 8, MK1Plus = 8, MK2 = 2, MK2Plus = 2, MK3 = 2, MK3Plus = 2, MK4 = 2, MK4Plus = 2, MK4PlusPlus = 2 }
			local shrikeActiveDesc = { MK1 = 7, MK1Plus = 7, MK2 = 1, MK2Plus = 1, MK3 = 1, MK3Plus = 1, MK4 = 1, MK4Plus = 1, MK4PlusPlus = 1 }
			local shrikeEffectorParent = { MK1 = 18, MK1Plus = 18, MK2 = 12, MK2Plus = 12, MK3 = 12, MK3Plus = 12, MK4 = 12, MK4Plus = 12, MK4PlusPlus = 12 }
			local shrikeEffectorRemove = { MK1 = 26, MK1Plus = 26, MK2 = 20, MK2Plus = 20, MK3 = 20, MK3Plus = 20, MK4 = 20, MK4Plus = 20, MK4PlusPlus = 20 }
			local shrikeValueZero = { MK1 = 23, MK1Plus = 23, MK2 = 17, MK2Plus = 17, MK3 = 17, MK3Plus = 17, MK4 = 17, MK4Plus = 17, MK4PlusPlus = 17 }
			local szLocActive = TweakDB:GetFlat("Attunements.TDO_ShrikeLoc.localizedDescription")
			if szLocActive ~= nil then szLocActive = tostring(szLocActive) end
			for i, suffix in ipairs(shrikeTierSuffixes) do
				local itemPath = "Items.AdvancedSandevistanC1" .. suffix
				TweakDB:SetFlat(itemPath .. ".displayName", LocKey("Item-TDO-C1Shrike-Name"))
				TweakDB:SetFlat(itemPath .. ".localizedDescription", LocKey("Item-TDO-C1Shrike-Flavor"))
				removeFlatsFromFlatArr(itemPath .. ".OnEquip", { itemPath .. "_inline" .. tostring(shrikeRemove1[suffix]), itemPath .. "_inline" .. tostring(shrikeRemove2[suffix]), "Attunements.ReflexesSandyProlong" })
				addFlatsToFlatArr(itemPath .. ".OnEquip", { "Attunements.TDO_Shrike" })
				if szLocActive ~= nil then TweakDB:SetFlat(itemPath .. "_inline" .. tostring(shrikeActiveDesc[suffix]) .. ".localizedDescription", szLocActive) end
				removeFlatsFromFlatArr(itemPath .. "_inline" .. tostring(shrikeEffectorParent[suffix]) .. ".effectors", { itemPath .. "_inline" .. tostring(shrikeEffectorRemove[suffix]) })
				TweakDB:SetFlat(itemPath .. "_inline" .. tostring(shrikeValueZero[suffix]) .. ".value", 0.0)
			end
		end
		if config.tanto.enabled then
			local tantoTierSuffixes = {"MK1", "MK1Plus", "MK2", "MK2Plus", "MK3", "MK3Plus", "MK4", "MK4Plus", "MK4PlusPlus"}
			local tantoOnEquipRemove = { MK1 = 8, MK1Plus = 8, MK2 = 2, MK2Plus = 2, MK3 = 2, MK3Plus = 2, MK4 = 2, MK4Plus = 2, MK4PlusPlus = 2 }
			local tantoActiveDesc = { MK1 = 7, MK1Plus = 7, MK2 = 1, MK2Plus = 1, MK3 = 1, MK3Plus = 1, MK4 = 1, MK4Plus = 1, MK4PlusPlus = 1 }
			local tzLocActive = TweakDB:GetFlat("Attunements.TDO_TantoLoc.localizedDescription")
			if tzLocActive ~= nil then tzLocActive = tostring(tzLocActive) end
			for i, suffix in ipairs(tantoTierSuffixes) do
				local itemPath = "Items.AdvancedSandevistanC2" .. suffix
				TweakDB:SetFlat(itemPath .. ".displayName", LocKey("Item-TDO-C2Tanto-Name"))
				TweakDB:SetFlat(itemPath .. ".localizedDescription", LocKey("Item-TDO-C2Tanto-Flavor"))
				removeFlatsFromFlatArr(itemPath .. ".OnEquip", { itemPath .. "_inline" .. tostring(tantoOnEquipRemove[suffix]), "Attunements.ReflexesSandyProlong" })
				addFlatsToFlatArr(itemPath .. ".OnEquip", { "Attunements.TDO_Tanto" })
				if tzLocActive ~= nil then TweakDB:SetFlat(itemPath .. "_inline" .. tostring(tantoActiveDesc[suffix]) .. ".localizedDescription", tzLocActive) end
			end
		end
		if config.falcon.enabled then
			local falconTierSuffixes = {"MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}
			local falconRemove1 = { MK4 = 10, MK4Plus = 19, MK5 = 19, MK5Plus = 19, MK5PlusPlus = 19 }
			local falconRemove2 = { MK4 = 2, MK4Plus = 11, MK5 = 11, MK5Plus = 11, MK5PlusPlus = 11 }
			local falconActiveDesc = { MK4 = 1, MK4Plus = 10, MK5 = 10, MK5Plus = 10, MK5PlusPlus = 10 }
			local falconValueZeroA = { MK4 = 8, MK4Plus = 17, MK5 = 17, MK5Plus = 17, MK5PlusPlus = 17 }
			local falconValueZeroB = { MK4 = 9, MK4Plus = 18, MK5 = 18, MK5Plus = 18, MK5PlusPlus = 18 }
			local falconValueZeroC = { MK4 = 26, MK4Plus = 6, MK5 = 6, MK5Plus = 6, MK5PlusPlus = 6 }
			local falconStatPoolClear = { MK4 = 17, MK4Plus = 26, MK5 = 26, MK5Plus = 26, MK5PlusPlus = 26 }
			local fzLocActive = TweakDB:GetFlat("Attunements.TDO_FalconLoc.localizedDescription")
			if fzLocActive ~= nil then fzLocActive = tostring(fzLocActive) end
			for i, suffix in ipairs(falconTierSuffixes) do
				local itemPath = "Items.AdvancedSandevistanC4" .. suffix
				TweakDB:SetFlat(itemPath .. ".displayName", LocKey("Item-TDO-Falcon-Name"))
				TweakDB:SetFlat(itemPath .. ".localizedDescription", LocKey("Item-TDO-Falcon-Flavor"))
				removeFlatsFromFlatArr(itemPath .. ".OnEquip", { itemPath .. "_inline" .. tostring(falconRemove1[suffix]), itemPath .. "_inline" .. tostring(falconRemove2[suffix]), "Attunements.ReflexesSandyProlong" })
				addFlatsToFlatArr(itemPath .. ".OnEquip", { "Attunements.TDO_Falcon", "Items.TDO_Falcon_WeaponBonus_Package" })
				if fzLocActive ~= nil then TweakDB:SetFlat(itemPath .. "_inline" .. tostring(falconActiveDesc[suffix]) .. ".localizedDescription", fzLocActive) end
				TweakDB:SetFlat(itemPath .. "_inline" .. tostring(falconValueZeroA[suffix]) .. ".value", 0.0)
				TweakDB:SetFlat(itemPath .. "_inline" .. tostring(falconValueZeroB[suffix]) .. ".value", 0.0)
				TweakDB:SetFlat(itemPath .. "_inline" .. tostring(falconValueZeroC[suffix]) .. ".value", 0.0)
				TweakDB:SetFlat(itemPath .. "_inline" .. tostring(falconStatPoolClear[suffix]) .. ".statPoolUpdates", {})
			end
		end
			nativeSettings.addSubcategory("/tdo/esrGeneral", "ESR - General")
			nativeSettings.addSwitch("/tdo/esrGeneral", "Enabled", "Master toggle for Enemy Sandevistan Rework. When disabled, enemy Sandevistan/Kerenzikov reverts to vanilla. Toggling needs a save reload.", config.esr.enabled, default.esr.enabled, function(state) config.esr.enabled = state saveSettings(config) end)
			nativeSettings.addSwitch("/tdo/esrGeneral", "Rebalance Original Abilities", "Will rebalance, which enemies use which Tier of Sandevistan / Kerenzikov.", config.esr.replaceOGAbilities, default.esr.replaceOGAbilities, function(state) config.esr.replaceOGAbilities = state saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrGeneral", "[AI Cheat] - Minimum Strength", "Minimum Strength of NPC sandevistan, when player Sandevistan is stronger than enemy's. So enemies don't feel useless vs a Sandevistan player.", 0.0, 1.0, 0.1, "%.1f", config.esr.enemyMinimumSvS, default.esr.enemyMinimumSvS, function(value) config.esr.enemyMinimumSvS = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrGeneral", "[Player Cheat] - Minimum Strength", "Minimum Strength so the player can still use their Sandevistan vs enemies when AI Sandevistan is stronger.", 0.0, 1.0, 0.1, "%.1f", config.esr.playerMinimumSvS, default.esr.playerMinimumSvS, function(value) config.esr.playerMinimumSvS = value saveSettings(config) end)
			nativeSettings.addRangeInt("/tdo/esrGeneral", "Offensive Usage - Cooldown", "How long the AI waits before using Sandevistan or Kerenzikov offensively again (mainly melee, pistols, shotguns).", 1, 30, 1, config.esr.offensiveUseCD, default.esr.offensiveUseCD, function(value) config.esr.offensiveUseCD = value saveSettings(config) end)
			nativeSettings.addRangeInt("/tdo/esrGeneral", "Defensive Usage - Cooldown", "How long the AI waits before using Sandevistan defensively again (vs melee attacks).", 1, 30, 1, config.esr.defensiveUseCD, default.esr.defensiveUseCD, function(value) config.esr.defensiveUseCD = value saveSettings(config) end)

			nativeSettings.addSubcategory("/tdo/esrKerenzikov", "ESR - Kerenzikov Enemies")
			nativeSettings.addRangeFloat("/tdo/esrKerenzikov", "Time Dilation Strength", "Slows down time, for affected enemy, by x%.", 1.0, 99.0, 1.0, "%.0f", config.esr.kerenzikovStrength, default.esr.kerenzikovStrength, function(value) config.esr.kerenzikovStrength = value saveSettings(config) end)
			nativeSettings.addSwitch("/tdo/esrKerenzikov", "Kerenzikov vs Sandevistan", "If true, kerenzikov enemies always match player speed when activating against a Sandevistan player.", config.esr.kerenzikovMatching, default.esr.kerenzikovMatching, function(state) config.esr.kerenzikovMatching = state saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrKerenzikov", "Time Dilation Duration", "Maximum duration in seconds. Acts like their charge (duration uses enemy time speed).", 1.0, 10.0, 1.0, "%.0f", config.esr.kerenzikovDuration, default.esr.kerenzikovDuration, function(value) config.esr.kerenzikovDuration = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrKerenzikov", "Time Dilation Cooldown", "Cooldown in seconds. How long it takes to fully recharge.", 1.0, 60.0, 1.0, "%.0f", config.esr.kerenzikovCD, default.esr.kerenzikovCD, function(value) config.esr.kerenzikovCD = value saveSettings(config) end)

			nativeSettings.addSubcategory("/tdo/esrMk1", "ESR - Sandevistan MK1 Enemies")
			nativeSettings.addRangeFloat("/tdo/esrMk1", "Time Dilation Strength", "Slows down time, for affected enemy, by x%.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk1Strength, default.esr.mk1Strength, function(value) config.esr.mk1Strength = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk1", "Time Dilation Duration", "Maximum duration in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk1Duration, default.esr.mk1Duration, function(value) config.esr.mk1Duration = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk1", "Time Dilation Cooldown", "Cooldown in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk1CD, default.esr.mk1CD, function(value) config.esr.mk1CD = value saveSettings(config) end)

			nativeSettings.addSubcategory("/tdo/esrMk2", "ESR - Sandevistan MK2 Enemies")
			nativeSettings.addRangeFloat("/tdo/esrMk2", "Time Dilation Strength", "Slows down time, for affected enemy, by x%.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk2Strength, default.esr.mk2Strength, function(value) config.esr.mk2Strength = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk2", "Time Dilation Duration", "Maximum duration in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk2Duration, default.esr.mk2Duration, function(value) config.esr.mk2Duration = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk2", "Time Dilation Cooldown", "Cooldown in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk2CD, default.esr.mk2CD, function(value) config.esr.mk2CD = value saveSettings(config) end)

			nativeSettings.addSubcategory("/tdo/esrMk3", "ESR - Sandevistan MK3 Enemies")
			nativeSettings.addRangeFloat("/tdo/esrMk3", "Time Dilation Strength", "Slows down time, for affected enemy, by x%.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk3Strength, default.esr.mk3Strength, function(value) config.esr.mk3Strength = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk3", "Time Dilation Duration", "Maximum duration in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk3Duration, default.esr.mk3Duration, function(value) config.esr.mk3Duration = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk3", "Time Dilation Cooldown", "Cooldown in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk3CD, default.esr.mk3CD, function(value) config.esr.mk3CD = value saveSettings(config) end)

			nativeSettings.addSubcategory("/tdo/esrMk4", "ESR - Sandevistan MK4 Enemies")
			nativeSettings.addRangeFloat("/tdo/esrMk4", "Time Dilation Strength", "Slows down time, for affected enemy, by x%.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk4Strength, default.esr.mk4Strength, function(value) config.esr.mk4Strength = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk4", "Time Dilation Duration", "Maximum duration in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk4Duration, default.esr.mk4Duration, function(value) config.esr.mk4Duration = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk4", "Time Dilation Cooldown", "Cooldown in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk4CD, default.esr.mk4CD, function(value) config.esr.mk4CD = value saveSettings(config) end)

			nativeSettings.addSubcategory("/tdo/esrMk5", "ESR - Sandevistan MK5 Enemies")
			nativeSettings.addRangeFloat("/tdo/esrMk5", "Time Dilation Strength", "Slows down time, for affected enemy, by x%.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk5Strength, default.esr.mk5Strength, function(value) config.esr.mk5Strength = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk5", "Time Dilation Duration", "Maximum duration in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk5Duration, default.esr.mk5Duration, function(value) config.esr.mk5Duration = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrMk5", "Time Dilation Cooldown", "Cooldown in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.mk5CD, default.esr.mk5CD, function(value) config.esr.mk5CD = value saveSettings(config) end)

			nativeSettings.addSubcategory("/tdo/esrStimPack", "ESR - Stim Pack")
			nativeSettings.addSwitch("/tdo/esrStimPack", "Enable", "Adds a Stim Pack ability to some enemies: sacrifice health for a short time dilation / accuracy buff.", config.esr.enableStimPack, default.esr.enableStimPack, function(state) config.esr.enableStimPack = state saveSettings(config) end)
			nativeSettings.addSwitch("/tdo/esrStimPack", "Custom Sound", "Plays a custom sound effect when enabled.", config.esr.enableStimPackCustomSound, default.esr.enableStimPackCustomSound, function(state) config.esr.enableStimPackCustomSound = state saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrStimPack", "Time Dilation Strength", "Slows down time, for affected enemy, by x%.", 1.0, 99.0, 1.0, "%.0f", config.esr.stimPackStrength, default.esr.stimPackStrength, function(value) config.esr.stimPackStrength = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrStimPack", "Time Dilation Duration", "Maximum duration in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.stimPackDuration, default.esr.stimPackDuration, function(value) config.esr.stimPackDuration = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrStimPack", "Time Dilation Cooldown", "Cooldown in seconds.", 1.0, 99.0, 1.0, "%.0f", config.esr.stimPackCooldown, default.esr.stimPackCooldown, function(value) config.esr.stimPackCooldown = value saveSettings(config) end)
			nativeSettings.addRangeFloat("/tdo/esrStimPack", "Health Cost", "How much HP the enemy pays per activation. They won't use it if it would bring HP under 50%.", 1.0, 50.0, 1.0, "%.0f", config.esr.stimPackHealthCost, default.esr.stimPackHealthCost, function(value) config.esr.stimPackHealthCost = value saveSettings(config) end)

			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Enabled;", function() return config.esr.enabled end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "ReplaceOGAbilities;", function() return config.esr.replaceOGAbilities end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "EnemyMinimumSvS;", function() return config.esr.enemyMinimumSvS end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "PlayerMinimumSvS;", function() return config.esr.playerMinimumSvS end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "OffensiveUseCD;", function() return config.esr.offensiveUseCD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "DefensiveUseCD;", function() return config.esr.defensiveUseCD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "KerenzikovStrength;", function() return config.esr.kerenzikovStrength end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "KerenzikovMatching;", function() return config.esr.kerenzikovMatching end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "KerenzikovDuration;", function() return config.esr.kerenzikovDuration end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "KerenzikovCD;", function() return config.esr.kerenzikovCD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk1Strength;", function() return config.esr.mk1Strength end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk1Duration;", function() return config.esr.mk1Duration end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk1CD;", function() return config.esr.mk1CD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk2Strength;", function() return config.esr.mk2Strength end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk2Duration;", function() return config.esr.mk2Duration end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk2CD;", function() return config.esr.mk2CD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk3Strength;", function() return config.esr.mk3Strength end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk3Duration;", function() return config.esr.mk3Duration end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk3CD;", function() return config.esr.mk3CD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk4Strength;", function() return config.esr.mk4Strength end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk4Duration;", function() return config.esr.mk4Duration end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk4CD;", function() return config.esr.mk4CD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk5Strength;", function() return config.esr.mk5Strength end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk5Duration;", function() return config.esr.mk5Duration end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "Mk5CD;", function() return config.esr.mk5CD end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "EnableStimPack;", function() return config.esr.enableStimPack end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "EnableStimPackCustomSound;", function() return config.esr.enableStimPackCustomSound end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "StimPackStrength;", function() return config.esr.stimPackStrength end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "StimPackDuration;", function() return config.esr.stimPackDuration end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "StimPackCooldown;", function() return config.esr.stimPackCooldown end)
			Override("Phoenicia.EnemySandevistanRework.Configurations.ESRConfig", "StimPackHealthCost;", function() return config.esr.stimPackHealthCost end)

		cat = "debug"
		nativeSettings.addSubcategory("/tdo/debug", nuiTxt[cat]["header"])

		nativeSettings.addSwitch("/tdo/debug", nuiTxt[cat]["enableDebugLog"]["opt"], nuiTxt[cat]["enableDebugLog"]["des"], config.debug.enableDebugLog, default.debug.enableDebugLog, function(state)
			config.debug.enableDebugLog = state
			saveSettings(config)
		end)

		nativeSettings.addSelectorString("/tdo/debug", nuiTxt[cat]["debugLogLevel"]["opt"], nuiTxt[cat]["debugLogLevel"]["des"], nuiTxt[cat]["debugLogLevel"]["sel"], config.debug.debugLogLevel + 1, default.debug.debugLogLevel + 1, function(value)
			config.debug.debugLogLevel = value - 1
			saveSettings(config)
		end)

		Override("TDOConfig", "EnableDebugLog;", function() return config.debug.enableDebugLog end)
		Override("TDOConfig", "DebugLogLevel;", function() return config.debug.debugLogLevel end)

	else
		config = require("config/userConfig.lua")
		print("[TDO] CAUTION: Native Settings Not Found")
	end

	local turnX = CName.new("TurnX")
	Observe("PlayerPuppet", "OnAction", function(this, action)
		if action == nil or this == nil then return end
		if action:GetName() ~= turnX then return end
		this:TDO_Herbie_SetSteer(action:GetValue())
	end)

	Observe("PlayerPuppet", "PlayerAttachedCallback", function(this)
		initSandyGradEffects(this)
	end)
	Observe("SandevistanEvents", "OnEnter", applySandyGrad)
	Observe("SandevistanEvents", "OnExit", removeSandyGrad)
	Observe("SandevistanEvents", "OnForcedExit", removeSandyGrad)

	applySandyScreenEffect()

	GameUI.OnSessionStart(function()
		isLoaded = true
	end)

	GameUI.OnSessionEnd(function()
		isLoaded = false
		collectgarbage("collect")
	end)

	Initialized = true

	if TweakDB:GetRecord("TDOInitialized") == nil then
		TweakDB:CreateRecord("TDOInitialized", "gamedataVendorItem_Record")
	end

	for _, v in pairs(ExternalMods) do
		if type(v) == "table" and v.TDOInitialized then
			v.TDOInitialized()
		end
	end

	print("[TDO] Initialized!")
end)

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

registerForEvent("onShutdown", function()
end)

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

return {
	TDODumpSandyStructure = TDODumpSandyStructure,
	TDOZetatechDebug = TDOZetatechDebug,
	TDODumpWeapon = TDODumpWeapon,
	TDODumpRecord = TDODumpRecord,
	TDODumpVanillaSandies = TDODumpVanillaSandies,
	TDODumpFullTweakDB = TDODumpFullTweakDB
}

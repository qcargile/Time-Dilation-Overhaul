Cron = require("CETKit/Cron.lua")
GameUI = require("modules/external/GameUI")
GameSettings = require('CETKit/GameSettings.lua')
Localizer = require("modules/localizedText.lua")
require("modules/commonFunctions.lua")
require("modules/tdoDebug.lua")

local config = {}
local default = require("config/nUIDefaults.lua")
local isLoaded = false
local Initialized = false
local ExternalMods = {}

local TDO_VERSION = "v2.3"
local ESR_VERSION = "d2026.6.11"

local function lerpTier(v1, vTop, tier, total)
	if total <= 1 then return v1 end
	return v1 + (vTop - v1) * (tier - 1) / (total - 1)
end

local SHRIKE_TIER_FLATS = {
	[1] = { item="Items.AdvancedSandevistanC1MK1",         dur="_inline1",  ts="_inline2",  rchrg="_inline3"  },
	[2] = { item="Items.AdvancedSandevistanC1MK1Plus",     dur="_inline1",  ts="_inline2",  rchrg="_inline3"  },
	[3] = { item="Items.AdvancedSandevistanC1MK2",         dur="_inline25", ts="_inline26", rchrg="_inline27" },
	[4] = { item="Items.AdvancedSandevistanC1MK2Plus",     dur="_inline25", ts="_inline26", rchrg="_inline27" },
	[5] = { item="Items.AdvancedSandevistanC1MK3",         dur="_inline25", ts="_inline26", rchrg="_inline27" },
	[6] = { item="Items.AdvancedSandevistanC1MK3Plus",     dur="_inline25", ts="_inline26", rchrg="_inline27" },
	[7] = { item="Items.AdvancedSandevistanC1MK4",         dur="_inline25", ts="_inline26", rchrg="_inline27" },
	[8] = { item="Items.AdvancedSandevistanC1MK4Plus",     dur="_inline25", ts="_inline26", rchrg="_inline27" },
	[9] = { item="Items.AdvancedSandevistanC1MK4PlusPlus", dur="_inline25", ts="_inline26", rchrg="_inline27" },
}

local bulletTrailCompatChecked = false
local bulletTrailVelocityBlocked = false

local function tweakFlatMatches(path, expected)
	local value = TweakDB:GetFlat(path)
	return type(value) == "number" and math.abs(value - expected) <= 0.0001
end

local function gunsRedoneOverhaulDetected()
	if bulletTrailCompatChecked then return bulletTrailVelocityBlocked end

	bulletTrailCompatChecked = true
	bulletTrailVelocityBlocked = tweakFlatMatches("Items.PierceKolac_inline0.value", 1.0) and tweakFlatMatches("Items.NoPierceKolac_inline0.value", 0.0)

	return bulletTrailVelocityBlocked
end

local function bulletTrailVelocityEnabled()
	return config.bulletTrail ~= nil and config.bulletTrail.enabled and not gunsRedoneOverhaulDetected()
end

local function applyShrikeTweaks(config)
	if config.zetatech == nil or config.zetatech.enabled == false then return end
	local totalTiers = 9
	for tier, flats in ipairs(SHRIKE_TIER_FLATS) do
		local slowPct = lerpTier(config.zetatech.slowTimeMinPct, config.zetatech.slowTimeMaxPct, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.ts .. ".value", 1.0 - slowPct / 100.0)
		local durSec = lerpTier(config.zetatech.durationMin, config.zetatech.durationMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.dur .. ".value", durSec)
		local rchrgSec = lerpTier(config.zetatech.rechargeMin, config.zetatech.rechargeMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.rchrg .. ".value", rchrgSec)
	end
end

local function createShrikeMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "zetatech"

	applyShrikeTweaks(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMinPct"]["opt"]..nuiTxt[cat]["slowTimeMinPct"]["optUnit"], nuiTxt[cat]["slowTimeMinPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.zetatech.slowTimeMinPct, default.zetatech.slowTimeMinPct, function(value) config.zetatech.slowTimeMinPct = value applyShrikeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMaxPct"]["opt"]..nuiTxt[cat]["slowTimeMaxPct"]["optUnit"], nuiTxt[cat]["slowTimeMaxPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.zetatech.slowTimeMaxPct, default.zetatech.slowTimeMaxPct, function(value) config.zetatech.slowTimeMaxPct = value applyShrikeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 1.0, 30.0, 0.5, "%.1f", config.zetatech.durationMin, default.zetatech.durationMin, function(value) config.zetatech.durationMin = value applyShrikeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 1.0, 30.0, 0.5, "%.1f", config.zetatech.durationMax, default.zetatech.durationMax, function(value) config.zetatech.durationMax = value applyShrikeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMin"]["opt"]..nuiTxt[cat]["rechargeMin"]["optUnit"], nuiTxt[cat]["rechargeMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.zetatech.rechargeMin, default.zetatech.rechargeMin, function(value) config.zetatech.rechargeMin = value applyShrikeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMax"]["opt"]..nuiTxt[cat]["rechargeMax"]["optUnit"], nuiTxt[cat]["rechargeMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.zetatech.rechargeMax, default.zetatech.rechargeMax, function(value) config.zetatech.rechargeMax = value applyShrikeTweaks(config) saveSettings(config) end))

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

local TANTO_TIER_FLATS = {
	[1] = { item="Items.AdvancedSandevistanC2MK1",         dur="_inline1",  ts="_inline2",  rchrg="_inline3",  critCh="_inline14", critDmg="_inline15" },
	[2] = { item="Items.AdvancedSandevistanC2MK1Plus",     dur="_inline1",  ts="_inline2",  rchrg="_inline3",  critCh="_inline14", critDmg="_inline15" },
	[3] = { item="Items.AdvancedSandevistanC2MK2",         dur="_inline11", ts="_inline12", rchrg="_inline13", critCh="_inline8",  critDmg="_inline9"  },
	[4] = { item="Items.AdvancedSandevistanC2MK2Plus",     dur="_inline11", ts="_inline12", rchrg="_inline13", critCh="_inline8",  critDmg="_inline9"  },
	[5] = { item="Items.AdvancedSandevistanC2MK3",         dur="_inline11", ts="_inline12", rchrg="_inline13", critCh="_inline8",  critDmg="_inline9"  },
	[6] = { item="Items.AdvancedSandevistanC2MK3Plus",     dur="_inline11", ts="_inline12", rchrg="_inline13", critCh="_inline8",  critDmg="_inline9"  },
	[7] = { item="Items.AdvancedSandevistanC2MK4",         dur="_inline11", ts="_inline12", rchrg="_inline13", critCh="_inline8",  critDmg="_inline9"  },
	[8] = { item="Items.AdvancedSandevistanC2MK4Plus",     dur="_inline11", ts="_inline12", rchrg="_inline13", critCh="_inline8",  critDmg="_inline9"  },
	[9] = { item="Items.AdvancedSandevistanC2MK4PlusPlus", dur="_inline11", ts="_inline12", rchrg="_inline13", critCh="_inline8",  critDmg="_inline9"  },
}

local function applyTantoTweaks(config)
	if config.tanto == nil or config.tanto.enabled == false then return end
	local totalTiers = 9
	for tier, flats in ipairs(TANTO_TIER_FLATS) do
		local slowPct = lerpTier(config.tanto.slowTimeMinPct, config.tanto.slowTimeMaxPct, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.ts .. ".value", 1.0 - slowPct / 100.0)
		local durSec = lerpTier(config.tanto.durationMin, config.tanto.durationMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.dur .. ".value", durSec)
		local rchrgSec = lerpTier(config.tanto.rechargeMin, config.tanto.rechargeMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.rchrg .. ".value", rchrgSec)
		local critChPct = lerpTier(config.tanto.critChanceMin, config.tanto.critChanceMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.critCh .. ".value", critChPct / 100.0)
		local critDmgPct = lerpTier(config.tanto.critDmgMin, config.tanto.critDmgMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.critDmg .. ".value", critDmgPct / 100.0)
	end
end

local function createTantoMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "tanto"

	applyTantoTweaks(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMinPct"]["opt"]..nuiTxt[cat]["slowTimeMinPct"]["optUnit"], nuiTxt[cat]["slowTimeMinPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.tanto.slowTimeMinPct, default.tanto.slowTimeMinPct, function(value) config.tanto.slowTimeMinPct = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMaxPct"]["opt"]..nuiTxt[cat]["slowTimeMaxPct"]["optUnit"], nuiTxt[cat]["slowTimeMaxPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.tanto.slowTimeMaxPct, default.tanto.slowTimeMaxPct, function(value) config.tanto.slowTimeMaxPct = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 1.0, 30.0, 0.5, "%.1f", config.tanto.durationMin, default.tanto.durationMin, function(value) config.tanto.durationMin = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 1.0, 30.0, 0.5, "%.1f", config.tanto.durationMax, default.tanto.durationMax, function(value) config.tanto.durationMax = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMin"]["opt"]..nuiTxt[cat]["rechargeMin"]["optUnit"], nuiTxt[cat]["rechargeMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.tanto.rechargeMin, default.tanto.rechargeMin, function(value) config.tanto.rechargeMin = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMax"]["opt"]..nuiTxt[cat]["rechargeMax"]["optUnit"], nuiTxt[cat]["rechargeMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.tanto.rechargeMax, default.tanto.rechargeMax, function(value) config.tanto.rechargeMax = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critChanceMin"]["opt"]..nuiTxt[cat]["critChanceMin"]["optUnit"], nuiTxt[cat]["critChanceMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.tanto.critChanceMin, default.tanto.critChanceMin, function(value) config.tanto.critChanceMin = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critChanceMax"]["opt"]..nuiTxt[cat]["critChanceMax"]["optUnit"], nuiTxt[cat]["critChanceMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.tanto.critChanceMax, default.tanto.critChanceMax, function(value) config.tanto.critChanceMax = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critDmgMin"]["opt"]..nuiTxt[cat]["critDmgMin"]["optUnit"], nuiTxt[cat]["critDmgMin"]["des"], 0.0, 200.0, 1.0, "%.0f", config.tanto.critDmgMin, default.tanto.critDmgMin, function(value) config.tanto.critDmgMin = value applyTantoTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critDmgMax"]["opt"]..nuiTxt[cat]["critDmgMax"]["optUnit"], nuiTxt[cat]["critDmgMax"]["des"], 0.0, 200.0, 1.0, "%.0f", config.tanto.critDmgMax, default.tanto.critDmgMax, function(value) config.tanto.critDmgMax = value applyTantoTweaks(config) saveSettings(config) end))

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

local WARPDANCER_TIER_FLATS = {
	[1] = { item="Items.AdvancedSandevistanC3MK3",         dur="_inline1",  ts="_inline2",  rchrg="_inline3"  },
	[2] = { item="Items.AdvancedSandevistanC3MK3Plus",     dur="_inline1",  ts="_inline2",  rchrg="_inline3"  },
	[3] = { item="Items.AdvancedSandevistanC3MK4",         dur="_inline1",  ts="_inline2",  rchrg="_inline3"  },
	[4] = { item="Items.AdvancedSandevistanC3MK4Plus",     dur="_inline1",  ts="_inline2",  rchrg="_inline3"  },
	[5] = { item="Items.AdvancedSandevistanC3MK5",         dur="_inline14", ts="_inline15", rchrg="_inline16" },
	[6] = { item="Items.AdvancedSandevistanC3MK5Plus",     dur="_inline14", ts="_inline15", rchrg="_inline16" },
	[7] = { item="Items.AdvancedSandevistanC3MK5PlusPlus", dur="_inline14", ts="_inline15", rchrg="_inline16" },
}

local function applyWarpDancerTSDurRchrg(config)
	if config.warpDancer == nil or config.warpDancer.enabled == false then return end
	local totalTiers = 7
	for tier, flats in ipairs(WARPDANCER_TIER_FLATS) do
		local slowPct = lerpTier(config.warpDancer.slowTimeMinPct, config.warpDancer.slowTimeMaxPct, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.ts .. ".value", 1.0 - slowPct / 100.0)
		local durSec = lerpTier(config.warpDancer.durationMin, config.warpDancer.durationMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.dur .. ".value", durSec)
		local rchrgSec = lerpTier(config.warpDancer.rechargeMin, config.warpDancer.rechargeMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.rchrg .. ".value", rchrgSec)
	end
end

local WARPDANCER_TIER_SUFFIXES = {"MK3", "MK3Plus", "MK4", "MK4Plus", "MK5", "MK5Plus", "MK5PlusPlus"}
local WARPDANCER_ACTIVATION_INLINE = { MK3 = 8, MK3Plus = 8, MK4 = 8, MK4Plus = 8, MK5 = 1, MK5Plus = 1, MK5PlusPlus = 1 }

local function applyWarpDancerStaggerPerTier(config)
	if config.warpDancer == nil or config.warpDancer.enabled == false then return end
	local sMin = config.warpDancer.staggerDurationMinSec
	local sMax = config.warpDancer.staggerDurationMaxSec
	for i, suffix in ipairs(WARPDANCER_TIER_SUFFIXES) do
		local t = (i - 1) / 6.0
		local staggerSec = sMax - (sMax - sMin) * t
		TweakDB:SetFlat("StatusEffects.TDO_WarpDancerStagger_" .. suffix .. "_DurMod.value", staggerSec)
	end
end

local function applyWarpDancerMoveSpeed(config)
	if config.warpDancer == nil or config.warpDancer.enabled == false then return end
	local msMin = config.warpDancer.moveSpeedMin
	local msMax = config.warpDancer.moveSpeedMax
	for i, suffix in ipairs(WARPDANCER_TIER_SUFFIXES) do
		local t = (i - 1) / 6.0
		local msPct = msMin + (msMax - msMin) * t
		TweakDB:SetFlat("StatusEffects.TDO_WarpDancerMoveSpeed_" .. suffix .. "_Mod.value", 1.0 + msPct / 100.0)
	end
end

local function applyWarpDancerCardValues(config)
	if config.warpDancer == nil or config.warpDancer.enabled == false then return end
	local msMin = config.warpDancer.moveSpeedMin
	local msMax = config.warpDancer.moveSpeedMax
	local stgMin = config.warpDancer.staggerDurationMinSec
	local stgMax = config.warpDancer.staggerDurationMaxSec
	for i, suffix in ipairs(WARPDANCER_TIER_SUFFIXES) do
		local t = (i - 1) / 6.0
		local msPct = msMin + (msMax - msMin) * t
		local stgSec = stgMax - (stgMax - stgMin) * t
		local inlineNum = WARPDANCER_ACTIVATION_INLINE[suffix]
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

local function createWarpDancerMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "warpDancer"

	applyWarpDancerTSDurRchrg(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMinPct"]["opt"]..nuiTxt[cat]["slowTimeMinPct"]["optUnit"], nuiTxt[cat]["slowTimeMinPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.warpDancer.slowTimeMinPct, default.warpDancer.slowTimeMinPct, function(value) config.warpDancer.slowTimeMinPct = value applyWarpDancerTSDurRchrg(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMaxPct"]["opt"]..nuiTxt[cat]["slowTimeMaxPct"]["optUnit"], nuiTxt[cat]["slowTimeMaxPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.warpDancer.slowTimeMaxPct, default.warpDancer.slowTimeMaxPct, function(value) config.warpDancer.slowTimeMaxPct = value applyWarpDancerTSDurRchrg(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 1.0, 30.0, 0.5, "%.1f", config.warpDancer.durationMin, default.warpDancer.durationMin, function(value) config.warpDancer.durationMin = value applyWarpDancerTSDurRchrg(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 1.0, 30.0, 0.5, "%.1f", config.warpDancer.durationMax, default.warpDancer.durationMax, function(value) config.warpDancer.durationMax = value applyWarpDancerTSDurRchrg(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMin"]["opt"]..nuiTxt[cat]["rechargeMin"]["optUnit"], nuiTxt[cat]["rechargeMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.warpDancer.rechargeMin, default.warpDancer.rechargeMin, function(value) config.warpDancer.rechargeMin = value applyWarpDancerTSDurRchrg(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMax"]["opt"]..nuiTxt[cat]["rechargeMax"]["optUnit"], nuiTxt[cat]["rechargeMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.warpDancer.rechargeMax, default.warpDancer.rechargeMax, function(value) config.warpDancer.rechargeMax = value applyWarpDancerTSDurRchrg(config) saveSettings(config) end))

	applyWarpDancerStaggerPerTier(config)
	applyWarpDancerMoveSpeed(config)
	applyWarpDancerCardValues(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["moveSpeedMin"]["opt"]..nuiTxt[cat]["moveSpeedMin"]["optUnit"], nuiTxt[cat]["moveSpeedMin"]["des"], 0.0, 100.0, 0.5, "%.1f", config.warpDancer.moveSpeedMin, default.warpDancer.moveSpeedMin, function(value)
		config.warpDancer.moveSpeedMin = value
		applyWarpDancerMoveSpeed(config)
		applyWarpDancerCardValues(config)
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["moveSpeedMax"]["opt"]..nuiTxt[cat]["moveSpeedMax"]["optUnit"], nuiTxt[cat]["moveSpeedMax"]["des"], 0.0, 100.0, 0.5, "%.1f", config.warpDancer.moveSpeedMax, default.warpDancer.moveSpeedMax, function(value)
		config.warpDancer.moveSpeedMax = value
		applyWarpDancerMoveSpeed(config)
		applyWarpDancerCardValues(config)
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rewindDurationSec"]["opt"]..nuiTxt[cat]["rewindDurationSec"]["optUnit"], nuiTxt[cat]["rewindDurationSec"]["des"], 0.5, 10.0, 0.1, "%.1f", config.warpDancer.rewindDurationSec, default.warpDancer.rewindDurationSec, function(value)
		config.warpDancer.rewindDurationSec = value
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["staggerDurationMinSec"]["opt"]..nuiTxt[cat]["staggerDurationMinSec"]["optUnit"], nuiTxt[cat]["staggerDurationMinSec"]["des"], 0.0, 5.0, 0.05, "%.2f", config.warpDancer.staggerDurationMinSec, default.warpDancer.staggerDurationMinSec, function(value)
		config.warpDancer.staggerDurationMinSec = value
		applyWarpDancerStaggerPerTier(config)
		applyWarpDancerCardValues(config)
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["staggerDurationMaxSec"]["opt"]..nuiTxt[cat]["staggerDurationMaxSec"]["optUnit"], nuiTxt[cat]["staggerDurationMaxSec"]["des"], 0.0, 5.0, 0.05, "%.2f", config.warpDancer.staggerDurationMaxSec, default.warpDancer.staggerDurationMaxSec, function(value)
		config.warpDancer.staggerDurationMaxSec = value
		applyWarpDancerStaggerPerTier(config)
		applyWarpDancerCardValues(config)
		saveSettings(config)
	end))

	return handles
end

local FALCON_TIER_FLATS = {
	[1] = { item="Items.AdvancedSandevistanC4MK4",         dur="_inline22", ts="_inline23", rchrg="_inline24", critCh="_inline8",  critDmg="_inline9"  },
	[2] = { item="Items.AdvancedSandevistanC4MK4Plus",     dur="_inline2",  ts="_inline3",  rchrg="_inline4",  critCh="_inline17", critDmg="_inline18" },
	[3] = { item="Items.AdvancedSandevistanC4MK5",         dur="_inline2",  ts="_inline3",  rchrg="_inline4",  critCh="_inline17", critDmg="_inline18" },
	[4] = { item="Items.AdvancedSandevistanC4MK5Plus",     dur="_inline2",  ts="_inline3",  rchrg="_inline4",  critCh="_inline17", critDmg="_inline18" },
	[5] = { item="Items.AdvancedSandevistanC4MK5PlusPlus", dur="_inline2",  ts="_inline3",  rchrg="_inline4",  critCh="_inline17", critDmg="_inline18" },
}

local function applyFalconTweaks(config)
	if config.falcon == nil or config.falcon.enabled == false then return end
	local totalTiers = 5
	for tier, flats in ipairs(FALCON_TIER_FLATS) do
		local slowPct = lerpTier(config.falcon.slowTimeMinPct, config.falcon.slowTimeMaxPct, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.ts .. ".value", 1.0 - slowPct / 100.0)
		local durSec = lerpTier(config.falcon.durationMin, config.falcon.durationMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.dur .. ".value", durSec)
		local rchrgSec = lerpTier(config.falcon.rechargeMin, config.falcon.rechargeMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.rchrg .. ".value", rchrgSec)
		local critChPct = lerpTier(config.falcon.critChanceMin, config.falcon.critChanceMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.critCh .. ".value", critChPct / 100.0)
		local critDmgPct = lerpTier(config.falcon.critDmgMin, config.falcon.critDmgMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.critDmg .. ".value", critDmgPct / 100.0)
	end
	TweakDB:SetFlat("Attacks.TDO_FalconBoltEMP_MK4_Damage.value",        config.falcon.boltEMPDamageT1)
	TweakDB:SetFlat("Attacks.TDO_FalconBoltEMP_MK4Plus_Damage.value",    config.falcon.boltEMPDamageT2)
	TweakDB:SetFlat("Attacks.TDO_FalconBoltEMP_MK5_Damage.value",        config.falcon.boltEMPDamageT3)
	TweakDB:SetFlat("Attacks.TDO_FalconBoltEMP_MK5Plus_Damage.value",    config.falcon.boltEMPDamageT4)
	TweakDB:SetFlat("Attacks.TDO_FalconBoltEMP_MK5PlusPlus_Damage.value", config.falcon.boltEMPDamageT5)
	TweakDB:Update("Attacks.TDO_FalconBoltEMP_MK4")
	TweakDB:Update("Attacks.TDO_FalconBoltEMP_MK4Plus")
	TweakDB:Update("Attacks.TDO_FalconBoltEMP_MK5")
	TweakDB:Update("Attacks.TDO_FalconBoltEMP_MK5Plus")
	TweakDB:Update("Attacks.TDO_FalconBoltEMP_MK5PlusPlus")
end

local function createFalconMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "falcon"

	applyFalconTweaks(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMinPct"]["opt"]..nuiTxt[cat]["slowTimeMinPct"]["optUnit"], nuiTxt[cat]["slowTimeMinPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.falcon.slowTimeMinPct, default.falcon.slowTimeMinPct, function(value) config.falcon.slowTimeMinPct = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["slowTimeMaxPct"]["opt"]..nuiTxt[cat]["slowTimeMaxPct"]["optUnit"], nuiTxt[cat]["slowTimeMaxPct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.falcon.slowTimeMaxPct, default.falcon.slowTimeMaxPct, function(value) config.falcon.slowTimeMaxPct = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 1.0, 30.0, 0.5, "%.1f", config.falcon.durationMin, default.falcon.durationMin, function(value) config.falcon.durationMin = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 1.0, 30.0, 0.5, "%.1f", config.falcon.durationMax, default.falcon.durationMax, function(value) config.falcon.durationMax = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMin"]["opt"]..nuiTxt[cat]["rechargeMin"]["optUnit"], nuiTxt[cat]["rechargeMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.falcon.rechargeMin, default.falcon.rechargeMin, function(value) config.falcon.rechargeMin = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMax"]["opt"]..nuiTxt[cat]["rechargeMax"]["optUnit"], nuiTxt[cat]["rechargeMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.falcon.rechargeMax, default.falcon.rechargeMax, function(value) config.falcon.rechargeMax = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critChanceMin"]["opt"]..nuiTxt[cat]["critChanceMin"]["optUnit"], nuiTxt[cat]["critChanceMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.falcon.critChanceMin, default.falcon.critChanceMin, function(value) config.falcon.critChanceMin = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critChanceMax"]["opt"]..nuiTxt[cat]["critChanceMax"]["optUnit"], nuiTxt[cat]["critChanceMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.falcon.critChanceMax, default.falcon.critChanceMax, function(value) config.falcon.critChanceMax = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critDmgMin"]["opt"]..nuiTxt[cat]["critDmgMin"]["optUnit"], nuiTxt[cat]["critDmgMin"]["des"], 0.0, 200.0, 1.0, "%.0f", config.falcon.critDmgMin, default.falcon.critDmgMin, function(value) config.falcon.critDmgMin = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critDmgMax"]["opt"]..nuiTxt[cat]["critDmgMax"]["optUnit"], nuiTxt[cat]["critDmgMax"]["des"], 0.0, 200.0, 1.0, "%.0f", config.falcon.critDmgMax, default.falcon.critDmgMax, function(value) config.falcon.critDmgMax = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["boltEMPDamageT1"]["opt"]..nuiTxt[cat]["boltEMPDamageT1"]["optUnit"], nuiTxt[cat]["boltEMPDamageT1"]["des"], 0.0, 2000.0, 25.0, "%.0f", config.falcon.boltEMPDamageT1, default.falcon.boltEMPDamageT1, function(value) config.falcon.boltEMPDamageT1 = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["boltEMPDamageT2"]["opt"]..nuiTxt[cat]["boltEMPDamageT2"]["optUnit"], nuiTxt[cat]["boltEMPDamageT2"]["des"], 0.0, 2000.0, 25.0, "%.0f", config.falcon.boltEMPDamageT2, default.falcon.boltEMPDamageT2, function(value) config.falcon.boltEMPDamageT2 = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["boltEMPDamageT3"]["opt"]..nuiTxt[cat]["boltEMPDamageT3"]["optUnit"], nuiTxt[cat]["boltEMPDamageT3"]["des"], 0.0, 2000.0, 25.0, "%.0f", config.falcon.boltEMPDamageT3, default.falcon.boltEMPDamageT3, function(value) config.falcon.boltEMPDamageT3 = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["boltEMPDamageT4"]["opt"]..nuiTxt[cat]["boltEMPDamageT4"]["optUnit"], nuiTxt[cat]["boltEMPDamageT4"]["des"], 0.0, 2000.0, 25.0, "%.0f", config.falcon.boltEMPDamageT4, default.falcon.boltEMPDamageT4, function(value) config.falcon.boltEMPDamageT4 = value applyFalconTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["boltEMPDamageT5"]["opt"]..nuiTxt[cat]["boltEMPDamageT5"]["optUnit"], nuiTxt[cat]["boltEMPDamageT5"]["des"], 0.0, 2000.0, 25.0, "%.0f", config.falcon.boltEMPDamageT5, default.falcon.boltEMPDamageT5, function(value) config.falcon.boltEMPDamageT5 = value applyFalconTweaks(config) saveSettings(config) end))

	return handles
end

local APOGEE_TIER_FLATS = {
	[1] = { item="Items.AdvancedSandevistanApogee",         dur="_inline19", ts="_inline20", rchrg="_inline21", critCh="_inline8", critDmg="_inline9", headshot="_inline10" },
	[2] = { item="Items.AdvancedSandevistanApogeePlus",     dur="_inline18", ts="_inline19", rchrg="_inline20", critCh="_inline8", critDmg="_inline9", headshot="_inline10" },
	[3] = { item="Items.AdvancedSandevistanApogeePlusPlus", dur="_inline18", ts="_inline19", rchrg="_inline20", critCh="_inline8", critDmg="_inline9", headshot="_inline10" },
}

local function applyApogeeTweaks(config)
	if config.apogee == nil or config.apogee.enabled == false then return end
	local totalTiers = 3
	local apLocActive = TweakDB:GetFlat("Attunements.TDO_ApogeeLoc.localizedDescription")
	if apLocActive ~= nil then apLocActive = tostring(apLocActive) end
	for tier, flats in ipairs(APOGEE_TIER_FLATS) do
		TweakDB:SetFlat(flats.item .. flats.ts .. ".value", 0.01)
		TweakDB:SetFlat(flats.item .. flats.dur .. ".value", 999.0)
		local rchrgSec = lerpTier(config.apogee.rechargeMin, config.apogee.rechargeMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.rchrg .. ".value", rchrgSec)
		local critChPct = lerpTier(config.apogee.critChanceMin, config.apogee.critChanceMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.critCh .. ".value", critChPct)
		local critDmgPct = lerpTier(config.apogee.critDmgMin, config.apogee.critDmgMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.critDmg .. ".value", critDmgPct)
		local headshotPct = lerpTier(config.apogee.headshotMin, config.apogee.headshotMax, tier, totalTiers)
		TweakDB:SetFlat(flats.item .. flats.headshot .. ".value", 1.0 + headshotPct / 100.0)
		if apLocActive ~= nil then
			TweakDB:SetFlat(flats.item .. "_inline1.localizedDescription", apLocActive)
		end
		removeFlatsFromFlatArr(flats.item .. ".OnEquip", { "Attunements.ReflexesSandyProlong", flats.item .. "_inline2" })
		addFlatsToFlatArr(flats.item .. ".OnEquip", { "Attunements.TDO_Apogee" })
		TweakDB:Update(flats.item)
	end
end

local function createApogeeMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "apogee"

	applyApogeeTweaks(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMin"]["opt"]..nuiTxt[cat]["rechargeMin"]["optUnit"], nuiTxt[cat]["rechargeMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.apogee.rechargeMin, default.apogee.rechargeMin, function(value) config.apogee.rechargeMin = value applyApogeeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rechargeMax"]["opt"]..nuiTxt[cat]["rechargeMax"]["optUnit"], nuiTxt[cat]["rechargeMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.apogee.rechargeMax, default.apogee.rechargeMax, function(value) config.apogee.rechargeMax = value applyApogeeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critChanceMin"]["opt"]..nuiTxt[cat]["critChanceMin"]["optUnit"], nuiTxt[cat]["critChanceMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.apogee.critChanceMin, default.apogee.critChanceMin, function(value) config.apogee.critChanceMin = value applyApogeeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critChanceMax"]["opt"]..nuiTxt[cat]["critChanceMax"]["optUnit"], nuiTxt[cat]["critChanceMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.apogee.critChanceMax, default.apogee.critChanceMax, function(value) config.apogee.critChanceMax = value applyApogeeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critDmgMin"]["opt"]..nuiTxt[cat]["critDmgMin"]["optUnit"], nuiTxt[cat]["critDmgMin"]["des"], 0.0, 200.0, 1.0, "%.0f", config.apogee.critDmgMin, default.apogee.critDmgMin, function(value) config.apogee.critDmgMin = value applyApogeeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["critDmgMax"]["opt"]..nuiTxt[cat]["critDmgMax"]["optUnit"], nuiTxt[cat]["critDmgMax"]["des"], 0.0, 200.0, 1.0, "%.0f", config.apogee.critDmgMax, default.apogee.critDmgMax, function(value) config.apogee.critDmgMax = value applyApogeeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["headshotMin"]["opt"]..nuiTxt[cat]["headshotMin"]["optUnit"], nuiTxt[cat]["headshotMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.apogee.headshotMin, default.apogee.headshotMin, function(value) config.apogee.headshotMin = value applyApogeeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["headshotMax"]["opt"]..nuiTxt[cat]["headshotMax"]["optUnit"], nuiTxt[cat]["headshotMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.apogee.headshotMax, default.apogee.headshotMax, function(value) config.apogee.headshotMax = value applyApogeeTweaks(config) saveSettings(config) end))

	return handles
end

local function applyFusilladeTweaks(config)
	if config.fusillade == nil then return end
	TweakDB:SetFlat("Items.TDO_Fusillade_TimeScale.value", config.fusillade.timeScale)
	TweakDB:SetFlat("Items.TDO_Fusillade_Duration.value", config.fusillade.durationMin)
	TweakDB:SetFlat("Items.TDO_FusilladePlus_Duration.value", config.fusillade.durationMax)
	TweakDB:SetFlat("Items.TDO_Fusillade_Recharge.value", config.fusillade.cooldownMax)
	TweakDB:SetFlat("Items.TDO_FusilladePlus_Recharge.value", config.fusillade.cooldownMin)
	TweakDB:SetFlat("Items.TDO_Fusillade_RecoilKickMin.value", config.fusillade.recoil)
	TweakDB:SetFlat("Items.TDO_Fusillade_RecoilKickMax.value", config.fusillade.recoil)
end

local function createFusilladeMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "fusillade"

	applyFusilladeTweaks(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["timeScale"]["opt"]..nuiTxt[cat]["timeScale"]["optUnit"], nuiTxt[cat]["timeScale"]["des"], 0.01, 1.0, 0.01, "%.2f", config.fusillade.timeScale, default.fusillade.timeScale, function(value) config.fusillade.timeScale = value applyFusilladeTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 1.0, 30.0, 0.5, "%.1f", config.fusillade.durationMin, default.fusillade.durationMin, function(value) config.fusillade.durationMin = value applyFusilladeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 1.0, 30.0, 0.5, "%.1f", config.fusillade.durationMax, default.fusillade.durationMax, function(value) config.fusillade.durationMax = value applyFusilladeTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.fusillade.cooldownMin, default.fusillade.cooldownMin, function(value) config.fusillade.cooldownMin = value applyFusilladeTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.fusillade.cooldownMax, default.fusillade.cooldownMax, function(value) config.fusillade.cooldownMax = value applyFusilladeTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["fireRateMult"]["opt"]..nuiTxt[cat]["fireRateMult"]["optUnit"], nuiTxt[cat]["fireRateMult"]["des"], 1.0, 4.0, 0.1, "%.1f", config.fusillade.fireRateMult, default.fusillade.fireRateMult, function(value) config.fusillade.fireRateMult = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rampStartMin"]["opt"]..nuiTxt[cat]["rampStartMin"]["optUnit"], nuiTxt[cat]["rampStartMin"]["des"], 0.0, 1.0, 0.05, "%.2f", config.fusillade.rampStartMin, default.fusillade.rampStartMin, function(value) config.fusillade.rampStartMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rampStartMax"]["opt"]..nuiTxt[cat]["rampStartMax"]["optUnit"], nuiTxt[cat]["rampStartMax"]["des"], 0.0, 1.0, 0.05, "%.2f", config.fusillade.rampStartMax, default.fusillade.rampStartMax, function(value) config.fusillade.rampStartMax = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["rampStep"]["opt"]..nuiTxt[cat]["rampStep"]["optUnit"], nuiTxt[cat]["rampStep"]["des"], 0.0, 1.0, 0.05, "%.2f", config.fusillade.rampStep, default.fusillade.rampStep, function(value) config.fusillade.rampStep = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["recoil"]["opt"]..nuiTxt[cat]["recoil"]["optUnit"], nuiTxt[cat]["recoil"]["des"], 0.0, 3.0, 0.1, "%.1f", config.fusillade.recoil, default.fusillade.recoil, function(value) config.fusillade.recoil = value applyFusilladeTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["ammoRefillMaxChancePct"]["opt"]..nuiTxt[cat]["ammoRefillMaxChancePct"]["optUnit"], nuiTxt[cat]["ammoRefillMaxChancePct"]["des"], 0.0, 100.0, 1.0, "%.0f", config.fusillade.ammoRefillMaxChancePct, default.fusillade.ammoRefillMaxChancePct, function(value) config.fusillade.ammoRefillMaxChancePct = value saveSettings(config) end))

	return handles
end

local function applyKurosawaTweaks(config)
	if config.kurosawa == nil then return end
	TweakDB:SetFlat("Items.TDO_Kurosawa_Duration.value", 999.0) -- buff cap
	TweakDB:SetFlat("Items.TDO_Kurosawa_Recharge.value", config.kurosawa.cooldown)
	TweakDB:SetFlat("Items.TDO_Kurosawa_DamageReduction.value", config.kurosawa.drMin)
	TweakDB:SetFlat("Items.TDO_KurosawaPlus_DamageReduction.value", config.kurosawa.drMax)
end

local function createKurosawaMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "kurosawa"

	applyKurosawaTweaks(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["enemySlowMult"]["opt"]..nuiTxt[cat]["enemySlowMult"]["optUnit"], nuiTxt[cat]["enemySlowMult"]["des"], 0.01, 1.0, 0.01, "%.2f", config.kurosawa.enemySlowMult, default.kurosawa.enemySlowMult, function(value) config.kurosawa.enemySlowMult = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["duration"]["opt"]..nuiTxt[cat]["duration"]["optUnit"], nuiTxt[cat]["duration"]["des"], 1.0, 30.0, 0.5, "%.1f", config.kurosawa.duration, default.kurosawa.duration, function(value) config.kurosawa.duration = value applyKurosawaTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldown"]["opt"]..nuiTxt[cat]["cooldown"]["optUnit"], nuiTxt[cat]["cooldown"]["des"], 5.0, 120.0, 1.0, "%.0f", config.kurosawa.cooldown, default.kurosawa.cooldown, function(value) config.kurosawa.cooldown = value applyKurosawaTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["drMin"]["opt"]..nuiTxt[cat]["drMin"]["optUnit"], nuiTxt[cat]["drMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.drMin, default.kurosawa.drMin, function(value) config.kurosawa.drMin = value applyKurosawaTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["drMax"]["opt"]..nuiTxt[cat]["drMax"]["optUnit"], nuiTxt[cat]["drMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.drMax, default.kurosawa.drMax, function(value) config.kurosawa.drMax = value applyKurosawaTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["healMin"]["opt"]..nuiTxt[cat]["healMin"]["optUnit"], nuiTxt[cat]["healMin"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.healMin, default.kurosawa.healMin, function(value) config.kurosawa.healMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["healMax"]["opt"]..nuiTxt[cat]["healMax"]["optUnit"], nuiTxt[cat]["healMax"]["des"], 0.0, 100.0, 1.0, "%.0f", config.kurosawa.healMax, default.kurosawa.healMax, function(value) config.kurosawa.healMax = value saveSettings(config) end))

	return handles
end

local function applyJuggernautCooldowns(config)
	if config.juggernaut == nil then return end
	TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T1_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 1, 5))
	TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T2_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 2, 5))
	TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T3_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 3, 5))
	TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T4_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 4, 5))
	TweakDB:SetFlat("StatusEffects.TDO_JuggernautCooldown_T5_DurMod.value", lerpTier(config.juggernaut.cooldownMax, config.juggernaut.cooldownMin, 5, 5))
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

	applyJuggernautCooldowns(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.juggernaut.cooldownMin, default.juggernaut.cooldownMin, function(value) config.juggernaut.cooldownMin = value applyJuggernautCooldowns(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.juggernaut.cooldownMax, default.juggernaut.cooldownMax, function(value) config.juggernaut.cooldownMax = value applyJuggernautCooldowns(config) saveSettings(config) end))

	return handles
end

local function applyPyrolithCooldowns(config)
	if config.pyrolith == nil then return end
	TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T1_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 1, 5))
	TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T2_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 2, 5))
	TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T3_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 3, 5))
	TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T4_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 4, 5))
	TweakDB:SetFlat("StatusEffects.TDO_PyrolithCooldown_T5_DurMod.value", lerpTier(config.pyrolith.cooldownMax, config.pyrolith.cooldownMin, 5, 5))
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

	applyPyrolithCooldowns(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.pyrolith.cooldownMin, default.pyrolith.cooldownMin, function(value) config.pyrolith.cooldownMin = value applyPyrolithCooldowns(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.pyrolith.cooldownMax, default.pyrolith.cooldownMax, function(value) config.pyrolith.cooldownMax = value applyPyrolithCooldowns(config) saveSettings(config) end))

	return handles
end

local function applyQuantumDurations(config)
	if config.quantum == nil then return end
	TweakDB:SetFlat("Items.TDO_Quantum_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 1, 5))
	TweakDB:SetFlat("Items.TDO_QuantumPlus_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 2, 5))
	TweakDB:SetFlat("Items.TDO_QuantumAdvanced_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 3, 5))
	TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlus_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 4, 5))
	TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlusPlus_Duration.value", lerpTier(config.quantum.durationMin, config.quantum.durationMax, 5, 5))
end

local function applyQuantumRecharge(config)
	if config.quantum == nil then return end
	TweakDB:SetFlat("Items.TDO_Quantum_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 1, 5))
	TweakDB:SetFlat("Items.TDO_QuantumPlus_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 2, 5))
	TweakDB:SetFlat("Items.TDO_QuantumAdvanced_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 3, 5))
	TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlus_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 4, 5))
	TweakDB:SetFlat("Items.TDO_QuantumAdvancedPlusPlus_Recharge.value", lerpTier(config.quantum.cooldownMax, config.quantum.cooldownMin, 5, 5))
end

local function createQuantumMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "quantum"
	table.insert(handles, nativeSettings.addRangeInt(path, nuiTxt[cat]["maxCharges"]["opt"], nuiTxt[cat]["maxCharges"]["des"], 1, 10, 1, config.quantum.maxCharges, default.quantum.maxCharges, function(value)
		config.quantum.maxCharges = value
		saveSettings(config)
	end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["plotFreezeStrength"]["opt"]..nuiTxt[cat]["plotFreezeStrength"]["optUnit"], nuiTxt[cat]["plotFreezeStrength"]["des"], 0.001, 0.05, 0.001, "%.3f", config.quantum.plotFreezeStrength, default.quantum.plotFreezeStrength, function(value) config.quantum.plotFreezeStrength = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["playerSlowTimePct"]["opt"]..nuiTxt[cat]["playerSlowTimePct"]["optUnit"], nuiTxt[cat]["playerSlowTimePct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.quantum.playerSlowTimePct, default.quantum.playerSlowTimePct, function(value) config.quantum.playerSlowTimePct = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareSlowTimePct"]["opt"]..nuiTxt[cat]["malwareSlowTimePct"]["optUnit"], nuiTxt[cat]["malwareSlowTimePct"]["des"], 0.0, 99.0, 1.0, "%.0f", config.quantum.malwareSlowTimePct, default.quantum.malwareSlowTimePct, function(value) config.quantum.malwareSlowTimePct = value saveSettings(config) end))

	applyQuantumDurations(config)
	applyQuantumRecharge(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.durationMin, default.quantum.durationMin, function(value) config.quantum.durationMin = value applyQuantumDurations(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.durationMax, default.quantum.durationMax, function(value) config.quantum.durationMax = value applyQuantumDurations(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 1.0, 120.0, 0.5, "%.1f", config.quantum.cooldownMin, default.quantum.cooldownMin, function(value) config.quantum.cooldownMin = value applyQuantumRecharge(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 1.0, 120.0, 0.5, "%.1f", config.quantum.cooldownMax, default.quantum.cooldownMax, function(value) config.quantum.cooldownMax = value applyQuantumRecharge(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["teleportRangeMin"]["opt"]..nuiTxt[cat]["teleportRangeMin"]["optUnit"], nuiTxt[cat]["teleportRangeMin"]["des"], 0.0, 30.0, 1.0, "%.0f", config.quantum.teleportRangeMin, default.quantum.teleportRangeMin, function(value) config.quantum.teleportRangeMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["teleportRangeMax"]["opt"]..nuiTxt[cat]["teleportRangeMax"]["optUnit"], nuiTxt[cat]["teleportRangeMax"]["des"], 0.0, 30.0, 1.0, "%.0f", config.quantum.teleportRangeMax, default.quantum.teleportRangeMax, function(value) config.quantum.teleportRangeMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareTargetsMin"]["opt"], nuiTxt[cat]["malwareTargetsMin"]["des"], 1.0, 20.0, 1.0, "%.0f", config.quantum.malwareTargetsMin, default.quantum.malwareTargetsMin, function(value) config.quantum.malwareTargetsMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareTargetsMax"]["opt"], nuiTxt[cat]["malwareTargetsMax"]["des"], 1.0, 20.0, 1.0, "%.0f", config.quantum.malwareTargetsMax, default.quantum.malwareTargetsMax, function(value) config.quantum.malwareTargetsMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareFreezeDurMin"]["opt"]..nuiTxt[cat]["malwareFreezeDurMin"]["optUnit"], nuiTxt[cat]["malwareFreezeDurMin"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.malwareFreezeDurMin, default.quantum.malwareFreezeDurMin, function(value) config.quantum.malwareFreezeDurMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["malwareFreezeDurMax"]["opt"]..nuiTxt[cat]["malwareFreezeDurMax"]["optUnit"], nuiTxt[cat]["malwareFreezeDurMax"]["des"], 0.5, 15.0, 0.25, "%.2f", config.quantum.malwareFreezeDurMax, default.quantum.malwareFreezeDurMax, function(value) config.quantum.malwareFreezeDurMax = value saveSettings(config) end))

	return handles
end

local function applySogimsuTweaks(config)
	if config.sogimsu == nil then return end
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

local function createSogimsuMechanic(nativeSettings, path, nuiTxt, config, default)
	local handles = {}
	local cat = "sogimsu"

	applySogimsuTweaks(config)

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMin"]["opt"]..nuiTxt[cat]["durationMin"]["optUnit"], nuiTxt[cat]["durationMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.durationMin, default.sogimsu.durationMin, function(value) config.sogimsu.durationMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["durationMax"]["opt"]..nuiTxt[cat]["durationMax"]["optUnit"], nuiTxt[cat]["durationMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.durationMax, default.sogimsu.durationMax, function(value) config.sogimsu.durationMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMin"]["opt"]..nuiTxt[cat]["cooldownMin"]["optUnit"], nuiTxt[cat]["cooldownMin"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.cooldownMin, default.sogimsu.cooldownMin, function(value) config.sogimsu.cooldownMin = value applySogimsuTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["cooldownMax"]["opt"]..nuiTxt[cat]["cooldownMax"]["optUnit"], nuiTxt[cat]["cooldownMax"]["des"], 5.0, 120.0, 1.0, "%.0f", config.sogimsu.cooldownMax, default.sogimsu.cooldownMax, function(value) config.sogimsu.cooldownMax = value applySogimsuTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["interventionsMin"]["opt"], nuiTxt[cat]["interventionsMin"]["des"], 1.0, 20.0, 1.0, "%.0f", config.sogimsu.interventionsMin, default.sogimsu.interventionsMin, function(value) config.sogimsu.interventionsMin = value saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["interventionsMax"]["opt"], nuiTxt[cat]["interventionsMax"]["des"], 1.0, 20.0, 1.0, "%.0f", config.sogimsu.interventionsMax, default.sogimsu.interventionsMax, function(value) config.sogimsu.interventionsMax = value saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["detSpeedMin"]["opt"]..nuiTxt[cat]["detSpeedMin"]["optUnit"], nuiTxt[cat]["detSpeedMin"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.detSpeedMin, default.sogimsu.detSpeedMin, function(value) config.sogimsu.detSpeedMin = value applySogimsuTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["detSpeedMax"]["opt"]..nuiTxt[cat]["detSpeedMax"]["optUnit"], nuiTxt[cat]["detSpeedMax"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.detSpeedMax, default.sogimsu.detSpeedMax, function(value) config.sogimsu.detSpeedMax = value applySogimsuTweaks(config) saveSettings(config) end))

	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["stealthDmgMin"]["opt"]..nuiTxt[cat]["stealthDmgMin"]["optUnit"], nuiTxt[cat]["stealthDmgMin"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.stealthDmgMin, default.sogimsu.stealthDmgMin, function(value) config.sogimsu.stealthDmgMin = value applySogimsuTweaks(config) saveSettings(config) end))
	table.insert(handles, nativeSettings.addRangeFloat(path, nuiTxt[cat]["stealthDmgMax"]["opt"]..nuiTxt[cat]["stealthDmgMax"]["optUnit"], nuiTxt[cat]["stealthDmgMax"]["des"], 0.0, 200.0, 1.0, "%.0f", config.sogimsu.stealthDmgMax, default.sogimsu.stealthDmgMax, function(value) config.sogimsu.stealthDmgMax = value applySogimsuTweaks(config) saveSettings(config) end))

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

local function createVanillaSandyMenu(nativeSettings, path, displayName, nuiTxt, config, showFlagKey, enableConfigSection, enableLabel, enableDefault, mechanicCreator)
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
			if mechanicCreator ~= nil then
				mechanicHandles = mechanicCreator(nativeSettings, path)
			end
		end
		saveSettings(config)
	end, 1)

	nativeSettings.addSwitch(path, enableLabel.opt, enableLabel.des, config[enableConfigSection].enabled, enableDefault, function(state)
		config[enableConfigSection].enabled = state
		saveSettings(config)
	end)

	if config[showFlagKey] == true and mechanicCreator ~= nil then
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

	if Game.GetPlayer() then
		isLoaded = Game.GetPlayer():IsAttached() and not Game.GetSystemRequestsHandler():IsPreGame()
	end

	local hardCodedMods = require("config/externalMods.lua") or {}
	for i, v in pairs(hardCodedMods) do
		ExternalMods[i] = v
	end

	
	nativeSettings = GetMod("nativeSettings")
	if nativeSettings ~= nil then
		config = loadSettings()

		local oldVersion = config.configVersion or 0

		if oldVersion < 11.5 and config.vehicle ~= nil then
			print("[TDO] INFO: Vehicle handling shipping defaults v11.5 — Car Turn Strength, Traction, Grip, and motorcycle sliders retuned to the new shipping defaults. Wiping vehicle.* to populate fresh values.")
			config.vehicle = nil
		end

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

		if config.quantum ~= nil then
			local qtClamped = false
			if type(config.quantum.teleportRangeMin) == "number" and config.quantum.teleportRangeMin > 30.0 then
				config.quantum.teleportRangeMin = 30.0
				qtClamped = true
			end
			if type(config.quantum.teleportRangeMax) == "number" and config.quantum.teleportRangeMax > 30.0 then
				config.quantum.teleportRangeMax = 30.0
				qtClamped = true
			end
			if qtClamped then
				saveSettings(config)
			end
		end

		if migrateSandysToVanillaSandyKeys(config, oldVersion) then
			saveSettings(config)
		end

		applyShrikeTweaks(config)
		applyTantoTweaks(config)
		applyWarpDancerTSDurRchrg(config)
		applyWarpDancerStaggerPerTier(config)
		applyWarpDancerMoveSpeed(config)
		applyWarpDancerCardValues(config)
		applyFalconTweaks(config)
		applyApogeeTweaks(config)
		applyFusilladeTweaks(config)
		applyKurosawaTweaks(config)
		applyJuggernautCooldowns(config)
		applyPyrolithCooldowns(config)
		applyQuantumDurations(config)
		applyQuantumRecharge(config)
		applySogimsuTweaks(config)

		local nuiTxt = Localizer.GetTextWithKeys("nui", nil, nil, nil)

		nativeSettings.addTab("/tdo", "TDO", function()
			saveSettings(config)
		end)

		nativeSettings.addSubcategory("/tdo/note", nuiTxt["reloadWarning"])

		nativeSettings.addSubcategory("/tdo/cinematic", "Cinematic / Screenshot Mode")

		nativeSettings.addSwitch("/tdo/cinematic", "Hide All TDO UI", "Master toggle: hides every TDO-added HUD element (scanning bar, teleport markers). Useful for screenshots and cinematic recording.", config.ui.hideAll, default.ui.hideAll, function(state)
			config.ui.hideAll = state
			saveSettings(config)
		end)

		nativeSettings.addSwitch("/tdo/cinematic", "Hide Scanning Charge Bar", "Hides the scanner time-dilation charge bar at the bottom of the screen. Bar still functions, just invisible.", config.ui.hideScanBar, default.ui.hideScanBar, function(state)
			config.ui.hideScanBar = state
			saveSettings(config)
		end)

		nativeSettings.addSwitch("/tdo/cinematic", "Hide Quantum Teleport Marker", "Hides the destination marker while plotting a Quantum teleport. Teleport still works, just no marker.", config.ui.hideQuantumMarker, default.ui.hideQuantumMarker, function(state)
			config.ui.hideQuantumMarker = state
			saveSettings(config)
		end)

		Override("TDOConfig", "UIHideAll;", function() return config.ui.hideAll end)
		Override("TDOConfig", "UIHideScanBar;", function() return config.ui.hideScanBar end)
		Override("TDOConfig", "UIHideQuantumMarker;", function() return config.ui.hideQuantumMarker end)

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

		nativeSettings.addSelectorString("/tdo/DOT", "Damage Curve", "How DOT damage scales with slow strength. Linear = constant ramp. Squared = soft start, bites hard at high slow. InverseSquared = bites early, softens at high slow.", {"Linear", "Squared", "InverseSquared"}, config.dot.curveType + 1, default.dot.curveType + 1, function(value)
			config.dot.curveType = value - 1
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
		Override("TDOConfig", "DOTCurveType;", function() return config.dot.curveType end)

		cat = "bulletTrail"
		nativeSettings.addSubcategory("/tdo/bulletTrail", nuiTxt[cat]["header"])

		nativeSettings.addSwitch("/tdo/bulletTrail", nuiTxt[cat]["enabled"]["opt"], nuiTxt[cat]["enabled"]["des"], config.bulletTrail.enabled, default.bulletTrail.enabled, function(state) config.bulletTrail.enabled = state saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at10"]["opt"]..nuiTxt[cat]["at10"]["optUnit"], nuiTxt[cat]["at10"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at10, default.bulletTrail.at10, function(value) config.bulletTrail.at10 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at20"]["opt"]..nuiTxt[cat]["at20"]["optUnit"], nuiTxt[cat]["at20"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at20, default.bulletTrail.at20, function(value) config.bulletTrail.at20 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at30"]["opt"]..nuiTxt[cat]["at30"]["optUnit"], nuiTxt[cat]["at30"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at30, default.bulletTrail.at30, function(value) config.bulletTrail.at30 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at40"]["opt"]..nuiTxt[cat]["at40"]["optUnit"], nuiTxt[cat]["at40"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at40, default.bulletTrail.at40, function(value) config.bulletTrail.at40 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at50"]["opt"]..nuiTxt[cat]["at50"]["optUnit"], nuiTxt[cat]["at50"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at50, default.bulletTrail.at50, function(value) config.bulletTrail.at50 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at60"]["opt"]..nuiTxt[cat]["at60"]["optUnit"], nuiTxt[cat]["at60"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at60, default.bulletTrail.at60, function(value) config.bulletTrail.at60 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at70"]["opt"]..nuiTxt[cat]["at70"]["optUnit"], nuiTxt[cat]["at70"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at70, default.bulletTrail.at70, function(value) config.bulletTrail.at70 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at80"]["opt"]..nuiTxt[cat]["at80"]["optUnit"], nuiTxt[cat]["at80"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at80, default.bulletTrail.at80, function(value) config.bulletTrail.at80 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at90"]["opt"]..nuiTxt[cat]["at90"]["optUnit"], nuiTxt[cat]["at90"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at90, default.bulletTrail.at90, function(value) config.bulletTrail.at90 = value saveSettings(config) end)

		nativeSettings.addRangeFloat("/tdo/bulletTrail", nuiTxt[cat]["at99"]["opt"]..nuiTxt[cat]["at99"]["optUnit"], nuiTxt[cat]["at99"]["des"], 5.0, 500.0, 5.0, "%.0f", config.bulletTrail.at99, default.bulletTrail.at99, function(value) config.bulletTrail.at99 = value saveSettings(config) end)

		Override("TDOConfig", "BulletTrailVelocityEnabled;", function() return bulletTrailVelocityEnabled() end)
		Override("TDOConfig", "BulletTrailVelocityAt10;", function() return config.bulletTrail.at10 end)
		Override("TDOConfig", "BulletTrailVelocityAt20;", function() return config.bulletTrail.at20 end)
		Override("TDOConfig", "BulletTrailVelocityAt30;", function() return config.bulletTrail.at30 end)
		Override("TDOConfig", "BulletTrailVelocityAt40;", function() return config.bulletTrail.at40 end)
		Override("TDOConfig", "BulletTrailVelocityAt50;", function() return config.bulletTrail.at50 end)
		Override("TDOConfig", "BulletTrailVelocityAt60;", function() return config.bulletTrail.at60 end)
		Override("TDOConfig", "BulletTrailVelocityAt70;", function() return config.bulletTrail.at70 end)
		Override("TDOConfig", "BulletTrailVelocityAt80;", function() return config.bulletTrail.at80 end)
		Override("TDOConfig", "BulletTrailVelocityAt90;", function() return config.bulletTrail.at90 end)
		Override("TDOConfig", "BulletTrailVelocityAt99;", function() return config.bulletTrail.at99 end)


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

		nativeSettings.addRangeFloat("/tdo/scanning", nuiTxt[cat]["gracePeriodSec"]["opt"]..nuiTxt[cat]["gracePeriodSec"]["optUnit"], nuiTxt[cat]["gracePeriodSec"]["des"], 0.1, 2.0, 0.1, "%.1f", config.scanning.gracePeriodSec, default.scanning.gracePeriodSec, function(value)
			config.scanning.gracePeriodSec = value
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
		Override("TDOConfig", "ScanningGracePeriodSec;", function() return config.scanning.gracePeriodSec end)

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

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["carYaw"]["opt"], nuiTxt[cat]["carYaw"]["des"], 0.0, 10.0, 0.1, "%.1f", config.vehicle.carYaw, default.vehicle.carYaw, function(value)
			config.vehicle.carYaw = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["traction"]["opt"], nuiTxt[cat]["traction"]["des"], 0.0, 5.0, 0.1, "%.1f", config.vehicle.traction, default.vehicle.traction, function(value)
			config.vehicle.traction = value
			saveSettings(config)
		end)

		nativeSettings.addRangeFloat("/tdo/vehicle", nuiTxt[cat]["gripForce"]["opt"], nuiTxt[cat]["gripForce"]["des"], 0.0, 2.0, 0.05, "%.2f", config.vehicle.gripForce, default.vehicle.gripForce, function(value)
			config.vehicle.gripForce = value
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
		Override("TDOConfig", "HerbieDownforce;", function() return config.vehicle.downforce end)
		Override("TDOConfig", "HerbieBikeYaw;", function() return config.vehicle.bikeYaw end)
		Override("TDOConfig", "HerbieBikeGrip;", function() return config.vehicle.bikeGrip end)
		Override("TDOConfig", "HerbieCarYaw;", function() return config.vehicle.carYaw end)
		Override("TDOConfig", "HerbieTraction;", function() return config.vehicle.traction end)

		createVanillaSandyMenu(nativeSettings, "/tdo/shrike", nuiTxt.zetatech.header, nuiTxt, config, "zetatechShow", "zetatech", nuiTxt.zetatech.enabled, default.zetatech.enabled, function(ns, p)
			return createShrikeMechanic(ns, p, nuiTxt, config, default)
		end)

		Override("TDOConfig", "ShrikeSlowTimeMinPct;", function() return config.zetatech.slowTimeMinPct end)
		Override("TDOConfig", "ShrikeSlowTimeMaxPct;", function() return config.zetatech.slowTimeMaxPct end)
		Override("TDOConfig", "ShrikeDurationMin;",    function() return config.zetatech.durationMin    end)
		Override("TDOConfig", "ShrikeDurationMax;",    function() return config.zetatech.durationMax    end)
		Override("TDOConfig", "ShrikeRechargeMin;",    function() return config.zetatech.rechargeMin    end)
		Override("TDOConfig", "ShrikeRechargeMax;",    function() return config.zetatech.rechargeMax    end)

		Override("TDOConfig", "TantoSlowTimeMinPct;", function() return config.tanto.slowTimeMinPct end)
		Override("TDOConfig", "TantoSlowTimeMaxPct;", function() return config.tanto.slowTimeMaxPct end)
		Override("TDOConfig", "TantoDurationMin;",    function() return config.tanto.durationMin    end)
		Override("TDOConfig", "TantoDurationMax;",    function() return config.tanto.durationMax    end)
		Override("TDOConfig", "TantoRechargeMin;",    function() return config.tanto.rechargeMin    end)
		Override("TDOConfig", "TantoRechargeMax;",    function() return config.tanto.rechargeMax    end)
		Override("TDOConfig", "TantoCritChanceMin;",  function() return config.tanto.critChanceMin  end)
		Override("TDOConfig", "TantoCritChanceMax;",  function() return config.tanto.critChanceMax  end)
		Override("TDOConfig", "TantoCritDmgMin;",     function() return config.tanto.critDmgMin     end)
		Override("TDOConfig", "TantoCritDmgMax;",     function() return config.tanto.critDmgMax     end)

		Override("TDOConfig", "WarpDancerSlowTimeMinPct;", function() return config.warpDancer.slowTimeMinPct end)
		Override("TDOConfig", "WarpDancerSlowTimeMaxPct;", function() return config.warpDancer.slowTimeMaxPct end)
		Override("TDOConfig", "WarpDancerDurationMin;",    function() return config.warpDancer.durationMin    end)
		Override("TDOConfig", "WarpDancerDurationMax;",    function() return config.warpDancer.durationMax    end)
		Override("TDOConfig", "WarpDancerRechargeMin;",    function() return config.warpDancer.rechargeMin    end)
		Override("TDOConfig", "WarpDancerRechargeMax;",    function() return config.warpDancer.rechargeMax    end)
		Override("TDOConfig", "WarpDancerMoveSpeedMin;",   function() return config.warpDancer.moveSpeedMin   end)
		Override("TDOConfig", "WarpDancerMoveSpeedMax;",   function() return config.warpDancer.moveSpeedMax   end)

		Override("TDOConfig", "FalconSlowTimeMinPct;", function() return config.falcon.slowTimeMinPct end)
		Override("TDOConfig", "FalconSlowTimeMaxPct;", function() return config.falcon.slowTimeMaxPct end)
		Override("TDOConfig", "FalconDurationMin;",    function() return config.falcon.durationMin    end)
		Override("TDOConfig", "FalconDurationMax;",    function() return config.falcon.durationMax    end)
		Override("TDOConfig", "FalconRechargeMin;",    function() return config.falcon.rechargeMin    end)
		Override("TDOConfig", "FalconRechargeMax;",    function() return config.falcon.rechargeMax    end)
		Override("TDOConfig", "FalconCritChanceMin;",  function() return config.falcon.critChanceMin  end)
		Override("TDOConfig", "FalconCritChanceMax;",  function() return config.falcon.critChanceMax  end)
		Override("TDOConfig", "FalconCritDmgMin;",     function() return config.falcon.critDmgMin     end)
		Override("TDOConfig", "FalconCritDmgMax;",     function() return config.falcon.critDmgMax     end)
		Override("TDOConfig", "FalconBoltEMPDamage_T1;", function() return config.falcon.boltEMPDamageT1 end)
		Override("TDOConfig", "FalconBoltEMPDamage_T2;", function() return config.falcon.boltEMPDamageT2 end)
		Override("TDOConfig", "FalconBoltEMPDamage_T3;", function() return config.falcon.boltEMPDamageT3 end)
		Override("TDOConfig", "FalconBoltEMPDamage_T4;", function() return config.falcon.boltEMPDamageT4 end)
		Override("TDOConfig", "FalconBoltEMPDamage_T5;", function() return config.falcon.boltEMPDamageT5 end)

		Override("TDOConfig", "ApogeeEnabled;",        function() return config.apogee.enabled end)
		Override("TDOConfig", "ApogeeRechargeMin;",    function() return config.apogee.rechargeMin    end)
		Override("TDOConfig", "ApogeeRechargeMax;",    function() return config.apogee.rechargeMax    end)
		Override("TDOConfig", "ApogeeCritChanceMin;",  function() return config.apogee.critChanceMin  end)
		Override("TDOConfig", "ApogeeCritChanceMax;",  function() return config.apogee.critChanceMax  end)
		Override("TDOConfig", "ApogeeCritDmgMin;",     function() return config.apogee.critDmgMin     end)
		Override("TDOConfig", "ApogeeCritDmgMax;",     function() return config.apogee.critDmgMax     end)
		Override("TDOConfig", "ApogeeHeadshotMin;",    function() return config.apogee.headshotMin    end)
		Override("TDOConfig", "ApogeeHeadshotMax;",    function() return config.apogee.headshotMax    end)

		Override("TDOConfig", "QuantumPlayerSlowTimePct;",  function() return config.quantum.playerSlowTimePct  end)
		Override("TDOConfig", "QuantumMalwareSlowTimePct;", function() return config.quantum.malwareSlowTimePct end)

		createVanillaSandyMenu(nativeSettings, "/tdo/tanto", nuiTxt.tanto.header, nuiTxt, config, "tantoShow", "tanto", nuiTxt.tanto.enabled, default.tanto.enabled, function(ns, p)
			return createTantoMechanic(ns, p, nuiTxt, config, default)
		end)

		createVanillaSandyMenu(nativeSettings, "/tdo/warpDancer", nuiTxt.warpDancer.header, nuiTxt, config, "warpDancerShow", "warpDancer", nuiTxt.warpDancer.enabled, default.warpDancer.enabled, function(ns, p)
			return createWarpDancerMechanic(ns, p, nuiTxt, config, default)
		end)

		createVanillaSandyMenu(nativeSettings, "/tdo/falcon", nuiTxt.falcon.header, nuiTxt, config, "falconShow", "falcon", nuiTxt.falcon.enabled, default.falcon.enabled, function(ns, p)
			return createFalconMechanic(ns, p, nuiTxt, config, default)
		end)

		createVanillaSandyMenu(nativeSettings, "/tdo/apogee", nuiTxt.apogee.header, nuiTxt, config, "apogeeShow", "apogee", nuiTxt.apogee.enabled, default.apogee.enabled, function(ns, p)
			return createApogeeMechanic(ns, p, nuiTxt, config, default)
		end)

		
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


registerForEvent("onShutdown", function()
end)

registerHotkey("TDOCinematicHideAll", "Cinematic — Toggle Hide All TDO UI", function()
	if type(config) ~= "table" or type(config.ui) ~= "table" then return end
	config.ui.hideAll = not config.ui.hideAll
	saveSettings(config)
	print("[TDO] Hide All UI: " .. tostring(config.ui.hideAll))
end)

registerHotkey("TDOCinematicHideScanBar", "Cinematic — Toggle Hide Scanning Bar", function()
	if type(config) ~= "table" or type(config.ui) ~= "table" then return end
	config.ui.hideScanBar = not config.ui.hideScanBar
	saveSettings(config)
	print("[TDO] Hide Scanning Bar: " .. tostring(config.ui.hideScanBar))
end)

registerHotkey("TDOCinematicHideQuantumMarker", "Cinematic — Toggle Hide Quantum Marker", function()
	if type(config) ~= "table" or type(config.ui) ~= "table" then return end
	config.ui.hideQuantumMarker = not config.ui.hideQuantumMarker
	saveSettings(config)
	print("[TDO] Hide Quantum Marker: " .. tostring(config.ui.hideQuantumMarker))
end)


return {
	TDODumpSandyStructure = TDODumpSandyStructure,
	TDOZetatechDebug = TDOZetatechDebug,
	TDODumpWeapon = TDODumpWeapon,
	TDODumpRecord = TDODumpRecord,
	TDODumpVanillaSandies = TDODumpVanillaSandies,
	TDODumpFullTweakDB = TDODumpFullTweakDB,
	TDODumpApogeeConflict = TDODumpApogeeConflict
}

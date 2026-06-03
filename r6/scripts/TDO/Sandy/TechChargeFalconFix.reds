module TDO.Sandy

import TDO.Logging.*

@addField(WeaponObject)
public let m_tdoTechChargeFalconMod: ref<gameConstantStatModifierData>;

public func TDO_TechChargeFalconFix_ShouldApply(player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Bool {
  if !IsDefined(player) || !IsDefined(weapon) { return false; }
  if !TDO_Falcon_IsEquipped(player) { return false; }
  if !TDO_Falcon_IsSandyActive(player) { return false; }
  if !TDO_Falcon_IsTechWeapon(weapon) { return false; }
  return true;
}

public func TDO_TechChargeFalconFix_Remove(weapon: ref<WeaponObject>) -> Void {
  if !IsDefined(weapon) { return; }
  if !IsDefined(weapon.m_tdoTechChargeFalconMod) { return; }
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
  stats.RemoveModifier(weapon.GetItemData().GetStatsObjectID(), weapon.m_tdoTechChargeFalconMod);
  weapon.m_tdoTechChargeFalconMod = null;
}

public func TDO_TechChargeFalconFix_Apply(player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Void {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
  let timeScale: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.TimeDilationSandevistanTimeScale);
  if timeScale <= 0.0 || timeScale >= 1.0 { return; }

  weapon.m_tdoTechChargeFalconMod = RPGManager.CreateStatModifier(gamedataStatType.ChargeTime, gameStatModifierType.Multiplier, timeScale) as gameConstantStatModifierData;
  stats.AddModifier(weapon.GetItemData().GetStatsObjectID(), weapon.m_tdoTechChargeFalconMod);
  TDOInfo("TechChargeFix", s"Applied Falcon tech-charge compression: timeScale=\(timeScale)");
}

@wrapMethod(WeaponObject)
protected cb func OnSetActiveWeapon(evt: ref<SetActiveWeaponEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  TDO_TechChargeFalconFix_Remove(this);

  let player: ref<PlayerPuppet> = this.GetOwner() as PlayerPuppet;
  if !TDO_TechChargeFalconFix_ShouldApply(player, this) { return result; }

  TDO_TechChargeFalconFix_Apply(player, this);
  return result;
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }

  let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(player);
  if !IsDefined(weapon) { return; }

  if !TDO_TechChargeFalconFix_ShouldApply(player, weapon) { return; }
  TDO_TechChargeFalconFix_Apply(player, weapon);
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(player);
    if IsDefined(weapon) {
      TDO_TechChargeFalconFix_Remove(weapon);
    }
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(player);
    if IsDefined(weapon) {
      TDO_TechChargeFalconFix_Remove(weapon);
    }
  }
  wrappedMethod(stateContext, scriptInterface);
}

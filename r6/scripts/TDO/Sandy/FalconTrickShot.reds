module TDO.Sandy

import TDO.Logging.*

@wrapMethod(ReloadDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let canReload: Bool = wrappedMethod(stateContext, scriptInterface);
  if !canReload { return false; }
  if !TDOConfig.FalconTrickShotEnabled() { return canReload; }
  if !TDOConfig.FalconTrickShotBlockReload() { return canReload; }

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return canReload; }
  if !TDO_Falcon_IsSandyActive(player) { return canReload; }
  if !TDO_Falcon_IsEquipped(player) { return canReload; }

  let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(player);
  if !IsDefined(weapon) { return canReload; }
  if !TDO_Falcon_IsPowerWeapon(weapon) { return canReload; }

  TDODebug("TrickShot", "blocking reload (Power weapon, Sandy active)");
  return false;
}

@wrapMethod(NoAmmoDecisions)
protected final const func ToReload(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let canReload: Bool = wrappedMethod(stateContext, scriptInterface);
  if !canReload { return false; }
  if !TDOConfig.FalconTrickShotEnabled() { return canReload; }
  if !TDOConfig.FalconTrickShotBlockReload() { return canReload; }

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return canReload; }
  if !TDO_Falcon_IsSandyActive(player) { return canReload; }
  if !TDO_Falcon_IsEquipped(player) { return canReload; }

  let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(player);
  if !IsDefined(weapon) { return canReload; }
  if !TDO_Falcon_IsPowerWeapon(weapon) { return canReload; }

  TDODebug("TrickShot", "blocking reload (Power weapon, Sandy active)");
  return false;
}

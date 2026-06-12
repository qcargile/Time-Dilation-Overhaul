module TDO.Core

import TDO.Logging.*

@wrapMethod(CycleTriggerModeEvents)
protected final func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  let weapon: wref<WeaponObject> = GameObject.GetActiveWeapon(player);
  if !IsDefined(weapon) {
    return;
  }
  let triggerMode: ref<TriggerMode_Record> = weapon.GetCurrentTriggerMode();
  if !IsDefined(triggerMode) {
    return;
  }
  if !Equals(triggerMode.Type(), gamedataTriggerMode.Charge) {
    return;
  }
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(player.GetGame());
  let weaponID: StatsObjectID = Cast<StatsObjectID>(weapon.GetEntityID());
  if pools.HasActiveStatPool(weaponID, gamedataStatPoolType.WeaponCharge) {
    return;
  }
  pools.RequestAddingStatPool(weaponID, t"BaseStatPools.WeaponCharge", true);
  TDODebug("TechChargeGuard", "WeaponCharge pool re-added after trigger mode cycle to Charge");
}

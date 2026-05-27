module TDO.Sandy

import TDO.Logging.*

public func TDO_Apogee_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return false;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return false;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tdb: TweakDBID = ItemID.GetTDBID(itemID);
      if Equals(tdb, t"Items.AdvancedSandevistanApogee") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanApogeePlus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanApogeePlusPlus") { return true; }
    }
    slotIdx += 1;
  }
  return false;
}

@addField(PlayerPuppet)
public let m_apogeeActivationCount: Int32;

@addField(PlayerPuppet)
public let m_apogeeLastActivationTime: Float;

public func TDO_Apogee_GetDOTMultiplier(player: ref<PlayerPuppet>) -> Float {
  if !IsDefined(player) {
    return 1.0;
  }
  if !TDOConfig.ApogeeEnabled() {
    return 1.0;
  }
  if !TDO_Apogee_IsEquipped(player) {
    return 1.0;
  }
  let count: Int32 = player.m_apogeeActivationCount;
  if count <= 1 {
    return 1.0;
  }
  let cap: Float = TDOConfig.ApogeeStrainMultiplierCap();
  let raw: Float = PowF(2.0, Cast<Float>(count - 1));
  if raw > cap {
    return cap;
  }
  return raw;
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if !TDOConfig.ApogeeEnabled() {
    return;
  }
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_Apogee_IsEquipped(player) {
    return;
  }
  let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame()));
  let elapsed: Float = now - player.m_apogeeLastActivationTime;
  if elapsed > 60.0 {
    player.m_apogeeActivationCount = 1;
  } else {
    player.m_apogeeActivationCount += 1;
  }
  player.m_apogeeLastActivationTime = now;
  TDOInfo("ApogeeStrain", "stack count=" + ToString(player.m_apogeeActivationCount) + " elapsed=" + ToString(elapsed));
}

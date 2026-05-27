module TDO.Sandy

public func TDO_Falcon_IsSandyActive(player: ref<PlayerPuppet>) -> Bool {
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) {
    return false;
  }
  let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
  return td == EnumInt(gamePSMTimeDilation.Sandevistan);
}

public func TDO_Falcon_GetHeldWeapon(player: ref<PlayerPuppet>) -> ref<WeaponObject> {
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(player.GetGame());
  if !IsDefined(ts) {
    return null;
  }
  return ts.GetItemInSlot(player, t"AttachmentSlots.WeaponRight") as WeaponObject;
}

public func TDO_Falcon_GetWeaponEvolution(weapon: ref<WeaponObject>) -> gamedataWeaponEvolution {
  if !IsDefined(weapon) {
    return gamedataWeaponEvolution.Invalid;
  }
  return RPGManager.GetWeaponEvolution(weapon.GetItemID());
}

public func TDO_Falcon_IsPowerWeapon(weapon: ref<WeaponObject>) -> Bool {
  return Equals(TDO_Falcon_GetWeaponEvolution(weapon), gamedataWeaponEvolution.Power);
}

public func TDO_Falcon_IsTechWeapon(weapon: ref<WeaponObject>) -> Bool {
  return Equals(TDO_Falcon_GetWeaponEvolution(weapon), gamedataWeaponEvolution.Tech);
}

public func TDO_Falcon_IsSmartWeapon(weapon: ref<WeaponObject>) -> Bool {
  return Equals(TDO_Falcon_GetWeaponEvolution(weapon), gamedataWeaponEvolution.Smart);
}

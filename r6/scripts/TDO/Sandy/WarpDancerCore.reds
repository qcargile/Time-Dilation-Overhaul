module TDO.Sandy

public class TDO_WarpDancerFrame {
  public let pos: Vector4;
  public let rot: EulerAngles;
}

@addField(PlayerPuppet)
public let m_warpDancerPhase: Int32;

@addField(PlayerPuppet)
public let m_warpDancerStartPos: Vector4;

@addField(PlayerPuppet)
public let m_warpDancerStartRot: EulerAngles;

@addField(PlayerPuppet)
public let m_warpDancerRecord: array<ref<TDO_WarpDancerFrame>>;

@addField(PlayerPuppet)
public let m_warpDancerRewindIdx: Int32;

@addField(PlayerPuppet)
public let m_warpDancerTickID: DelayID;

@addField(PlayerPuppet)
public let m_warpDancerStoredNPCs: array<wref<NPCPuppet>>;

@addField(PlayerPuppet)
public let m_warpDancerComputedStride: Int32;

public func TDO_WarpDancer_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
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
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK3") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK3Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK4") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK4Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK5") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK5Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK5PlusPlus") { return true; }
    }
    slotIdx += 1;
  }
  return false;
}

public func TDO_WarpDancer_GetEquippedTierIndex(player: ref<PlayerPuppet>) -> Int32 {
  if !IsDefined(player) {
    return -1;
  }
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return -1;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return -1;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tdb: TweakDBID = ItemID.GetTDBID(itemID);
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK3") { return 0; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK3Plus") { return 1; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK4") { return 2; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK4Plus") { return 3; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK5") { return 4; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK5Plus") { return 5; }
      if Equals(tdb, t"Items.AdvancedSandevistanC3MK5PlusPlus") { return 6; }
    }
    slotIdx += 1;
  }
  return -1;
}

public func TDO_WarpDancer_GetStaggerSEID(player: ref<PlayerPuppet>) -> TweakDBID {
  let idx: Int32 = TDO_WarpDancer_GetEquippedTierIndex(player);
  if idx == 0 { return t"StatusEffects.TDO_WarpDancerStagger_MK3"; }
  if idx == 1 { return t"StatusEffects.TDO_WarpDancerStagger_MK3Plus"; }
  if idx == 2 { return t"StatusEffects.TDO_WarpDancerStagger_MK4"; }
  if idx == 3 { return t"StatusEffects.TDO_WarpDancerStagger_MK4Plus"; }
  if idx == 4 { return t"StatusEffects.TDO_WarpDancerStagger_MK5"; }
  if idx == 5 { return t"StatusEffects.TDO_WarpDancerStagger_MK5Plus"; }
  return t"StatusEffects.TDO_WarpDancerStagger_MK5PlusPlus";
}

public func TDO_WarpDancer_IsActive(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  return player.m_warpDancerPhase != 0;
}

public func TDO_WarpDancer_GetMoveSpeedSEID(tier: Int32) -> TweakDBID {
  switch tier {
    case 0: return t"StatusEffects.TDO_WarpDancerMoveSpeed_MK3";
    case 1: return t"StatusEffects.TDO_WarpDancerMoveSpeed_MK3Plus";
    case 2: return t"StatusEffects.TDO_WarpDancerMoveSpeed_MK4";
    case 3: return t"StatusEffects.TDO_WarpDancerMoveSpeed_MK4Plus";
    case 4: return t"StatusEffects.TDO_WarpDancerMoveSpeed_MK5";
    case 5: return t"StatusEffects.TDO_WarpDancerMoveSpeed_MK5Plus";
    case 6: return t"StatusEffects.TDO_WarpDancerMoveSpeed_MK5PlusPlus";
  }
  return TDBID.None();
}

public func TDO_WarpDancer_ApplyMoveSpeed(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  TDO_WarpDancer_RemoveMoveSpeed(player);
  let tier: Int32 = TDO_WarpDancer_GetEquippedTierIndex(player);
  if tier < 0 {
    return;
  }
  let seid: TweakDBID = TDO_WarpDancer_GetMoveSpeedSEID(tier);
  StatusEffectHelper.ApplyStatusEffect(player, seid);
}

public func TDO_WarpDancer_RemoveMoveSpeed(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_WarpDancerMoveSpeed_MK3");
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_WarpDancerMoveSpeed_MK3Plus");
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_WarpDancerMoveSpeed_MK4");
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_WarpDancerMoveSpeed_MK4Plus");
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_WarpDancerMoveSpeed_MK5");
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_WarpDancerMoveSpeed_MK5Plus");
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_WarpDancerMoveSpeed_MK5PlusPlus");
}

public func TDO_WarpDancer_ClearMovementLocks(player: ref<PlayerPuppet>) -> Void {
  TDO_Sandy_ClearMovementLocks(player);
}

public func TDO_WarpDancer_ClearMovementLocksThrottled(player: ref<PlayerPuppet>) -> Void {
  TDO_Sandy_ClearMovementLocksThrottled(player);
}

module TDO.Sandy

public func TDO_Falcon_GetEquippedTier(player: ref<PlayerPuppet>) -> Int32 {
  if !IsDefined(player) {
    return 0;
  }
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return 0;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return 0;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tdb: TweakDBID = ItemID.GetTDBID(itemID);
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK5PlusPlus") { return 5; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK5Plus") { return 4; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK5") { return 3; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK4Plus") { return 2; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK4") { return 1; }
    }
    slotIdx += 1;
  }
  return 0;
}

public func TDO_Falcon_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
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
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK4") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK4Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK5") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK5Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC4MK5PlusPlus") { return true; }
    }
    slotIdx += 1;
  }
  return false;
}

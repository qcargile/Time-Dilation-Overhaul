module TDO.Sandy

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

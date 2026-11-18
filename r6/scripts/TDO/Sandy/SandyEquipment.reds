module TDO.Sandy

@if(ModuleExists("CyberwareEx"))
import CyberwareEx.*

@if(!ModuleExists("CyberwareEx"))
public func TDO_Sandy_GetSelectedItem(player: ref<PlayerPuppet>) -> ItemID {
  if !IsDefined(player) {
    return ItemID.None();
  }
  let data: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(player);
  if !IsDefined(data) {
    return ItemID.None();
  }
  return data.GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
}

@if(ModuleExists("CyberwareEx"))
public func TDO_Sandy_GetSelectedItem(player: ref<PlayerPuppet>) -> ItemID {
  if !IsDefined(player) {
    return ItemID.None();
  }
  let data: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(player);
  if !IsDefined(data) {
    return ItemID.None();
  }
  return data.GetTaggedItem(gamedataEquipmentArea.SystemReplacementCW, n"Sandevistan");
}

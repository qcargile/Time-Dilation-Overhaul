module TDO.Sandy

@if(ModuleExists("CyberwareEx"))
import CyberwareEx.*

@if(!ModuleExists("CyberwareEx"))
private func TDO_WarpDancer_IsSelected(player: ref<PlayerPuppet>) -> Bool {
  let itemID: ItemID = EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
  return ItemID.IsValid(itemID) && TDO_WarpDancer_IsTDB(ItemID.GetTDBID(itemID));
}

@if(ModuleExists("CyberwareEx"))
private func TDO_WarpDancer_IsSelected(player: ref<PlayerPuppet>) -> Bool {
  let itemID: ItemID = EquipmentSystem.GetData(player).GetTaggedItem(gamedataEquipmentArea.SystemReplacementCW, n"Sandevistan");
  return ItemID.IsValid(itemID) && TDO_WarpDancer_IsTDB(ItemID.GetTDBID(itemID));
}

private func TDO_WarpDancer_BlocksDeadeyeTail(game: GameInstance, effector: ref<ApplyStatusEffectEffector>) -> Bool {
  let player: ref<PlayerPuppet> = GetPlayer(game);
  return IsDefined(player)
    && TDO_WarpDancer_IsSelected(player)
    && TDO_Sandy_OwnsCombatTime(player)
    && Equals(effector.GetRecord(), t"BaseStatusEffect.DeadeyeSE_inline9")
    && Equals(effector.m_targetEntityID, player.GetEntityID());
}

@wrapMethod(ApplyStatusEffectEffector)
protected func Uninitialize(game: GameInstance) -> Void {
  if TDO_WarpDancer_BlocksDeadeyeTail(game, this) {
    return;
  }
  wrappedMethod(game);
}

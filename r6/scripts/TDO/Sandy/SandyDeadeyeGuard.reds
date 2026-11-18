module TDO.Sandy

private func TDO_WarpDancer_BlocksDeadeyeTail(game: GameInstance, effector: ref<ApplyStatusEffectEffector>) -> Bool {
  let player: ref<PlayerPuppet> = GetPlayer(game);
  return IsDefined(player)
    && TDO_WarpDancer_IsEquipped(player)
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

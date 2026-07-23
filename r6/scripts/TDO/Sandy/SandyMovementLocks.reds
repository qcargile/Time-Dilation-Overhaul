module TDO.Sandy

@addField(PlayerPuppet)
public let m_tdoSandyLastLockClearTime: Float;

public func TDO_Sandy_ClearMovementLocks(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  StatusEffectHelper.RemoveAllStatusEffectsByType(player, gamedataStatusEffectType.Stunned);
  StatusEffectHelper.RemoveAllStatusEffectsByType(player, gamedataStatusEffectType.Stagger);
  StatusEffectHelper.RemoveAllStatusEffectsByType(player, gamedataStatusEffectType.Knockdown);
  player.m_tdoSandyLastLockClearTime = EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame()));
}

public func TDO_Sandy_ClearMovementLocksThrottled(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame()));
  if now - player.m_tdoSandyLastLockClearTime < TDOConfig.WarpDancerMovementLockClearIntervalSec() {
    return;
  }
  TDO_Sandy_ClearMovementLocks(player);
}

public func TDO_Sandy_ClearGutsLock(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  StatusEffectHelper.RemoveStatusEffect(player, t"BaseStatusEffect.EdgerunnersStun");
}

public func TDO_Sandy_ShouldClearGutsLock(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  if !TDOConfig.BulletTrailVelocityEnabled() {
    return false;
  }
  if !TDO_BulletTrailVelocity_IsSandyActive(player) {
    return false;
  }
  return StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.EdgerunnersStun");
}

@wrapMethod(SandevistanEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if TDO_Sandy_ShouldClearGutsLock(player) {
    TDO_Sandy_ClearGutsLock(player);
  }
}

module TDO.Sandy

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if !TDOConfig.WarpDancerEnabled() {
    return;
  }
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_WarpDancer_IsEquipped(player) {
    return;
  }
  if TDO_IsPlayerInVehicle(player) {
    return;
  }
  TDO_WarpDancer_Begin(player);
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if player.m_warpDancerPhase == 1 {
    TDO_WarpDancer_BeginRewind(player);
  }
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if player.m_warpDancerPhase != 0 {
    TDO_WarpDancer_Abort(player);
  }
}

@wrapMethod(PlayerPuppet)
protected func OnIncapacitated() -> Void {
  wrappedMethod();
  if this.m_warpDancerPhase != 0 {
    TDO_WarpDancer_Abort(this);
  }
}

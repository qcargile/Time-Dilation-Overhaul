module TDO.Sandy

@wrapMethod(DefaultTransition)
public final const func BlockAimingForTime(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>, const blockAimingFor: Float) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if TDO_Sandy_OwnsCombatTime(player) {
    let deadline: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(scriptInterface.GetGame())) + blockAimingFor;
    stateContext.SetPermanentFloatParameter(n"TDOBlockAimingTillEngineTime", deadline, true);
    wrappedMethod(stateContext, scriptInterface, 0.00);
    return;
  }
  stateContext.SetPermanentFloatParameter(n"TDOBlockAimingTillEngineTime", 0.00, true);
  wrappedMethod(stateContext, scriptInterface, blockAimingFor);
}

@wrapMethod(DefaultTransition)
protected final const func IsAimingBlockedForTime(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let deadline: Float = stateContext.GetFloatParameter(n"TDOBlockAimingTillEngineTime", true);
  if deadline > 0.00 {
    if EngineTime.ToFloat(GameInstance.GetEngineTime(scriptInterface.GetGame())) < deadline {
      return true;
    }
    stateContext.SetPermanentFloatParameter(n"TDOBlockAimingTillEngineTime", 0.00, true);
  }
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(SandevistanDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let deactivationTime: Float = stateContext.GetFloatParameter(n"SandevistanDeactivationTimeStamp", true);
  let gracePeriod: Float = TDOConfig.SandevistanGracePeriodSeconds();
  if scriptInterface.GetNow() < deactivationTime + gracePeriod {
    return false;
  };
  return wrappedMethod(stateContext, scriptInterface);
}

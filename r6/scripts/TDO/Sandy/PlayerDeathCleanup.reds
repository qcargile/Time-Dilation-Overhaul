module TDO.Sandy

import TDO.Logging.*

@wrapMethod(PlayerPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);

  let gi: GameInstance = this.GetGame();

  TimeDilationHelper.UnSetTimeDilation(this, n"TDOQuantumPlot", n"Linear");
  TimeDilationHelper.UnSetTimeDilationOnPlayer(this, n"TDOQuantumPlot", n"Linear");
  TimeDilationHelper.UnSetTimeDilation(this, n"WarpDancer", n"Linear");
  TimeDilationHelper.UnSetTimeDilation(this, n"TDOScannerTD", n"Linear");
  TimeDilationHelper.SetIgnoreTimeDilationOnLocalPlayerZero(this, false);

  let timeSys: ref<TimeSystem> = GameInstance.GetTimeSystem(gi);
  if IsDefined(timeSys) {
    timeSys.UnsetTimeDilationOnLocalPlayerZero(TimeDilationHelper.GetSandevistanKey(), n"");
  }

  TDOInfo("DeathCleanup", "unset all custom TD reasons on player death");
  return result;
}

module TDO.Sandy

import TDO.Logging.*
import TDO.Vehicle.*

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

  if this.m_warpDancerPhase != 0 {
    TDO_WarpDancer_Abort(this);
  }

  if this.m_tdoQPlotting {
    TDO_Quantum_EndPlot(this);
  }

  if this.m_tdoHerbieActive {
    TDO_Herbie_Disengage(this, gi);
  }

  this.TDO_DOT_Cancel();

  let i: Int32 = 0;
  while i < ArraySize(this.m_tdoTantoCritMarkedNPCs) {
    let npc: wref<NPCPuppet> = GameInstance.FindEntityByID(gi, this.m_tdoTantoCritMarkedNPCs[i]) as NPCPuppet;
    if IsDefined(npc) {
      StatusEffectHelper.RemoveStatusEffect(npc, t"StatusEffects.TDO_TantoCritChargeUsed");
    }
    i += 1;
  }
  ArrayClear(this.m_tdoTantoCritMarkedNPCs);
  this.m_tdoTantoIsBlocking = false;
  StatusEffectHelper.RemoveStatusEffect(this, t"StatusEffects.TDO_TantoTeleportCrit");

  this.m_tdoFusilladeRampHits = 0;
  this.m_tdoFusilladeShotInFlight = false;

  this.m_apogeeActivationCount = 0;
  this.m_apogeeLastActivationTime = 0.0;

  TDOInfo("DeathCleanup", "unset all custom TD reasons and reset attunement state on player death");
  return result;
}

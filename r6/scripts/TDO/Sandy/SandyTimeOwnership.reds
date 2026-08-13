module TDO.Sandy

import TDO.Logging.*

public class TDO_SandyCombatDilationCleanupEvent extends Event {}

public func TDO_Sandy_OwnsCombatTime(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  return TDO_Sandy_IsActive(player) || player.m_warpDancerPhase != 0;
}

public func TDO_Sandy_BlocksCombatDilation(reason: CName) -> Bool {
  return Equals(reason, n"kereznikov")
    || Equals(reason, n"focusMode")
    || Equals(reason, n"focusedStatePerkDilation")
    || Equals(reason, n"coolReloadPerkDilation")
    || Equals(reason, n"meleeHit")
    || Equals(reason, n"deflect")
    || Equals(reason, n"TDOScannerTD")
    || Equals(reason, n"EvasionStreak")
    || Equals(reason, n"NeurotagProtocol")
    || Equals(reason, n"OverclockDilation");
}

public func TDO_Sandy_ClearPSMState(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if IsDefined(bb) {
    bb.SetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation, 0, true);
    TDODebug("TimeOwner", "cleared Sandy PSM ownership state");
  }
}

public func TDO_Sandy_UnsetCombatDilation(player: ref<PlayerPuppet>, reason: CName) -> Void {
  let timeSystem: ref<TimeSystem> = GameInstance.GetTimeSystem(player.GetGame());
  if IsDefined(timeSystem) && timeSystem.IsTimeDilationActive(reason) {
    TDOTrace("TimeOwner", "preempted reason=" + ToString(reason));
    timeSystem.UnsetTimeDilation(reason, n"None");
  }
}

public func TDO_Sandy_PreemptCombatDilation(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  let timeSystem: ref<TimeSystem> = GameInstance.GetTimeSystem(player.GetGame());
  let evasionActive: Bool = IsDefined(timeSystem) && timeSystem.IsTimeDilationActive(n"EvasionStreak");
  TDO_Sandy_UnsetCombatDilation(player, n"kereznikov");
  TDO_Sandy_UnsetCombatDilation(player, n"focusMode");
  TDO_Sandy_UnsetCombatDilation(player, n"focusedStatePerkDilation");
  TDO_Sandy_UnsetCombatDilation(player, n"coolReloadPerkDilation");
  TDO_Sandy_UnsetCombatDilation(player, n"meleeHit");
  TDO_Sandy_UnsetCombatDilation(player, n"deflect");
  TDO_Sandy_UnsetCombatDilation(player, n"TDOScannerTD");
  TDO_Sandy_UnsetCombatDilation(player, n"EvasionStreak");
  TDO_Sandy_UnsetCombatDilation(player, n"NeurotagProtocol");
  TDO_Sandy_UnsetCombatDilation(player, n"OverclockDilation");

  if evasionActive {
    timeSystem.UnsetTimeDilationOnLocalPlayerZero(n"EvasionStreak", n"None");
  }
}

public func TDO_Sandy_QueueCombatDilationCleanup(player: ref<PlayerPuppet>) -> Void {
  if IsDefined(player) {
    GameInstance.GetDelaySystem(player.GetGame()).DelayEventNextFrame(player, new TDO_SandyCombatDilationCleanupEvent());
  }
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_SandyCombatDilationCleanupEvent(evt: ref<TDO_SandyCombatDilationCleanupEvent>) -> Bool {
  if TDO_Sandy_OwnsCombatTime(this) {
    TDO_Sandy_PreemptCombatDilation(this);
  }
  return true;
}

@wrapMethod(TimeDilationHelper)
public final static func SetTimeDilation(requester: wref<GameObject>, reason: CName, timeDilation: Float, opt duration: Float, easeInCurve: CName, easeOutCurve: CName, allowMultipleTimeDilationSimultaneously: Bool, opt listener: ref<TimeDilationListener>) -> Bool {
  let player: ref<PlayerPuppet> = requester as PlayerPuppet;
  if TDO_Sandy_OwnsCombatTime(player) && TDO_Sandy_BlocksCombatDilation(reason) {
    TDOTrace("TimeOwner", "blocked helper reason=" + ToString(reason));
    return false;
  }
  return wrappedMethod(requester, reason, timeDilation, duration, easeInCurve, easeOutCurve, allowMultipleTimeDilationSimultaneously, listener);
}

@wrapMethod(TimeDilationHelper)
public final static func SetTimeDilationOnPlayer(requester: wref<GameObject>, reason: CName, timeDilation: Float, opt duration: Float, easeInCurve: CName, easeOutCurve: CName, allowMultipleTimeDilationSimultaneously: Bool, opt listener: ref<TimeDilationListener>) -> Bool {
  let player: ref<PlayerPuppet> = requester as PlayerPuppet;
  if TDO_Sandy_OwnsCombatTime(player) && TDO_Sandy_BlocksCombatDilation(reason) {
    TDOTrace("TimeOwner", "blocked local helper reason=" + ToString(reason));
    return false;
  }
  return wrappedMethod(requester, reason, timeDilation, duration, easeInCurve, easeOutCurve, allowMultipleTimeDilationSimultaneously, listener);
}

@wrapMethod(SetTimeDilationEffector)
protected func ActionOn(owner: ref<GameObject>) -> Void {
  let player: ref<PlayerPuppet> = owner as PlayerPuppet;
  if IsDefined(player) && TDO_Sandy_OwnsCombatTime(player) && TDO_Sandy_BlocksCombatDilation(this.m_reason) {
    return;
  }
  wrappedMethod(owner);
}

@wrapMethod(PlayerPuppet)
protected cb func OnSetSlowMoForOnePunchAttackEvent(evt: ref<SetSlowMoForOnePunchAttackEvent>) -> Bool {
  if TDO_Sandy_OwnsCombatTime(this) {
    return false;
  }
  return wrappedMethod(evt);
}

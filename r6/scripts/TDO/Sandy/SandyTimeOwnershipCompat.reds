module TDO.Sandy

import TDO.Logging.*

@if(ModuleExists("MercProtocol"))
import MercProtocol.*

@if(ModuleExists("BlackBudget.TDOCompat"))
import BlackBudget.TDOCompat.*

public class TDO_SandyRestoreEvasionChargesEvent extends Event {}

@addField(PlayerPuppet)
public let m_tdoSuspendedEvasionCharges: Int32;

@addField(PlayerPuppet)
public let m_tdoEvasionChargesSuspended: Bool;

@wrapMethod(AimingStateEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  TDO_Sandy_SuspendEvasionStreak(player);
  wrappedMethod(stateContext, scriptInterface);
  if TDO_Sandy_OwnsCombatTime(player) {
    TDO_Sandy_PreemptCombatDilation(player);
    TDO_Sandy_QueueCombatDilationCleanup(player);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnMeleeHitSloMo(evt: ref<MeleeHitSlowMoEvent>) -> Bool {
  if TDO_Sandy_OwnsCombatTime(this) {
    return false;
  }
  return wrappedMethod(evt);
}

@if(ModuleExists("MercProtocol"))
public func TDO_Sandy_SuspendEvasionStreak(player: ref<PlayerPuppet>) -> Void {
  if TDO_Sandy_OwnsCombatTime(player) && !player.m_tdoEvasionChargesSuspended {
    player.m_tdoSuspendedEvasionCharges = player.mercProtocol_EvasionStreakCharges;
    player.m_tdoEvasionChargesSuspended = true;
    player.mercProtocol_EvasionStreakCharges = 0;
    TDOTrace("TimeOwner", "suspended Evasion Streak charges=" + ToString(player.m_tdoSuspendedEvasionCharges));
    GameInstance.GetDelaySystem(player.GetGame()).DelayEventNextFrame(player, new TDO_SandyRestoreEvasionChargesEvent());
  }
}

@if(!ModuleExists("MercProtocol"))
public func TDO_Sandy_SuspendEvasionStreak(player: ref<PlayerPuppet>) -> Void {}

@if(ModuleExists("MercProtocol"))
public func TDO_Sandy_RestoreEvasionStreak(player: ref<PlayerPuppet>) -> Void {
  if IsDefined(player) && player.m_tdoEvasionChargesSuspended {
    if player.IsInCombat() && player.GetMercProtocolPerkLevel(MercProtocolPerk.EvasionStreak) > 0 {
      player.mercProtocol_EvasionStreakCharges = player.m_tdoSuspendedEvasionCharges;
      TDOTrace("TimeOwner", "restored Evasion Streak charges=" + ToString(player.m_tdoSuspendedEvasionCharges));
    }
    player.m_tdoSuspendedEvasionCharges = 0;
    player.m_tdoEvasionChargesSuspended = false;
  }
}

@if(!ModuleExists("MercProtocol"))
public func TDO_Sandy_RestoreEvasionStreak(player: ref<PlayerPuppet>) -> Void {}

@if(ModuleExists("BlackBudget.TDOCompat"))
public func TDO_Sandy_CancelNeurotagTime(player: ref<PlayerPuppet>) -> Void {
  BlackBudget_CancelNeurotagTime(player);
}

@if(!ModuleExists("BlackBudget.TDOCompat"))
public func TDO_Sandy_CancelNeurotagTime(player: ref<PlayerPuppet>) -> Void {}

@addMethod(PlayerPuppet)
protected cb func OnTDO_SandyRestoreEvasionChargesEvent(evt: ref<TDO_SandyRestoreEvasionChargesEvent>) -> Bool {
  TDO_Sandy_RestoreEvasionStreak(this);
  return true;
}

@if(ModuleExists("OverclockOverheat"))
@wrapMethod(QuickHackableHelper)
public final static func TryToCycleOverclockedState(player: ref<GameObject>) -> Bool {
  let playerPuppet: ref<PlayerPuppet> = player as PlayerPuppet;
  if !TDO_Sandy_OwnsCombatTime(playerPuppet) || !IsDefined(playerPuppet.OVConfig) {
    return wrappedMethod(player);
  }
  let dilationEnabled: Bool = playerPuppet.OVConfig.ocDilation;
  playerPuppet.OVConfig.ocDilation = false;
  let result: Bool = wrappedMethod(player);
  playerPuppet.OVConfig.ocDilation = dilationEnabled;
  return result;
}

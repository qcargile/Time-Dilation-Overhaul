module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoDOTTickDelayID: DelayID;

public class TDO_SandyDOTTickEvent extends DelayEvent {}

public func TDO_DOT_GetActiveSandyRefStat(player: ref<PlayerPuppet>) -> gamedataStatType {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return gamedataStatType.Invalid;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return gamedataStatType.Invalid;
  }
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(player.GetGame());
  if !IsDefined(ts) {
    return gamedataStatType.Invalid;
  }

  let strongestRefStat: gamedataStatType = gamedataStatType.Invalid;
  let strongestTS: Float = 2.0;
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let itemData: ref<gameItemData> = ts.GetItemData(player, itemID);
      if IsDefined(itemData) {
        let itemTS: Float = itemData.GetStatValueByType(gamedataStatType.TimeDilationSandevistanTimeScale);
        if itemTS > 0.0 && itemTS < 1.0 {
          let tdb: TweakDBID = ItemID.GetTDBID(itemID);
          let mappedRefStat: gamedataStatType;
          let mappedMultiplier: Float;
          let thisRefStat: gamedataStatType;
          if TDO_Attunement_GetScaling(tdb, mappedRefStat, mappedMultiplier) {
            thisRefStat = mappedRefStat;
          } else {
            thisRefStat = gamedataStatType.Reflexes;
          }
          if itemTS < strongestTS {
            strongestTS = itemTS;
            strongestRefStat = thisRefStat;
          }
        }
      }
    }
    slotIdx += 1;
  }
  return strongestRefStat;
}

public func TDO_DOT_ComputeTickInterval(slowPct: Float) -> Float {
  let minInterval: Float = TDOConfig.DOTTickMinInterval();
  let maxInterval: Float = TDOConfig.DOTTickMaxInterval();
  let rangeMin: Float = TDOConfig.DOTSlowRangeMinPct();
  let rangeMax: Float = TDOConfig.DOTSlowRangeMaxPct();
  let span: Float = rangeMax - rangeMin;
  if span <= 0.0 {
    return maxInterval;
  }
  let clamped: Float = MinF(MaxF((slowPct - rangeMin) / span, 0.0), 1.0);
  return maxInterval - clamped * (maxInterval - minInterval);
}

public func TDO_DOT_ComputeMitigation(player: ref<PlayerPuppet>, refStat: gamedataStatType) -> Float {
  if Equals(refStat, gamedataStatType.Invalid) {
    return 0.0;
  }
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let refValue: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), refStat);
  let cap: Float = TDOConfig.DOTMitigationCap();
  let refCap: Float = TDOConfig.DOTMitigationRefStatCap();
  if refCap <= 0.0 {
    return 0.0;
  }
  return MinF(refValue / refCap, 1.0) * cap;
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_SandyDOTTickEvent(evt: ref<TDO_SandyDOTTickEvent>) -> Bool {
  this.m_tdoDOTTickDelayID = GetInvalidDelayID();
  if !TDOConfig.DOTEnabled() {
    return false;
  }

  let bb: ref<IBlackboard> = this.GetPlayerStateMachineBlackboard();
  if IsDefined(bb) {
    let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
    if td != EnumInt(gamePSMTimeDilation.Sandevistan) {
      TDODebug("DOT", "tick saw PSM != Sandevistan, self-terminating");
      return false;
    }
  }

  if this.m_warpDancerPhase != 0 {
    this.TDO_DOT_Reschedule(TDOConfig.DOTTickMaxInterval());
    return true;
  }

  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  let playerID: StatsObjectID = Cast<StatsObjectID>(this.GetEntityID());

  let hasSandy: Float = stats.GetStatValue(playerID, gamedataStatType.HasSandevistan);
  if hasSandy <= 0.0 {
    return false;
  }
  let timeScale: Float = stats.GetStatValue(playerID, gamedataStatType.TimeDilationSandevistanTimeScale);
  if timeScale <= 0.0 || timeScale >= 1.0 {
    return false;
  }
  let slowPct: Float = (1.0 - timeScale) * 100.0;
  let nextInterval: Float = TDO_DOT_ComputeTickInterval(slowPct);

  if slowPct < TDOConfig.DOTSlowThresholdPct() {
    TDOTrace("DOTTick", "below slow threshold slowPct=" + ToString(slowPct) + " thr=" + ToString(TDOConfig.DOTSlowThresholdPct()));
    this.TDO_DOT_Reschedule(nextInterval);
    return true;
  }

  let maxHP: Float = stats.GetStatValue(playerID, gamedataStatType.Health);
  let baseDOT: Float = maxHP * TDOConfig.DOTBaseRatePct() / 100.0;
  let refStat: gamedataStatType = TDO_DOT_GetActiveSandyRefStat(this);
  let mitigation: Float = TDO_DOT_ComputeMitigation(this, refStat);
  let strainMultiplier: Float = TDO_Apogee_GetDOTMultiplier(this);
  let damage: Float = baseDOT * (1.0 - mitigation) * strainMultiplier;
  TDOTrace("DOTTick", "slowPct=" + ToString(slowPct) + " base=" + ToString(baseDOT) + " mitigation=" + ToString(mitigation) + " strain=" + ToString(strainMultiplier) + " damage=" + ToString(damage));

  if damage > 0.0 {
    let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
    let currentHealth: Float = pools.GetStatPoolValue(playerID, gamedataStatPoolType.Health, false);
    let applied: Float = damage;
    if !TDOConfig.DOTCanKill() && currentHealth - damage < 1.0 {
      applied = MaxF(currentHealth - 1.0, 0.0);
    }
    if applied > 0.0 {
      pools.RequestChangingStatPoolValue(playerID, gamedataStatPoolType.Health, -applied, null, false);
    }
  }

  this.TDO_DOT_Reschedule(nextInterval);
  return true;
}

@addMethod(PlayerPuppet)
public final func TDO_DOT_Reschedule(interval: Float) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  if this.m_tdoDOTTickDelayID != GetInvalidDelayID() {
    delaySys.CancelDelay(this.m_tdoDOTTickDelayID);
  }
  let evt: ref<TDO_SandyDOTTickEvent> = new TDO_SandyDOTTickEvent();
  this.m_tdoDOTTickDelayID = delaySys.DelayEvent(this, evt, interval, false);
}

@addMethod(PlayerPuppet)
public final func TDO_DOT_Cancel() -> Void {
  if this.m_tdoDOTTickDelayID != GetInvalidDelayID() {
    GameInstance.GetDelaySystem(this.GetGame()).CancelDelay(this.m_tdoDOTTickDelayID);
    this.m_tdoDOTTickDelayID = GetInvalidDelayID();
  }
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if !TDOConfig.DOTEnabled() {
    return;
  }
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let timeScale: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.TimeDilationSandevistanTimeScale);
  let slowPct: Float = (1.0 - timeScale) * 100.0;
  player.TDO_DOT_Reschedule(TDO_DOT_ComputeTickInterval(slowPct));
  TDOInfo("DOT", "armed slowPct=" + ToString(slowPct));
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  player.TDO_DOT_Cancel();
  TDODebug("DOT", "disarmed on Sandy exit");
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  player.TDO_DOT_Cancel();
  TDODebug("DOT", "disarmed on Sandy forced exit");
}

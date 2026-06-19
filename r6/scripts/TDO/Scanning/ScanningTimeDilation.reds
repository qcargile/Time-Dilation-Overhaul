module TDO.Scanning

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoScanCharge: Float;

@addField(PlayerPuppet)
public let m_tdoScanTDActive: Bool;

@addField(PlayerPuppet)
public let m_tdoScanTickID: DelayID;

@addField(PlayerPuppet)
public let m_tdoScanVisListener: ref<CallbackHandle>;

@addField(PlayerPuppet)
public let m_tdoScanBar: ref<TDO_ScanningBar>;

@addField(PlayerPuppet)
public let m_tdoScanLockedOut: Bool;

@addField(PlayerPuppet)
public let m_tdoScanGraceTimer: Float;

@addField(PlayerPuppet)
public let m_tdoScanGraceActive: Bool;

public func TDO_Scanning_ComputeStrength(player: ref<PlayerPuppet>) -> Float {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let intel: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Intelligence);
  let t: Float = ClampF(intel / 20.0, 0.0, 1.0); // max Intelligence
  return LerpF(t, TDOConfig.ScanningStrengthAtMinInt(), TDOConfig.ScanningStrengthAtMaxInt());
}

public func TDO_Scanning_IntScale(player: ref<PlayerPuppet>) -> Float {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let intel: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Intelligence);
  let t: Float = ClampF(intel / 20.0, 0.0, 1.0); // max Intelligence
  return LerpF(t, 1.0, TDOConfig.ScanningIntScaleMax());
}

public func TDO_Scanning_IsScannerOpen(gi: GameInstance) -> Bool {
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_Scanner);
  if !IsDefined(bb) {
    return false;
  }
  return bb.GetBool(GetAllBlackboardDefs().UI_Scanner.UIVisible);
}

public func TDO_Scanning_IsLookingAtScannable(gi: GameInstance) -> Bool {
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_Scanner);
  if !IsDefined(bb) {
    return false;
  }
  let scanned: EntityID = bb.GetEntityID(GetAllBlackboardDefs().UI_Scanner.ScannedObject);
  return EntityID.IsDefined(scanned);
}

public class TDO_ScanningTick extends DelayCallback {

  public let m_playerID: EntityID;

  public func Call() -> Void {
    let gi: GameInstance = GetGameInstance();
    let player: ref<PlayerPuppet> = GameInstance.FindEntityByID(gi, this.m_playerID) as PlayerPuppet;
    if !IsDefined(player) {
      return;
    }
    player.m_tdoScanTickID = GetInvalidDelayID();

    if !TDOConfig.ScanningEnabled() {
      if player.m_tdoScanTDActive {
        TimeDilationHelper.UnSetTimeDilation(player, n"TDOScannerTD", n"Linear");
        player.m_tdoScanTDActive = false;
        TDOInfo("ScanningTD", "TD OFF (feature disabled)");
      }
      if IsDefined(player.m_tdoScanBar) {
        player.m_tdoScanBar.Update(player.m_tdoScanCharge, false);
      }
      return;
    }

    let scannerOpen: Bool = TDO_Scanning_IsScannerOpen(gi);

    if scannerOpen {
      let step: Float = TDOConfig.ScanningTickInterval();
      let intScale: Float = TDO_Scanning_IntScale(player);
      let onTarget: Bool = TDO_Scanning_IsLookingAtScannable(gi);

      if onTarget {
        player.m_tdoScanGraceActive = true;
        player.m_tdoScanGraceTimer = 0.0;
      } else {
        if player.m_tdoScanGraceActive {
          player.m_tdoScanGraceTimer += step;
          if player.m_tdoScanGraceTimer >= TDOConfig.ScanningGracePeriodSec() {
            player.m_tdoScanGraceActive = false;
          }
        }
      }

      let effectivelyOnTarget: Bool = onTarget || player.m_tdoScanGraceActive;
      let hasResource: Bool = !player.m_tdoScanLockedOut && player.m_tdoScanCharge > 0.0;
      let wantTD: Bool = effectivelyOnTarget && hasResource;

      if wantTD {
        if !player.m_tdoScanTDActive {
          TimeDilationHelper.SetTimeDilation(player, n"TDOScannerTD", TDO_Scanning_ComputeStrength(player), 999.0, n"Linear", n"Linear", true);
          player.m_tdoScanTDActive = true;
          TDOInfo("ScanningTD", "TD ON");
        }
      } else {
        if player.m_tdoScanTDActive {
          TimeDilationHelper.UnSetTimeDilation(player, n"TDOScannerTD", n"Linear");
          player.m_tdoScanTDActive = false;
          TDOInfo("ScanningTD", "TD OFF");
        }
      }

      if player.m_tdoScanTDActive {
        player.m_tdoScanCharge -= (TDOConfig.ScanningDrainPerSec() / intScale) * step;
      } else {
        player.m_tdoScanCharge += (TDOConfig.ScanningRechargePerSec() * intScale) * step;
      }
      player.m_tdoScanCharge = ClampF(player.m_tdoScanCharge, 0.0, 1.0);

      if player.m_tdoScanCharge <= 0.0 {
        player.m_tdoScanLockedOut = true;
      }
      if player.m_tdoScanLockedOut && player.m_tdoScanCharge >= 1.0 {
        player.m_tdoScanLockedOut = false;
      }

      if !IsDefined(player.m_tdoScanBar) {
        player.m_tdoScanBar = new TDO_ScanningBar();
      }
      player.m_tdoScanBar.EnsureCreated();
      player.m_tdoScanBar.Update(player.m_tdoScanCharge, true);

      TDO_Scanning_ArmTick(player, TDOConfig.ScanningTickInterval());
    } else {
      if player.m_tdoScanTDActive {
        TimeDilationHelper.UnSetTimeDilation(player, n"TDOScannerTD", n"Linear");
        player.m_tdoScanTDActive = false;
        TDOInfo("ScanningTD", "TD OFF (scanner closed)");
      }
      player.m_tdoScanGraceActive = false;
      player.m_tdoScanGraceTimer = 0.0;

      if player.m_tdoScanCharge < 1.0 {
        let step: Float = 0.5; // slow recharge heartbeat interval while scanner closed
        player.m_tdoScanCharge += (TDOConfig.ScanningRechargePerSec() * TDO_Scanning_IntScale(player)) * step;
        player.m_tdoScanCharge = ClampF(player.m_tdoScanCharge, 0.0, 1.0);
        if player.m_tdoScanLockedOut && player.m_tdoScanCharge >= 1.0 {
          player.m_tdoScanLockedOut = false;
        }
        if IsDefined(player.m_tdoScanBar) {
          player.m_tdoScanBar.Update(player.m_tdoScanCharge, false);
        }
        TDO_Scanning_ArmTick(player, step);
      } else {
        if IsDefined(player.m_tdoScanBar) {
          player.m_tdoScanBar.Update(player.m_tdoScanCharge, false);
        }
      }
    }
  }
}

public func TDO_Scanning_ArmTick(player: ref<PlayerPuppet>, interval: Float) -> Void {
  let ds: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_tdoScanTickID != GetInvalidDelayID() {
    ds.CancelDelay(player.m_tdoScanTickID);
  }
  let tick: ref<TDO_ScanningTick> = new TDO_ScanningTick();
  tick.m_playerID = player.GetEntityID();
  player.m_tdoScanTickID = ds.DelayCallback(tick, interval, false);
}

public class TDO_ScanningSetup extends DelayCallback {

  public let m_playerID: EntityID;

  public func Call() -> Void {
    let gi: GameInstance = GetGameInstance();
    let player: ref<PlayerPuppet> = GameInstance.FindEntityByID(gi, this.m_playerID) as PlayerPuppet;
    if !IsDefined(player) {
      return;
    }
    if IsDefined(player.m_tdoScanVisListener) {
      return;
    }
    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_Scanner);
    if IsDefined(bb) {
      player.m_tdoScanVisListener = bb.RegisterListenerBool(GetAllBlackboardDefs().UI_Scanner.UIVisible, player, n"OnTDOScannerVisibleChanged", true);
    }
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  wrappedMethod();
  this.m_tdoScanCharge = 1.0;
  this.m_tdoScanTDActive = false;
  this.m_tdoScanLockedOut = false;
  this.m_tdoScanGraceTimer = 0.0;
  this.m_tdoScanGraceActive = false;
  this.m_tdoScanTickID = GetInvalidDelayID();
  this.m_tdoScanVisListener = null;
  let setup: ref<TDO_ScanningSetup> = new TDO_ScanningSetup();
  setup.m_playerID = this.GetEntityID();
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(setup, 1.0, false); // defer listener registration until UI blackboards are ready, one-shot
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  let result: Bool = wrappedMethod();
  if IsDefined(this.m_tdoScanVisListener) {
    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Scanner);
    if IsDefined(bb) {
      bb.UnregisterListenerBool(GetAllBlackboardDefs().UI_Scanner.UIVisible, this.m_tdoScanVisListener);
    }
    this.m_tdoScanVisListener = null;
  }
  return result;
}

@addMethod(PlayerPuppet)
protected cb func OnTDOScannerVisibleChanged(visible: Bool) -> Bool {
  if visible && TDOConfig.ScanningEnabled() {
    TDO_Scanning_ArmTick(this, TDOConfig.ScanningTickInterval());
  }
  return true;
}

@wrapMethod(TimeDilationFocusModeDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if TDOConfig.ScanningEnabled() {
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

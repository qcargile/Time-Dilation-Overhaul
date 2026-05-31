module TDO.Scanning

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoScanCharge: Float;

@addField(PlayerPuppet)
public let m_tdoScanTDActive: Bool;

@addField(PlayerPuppet)
public let m_tdoScanTickScheduled: Bool;

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

  public let m_player: ref<PlayerPuppet>;

  public func Call() -> Void {
    let player: ref<PlayerPuppet> = this.m_player;
    if !IsDefined(player) {
      return;
    }
    let gi: GameInstance = player.GetGame();

    if !TDOConfig.ScanningEnabled() {
      if player.m_tdoScanTDActive {
        TimeDilationHelper.UnSetTimeDilation(player, n"TDOScannerTD", n"Linear");
        player.m_tdoScanTDActive = false;
        TDOInfo("ScanningTD", "TD OFF (feature disabled)");
      }
      if IsDefined(player.m_tdoScanBar) {
        player.m_tdoScanBar.Update(player.m_tdoScanCharge, false);
      }
    } else {
      let step: Float = TDOConfig.ScanningTickInterval();
      let intScale: Float = TDO_Scanning_IntScale(player);

      let scannerOpen: Bool = TDO_Scanning_IsScannerOpen(gi);
      let onTarget: Bool = scannerOpen && TDO_Scanning_IsLookingAtScannable(gi);

      if !scannerOpen {
        player.m_tdoScanGraceActive = false;
        player.m_tdoScanGraceTimer = 0.0;
      } else {
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
      }

      let effectivelyOnTarget: Bool = onTarget || (scannerOpen && player.m_tdoScanGraceActive);
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
      player.m_tdoScanBar.Update(player.m_tdoScanCharge, scannerOpen);
    }

    let next: ref<TDO_ScanningTick> = new TDO_ScanningTick();
    next.m_player = player;
    GameInstance.GetDelaySystem(gi).DelayCallback(next, TDOConfig.ScanningTickInterval(), false);
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
  if !this.m_tdoScanTickScheduled {
    this.m_tdoScanTickScheduled = true;
    let tick: ref<TDO_ScanningTick> = new TDO_ScanningTick();
    tick.m_player = this;
    GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(tick, TDOConfig.ScanningTickInterval(), false);
  }
}

@wrapMethod(TimeDilationFocusModeDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if TDOConfig.ScanningEnabled() {
    return false;
  }
  return wrappedMethod(stateContext, scriptInterface);
}

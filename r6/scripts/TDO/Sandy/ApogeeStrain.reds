module TDO.Sandy

import TDO.Logging.*
import TDO.Vehicle.*

public func TDO_Apogee_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return false;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return false;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tdb: TweakDBID = ItemID.GetTDBID(itemID);
      if Equals(tdb, t"Items.AdvancedSandevistanApogee") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanApogeePlus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanApogeePlusPlus") { return true; }
    }
    slotIdx += 1;
  }
  return false;
}

@addField(PlayerPuppet)
public let m_tdoApogeeActive: Bool;

@addField(PlayerPuppet)
public let m_tdoApogeeStillElapsed: Float;

@addField(PlayerPuppet)
public let m_tdoApogeeTickID: DelayID;

@addField(PlayerPuppet)
public let m_tdoApogeeLastCamFwd: Vector4;

@addField(PlayerPuppet)
public let m_tdoApogeeLastFireTime: Float;

@addField(PlayerPuppet)
public let m_tdoApogeeShootCB: ref<CallbackHandle>;

public func TDO_Apogee_GetDOTMultiplier(player: ref<PlayerPuppet>) -> Float {
  if !IsDefined(player) {
    return 1.0;
  }
  if !TDOConfig.ApogeeEnabled() {
    return 1.0;
  }
  if !player.m_tdoApogeeActive {
    return 1.0;
  }
  return 0.0;
}

public func TDO_Apogee_IsActiveMovementState(loco: Int32) -> Bool {
  return loco == EnumInt(gamePSMLocomotionStates.Sprint)
    || loco == EnumInt(gamePSMLocomotionStates.Jump)
    || loco == EnumInt(gamePSMLocomotionStates.Vault)
    || loco == EnumInt(gamePSMLocomotionStates.Dodge)
    || loco == EnumInt(gamePSMLocomotionStates.DodgeAir)
    || loco == EnumInt(gamePSMLocomotionStates.Slide)
    || loco == EnumInt(gamePSMLocomotionStates.SlideFall)
    || loco == EnumInt(gamePSMLocomotionStates.CrouchSprint)
    || loco == EnumInt(gamePSMLocomotionStates.CrouchDodge);
}

public func TDO_Apogee_IsControlLost(player: ref<PlayerPuppet>) -> Bool {
  return StatusEffectSystem.ObjectHasStatusEffectOfType(player, gamedataStatusEffectType.Knockdown)
    || StatusEffectSystem.ObjectHasStatusEffectOfType(player, gamedataStatusEffectType.Stunned);
}

public class TDO_ApogeeTickEvent extends DelayEvent {}

@addMethod(PlayerPuppet)
protected cb func OnTDOApogeeShoot(value: Variant) -> Bool {
  if this.m_tdoApogeeActive {
    this.m_tdoApogeeLastFireTime = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGame()));
    TimeDilationHelper.SetTimeDilation(this, n"sandevistan", 1.0 - TDOConfig.ApogeeActionSlowPct() / 100.0, 999.0, n"None", n"None", true);
  }
  return true;
}

@addMethod(PlayerPuppet)
public final func TDO_Apogee_RegisterShoot() -> Void {
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_ActiveWeaponData);
  if IsDefined(bb) {
    this.m_tdoApogeeShootCB = bb.RegisterListenerVariant(GetAllBlackboardDefs().UI_ActiveWeaponData.ShootEvent, this, n"OnTDOApogeeShoot");
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Apogee_UnregisterShoot() -> Void {
  if IsDefined(this.m_tdoApogeeShootCB) {
    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_ActiveWeaponData);
    if IsDefined(bb) {
      bb.UnregisterListenerVariant(GetAllBlackboardDefs().UI_ActiveWeaponData.ShootEvent, this.m_tdoApogeeShootCB);
    }
    this.m_tdoApogeeShootCB = null;
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Apogee_ScheduleTick() -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  if this.m_tdoApogeeTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(this.m_tdoApogeeTickID);
  }
  let evt: ref<TDO_ApogeeTickEvent> = new TDO_ApogeeTickEvent();
  this.m_tdoApogeeTickID = delaySys.DelayEvent(this, evt, TDOConfig.ApogeeTickInterval(), false);
}

@addMethod(PlayerPuppet)
public final func TDO_Apogee_CancelTick() -> Void {
  if this.m_tdoApogeeTickID != GetInvalidDelayID() {
    GameInstance.GetDelaySystem(this.GetGame()).CancelDelay(this.m_tdoApogeeTickID);
    this.m_tdoApogeeTickID = GetInvalidDelayID();
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Apogee_Disarm() -> Void {
  this.m_tdoApogeeActive = false;
  this.m_tdoApogeeStillElapsed = 0.0;
  this.m_tdoApogeeLastFireTime = 0.0;
  this.TDO_Apogee_CancelTick();
  this.TDO_Apogee_UnregisterShoot();
  TimeDilationHelper.UnSetTimeDilation(this, n"sandevistan", n"None");
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_ApogeeTickEvent(evt: ref<TDO_ApogeeTickEvent>) -> Bool {
  this.m_tdoApogeeTickID = GetInvalidDelayID();
  if !this.m_tdoApogeeActive {
    return false;
  }
  if !TDOConfig.ApogeeEnabled() {
    this.TDO_Apogee_Disarm();
    return false;
  }

  let bb: ref<IBlackboard> = this.GetPlayerStateMachineBlackboard();
  if IsDefined(bb) {
    let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
    if td != EnumInt(gamePSMTimeDilation.Sandevistan) {
      TDODebug("Apogee", "tick saw PSM != Sandevistan, self-terminating");
      this.TDO_Apogee_Disarm();
      return false;
    }
  }

  if TDO_IsPlayerInVehicle(this) {
    TDODebug("Apogee", "tick saw player in vehicle, disarming");
    this.TDO_Apogee_Disarm();
    return false;
  }

  let gi: GameInstance = this.GetGame();
  let playerID: StatsObjectID = Cast<StatsObjectID>(this.GetEntityID());
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
  let tickInterval: Float = TDOConfig.ApogeeTickInterval();
  let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));

  let speed: Float = Vector4.Length2D(this.GetVelocity());
  let loco: Int32 = 0;
  let upperBody: Int32 = 0;
  let melee: Int32 = 0;
  if IsDefined(bb) {
    loco = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion);
    upperBody = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody);
    melee = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon);
  }

  let camMoved: Bool = false;
  let camSys: ref<CameraSystem> = GameInstance.GetCameraSystem(gi);
  if IsDefined(camSys) {
    let camFwd: Vector4 = camSys.GetActiveCameraForward();
    camMoved = Vector4.Distance(camFwd, this.m_tdoApogeeLastCamFwd) > TDOConfig.ApogeeCamLookThreshold();
    this.m_tdoApogeeLastCamFwd = camFwd;
  }

  let recentlyFired: Bool = (now - this.m_tdoApogeeLastFireTime) < TDOConfig.ApogeeFireWindow();

  let isAct: Bool = speed >= TDOConfig.ApogeeMoveThreshold()
    || TDO_Apogee_IsActiveMovementState(loco)
    || recentlyFired
    || (melee >= EnumInt(gamePSMMeleeWeapon.ComboAttack) && melee < EnumInt(gamePSMMeleeWeapon.Default));
  let isAim: Bool = upperBody == EnumInt(gamePSMUpperBodyStates.Aim)
    || melee == EnumInt(gamePSMMeleeWeapon.Block);

  let ctrlLost: Bool = TDO_Apogee_IsControlLost(this);
  let slowPct: Float;
  if ctrlLost {
    slowPct = 0.0;
  } else {
    if isAct {
      slowPct = TDOConfig.ApogeeActionSlowPct();
    } else {
      if isAim {
        slowPct = TDOConfig.ApogeeAimSlowPct();
      } else {
        if camMoved {
          slowPct = TDOConfig.ApogeeCamLookSlowPct();
        } else {
          slowPct = TDOConfig.ApogeeStillSlowPct();
        }
      }
    }
  }
  let timescale: Float = 1.0 - slowPct / 100.0;
  TimeDilationHelper.SetTimeDilation(this, n"sandevistan", timescale, 999.0, n"None", n"None", true);

  if pools.GetStatPoolValue(playerID, gamedataStatPoolType.SandevistanCharge, true) < TDOConfig.ApogeeChargeRefillThreshold() {
    pools.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.SandevistanCharge, 100.0, null, true);
  }

  if isAct || ctrlLost {
    this.m_tdoApogeeStillElapsed = 0.0;
  } else {
    if !isAim {
      this.m_tdoApogeeStillElapsed += tickInterval;
    }
  }

  let reflexes: Float = stats.GetStatValue(playerID, gamedataStatType.Reflexes);
  let graceEff: Float = MinF(TDOConfig.ApogeeStrainGrace() + reflexes * TDOConfig.ApogeeStrainReflexGraceScale(), TDOConfig.ApogeeStrainGraceCap());
  let rampEff: Float = TDOConfig.ApogeeStrainRampDuration();
  if !isAim && this.m_tdoApogeeStillElapsed > graceEff && rampEff > 0.0 {
    let t: Float = MinF(MaxF((this.m_tdoApogeeStillElapsed - graceEff) / rampEff, 0.0), 1.0);
    let restingHP: Float = stats.GetStatValue(playerID, gamedataStatType.Health);
    let damage: Float = t * (TDOConfig.ApogeeStrainCapPctPerSec() / 100.0) * restingHP * tickInterval;
    if damage > 0.0 {
      let currentHealth: Float = pools.GetStatPoolValue(playerID, gamedataStatPoolType.Health, false);
      let applied: Float = damage;
      if !TDOConfig.ApogeeStrainCanKill() && currentHealth - damage < 1.0 {
        applied = MaxF(currentHealth - 1.0, 0.0);
      }
      if applied > 0.0 {
        pools.RequestChangingStatPoolValue(playerID, gamedataStatPoolType.Health, -applied, null, false);
      }
    }
  }

  this.TDO_Apogee_ScheduleTick();
  return true;
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if !TDOConfig.ApogeeEnabled() {
    return;
  }
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_Apogee_IsEquipped(player) {
    return;
  }
  if TDO_IsPlayerInVehicle(player) {
    return;
  }
  player.m_tdoApogeeActive = true;
  player.m_tdoApogeeStillElapsed = 0.0;
  player.m_tdoApogeeLastFireTime = EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame())) - 10.0;
  let camSys: ref<CameraSystem> = GameInstance.GetCameraSystem(player.GetGame());
  if IsDefined(camSys) {
    player.m_tdoApogeeLastCamFwd = camSys.GetActiveCameraForward();
  }
  player.TDO_Apogee_RegisterShoot();
  player.TDO_Apogee_ScheduleTick();
  TDOInfo("Apogee", "Stillpoint armed");
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_tdoApogeeActive {
    player.TDO_Apogee_Disarm();
    TDODebug("Apogee", "Stillpoint disarmed on Sandy exit");
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_tdoApogeeActive {
    player.TDO_Apogee_Disarm();
    TDODebug("Apogee", "Stillpoint disarmed on Sandy forced exit");
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(PlayerPuppet)
protected func OnIncapacitated() -> Void {
  if this.m_tdoApogeeActive {
    this.TDO_Apogee_Disarm();
  }
  wrappedMethod();
}

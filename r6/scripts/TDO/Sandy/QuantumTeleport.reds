module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoQPlotting: Bool;

@addField(PlayerPuppet)
public let m_tdoQMappinID: NewMappinID;

@addField(PlayerPuppet)
public let m_tdoQMappinActive: Bool;

@addField(PlayerPuppet)
public let m_tdoQPlotTickID: DelayID;

@addField(PlayerPuppet)
public let m_tdoQDestValid: Bool;

@addField(PlayerPuppet)
public let m_tdoQDest: Vector4;

@addField(PlayerPuppet)
public let m_tdoQDestRot: EulerAngles;

public class TDO_QuantumPlotTickEvent extends DelayEvent {}

public func TDO_Quantum_GetTeleportRangeBase(player: ref<PlayerPuppet>) -> Float {
  return TDOConfig.LerpTier(TDOConfig.QuantumTeleportRangeMin(), TDOConfig.QuantumTeleportRangeMax(), TDO_Quantum_GetTier(player), 5);
}

public func TDO_Quantum_GetTeleportRange(player: ref<PlayerPuppet>) -> Float {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let cool: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Cool);
  let range: Float = TDO_Quantum_GetTeleportRangeBase(player) + cool * TDOConfig.QuantumTeleportRangePerCool();
  let cap: Float = TDOConfig.QuantumTeleportMaxRange();
  if range > cap {
    range = cap;
  }
  return range;
}

public func TDO_Quantum_LevelFacing(player: ref<PlayerPuppet>, camFwd: Vector4) -> EulerAngles {
  let flat: Vector4 = camFwd;
  flat.Z = 0.0;
  if Vector4.Length(flat) < 0.01 {
    flat = player.GetWorldForward();
    flat.Z = 0.0;
  }
  flat = Vector4.Normalize(flat);
  return Vector4.ToRotation(flat);
}

public func TDO_Quantum_SchedulePlotTick(player: ref<PlayerPuppet>) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_tdoQPlotTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_tdoQPlotTickID);
  }
  let evt: ref<TDO_QuantumPlotTickEvent> = new TDO_QuantumPlotTickEvent();
  player.m_tdoQPlotTickID = delaySys.DelayEvent(player, evt, TDOConfig.QuantumPlotTickInterval(), false);
}

public func TDO_Quantum_SpawnWarpFx(player: ref<PlayerPuppet>, pos: Vector4) -> ref<FxInstance> {
  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if !IsDefined(fxSystem) {
    return null;
  }
  let raRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(raRef, r"base\\fx\\quest\\q110\\transition_glitch_fx_intro_outro.effect");
  let fxRes: FxResource;
  fxRes.effect = raRef;
  let wp: WorldPosition;
  WorldPosition.SetVector4(wp, pos);
  let transform: WorldTransform;
  WorldTransform.SetWorldPosition(transform, wp);
  WorldTransform.SetOrientationFromDir(transform, player.GetWorldForward());
  return fxSystem.SpawnEffect(fxRes, transform, true);
}

public func TDO_Quantum_UpdateMarker(player: ref<PlayerPuppet>, pos: Vector4) -> Void {
  if TDOConfig.UIShouldHideQuantumMarker() {
    TDO_Quantum_ClearMarker(player);
    return;
  }
  let ms: ref<MappinSystem> = GameInstance.GetMappinSystem(player.GetGame());
  if !IsDefined(ms) {
    return;
  }
  if player.m_tdoQMappinActive {
    ms.SetMappinPosition(player.m_tdoQMappinID, pos);
    return;
  }
  let md: MappinData;
  md.mappinType = t"Mappins.DefaultStaticMappin";
  md.variant = gamedataMappinVariant.DistractVariant;
  md.active = true;
  md.visibleThroughWalls = true;
  player.m_tdoQMappinID = ms.RegisterMappin(md, pos);
  player.m_tdoQMappinActive = true;
}

public func TDO_Quantum_ClearMarker(player: ref<PlayerPuppet>) -> Void {
  if player.m_tdoQMappinActive {
    let ms: ref<MappinSystem> = GameInstance.GetMappinSystem(player.GetGame());
    if IsDefined(ms) {
      ms.UnregisterMappin(player.m_tdoQMappinID);
    }
    let invalidMappinID: NewMappinID;
    player.m_tdoQMappinID = invalidMappinID;
    player.m_tdoQMappinActive = false;
  }
}

public class TDO_QuantumLandingSoundCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    let p: ref<PlayerPuppet> = this.player;
    if !IsDefined(p) {
      return;
    }
    GameObject.PlaySoundEvent(p, n"grenade_emp");
  }
}

public func TDO_Quantum_BeginPlot(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) || player.m_tdoQPlotting {
    return;
  }
  if TDO_IsPlayerInVehicle(player) {
    return;
  }
  player.m_tdoQPlotting = true;
  player.m_tdoQDestValid = false;

  let strength: Float = TDOConfig.QuantumPlotFreezeStrength();
  TimeDilationHelper.SetTimeDilation(player, n"TDOQuantumPlot", strength, 999.0, n"Linear", n"Linear", true);
  TimeDilationHelper.SetTimeDilationOnPlayer(player, n"TDOQuantumPlot", strength, 999.0, n"Linear", n"Linear", true);

  TDO_Quantum_SchedulePlotTick(player);
  GameObject.PlaySoundEvent(player, n"grenade_laser_start");
  TDODebug("QuantumTeleport", "plotting started, range=" + ToString(TDO_Quantum_GetTeleportRange(player)));
}

public func TDO_Quantum_EndPlot(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) || !player.m_tdoQPlotting {
    return;
  }
  player.m_tdoQPlotting = false;
  player.m_tdoQDestValid = false;
  GameObject.StopSoundEvent(player, n"grenade_laser_start");

  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_tdoQPlotTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_tdoQPlotTickID);
    player.m_tdoQPlotTickID = GetInvalidDelayID();
  }

  TDO_Quantum_ClearMarker(player);

  TimeDilationHelper.UnSetTimeDilationOnPlayer(player, n"TDOQuantumPlot", n"Linear");
  TimeDilationHelper.UnSetTimeDilation(player, n"TDOQuantumPlot", n"Linear");
  TDODebug("QuantumTeleport", "plotting ended");
}

public func TDO_Quantum_ExecuteTeleport(player: ref<PlayerPuppet>) -> Bool {
  if !player.m_tdoQDestValid {
    return false;
  }
  let dest: Vector4 = player.m_tdoQDest;
  let rot: EulerAngles = player.m_tdoQDestRot;
  GameInstance.GetTeleportationFacility(player.GetGame()).Teleport(player, dest, rot);
  GameObject.PlaySoundEvent(player, n"grenade_sonic_bubble_core");
  let landingCb: ref<TDO_QuantumLandingSoundCallback> = new TDO_QuantumLandingSoundCallback();
  landingCb.player = player;
  GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(landingCb, 0.3, false);
  TDOInfo("QuantumTeleport", "teleport executed");
  TDO_Quantum_SpawnWarpFx(player, dest);
  TDO_Quantum_TriggerMalware(player);
  if TDOConfig.QuantumLandingStimEnabled() {
    let investigateData: stimInvestigateData;
    investigateData.skipReactionDelay = true;
    investigateData.skipInitialAnimation = false;
    StimBroadcasterComponent.BroadcastStim(player, gamedataStimType.Bump, TDOConfig.QuantumLandingStimRadius(), investigateData, true);
    TDODebug("QuantumTeleport", "landing bump stim broadcast radius=" + ToString(TDOConfig.QuantumLandingStimRadius()));
  }
  return true;
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_QuantumPlotTickEvent(evt: ref<TDO_QuantumPlotTickEvent>) -> Bool {
  this.m_tdoQPlotTickID = GetInvalidDelayID();
  if !this.m_tdoQPlotting {
    return false;
  }
  let hitPos: Vector4;
  let valid: Bool = TDO_Quantum_ResolveAimPoint(this, TDO_Quantum_GetTeleportRange(this), TDOConfig.QuantumMarkerLift(), hitPos);
  if valid {
    this.m_tdoQDest = hitPos;
    this.m_tdoQDestRot = TDO_Quantum_LevelFacing(this, TDO_Quantum_GetCameraForward(this));
    this.m_tdoQDestValid = true;
    TDO_Quantum_UpdateMarker(this, hitPos);
  } else {
    this.m_tdoQDestValid = false;
    TDO_Quantum_ClearMarker(this);
  }
  TDO_Quantum_SchedulePlotTick(this);
  return true;
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if !TDOConfig.QuantumTeleportEnabled() {
    return;
  }
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_Quantum_IsEquipped(player) {
    return;
  }
  TDO_Quantum_BeginPlot(player);
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if player.m_tdoQPlotting {
    TDO_Quantum_EndPlot(player);
  }
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if player.m_tdoQPlotting {
    TDO_Quantum_EndPlot(player);
  }
}

@wrapMethod(DisableSandevistanAction)
public func StartAction(gameInstance: GameInstance) -> Void {
  let player: ref<PlayerPuppet> = this.GetExecutor() as PlayerPuppet;
  if IsDefined(player) && TDOConfig.QuantumTeleportEnabled() && TDO_Quantum_IsEquipped(player) && player.m_tdoQPlotting {
    TDO_Quantum_ExecuteTeleport(player);
    TDO_Quantum_EndPlot(player);
    wrappedMethod(gameInstance);
    return;
  }
  wrappedMethod(gameInstance);
}

module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoQPlotting: Bool;

@addField(PlayerPuppet)
public let m_tdoQMappinID: NewMappinID;

@addField(PlayerPuppet)
public let m_tdoQMappinActive: Bool;

@addField(PlayerPuppet)
public let m_tdoQNextAimTime: Float;

@addField(PlayerPuppet)
public let m_tdoQCommitRequested: Bool;

@addField(PlayerPuppet)
public let m_tdoQDestValid: Bool;

@addField(PlayerPuppet)
public let m_tdoQDest: Vector4;

@addField(PlayerPuppet)
public let m_tdoQDestRot: EulerAngles;

public func TDO_Quantum_GetTeleportRangeBase(player: ref<PlayerPuppet>) -> Float {
  return TDOConfig.LerpTier(TDOConfig.QuantumTeleportRangeMin(), TDOConfig.QuantumTeleportRangeMax(), TDO_Quantum_GetTier(player), 5);
}

public func TDO_Quantum_GetTeleportRange(player: ref<PlayerPuppet>) -> Float {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let cool: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Cool);
  let range: Float = TDO_Quantum_GetTeleportRangeBase(player) + cool * TDOConfig.QuantumTeleportRangePerCool();
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
    TDOTrace("QuantumMarker", "reposition to " + TDO_Quantum_Vec3Str(pos));
    return;
  }
  let md: MappinData;
  md.mappinType = t"Mappins.DefaultStaticMappin";
  md.variant = gamedataMappinVariant.DistractVariant;
  md.active = true;
  md.visibleThroughWalls = true;
  player.m_tdoQMappinID = ms.RegisterMappin(md, pos);
  player.m_tdoQMappinActive = true;
  TDOTrace("QuantumMarker", "register at " + TDO_Quantum_Vec3Str(pos));
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
  public let requestedDestination: Vector4;
  public let departurePosition: Vector4;

  public func Call() -> Void {
    let p: ref<PlayerPuppet> = this.player;
    if !IsDefined(p) {
      return;
    }
    if TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= 4 {
      TDOTrace("QuantumLanding", "departure=" + TDO_Quantum_Vec3Str(this.departurePosition) + " requested=" + TDO_Quantum_Vec3Str(this.requestedDestination) + " observed=" + TDO_Quantum_Vec3Str(p.GetWorldPosition()));
    }
    GameObject.PlaySoundEvent(p, n"grenade_emp");
  }
}

public func TDO_Quantum_BeginPlot(player: ref<PlayerPuppet>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  if !IsDefined(player) || player.m_tdoQPlotting {
    return;
  }
  if TDO_IsPlayerInVehicle(player) {
    return;
  }
  player.m_tdoQPlotting = true;
  player.m_tdoQDestValid = false;
  player.m_tdoQCommitRequested = false;

  let strength: Float = TDOConfig.QuantumPlotFreezeStrength();
  TimeDilationHelper.SetTimeDilation(player, n"TDOQuantumPlot", strength, 999.0, n"Linear", n"Linear", true);
  TimeDilationHelper.SetTimeDilationOnPlayer(player, n"TDOQuantumPlot", strength, 999.0, n"Linear", n"Linear", true);

  TDO_Quantum_UpdateAim(player, scriptInterface);
  GameObject.PlaySoundEvent(player, n"grenade_laser_start");
  TDODebug("QuantumTeleport", "plotting started, range=" + ToString(TDO_Quantum_GetTeleportRange(player)));
}

public func TDO_Quantum_EndPlot(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) || !player.m_tdoQPlotting {
    return;
  }
  player.m_tdoQPlotting = false;
  player.m_tdoQDestValid = false;
  player.m_tdoQCommitRequested = false;
  player.m_tdoQNextAimTime = 0.0;
  GameObject.StopSoundEvent(player, n"grenade_laser_start");

  TDO_Quantum_ClearMarker(player);

  TimeDilationHelper.UnSetTimeDilationOnPlayer(player, n"TDOQuantumPlot", n"Linear");
  TimeDilationHelper.UnSetTimeDilation(player, n"TDOQuantumPlot", n"Linear");
  TDODebug("QuantumTeleport", "plotting ended");
}

public func TDO_Quantum_ExecuteTeleport(player: ref<PlayerPuppet>, scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if !TDOConfig.QuantumTeleportEnabled() || !TDO_Quantum_IsEquipped(player) || player.IsDead() || TDO_IsPlayerInVehicle(player) {
    return false;
  }
  if StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.PlayerInFinisherWorkspot") {
    return false;
  }
  TDO_Quantum_UpdateAim(player, scriptInterface);
  if !player.m_tdoQDestValid {
    TDODebug("QuantumTeleport", "execute BLOCKED: dest not valid");
    return false;
  }
  TDODebug("QuantumTeleport", "execute teleport to " + TDO_Quantum_Vec3Str(player.m_tdoQDest));
  let dest: Vector4 = player.m_tdoQDest;
  let rot: EulerAngles = player.m_tdoQDestRot;
  let departure: Vector4 = player.GetWorldPosition();
  GameInstance.GetTeleportationFacility(player.GetGame()).Teleport(player, dest, rot);
  GameObject.PlaySoundEvent(player, n"grenade_sonic_bubble_core");
  let landingCb: ref<TDO_QuantumLandingSoundCallback> = new TDO_QuantumLandingSoundCallback();
  landingCb.player = player;
  landingCb.requestedDestination = dest;
  landingCb.departurePosition = departure;
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

public func TDO_Quantum_UpdateAim(player: ref<PlayerPuppet>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let hitPos: Vector4;
  let valid: Bool = TDO_Quantum_ResolveAimPoint(player, scriptInterface, TDO_Quantum_GetTeleportRange(player), TDOConfig.QuantumMarkerLift(), hitPos);
  player.m_tdoQNextAimTime = EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame())) + TDOConfig.QuantumPlotTickInterval();
  TDOTrace("QuantumAim", "UpdateAim valid=" + ToString(valid) + " hitPos=" + TDO_Quantum_Vec3Str(hitPos));
  if valid {
    player.m_tdoQDest = hitPos;
    player.m_tdoQDestRot = TDO_Quantum_LevelFacing(player, TDO_Quantum_GetCameraForward(player));
    player.m_tdoQDestValid = true;
    TDO_Quantum_UpdateMarker(player, hitPos);
  } else {
    player.m_tdoQDestValid = false;
    TDO_Quantum_ClearMarker(player);
  }
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
  TDO_Quantum_BeginPlot(player, scriptInterface);
}

@wrapMethod(SandevistanEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) || !player.m_tdoQPlotting {
    return;
  }
  if !TDOConfig.QuantumTeleportEnabled() || !TDO_Quantum_IsEquipped(player) || player.IsDead() || TDO_IsPlayerInVehicle(player) {
    TDO_Quantum_EndPlot(player);
    return;
  }
  if EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame())) >= player.m_tdoQNextAimTime {
    TDO_Quantum_UpdateAim(player, scriptInterface);
  }
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_tdoQPlotting {
    let commit: Bool = player.m_tdoQCommitRequested;
    player.m_tdoQCommitRequested = false;
    if commit {
      TDO_Quantum_ExecuteTeleport(player, scriptInterface);
    }
    TDO_Quantum_EndPlot(player);
  }
  wrappedMethod(stateContext, scriptInterface);
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

@wrapMethod(SandevistanEvents)
protected final func OnExitToTimeDilationPhotomode(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_tdoQPlotting {
    TDO_Quantum_EndPlot(player);
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(DisableSandevistanAction)
public func StartAction(gameInstance: GameInstance) -> Void {
  let player: ref<PlayerPuppet> = this.GetExecutor() as PlayerPuppet;
  if IsDefined(player) && TDOConfig.QuantumTeleportEnabled() && TDO_Quantum_IsEquipped(player) && player.m_tdoQPlotting {
    if !StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.PlayerInFinisherWorkspot") {
      player.m_tdoQCommitRequested = true;
    }
  }
  wrappedMethod(gameInstance);
}

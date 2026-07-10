module TDO.Sandy

import TDO.Logging.*

public class TDO_WarpDancerRecordTickEvent extends DelayEvent {}
public class TDO_WarpDancerRewindTickEvent extends DelayEvent {}
public class TDO_WarpDancerReleaseTickEvent extends DelayEvent {}

public func TDO_WarpDancer_Begin(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  if player.m_warpDancerPhase != 0 {
    return;
  }
  TDOInfo("WarpDancer", "rewind capture started");
  player.m_warpDancerStartPos = player.GetWorldPosition();
  player.m_warpDancerStartRot = Quaternion.ToEulerAngles(player.GetWorldOrientation());
  ArrayClear(player.m_warpDancerRecord);
  ArrayClear(player.m_warpDancerStoredNPCs);
  player.m_warpDancerRewindIdx = 0;
  player.m_warpDancerPhase = 1;

  let strength: Float = TDOConfig.WarpDancerDilationStrength();
  TimeDilationHelper.SetTimeDilation(player, n"WarpDancer", strength, 999.0, n"Linear", n"Linear", true);
  TimeDilationHelper.SetIgnoreTimeDilationOnLocalPlayerZero(player, true);

  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(player.GetGame());
  pools.RequestSettingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Stamina, 100.0, player, true);

  TDO_WarpDancer_ApplyMoveSpeed(player);
  TDO_WarpDancer_ClearMovementLocks(player);
  TDO_WarpDancer_ScheduleRecordTick(player);
}

public func TDO_WarpDancer_ScheduleRecordTick(player: ref<PlayerPuppet>) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_warpDancerTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_warpDancerTickID);
  }
  let evt: ref<TDO_WarpDancerRecordTickEvent> = new TDO_WarpDancerRecordTickEvent();
  let interval: Float = TDOConfig.WarpDancerRecordIntervalSec();
  player.m_warpDancerTickID = delaySys.DelayEvent(player, evt, interval, false);
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_WarpDancerRecordTickEvent(evt: ref<TDO_WarpDancerRecordTickEvent>) -> Bool {
  this.m_warpDancerTickID = GetInvalidDelayID();
  if this.m_warpDancerPhase != 1 {
    return false;
  }
  let frame: ref<TDO_WarpDancerFrame> = new TDO_WarpDancerFrame();
  frame.pos = this.GetWorldPosition();
  frame.rot = Quaternion.ToEulerAngles(this.GetWorldOrientation());
  ArrayPush(this.m_warpDancerRecord, frame);
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  pools.RequestSettingStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Stamina, 100.0, this, true);
  TDO_WarpDancer_ClearMovementLocksThrottled(this);
  TDO_WarpDancer_ScheduleRecordTick(this);
  return true;
}

public func TDO_WarpDancer_BeginRewind(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  if player.m_warpDancerPhase != 1 {
    return;
  }

  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_warpDancerTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_warpDancerTickID);
    player.m_warpDancerTickID = GetInvalidDelayID();
  }

  TimeDilationHelper.SetIgnoreTimeDilationOnLocalPlayerZero(player, false);

  GameObject.PlaySoundEvent(player, n"dev_turret_hologram_deactivate");

  if ArraySize(player.m_warpDancerRecord) == 0 {
    TDO_WarpDancer_BeginPostRewindPause(player);
    return;
  }

  player.m_warpDancerPhase = 2;
  player.m_warpDancerRewindIdx = ArraySize(player.m_warpDancerRecord) - 1;

  let durationSec: Float = TDOConfig.WarpDancerRewindDurationSec();
  let tickInterval: Float = TDOConfig.WarpDancerRewindIntervalSec();
  let totalFrames: Float = Cast<Float>(ArraySize(player.m_warpDancerRecord));
  let stride: Int32 = 1;
  if tickInterval > 0.0 && durationSec > 0.0 {
    let totalTicks: Float = durationSec / tickInterval;
    if totalTicks > 0.0 {
      stride = CeilF(totalFrames / totalTicks);
    }
  }
  if stride < 1 {
    stride = 1;
  }
  player.m_warpDancerComputedStride = stride;

  TDO_WarpDancer_SpawnRewindGlitch(player);
  TDO_WarpDancer_ScheduleRewindTick(player);
}

public func TDO_WarpDancer_ScheduleRewindTick(player: ref<PlayerPuppet>) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_warpDancerTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_warpDancerTickID);
  }
  let evt: ref<TDO_WarpDancerRewindTickEvent> = new TDO_WarpDancerRewindTickEvent();
  let interval: Float = TDOConfig.WarpDancerRewindIntervalSec();
  player.m_warpDancerTickID = delaySys.DelayEvent(player, evt, interval, false);
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_WarpDancerRewindTickEvent(evt: ref<TDO_WarpDancerRewindTickEvent>) -> Bool {
  this.m_warpDancerTickID = GetInvalidDelayID();
  if this.m_warpDancerPhase != 2 {
    return false;
  }

  let idx: Int32 = this.m_warpDancerRewindIdx;
  if idx < 0 {
    TDO_WarpDancer_BeginPostRewindPause(this);
    return true;
  }

  let frame: ref<TDO_WarpDancerFrame> = this.m_warpDancerRecord[idx];
  if IsDefined(frame) {
    GameInstance.GetTeleportationFacility(this.GetGame()).Teleport(this, frame.pos, frame.rot);
  }

  let stride: Int32 = this.m_warpDancerComputedStride;
  if stride < 1 {
    stride = 1;
  }
  this.m_warpDancerRewindIdx = idx - stride;

  if this.m_warpDancerRewindIdx < 0 {
    GameInstance.GetTeleportationFacility(this.GetGame()).Teleport(this, this.m_warpDancerStartPos, this.m_warpDancerStartRot);
    TDO_WarpDancer_BeginPostRewindPause(this);
    return true;
  }

  TDO_WarpDancer_ScheduleRewindTick(this);
  return true;
}

public func TDO_WarpDancer_BeginPostRewindPause(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  player.m_warpDancerPhase = 3;
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_warpDancerTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_warpDancerTickID);
  }
  let evt: ref<TDO_WarpDancerReleaseTickEvent> = new TDO_WarpDancerReleaseTickEvent();
  let pauseSec: Float = TDOConfig.WarpDancerPostRewindPauseSec();
  player.m_warpDancerTickID = delaySys.DelayEvent(player, evt, pauseSec, false);
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_WarpDancerReleaseTickEvent(evt: ref<TDO_WarpDancerReleaseTickEvent>) -> Bool {
  this.m_warpDancerTickID = GetInvalidDelayID();
  if this.m_warpDancerPhase != 3 {
    return false;
  }
  TDO_WarpDancer_Release(this);
  return true;
}

public func TDO_WarpDancer_Release(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  TDOInfo("WarpDancer", "rewind complete, releasing");
  TimeDilationHelper.UnSetTimeDilation(player, n"WarpDancer", n"Linear");

  GameObject.PlaySoundEvent(player, n"lcm_player_intcloak_activated");

  TDO_WarpDancer_RemoveMoveSpeed(player);
  TDO_WarpDancer_FlushStoredDamage(player);

  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(player.GetGame());
  let pid: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
  pools.RequestSettingStatPoolValue(pid, gamedataStatPoolType.SandevistanCharge, 0.0, player, false);

  let staggerIdx: Int32 = TDO_WarpDancer_GetEquippedTierIndex(player);
  if staggerIdx >= 0 {
    let staggerSEID: TweakDBID = TDO_WarpDancer_GetStaggerSEID(player);
    StatusEffectHelper.ApplyStatusEffect(player, staggerSEID);
  }

  ArrayClear(player.m_warpDancerRecord);
  player.m_warpDancerRewindIdx = 0;
  player.m_warpDancerPhase = 0;
}

public func TDO_WarpDancer_Abort(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) || player.m_warpDancerPhase == 0 {
    return;
  }
  TDOInfo("WarpDancer", "aborted (phase=" + ToString(player.m_warpDancerPhase) + ")");
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_warpDancerTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_warpDancerTickID);
    player.m_warpDancerTickID = GetInvalidDelayID();
  }
  TimeDilationHelper.UnSetTimeDilation(player, n"WarpDancer", n"Linear");
  TimeDilationHelper.SetIgnoreTimeDilationOnLocalPlayerZero(player, false);
  TDO_WarpDancer_RemoveMoveSpeed(player);
  TDO_WarpDancer_FlushStoredDamage(player);
  ArrayClear(player.m_warpDancerRecord);
  player.m_warpDancerRewindIdx = 0;
  player.m_warpDancerPhase = 0;
}

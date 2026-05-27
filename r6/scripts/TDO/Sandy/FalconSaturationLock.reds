module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoFalconLockedTargets: array<EntityID>;

@addField(PlayerPuppet)
public let m_tdoFalconLockTickID: DelayID;

@addField(PlayerPuppet)
public let m_tdoFalconSmartShotCount: Int32;

@addField(PlayerPuppet)
public let m_tdoFalconPenaltySession: Int32;

public func TDO_Falcon_IsADS(player: ref<PlayerPuppet>) -> Bool {
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) { return false; }
  let upper: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody);
  return upper == EnumInt(gamePSMUpperBodyStates.Aim);
}

public func TDO_Falcon_ScanVisibleHostiles(player: ref<PlayerPuppet>, range: Float) -> array<wref<NPCPuppet>> {
  let result: array<wref<NPCPuppet>>;
  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(player.GetGame());
  let query: TargetSearchQuery = TSQ_NPC();
  query.maxDistance = range;
  query.filterObjectByDistance = true;
  query.testedSet = TargetingSet.Complete;

  let parts: array<TS_TargetPartInfo>;
  targetingSystem.GetTargetParts(player, query, parts);

  let seen: array<EntityID>;
  let i: Int32 = 0;
  while i < ArraySize(parts) {
    let comp: wref<TargetingComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
    if IsDefined(comp) {
      let entity: wref<Entity> = comp.GetEntity();
      let npc: wref<NPCPuppet> = entity as NPCPuppet;
      if IsDefined(npc) && !npc.IsDead() && npc.IsHostile() && !ArrayContains(seen, npc.GetEntityID()) {
        ArrayPush(result, npc);
        ArrayPush(seen, npc.GetEntityID());
      }
    }
    i += 1;
  }
  return result;
}

public class TDO_FalconLockTickEvent extends Event {}

public func TDO_Falcon_ScheduleLockTick(player: ref<PlayerPuppet>) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_tdoFalconLockTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_tdoFalconLockTickID);
  }
  let evt: ref<TDO_FalconLockTickEvent> = new TDO_FalconLockTickEvent();
  player.m_tdoFalconLockTickID = delaySys.DelayEvent(player, evt, 0.1, false);
}

public func TDO_Falcon_StopLockTick(player: ref<PlayerPuppet>) -> Void {
  if player.m_tdoFalconLockTickID != GetInvalidDelayID() {
    let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
    delaySys.CancelDelay(player.m_tdoFalconLockTickID);
    player.m_tdoFalconLockTickID = GetInvalidDelayID();
  }
}

public func TDO_Falcon_ClearLocks(player: ref<PlayerPuppet>) -> Void {
  let gi: GameInstance = player.GetGame();
  let i: Int32 = 0;
  while i < ArraySize(player.m_tdoFalconLockedTargets) {
    let entity: wref<Entity> = GameInstance.FindEntityByID(gi, player.m_tdoFalconLockedTargets[i]);
    let npc: ref<GameObject> = entity as GameObject;
    if IsDefined(npc) {
      StatusEffectHelper.RemoveStatusEffect(npc, t"StatusEffects.TDO_FalconLockMarker");
    }
    i += 1;
  }
  ArrayClear(player.m_tdoFalconLockedTargets);
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_FalconLockTickEvent(evt: ref<TDO_FalconLockTickEvent>) -> Bool {
  this.m_tdoFalconLockTickID = GetInvalidDelayID();

  if !TDOConfig.FalconSaturationLockEnabled() {
    return true;
  }
  if !TDO_Falcon_IsSandyActive(this) {
    TDO_Falcon_ClearLocks(this);
    return true;
  }
  if !TDO_Falcon_IsEquipped(this) {
    TDO_Falcon_ClearLocks(this);
    return true;
  }
  let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(this);
  if !IsDefined(weapon) || !TDO_Falcon_IsSmartWeapon(weapon) {
    TDO_Falcon_ClearLocks(this);
    return true;
  }
  if !TDO_Falcon_IsADS(this) {
    TDO_Falcon_ScheduleLockTick(this);
    return true;
  }

  let visible: array<wref<NPCPuppet>> = TDO_Falcon_ScanVisibleHostiles(this, TDOConfig.FalconSaturationLockRange());
  let i: Int32 = 0;
  while i < ArraySize(visible) {
    let npc: wref<NPCPuppet> = visible[i];
    let id: EntityID = npc.GetEntityID();
    if !ArrayContains(this.m_tdoFalconLockedTargets, id) {
      ArrayPush(this.m_tdoFalconLockedTargets, id);
      StatusEffectHelper.ApplyStatusEffect(npc, t"StatusEffects.TDO_FalconLockMarker");
    }
    i += 1;
  }

  TDO_Falcon_ScheduleLockTick(this);
  return true;
}

public class TDO_FalconVolleyTickEvent extends Event {
  public let targetIndex: Int32;
  public let weaponRef: wref<WeaponObject>;
  public let targets: array<EntityID>;
}

public func TDO_Falcon_ScheduleVolleyTick(player: ref<PlayerPuppet>, weapon: ref<WeaponObject>, index: Int32, delay: Float, targets: array<EntityID>) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  let evt: ref<TDO_FalconVolleyTickEvent> = new TDO_FalconVolleyTickEvent();
  evt.targetIndex = index;
  evt.weaponRef = weapon;
  evt.targets = targets;
  delaySys.DelayEvent(player, evt, delay, false);
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_FalconVolleyTickEvent(evt: ref<TDO_FalconVolleyTickEvent>) -> Bool {
  let idx: Int32 = evt.targetIndex;
  let total: Int32 = ArraySize(evt.targets);
  if idx >= total {
    return true;
  }

  let weapon: ref<WeaponObject> = evt.weaponRef;
  if !IsDefined(weapon) {
    return true;
  }

  let gi: GameInstance = this.GetGame();
  let entity: wref<Entity> = GameInstance.FindEntityByID(gi, evt.targets[idx]);
  let target: wref<NPCPuppet> = entity as NPCPuppet;
  if IsDefined(target) {
    StatusEffectHelper.RemoveStatusEffect(target, t"StatusEffects.TDO_FalconLockMarker");
    if !target.IsDead() {
      let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
      let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
      let weaponID: StatsObjectID = Cast<StatsObjectID>(weapon.GetEntityID());
      let playerID: StatsObjectID = Cast<StatsObjectID>(this.GetEntityID());
      let baseDamage: Float = statsSystem.GetStatValue(weaponID, gamedataStatType.EffectiveDamagePerHit);
      let weakspotMult: Float = statsSystem.GetStatValue(playerID, gamedataStatType.WeakspotDamageMultiplier);
      let damage: Float = baseDamage * (1.0 + weakspotMult);
      let npcMaxHP: Float = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.Health);
      let xpPct: Float = 100.0;
      if npcMaxHP > 0.0 {
        xpPct = MinF(100.0, (damage / npcMaxHP) * 100.0);
      }
      TDO_Falcon_GrantKillCredit(this, target, weapon, xpPct);
      pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatPoolType.Health, -damage, this, false, false);
      GameObjectEffectHelper.StartEffectEvent(target, n"weakspot_hit");
      GameObjectEffectHelper.StartEffectEvent(target, n"blood_headshot");
      ProjectileLaunchHelper.SpawnProjectileFromScreenCenter(this, n"smart_bullet_high", n"None", weapon);
    }
  }

  let next: Int32 = idx + 1;
  if next < total {
    TDO_Falcon_ScheduleVolleyTick(this, weapon, next, TDOConfig.FalconSaturationLockStagger(), evt.targets);
  }
  return true;
}

public func TDO_Falcon_FireSaturationVolley(player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Void {
  if TDO_IsPlayerInVehicle(player) {
    return;
  }
  let gi: GameInstance = player.GetGame();
  let alive: array<EntityID>;
  let i: Int32 = 0;
  while i < ArraySize(player.m_tdoFalconLockedTargets) {
    let id: EntityID = player.m_tdoFalconLockedTargets[i];
    let npc: wref<NPCPuppet> = GameInstance.FindEntityByID(gi, id) as NPCPuppet;
    if IsDefined(npc) && !npc.IsDead() {
      ArrayPush(alive, id);
    }
    i += 1;
  }
  if ArraySize(alive) < TDOConfig.FalconSaturationLockMinTargets() {
    TDODebug("Falcon", "Saturation volley aborted: " + ToString(ArraySize(alive)) + " alive < min");
    TDO_Falcon_ClearLocks(player);
    return;
  }
  TDOInfo("Falcon", "Saturation volley firing, " + ToString(ArraySize(alive)) + " targets");
  ArrayClear(player.m_tdoFalconLockedTargets);
  TDO_Falcon_ScheduleVolleyTick(player, weapon, 0, 0.01, alive);
}

public class TDO_FalconCyberwareTickEvent extends Event {
  public let remainingDuration: Float;
  public let session: Int32;
}

public func TDO_Falcon_ApplySmartCyberwarePenalty(player: ref<PlayerPuppet>) -> Void {
  let shots: Int32 = player.m_tdoFalconSmartShotCount;
  player.m_tdoFalconSmartShotCount = 0;
  if shots <= 0 { return; }

  let duration: Float = Cast<Float>(shots) * TDOConfig.FalconSaturationLockEMPSecondsPerShot();
  if duration <= 0.1 { return; }

  let evt: ref<TDO_FalconCyberwareTickEvent> = new TDO_FalconCyberwareTickEvent();
  evt.remainingDuration = duration;
  evt.session = player.m_tdoFalconPenaltySession;
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  delaySys.DelayEvent(player, evt, 0.0, false);
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_FalconCyberwareTickEvent(evt: ref<TDO_FalconCyberwareTickEvent>) -> Bool {
  if evt.session != this.m_tdoFalconPenaltySession {
    return true;
  }
  if evt.remainingDuration <= 0.0 {
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.CyberwareMalfunction");
    return true;
  }

  StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.CyberwareMalfunction", this.GetEntityID());

  let tickInterval: Float = 4.0;
  let nextDelay: Float = tickInterval;
  if evt.remainingDuration < tickInterval {
    nextDelay = evt.remainingDuration;
  }
  let nextEvt: ref<TDO_FalconCyberwareTickEvent> = new TDO_FalconCyberwareTickEvent();
  nextEvt.remainingDuration = evt.remainingDuration - nextDelay;
  nextEvt.session = evt.session;
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  delaySys.DelayEvent(this, nextEvt, nextDelay, false);
  return true;
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  if !TDO_Falcon_IsEquipped(player) { return; }
  player.m_tdoFalconSmartShotCount = 0;
  player.m_tdoFalconPenaltySession += 1;
  TDO_Falcon_ScheduleLockTick(player);
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  TDO_Falcon_StopLockTick(player);
  TDO_Falcon_ClearLocks(player);
  TDO_Falcon_ApplySmartCyberwarePenalty(player);
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  TDO_Falcon_StopLockTick(player);
  TDO_Falcon_ClearLocks(player);
  TDO_Falcon_ApplySmartCyberwarePenalty(player);
}

@wrapMethod(ShootEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);

  if !TDOConfig.FalconSaturationLockEnabled() { return; }

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }

  if !TDO_Falcon_IsSandyActive(player) { return; }
  if !TDO_Falcon_IsEquipped(player) { return; }

  let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(player);
  if !IsDefined(weapon) { return; }

  if !TDO_Falcon_IsSmartWeapon(weapon) { return; }

  player.m_tdoFalconSmartShotCount += 1;
  TDO_Falcon_FireSaturationVolley(player, weapon);
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  ArrayClear(this.m_tdoFalconLockedTargets);
  this.m_tdoFalconLockTickID = GetInvalidDelayID();
  return result;
}

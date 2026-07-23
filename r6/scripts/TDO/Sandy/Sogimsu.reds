module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_sogimsuWatchdogActive: Bool;

@addField(PlayerPuppet)
public let m_sogimsuWatchdogEndTime: Float;

@addField(PlayerPuppet)
public let m_sogimsuWatchdogInterventionsLeft: Int32;

@addField(PlayerPuppet)
public let m_sogimsuWatchdogInterventedNPCs: array<EntityID>;

@addField(PlayerPuppet)
public let m_sogimsuWatchdogTier: Int32;

@addField(PlayerPuppet)
public let m_sogimsuWatchdogTickID: DelayID;

public func TDO_Sogimsu_GetWatchdogDuration(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.SogimsuDurationMin(), TDOConfig.SogimsuDurationMax(), tier, 7);
}

public func TDO_Sogimsu_GetCooldownSE(tier: Int32) -> TweakDBID {
  switch tier {
    case 1: return t"StatusEffects.TDO_SogimsuCooldown_T1";
    case 2: return t"StatusEffects.TDO_SogimsuCooldown_T2";
    case 3: return t"StatusEffects.TDO_SogimsuCooldown_T3";
    case 4: return t"StatusEffects.TDO_SogimsuCooldown_T4";
    case 5: return t"StatusEffects.TDO_SogimsuCooldown_T5";
    case 6: return t"StatusEffects.TDO_SogimsuCooldown_T6";
    case 7: return t"StatusEffects.TDO_SogimsuCooldown_T7";
  }
  return t"StatusEffects.TDO_SogimsuCooldown_T1";
}

@addMethod(PlayerPuppet)
public func TDO_Sogimsu_GetEquippedTier() -> Int32 {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(this);
  if !IsDefined(es) {
    return 0;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(this);
  if !IsDefined(pd) {
    return 0;
  }
  let slotIdx: Int32 = 0;
  let slotCount: Int32 = pd.GetNumberOfSlots(gamedataEquipmentArea.SystemReplacementCW, true);
  while slotIdx < slotCount {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tier: Int32 = TDO_Sogimsu_TierForItemTDB(ItemID.GetTDBID(itemID));
      if tier > 0 { return tier; }
    }
    slotIdx += 1;
  }
  return 0;
}

@addMethod(PlayerPuppet)
public func TDO_Sogimsu_OnActivate(tier: Int32) -> Void {
  if this.m_sogimsuWatchdogActive {
    this.TDO_Sogimsu_EndWatchdog();
    return;
  }
  if TDO_IsPlayerInVehicle(this) {
    return;
  }
  if !TDOConfig.SogimsuEnabled() {
    return;
  }
  if this.TDO_Sogimsu_IsOnCooldown() {
    TDODebug("Sogimsu", "activate blocked: on cooldown");
    GameObject.PlaySoundEvent(this, n"ui_hacking_access_denied");
    return;
  }
  this.TDO_Sogimsu_StartWatchdog(tier);
}

@addMethod(PlayerPuppet)
public func TDO_Sogimsu_IsOnCooldown() -> Bool {
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_SogimsuCooldown_T1") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_SogimsuCooldown_T2") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_SogimsuCooldown_T3") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_SogimsuCooldown_T4") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_SogimsuCooldown_T5") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_SogimsuCooldown_T6") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_SogimsuCooldown_T7") { return true; }
  return false;
}

@addMethod(PlayerPuppet)
public func TDO_Sogimsu_StartWatchdog(tier: Int32) -> Void {
  let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGame()));
  let duration: Float = TDO_Sogimsu_GetWatchdogDuration(tier);

  let interventions: Int32 = Cast<Int32>(TDOConfig.LerpTier(TDOConfig.SogimsuInterventionsMin(), TDOConfig.SogimsuInterventionsMax(), tier, 7) + 0.5);

  this.m_sogimsuWatchdogActive = true;
  this.m_sogimsuWatchdogTier = tier;
  this.m_sogimsuWatchdogEndTime = now + duration;
  this.m_sogimsuWatchdogInterventionsLeft = interventions;
  ArrayClear(this.m_sogimsuWatchdogInterventedNPCs);
  TDOInfo("Sogimsu", "Watchdog Protocol started tier=" + ToString(tier) + " duration=" + FloatToStringPrec(duration, 1) + " interventions=" + ToString(interventions));

  StatusEffectHelper.ApplyStatusEffect(this, t"StatusEffects.TDO_SogimsuWatchdogActive");
  GameObject.PlaySoundEvent(this, n"lcm_player_intcloak_activated");

  this.TDO_Sogimsu_ScheduleWatchdogTick();
}

public class TDO_SogimsuWatchdogTickCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;
  public func Call() -> Void {
    if IsDefined(this.player) {
      this.player.TDO_Sogimsu_OnWatchdogTick();
    }
  }
}

@addMethod(PlayerPuppet)
public func TDO_Sogimsu_ScheduleWatchdogTick() -> Void {
  if !this.m_sogimsuWatchdogActive {
    return;
  }
  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  if this.m_sogimsuWatchdogTickID != GetInvalidDelayID() {
    delaySystem.CancelCallback(this.m_sogimsuWatchdogTickID);
  }
  let callback: ref<TDO_SogimsuWatchdogTickCallback> = new TDO_SogimsuWatchdogTickCallback();
  callback.player = this;
  this.m_sogimsuWatchdogTickID = delaySystem.DelayCallback(callback, TDOConfig.SogimsuWatchdogTickInterval(), false);
}

@addMethod(PlayerPuppet)
public func TDO_Sogimsu_OnWatchdogTick() -> Void {
  this.m_sogimsuWatchdogTickID = GetInvalidDelayID();
  if !this.m_sogimsuWatchdogActive {
    return;
  }

  if this.TDO_Sogimsu_GetEquippedTier() == 0 || !TDOConfig.SogimsuEnabled() {
    this.TDO_Sogimsu_EndWatchdog();
    return;
  }

  let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGame()));
  if now >= this.m_sogimsuWatchdogEndTime || this.m_sogimsuWatchdogInterventionsLeft <= 0 {
    this.TDO_Sogimsu_EndWatchdog();
    return;
  }

  let radius: Float = TDOConfig.SogimsuWatchdogRadius();
  let threshold: Float = TDOConfig.SogimsuWatchdogDetectionThreshold();
  let hostiles: array<wref<NPCPuppet>> = TDO_Sogimsu_GetNearbyHostiles(this, radius);

  let i: Int32 = 0;
  while i < ArraySize(hostiles) && this.m_sogimsuWatchdogInterventionsLeft > 0 {
    let npc: wref<NPCPuppet> = hostiles[i];
    let npcID: EntityID = npc.GetEntityID();

    if !ArrayContains(this.m_sogimsuWatchdogInterventedNPCs, npcID) {
      if !npc.IsBoss() && !Equals(npc.GetNPCRarity(), gamedataNPCRarity.MaxTac) {
        let detection: Float = TDO_Sogimsu_GetNPCDetectionOnPlayer(npc, this);
        if detection >= threshold {
          TDO_Sogimsu_ApplyRandomIntervention(npc, this);
          ArrayPush(this.m_sogimsuWatchdogInterventedNPCs, npcID);
          this.m_sogimsuWatchdogInterventionsLeft -= 1;
        }
      }
    }
    i += 1;
  }

  let combatIdx: Int32 = 0;
  while combatIdx < ArraySize(hostiles) {
    let h: wref<NPCPuppet> = hostiles[combatIdx];
    if TDO_Sogimsu_IsNPCInCombat(h) {
      let tracker: ref<TargetTrackerComponent> = h.GetTargetTrackerComponent();
      if IsDefined(tracker) {
        let threat: TrackedLocation;
        if tracker.ThreatFromEntity(this, threat) {
          this.TDO_Sogimsu_EndWatchdog();
          return;
        }
      }
    }
    combatIdx += 1;
  }

  this.TDO_Sogimsu_ScheduleWatchdogTick();
}

public func TDO_Sogimsu_GetNearbyHostiles(player: ref<PlayerPuppet>, range: Float) -> array<wref<NPCPuppet>> {
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

public func TDO_Sogimsu_GetNPCDetectionOnPlayer(npc: wref<NPCPuppet>, player: ref<PlayerPuppet>) -> Float {
  let bar: Float = npc.GetDetectionPercentage();
  if bar > 0.0 {
    return bar / 100.0;
  }
  let sense: ref<SenseComponent> = npc.GetSensesComponent();
  if IsDefined(sense) {
    let d: Float = sense.GetDetection(player.GetEntityID());
    if d > 0.0 {
      return d;
    }
  }
  let tracker: ref<TargetTrackerComponent> = npc.GetTargetTrackerComponent();
  if IsDefined(tracker) {
    let threat: TrackedLocation;
    if tracker.ThreatFromEntity(player, threat) {
      return threat.accuracy;
    }
  }
  return 0.0;
}

public func TDO_Sogimsu_ClearDetection(npc: wref<NPCPuppet>, player: ref<PlayerPuppet>) -> Void {
  npc.SetDetectionPercentage(0.0);
  let sense: ref<SenseComponent> = npc.GetSensesComponent();
  if IsDefined(sense) {
    sense.ResetDetection(player.GetEntityID());
  }
  let tracker: ref<TargetTrackerComponent> = npc.GetTargetTrackerComponent();
  if IsDefined(tracker) {
    tracker.ClearThreats();
  }
}

public func TDO_Sogimsu_IsNPCInCombat(npc: wref<NPCPuppet>) -> Bool {
  return Equals(npc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat);
}

public func TDO_Sogimsu_WipeNearbyAwareness(player: ref<PlayerPuppet>, range: Float) -> Void {
  let nearby: array<wref<NPCPuppet>> = TDO_Sogimsu_GetNearbyHostiles(player, range);
  let i: Int32 = 0;
  while i < ArraySize(nearby) {
    TDO_Sogimsu_ClearDetection(nearby[i], player);
    i += 1;
  }
}

public func TDO_Sogimsu_ApplyRandomIntervention(npc: wref<NPCPuppet>, player: ref<PlayerPuppet>) -> Void {
  StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.MemoryWipeLevel2", player.GetEntityID());
  StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.QuickHackBlindLevel4", player.GetEntityID());
  TDO_Sogimsu_ClearDetection(npc, player);
  GameObject.PlaySoundEvent(player, n"q005_sc_03_v_telemetry_glitch");
}

@addMethod(PlayerPuppet)
public func TDO_Sogimsu_EndWatchdog() -> Void {
  if !this.m_sogimsuWatchdogActive {
    return;
  }
  this.m_sogimsuWatchdogActive = false;
  TDOInfo("Sogimsu", "Watchdog Protocol ended");

  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  if this.m_sogimsuWatchdogTickID != GetInvalidDelayID() {
    delaySystem.CancelCallback(this.m_sogimsuWatchdogTickID);
    this.m_sogimsuWatchdogTickID = GetInvalidDelayID();
  }

  ArrayClear(this.m_sogimsuWatchdogInterventedNPCs);

  StatusEffectHelper.RemoveStatusEffect(this, t"StatusEffects.TDO_SogimsuWatchdogActive");
  StatusEffectHelper.ApplyStatusEffect(this, t"StatusEffects.TDO_SogimsuWatchdogCamo");

  TDO_Sogimsu_WipeNearbyAwareness(this, 60.0);

  let cooldownSE: TweakDBID = TDO_Sogimsu_GetCooldownSE(this.m_sogimsuWatchdogTier);
  StatusEffectHelper.ApplyStatusEffect(this, cooldownSE);

  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.SandevistanCharge, -100.0, this, false);

  GameObject.PlaySoundEvent(this, n"lcm_player_intcloak_deactivated");
}

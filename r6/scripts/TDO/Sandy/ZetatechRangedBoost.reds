module TDO.Sandy

import TDO.Logging.*

public func TDO_Zetatech_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
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
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK1") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK1Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK2") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK2Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK3") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK3Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK4") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK4Plus") { return true; }
      if Equals(tdb, t"Items.AdvancedSandevistanC1MK4PlusPlus") { return true; }
    }
    slotIdx += 1;
  }
  return false;
}

@addField(PlayerPuppet)
public let m_tdoShrikeMarkedNPCs: array<EntityID>;

@addField(PlayerPuppet)
public let m_tdoShrikeHoveredNPC: EntityID;

@addField(PlayerPuppet)
public let m_tdoShrikeHoverStartTime: Float;

@addField(PlayerPuppet)
public let m_tdoShrikeMarkTickID: DelayID;

@addField(PlayerPuppet)
public let m_tdoShrikeLastDeniedTarget: EntityID;

@addField(PlayerPuppet)
public let m_tdoShrikePendingHitscanBullets: Int32;

@addField(PlayerPuppet)
public let m_tdoShrikeCooldownIDs: array<EntityID>;

@addField(PlayerPuppet)
public let m_tdoShrikeCooldownTimes: array<Float>;

@addField(PlayerPuppet)
public let m_tdoShrikeAimHandled: Bool;

@addField(PlayerPuppet)
public let m_tdoShrikeUnavailableSince: array<Float>;

@addField(PlayerPuppet)
public let m_tdoShrikeNextCleanup: Float;

@addField(PlayerPuppet)
public let m_tdoShrikeTickGeneration: Uint32;

public func TDO_Shrike_ResetAim(player: ref<PlayerPuppet>) -> Void {
  player.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
  player.m_tdoShrikeAimHandled = false;
  player.m_tdoShrikeLastDeniedTarget = EMPTY_ENTITY_ID();
}

public func TDO_Shrike_PruneMarks(player: ref<PlayerPuppet>, now: Float) -> Void {
  let i: Int32 = ArraySize(player.m_tdoShrikeMarkedNPCs) - 1;
  while i >= 0 {
    let npc: ref<NPCPuppet> = GameInstance.FindEntityByID(player.GetGame(), player.m_tdoShrikeMarkedNPCs[i]) as NPCPuppet;
    let remove: Bool = false;
    if IsDefined(npc) {
      player.m_tdoShrikeUnavailableSince[i] = 0.0;
      remove = !TDO_Shrike_IsEligibleTarget(npc);
    } else {
      if player.m_tdoShrikeUnavailableSince[i] <= 0.0 {
        player.m_tdoShrikeUnavailableSince[i] = now;
      } else {
        remove = now - player.m_tdoShrikeUnavailableSince[i] >= 5.0;
      }
    }
    if remove {
      if IsDefined(npc) {
        TDO_Shrike_RemoveMarkHighlight(player, npc);
      }
      ArrayErase(player.m_tdoShrikeMarkedNPCs, i);
      ArrayErase(player.m_tdoShrikeUnavailableSince, i);
    }
    i -= 1;
  }
}

public func TDO_Shrike_PruneCooldowns(player: ref<PlayerPuppet>, now: Float) -> Void {
  let limit: Float = TDOConfig.ShrikeRemarkCooldown();
  let i: Int32 = ArraySize(player.m_tdoShrikeCooldownIDs) - 1;
  while i >= 0 {
    if now - player.m_tdoShrikeCooldownTimes[i] >= limit {
      ArrayErase(player.m_tdoShrikeCooldownIDs, i);
      ArrayErase(player.m_tdoShrikeCooldownTimes, i);
    }
    i -= 1;
  }
}

public func TDO_Shrike_IsOnCooldown(player: ref<PlayerPuppet>, targetID: EntityID, now: Float) -> Bool {
  let idx: Int32 = ArrayFindFirst(player.m_tdoShrikeCooldownIDs, targetID);
  if idx < 0 { return false; }
  return (now - player.m_tdoShrikeCooldownTimes[idx]) < TDOConfig.ShrikeRemarkCooldown();
}

public func TDO_Shrike_RecordCooldown(player: ref<PlayerPuppet>, targetID: EntityID, now: Float) -> Void {
  let idx: Int32 = ArrayFindFirst(player.m_tdoShrikeCooldownIDs, targetID);
  if idx >= 0 {
    ArrayErase(player.m_tdoShrikeCooldownIDs, idx);
    ArrayErase(player.m_tdoShrikeCooldownTimes, idx);
  }
  ArrayPush(player.m_tdoShrikeCooldownIDs, targetID);
  ArrayPush(player.m_tdoShrikeCooldownTimes, now);
}

public func TDO_Shrike_IsSandyActive(player: ref<PlayerPuppet>) -> Bool {
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) {
    return false;
  }
  let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
  return td == EnumInt(gamePSMTimeDilation.Sandevistan);
}

public func TDO_Shrike_IsADS(player: ref<PlayerPuppet>) -> Bool {
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) {
    return false;
  }
  let upper: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody);
  return upper == EnumInt(gamePSMUpperBodyStates.Aim);
}

public func TDO_Shrike_IsRangedWeaponEquipped(player: ref<PlayerPuppet>) -> Bool {
  let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(player);
  if !IsDefined(weapon) {
    return false;
  }
  return weapon.IsRanged();
}

public class TDO_ShrikeMarkTickEvent extends Event {
  public let generation: Uint32;
}

public func TDO_Shrike_ScheduleMarkTick(player: ref<PlayerPuppet>) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  TDO_Shrike_StopMarkTick(player);
  let evt: ref<TDO_ShrikeMarkTickEvent> = new TDO_ShrikeMarkTickEvent();
  evt.generation = player.m_tdoShrikeTickGeneration;
  player.m_tdoShrikeMarkTickID = delaySys.DelayEvent(player, evt, 0.05, false);
}

public func TDO_Shrike_StopMarkTick(player: ref<PlayerPuppet>) -> Void {
  player.m_tdoShrikeTickGeneration += 1u;
  if player.m_tdoShrikeMarkTickID != GetInvalidDelayID() {
    let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
    delaySys.CancelDelay(player.m_tdoShrikeMarkTickID);
    player.m_tdoShrikeMarkTickID = GetInvalidDelayID();
  }
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_ShrikeMarkTickEvent(evt: ref<TDO_ShrikeMarkTickEvent>) -> Bool {
  if evt.generation != this.m_tdoShrikeTickGeneration {
    return true;
  }
  this.m_tdoShrikeMarkTickID = GetInvalidDelayID();

  let isShrike: Bool = TDO_Zetatech_IsEquipped(this);
  let inSandy: Bool = TDO_Shrike_IsSandyActive(this);
  let isADS: Bool = TDO_Shrike_IsADS(this);

  if !TDOConfig.ShrikeEnabled() || !isShrike || this.IsDead() || this.IsReplacer() {
    TDO_Shrike_Shutdown(this);
    return true;
  }

  let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGame()));
  let inMenu: Bool = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_System).GetBool(GetAllBlackboardDefs().UI_System.IsInMenu);
  if inMenu || GameInstance.GetPhotoModeSystem(this.GetGame()).IsPhotoModeActive() {
    TDO_Shrike_ResetAim(this);
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  if now >= this.m_tdoShrikeNextCleanup {
    TDO_Shrike_PruneMarks(this, now);
    TDO_Shrike_PruneCooldowns(this, now);
    this.m_tdoShrikeNextCleanup = now + 0.25;
  }

  if !TDO_Shrike_IsRangedWeaponEquipped(this) {
    TDO_Shrike_ResetAim(this);
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  if inSandy && isADS && ArraySize(this.m_tdoShrikeMarkedNPCs) > 0 {
    let bestIdx: Int32 = TDO_Shrike_PickBestMarkIndex(this);
    if bestIdx >= 0 {
      TDO_Shrike_SnapToMarkAtIndex(this, bestIdx);
    }
    TDO_Shrike_ResetAim(this);
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  if inSandy {
    TDO_Shrike_ResetAim(this);
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  if !isADS {
    TDO_Shrike_ResetAim(this);
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(this.GetGame());
  let lookAt: ref<GameObject> = targetingSystem.GetLookAtObject(this, true, true);
  if !IsDefined(lookAt) {
    TDO_Shrike_ResetAim(this);
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let npc: ref<NPCPuppet> = lookAt as NPCPuppet;
  if !TDO_Shrike_IsEligibleTarget(npc) {
    TDO_Shrike_ResetAim(this);
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let targetID: EntityID = lookAt.GetEntityID();

  if !Equals(this.m_tdoShrikeHoveredNPC, targetID) {
    this.m_tdoShrikeHoveredNPC = targetID;
    this.m_tdoShrikeHoverStartTime = now;
    this.m_tdoShrikeAimHandled = false;
    this.m_tdoShrikeLastDeniedTarget = EMPTY_ENTITY_ID();
  }

  if this.m_tdoShrikeAimHandled {
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let elapsed: Float = now - this.m_tdoShrikeHoverStartTime;
  let existingIdx: Int32 = ArrayFindFirst(this.m_tdoShrikeMarkedNPCs, targetID);

  if existingIdx >= 0 {
    if elapsed >= TDOConfig.ShrikeUnmarkHoverTime() {
      TDO_Shrike_RemoveMarkHighlight(this, lookAt);
      ArrayErase(this.m_tdoShrikeMarkedNPCs, existingIdx);
      ArrayErase(this.m_tdoShrikeUnavailableSince, existingIdx);
      TDO_Shrike_RecordCooldown(this, targetID, now);
      GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_disassemble");
      this.m_tdoShrikeLastDeniedTarget = EMPTY_ENTITY_ID();
      TDODebug("Shrike", "mark removed " + ToString(ArraySize(this.m_tdoShrikeMarkedNPCs)) + "/" + ToString(TDO_Shrike_GetMaxMarks(this)));
      this.m_tdoShrikeAimHandled = true;
    }
  } else {
    let dist: Float = Vector4.Distance(this.GetWorldPosition(), lookAt.GetWorldPosition());
    if dist > TDO_Shrike_GetMarkRange() {
      if !Equals(this.m_tdoShrikeLastDeniedTarget, targetID) {
        this.m_tdoShrikeLastDeniedTarget = targetID;
        GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_crafting_fail");
      }
      TDO_Shrike_ScheduleMarkTick(this);
      return true;
    }
    if elapsed >= TDOConfig.ShrikeHoverTime() {
      if TDO_Shrike_IsOnCooldown(this, targetID, now) {
        if !Equals(this.m_tdoShrikeLastDeniedTarget, targetID) {
          this.m_tdoShrikeLastDeniedTarget = targetID;
          GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_crafting_fail");
          TDODebug("Shrike", "mark denied (cooldown)");
        }
      } else {
        let maxMarks: Int32 = TDO_Shrike_GetMaxMarks(this);
        TDO_Shrike_PruneMarks(this, now);
        if ArraySize(this.m_tdoShrikeMarkedNPCs) < maxMarks {
          ArrayPush(this.m_tdoShrikeMarkedNPCs, targetID);
          ArrayPush(this.m_tdoShrikeUnavailableSince, 0.0);
          TDO_Shrike_ApplyMarkHighlight(this, lookAt);
          GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_loot_rarity_legendary");
          this.m_tdoShrikeLastDeniedTarget = EMPTY_ENTITY_ID();
          TDODebug("Shrike", "mark added " + ToString(ArraySize(this.m_tdoShrikeMarkedNPCs)) + "/" + ToString(maxMarks));
          this.m_tdoShrikeAimHandled = true;
        } else {
          if !Equals(this.m_tdoShrikeLastDeniedTarget, targetID) {
            this.m_tdoShrikeLastDeniedTarget = targetID;
            GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_crafting_fail");
            TDODebug("Shrike", "mark denied (max " + ToString(maxMarks) + " reached)");
          }
        }
      }
    }
  }

  TDO_Shrike_ScheduleMarkTick(this);
  return true;
}

public func TDO_Shrike_GetEquippedTier(player: ref<PlayerPuppet>) -> Int32 {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return 0;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return 0;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tier: Int32 = TDO_Shrike_TierForItemTDB(ItemID.GetTDBID(itemID));
      if tier > 0 {
        return tier;
      }
    }
    slotIdx += 1;
  }
  return 0;
}

public func TDO_Shrike_GetMaxMarks(player: ref<PlayerPuppet>) -> Int32 {
  let tier: Int32 = TDO_Shrike_GetEquippedTier(player);
  if tier <= 0 {
    return 2;
  }
  return TDO_Shrike_MarksForTier(tier);
}

public func TDO_Shrike_GetMarkRange() -> Float {
  return MinF(TDOConfig.ShrikeMarkRange(), 30.0);
}

public func TDO_Shrike_ApplyMarkHighlight(player: ref<PlayerPuppet>, target: ref<GameObject>) -> Void {
  let highlightData: ref<FocusForcedHighlightData> = new FocusForcedHighlightData();
  highlightData.sourceID = player.GetEntityID();
  highlightData.sourceName = n"TDO_ShrikeMark";
  highlightData.priority = EPriority.VeryHigh;
  highlightData.inTransitionTime = 0.2;
  highlightData.outTransitionTime = 0.3;
  highlightData.highlightType = EFocusForcedHighlightType.DISTRACTION;
  highlightData.outlineType = EFocusOutlineType.DISTRACTION;
  highlightData.isRevealed = true;

  let evt: ref<ForceVisionApperanceEvent> = new ForceVisionApperanceEvent();
  evt.forcedHighlight = highlightData;
  evt.apply = true;
  target.QueueEvent(evt);
}

public func TDO_Shrike_RemoveMarkHighlight(player: ref<PlayerPuppet>, target: ref<GameObject>) -> Void {
  let highlightData: ref<FocusForcedHighlightData> = new FocusForcedHighlightData();
  highlightData.sourceID = player.GetEntityID();
  highlightData.sourceName = n"TDO_ShrikeMark";

  let evt: ref<ForceVisionApperanceEvent> = new ForceVisionApperanceEvent();
  evt.forcedHighlight = highlightData;
  evt.apply = false;
  evt.forceCancel = true;
  target.QueueEvent(evt);
}

public func TDO_Shrike_ClearPreparedState(player: ref<PlayerPuppet>) -> Void {
  let gi: GameInstance = player.GetGame();
  let i: Int32 = 0;
  while i < ArraySize(player.m_tdoShrikeMarkedNPCs) {
    let entity: wref<Entity> = GameInstance.FindEntityByID(gi, player.m_tdoShrikeMarkedNPCs[i]);
    let go: ref<GameObject> = entity as GameObject;
    if IsDefined(go) {
      TDO_Shrike_RemoveMarkHighlight(player, go);
    }
    i += 1;
  }
  ArrayClear(player.m_tdoShrikeMarkedNPCs);
  ArrayClear(player.m_tdoShrikeUnavailableSince);
  ArrayClear(player.m_tdoShrikeCooldownIDs);
  ArrayClear(player.m_tdoShrikeCooldownTimes);
  TDO_Shrike_ResetAim(player);
  player.m_tdoShrikeNextCleanup = 0.0;
}

public func TDO_Shrike_ClearMarks(player: ref<PlayerPuppet>) -> Void {
  TDO_Shrike_ClearPreparedState(player);
  player.m_tdoShrikePendingHitscanBullets = 0;
}

public func TDO_Shrike_Shutdown(player: ref<PlayerPuppet>) -> Void {
  TDO_Shrike_StopMarkTick(player);
  if TDO_Shrike_IsSandyActive(player) && ArraySize(player.m_tdoShrikeMarkedNPCs) > 0 {
    GameInstance.GetTargetingSystem(player.GetGame()).BreakLookAt(player);
  }
  TDO_Shrike_ClearMarks(player);
}

public func TDO_Shrike_Refresh(player: ref<PlayerPuppet>) -> Void {
  if TDOConfig.ShrikeEnabled() && TDO_Zetatech_IsEquipped(player) && !player.IsDead() && !player.IsReplacer() {
    TDO_Shrike_ScheduleMarkTick(player);
  } else {
    TDO_Shrike_Shutdown(player);
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Shrike_ClearPreparedMarks() -> Bool {
  if TDO_Shrike_IsSandyActive(this) {
    GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_crafting_fail");
    return false;
  }
  TDO_Shrike_ClearPreparedState(this);
  GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_disassemble");
  if TDOConfig.ShrikeEnabled() && TDO_Zetatech_IsEquipped(this) && !this.IsDead() && !this.IsReplacer() {
    TDO_Shrike_ScheduleMarkTick(this);
  }
  return true;
}

public func TDO_Shrike_GetExecuteDamagePct(target: ref<GameObject>) -> Float {
  let npc: ref<NPCPuppet> = target as NPCPuppet;
  if !IsDefined(npc) {
    return 100.0;
  }
  let rarity: gamedataNPCRarity = npc.GetNPCRarity();
  switch rarity {
    case gamedataNPCRarity.Trash: return TDOConfig.ShrikeExecuteDmgTrash();
    case gamedataNPCRarity.Weak: return TDOConfig.ShrikeExecuteDmgWeak();
    case gamedataNPCRarity.Normal: return TDOConfig.ShrikeExecuteDmgNormal();
    case gamedataNPCRarity.Rare: return TDOConfig.ShrikeExecuteDmgRare();
    case gamedataNPCRarity.Officer: return TDOConfig.ShrikeExecuteDmgOfficer();
    case gamedataNPCRarity.Elite: return TDOConfig.ShrikeExecuteDmgElite();
    case gamedataNPCRarity.MaxTac: return TDOConfig.ShrikeExecuteDmgMaxTac();
    case gamedataNPCRarity.Boss: return TDOConfig.ShrikeExecuteDmgBoss();
  }
  return 100.0;
}

public func TDO_Shrike_GetTargetChestPos(target: ref<GameObject>) -> Vector4 {
  let chestPos: Vector4;
  if AIActionHelper.GetTargetSlotPosition(target, n"Chest", chestPos) {
    return chestPos;
  }
  if AIActionHelper.GetTargetSlotPosition(target, n"Center", chestPos) {
    return chestPos;
  }
  return target.GetWorldPosition();
}

public func TDO_Shrike_HasLOSToTarget(player: ref<PlayerPuppet>, targetPos: Vector4) -> Bool {
  let cameraComp: ref<FPPCameraComponent> = player.GetFPPCameraComponent();
  if !IsDefined(cameraComp) {
    return false;
  }
  let cameraPos: Vector4 = Matrix.GetTranslation(cameraComp.GetLocalToWorld());
  let queriesSystem: ref<SpatialQueriesSystem> = GameInstance.GetSpatialQueriesSystem(player.GetGame());
  if !IsDefined(queriesSystem) {
    return false;
  }
  let traceResult: TraceResult;
  let hitStatic: Bool = queriesSystem.SyncRaycastByCollisionPreset(cameraPos, targetPos, n"World Static", traceResult, true);
  let hitDynamic: Bool = queriesSystem.SyncRaycastByCollisionPreset(cameraPos, targetPos, n"World Dynamic", traceResult, true);
  return !hitStatic && !hitDynamic;
}

public func TDO_Shrike_IsEligibleTarget(npc: ref<NPCPuppet>) -> Bool {
  return IsDefined(npc) && npc.IsEnemy() && !npc.IsDead() && !ScriptedPuppet.IsDefeated(npc) && !ScriptedPuppet.IsUnconscious(npc) && !GameObject.IsFriendlyTowardsPlayer(npc) && !ScriptedPuppet.IsPlayerCompanion(npc);
}

public func TDO_Shrike_PickBestMarkIndex(player: ref<PlayerPuppet>) -> Int32 {
  let gi: GameInstance = player.GetGame();
  let playerPos: Vector4 = player.GetWorldPosition();
  let bestIdx: Int32 = -1;
  let bestDist: Float = 1000000.0;
  let i: Int32 = 0;
  while i < ArraySize(player.m_tdoShrikeMarkedNPCs) {
    let markID: EntityID = player.m_tdoShrikeMarkedNPCs[i];
    let entity: wref<Entity> = GameInstance.FindEntityByID(gi, markID);
    let target: ref<GameObject> = entity as GameObject;
    if IsDefined(target) {
      let npc: ref<NPCPuppet> = target as NPCPuppet;
      if TDO_Shrike_IsEligibleTarget(npc) {
        let chestPos: Vector4 = TDO_Shrike_GetTargetChestPos(target);
        if TDO_Shrike_HasLOSToTarget(player, chestPos) {
          let dist: Float = Vector4.Distance(playerPos, target.GetWorldPosition());
          if dist < bestDist {
            bestDist = dist;
            bestIdx = i;
          }
        }
      }
    }
    i += 1;
  }
  return bestIdx;
}

public func TDO_Shrike_SnapAimToTarget(player: ref<PlayerPuppet>, targetPos: Vector4) -> Void {
  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(player.GetGame());
  if !IsDefined(targetingSystem) {
    return;
  }

  let aimRequest: AimRequest;
  aimRequest.lookAtTarget = targetPos;
  aimRequest.duration = 0.10;
  aimRequest.maxDuration = 0.20;
  aimRequest.easeIn = false;
  aimRequest.easeOut = false;
  aimRequest.precision = 0.01;
  aimRequest.adjustPitch = true;
  aimRequest.adjustYaw = true;
  aimRequest.checkRange = false;
  aimRequest.endOnCameraInputApplied = false;
  aimRequest.endOnTargetReached = false;
  aimRequest.endOnTimeExceeded = true;
  aimRequest.processAsInput = true;

  targetingSystem.BreakAimSnap(player);
  targetingSystem.LookAt(player, aimRequest);
}

public func TDO_Shrike_SnapToMarkAtIndex(player: ref<PlayerPuppet>, idx: Int32) -> Void {
  if idx < 0 || idx >= ArraySize(player.m_tdoShrikeMarkedNPCs) {
    return;
  }
  let gi: GameInstance = player.GetGame();
  let markID: EntityID = player.m_tdoShrikeMarkedNPCs[idx];
  let entity: wref<Entity> = GameInstance.FindEntityByID(gi, markID);
  let target: ref<GameObject> = entity as GameObject;
  if !TDO_Shrike_IsEligibleTarget(target as NPCPuppet) {
    return;
  }
  let chestPos: Vector4 = TDO_Shrike_GetTargetChestPos(target);
  TDO_Shrike_SnapAimToTarget(player, chestPos);
}

public func TDO_Shrike_ConsumeMark(player: ref<PlayerPuppet>, idx: Int32) -> Void {
  if idx < 0 || idx >= ArraySize(player.m_tdoShrikeMarkedNPCs) {
    return;
  }
  TDOInfo("Shrike", "execute mark idx=" + ToString(idx));
  let gi: GameInstance = player.GetGame();
  let markID: EntityID = player.m_tdoShrikeMarkedNPCs[idx];
  let entity: wref<Entity> = GameInstance.FindEntityByID(gi, markID);
  let target: ref<GameObject> = entity as GameObject;

  if IsDefined(target) {
    let npc: ref<NPCPuppet> = target as NPCPuppet;
    if TDO_Shrike_IsEligibleTarget(npc) {
      let pct: Float = TDO_Shrike_GetExecuteDamagePct(target);
      if pct >= 100.0 {
        npc.Kill(player, false, false);
      } else {
        let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
        let maxHP: Float = statsSystem.GetStatValue(Cast<StatsObjectID>(markID), gamedataStatType.Health);
        if maxHP > 0.0 {
          let damage: Float = maxHP * (pct / 100.0);
          let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
          let currentHP: Float = pools.GetStatPoolValue(Cast<StatsObjectID>(markID), gamedataStatPoolType.Health, false);
          if damage >= currentHP {
            npc.Kill(player, false, false);
          } else {
            pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(markID), gamedataStatPoolType.Health, -damage, player, false, false);
          }
        }
      }
    }
    TDO_Shrike_RemoveMarkHighlight(player, target);
  }

  ArrayErase(player.m_tdoShrikeMarkedNPCs, idx);
  ArrayErase(player.m_tdoShrikeUnavailableSince, idx);

  if ArraySize(player.m_tdoShrikeMarkedNPCs) == 0 {
    GameInstance.GetTargetingSystem(gi).BreakLookAt(player);
  }
}

@wrapMethod(ShootEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);

  if !TDOConfig.ShrikeEnabled() {
    return;
  }
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_Shrike_IsSandyActive(player) {
    return;
  }
  if !TDO_Zetatech_IsEquipped(player) {
    return;
  }
  if !TDO_Shrike_IsADS(player) {
    return;
  }
  if ArraySize(player.m_tdoShrikeMarkedNPCs) == 0 {
    return;
  }

  TDO_Shrike_PruneMarks(player, EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame())));
  let bestIdx: Int32 = TDO_Shrike_PickBestMarkIndex(player);
  if bestIdx < 0 {
    return;
  }
  TDO_Shrike_ConsumeMark(player, bestIdx);
  player.m_tdoShrikePendingHitscanBullets += 1;
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_Zetatech_IsEquipped(player) {
    return;
  }
  GameInstance.GetTargetingSystem(player.GetGame()).BreakLookAt(player);
  TDO_Shrike_ClearMarks(player);
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_Zetatech_IsEquipped(player) {
    return;
  }
  GameInstance.GetTargetingSystem(player.GetGame()).BreakLookAt(player);
  TDO_Shrike_ClearMarks(player);
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  TDO_Shrike_Shutdown(this);
  TDO_Shrike_Refresh(this);
  return result;
}

@wrapMethod(EquipmentSystemPlayerData)
private final func EquipItem(itemID: ItemID, slotIndex: Int32, opt blockActiveSlotsUpdate: Bool, opt forceEquipWeapon: Bool) -> Void {
  wrappedMethod(itemID, slotIndex, blockActiveSlotsUpdate, forceEquipWeapon);
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) {
    TDO_Shrike_Refresh(player);
  }
}

@wrapMethod(EquipmentSystemPlayerData)
private final func UnequipItem(equipAreaIndex: Int32, slotIndex: Int32, opt forceRemove: Bool) -> Void {
  wrappedMethod(equipAreaIndex, slotIndex, forceRemove);
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) {
    TDO_Shrike_Refresh(player);
  }
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnRestored() -> Void {
  wrappedMethod();
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) {
    TDO_Shrike_Refresh(player);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  TDO_Shrike_Shutdown(this);
  return wrappedMethod();
}

@wrapMethod(PlayerPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  TDO_Shrike_Shutdown(this);
  return wrappedMethod(evt);
}

@wrapMethod(SandevistanEvents)
protected final func OnExitToTimeDilationPhotomode(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && TDO_Zetatech_IsEquipped(player) {
    GameInstance.GetTargetingSystem(player.GetGame()).BreakLookAt(player);
    TDO_Shrike_ClearMarks(player);
  }
}

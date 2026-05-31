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

public func TDO_Shrike_IsSandyChargeFull(player: ref<PlayerPuppet>) -> Bool {
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(player.GetGame());
  return pools.HasStatPoolValueReachedMax(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.SandevistanCharge);
}

public class TDO_ShrikeMarkTickEvent extends Event {}

public func TDO_Shrike_ScheduleMarkTick(player: ref<PlayerPuppet>) -> Void {
  let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
  if player.m_tdoShrikeMarkTickID != GetInvalidDelayID() {
    delaySys.CancelDelay(player.m_tdoShrikeMarkTickID);
  }
  let evt: ref<TDO_ShrikeMarkTickEvent> = new TDO_ShrikeMarkTickEvent();
  player.m_tdoShrikeMarkTickID = delaySys.DelayEvent(player, evt, 0.05, false);
}

public func TDO_Shrike_StopMarkTick(player: ref<PlayerPuppet>) -> Void {
  if player.m_tdoShrikeMarkTickID != GetInvalidDelayID() {
    let delaySys: ref<DelaySystem> = GameInstance.GetDelaySystem(player.GetGame());
    delaySys.CancelDelay(player.m_tdoShrikeMarkTickID);
    player.m_tdoShrikeMarkTickID = GetInvalidDelayID();
  }
}

@addMethod(PlayerPuppet)
protected cb func OnTDO_ShrikeMarkTickEvent(evt: ref<TDO_ShrikeMarkTickEvent>) -> Bool {
  this.m_tdoShrikeMarkTickID = GetInvalidDelayID();

  let isShrike: Bool = TDO_Zetatech_IsEquipped(this);
  let inSandy: Bool = TDO_Shrike_IsSandyActive(this);
  let isADS: Bool = TDO_Shrike_IsADS(this);

  if !TDOConfig.ShrikeEnabled() {
    return true;
  }
  if !isShrike {
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  if inSandy && isADS && ArraySize(this.m_tdoShrikeMarkedNPCs) > 0 {
    let bestIdx: Int32 = TDO_Shrike_PickBestMarkIndex(this);
    if bestIdx >= 0 {
      TDO_Shrike_SnapToMarkAtIndex(this, bestIdx);
    }
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let chargeFull: Bool = TDO_Shrike_IsSandyChargeFull(this);

  if inSandy || !chargeFull {
    this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  if !isADS {
    this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(this.GetGame());
  let lookAt: ref<GameObject> = targetingSystem.GetLookAtObject(this, true, true);
  if !IsDefined(lookAt) {
    this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let npc: ref<NPCPuppet> = lookAt as NPCPuppet;
  if !IsDefined(npc) || npc.IsDead() || ScriptedPuppet.IsDefeated(lookAt) {
    this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let dist: Float = Vector4.Distance(this.GetWorldPosition(), lookAt.GetWorldPosition());
  if dist > MinF(TDOConfig.ShrikeMarkRange(), 30.0) {
    let deniedID: EntityID = lookAt.GetEntityID();
    if !Equals(this.m_tdoShrikeLastDeniedTarget, deniedID) {
      this.m_tdoShrikeLastDeniedTarget = deniedID;
      GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_crafting_fail");
    }
    this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  let targetID: EntityID = lookAt.GetEntityID();
  let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));

  if ArrayContains(this.m_tdoShrikeMarkedNPCs, targetID) {
    this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
    TDO_Shrike_ScheduleMarkTick(this);
    return true;
  }

  if !Equals(this.m_tdoShrikeHoveredNPC, targetID) {
    this.m_tdoShrikeHoveredNPC = targetID;
    this.m_tdoShrikeHoverStartTime = now;
  }

  let elapsed: Float = now - this.m_tdoShrikeHoverStartTime;
  if elapsed >= TDOConfig.ShrikeHoverTime() {
    let maxMarks: Int32 = TDO_Shrike_GetMaxMarks(this);
    if ArraySize(this.m_tdoShrikeMarkedNPCs) < maxMarks {
      ArrayPush(this.m_tdoShrikeMarkedNPCs, targetID);
      TDO_Shrike_ApplyMarkHighlight(this, lookAt);
      GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_loot_rarity_legendary");
      this.m_tdoShrikeLastDeniedTarget = EMPTY_ENTITY_ID();
      TDODebug("Shrike", "mark added " + ToString(ArraySize(this.m_tdoShrikeMarkedNPCs)) + "/" + ToString(maxMarks));
    } else {
      if !Equals(this.m_tdoShrikeLastDeniedTarget, targetID) {
        this.m_tdoShrikeLastDeniedTarget = targetID;
        GameInstance.GetAudioSystem(this.GetGame()).Play(n"ui_menu_item_crafting_fail");
        TDODebug("Shrike", "mark denied (max " + ToString(maxMarks) + " reached)");
      }
    }
    this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
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

public func TDO_Shrike_ClearMarks(player: ref<PlayerPuppet>) -> Void {
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
  player.m_tdoShrikePendingHitscanBullets = 0;
  player.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
  player.m_tdoShrikeLastDeniedTarget = EMPTY_ENTITY_ID();
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
      if IsDefined(npc) && !npc.IsDead() && !ScriptedPuppet.IsDefeated(target) {
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
  if !IsDefined(target) {
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
    let isDead: Bool = IsDefined(npc) && npc.IsDead();
    if !isDead && IsDefined(npc) {
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
  ArrayClear(this.m_tdoShrikeMarkedNPCs);
  this.m_tdoShrikePendingHitscanBullets = 0;
  this.m_tdoShrikeHoveredNPC = EMPTY_ENTITY_ID();
  this.m_tdoShrikeLastDeniedTarget = EMPTY_ENTITY_ID();
  if TDOConfig.ShrikeEnabled() {
    TDO_Shrike_ScheduleMarkTick(this);
  }
  return result;
}

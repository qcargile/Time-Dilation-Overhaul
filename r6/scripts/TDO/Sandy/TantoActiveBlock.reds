module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoTantoIsBlocking: Bool;

@addField(PlayerPuppet)
public let m_tdoTantoCritMarkedNPCs: array<EntityID>;

public func TDO_Tanto_GetEquippedTierIndex(player: ref<PlayerPuppet>) -> Int32 {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return -1;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return -1;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tdb: TweakDBID = ItemID.GetTDBID(itemID);
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK1") { return 0; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK1Plus") { return 1; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK2") { return 2; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK2Plus") { return 3; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK3") { return 4; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK3Plus") { return 5; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK4") { return 6; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK4Plus") { return 7; }
      if Equals(tdb, t"Items.AdvancedSandevistanC2MK4PlusPlus") { return 8; }
    }
    slotIdx += 1;
  }
  return -1;
}

public func TDO_Tanto_IsSandyActive(player: ref<PlayerPuppet>) -> Bool {
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) {
    return false;
  }
  let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
  return td == EnumInt(gamePSMTimeDilation.Sandevistan);
}

public func TDO_Tanto_IsBladeActive(player: ref<PlayerPuppet>) -> Bool {
  let weapon: wref<WeaponObject> = GameObject.GetActiveWeapon(player);
  if !IsDefined(weapon) {
    return false;
  }
  return weapon.IsBlade();
}

@wrapMethod(MeleeBlockEvents)
public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  player.m_tdoTantoIsBlocking = true;
}

@wrapMethod(MeleeBlockEvents)
public func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  player.m_tdoTantoIsBlocking = false;
}

@wrapMethod(DamageSystem)
private final func ProcessBlockAndDeflect(hitEvent: ref<gameHitEvent>) -> Void {
  wrappedMethod(hitEvent);
  if !TDOConfig.TantoEnabled() {
    return;
  }
  let target: ref<GameObject> = hitEvent.target;
  if !IsDefined(target) || !target.IsPlayer() {
    return;
  }
  let player: ref<PlayerPuppet> = target as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !hitEvent.attackData.WasDeflected() {
    return;
  }
  if TDO_Tanto_IsSandyActive(player) {
    return;
  }
  if !TDO_Tanto_IsBladeActive(player) || TDO_Tanto_GetEquippedTierIndex(player) < 0 {
    return;
  }
  let system: ref<TantoChargeSystem> = TantoChargeSystem.GetInstance(player.GetGame());
  if !IsDefined(system) {
    return;
  }
  if system.TryAddCharge(player) {
    GameObject.PlaySoundEventWithParams(player, n"w_melee_perk_finisher_ready", audioAudioEventFlags.Music, audioEventActionType.Play);
    StatusEffectHelper.ApplyStatusEffect(player, t"StatusEffects.TDO_TantoChargeIndicator");
  }
}

@wrapMethod(DisableSandevistanAction)
public func StartAction(gameInstance: GameInstance) -> Void {
  let player: ref<PlayerPuppet> = this.GetExecutor() as PlayerPuppet;
  if IsDefined(player) && TDO_Tanto_TryTeleport(player) {
    return;
  }
  wrappedMethod(gameInstance);
}

public func TDO_Tanto_TryTeleport(player: ref<PlayerPuppet>) -> Bool {
  if !TDOConfig.TantoEnabled() {
    return false;
  }
  if TDO_IsPlayerInVehicle(player) {
    return false;
  }
  if !TDO_Tanto_IsSandyActive(player) {
    return false;
  }
  if TDO_Tanto_GetEquippedTierIndex(player) < 0 {
    return false;
  }
  if !player.m_tdoTantoIsBlocking {
    return false;
  }
  let system: ref<TantoChargeSystem> = TantoChargeSystem.GetInstance(player.GetGame());
  if !IsDefined(system) || system.GetCharges(player) <= 0 {
    return false;
  }
  let target: ref<NPCPuppet> = TDO_Tanto_FindTeleportTarget(player, system.GetRange(player));
  if !IsDefined(target) {
    TDODebug("Tanto", "Phantom Strike: no valid target in range");
    return true;
  }
  TDO_Tanto_ExecuteTeleport(player, target);
  system.ConsumeCharge(player);
  if system.GetCharges(player) <= 0 {
    StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_TantoChargeIndicator");
  }
  return true;
}

public func TDO_Tanto_FindTeleportTarget(player: ref<PlayerPuppet>, range: Float) -> ref<NPCPuppet> {
  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(player.GetGame());
  let lookAt: ref<GameObject> = targetingSystem.GetLookAtObject(player, true, true);
  if !IsDefined(lookAt) {
    return null;
  }
  let npc: ref<NPCPuppet> = lookAt as NPCPuppet;
  if !IsDefined(npc) || npc.IsDead() || !npc.IsHostile() {
    return null;
  }
  let dist: Float = Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition());
  if dist > range {
    return null;
  }
  return npc;
}

public func TDO_Tanto_ExecuteTeleport(player: ref<PlayerPuppet>, target: ref<NPCPuppet>) -> Void {
  let targetPos: Vector4 = target.GetWorldPosition();
  let targetForward: Vector4 = target.GetWorldForward();
  targetForward.Z = 0.0;
  targetForward = Vector4.Normalize(targetForward);
  let offset: Float = TDOConfig.TantoTeleportBehindOffset();
  let finalPos: Vector4 = targetPos - (targetForward * offset);
  finalPos.Z = targetPos.Z;
  let finalRot: EulerAngles = Vector4.ToRotation(targetForward);
  GameInstance.GetTeleportationFacility(player.GetGame()).Teleport(player, finalPos, finalRot);
  TDOInfo("Tanto", "Phantom Strike teleport behind id=" + ToString(target.GetEntityID()));
  GameObjectEffectHelper.StartEffectEvent(player, n"dash");

  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if IsDefined(fxSystem) {
    let sandyRef: ResourceAsyncRef = new ResourceAsyncRef();
    ResourceAsyncRef.SetPath(sandyRef, r"base\\fx\\characters\\npc\\abilities\\ch_npc_sandevistan_left.effect");
    let sandyFx: FxResource;
    sandyFx.effect = sandyRef;
    let playerWorldPos: WorldPosition;
    WorldPosition.SetVector4(playerWorldPos, player.GetWorldPosition());
    let playerTransform: WorldTransform;
    WorldTransform.SetWorldPosition(playerTransform, playerWorldPos);
    WorldTransform.SetOrientationFromDir(playerTransform, player.GetWorldForward());
    fxSystem.SpawnEffect(sandyFx, playerTransform, true);

    let glitchRef: ResourceAsyncRef = new ResourceAsyncRef();
    ResourceAsyncRef.SetPath(glitchRef, r"base\\fx\\quest\\q110\\q110_13_alt_intro\\q110_cyberspace_warp_glitch.effect");
    let glitchFx: FxResource;
    glitchFx.effect = glitchRef;
    fxSystem.SpawnEffect(glitchFx, playerTransform, true);
  }

  StatusEffectHelper.ApplyStatusEffect(player, t"StatusEffects.TDO_TantoTeleportCrit");
}

@wrapMethod(DamageSystem)
private final func ProcessHitReaction(hitEvent: ref<gameHitEvent>) -> Void {
  wrappedMethod(hitEvent);
  if !TDOConfig.TantoEnabled() {
    return;
  }
  let instigator: wref<GameObject> = hitEvent.attackData.GetInstigator();
  if !IsDefined(instigator) || !instigator.IsPlayer() {
    return;
  }
  let player: ref<PlayerPuppet> = instigator as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  let victim: ref<GameObject> = hitEvent.target;
  if !IsDefined(victim) || victim.IsPlayer() {
    return;
  }
  let isMelee: Bool = AttackData.IsMelee(hitEvent.attackData.GetAttackType());

  if TDO_Tanto_IsBladeActive(player) && TDO_Tanto_GetEquippedTierIndex(player) >= 0 {
    let npcVictim: ref<NPCPuppet> = victim as NPCPuppet;
    if IsDefined(npcVictim) && npcVictim.IsHostile() && !npcVictim.IsDead() {
      let isFinisher: Bool = hitEvent.attackData.HasFlag(hitFlag.FinisherTriggered);
      let isCrit: Bool = isMelee && hitEvent.attackData.HasFlag(hitFlag.CriticalHit);
      let critUsed: Bool = IsDefined(StatusEffectHelper.GetStatusEffectByID(npcVictim, t"StatusEffects.TDO_TantoCritChargeUsed"));
      if isFinisher || (isCrit && !critUsed) {
        let system: ref<TantoChargeSystem> = TantoChargeSystem.GetInstance(player.GetGame());
        if IsDefined(system) && system.TryAddCharge(player) {
          if isCrit && !isFinisher {
            StatusEffectHelper.ApplyStatusEffect(npcVictim, t"StatusEffects.TDO_TantoCritChargeUsed");
            if !ArrayContains(player.m_tdoTantoCritMarkedNPCs, npcVictim.GetEntityID()) {
              ArrayPush(player.m_tdoTantoCritMarkedNPCs, npcVictim.GetEntityID());
            }
          }
          GameObject.PlaySoundEventWithParams(player, n"w_melee_perk_finisher_ready", audioAudioEventFlags.Music, audioEventActionType.Play);
          StatusEffectHelper.ApplyStatusEffect(player, t"StatusEffects.TDO_TantoChargeIndicator");
        }
      }
    }
  }

  if !isMelee {
    return;
  }
  let mark: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(player, t"StatusEffects.TDO_TantoTeleportCrit");
  if !IsDefined(mark) {
    return;
  }
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_TantoTeleportCrit");
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !TDO_Tanto_IsEquipped(player) {
    return;
  }
  let gi: GameInstance = player.GetGame();
  let i: Int32 = 0;
  while i < ArraySize(player.m_tdoTantoCritMarkedNPCs) {
    let npc: wref<NPCPuppet> = GameInstance.FindEntityByID(gi, player.m_tdoTantoCritMarkedNPCs[i]) as NPCPuppet;
    if IsDefined(npc) {
      StatusEffectHelper.RemoveStatusEffect(npc, t"StatusEffects.TDO_TantoCritChargeUsed");
    }
    i += 1;
  }
  ArrayClear(player.m_tdoTantoCritMarkedNPCs);
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_TantoTeleportCrit");
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_TantoTeleportCrit");
}

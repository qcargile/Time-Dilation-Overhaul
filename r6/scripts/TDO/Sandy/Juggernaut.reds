module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_juggernautActive: Bool;

@addField(PlayerPuppet)
public let m_juggernautAbsorbed: Float;

@addField(PlayerPuppet)
public let m_juggernautTier: Int32;

@addField(PlayerPuppet)
public let m_juggernautReleaseCallbackId: DelayID;

@addField(PlayerPuppet)
public let m_juggernautShieldFx: ref<FxInstance>;

public func TDO_Juggernaut_GetLockDuration(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.JuggernautLockDurationMin(), TDOConfig.JuggernautLockDurationMax(), tier, 5);
}

public func TDO_Juggernaut_GetMaxRadius(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.JuggernautRadiusMin(), TDOConfig.JuggernautRadiusMax(), tier, 5);
}

public func TDO_Juggernaut_GetAbsorbCap(tier: Int32) -> Float {
  switch tier {
    case 1: return 500.0;
    case 2: return 1000.0;
    case 3: return 1500.0;
    case 4: return 1500.0;
    case 5: return 1500.0;
  }
  return 500.0;
}

public func TDO_Juggernaut_GetCooldownSE(tier: Int32) -> TweakDBID {
  switch tier {
    case 1: return t"StatusEffects.TDO_JuggernautCooldown_T1";
    case 2: return t"StatusEffects.TDO_JuggernautCooldown_T2";
    case 3: return t"StatusEffects.TDO_JuggernautCooldown_T3";
    case 4: return t"StatusEffects.TDO_JuggernautCooldown_T4";
    case 5: return t"StatusEffects.TDO_JuggernautCooldown_T5";
  }
  return t"StatusEffects.TDO_JuggernautCooldown_T1";
}

@addMethod(PlayerPuppet)
public func TDO_Juggernaut_GetEquippedTier() -> Int32 {
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
      let tier: Int32 = TDO_Juggernaut_TierForItemTDB(ItemID.GetTDBID(itemID));
      if tier > 0 { return tier; }
    }
    slotIdx += 1;
  }
  return 0;
}

@addMethod(PlayerPuppet)
public func TDO_Juggernaut_OnActivate(tier: Int32) -> Void {
  if this.m_juggernautActive {
    this.TDO_Juggernaut_Release();
    return;
  }
  if TDO_IsPlayerInVehicle(this) {
    return;
  }
  if !TDOConfig.JuggernautEnabled() {
    return;
  }
  if this.TDO_Juggernaut_IsOnCooldown() {
    TDODebug("Juggernaut", "activate blocked: on cooldown");
    GameObject.PlaySoundEvent(this, n"ui_hacking_access_denied");
    return;
  }
  this.TDO_Juggernaut_Engage(tier);
}

@addMethod(PlayerPuppet)
public func TDO_Juggernaut_IsOnCooldown() -> Bool {
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_JuggernautCooldown_T1") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_JuggernautCooldown_T2") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_JuggernautCooldown_T3") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_JuggernautCooldown_T4") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_JuggernautCooldown_T5") { return true; }
  return false;
}

@addMethod(PlayerPuppet)
public func TDO_Juggernaut_Engage(tier: Int32) -> Void {
  this.m_juggernautActive = true;
  this.m_juggernautAbsorbed = 0.0;
  this.m_juggernautTier = tier;
  TDOInfo("Juggernaut", "Armor Lock engaged tier=" + ToString(tier));

  StatusEffectHelper.ApplyStatusEffect(this, t"StatusEffects.TDO_JuggernautActive");
  StatusEffectHelper.ApplyStatusEffect(this, t"GameplayRestriction.NoCombat");

  TDO_Juggernaut_SpawnActivationVFX(this);
  this.m_juggernautShieldFx = TDO_Juggernaut_SpawnShieldVFX(this);

  GameObject.PlaySoundEvent(this, n"q000_sc_03_kerry_chooses_path_phone");

  let lockDur: Float = TDO_Juggernaut_GetLockDuration(tier);
  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  let callback: ref<TDO_JuggernautReleaseCallback> = new TDO_JuggernautReleaseCallback();
  callback.player = this;
  this.m_juggernautReleaseCallbackId = delaySystem.DelayCallback(callback, lockDur, false);
}

public func TDO_Juggernaut_SpawnFxAt(player: ref<PlayerPuppet>, path: ResRef, origin: Vector4) -> Void {
  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if !IsDefined(fxSystem) {
    return;
  }
  let raRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(raRef, path);
  let fxRes: FxResource;
  fxRes.effect = raRef;
  let position: WorldPosition;
  WorldPosition.SetVector4(position, origin);
  let transform: WorldTransform;
  WorldTransform.SetWorldPosition(transform, position);
  WorldTransform.SetOrientationFromDir(transform, player.GetWorldForward());
  fxSystem.SpawnEffect(fxRes, transform, true);
}

public func TDO_Juggernaut_SpawnActivationVFX(player: ref<PlayerPuppet>) -> Void {
  TDO_Juggernaut_SpawnFxAt(player, r"base\\fx\\gameplay\\perks\\cyberware_explosion\\cyberware_explosion.effect", player.GetWorldPosition());
}

public func TDO_Juggernaut_SpawnShieldVFX(player: ref<PlayerPuppet>) -> ref<FxInstance> {
  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if !IsDefined(fxSystem) {
    return null;
  }
  let raRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(raRef, r"base\\fx\\player\\cyberware\\nano_tech_plates\\damage_high_nano.effect");
  let fxRes: FxResource;
  fxRes.effect = raRef;
  let position: WorldPosition;
  WorldPosition.SetVector4(position, player.GetWorldPosition());
  let transform: WorldTransform;
  WorldTransform.SetWorldPosition(transform, position);
  WorldTransform.SetOrientationFromDir(transform, player.GetWorldForward());
  let fxInstance: ref<FxInstance> = fxSystem.SpawnEffect(fxRes, transform, true);
  if IsDefined(fxInstance) {
    fxInstance.AttachToSlot(player, entAttachmentTarget.Transform, n"Chest");
  }
  return fxInstance;
}

public func TDO_Juggernaut_SpawnShockwaveVFX(player: ref<PlayerPuppet>) -> Void {
  TDO_Juggernaut_SpawnFxAt(player, r"base\\fx\\gameplay\\perks\\cyberware_explosion\\cyberware_explosion.effect", player.GetWorldPosition());
}

public func TDO_Juggernaut_SpawnAbsorbVFX(player: ref<PlayerPuppet>, hitPos: Vector4) -> Void {
  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if !IsDefined(fxSystem) {
    return;
  }

  let nanoRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(nanoRef, r"base\\fx\\player\\cyberware\\nano_tech_plates\\damage_high_nano.effect");
  let nanoRes: FxResource;
  nanoRes.effect = nanoRef;
  let nanoPos: WorldPosition;
  WorldPosition.SetVector4(nanoPos, player.GetWorldPosition());
  let nanoTransform: WorldTransform;
  WorldTransform.SetWorldPosition(nanoTransform, nanoPos);
  WorldTransform.SetOrientationFromDir(nanoTransform, player.GetWorldForward());
  let nanoFx: ref<FxInstance> = fxSystem.SpawnEffect(nanoRes, nanoTransform, true);
  if IsDefined(nanoFx) {
    nanoFx.AttachToSlot(player, entAttachmentTarget.Transform, n"Chest");
  }

  let hitRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(hitRef, r"base\\fx\\quest\\q110\\elders_lair\\sparks_burst_small_train.effect");
  let hitRes: FxResource;
  hitRes.effect = hitRef;
  let hitWorldPos: WorldPosition;
  WorldPosition.SetVector4(hitWorldPos, hitPos);
  let hitTransform: WorldTransform;
  WorldTransform.SetWorldPosition(hitTransform, hitWorldPos);
  WorldTransform.SetOrientationFromDir(hitTransform, player.GetWorldForward());
  fxSystem.SpawnEffect(hitRes, hitTransform, true);

  let glitchRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(glitchRef, r"base\\gameplay\\devices\\frames\\base\\frameglitch.effect");
  let glitchRes: FxResource;
  glitchRes.effect = glitchRef;
  let glitchPos: WorldPosition;
  WorldPosition.SetVector4(glitchPos, player.GetWorldPosition());
  let glitchTransform: WorldTransform;
  WorldTransform.SetWorldPosition(glitchTransform, glitchPos);
  WorldTransform.SetOrientationFromDir(glitchTransform, player.GetWorldForward());
  let glitchFx: ref<FxInstance> = fxSystem.SpawnEffect(glitchRes, glitchTransform, true);
  if IsDefined(glitchFx) {
    glitchFx.AttachToSlot(player, entAttachmentTarget.Transform, n"Chest");
  }
}

@addMethod(PlayerPuppet)
public func TDO_Juggernaut_Release() -> Void {
  if !this.m_juggernautActive {
    return;
  }
  this.m_juggernautActive = false;
  TDOInfo("Juggernaut", "kinetic burst released tier=" + ToString(this.m_juggernautTier) + " absorbed=" + FloatToStringPrec(this.m_juggernautAbsorbed, 0));

  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  if this.m_juggernautReleaseCallbackId != GetInvalidDelayID() {
    delaySystem.CancelCallback(this.m_juggernautReleaseCallbackId);
    this.m_juggernautReleaseCallbackId = GetInvalidDelayID();
  }

  StatusEffectHelper.RemoveStatusEffect(this, t"StatusEffects.TDO_JuggernautActive");
  StatusEffectHelper.RemoveStatusEffect(this, t"GameplayRestriction.NoCombat");

  if IsDefined(this.m_juggernautShieldFx) {
    this.m_juggernautShieldFx.BreakLoop();
    this.m_juggernautShieldFx = null;
  }

  if this.m_juggernautAbsorbed > 0.0 {
    TDO_Juggernaut_SpawnShockwaveVFX(this);
  }

  this.TDO_Juggernaut_FireBurst();

  let cooldownSE: TweakDBID = TDO_Juggernaut_GetCooldownSE(this.m_juggernautTier);
  StatusEffectHelper.ApplyStatusEffect(this, cooldownSE);

  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.SandevistanCharge, -100.0, this, false);

  if this.m_juggernautAbsorbed > 0.0 {
    GameObject.PlaySoundEvent(this, n"v_quest_act3_judy_clouds_v");
  }

  this.m_juggernautAbsorbed = 0.0;
}

public func TDO_Juggernaut_GetDamageMult(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.JuggernautDamageMultMin(), TDOConfig.JuggernautDamageMultMax(), tier, 5);
}

@addMethod(PlayerPuppet)
public func TDO_Juggernaut_FireBurst() -> Void {
  let absorbed: Float = this.m_juggernautAbsorbed;
  if absorbed <= 0.0 {
    return;
  }

  let tier: Int32 = this.m_juggernautTier;
  let radius: Float = TDO_Juggernaut_GetMaxRadius(tier);
  let outgoingDamage: Float = MinF(absorbed * TDO_Juggernaut_GetDamageMult(tier), TDOConfig.JuggernautMaxBurstDamage());

  let center: Vector4 = this.GetWorldPosition();
  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(this.GetGame());
  let query: TargetSearchQuery;
  query.testedSet = TargetingSet.Complete;
  query.searchFilter = TSF_EnemyNPC();
  query.maxDistance = radius;
  query.includeSecondaryTargets = false;
  query.ignoreInstigator = true;

  let parts: array<TS_TargetPartInfo>;
  targetingSystem.GetTargetParts(this, query, parts);

  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  let seenIDs: array<EntityID>;
  let i: Int32 = 0;
  while i < ArraySize(parts) {
    let component: ref<IComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
    if IsDefined(component) {
      let entity: ref<Entity> = component.GetEntity();
      let npc: ref<NPCPuppet> = entity as NPCPuppet;
      if IsDefined(npc) {
        let npcID: EntityID = npc.GetEntityID();
        if !ArrayContains(seenIDs, npcID) {
          ArrayPush(seenIDs, npcID);
          pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(npcID), gamedataStatPoolType.Health, -outgoingDamage, this, false, false);
          StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.Knockdown", this.GetEntityID());
          let impulse: ref<PSMImpulse> = new PSMImpulse();
          impulse.id = n"impulse";
          let dir: Vector4 = npc.GetWorldPosition() - center;
          dir.Z = 0.0;
          dir = Vector4.Normalize(dir);
          impulse.impulse = dir * 300.0;
          npc.QueueEvent(impulse);
        }
      }
    }
    i += 1;
  }
}

@wrapMethod(StatPoolsManager)
public final static func ApplyDamage(hitEvent: ref<gameHitEvent>, forReal: Bool, out valuesLost: array<SDamageDealt>) -> Void {
  if !forReal {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let target: ref<GameObject> = hitEvent.target;
  if !IsDefined(target) || !target.IsPlayer() {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let player: ref<PlayerPuppet> = target as PlayerPuppet;
  if !IsDefined(player) || !player.m_juggernautActive {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let damageValue: Float = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
  if damageValue <= 0.0 {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  player.m_juggernautAbsorbed += damageValue;
  let attackValues: array<Float> = hitEvent.attackComputed.GetAttackValues();
  let i: Int32 = 0;
  while i < ArraySize(attackValues) {
    attackValues[i] = 0.0;
    i += 1;
  }
  hitEvent.attackComputed.SetAttackValues(attackValues);
  TDO_Juggernaut_SpawnAbsorbVFX(player, hitEvent.hitPosition);
  wrappedMethod(hitEvent, forReal, valuesLost);

  let absorbCap: Float = TDO_Juggernaut_GetAbsorbCap(player.m_juggernautTier);
  if player.m_juggernautAbsorbed >= absorbCap {
    player.TDO_Juggernaut_Release();
  }
}

@wrapMethod(UseHealChargeAction)
public func CompleteAction(gameInstance: GameInstance) -> Void {
  let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(gameInstance);
}

@wrapMethod(CombatGadgetEquipEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(CombatGadgetQuickThrowEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(CombatGadgetChargedThrowEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(CombatGadgetChargeEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(CombatGadgetEquipEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(timeDelta, stateContext, scriptInterface);
}

@wrapMethod(CombatGadgetQuickThrowEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(timeDelta, stateContext, scriptInterface);
}

@wrapMethod(CombatGadgetChargedThrowEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(timeDelta, stateContext, scriptInterface);
}

@wrapMethod(CombatGadgetChargeEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(timeDelta, stateContext, scriptInterface);
}

@wrapMethod(CrouchEvents)
public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(MeleeAttackGenericEvents)
public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(QuickMeleeEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(MeleeBlockEvents)
public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(MeleeDeflectEvents)
public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(DodgeEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(DodgeAirEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(ClimbEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(VaultEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(ShootEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(ReloadEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.m_juggernautActive {
    return;
  }
  wrappedMethod(stateContext, scriptInterface);
}

public class TDO_JuggernautReleaseCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if IsDefined(this.player) && this.player.m_juggernautActive {
      this.player.TDO_Juggernaut_Release();
    }
  }
}

@wrapMethod(PlayerPuppet)
protected func OnIncapacitated() -> Void {
  wrappedMethod();
  if this.m_juggernautActive {
    this.TDO_Juggernaut_Release();
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  StatusEffectHelper.RemoveStatusEffect(this, t"GameplayRestriction.NoCombat");
  return result;
}

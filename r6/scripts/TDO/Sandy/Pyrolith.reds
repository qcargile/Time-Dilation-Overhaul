module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_pyrolithActive: Bool;

@addField(PlayerPuppet)
public let m_pyrolithTier: Int32;

@addField(PlayerPuppet)
public let m_pyrolithReleaseCallbackId: DelayID;

@addField(PlayerPuppet)
public let m_pyrolithLastClusterTime: Float;

@addField(PlayerPuppet)
public let m_pyrolithLastClusterScalar: Float;

@addField(PlayerPuppet)
public let m_pyrolithOriginalGrenadeID: EntityID;

@addField(PlayerPuppet)
public let m_pyrolithBuffFx: ref<FxInstance>;

public func TDO_Pyrolith_GetActiveDuration(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.PyrolithDurationMin(), TDOConfig.PyrolithDurationMax(), tier, 5);
}

public func TDO_Pyrolith_GetBulletExplosionRadius(tier: Int32) -> Float {
  switch tier {
    case 1: return TDOConfig.PyrolithBulletExplosionRadius_T1();
    case 2: return TDOConfig.PyrolithBulletExplosionRadius_T2();
    case 3: return TDOConfig.PyrolithBulletExplosionRadius_T3();
    case 4: return TDOConfig.PyrolithBulletExplosionRadius_T4();
    case 5: return TDOConfig.PyrolithBulletExplosionRadius_T5();
  }
  return TDOConfig.PyrolithBulletExplosionRadius_T1();
}

public func TDO_Pyrolith_GetCooldownSE(tier: Int32) -> TweakDBID {
  switch tier {
    case 1: return t"StatusEffects.TDO_PyrolithCooldown_T1";
    case 2: return t"StatusEffects.TDO_PyrolithCooldown_T2";
    case 3: return t"StatusEffects.TDO_PyrolithCooldown_T3";
    case 4: return t"StatusEffects.TDO_PyrolithCooldown_T4";
    case 5: return t"StatusEffects.TDO_PyrolithCooldown_T5";
  }
  return t"StatusEffects.TDO_PyrolithCooldown_T1";
}

public func TDO_Pyrolith_GetExplosionDamage(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.PyrolithExplosionDamageMin(), TDOConfig.PyrolithExplosionDamageMax(), tier, 5);
}

public func TDO_Pyrolith_GetClusterCount(tier: Int32) -> Int32 {
  return Cast<Int32>(TDOConfig.LerpTier(TDOConfig.PyrolithClusterCountMin(), TDOConfig.PyrolithClusterCountMax(), tier, 5) + 0.5);
}

public func TDO_Pyrolith_GetClusterDamageScalar(tier: Int32) -> Float {
  switch tier {
    case 1: return TDOConfig.PyrolithClusterDamageScalar_T1();
    case 2: return TDOConfig.PyrolithClusterDamageScalar_T2();
    case 3: return TDOConfig.PyrolithClusterDamageScalar_T3();
    case 4: return TDOConfig.PyrolithClusterDamageScalar_T4();
    case 5: return TDOConfig.PyrolithClusterDamageScalar_T5();
  }
  return TDOConfig.PyrolithClusterDamageScalar_T1();
}

public func TDO_Pyrolith_GetThrowVelocityMultiplier(tier: Int32) -> Float {
  switch tier {
    case 1: return TDOConfig.PyrolithThrowVelocityMultiplier_T1();
    case 2: return TDOConfig.PyrolithThrowVelocityMultiplier_T2();
    case 3: return TDOConfig.PyrolithThrowVelocityMultiplier_T3();
    case 4: return TDOConfig.PyrolithThrowVelocityMultiplier_T4();
    case 5: return TDOConfig.PyrolithThrowVelocityMultiplier_T5();
  }
  return TDOConfig.PyrolithThrowVelocityMultiplier_T1();
}

@addMethod(PlayerPuppet)
public func TDO_Pyrolith_GetEquippedTier() -> Int32 {
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
      let tier: Int32 = TDO_Pyrolith_TierForItemTDB(ItemID.GetTDBID(itemID));
      if tier > 0 { return tier; }
    }
    slotIdx += 1;
  }
  return 0;
}

@addMethod(PlayerPuppet)
public func TDO_Pyrolith_OnActivate(tier: Int32) -> Void {
  if this.m_pyrolithActive {
    this.TDO_Pyrolith_End();
    return;
  }
  if !TDOConfig.PyrolithEnabled() {
    return;
  }
  if this.TDO_Pyrolith_IsOnCooldown() {
    TDODebug("Pyrolith", "activate blocked: on cooldown");
    GameObject.PlaySoundEvent(this, n"ui_hacking_access_denied");
    return;
  }
  this.TDO_Pyrolith_Engage(tier);
}

@addMethod(PlayerPuppet)
public func TDO_Pyrolith_IsOnCooldown() -> Bool {
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_PyrolithCooldown_T1") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_PyrolithCooldown_T2") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_PyrolithCooldown_T3") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_PyrolithCooldown_T4") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(this, t"StatusEffects.TDO_PyrolithCooldown_T5") { return true; }
  return false;
}

@addMethod(PlayerPuppet)
public func TDO_Pyrolith_Engage(tier: Int32) -> Void {
  this.m_pyrolithActive = true;
  this.m_pyrolithTier = tier;
  TDOInfo("Pyrolith", "engaged tier=" + ToString(tier) + " duration=" + FloatToStringPrec(TDO_Pyrolith_GetActiveDuration(tier), 1));

  StatusEffectHelper.ApplyStatusEffect(this, t"StatusEffects.TDO_PyrolithActive");
  this.m_pyrolithBuffFx = TDO_Pyrolith_SpawnBuffVFX(this);

  GameObject.PlaySoundEvent(this, n"q000_sc_03_kerry_chooses_path_phone");

  let dur: Float = TDO_Pyrolith_GetActiveDuration(tier);
  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  let callback: ref<TDO_PyrolithEndCallback> = new TDO_PyrolithEndCallback();
  callback.player = this;
  this.m_pyrolithReleaseCallbackId = delaySystem.DelayCallback(callback, dur, false);
}

@addMethod(PlayerPuppet)
public func TDO_Pyrolith_End() -> Void {
  if !this.m_pyrolithActive {
    return;
  }
  this.m_pyrolithActive = false;
  TDOInfo("Pyrolith", "ended tier=" + ToString(this.m_pyrolithTier));

  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  if this.m_pyrolithReleaseCallbackId != GetInvalidDelayID() {
    delaySystem.CancelCallback(this.m_pyrolithReleaseCallbackId);
    this.m_pyrolithReleaseCallbackId = GetInvalidDelayID();
  }

  StatusEffectHelper.RemoveStatusEffect(this, t"StatusEffects.TDO_PyrolithActive");

  if IsDefined(this.m_pyrolithBuffFx) {
    this.m_pyrolithBuffFx.BreakLoop();
    this.m_pyrolithBuffFx = null;
  }

  let cooldownSE: TweakDBID = TDO_Pyrolith_GetCooldownSE(this.m_pyrolithTier);
  StatusEffectHelper.ApplyStatusEffect(this, cooldownSE);

  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.SandevistanCharge, -100.0, this, false);

  GameObject.PlaySoundEvent(this, n"v_quest_act3_judy_clouds_v");
}

@addMethod(PlayerPuppet)
public final func TDO_Pyrolith_FireBulletExplosionAt(origin: Vector4) -> Void {
  let tier: Int32 = this.TDO_Pyrolith_GetEquippedTier();
  if tier <= 0 {
    return;
  }

  TDO_Pyrolith_SpawnExplosionVFXAt(this, origin);

  let radius: Float = TDO_Pyrolith_GetBulletExplosionRadius(tier);

  let attackContext: AttackInitContext;
  attackContext.record = TweakDBInterface.GetAttackRecord(t"Attacks.Explosion");
  attackContext.instigator = this;
  attackContext.source = this;
  let attack: ref<Attack_GameEffect> = IAttack.Create(attackContext) as Attack_GameEffect;
  if !IsDefined(attack) {
    return;
  }

  let statMods: array<ref<gameStatModifierData>>;
  attack.GetStatModList(statMods);

  let effect: ref<EffectInstance> = attack.PrepareAttack(this);
  if !IsDefined(effect) {
    return;
  }

  EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.radius, radius);
  EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.position, origin);
  EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attack, ToVariant(attack));
  EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attackStatModList, ToVariant(statMods));
  attack.StartAttack();
}

public func TDO_Pyrolith_SpawnExplosionVFXAt(player: ref<PlayerPuppet>, pos: Vector4) -> Void {
  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if !IsDefined(fxSystem) {
    return;
  }
  let raRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(raRef, r"base\\fx\\weapons\\explosives\\w_explosion_small.effect");
  let fxRes: FxResource;
  fxRes.effect = raRef;
  let position: WorldPosition;
  WorldPosition.SetVector4(position, pos);
  let transform: WorldTransform;
  WorldTransform.SetWorldPosition(transform, position);
  WorldTransform.SetOrientationFromDir(transform, player.GetWorldForward());
  fxSystem.SpawnEffect(fxRes, transform, true);
}

public func TDO_Pyrolith_SpawnBuffVFX(player: ref<PlayerPuppet>) -> ref<FxInstance> {
  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if !IsDefined(fxSystem) {
    TDOWarn("Pyrolith", "buff fx skipped (no FxSystem)");
    return null;
  }
  let raRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(raRef, r"base\\fx\\camera\\splinter_buff\\splinter_buff_fx.effect");
  let fxRes: FxResource;
  fxRes.effect = raRef;
  let position: WorldPosition;
  WorldPosition.SetVector4(position, player.GetWorldPosition());
  let transform: WorldTransform;
  WorldTransform.SetWorldPosition(transform, position);
  WorldTransform.SetOrientationFromDir(transform, player.GetWorldForward());
  return fxSystem.SpawnEffect(fxRes, transform, true);
}

public class TDO_PyrolithClusterCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;
  public let origin: Vector4;
  public let grenadeItemTDB: TweakDBID;
  public let offsetX: Float;
  public let offsetY: Float;

  public func Call() -> Void {
    if !IsDefined(this.player) {
      return;
    }
    let grenadeRecord: ref<Grenade_Record> = TweakDBInterface.GetGrenadeRecord(this.grenadeItemTDB);
    if !IsDefined(grenadeRecord) {
      return;
    }
    let attackRecord: ref<Attack_Record> = grenadeRecord.Attack();
    if !IsDefined(attackRecord) {
      return;
    }
    let attackGameEffect: ref<Attack_GameEffect_Record> = attackRecord as Attack_GameEffect_Record;
    if !IsDefined(attackGameEffect) {
      return;
    }

    let clusterPos: Vector4 = this.origin;
    clusterPos.X = this.origin.X + this.offsetX;
    clusterPos.Y = this.origin.Y + this.offsetY;
    clusterPos.W = 1.0;

    let attackContext: AttackInitContext;
    attackContext.record = attackGameEffect;
    attackContext.instigator = this.player;
    attackContext.source = this.player;
    let attack: ref<Attack_GameEffect> = IAttack.Create(attackContext) as Attack_GameEffect;
    if !IsDefined(attack) {
      return;
    }

    let statMods: array<ref<gameStatModifierData>>;
    attack.GetStatModList(statMods);

    let effect: ref<EffectInstance> = attack.PrepareAttack(this.player);
    if !IsDefined(effect) {
      return;
    }

    let radius: Float = attackGameEffect.Range();
    if radius <= 0.0 {
      radius = grenadeRecord.AttackRadius();
    }

    EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.radius, radius);
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.position, clusterPos);
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attack, ToVariant(attack));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attackStatModList, ToVariant(statMods));
    attack.StartAttack();
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Pyrolith_SpawnClusters(origin: Vector4, grenadeItemTDB: TweakDBID) -> Void {
  if !this.m_pyrolithActive {
    return;
  }
  let tier: Int32 = this.TDO_Pyrolith_GetEquippedTier();
  if tier <= 0 {
    return;
  }
  let extraCount: Int32 = TDO_Pyrolith_GetClusterCount(tier);
  if extraCount <= 0 {
    return;
  }
  let scalar: Float = TDO_Pyrolith_GetClusterDamageScalar(tier);

  let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(this.GetGame()));
  this.m_pyrolithLastClusterTime = now;
  this.m_pyrolithLastClusterScalar = scalar;

  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.GetGame());
  let i: Int32 = 0;
  while i < extraCount {
    let callback: ref<TDO_PyrolithClusterCallback> = new TDO_PyrolithClusterCallback();
    callback.player = this;
    callback.origin = origin;
    callback.grenadeItemTDB = grenadeItemTDB;
    let angle: Float = (Cast<Float>(i) / Cast<Float>(extraCount)) * 6.283 + RandRangeF(-0.3, 0.3);
    callback.offsetX = 2.0 * CosF(angle);
    callback.offsetY = 2.0 * SinF(angle);
    let delay: Float = 0.15 + Cast<Float>(i) * 0.12;
    delaySystem.DelayCallback(callback, delay, false);
    i += 1;
  }
}

@wrapMethod(DamageSystem)
private final func ProcessHitReaction(hitEvent: ref<gameHitEvent>) -> Void {
  wrappedMethod(hitEvent);
  let instigator: wref<GameObject> = hitEvent.attackData.GetInstigator();
  if !IsDefined(instigator) || !instigator.IsPlayer() {
    return;
  }
  let player: ref<PlayerPuppet> = instigator as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !player.m_pyrolithActive {
    return;
  }
  let tier: Int32 = player.TDO_Pyrolith_GetEquippedTier();
  if tier <= 0 || !TDOConfig.PyrolithEnabled() {
    return;
  }
  let target: ref<GameObject> = hitEvent.target;
  if !IsDefined(target) {
    return;
  }
  let hitPos: Vector4 = hitEvent.hitPosition;
  let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();

  if player.m_pyrolithActive && Equals(attackType, gamedataAttackType.Ranged) && !target.IsPlayer() {
    player.TDO_Pyrolith_FireBulletExplosionAt(hitPos);
  }

  if player.m_pyrolithActive && Equals(attackType, gamedataAttackType.Explosion) {
    let grenadeSource: wref<BaseGrenade> = hitEvent.attackData.GetSource() as BaseGrenade;
    if IsDefined(grenadeSource) {
      let grenadeEntityID: EntityID = grenadeSource.GetEntityID();
      if !Equals(grenadeEntityID, player.m_pyrolithOriginalGrenadeID) {
        player.m_pyrolithOriginalGrenadeID = grenadeEntityID;
        let grenadeItemTDB: TweakDBID = ItemID.GetTDBID(grenadeSource.GetItemID());
        player.TDO_Pyrolith_SpawnClusters(hitPos, grenadeItemTDB);
      }
    }
  }
}

@wrapMethod(DamageSystem)
private final func ProcessOneShotProtection(hitEvent: ref<gameHitEvent>) -> Void {
  let instigator: wref<GameObject> = hitEvent.attackData.GetInstigator();
  if IsDefined(instigator) && instigator.IsPlayer() {
    let player: ref<PlayerPuppet> = instigator as PlayerPuppet;
    let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();
    let isExplosion: Bool = Equals(attackType, gamedataAttackType.Explosion);

    if IsDefined(player) && player.m_pyrolithActive && TDOConfig.PyrolithEnabled() && isExplosion && !hitEvent.target.IsPlayer() {
      let attackRecord: ref<Attack_Record> = hitEvent.attackData.attackDefinition.GetRecord();
      if IsDefined(attackRecord) {
        let recordID: TweakDBID = attackRecord.GetID();
        if Equals(recordID, t"Attacks.Explosion") {
          let tier: Int32 = player.TDO_Pyrolith_GetEquippedTier();
          let pyroDmg: Float = TDO_Pyrolith_GetExplosionDamage(tier);
          hitEvent.attackComputed.MultAttackValue(0.0);
          hitEvent.attackComputed.SetAttackValue(pyroDmg, gamedataDamageType.Thermal);
        } else {
          let grenadeSource: wref<BaseGrenade> = hitEvent.attackData.GetSource() as BaseGrenade;
          let isOriginalGrenade: Bool = IsDefined(grenadeSource);
          if !isOriginalGrenade && player.m_pyrolithLastClusterScalar > 0.0 {
            let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(player.GetGame()));
            let withinWindow: Bool = (now - player.m_pyrolithLastClusterTime) < 8.0;
            if withinWindow {
              hitEvent.attackComputed.MultAttackValue(player.m_pyrolithLastClusterScalar);
            }
          }
        }
      }
    }
  }
  wrappedMethod(hitEvent);
}

@wrapMethod(BaseGrenade)
public final func GetInitialVelocity(isQuickThrow: Bool) -> Float {
  let baseVelocity: Float = wrappedMethod(isQuickThrow);
  if !IsDefined(this.m_user) || !this.m_user.IsPlayer() {
    return baseVelocity;
  }
  let player: ref<PlayerPuppet> = this.m_user as PlayerPuppet;
  if !IsDefined(player) {
    return baseVelocity;
  }
  let tier: Int32 = player.TDO_Pyrolith_GetEquippedTier();
  if tier <= 0 || !TDOConfig.PyrolithEnabled() {
    return baseVelocity;
  }
  let mult: Float = TDO_Pyrolith_GetThrowVelocityMultiplier(tier);
  return baseVelocity * mult;
}

public class TDO_PyrolithEndCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if IsDefined(this.player) && this.player.m_pyrolithActive {
      this.player.TDO_Pyrolith_End();
    }
  }
}

@wrapMethod(PlayerPuppet)
protected func OnIncapacitated() -> Void {
  wrappedMethod();
  if this.m_pyrolithActive {
    this.TDO_Pyrolith_End();
  }
}

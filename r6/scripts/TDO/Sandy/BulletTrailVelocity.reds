import TDO.Sandy.*
import TDO.Logging.*

@addField(WeaponObject)
public let m_tdoBulletTrailAttack: TweakDBID;

@addField(sampleBullet)
public let m_tdoNeedsVelocityRestore: Bool;

@addField(sampleBullet)
public let m_tdoOriginalVelocity: Float;

@addField(sampleBullet)
public let m_tdoBulletTrailOwner: wref<PlayerPuppet>;

public func TDO_BulletTrailVelocity_GetSliderAt(pct: Int32) -> Float {
  switch pct {
    case 10: return TDOConfig.BulletTrailVelocityAt10();
    case 20: return TDOConfig.BulletTrailVelocityAt20();
    case 30: return TDOConfig.BulletTrailVelocityAt30();
    case 40: return TDOConfig.BulletTrailVelocityAt40();
    case 50: return TDOConfig.BulletTrailVelocityAt50();
    case 60: return TDOConfig.BulletTrailVelocityAt60();
    case 70: return TDOConfig.BulletTrailVelocityAt70();
    case 80: return TDOConfig.BulletTrailVelocityAt80();
    case 90: return TDOConfig.BulletTrailVelocityAt90();
    case 99: return TDOConfig.BulletTrailVelocityAt99();
  }
  return TDOConfig.BulletTrailVelocityAt50();
}

public func TDO_BulletTrailVelocity_AtSlow(slowPct: Float) -> Float {
  if slowPct <= 10.0 {
    return TDOConfig.BulletTrailVelocityAt10();
  }
  if slowPct >= 99.0 {
    return TDOConfig.BulletTrailVelocityAt99();
  }
  if slowPct >= 90.0 {
    let velLower: Float = TDOConfig.BulletTrailVelocityAt90();
    let velUpper: Float = TDOConfig.BulletTrailVelocityAt99();
    let t: Float = (slowPct - 90.0) / 9.0;
    return LerpF(t, velLower, velUpper);
  }
  let lowerI: Int32 = FloorF(slowPct / 10.0) * 10;
  let upperI: Int32 = lowerI + 10;
  let lower: Float = Cast<Float>(lowerI);
  let t: Float = (slowPct - lower) / 10.0;
  let velLower: Float = TDO_BulletTrailVelocity_GetSliderAt(lowerI);
  let velUpper: Float = TDO_BulletTrailVelocity_GetSliderAt(upperI);
  return LerpF(t, velLower, velUpper);
}

public func TDO_BulletTrailVelocity(player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Float {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
  let timeScale: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.TimeDilationSandevistanTimeScale);
  if timeScale <= 0.0 || timeScale >= 1.0 {
    return -1.0;
  }
  let slowPct: Float = (1.0 - timeScale) * 100.0;
  return TDO_BulletTrailVelocity_AtSlow(slowPct);
}

@if(ModuleExists("TriggerModeControl"))
public func TDO_BulletTrailVelocity_ChargeReadyPercentage(weapon: ref<WeaponObject>) -> Float {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
  let threshold: Float = stats.GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ChargeReadyPercentage);
  return threshold > 0.0 ? threshold : 1.0;
}

@if(!ModuleExists("TriggerModeControl"))
public func TDO_BulletTrailVelocity_ChargeReadyPercentage(weapon: ref<WeaponObject>) -> Float {
  return 1.0;
}

@wrapMethod(WeaponTransition)
protected final func GetDesiredAttackRecord(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> ref<Attack_Record> {
  let attackRecord: ref<Attack_Record> = wrappedMethod(stateContext, scriptInterface);
  let weapon: ref<WeaponObject> = this.GetWeaponObject(scriptInterface);
  if !IsDefined(weapon) {
    return attackRecord;
  }

  weapon.m_tdoBulletTrailAttack = t"";
  if !IsDefined(attackRecord) {
    return attackRecord;
  }
  if !TDOConfig.BulletTrailVelocityEnabled() {
    return attackRecord;
  }

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return attackRecord;
  }
  if !TDO_Sandy_IsActive(player) {
    return attackRecord;
  }
  let traceEnabled: Bool = TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= EnumInt(TDO_LogLevel.TRACE);
  if StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.DeadeyeSE") {
    if traceEnabled { TDOTrace("BulletTrail", "selector gate=deadeye attack=" + TDBID.ToStringDEBUG(attackRecord.GetID())); }
    return attackRecord;
  }
  if Equals(weapon.GetWeaponRecord().Evolution().Type(), gamedataWeaponEvolution.Tech) {
    if traceEnabled { TDOTrace("BulletTrail", "selector gate=tech attack=" + TDBID.ToStringDEBUG(attackRecord.GetID())); }
    return attackRecord;
  }

  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
  let projectilesPerShot: Float = stats.GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ProjectilesPerShot);
  if projectilesPerShot != 1.0 {
    if traceEnabled { TDOTrace("BulletTrail", "selector gate=projectile count attack=" + TDBID.ToStringDEBUG(attackRecord.GetID()) + " count=" + ToString(projectilesPerShot)); }
    return attackRecord;
  }
  let velocity: Float = TDO_BulletTrailVelocity(player, weapon);
  if velocity <= 0.0 {
    if traceEnabled { TDOTrace("BulletTrail", "selector gate=no sandy velocity attack=" + TDBID.ToStringDEBUG(attackRecord.GetID()) + " velocity=" + ToString(velocity)); }
    return attackRecord;
  }

  let rangedAttackPackage: ref<RangedAttackPackage_Record> = this.m_rangedAttackPackage;
  if !IsDefined(rangedAttackPackage) {
    if traceEnabled { TDOTrace("BulletTrail", "selector gate=no ranged package attack=" + TDBID.ToStringDEBUG(attackRecord.GetID())); }
    return attackRecord;
  }
  let weaponCharge: Float = WeaponObject.GetWeaponChargeNormalized(weapon);
  let chargeReadyPercentage: Float = TDO_BulletTrailVelocity_ChargeReadyPercentage(weapon);
  let rangedAttack: ref<RangedAttack_Record>;
  rangedAttack = weaponCharge >= chargeReadyPercentage ? rangedAttackPackage.ChargeFire() : rangedAttackPackage.DefaultFire();
  if !IsDefined(rangedAttack) {
    if traceEnabled { TDOTrace("BulletTrail", "selector gate=no ranged attack final=" + TDBID.ToStringDEBUG(attackRecord.GetID())); }
    return attackRecord;
  }

  let projectileAttack: ref<Attack_Record>;
  switch rangedAttack.GetID() {
    case t"Attacks.PhysicalBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.PowerBullets_Projectile");
      break;
    case t"Attacks.PhysicalStatusEffectBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.BleedingBulletProjectile");
      break;
    case t"Attacks.ThermalBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.ThermalBulletProjectile");
      break;
    case t"Attacks.ThermalStatusEffectBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.BurningBulletProjectile");
      break;
    case t"Attacks.ChemicalBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.ChemicalBulletProjectile");
      break;
    case t"Attacks.ChemicalStatusEffectBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.PoisonBulletProjectile");
      break;
    case t"Attacks.ElectricBullet":
    case t"Attacks.ElectricStatusEffectBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.ElectricBulletProjectile");
      break;
    case t"Attacks.PowerRoundsBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.PowerRounds_Projectile");
      break;
    case t"Attacks.PowerBuckshotsBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.PowerBuckshots_Projectile");
      break;
    case t"Attacks.PowerBulletsBullet":
      projectileAttack = TweakDBInterface.GetAttackRecord(t"Attacks.PowerBullets_Projectile");
      break;
  }

  if !IsDefined(projectileAttack) {
    if traceEnabled { TDOTrace("BulletTrail", "selector gate=unsupported ranged=" + TDBID.ToStringDEBUG(rangedAttack.GetID()) + " final=" + TDBID.ToStringDEBUG(attackRecord.GetID())); }
    return attackRecord;
  }

  weapon.m_tdoBulletTrailAttack = projectileAttack.GetID();
  if traceEnabled { TDOTrace("BulletTrail", "selector converted source=" + TDBID.ToStringDEBUG(rangedAttack.GetID()) + " from=" + TDBID.ToStringDEBUG(attackRecord.GetID()) + " to=" + TDBID.ToStringDEBUG(projectileAttack.GetID()) + " velocity=" + ToString(velocity)); }
  return projectileAttack;
}

@wrapMethod(sampleBullet)
protected cb func OnProjectileInitialize(eventData: ref<gameprojectileSetUpEvent>) -> Bool {
  this.m_tdoNeedsVelocityRestore = false;
  this.m_tdoOriginalVelocity = this.m_startVelocity;
  this.m_tdoBulletTrailOwner = eventData.owner as PlayerPuppet;
  let traceEnabled: Bool = TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= EnumInt(TDO_LogLevel.TRACE);

  let player: ref<PlayerPuppet> = this.m_tdoBulletTrailOwner;
  let weapon: ref<WeaponObject> = eventData.weapon as WeaponObject;
  let bulletTrailAttack: TweakDBID = t"";
  if IsDefined(weapon) {
    bulletTrailAttack = weapon.m_tdoBulletTrailAttack;
    weapon.m_tdoBulletTrailAttack = t"";
  }
  if IsDefined(player) && IsDefined(weapon) {
    if player.m_tdoShrikePendingHitscanBullets > 0 {
      if traceEnabled { TDOTrace("BulletTrail", "init gate=shrike hitscan"); }
      this.m_startVelocity = 10000.0;
      player.m_tdoShrikePendingHitscanBullets -= 1;
      return wrappedMethod(eventData);
    }
    if player.m_tdoApogeeActive {
      if traceEnabled { TDOTrace("BulletTrail", "init gate=apogee"); }
      this.m_startVelocity = this.m_startVelocity * TDOConfig.ApogeeProjectileSpeedMult();
      return wrappedMethod(eventData);
    }
  }

  if !TDOConfig.BulletTrailVelocityEnabled() {
    if traceEnabled { TDOTrace("BulletTrail", "init gate=disabled"); }
    return wrappedMethod(eventData);
  }
  if !IsDefined(player) || !IsDefined(weapon) {
    if traceEnabled { TDOTrace("BulletTrail", "init gate=missing player or weapon"); }
    return wrappedMethod(eventData);
  }

  let currentAttack: ref<IAttack> = weapon.GetCurrentAttack();
  if !IsDefined(currentAttack) {
    if traceEnabled { TDOTrace("BulletTrail", "init gate=no current attack selected=" + TDBID.ToStringDEBUG(bulletTrailAttack)); }
    return wrappedMethod(eventData);
  }
  let currentAttackRecord: ref<Attack_Record> = currentAttack.GetRecord();
  if !IsDefined(currentAttackRecord) {
    if traceEnabled { TDOTrace("BulletTrail", "init gate=no current attack record selected=" + TDBID.ToStringDEBUG(bulletTrailAttack)); }
    return wrappedMethod(eventData);
  }
  if NotEquals(currentAttackRecord.GetID(), bulletTrailAttack) {
    if traceEnabled { TDOTrace("BulletTrail", "init gate=attack mismatch current=" + TDBID.ToStringDEBUG(currentAttackRecord.GetID()) + " selected=" + TDBID.ToStringDEBUG(bulletTrailAttack)); }
    return wrappedMethod(eventData);
  }

  let velocity: Float = TDO_BulletTrailVelocity(player, weapon);
  if velocity > 0.0 && velocity != this.m_startVelocity {
    this.m_tdoOriginalVelocity = this.m_startVelocity;
    this.m_startVelocity = velocity;
    this.m_tdoNeedsVelocityRestore = true;
    if traceEnabled { TDOTrace("BulletTrail", "init slowed attack=" + TDBID.ToStringDEBUG(currentAttackRecord.GetID()) + " original=" + ToString(this.m_tdoOriginalVelocity) + " velocity=" + ToString(velocity)); }
  } else {
    if traceEnabled { TDOTrace("BulletTrail", "init gate=velocity unchanged attack=" + TDBID.ToStringDEBUG(currentAttackRecord.GetID()) + " original=" + ToString(this.m_startVelocity) + " velocity=" + ToString(velocity)); }
  }
  return wrappedMethod(eventData);
}

@wrapMethod(sampleBullet)
protected cb func OnTick(eventData: ref<gameprojectileTickEvent>) -> Bool {
  if !this.m_tdoNeedsVelocityRestore {
    return wrappedMethod(eventData);
  }

  let player: ref<PlayerPuppet> = this.m_tdoBulletTrailOwner;
  if IsDefined(player) && TDOConfig.BulletTrailVelocityEnabled() && TDO_Sandy_OwnsCombatTime(player) {
    return wrappedMethod(eventData);
  }

  this.m_tdoNeedsVelocityRestore = false;
  this.m_startVelocity = this.m_tdoOriginalVelocity;
  let params: ref<LinearTrajectoryParams> = new LinearTrajectoryParams();
  params.startVel = this.m_tdoOriginalVelocity;
  this.m_projectileComponent.ClearTrajectories();
  this.m_projectileComponent.AddLinear(params);

  return wrappedMethod(eventData);
}

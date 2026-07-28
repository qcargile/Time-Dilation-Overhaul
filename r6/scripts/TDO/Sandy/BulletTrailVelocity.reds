@addField(WeaponObject)
public let m_tdoBulletTrailAttack: TweakDBID;

@addField(sampleBullet)
public let m_tdoNeedsVelocityRestore: Bool;

@addField(sampleBullet)
public let m_tdoOriginalVelocity: Float;

@addField(sampleBullet)
public let m_tdoBulletTrailOwner: wref<PlayerPuppet>;

public func TDO_BulletTrailVelocity_IsSandyActive(player: ref<PlayerPuppet>) -> Bool {
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) {
    return false;
  }
  let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
  return td == EnumInt(gamePSMTimeDilation.Sandevistan);
}

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

@wrapMethod(WeaponTransition)
protected final func GetDesiredAttackRecord(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> ref<Attack_Record> {
  let attackRecord: ref<Attack_Record> = wrappedMethod(stateContext, scriptInterface);
  let weapon: ref<WeaponObject> = this.GetWeaponObject(scriptInterface);
  if !IsDefined(weapon) {
    return attackRecord;
  }

  weapon.m_tdoBulletTrailAttack = t"";
  if !IsDefined(attackRecord) || !TDOConfig.BulletTrailVelocityEnabled() {
    return attackRecord;
  }

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) || !TDO_BulletTrailVelocity_IsSandyActive(player) {
    return attackRecord;
  }
  if StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.DeadeyeSE") {
    return attackRecord;
  }
  if Equals(weapon.GetWeaponRecord().Evolution().Type(), gamedataWeaponEvolution.Tech) {
    return attackRecord;
  }

  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
  let projectilesPerShot: Float = stats.GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ProjectilesPerShot);
  if projectilesPerShot != 1.0 {
    return attackRecord;
  }

  let projectileAttack: ref<Attack_Record>;
  switch attackRecord.GetID() {
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
    return attackRecord;
  }

  weapon.m_tdoBulletTrailAttack = projectileAttack.GetID();
  return projectileAttack;
}

@wrapMethod(sampleBullet)
protected cb func OnProjectileInitialize(eventData: ref<gameprojectileSetUpEvent>) -> Bool {
  this.m_tdoNeedsVelocityRestore = false;
  this.m_tdoOriginalVelocity = this.m_startVelocity;
  this.m_tdoBulletTrailOwner = eventData.owner as PlayerPuppet;

  let player: ref<PlayerPuppet> = this.m_tdoBulletTrailOwner;
  let weapon: ref<WeaponObject> = eventData.weapon as WeaponObject;
  let bulletTrailAttack: TweakDBID = t"";
  if IsDefined(weapon) {
    bulletTrailAttack = weapon.m_tdoBulletTrailAttack;
    weapon.m_tdoBulletTrailAttack = t"";
  }
  if IsDefined(player) && IsDefined(weapon) {
    if player.m_tdoShrikePendingHitscanBullets > 0 {
      this.m_startVelocity = 10000.0;
      player.m_tdoShrikePendingHitscanBullets -= 1;
      return wrappedMethod(eventData);
    }
    if player.m_tdoApogeeActive {
      this.m_startVelocity = this.m_startVelocity * TDOConfig.ApogeeProjectileSpeedMult();
      return wrappedMethod(eventData);
    }
  }

  if !TDOConfig.BulletTrailVelocityEnabled() {
    return wrappedMethod(eventData);
  }
  if !IsDefined(player) || !IsDefined(weapon) {
    return wrappedMethod(eventData);
  }

  let currentAttack: ref<IAttack> = weapon.GetCurrentAttack();
  if !IsDefined(currentAttack) {
    return wrappedMethod(eventData);
  }
  let currentAttackRecord: ref<Attack_Record> = currentAttack.GetRecord();
  if !IsDefined(currentAttackRecord) || NotEquals(currentAttackRecord.GetID(), bulletTrailAttack) {
    return wrappedMethod(eventData);
  }

  let v: Float = TDO_BulletTrailVelocity(player, weapon);
  if v > 0.0 && v != this.m_startVelocity {
    this.m_tdoOriginalVelocity = this.m_startVelocity;
    this.m_startVelocity = v;
    this.m_tdoNeedsVelocityRestore = true;
  }
  return wrappedMethod(eventData);
}

@wrapMethod(sampleBullet)
protected cb func OnTick(eventData: ref<gameprojectileTickEvent>) -> Bool {
  if !this.m_tdoNeedsVelocityRestore {
    return wrappedMethod(eventData);
  }

  let player: ref<PlayerPuppet> = this.m_tdoBulletTrailOwner;
  if IsDefined(player) && TDOConfig.BulletTrailVelocityEnabled() && TDO_BulletTrailVelocity_IsSandyActive(player) {
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

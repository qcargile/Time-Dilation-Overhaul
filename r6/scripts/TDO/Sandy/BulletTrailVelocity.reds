@addField(sampleBullet)
public let m_tdoNeedsVelocityRestore: Bool;

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

public func TDO_BulletTrailVelocity(weaponObj: wref<GameObject>) -> Float {
  let weapon: wref<WeaponObject> = weaponObj as WeaponObject;
  if !IsDefined(weapon) {
    return -1.0;
  }
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
  if !IsDefined(stats) {
    return -1.0;
  }
  let playerSys: ref<PlayerSystem> = GameInstance.GetPlayerSystem(weapon.GetGame());
  if !IsDefined(playerSys) {
    return -1.0;
  }
  let player: ref<PlayerPuppet> = playerSys.GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(player) {
    return -1.0;
  }
  if !TDO_BulletTrailVelocity_IsSandyActive(player) {
    return -1.0;
  }
  if StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.DeadeyeSE") {
    return -1.0;
  }
  let timeScale: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.TimeDilationSandevistanTimeScale);
  if timeScale <= 0.0 || timeScale >= 1.0 {
    return -1.0;
  }
  let slowPct: Float = (1.0 - timeScale) * 100.0;
  let v: Float = TDO_BulletTrailVelocity_AtSlow(slowPct);
  let projectilesPerShot: Float = stats.GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ProjectilesPerShot);
  let extremeSlowVelocity: Float = 15.0;
  if projectilesPerShot >= 20.0 && v <= extremeSlowVelocity {
    return -1.0;
  }
  return v;
}

@wrapMethod(sampleBullet)
protected cb func OnProjectileInitialize(eventData: ref<gameprojectileSetUpEvent>) -> Bool {
  this.m_tdoNeedsVelocityRestore = false;

  let playerSys: ref<PlayerSystem> = GameInstance.GetPlayerSystem(this.GetGame());
  if IsDefined(playerSys) {
    let player: ref<PlayerPuppet> = playerSys.GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) && player.m_tdoShrikePendingHitscanBullets > 0 {
      this.m_startVelocity = 10000.0;
      player.m_tdoShrikePendingHitscanBullets -= 1;
      return wrappedMethod(eventData);
    }
    if IsDefined(player) && player.m_tdoApogeeActive {
      this.m_startVelocity = this.m_startVelocity * TDOConfig.ApogeeProjectileSpeedMult();
      return wrappedMethod(eventData);
    }
  }

  if !TDOConfig.BulletTrailVelocityEnabled() {
    return wrappedMethod(eventData);
  }

  let v: Float = TDO_BulletTrailVelocity(eventData.weapon);
  if v > 0.0 {
    this.m_startVelocity = v;
    if v < 90.0 {
      this.m_tdoNeedsVelocityRestore = true;
    }
  }
  return wrappedMethod(eventData);
}

@wrapMethod(sampleBullet)
protected cb func OnTick(eventData: ref<gameprojectileTickEvent>) -> Bool {
  if !TDOConfig.BulletTrailVelocityEnabled() {
    return wrappedMethod(eventData);
  }
  if !this.m_tdoNeedsVelocityRestore {
    return wrappedMethod(eventData);
  }

  let playerSys: ref<PlayerSystem> = GameInstance.GetPlayerSystem(this.GetGame());
  if !IsDefined(playerSys) {
    return wrappedMethod(eventData);
  }
  let player: ref<PlayerPuppet> = playerSys.GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(player) {
    return wrappedMethod(eventData);
  }
  if TDO_BulletTrailVelocity_IsSandyActive(player) {
    return wrappedMethod(eventData);
  }

  this.m_tdoNeedsVelocityRestore = false;
  let params: ref<LinearTrajectoryParams> = new LinearTrajectoryParams();
  params.startVel = 90.0;
  this.m_projectileComponent.ClearTrajectories();
  this.m_projectileComponent.AddLinear(params);

  return wrappedMethod(eventData);
}

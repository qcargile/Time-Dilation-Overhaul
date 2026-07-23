module TDO.Sandy

import TDO.Logging.*

@addField(sampleBullet)
public let m_tdoFalconSelfHitApplied: Bool;

@addField(sampleBullet)
public let m_tdoFalconHasBeenFar: Bool;

@addField(sampleBullet)
public let m_tdoFalconProjectilesPerShot: Float;

@addField(sampleBullet)
public let m_tdoFalconWeapon: wref<WeaponObject>;

@addField(sampleBullet)
public let m_tdoFalconHasLastPosition: Bool;

@addField(sampleBullet)
public let m_tdoFalconLastPosition: Vector4;

@addField(sampleBullet)
public let m_tdoFalconHasLaunchDirection: Bool;

@addField(sampleBullet)
public let m_tdoFalconLaunchDirection: Vector4;

@wrapMethod(sampleBullet)
protected cb func OnProjectileInitialize(eventData: ref<gameprojectileSetUpEvent>) -> Bool {
  this.m_tdoFalconSelfHitApplied = false;
  this.m_tdoFalconHasBeenFar = false;
  this.m_tdoFalconProjectilesPerShot = 1.0;
  this.m_tdoFalconWeapon = eventData.weapon as WeaponObject;
  this.m_tdoFalconHasLastPosition = false;
  this.m_tdoFalconLastPosition = Vector4.EmptyVector();
  this.m_tdoFalconHasLaunchDirection = false;
  this.m_tdoFalconLaunchDirection = Vector4.EmptyVector();
  if IsDefined(this.m_tdoFalconWeapon) {
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
    if IsDefined(stats) {
      this.m_tdoFalconProjectilesPerShot = stats.GetStatValue(Cast<StatsObjectID>(this.m_tdoFalconWeapon.GetEntityID()), gamedataStatType.ProjectilesPerShot);
      if this.m_tdoFalconProjectilesPerShot < 1.0 {
        this.m_tdoFalconProjectilesPerShot = 1.0;
      }
    }
  }
  return wrappedMethod(eventData);
}

@wrapMethod(sampleBullet)
protected cb func OnTick(eventData: ref<gameprojectileTickEvent>) -> Bool {
  let result: Bool = wrappedMethod(eventData);
  if this.m_tdoFalconSelfHitApplied { return result; }
  if !TDOConfig.FalconEnabled() { return result; }

  let playerSys: ref<PlayerSystem> = GameInstance.GetPlayerSystem(this.GetGame());
  if !IsDefined(playerSys) { return result; }
  let player: ref<PlayerPuppet> = playerSys.GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(player) { return result; }

  if !IsDefined(this.m_user) { return result; }
  if !Equals(this.m_user.GetEntityID(), player.GetEntityID()) { return result; }

  if !TDO_Falcon_IsEquipped(player) { return result; }
  if !TDO_Falcon_IsSandyActive(player) { return result; }

  let shotWeapon: wref<WeaponObject> = this.m_tdoFalconWeapon;
  if !IsDefined(shotWeapon) { return result; }
  if TDO_Falcon_IsTechWeapon(shotWeapon) { return result; }
  if TDO_Falcon_IsSmartWeapon(shotWeapon) { return result; }

  let bulletPos: Vector4 = this.GetWorldPosition();
  let playerPos: Vector4 = player.GetWorldPosition();
  let dist: Float = Vector4.Distance(bulletPos, playerPos);

  if !this.m_tdoFalconHasLastPosition {
    this.m_tdoFalconHasLastPosition = true;
    this.m_tdoFalconLastPosition = bulletPos;
    return result;
  }

  let lastBulletPos: Vector4 = this.m_tdoFalconLastPosition;
  let lastDist: Float = Vector4.Distance(lastBulletPos, playerPos);
  if dist > 5.0 || lastDist > 5.0 {
    this.m_tdoFalconHasBeenFar = true;
  }

  let travel: Vector4 = bulletPos - lastBulletPos;
  let travelLenSq: Float = Vector4.LengthSquared(travel);
  if travelLenSq < 0.0025 {
    this.m_tdoFalconLastPosition = bulletPos;
    return result;
  }

  let travelDir: Vector4 = Vector4.Normalize(travel);
  if !this.m_tdoFalconHasLaunchDirection && dist > 2.0 {
    this.m_tdoFalconHasLaunchDirection = true;
    this.m_tdoFalconLaunchDirection = travelDir;
  }

  if !this.m_tdoFalconHasBeenFar {
    this.m_tdoFalconLastPosition = bulletPos;
    return result;
  }
  if !this.m_tdoFalconHasLaunchDirection {
    this.m_tdoFalconLastPosition = bulletPos;
    return result;
  }

  let playerFromLast: Vector4 = playerPos - lastBulletPos;
  let approach: Float = Vector4.Dot(travel, playerFromLast);
  if approach <= 0.0 {
    this.m_tdoFalconLastPosition = bulletPos;
    return result;
  }

  let closestT: Float = ClampF(approach / travelLenSq, 0.0, 1.0);
  let closestPoint: Vector4 = lastBulletPos + travel * closestT;
  let closestDist: Float = Vector4.Distance(closestPoint, playerPos);
  let launchDot: Float = Vector4.Dot(travelDir, this.m_tdoFalconLaunchDirection);
  this.m_tdoFalconLastPosition = bulletPos;

  if closestDist > 1.5 { return result; }
  if launchDot >= 0.25 { return result; }

  this.m_tdoFalconSelfHitApplied = true;

  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  let maxHP: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Health);
  let damage: Float = maxHP * 0.10 / this.m_tdoFalconProjectilesPerShot;

  let bulletAttackRecord: ref<Attack_Record> = TweakDBInterface.GetAttackRecord(t"Attacks.NPCBulletEffect");
  if IsDefined(bulletAttackRecord) {
    let attackContext: AttackInitContext;
    attackContext.record = bulletAttackRecord;
    attackContext.instigator = player;
    attackContext.source = player;
    attackContext.weapon = shotWeapon;
    let attack: ref<IAttack> = IAttack.Create(attackContext);

    let hit: ref<gameHitEvent> = new gameHitEvent();
    hit.attackData = new AttackData();
    hit.target = player;
    hit.attackData.SetAttackDefinition(attack);
    hit.attackData.AddFlag(hitFlag.DealNoDamage, n"TDOFalconRicochetSelfHit");
    hit.attackData.SetSource(player);
    hit.attackData.SetInstigator(player);
    hit.attackData.SetWeapon(shotWeapon);
    let damageSys: ref<DamageSystem> = GameInstance.GetDamageSystem(this.GetGame());
    damageSys.QueueHitEvent(hit, player);
  }

  pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, -damage, player, false, false);

  TDOInfo("FalconRicochet", s"Self-hit by own ricochet at dist=\(dist), closest=\(closestDist), dealt \(damage) (10% of \(maxHP) / \(this.m_tdoFalconProjectilesPerShot) projectiles)");
  return result;
}

module TDO.Sandy

import TDO.Logging.*

@addField(sampleBullet)
public let m_tdoFalconSelfHitApplied: Bool;

@addField(sampleBullet)
public let m_tdoFalconHasBeenFar: Bool;

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

  let activeWeapon: wref<WeaponObject> = GameObject.GetActiveWeapon(player);
  if IsDefined(activeWeapon) {
    if TDO_Falcon_IsTechWeapon(activeWeapon) { return result; }
    if TDO_Falcon_IsSmartWeapon(activeWeapon) { return result; }
  }

  let bulletPos: Vector4 = this.GetWorldPosition();
  let playerPos: Vector4 = player.GetWorldPosition();
  let dist: Float = Vector4.Distance(bulletPos, playerPos);

  if dist > 5.0 {
    this.m_tdoFalconHasBeenFar = true;
  }

  if dist > 2.0 { return result; }
  if !this.m_tdoFalconHasBeenFar { return result; }

  this.m_tdoFalconSelfHitApplied = true;

  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  let maxHP: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Health);
  let damage: Float = maxHP * 0.10;  // 10% HP cap per ricochet hit

  let bulletAttackRecord: ref<Attack_Record> = TweakDBInterface.GetAttackRecord(t"Attacks.NPCBulletEffect");
  if IsDefined(bulletAttackRecord) && IsDefined(activeWeapon) {
    let attackContext: AttackInitContext;
    attackContext.record = bulletAttackRecord;
    attackContext.instigator = player;
    attackContext.source = player;
    attackContext.weapon = activeWeapon;
    let attack: ref<IAttack> = IAttack.Create(attackContext);

    let hit: ref<gameHitEvent> = new gameHitEvent();
    hit.attackData = new AttackData();
    hit.target = player;
    hit.attackData.SetAttackDefinition(attack);
    hit.attackData.AddFlag(hitFlag.DealNoDamage, n"TDOFalconRicochetSelfHit");
    hit.attackData.SetSource(player);
    hit.attackData.SetInstigator(player);
    hit.attackData.SetWeapon(activeWeapon);
    let damageSys: ref<DamageSystem> = GameInstance.GetDamageSystem(this.GetGame());
    damageSys.QueueHitEvent(hit, player);
  }

  pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, -damage, player, false, false);

  TDOInfo("FalconRicochet", s"Self-hit by own ricochet at dist=\(dist), dealt \(damage) (10% of \(maxHP))");
  return result;
}

module TDO.Sandy

import TDO.Logging.*

public func TDO_Falcon_GrantKillCredit(player: ref<PlayerPuppet>, npc: wref<NPCPuppet>, weapon: ref<WeaponObject>, damagePercent: Float) -> Void {
  if !IsDefined(player) || !IsDefined(npc) || !IsDefined(weapon) {
    return;
  }
  let attackContext: AttackInitContext;
  attackContext.record = TweakDBInterface.GetAttackRecord(t"Attacks.Finisher_Fake_Attack");
  attackContext.instigator = player;
  attackContext.source = player;
  attackContext.weapon = weapon;
  let attack: ref<IAttack> = IAttack.Create(attackContext);
  let hit: ref<gameHitEvent> = new gameHitEvent();
  hit.attackData = new AttackData();
  hit.target = npc;
  hit.attackData.SetAttackDefinition(attack);
  hit.attackData.AddFlag(hitFlag.DealNoDamage, n"TDOFalcon");
  hit.attackData.SetSource(player);
  hit.attackData.SetInstigator(player);
  hit.attackData.SetWeapon(weapon);
  GameInstance.GetDamageSystem(player.GetGame()).QueueHitEvent(hit, npc);
  RPGManager.AwardExperienceFromDamage(hit, damagePercent);
}

public func TDO_Falcon_IsWeaponFullyCharged(weapon: ref<WeaponObject>, scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let chargeValue: Float = scriptInterface.GetStatPoolsSystem().GetStatPoolValue(
    Cast<StatsObjectID>(weapon.GetEntityID()),
    gamedataStatPoolType.WeaponCharge,
    false);
  return chargeValue >= WeaponObject.GetBaseMaxChargeThreshold(weapon);
}

public func TDO_Falcon_GetOnLineHostiles(player: ref<PlayerPuppet>, lineStart: Vector4, lineEnd: Vector4, lineRadius: Float) -> array<wref<NPCPuppet>> {
  let result: array<wref<NPCPuppet>>;
  let playerPos: Vector4 = lineStart;
  let lineDir: Vector4 = lineEnd - playerPos;
  let lineLen: Float = Vector4.Length(lineDir);
  if lineLen <= 0.001 {
    return result;
  }
  let lineNorm: Vector4 = lineDir / lineLen;

  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(player.GetGame());
  let query: TargetSearchQuery = TSQ_NPC();
  query.maxDistance = 100.0;
  query.filterObjectByDistance = true;
  query.testedSet = TargetingSet.Complete;

  let parts: array<TS_TargetPartInfo>;
  targetingSystem.GetTargetParts(player, query, parts);

  let seen: array<EntityID>;
  let i: Int32 = 0;
  while i < ArraySize(parts) {
    let comp: wref<TargetingComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
    if IsDefined(comp) {
      let entity: wref<Entity> = comp.GetEntity();
      let npc: wref<NPCPuppet> = entity as NPCPuppet;
      if IsDefined(npc) && !npc.IsDead() && npc.IsHostile() && !ArrayContains(seen, npc.GetEntityID()) {
        let npcPos: Vector4 = npc.GetWorldPosition();
        let toNpc: Vector4 = npcPos - playerPos;
        let projLen: Float = Vector4.Dot(toNpc, lineNorm);
        if projLen > 0.0 && projLen < lineLen {
          let projPoint: Vector4 = playerPos + (lineNorm * projLen);
          let perpDist: Float = Vector4.Distance(npcPos, projPoint);
          if perpDist <= lineRadius {
            ArrayPush(result, npc);
            ArrayPush(seen, npc.GetEntityID());
          }
        }
      }
    }
    i += 1;
  }
  return result;
}

public func TDO_Falcon_GetNearbyHostiles(player: ref<PlayerPuppet>, range: Float) -> array<wref<NPCPuppet>> {
  let result: array<wref<NPCPuppet>>;
  let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(player.GetGame());
  let query: TargetSearchQuery = TSQ_NPC();
  query.maxDistance = range;
  query.filterObjectByDistance = true;
  query.testedSet = TargetingSet.Complete;

  let parts: array<TS_TargetPartInfo>;
  targetingSystem.GetTargetParts(player, query, parts);

  let seen: array<EntityID>;
  let i: Int32 = 0;
  while i < ArraySize(parts) {
    let comp: wref<TargetingComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
    if IsDefined(comp) {
      let entity: wref<Entity> = comp.GetEntity();
      let npc: wref<NPCPuppet> = entity as NPCPuppet;
      if IsDefined(npc) && !npc.IsDead() && npc.IsHostile() && !ArrayContains(seen, npc.GetEntityID()) {
        ArrayPush(result, npc);
        ArrayPush(seen, npc.GetEntityID());
      }
    }
    i += 1;
  }
  return result;
}

public func TDO_Falcon_FirePhaseRound(player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Void {
  if TDO_IsPlayerInVehicle(player) {
    return;
  }
  let gi: GameInstance = player.GetGame();
  let camera: ref<FPPCameraComponent> = player.GetFPPCameraComponent();
  let camMatrix: Matrix = camera.GetLocalToWorld();
  let camPos: Vector4 = Matrix.GetTranslation(camMatrix);
  let camFwd: Vector4 = Vector4.Normalize(Matrix.GetDirectionVector(camMatrix));
  let lineEnd: Vector4 = camPos + (camFwd * 100.0);

  let hostiles: array<wref<NPCPuppet>> = TDO_Falcon_GetOnLineHostiles(player, camPos, lineEnd, TDOConfig.FalconPhaseRoundLineRadius());
  if ArraySize(hostiles) == 0 {
    TDODebug("Falcon", "Phase Round: no hostiles on line, no-op");
    return;
  }
  TDOInfo("Falcon", "Phase Round fired, " + ToString(ArraySize(hostiles)) + " on line");

  GameObjectEffectHelper.StartEffectEvent(player, n"blackwall_use_force");
  GameObjectEffectHelper.StartEffectEvent(player, n"laser_targetting");
  GameObjectEffectHelper.StartEffectEvent(player, n"trail_electric");
  GameObjectEffectHelper.StartEffectEvent(weapon, n"trail_electric");
  GameObjectEffectHelper.StartEffectEvent(weapon, n"emp_hit");

  let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
  let weaponID: StatsObjectID = Cast<StatsObjectID>(weapon.GetEntityID());
  let baseDamage: Float = statsSystem.GetStatValue(weaponID, gamedataStatType.EffectiveDamagePerHit);
  let mult: Float = TDOConfig.FalconPhaseRoundDamageMultiplier();
  let playerID: EntityID = player.GetEntityID();

  let lineIDs: array<EntityID>;
  let i: Int32 = 0;
  while i < ArraySize(hostiles) {
    let npc: wref<NPCPuppet> = hostiles[i];
    let npcID: EntityID = npc.GetEntityID();
    let damage: Float = baseDamage * mult;
    let npcMaxHP: Float = statsSystem.GetStatValue(Cast<StatsObjectID>(npcID), gamedataStatType.Health);
    let xpPct: Float = 100.0;
    if npcMaxHP > 0.0 {
      xpPct = MinF(100.0, (damage / npcMaxHP) * 100.0);
    }
    TDO_Falcon_GrantKillCredit(player, npc, weapon, xpPct);
    pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(npcID), gamedataStatPoolType.Health, -damage, player, false, false);
    StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.Electrocuted", playerID);
    StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.EMP", playerID);
    GameObjectEffectHelper.StartEffectEvent(npc, n"weakspot_destroyed");
    GameObjectEffectHelper.StartEffectEvent(npc, n"weakspot_explode");
    GameObjectEffectHelper.StartEffectEvent(npc, n"weakspot_overload");
    GameObjectEffectHelper.StartEffectEvent(npc, n"blood_headshot");
    GameObjectEffectHelper.StartEffectEvent(npc, n"emp_hit");
    GameObjectEffectHelper.StartEffectEvent(npc, n"spy_strong_arms_force");
    ArrayPush(lineIDs, npcID);
    i += 1;
  }

  let nearby: array<wref<NPCPuppet>> = TDO_Falcon_GetNearbyHostiles(player, 25.0);
  let j: Int32 = 0;
  while j < ArraySize(nearby) {
    let bystander: wref<NPCPuppet> = nearby[j];
    if !ArrayContains(lineIDs, bystander.GetEntityID()) {
      GameObjectEffectHelper.StartEffectEvent(bystander, n"weakspot_overload");
      GameObjectEffectHelper.StartEffectEvent(bystander, n"emp_hit");
    }
    j += 1;
  }

  let maxHealth: Float = statsSystem.GetStatValue(Cast<StatsObjectID>(playerID), gamedataStatType.Health);
  let selfDamage: Float = maxHealth * TDOConfig.FalconPhaseRoundSelfDamagePercent();
  pools.RequestChangingStatPoolValue(Cast<StatsObjectID>(playerID), gamedataStatPoolType.Health, -selfDamage, player, false, false);
}

@wrapMethod(ShootEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);

  if !TDOConfig.FalconPhaseRoundEnabled() { return; }

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }

  if !TDO_Falcon_IsSandyActive(player) { return; }
  if !TDO_Falcon_IsEquipped(player) { return; }

  let weapon: ref<WeaponObject> = TDO_Falcon_GetHeldWeapon(player);
  if !IsDefined(weapon) { return; }

  if !TDO_Falcon_IsTechWeapon(weapon) { return; }
  if !TDO_Falcon_IsWeaponFullyCharged(weapon, scriptInterface) { return; }

  TDO_Falcon_FirePhaseRound(player, weapon);
}

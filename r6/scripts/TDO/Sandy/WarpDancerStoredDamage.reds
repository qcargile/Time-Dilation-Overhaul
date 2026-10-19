module TDO.Sandy

import TDO.Logging.*

@addField(NPCPuppet)
public let m_warpDancerStored: Float;

@addField(gameHitEvent)
public let m_tdoWarpDancerStoresHealth: Bool;

@addField(gameHitEvent)
public let m_tdoWarpDancerPendingHealth: Float;

@wrapMethod(StatPoolsManager)
public final static func ApplyDamage(hitEvent: ref<gameHitEvent>, forReal: Bool, out valuesLost: array<SDamageDealt>) -> Void {
  if !forReal {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  if !TDOConfig.WarpDancerEnabled() {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let target: ref<GameObject> = hitEvent.target;
  if !IsDefined(target) || target.IsPlayer() {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let npc: ref<NPCPuppet> = target as NPCPuppet;
  if !IsDefined(npc) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let instigator: wref<GameObject> = hitEvent.attackData.GetInstigator();
  if !IsDefined(instigator) || !instigator.IsPlayer() {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let player: ref<PlayerPuppet> = instigator as PlayerPuppet;
  if !IsDefined(player) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  if !TDO_WarpDancer_IsActive(player) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }

  let damageValue: Float = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
  if damageValue <= 0.0 {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }

  let storedBefore: Float = npc.m_warpDancerStored;
  hitEvent.m_tdoWarpDancerStoresHealth = true;
  wrappedMethod(hitEvent, forReal, valuesLost);
  hitEvent.m_tdoWarpDancerStoresHealth = false;
  hitEvent.m_tdoWarpDancerPendingHealth = 0.0;

  let attackValues: array<Float> = hitEvent.attackComputed.GetAttackValues();
  let i: Int32 = 0;
  while i < ArraySize(attackValues) {
    attackValues[i] = 0.0;
    i += 1;
  }
  hitEvent.attackComputed.SetAttackValues(attackValues);

  if npc.m_warpDancerStored > storedBefore {
    TDOTrace("WarpDancer", "stored health dmg=" + ToString(npc.m_warpDancerStored - storedBefore) + " npc=" + ToString(npc.GetEntityID()) + " stored=" + ToString(npc.m_warpDancerStored));
    if !TDO_WarpDancer_TrackedAlready(player, npc) {
      ArrayPush(player.m_warpDancerStoredNPCs, npc);
    }
  }
}

@wrapMethod(StatPoolsManager)
private final static func ApplyDamageSingle(hitEvent: ref<gameHitEvent>, dmgType: gamedataDamageType, initialDamageValue: Float, forReal: Bool, valuesLost: script_ref<[SDamageDealt]>) -> Void {
  if !hitEvent.m_tdoWarpDancerStoresHealth {
    wrappedMethod(hitEvent, dmgType, initialDamageValue, forReal, valuesLost);
    return;
  }

  let wasKillingBlow: Bool = hitEvent.attackData.HasFlag(hitFlag.WasKillingBlow);
  hitEvent.m_tdoWarpDancerPendingHealth = 0.0;
  wrappedMethod(hitEvent, dmgType, initialDamageValue, forReal, valuesLost);
  let healthDamage: Float = hitEvent.m_tdoWarpDancerPendingHealth;
  hitEvent.m_tdoWarpDancerPendingHealth = 0.0;
  if healthDamage <= 0.0 {
    return;
  }

  let absorbed: Float = 0.0;
  let i: Int32 = 0;
  while i < ArraySize(Deref(valuesLost)) {
    if Equals(Deref(valuesLost)[i].affectedStatPool, gamedataStatPoolType.CPO_Armor) || Equals(Deref(valuesLost)[i].affectedStatPool, gamedataStatPoolType.Overshield) {
      absorbed += Deref(valuesLost)[i].value;
    }
    i += 1;
  }

  if absorbed >= initialDamageValue && healthDamage <= 1.0 {
    hitEvent.m_tdoWarpDancerStoresHealth = false;
    StatPoolsManager.DrainStatPool(hitEvent, gamedataStatPoolType.Health, healthDamage);
    hitEvent.m_tdoWarpDancerStoresHealth = true;
    return;
  }

  let npc: ref<NPCPuppet> = hitEvent.target as NPCPuppet;
  npc.m_warpDancerStored += healthDamage;
  i = ArraySize(Deref(valuesLost)) - 1;
  while i >= 0 {
    if Equals(Deref(valuesLost)[i].affectedStatPool, gamedataStatPoolType.Health) {
      ArrayErase(Deref(valuesLost), i);
    }
    i -= 1;
  }
  if !wasKillingBlow {
    hitEvent.attackData.RemoveFlag(hitFlag.WasKillingBlow);
  }
}

@wrapMethod(StatPoolsManager)
private final static func ApplyLocalizedDamageSingle(hitEvent: ref<gameHitEvent>, dmg: Float, dmgType: gamedataDamageType, poolType: gamedataStatPoolType, forReal: Bool, valuesLost: script_ref<[SDamageDealt]>) -> Void {
  if hitEvent.m_tdoWarpDancerStoresHealth {
    ArrayClear(Deref(valuesLost));
    return;
  }
  wrappedMethod(hitEvent, dmg, dmgType, poolType, forReal, valuesLost);
}

@wrapMethod(StatPoolsManager)
public final static func DrainStatPool(hitEvent: ref<gameHitEvent>, statPoolType: gamedataStatPoolType, value: Float) -> Void {
  if hitEvent.m_tdoWarpDancerStoresHealth && Equals(statPoolType, gamedataStatPoolType.Health) {
    if value > 0.0 {
      hitEvent.m_tdoWarpDancerPendingHealth += value;
    }
    return;
  }
  wrappedMethod(hitEvent, statPoolType, value);
}

public func TDO_WarpDancer_TrackedAlready(player: ref<PlayerPuppet>, npc: ref<NPCPuppet>) -> Bool {
  let id: EntityID = npc.GetEntityID();
  let i: Int32 = 0;
  while i < ArraySize(player.m_warpDancerStoredNPCs) {
    let existing: wref<NPCPuppet> = player.m_warpDancerStoredNPCs[i];
    if IsDefined(existing) && Equals(existing.GetEntityID(), id) {
      return true;
    }
    i += 1;
  }
  return false;
}

public func TDO_WarpDancer_FlushStoredDamage(player: ref<PlayerPuppet>) -> Void {
  let game: GameInstance = player.GetGame();
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(game);
  let count: Int32 = ArraySize(player.m_warpDancerStoredNPCs);
  let total: Float = 0.0;
  let i: Int32 = 0;
  while i < ArraySize(player.m_warpDancerStoredNPCs) {
    let npc: wref<NPCPuppet> = player.m_warpDancerStoredNPCs[i];
    if IsDefined(npc) {
      let stored: Float = npc.m_warpDancerStored;
      if stored > 0.0 {
        let id: StatsObjectID = Cast<StatsObjectID>(npc.GetEntityID());
        let currentHealth: Float = pools.GetStatPoolValue(id, gamedataStatPoolType.Health, false);
        if !npc.IsDead() && TDOConfig.WarpDancerStoredDamageCanKill() && stored >= currentHealth {
          npc.Kill(player, false, false);
        } else {
          pools.RequestChangingStatPoolValue(id, gamedataStatPoolType.Health, -stored, player, false, false);
        }
        npc.m_warpDancerStored = 0.0;
        total += stored;
      }
    }
    i += 1;
  }
  ArrayClear(player.m_warpDancerStoredNPCs);
  TDODebug("WarpDancer", "flushed stored damage total=" + ToString(total) + " across " + ToString(count) + " npcs");
}

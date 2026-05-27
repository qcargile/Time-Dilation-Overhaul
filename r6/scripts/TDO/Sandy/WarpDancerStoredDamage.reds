module TDO.Sandy

import TDO.Logging.*

@addField(NPCPuppet)
public let m_warpDancerStored: Float;

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

  let attackValues: array<Float> = hitEvent.attackComputed.GetAttackValues();
  let i: Int32 = 0;
  while i < ArraySize(attackValues) {
    attackValues[i] = 0.0;
    i += 1;
  }
  hitEvent.attackComputed.SetAttackValues(attackValues);

  npc.m_warpDancerStored += damageValue;
  TDOTrace("WarpDancer", "absorbed dmg=" + ToString(damageValue) + " npc=" + ToString(npc.GetEntityID()) + " stored=" + ToString(npc.m_warpDancerStored));

  if !TDO_WarpDancer_TrackedAlready(player, npc) {
    ArrayPush(player.m_warpDancerStoredNPCs, npc);
  }

  wrappedMethod(hitEvent, forReal, valuesLost);
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
        pools.RequestChangingStatPoolValue(id, gamedataStatPoolType.Health, -stored, player, false, false);
        npc.m_warpDancerStored = 0.0;
        total += stored;
      }
    }
    i += 1;
  }
  ArrayClear(player.m_warpDancerStoredNPCs);
  TDODebug("WarpDancer", "flushed stored damage total=" + ToString(total) + " across " + ToString(count) + " npcs");
}

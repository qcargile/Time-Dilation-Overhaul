module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoKurosawaSandyActive: Bool;

@addField(PlayerPuppet)
public let m_tdoKurosawaSlowedNPCs: array<EntityID>;

@addField(PlayerPuppet)
public let m_tdoKurosawaPOPed: array<EntityID>;

@addField(PlayerPuppet)
public let m_tdoKurosawaRemaining: Float;

@wrapMethod(NewPerkFinisherCondition)
public final const func Test(const activatorObject: wref<GameObject>, const hotSpotObject: wref<GameObject>) -> Bool {
  let result: Bool = wrappedMethod(activatorObject, hotSpotObject);
  if !result {
    return false;
  }
  let player: ref<PlayerPuppet> = activatorObject as PlayerPuppet;
  if !IsDefined(player) {
    return result;
  }
  if !player.m_tdoKurosawaSandyActive {
    return result;
  }
  if ArrayContains(player.m_tdoKurosawaSlowedNPCs, hotSpotObject.GetEntityID()) {
    return result;
  }
  return false;
}

public func TDO_Kurosawa_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return false;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return false;
  }
  let i: Int32 = 0;
  while i < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, i);
    if ItemID.IsValid(itemID) {
      let tdb: TweakDBID = ItemID.GetTDBID(itemID);
      if Equals(tdb, t"Items.TDO_Kurosawa") || Equals(tdb, t"Items.TDO_KurosawaPlus") {
        return true;
      }
    }
    i += 1;
  }
  return false;
}

public func TDO_Kurosawa_IsActive(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  if !player.m_tdoKurosawaSandyActive {
    return false;
  }
  return TDO_Kurosawa_IsEquipped(player);
}

public func TDO_Kurosawa_IsPlusEquipped(player: ref<PlayerPuppet>) -> Bool {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return false;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return false;
  }
  let i: Int32 = 0;
  while i < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, i);
    if ItemID.IsValid(itemID) {
      if Equals(ItemID.GetTDBID(itemID), t"Items.TDO_KurosawaPlus") {
        return true;
      }
    }
    i += 1;
  }
  return false;
}

public func TDO_Kurosawa_ComputeAttunementBonus(player: ref<PlayerPuppet>) -> Float {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let pid: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
  let body: Float = stats.GetStatValue(pid, gamedataStatType.Strength);
  let perPoint: Float = TDOConfig.KurosawaAttunementPerPointPct() / 100.0;
  let cap: Float = TDOConfig.KurosawaAttunementPerAttrCapPct() / 100.0;
  let bonus: Float = body * perPoint;
  if bonus > cap {
    bonus = cap;
  }
  return bonus;
}

public func TDO_Kurosawa_ComputePOPRefund(player: ref<PlayerPuppet>) -> Float {
  let base: Float = TDOConfig.KurosawaPOPRefundBase();
  let bonus: Float = TDOConfig.KurosawaPOPRefundAttunementBonus();
  let cap: Float = TDOConfig.KurosawaAttunementPerAttrCapPct() / 100.0;
  if cap <= 0.0 {
    return base;
  }
  let attBonus: Float = TDO_Kurosawa_ComputeAttunementBonus(player);
  let ratio: Float = attBonus / cap;
  if ratio > 1.0 {
    ratio = 1.0;
  }
  if ratio < 0.0 {
    ratio = 0.0;
  }
  return base + ratio * bonus;
}

public func TDO_Kurosawa_ApplySlowToNPC(npc: ref<NPCPuppet>, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(npc) || !IsDefined(player) {
    return;
  }
  if TDO_IsPlayerInVehicle(player) {
    return;
  }
  npc.SetIndividualTimeDilation(n"TDO_KurosawaSlow", TDOConfig.KurosawaIndividualSlowMult(), TDOConfig.KurosawaSlowDuration(), n"None", n"None", false, false);
  StatusEffectHelper.ApplyStatusEffect(npc, t"StatusEffects.TDO_KurosawaSlowMark");
  let id: EntityID = npc.GetEntityID();
  if !ArrayContains(player.m_tdoKurosawaSlowedNPCs, id) {
    ArrayPush(player.m_tdoKurosawaSlowedNPCs, id);
  }
}

public func TDO_Kurosawa_ClearAllSlows(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) {
    return;
  }
  let gi: GameInstance = player.GetGame();
  let i: Int32 = 0;
  while i < ArraySize(player.m_tdoKurosawaSlowedNPCs) {
    let id: EntityID = player.m_tdoKurosawaSlowedNPCs[i];
    let npc: ref<NPCPuppet> = GameInstance.FindEntityByID(gi, id) as NPCPuppet;
    if IsDefined(npc) {
      npc.UnsetIndividualTimeDilation();
      StatusEffectHelper.RemoveStatusEffect(npc, t"StatusEffects.TDO_KurosawaSlowMark");
    }
    i += 1;
  }
  ArrayClear(player.m_tdoKurosawaSlowedNPCs);
}

public class TDO_KurosawaKillCheck extends DelayCallback {

  public let m_player: ref<PlayerPuppet>;
  public let m_npcID: EntityID;
  public let m_attempt: Int32;

  public func Call() -> Void {
    if !IsDefined(this.m_player) {
      return;
    }
    let gi: GameInstance = this.m_player.GetGame();
    let npc: ref<NPCPuppet> = GameInstance.FindEntityByID(gi, this.m_npcID) as NPCPuppet;
    if !IsDefined(npc) {
      return;
    }
    if ArrayContains(this.m_player.m_tdoKurosawaPOPed, this.m_npcID) {
      return;
    }
    if !npc.IsDead() && !ScriptedPuppet.IsDefeated(npc) {
      if this.m_attempt < 3 {
        let retry: ref<TDO_KurosawaKillCheck> = new TDO_KurosawaKillCheck();
        retry.m_player = this.m_player;
        retry.m_npcID = this.m_npcID;
        retry.m_attempt = this.m_attempt + 1;
        GameInstance.GetDelaySystem(gi).DelayCallback(retry, 0.4, false);
      }
      return;
    }
    ArrayPush(this.m_player.m_tdoKurosawaPOPed, this.m_npcID);
    let refundSeconds: Float = TDO_Kurosawa_ComputePOPRefund(this.m_player);
    if refundSeconds > 0.0 {
      this.m_player.m_tdoKurosawaRemaining += refundSeconds;
    }
    let pop: ref<TDO_KurosawaPOP> = new TDO_KurosawaPOP();
    pop.m_player = this.m_player;
    pop.m_npcID = this.m_npcID;
    GameInstance.GetDelaySystem(gi).DelayCallback(pop, TDOConfig.KurosawaPOPDelay(), false);
  }
}

public class TDO_KurosawaPOP extends DelayCallback {

  public let m_player: ref<PlayerPuppet>;
  public let m_npcID: EntityID;

  public func Call() -> Void {
    if !IsDefined(this.m_player) {
      return;
    }
    let gi: GameInstance = this.m_player.GetGame();
    let npc: ref<NPCPuppet> = GameInstance.FindEntityByID(gi, this.m_npcID) as NPCPuppet;
    if IsDefined(npc) {
      let pos: Vector4 = npc.GetWorldPosition();
      DismembermentComponent.RequestDismemberment(npc, gameDismBodyPart.HEAD, gameDismWoundType.COARSE, pos, true);
      DismembermentComponent.RequestDismemberment(npc, gameDismBodyPart.BODY, gameDismWoundType.COARSE, pos, true);
      GameObjectEffectHelper.StartEffectEvent(npc, n"finisher_katana_02");
      GameObjectEffectHelper.StartEffectEvent(npc, n"blood_headshot");
      GameObjectEffectHelper.StartEffectEvent(npc, n"takedown_aerial_front_blood_ground");
    }
    let healPct: Float;
    if TDO_Kurosawa_IsPlusEquipped(this.m_player) {
      healPct = TDOConfig.KurosawaPOPHealPctPlus();
    } else {
      healPct = TDOConfig.KurosawaPOPHealPctBase();
    }
    if healPct > 0.0 {
      let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
      let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
      let playerStatsID: StatsObjectID = Cast<StatsObjectID>(this.m_player.GetEntityID());
      let maxHP: Float = stats.GetStatValue(playerStatsID, gamedataStatType.Health);
      let healAmount: Float = maxHP * (healPct / 100.0);
      pools.RequestChangingStatPoolValue(playerStatsID, gamedataStatPoolType.Health, healAmount, this.m_player, false, false);
    }
  }
}

public class TDO_KurosawaReAssertCallback extends DelayCallback {
  public let m_player: ref<PlayerPuppet>;
  public let m_interval: Float;

  public func Call() -> Void {
    if !IsDefined(this.m_player) || !this.m_player.m_tdoKurosawaSandyActive {
      return;
    }
    let gi: GameInstance = this.m_player.GetGame();
    let i: Int32 = 0;
    while i < ArraySize(this.m_player.m_tdoKurosawaSlowedNPCs) {
      let npc: ref<NPCPuppet> = GameInstance.FindEntityByID(gi, this.m_player.m_tdoKurosawaSlowedNPCs[i]) as NPCPuppet;
      if IsDefined(npc) && !npc.IsDead() && !npc.HasIndividualTimeDilation(n"TDO_KurosawaSlow") {
        npc.SetIndividualTimeDilation(n"TDO_KurosawaSlow", TDOConfig.KurosawaIndividualSlowMult(), TDOConfig.KurosawaSlowDuration(), n"None", n"None", false, false);
      }
      i += 1;
    }
    let baseDur: Float = TDOConfig.KurosawaDuration();
    this.m_player.m_tdoKurosawaRemaining -= this.m_interval;
    let poolPct: Float = ClampF(this.m_player.m_tdoKurosawaRemaining / baseDur * 100.0, 0.0, 100.0);
    GameInstance.GetStatPoolsSystem(gi).RequestSettingStatPoolValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatPoolType.SandevistanCharge, poolPct, null);
    TDOTrace("Kurosawa", "remaining=" + ToString(this.m_player.m_tdoKurosawaRemaining) + " pool=" + ToString(poolPct));
    if this.m_player.m_tdoKurosawaRemaining <= 0.0 {
      return;
    }
    let next: ref<TDO_KurosawaReAssertCallback> = new TDO_KurosawaReAssertCallback();
    next.m_player = this.m_player;
    next.m_interval = this.m_interval;
    GameInstance.GetDelaySystem(gi).DelayCallback(next, this.m_interval, false);
  }
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    if TDOConfig.KurosawaEnabled() && TDO_Kurosawa_IsEquipped(player) {
      player.m_tdoKurosawaSandyActive = true;
      TDOInfo("Kurosawa", "Sandevistan active (blade slow-transfer armed)");
      ArrayClear(player.m_tdoKurosawaSlowedNPCs);
      ArrayClear(player.m_tdoKurosawaPOPed);
      player.m_tdoKurosawaRemaining = TDOConfig.KurosawaDuration();
      GameInstance.GetStatPoolsSystem(player.GetGame()).RequestSettingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.SandevistanCharge, 100.0, null);
      let reCb: ref<TDO_KurosawaReAssertCallback> = new TDO_KurosawaReAssertCallback();
      reCb.m_player = player;
      reCb.m_interval = 0.2; // re-assert cadence (s)
      GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(reCb, reCb.m_interval, false);
    } else {
      player.m_tdoKurosawaSandyActive = false;
    }
  }
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    player.m_tdoKurosawaSandyActive = false;
    TDOInfo("Kurosawa", "Sandevistan ended, slows cleared");
    TDO_Kurosawa_ClearAllSlows(player);
    ArrayClear(player.m_tdoKurosawaPOPed);
  }
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    player.m_tdoKurosawaSandyActive = false;
    TDO_Kurosawa_ClearAllSlows(player);
    ArrayClear(player.m_tdoKurosawaPOPed);
  }
}

@wrapMethod(StatPoolsManager)
public final static func ApplyDamage(hitEvent: ref<gameHitEvent>, forReal: Bool, out valuesLost: array<SDamageDealt>) -> Void {
  if !forReal {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  if !TDOConfig.KurosawaEnabled() {
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
  if !IsDefined(player) || !TDO_Kurosawa_IsActive(player) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  if !AttackData.IsMelee(hitEvent.attackData.GetAttackType()) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }

  TDO_Kurosawa_ApplySlowToNPC(npc, player);

  let killCheck: ref<TDO_KurosawaKillCheck> = new TDO_KurosawaKillCheck();
  killCheck.m_player = player;
  killCheck.m_npcID = npc.GetEntityID();
  GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(killCheck, 0.15, false);

  wrappedMethod(hitEvent, forReal, valuesLost);
}

@wrapMethod(FinisherAttackEvents)
public final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if !TDOConfig.KurosawaEnabled() {
    return;
  }
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) || !TDO_Kurosawa_IsActive(player) {
    return;
  }
  if !IsDefined(this.stateMachineInitData) {
    return;
  }
  let target: ref<NPCPuppet> = this.stateMachineInitData.target as NPCPuppet;
  if !IsDefined(target) {
    return;
  }
  let id: EntityID = target.GetEntityID();
  if !ArrayContains(player.m_tdoKurosawaSlowedNPCs, id) {
    return;
  }
  if ArrayContains(player.m_tdoKurosawaPOPed, id) {
    return;
  }
  ArrayPush(player.m_tdoKurosawaPOPed, id);

  let refundSeconds: Float = TDO_Kurosawa_ComputePOPRefund(player) * 2.0;
  if refundSeconds > 0.0 {
    player.m_tdoKurosawaRemaining += refundSeconds;
  }

  let healPct: Float;
  if TDO_Kurosawa_IsPlusEquipped(player) {
    healPct = TDOConfig.KurosawaPOPHealPctPlus();
  } else {
    healPct = TDOConfig.KurosawaPOPHealPctBase();
  }
  healPct = healPct * 2.0;
  if healPct > 0.0 {
    let gi: GameInstance = player.GetGame();
    let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
    let pid: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let maxHP: Float = stats.GetStatValue(pid, gamedataStatType.Health);
    let healAmount: Float = maxHP * (healPct / 100.0);
    pools.RequestChangingStatPoolValue(pid, gamedataStatPoolType.Health, healAmount, player, false, false);
  }
  TDOInfo("Kurosawa", "finisher double-pop on slowed enemy id=" + ToString(id));
}

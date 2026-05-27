@addField(PlayerPuppet)
public let m_tdoFusilladeRampHits: Int32;

@addField(PlayerPuppet)
public let m_tdoFusilladeShotInFlight: Bool;

public func TDO_Fusillade_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
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
      if Equals(tdb, t"Items.TDO_Fusillade") || Equals(tdb, t"Items.TDO_FusilladePlus") {
        return true;
      }
    }
    i += 1;
  }
  return false;
}

public func TDO_Fusillade_GetEquippedTier(player: ref<PlayerPuppet>) -> Int32 {
  if !IsDefined(player) {
    return 0;
  }
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return 0;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return 0;
  }
  let i: Int32 = 0;
  while i < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, i);
    if ItemID.IsValid(itemID) {
      let tdb: TweakDBID = ItemID.GetTDBID(itemID);
      if Equals(tdb, t"Items.TDO_FusilladePlus") {
        return 2;
      }
      if Equals(tdb, t"Items.TDO_Fusillade") {
        return 1;
      }
    }
    i += 1;
  }
  return 0;
}

public func TDO_Fusillade_IsSandyActive(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) {
    return false;
  }
  let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
  return td == EnumInt(gamePSMTimeDilation.Sandevistan);
}

public func TDO_Fusillade_IsMechanicActive(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  if !TDOConfig.FusilladeFireRateRealTimeEnabled() {
    return false;
  }
  if !TDO_Fusillade_IsEquipped(player) {
    return false;
  }
  return TDO_Fusillade_IsSandyActive(player);
}

public func TDO_Fusillade_GetRampFraction(player: ref<PlayerPuppet>) -> Float {
  let start: Float;
  if TDO_Fusillade_GetEquippedTier(player) >= 2 {
    start = TDOConfig.FusilladeRampStartMax();
  } else {
    start = TDOConfig.FusilladeRampStartMin();
  }
  let frac: Float = start + Cast<Float>(player.m_tdoFusilladeRampHits) * TDOConfig.FusilladeRampStep();
  if frac > 1.0 {
    frac = 1.0;
  }
  if frac < 0.0 {
    frac = 0.0;
  }
  return frac;
}

public func TDO_Fusillade_TryRefill(player: ref<PlayerPuppet>, rampFraction: Float) -> Void {
  if !TDOConfig.FusilladeAmmoRefillEnabled() {
    return;
  }
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  let reflexes: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Reflexes);
  let chance: Float = reflexes * TDOConfig.FusilladeAmmoRefillPerReflexes();
  let maxChance: Float = TDOConfig.FusilladeAmmoRefillMaxChancePct();
  if chance > maxChance {
    chance = maxChance;
  }
  chance = chance * rampFraction;
  if chance <= 0.0 {
    return;
  }
  let roll: Float = RandRangeF(0.0, 100.0);
  if roll >= chance {
    return;
  }
  let weapon: wref<WeaponObject> = GameObject.GetActiveWeapon(player);
  if !IsDefined(weapon) {
    return;
  }
  let capacity: Int32 = Cast<Int32>(WeaponObject.GetMagazineCapacity(weapon));
  let current: Int32 = Cast<Int32>(WeaponObject.GetMagazineAmmoCount(weapon));
  if current >= capacity {
    return;
  }
  let refundEvent: ref<SetAmmoCountEvent> = new SetAmmoCountEvent();
  refundEvent.ammoTypeID = WeaponObject.GetAmmoType(weapon);
  refundEvent.count = Cast<Uint32>(current + 1);
  weapon.QueueEvent(refundEvent);
}

@wrapMethod(WeaponTransition)
protected final const func CalcCycleTimeDeltaFactor(cycleTime: Float, scriptInterface: ref<StateGameScriptInterface>) -> Float {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  let globalTimeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();
  if globalTimeDilation <= 0.00 || globalTimeDilation >= 1.00 {
    return wrappedMethod(cycleTime, scriptInterface);
  };
  if IsDefined(player) && player.m_warpDancerPhase == 1 {
    return 1.00 / globalTimeDilation;
  };
  if !TDOConfig.FusilladeFireRateRealTimeEnabled() {
    return wrappedMethod(cycleTime, scriptInterface);
  };
  if !scriptInterface.GetTimeSystem().IsTimeDilationActive(n"sandevistan") {
    return wrappedMethod(cycleTime, scriptInterface);
  };
  if !TDO_Fusillade_IsEquipped(player) {
    return wrappedMethod(cycleTime, scriptInterface);
  };
  return (1.00 / globalTimeDilation) * TDOConfig.FusilladeFireRateMult();
}

@wrapMethod(ShootEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !TDO_Fusillade_IsMechanicActive(player) {
    return;
  }
  if player.m_tdoFusilladeShotInFlight {
    player.m_tdoFusilladeRampHits = 0;
  }
  player.m_tdoFusilladeShotInFlight = true;
}

@wrapMethod(StatPoolsManager)
public final static func ApplyDamage(hitEvent: ref<gameHitEvent>, forReal: Bool, out valuesLost: array<SDamageDealt>) -> Void {
  if !forReal {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let instigator: wref<GameObject> = hitEvent.attackData.GetInstigator();
  if !IsDefined(instigator) || !instigator.IsPlayer() {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let player: ref<PlayerPuppet> = instigator as PlayerPuppet;
  if !IsDefined(player) || !TDO_Fusillade_IsMechanicActive(player) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  if !Equals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Ranged) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let target: ref<GameObject> = hitEvent.target;
  if !IsDefined(target) || target.IsPlayer() {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  player.m_tdoFusilladeShotInFlight = false;
  let npc: ref<NPCPuppet> = target as NPCPuppet;
  if !IsDefined(npc) {
    wrappedMethod(hitEvent, forReal, valuesLost);
    return;
  }
  let frac: Float = TDO_Fusillade_GetRampFraction(player);
  hitEvent.attackComputed.MultAttackValue(frac);
  wrappedMethod(hitEvent, forReal, valuesLost);
  player.m_tdoFusilladeRampHits += 1;
  TDO_Fusillade_TryRefill(player, frac);
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    player.m_tdoFusilladeRampHits = 0;
    player.m_tdoFusilladeShotInFlight = false;
  }
}

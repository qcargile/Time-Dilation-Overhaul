module TDO.Sandy

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoQuantumListenerRegistered: Bool;

@addField(PlayerPuppet)
public let m_tdoQuantumListener: ref<TDOSandyChargeListener>;

@addMethod(PlayerPuppet)
public final func TDO_Quantum_IsAdvancedEquipped() -> Bool {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(this);
  if !IsDefined(es) {
    return false;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(this);
  if !IsDefined(pd) {
    return false;
  }
  let osItem: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, 0);
  let tdb: TweakDBID = ItemID.GetTDBID(osItem);
  return Equals(tdb, t"Items.TDO_QuantumAdvanced") || Equals(tdb, t"Items.TDO_QuantumAdvancedPlus") || Equals(tdb, t"Items.TDO_QuantumAdvancedPlusPlus");
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_GetCharges() -> Int32 {
  let se: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(this, t"StatusEffects.TDO_QuantumSpareCharge");
  if IsDefined(se) {
    return Cast<Int32>(se.GetStackCount());
  }
  return 0;
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_ApplyOneStack() -> Void {
  GameInstance.GetStatusEffectSystem(this.GetGame()).ApplyStatusEffect(
    this.GetEntityID(),
    t"StatusEffects.TDO_QuantumSpareCharge",
    TDBID.None(),
    this.GetEntityID(),
    1u
  );
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_ApplyFullCharges() -> Void {
  let targetStacks: Int32 = TDOConfig.QuantumMaxCharges();
  let i: Int32 = this.TDO_Quantum_GetCharges();
  while i < targetStacks {
    this.TDO_Quantum_ApplyOneStack();
    i += 1;
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_ConsumeOneCharge() -> Void {
  StatusEffectHelper.RemoveStatusEffect(this, t"StatusEffects.TDO_QuantumSpareCharge", 1u);
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_GetRechargeDuration() -> Float {
  let tier: Int32 = TDO_Quantum_TierForTDB(TDO_Quantum_GetEquippedTDB(this));
  return TDOConfig.LerpTier(TDOConfig.QuantumCooldownMax(), TDOConfig.QuantumCooldownMin(), tier, 5);
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_RefillPool() -> Void {
  let poolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  if !IsDefined(poolSystem) {
    return;
  }
  let ownerID: StatsObjectID = Cast<StatsObjectID>(this.GetEntityID());
  poolSystem.RequestSettingStatPoolValue(ownerID, gamedataStatPoolType.SandevistanCharge, 100.0, null);
}

public class TDO_QuantumSingleRegenCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if !IsDefined(this.player) {
      return;
    }
    if !this.player.TDO_Quantum_IsAdvancedEquipped() {
      return;
    }
    if this.player.TDO_Quantum_GetCharges() >= TDOConfig.QuantumMaxCharges() {
      return;
    }
    this.player.TDO_Quantum_ApplyOneStack();
  }
}

public class TDO_QuantumEquipInitCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if !IsDefined(this.player) {
      return;
    }
    if !this.player.TDO_Quantum_IsAdvancedEquipped() {
      return;
    }
    this.player.TDO_Quantum_ApplyFullCharges();
  }
}

public class TDOSandyChargeListener extends ScriptStatPoolsListener {
  public let player: wref<PlayerPuppet>;

  public func OnStatPoolValueChanged(oldValue: Float, newValue: Float, percToPoints: Float) -> Void {
    let p: ref<PlayerPuppet> = this.player;
    if !IsDefined(p) {
      return;
    }
    if !p.TDO_Quantum_IsAdvancedEquipped() {
      return;
    }

    if oldValue > 0.01 && newValue <= 0.01 {
      if p.TDO_Quantum_GetCharges() > 0 {
        p.TDO_Quantum_RefillPool();
        TDODebug("QuantumCharge", "pool depleted mid-Sandy, auto-refilled (spares=" + ToString(p.TDO_Quantum_GetCharges()) + ")");
      }
      return;
    }
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_RegisterListenerIfNeeded() -> Void {
  if this.m_tdoQuantumListenerRegistered {
    return;
  }
  let poolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
  if !IsDefined(poolSystem) {
    return;
  }
  let listener: ref<TDOSandyChargeListener> = new TDOSandyChargeListener();
  listener.player = this;
  poolSystem.RequestRegisteringListener(
    Cast<StatsObjectID>(this.GetEntityID()),
    gamedataStatPoolType.SandevistanCharge,
    listener
  );
  this.m_tdoQuantumListener = listener;
  this.m_tdoQuantumListenerRegistered = true;
}

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !player.TDO_Quantum_IsAdvancedEquipped() {
    return;
  }

  player.TDO_Quantum_RegisterListenerIfNeeded();

  if player.TDO_Quantum_GetCharges() > 0 {
    player.TDO_Quantum_ConsumeOneCharge();
    TDODebug("QuantumCharge", "consumed spare charge, " + ToString(player.TDO_Quantum_GetCharges()) + " left, regen in " + ToString(player.TDO_Quantum_GetRechargeDuration()) + "s");
    let regenCb: ref<TDO_QuantumSingleRegenCallback> = new TDO_QuantumSingleRegenCallback();
    regenCb.player = player;
    GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(regenCb, player.TDO_Quantum_GetRechargeDuration(), false);
  }
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !player.TDO_Quantum_IsAdvancedEquipped() {
    return;
  }

  if player.TDO_Quantum_GetCharges() > 0 {
    player.TDO_Quantum_RefillPool();
  }
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);

  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  if !player.TDO_Quantum_IsAdvancedEquipped() {
    return;
  }

  if player.TDO_Quantum_GetCharges() > 0 {
    player.TDO_Quantum_RefillPool();
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  let cb: ref<TDO_QuantumEquipInitCallback> = new TDO_QuantumEquipInitCallback();
  cb.player = this;
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(cb, 1.0, false);
  return result;
}

@wrapMethod(SandevistanDecisions)
public func OnStatChanged(ownerID: StatsObjectID, statType: gamedataStatType, diff: Float, total: Float) -> Void {
  wrappedMethod(ownerID, statType, diff, total);
  if Equals(statType, gamedataStatType.HasSandevistan) && total > 0.0 {
    let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());
    if IsDefined(player) && player.TDO_Quantum_IsAdvancedEquipped() {
      player.TDO_Quantum_ApplyFullCharges();
      TDOInfo("QuantumCharge", "charges set to full on Sandy unlock (max=" + ToString(TDOConfig.QuantumMaxCharges()) + ")");
    }
  }
}

@addMethod(PlayerPuppet)
public final func TDO_Quantum_RevalidateCharges() -> Void {
  if this.TDO_Quantum_IsAdvancedEquipped() {
    return;
  }
  if this.TDO_Quantum_GetCharges() > 0 {
    StatusEffectHelper.RemoveStatusEffect(this, t"StatusEffects.TDO_QuantumSpareCharge");
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnItemRemovedFromSlot(evt: ref<ItemRemovedFromSlot>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  this.TDO_Quantum_RevalidateCharges();
  return result;
}

module TDO.Sandy

import TDO.Logging.*

public func TDO_Tanto_GetEquippedTier(player: ref<PlayerPuppet>) -> Int32 {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return 0;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return 0;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let tier: Int32 = TDO_Tanto_TierForItemTDB(ItemID.GetTDBID(itemID));
      if tier > 0 {
        return tier;
      }
    }
    slotIdx += 1;
  }
  return 0;
}

public class TantoChargeSystem extends ScriptableSystem {
  private persistent let m_charges: Int32 = 0;

  public static func GetInstance(gi: GameInstance) -> ref<TantoChargeSystem> {
    return GameInstance.GetScriptableSystemsContainer(gi).Get(n"TDO.Sandy.TantoChargeSystem") as TantoChargeSystem;
  }

  public func GetCharges(player: ref<PlayerPuppet>) -> Int32 {
    this.Validate(player);
    return this.m_charges;
  }

  public func TryAddCharge(player: ref<PlayerPuppet>) -> Bool {
    this.Validate(player);
    let cap: Int32 = this.GetCapacity(player);
    if this.m_charges >= cap {
      return false;
    }
    this.m_charges += 1;
    TDODebug("TantoCharge", "charge gained " + ToString(this.m_charges) + "/" + ToString(cap));
    return true;
  }

  public func ConsumeCharge(player: ref<PlayerPuppet>) -> Bool {
    this.Validate(player);
    if this.m_charges <= 0 {
      return false;
    }
    this.m_charges -= 1;
    return true;
  }

  public func GetCapacity(player: ref<PlayerPuppet>) -> Int32 {
    let tier: Int32 = TDO_Tanto_GetEquippedTier(player);
    if tier <= 0 {
      return 1;
    }
    return TDO_Tanto_ChargesForTier(tier);
  }

  public func GetRange(player: ref<PlayerPuppet>) -> Float {
    let baseRange: Float = TDOConfig.TantoTeleportBaseRange();
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
    let reflexes: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Reflexes);
    let perPoint: Float = TDOConfig.TantoTeleportRangePerReflexes();
    let range: Float = baseRange + reflexes * perPoint;
    let maxRange: Float = TDOConfig.TantoTeleportMaxRange();
    if range > maxRange {
      range = maxRange;
    }
    return range;
  }

  private func Validate(player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(player) {
      return;
    }
    if !TDO_Tanto_IsEquipped(player) {
      if this.m_charges > 0 {
        this.m_charges = 0;
        StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_TantoChargeIndicator");
      }
    }
  }

  public func ForceRevalidate(player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(player) {
      return;
    }
    if !TDO_Tanto_IsEquipped(player) || !TDOConfig.TantoEnabled() {
      if this.m_charges > 0 {
        TDODebug("TantoCharge", "charges reset (unequipped or disabled)");
      }
      this.m_charges = 0;
      StatusEffectHelper.RemoveStatusEffect(player, t"StatusEffects.TDO_TantoChargeIndicator");
    }
  }
}

public func TDO_Tanto_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  return TDO_Tanto_GetEquippedTierIndex(player) >= 0;
}

@wrapMethod(PlayerPuppet)
protected cb func OnItemRemovedFromSlot(evt: ref<ItemRemovedFromSlot>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let system: ref<TantoChargeSystem> = TantoChargeSystem.GetInstance(this.GetGame());
  if IsDefined(system) {
    system.ForceRevalidate(this);
  }
  return result;
}

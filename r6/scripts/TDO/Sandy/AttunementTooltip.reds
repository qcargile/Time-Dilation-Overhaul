module TDO.Sandy

public enum TDO_AttunementKind {
  None = 0,
  Shrike = 1,
  Tanto = 2,
  WarpDancer = 3,
  Fusillade = 4,
  KurosawaBody = 5,
  Falcon = 6,
  Quantum = 9,
  QuantumAdvanced = 10,
  Sogimsu = 11,
  Juggernaut = 12,
  Pyrolith = 13
}

public func TDO_Attunement_GetScaling(itemID: TweakDBID, out refStat: gamedataStatType, out multiplier: Float) -> Bool {
  let kind: TDO_AttunementKind = TDO_Attunement_KindFor(itemID);
  switch kind {
    case TDO_AttunementKind.Shrike:          refStat = gamedataStatType.Reflexes;         multiplier = 0.1;   return true;
    case TDO_AttunementKind.Tanto:           refStat = gamedataStatType.Reflexes;         multiplier = 0.25;  return true;
    case TDO_AttunementKind.WarpDancer:      refStat = gamedataStatType.Cool;             multiplier = 0.05;  return true;
    case TDO_AttunementKind.Fusillade:       refStat = gamedataStatType.Reflexes;         multiplier = 0.25;  return true;
    case TDO_AttunementKind.KurosawaBody:    refStat = gamedataStatType.Strength;         multiplier = 0.05;  return true;
    case TDO_AttunementKind.Falcon:          refStat = gamedataStatType.TechnicalAbility; multiplier = 0.1;   return true;
    case TDO_AttunementKind.Quantum:         refStat = gamedataStatType.Cool;             multiplier = 0.0;   return true;
    case TDO_AttunementKind.QuantumAdvanced: refStat = gamedataStatType.Cool;             multiplier = 0.0;   return true;
    case TDO_AttunementKind.Sogimsu:         refStat = gamedataStatType.Cool;             multiplier = 0.05;  return true;
    case TDO_AttunementKind.Juggernaut:      refStat = gamedataStatType.Strength;         multiplier = 0.02;  return true;
    case TDO_AttunementKind.Pyrolith:        refStat = gamedataStatType.TechnicalAbility; multiplier = 0.02;  return true;
  }
  return false;
}

public func TDO_Attunement_KindFor(itemID: TweakDBID) -> TDO_AttunementKind {
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK1") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK1Plus") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK2") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK2Plus") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK3") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK3Plus") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK4") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK4Plus") { return TDO_AttunementKind.Shrike; }
  if Equals(itemID, t"Items.AdvancedSandevistanC1MK4PlusPlus") { return TDO_AttunementKind.Shrike; }

  if Equals(itemID, t"Items.AdvancedSandevistanC2MK1") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK1Plus") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK2") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK2Plus") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK3") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK3Plus") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK4") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK4Plus") { return TDO_AttunementKind.Tanto; }
  if Equals(itemID, t"Items.AdvancedSandevistanC2MK4PlusPlus") { return TDO_AttunementKind.Tanto; }

  if Equals(itemID, t"Items.AdvancedSandevistanC3MK3") { return TDO_AttunementKind.WarpDancer; }
  if Equals(itemID, t"Items.AdvancedSandevistanC3MK3Plus") { return TDO_AttunementKind.WarpDancer; }
  if Equals(itemID, t"Items.AdvancedSandevistanC3MK4") { return TDO_AttunementKind.WarpDancer; }
  if Equals(itemID, t"Items.AdvancedSandevistanC3MK4Plus") { return TDO_AttunementKind.WarpDancer; }
  if Equals(itemID, t"Items.AdvancedSandevistanC3MK5") { return TDO_AttunementKind.WarpDancer; }
  if Equals(itemID, t"Items.AdvancedSandevistanC3MK5Plus") { return TDO_AttunementKind.WarpDancer; }
  if Equals(itemID, t"Items.AdvancedSandevistanC3MK5PlusPlus") { return TDO_AttunementKind.WarpDancer; }

  if Equals(itemID, t"Items.AdvancedSandevistanC4MK4") { return TDO_AttunementKind.Falcon; }
  if Equals(itemID, t"Items.AdvancedSandevistanC4MK4Plus") { return TDO_AttunementKind.Falcon; }
  if Equals(itemID, t"Items.AdvancedSandevistanC4MK5") { return TDO_AttunementKind.Falcon; }
  if Equals(itemID, t"Items.AdvancedSandevistanC4MK5Plus") { return TDO_AttunementKind.Falcon; }
  if Equals(itemID, t"Items.AdvancedSandevistanC4MK5PlusPlus") { return TDO_AttunementKind.Falcon; }

  if Equals(itemID, t"Items.TDO_Fusillade") { return TDO_AttunementKind.Fusillade; }
  if Equals(itemID, t"Items.TDO_FusilladePlus") { return TDO_AttunementKind.Fusillade; }

  if Equals(itemID, t"Items.TDO_Kurosawa") { return TDO_AttunementKind.KurosawaBody; }
  if Equals(itemID, t"Items.TDO_KurosawaPlus") { return TDO_AttunementKind.KurosawaBody; }

  if Equals(itemID, t"Items.TDO_Quantum") { return TDO_AttunementKind.Quantum; }
  if Equals(itemID, t"Items.TDO_QuantumPlus") { return TDO_AttunementKind.Quantum; }

  if Equals(itemID, t"Items.TDO_QuantumAdvanced") { return TDO_AttunementKind.QuantumAdvanced; }
  if Equals(itemID, t"Items.TDO_QuantumAdvancedPlus") { return TDO_AttunementKind.QuantumAdvanced; }
  if Equals(itemID, t"Items.TDO_QuantumAdvancedPlusPlus") { return TDO_AttunementKind.QuantumAdvanced; }

  if Equals(itemID, t"Items.TDO_SogimsuRare") { return TDO_AttunementKind.Sogimsu; }
  if Equals(itemID, t"Items.TDO_SogimsuRarePlus") { return TDO_AttunementKind.Sogimsu; }
  if Equals(itemID, t"Items.TDO_SogimsuEpic") { return TDO_AttunementKind.Sogimsu; }
  if Equals(itemID, t"Items.TDO_SogimsuEpicPlus") { return TDO_AttunementKind.Sogimsu; }
  if Equals(itemID, t"Items.TDO_SogimsuLegendary") { return TDO_AttunementKind.Sogimsu; }
  if Equals(itemID, t"Items.TDO_SogimsuLegendaryPlus") { return TDO_AttunementKind.Sogimsu; }
  if Equals(itemID, t"Items.TDO_SogimsuLegendaryPlusPlus") { return TDO_AttunementKind.Sogimsu; }

  if Equals(itemID, t"Items.TDO_JuggernautRare") { return TDO_AttunementKind.Juggernaut; }
  if Equals(itemID, t"Items.TDO_JuggernautEpic") { return TDO_AttunementKind.Juggernaut; }
  if Equals(itemID, t"Items.TDO_JuggernautLegendary") { return TDO_AttunementKind.Juggernaut; }
  if Equals(itemID, t"Items.TDO_JuggernautLegendaryPlus") { return TDO_AttunementKind.Juggernaut; }
  if Equals(itemID, t"Items.TDO_JuggernautLegendaryPlusPlus") { return TDO_AttunementKind.Juggernaut; }

  if Equals(itemID, t"Items.TDO_PyrolithRare") { return TDO_AttunementKind.Pyrolith; }
  if Equals(itemID, t"Items.TDO_PyrolithEpic") { return TDO_AttunementKind.Pyrolith; }
  if Equals(itemID, t"Items.TDO_PyrolithLegendary") { return TDO_AttunementKind.Pyrolith; }
  if Equals(itemID, t"Items.TDO_PyrolithLegendaryPlus") { return TDO_AttunementKind.Pyrolith; }
  if Equals(itemID, t"Items.TDO_PyrolithLegendaryPlusPlus") { return TDO_AttunementKind.Pyrolith; }

  return TDO_AttunementKind.None;
}

public func TDO_Pyrolith_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.TDO_PyrolithRare") { return 1; }
  if Equals(itemTDB, t"Items.TDO_PyrolithEpic") { return 2; }
  if Equals(itemTDB, t"Items.TDO_PyrolithLegendary") { return 3; }
  if Equals(itemTDB, t"Items.TDO_PyrolithLegendaryPlus") { return 4; }
  if Equals(itemTDB, t"Items.TDO_PyrolithLegendaryPlusPlus") { return 5; }
  return 0;
}

public func TDO_Pyrolith_InjectActiveCardLiveValues(itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) {
    return;
  }
  let tier: Int32 = TDO_Pyrolith_TierForItemTDB(itemTDB);
  if tier <= 0 {
    return;
  }
  let fv: array<Float> = dataPackage.floatValues;
  if ArraySize(fv) != 7 {
    return;
  }
  fv[0] = TDO_Pyrolith_GetActiveDuration(tier);
  fv[1] = TDO_Pyrolith_GetBulletExplosionRadius(tier);
  fv[2] = TDO_Pyrolith_GetExplosionDamage(tier);
  fv[3] = Cast<Float>(TDO_Pyrolith_GetClusterCount(tier));
  fv[4] = TDO_Pyrolith_GetClusterDamageScalar(tier) * 100.0;
  fv[5] = (TDO_Pyrolith_GetThrowVelocityMultiplier(tier) - 1.0) * 100.0;
  fv[6] = TDO_Pyrolith_CooldownForTier(tier);
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Pyrolith_CooldownForTier(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.PyrolithCooldownMax(), TDOConfig.PyrolithCooldownMin(), tier, 5);
}

public func TDO_Juggernaut_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.TDO_JuggernautRare") { return 1; }
  if Equals(itemTDB, t"Items.TDO_JuggernautEpic") { return 2; }
  if Equals(itemTDB, t"Items.TDO_JuggernautLegendary") { return 3; }
  if Equals(itemTDB, t"Items.TDO_JuggernautLegendaryPlus") { return 4; }
  if Equals(itemTDB, t"Items.TDO_JuggernautLegendaryPlusPlus") { return 5; }
  return 0;
}

public func TDO_Juggernaut_LockDurForTier(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.JuggernautLockDurationMin(), TDOConfig.JuggernautLockDurationMax(), tier, 5);
}

public func TDO_Juggernaut_CooldownForTier(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.JuggernautCooldownMax(), TDOConfig.JuggernautCooldownMin(), tier, 5);
}

public func TDO_Juggernaut_MaxRadiusForTier(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.JuggernautRadiusMin(), TDOConfig.JuggernautRadiusMax(), tier, 5);
}

public func TDO_Juggernaut_InjectActiveCardLiveValues(itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) {
    return;
  }
  let tier: Int32 = TDO_Juggernaut_TierForItemTDB(itemTDB);
  if tier <= 0 {
    return;
  }
  let fv: array<Float> = dataPackage.floatValues;
  if ArraySize(fv) != 4 {
    return;
  }
  fv[0] = TDO_Juggernaut_LockDurForTier(tier);
  fv[1] = TDO_Juggernaut_MaxRadiusForTier(tier);
  fv[3] = TDO_Juggernaut_CooldownForTier(tier);
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Sogimsu_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.TDO_SogimsuRare") { return 1; }
  if Equals(itemTDB, t"Items.TDO_SogimsuRarePlus") { return 2; }
  if Equals(itemTDB, t"Items.TDO_SogimsuEpic") { return 3; }
  if Equals(itemTDB, t"Items.TDO_SogimsuEpicPlus") { return 4; }
  if Equals(itemTDB, t"Items.TDO_SogimsuLegendary") { return 5; }
  if Equals(itemTDB, t"Items.TDO_SogimsuLegendaryPlus") { return 6; }
  if Equals(itemTDB, t"Items.TDO_SogimsuLegendaryPlusPlus") { return 7; }
  return 0;
}

public func TDO_Sogimsu_WatchdogDurForTier(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.SogimsuDurationMin(), TDOConfig.SogimsuDurationMax(), tier, 7);
}

public func TDO_Sogimsu_CooldownForTier(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.SogimsuCooldownMax(), TDOConfig.SogimsuCooldownMin(), tier, 7);
}

public func TDO_Sogimsu_InjectActiveCardLiveValues(itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) {
    return;
  }
  let tier: Int32 = TDO_Sogimsu_TierForItemTDB(itemTDB);
  if tier <= 0 {
    return;
  }
  let fv: array<Float> = dataPackage.floatValues;
  if ArraySize(fv) != 6 {
    return;
  }
  fv[0] = TDO_Sogimsu_WatchdogDurForTier(tier);
  fv[1] = TDO_Sogimsu_CooldownForTier(tier);
  fv[2] = TDOConfig.LerpTier(TDOConfig.SogimsuDetectionDecreaseMin(), TDOConfig.SogimsuDetectionDecreaseMax(), tier, 7);
  fv[3] = TDOConfig.LerpTier(TDOConfig.SogimsuStealthHitDamageMin(), TDOConfig.SogimsuStealthHitDamageMax(), tier, 7);
  fv[4] = TDOConfig.LerpTier(TDOConfig.SogimsuInterventionsMin(), TDOConfig.SogimsuInterventionsMax(), tier, 7);
  fv[5] = TDOConfig.SogimsuWatchdogCamoBase();
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Fusillade_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.TDO_Fusillade") { return 1; }
  if Equals(itemTDB, t"Items.TDO_FusilladePlus") { return 2; }
  return 0;
}

public func TDO_Fusillade_InjectActiveCardLiveValues(itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) {
    return;
  }
  let tier: Int32 = TDO_Fusillade_TierForItemTDB(itemTDB);
  if tier <= 0 {
    return;
  }
  let fv: array<Float> = dataPackage.floatValues;
  if ArraySize(fv) != 7 {
    return;
  }
  fv[0] = (1.0 - TDOConfig.FusilladeTimeScale()) * 100.0;
  fv[1] = TDOConfig.FusilladeFireRateMult();
  fv[2] = TDOConfig.LerpTier(TDOConfig.FusilladeRampStartMin(), TDOConfig.FusilladeRampStartMax(), tier, 2) * 100.0;
  fv[3] = TDOConfig.FusilladeRampStep() * 100.0;
  fv[4] = TDOConfig.FusilladeRecoilAmount() * 100.0;
  fv[5] = TDOConfig.LerpTier(TDOConfig.FusilladeDurationMin(), TDOConfig.FusilladeDurationMax(), tier, 2);
  fv[6] = TDOConfig.LerpTier(TDOConfig.FusilladeCooldownMax(), TDOConfig.FusilladeCooldownMin(), tier, 2);
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Kurosawa_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.TDO_Kurosawa") { return 1; }
  if Equals(itemTDB, t"Items.TDO_KurosawaPlus") { return 2; }
  return 0;
}

public func TDO_Kurosawa_InjectActiveCardLiveValues(itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) {
    return;
  }
  let tier: Int32 = TDO_Kurosawa_TierForItemTDB(itemTDB);
  if tier <= 0 {
    return;
  }
  let fv: array<Float> = dataPackage.floatValues;
  if ArraySize(fv) != 5 {
    return;
  }
  fv[0] = (1.0 - TDOConfig.KurosawaIndividualSlowMult()) * 100.0;
  fv[1] = TDOConfig.LerpTier(TDOConfig.KurosawaDamageReductionMin(), TDOConfig.KurosawaDamageReductionMax(), tier, 2);
  fv[2] = TDOConfig.LerpTier(TDOConfig.KurosawaPOPHealPctBase(), TDOConfig.KurosawaPOPHealPctPlus(), tier, 2);
  fv[3] = TDOConfig.KurosawaDuration();
  fv[4] = TDOConfig.KurosawaRecharge();
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Quantum_DurationForTier(tier: Int32) -> Float {
  return TDOConfig.LerpTier(TDOConfig.QuantumDurationMin(), TDOConfig.QuantumDurationMax(), tier, 5);
}

public func TDO_Quantum_InjectActiveCardLiveValues(game: GameInstance, itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) {
    return;
  }
  let tier: Int32 = TDO_Quantum_TierForTDB(itemTDB);
  if tier <= 0 {
    return;
  }
  let fv: array<Float> = dataPackage.floatValues;
  if ArraySize(fv) == 1 {
    fv[0] = TDOConfig.LerpTier(TDOConfig.QuantumCooldownMax(), TDOConfig.QuantumCooldownMin(), tier, 5);
    dataPackage.floatValues = fv;
    dataPackage.InvalidateTextParams();
    return;
  }
  while ArraySize(fv) < 6 { ArrayPush(fv, 0.0); }
  let maxTargets: Int32 = Cast<Int32>(TDOConfig.LerpTier(TDOConfig.QuantumMalwareTargetsMin(), TDOConfig.QuantumMalwareTargetsMax(), tier, 5) + 0.5);
  let radius: Float = TDOConfig.QuantumMalwareRadiusBase();
  let tpRange: Float = TDOConfig.QuantumTeleportRangeMin();
  let malwareDur: Float = TDOConfig.QuantumMalwareFreezeDurMin();
  let teleWindow: Float = TDO_Quantum_DurationForTier(tier);
  let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if IsDefined(player) {
    radius = TDO_Quantum_GetMalwareRadius(player);
    tpRange = TDO_Quantum_GetTeleportRange(player);
    malwareDur = TDO_Quantum_GetMalwareDuration(player);
  }
  let cooldown: Float = TDOConfig.LerpTier(TDOConfig.QuantumCooldownMax(), TDOConfig.QuantumCooldownMin(), tier, 5);
  fv[0] = tpRange;
  fv[1] = Cast<Float>(maxTargets);
  fv[2] = radius;
  fv[3] = malwareDur;
  fv[4] = teleWindow;
  fv[5] = cooldown;
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Attunement_InjectLiveTotal(game: GameInstance, itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) {
    return;
  }
  let kind: TDO_AttunementKind = TDO_Attunement_KindFor(itemTDB);
  if Equals(kind, TDO_AttunementKind.None) {
    return;
  }
  let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if !IsDefined(player) {
    return;
  }
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(game);
  let objID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
  let reflexes: Float = stats.GetStatValue(objID, gamedataStatType.Reflexes);
  let cool: Float = stats.GetStatValue(objID, gamedataStatType.Cool);
  let body: Float = stats.GetStatValue(objID, gamedataStatType.Strength);
  let ta: Float = stats.GetStatValue(objID, gamedataStatType.TechnicalAbility);

  let fv: array<Float> = dataPackage.floatValues;

  switch kind {
    case TDO_AttunementKind.Shrike:
      if TDOConfig.ShrikeEnabled() {
        while ArraySize(fv) < 2 { ArrayPush(fv, 0.0); }
        fv[1] = reflexes * 0.1;
      }
      break;
    case TDO_AttunementKind.Tanto:
      if TDOConfig.TantoEnabled() {
        while ArraySize(fv) < 4 { ArrayPush(fv, 0.0); }
        fv[1] = reflexes * 0.25;
        fv[3] = reflexes * 1.0;
      }
      break;
    case TDO_AttunementKind.WarpDancer:
      if TDOConfig.WarpDancerEnabled() {
        while ArraySize(fv) < 4 { ArrayPush(fv, 0.0); }
        fv[1] = cool * 0.05;
        fv[3] = cool * 1.65;
      }
      break;
    case TDO_AttunementKind.Fusillade:
      while ArraySize(fv) < 2 { ArrayPush(fv, 0.0); }
      let refillRaw: Float = reflexes * TDOConfig.FusilladeAmmoRefillPerReflexes();
      if refillRaw > TDOConfig.FusilladeAmmoRefillMaxChancePct() {
        refillRaw = TDOConfig.FusilladeAmmoRefillMaxChancePct();
      }
      fv[1] = refillRaw;
      break;
    case TDO_AttunementKind.KurosawaBody:
      while ArraySize(fv) < 2 { ArrayPush(fv, 0.0); }
      let refundRaw: Float = body * 0.05;
      if refundRaw > 1.0 {
        refundRaw = 1.0;
      }
      fv[1] = refundRaw;
      break;
    case TDO_AttunementKind.Falcon:
      if TDOConfig.FalconEnabled() {
        while ArraySize(fv) < 4 { ArrayPush(fv, 0.0); }
        fv[1] = ta * 0.1;
        let weaponRaw: Float = ta * 0.5;
        if weaponRaw > 10.0 {
          weaponRaw = 10.0;
        }
        fv[3] = weaponRaw;
      }
      break;
    case TDO_AttunementKind.Quantum:
    case TDO_AttunementKind.QuantumAdvanced:
      while ArraySize(fv) < 4 { ArrayPush(fv, 0.0); }
      fv[0] = TDOConfig.QuantumMalwareCoolPerPoint();
      fv[1] = cool * TDOConfig.QuantumMalwareCoolPerPoint();
      fv[2] = TDOConfig.QuantumTeleportRangePerCool();
      fv[3] = cool * TDOConfig.QuantumTeleportRangePerCool();
      break;
    case TDO_AttunementKind.Sogimsu:
      while ArraySize(fv) < 2 { ArrayPush(fv, 0.0); }
      fv[1] = cool * 0.25;
      break;
    case TDO_AttunementKind.Juggernaut:
      while ArraySize(fv) < 2 { ArrayPush(fv, 0.0); }
      fv[1] = body * 2.0;
      break;
    case TDO_AttunementKind.Pyrolith:
      while ArraySize(fv) < 2 { ArrayPush(fv, 0.0); }
      fv[1] = ta * fv[0];
      break;
  }

  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Shrike_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK1") { return 1; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK1Plus") { return 2; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK2") { return 3; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK2Plus") { return 4; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK3") { return 5; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK3Plus") { return 6; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK4") { return 7; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK4Plus") { return 8; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC1MK4PlusPlus") { return 9; }
  return 0;
}

public func TDO_Shrike_MarksForTier(tier: Int32) -> Int32 {
  if tier <= 2 { return 2; }
  if tier <= 4 { return 3; }
  if tier <= 6 { return 4; }
  return 5;
}

public func TDO_Shrike_InjectActiveCardLiveValues(game: GameInstance, itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) { return; }
  if !TDOConfig.ShrikeEnabled() { return; }
  let tier: Int32 = TDO_Shrike_TierForItemTDB(itemTDB);
  if tier <= 0 { return; }
  let fv: array<Float> = dataPackage.floatValues;
  while ArraySize(fv) < 7 { ArrayPush(fv, 0.0); }
  let t: Float = Cast<Float>(tier - 1) / 8.0;
  fv[3] = 30.0 + (15.0 - 30.0) * t;
  fv[5] = Cast<Float>(TDO_Shrike_MarksForTier(tier));
  fv[6] = 5.0 + (10.0 - 5.0) * t;
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Tanto_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK1") { return 1; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK1Plus") { return 2; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK2") { return 3; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK2Plus") { return 4; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK3") { return 5; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK3Plus") { return 6; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK4") { return 7; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK4Plus") { return 8; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC2MK4PlusPlus") { return 9; }
  return 0;
}

public func TDO_Tanto_ChargesForTier(tier: Int32) -> Int32 {
  if tier <= 2 { return 1; }
  if tier <= 4 { return 2; }
  if tier <= 6 { return 3; }
  return 4;
}

public func TDO_Tanto_InjectActiveCardLiveValues(game: GameInstance, itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) { return; }
  if !TDOConfig.TantoEnabled() { return; }
  let tier: Int32 = TDO_Tanto_TierForItemTDB(itemTDB);
  if tier <= 0 { return; }
  let fv: array<Float> = dataPackage.floatValues;
  while ArraySize(fv) < 7 { ArrayPush(fv, 0.0); }
  let t: Float = Cast<Float>(tier - 1) / 8.0;
  fv[0] = 60.0;
  fv[1] = 5.0 + (15.0 - 5.0) * t;
  fv[2] = 10.0 + (50.0 - 10.0) * t;
  fv[3] = 10.0 + (15.0 - 10.0) * t;
  fv[5] = Cast<Float>(TDO_Tanto_ChargesForTier(tier));
  fv[6] = 50.0 + (25.0 - 50.0) * t;
  let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if IsDefined(player) {
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(game);
    let reflexes: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Reflexes);
    let tpRange: Float = TDOConfig.TantoTeleportBaseRange() + reflexes * TDOConfig.TantoTeleportRangePerReflexes();
    let tpMax: Float = TDOConfig.TantoTeleportMaxRange();
    if tpRange > tpMax { tpRange = tpMax; }
    fv[4] = tpRange;
  } else {
    fv[4] = TDOConfig.TantoTeleportBaseRange();
  }
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_WarpDancer_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.AdvancedSandevistanC3MK3") { return 1; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC3MK3Plus") { return 2; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC3MK4") { return 3; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC3MK4Plus") { return 4; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC3MK5") { return 5; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC3MK5Plus") { return 6; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC3MK5PlusPlus") { return 7; }
  return 0;
}

public func TDO_WarpDancer_InjectActiveCardLiveValues(itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) { return; }
  if !TDOConfig.WarpDancerEnabled() { return; }
  let tier: Int32 = TDO_WarpDancer_TierForItemTDB(itemTDB);
  if tier <= 0 { return; }
  let fv: array<Float> = dataPackage.floatValues;
  while ArraySize(fv) < 9 { ArrayPush(fv, 0.0); }
  let t: Float = Cast<Float>(tier - 1) / 6.0;
  fv[4] = 5.0 + (9.0 - 5.0) * t;
  fv[5] = 5.0 + (20.0 - 5.0) * t;
  fv[6] = TDOConfig.WarpDancerStaggerDurationMaxSec() - (TDOConfig.WarpDancerStaggerDurationMaxSec() - TDOConfig.WarpDancerStaggerDurationMinSec()) * t;
  fv[7] = 80.0 + (45.0 - 80.0) * t;
  fv[8] = TDOConfig.WarpDancerRewindDurationSec();
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

public func TDO_Falcon_TierForItemTDB(itemTDB: TweakDBID) -> Int32 {
  if Equals(itemTDB, t"Items.AdvancedSandevistanC4MK4") { return 1; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC4MK4Plus") { return 2; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC4MK5") { return 3; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC4MK5Plus") { return 4; }
  if Equals(itemTDB, t"Items.AdvancedSandevistanC4MK5PlusPlus") { return 5; }
  return 0;
}

public func TDO_Falcon_InjectActiveCardLiveValues(itemTDB: TweakDBID, dataPackage: ref<UILocalizationDataPackage>) -> Void {
  if !IsDefined(dataPackage) { return; }
  if !TDOConfig.FalconEnabled() { return; }
  let tier: Int32 = TDO_Falcon_TierForItemTDB(itemTDB);
  if tier <= 0 { return; }
  let fv: array<Float> = dataPackage.floatValues;
  while ArraySize(fv) < 8 { ArrayPush(fv, 0.0); }
  let t: Float = Cast<Float>(tier - 1) / 4.0;
  fv[0] = 40.0;
  fv[6] = 12.0 + (16.0 - 12.0) * t;
  fv[7] = 45.0 + (30.0 - 45.0) * t;
  dataPackage.floatValues = fv;
  dataPackage.InvalidateTextParams();
}

@wrapMethod(UIInventoryItemModsManager)
private final func FetchModsDataPackages(inventoryItem: wref<UIInventoryItem>) -> Void {
  wrappedMethod(inventoryItem);
  if !IsDefined(inventoryItem) {
    return;
  }
  let itemTDB: TweakDBID = inventoryItem.GetTweakDBID();
  let owner: wref<GameObject> = inventoryItem.GetOwner();
  if !IsDefined(owner) {
    return;
  }
  let game: GameInstance = owner.GetGame();
  let i: Int32 = 0;
  let limit: Int32 = ArraySize(this.m_mods);
  while i < limit {
    let modData: ref<UIInventoryItemModDataPackage> = this.m_mods[i] as UIInventoryItemModDataPackage;
    if IsDefined(modData) {
      if IsDefined(modData.AttunementData) {
        TDO_Attunement_InjectLiveTotal(game, itemTDB, modData.DataPackage);
      } else {
        TDO_Pyrolith_InjectActiveCardLiveValues(itemTDB, modData.DataPackage);
        TDO_Juggernaut_InjectActiveCardLiveValues(itemTDB, modData.DataPackage);
        TDO_Sogimsu_InjectActiveCardLiveValues(itemTDB, modData.DataPackage);
        TDO_Quantum_InjectActiveCardLiveValues(game, itemTDB, modData.DataPackage);
        TDO_Fusillade_InjectActiveCardLiveValues(itemTDB, modData.DataPackage);
        TDO_Kurosawa_InjectActiveCardLiveValues(itemTDB, modData.DataPackage);
        TDO_Shrike_InjectActiveCardLiveValues(game, itemTDB, modData.DataPackage);
        TDO_Tanto_InjectActiveCardLiveValues(game, itemTDB, modData.DataPackage);
        TDO_WarpDancer_InjectActiveCardLiveValues(itemTDB, modData.DataPackage);
        TDO_Falcon_InjectActiveCardLiveValues(itemTDB, modData.DataPackage);
      }
    }
    i += 1;
  }
}

@wrapMethod(MinimalItemTooltipData)
public final static func GetModsDataPackages(itemData: wref<gameItemData>, itemRecord: wref<Item_Record>, displayContext: InventoryTooltipDisplayContext, opt parentItemData: wref<gameItemData>, opt slotID: TweakDBID, mods: script_ref<array<ref<MinimalItemTooltipModData>>>) -> Void {
  wrappedMethod(itemData, itemRecord, displayContext, parentItemData, slotID, mods);
  if !IsDefined(itemRecord) {
    return;
  }
  let itemTDB: TweakDBID = itemRecord.GetRecordID();
  let game: GameInstance = GetGameInstance();
  let i: Int32 = 0;
  let limit: Int32 = ArraySize(Deref(mods));
  while i < limit {
    let modData: ref<MinimalItemTooltipModRecordData> = Deref(mods)[i] as MinimalItemTooltipModRecordData;
    if IsDefined(modData) {
      if IsDefined(modData.attunementData) {
        TDO_Attunement_InjectLiveTotal(game, itemTDB, modData.dataPackage);
      } else {
        TDO_Pyrolith_InjectActiveCardLiveValues(itemTDB, modData.dataPackage);
        TDO_Juggernaut_InjectActiveCardLiveValues(itemTDB, modData.dataPackage);
        TDO_Sogimsu_InjectActiveCardLiveValues(itemTDB, modData.dataPackage);
        TDO_Quantum_InjectActiveCardLiveValues(game, itemTDB, modData.dataPackage);
        TDO_Fusillade_InjectActiveCardLiveValues(itemTDB, modData.dataPackage);
        TDO_Kurosawa_InjectActiveCardLiveValues(itemTDB, modData.dataPackage);
        TDO_Shrike_InjectActiveCardLiveValues(game, itemTDB, modData.dataPackage);
        TDO_Tanto_InjectActiveCardLiveValues(game, itemTDB, modData.dataPackage);
        TDO_WarpDancer_InjectActiveCardLiveValues(itemTDB, modData.dataPackage);
        TDO_Falcon_InjectActiveCardLiveValues(itemTDB, modData.dataPackage);
      }
    }
    i += 1;
  }
}

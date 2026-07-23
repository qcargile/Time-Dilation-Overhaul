module TDO.Sandy

@if(ModuleExists("CyberwareEx"))
import CyberwareEx.*

@wrapMethod(PlayerPuppet)
private final func ActivateIconicCyberware() -> Void {
  wrappedMethod();

  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  if stats.GetStatBoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.HasSandevistan) {
    return;
  }

  let psmBlackboard: ref<IBlackboard> = this.GetPlayerStateMachineBlackboard();
  if Equals(IntEnum<gamePSMVision>(psmBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vision)), gamePSMVision.Focus) {
    return;
  }
  if this.IsPhoneCallActive() || !TimeDilationHelper.CanUseTimeDilation(this) {
    return;
  }

  this.TDO_ActivateNonSandyCustomOS();
}

@addMethod(PlayerPuppet)
private func TDO_UseNonSandyCustomOS(itemID: ItemID) -> Void {
  let successful: Bool = ItemActionsHelper.UseItem(this, itemID);
  let dpadAction: ref<DPADActionPerformed> = new DPADActionPerformed();
  dpadAction.action = EHotkey.LBRB;
  dpadAction.state = EUIActionState.COMPLETED;
  dpadAction.successful = successful;
  GameInstance.GetUISystem(this.GetGame()).QueueEvent(dpadAction);

  if successful {
    this.IconicCyberwareActivated();
  } else {
    let audioEvent: ref<SoundPlayEvent> = new SoundPlayEvent();
    audioEvent.soundName = n"ui_grenade_empty";
    this.QueueEvent(audioEvent);
  }
}

@if(!ModuleExists("CyberwareEx"))
@addMethod(PlayerPuppet)
private func TDO_ActivateNonSandyCustomOS() -> Void {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(this);
  if IsDefined(es) {
    let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(this);
    if IsDefined(pd) {
      let slotIdx: Int32 = 0;
      let slotCount: Int32 = pd.GetNumberOfSlots(gamedataEquipmentArea.SystemReplacementCW, true);
      while slotIdx < slotCount {
        let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
        if ItemID.IsValid(itemID) {
          let kind: TDO_AttunementKind = TDO_Attunement_KindFor(ItemID.GetTDBID(itemID));
          if Equals(kind, TDO_AttunementKind.Sogimsu) || Equals(kind, TDO_AttunementKind.Juggernaut) || Equals(kind, TDO_AttunementKind.Pyrolith) {
            this.TDO_UseNonSandyCustomOS(itemID);
            return;
          }
        }
        slotIdx += 1;
      }
    }
  }
}

@if(ModuleExists("CyberwareEx"))
@addMethod(PlayerPuppet)
private func TDO_ActivateNonSandyCustomOS() -> Void {
  let equipmentData: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this);
  let characterData: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  let hasBerserk: Bool = equipmentData.HasTaggedItem(gamedataEquipmentArea.SystemReplacementCW, n"Berserk");
  let hasSandevistan: Bool = equipmentData.HasTaggedItem(gamedataEquipmentArea.SystemReplacementCW, n"Sandevistan");
  let hasOverclock: Bool = equipmentData.HasTaggedItem(gamedataEquipmentArea.SystemReplacementCW, n"Cyberdeck")
    && characterData.IsNewPerkBought(gamedataNewPerkType.Intelligence_Central_Milestone_3) == 3;
  let numberOfAbilities: Int32 = (hasBerserk ? 1 : 0) + (hasSandevistan ? 1 : 0) + (hasOverclock ? 1 : 0);
  let isOnlyOneAbility: Bool = numberOfAbilities == 1;
  let psmBlackboard: ref<IBlackboard> = this.GetPlayerStateMachineBlackboard();
  let meleeWeaponState: gamePSMMeleeWeapon = IntEnum<gamePSMMeleeWeapon>(psmBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon));
  let isFocusMode: Bool = Equals(IntEnum<gamePSMVision>(psmBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vision)), gamePSMVision.Focus);
  let isBlocking: Bool = Equals(meleeWeaponState, gamePSMMeleeWeapon.Block)
    || Equals(meleeWeaponState, gamePSMMeleeWeapon.BlockAttack)
    || Equals(meleeWeaponState, gamePSMMeleeWeapon.Deflect)
    || Equals(meleeWeaponState, gamePSMMeleeWeapon.DeflectAttack);
  if hasSandevistan && !isFocusMode && (isOnlyOneAbility || !isBlocking || !hasBerserk || IsCombinedAbilityMode()) {
    let itemID: ItemID = equipmentData.GetTaggedItem(gamedataEquipmentArea.SystemReplacementCW, n"Sandevistan");
    let kind: TDO_AttunementKind = TDO_Attunement_KindFor(ItemID.GetTDBID(itemID));
    if Equals(kind, TDO_AttunementKind.Sogimsu) || Equals(kind, TDO_AttunementKind.Juggernaut) || Equals(kind, TDO_AttunementKind.Pyrolith) {
      this.TDO_UseNonSandyCustomOS(itemID);
    }
  }
}

@wrapMethod(UseSandevistanAction)
public func StartAction(gameInstance: GameInstance) -> Void {
  let player: ref<PlayerPuppet> = this.GetExecutor() as PlayerPuppet;
  if !IsDefined(player) {
    wrappedMethod(gameInstance);
    return;
  }

  let itemData: wref<gameItemData> = this.GetItemData();
  if !IsDefined(itemData) {
    wrappedMethod(gameInstance);
    return;
  }

  let itemTDB: TweakDBID = ItemID.GetTDBID(itemData.GetID());
  let sogimsuTier: Int32 = TDO_Sogimsu_TierForItemTDB(itemTDB);
  if sogimsuTier > 0 {
    player.TDO_Sogimsu_OnActivate(sogimsuTier);
    return;
  }

  let juggernautTier: Int32 = TDO_Juggernaut_TierForItemTDB(itemTDB);
  if juggernautTier > 0 {
    player.TDO_Juggernaut_OnActivate(juggernautTier);
    return;
  }

  let pyrolithTier: Int32 = TDO_Pyrolith_TierForItemTDB(itemTDB);
  if pyrolithTier > 0 {
    player.TDO_Pyrolith_OnActivate(pyrolithTier);
    return;
  }

  wrappedMethod(gameInstance);
}

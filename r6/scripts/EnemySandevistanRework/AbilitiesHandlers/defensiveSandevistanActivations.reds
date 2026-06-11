module Phoenicia.EnemySandevistanRework.Effectors

import Phoenicia.EnemySandevistanRework.Utils.*

public class SurvivalEffector extends ModifyAttackEffector {
  protected func ActionOn(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  protected func RepeatedAction(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  private final func ProcessAction(owner: ref<GameObject>) -> Void {
    let healthPercentage = GameInstance.GetStatPoolsSystem(owner.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(owner.GetEntityID()), gamedataStatPoolType.Health);
    
    if (healthPercentage < 30.0 && 
        CheckCommonRestrictions((owner as NPCPuppet), true, false) && 
        !StatusEffectSystem.ObjectHasStatusEffect(owner, t"BaseStatusEffect.ESR_Defensive_CD") && 
        !StatusEffectSystem.ObjectHasStatusEffectWithTag((owner as NPCPuppet), n"ESR_Sandi_Buff")) {

        let remainingSandiDuration = AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(owner as ScriptedPuppet);

        if (remainingSandiDuration >= 2.0) {
            let random = RandRange(0, 100);
            if (random > 30) {
              let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(owner as ScriptedPuppet);
              (owner as NPCPuppet).SetIndividualTimeDilation(n"sandevistanAbility", speed);
              AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(owner as ScriptedPuppet, Min(FloorF(remainingSandiDuration), 4), false);
              AISubActionApplyTimeDilation_Record_Implementation.ApplyDefensiveUseCooldown(owner as ScriptedPuppet);
            }
        }
    }
  }
}


public class MeleeDefenseEffector extends ModifyAttackEffector {
  protected func ActionOn(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  protected func RepeatedAction(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  private final func ProcessAction(owner: ref<GameObject>) -> Void {    
    if (CheckCommonRestrictions((owner as NPCPuppet), true, false) && 
        !StatusEffectSystem.ObjectHasStatusEffect(owner, t"BaseStatusEffect.ESR_Defensive_CD") && 
        !StatusEffectSystem.ObjectHasStatusEffectWithTag((owner as NPCPuppet), n"ESR_Sandi_Buff")) {
        if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(owner as ScriptedPuppet) >= 2.0) {
            if (RandRange(0, 100) > 50) {
              let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(owner as ScriptedPuppet);
              (owner as NPCPuppet).SetIndividualTimeDilation(n"sandevistanAbility", speed);

              AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(owner as ScriptedPuppet, 2, false);
              AISubActionApplyTimeDilation_Record_Implementation.ApplyDefensiveUseCooldown(owner as ScriptedPuppet);
            }
        }

    }
  }
}


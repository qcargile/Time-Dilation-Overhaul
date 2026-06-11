module Phoenicia.EnemySandevistanRework.Smasher

import Phoenicia.EnemySandevistanRework.Utils.*

public func HasSmasherSandevistanBlocker(smasher: ref<NPCPuppet>) -> Bool {

  return  StatusEffectSystem.ObjectHasStatusEffect(smasher, t"BaseStatusEffect.BossNoInterrupt") || 
          StatusEffectSystem.ObjectHasStatusEffect(smasher, t"AdamSmasher.InAir") || 
          StatusEffectSystem.ObjectHasStatusEffect(smasher, t"Oda.OdaLeapBlocker") || 
          StatusEffectSystem.ObjectHasStatusEffect(smasher, t"BaseStatusEffect.Invulnerable") || 
          StatusEffectSystem.ObjectHasStatusEffect(smasher, t"AdamSmasher.Invulnerable") || 
          StatusEffectSystem.ObjectHasStatusEffect(smasher, t"AdamSmasher.Smashed") || 
          StatusEffectSystem.ObjectHasStatusEffect(smasher, t"BaseStatusEffect.BossNoTakeDown") || 
          StatusEffectSystem.ObjectHasStatusEffect(smasher, t"AdamSmasher.EMP_Shield_Rocket_Barrage");
}

public class SurvivalSmasherEffector extends ModifyAttackEffector {
  protected func ActionOn(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  protected func RepeatedAction(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  private final func ProcessAction(owner: ref<GameObject>) -> Void {    
    if (CheckCommonRestrictions((owner as NPCPuppet), true, false) && 
        !HasSmasherSandevistanBlocker(owner as NPCPuppet) && 
        !StatusEffectSystem.ObjectHasStatusEffect(owner, t"BaseStatusEffect.ESR_Defensive_CD") && 
        !StatusEffectSystem.ObjectHasStatusEffectWithTag((owner as NPCPuppet), n"ESR_Sandi_Buff")) {

        let remainingSandiDuration = AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(owner as ScriptedPuppet);

        if (remainingSandiDuration >= 2.0) {
            let random = RandRange(0, 100);
            if (random > 80) {
                let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(owner as ScriptedPuppet);
                (owner as NPCPuppet).SetIndividualTimeDilation(n"sandevistanAbility", speed);

                let stacks = StatusEffectSystem.ObjectHasStatusEffect((owner as NPCPuppet), t"AdamSmasher.Phase1") ? 5 : 2;

                AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(owner as ScriptedPuppet, Min(FloorF(remainingSandiDuration), stacks), false);
                AISubActionApplyTimeDilation_Record_Implementation.ApplyDefensiveUseCooldown(owner as ScriptedPuppet);
            }
        }
    }
  }
}


public class MeleeDefenseSmasherEffector extends ModifyAttackEffector {
  protected func ActionOn(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  protected func RepeatedAction(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  private final func ProcessAction(owner: ref<GameObject>) -> Void {    
    if (CheckCommonRestrictions((owner as NPCPuppet), true, false) && 
        !HasSmasherSandevistanBlocker(owner as NPCPuppet) && 
        !StatusEffectSystem.ObjectHasStatusEffect(owner, t"BaseStatusEffect.ESR_Defensive_CD") && 
        !StatusEffectSystem.ObjectHasStatusEffectWithTag((owner as NPCPuppet), n"ESR_Sandi_Buff")) {
            
        if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(owner as ScriptedPuppet) >= 2.0) {
            if (RandRange(0, 100) > 50) {
                
                let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(owner as ScriptedPuppet);
                (owner as NPCPuppet).SetIndividualTimeDilation(n"sandevistanAbility", speed);
              
                let stacks = StatusEffectSystem.ObjectHasStatusEffect((owner as NPCPuppet), t"AdamSmasher.Phase1") ? 4 : 1;

                AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(owner as ScriptedPuppet, stacks, false);
                AISubActionApplyTimeDilation_Record_Implementation.ApplyDefensiveUseCooldown(owner as ScriptedPuppet);
            }
        }

    }
  }
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {

    if (Equals(this.GetRecordID(), t"Character.q113_boss_smasher")) {
        if (Equals(evt.staticData.GetID(), t"AdamSmasher.Emergency") || 
            Equals(evt.staticData.GetID(), t"AdamSmasher.Invulnerable") || 
            Equals(evt.staticData.GetID(), t"BaseStatusEffect.Invulnerable") || 
            Equals(evt.staticData.GetID(), t"AdamSmasher.Destroyed_Plate") ||
            Equals(evt.staticData.GetID(), t"AdamSmasher.Phase2") ||
            Equals(evt.staticData.GetID(), t"AdamSmasher.Smashed") ||
            Equals(evt.staticData.GetID(), t"AdamSmasher.Phase3")
            ) {
                StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.ESR_Sandi_Buff", Cast<Uint32>(20));
                AISubActionApplyTimeDilation_Record_Implementation.ForceDeactivateSandevistan(this, false); 
        }
       
    }

    return wrappedMethod(evt);
}
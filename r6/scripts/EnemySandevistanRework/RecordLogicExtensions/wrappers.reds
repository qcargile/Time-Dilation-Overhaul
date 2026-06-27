module Phoenicia.EnemySandevistanRework.Wrappers

import Phoenicia.EnemySandevistanRework.Configurations.*



@wrapMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func Activate(context: ScriptExecutionContext, record: wref<AISubActionApplyTimeDilation_Record>) -> Void {
    let suppressOwner = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
    if IsDefined(suppressOwner) && StatusEffectSystem.ObjectHasStatusEffectWithTag(suppressOwner, n"TDO_TDSuppress") {
        return;
    }

    if (StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_RhinoSandiDebuff")) {
      return;
    }

    if Equals(record.Reason(), n"sandevistanVersusSandevistan") {
        let blackboard: ref<IBlackboard>;
        let player: ref<PlayerPuppet>;
        let playerTimeDilation: Float;
        if !AISubActionApplyTimeDilation_Record_Implementation.IsConditionFulfilled(context, record) {
            return;
        };
        if NotEquals(record.Reason(), n"sandevistanVersusSandevistan") {
            return;
        };
        blackboard = (ScriptExecutionContext.GetOwner(context) as ScriptedPuppet).GetAIControllerComponent().GetActionBlackboard();
        if !IsDefined(blackboard) {
            return;
        };

        if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(context) < 3.0 && !StatusEffectSystem.ObjectHasStatusEffectWithTag(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, n"ESR_Sandi_Buff")) {
          return;
        }

        if (!StatusEffectSystem.ObjectHasStatusEffectWithTag(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, n"ESR_Sandi_Buff")) {
          AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(context, 1, true);
        }
        
        player = GameInstance.GetPlayerSystem(ScriptExecutionContext.GetOwner(context).GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
        if IsDefined(player) {
            let enemyTimeDilation = AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanVsSandevistanSpeed(context);
            blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerGlobalTimeDilation, enemyTimeDilation);
            
        };
    } else {
        wrappedMethod(context, record);
    };



    
}



@wrapMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func Deactivate(context: ScriptExecutionContext, record: wref<AISubActionApplyTimeDilation_Record>, const duration: Float, interrupted: Bool) -> Void {
    let sandiBuffActive = StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_Sandi_Buff");
    let kerenzikovBuffActive = StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_SVK_Buff");
    let stimBuffActive = StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_Stim_Buff");

    if (StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_RhinoSandiDebuff")) {
      return;
    }

    if (sandiBuffActive || kerenzikovBuffActive || stimBuffActive) {
      if (sandiBuffActive) {
          let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(context);
          (ScriptExecutionContext.GetOwner(context) as ScriptedPuppet).SetIndividualTimeDilation(n"sandevistanAbility", speed);
      } else if (kerenzikovBuffActive) {
        let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovSpeed(context);
        (ScriptExecutionContext.GetOwner(context) as ScriptedPuppet).SetIndividualTimeDilation(n"kerenzikovAbility", speed);
      } else {
        let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseStimPackSpeed(context);
        (ScriptExecutionContext.GetOwner(context) as ScriptedPuppet).SetIndividualTimeDilation(n"sandevistanAbility", speed);
      }
      return;
    } else {
      wrappedMethod(context, record, duration, interrupted);
    }
}



@wrapMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func SetTimeDilation(context: ScriptExecutionContext, record: wref<AISubActionApplyTimeDilation_Record>) -> Bool {
    let blackboard: ref<IBlackboard>;
    let currentDilation: Float;
    let dilation: Float;
    let duration: Float;
    let globalDilation: Float;
    let globalSandevistanActive: Bool;
    let isGlobalSandevistan: Bool;

    let sandiBuffActive = StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_Sandi_Buff");
    let kerenzikovBuffActive = StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_SVK_Buff");


    if (StatusEffectSystem.ObjectHasStatusEffect(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, t"BaseStatusEffect.ESR_RhinoSandiDebuff")) {
      return false;
    }

    if (sandiBuffActive || kerenzikovBuffActive) {
      return false;
    }
    if record.Duration() == 0.00 {
      return false;
    };
    blackboard = (ScriptExecutionContext.GetOwner(context) as ScriptedPuppet).GetAIControllerComponent().GetActionBlackboard();
    if !IsDefined(blackboard) {
      return false;
    };
    currentDilation = blackboard.GetFloat(GetAllBlackboardDefs().AIAction.ownerTimeDilation);
    globalDilation = blackboard.GetFloat(GetAllBlackboardDefs().AIAction.ownerGlobalTimeDilation);
    isGlobalSandevistan = Equals(record.Reason(), n"sandevistanVersusSandevistan");
    if isGlobalSandevistan {
      dilation = globalDilation;
        if (!StatusEffectSystem.ObjectHasStatusEffectWithTag(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, n"ESR_Sandi_Buff")) {
              if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(context) < 1.0 && AISubActionApplyTimeDilation_Record_Implementation.GetAvailableKerenzikovDuration(context) < 1.0) {
                AISubActionApplyTimeDilation_Record_Implementation.ForceDeactivateSandevistan(context, true);
                return false;
              } else {
                if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableKerenzikovDuration(context) > 1.0) {
                    AISubActionApplyTimeDilation_Record_Implementation.ApplyKerenzikovCooldownAndDurationStacks(context, 1);
                } else {
                    AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(context, 1, true);
                }
              }
        }

        if (StatusEffectSystem.ObjectHasStatusEffectWithTag(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, n"ESR_Kerenzikov_Buff")) {
          dilation = AISubActionApplyTimeDilation_Record_Implementation.GetKerenzikovVsSandevistanSpeed(context);
        } else if (StatusEffectSystem.ObjectHasStatusEffectWithTag(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, n"ESR_Sandi_Buff")) {
          dilation = AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanVsSandevistanSpeed(context);
        }

    } else {
      return wrappedMethod(context, record);
    };
    if dilation < 0.00 || dilation == currentDilation {
      return false;
    };
    globalSandevistanActive = isGlobalSandevistan || ScriptExecutionContext.GetOwner(context).HasIndividualTimeDilation(n"sandevistanVersusSandevistan");
    if globalSandevistanActive && dilation < currentDilation {
      return false;
    };
    blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerTimeDilation, dilation);
    if ScriptExecutionContext.GetOwner(context).HasIndividualTimeDilation() {
      ScriptExecutionContext.GetOwner(context).UnsetIndividualTimeDilation();
    };
    duration = record.Duration() < 0.00 ? 600.00 : record.Duration() * dilation;
    
    ScriptExecutionContext.GetOwner(context).SetIndividualTimeDilation(record.Reason(), dilation, duration, record.EaseIn(), record.EaseOut(), false, record.UseRealTime());
    return true;
  }

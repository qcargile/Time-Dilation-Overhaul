module Phoenicia.EnemySandevistanRework.Additions

import Phoenicia.EnemySandevistanRework.Configurations.*

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ForceDeactivateSandevistan(context: ScriptExecutionContext, isGlobalSandevistan: Bool) -> Void {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    AISubActionApplyTimeDilation_Record_Implementation.ForceDeactivateSandevistan(puppet, isGlobalSandevistan);
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ForceDeactivateSandevistan(puppet: ref<ScriptedPuppet>, isGlobalSandevistan: Bool) -> Void {
    let blackboard: ref<IBlackboard>;
    let isGlobalSandevistan: Bool;
    let resetTimeDilationEvent: ref<ResetTimeDilation>;
    blackboard = puppet.GetAIControllerComponent().GetActionBlackboard();
    if !IsDefined(blackboard) {
      return;
    };
    if blackboard.GetFloat(GetAllBlackboardDefs().AIAction.ownerTimeDilation) != -1.00 && !puppet.HasIndividualTimeDilation() {
      resetTimeDilationEvent = new ResetTimeDilation();
      resetTimeDilationEvent.easeOut = n"";
      resetTimeDilationEvent.global = isGlobalSandevistan;
      puppet.QueueEvent(resetTimeDilationEvent);
    } else {
      puppet.UnsetIndividualTimeDilation(n"");
      blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerTimeDilation, -1.00);
      if isGlobalSandevistan {
        blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerGlobalTimeDilation, -1.00);
      };
    };
}

// ApplyOffensiveCooldown
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ApplyOffensiveUseCooldown(puppet: ref<ScriptedPuppet>) -> Void {    
    let settings = ESR_Settings();

    let i = 0;

    while (settings.offensiveUseCD > i) {
      StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_Offensive_CD");
      i += 1;
    }
}

// ApplyOffensiveCooldown
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ApplyDefensiveUseCooldown(puppet: ref<ScriptedPuppet>) -> Void {    
    let settings = ESR_Settings();

    let i = 0;

    while (settings.defensiveUseCD > i) {
      StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_Defensive_CD");
      i += 1;
    }
}
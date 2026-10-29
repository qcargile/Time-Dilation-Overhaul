module Phoenicia.EnemySandevistanRework.Utils

import Phoenicia.EnemySandevistanRework.Configurations.*

public static func ClearESRState(npc: ref<NPCPuppet>) -> Void {
    let hasBuff = StatusEffectSystem.ObjectHasStatusEffectWithTag(npc, n"ESR_Sandi_Buff");
    if npc.HasIndividualTimeDilation(n"Rhino") ||
       (hasBuff && (npc.HasIndividualTimeDilation(n"sandevistanAbility") ||
                    npc.HasIndividualTimeDilation(n"kerenzikovAbility") ||
                    npc.HasIndividualTimeDilation(n"kerenzikovVsSandi") ||
                    npc.HasIndividualTimeDilation(n"sandevistanVersusSandevistan"))) {
        npc.UnsetIndividualTimeDilation();
        let blackboard = npc.GetAIControllerComponent().GetActionBlackboard();
        if IsDefined(blackboard) {
            blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerTimeDilation, -1.00);
            blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerGlobalTimeDilation, -1.00);
        }
    }

    let effects: array<ref<StatusEffect>>;
    let effectSystem = GameInstance.GetStatusEffectSystem(npc.GetGame());
    effectSystem.GetAppliedEffects(npc.GetEntityID(), effects);
    let i = 0;
    while i < ArraySize(effects) {
        let id = effects[i].GetRecord().GetID();
        switch id {
            case t"BaseStatusEffect.ESR_Sandi_CD":
            case t"BaseStatusEffect.ESR_Sandi_Buff":
            case t"BaseStatusEffect.ESR_SVS_Buff":
            case t"BaseStatusEffect.ESR_SVK_Buff":
            case t"BaseStatusEffect.ESR_Kerenzikov_CD":
            case t"BaseStatusEffect.ESR_Offensive_CD":
            case t"BaseStatusEffect.ESR_Defensive_CD":
            case t"BaseStatusEffect.ESR_Stim_CD":
            case t"BaseStatusEffect.ESR_Stim_Buff":
            case t"BaseStatusEffect.ESR_RhinoSandiDebuff":
            case t"BaseStatusEffect.ESR_RhinoSandiSWBuff":
                effectSystem.RemoveStatusEffect(npc.GetEntityID(), id);
                break;
        }
        i += 1;
    }
}

public static func IsLookingAtTarget(looker: ref<GameObject>, target: ref<GameObject>, maxAngle: Float) -> Bool {
    let lookerPos: Vector4 = looker.GetWorldPosition();
    let targetPos: Vector4 = target.GetWorldPosition();


    let dirToTarget: Vector4 = Vector4.Normalize(targetPos - lookerPos);


    let lookDir: Vector4 = Vector4.Normalize(looker.GetWorldForward());


    let dotValue: Float = Vector4.Dot(lookDir, dirToTarget);


    let angleCos: Float = CosF(Deg2Rad(maxAngle));

    return IsLookingAtTarget(looker, target) || dotValue >= angleCos;
}

public static func IsLookingAtTarget(looker: ref<GameObject>, target: ref<GameObject>) -> Bool {
    let theGame = GetGameInstance();

    let lookedAtObect: ref<GameObject> = GameInstance.GetTargetingSystem(theGame).GetLookAtObject(looker, true, true);

    if !IsDefined(lookedAtObect) {
      return false;
    };

    return target.GetEntityID() == lookedAtObect.GetEntityID();
}

public static func CheckCommonRestrictions(npc: ref<NPCPuppet>, blockedByCC: Bool, allowSleep: Bool) -> Bool {
    if !ESRConfig.Enabled() {
        return false;
    }
    if (VehicleComponent.IsMountedToVehicle(npc.GetGame(), npc) && blockedByCC) {
        return false;
    }

    if (npc.IsDead()) {
        return false;
    }

    if (npc.IsIncapacitated() && !allowSleep) {
        return false;
    }

    if (StatusEffectSystem.ObjectHasStatusEffectOfType(npc, gamedataStatusEffectType.EMP)) {
        return false;
    }

    if (StatusEffectSystem.ObjectHasStatusEffectOfType(npc, gamedataStatusEffectType.Grapple) && blockedByCC) {
        return false;
    }

    if (StatusEffectSystem.ObjectHasStatusEffectOfType(npc, gamedataStatusEffectType.Stunned) && blockedByCC) {
        return false;
    }

    if (StatusEffectSystem.ObjectHasStatusEffectOfType(npc, gamedataStatusEffectType.Knockdown) && blockedByCC) {
        return false;
    }

    if (StatusEffectSystem.ObjectHasStatusEffectWithTag(npc, n"CyberwareMalfunction")) {
        return false;
    }

    if (StatusEffectSystem.ObjectHasStatusEffectWithTag(npc, n"TDO_TDSuppress")) {
        return false;
    }

    if npc.IsVendor(){
        return false;
    }

    let player = GetPlayer(GetGameInstance());

    if GameInstance.GetBlackboardSystem(GetGameInstance()).GetLocalInstanced(player.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine).GetInt(GetAllBlackboardDefs().PlayerStateMachine.SceneTier) >1{
        return false;
    };

    return true;
}

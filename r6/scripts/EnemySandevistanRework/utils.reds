module Phoenicia.EnemySandevistanRework.Utils

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
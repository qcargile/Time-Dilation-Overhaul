module Phoenicia.EnemySandevistanRework.Additions

import Phoenicia.EnemySandevistanRework.Configurations.*

//////////////////////////////////////////////////////////
////////////////////// KERENZIKOV ////////////////////////
//////////////////////////////////////////////////////////

// GetKerenzikovTier
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetKerenzikovTier(context: ScriptExecutionContext) -> Int32 {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanTier(puppet);
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetKerenzikovTier(puppet: ref<ScriptedPuppet>) -> Int32 {
    let statSystem = GameInstance.GetStatsSystem(GetGameInstance());
    let hasKerenzikov = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"HasKerenzikov"))); 

    if (hasKerenzikov > 0.0) {      
        return 1;
    }

    return 0;
}


// GetBaseKerenzikovDuration
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseKerenzikovDuration(puppet: ref<ScriptedPuppet>) -> Float {
    let settings = ESR_Settings();

    return settings.kerenzikovDuration;
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseKerenzikovDuration(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovDuration(puppet);
}
 

// GetBaseKerenzikovCooldown
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseKerenzikovCooldown(puppet: ref<ScriptedPuppet>) -> Float {
  let settings = ESR_Settings();

  return settings.kerenzikovCD;
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseKerenzikovCooldown(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovCooldown(puppet);
}


// GetBaseKerenzikovSpeed
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseKerenzikovSpeed(puppet: ref<ScriptedPuppet>) -> Float {
    let settings = ESR_Settings();

    return 1.0 / (1.0 - (settings.kerenzikovStrength / 100.0));
}


@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseKerenzikovSpeed(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovSpeed(puppet);
}



// GetAvailableKerenzikovDuration
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetAvailableKerenzikovDuration(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
    
    return AISubActionApplyTimeDilation_Record_Implementation.GetAvailableKerenzikovDuration(puppet);
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetAvailableKerenzikovDuration(puppet: ref<ScriptedPuppet>) -> Float {
    let statSystem = GameInstance.GetStatsSystem(GetGameInstance());

    let currentCooldown = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"ESR_Kerenzikov_CD_Counter"))); 

    let baseDuration = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovDuration(puppet);
    let baseCooldown = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovCooldown(puppet);

    // LogChannel(n"DEBUG", "z1: " + ToString(currentCooldown));
    // LogChannel(n"DEBUG", "z2: " + ToString(baseCooldown));
    // LogChannel(n"DEBUG", "z3: " + ToString((1.0 - (currentCooldown / baseCooldown))));
    // LogChannel(n"DEBUG", "z4: " + ToString(baseDuration));
    // LogChannel(n"DEBUG", "z5: " + ToString(baseDuration * (1.0 - (currentCooldown / baseCooldown))));

    return baseDuration * (1.0 - (currentCooldown / baseCooldown));
}


// ApplyCooldownAndDurationStacks
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ApplyKerenzikovCooldownAndDurationStacks(puppet: ref<ScriptedPuppet>, durationInSeconds: Int32) -> Void {
    let baseDuration = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovDuration(puppet);
    let baseCooldown = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovCooldown(puppet);

    let i = 0;

    while (10 * durationInSeconds > i) {
        StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_SVK_Buff");
        i += 1;
    }

    i = 0;

    let cooldownToDurationRatio = baseCooldown / baseDuration;

    let cooldownStacks = Cast<Int32>(cooldownToDurationRatio * Cast<Float>(durationInSeconds));

    while (cooldownStacks > i) {
      StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_Kerenzikov_CD");
      i += 1;
    }
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ApplyKerenzikovCooldownAndDurationStacks(context: ScriptExecutionContext, durationInSeconds: Int32) -> Void {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    AISubActionApplyTimeDilation_Record_Implementation.ApplyKerenzikovCooldownAndDurationStacks(puppet, durationInSeconds);
}


// StimPack
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseStimPackSpeed(puppet: ref<ScriptedPuppet>) -> Float {
    let settings = ESR_Settings();

    return 1.0 / (1.0 - (settings.stimPackStrength / 100.0));
}


@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseStimPackSpeed(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetBaseStimPackSpeed(puppet);
}



// Others
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetKerenzikovVsSandevistanSpeed(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetKerenzikovVsSandevistanSpeed(puppet);
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetKerenzikovVsSandevistanSpeed(puppet: ref<ScriptedPuppet>) -> Float {
    let settings = ESR_Settings();
    let player = GameInstance.GetPlayerSystem(puppet.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;

    let baseKerenzikovSpeed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovSpeed(puppet);
    let playerTimeDilation = 1.00 / GameInstance.GetTimeSystem(player.GetGame()).GetActiveTimeDilation(n"sandevistan", true);

    if (playerTimeDilation == baseKerenzikovSpeed) {
        return baseKerenzikovSpeed;
    }

    if (playerTimeDilation > baseKerenzikovSpeed) {
        return settings.kerenzikovMatching ? MaxF(baseKerenzikovSpeed, playerTimeDilation) : MaxF(baseKerenzikovSpeed, playerTimeDilation * settings.enemyMinimumSvS);
    } else {
        return MinF(baseKerenzikovSpeed, playerTimeDilation * (1.0 / (settings.playerMinimumSvS == 0.0 ? 0.001 : settings.playerMinimumSvS)));
    }
}


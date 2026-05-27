module Phoenicia.EnemySandevistanRework.Additions

import Phoenicia.EnemySandevistanRework.Configurations.*

//////////////////////////////////////////////////////////
////////////////////// SANDEVISTAN ///////////////////////
//////////////////////////////////////////////////////////

// GetSandevistanTier
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetSandevistanTier(context: ScriptExecutionContext) -> Int32 {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanTier(puppet);
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetSandevistanTier(puppet: ref<ScriptedPuppet>) -> Int32 {
    let statSystem = GameInstance.GetStatsSystem(GetGameInstance());
    let sandiTier1 = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"HasSandevistanTier1"))); 
    let sandiTier2 = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"HasSandevistanTier2"))); 
    let sandiTier3 = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"HasSandevistanTier3"))); 
    let sandiTier4 = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"HasSandevistanTier4"))); 
    let sandiTier5 = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"HasSandevistanTier5"))); 

    if (sandiTier5 > 0.0) {
        return 5;
    }

    if (sandiTier4 > 0.0) {
        return 4;
    }

    if (sandiTier3 > 0.0) {
        return 3;
    }

    if (sandiTier2 > 0.0) {
        return 2;
    }

    if (sandiTier1 > 0.0) {      
        return 1;
    }

    return 0;
}


// GetBaseSandevistanDuration
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseSandevistanDuration(puppet: ref<ScriptedPuppet>) -> Float {
    let settings = ESR_Settings();
    let sandevistanTier = AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanTier(puppet);
    let baseDuration: Float;
    switch (sandevistanTier) {
      case 5:
        baseDuration = settings.mk5Duration;
        break;
      case 4:
        baseDuration = settings.mk4Duration;
        break;
      case 3:
        baseDuration = settings.mk3Duration;
        break;
      case 2:
        baseDuration = settings.mk2Duration;
        break;
      case 1:
        baseDuration = settings.mk1Duration;
        break;
      default:
        baseDuration = 10.0;
        break;
    }    

    return baseDuration;
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseSandevistanDuration(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanDuration(puppet);
}
 

// GetBaseSandevistanCooldown
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseSandevistanCooldown(puppet: ref<ScriptedPuppet>) -> Float {
  let settings = ESR_Settings();
  let sandevistanTier = AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanTier(puppet);
  let baseCooldown: Float;

  switch (sandevistanTier) {
    case 5:
      baseCooldown = settings.mk5CD;
        break;
    case 4:
      baseCooldown = settings.mk4CD;
        break;
    case 3:
      baseCooldown = settings.mk3CD;
        break;
    case 2:
      baseCooldown = settings.mk2CD;
        break;
    case 1:
      baseCooldown = settings.mk1CD;
        break;
    default:
      baseCooldown = 40.0;
      break;
  }    

  return baseCooldown;
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseSandevistanCooldown(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanCooldown(puppet);
}


// GetBaseSandevistanSpeed
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseSandevistanSpeed(puppet: ref<ScriptedPuppet>) -> Float {
    let settings = ESR_Settings();

    let sandevistanTier = AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanTier(puppet);

    switch (sandevistanTier) {
      case 5:
        return 1.0 / (1.0 - (settings.mk5Strength / 100.0));
      case 4:
        return 1.0 / (1.0 - (settings.mk4Strength / 100.0));
      case 3:
        return 1.0 / (1.0 - (settings.mk3Strength / 100.0));
      case 2:
        return 1.0 / (1.0 - (settings.mk2Strength / 100.0));
      case 1:
        return 1.0 / (1.0 - (settings.mk1Strength / 100.0));
      default:
        return 1.45;
    }    
}


@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetBaseSandevistanSpeed(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    return AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(puppet);
}


// GetAvailableSandevistanDuration
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetAvailableSandevistanDuration(context: ScriptExecutionContext) -> Float {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
    
    return AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(puppet);
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetAvailableSandevistanDuration(puppet: ref<ScriptedPuppet>) -> Float {
    let statSystem = GameInstance.GetStatsSystem(GetGameInstance());

    let currentCooldown = statSystem.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"ESR_Sandi_CD_Counter"))); 
    
    let baseDuration = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanDuration(puppet);
    let baseCooldown = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanCooldown(puppet);

    return baseDuration * (1.0 - (currentCooldown / baseCooldown));
}


// ApplyCooldownAndDurationStacks
@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ApplyCooldownAndDurationStacks(puppet: ref<ScriptedPuppet>, durationInSeconds: Int32, isSvS: Bool) -> Void {
    let baseDuration = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanDuration(puppet);
    let baseCooldown = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanCooldown(puppet);

    let i = 0;

    if (isSvS) {
      while (10 * durationInSeconds > i) {
        StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_SVS_Buff");
        i += 1;
      }
    } else {
      while (10 * durationInSeconds > i) {
        StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_Sandi_Buff");
        i += 1;
      }
    }

    i = 0;

    let cooldownToDurationRatio = baseCooldown / baseDuration;

    let cooldownStacks = Cast<Int32>(cooldownToDurationRatio * Cast<Float>(durationInSeconds));

    while (cooldownStacks > i) {
      StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_Sandi_CD");
      i += 1;
    }
}

@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func ApplyCooldownAndDurationStacks(context: ScriptExecutionContext, durationInSeconds: Int32, isSvS: Bool) -> Void {
    let puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;

    AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(puppet, durationInSeconds, isSvS);
}



// Others




@addMethod(AISubActionApplyTimeDilation_Record_Implementation)
public final static func GetSandevistanVsSandevistanSpeed(context: ScriptExecutionContext) -> Float {
    let settings = ESR_Settings();
    let player = GameInstance.GetPlayerSystem(ScriptExecutionContext.GetOwner(context).GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;

    let baseSandevistanSpeed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(context);
    let playerTimeDilation = 1.00 / GameInstance.GetTimeSystem(player.GetGame()).GetActiveTimeDilation(n"sandevistan", true);

    if (playerTimeDilation == baseSandevistanSpeed) {
        return baseSandevistanSpeed;
    }

    if (playerTimeDilation > baseSandevistanSpeed) {
        return MaxF(baseSandevistanSpeed, playerTimeDilation * settings.enemyMinimumSvS);
    } else {
        return MinF(baseSandevistanSpeed, playerTimeDilation * (1.0 / (settings.playerMinimumSvS == 0.0 ? 0.001 : settings.playerMinimumSvS)));
    }
}


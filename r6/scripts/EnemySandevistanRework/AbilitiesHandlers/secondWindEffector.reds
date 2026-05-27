module Phoenicia.EnemySandevistanRework.Effectors

import Phoenicia.EnemySandevistanRework.Utils.*


public class SecondWindEffector extends ModifyAttackEffector {
  protected func ActionOn(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  protected func RepeatedAction(owner: ref<GameObject>) -> Void {
    this.ProcessAction(owner);
  }

  private final func ProcessAction(owner: ref<GameObject>) -> Void {    
    StatusEffectHelper.ApplyStatusEffect(owner, t"BaseStatusEffect.ESR_RhinoSandiSWBuff");
    StatusEffectHelper.ApplyStatusEffect(owner, t"BaseStatusEffect.ESR_RhinoSandiSWBuff");

    ApplyRhinoDilation(owner as NPCPuppet);
  }
}

public func ApplyRhinoDilation(owner: ref<NPCPuppet>) {
    let statSystem = GameInstance.GetStatsSystem(GetGameInstance());

    let healthPercentage = MaxF(GameInstance.GetStatPoolsSystem(owner.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(owner.GetEntityID()), gamedataStatPoolType.Health), 30.0);
    let dilationStrength = 20.0 * ((100.0 - healthPercentage) / 70.0);
            
    let ESR_RhinoBuffCounter = statSystem.GetStatValue(Cast<StatsObjectID>(owner.GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"ESR_RhinoBuffCounter"))); 
    dilationStrength += ESR_RhinoBuffCounter;

    let speed = 1.0 / (1.0 - (dilationStrength / 100.0));
    StatusEffectHelper.ApplyStatusEffect(owner, t"BaseStatusEffect.ESR_RhinoSandiDebuff");
    
    owner.SetIndividualTimeDilation(n"Rhino", speed);
}
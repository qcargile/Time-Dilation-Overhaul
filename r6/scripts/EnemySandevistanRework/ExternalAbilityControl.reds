module Phoenicia.EnemySandevistanRework.Utils

@if(ModuleExists("MuchBetterAI.SandevistanIntegration"))
import MuchBetterAI.SandevistanIntegration.*

@if(ModuleExists("MuchBetterAI.SandevistanIntegration"))
public static func ESR_DelegatesSandevistan(actor: ref<NPCPuppet>) -> Bool {
    return MBAI_ControlsEnemySandevistan(actor);
}

@if(!ModuleExists("MuchBetterAI.SandevistanIntegration"))
public static func ESR_DelegatesSandevistan(actor: ref<NPCPuppet>) -> Bool {
    return false;
}

@if(ModuleExists("MuchBetterAI.SandevistanIntegration"))
public static func ESR_EnemyAbilityBusy(actor: ref<NPCPuppet>) -> Bool {
    return MBAI_EnemySandevistanBusy(actor);
}

@if(!ModuleExists("MuchBetterAI.SandevistanIntegration"))
public static func ESR_EnemyAbilityBusy(actor: ref<NPCPuppet>) -> Bool {
    return false;
}

@if(ModuleExists("MuchBetterAI.SandevistanIntegration"))
public static func ESR_ProtectsExternalSandevistan(actor: ref<NPCPuppet>) -> Bool {
    return MBAI_ProtectsSandevistanDilation(actor);
}

@if(!ModuleExists("MuchBetterAI.SandevistanIntegration"))
public static func ESR_ProtectsExternalSandevistan(actor: ref<NPCPuppet>) -> Bool {
    return false;
}

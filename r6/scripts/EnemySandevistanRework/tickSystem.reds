module Phoenicia.EnemySandevistanRework.TickSystem

import Phoenicia.EnemySandevistanRework.Configurations.*
import Phoenicia.EnemySandevistanRework.Utils.*
import Phoenicia.EnemySandevistanRework.Effectors.*
import Phoenicia.EnemySandevistanRework.Smasher.*

public class TickSystem extends ScriptableSystem {
    private let player: wref<PlayerPuppet>;
    private let delaySystem: ref<DelaySystem>;
    private let statsSystem: ref<StatsSystem>;
    private let statPoolSystem: ref<StatPoolsSystem>;

    public static func GetInstance(gameInstance: GameInstance) -> ref<TickSystem> {
        let system: ref<TickSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"Phoenicia.EnemySandevistanRework.TickSystem.TickSystem") as TickSystem;
        return system;
    }

    private final func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
        let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());

        if IsDefined(player) { 
            this.player = player;
            this.delaySystem = GameInstance.GetDelaySystem(this.player.GetGame());
            this.statsSystem = GameInstance.GetStatsSystem(this.player.GetGame());
            this.statPoolSystem = GameInstance.GetStatPoolsSystem(this.player.GetGame());

            this.SetUpNextCallback();
        }
    }

    public func SetUpNextCallback() {
        let entities = this.player.GetEntitiesAroundObject(32.0, TSF_NPC());

        let i = 0;

        while i < ArraySize(entities) {
            
            if (this.statsSystem.GetStatValue(Cast<StatsObjectID>(entities[i].GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"ESR_HasSecondWind"))) > 0.0) {
                this.HandleRhino(entities[i] as NPCPuppet);
            }

            if (this.statsSystem.GetStatValue(Cast<StatsObjectID>(entities[i].GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"ESR_HasStimPack"))) > 0.0) {
                this.ConsiderStimPack(entities[i] as NPCPuppet);
            }

            let sandevistanTier = AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanTier(entities[i] as NPCPuppet);

            if (sandevistanTier != 5 && (sandevistanTier > 0 || AISubActionApplyTimeDilation_Record_Implementation.GetKerenzikovTier(entities[i] as NPCPuppet) > 0)) {
                this.TriggerOffensiveAction(entities[i] as NPCPuppet, AISubActionApplyTimeDilation_Record_Implementation.GetSandevistanTier(entities[i] as NPCPuppet) > 0, AISubActionApplyTimeDilation_Record_Implementation.GetKerenzikovTier(entities[i] as NPCPuppet) > 0);
            }

            if (sandevistanTier == 5) {
                this.HandleSmasherOffensiveSandiActivations(entities[i] as NPCPuppet);
            }

            if (AISubActionApplyTimeDilation_Record_Implementation.GetKerenzikovTier(entities[i] as NPCPuppet) > 0) {
                this.HandleKerenzikovVsSandevistanActivation(entities[i] as NPCPuppet);
            } 

            i+= 1;
        }

        this.delaySystem.DelayCallback(EnemySandevistanReworkCallback.Create(this), 1, true);
    }

    private func HandleSmasherOffensiveSandiActivations(puppet: ref<NPCPuppet>) {
        if (NPCPuppet.IsInCombatWithTarget(puppet, this.player) && 
            this.CommonOffensiveRestrictions(puppet) &&
            !HasSmasherSandevistanBlocker(puppet) &&
            !StatusEffectSystem.ObjectHasStatusEffectWithTag(puppet, n"ESR_Sandi_Buff")) {
                let baseChance = 5;
                let distanceToPlayer = Vector4.Distance(puppet.GetWorldPosition(), this.player.GetWorldPosition());
                
                let isPhase1 = !StatusEffectSystem.ObjectHasStatusEffect(puppet, t"AdamSmasher.Destroyed_Plate") && StatusEffectSystem.ObjectHasStatusEffect(puppet, t"AdamSmasher.Phase1");
                let isPhase15 = StatusEffectSystem.ObjectHasStatusEffect(puppet, t"AdamSmasher.Destroyed_Plate") && StatusEffectSystem.ObjectHasStatusEffect(puppet, t"AdamSmasher.Phase1");
                let isLastPhase = StatusEffectSystem.ObjectHasStatusEffect(puppet, t"AdamSmasher.Emergency");

                if (StatusEffectSystem.ObjectHasStatusEffect(puppet, t"AdamSmasher.Smasher_Single_Shot_Dps_Modifier")) {
                    baseChance += (isPhase1 || isLastPhase || isPhase15 ? 35 : 15);
                } else if (StatusEffectSystem.ObjectHasStatusEffect(puppet, t"AdamSmasher.Shooting")) {
                    baseChance += (isPhase1 || isPhase15 ? 15 : 5);
                    baseChance += (isLastPhase ? 35 : 10);
                }   

                if (isPhase1 && (distanceToPlayer < 12.0 || distanceToPlayer > 35.0)) {
                    baseChance += 25;
                }

                if (isPhase15) {
                    baseChance += 5;
                }

                if (isLastPhase && distanceToPlayer < 15.0) {
                    baseChance += 25;
                }

                let randomNumber = RandRange(0, 100);
                if (baseChance > randomNumber) {
                    let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(puppet);

                    let stacks = 2;
                    stacks += (isPhase1 ? 4 : 0);
                    stacks += (isPhase15 ? 2 : 0);

                    AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(puppet, stacks, false);
                    puppet.SetIndividualTimeDilation(n"sandevistanAbility", speed);
                    AISubActionApplyTimeDilation_Record_Implementation.ApplyOffensiveUseCooldown(puppet);
                }
            }
    }

    public func HandleKerenzikovVsSandevistanActivation(puppet: ref<NPCPuppet>) {
        let distanceToPlayer = Vector4.Distance(puppet.GetWorldPosition(), this.player.GetWorldPosition());
        let playerInSandevistan = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"SandevistanPlayerBuff");
        let rangeCheck = ((IsLookingAtTarget(puppet, this.player, 90) && distanceToPlayer < 20.0) || distanceToPlayer < 5.0);


        if (playerInSandevistan && 
            NPCPuppet.IsInCombatWithTarget(puppet, this.player) && 
            rangeCheck && CheckCommonRestrictions(puppet, true, false) && 
            !StatusEffectSystem.ObjectHasStatusEffectWithTag(puppet, n"ESR_Sandi_Buff")
            ) {
            let kerenzikovDuration = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovDuration(puppet);

            if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableKerenzikovDuration(puppet) == kerenzikovDuration) {
                AISubActionApplyTimeDilation_Record_Implementation.ApplyKerenzikovCooldownAndDurationStacks(puppet, Cast<Int32>(kerenzikovDuration));
                let speed = AISubActionApplyTimeDilation_Record_Implementation.GetKerenzikovVsSandevistanSpeed(puppet);
                puppet.SetIndividualTimeDilation(n"kerenzikovVsSandi", speed);
                // puppetBlackBoard.SetFloat(GetAllBlackboardDefs().AIAction.ownerGlobalTimeDilation, AISubActionApplyTimeDilation_Record_Implementation.GetKerenzikovVsSandevistanSpeed(puppet));
            }
        }

    }

    public func HandleRhino(puppet: ref<NPCPuppet>) {
        if (NPCPuppet.IsInCombat(puppet)) {
            ApplyRhinoDilation(puppet);

        } else {
            puppet.UnsetIndividualTimeDilation();
        }

    }

    public func ConsiderStimPack(puppet: ref<NPCPuppet>) {
        let distanceToPlayer = Vector4.Distance(puppet.GetWorldPosition(), this.player.GetWorldPosition());

        let npcWeapon = NPCPuppet.GetActiveWeapon(puppet);
        let isMelee = npcWeapon.IsMelee();

        if this.CommonOffensiveRestrictions(puppet) && IsLookingAtTarget(puppet, this.player, 60) && ((!isMelee && distanceToPlayer < 30.0) || (isMelee && distanceToPlayer < 12.0)) && !StatusEffectSystem.ObjectHasStatusEffect(puppet, t"BaseStatusEffect.ESR_Stim_CD") {
            let settings = ESR_Settings();
            let healthCost = settings.stimPackHealthCost;
            let npcHealth = GameInstance.GetStatPoolsSystem(this.player.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatPoolType.Health);

            if (npcHealth - healthCost > 50.0) {
                let randomNumber = RandRange(0, 100);

                if (20 > randomNumber) {
                    StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_Stim_Buff");
                    StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.ESR_Stim_CD");
                    let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseStimPackSpeed(puppet);
                    puppet.SetIndividualTimeDilation(n"sandevistanAbility", speed);
                    GameInstance.GetStatPoolsSystem(puppet.GetGame()).RequestChangingStatPoolValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatPoolType.Health, -settings.stimPackHealthCost, puppet, false, true);

                    if (settings.enableStimPackCustomSound) {
                        let randomNumber = RandRange(0, 100);

                        let soundString = randomNumber > 50 ? "stim1" : "stim2" ;
                        GameInstance.GetAudioSystem(puppet.GetGame()).Play(StringToName(soundString), puppet.GetEntityID(), n"V");
                    }

                }
            }

        }
    }

    private func CommonOffensiveRestrictions(puppet: ref<NPCPuppet>) -> Bool {
        return IsLookingAtTarget(puppet, this.player, 30) && 
               CheckCommonRestrictions(puppet, true, false) && 
               NPCPuppet.IsInCombatWithTarget(puppet, this.player) &&
               !StatusEffectSystem.ObjectHasStatusEffect(puppet, t"BaseStatusEffect.ESR_Stim_Buff") && 
               !StatusEffectSystem.ObjectHasStatusEffect(puppet, t"BaseStatusEffect.ESR_Sandi_Buff") && 
               !StatusEffectSystem.ObjectHasStatusEffect(puppet, t"BaseStatusEffect.ESR_SVS_Buff") &&
               !StatusEffectSystem.ObjectHasStatusEffect(puppet, t"BaseStatusEffect.ESR_SVK_Buff") &&
               !StatusEffectSystem.ObjectHasStatusEffect(puppet, t"BaseStatusEffect.ESR_Offensive_CD");
    }

    public func TriggerOffensiveAction(puppet: ref<NPCPuppet>, hasSandi: Bool, hasKerenzikov: Bool) {
        let distanceToPlayer = Vector4.Distance(puppet.GetWorldPosition(), this.player.GetWorldPosition());
        let npcWeapon = NPCPuppet.GetActiveWeapon(puppet);

        let isMelee = npcWeapon.IsMelee();
        let magFull = WeaponObject.IsMagazineFull(npcWeapon);
        let hasShotgun = npcWeapon.IsShotgun();
        let pistolOrRevolver = WeaponObject.IsOfType(npcWeapon.GetItemID(), gamedataItemType.Wea_Revolver) || WeaponObject.IsOfType(npcWeapon.GetItemID(), gamedataItemType.Wea_Handgun);
        let bb: ref<IBlackboard> =  GameInstance.GetBlackboardSystem(GetGameInstance()).GetLocalInstanced(puppet.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
        let playerNotLooking = !IsLookingAtTarget(this.player, puppet, 135);
        let playerReloadingWeapon = Equals(bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Weapon), Cast<Int32>(EnumValueFromString("gamePSMRangedWeaponStates", "Reload")));
        let playerLowHealth = GameInstance.GetStatPoolsSystem(this.player.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatPoolType.Health) < 30.0;
        let kerenzikovDuration = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovDuration(puppet);
        let playerHasSandiCharges = this.statPoolSystem.GetStatPoolValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatPoolType.SandevistanCharge) > 50.0;
        let playerHasSandi = this.statsSystem.GetStatValue(Cast<StatsObjectID>(GetPlayer(GetGameInstance()).GetEntityID()), IntEnum<gamedataStatType>(EnumValueFromName(n"gamedataStatType", n"HasSandevistan"))) > 0.0;


        if (distanceToPlayer < 20.0 && this.CommonOffensiveRestrictions(puppet) &&
         (pistolOrRevolver || (isMelee && hasSandi) || (hasShotgun && hasSandi))) {
            let baseChance = 0;

            if (distanceToPlayer < 5.0) {
                baseChance += (isMelee ? 35 : 10);
                baseChance += (hasShotgun ? -20: 0);
            } else if (distanceToPlayer < 10.0) {
                baseChance += (isMelee ? 15 : 5);
            } else if (distanceToPlayer < 15.0) {
                baseChance += (isMelee ? 10 : 5);
                baseChance += (hasShotgun ? 10: 0);
            } else {
                baseChance += (isMelee ? 0 : 5);
                baseChance += (hasShotgun ? 5: 0);
            }

            if (pistolOrRevolver) {
                if (hasKerenzikov && AISubActionApplyTimeDilation_Record_Implementation.GetAvailableKerenzikovDuration(puppet) == kerenzikovDuration){
                    baseChance += (magFull ? 20 : -30);
                    baseChance += (hasSandi && magFull ? 15 : 0);
                } else {
                    baseChance += (magFull ? 10 : -30);
                }
            }

            if (playerHasSandi && !(pistolOrRevolver && hasKerenzikov && AISubActionApplyTimeDilation_Record_Implementation.GetAvailableKerenzikovDuration(puppet) == kerenzikovDuration)) {
                baseChance -= 5;

                if (playerHasSandiCharges) {
                    baseChance -= 20;
                }
            }

            if (playerNotLooking) {
                baseChance += 15;
            }

            if (playerReloadingWeapon && (isMelee || hasShotgun)) {
                baseChance += 25;
            }

            if (playerLowHealth) {
                baseChance += 15;
            }

            let randomNumber = RandRange(0, 100);
            if (baseChance > randomNumber) {
                if (pistolOrRevolver) {
                    if (hasKerenzikov && AISubActionApplyTimeDilation_Record_Implementation.GetAvailableKerenzikovDuration(puppet) >= 2.0) {
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyKerenzikovCooldownAndDurationStacks(puppet, Cast<Int32>(2.0));
                        let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseKerenzikovSpeed(puppet);
                        puppet.SetIndividualTimeDilation(n"kerenzikovAbility", speed);
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyOffensiveUseCooldown(puppet);
                    } else if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(puppet) >= 2.0) {
                        let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(puppet);
                        puppet.SetIndividualTimeDilation(n"sandevistanAbility", speed);
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(puppet, 2, false);
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyOffensiveUseCooldown(puppet);
                    }
                }

                if (hasShotgun) {
                    if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(puppet) >= 2.0) {
                        let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(puppet);
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(puppet, 2, false);
                        puppet.SetIndividualTimeDilation(n"sandevistanAbility", speed);
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyOffensiveUseCooldown(puppet);
                    }
                }

                if (isMelee) {
                    if (AISubActionApplyTimeDilation_Record_Implementation.GetAvailableSandevistanDuration(puppet) >= 4.0) {
                        let speed = AISubActionApplyTimeDilation_Record_Implementation.GetBaseSandevistanSpeed(puppet);
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyCooldownAndDurationStacks(puppet, 4, false);
                        puppet.SetIndividualTimeDilation(n"sandevistanAbility", speed);
                        AISubActionApplyTimeDilation_Record_Implementation.ApplyOffensiveUseCooldown(puppet);
                    }
                }
            }

        }
    }
}



public class EnemySandevistanReworkCallback extends DelayCallback {
  let system: wref<TickSystem>;

  public static func Create(system: ref<TickSystem>) -> ref<EnemySandevistanReworkCallback> {
    let self: ref<EnemySandevistanReworkCallback> = new EnemySandevistanReworkCallback();
    self.system = system;
    return self;
  }

  public func Call() -> Void {
    this.system.SetUpNextCallback();
  }
}
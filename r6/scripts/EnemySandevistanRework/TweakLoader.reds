module Phoenicia.EnemySandevistanRework.TweakLoader

import Phoenicia.EnemySandevistanRework.Configurations.*

class TweakLoader extends ScriptableService {
    private let preInit: Bool = false;
    private let initialized: Bool = false;
    private let configs: ref<EnemySandevistanSettings>;

    private cb func OnInitialize() {
      this.configs = ESR_Settings();

      GameInstance.GetCallbackSystem()
        .RegisterCallback(n"Session/BeforeStart", this, n"OnAfterInit");
  }

  private cb func OnAfterInit(event: ref<GameSessionEvent>) {
      if (!this.preInit) {
        this.preInit = true;
        return;
      }

      if (this.initialized) {
        return;
      }

      this.initialized = true;



      if (this.configs.enableStimPack) {
        TweakDBManager.SetFlat(t"BaseStatusEffect.ESR_Stim_CDDuration.value", this.configs.stimPackCooldown + this.configs.stimPackDuration);
        TweakDBManager.UpdateRecord(t"BaseStatusEffect.ESR_Stim_CDDuration");

        TweakDBManager.SetFlat(t"BaseStatusEffect.ESR_Stim_Duration.value", this.configs.stimPackDuration);
        TweakDBManager.UpdateRecord(t"BaseStatusEffect.ESR_Stim_Duration");
      }

      if (this.configs.replaceOGAbilities) {
        this.DisableOGAbilities();

        this.InitializeCrimeBosses();
        this.InitializePsychos();
        this.InitializeScavs();
        this.InitializeVoodoo();
        this.InitializeSixth();
        this.InitializeValentinos();
        this.InitializeTygers();
        this.InitializeAnimals();
        this.InitializeWraiths();
        this.InitializeMaelstormers();
        this.InitializeMercs();
        this.InitializeKangTao();
        this.InitializeSecurity();
        this.InitializeBarghest();
        this.InitializeMilitech();
        this.InitializeArasaka();
        this.InitializeTraumaTeam();
        this.InitializeBeatsOnBrats();
      }

  }

  private func InitializeBeatsOnBrats() {
      AddAbilitiesToCharacter(t"Character.mq025_cesar", [t"Ability.ESR_HasSandevistanTier1"]);

      AddAbilitiesToCharacter(t"Character.mq025_buck", [t"Ability.ESR_HasKerenzikov"]);

      AddAbilitiesToCharacter(t"Character.mq025_ozob_fist_fight", [t"Ability.ESR_HasKerenzikov"]);

      AddAbilitiesToCharacter(t"Character.mq025_rhino", [t"Ability.ESR_HasSecondWind"]);


      AddAbilitiesToCharacter(t"Character.mq025_razor", [t"Ability.ESR_HasSandevistanTier3", t"Ability.ESR_HasKerenzikov"]);

  }

  private func DisableOGAbilities() {
    TweakDBManager.SetFlat(t"Ability.HasSandevistan.showInCodex", false);
    TweakDBManager.SetFlat(t"Ability.HasSandevistan.abilityPackage", t"Ability.ESR_EmptyAbilityGameplayPackage");
    TweakDBManager.UpdateRecord(t"Ability.HasSandevistan");

    TweakDBManager.SetFlat(t"Ability.HasSandevistanTier1.showInCodex", false);
    TweakDBManager.SetFlat(t"Ability.HasSandevistanTier1.abilityPackage", t"Ability.ESR_EmptyAbilityGameplayPackage");
    TweakDBManager.UpdateRecord(t"Ability.HasSandevistanTier1");

    TweakDBManager.SetFlat(t"Ability.HasSandevistanTier2.showInCodex", false);
    TweakDBManager.SetFlat(t"Ability.HasSandevistanTier2.abilityPackage", t"Ability.ESR_EmptyAbilityGameplayPackage");
    TweakDBManager.UpdateRecord(t"Ability.HasSandevistanTier2");

    TweakDBManager.SetFlat(t"Ability.HasSandevistanTier3.showInCodex", false);
    TweakDBManager.SetFlat(t"Ability.HasSandevistanTier3.abilityPackage", t"Ability.ESR_EmptyAbilityGameplayPackage");
    TweakDBManager.UpdateRecord(t"Ability.HasSandevistanTier3");

    TweakDBManager.SetFlat(t"Ability.HasKerenzikov.showInCodex", false);
    TweakDBManager.SetFlat(t"Ability.HasKerenzikov.abilityPackage", t"Ability.ESR_EmptyAbilityGameplayPackage");
    TweakDBManager.UpdateRecord(t"Ability.HasKerenzikov");
  }

  private func InitializeCrimeBosses() {
    AddAbilitiesToCharacter(t"Character.ma_wat_lch_08_outpost_miniboss", [t"Ability.ESR_HasSandevistanTier3", t"Ability.ESR_HasKerenzikov"]);
    AddAbilitiesToCharacter(t"Character.ma_wat_lch_01_outpost_miniboss", [t"Ability.ESR_HasSandevistanTier2"]);
    AddAbilitiesToCharacter(t"Character.ma_wat_nid_01_outpost_miniboss", [t"Ability.ESR_HasSandevistanTier2"]);

    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.ma_wat_nid_02_outpost_miniboss", [t"Ability.ESR_HasStimPack"]);
    }


    AddAbilitiesToCharacter(t"Character.ma_wbr_jpn_20_outpost_miniboss", [t"Ability.ESR_HasKerenzikov"]);



    AddAbilitiesToCharacter(t"Character.ma_hey_gle_02_outpost_miniboss", [t"Ability.ESR_HasKerenzikov", t"Ability.ESR_HasSandevistanTier2"]);


    AddAbilitiesToCharacter(t"Character.ma_hey_rey_06_outpost_miniboss", [t"Ability.ESR_HasKerenzikov", t"Ability.ESR_HasSandevistanTier2"]);


    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.ma_std_arr_03_outpost_miniboss", [t"Ability.ESR_HasStimPack"]);
    }
    AddAbilitiesToCharacter(t"Character.ma_std_arr_03_outpost_miniboss", [t"Ability.ESR_HasKerenzikov"]);


    AddAbilitiesToCharacter(t"Character.ma_pac_cvi_12_outpost_miniboss", [t"Ability.ESR_HasKerenzikov", t"Ability.ESR_HasSandevistanTier2"]);


    AddAbilitiesToCharacter(t"Character.ma_std_rcr_08_outpost_miniboss", [t"Ability.ESR_HasSandevistanTier1"]);


    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.ma_bls_ina_se1_17_outpost_miniboss", [t"Ability.ESR_HasStimPack"]);
    }
    AddAbilitiesToCharacter(t"Character.ma_bls_ina_se1_17_outpost_miniboss", [t"Ability.ESR_HasKerenzikov"]);


    AddAbilitiesToCharacter(t"Character.ma_pac_wwd_02_outpost_miniboss", [
      t"Ability.ESR_HasKerenzikov"
    ]);


    AddAbilitiesToCharacter(t"Character.sts_wat_kab_107_taki_kenmochi", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier2"
    ]);


    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.sts_wat_kab_03_solo", [t"Ability.ESR_HasStimPack"]);
    }
    AddAbilitiesToCharacter(t"Character.sts_wat_kab_03_solo", [t"Ability.ESR_HasKerenzikov"]);


    AddAbilitiesToCharacter(t"Character.ma_wat_nid_06_outpost_miniboss", [
      t"Ability.ESR_HasSandevistanTier1"
    ]);


    AddAbilitiesToCharacter(t"Character.q110_animals_boss", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier3"
    ]);


    AddAbilitiesToCharacter(t"Character.we_ep1_05_mini_boss", [
      t"Ability.ESR_HasSandevistanTier3"
    ]);


    AddAbilitiesToCharacter(t"Character.sts_ep1_03_miniboss_placeholder", [
      t"Ability.ESR_HasKerenzikov"
    ]);


    AddAbilitiesToCharacter(t"Character.sts_ep1_08_kgb_boss", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier3"
    ]);



    AddAbilitiesToCharacter(t"Character.q304_kurt_miniboss", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier1"
    ]);

    AddAbilitiesToCharacter(t"Character.kurtz", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier1"
    ]);



    AddAbilitiesToCharacter(t"Character.q305_maxtac_droid", [
      t"Ability.ESR_HasSandevistanTier1"
    ]);


    AddAbilitiesToCharacter(t"Character.q305_maxtac_miniboss_netrunner_ma", [
      t"Ability.ESR_HasKerenzikov"
    ]);

    AddAbilitiesToCharacter(t"Character.maxtac_av_netrunner_ma", [
      t"Ability.ESR_HasKerenzikov"
    ]);

    AddAbilitiesToCharacter(t"Character.maxtac_av_netrunner_ma_2nd_wave", [
      t"Ability.ESR_HasKerenzikov"
    ]);

    AddAbilitiesToCharacter(t"Character.q305_maxtac_miniboss_frifle_wa", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier2"
    ]);
    AddAbilitiesToCharacter(t"Character.maxtac_av_riffle_ma", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier2"
    ]);
    AddAbilitiesToCharacter(t"Character.maxtac_av_sniper_wa_elite_2nd_wave", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier2"
    ]);
    AddAbilitiesToCharacter(t"Character.maxtac_av_riffle_ma_2nd_wave", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier2"
    ]);
    AddAbilitiesToCharacter(t"Character.maxtac_av_sniper_wa_elite", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier2"
    ]);


    AddAbilitiesToCharacter(t"Character.q305_maxtac_miniboss_mantis_ma", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier3"
    ]);

    AddAbilitiesToCharacter(t"Character.maxtac_av_mantis_wa", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier3"
    ]);

    AddAbilitiesToCharacter(t"Character.maxtac_av_mantis_wa_2nd_wave", [
      t"Ability.ESR_HasKerenzikov",
      t"Ability.ESR_HasSandevistanTier3"
    ]);

  }

  private func InitializePsychos() {

      AddAbilitiesToCharacter(t"Character.ma_wat_kab_02_cyberpsycho", [t"Ability.ESR_HasSandevistanTier2", t"Ability.ESR_HasKerenzikov"]);

      AddAbilitiesToCharacter(t"Character.ma_wat_kab_08_cyberpsycho", [t"Ability.ESR_HasSandevistanTier3", t"Ability.ESR_HasKerenzikov"]);

    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.ma_wat_lch_06_cyberpsycho", [t"Ability.ESR_HasStimPack"]);
    }

    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.ma_cct_dtn_03_cyberpsycho", [t"Ability.ESR_HasStimPack"]);
    }
    AddAbilitiesToCharacter(t"Character.ma_cct_dtn_03_cyberpsycho", [t"Ability.ESR_HasKerenzikov"]);


    AddAbilitiesToCharacter(t"Character.ma_cct_dtn_07_cyberpsycho", [t"Ability.ESR_HasSandevistanTier3", t"Ability.ESR_HasKerenzikov"]);

    AddAbilitiesToCharacter(t"Character.ma_hey_spr_04_cyberpsycho", [
      t"Ability.ESR_HasSandevistanTier2"
    ]);


    AddAbilitiesToCharacter(t"Character.ma_pac_cvi_08_psycho", [t"Ability.ESR_HasSandevistanTier3", t"Ability.ESR_HasKerenzikov"]);


    TweakDBManager.SetFlat(t"Character.ma_bls_ina_se1_08_cyberpsycho.archetypeData", t"ArchetypeData.ShotgunnerT2");
    TweakDBManager.UpdateRecord(t"Character.ma_bls_ina_se1_08_cyberpsycho");


    AddAbilitiesToCharacter(t"Character.ma_bls_ina_se1_22_psycho", [t"Ability.ESR_HasSandevistanTier2", t"Ability.ESR_HasKerenzikov"]);


    AddAbilitiesToCharacter(t"Character.ma_std_rcr_11_cyberpsycho", [
      t"Ability.ESR_HasSandevistanTier1"
    ]);



    AddAbilitiesToCharacter(t"Character.sts_wat_nid_01_cyberpsycho", [
      t"Ability.ESR_HasSandevistanTier2", t"Ability.ESR_HasKerenzikov"
    ]);



    AddAbilitiesToCharacter(t"Character.sts_wat_kab_04_ryoko", [
      t"Ability.ESR_HasSandevistanTier3", t"Ability.ESR_HasKerenzikov"
    ]);



    AddAbilitiesToCharacter(t"Character.ma_cct_dtn_03_cyberpsycho", [t"Ability.ESR_HasSandevistanTier1"]);


    AddAbilitiesToCharacter(t"Character.Cyberninja_Oda", [
      t"Ability.ESR_HasSandevistanTier4", t"Ability.ESR_HasKerenzikov"
    ]);


    AddAbilitiesToCharacter(t"Character.cbj_ep1_001_cyberjunkie", [
      t"Ability.ESR_HasSandevistanTier1", t"Ability.ESR_HasKerenzikov"
    ]);

    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.cbj_ep1_004_cyberjunkie", [t"Ability.ESR_HasStimPack"]);
    }

    AddAbilitiesToCharacter(t"Character.cbj_ep1_005_cyberjunkie", [
      t"Ability.ESR_HasSandevistanTier3"
    ]);

    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.cbj_ep1_006_cyberjunkie", [t"Ability.ESR_HasStimPack"]);
    }

    if (this.configs.enableStimPack) {
      AddAbilitiesToCharacter(t"Character.cbj_ep1_008_cyberjunkie", [t"Ability.ESR_HasStimPack"]);
    }

    AddAbilitiesToCharacter(t"Character.cbj_ep1_008_cyberjunkie", [
      t"Ability.ESR_HasSandevistanTier1"
    ]);

    AddAbilitiesToCharacter(t"Character.cbj_ep1_011_cyberjunkie", [
      t"Ability.ESR_HasSandevistanTier1", t"Ability.ESR_HasKerenzikov"
    ]);



    AddAbilitiesToCharacter(t"Character.q113_smasher_arasaka_mantis", [
      t"Ability.ESR_HasSandevistanTier1", t"Ability.ESR_HasKerenzikov"
    ]);

    AddAbilitiesToCharacter(t"Character.q113_boss_smasher", [
      t"Ability.ESR_HasSandevistanTier5", t"Ability.ESR_HasKerenzikov"
    ]);

  }

  private func InitializeScavs() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
          t"Character.scavenger_elite3_sniper2_grad_ma_inline0",
          t"Character.ep1_scavenger_elite3_sniper2_grad_ma_inline0",
          t"Character.scavenger_fast2_fmelee2rare_knife_ma_rare_inline8",
          t"Character.scavenger_fast3_fmelee3_machete_wa_elite_inline8",
          t"Character.ep1_scavenger_strong3_gunner2_defender_mb_rare_inline0",
          t"Character.scavenger_strong3_gunner2_defender_mb_rare_inline0"
      ]);
  }

  private func InitializeVoodoo() {
      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.voodooboys_grunt1_fmelee2rare_baseball_ma_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
          t"Character.ep1_voodooboys_grunt3coat_shotgun3_zhuo_ma_elite_inline4",
          t"Character.voodooboys_grunt3coat_shotgun3_zhuo_ma_elite_inline4"
      ]);
  }

  private func InitializeSixth() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.sixthstreet_prepers3_grenadier2_nova_ma_rare_inline0",
        t"Character.sixthstreet_prepers3_shotgun3_carnage_ma_rare_inline0",
        t"Character.sixthstreet_patrol2_shotgun3_satara_ma_elite_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.sixthstreet_menace1_shotgun2_igla_ma_inline4",
        t"Character.sixthstreet_menace1_shotgun2_tactician_ma_inline0",
        t"Character.sixthstreet_veteran3_ranged2_ajax_ma_inline4",
        t"Character.sixthstreet_menace1_fshotgun2_tactician_wa_rare_inline4",
        t"Character.sixthstreet_prepers3_grenadier2_nova_ma_rare_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.sixthstreet_prepers3_shotgun3_carnage_ma_rare_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier3AbilityGroup", [
          t"Character.sixthstreet_patrol2_shotgun3_satara_ma_elite_inline0"
      ]);
  }

  private func InitializeValentinos() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
          t"Character.valentinos_sniper_sniper3_grad_wa_elite_inline0",
          t"Character.valentinos_shotgun3_shotgun3_testera_ma_elite_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
          t"Character.valentinos_grunt3_fmelee2_knife_ma_rare_inline4",
          t"Character.valentinos_grunt3_fmelee2_machete_ma_rare_inline4",
          t"Character.valentinos_strong2_shotgun2_igla_ma_rare_inline4",
          t"Character.valentinos_sniper_sniper3_grad_wa_elite_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
          t"Character.valentinos_shotgun3_shotgun3_testera_ma_elite_inline0"
      ]);
  }

  private func InitializeTygers() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.tygerclaw_gangster3_netrunner_nue_wa_rare_inline4",
        t"Character.tyger_claws_kunoichi_fmelee3_fists_ma_elite_inline0",
        t"Character.tyger_claws_kunoichi_fmelee3_katana_wa_elite_inline4",
        t"Character.tyger_claws_martial_fmelee2_fists_ma_rare_inline0",
        t"Character.tyger_claws_martial_fmelee2_katana_ma_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.tyger_claws_martial_fmelee2_fists_ma_rare_inline0",
        t"Character.tyger_claws_martial_fmelee2_katana_ma_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.tyger_claws_biker3_shotgun2_tactician_wa_inline0",
        t"Character.tyger_claws_gangster3_ranged3_sidewinder_ma_inline4",
        t"Character.tyger_claws_kunoichi_fmelee3_fists_ma_elite_inline0",
        t"Character.tyger_claws_kunoichi_fmelee3_katana_wa_elite_inline4",
        t"Character.tyger_claws_biker3_shotgun3_zhuo_ma_elite_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier3AbilityGroup", [
        t"Character.tygerclaw_gangster3_netrunner_nue_wa_rare_inline4"
      ]);
  }

  private func InitializeAnimals() {
      if (this.configs.enableStimPack) {
        AddAbilityTo(t"ESR_HasStimPackAbilityGroup", [
          t"Character.animals_elite3_gunner3_hmg_mba_elite_inline2",
          t"Character.animals_bouncer3_hmelee3_fists_mba_elite_inline0",
          t"Character.animals_elite3_hmelee3_fists_mba_elite_inline0"
        ]);
      }

  }

  private func InitializeWraiths() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.wraiths_warrior3_shotgun3_palica_ma_elite_inline2",
        t"Character.wraiths_warrior3_shotgun3_satara_ma_elite_inline0",
        t"Character.wraiths_operator3_shotgun2_crusher_ma_rare_inline4",
        t"Character.wraiths_warrior3_ranged3_quasar_wa_rare_inline4",
        t"Character.wraiths_prisoner_fmelee3_fists_ma_elite_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.wraiths_warrior3_shotgun3_palica_ma_elite_inline2",
        t"Character.wraiths_operator3_shotgun2_crusher_ma_rare_inline4",
        t"Character.wraiths_warrior3_ranged3_quasar_wa_rare_inline4",
        t"Character.wraiths_strong_gunner3_hmg_mb_elite_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.wraiths_warrior3_shotgun3_satara_ma_elite_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier3AbilityGroup", [
        t"Character.wraiths_prisoner_fmelee3_fists_ma_elite_inline0"
      ]);
  }

  private func InitializeMaelstormers() {
      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.maelstrom_grunt1_ranged1_copperhead_ma_inline0",
        t"Character.maelstrom_grunt1_ranged1_copperhead_wa_inline0",
        t"Character.maelstrom_grunt1_ranged1_lexington_ma_inline0",
        t"Character.maelstrom_grunt1_ranged1_lexington_wa_inline0",
        t"Character.maelstrom_fast2_fmelee2_knife_ma_rare_inline4",
        t"Character.maelstrom_fast_fmelee2_machete_ma_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.maelstrom_grunt1_melee1_knife_ma_inline4",
        t"Character.maelstrom_fast_fmelee3_mantis_wa_elite_inline10"
      ]);
  }

  private func InitializeMercs() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.afterlife_rare_franged2_ajax_ma_rare_inline4",
        t"Character.afterlife_rare_franged2_ajax_wa_rare_inline4",
        t"Character.afterlife_rare_fmelee3_katana_ma_elite_inline4",
        t"Character.afterlife_rare_fmelee3_katana_wa_elite_inline4",
        t"Character.afterlife_rare_fmelee3_mantis_ma_elite_inline0",
        t"Character.afterlife_rare_fmelee3_mantis_wa_elite_inline0",
        t"Character.afterlife_rare_sniper3_ashura_ma_elite_inline4",
        t"Character.afterlife_rare_fshotgun3_zhuo_mb_elite_inline4",
        t"Character.generic_fast_fmelee2_knife_wa_rare_inline4",
        t"Character.generic_fast_fmelee2_machete_ma_rare_inline4",
        t"Character.generic_shotgun_shotgun3_carnage_mb_elite_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.generic_shotgun_fshotgun2_palica_ma_inline4",
        t"Character.afterlife_rare_franged2_saratoga_ma_rare_inline4",
        t"Character.afterlife_rare_franged2_saratoga_wa_rare_inline4",
        t"Character.generic_gunner_gunner3_hmg_mb_elite_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.afterlife_rare_sniper3_ashura_ma_elite_inline4",
        t"Character.generic_fast_fmelee2_knife_wa_rare_inline4",
        t"Character.generic_fast_fmelee2_machete_ma_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier3AbilityGroup", [
        t"Character.afterlife_rare_fmelee3_katana_ma_elite_inline4",
        t"Character.afterlife_rare_fmelee3_katana_wa_elite_inline4",
        t"Character.afterlife_rare_fmelee3_mantis_ma_elite_inline0",
        t"Character.afterlife_rare_fmelee3_mantis_wa_elite_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier4AbilityGroup", [
        t"Character.generic_shotgun_shotgun3_carnage_mb_elite_inline4"
      ]);
  }

  private func InitializeKangTao() {

  }

  private func InitializeSecurity() {

  }

  private func InitializeTraumaTeam() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.trauma_rare_officer_chao_ma_inline0",
        t"Character.trauma_soldier_shotgun2_zhuo_ma_rare_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.trauma_soldier_shotgun2_zhuo_ma_rare_inline0"
      ]);

  }

  private func InitializeBarghest() {
      if (this.configs.enableStimPack) {
        AddAbilityTo(t"ESR_HasStimPackAbilityGroup", [
          t"Character.kurtz_grunt1_ranged1_handgun_ma_inline4",
          t"Character.kurtz_grunt1_ranged1_handgun_wa_inline4",
          t"Character.kurtz_soldier1_generic_ranged2_rifle_wa_inline4",
          t"Character.kurtz_soldier2_generic_ranged3_rifle_ma_inline4",
          t"Character.kurtz_elite3_gunner3_HMG_mb_elite_inline0",
          t"Character.kurtz_elite3_gunner3_LMG_mb_elite_inline0"
        ]);
      }

      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.kurtz_recon_sniper2_achilles_ma_rare_inline0",
        t"Character.kurtz_soldier1_generic_ranged2_rifle_wa_inline4",
        t"Character.kurtz_soldier2_generic_ranged3_rifle_ma_inline4",
        t"Character.kurtz_soldier2_shotgun3_shotgun_ma_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.kurtz_soldier2_shotgun2_shotgun_ma_rare_inline4",
        t"Character.kurtz_tech_franged2_handgun_ma_rare_inline0",
        t"Character.prevention_dogtown_shotgun_ma_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.kurtz_soldier2_shotgun3_shotgun_ma_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier3AbilityGroup", [
        t"Character.kurtz_martial_fmelee3_fists_ma_rare_inline0",
        t"Character.prevention_dogtown_martial_fmelee3_fists_ma_rare_inline5"
      ]);
  }

  private func InitializeMilitech() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.militech_recon_sniper2_achilles_ma_rare_inline0",
        t"Character.militech_soldier3_shotgun3_crusher_mah_elite_inline0",
        t"Character.militech_enforcer2_shotgun2_tactician_mah_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.militech_recon_sniper2_achilles_ma_rare_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.militech_tech_franged2_omaha_ma_rare_inline0"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier3AbilityGroup", [
        t"Character.militech_soldier3_shotgun3_crusher_mah_elite_inline0"
      ]);


      if (this.configs.enableStimPack) {
        AddAbilityTo(t"ESR_HasStimPackAbilityGroup", [
          t"Character.militech_ranger2_ranged2_omaha_ma_inline4",
          t"Character.militech_ranger2_ranged2_ajax_ma_inline4",
          t"Character.militech_ranger1_ranged1_saratoga_ma_inline0",
          t"Character.militech_ranger1_ranged1_lexington_ma_inline0"
        ]);
      }


      AddAbilitiesToCharacter(t"Character.q306_black_ops_wa", [
        t"Ability.ESR_HasKerenzikov", t"Ability.ESR_HasSandevistanTier1"
      ]);

      AddAbilitiesToCharacter(t"Character.q306_black_ops_fast_ranged", [
        t"Ability.ESR_HasKerenzikov"
      ]);

      AddAbilitiesToCharacter(t"Character.q306_black_ops_HMG", [
        t"Ability.ESR_HasSandevistanTier1"
      ]);


  }

  private func InitializeArasaka() {
      AddAbilityTo(t"ESR_HasKerenzikovAbilityGroup", [
        t"Character.arasaka_sniper_sniper3_ashura_ma_elite_inline0",
        t"Character.arasaka_sniper_sniper3_nekomata_ma_elite_inline0",
        t"Character.arasaka_ninja_fmelee3_katana_ma_elite_inline4",
        t"Character.arasaka_ninja_fmelee3_katana_wa_elite_inline4",
        t"Character.arasaka_ninja_fmelee3_mantis_ma_elite_inline0",
        t"Character.arasaka_ninja_fmelee3_mantis_wa_elite_inline0",
        t"Character.arasaka_terminator_shotgun3_zhuo_mah_elite_inline4",
        t"Character.arasaka_agent_fmelee2rare_katana_ma_rare_inline4",
        t"Character.arasaka_agent_fmelee2rare_katana_wa_rare_inline4",
        t"Character.arasaka_agent_fmelee2rare_knife_ma_rare_inline4",
        t"Character.arasaka_agent_fmelee2rare_knife_wa_rare_inline4",
        t"Character.arasaka_agent_franged2_yukimura_wa_rare_inline4",
        t"Character.arasaka_agent_fshotgun2_tactician_ma_rare_inline4",
        t"Character.arasaka_agent_fshotgun2_tactician_wa_rare_inline4",
        t"Character.arasaka_soldier2_shotgun2_tactician_mah_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier1AbilityGroup", [
        t"Character.arasaka_bodyguard_hmelee2_fists_mb_rare_inline0",
        t"Character.arasaka_cyborg_fshotgun3_zhuo_ma_elite_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier2AbilityGroup", [
        t"Character.arasaka_agent_fmelee2rare_katana_ma_rare_inline4",
        t"Character.arasaka_agent_fmelee2rare_katana_wa_rare_inline4",
        t"Character.arasaka_agent_fmelee2rare_knife_ma_rare_inline4",
        t"Character.arasaka_agent_fmelee2rare_knife_wa_rare_inline4",
        t"Character.arasaka_agent_franged2_yukimura_wa_rare_inline4",
        t"Character.arasaka_agent_fshotgun2_tactician_ma_rare_inline4",
        t"Character.arasaka_agent_fshotgun2_tactician_wa_rare_inline4",
        t"Character.arasaka_sniper_sniper3_ashura_ma_elite_inline0",
        t"Character.arasaka_sniper_sniper3_nekomata_ma_elite_inline0",
        t"Character.arasaka_soldier2_shotgun2_tactician_mah_rare_inline4"
      ]);

      AddAbilityTo(t"ESR_HasSandevistanTier3AbilityGroup", [
        t"Character.arasaka_ninja_fmelee3_katana_ma_elite_inline4",
        t"Character.arasaka_ninja_fmelee3_katana_wa_elite_inline4",
        t"Character.arasaka_ninja_fmelee3_mantis_ma_elite_inline0",
        t"Character.arasaka_ninja_fmelee3_mantis_wa_elite_inline0",
        t"Character.arasaka_terminator_shotgun3_zhuo_mah_elite_inline4"
      ]);
  }

}

public final static func AddAbilityTo(ability: TweakDBID, archetypes: array<TweakDBID>) -> Void {
  let i = 0;
  let len = ArraySize(archetypes);
  while (i < len) {
    let tab = TweakDBInterface.GetForeignKeyArray(archetypes[i] + t".abilityGroups");
    ArrayPush(tab, ability);
    TweakDBManager.SetFlat(archetypes[i] + t".abilityGroups", tab);
    TweakDBManager.UpdateRecord(archetypes[i]);

    i += 1;
  }
}

public final static func AddAbilitiesToCharacter(character: TweakDBID, abilities: array<TweakDBID>) -> Void {
  let i = 0;
  let len = ArraySize(abilities);

  let tab = TweakDBInterface.GetForeignKeyArray(character + t".abilities");

  while (i < len) {
    ArrayPush(tab, abilities[i]);

    i += 1;
  }

  TweakDBManager.SetFlat(character + t".abilities", tab);
  TweakDBManager.UpdateRecord(character);
}

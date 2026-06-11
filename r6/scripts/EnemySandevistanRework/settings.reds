module Phoenicia.EnemySandevistanRework.Configurations

public class EnemySandevistanSettings {
    public let enabled: Bool = true;
    public let replaceOGAbilities: Bool = true;
    public let enemyMinimumSvS: Float = 0.5;
    public let playerMinimumSvS: Float = 0.0;
    public let offensiveUseCD: Int32 = 10;
    public let defensiveUseCD: Int32 = 10;

    public let kerenzikovStrength: Float = 60.0;
    public let kerenzikovMatching: Bool = true;
    public let kerenzikovDuration: Float = 3.0;
    public let kerenzikovCD: Float = 12.0;

    public let mk1Strength: Float = 35.0;
    public let mk1Duration: Float = 12.0;
    public let mk1CD: Float = 24.0;

    public let mk2Strength: Float = 50.0;
    public let mk2Duration: Float = 10.0;
    public let mk2CD: Float = 30.0;

    public let mk3Strength: Float = 70.0;
    public let mk3Duration: Float = 10.0;
    public let mk3CD: Float = 30.0;

    public let mk4Strength: Float = 85.0;
    public let mk4Duration: Float = 8.0;
    public let mk4CD: Float = 16.0;

    public let mk5Strength: Float = 85.0;
    public let mk5Duration: Float = 15.0;
    public let mk5CD: Float = 15.0;

    public let enableStimPack: Bool = true;
    public let enableStimPackCustomSound: Bool = true;
    public let stimPackStrength: Float = 40.0;
    public let stimPackDuration: Float = 12.0;
    public let stimPackCooldown: Float = 12.0;
    public let stimPackHealthCost: Float = 20.0;
}

public class ESRConfig {
    public static func Enabled() -> Bool { return true; }
    public static func ReplaceOGAbilities() -> Bool { return true; }
    public static func EnemyMinimumSvS() -> Float { return 0.5; }
    public static func PlayerMinimumSvS() -> Float { return 0.0; }
    public static func OffensiveUseCD() -> Int32 { return 10; }
    public static func DefensiveUseCD() -> Int32 { return 10; }

    public static func KerenzikovStrength() -> Float { return 60.0; }
    public static func KerenzikovMatching() -> Bool { return true; }
    public static func KerenzikovDuration() -> Float { return 3.0; }
    public static func KerenzikovCD() -> Float { return 12.0; }

    public static func Mk1Strength() -> Float { return 35.0; }
    public static func Mk1Duration() -> Float { return 12.0; }
    public static func Mk1CD() -> Float { return 24.0; }

    public static func Mk2Strength() -> Float { return 50.0; }
    public static func Mk2Duration() -> Float { return 10.0; }
    public static func Mk2CD() -> Float { return 30.0; }

    public static func Mk3Strength() -> Float { return 70.0; }
    public static func Mk3Duration() -> Float { return 10.0; }
    public static func Mk3CD() -> Float { return 30.0; }

    public static func Mk4Strength() -> Float { return 85.0; }
    public static func Mk4Duration() -> Float { return 8.0; }
    public static func Mk4CD() -> Float { return 16.0; }

    public static func Mk5Strength() -> Float { return 95.0; }
    public static func Mk5Duration() -> Float { return 15.0; }
    public static func Mk5CD() -> Float { return 15.0; }

    public static func EnableStimPack() -> Bool { return true; }
    public static func EnableStimPackCustomSound() -> Bool { return true; }
    public static func StimPackStrength() -> Float { return 40.0; }
    public static func StimPackDuration() -> Float { return 12.0; }
    public static func StimPackCooldown() -> Float { return 12.0; }
    public static func StimPackHealthCost() -> Float { return 20.0; }
}

public final static func ESR_Settings() -> ref<EnemySandevistanSettings> {
    let s: ref<EnemySandevistanSettings> = new EnemySandevistanSettings();
    s.enabled = ESRConfig.Enabled();
    s.replaceOGAbilities = ESRConfig.ReplaceOGAbilities();
    s.enemyMinimumSvS = ESRConfig.EnemyMinimumSvS();
    s.playerMinimumSvS = ESRConfig.PlayerMinimumSvS();
    s.offensiveUseCD = ESRConfig.OffensiveUseCD();
    s.defensiveUseCD = ESRConfig.DefensiveUseCD();
    s.kerenzikovStrength = ESRConfig.KerenzikovStrength();
    s.kerenzikovMatching = ESRConfig.KerenzikovMatching();
    s.kerenzikovDuration = ESRConfig.KerenzikovDuration();
    s.kerenzikovCD = ESRConfig.KerenzikovCD();
    s.mk1Strength = ESRConfig.Mk1Strength();
    s.mk1Duration = ESRConfig.Mk1Duration();
    s.mk1CD = ESRConfig.Mk1CD();
    s.mk2Strength = ESRConfig.Mk2Strength();
    s.mk2Duration = ESRConfig.Mk2Duration();
    s.mk2CD = ESRConfig.Mk2CD();
    s.mk3Strength = ESRConfig.Mk3Strength();
    s.mk3Duration = ESRConfig.Mk3Duration();
    s.mk3CD = ESRConfig.Mk3CD();
    s.mk4Strength = ESRConfig.Mk4Strength();
    s.mk4Duration = ESRConfig.Mk4Duration();
    s.mk4CD = ESRConfig.Mk4CD();
    s.mk5Strength = ESRConfig.Mk5Strength();
    s.mk5Duration = ESRConfig.Mk5Duration();
    s.mk5CD = ESRConfig.Mk5CD();
    s.enableStimPack = ESRConfig.EnableStimPack();
    s.enableStimPackCustomSound = ESRConfig.EnableStimPackCustomSound();
    s.stimPackStrength = ESRConfig.StimPackStrength();
    s.stimPackDuration = ESRConfig.StimPackDuration();
    s.stimPackCooldown = ESRConfig.StimPackCooldown();
    s.stimPackHealthCost = ESRConfig.StimPackHealthCost();
    return s;
}

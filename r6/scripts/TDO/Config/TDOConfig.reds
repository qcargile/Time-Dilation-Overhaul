public class TDOConfig {

  public static func LerpTier(v1: Float, vTop: Float, tier: Int32, totalTiers: Int32) -> Float {
    if totalTiers <= 1 {
      return v1;
    }
    let t: Float = Cast<Float>(tier - 1) / Cast<Float>(totalTiers - 1);
    if t < 0.0 { t = 0.0; }
    if t > 1.0 { t = 1.0; }
    return v1 + (vTop - v1) * t;
  }


  public static func SandevistanGracePeriodSeconds() -> Float {
    return 0.10;
  }

  public static func BulletTrailVelocityEnabled() -> Bool { return true; }
  public static func BulletTrailVelocityAt10() -> Float { return 95.0; }
  public static func BulletTrailVelocityAt20() -> Float { return 85.0; }
  public static func BulletTrailVelocityAt30() -> Float { return 75.0; }
  public static func BulletTrailVelocityAt40() -> Float { return 65.0; }
  public static func BulletTrailVelocityAt50() -> Float { return 55.0; }
  public static func BulletTrailVelocityAt60() -> Float { return 45.0; }
  public static func BulletTrailVelocityAt70() -> Float { return 35.0; }
  public static func BulletTrailVelocityAt80() -> Float { return 25.0; }
  public static func BulletTrailVelocityAt90() -> Float { return 15.0; }
  public static func BulletTrailVelocityAt99() -> Float { return 5.0; }

  
  public static func FusilladeFireRateRealTimeEnabled() -> Bool {
    return true;
  }

  
  public static func FusilladeAmmoRefillEnabled() -> Bool {
    return true;
  }

  public static func FusilladeAmmoRefillPerReflexes() -> Float {
    return 2.5;
  }

  public static func FusilladeAmmoRefillMaxChancePct() -> Float {
    return 50.0;
  }

  
  public static func QuantumMaxCharges() -> Int32 {
    return 2;
  }

  public static func QuantumCooldownMin() -> Float {
    return 7.0;
  }

  public static func QuantumCooldownMax() -> Float {
    return 15.0;
  }

  public static func QuantumDurationMin() -> Float { return 2.0; }
  public static func QuantumDurationMax() -> Float { return 5.0; }

  
  public static func DOTEnabled() -> Bool {
    return true;
  }

  public static func DOTBaseRatePct() -> Float {
    return 1.0;
  }

  public static func DOTSlowThresholdPct() -> Float {
    return 40.0;
  }

  public static func DOTSlowRangeMinPct() -> Float {
    return 10.0;
  }

  public static func DOTSlowRangeMaxPct() -> Float {
    return 90.0;
  }

  public static func DOTTickMinInterval() -> Float {
    return 0.5;
  }

  public static func DOTTickMaxInterval() -> Float {
    return 1.5;
  }

  public static func DOTMitigationCap() -> Float {
    return 0.75;
  }

  public static func DOTMitigationRefStatCap() -> Float {
    return 15.0;
  }

  public static func DOTCanKill() -> Bool {
    return true;
  }

  public static func DOTCurveType() -> Int32 {
    return 0; // 0=Linear, 1=Squared, 2=InverseSquared
  }

  
  public static func KurosawaEnabled() -> Bool {
    return true;
  }

  public static func KurosawaAttunementPerPointPct() -> Float {
    return 0.75;
  }

  public static func KurosawaAttunementPerAttrCapPct() -> Float {
    return 15.0;
  }


  public static func KurosawaIndividualSlowMult() -> Float {
    return 0.1;
  }

  public static func KurosawaSlowDuration() -> Float {
    return 60.0;
  }

  public static func KurosawaPOPDelay() -> Float {
    return 1.0;
  }

  public static func KurosawaPOPRefundBase() -> Float {
    return 1.0;
  }

  public static func KurosawaPOPRefundAttunementBonus() -> Float {
    return 1.0;
  }

  public static func KurosawaPOPHealPctBase() -> Float {
    return 5.0;
  }

  public static func KurosawaPOPHealPctPlus() -> Float {
    return 10.0;
  }


  public static func ApogeeEnabled() -> Bool {
    return false;
  }

  public static func ApogeeStrainMultiplierCap() -> Float {
    return 8.0;
  }

  public static func ApogeeSlowTimeMinPct() -> Float {
    return 85.0;
  }

  public static func ApogeeSlowTimeMaxPct() -> Float {
    return 90.0;
  }

  public static func ApogeeDurationMin() -> Float {
    return 6.0;
  }

  public static func ApogeeDurationMax() -> Float {
    return 10.0;
  }

  public static func ApogeeRechargeMin() -> Float {
    return 30.0;
  }

  public static func ApogeeRechargeMax() -> Float {
    return 20.0;
  }

  public static func SandyVFXEnabled() -> Bool {
    return false;
  }

  public static func SandyVFXUseVanilla() -> Bool {
    return false;
  }

  
  public static func TantoEnabled() -> Bool {
    return true;
  }

  public static func TantoTeleportBaseRange() -> Float {
    return 20.0;
  }

  public static func TantoTeleportRangePerReflexes() -> Float {
    return 1.0;
  }

  public static func TantoTeleportMaxRange() -> Float {
    return 40.0;
  }

  public static func TantoTeleportBehindOffset() -> Float {
    return 1.5;
  }

  public static func TantoSlowTimeMinPct() -> Float {
    return 60.0;
  }

  public static func TantoSlowTimeMaxPct() -> Float {
    return 60.0;
  }

  public static func TantoDurationMin() -> Float {
    return 10.0;
  }

  public static func TantoDurationMax() -> Float {
    return 15.0;
  }

  public static func TantoRechargeMin() -> Float {
    return 50.0;
  }

  public static func TantoRechargeMax() -> Float {
    return 25.0;
  }

  public static func TantoCritChanceMin() -> Float {
    return 5.0;
  }

  public static func TantoCritChanceMax() -> Float {
    return 15.0;
  }

  public static func TantoCritDmgMin() -> Float {
    return 10.0;
  }

  public static func TantoCritDmgMax() -> Float {
    return 50.0;
  }

  
  public static func ShrikeEnabled() -> Bool {
    return true;
  }

  public static func ShrikeHoverTime() -> Float {
    return 0.0;
  }

  public static func ShrikeUnmarkHoverTime() -> Float {
    return 1.0; // wall-clock seconds to confirm unmark
  }

  public static func ShrikeRemarkCooldown() -> Float {
    return 5.0; // wall-clock seconds before a just-unmarked target is taggable again
  }

  public static func ShrikeMarkRange() -> Float {
    return 30.0;
  }

  public static func ShrikeSlowTimeMinPct() -> Float {
    return 30.0;
  }

  public static func ShrikeSlowTimeMaxPct() -> Float {
    return 60.0;
  }

  public static func ShrikeDurationMin() -> Float {
    return 5.0;
  }

  public static func ShrikeDurationMax() -> Float {
    return 10.0;
  }

  public static func ShrikeRechargeMin() -> Float {
    return 30.0;
  }

  public static func ShrikeRechargeMax() -> Float {
    return 15.0;
  }

  public static func ShrikeExecuteDmgTrash() -> Float {
    return 100.0;
  }

  public static func ShrikeExecuteDmgWeak() -> Float {
    return 100.0;
  }

  public static func ShrikeExecuteDmgNormal() -> Float {
    return 100.0;
  }

  public static func ShrikeExecuteDmgRare() -> Float {
    return 95.0;
  }

  public static func ShrikeExecuteDmgOfficer() -> Float {
    return 90.0;
  }

  public static func ShrikeExecuteDmgElite() -> Float {
    return 75.0;
  }

  public static func ShrikeExecuteDmgMaxTac() -> Float {
    return 15.0;
  }

  public static func ShrikeExecuteDmgBoss() -> Float {
    return 15.0;
  }

  
  public static func FalconEnabled() -> Bool {
    return true;
  }

  
  public static func FalconPhaseRoundEnabled() -> Bool {
    return true;
  }

  public static func FalconPhaseRoundLineRadius() -> Float {
    return 2.0;
  }

  public static func FalconPhaseRoundSelfDamagePercent() -> Float {
    return 0.10;
  }

  public static func FalconBoltEMPDamage_T1() -> Float {
    return 200.0;
  }

  public static func FalconBoltEMPDamage_T2() -> Float {
    return 400.0;
  }

  public static func FalconBoltEMPDamage_T3() -> Float {
    return 600.0;
  }

  public static func FalconBoltEMPDamage_T4() -> Float {
    return 800.0;
  }

  public static func FalconBoltEMPDamage_T5() -> Float {
    return 1000.0;
  }

  
  public static func FalconTrickShotEnabled() -> Bool {
    return true;
  }

  public static func FalconTrickShotBlockReload() -> Bool {
    return true;
  }

  
  public static func FalconSaturationLockEnabled() -> Bool {
    return true;
  }

  public static func FalconSaturationLockMinTargets() -> Int32 {
    return 3;
  }

  public static func FalconSaturationLockRange() -> Float {
    return 60.0;
  }

  public static func FalconSaturationLockStagger() -> Float {
    return 0.02;
  }

  public static func FalconSaturationLockEMPSecondsPerShot() -> Float {
    return 0.5;
  }

  public static func FalconSlowTimeMinPct() -> Float {
    return 40.0;
  }

  public static func FalconSlowTimeMaxPct() -> Float {
    return 40.0;
  }

  public static func FalconDurationMin() -> Float {
    return 12.0;
  }

  public static func FalconDurationMax() -> Float {
    return 16.0;
  }

  public static func FalconRechargeMin() -> Float {
    return 45.0;
  }

  public static func FalconRechargeMax() -> Float {
    return 30.0;
  }

  public static func FalconCritChanceMin() -> Float {
    return 5.0;
  }

  public static func FalconCritChanceMax() -> Float {
    return 15.0;
  }

  public static func FalconCritDmgMin() -> Float {
    return 10.0;
  }

  public static func FalconCritDmgMax() -> Float {
    return 50.0;
  }

  
  public static func WarpDancerEnabled() -> Bool {
    return true;
  }

  public static func WarpDancerDilationStrength() -> Float {
    return 0.01;
  }

  public static func WarpDancerRecordIntervalSec() -> Float {
    return 0.033;
  }

  public static func WarpDancerRewindIntervalSec() -> Float {
    return 0.020;
  }

  public static func WarpDancerRewindDurationSec() -> Float {
    return 3.0;
  }

  public static func WarpDancerPostRewindPauseSec() -> Float {
    return 1.0;
  }

  public static func WarpDancerStaggerDurationMinSec() -> Float {
    return 0.3;
  }

  public static func WarpDancerStaggerDurationMaxSec() -> Float {
    return 2.0;
  }

  public static func WarpDancerSlowTimeMinPct() -> Float {
    return 99.0;
  }

  public static func WarpDancerSlowTimeMaxPct() -> Float {
    return 99.0;
  }

  public static func WarpDancerDurationMin() -> Float {
    return 5.0;
  }

  public static func WarpDancerDurationMax() -> Float {
    return 9.0;
  }

  public static func WarpDancerRechargeMin() -> Float {
    return 80.0;
  }

  public static func WarpDancerRechargeMax() -> Float {
    return 45.0;
  }

  public static func WarpDancerMoveSpeedMin() -> Float {
    return 5.0;
  }

  public static func WarpDancerMoveSpeedMax() -> Float {
    return 20.0;
  }

  public static func WarpDancerRewindGlitchEnabled() -> Bool {
    return true;
  }

  
  public static func SogimsuEnabled() -> Bool {
    return true;
  }

  public static func SogimsuDurationMin() -> Float {
    return 15.0;
  }

  public static func SogimsuDurationMax() -> Float {
    return 40.0;
  }

  public static func SogimsuInterventionsMin() -> Float {
    return 3.0;
  }

  public static func SogimsuInterventionsMax() -> Float {
    return 7.0;
  }

  public static func SogimsuDetectionDecreaseMin() -> Float {
    return 20.0;
  }

  public static func SogimsuDetectionDecreaseMax() -> Float {
    return 100.0;
  }

  public static func SogimsuStealthHitDamageMin() -> Float {
    return 10.0;
  }

  public static func SogimsuStealthHitDamageMax() -> Float {
    return 60.0;
  }

  public static func SogimsuWatchdogCamoBase() -> Float {
    return 5.0;
  }

  public static func SogimsuWatchdogDetectionThreshold() -> Float {
    return 0.5;
  }

  public static func SogimsuWatchdogRadius() -> Float {
    return 30.0;
  }

  public static func SogimsuWatchdogTickInterval() -> Float {
    return 0.1;
  }

  
  public static func JuggernautEnabled() -> Bool {
    return true;
  }

  public static func JuggernautLockDurationMin() -> Float {
    return 4.0;
  }

  public static func JuggernautLockDurationMax() -> Float {
    return 12.0;
  }

  public static func JuggernautRadiusMin() -> Float {
    return 15.0;
  }

  public static func JuggernautRadiusMax() -> Float {
    return 35.0;
  }

  public static func JuggernautDamageMultMin() -> Float {
    return 1.5;
  }

  public static func JuggernautDamageMultMax() -> Float {
    return 2.5;
  }

  public static func JuggernautMaxBurstDamage() -> Float {
    return 5000.0;
  }

  
  public static func PyrolithEnabled() -> Bool {
    return true;
  }

  public static func PyrolithDurationMin() -> Float {
    return 10.0;
  }

  public static func PyrolithDurationMax() -> Float {
    return 20.0;
  }

  public static func PyrolithExplosionDamageMin() -> Float {
    return 25.0;
  }

  public static func PyrolithExplosionDamageMax() -> Float {
    return 125.0;
  }

  public static func PyrolithBulletExplosionRadius_T1() -> Float {
    return 2.0;
  }

  public static func PyrolithBulletExplosionRadius_T2() -> Float {
    return 3.0;
  }

  public static func PyrolithBulletExplosionRadius_T3() -> Float {
    return 4.0;
  }

  public static func PyrolithBulletExplosionRadius_T4() -> Float {
    return 5.0;
  }

  public static func PyrolithBulletExplosionRadius_T5() -> Float {
    return 6.0;
  }

  public static func PyrolithClusterCountMin() -> Float {
    return 1.0;
  }

  public static func PyrolithClusterCountMax() -> Float {
    return 3.0;
  }

  public static func PyrolithClusterDamageScalar_T1() -> Float {
    return 0.15;
  }

  public static func PyrolithClusterDamageScalar_T2() -> Float {
    return 0.20;
  }

  public static func PyrolithClusterDamageScalar_T3() -> Float {
    return 0.25;
  }

  public static func PyrolithClusterDamageScalar_T4() -> Float {
    return 0.25;
  }

  public static func PyrolithClusterDamageScalar_T5() -> Float {
    return 0.25;
  }

  public static func PyrolithThrowVelocityMultiplier_T1() -> Float {
    return 1.5;
  }

  public static func PyrolithThrowVelocityMultiplier_T2() -> Float {
    return 1.75;
  }

  public static func PyrolithThrowVelocityMultiplier_T3() -> Float {
    return 2.0;
  }

  public static func PyrolithThrowVelocityMultiplier_T4() -> Float {
    return 2.0;
  }

  public static func PyrolithThrowVelocityMultiplier_T5() -> Float {
    return 2.0;
  }


  public static func ScanningEnabled() -> Bool {
    return true;
  }

  public static func ScanningTickInterval() -> Float {
    return 0.1;
  }

  public static func ScanningDrainPerSec() -> Float {
    return 0.10;
  }

  public static func ScanningRechargePerSec() -> Float {
    return 0.15;
  }

  public static func ScanningStrengthAtMinInt() -> Float {
    return 0.50;
  }

  public static func ScanningStrengthAtMaxInt() -> Float {
    return 0.05;
  }

  public static func ScanningBarWidth() -> Float {
    return 320.0;
  }

  public static func ScanningBarHeight() -> Float {
    return 16.0;
  }

  public static func ScanningBarPosX() -> Float {
    return 1820.0;
  }

  public static func ScanningBarPosY() -> Float {
    return 1740.0;
  }

  public static func ScanningIntScaleMax() -> Float {
    return 2.0;
  }

  public static func ScanningGracePeriodSec() -> Float {
    return 1.0;
  }

  public static func HerbieEnabled() -> Bool {
    return true;
  }

  public static func EnableDebugLog() -> Bool {
    return false;
  }

  public static func DebugLogLevel() -> Int32 {
    return 2;
  }

  public static func HerbieTickInterval() -> Float {
    return 0.025; // 40Hz sampling; impulses auto-scale via dtScale = tickInterval/0.05
  }

  public static func HerbieWorldScaleUncommon() -> Float {
    return 0.80; // world time scale, Uncommon Sandy
  }

  public static func HerbieWorldScaleRare() -> Float {
    return 0.70;
  }

  public static func HerbieWorldScaleEpic() -> Float {
    return 0.60;
  }

  public static func HerbieWorldScaleLegendary() -> Float {
    return 0.50;
  }

  public static func HerbieGripForce() -> Float {
    return 0.20; // P-gain on lateral velocity error (kills drift)
  }

  public static func HerbieMaxImpulse() -> Float {
    return 1000.0; // bike-side per-impulse cap (cars use hardcoded 5000 in ApplyImpulses)
  }

  public static func HerbieDownforce() -> Float {
    return 0.20; // optional supplemental plant, range 0-1
  }

  public static func HerbieBikeYaw() -> Float {
    return 0.2; // motorcycle steer-gated yaw-couple strength
  }

  public static func HerbieBikeGrip() -> Float {
    return 1.0; // motorcycle lateral-slip grip while steering
  }

  public static func HerbieCarYaw() -> Float {
    return 0.4; // car steer-gated yaw-couple strength
  }

  public static func HerbieTraction() -> Float {
    return 4.0; // forward momentum preservation during turns; restoration rate cap 2.0 × traction m/s/sec
  }


  public static func QuantumTeleportEnabled() -> Bool {
    return true;
  }

  public static func QuantumPlotFreezeStrength() -> Float {
    return 0.001; // world time scale during plot freeze (~99.9% slow)
  }

  public static func QuantumPlayerSlowTimePct() -> Float {
    return 99.0;
  }

  public static func QuantumMalwareSlowTimePct() -> Float {
    return 99.0;
  }

  public static func QuantumTeleportMaxRange() -> Float {
    return 50.0; // teleport range cap, meters
  }

  public static func QuantumTeleportRangeMin() -> Float {
    return 5.0;
  }

  public static func QuantumTeleportRangeMax() -> Float {
    return 10.0;
  }

  public static func QuantumTeleportRangePerCool() -> Float {
    return 1.75; // added teleport range per Cool point, meters
  }

  public static func QuantumPlotTickInterval() -> Float {
    return 0.05; // marker reposition tick, real-time seconds
  }

  public static func QuantumMarkerLift() -> Float {
    return 0.1; // teleport landing lift off hit surface, meters
  }

  public static func QuantumTeleportGroundSearchBudget() -> Float {
    return 3.0; // downward floor search budget, meters
  }

  public static func QuantumTeleportGroundSearchStartLift() -> Float {
    return 0.5; // start downward raycast above raw aim point, meters
  }

  public static func QuantumTeleportCapsuleWidth() -> Float {
    return 0.5; // player capsule width for overlap check, meters
  }

  public static func QuantumTeleportCapsuleHeight() -> Float {
    return 1.9; // player capsule height for overlap check, meters
  }

  public static func QuantumTeleportCapsuleClearance() -> Float {
    return 0.1; // foot-to-box-bottom gap during overlap check, meters
  }

  public static func QuantumTeleportNavmeshSnapRadius() -> Float {
    return 0.5; // navmesh point search radius, meters
  }

  public static func QuantumTeleportFloorNormalMinZ() -> Float {
    return 0.7; // floor normal Z minimum, rejects walls and steep slopes
  }

  public static func QuantumTeleportFallbackNearOffset() -> Float {
    return 0.5; // first fallback search offset, meters
  }

  public static func QuantumTeleportFallbackFarOffset() -> Float {
    return 1.0; // second fallback search offset, meters
  }

  public static func QuantumLandingStimEnabled() -> Bool {
    return true;
  }

  public static func QuantumLandingStimRadius() -> Float {
    return 20.0; // bump stim radius on landing, meters
  }

  public static func UIHideAll() -> Bool {
    return false;
  }

  public static func UIHideScanBar() -> Bool {
    return false;
  }

  public static func UIHideQuantumMarker() -> Bool {
    return false;
  }

  public static func UIShouldHideScanBar() -> Bool {
    return TDOConfig.UIHideAll() || TDOConfig.UIHideScanBar();
  }

  public static func UIShouldHideQuantumMarker() -> Bool {
    return TDOConfig.UIHideAll() || TDOConfig.UIHideQuantumMarker();
  }


  public static func QuantumMalwareEnabled() -> Bool {
    return true;
  }

  public static func QuantumMalwareRadiusBase() -> Float {
    return 2.0; // malware radius at 0 Cool, meters
  }

  public static func QuantumMalwareRadiusPerCool() -> Float {
    return 0.4; // added malware radius per Cool point, meters
  }

  public static func QuantumMalwareRadiusCap() -> Float {
    return 10.0; // max malware radius, meters
  }

  public static func QuantumMalwareTargetsMin() -> Float {
    return 2.0;
  }

  public static func QuantumMalwareTargetsMax() -> Float {
    return 5.0;
  }

  public static func QuantumMalwareStrength() -> Float {
    return 0.01; // enemy individual time scale (0.01 = enemies frozen, ~99% slow)
  }

  public static func QuantumMalwareFreezeDurMin() -> Float {
    return 1.5;
  }

  public static func QuantumMalwareFreezeDurMax() -> Float {
    return 3.0;
  }

  public static func QuantumMalwareCoolPerPoint() -> Float {
    return 0.075; // added duration seconds per Cool point (reaches +1.5s at Cool 20)
  }

  public static func QuantumMalwareDurationCap() -> Float {
    return 3.0; // max enemy slow duration, seconds
  }

  public static func JuggernautCooldownMin() -> Float { return 35.0; }
  public static func JuggernautCooldownMax() -> Float { return 60.0; }

  public static func SogimsuCooldownMin() -> Float { return 30.0; }
  public static func SogimsuCooldownMax() -> Float { return 60.0; }

  public static func PyrolithCooldownMin() -> Float { return 35.0; }
  public static func PyrolithCooldownMax() -> Float { return 60.0; }

  public static func FusilladeTimeScale() -> Float { return 0.25; }
  public static func FusilladeDurationMin() -> Float { return 2.0; }
  public static func FusilladeDurationMax() -> Float { return 2.5; }
  public static func FusilladeCooldownMin() -> Float { return 10.0; }
  public static func FusilladeCooldownMax() -> Float { return 15.0; }
  public static func FusilladeFireRateMult() -> Float { return 2.5; }
  public static func FusilladeRampStartMin() -> Float { return 0.20; }
  public static func FusilladeRampStartMax() -> Float { return 0.25; }
  public static func FusilladeRampStep() -> Float { return 0.25; }
  public static func FusilladeRecoilAmount() -> Float { return 0.5; }
  public static func KurosawaDuration() -> Float { return 8.0; }
  public static func KurosawaRecharge() -> Float { return 35.0; }
  public static func KurosawaDamageReductionMin() -> Float { return 15.0; }
  public static func KurosawaDamageReductionMax() -> Float { return 20.0; }
}

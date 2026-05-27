module TDO.Vehicle

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoHerbieActive: Bool;

@addField(PlayerPuppet)
public let m_tdoHerbieTDMod: ref<gameStatModifierData>;

@addField(PlayerPuppet)
public let m_tdoHerbieTickScheduled: Bool;

@addField(PlayerPuppet)
public let m_tdoHerbieDiagN: Int32;

@addField(PlayerPuppet)
public let m_tdoHerbieSteer: Float;

@addField(PlayerPuppet)
public let m_tdoHerbiePrevLat: Float;

@addField(PlayerPuppet)
public let m_tdoHerbieRadioWasOn: Bool;

@addField(PlayerPuppet)
public let m_tdoHerbieRadioVehicle: wref<VehicleObject>;

public func TDO_Herbie_IsRealSandy(player: ref<PlayerPuppet>) -> Bool {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
  if !stats.GetStatBoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.HasSandevistan) {
    return false;
  }
  if player.TDO_Sogimsu_GetEquippedTier() > 0 {
    return false;
  }
  if player.TDO_Juggernaut_GetEquippedTier() > 0 {
    return false;
  }
  if player.TDO_Pyrolith_GetEquippedTier() > 0 {
    return false;
  }
  return true;
}

public func TDO_Herbie_IsSandyActive(player: ref<PlayerPuppet>) -> Bool {
  let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(bb) {
    return false;
  }
  let td: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.TimeDilation);
  return td == EnumInt(gamePSMTimeDilation.Sandevistan);
}

public func TDO_Herbie_GetDriverVehicle(player: ref<PlayerPuppet>, gi: GameInstance) -> wref<VehicleObject> {
  let vehicle: wref<VehicleObject>;
  if !VehicleComponent.GetVehicle(gi, player, vehicle) {
    return null;
  }
  if !IsDefined(vehicle) || !vehicle.IsPlayerDriver() {
    return null;
  }
  return vehicle;
}

public func TDO_Herbie_GetSandyQuality(player: ref<PlayerPuppet>) -> gamedataQuality {
  let es: ref<EquipmentSystem> = EquipmentSystem.GetInstance(player);
  if !IsDefined(es) {
    return gamedataQuality.Invalid;
  }
  let pd: ref<EquipmentSystemPlayerData> = es.GetPlayerData(player);
  if !IsDefined(pd) {
    return gamedataQuality.Invalid;
  }
  let slotIdx: Int32 = 0;
  while slotIdx < 3 {
    let itemID: ItemID = pd.GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, slotIdx);
    if ItemID.IsValid(itemID) {
      let itemData: wref<gameItemData> = RPGManager.GetItemData(player.GetGame(), player, itemID);
      if IsDefined(itemData) {
        return RPGManager.GetItemDataQuality(itemData);
      }
    }
    slotIdx += 1;
  }
  return gamedataQuality.Invalid;
}

public func TDO_Herbie_GetWorldScale(player: ref<PlayerPuppet>) -> Float {
  let q: gamedataQuality = TDO_Herbie_GetSandyQuality(player);
  switch q {
    case gamedataQuality.Common: return TDOConfig.HerbieWorldScaleUncommon();
    case gamedataQuality.CommonPlus: return TDOConfig.HerbieWorldScaleUncommon();
    case gamedataQuality.Uncommon: return TDOConfig.HerbieWorldScaleUncommon();
    case gamedataQuality.UncommonPlus: return TDOConfig.HerbieWorldScaleUncommon();
    case gamedataQuality.Rare: return TDOConfig.HerbieWorldScaleRare();
    case gamedataQuality.RarePlus: return TDOConfig.HerbieWorldScaleRare();
    case gamedataQuality.Epic: return TDOConfig.HerbieWorldScaleEpic();
    case gamedataQuality.EpicPlus: return TDOConfig.HerbieWorldScaleEpic();
    case gamedataQuality.Legendary: return TDOConfig.HerbieWorldScaleLegendary();
    case gamedataQuality.LegendaryPlus: return TDOConfig.HerbieWorldScaleLegendary();
    case gamedataQuality.LegendaryPlusPlus: return TDOConfig.HerbieWorldScaleLegendary();
    case gamedataQuality.Iconic: return TDOConfig.HerbieWorldScaleRare();
  }
  return TDOConfig.HerbieWorldScaleUncommon();
}

public func TDO_Herbie_Engage(player: ref<PlayerPuppet>, gi: GameInstance, vehicle: wref<VehicleObject>) -> Void {
  let target: Float = TDO_Herbie_GetWorldScale(player);
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
  let objID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
  let current: Float = stats.GetStatValue(objID, gamedataStatType.TimeDilationSandevistanTimeScale);
  let delta: Float = target - current;
  let mod: ref<gameStatModifierData> = RPGManager.CreateStatModifier(gamedataStatType.TimeDilationSandevistanTimeScale, gameStatModifierType.Additive, delta);
  stats.AddModifier(objID, mod);
  player.m_tdoHerbieTDMod = mod;
  GameInstance.GetTimeSystem(gi).SetTimeDilationOnLocalPlayerZero(TimeDilationHelper.GetSandevistanKey(), 1.0, 999.0, n"", n"");
  player.m_tdoHerbieActive = true;
  let radioVeh: wref<VehicleObject> = vehicle;
  player.m_tdoHerbieRadioVehicle = radioVeh;
  player.m_tdoHerbieRadioWasOn = false;
  if IsDefined(radioVeh) && radioVeh.IsRadioReceiverActive() {
    player.m_tdoHerbieRadioWasOn = true;
    radioVeh.ToggleRadioReceiver(false);
  }
  TDOInfo("HerbieEngage", "engage worldScale=" + FloatToStringPrec(target, 3) + " radioMuted=" + ToString(player.m_tdoHerbieRadioWasOn));
}

public func TDO_Herbie_Disengage(player: ref<PlayerPuppet>, gi: GameInstance) -> Void {
  if IsDefined(player.m_tdoHerbieTDMod) {
    GameInstance.GetStatsSystem(gi).RemoveModifier(Cast<StatsObjectID>(player.GetEntityID()), player.m_tdoHerbieTDMod);
    player.m_tdoHerbieTDMod = null;
  }
  GameInstance.GetTimeSystem(gi).UnsetTimeDilationOnLocalPlayerZero(TimeDilationHelper.GetSandevistanKey(), n"");
  if player.m_tdoHerbieRadioWasOn {
    let radioVeh: wref<VehicleObject> = player.m_tdoHerbieRadioVehicle;
    if IsDefined(radioVeh) {
      radioVeh.ToggleRadioReceiver(true);
    }
  }
  player.m_tdoHerbieRadioWasOn = false;
  player.m_tdoHerbieRadioVehicle = null;
  player.m_tdoHerbiePrevLat = 0.0;
  player.m_tdoHerbieActive = false;
  TDOInfo("HerbieDisengage", "disengage");
}

public func TDO_Herbie_ApplyBikeYaw(player: ref<PlayerPuppet>, vehicle: wref<VehicleObject>) -> Void {
  let steer: Float = ClampF(player.m_tdoHerbieSteer, -1.0, 1.0);
  if AbsF(steer) < 0.05 {
    return;
  }
  let vel: Vector4 = vehicle.GetLinearVelocity();
  let spd: Float = SqrtF(vel.X * vel.X + vel.Y * vel.Y + vel.Z * vel.Z);
  if spd < 2.0 {
    return;
  }
  let fwd: Vector4 = vehicle.GetWorldForward();
  let rgt: Vector4 = vehicle.GetWorldRight();
  let mass: Float = vehicle.GetTotalMass();
  let pos: Vector4 = vehicle.GetWorldPosition();
  let spdFactor: Float = ClampF(spd / 20.0, 0.0, 1.0);
  let mag: Float = TDOConfig.HerbieBikeYaw() * mass * spdFactor * steer;
  let cap: Float = TDOConfig.HerbieMaxImpulse();
  if mag > cap {
    mag = cap;
  }
  if mag < -cap {
    mag = -cap;
  }
  let d: Float = 1.0;
  let evF: ref<PhysicalImpulseEvent> = new PhysicalImpulseEvent();
  evF.worldPosition.X = pos.X + fwd.X * d;
  evF.worldPosition.Y = pos.Y + fwd.Y * d;
  evF.worldPosition.Z = pos.Z + fwd.Z * d;
  evF.worldImpulse.X = rgt.X * mag;
  evF.worldImpulse.Y = rgt.Y * mag;
  evF.worldImpulse.Z = rgt.Z * mag;
  vehicle.QueueEvent(evF);
  let evR: ref<PhysicalImpulseEvent> = new PhysicalImpulseEvent();
  evR.worldPosition.X = pos.X - fwd.X * d;
  evR.worldPosition.Y = pos.Y - fwd.Y * d;
  evR.worldPosition.Z = pos.Z - fwd.Z * d;
  evR.worldImpulse.X = rgt.X * -mag;
  evR.worldImpulse.Y = rgt.Y * -mag;
  evR.worldImpulse.Z = rgt.Z * -mag;
  vehicle.QueueEvent(evR);
  let latSlip: Float = vel.X * rgt.X + vel.Y * rgt.Y + vel.Z * rgt.Z;
  let gripMag: Float = -latSlip * mass * TDOConfig.HerbieBikeGrip();
  if gripMag > cap {
    gripMag = cap;
  }
  if gripMag < -cap {
    gripMag = -cap;
  }
  let evG: ref<PhysicalImpulseEvent> = new PhysicalImpulseEvent();
  evG.worldPosition.X = pos.X;
  evG.worldPosition.Y = pos.Y;
  evG.worldPosition.Z = pos.Z;
  evG.worldImpulse.X = rgt.X * gripMag;
  evG.worldImpulse.Y = rgt.Y * gripMag;
  evG.worldImpulse.Z = rgt.Z * gripMag;
  vehicle.QueueEvent(evG);
}

public func TDO_Herbie_ApplyImpulses(player: ref<PlayerPuppet>, vehicle: wref<VehicleObject>) -> Void {
  if IsDefined(vehicle as BikeObject) {
    TDO_Herbie_ApplyBikeYaw(player, vehicle);
    return;
  }
  let kp: Float = TDOConfig.HerbieGripForce();
  let kd: Float = TDOConfig.HerbieDamping();
  let lead: Float = TDOConfig.HerbieSteerLead();
  let vel: Vector4 = vehicle.GetLinearVelocity();
  let fwd: Vector4 = vehicle.GetWorldForward();
  let rgt: Vector4 = vehicle.GetWorldRight();
  let mass: Float = vehicle.GetTotalMass();
  let pos: Vector4 = vehicle.GetWorldPosition();
  let spd: Float = SqrtF(vel.X * vel.X + vel.Y * vel.Y + vel.Z * vel.Z);
  let steer: Float = ClampF(player.m_tdoHerbieSteer, -1.0, 1.0);
  let tgX: Float = fwd.X + rgt.X * steer * lead;
  let tgY: Float = fwd.Y + rgt.Y * steer * lead;
  let tgZ: Float = fwd.Z + rgt.Z * steer * lead;
  let tlen: Float = SqrtF(tgX * tgX + tgY * tgY + tgZ * tgZ);
  if tlen < 0.001 {
    tgX = fwd.X; tgY = fwd.Y; tgZ = fwd.Z; tlen = 1.0;
  }
  let errX: Float = tgX / tlen * spd - vel.X;
  let errY: Float = tgY / tlen * spd - vel.Y;
  let errZ: Float = tgZ / tlen * spd - vel.Z;
  let errMag: Float = SqrtF(errX * errX + errY * errY + errZ * errZ);
  let pGain: Float = 0.0;
  if errMag >= TDOConfig.HerbieSlipThreshold() {
    pGain = kp;
  }
  let latS: Float = vel.X * rgt.X + vel.Y * rgt.Y + vel.Z * rgt.Z;
  let dLat: Float = (latS - player.m_tdoHerbiePrevLat) / TDOConfig.HerbieTickInterval();
  player.m_tdoHerbiePrevLat = latS;
  let dTerm: Float = dLat * mass * kd;
  let cx: Float = errX * mass * pGain - rgt.X * dTerm;
  let cy: Float = errY * mass * pGain - rgt.Y * dTerm;
  let cz: Float = errZ * mass * pGain - rgt.Z * dTerm;
  let cmag: Float = SqrtF(cx * cx + cy * cy + cz * cz);
  let cap: Float = TDOConfig.HerbieMaxImpulse();
  if cmag > cap && cmag > 0.001 {
    let s: Float = cap / cmag;
    cx = cx * s; cy = cy * s; cz = cz * s;
  }
  let dn: Float = mass * TDOConfig.HerbieDownforce();
  let ev: ref<PhysicalImpulseEvent> = new PhysicalImpulseEvent();
  ev.worldPosition.X = pos.X;
  ev.worldPosition.Y = pos.Y;
  ev.worldPosition.Z = pos.Z;
  ev.worldImpulse.X = cx;
  ev.worldImpulse.Y = cy;
  ev.worldImpulse.Z = cz - dn;
  vehicle.QueueEvent(ev);
  player.m_tdoHerbieDiagN += 1;
  if player.m_tdoHerbieDiagN % 60 == 1 {
    TDOTrace("HerbiePID", "kp=" + FloatToStringPrec(kp, 2) + " kd=" + FloatToStringPrec(kd, 2) + " steer=" + FloatToStringPrec(steer, 2) + " spd=" + FloatToStringPrec(spd, 1) + " err=" + FloatToStringPrec(errMag, 2) + " dLat=" + FloatToStringPrec(dLat, 2) + " corr=" + FloatToStringPrec(cmag, 0));
  }
}

@addMethod(PlayerPuppet)
public func TDO_Herbie_SetSteer(v: Float) -> Void {
  this.m_tdoHerbieSteer = v;
}

public class TDO_HerbieTick extends DelayCallback {

  public let m_player: ref<PlayerPuppet>;

  public func Call() -> Void {
    let player: ref<PlayerPuppet> = this.m_player;
    if !IsDefined(player) {
      return;
    }
    let gi: GameInstance = player.GetGame();

    let enabled: Bool = TDOConfig.HerbieEnabled();
    let vehicle: wref<VehicleObject> = TDO_Herbie_GetDriverVehicle(player, gi);
    let eligible: Bool = enabled && IsDefined(vehicle) && TDO_Herbie_IsSandyActive(player) && TDO_Herbie_IsRealSandy(player);

    if eligible && !player.m_tdoHerbieActive {
      TDO_Herbie_Engage(player, gi, vehicle);
    }
    if !eligible && player.m_tdoHerbieActive {
      TDO_Herbie_Disengage(player, gi);
    }
    if player.m_tdoHerbieActive && IsDefined(vehicle) {
      TDO_Herbie_ApplyImpulses(player, vehicle);
    }

    let next: ref<TDO_HerbieTick> = new TDO_HerbieTick();
    next.m_player = player;
    GameInstance.GetDelaySystem(gi).DelayCallback(next, TDOConfig.HerbieTickInterval(), false);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  wrappedMethod();
  this.m_tdoHerbieActive = false;
  this.m_tdoHerbieTDMod = null;
  this.m_tdoHerbieRadioWasOn = false;
  this.m_tdoHerbieRadioVehicle = null;
  if !this.m_tdoHerbieTickScheduled {
    this.m_tdoHerbieTickScheduled = true;
    let tick: ref<TDO_HerbieTick> = new TDO_HerbieTick();
    tick.m_player = this;
    GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(tick, TDOConfig.HerbieTickInterval(), false);
  }
}

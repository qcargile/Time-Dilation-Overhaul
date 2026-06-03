module TDO.Debug

import TDO.Logging.*

@addField(PlayerPuppet)
public let m_tdoDbgSandyStartReal: Float;

@addField(PlayerPuppet)
public let m_tdoDbgSandyStartSim: Float;

@addField(PlayerPuppet)
public let m_tdoDbgSandyLastSampleReal: Float;

@addField(PlayerPuppet)
public let m_tdoDbgChargeStartReal: Float;

@addField(PlayerPuppet)
public let m_tdoDbgChargeStartSim: Float;

@addField(PlayerPuppet)
public let m_tdoDbgChargeStartChargeTime: Float;

@addField(PlayerPuppet)
public let m_tdoDbgChargeLastTickReal: Float;

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  TDO_Dbg_LogSandyEnter(scriptInterface);
}

@wrapMethod(SandevistanEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  TDO_Dbg_LogSandyTick(scriptInterface);
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  TDO_Dbg_LogSandyEnd(scriptInterface, "OnExit");
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  TDO_Dbg_LogSandyEnd(scriptInterface, "OnForcedExit");
  wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(ChargeEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  TDO_Dbg_LogChargeStart(scriptInterface);
}

@wrapMethod(ChargeReadyEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  TDO_Dbg_LogChargeReady(scriptInterface);
}

@wrapMethod(ChargeReadyEvents)
protected func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  TDO_Dbg_LogChargeTick(scriptInterface);
}

@wrapMethod(ChargeMaxEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  TDO_Dbg_LogChargeMax(scriptInterface);
}

public static func TDO_Dbg_LogSandyEnter(scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  let gi: GameInstance = scriptInterface.GetGame();
  let realTime: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));
  let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
  let stats: ref<StatsSystem> = scriptInterface.GetStatsSystem();
  let pools: ref<StatPoolsSystem> = scriptInterface.GetStatPoolsSystem();
  let timeScaleStat: Float = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.TimeDilationSandevistanTimeScale);
  let activeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();

  player.m_tdoDbgSandyStartReal = realTime;
  player.m_tdoDbgSandyStartSim = simTime;
  player.m_tdoDbgSandyLastSampleReal = realTime;

  let weapon: wref<WeaponObject> = GameObject.GetActiveWeapon(player);
  let weaponID: String = "(none)";
  let evoInt: Int32 = -1;
  let chargeTime: Float = 0.0;
  let chargeRate: Float = 0.0;
  let chargePool: Float = 0.0;
  if IsDefined(weapon) {
    weaponID = ToString(weapon.GetWeaponRecord().GetID());
    evoInt = EnumInt(RPGManager.GetWeaponEvolution(weapon.GetItemID()));
    chargeTime = stats.GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ChargeTime);
    if chargeTime > 0.0 {
      chargeRate = 100.0 / chargeTime;
    } else {
      chargeRate = -1.0;
    }
    chargePool = pools.GetStatPoolValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatPoolType.WeaponCharge, false);
  }

  TDODebug("ChargeDbg", s"[SANDY ENTER] real=\(realTime) sim=\(simTime) timeScaleStat=\(timeScaleStat) activeDilation=\(activeDilation) weapon=\(weaponID) evoInt=\(evoInt) chargeTimeStat=\(chargeTime) computedRatePerSec=\(chargeRate) chargePool=\(chargePool)");
}

public static func TDO_Dbg_LogSandyTick(scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  let gi: GameInstance = scriptInterface.GetGame();
  let realTime: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));
  if (realTime - player.m_tdoDbgSandyLastSampleReal) < 0.5 {
    return;
  }
  player.m_tdoDbgSandyLastSampleReal = realTime;

  let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
  let realDelta: Float = realTime - player.m_tdoDbgSandyStartReal;
  let simDelta: Float = simTime - player.m_tdoDbgSandyStartSim;
  let observedDilation: Float = -1.0;
  if realDelta > 0.0 {
    observedDilation = simDelta / realDelta;
  }
  let activeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();

  let weapon: wref<WeaponObject> = GameObject.GetActiveWeapon(player);
  let chargePool: Float = 0.0;
  if IsDefined(weapon) {
    chargePool = scriptInterface.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatPoolType.WeaponCharge, false);
  }

  TDODebug("ChargeDbg", s"[SANDY TICK ] realDelta=\(realDelta) simDelta=\(simDelta) observedDilationRatio=\(observedDilation) activeDilation=\(activeDilation) chargePool=\(chargePool)");
}

public static func TDO_Dbg_LogSandyEnd(scriptInterface: ref<StateGameScriptInterface>, reason: String) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  let gi: GameInstance = scriptInterface.GetGame();
  let realTime: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));
  let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
  let realDelta: Float = realTime - player.m_tdoDbgSandyStartReal;
  let simDelta: Float = simTime - player.m_tdoDbgSandyStartSim;
  let activeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();

  let weapon: wref<WeaponObject> = GameObject.GetActiveWeapon(player);
  let chargePool: Float = 0.0;
  let chargeTime: Float = 0.0;
  if IsDefined(weapon) {
    chargePool = scriptInterface.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatPoolType.WeaponCharge, false);
    chargeTime = scriptInterface.GetStatsSystem().GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ChargeTime);
  }

  TDODebug("ChargeDbg", s"[SANDY \(reason)] real=\(realTime) realDelta=\(realDelta) simDelta=\(simDelta) activeDilationStillReported=\(activeDilation) chargePool=\(chargePool) chargeTimeStat=\(chargeTime)");
}

public static func TDO_Dbg_LogChargeStart(scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  let weapon: ref<WeaponObject> = scriptInterface.owner as WeaponObject;
  if !IsDefined(weapon) { return; }
  let gi: GameInstance = scriptInterface.GetGame();
  let realTime: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));
  let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
  let chargeTime: Float = scriptInterface.GetStatsSystem().GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ChargeTime);
  let chargeRate: Float = -1.0;
  if chargeTime > 0.0 {
    chargeRate = 100.0 / chargeTime;
  }
  let pool: Float = scriptInterface.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatPoolType.WeaponCharge, false);
  let sandyActive: Bool = scriptInterface.GetTimeSystem().IsTimeDilationActive(n"sandevistan");
  let activeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();
  let weaponID: String = ToString(weapon.GetWeaponRecord().GetID());

  player.m_tdoDbgChargeStartReal = realTime;
  player.m_tdoDbgChargeStartSim = simTime;
  player.m_tdoDbgChargeStartChargeTime = chargeTime;

  TDODebug("ChargeDbg", s"[CHARGE START] real=\(realTime) sim=\(simTime) weapon=\(weaponID) chargeTimeStat=\(chargeTime) computedRatePerSec=\(chargeRate) startPool=\(pool) sandyActive=\(sandyActive) activeDilation=\(activeDilation)");
}

public static func TDO_Dbg_LogChargeReady(scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  let weapon: ref<WeaponObject> = scriptInterface.owner as WeaponObject;
  if !IsDefined(weapon) { return; }
  let gi: GameInstance = scriptInterface.GetGame();
  let realTime: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));
  let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
  let realDelta: Float = realTime - player.m_tdoDbgChargeStartReal;
  let simDelta: Float = simTime - player.m_tdoDbgChargeStartSim;
  let pool: Float = scriptInterface.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatPoolType.WeaponCharge, false);
  let sandyStillActive: Bool = scriptInterface.GetTimeSystem().IsTimeDilationActive(n"sandevistan");
  let activeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();

  player.m_tdoDbgChargeLastTickReal = realTime;

  TDODebug("ChargeDbg", s"[CHARGE READY-THRESHOLD] real=\(realTime) realDelta=\(realDelta) simDelta=\(simDelta) firingThresholdCrossedAtPool=\(pool) sandyStillActive=\(sandyStillActive) activeDilation=\(activeDilation)");
}

public static func TDO_Dbg_LogChargeTick(scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  let weapon: ref<WeaponObject> = scriptInterface.owner as WeaponObject;
  if !IsDefined(weapon) { return; }
  let gi: GameInstance = scriptInterface.GetGame();
  let realTime: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));
  if (realTime - player.m_tdoDbgChargeLastTickReal) < 0.5 {
    return;
  }
  player.m_tdoDbgChargeLastTickReal = realTime;

  let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
  let realDelta: Float = realTime - player.m_tdoDbgChargeStartReal;
  let simDelta: Float = simTime - player.m_tdoDbgChargeStartSim;
  let pool: Float = scriptInterface.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatPoolType.WeaponCharge, false);
  let sandyActive: Bool = scriptInterface.GetTimeSystem().IsTimeDilationActive(n"sandevistan");
  let activeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();

  TDODebug("ChargeDbg", s"[CHARGE TICK ] realDelta=\(realDelta) simDelta=\(simDelta) pool=\(pool) sandyActive=\(sandyActive) activeDilation=\(activeDilation)");
}

public static func TDO_Dbg_LogChargeMax(scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) { return; }
  let weapon: ref<WeaponObject> = scriptInterface.owner as WeaponObject;
  if !IsDefined(weapon) { return; }
  let gi: GameInstance = scriptInterface.GetGame();
  let realTime: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(gi));
  let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
  let realDelta: Float = realTime - player.m_tdoDbgChargeStartReal;
  let simDelta: Float = simTime - player.m_tdoDbgChargeStartSim;
  let chargeTimeNow: Float = scriptInterface.GetStatsSystem().GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ChargeTime);
  let pool: Float = scriptInterface.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatPoolType.WeaponCharge, false);
  let sandyStillActive: Bool = scriptInterface.GetTimeSystem().IsTimeDilationActive(n"sandevistan");
  let activeDilation: Float = scriptInterface.GetTimeSystem().GetActiveTimeDilation();
  let observedRatio: Float = -1.0;
  if realDelta > 0.0 {
    observedRatio = simDelta / realDelta;
  }

  TDODebug("ChargeDbg", s"[CHARGE MAX  ] real=\(realTime) realDelta=\(realDelta) simDelta=\(simDelta) observedDilationRatio=\(observedRatio) chargeTimeAtStart=\(player.m_tdoDbgChargeStartChargeTime) chargeTimeNow=\(chargeTimeNow) maxedPool=\(pool) sandyStillActive=\(sandyStillActive) activeDilation=\(activeDilation)");
}

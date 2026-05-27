module TDO.Logging

public enum TDO_LogLevel {
  ERROR = 0,
  WARNING = 1,
  INFO = 2,
  DEBUG = 3,
  TRACE = 4
}

public class TDO_LoggerConfigProbe extends DelayCallback {
  public func Call() -> Void {
    ModLog(n"TDO", s"[INIT] TDO logger online. EnableDebugLog=\(TDOConfig.EnableDebugLog()) DebugLogLevel=\(TDOConfig.DebugLogLevel())");
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  let probe: ref<TDO_LoggerConfigProbe> = new TDO_LoggerConfigProbe();
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(probe, 2.0, false);
  return result;
}

public class TDO_LoggerStateSystem extends ScriptableSystem {
  private let m_lastLogMessage: String;
  private let m_lastLogContext: String;
  private let m_lastLogTimestamp: Float;
  private let m_duplicateCount: Int32;

  private func OnAttach() {
    this.m_lastLogMessage = "";
    this.m_lastLogContext = "";
    this.m_lastLogTimestamp = 0.0;
    this.m_duplicateCount = 0;
  }

  public func GetLastMessage() -> String { return this.m_lastLogMessage; }
  public func GetLastContext() -> String { return this.m_lastLogContext; }
  public func GetLastTimestamp() -> Float { return this.m_lastLogTimestamp; }
  public func GetDuplicateCount() -> Int32 { return this.m_duplicateCount; }
  public func SetLastMessage(msg: String) { this.m_lastLogMessage = msg; }
  public func SetLastContext(ctx: String) { this.m_lastLogContext = ctx; }
  public func SetLastTimestamp(time: Float) { this.m_lastLogTimestamp = time; }
  public func SetDuplicateCount(count: Int32) { this.m_duplicateCount = count; }
  public func IncrementDuplicateCount() { this.m_duplicateCount += 1; }
}

private static func TDO_GetCurrentLogLevel() -> TDO_LogLevel {
  if !TDOConfig.EnableDebugLog() {
    return TDO_LogLevel.ERROR;
  }
  let level: Int32 = TDOConfig.DebugLogLevel();
  if level <= 0 { return TDO_LogLevel.ERROR; }
  if level == 1 { return TDO_LogLevel.WARNING; }
  if level == 2 { return TDO_LogLevel.INFO; }
  if level == 3 { return TDO_LogLevel.DEBUG; }
  return TDO_LogLevel.TRACE;
}

public static func TDOError(context: String, message: String) -> Void {
  TDO_LogWithLevel(TDO_LogLevel.ERROR, context, message);
}
public static func TDOWarn(context: String, message: String) -> Void {
  if EnumInt(TDO_GetCurrentLogLevel()) >= EnumInt(TDO_LogLevel.WARNING) {
    TDO_LogWithLevel(TDO_LogLevel.WARNING, context, message);
  }
}
public static func TDOInfo(context: String, message: String) -> Void {
  if EnumInt(TDO_GetCurrentLogLevel()) >= EnumInt(TDO_LogLevel.INFO) {
    TDO_LogWithLevel(TDO_LogLevel.INFO, context, message);
  }
}
public static func TDODebug(context: String, message: String) -> Void {
  if EnumInt(TDO_GetCurrentLogLevel()) >= EnumInt(TDO_LogLevel.DEBUG) {
    TDO_LogWithLevel(TDO_LogLevel.DEBUG, context, message);
  }
}
public static func TDOTrace(context: String, message: String) -> Void {
  if EnumInt(TDO_GetCurrentLogLevel()) >= EnumInt(TDO_LogLevel.TRACE) {
    TDO_LogWithLevel(TDO_LogLevel.TRACE, context, message);
  }
}

private static func TDO_LogWithLevel(level: TDO_LogLevel, context: String, message: String) -> Void {
  let gameInstance: GameInstance = GetGameInstance();
  let loggerState: ref<TDO_LoggerStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"TDO.Logging.TDO_LoggerStateSystem") as TDO_LoggerStateSystem;
  if !IsDefined(loggerState) {
    ModLog(n"TDO", TDO_GetLevelPrefix(level) + " [" + context + "] " + message);
    return;
  }
  let currentTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gameInstance));
  let timeSinceLastLog: Float = currentTime - loggerState.GetLastTimestamp();
  if timeSinceLastLog < 5.0 && Equals(loggerState.GetLastContext(), context) && Equals(loggerState.GetLastMessage(), message) {
    loggerState.IncrementDuplicateCount();
    return;
  }
  if loggerState.GetDuplicateCount() > 0 {
    ModLog(n"TDO", TDO_GetLevelPrefix(level) + " [" + loggerState.GetLastContext() + "] -> Previous message repeated " + ToString(loggerState.GetDuplicateCount()) + " times");
    loggerState.SetDuplicateCount(0);
  }
  ModLog(n"TDO", TDO_GetLevelPrefix(level) + " [" + context + "] " + message);
  loggerState.SetLastMessage(message);
  loggerState.SetLastContext(context);
  loggerState.SetLastTimestamp(currentTime);
}

private static func TDO_GetLevelPrefix(level: TDO_LogLevel) -> String {
  switch level {
    case TDO_LogLevel.ERROR:   return "[ERROR]  ";
    case TDO_LogLevel.WARNING: return "[WARN]   ";
    case TDO_LogLevel.INFO:    return "[INFO]   ";
    case TDO_LogLevel.DEBUG:   return "[DEBUG]  ";
    case TDO_LogLevel.TRACE:   return "[TRACE]  ";
  }
  return "[UNKNOWN]";
}

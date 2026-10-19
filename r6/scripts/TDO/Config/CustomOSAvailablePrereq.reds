public class TDO_CustomOSAvailablePrereq extends IScriptablePrereq {
  private let m_availableFlat: TweakDBID;

  protected func Initialize(recordID: TweakDBID) -> Void {
    this.m_availableFlat = recordID + t".available";
  }

  public const func IsFulfilled(game: GameInstance, context: ref<IScriptable>) -> Bool {
    return TweakDBInterface.GetBool(this.m_availableFlat, true);
  }
}

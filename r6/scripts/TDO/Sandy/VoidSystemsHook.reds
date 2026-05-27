module TDO.Sandy

@wrapMethod(UseSandevistanAction)
public func StartAction(gameInstance: GameInstance) -> Void {
  let player: ref<PlayerPuppet> = this.GetExecutor() as PlayerPuppet;
  if !IsDefined(player) {
    wrappedMethod(gameInstance);
    return;
  }

  let sogimsuTier: Int32 = player.TDO_Sogimsu_GetEquippedTier();
  if sogimsuTier > 0 {
    player.TDO_Sogimsu_OnActivate(sogimsuTier);
    return;
  }

  let juggernautTier: Int32 = player.TDO_Juggernaut_GetEquippedTier();
  if juggernautTier > 0 {
    player.TDO_Juggernaut_OnActivate(juggernautTier);
    return;
  }

  let pyrolithTier: Int32 = player.TDO_Pyrolith_GetEquippedTier();
  if pyrolithTier > 0 {
    player.TDO_Pyrolith_OnActivate(pyrolithTier);
    return;
  }

  wrappedMethod(gameInstance);
}

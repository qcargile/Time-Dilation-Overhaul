module TDO.Sandy

import TDO.Logging.*

public func TDO_WarpDancer_SpawnRewindGlitch(player: ref<PlayerPuppet>) -> Void {
  if !TDOConfig.WarpDancerRewindGlitchEnabled() {
    return;
  }
  let fxSystem: ref<FxSystem> = GameInstance.GetFxSystem(player.GetGame());
  if !IsDefined(fxSystem) {
    TDOWarn("WarpDancer", "rewind glitch fx skipped (no FxSystem)");
    return;
  }
  let raRef: ResourceAsyncRef = new ResourceAsyncRef();
  ResourceAsyncRef.SetPath(raRef, r"base\\fx\\player\\p_reboot_glitch\\p_reboot_glitch.effect");
  let fxRes: FxResource;
  fxRes.effect = raRef;
  let position: WorldPosition;
  WorldPosition.SetVector4(position, player.GetWorldPosition());
  let transform: WorldTransform;
  WorldTransform.SetWorldPosition(transform, position);
  WorldTransform.SetOrientationFromDir(transform, player.GetWorldForward());
  fxSystem.SpawnEffect(fxRes, transform, true);
}

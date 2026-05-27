module TDO.Sandy

public func TDO_Quantum_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  return TDBID.IsValid(TDO_Quantum_GetEquippedTDB(player));
}

public func TDO_Quantum_GetCameraForward(player: ref<PlayerPuppet>) -> Vector4 {
  let camera: ref<FPPCameraComponent> = player.GetFPPCameraComponent();
  if !IsDefined(camera) {
    return player.GetWorldForward();
  }
  let camMatrix: Matrix = camera.GetLocalToWorld();
  return Vector4.Normalize(Matrix.GetDirectionVector(camMatrix));
}

public func TDO_Quantum_GetCameraPosition(player: ref<PlayerPuppet>) -> Vector4 {
  let camera: ref<FPPCameraComponent> = player.GetFPPCameraComponent();
  if !IsDefined(camera) {
    return player.GetWorldPosition();
  }
  return Matrix.GetTranslation(camera.GetLocalToWorld());
}

public func TDO_Quantum_ResolveAimPoint(player: ref<PlayerPuppet>, maxRange: Float, lift: Float, out hitPos: Vector4) -> Bool {
  let gi: GameInstance = player.GetGame();
  let qs: ref<SpatialQueriesSystem> = GameInstance.GetSpatialQueriesSystem(gi);
  if !IsDefined(qs) {
    return false;
  }
  let camPos: Vector4 = TDO_Quantum_GetCameraPosition(player);
  let camFwd: Vector4 = TDO_Quantum_GetCameraForward(player);
  let lineEnd: Vector4 = camPos + (camFwd * maxRange);
  let tr: TraceResult;
  let hit: Bool = qs.SyncRaycastByCollisionPreset(camPos, lineEnd, n"World Static", tr, true);
  if !hit {
    hitPos = lineEnd;
    hitPos.Z += lift;
    return true;
  }
  let p: Vector4 = Cast<Vector4>(tr.position);
  p.Z += lift;
  hitPos = p;
  return true;
}

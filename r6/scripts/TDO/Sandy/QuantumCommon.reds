module TDO.Sandy

import TDO.Logging.*

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

public func TDO_Quantum_SnapToGround(qs: ref<SpatialQueriesSystem>, raw: Vector4, out grounded: Vector4) -> Bool {
  let startPos: Vector4 = raw;
  startPos.Z += TDOConfig.QuantumTeleportGroundSearchStartLift();
  let endPos: Vector4 = raw;
  endPos.Z -= TDOConfig.QuantumTeleportGroundSearchBudget();
  let tr: TraceResult;
  let hit: Bool = qs.SyncRaycastByCollisionGroup(startPos, endPos, n"Static", tr, true, false);
  if !hit {
    return false;
  }
  let normal: Vector4 = Cast<Vector4>(tr.normal);
  let dotUp: Float = Vector4.Dot(normal, new Vector4(0.0, 0.0, 1.0, 0.0));
  if dotUp < TDOConfig.QuantumTeleportFloorNormalMinZ() {
    return false;
  }
  grounded = Cast<Vector4>(tr.position);
  return true;
}

public func TDO_Quantum_HasCapsuleSpace(qs: ref<SpatialQueriesSystem>, foot: Vector4) -> Bool {
  let width: Float = TDOConfig.QuantumTeleportCapsuleWidth();
  let height: Float = TDOConfig.QuantumTeleportCapsuleHeight();
  let clearance: Float = TDOConfig.QuantumTeleportCapsuleClearance();
  let halfExt: Vector4 = new Vector4(width * 0.5, width * 0.5, height * 0.5, 0.0);
  let boxCenter: Vector4 = foot;
  boxCenter.Z += clearance + halfExt.Z;
  let identity: Quaternion;
  Quaternion.SetIdentity(identity);
  let filter: QueryFilter;
  QueryFilter.AddGroup(filter, n"Static");
  QueryFilter.AddGroup(filter, n"Vehicle");
  QueryFilter.AddGroup(filter, n"Dynamic");
  QueryFilter.AddGroup(filter, n"Terrain");
  let overlapResult: TraceResult;
  let overlap: Bool = qs.OverlapByQueryFilter(halfExt, boxCenter, identity, filter, overlapResult);
  return !overlap;
}

public func TDO_Quantum_TryCandidate(player: ref<PlayerPuppet>, qs: ref<SpatialQueriesSystem>, raw: Vector4, lift: Float, out finalPos: Vector4) -> Bool {
  let grounded: Vector4;
  if !TDO_Quantum_SnapToGround(qs, raw, grounded) {
    TDOTrace("QuantumSafety", "snap-to-ground failed");
    return false;
  }
  let navSys: ref<AINavigationSystem> = GameInstance.GetAINavigationSystem(player.GetGame());
  if IsDefined(navSys) {
    let navResult: NavigationFindPointResult = navSys.FindPointInSphereForCharacter(grounded, TDOConfig.QuantumTeleportNavmeshSnapRadius(), player);
    if Equals(navResult.status, worldNavigationRequestStatus.OK) {
      grounded = navResult.point;
      TDOTrace("QuantumSafety", "navmesh snap OK");
    } else {
      TDOTrace("QuantumSafety", "navmesh status=" + ToString(EnumInt(navResult.status)) + " continuing without snap");
    }
  }
  if !TDO_Quantum_HasCapsuleSpace(qs, grounded) {
    TDOTrace("QuantumSafety", "capsule overlap rejected");
    return false;
  }
  grounded.Z += lift;
  finalPos = grounded;
  return true;
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
  let raw: Vector4;
  if hit {
    raw = Cast<Vector4>(tr.position);
  } else {
    raw = lineEnd;
  }
  let candidate: Vector4;
  if TDO_Quantum_TryCandidate(player, qs, raw, lift, candidate) {
    hitPos = candidate;
    return true;
  }
  TDODebug("QuantumSafety", "primary rejected, trying fallbacks");
  let camFwdFlat: Vector4 = camFwd;
  camFwdFlat.Z = 0.0;
  if Vector4.Length(camFwdFlat) < 0.01 {
    camFwdFlat = new Vector4(0.0, 1.0, 0.0, 0.0);
  }
  camFwdFlat = Vector4.Normalize(camFwdFlat);
  let camRightFlat: Vector4 = Vector4.Cross(camFwdFlat, new Vector4(0.0, 0.0, 1.0, 0.0));
  camRightFlat = Vector4.Normalize(camRightFlat);
  let nearOff: Float = TDOConfig.QuantumTeleportFallbackNearOffset();
  let farOff: Float = TDOConfig.QuantumTeleportFallbackFarOffset();
  let attempt: Vector4 = raw - camFwdFlat * nearOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback back-near accepted");
    return true;
  }
  attempt = raw - camFwdFlat * farOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback back-far accepted");
    return true;
  }
  attempt = raw + camRightFlat * nearOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback right-near accepted");
    return true;
  }
  attempt = raw - camRightFlat * nearOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback left-near accepted");
    return true;
  }
  TDODebug("QuantumSafety", "all fallbacks rejected, no valid destination");
  return false;
}

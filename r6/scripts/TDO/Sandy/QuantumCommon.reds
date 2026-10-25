module TDO.Sandy

import TDO.Logging.*

public func TDO_Quantum_Vec3Str(v: Vector4) -> String {
  return ToString(v.X) + " / " + ToString(v.Y) + " / " + ToString(v.Z);
}

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
  if TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= 4 {
    TDOTrace("QuantumGround", "start=" + TDO_Quantum_Vec3Str(startPos) + " end=" + TDO_Quantum_Vec3Str(endPos) + " hit=" + ToString(hit) + " position=" + TDO_Quantum_Vec3Str(Cast<Vector4>(tr.position)) + " normal=" + TDO_Quantum_Vec3Str(Cast<Vector4>(tr.normal)));
  }
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
  if TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= 4 {
    TDOTrace("QuantumClearance", "foot=" + TDO_Quantum_Vec3Str(foot) + " center=" + TDO_Quantum_Vec3Str(boxCenter) + " halfExtents=" + TDO_Quantum_Vec3Str(halfExt) + " overlap=" + ToString(overlap));
  }
  return !overlap;
}

public func TDO_Quantum_TryCandidate(player: ref<PlayerPuppet>, qs: ref<SpatialQueriesSystem>, raw: Vector4, lift: Float, out finalPos: Vector4) -> Bool {
  let grounded: Vector4;
  if !TDO_Quantum_SnapToGround(qs, raw, grounded) {
    TDOTrace("QuantumSafety", "snap-to-ground failed");
    return false;
  }
  let navSys: ref<AINavigationSystem> = GameInstance.GetAINavigationSystem(player.GetGame());
  if !IsDefined(navSys) {
    TDOTrace("QuantumSafety", "navmesh system missing");
    return false;
  }
  let navResult: NavigationFindPointResult = navSys.FindPointInSphereForCharacter(grounded, TDOConfig.QuantumTeleportNavmeshSnapRadius(), player);
  if TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= 4 {
    TDOTrace("QuantumNavigation", "ground=" + TDO_Quantum_Vec3Str(grounded) + " status=" + ToString(EnumInt(navResult.status)) + " point=" + TDO_Quantum_Vec3Str(navResult.point));
  }
  if !Equals(navResult.status, worldNavigationRequestStatus.OK) {
    TDOTrace("QuantumSafety", "navmesh status=" + ToString(EnumInt(navResult.status)) + " rejected");
    return false;
  }
  grounded = navResult.point;
  TDOTrace("QuantumSafety", "navmesh snap OK");
  grounded.Z += lift;
  if !TDO_Quantum_HasCapsuleSpace(qs, grounded) {
    TDOTrace("QuantumSafety", "capsule overlap rejected");
    return false;
  }
  finalPos = grounded;
  return true;
}

public func TDO_Quantum_TryDirectCandidate(qs: ref<SpatialQueriesSystem>, raw: Vector4, lift: Float, out finalPos: Vector4) -> Bool {
  let candidate: Vector4 = raw;
  candidate.Z += lift;
  if !TDO_Quantum_HasCapsuleSpace(qs, candidate) {
    TDOTrace("QuantumSafety", "direct capsule overlap rejected");
    return false;
  }
  finalPos = candidate;
  return true;
}

public func TDO_Quantum_ResolveAimPoint(player: ref<PlayerPuppet>, maxRange: Float, lift: Float, out aimPos: Vector4, out hitPos: Vector4) -> Bool {
  let gi: GameInstance = player.GetGame();
  let qs: ref<SpatialQueriesSystem> = GameInstance.GetSpatialQueriesSystem(gi);
  if !IsDefined(qs) {
    return false;
  }
  let camPos: Vector4 = TDO_Quantum_GetCameraPosition(player);
  let camFwd: Vector4 = TDO_Quantum_GetCameraForward(player);
  let camFwdFlat: Vector4 = camFwd;
  camFwdFlat.Z = 0.0;
  if Vector4.Length(camFwdFlat) < 0.01 {
    camFwdFlat = player.GetWorldForward();
    camFwdFlat.Z = 0.0;
  }
  if Vector4.Length(camFwdFlat) < 0.01 {
    camFwdFlat = new Vector4(0.0, 1.0, 0.0, 0.0);
  }
  camFwdFlat = Vector4.Normalize(camFwdFlat);
  let lineEnd: Vector4 = camPos + (camFwd * maxRange);
  let tr: TraceResult;
  let hit: Bool = qs.SyncRaycastByCollisionPreset(camPos, lineEnd, n"World Static", tr, true);
  if TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= 4 {
    let referenceFilter: QueryFilter;
    QueryFilter.AddGroup(referenceFilter, n"Static");
    QueryFilter.AddGroup(referenceFilter, n"Terrain");
    QueryFilter.AddGroup(referenceFilter, n"PlayerBlocker");
    let referenceTrace: TraceResult;
    let referenceHit: Bool = qs.SyncRaycastByQueryFilter(camPos, lineEnd, referenceFilter, referenceTrace, true, false);
    TDOTrace("QuantumAimReference", "primaryHit=" + ToString(hit) + " primaryPosition=" + TDO_Quantum_Vec3Str(Cast<Vector4>(tr.position)) + " primaryNormal=" + TDO_Quantum_Vec3Str(Cast<Vector4>(tr.normal)) + " referenceHit=" + ToString(referenceHit) + " referencePosition=" + TDO_Quantum_Vec3Str(Cast<Vector4>(referenceTrace.position)) + " referenceNormal=" + TDO_Quantum_Vec3Str(Cast<Vector4>(referenceTrace.normal)));
  }
  let raw: Vector4;
  if hit {
    raw = Cast<Vector4>(tr.position);
  } else {
    raw = lineEnd;
  }
  TDOTrace("QuantumAim", "hit=" + ToString(hit) + " range=" + ToString(maxRange) + " camPos=" + TDO_Quantum_Vec3Str(camPos) + " camFwd=" + TDO_Quantum_Vec3Str(camFwd) + " raw=" + TDO_Quantum_Vec3Str(raw));
  let candidate: Vector4;
  let directAllowed: Bool = !hit;
  if hit {
    let normal: Vector4 = Cast<Vector4>(tr.normal);
    directAllowed = Vector4.Dot(normal, new Vector4(0.0, 0.0, 1.0, 0.0)) >= TDOConfig.QuantumTeleportFloorNormalMinZ();
  }
  if directAllowed && TDO_Quantum_TryDirectCandidate(qs, raw, lift, candidate) {
    if TDOConfig.EnableDebugLog() && TDOConfig.DebugLogLevel() >= 4 {
      TDOTrace("QuantumSafety", "direct accepted hit=" + ToString(hit) + " raw=" + TDO_Quantum_Vec3Str(raw) + " destination=" + TDO_Quantum_Vec3Str(candidate));
    }
    aimPos = raw;
    hitPos = candidate;
    return true;
  }
  if TDO_Quantum_TryCandidate(player, qs, raw, lift, candidate) {
    aimPos = raw;
    hitPos = candidate;
    return true;
  }
  TDODebug("QuantumSafety", "primary rejected, trying fallbacks");
  let camRightFlat: Vector4 = Vector4.Cross(camFwdFlat, new Vector4(0.0, 0.0, 1.0, 0.0));
  camRightFlat = Vector4.Normalize(camRightFlat);
  let nearOff: Float = TDOConfig.QuantumTeleportFallbackNearOffset();
  let farOff: Float = TDOConfig.QuantumTeleportFallbackFarOffset();
  let attempt: Vector4 = raw - camFwdFlat * nearOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    aimPos = raw;
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback back-near accepted");
    return true;
  }
  attempt = raw - camFwdFlat * farOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    aimPos = raw;
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback back-far accepted");
    return true;
  }
  attempt = raw + camRightFlat * nearOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    aimPos = raw;
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback right-near accepted");
    return true;
  }
  attempt = raw - camRightFlat * nearOff;
  if TDO_Quantum_TryCandidate(player, qs, attempt, lift, candidate) {
    aimPos = raw;
    hitPos = candidate;
    TDODebug("QuantumSafety", "fallback left-near accepted");
    return true;
  }
  TDODebug("QuantumSafety", "all candidates rejected");
  return false;
}

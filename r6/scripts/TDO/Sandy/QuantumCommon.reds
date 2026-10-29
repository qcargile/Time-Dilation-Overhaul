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

public func TDO_Quantum_GetCollisionFilter() -> QueryFilter {
  let filter: QueryFilter;
  QueryFilter.AddGroup(filter, n"Static");
  QueryFilter.AddGroup(filter, n"Terrain");
  QueryFilter.AddGroup(filter, n"PlayerBlocker");
  QueryFilter.AddGroup(filter, n"Vehicle");
  QueryFilter.AddGroup(filter, n"VehicleBlocker");
  QueryFilter.AddGroup(filter, n"Dynamic");
  QueryFilter.AddGroup(filter, n"Collider");
  QueryFilter.AddGroup(filter, n"Destructible");
  return filter;
}

public func TDO_Quantum_HasSurfaceSupport(qs: ref<SpatialQueriesSystem>, filter: QueryFilter, surface: Vector4, normal: Vector4, radius: Float) -> Bool {
  let tolerance: Float = TDOConfig.QuantumTeleportSurfaceTolerance();
  let i: Int32 = 0;
  while i < 5 {
    let sample: Vector4 = surface;
    if i > 0 {
      let offsetX: Float = i <= 2 ? -radius : radius;
      let offsetY: Float = i == 1 || i == 3 ? -radius : radius;
      sample.X += offsetX;
      sample.Y += offsetY;
      sample.Z -= (normal.X * offsetX + normal.Y * offsetY) / normal.Z;
    }
    let startPos: Vector4 = sample;
    startPos.Z += tolerance;
    let endPos: Vector4 = sample;
    endPos.Z -= tolerance;
    let tr: TraceResult;
    if !qs.SyncRaycastByQueryFilter(startPos, endPos, filter, tr, true, false) {
      TDOTrace("QuantumSafety", "support missing at sample=" + ToString(i));
      return false;
    }
    let supportNormal: Vector4 = Cast<Vector4>(tr.normal);
    if !(supportNormal.Z >= TDOConfig.QuantumTeleportFloorNormalMinZ()) || !(Vector4.Distance(sample, Cast<Vector4>(tr.position)) <= tolerance) {
      TDOTrace("QuantumSafety", "support disagrees with selected surface at sample=" + ToString(i));
      return false;
    }
    i += 1;
  }
  return true;
}

public func TDO_Quantum_HasTravelSpace(player: ref<PlayerPuppet>, scriptInterface: ref<StateGameScriptInterface>, qs: ref<SpatialQueriesSystem>, filter: QueryFilter, foot: Vector4, radius: Float) -> Bool {
  let height: Float = TDOConfig.QuantumTeleportCapsuleHeight();
  let halfExt: Vector4 = new Vector4(radius, radius, height * 0.5, 0.0);
  let center: Vector4 = foot;
  center.Z += halfExt.Z;
  let identity: Quaternion;
  Quaternion.SetIdentity(identity);
  let tr: TraceResult;
  if qs.OverlapByQueryFilter(halfExt, center, identity, filter, tr) {
    TDOTrace("QuantumSafety", "landing box obstructed");
    return false;
  }
  let capsule: Vector4 = new Vector4(radius, halfExt.Z - radius, -1.0, 0.0);
  let rotation: EulerAngles;
  rotation.Roll = 90.0;
  if scriptInterface.LocomotionOverlapTest(capsule, center, rotation, tr) {
    TDOTrace("QuantumSafety", "landing capsule obstructed");
    return false;
  }
  let startPos: Vector4 = player.GetWorldPosition();
  startPos.Z += halfExt.Z + TDOConfig.QuantumMarkerLift();
  let travel: Vector4 = center - startPos;
  let distance: Float = Vector4.Length(travel);
  if !(distance > 0.0) {
    return false;
  }
  if scriptInterface.LocomotionSweepTest(capsule, startPos, rotation, Vector4.Normalize(travel), distance, false, tr) {
    TDOTrace("QuantumSafety", "travel capsule obstructed");
    return false;
  }
  return true;
}

public func TDO_Quantum_ResolveAimPoint(player: ref<PlayerPuppet>, scriptInterface: ref<StateGameScriptInterface>, maxRange: Float, lift: Float, out hitPos: Vector4) -> Bool {
  let gi: GameInstance = player.GetGame();
  let qs: ref<SpatialQueriesSystem> = GameInstance.GetSpatialQueriesSystem(gi);
  if !IsDefined(qs) {
    return false;
  }
  let physicsRadius: Float = FromVariant<Float>(scriptInterface.GetStateVectorParameter(physicsStateValue.Radius));
  if !(physicsRadius > 0.0 && physicsRadius <= TDOConfig.QuantumTeleportCapsuleHeight() * 0.5) {
    TDOTrace("QuantumSafety", "player radius unavailable value=" + ToString(physicsRadius));
    return false;
  }
  let radius: Float = MaxF(physicsRadius, 0.4);
  let filter: QueryFilter = TDO_Quantum_GetCollisionFilter();
  let camPos: Vector4 = TDO_Quantum_GetCameraPosition(player);
  let camFwd: Vector4 = TDO_Quantum_GetCameraForward(player);
  let lineEnd: Vector4 = camPos + (camFwd * maxRange);
  let tr: TraceResult;
  if !qs.SyncRaycastByQueryFilter(camPos, lineEnd, filter, tr, true, false) {
    TDOTrace("QuantumSafety", "aim has no surface");
    return false;
  }
  let raw: Vector4 = Cast<Vector4>(tr.position);
  let normal: Vector4 = Cast<Vector4>(tr.normal);
  if !(Vector4.Distance(camPos, raw) <= maxRange) || !(normal.Z >= TDOConfig.QuantumTeleportFloorNormalMinZ()) || !(Vector4.Length(normal) <= 1.01) {
    TDOTrace("QuantumSafety", "aim surface invalid or too steep");
    return false;
  }
  if !TDO_Quantum_HasSurfaceSupport(qs, filter, raw, normal, radius) {
    return false;
  }
  let navSys: ref<AINavigationSystem> = GameInstance.GetAINavigationSystem(gi);
  if !IsDefined(navSys) {
    return false;
  }
  let navResult: NavigationFindPointResult = navSys.FindPointInSphereForCharacter(raw, TDOConfig.QuantumTeleportNavmeshSnapRadius(), player);
  if !Equals(navResult.status, worldNavigationRequestStatus.OK) || !(Vector4.Distance(raw, navResult.point) <= TDOConfig.QuantumTeleportNavmeshSnapRadius()) || !(AbsF(raw.Z - navResult.point.Z) <= TDOConfig.QuantumTeleportSurfaceTolerance()) {
    TDOTrace("QuantumSafety", "navigation disagrees with selected surface");
    return false;
  }
  let candidate: Vector4 = raw;
  candidate.Z += lift;
  if !(Vector4.Distance(camPos, candidate) <= maxRange) || !TDO_Quantum_HasTravelSpace(player, scriptInterface, qs, filter, candidate, radius) {
    return false;
  }
  hitPos = candidate;
  TDOTrace("QuantumSafety", "verified surface destination=" + TDO_Quantum_Vec3Str(candidate));
  return true;
}

module TDO.Sandy

import TDO.Logging.*

public func TDO_Quantum_Vec3Str(v: Vector4) -> String {
  return ToString(v.X) + " / " + ToString(v.Y) + " / " + ToString(v.Z);
}

public func TDO_Quantum_IsEquipped(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  let itemID: ItemID = TDO_Sandy_GetSelectedItem(player);
  return ItemID.IsValid(itemID) && TDO_Quantum_TierForTDB(ItemID.GetTDBID(itemID)) > 0;
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

public func TDO_Quantum_HasLandingSpace(scriptInterface: ref<StateGameScriptInterface>, foot: Vector4, radius: Float) -> Bool {
  let height: Float = TDOConfig.QuantumTeleportCapsuleHeight();
  let center: Vector4 = foot;
  center.Z += height * 0.5;
  let tr: TraceResult;
  let capsule: Vector4 = new Vector4(radius, height * 0.5 - radius, -1.0, 0.0);
  let rotation: EulerAngles;
  rotation.Roll = 90.0;
  if scriptInterface.LocomotionOverlapTest(capsule, center, rotation, tr) {
    TDOTrace("QuantumSafety", "landing capsule obstructed");
    return false;
  }
  return true;
}

public func TDO_Quantum_ValidateDestination(player: ref<PlayerPuppet>, scriptInterface: ref<StateGameScriptInterface>, foot: Vector4, maxRange: Float) -> Bool {
  let displacement: Vector4 = foot - player.GetWorldPosition();
  displacement.Z = 0.0;
  if !(Vector4.Length(displacement) <= maxRange + 0.01) {
    TDOTrace("QuantumSafety", "destination outside teleport range");
    return false;
  }
  let radius: Float = FromVariant<Float>(scriptInterface.GetStateVectorParameter(physicsStateValue.Radius));
  if !(radius > 0.0 && radius <= TDOConfig.QuantumTeleportCapsuleHeight() * 0.5) {
    TDOTrace("QuantumSafety", "player radius unavailable value=" + ToString(radius));
    return false;
  }
  if !TDO_Quantum_HasLandingSpace(scriptInterface, foot, radius) {
    return false;
  }
  let groundEnd: Vector4 = foot;
  groundEnd.Z -= TDOConfig.QuantumMarkerLift() + radius * (1.0 / TDOConfig.QuantumTeleportFloorNormalMinZ() - 1.0) + TDOConfig.QuantumTeleportCapsuleClearance();
  let support: TraceResult = scriptInterface.LocomotionRaycastTest(foot, groundEnd);
  if !TraceResult.IsValid(support) {
    TDOTrace("QuantumSafety", "destination has no player collision support");
    return false;
  }
  let normal: Vector4 = Vector4.Normalize(Cast<Vector4>(support.normal));
  if !(normal.Z >= TDOConfig.QuantumTeleportFloorNormalMinZ()) {
    TDOTrace("QuantumSafety", "destination support too steep");
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
  let radius: Float = FromVariant<Float>(scriptInterface.GetStateVectorParameter(physicsStateValue.Radius));
  if !(radius > 0.0 && radius <= TDOConfig.QuantumTeleportCapsuleHeight() * 0.5) {
    TDOTrace("QuantumSafety", "player radius unavailable value=" + ToString(radius));
    return false;
  }
  let filter: QueryFilter = TDO_Quantum_GetCollisionFilter();
  let origin: Vector4 = player.GetWorldPosition();
  let camPos: Vector4 = TDO_Quantum_GetCameraPosition(player);
  let camFwd: Vector4 = TDO_Quantum_GetCameraForward(player);
  let aimOrigin: Vector4 = origin;
  aimOrigin.Z = camPos.Z;
  let cameraOffset: Vector4 = camPos - aimOrigin;
  let rangeSquared: Float = maxRange * maxRange;
  let cameraDistanceSquared: Float = Vector4.LengthSquared(cameraOffset);
  if !(maxRange > 0.0 && cameraDistanceSquared < rangeSquared) {
    return false;
  }
  let alongAim: Float = Vector4.Dot(cameraOffset, camFwd);
  let aimDistance: Float = SqrtF(alongAim * alongAim + rangeSquared - cameraDistanceSquared) - alongAim;
  let raw: Vector4 = camPos + camFwd * aimDistance;
  let tr: TraceResult;
  let normal: Vector4;
  if qs.SyncRaycastByQueryFilter(camPos, raw, filter, tr, true, false) {
    raw = Cast<Vector4>(tr.position);
    normal = Vector4.Normalize(Cast<Vector4>(tr.normal));
    if normal.Z >= TDOConfig.QuantumTeleportFloorNormalMinZ() {
      raw.Z += TDOConfig.QuantumTeleportCapsuleClearance();
    } else {
      raw += normal * (radius + TDOConfig.QuantumTeleportCapsuleClearance());
    }
  }
  let groundEnd: Vector4 = raw;
  groundEnd.Z -= 1000.0;
  tr = scriptInterface.LocomotionRaycastTest(raw, groundEnd);
  if !TraceResult.IsValid(tr) {
    TDOTrace("QuantumSafety", "no ground below aim");
    return false;
  }
  raw = Cast<Vector4>(tr.position);
  normal = Vector4.Normalize(Cast<Vector4>(tr.normal));
  if !(normal.Z >= TDOConfig.QuantumTeleportFloorNormalMinZ()) {
    TDOTrace("QuantumSafety", "selected surface too steep");
    return false;
  }
  let candidate: Vector4 = raw;
  candidate.Z += lift + radius * (1.0 / normal.Z - 1.0);
  if !TDO_Quantum_ValidateDestination(player, scriptInterface, candidate, maxRange) {
    return false;
  }
  hitPos = candidate;
  TDOTrace("QuantumSafety", "selected supported destination=" + TDO_Quantum_Vec3Str(candidate));
  return true;
}

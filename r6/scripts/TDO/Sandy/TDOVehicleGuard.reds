module TDO.Sandy

public func TDO_IsPlayerInVehicle(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  let vehicle: wref<VehicleObject>;
  if !VehicleComponent.GetVehicle(player.GetGame(), player, vehicle) {
    return false;
  }
  return IsDefined(vehicle);
}

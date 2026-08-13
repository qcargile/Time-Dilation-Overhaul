module TDO.TimeOwnership

import TDO.Sandy.*

public func TDO_OwnsCombatTime(player: ref<PlayerPuppet>) -> Bool {
  return TDO_Sandy_OwnsCombatTime(player);
}

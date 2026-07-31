param(
    [string]$ModRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Require-Match([string]$text, [string]$pattern, [string]$message) {
    if ($text -notmatch $pattern) {
        throw $message
    }
}

function Reject-Match([string]$text, [string]$pattern, [string]$message) {
    if ($text -match $pattern) {
        throw $message
    }
}

$trailPath = Join-Path $ModRoot "r6\scripts\TDO\Sandy\BulletTrailVelocity.reds"
$movementPath = Join-Path $ModRoot "r6\scripts\TDO\Sandy\SandyMovementLocks.reds"
$initPath = Join-Path $ModRoot "bin\x64\plugins\cyber_engine_tweaks\mods\tdo\init.lua"
$languagePath = Join-Path $ModRoot "bin\x64\plugins\cyber_engine_tweaks\mods\tdo\modules\languages\en-us.lua"
$staticPath = Join-Path $ModRoot "r6\tweaks\TDO\bulletProjectile.yaml"

$trail = Get-Content -LiteralPath $trailPath -Raw
$movement = Get-Content -LiteralPath $movementPath -Raw
$init = Get-Content -LiteralPath $initPath -Raw
$language = Get-Content -LiteralPath $languagePath -Raw

if (Test-Path -LiteralPath $staticPath) {
    throw "Static time-dilated attack mappings still exist"
}

Require-Match $trail '@wrapMethod\(WeaponTransition\)' "Missing per-shot attack selector wrapper"
Require-Match $trail 'protected final func GetDesiredAttackRecord\(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>\) -> ref<Attack_Record>' "Attack selector signature does not match vanilla"
Require-Match $trail 'let attackRecord: ref<Attack_Record> = wrappedMethod\(stateContext, scriptInterface\);' "Attack selector does not preserve the winning vanilla or modded result"
Reject-Match $trail 'm_tdoBulletTrailSelected' "A reusable Boolean still authorizes projectile mutation"
Require-Match $trail 'm_tdoBulletTrailAttack = t""' "Selected attack identity is not reset and consumed"
Require-Match $trail 'm_tdoBulletTrailAttack = projectileAttack\.GetID\(\)' "TDO-selected attack identity is not recorded"
Require-Match $trail 'TDOConfig\.BulletTrailVelocityEnabled\(\)' "Attack conversion is not controlled by the master toggle"
Require-Match $trail 'TDO_BulletTrailVelocity_IsSandyActive\(player\)' "Attack conversion is not restricted to actual Sandevistan"
Require-Match $trail 'BaseStatusEffect\.DeadeyeSE' "Deadeye compatibility exclusion is missing"
Require-Match $trail 'gamedataWeaponEvolution\.Tech' "Tech weapon exclusion is missing"
Require-Match $trail 'projectilesPerShot != 1\.0' "Multi-projectile weapon exclusion is missing"

$normalAttacks = @(
    "Attacks.PhysicalBullet",
    "Attacks.PhysicalStatusEffectBullet",
    "Attacks.ThermalBullet",
    "Attacks.ThermalStatusEffectBullet",
    "Attacks.ChemicalBullet",
    "Attacks.ChemicalStatusEffectBullet",
    "Attacks.ElectricBullet",
    "Attacks.ElectricStatusEffectBullet",
    "Attacks.PowerRoundsBullet",
    "Attacks.PowerBuckshotsBullet",
    "Attacks.PowerBulletsBullet"
)

$projectileAttacks = @(
    "Attacks.PowerBullets_Projectile",
    "Attacks.BleedingBulletProjectile",
    "Attacks.ThermalBulletProjectile",
    "Attacks.BurningBulletProjectile",
    "Attacks.ChemicalBulletProjectile",
    "Attacks.PoisonBulletProjectile",
    "Attacks.ElectricBulletProjectile",
    "Attacks.PowerRounds_Projectile",
    "Attacks.PowerBuckshots_Projectile"
)

foreach ($attack in $normalAttacks + $projectileAttacks) {
    Require-Match $trail ([regex]::Escape($attack)) "Missing attack mapping: $attack"
}

Require-Match $trail 'eventData\.owner as PlayerPuppet' "Projectile initialization is not player-owner gated"
Require-Match $trail 'bulletTrailAttack = weapon\.m_tdoBulletTrailAttack' "Projectile initialization does not capture TDO selection before consuming it"
Require-Match $trail 'currentAttackRecord\.GetID\(\), bulletTrailAttack' "Projectile initialization does not verify the live attack against TDO selection"
$consumeIndex = $trail.IndexOf("bulletTrailAttack = weapon.m_tdoBulletTrailAttack")
$shrikeIndex = $trail.IndexOf("if player.m_tdoShrikePendingHitscanBullets > 0")
if ($consumeIndex -lt 0 -or $shrikeIndex -lt 0 -or $consumeIndex -gt $shrikeIndex) {
    throw "Selected attack identity is not consumed before projectile early returns"
}
Require-Match $trail 'm_tdoOriginalVelocity = this\.m_startVelocity' "Original projectile velocity is not captured"
Require-Match $trail 'params\.startVel = this\.m_tdoOriginalVelocity' "Original projectile velocity is not restored"
Require-Match $trail 'TDOConfig\.BulletTrailVelocityEnabled\(\) && TDO_BulletTrailVelocity_IsSandyActive' "In-flight projectile retention is not gated by both the toggle and Sandevistan"
Reject-Match $trail 'params\.startVel = 90\.0' "Projectile restoration still hardcodes vanilla velocity"

Reject-Match $movement 'TDOConfig\.BulletTrailVelocityEnabled\(\)' "GUTS movement-lock cleanup is still coupled to Bullet Trails"
Reject-Match $init 'gunsRedoneOverhaulDetected' "Author-specific GRO detection still owns Bullet Trails"
Reject-Match $init 'bulletTrailVelocityBlocked' "Legacy author-specific Bullet Trails block remains"
Reject-Match $language 'snap back to vanilla 90 m/s' "Bullet Trails settings still promise a hardcoded restoration speed"
Require-Match $language 'return to their original speed' "Bullet Trails settings do not describe original-speed restoration"

Write-Output "Bullet Trail compatibility validation passed"

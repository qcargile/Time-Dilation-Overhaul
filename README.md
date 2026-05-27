# Time Dilation Overhaul

Vanilla Time Dilation is a flat "slow everything, win the fight" button. TDO rebuilds it into a system with cost, variety, and counterplay: enemies that act inside your slow-mo, strain that punishes over-slowing, scanner hacking that isn't free, and a roster of **eleven Sandevistan operating systems** that each play completely differently. Four of them don't slow time at all.

This package also bundles **Enemy Sandevistan Rework** by Phoenicia, which handles the enemy side. Player-side is TDO, enemy-side is ESR, shipped as one mod.

Every value is configurable through a Native Settings UI menu.

---

## Core Systems

### Enemy Sandevistans (Enemy Sandevistan Rework)
NPCs with Sandevistan or Kerenzikov cyberware act inside your time dilation instead of freezing. Each tier is assigned a strength: weaker than yours and they move slowed but not frozen; stronger than yours and they outpace you and use their own abilities. Some enemies get a Stim Pack option. The game's "Time Between Hits" is scaled to your dilation strength, so heavy slow-mo no longer makes you immune to ranged fire; you have to actually dodge.

### Sandevistan Strain
Slowing time too hard damages your body. Strain scales with your Sandevistan's dilation strength, with a threshold below which there's none. It's calculated from resting health, so health-pool consumables don't inflate it.

### Scanning Time Dilation
Sitting in scanner slow-mo to queue quickhacks for free is over. A bar appears while you scan in dilation and decays; it recharges when you leave, and cuts off scanning dilation entirely if it empties. Duration and cooldown scale with Intelligence, and a Netrunner suit adds a bonus by quality.

### Vehicle Time Dilation
A fragment lets you trigger dilation while driving. The car doesn't go faster, but grip and turning improve hard. It's a toggle with a charge bar that decays while on and cuts out if drained.

### Attunement Scaling
Every Sandevistan is attuned to an attribute (Reflexes, Body, Cool, or Technical Ability). Leveling that attribute scales the Sandevistan's signature stat per point: extra duration, longer teleport range, bigger refunds, and so on.

### Visual Effects
The blue-screen effect is graded by dilation strength: weaker Sandevistans get a milder screen, stronger ones get the full blur.

### Bug Fixes
- Synaptic Accelerator and Reflex Tuner no longer drop into cooldown the instant they fire and eat your next Sandevistan activation.
- Looking at a loot container with more than two items no longer blocks time dilation.
- The Sandevistan buff is removed cleanly on exit.
- Addresses the ranged-weapon fire-rate slowdown tied to how EngineTime passes.

---

## The Sandevistans

Each manufacturer's operating system is its own playstyle. Damage bonuses are stripped (you're already buffed by attack speed); the differentiation is in the mechanics.

### Zetatech "Shrike" - Mark & Execute
Slows time, you aren't slowed. ADS to mark hostiles in line of sight within 50m. While active, ADS to track the closest mark, then pull the trigger to execute it. A marksman's Sandevistan. (Reflexes-attuned.)

### Dynalar "Tanto" - Phantom Strike
Requires a blade. Slows time, you aren't slowed. Build Phantom Strike charges with perfect parries, melee crits, and finishers. While blocking with a blade, hit activate to phase behind your target and land a guaranteed crit, spending one charge. (Reflexes-attuned.)

### QianT "Warp Dancer" - Temporal Rewind
The deepest dive in the lineup. Slows time by 99% (you aren't slowed), with bonus move speed and infinite stamina, and records your path the whole time. On expiry it rewinds you back along that path and releases every attack you lined up all at once, then leaves you staggered from the whiplash. Pure burst, paid for in recovery.

### Militech "Falcon" - Weapon Subroutine
Slows time, you aren't slowed, and adapts to the weapon in your hands:
- **Power** - Trick Shot: bullets ricochet, but you can't reload while active.
- **Tech** - Phase Round: a full charge pierces everyone on the shot line and electrocutes, at 15% max HP per shot.
- **Smart** - Saturation Lock: ADS to lock every visible enemy, fire to volley them all; the cyberware disables afterward, proportional to how many Smart shots you fired.

(Technical-Ability-attuned: the weapon-type bonus scales with TA.)

### Raven "Fusillade" - Metalstorm
Slows time, you aren't slowed. Your weapons fire several times faster than their mechanical limit, with no crits or weakspot damage. Each hit ramps damage up toward +100%, and a miss resets the ramp to zero. Recoil climbs hard as the price. (Reflexes-attuned: a hit-driven ammo refill that builds with your ramp.)

### Fuyutsuki "Kurosawa" - Katana Skillsoft
No world time dilation, melee only. Hitting an enemy slows that enemy for the rest of the activation. Kill a slowed enemy and it dismembers a beat later, heals you, and refunds duration. A finisher on a slowed enemy works at any health and doubles the heal and refund. (Body-attuned: duration refund per kill.)

### MoorE "Quantum" - Teleport & Malware
Slows time by 99%, and you're slowed too. While slowed, aim a teleport marker and warp to it; you can't act until you commit or cancel. On arrival it implants Quantum Malware into the nearest enemies, freezing each of them in their own dilated time. Passively makes you harder to hit outside dilation. The **Advanced** model banks two teleport charges back to back. (Cool-attuned: freeze duration and teleport range.)

### Arasaka "Sogimsu" - Watchdog Protocol
No time dilation. A reactive counter-detection AI runs in the background and auto-quickhacks (Memory Wipe + Reboot Optics) any hostile about to spot you. It ends early if you're pulled into combat, and drops you into an empowered Optical Camo when it ends so you can reposition. A pure stealth tool. (Cool-attuned.)

### Anvil Defense "Juggernaut" - Armor Lock
No time dilation. Lock down to absorb a set amount of incoming damage with full status immunity. You can't act while locked. End it early or let it auto-release at the cap, and the stored damage detonates as a 360° kinetic shockwave that knocks down everyone nearby. (Body-attuned: damage and fall-damage reduction.)

### Wraith Munitions "Pyrolith" - Demolition
No time dilation. Ranged hits detonate a thermal explosion on impact, and thrown grenades split into clusters of the same type. Grenade cooldown is slashed and throw range extended while active. (Technical-Ability-attuned: explosion resistance.)

### Militech "Apogee"
The vanilla iconic, left stock. An optional Biological Strain mechanic ships **off by default** and can be toggled on in settings.

---

## Settings

Everything is configured from **Mods → TDO** in the game menu.

- Time dilation reads as "slows time **by** x%" here, the inverse of the game's "slows time **to** x%." Setting `75` means the game shows "slows time to 25%."
- Most changes don't apply until you reload a save.
- The ESR (enemy) options live in their own subsection under the same tab.
- No Native Settings UI? Edit `bin\x64\plugins\cyber_engine_tweaks\mods\tdo\config\userConfig.lua` directly; changes apply on the next game start. Don't touch anything in quotes.

---

## Requirements

- [Cyber Engine Tweaks](https://www.nexusmods.com/cyberpunk2077/mods/107)
- [RED4ext](https://www.nexusmods.com/cyberpunk2077/mods/2380)
- [Redscript](https://www.nexusmods.com/cyberpunk2077/mods/1511)
- [Codeware](https://www.nexusmods.com/cyberpunk2077/mods/7780)
- [ArchiveXL](https://www.nexusmods.com/cyberpunk2077/mods/4198)
- [TweakXL](https://www.nexusmods.com/cyberpunk2077/mods/4197)
- [Native Settings UI](https://www.nexusmods.com/cyberpunk2077/mods/3518)
- Audioware (used by the bundled Enemy Sandevistan Rework for its sounds)

## Installation

Extract to your Cyberpunk 2077 root folder, or install with a mod manager. To uninstall, remove the files; any cyberware the mod adds disappears on the next load.

---

## Credits

- **TeslaCoiled** - code.
- **brahmax** and **z9** - design, ideas, and testing from the first message about fixing Sandevistans onward.
- **Phoenicia** - Enemy Sandevistan Rework, bundled here as a collaboration.
- **walrus420** - corporation and cyberware logos.
- Testers **Derisat** and **jermz**.
- **psiberx**, **NexusGuy999**, **scissors**, and the Cyberpunk 2077 modding community.
- The WolvenKit, Cyber Engine Tweaks, and Redscript teams.

## License

MIT - see [LICENSE](LICENSE).

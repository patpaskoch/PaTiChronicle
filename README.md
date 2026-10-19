# PaTiChronicle

**Every run tells a story.** A chronicle of your dungeon runs for World of Warcraft: Forever (Interface 16001):
a run clock, a run report after every dungeon, best times, your run history and achievements for teamplay,
survival and personal bests. We play together against our own earlier runs — not against each other.

> Formerly **PaTiCompetition** (renamed 2026-10-19). The old `/pcomp` command still works until 0.3.0. Saved data:
> WoW keeps it per addon folder, so copy `WTF/…/SavedVariables/PaTiCompetition.lua` to `PaTiChronicle.lua` once
> (WoW closed) and rename `PaTiCompetitionDB` inside to `PaTiChronicleDB`; otherwise PaTiChronicle starts fresh.

> Status: 0.2.0, not yet tested in game. Which events this client really sends is checked by the probe
> (`/pchron probe`); achievements that need data the client does not deliver are never given.

## The run report
Opens when a run ends (or with `/pchron`). Three tabs, first the shared success, then your part, then the details:
- **Overview** — dungeon, run time, new best time, the group (portrait, name in class colour, level and class — no
  numbers per person, no ranking), group achievements, your highlight and the run as a strip.
- **My performance** — your achievements in this run and your development: run time, your deaths, your aggro
  moments (tank: the group's), each against your own average of your last runs in this dungeon and role.
  Better shows as "better than your average", worse only as "above your average".
- **Timeline** — the run as a strip (fights, boss fights, deaths, aggro moments) and the list of what happened, with
  time and fight number. Who died is named; causes never. Aggro moments carry a name only when they were yours.

## Run rules
- **Start:** the first fight inside a 5-player dungeon.
- **Continues** through deaths, wipes, running back as a ghost, `/reload` and disconnects.
- **Completed:** your click "End run – end boss defeated" (••• menu, the clock's right-click menu, `/pchron end`), or
  the end boss of this dungeon. The end boss is learned: end a run by hand within 5 minutes after a boss kill and
  that boss ends the run by itself next time (needs boss events from the client).
- **Aborted:** your click, another dungeon, more than 15 minutes outside, or a login more than 30 minutes after the
  logout. Aborted runs are not saved and give no achievements.
- **Counted** (best times, streaks, team): completed, with at least 3 players at the end.
- **Without gaps:** no `/reload`, no disconnect, never left the dungeon except as a ghost. Achievements that say
  "nothing happened" (no death, no aggro) need a run without gaps.

## Achievements
Only for data the client delivers readably; never for missing or incomplete data (then "not checkable" with the
reason in the tooltip). Always positive; nothing is put on another player. The rule of each one is in its tooltip.

| Achievement | Rule |
|---|---|
| New best time | counted, faster than the best time of this dungeon (or of this group) |
| First time set | the first counted run in this dungeon |
| Survived together | no member died (run without gaps) |
| No wipe | deaths, but never the whole group at once |
| Well-rehearsed team ×N | the 3rd, 5th, 10th … counted run with the same members |
| Steadfast (×N in a row) | you did not die (counted, without gaps) |
| Improved | better than your average (at least 3 earlier runs in this dungeon and role) in run time, deaths or aggro moments |
| Aggro under control (tank) | no aggro moment of another member in the whole run |
| Untouched (healer) / Clean aggro (damage) | no aggro moment of yours in the whole run |

An **aggro moment**: an enemy attacks a non-tank for at least 3 seconds without a break (threat status 2 or 3).
Your role: the group role, or "My role" in the settings. Without a known tank the others' moments are not counted.

## Run clock
One quiet line inside a dungeon: dungeon, run time, best time. Right click: end run, abort, open the report, hide.
Drag to move. Switch it off in the settings or with `/pchron hud`.

## PaTiSuite

This addon is part of the **PaTiSuite** — a collection of small addons for World of Warcraft: Forever.
Each one is installed on its own and works on its own; none of them is needed by another.
Overview of all addons: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin).

## Installation
1. Download the release zip (`PaTiChronicle-<version>.zip`).
2. Unpack it and copy the folder `PaTiChronicle` into `World of Warcraft/<client>/Interface/AddOns/`.
3. Start WoW and enable PaTiChronicle in the AddOns list.

## Commands
`/pchron` or `/patichronicle` (report on / off) — `show` · `hide` · `test` (example run on / off) · `lock` ·
`unlock` · `reset` (window and clock back to their default position) · `settings` · `end` (end the run: end boss
defeated) · `abort` · `hud` (clock on / off) · `probe` (what this client delivers) · `clear` (clear the probe) ·
`version`

## Settings
••• → Settings (or `/pchron settings`), like the other PaTi addons: language, scale, my role, show the run clock,
open the report at the end, lock window, theme (WoForever by default), panel opacity, the test mode switch and
Restore Defaults (keeps the position, runs, best times and the probe).

## Known limitations
- The combat log is reserved for the Blizzard UI in this client: no damage, healing, interrupts or killing blows.
  `C_DamageMeter` exists; the probe lists its functions, nothing is used yet.
- Boss events and readable threat/death states are not confirmed yet (probe, INGAME_TESTING.md T1–T7).
- Only what your client sees; members far away may be missed.
- No icon yet.

## Development

Architecture, tests and engineering rules of the suite: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin). PaTiAdmin is not a WoW addon — players do not install it. The shared UI code (PaTiShared) is already embedded in this addon's `Shared/` folder; there is nothing extra to install.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.

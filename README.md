# PaTiCompetition

A dungeon competition for World of Warcraft: Forever (Interface 16001): a clock runs from the first fight in a
dungeon until the end boss is dead, then an end screen shows every member of the group with portrait,
name, damage done, healing, damage taken, interrupts, killing blows, pulled aggro, deaths and a score. More than a
damage meter: the group plays against its own best time and compares who did best.

> Status: 0.1.0 = test run (probe) + the end screen "Party Competition" (`/pcomp show`, `/pcomp test`). The clock
> does not stop at the end boss yet. Not yet tested in game.

## What 0.1.0 does
- Checks whether the client offers Blizzard's damage meter data (`C_DamageMeter`). The combat log is reserved for
  the Blizzard UI in this client, so damage, healing, damage taken, interrupts, killing blows and deaths stay 0 for
  now (owner test 2026-10-19)
- Counts pulled aggro per member: an enemy turns to them (threat status rises to 2 or more), with their role
- Notes whether the client sends boss fight events (start, end, kill) and with which boss number
- Starts a clock with the first fight inside an instance; boss fights are timed from there
- A new run (another instance) starts the totals from zero
- Shows nothing by itself except a chat line when the clock starts and when a boss fight ends.
  Nothing is cast, targeted or sent to others

Results are saved in `PaTiCompetitionDB` (SavedVariables, per character) with `/reload` or logout.

## End screen "Party Competition"
`/pcomp show` opens it with the values of the current run, `/pcomp test` with example values. Five cards side by
side (tank, healer, then damage dealers), each with portrait (framed in the role colour: tank blue, healer green,
damage red), name, role, damage, healing, damage taken, interrupts, killing blows, pulled aggro, deaths and the
score (number and bar 0–100). The best score gets a gold frame. Esc or ••• → Hide closes it. Colours: WoForever theme (gold and bronze)
by default; PaTiSuite can switch it.

**Score (0–100), relative to the group of this run:** 20 base + 50 × your best share (damage ÷ most damage, healing ÷
most healing; for the tank also damage taken ÷ most taken) + 15 × interrupts ÷ most interrupts + 15 × killing blows ÷
most killing blows − 10 per death − 5 per pulled aggro (not for the tank). If nobody interrupted or struck a killing
blow, those points go to the share. The tank is whoever chose the tank role, else whoever took the most damage.

## Planned
- Run clock in a small window, stops when the end boss of the dungeon dies (a list per dungeon) or with a
  "Finish" button; then the end screen opens
- Best time per dungeon

## PaTiSuite

This addon is part of the **PaTiSuite** — a collection of small addons for World of Warcraft: Forever.
Each one is installed on its own and works on its own; none of them is needed by another.
Overview of all addons: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin).

## Installation
1. Download the release zip (`PaTiCompetition-<version>.zip`).
2. Unpack it and copy the folder `PaTiCompetition` into `World of Warcraft/<client>/Interface/AddOns/`.
3. Start WoW and enable PaTiCompetition in the AddOns list.

## Commands
`/pcomp` or `/paticompetition` (end screen on / off) — `show` · `hide` · `test` (test mode: example values on / off) ·
`lock` · `unlock` · `reset` (window back to its default position) · `settings` · `probe` (test results in the chat) ·
`clear` (clear the test results and start again) · `version`

## Settings
••• → Settings (or `/pcomp settings`), like the other PaTi addons: language, scale, lock window, theme (WoForever by
default), panel opacity, the test mode switch top right and Restore Defaults (keeps the position and the test
results). ••• also has Lock, Test Mode and Hide.

## Known limitations
- No source for damage, healing, interrupts, killing blows and deaths yet: the combat log is reserved for the Blizzard
  UI here. The end screen shows these as 0; only pulled aggro is counted.
- No icon yet.

## Development

Architecture, tests and engineering rules of the suite: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin). PaTiAdmin is not a WoW addon — players do not install it. The shared UI code (PaTiShared) is already embedded in this addon's `Shared/` folder; there is nothing extra to install.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.

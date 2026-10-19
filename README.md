# PaTiCompetition

A dungeon competition for World of Warcraft: Forever (Interface 16001): a clock runs from the first fight in a
dungeon until the end boss is dead, then an end screen shows every member of the group with portrait,
name, damage done, healing, damage taken, interrupts, killing blows, pulled aggro, deaths and a score. More than a
damage meter: the group plays against its own best time and compares who did best.

> Status: 0.1.0 = test run (probe) + the end screen "Party Competition" (`/pcomp show`, `/pcomp test`). The clock
> does not stop at the end boss yet. Not yet tested in game.

## What 0.1.0 does
- Counts the combat log: how many entries arrive, how many have readable numbers and how many are secret
- Adds up damage done, damage taken, healing (without overhealing), deaths, interrupts and killing blows for you,
  your party and the pets
- Counts pulled aggro per member: an enemy turns to them (threat status rises to 2 or more), with their role
- Notes whether the client sends boss fight events (start, end, kill) and with which boss number
- Starts a clock with the first fight inside an instance; boss fights are timed from there
- A new run (another instance) starts the totals from zero
- Keeps the last 40 enemy deaths with their NPC number (to build the list of end bosses later)
- Shows nothing by itself except a chat line when the clock starts and when a boss fight ends.
  Nothing is cast, targeted or sent to others

Results are saved in `PaTiCompetitionDB` (SavedVariables, per character) with `/reload` or logout.

## End screen "Party Competition"
`/pcomp show` opens it with the values of the current run, `/pcomp test` with example values. Five cards side by
side (tank, healer, then damage dealers), each with portrait (framed in the role colour: tank blue, healer green,
damage red), name, role, damage, healing, damage taken, interrupts, killing blows, pulled aggro, deaths and the
score. The best score gets a gold frame. Esc or ••• → Hide closes it. Colours: WoForever theme (gold and bronze)
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
`/pcomp` or `/paticompetition` — `show` (end screen) · `test` (end screen with example values) ·
`probe` (test results in the chat) · `reset` (clear and start again) · `version`

## Known limitations
- Test run only: no window, no end screen, no score yet.
- Only what this client sees: members far away may miss entries (WoW's combat log range).
- No icon yet.

## Development

Architecture, tests and engineering rules of the suite: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin). PaTiAdmin is not a WoW addon — players do not install it. The shared UI code (PaTiShared) is already embedded in this addon's `Shared/` folder; there is nothing extra to install.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.

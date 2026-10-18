# PaTiCompetition

A dungeon competition for World of Warcraft: Forever (Interface 16001): a clock runs from the first fight in a
dungeon until the end boss is dead, then an end screen in the style of Left 4 Dead shows every member of the group
with portrait, name, damage done, damage taken, healing and a score. More than a damage meter: the group plays
against its own best time.

> Status: 0.1.0 is only a **test run** (probe). It finds out what the Forever client delivers before the clock and
> the end screen are built. Not yet tested in game.

## What 0.1.0 does
- Counts the combat log: how many entries arrive, how many have readable numbers and how many are secret
- Adds up damage done, damage taken, healing (without overhealing) and deaths for you, your party and the pets
- Notes whether the client sends boss fight events (start, end, kill) and with which boss number
- Starts a clock with the first fight inside an instance; boss fights are timed from there
- Keeps the last 40 enemy deaths with their NPC number (to build the list of end bosses later)
- Shows nothing by itself except a chat line when the clock starts and when a boss fight ends.
  Nothing is cast, targeted or sent to others

Results are saved in `PaTiCompetitionDB` (SavedVariables, per character) with `/reload` or logout.

## Planned (after the test run)
- Run clock in a small window, stops when the end boss of the dungeon dies (a list per dungeon) or with a
  "Finish" button
- End screen: a grid of five cards (one per member) with portrait, name, damage, damage taken, healing and score
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
`/pcomp` or `/paticompetition` — `probe` (test results in the chat) · `reset` (clear and start again) · `version`

## Known limitations
- Test run only: no window, no end screen, no score yet.
- Only what this client sees: members far away may miss entries (WoW's combat log range).
- No icon yet.

## Development

Architecture, tests and engineering rules of the suite: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin). PaTiAdmin is not a WoW addon — players do not install it. The shared UI code (PaTiShared) is already embedded in this addon's `Shared/` folder; there is nothing extra to install.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.

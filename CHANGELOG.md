# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.
### Added
- Group result, tab **Contribution** (redesign step 9, after the probe 2026-10-19): damage, healing, interrupts and
  dispels per member and for the group, from WoW's own damage meter (`C_DamageMeter`, read only, never reset). Its
  values are secret during a fight, so every session is read after the fight; a run that ends in combat gets its
  last fight after combat. Fixed order, nothing highlighted, no ranking. Older runs show "n/a" with the reason.
  Test mode has example values.

### Fixed
- A member's changed role, class or level during a run is now taken over (owner 2026-10-19: the healer change was
  not shown); before, the first reading stayed.
- A wipe was not counted when your own death ended combat before the last member died (owner 2026-10-19): it
  now belongs to the last fight if that ended at most 60 seconds earlier.
- Group result: always the portrait, no 3D character (owner 2026-10-19: the 3D figure came and went).


## [Unreleased] — 0.2.0 PaTiChronicle
### Changed
- Renamed from PaTiCompetition to **PaTiChronicle** — "Every run tells a story" (owner decision 2026-10-19): a
  chronicle of dungeon runs instead of a competition between players. GitHub repo renamed (history kept). Commands
  `/pchron`, `/patichronicle`; the old `/pcomp` still works until 0.3.0. SavedVariables `PaTiChronicleDB` (the old
  `PaTiCompetitionDB` file is copied over once by hand, see README). In-game tests start again as PT-CHRON-…; the
  old PT-COMP-… are retired.

### Added
- Theme **Soft Fantasy** (PaTiShared, owner wish 2026-10-19): calm slate blue, grey and violet with a muted
  lavender accent — the fourth choice in the settings and in PaTiSuite.
- Run report "Every run tells a story" (owner decision 2026-10-19) instead of player cards and a score: three tabs —
  Overview (dungeon, run time, new best time, the group without numbers per person, group achievements, your
  highlight, the run as a strip), My performance (your achievements and your development against your own average
  in this dungeon and role), Timeline (fights, boss fights, deaths, aggro moments with time and fight number).
- Run rules: start with the first fight in a 5-player dungeon; continues through deaths, ghost run-backs, /reload;
  completed by your click or the learned end boss; aborted by click, another dungeon, 15 min outside or 30 min
  logged out; counted with at least 3 players. Best times per dungeon and per group, the last 20 runs per dungeon.
- Achievements only for reliable data: New best time, First time set, Survived together, No wipe, Well-rehearsed
  team, Steadfast, Improved, Aggro under control (tank), Untouched (healer), Clean aggro (damage). Missing data:
  "not checkable" with the reason.
- Run clock line in dungeons (right click: end run, abort, report, hide). Settings: my role, show the run clock, open
  the report at the end. Commands `end`, `abort`, `hud`.
- Probe, redesign step 1: what `C_DamageMeter` delivers (available, categories, session types, the fields of a
  session and a player entry, readable or secret — after and during a fight; read only, never reset), whether a 3D
  character (`PlayerModel`) works and which big fonts exist.
- Probe: boss events, threat and death state readable or secret, fights, the function names of `C_DamageMeter`.

### Removed
- The end screen with five player cards, seven values, points per value and the score 0–100 (`Score.lua`,
  `Results.lua`); the combat-log parser.

### Added
- Ways to open the run report (owner 2026-10-19: "tedious"): a minimap button (left click: report on / off, right
  click: the menu, drag: move around the minimap; setting "Show the minimap button", `/pchron minimap`), a key
  binding "Run report on / off" in WoW's key binding menu (nothing is bound automatically), and a left click on the
  run clock line.

### Changed
- Redesign of the run report (owner approval 2026-10-19): a game results screen instead of a dashboard. Four tabs as
  text tabs with an accent underline — Overview, **Group result** (new), My performance, Timeline. Five type levels
  (Blizzard fonts, bigger than before), one grid (20 px edges, 24 px between sections, 30 px rows), one strong element
  per tab, no boxes inside the page. Window 640 × 560; the report is fully opaque (the opacity setting is the real
  cover; a saved 0.75 — the old default — becomes 1 once).
- Overview: completion kicker, dungeon, the run time large, new best time, the group, achievements as medallions, two
  highlights by fixed rules (most deaths in a fight or a wipe, the longest fight).
- Group result: the five members side by side (3D character where the probe confirmed it, else the portrait), a calm
  table in fixed order — deaths, time dead, attacks of 3 s or more, time in the group, the group total; a click shows
  the times. "Contribution" (damage, healing, interrupts) stays off until C_DamageMeter is confirmed. Missing values:
  "n/a" with the reason.
- My performance: no mini bar charts; every value with its change in words ("2:29 faster than your average"), "your
  best run here", and "room to grow" for values above your average.
- Timeline: time axis, clustered symbols, aligned times, a line between fights, a detail column for the chosen event.
  Aggro is now the orange circle (the green triangle read as "good").

### Fixed
- Without a run yet, PaTiSuite "show all" said "Chronicle: not possible in combat" and a chat line came each time
  (owner screenshot 2026-10-19): the report window now opens with the note "No run yet …" instead, with a button
  "Test mode: view an example run".

- Overview: the reason under a group achievement was cut off ("0:48 faster than your b…"); it now takes two lines.
- "Improved" named the weaker value on a tie ("deaths 0, average 0.2"); it now names the one with the larger average.

### Known Issues
- Not tested in game. Boss events, readable threat and death states are unconfirmed (probe, PT-CHRON-010…016);
  achievements that need them stay "not checkable" until then. No icon yet.

Earlier, as PaTiCompetition 0.1.0 (never released):

### Added
- New addon (owner wish 2026-10-18): dungeon competition "PaTi Competition" — run clock until the end boss, then an
  end screen (portrait, name, damage, damage taken, healing, pulled aggro, score). 0.1.0 is the test run only.
- Test run: counts the combat log (readable / secret entries), adds up damage done, damage taken, healing (without
  overhealing) and deaths per member (pets count for their owner), notes the boss fight events (start, end, kill)
  with boss number and time, starts a clock with the first fight in an instance, keeps the last 40 enemy deaths with
  their NPC number. `/pcomp probe`, `reset`, `version`.
- Test run, owner wish 2026-10-19: counts pulled aggro per member (threat status rises to 2 or more, via
  `UNIT_THREAT_SITUATION_UPDATE`) and notes the role. Later in the score: minus points, except for the tank.
- `PaTiCompetitionDB`, schema 1: the test results (`probe`), theme (default WoForever), window position. English texts, German translation. MIT license.
- End screen "Party Competition" after the owner's design (2026-10-19): `/pcomp show` (current run), `/pcomp test`
  (example values). Five cards — tank, healer, damage — with portrait in a role-coloured frame, name, role, damage,
  healing, damage taken, interrupts, killing blows, pulled aggro, deaths and the score 0–100 (formula in the README);
  the best score gets a gold frame. Esc closes it. WoForever theme by default.
- Interrupts (`SPELL_INTERRUPT`) and killing blows (`PARTY_KILL`, owner question 2026-10-19) per member; a new run
  starts the totals from zero.

- Test mode and settings like the other PaTi addons (owner wish 2026-10-19): ••• → Settings / `/pcomp settings`
  with language, scale, lock window, theme, panel opacity, test switch and Restore Defaults; ••• → Test Mode;
  `/pcomp test` switches the example values on and off. Commands `hide`, `lock`, `unlock`, `settings`; `reset` now
  moves the window back to its default position (as everywhere), `clear` clears the test results.

- End screen: the score also as a bar 0–100 under the number (role colour, gold for the best; owner 2026-10-19).

- End screen easier to read (owner 2026-10-19): more space and a line between the values; every value shows the
  points it gives as a bar and a number (green plus, red minus); level and class (class colour) under the name.
  Cards 176 × 500.

### Removed
- The combat log is no longer read (owner screenshot 2026-10-19: "PaTiCompetition wurde geblockt"): this client
  reserves `COMBAT_LOG_EVENT_UNFILTERED` for the Blizzard UI. The test run now checks for `C_DamageMeter` instead.

### Known Issues
- No source for damage, healing, damage taken, interrupts, killing blows and deaths yet: they show 0.
- The clock does not stop at the end boss yet; the end screen opens only by command.

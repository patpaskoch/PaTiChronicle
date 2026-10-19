# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.2.0 PaTiChronicle
### Changed
- Renamed from PaTiCompetition to **PaTiChronicle** — "Every run tells a story" (owner decision 2026-10-19): a
  chronicle of dungeon runs instead of a competition between players. GitHub repo renamed (history kept). Commands
  `/pchron`, `/patichronicle`; the old `/pcomp` still works until 0.3.0. SavedVariables `PaTiChronicleDB` (the old
  `PaTiCompetitionDB` file is copied over once by hand, see README). In-game tests start again as PT-CHRON-…; the
  old PT-COMP-… are retired.

### Added
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
- Probe: boss events, threat and death state readable or secret, fights, the function names of `C_DamageMeter`.

### Removed
- The end screen with five player cards, seven values, points per value and the score 0–100 (`Score.lua`,
  `Results.lua`); the combat-log parser.

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

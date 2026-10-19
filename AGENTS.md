# AGENTS.md — PaTiChronicle

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: "Every run tells a story" — a chronicle of dungeon runs: run clock, run report (Overview, My
  performance, Timeline), best times, run history, achievements. We play together against our own earlier runs:
  **no ranking between players, no score 0–100, no winner** (owner decision 2026-10-19).
  **Display only:** never casts, targets, marks or sends anything; no addon messages.
- Not here: dungeon help and map (→ PaTiDungeon), live threat (→ PaTiAggro), quests (→ PaTiQuest), a damage meter.
- Formerly PaTiCompetition (renamed 2026-10-19); `/pcomp` stays as an alias until 0.3.0 (Settings.lua).
- Files: `Logic.lua` (settings, migration, probe, clock; pure) · `Run.lua` (run rules and events; pure) ·
  `Chronicle.lua` (history, best times, achievements, development; pure) · `Sample.lua` (example run through the
  same rules; pure) · `Report.lua` (window, tabs, building blocks, Overview) · `ReportGroup.lua` · `ReportMine.lua` · `ReportTimeline.lua`
  · `Hud.lua` (run clock line) · `Minimap.lua` (minimap button) · `Probe.lua` (read-only API probe) · `Bindings.xml`
  (key binding `PaTiChronicle_Toggle`) · `PaTiChronicle.lua` (adapters, events, runs) · `Settings.lua` (settings, menu,
  commands, probe output) · `Locales/` · `Shared/` (PaTiShared, synced — never edit). Tests: `tests/*_spec.lua`.
- Rules live in the headers of `Run.lua` (start/end/abort/counted/without gaps) and `Chronicle.lua` (achievements);
  README "Run rules" and "Achievements" and the `RULE_*` locale texts must say the same — change them together.
- **Achievements only for reliable data** (`Chronicle.Reliable`): never for missing, secret or incomplete data —
  then a `missing` entry with the reason. Never name another player for an aggro moment; never a cause of death.
- **Never register `COMBAT_LOG_EVENT_UNFILTERED`:** this client reserves it for the Blizzard UI (forbidden popup,
  owner 2026-10-19; pcall does not help). `C_DamageMeter`: only its function names are listed by the probe.
- Secret values: a secret threat status or death state is recorded as "secret" (`run.data.*Secret`), never compared.
- Hot path: `UNIT_HEALTH` (filtered to player/party1-4, one `UnitIsDeadOrGhost` per member) and
  `UNIT_THREAT_SITUATION_UPDATE`. The HUD ticks once a second only while shown and a run is running.
- SavedVariables: `PaTiChronicleDB` (per character), schema 2 — settings, position, `hud`, `probe`, `run` (running),
  `report` (the last one), `runs[key]` (last 20 summaries), `bests`, `groupBests`, `teams`, `streaks`, `endBosses`.
  Any shape change: bump `Logic.SCHEMA`, add a migration step and a test.
- Secure / combat-sensitive: none. Windows: the report is the suite's main window (`UI.CreateWindow`); the HUD is
  a plain frame with its own position.
- Settings like PaTiDungeon (`Logic.DEFAULTS`, `Logic.RestoreDefaults`, `UI.AddWindowSettings`); test mode is
  runtime only (`Sample.Report`).

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `INGAME_TESTING.md`.

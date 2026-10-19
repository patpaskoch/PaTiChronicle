# AGENTS.md — PaTiCompetition

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: dungeon competition — run clock until the end boss, end screen with damage, damage taken, healing, pulled
  aggro and a score per member (pulled aggro: minus points except for the tank).
  **Display only:** never casts, targets, marks or sends anything; no addon messages.
- 0.1.0 = the test run (probe): what the Forever client delivers (combat log, secret values, boss fight events).
  Build the clock window and the end screen only on what the probe confirmed (docs/WOW_API_COMPAT.md).
- Files: `Logic.lua` (combat-log parsing, totals, run clock, migration; pure, tested) · `PaTiCompetition.lua`
  (adapters, events, commands) · `Locales/` · `Shared/` (PaTiShared, synced — never edit).
- Hot path: `COMBAT_LOG_EVENT_UNFILTERED` — keep `Logic.Parse` / `Logic.Record` cheap (no string building, no UI).
- Secret values: an entry with a secret field is only counted (`combatLog.secret`), never added up or printed.
- SavedVariables: `PaTiCompetitionDB` (per character), schema 1 — `probe` (see `Logic.NewProbe`). Any shape change:
  bump `Logic.SCHEMA`, add a migration step and a test.
- Secure / combat-sensitive: none. Slash commands: `/pcomp`, `/paticompetition`.

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `INGAME_TESTING.md`.

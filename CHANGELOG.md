# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.1.0
### Added
- New addon (owner wish 2026-10-18): dungeon competition "PaTi Competition" — run clock until the end boss, then an
  end screen like Left 4 Dead (portrait, name, damage, damage taken, healing, score). 0.1.0 is the test run only.
- Test run: counts the combat log (readable / secret entries), adds up damage done, damage taken, healing (without
  overhealing) and deaths per member (pets count for their owner), notes the boss fight events (start, end, kill)
  with boss number and time, starts a clock with the first fight in an instance, keeps the last 40 enemy deaths with
  their NPC number. `/pcomp probe`, `reset`, `version`.
- `PaTiCompetitionDB`, schema 1: the test results (`probe`). English texts, German translation. MIT license.

### Known Issues
- No window, end screen or score yet (follows after the test run).

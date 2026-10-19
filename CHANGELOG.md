# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.1.0
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

### Removed
- The combat log is no longer read (owner screenshot 2026-10-19: "PaTiCompetition wurde geblockt"): this client
  reserves `COMBAT_LOG_EVENT_UNFILTERED` for the Blizzard UI. The test run now checks for `C_DamageMeter` instead.

### Known Issues
- No source for damage, healing, damage taken, interrupts, killing blows and deaths yet: they show 0.
- The clock does not stop at the end boss yet; the end screen opens only by command.

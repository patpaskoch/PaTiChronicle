# Ingame Testing – PaTiCompetition

World of Warcraft: Forever
Interface: 16001

Diese Datei dokumentiert ausschließlich Tests im echten WoW-Client.

Automatisierte Tests, CI und Code Review zählen NICHT als Ingame-Verifikation.
Regeln und Eintragen von Ergebnissen: [PaTiAdmin/docs/TESTING.md](https://github.com/patpaskoch/PaTiAdmin/blob/main/docs/TESTING.md#in-game-test-files).

## Legende

- [ ] offen / noch nicht bestätigt
- [x] vom Owner im echten Client bestätigt
- ❌ FAIL = im echten Client fehlgeschlagen
- 🔧 FIX IMPLEMENTED = Codefix vorhanden, Retest noch offen
- ✅ VERIFIED = erfolgreich im echten Client bestätigt
- MANUAL RETEST REQUIRED = erneuter Test notwendig

## Installation / Laden

- [ ] PT-COMP-001 Login ohne Lua-Fehler; PaTiCompetition erscheint in der AddOn-Liste mit Beschreibung
  ❌ FAIL 2026-10-19 – Fenster „PaTiCompetition wurde geblockt … der Blizzard-UI vorbehalten“ (Kampflog)
  🔧 FIX IMPLEMENTED 2026-10-19 – Kampflog wird nicht mehr angemeldet · MANUAL RETEST REQUIRED
- [ ] PT-COMP-002 `/reload` ohne Lua-Fehler; `/pcomp` zeigt die Hilfe, `/pcomp version` die Version 0.1.0
- [ ] PT-COMP-003 Login und `/reload`: kein Fenster „PaTiCompetition wurde geblockt“

## Testlauf (Probe)

- [ ] PT-COMP-010 `/pcomp probe` direkt nach dem Login: Zeilen „Kampflog … Schadensmesser-API“ und „Boss-Meldungen“
  mit ja/nein erscheinen (Ausgabe melden oder nach `/reload` die SavedVariables-Datei schicken)
- ~~PT-COMP-011 Draußen Gegner töten, dann `/pcomp probe`: „Kampflog-Einträge“ steigt, Schaden steht da~~
  - RETIRED 2026-10-19 – der Kampflog ist der Blizzard-UI vorbehalten (Fenster „wurde geblockt“)
- ~~PT-COMP-012 In einer Gruppe mit Heiler: Heiler steht mit Heilung da, Mitglieder mit ihrem Schaden~~
  - RETIRED 2026-10-19 – der Kampflog ist der Blizzard-UI vorbehalten
- [ ] PT-COMP-013 Im Dungeon: beim ersten Kampf erscheint „Uhr gestartet: <Dungeon> (<Nummer>)“
- [ ] PT-COMP-014 Im Dungeon einen Boss töten: erscheint „Bosskampf vorbei: <Name> (#<Nummer>) bei <Zeit>“? Wenn nicht:
  melden (dann sendet der Client keine Boss-Meldung)
- [ ] PT-COMP-015 Nach dem Dungeon `/pcomp probe`: Liste der Bosskämpfe mit Name und Nummer (Ausgabe melden;
  daraus entsteht die Endboss-Liste)
- [ ] PT-COMP-016 `/pcomp reset`: „Testergebnis gelöscht.“, danach zeigt `/pcomp probe` wieder 0 Einträge
- [ ] PT-COMP-017 In der Gruppe: zieht ein Nicht-Tank Aggro (ein Gegner haut ihn), steht bei `/pcomp probe` hinter
  seinem Namen „Aggro gezogen 1“ (oder mehr) und seine Rolle; beim Tank zählt es auch
  (gibt später aber keine Minuspunkte)

## Endbildschirm „Party Competition“

- [ ] PT-COMP-020 `/pcomp test`: Fenster mit Titel „Party Competition“, „RUNDENAUSWERTUNG · Todesminen · 24:13“,
  „Beispielwerte“ und TEST-Abzeichen; fünf Karten nebeneinander: Arden (Tank), Mira (Heiler), dann Nyra, Kael, Korr
- [ ] PT-COMP-021 Karten: Rahmen ums Bild in Rollenfarbe (Tank blau, Heiler grün, Schaden rot), Name in derselben Farbe,
  sieben Werte mit Symbol (Schaden, Heilung, Erlittener Schaden, Unterbrechungen, Todesstöße, Aggro gezogen, Tode),
  nichts abgeschnitten oder überlappt; Symbole sichtbar (kein grünes Fragezeichen)
- [ ] PT-COMP-022 Beste Wertung hat einen goldenen Rahmen und goldene Zahl; Zahlen deutsch „18,4 Tsd.“
- [ ] PT-COMP-023 Esc schließt das Fenster; ••• → Ausblenden schließt es; am Kopf verschiebbar, Position bleibt nach
  `/reload`
- [ ] PT-COMP-024 Nach echten Kämpfen `/pcomp show`: deine Gruppe mit echten Porträts und Werten; Wertung wirkt fair
  (Rückmeldung zur Formel)
- ~~PT-COMP-025 Unterbrechungen und Todesstöße werden gezählt: Werte auf der Karte und bei `/pcomp probe`~~
  - RETIRED 2026-10-19 – kamen aus dem Kampflog (der Blizzard-UI vorbehalten)

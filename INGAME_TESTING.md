# Ingame Testing – PaTiChronicle

World of Warcraft: Forever
Interface: 16001

Diese Datei dokumentiert ausschließlich Tests im echten WoW-Client.

Automatisierte Tests, CI und Code Review zählen NICHT als Ingame-Verifikation.
Regeln und Eintragen von Ergebnissen: [PaTiAdmin/docs/TESTING.md](https://github.com/patpaskoch/PaTiAdmin/blob/main/docs/TESTING.md#in-game-test-files).

PaTiChronicle ist das frühere PaTiCompetition (umbenannt 2026-10-19). Die alten `PT-COMP-001…034` stehen unten als
RETIRED (Legacy) und werden nie wiederverwendet; kein früheres `[x]` gab es zu übertragen.

## Legende

- [ ] offen / noch nicht bestätigt
- [x] vom Owner im echten Client bestätigt
- ❌ FAIL = im echten Client fehlgeschlagen
- 🔧 FIX IMPLEMENTED = Codefix vorhanden, Retest noch offen
- ✅ VERIFIED = erfolgreich im echten Client bestätigt
- MANUAL RETEST REQUIRED = erneuter Test notwendig

## Installation / Laden

- [ ] PT-CHRON-001 Login ohne Lua-Fehler und ohne Fenster „wurde geblockt“; PaTiChronicle erscheint in der
  AddOn-Liste mit Beschreibung („Jeder Run erzählt eine Geschichte …“); der alte Ordner `PaTiCompetition` ist weg
- [ ] PT-CHRON-002 `/reload` ohne Lua-Fehler; `/pchron` und `/patichronicle` antworten, `/pchron version` zeigt 0.2.0
- [ ] PT-CHRON-003 Der alte Befehl `/pcomp` funktioniert noch genauso wie `/pchron`

## Legacy – frühere PaTiCompetition-Tests (RETIRED)

Diese IDs gehörten PaTiCompetition 0.1.0 (Endbildschirm mit Spielerkarten und Wertung 0–100). Sie bleiben als
Historie stehen, werden nie wiederverwendet und gelten nicht für PaTiChronicle.

### Legacy: Installation / Laden
- ~~PT-COMP-001 Login ohne Lua-Fehler; PaTiCompetition erscheint in der AddOn-Liste mit Beschreibung~~
  - ❌ FAIL 2026-10-19 – Fenster „PaTiCompetition wurde geblockt … der Blizzard-UI vorbehalten“ (Kampflog)
  - 🔧 FIX IMPLEMENTED 2026-10-19 – Kampflog wird nicht mehr angemeldet · MANUAL RETEST REQUIRED
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-002 `/reload` ohne Lua-Fehler; `/pcomp` zeigt die Hilfe, `/pcomp version` die Version 0.1.0~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-003 Login und `/reload`: kein Fenster „PaTiCompetition wurde geblockt“~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…

### Legacy: Testlauf (Probe)
- ~~PT-COMP-010 `/pcomp probe` direkt nach dem Login: Zeilen „Kampflog … Schadensmesser-API“ und „Boss-Meldungen“
  mit ja/nein erscheinen (Ausgabe melden oder nach `/reload` die SavedVariables-Datei schicken)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-011 Draußen Gegner töten, dann `/pcomp probe`: „Kampflog-Einträge“ steigt, Schaden steht da~~
  - RETIRED 2026-10-19 – der Kampflog ist der Blizzard-UI vorbehalten (Fenster „wurde geblockt“)
- ~~PT-COMP-012 In einer Gruppe mit Heiler: Heiler steht mit Heilung da, Mitglieder mit ihrem Schaden~~
  - RETIRED 2026-10-19 – der Kampflog ist der Blizzard-UI vorbehalten
- ~~PT-COMP-013 Im Dungeon: beim ersten Kampf erscheint „Uhr gestartet: <Dungeon> (<Nummer>)“~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-014 Im Dungeon einen Boss töten: erscheint „Bosskampf vorbei: <Name> (#<Nummer>) bei <Zeit>“? Wenn nicht:
  melden (dann sendet der Client keine Boss-Meldung)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-015 Nach dem Dungeon `/pcomp probe`: Liste der Bosskämpfe mit Name und Nummer (Ausgabe melden;
  daraus entsteht die Endboss-Liste)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-016 `/pcomp clear`: „Testergebnis gelöscht.“, danach zeigt `/pcomp probe` wieder 0 Einträge~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-017 In der Gruppe: zieht ein Nicht-Tank Aggro (ein Gegner haut ihn), steht bei `/pcomp probe` hinter
  seinem Namen „Aggro gezogen 1“ (oder mehr) und seine Rolle; beim Tank zählt es auch
  (gibt später aber keine Minuspunkte)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…

### Legacy: Einstellungen und Testmodus
- ~~PT-COMP-030 ••• → Einstellungen (oder `/pcomp settings`): Fenster „PaTiCompetition Einstellungen“ mit Sprache,
  Größe, Fenster sperren, Farbschema (WoForever), Deckkraft und oben rechts dem Schalter Testmodus; kein Lua-Fehler~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-031 Testmodus: ••• → Testmodus, der Schalter in den Einstellungen und `/pcomp test` schalten die
  Beispielwerte ein (TEST-Abzeichen) und wieder aus (echte Werte); Häkchen stimmt jeweils~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-032 Sprache auf Englisch: Titel, Werte-Namen und Rollen auf den Karten wechseln sofort; zurück auf Deutsch~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-033 Größe, Farbschema und Deckkraft ändern das Fenster sofort und bleiben nach `/reload`;
  „Standard wiederherstellen“ setzt alles zurück (WoForever, 100 %), Position und Testergebnis bleiben~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-034 `/pcomp` blendet das Fenster ein/aus, `/pcomp hide` / `show`; `/pcomp reset` setzt es an die
  Standardposition; `/pcomp lock` / `unlock` sperren / entsperren; `/pcomp xyz` zeigt die Hilfe~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…

### Legacy: Endbildschirm „Party Competition“
- ~~PT-COMP-020 `/pcomp test`: Fenster mit Titel „Party Competition“, „RUNDENAUSWERTUNG · Todesminen · 24:13“,
  „Beispielwerte“ und TEST-Abzeichen; fünf Karten nebeneinander: Arden (Tank), Mira (Heiler), dann Nyra, Kael, Korr~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-021 Karten: Rahmen ums Bild in Rollenfarbe (Tank blau, Heiler grün, Schaden rot), Name in derselben Farbe,
  sieben Werte mit Symbol (Schaden, Heilung, Erlittener Schaden, Unterbrechungen, Todesstöße, Aggro gezogen, Tode),
  nichts abgeschnitten oder überlappt; Symbole sichtbar (kein grünes Fragezeichen)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-022 Beste Wertung hat einen goldenen Rahmen und goldene Zahl; Zahlen deutsch „18,4 Tsd.“~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-023 Esc schließt das Fenster; ••• → Ausblenden schließt es; am Kopf verschiebbar, Position bleibt nach
  `/reload`~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-024 Nach echten Kämpfen `/pcomp show`: deine Gruppe mit echten Porträts und Werten; Wertung wirkt fair
  (Rückmeldung zur Formel)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-025 Unterbrechungen und Todesstöße werden gezählt: Werte auf der Karte und bei `/pcomp probe`~~
  - RETIRED 2026-10-19 – kamen aus dem Kampflog (der Blizzard-UI vorbehalten)
- ~~PT-COMP-027 Werte gut lesbar: Abstand und eine feine Linie zwischen den Zeilen; Name des Werts links, Zahl
  rechts; nichts abgeschnitten oder überlappt (auch „Erlittener Schaden“, „Unterbrechungen“)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-028 Unter jedem Wert ein Punkte-Balken mit Zahl rechts („+50“, „-10“, „0“): Plus grün, Minus rot (Tode,
  Aggro gezogen); Schaden / Heilung / erlittener Schaden: nur der stärkste Wert hat Punkte (zählt einmal)~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-029 Unter dem Namen Stufe und Klasse in Klassenfarbe („Stufe 60 Krieger“); bei `/pcomp test` die
  Beispielklassen, bei `/pcomp show` die echten deiner Gruppe~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…
- ~~PT-COMP-026 Unter der Wertung ein Balken: so lang wie die Wertung (91 / 100 = fast voll), in Rollenfarbe, bei der
  besten Wertung gold; Wertung 0 = leerer Balken; nichts überlappt mit „WERTUNG“ oder der Zahl~~
  - RETIRED 2026-10-19 – PaTiCompetition wurde zu PaTiChronicle (Neukonzept Run-Bericht); neue Tests PT-CHRON-…

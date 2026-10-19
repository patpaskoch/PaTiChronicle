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
- [ ] PT-CHRON-005 Noch kein Run: PaTiSuite „alle zeigen“ und `/pchron` öffnen das Fenster mit „Noch kein Run …“;
  keine Meldung „Chronicle: im Kampf nicht möglich“, keine Chat-Zeile; der Knopf „Testmodus: Beispiel-Run ansehen“
  zeigt den Beispiel-Run (TEST-Abzeichen), ••• → Testmodus wieder aus → zurück zum Hinweis
- [ ] PT-CHRON-004 Übernommene Daten: Farbschema, Größe und Sprache wie vorher bei PaTiCompetition

## API-Prüfung (Probe, Tests T1–T7)

- [ ] PT-CHRON-010 (T6) `/pchron probe`: Zeile „C_DamageMeter: …“ zeigt Funktionsnamen – Ausgabe melden
- [ ] PT-CHRON-011 (T2) In einem 5er-Dungeon einen Boss töten, dann `/pchron probe`: erscheinen Zeilen
  „ENCOUNTER_START / ENCOUNTER_END: <Name> (#<Nummer>) Erfolg …“? Ausgabe melden
- [ ] PT-CHRON-012 (T1) Nach Kämpfen in einer Gruppe `/pchron probe`: „Bedrohungsstatus: lesbar … · geheim … · von
  Gruppenmitgliedern …“ – Zahlen melden
- [ ] PT-CHRON-013 (T3) Nach einem Tod in der Gruppe `/pchron probe`: „Todeszustand: lesbar … · geheim …“ – melden
- [ ] PT-CHRON-014 (T4) „Kämpfe in Dungeons gesehen“ steigt mit jedem Kampf im Dungeon
- [ ] PT-CHRON-015 (T5) Die Run-Uhr zeigt den richtigen Dungeon-Namen
- [ ] PT-CHRON-016 (T7) Ohne Rollenwahl: Reiter „Meine Leistung“ zeigt deine Rolle (oder „Keine Rolle“);
  Einstellung „Meine Rolle“ ändert sie für den nächsten Run

- [ ] PT-CHRON-017 (T6a–d) Nach einem Kampf und noch einmal während eines Kampfes `/pchron probe`: Zeilen
  „Schadensmesser verfügbar … Kategorien … Sitzungsarten …“, „Sitzungen“, „Nach einem Kampf“, „Während eines Kampfes“
  – Ausgabe melden (enthält nur Feldnamen und „secret“, keine Zahlen)
- [ ] PT-CHRON-018 (T9) `/pchron probe`: Zeile „3D-Figur: ok / …“ und welche Schriften „yes“ sind – melden

## Run

- [ ] PT-CHRON-020 Dungeon betreten: Uhr-Zeile „<Dungeon> bereit …“; erster Kampf: Chat „Run gestartet“, Uhr läuft
- [ ] PT-CHRON-021 Sterben und als Geist zurücklaufen: Run läuft weiter; im Verlauf steht der Tod; „Lückenlos: ja“
- [ ] PT-CHRON-022 `/reload` im Run: Run läuft weiter, im Verlauf unten „Lückenlos: nein“
- [ ] PT-CHRON-023 Nach dem Endboss ••• oder Rechtsklick auf die Uhr → „Run beenden – Endboss besiegt“: Chat „Run
  abgeschlossen“, Bericht öffnet sich; wenn Boss-Meldungen kommen: Chat „Endboss … gemerkt“
- [ ] PT-CHRON-024 Nächster Run im selben Dungeon: beim Endboss endet der Run von selbst
- [ ] PT-CHRON-025 „Run abbrechen“: Chat „Run abgebrochen … wird nicht gespeichert“, die Bestzeit bleibt
- [ ] PT-CHRON-026 Während eines Runs einen anderen Dungeon betreten: der alte Run wird abgebrochen

## Run-Bericht

- ~~PT-CHRON-030 `/pchron test`: Übersicht „Die Todesminen“, „abgeschlossen in 24:13“, „NEUE BESTZEIT · 0:48
  schneller“, fünf Porträts (Initialen), Namen in Klassenfarbe mit „21 Krieger“ usw.; GEMEINSAM: Neue Bestzeit,
  Eingespieltes Team, Kein Wipe; DEIN HIGHLIGHT: Standhaft (5 Runs in Folge), Saubere Aggro; Streifen; TEST-Abzeichen~~
  - RETIRED 2026-10-19 – Übersicht neu gestaltet (Redesign), ersetzt durch PT-CHRON-060
- [ ] PT-CHRON-031 Symbole sichtbar (kein grünes Fragezeichen): Erfolge, Totenkopf (Boss), rotes Kreuz (Tod) und
  oranger Kreis (Aggro) in Zeitleiste und Liste
- [ ] PT-CHRON-032 Tooltips: Erfolg → Regel; Markierung im Streifen → Zeit und Ereignis; „! n nicht prüfbar“ → Gründe
- ~~PT-CHRON-033 Reiter „Meine Leistung“: Kael · Schaden · 20 Magier; Erfolge; Entwicklung (Laufzeit, Tode,
  Aggro-Momente) mit Schnitt, kleinen Balken und „besser als dein Schnitt“ in Grün~~
  - RETIRED 2026-10-19 – keine Mini-Balken mehr (Redesign), ersetzt durch PT-CHRON-064
- ~~PT-CHRON-034 Reiter „Verlauf“: Streifen, Legende, „16 Kämpfe · 3 Bosskämpfe · im Kampf …“, Liste mit Bossen,
  Toden, „Aggro-Moment (Gruppe)“ und „Run abgeschlossen“; nichts überlappt oder ist abgeschnitten~~
  - RETIRED 2026-10-19 – Verlauf neu gestaltet (Redesign), ersetzt durch PT-CHRON-066
- [ ] PT-CHRON-035 Farbschemata Standard, WoForever und Dracula: alles lesbar, Reiter-Unterstrich in Akzentfarbe
- [ ] PT-CHRON-036 Nach einem echten Run: Bericht mit echten Porträts und deinen Werten; niemand hat Punkte oder Rang
- [ ] PT-CHRON-037 Esc schließt den Bericht; am Kopf verschiebbar; Position bleibt nach `/reload`

## Redesign (Game-Results-Screen)

- [ ] PT-CHRON-060 `/pchron test`, Übersicht: oben „DUNGEON ABGESCHLOSSEN“, groß „Die Todesminen“, sehr groß „24:13“,
  darunter „NEUE BESTZEIT · 0:48 schneller“ in Akzentfarbe; fünf Porträts mit Namen in Klassenfarbe und „Klasse · Rolle“;
  GEMEINSAM GESCHAFFT mit drei Erfolgen (Begründung in bis zu zwei Zeilen, nichts abgeschnitten); HIGHLIGHTS mit
  „2 Tode im 10. Kampf“ und „Längster Kampf: Edwin VanCleef, 1:53“
- [ ] PT-CHRON-061 Schrift deutlich größer als vorher; nichts gequetscht, keine großen Leerflächen; Fenster deckt die
  Spielwelt ab (keine Namensschilder scheinen durch, Deckkraft 100 %)
- [ ] PT-CHRON-062 Reiter als Text mit Unterstrich (keine Knöpfe): Übersicht, Gruppenergebnis, Meine Leistung,
  Verlauf; Maus darüber hellt auf; aktiver Reiter unterstrichen
- [ ] PT-CHRON-063 Gruppenergebnis: fünf Mitglieder nebeneinander (3D-Figur, wenn die Probe „ok“ meldet, sonst Porträt),
  Name, Klasse mit Stufe, Rolle in Rollenfarbe; Tabelle in fester Reihenfolge Tank, Heiler, Schaden: TODE, ZEIT TOT,
  ANGRIFFE 3 S+, DABEI; Korr 1 / 0:42 / 1, Nyra 1 / 0:39; Arden bei Angriffen „-“; deine Zeile mit Strich und „(du)“;
  Zeile „Gruppe“ mit „kein Wipe“; Reiter „Beitrag“ ausgegraut mit Tooltip
- [ ] PT-CHRON-064 Klick auf ein Porträt in der Übersicht öffnet das Gruppenergebnis; Klick auf eine Zeile oder Figur
  zeigt darunter die Zeiten („Korr: gestorben 14:05 · angegriffen 9:13“); „n. v.“-Felder erklären im Tooltip warum
- [ ] PT-CHRON-065 Meine Leistung: großer Name in Klassenfarbe, „Magier · Schaden · Stufe 20“; DARAUF KANNST DU STOLZ
  SEIN mit drei Erfolgen; DEINE ENTWICKLUNG ohne Balken: „Laufzeit 24:13 – 2:29 schneller als dein Schnitt (26:42)“
  mit „dein bester Run hier“, Tode, Aggro-Momente; HIER IST NOCH LUFT: „Nichts aufgefallen – ein sauberer Run.“
- [ ] PT-CHRON-066 Verlauf: Zeitleiste mit Zeitachse (0:00, 5:00, … 24:13), Bosskämpfe in Akzentfarbe, Symbole darüber
  (nahe gleiche zusammengefasst mit „×2“); Liste mit sauber ausgerichteten Zeiten, Linie zwischen Kämpfen; rechts DETAIL
  mit dem ersten Tod (Kampf 10, Dauer, „Im selben Kampf: … Korr gestorben“)
- [ ] PT-CHRON-067 Klick auf eine Zeile oder ein Symbol der Zeitleiste zeigt rechts dessen Details; die Zeile ist markiert
- [ ] PT-CHRON-068 Alle vier Farbschemata (Standard, WoForever, Dracula, Soft Fantasy): alles lesbar, getönte
  Tabellenzeilen sichtbar; Soft Fantasy bleibt nach `/reload` gewählt

## Öffnen (Minimap-Knopf, Taste, Run-Uhr)

- [ ] PT-CHRON-070 Minimap-Knopf mit Buch-Symbol am Rand der Minimap; Linksklick blendet den Run-Bericht ein/aus;
  Tooltip „Linksklick: Run-Bericht · Rechtsklick: Menü · Ziehen: verschieben“
- [ ] PT-CHRON-071 Rechtsklick: Menü (Einstellungen, Testmodus, … , „Minimap-Knopf ausblenden“); Ausblenden → Chat-Hinweis;
  `/pchron minimap` und die Einstellung „Minimap-Knopf zeigen“ holen ihn zurück
- [ ] PT-CHRON-072 Knopf um die Minimap ziehen; Position bleibt nach `/reload`
- [ ] PT-CHRON-073 WoW-Tastenbelegung → „PaTiChronicle“ → „Run-Bericht ein/aus“: eine Taste zuweisen, sie blendet den
  Bericht ein/aus (das Addon belegt selbst keine Taste)
- [ ] PT-CHRON-074 Im Dungeon: Linksklick auf die Run-Uhr öffnet den Bericht; Ziehen verschiebt sie, ohne den Bericht
  zu öffnen; Rechtsklick zeigt das Menü

## Run-Uhr

- [ ] PT-CHRON-040 Nur in 5er-Dungeons sichtbar; Zeit läuft jede Sekunde; Bestzeit rechts daneben
- [ ] PT-CHRON-041 Ziehen verschiebt sie, Position bleibt nach `/reload`; Rechtsklick-Menü; „Run-Uhr ausblenden“,
  Einstellung „Run-Uhr im Dungeon zeigen“ und `/pchron hud` schalten sie aus und an

## Einstellungen und Befehle

- [ ] PT-CHRON-050 Einstellungen: Sprache, Größe, Meine Rolle, Run-Uhr, Bericht am Ende öffnen, Fenster sperren,
  Farbschema, Deckkraft, Testmodus-Schalter; „Standard wiederherstellen“ behält Runs und Bestzeiten
- [ ] PT-CHRON-051 Sprache Englisch: Texte im Bericht wechseln sofort
- [ ] PT-CHRON-052 `/pchron` blendet den Bericht ein/aus; `show`, `hide`, `reset`; `end`/`abort` ohne Run → „Es
  läuft kein Run.“; `version` → 0.2.0; `/pchron xyz` → Hilfe


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

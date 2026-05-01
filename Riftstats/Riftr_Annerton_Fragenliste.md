# Anlage 4 — Strukturierte Fragenliste für die Erstberatung Annerton

> **Bezugsmandat:** Riftr — Pre-Launch Legal Review
> **Stand:** 30.04.2026
> **Verfasser:** Eladio Rubio Hernandez (Gründer, Geschäftsführer i. G.)
> **Bezugsdokumente:** Riftr_AGB_Klauseln_Discogs_Modell.md (Rev. 2),
> Riftr_AGB_Anhang_1_Widerrufsbelehrung.md, Riftr_ZAG_Gutachten.md
>
> **Hinweis zur Bearbeitung:** Die nachfolgenden Fragen sind auf eine
> schriftliche Erstberatungs-Aktennotiz zugeschnitten. Wo die Bewertung
> als „im Wesentlichen tragfähig, Restrisiko vorhanden" ausfällt, bitte
> um konkrete Empfehlung, ob das Restrisiko durch Wording-Anpassung,
> zusätzliche Compliance-Maßnahme oder erst durch ein vollumfängliches
> ZAG-Memo abgesichert werden soll.

---

## Cluster 1 — Kern-ZAG-Fragen

### Frage 1 — ZAG-Erlaubnisfreiheit für Stripe-Connect-Standard mit Destination Charges

Bestätigt Annerton die ZAG-Erlaubnisfreiheit der Riftr-Plattform-
Architektur auf Basis des BaFin-Merkblatts zum ZAG (Stand 31.03.2026)
unter folgenden Voraussetzungen:

   a) Riftr nutzt **Stripe Connect Standard** (nicht Custom oder
      Express); Verkäufer betreiben eigenständige Stripe-Konten,
      Riftr ist nicht Vertragspartner der Zahlungsbeziehung zwischen
      Käufer und Verkäufer.

   b) Geldströme laufen ausschließlich über die Stripe-Infrastruktur;
      Riftr hält zu keinem Zeitpunkt Kundengelder.

   c) Die Refund-Architektur folgt dem **Discogs-Modell**: keine
      einseitigen Plattform-Refunds, keine Wertentscheidungen am Geld
      durch Riftr.

Bitte um Bewertung, ob die Architektur die BaFin-Kriterien zur
Erlaubnisfreiheit erfüllt, oder ob aus aufsichtsrechtlicher Sicht
zusätzliche Maßnahmen erforderlich sind.

### Frage 2 — Bewertung der `adminResolveDispute`-Reject-Funktion

Die Riftr-Code-Funktion `adminResolveDispute` mit Aktion `Reject`
nimmt ausschließlich folgende Operationen vor:

   - Order-Doc-Update (`status: "shipped"`, `disputeStatus: "resolved"`,
     neuer `autoReleaseAt`-Timestamp)
   - Audit-Log-Eintrag
   - Push-Notifications an Käufer und Verkäufer

**Es findet kein Stripe-API-Aufruf statt** (kein `refunds.create`,
kein `transfers.create`, kein `paymentIntents.capture`, keine
`applicationFee`-Manipulation, keine Modifikation der `delay_days`-
Konfiguration). Die Auszahlung an den Verkäufer folgt der vorab durch
Stripe konfigurierten `delay_days`-Mechanik, die durch die
Reklamations-Schließung lediglich nicht weiter ausgesetzt wird. Auf
Wunsch kann die konkrete Code-Stelle (Cloud Function `adminResolveDispute`
in `functions/index.js`) zur Einsicht zur Verfügung gestellt werden.

**Frage:** Bewertet Annerton diese Konstruktion als

   **Lesart A** — passive Auto-Release-Reaktivierung (= ZAG-konform),
   oder
   **Lesart B** — Wertentscheidung am Geld i. S. d. BaFin-Merkblatts
   (= ZAG-relevant)?

Die AGB-Klausel § Streitbeilegung Abs. (2a) ist so formuliert, dass
sie beide Lesarten offenhält und die Schließung als reine
Verfahrens-Entscheidung neutralisiert. Bitte um Bewertung, ob diese
Klausel-Formulierung zusammen mit der oben beschriebenen technischen
Implementation aus aufsichtsrechtlicher Sicht trägt oder ob weitere
Maßnahmen (z. B. vollständige Entfernung der Admin-Reject-Funktion,
externe Code-Audit-Bestätigung, Ersetzung durch reine Frist-Trigger)
erforderlich wären.

### Frage 3 — Bewertung der Auto-Trigger-Konstruktion (14d / 7d / 7d)

Die AGB definiert drei objektive Auto-Trigger:

   a) **14-Tage-Versand-Frist:** Verkäufer markiert Versand nicht ⇒
      Auto-Stornierung mit Refund.
   b) **7-Tage-Verkäufer-Reaktionsfrist:** Verkäufer reagiert nicht auf
      Reklamation ⇒ Auto-Refund mit Service-Gebühr.
   c) **7-Tage-Käufer-Reaktionsfrist:** Käufer reagiert nicht auf
      Refund-Vorschlag ⇒ Vorschlag gilt als abgelehnt, Reklamation
      kehrt in offenen Status zurück.

**Frage:** Sind diese Trigger aufsichtsrechtlich als **abstrakte
AGB-Folge** (= vorab definierte messbare Kriterien, keine
Wertentscheidung) zu werten und damit ZAG-konform, oder besteht das
Risiko einer Re-Klassifizierung als **Plattform-Wertentscheidung**?

Subfrage: Müssen die Auto-Trigger im Rahmen der AGB ergänzend so
formuliert werden, dass jede technische Ausführung explizit als
„automatisierte Folge der vorab vereinbarten Vertragsbedingungen"
gekennzeichnet ist?

### Frage 4 — Bewertung der Pattern-Detection (3/5 Disputes / 6 Monate)

Die Pattern-Detection in § Y Account-Pflichten Abs. (3) knüpft
ausschließlich an die **Anzahl** eröffneter Reklamationen an,
unabhängig vom Ausgang:

   a) Drei Reklamationen in 6 Monaten ⇒ 30-Tage-Listing-Pause
   b) Fünf Reklamationen in 6 Monaten ⇒ dauerhafte Account-Sperrung

**Frage:** Bewertet Annerton diese Konstruktion als

   **plattformseitige Risikomaßnahme** (Hausrecht, ohne Bewertung der
   materiellen Schuldfrage) — oder als **Schuldfrage-Bewertung im
   Einzelfall** mit aufsichtsrechtlichem Risiko?

Subfrage: Ist die Klausel § Y Abs. (3) lit. c) („knüpft ausschließlich
an die Anzahl eröffneter Reklamationen an, unabhängig vom Ausgang")
ausreichend, um die Konstruktion als plattformseitige Risikomaßnahme
zu qualifizieren, oder bedarf es zusätzlich einer DSA-Begründungs-
mechanik im Einzelfall (Art. 17 DSA)?

---

## Cluster 2 — AGB-rechtliche Fragen

### Frage 5 — § 305c BGB-Risiko bei Service-Gebühr-Differenzierung

Die § X Refund-Policy Abs. (2) lit. b) (i)/(ii) unterscheidet die
Service-Gebühr-Behandlung nach Reason-Code:

   - `not_arrived` / `wrong_card` ⇒ Service-Gebühr wird dem Verkäufer
     belastet (`refund_application_fee: true`)
   - `condition` ⇒ Service-Gebühr verbleibt bei der Plattform
     (`refund_application_fee: false`)

**Frage:** Ist die Differenzierung nach Reason-Code für gewerbliche
und private Verkäufer hinreichend transparent (§ 307 Abs. 1 S. 2 BGB),
oder besteht das Risiko einer überraschenden Klausel nach § 305c BGB?

Subfrage: Reicht die Klarstellung in lit. b) (iii) („Reason-Code wird
vom Käufer eigenständig gewählt, keine Plattform-Umklassifizierung")
aus, um die Differenzierung als für den Verkäufer berechenbar zu
qualifizieren?

### Frage 6 — § 308 Nr. 4 BGB bei Account-Sanktionen

§ Y Account-Pflichten Abs. (1) lit. a) sieht eine Pausierung von
Listings „für die Dauer von 30 Tagen (Standardmaß bei Pattern-Detection)
bis zu maximal 365 Tagen (bei schwerwiegenden Einzelverstößen)" vor.

**Frage:** Ist die Spannweite 30–365 Tage in Verbindung mit den
Beispielkriterien („Verkauf gefälschter Ware", „wiederholte
Versandpflicht-Verstöße") hinreichend bestimmt, um nicht als
unzulässiger Änderungsvorbehalt nach § 308 Nr. 4 BGB qualifiziert zu
werden?

Subfrage: Sollten konkrete Sanktions-Stufen (z. B. „Erstverstoß: 30
Tage; Zweitverstoß: 90 Tage; Drittverstoß: 365 Tage oder Sperrung")
ergänzt werden, um die Klausel weiter abzusichern?

### Frage 7 — § 447 BGB-Abweichung für unversicherten Versand ab €300

§ X Versand Abs. (N) lit. d) sieht vor:

> „Versendet der Verkäufer abweichend von der durch das System
> zugewiesenen Versandklasse (insbesondere unversichert bei Bestellungen
> ab €300), trägt er gegenüber dem Käufer das volle Versand- und
> Verlustrisiko abweichend von § 447 BGB."

**Frage:** Ist die explizite Abweichung von § 447 BGB für
**Verbraucher-Verkäufer** (C2C-Konstellation) wirksam, oder muss die
Klausel nach §§ 305 ff. BGB-Maßstab umformuliert werden?

Subfrage: Ist eine ergänzende Hinweispflicht in der App-UI
erforderlich (z. B. Pflicht-Bestätigung des Verkäufers vor erstem
Listing ab €300), um die Klausel auch unter Verbraucherschutz-Maßstab
zu tragen?

---

## Cluster 3 — Verbraucherschutz

### Frage 8 — Reklamations-Hinweispflicht bei Reason-Code-Wahl

Die App-UI fragt bei Wahl von `not_arrived` oder `wrong_card` durch
einen Käufer eines gewerblichen Verkäufers aktiv ab, ob der Käufer
stattdessen das gesetzliche Widerrufsrecht ausüben möchte
(siehe Anhang 1 Abschnitt C). Die Auswahl wird im Audit-Log
dokumentiert.

**Frage:** Ist diese Hinweispflicht in der vorgesehenen Form
(aktive App-Abfrage, Audit-Log-Dokumentation, neutrale Default-Auswahl)
ausreichend, um den Vorwurf eines **Dark Pattern** nach UWG / UCPD
auszuschließen?

Subfrage: Welche zusätzlichen UX-Anforderungen wären aus
verbraucherschutzrechtlicher Sicht zu beachten (z. B.
Mindest-Dauer-Anzeige, Pflicht zur expliziten Wahlbestätigung,
Verbot bestimmter farblicher Hervorhebungen)?

### Frage 9 — Trennung Verbraucherwiderruf ↔ konsensualer Refund

§ X Refund-Policy Abs. (2) lit. c) regelt den Verbraucherwiderruf
strukturell getrennt vom konsensualen Refund nach lit. b) und verweist
für die Rückabwicklung auf §§ 355 ff. BGB.

**Frage:** Ist die Trennung klausel-konform mit den
Klauselverboten des § 309 Nr. 8 BGB, insbesondere Nr. 8 lit. b)
(Rechte aus Mängelhaftung)? Besteht das Risiko, dass die parallele
Existenz beider Pfade (Widerrufsrecht + plattformeigene Reklamation)
als Beschränkung des Widerrufsrechts gewertet werden könnte?

Subfrage: Müssen die Käufer bereits in der Bestellbestätigung (nicht
erst im Reklamations-Workflow) über die Wahlmöglichkeit zwischen
Widerruf und Reklamation belehrt werden?

---

## Cluster 4 — Operative Fragen

### Frage 10 — BaFin-Eingriff-Eskalationsplan

Falls die BaFin eine Auskunftsanfrage zur Riftr-Plattform stellt
(z. B. nach § 44 KWG analog, Plattform-Erkundung im ZAG-Bereich oder
auf Veranlassung Dritter):

**Frage:** Wie sieht die ideale Erst-Reaktion aus?

   a) Welche Dokumente sollten vorab vorbereitet sein (ZAG-Memo,
      AGB-Versionierung, Stripe-Connect-Architekturdiagramm,
      ggf. Code-Auszüge zu `adminResolveDispute`)?
   b) Wer sollte als Erst-Ansprechpartner fungieren (Geschäftsführer
      direkt, Annerton als externer Berater, oder gemeinsame
      Antwort)?
   c) Welche Fristen sind typischerweise zu erwarten und wie ist die
      Bearbeitung intern zu organisieren?
   d) Gibt es eine Empfehlung zur **proaktiven** Kontaktaufnahme mit
      der BaFin vor Launch (informeller Vorgespräch / Marktbegleitung)
      oder ist abzuwarten?

### Frage 11 — Empfehlung zu weiteren Compliance-Schichten

**Frage:** Empfiehlt Annerton zusätzliche Compliance-Maßnahmen
über das gesetzliche Mindestmaß hinaus, insbesondere

   a) **KYC-Verschärfung für Verkäufer ab Lifetime-Volumen >€10.000?**
      (z. B. Pflicht zur Vorlage einer Gewerbeanmeldung,
      Plausibilitätsprüfung der Verkäufer-Identität durch Riftr
      zusätzlich zur Stripe-KYC)
   b) **Anti-Money-Laundering-Schicht** auf Plattform-Ebene (auch
      wenn das GwG bei Stripe-Connect-Standard primär bei Stripe
      ankert)?
   c) **DSA-Trusted-Flagger-Vorbereitung** für
      Marken-/Counterfeit-Hinweise von Riot Games oder anderen
      Rechteinhabern?
   d) **DSA-Notice-and-Action-Workflow** für illegale Inhalte
      (gefälschte Karten, Beleidigungen in Listings, etc.)?

Bitte um Priorisierung in „Pre-Launch erforderlich" / „Post-Launch im
ersten Halbjahr empfohlen" / „Optional bei Volumen-Wachstum".

### Frage 12 — Schwellen für ein vollumfängliches ZAG-Memo

Die aktuelle interne ZAG-Aktennotiz (Anlage 3) ist auf
Erstberatungs-Niveau verfasst. Für spätere Investorenrunden,
Bankenkooperationen oder behördliche Anfragen kann ein **vollumfängliches
ZAG-Memo** durch eine spezialisierte Aufsichtsrechts-Kanzlei sinnvoll
sein.

**Frage:** Bei welcher Schwelle sollte Riftr ein solches Memo
beauftragen?

   a) **Volumenschwelle:** Monatliches Brutto-Marktplatz-Volumen ab
      welchem Wert? (€100k? €500k? €1 Mio?)
   b) **Funding-Schwelle:** Bei welcher Investorenrunde?
      (Pre-Seed-Verzicht ⇒ Seed-Round ⇒ Series A?)
   c) **Funktions-Trigger:** Bei welcher technischen
      Plattform-Erweiterung wird ein Memo erforderlich? (z. B.
      Einführung eines Riftr-eigenen Wallets, Stored-Value-Funktionen,
      Rabatt-Punktesysteme, Inter-User-Transfers außerhalb von
      Kaufverträgen?)
   d) **Wettbewerber-Trigger:** Sollte Riftr proaktiv ein Memo
      vorhalten, sobald ein vergleichbarer Wettbewerber
      BaFin-Maßnahmen ausgesetzt war?

---

**Erstellt:** 30.04.2026
**Verfasser:** Eladio Rubio Hernandez (Gründer, Geschäftsführer i. G.)
**Status:** Anlage 4 zur Annerton-Erstberatungs-Anfrage

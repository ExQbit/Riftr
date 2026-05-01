# Anlage 5 — Code-Audit-Befund zu `adminResolveDispute`

> **⚠️ STATUS (01.05.2026): SCHUBLADEN-DOKUMENT — NICHT IM
> ERSTBERATUNGS-PAKET ENTHALTEN.**
>
> Begründung: Bei einer einstündigen anwaltlichen Erstberatung (€300–500)
> mit Annerton ist ein formaler Code-Audit + Code-Änderungs-Verpflichtung
> nicht angemessen. Riftr befindet sich aktuell in geschlossener Beta
> (7 Tester); Architektur-Beweglichkeit ist erwünscht. Eine bindende
> Architektur-Verpflichtung gegenüber Annerton kommt erst bei realem
> Live-Betrieb in Frage (z. B. wenn Stripe Live-Review explizit nach
> einem schriftlichen Code-Audit-Befund fragt, bei Investor-DD oder
> ab definierter Volumen-Schwelle).
>
> Dieses Dokument bleibt im Repository als **vorbereitete Vorlage**
> erhalten und kann bei Bedarf reaktiviert werden — z. B. wenn
> Annerton nach der Erstberatung eine schriftliche Code-Bestätigung
> nachfordert. Vor Reaktivierung ist die zwischenzeitliche Code-
> Entwicklung neu zu prüfen.
>
> **Bezugsmandat:** Riftr — Pre-Launch Legal Review (Annerton)
> **Stand:** 30.04.2026 (Schubladen-Status: 01.05.2026)
> **Verfasser:** Eladio Rubio Hernandez (Gründer, Geschäftsführer i. G.)
> **Bezugsdokument:** Riftr_AGB_Klauseln_Discogs_Modell.md (Rev. 2),
> § Streitbeilegung Abs. (2a)
> **Anlass (vorgesehen):** Stärkung der Lesart-A-Position (passive Auto-
> Release-Reaktivierung) zur Bewertungsfrage 2 der Fragenliste an
> Annerton (Cluster 1 — Kern-ZAG-Fragen).

---

## 1. Audit-Anlass

Die AGB-Klausel § Streitbeilegung Abs. (2a) im Discogs-Modell stützt
sich auf die Behauptung, dass die `adminResolveDispute`-Reject-Funktion
**keine aktive Geld-Entscheidung**, sondern eine reine Verfahrens-
Entscheidung darstellt. Die Auszahlung an den Verkäufer folgt der
vorab durch Stripe konfigurierten `delay_days`-Mechanik, die durch die
Reklamations-Schließung lediglich nicht weiter ausgesetzt wird.

Diese rechtliche Konstruktion trägt nur, wenn die technische
Implementation tatsächlich keinen Stripe-API-Aufruf vornimmt, der eine
Geldbewegung auslöst, beschleunigt, umlenkt oder modifiziert.

Der nachfolgende Code-Audit dokumentiert das Ergebnis der internen
Verifikation der `adminResolveDispute`-Funktion mit Aktion `Reject`
zum Stand des Code-Audit-Datums.

---

## 2. Audit-Methodik

### Audit-Subjekt

Cloud-Funktion `adminResolveDispute` im Riftr-Backend, Aktion `Reject`
(„Seller wins" — Reklamation wird zugunsten des Verkäufers geschlossen).

### Audit-Verfahren

   a) Manuelle Code-Inspektion der Cloud-Funktion und aller von ihr
      aufgerufenen Helper-Funktionen.

   b) Statische Suche nach allen Stripe-SDK-Aufrufen innerhalb der
      Funktion und ihrer Aufrufkette mit den folgenden Suchbegriffen:

      - `stripe.refunds.create`
      - `stripe.refunds`
      - `stripe.transfers.create`
      - `stripe.transfers`
      - `stripe.paymentIntents.capture`
      - `stripe.paymentIntents.update`
      - `stripe.paymentIntents`
      - `stripe.applicationFees`
      - `stripe.charges`
      - `applicationFee` (alle Schreibweisen)
      - `reverse_transfer`
      - `refund_application_fee`

   c) Verifikation, dass die Funktion ausschließlich Firestore-Updates,
      Audit-Log-Einträge und Push-Benachrichtigungen vornimmt.

### Audit-Ausschluss

Der Audit umfasst ausschließlich die Aktion `Reject`. Die Aktion
`Approve` (Refund mit `refundPercent > 0`) wurde im Rahmen des
Code-Refactors zum Discogs-Modell vollständig entfernt
(Commits a361a09–cdc1cc6) und ist nicht mehr im Code vorhanden.

---

## 3. Audit-Ergebnis

### Operationen der Funktion `adminResolveDispute(action: "Reject")`

Die Funktion nimmt **ausschließlich** folgende drei Operationen vor:

   **(1) Order-Doc-Update** (Firestore):
   - `status` wird von `disputed` auf `shipped` zurückgesetzt
   - `disputeStatus` wird von `open` (oder `sellerProposed`) auf
     `resolved` gesetzt
   - `autoReleaseAt` wird auf einen neuen Timestamp gesetzt
     (Standardmaß: aktueller Zeitpunkt + 7 Tage)
   - `disputeResolvedAt` wird auf den aktuellen Server-Timestamp gesetzt
   - `disputeResolution` wird auf `seller_wins` gesetzt

   **(2) Audit-Log-Eintrag** (Firestore-Subcollection `auditLog`):
   - Eintrag mit Timestamp, ausführendem Admin-User-ID,
     Reklamations-ID, Aktions-Typ `reject`, vorheriger und neuer
     `disputeStatus`-Wert.

   **(3) Push-Benachrichtigungen** (Firebase Cloud Messaging):
   - Käufer-Benachrichtigung: Reklamation wurde geschlossen
   - Verkäufer-Benachrichtigung: Reklamation wurde geschlossen

### Stripe-API-Aufrufe

**Keine.**

Konkret wurde verifiziert, dass die Funktion **keinen** der folgenden
Aufrufe vornimmt:

   - `stripe.refunds.create` — kein Refund wird ausgelöst
   - `stripe.transfers.create` — kein Transfer wird ausgelöst
   - `stripe.transfers.createReversal` — keine Transfer-Reversal
   - `stripe.paymentIntents.capture` — keine Capture wird ausgelöst
   - `stripe.paymentIntents.update` — keine PaymentIntent-Modifikation
   - `stripe.applicationFees.create` — keine Application-Fee-Operation
   - `stripe.applicationFees.createRefund` — keine Application-Fee-
     Refund-Operation
   - **Keine Manipulation des `applicationFee`-Parameters**
   - **Keine Manipulation des `delay_days`-Parameters** auf dem
     Stripe-Connected-Account
   - **Keine Manipulation des `reverse_transfer`-Parameters**

### Verhalten der Stripe-`delay_days`-Mechanik nach Status-Reset

Die `delay_days`-Konfiguration wird zum Zeitpunkt der Order-Erstellung
auf dem Stripe-Connected-Account des Verkäufers gesetzt und bleibt
während der gesamten Order-Lebensdauer unverändert. Bei Eröffnung
einer Reklamation (`disputeStatus: "open"`) pausiert das Riftr-System
**intern** die Auszahlung, indem `autoReleaseAt` auf den fernen
Zukunfts-Timestamp `9999-12-31` gesetzt wird; die `delay_days`-
Konfiguration auf dem Stripe-Connected-Account bleibt davon unberührt.

Bei `Reject` wird `autoReleaseAt` auf den neuen 7-Tage-Timestamp
zurückgesetzt; nach Erreichen dieses Timestamps löst der Auszahlungs-
Cron die Auszahlung gemäß der unverändert bestehenden Stripe-
`delay_days`-Konfiguration aus. Riftr ruft auch zu diesem Zeitpunkt
keine aktive Stripe-API auf, die eine Geldbewegung auslöst — der
Auszahlungs-Cron prüft lediglich, ob `autoReleaseAt` erreicht ist, und
markiert die Order intern als `released`. Die tatsächliche Auszahlung
folgt der Stripe-eigenen Mechanik.

---

## 4. Bewertung der Audit-Ergebnisse

### Schlussfolgerung zur ZAG-Position

Der Code-Audit dokumentiert, dass die `adminResolveDispute`-Reject-
Funktion ausschließlich Status-Manipulationen in der Riftr-eigenen
Datenbank vornimmt und keine aktive Geldbewegung über Stripe-APIs
auslöst. Die kausale Folge der Status-Manipulation — das spätere
Auslaufen der internen `autoReleaseAt`-Frist und die nachfolgende
Stripe-Auszahlung — ist eine **passive Reaktivierung** der vor
Reklamations-Eröffnung bereits feststehenden Auszahlungs-Mechanik.

Damit ist die Konstruktion technisch konsistent mit der in § Streit-
beilegung Abs. (2a) der AGB beschriebenen Lesart A („passive Auto-
Release-Reaktivierung"). Eine technische Grundlage für Lesart B
(„Wertentscheidung am Geld" mit aktivem Stripe-API-Aufruf) liegt
nicht vor.

### Limitations dieses Audits

   a) Der Audit basiert auf der Code-Inspektion zum Audit-Datum. Eine
      spätere Code-Änderung kann die Befundlage verändern; die
      AGB-Klausel § Streitbeilegung Abs. (2a) muss bei jeder
      Architektur-Änderung neu validiert werden.

   b) Der Audit ist eine **interne Verifikation** durch den Gründer
      und Geschäftsführer i. G. Eine externe Code-Audit-Bestätigung
      durch einen unabhängigen IT-Auditor wurde nicht durchgeführt.
      Sollte dies aus aufsichtsrechtlicher Sicht erforderlich sein,
      bittet Riftr Annerton um entsprechende Empfehlung.

   c) Der Audit umfasst nicht die Stripe-Connect-Konfiguration auf
      Account-Ebene. Die Aussage zur unveränderten `delay_days`-
      Konfiguration basiert auf der dokumentierten Konfigurations-
      Logik im Onboarding-Code; eine spot-check-Verifikation auf
      bestehenden Test-Accounts wurde durchgeführt.

### Empfehlung für die Aktennotiz

Riftr bittet Annerton, im Rahmen der Erstberatungs-Aktennotiz zu
Frage 2 der Fragenliste (Lesart-A vs. Lesart-B-Bewertung) den
Code-Audit-Befund als technische Grundlage zu berücksichtigen und
gegebenenfalls eine Empfehlung zu geben, ob

   a) der jetzige Stand des Code-Audits aus aufsichtsrechtlicher
      Sicht ausreichend ist,
   b) eine externe Code-Audit-Bestätigung erforderlich oder ratsam
      wäre,
   c) eine periodische Re-Verifikation (z. B. quartalsweise oder bei
      jedem Architektur-Release) empfohlen wird.

---

## 5. Code-Änderungs-Verpflichtung

Riftr verpflichtet sich gegenüber Annerton, die in diesem Audit
dokumentierte Implementation während der Mandatsdauer in folgenden
Aspekten unverändert zu halten:

   a) `adminResolveDispute` mit Aktion `Reject` ruft keine
      Stripe-API auf, die eine Geldbewegung auslöst, beschleunigt,
      umlenkt oder modifiziert.

   b) Die `delay_days`-Konfiguration auf Stripe-Connected-Accounts
      wird ausschließlich beim initialen Onboarding gesetzt und im
      laufenden Betrieb nicht durch Riftr modifiziert.

   c) Eine etwaige zukünftige Reaktivierung einer Admin-initiierten
      Refund-Funktion erfolgt nicht ohne vorherige rechtliche
      Freigabe durch Annerton oder eine vergleichbare aufsichtsrechtliche
      Beratung.

Sollte eine dieser Bedingungen verletzt werden, ist die AGB-Klausel
§ Streitbeilegung Abs. (2a) erneut zu validieren und gegebenenfalls
anzupassen.

---

**Erstellt:** 30.04.2026
**Verfasser:** Eladio Rubio Hernandez (Gründer, Geschäftsführer i. G.)
**Status:** Anlage 5 zur Annerton-Erstberatungs-Anfrage
**Bezug:** Fragenliste Cluster 1, Frage 2 (Lesart-A vs. Lesart-B)

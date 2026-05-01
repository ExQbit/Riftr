# Mandatsschreiben — Erstberatung Annerton

> **Anlass:** Vorbereitung des Markteintritts der Riftr-Plattform
> (Trading-Card-Game-Marktplatz, B2C/C2C) mit Stripe-Connect-basierter
> Zahlungsarchitektur. Erstberatung zur ZAG-Befreiungs-Position,
> AGB-Konformität (Discogs-Modell) und DSA-Compliance.
>
> **Stand:** 30.04.2026
> **Verfasser:** Eladio Rubio Hernandez (Gründer, Geschäftsführer i. G.)
> **Empfänger:** Annerton Rechtsanwaltsgesellschaft mbH
> **Mandatsbezeichnung:** Riftr — Pre-Launch Legal Review

---

## 1. Mandant

**Riftr UG (haftungsbeschränkt) i. G.**
Sitz Nordrhein-Westfalen (Anschrift wird mit UG-Eintragung Q2 2026
ergänzt)
vertreten durch den Gründer und Geschäftsführer i. G. Eladio Rubio
Hernandez

E-Mail: support@getriftr.app
Plattform: Riftbound-Marktplatz in der Riftr-App (iOS/Android)

---

## 2. Anlass und Sachverhalt

### Geschäftsmodell

Die Riftr UG i. G. plant den Launch eines mobilen Marktplatzes für
Trading Cards des Riftbound-TCG (vergleichbar in Funktion und Zuschnitt
mit Cardmarket und Discogs). Verkäufer sind sowohl gewerblich (§ 14 BGB)
als auch privat (P2P) tätig; Käufer sind ganz überwiegend Verbraucher.

### Zahlungsarchitektur

Sämtliche Geldbewegungen werden ausschließlich durch den lizenzierten
Zahlungsdienstleister **Stripe Payments Europe Limited** ausgeführt.
Riftr nutzt **Stripe Connect Standard mit Destination Charges**;
Verkäufer durchlaufen das Stripe-eigene KYC-Verfahren und betreiben
eigenständige Stripe-Konten. Riftr selbst hält zu keinem Zeitpunkt
Kundengelder.

### Kern-Konstruktion zur ZAG-Befreiung („Discogs-Modell")

Auf Basis des BaFin-Merkblatts zum ZAG (Stand 31.03.2026) wurde die
Plattform-Architektur so refaktoriert, dass **Riftr keine
Einwirkungsmöglichkeit auf den Zahlungsfluss** hat. Konkret:

- **Konsensbasierte Refunds:** Refund-Vorschlag durch Verkäufer,
  Annahme/Ablehnung durch Käufer; Stripe-API-Aufruf erfolgt nur bei
  Konsens.
- **Objektive Auto-Trigger nach Fristablauf:** 14-Tage-Versand-Frist,
  7-Tage-Verkäufer-Reaktionsfrist, 7-Tage-Käufer-Reaktionsfrist.
  Sämtliche Trigger basieren auf vorab in der AGB definierten,
  messbaren Kriterien (Datum/Status), nicht auf
  Plattform-Wertentscheidungen.
- **Externe Eskalationswege:** Stripe-Chargeback,
  Verbraucherschlichtung (für Käufe von gewerblichen Verkäufern),
  Zivilrechtsweg auf Basis der KYC-verifizierten Stripe-Verkäuferdaten.
- **`adminResolveDispute`-Reject-Funktion:** Diese Funktion nimmt
  ausschließlich einen Order-Status-Flip, einen Audit-Log-Eintrag und
  Push-Benachrichtigungen vor. Kein Stripe-API-Aufruf (`refunds.create`,
  `transfers.create`, `paymentIntents.capture`, `applicationFee`-
  Manipulation) findet statt; die Auszahlung folgt der vorab
  definierten Stripe-`delay_days`-Mechanik. Diese technische
  Implementation stützt die Lesart-A-Position („passive Auto-Release-
  Reaktivierung") in § Streitbeilegung Abs. (2a) der AGB. Die konkrete
  Code-Stelle kann auf Anfrage zur Einsicht zur Verfügung gestellt
  werden.

### Account-Sanktionen (Hausrecht, getrennt vom Zahlungsfluss)

Pattern-Detection auf Basis der Anzahl eröffneter Reklamationen
(unabhängig vom Ausgang): drei Reklamationen / 6 Monate ⇒ 30-Tage-Pause;
fünf Reklamationen / 6 Monate ⇒ Account-Sperre. Sanktionen sind reine
Plattform-Maßnahmen; bestehende Bestellungen werden nach den allgemeinen
Refund-Policy-Regeln fortgeführt.

---

## 3. Auftragsumfang der Erstberatung

Im Rahmen der anwaltlichen **Erstberatung** wird Annerton gebeten,
folgende Themenbereiche schriftlich oder im Erstgespräch zu bewerten:

   a) **ZAG-Befreiungs-Position** für die beschriebene Architektur,
      insbesondere die Bewertung der `adminResolveDispute`-Reject-
      Funktion und der Auto-Trigger-Konstruktion.

   b) **AGB-Konformität** der überarbeiteten Klauselsätze (Anlage 1)
      einschließlich Anhang 1 Widerrufsbelehrung (Anlage 2) nach
      §§ 305 ff. BGB, mit Schwerpunkten Transparenzgebot, § 305c BGB
      und § 308/309-Klauselverbote.

   c) **DSA-Konformität** der Sanktions- und Beschwerde-Architektur
      (Art. 17, 20 DSA).

   d) **Verbraucherschutzrechtliche Risiken**, insbesondere die
      Reklamations-Hinweispflicht bei Reason-Code-Wahl
      (Dark-Pattern-Vermeidung nach UWG/UCPD) und die saubere
      Trennung Verbraucherwiderruf ↔ konsensualer Refund.

   e) **Operative Compliance-Empfehlungen** für den Pre-Launch- und
      Post-Launch-Pfad einschließlich BaFin-Eingriff-Eskalationsplan
      und Volumen-Schwellen für ein vollumfängliches ZAG-Memo.

Die strukturierte Fragenliste mit zwölf Punkten in vier Clustern liegt
diesem Schreiben als **Anlage 4** bei.

### Form der Beratung

Erbeten wird eine schriftliche **Erstberatungs-Aktennotiz** mit
Bewertung der zwölf Fragen (Cluster 1–4) sowie ein einstündiges
Erstgespräch (Video oder vor Ort in Frankfurt) zur Klärung offener
Detailfragen.

### Honorar

Honorarvereinbarung auf Basis des Annerton-Tarifs nach Aufwand;
Riftr bittet vorab um eine Aufwandsschätzung in Stunden für die
Erstberatungs-Aktennotiz und das Erstgespräch.

### Zeitlicher Rahmen

Geplanter Plattform-Launch: Q2/Q3 2026 (parallel zur UG-Eintragung).
Annerton-Erstberatungs-Aktennotiz erbeten bis spätestens **Ende Mai
2026**, damit die finalen AGB-Versionen vor Launch freigegeben werden
können.

---

## 4. Anlagen

   - **Anlage 1:** Riftr_AGB_Klauseln_Discogs_Modell.md (Rev. 2,
     30.04.2026) — überarbeitete Klauselsätze § Streitbeilegung,
     § Refund-Policy, § Versand, § Y Account-Pflichten und Sanktionen
   - **Anlage 2:** Riftr_AGB_Anhang_1_Widerrufsbelehrung.md (30.04.2026)
   - **Anlage 3:** Riftr_ZAG_Gutachten.md (interne Aktennotiz, Sektion
     D.7.0 zur ZAG-Befreiungs-Position)
   - **Anlage 4:** Riftr_Annerton_Fragenliste.md — strukturierte Fragen
     in vier Clustern

---

**Riftr UG (haftungsbeschränkt) i. G.**
Eladio Rubio Hernandez
Gründer und Geschäftsführer i. G.
30.04.2026

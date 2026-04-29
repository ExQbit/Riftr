# Riftr — Anwalt-Briefing

**Stand:** April 2026
**Kontakt:** [DEIN NAME] — eladiorubiohernandez@gmail.com — getriftr.app

---

## 1. Über Riftr

Riftr ist eine **mobile Companion-App + P2P-Marktplatz für Riftbound TCG** (das neue League-of-Legends-Trading-Card-Game von Riot Games). Zielgruppe: TCG-Spieler in der EU.

**Funktionen der App:**
- Card-Scanner (ML-basiert) zur automatischen Erkennung physischer Sammelkarten
- Sammlungs-Tracking mit Wertentwicklung
- Deck-Builder
- Marktplatz wo Privatpersonen + (geplant) gewerbliche Händler Karten kaufen + verkaufen
- Smart-Cart (algorithmische Optimierung über mehrere Verkäufer)

**Geschäftsmodell:**
- Service-Gebühr (Käufer): €0,49 — €1,99 pro Bestellung, gestaffelt nach Bestellwert
- Provision (Verkäufer): 5,0 % — 6,5 % vom Karten-Wert, gestaffelt nach Bestellwert
- Multi-Seller-Aufschlag: +€0,30 pro zusätzlichem Verkäufer im Cart
- Stripe-Gebühren werden von Riftr getragen (klare Buchhaltung)

**Erwartetes Volumen Erste 12 Monate:**
- Phase 1 (Beta): 10-50 Tester, kein Echtgeld
- Phase 2 (Soft-Launch): 500-2000 User, ~€10k-50k Umsatz/Monat (geschätzt)
- Phase 3 (12 Monate post-Launch): hoffen auf 5000-20000 User, ~€100k-500k Umsatz/Monat (geschätzt)

---

## 2. Geplante UG (haftungsbeschränkt)

- **Name:** Voraussichtlich „Riftr UG (haftungsbeschränkt)"
- **Geschäftsführer:** [DEIN NAME]
- **Sitz:** [DEINE STADT]
- **Stammkapital:** €1 (Gründungsstamm) + Kapitalrücklage
- **Gegenstand:** Betrieb einer Online-Plattform zur Vermittlung von Sammelkarten zwischen Privatpersonen sowie Bereitstellung von Tools zur Sammlungsverwaltung und Deckbau
- **Tätigkeitsbeginn:** Geplant Q3 2026 (sobald UG eingetragen + AGB final)

**Fragen zur UG-Gründung:**
1. Online-Notar (z. B. ETL-Notarservice) vs. lokaler Notar — Empfehlung?
2. Pflicht-Eintragungen (HRB, IHK, Gewerbe) und voraussichtliche Kosten total
3. Nach Eintragung: USt-IdNr beantragen — sollte ich Kleinunternehmer-Regelung wählen oder direkt Regelbesteuerung (steuerberater-Frage parallel)?
4. Geschäftskonto-Empfehlung mit Stripe-Connect-Compatibility (z. B. Holvi, Penta, oder klassisch Sparkasse)?

---

## 3. Architektur — warum keine BaFin-Lizenz nötig

**Wichtig für AGB + Compliance-Bewertung:** Riftr berührt zu **keinem Zeitpunkt** das Geld der User.

Sämtliche Zahlungen laufen über **Stripe Connect Destination Charges** mit:
- `transfer_data: { destination: <verkäufer-stripe-konto> }` — Stripe routet Gelder automatisch an Connected-Account des Verkäufers
- `application_fee_amount` — Riftrs Service-Gebühr + Provision wird von Stripe direkt abgezogen
- Stripe-Fees trägt Riftr (= klare Buchhaltung, keine User-Verwirrung)

**Anmerkung zur Stripe-Charge-Type-Terminologie:**

Riftr nutzt **Destination Charges** mit `transfer_data + application_fee_amount` (NICHT Direct Charges via `stripeAccount`-Header).

**Drei Ebenen die wir sauber trennen wollen** (auf Hinweis eines Aufsichtsrechtlers):

| Ebene | Rolle Riftr | Bedeutung |
|---|---|---|
| **Stripe-technisch** | Charge-Empfänger | Plattform-Stripe-Account empfängt formal die Zahlung, leitet sie automatisch via `transfer_data` weiter |
| **Zivilrechtlich** | Vermittler (NICHT Verkäufer) | Kaufvertrag besteht ausschließlich zwischen Käufer und Verkäufer |
| **Aufsichtsrechtlich (ZAG)** | nicht zahlungsdienste-pflichtig | Riftr hat keine tatsächliche oder rechtliche Verfügungsmacht über die Gelder; Stripe leitet sie automatisch und unwiderruflich weiter |

**ZAG-Memo:** Wir möchten zur formalen Dokumentation der ZAG-Befreiung ein **Standard-Memo** beauftragen (8–12 Seiten, mit Risikoanalyse). Begründung: später sowohl bei Investoren-Due-Diligence als auch bei Stripe-Risk-Review vorlegbar.

**Bewusst KEINE BaFin-Anfrage:**
- BaFin-Anfragen sind gebührenpflichtig (€1.000–5.000)
- Verfahrensdauer 2–6 Monate, kein Anspruch auf bestimmte Antwort
- Marktstandard: eBay, Etsy, Cardmarket, Vinted, Kleinanzeigen operieren alle ohne formale BaFin-Bestätigung
- Stripe Payments Europe Ltd. ist EU-passportet als regulierter Akteur, das Memo dokumentiert unsere Architektur-Konformität

**Wichtige Klarstellung:** Wir berufen uns NICHT auf eine "Stripe Compliance Bestätigung" — solche mündlichen/Chat-Aussagen wären rechtlich wertlos. Wir verlassen uns ausschließlich auf das anwaltliche Memo.

**Konsequenz rechtlich:**
- Keine BaFin-Erlaubnis nach §§ 10, 32 KWG erforderlich
- Riftr ist nach unserer Bewertung kein Zahlungsdienstleister i.S. § 1 Abs. 1 ZAG (kein Halten oder Weiterleiten fremder Gelder)
- Stripe (Stripe Payments Europe Ltd., Dublin) ist der lizenzierte Zahlungsdienstleister mit EU-Passport
- Verkäufer schließen beim Stripe-Connect-Express-Onboarding eigenständige Verträge mit Stripe ab (= Stripe-Express-Vereinbarung)

**Fragen an Anwalt:**
1. Bestätigt unsere Destination-Charges-Setup mit `transfer_data + application_fee_amount` die ZAG-Befreiung?
2. Erstellung eines ZAG-Memos zur formalen Dokumentation der Befreiung — was ist der typische Aufwand + Honorar?
3. Reicht der Verweis im AGB auf den Stripe-Express-Vertrag?
4. **BaFin-Anfrage NICHT geplant** — bewusste Entscheidung um nicht aktiv auf das Radar zu kommen. Stimmt diese Strategie?

**Treuhand-Mechanismus über Stripe `delay_days`:**
- Stripe hält das Käufer-Geld auf dem Verkäufer-Connect-Konto für 1-7 Tage zurück (tier-abhängig)
- Power-Seller (200+ Verkäufe, 4,95★): 1 Tag bei Bestellungen ≤ €100, sonst 7 Tage
- Bei Refund/Chargeback: Stripe holt das Geld via `reverse_transfer` zurück
- Riftr trifft pro-Order **keine** Wertentscheidung über das Geld — `delay_days` ist Account-global konfiguriert

---

## 4. AGB — bereits gedrafted, brauche Review

**Bereits ausgearbeitet** (siehe Anhang `CLAUDE.md` im Riftr-Repo):

- § Service-Gebühr-Staffelung (Käufer)
- § Provision-Staffelung (Verkäufer)
- § Auszahlung-Tier-System (Neu/Etabliert/Trusted/Power-Seller mit Schwellenwerten)
- § Zahlungsabwicklung (Stripe Connect, Riftr berührt kein Geld)
- § Mediations-Service bei Streitigkeiten (kein Käuferschutz im Sinne §307 BGB)

**Bewusste Wording-Regeln** (rechtssicher gehalten):
- Wir nutzen NIRGENDS „Käuferschutz" / „Buyer Protection" / „Geld-zurück-Garantie"
- Stattdessen „Mediations-Service bei Streitigkeiten" — beschreibt Tätigkeit, kein Versprechen
- Service-Gebühr-Beschreibung: „deckt Plattform-Kosten" — kein Gewährleistungs-Versprechen
- Klare Trennung: Kaufvertrag besteht zwischen Käufer und Verkäufer, NICHT mit Riftr

**Vorgeschlagene Vermittler-Klausel** (zur juristischen Untermauerung der ZAG-Befreiung):

> „Die Zahlungsabwicklung erfolgt technisch über Stripe Connect. Riftr nimmt zwar im Stripe-System formal die Käuferzahlung in Empfang, hat aber keinerlei tatsächliche oder rechtliche Verfügungsmacht über die Gelder; Stripe leitet die Beträge automatisch und unwiderruflich an den Verkäufer-Account weiter. Der Kaufvertrag kommt ausschließlich zwischen Käufer und Verkäufer zustande; Riftr ist Vermittler."

Bitte diese Klausel review + ggf. verfeinern. Anwalt wurde bereits angeboten weitere AGB-Klauseln zu formulieren, die die fehlende-Verfügungsgewalt-Argumentation wasserdicht in die Vermittler-Position einbetten.

**Konkrete Fragen für AGB-Review:**

1. **Plattform-Definition:** Sind wir nach unserer Architektur juristisch eindeutig „Vermittler" und nicht „Verkäufer"? Reichen unsere Wording-Regeln aus, um nicht versehentlich in eine Verkäufer-Haftung zu rutschen?

2. **Mediations-Service-Wording:** Wie formulieren wir den optionalen Streit-Mediation-Service, ohne dass er als rechtsverbindliche Schiedsvereinbarung interpretiert werden kann?

3. **Refund-Policy + Service-Gebühr:**
   - Bei klar-Verkäufer-Schuld (z. B. nicht versendet, falsche Karte): Voll-Refund inkl. Service-Gebühr
   - Bei Streitfall mit Lieferung: Service-Gebühr bleibt bei Plattform (Service erbracht)
   - Ist diese Differenzierung gerichtsfest? Wording-Vorschlag?

4. **Widerrufsrecht:**
   - P2P (Privat zu Privat): grundsätzlich kein Widerrufsrecht (kein Verbraucher-zu-Unternehmer-Geschäft)
   - Aber: was bei „Commercial Sellers" (gewerbliche Händler die unsere Plattform nutzen)? Wir haben das Feld `isCommercialSeller` im User-Profil. Reicht das? Müssen wir dann 14-Tage-Widerruf erzwingen?
   - Wie kommunizieren wir das im Cart-Flow? Hinweis bei kommerzieller Verkäufer-Anzeige?

5. **Haftungsausschluss:**
   - Riftr haftet nicht für Karten-Echtheit (sind ja Drittanbieter-Verkäufer)
   - Riftr haftet nicht für Versandschäden (außer Plattform-Bug der zur Falsch-Adresse führt)
   - Wie weit kann der Haftungsausschluss gehen? §§ 309, 307 BGB-Grenzen?

6. **EU-OSS-Pflicht:**
   - Bei EU-weitem Vertrieb (Service-Gebühren über die Grenze) müssen wir EU-One-Stop-Shop nutzen?
   - Steuerberater-Thema, aber rechtlich relevant für AGB-Wording

7. **Anti-Manipulation-Klauseln:**
   - Selbst-Käufe / Wash-Trading / Sock-Puppet-Reviews verboten — auch ohne Gerichtsverfahren?
   - Cardmarket hat Marktmanipulatoren erfolgreich verklagt — möglich für uns auch?

8. **Plattform-Recht zur Account-Sperrung:**
   - Bei Verstößen oder Fraud-Verdacht
   - Wie formuliert man das ohne überraschend zu sein?
   - Vorab-Warnung-Pflicht?

9. **Stripe-Vertrag-Verweis:**
   - Verkäufer-Onboarding bei Stripe = separater Vertrag mit Stripe Payments Europe Ltd.
   - Wir verweisen darauf im AGB. Reicht das?
   - Oder müssen wir Stripe's Vertrag mitliefern?

---

## 5. Datenschutzerklärung — Daten-Inventar

**Was wir sammeln (für DSGVO-Erklärung):**

### Pflicht-Daten (für Funktionalität)

| Datenart | Wofür | Wo gespeichert | Aufbewahrung |
|---|---|---|---|
| E-Mail | Login, Account | Firebase Auth (EU-region) | Account-Lebensdauer |
| Display-Name (Username) | Public-Profil, Reviews | Firestore EU | Account-Lebensdauer |
| Avatar (URL) | Public-Profil | Firestore EU + Firebase Storage EU | Account-Lebensdauer |
| Country | Versand-Berechnung | Firestore EU | Account-Lebensdauer |
| Adresse (Straße, PLZ, Stadt) | Käufer: Versand-Adresse / Verkäufer: Stripe-KYC | Firestore EU + Stripe (DE/IE) | Verkäufer dauerhaft (Compliance), Käufer pro Bestellung |
| Geburtsdatum (nur Verkäufer) | Stripe-KYC + DAC7-Reporting | Stripe (DE/IE) | gesetzlich erforderlich |
| Steuer-ID (TIN, ab Schwellenwert) | DAC7-Meldung (EU-Pflicht) | Stripe (DE/IE) | gesetzlich erforderlich |
| Bank-IBAN (nur Verkäufer) | Auszahlung über Stripe | Stripe (DE/IE) | Auszahlungs-Account-Lebensdauer |
| FCM-Push-Token | Benachrichtigungen | Firestore EU | Logout / Token-Refresh |
| Kartensammlung | Kern-App-Funktion | Firestore EU | Account-Lebensdauer |
| Bestell-Historie | Käufe + Verkäufe | Firestore EU | 10 Jahre (HGB-Aufbewahrung für Verkäufer) |
| Review-Texte | Public-Marketplace-Vertrauen | Firestore EU | Account-Lebensdauer |

### Auto-gesammelt (Tech)

- App-Crashes (anonym, via Firebase Crashlytics — geplant)
- IP-Adresse bei jedem Cloud-Function-Call (Logging, 30 Tage)
- Device-ID (Apple-DeviceCheck-Token, NICHT auswertbar — App-Check für Fraud-Prevention)

### NICHT gesammelt

- Echte Zahlungsmittel-Daten (Card-Number / CVV) — bleiben PCI-DSS-konform bei Stripe
- Gesundheitsdaten, sexuelle Orientierung, Religion, Politik
- Standort-Tracking (außer Country-Auswahl)
- Verhalten außerhalb Riftr (kein Tracking-Pixel, kein Cross-Site)

### Konkrete DSGVO-Fragen

1. **Rechtsgrundlagen:**
   - Account-Daten (Email, Profil): Vertragserfüllung Art. 6 (1) b
   - Marketplace-Daten (Bestellungen, Adressen): Vertragserfüllung
   - Stripe-KYC-Daten: gesetzliche Verpflichtung Art. 6 (1) c (PSD2, GwG)
   - Push-Tokens: Einwilligung Art. 6 (1) a
   - IP-Logging für Fraud: berechtigtes Interesse Art. 6 (1) f
   - Reicht das? Welche Wording-Vorschläge?

2. **Auftragsverarbeitungs-Verträge (AVV):**
   - Mit Google Cloud (Firebase) → AVV bereits standard im Google Workspace
   - Mit Stripe → über Stripe-Connect-Vertrag abgedeckt?
   - Mit Resend (Transaktions-Emails) → AVV nötig?
   - Mit Apple (Push via APNs) → AVV nötig?

3. **EU-Datentransfer:**
   - Firebase: explizit auf europe-west1 / europe-west3 konfiguriert
   - Stripe: Stripe Payments Europe Ltd. in Dublin → innerhalb EU
   - Apple Push: Apple Inc. (USA) — adäquater Schutz nach Schrems-II?
   - Welche Standardvertragsklauseln (SCC) brauchen wir?

4. **DSGVO-Rechte-Implementierung:**
   - Recht auf Auskunft → User kann bereits in App alle eigenen Daten sehen
   - Recht auf Löschung → wie weit? Bestell-Historie muss 10 Jahre HGB-aufbewahrt werden, aber Email kann pseudonymisiert werden?
   - Recht auf Datenübertragbarkeit → wie umsetzen? CSV-Export?
   - Reicht ein einfacher Email-Kontakt für DSGVO-Anfragen, oder müssen wir einen In-App-Self-Service bauen?

5. **Cookie-Banner / Tracking:**
   - Mobile-App ohne Web-Tracking — brauchen wir trotzdem ein Consent-Banner?
   - Push-Notifications: Apple/Google fragen schon system-side. Reicht das oder eigene Einwilligung?

6. **DAC7-Reporting (ab 2024 Pflicht):**
   - Stripe macht das automatisch ab €2000/Jahr Umsatz oder >30 Transaktionen pro Verkäufer
   - Riftr muss „nur" die Daten korrekt sammeln (TIN, DOB, Adresse) und Stripe weiterleiten
   - AGB-Hinweis nötig dass Daten an Finanzamt gemeldet werden?
   - Schwellenwert-Hinweise für Verkäufer im Onboarding?

7. **Fraud-Detection-Daten:**
   - Wir tracken: Buyer-Seller-Pair-Velocity (für Sock-Puppet-Detection), Rate-Limit-Counter, Stripe-Webhook-Events
   - Diese Daten enthalten User-IDs und Transaktions-Patterns
   - Berechtigtes Interesse Art. 6 (1) f? Wie lange dürfen wir die behalten? (aktuell 30 Tage rolling für Sock-Puppet-Tracking, 30 Tage für Stripe-Webhook-Dedup)

8. **DSGVO-Inhalt-Mindestpflichten:**
   - Welche Informationspflichten nach Art. 13/14 DSGVO?
   - Cookie-Hinweis falls auf der Marketing-Site getriffr.app weitere Cookies?

---

## 6. Sonstige rechtliche Themen

### Berufshaftpflicht

- Plattform-Mediation enthält Haftungs-Komponente (wenn wir bei Streit falsch entscheiden, kann Verkäufer/Käufer uns belangen)
- Welche Versicherungs-Größenordnung empfehlt ihr für Start?
- IT-Berufshaftpflicht oder Plattform-Betreiber-Haftpflicht?

### MwSt / Steuern

(parallel mit Steuerberater)
- Service-Gebühr + Provision sind unsere Einnahmen — MwSt-pflichtig?
- Bei Kleinunternehmer-Wahl: Grenze €22k Umsatz/Jahr?
- EU-OSS bei grenzüberschreitenden Käufen?

### Markenrechte / Riot Games

- Riftbound ist Riot-Trademark
- Wir nutzen keine Riot-Logos in der App-UI
- Kartennamen + Stats sind Game-Daten (Fair Use für Marktplatz-Nutzung?)
- Kartenbilder: aktuell laden wir vom Riot-CDN (cmsassets.rgpub.io) — rechtlich OK für Marktplatz-Listings?
- Sicherheit: brauchen wir formale Riot-Erlaubnis oder reicht „Fan-App"-Status?

### Verbraucherrechte EU

- Garantie / Sachmängel-Haftung bei Privat-Verkäufen: standard 2 Jahre, kann ausgeschlossen werden bei Privat-zu-Privat
- Bei kommerziellen Verkäufern: zwingend, kann nicht ausgeschlossen werden
- Wie kennzeichnen wir kommerzielle Verkäufer in der App damit Käufer's Rechte klar sind?

---

## 7. Anhänge (separate Dokumente)

1. **CLAUDE.md** (Auszug) — bestehender AGB-Wording-Draft + bewusste Anti-Patterns
2. **BACKLOG.md** — vollständige Security-Audit-Historie (29 verifizierte Findings + 11 dokumentierte Defer-Items)
3. **Architecture-Doc** — wie Stripe Connect **Destination Charges** mit `transfer_data` + `application_fee_amount` genau funktioniert (zur ZAG-Bewertung)
4. **Privacy-Inventory** — vollständige Liste aller Daten-Felder mit Speicher-Ort + Aufbewahrungsfrist

(Lass mich wissen welche Anhänge du brauchst, ich exportiere sie.)

---

## 8. Was ich vom Anwalt brauche

**Priorität:**

### High (Blocker für Launch)

1. AGB final-Drafts (auf Basis CLAUDE.md-Wording)
2. Datenschutzerklärung
3. Impressum-Vorlage
4. **ZAG-Memo zur Dokumentation der Zahlungsdienstegesetz-Befreiung** (kein BaFin-Antrag). Scope:
   - Subsumtion der konkreten Riftr-Architektur (Destination Charges + `transfer_data` + `application_fee_amount` + Standard Connected Accounts) unter § 1 Abs. 1 ZAG (Finanztransfergeschäft) und § 1 Abs. 1 Nr. 5 ZAG (Acquiring)
   - Bezugnahme auf BaFin-Merkblatt zum ZAG (Stand 2017 + Aktualisierungen)
   - Argumentation der fehlenden Verfügungsgewalt (Kernargument)
   - Abgrenzung zu klassischem Finanztransfergeschäft (z. B. PayPal-Architektur Pre-PSD2)
   - Stripe Payments Europe Ltd. als regulierter Akteur (irische E-Geld-Lizenz, EU-Passport)
   - Risikobewertung: Was ändert sich, wenn BaFin-Position kippt? Welche Architektur-Anpassungen wären nötig?
   - Empfehlung zu AGB-Klauseln, die die Befreiung stützen (Vermittler-Wording)
5. Widerrufsrecht-Klarstellung (P2P vs. kommerzielle Verkäufer)

### Medium (vor Live-Launch)

6. Allgemeine Haftungs-Klausel-Review
7. EU-Datentransfer-Bewertung (Schrems II)
8. Markenrechts-Bewertung Riot/Riftbound

### Low (parallel oder nach Launch)

9. Etwaige Riot-Trademark-Lizenz-Anfrage (oder Klarstellung dass Fan-App keine Lizenz braucht)
10. Vertragsgestaltung mit zukünftigen Commercial-Sellers (B2B-AGB falls anders)

---

## 9. Timeline + Budget-Erwartung

**Mein Plan:**
- 1-2 Wochen UG-Gründung (parallel zu Anwalt)
- 1-2 Wochen AGB + Datenschutz Anwalts-Review + Drafting
- 1 Woche Steuerberater-Klärung
- 1 Woche Stripe-Live-Mode-Antrag + Konfiguration
- = Realistic Live-Launch in 4-6 Wochen

**Budget-Erwartung für Anwalt:**
- AGB + Datenschutz + Impressum: €800 — €2.300
- Telefon-Termin für Erst-Beratung: 1-2 Stunden
- Wenn weitere Sachverständigen-Reviews nötig (z. B. BaFin-Bestätigung): zusätzlich

Bin offen für Pauschal-Angebot oder Zeit-basierte Abrechnung — was ist üblich für solche Plattform-Setups?

---

**Danke für die Zeit. Bin per Email + Phone gut erreichbar, gerne auch Video-Call falls Fragen offen sind.**

[DEIN NAME]
[DEINE TELEFONNUMMER]
eladiorubiohernandez@gmail.com
getriftr.app

---

*Dieses Briefing ist als Diskussions-Grundlage gedacht. Alle Architektur-Aussagen sind nach unserer technischen Bewertung gemacht und sollen rechtlich validiert werden.*

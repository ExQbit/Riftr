# Riftr Flutter — Developer Rules

> **Payment-Architektur-Migration: Phase 0–8 alle ABGESCHLOSSEN (2026-04-28).**
> Single-Seller-Buy + Multi-Seller-Cart + Refund/Dispute/Cancel + Admin-Mediation + Phase-7-UI-Polish + Phase-8-Test-Suite (46/46 gruen). Detaillierte Phasen-Notes in `BACKLOG.md`.
>
> Production-Blocker bleiben: UG-Gruendung, AGB, Datenschutzerklärung, Impressum, MwSt-Klärung, DAC7-Reporting, Berufshaftpflicht, FAQ-Seite (Anwalt + Steuerberater Track).

## Deploy-Regeln

1. Vor jedem Deploy: `flutter test` ausfuehren. Tests muessen gruen sein.
2. Vor jedem Deploy: Match-Stats pruefen (precise, fallback, skipped, unmatched)
3. Alle Preis-Felder muessen Komma als Dezimaltrenner akzeptieren: `input.replaceAll(',', '.')`
4. Showcase Rarity = NUR Overnumbered + Alternate Art Karten. Promos behalten Basis-Rarity.
5. Name-only Fallback darf precise Match nie ueberschreiben
6. Pre-Release: Alle zeitbasierten Trigger (Auto-Release, Reminders, Disputes) starten erst ab releaseDate, nicht Kaufdatum
7. Buttons die Geld/Versand betreffen immer fixiert am unteren Rand (Column[Expanded(ScrollView), Button])
8. Neue Sheets: Immer DragToDismiss Full-Screen (Navigator.push), nicht showRiftrSheet
9. SFD Common Rune cmId-Paare sind in der CF getauscht (Cardmarket API Bug) — siehe SFD_RUNE_SWAP unten

## Collection ↔ Listing Sync

- listing.qty geht nie unter reservedQty
- Listings mit offenen Orders koennen nicht gecancelled werden
- Manuelle Collection-Reduktion → Listings werden automatisch angepasst
- Collection-Reduktion unter offene Order-Menge wird blockiert mit Toast
- Collection -1 passiert bei markShipped, nicht confirmDelivery
- "Add to Collection" Toggle: AUS = aus bestehendem Bestand (fuellt auf wenn noetig), AN = komplett neue Karten

## Listing-Schema (Firestore + App-Integration)

Listings liegen unter `artifacts/riftr-v1/listings/{id}` mit folgenden **Pflicht-Feldern fuer App-Sichtbarkeit**:

- `cardId` = **RiftCard.id (UUID)** aus `assets/cards.json`. **NICHT** die Cardmarket cmId aus `market/overview` (das ist ein numerischer Pricing-Index, nicht die App-Card-ID).
- `setCode` = `"OGN"` / `"SFD"` / etc.
- `collectorNumber` = Card-Nummer als string oder int (z.B. `"27"`)
- `cardName`, `price`, `condition`, `quantity`, `sellerId`, `sellerName`, `sellerCountry`, `status: "active"`, `listedAt`
- `imageUrl` = optional (App fallt auf `card.media.image_url` aus cards.json zurueck)

**Wichtig:** CardService.loadCards() laedt aus `assets/cards.json` (statisches App-Bundle), NICHT aus Firestore. Listings die auf eine `cardId` verweisen die nicht in cards.json existiert, rendern in der App gar nicht — kein Card-Detail erreichbar = keine Listings sichtbar (silent fail im Browse).

`market/overview` Doc liefert nur die Preise + Trend-Metadaten (keyed by cmId). Bei Preisabfrage matched die App den cmId zur Riftbound-UUID via internem Lookup (siehe `MarketService`). Listings duerfen das nicht durcheinanderbringen.

## Preis-Matching

- Chart plottet p (Performance), NICHT v (totalValue)
- Alle Preis-Felder: Komma durch Punkt ersetzen vor dem Parsen
- Showcase = NUR Overnumbered + Alt Art Karten
- Promo-Karten behalten die Rarity ihrer Basis-Version
- Name-only Fallback darf precise Match nicht ueberschreiben
- SFD Common Rune Preise: Cardmarket API hat foil/non-foil vertauscht → cmId-Paare getauscht in CF (siehe SFD_RUNE_SWAP)

## SFD_RUNE_SWAP — KRITISCH

Die 6 SFD Rune Common/Showcase Paare haben bei Cardmarket vertauschte Preise.
Der Swap betrifft DREI Stellen in der CF (functions/index.js) die ALLE synchron bleiben muessen:

1. **Preis-Swap** (priceFields) — tauscht alle Preis-Werte zwischen cmId-Paaren
2. **History-Writes** — muessen NACH dem Preis-Swap getauscht werden, damit korrekte Preise in korrekte Docs landen
3. **c24-Berechnung** — nutzt die EIGENE History (mergedFoil/mergedNf), KEIN swappedHistoryMap

Wenn eine dieser Stellen geaendert wird, MUESSEN alle drei geprueft werden.
Nach jeder CF-Aenderung: SFD Rune Preise + c24 Werte in Firestore verifizieren.

Paare: 871893↔872478 (Fury), 871894↔872479 (Calm), 871895↔872480 (Mind),
871896↔872481 (Body), 871897↔872482 (Chaos), 871898↔872483 (Order)

## Outlier-Guards — Display + History anchoring (KRITISCH bei SFD-Swap)

`spikeGuard` und `movementGuard` korrigieren NICHT NUR die `historyWrites`,
sondern MUESSEN auch `prices[cmId].pF/pNf/p` synchron clampen. Sonst gibt
es Phantom-c24-Movements: Display zeigt den Raw-Tageswert, mergedHistory
hat den korrigierten Wert, und c24 = (raw - history) / history wird anomal.

Konkretes Bug-Beispiel (2026-04-28): SFD Calm Rune Common (cmId 871894)
nach Swap pNf=0.44 (raw von 872479), aber spike-corrected history=0.11.
c24 berechnet (0.44-0.10)/0.10 = +340% → Calm Rune wurde Top-Gainer.

Fix: spikeGuard schreibt zusaetzlich `prices[cmId].pX = round2(histX)` und
movementGuard schreibt `prices[cmId].pX = round2(lastPt.p)` wenn er feuert.
Beides ist post-Swap konsistent weil prices[cmId] und mergedHistory beide
auf den korrigierten Wert gehen, c24 = 0% (stabile Anchoring).

## Foil/Non-Foil Drei-Zonen Regel

Jede Karten-Anzeige (Chart, Preis, Overview, Tile) MUSS alle 3 Zonen beruecksichtigen:

**Zone 1 — isNonFoilOnly (OGS):**
Immer Non-Foil Preis + Non-Foil History. Kein Toggle. Kein Foil-Preis.

**Zone 2 — isFoilOnly (OGNX/SFDX/OGSX + Rare+ in OGN/SFD/UNL):**
Immer Foil Preis + Foil History. Kein Toggle. NF-Fallback bei Promo-Sets wenn Foil=0 (CM-Seller listen manchmal falsch).

**Zone 3 — Common/Uncommon in OGN/SFD/UNL:**
Toggle sichtbar. Beide Varianten. Non-Foil als Primary, Foil als Premium.

Code-Stellen (ALLE muessen synchron sein):
- CF: isPrimaryFoil Logik + Promo-Override (functions/index.js)
- Flutter Model: showVariantToggle + isFoilOnly + isNonFoilOnly (card_price_data.dart)
- Flutter Chart: chartData + _getStandardChartData + Chart-Render (market_screen.dart)
- Flutter Collection: isFoilVariant (firestore_collection_service.dart)

Pruef-Reihenfolge bei JEDER Aenderung an Chart/Preis-Logik:
1. OGS Karte oeffnen → Hat Chart? Zeigt NF-Preis?
2. OGNX Common oeffnen → Zeigt Foil-Preis? Kein Toggle?
3. OGN Common oeffnen → Toggle da? Beide Charts?
4. OGN Rare oeffnen → Kein Toggle? Foil-Chart?

## PREIS-VERIFIKATION (nach jedem CF Deploy) — PFLICHT

Nach JEDER Aenderung an fetchPricesDaily/fetchPricesManual diese Checks ausfuehren:

1. **SFD Runes (871893-871898):** c24 zwischen -20% und +20%? (NICHT -99%)
2. **OGNX Commons (856098, 856111, 856116):** Preis < EUR1? (NICHT Non-Foil EUR1-EUR13)
3. **OGNX Teemo Scout (850075):** Hat Preis? (NF-Fallback aktiv)
4. **OGS Karten:** Chart vorhanden? (Non-Foil History)
5. **OGN Rare (z.B. 847186 Ahri):** Preis unveraendert?
6. **Metal-Karten (PLATED_LEGEND):** Preise unveraendert?

Wenn EINER dieser Checks fehlschlaegt → SOFORT vorherige CF Version redeployen.
fetchPricesManual NICHT nochmal triggern bis Root Cause gefunden.

Verifikations-Script:
```
node -e "... (siehe functions/ fuer das aktuelle Script)"
```

## Geplant: verifyPriceIntegrity CF (v1.1, nach Launch)
Automatische Ausfuehrung der 6 Checks nach jedem Preisimport.
Bei Fehler: Push-Notification an ExQbit.

## UI Patterns

- DragToDismiss + ScrollView: Custom ScrollPhysics mit Lock, NICHT NotificationListener
- Buttons fixiert am unteren Rand: Column[Expanded(ScrollView), Button] — nicht im ScrollView
- Keyboard + Eingabefeld: Kein Delay-basierter Auto-Scroll. Stattdessen Button aus ScrollView rausnehmen.
- Wenn UI-Problem nach 2 Versuchen nicht geloest: Schritt zurueck, schauen wie andere Apps es machen, einfachsten Ansatz waehlen

### Card-Detail Action Buttons (Market / Cards / Collection)

Trade-Republic-Pattern, **konsistent in allen 3 Detail-Views** (Market-Tab Detail, Cards-Tab Preview, Collection-Tab Preview):

- **Buy / "Buy on Market"** = `RiftrButtonStyle.primary` (amber500), Icon `shopping_bag_outlined`, **links**
- **Sell** = `RiftrButtonStyle.secondary` (surfaceLight dark), Icon `sell_outlined`, **rechts**
- Beide `height: 56`, `radius: AppRadius.pill`, keine Shadows/Glow, keine `withValues`-Transparenz

**Wichtig — ueberschreibt aelteres V2-Design (§7.3 "Sell IMMER primary/amber"):** Konsens ist jetzt **Kaeufer-Aktion = primary, Verkaeufer-Aktion = secondary**. Begruendung: Buy ist die Akquise-Aktion, soll auffallen; Sell ist sekundaere Power-User-Funktion. Konsistentes Mental-Modell ueber alle Tabs hinweg, kein Farbwechsel beim Tab-Wechsel.

NICHT zurueckdrehen ohne Ruecksprache. Aelterer V2-Kommentar `Per V2 §7.3: Sell IMMER rechts + primary` ist obsolet.

## FAB Positioning Rules

- **Mit NavBar** (Market Tab, Decks Uebersicht): unterer FAB bottom: 68 + viewPadding, oberer FAB bottom: 133 + viewPadding. Slide 80px runter synchron mit NavBar via AppShell.navSlideNotifier + Transform.translate.
- **Ohne NavBar** (Deck Viewer, Deck Editor, Tracker VS/Battle): FABs auf gleicher visueller Hoehe wie Market FABs NACH dem Slide. Aktueller Wert: bottom: 22 (fest, kein Slide).
- Oberer FAB immer +65 ueber dem unteren.
- Kein Glow, kein Shadow auf FABs — clean flat design.
- NavBar Animation: Slide down/up (Transform.translate), NICHT Shrink/Blur/CustomPaint-Schrumpf-Animation.
- NavBar Scroll-Trigger: delta > 5 zum Verstecken, delta < -5 zum Zeigen, 200ms Debounce.
- Tab-Wechsel: NavBar sofort sichtbar (value = 1.0, kein Slide-In).
- Alle neuen Screens/Tabs muessen diese Werte einhalten.

---

# Payment-Architektur (Single Source of Truth fuer AGB / FAQ / Code)

> **Stand: 2026-04-28**, Entscheidung getroffen nach BaFin-/PSD2-Recherche + Stripe-Connect-Audit.
> Bei Aenderungen IMMER auch [BACKLOG.md](./BACKLOG.md) und AGB-Texte synchronisieren.

## Architektur-Grundsatz: Kein Wallet, kein Plattform-Halten

**Riftr berührt zu KEINEM Zeitpunkt das Geld der User.** Saemtliche Zahlungen laufen ueber Stripe Connect **Destination Charges** mit `transfer_data: { destination }` und `application_fee_amount` (NICHT Direct Charges — Direct Charges nutzen `stripeAccount` Header und Verkaeufer = merchant of record. Bei Destination Charges ist Riftr merchant of record, aber Stripe routet Gelder automatisch zum Connected Account, ohne dass Riftr operative Kontrolle ueber die Gelder hat). Riftr ist Vermittler, keine Zahlungsinstitution.

Was das bedeutet rechtlich:
- Keine BaFin-Erlaubnis noetig (PSD2 Art. 4 Nr. 11 — kein Zahlungsdienst da Riftr keine Gelder Dritter haelt oder weiterleitet)
- Stripe ist der lizenzierte Zahlungsdienstleister (Stripe Payments Europe Ltd., Lizenzen passportet nach DE)
- Verkaeufer schliesst beim Stripe-Connect-Express-Onboarding eigenstaendige Vertraege mit Stripe ab
- Riftr's Marktplatzbetrieb ist von der "commercial agent exception" gedeckt **nicht** (BaFin-Auslegung) — daher der Destination-Charges-Pfad mit auto-routing zum Connected Account zwingend (kein Plattform-Halten)

Was das bedeutet technisch:
- KEINE der folgenden Cloud-Functions darf wieder eingebaut werden: `topUpBalance`, `purchaseWithBalance`, `requestPayout` (alte wallet-Variante)
- KEINE Manipulation von `stripe.customers.balance` fuer Marketplace-Zwecke
- KEINE eigene `wallet_balance`-Persistenz in Firestore-User-Dokumenten
- Wenn ein Feature "Guthaben verschieben" will → es ist falsch konzipiert, neu denken

## Gebuehren-Modell (Stand 2026-04-28)

Alle Werte in Cents fuer interne Berechnung, EUR fuer User-Anzeige.

### Service-Gebuehr (Kaeufer-seitig, je Bestellung)

Gestaffelt nach `cartSubtotalCents` (Karten-Wert ohne Versand):

| Bestell-Subtotal | Service-Gebuehr (Basis) |
|---|---|
| < 15,00 € | 0,49 € |
| 15,00 – 50,00 € | 0,79 € |
| 50,00 – 200,00 € | 1,29 € |
| > 200,00 € | 1,99 € |

**Multi-Seller-Aufschlag:** zusätzlich `+ 0,30 € pro zusätzlichem Verkäufer` (also `0,30 × (N-1)`).

Die Service-Gebühr wird **einmal pro Cart** berechnet und auf den ersten PaymentIntent gepackt. Andere PaymentIntents tragen nur ihre eigene Provision.

Variable: `cartSubtotalCents` (NICHT `orderTotalCents`) damit klar ist dass Versand nicht eingerechnet ist.

### Provision (Verkaeufer-seitig, vom Karten-Wert)

| Bestell-Subtotal | Provisions-Rate |
|---|---|
| < 15,00 € | 5,0 % |
| 15,00 – 50,00 € | 5,5 % |
| 50,00 – 200,00 € | 6,0 % |
| > 200,00 € | 6,5 % |

Wird ueber Stripe `application_fee_amount` (Service-Gebuehr + Provision summiert) abgerechnet.

### Stripe-Fee — traegt IMMER Riftr-Plattform

Kein dynamisches `on_behalf_of`. Stripe-Fee (1,5 % + 0,25 €) geht ueber die `application_fee_amount` zu Riftr's Lasten. Saubere Buchhaltung, keine User-Verwirrung im Stripe-Statement der Verkaeufer.

### Code-Implementation

`functions/index.js` — `calculateOrderFees(cartSubtotalCents, sellerCount)`:
- liefert `{ serviceFeeCents, platformCommissionCents, totalApplicationFeeCents }`
- Multi-Seller-Skalierung nur bei `sellerCount > 1` als `+30 × (N-1)` Cents

## Auszahlungs-Tier-System (delay_days dynamisch)

Stripe Connect Express `payout_schedule.delay_days` wird per Verkaeufer-Reputation gestaffelt.

### Tier-Definition

| Tier | Verkaeufe (`completedSalesCount`) | Bewertung (`rating`) | Min. Reviews | `delay_days` |
|---|---|---|---|---|
| **Neu** | < 10 | — | — | **7 Tage** (Default) |
| **Etabliert** | 10–49 | ≥ 4,75 / 5,0 | ≥ 5 | **5 Tage** |
| **Trusted** | 50–199 | ≥ 4,90 / 5,0 | ≥ 5 | **3 Tage** |
| **Power-Seller** | 200+ | ≥ 4,95 / 5,0 | ≥ 5 | **1 Tag** |

**Wichtige Einschraenkung:** Power-Seller-Delay (1 Tag) gilt **nur bei Bestellungen ≤ 100 €**. Bestellungen > 100 € fallen fuer ALLE Tiers auf 7 Tage zurueck. Schuetzt vor hohen Verlusten bei seltenen High-Value-Karten.

### Stripe Risk-Floor fuer neue Connect-Accounts

Stripe enforced bei neuen Express-Connect-Accounts einen **Risk-Floor von typisch 7 Tagen** auf `payout_schedule.delay_days`. Versuch `delay_days < 7` setzen vor Floor-Lift gibt `400 "You cannot lower this merchant's delay below 7"`.

Floor wird von Stripe automatisch gesenkt nach Onboarding + Risk-Eval-Periode (variabel, typisch 3-30 Tage je nach Volumen + Risk-Score). Plattform kann nicht aktiv triggern.

**Konsequenz fuer Tier-System:**
- `applyTierToStripeAccount` faengt Floor-Error mit try/catch ab und setzt auf den Floor-Wert (Default 7) als Fallback.
- Profile schreibt **zwei Felder**: `delayDays` (logischer Tier-Soll, was UI zeigt) + `stripeDelayDaysActual` (was Stripe gerade enforced) + `stripeFloorActive` (Boolean-Marker).
- Beim naechsten `syncSellerTier`-Trigger wird der Soll-Wert erneut versucht — sobald Stripe den Floor gesenkt hat, geht's automatisch durch.
- Audit-Log dokumentiert Divergenz fuer Ops-Forensik.

UI-Konsequenz: User sieht den Tier-Soll-Wert (Auszahlung in 1/3/5/7 Tagen) — nicht den Floor. Tatsaechliche Stripe-Auszahlung kann initial laenger dauern. Akzeptiertes Inkonsistenz-Fenster fuer Sandbox + erste Live-Wochen, da der Effekt vor allem neue Power-Seller betrifft (die ohnehin nicht direkt nach Account-Creation 200 Verkaeufe haben).

### Stripe Reserve fuer Power-Seller

Power-Seller-Tier zusaetzlich mit Stripe-Connect Reserve abgesichert:
- 5 % rolling 7 Tage
- Konfiguriert via `stripe.accounts.update({ settings: { reserves: ... }})`
- Stripe verwaltet die Reserve automatisch (kein BaFin-Risiko, kein Riftr-Halten)
- Trusted/Etabliert/Neu: keine Reserve noetig (Delay reicht als Buffer)

### Trigger-Mechanismus

Tier-Update in Cloud-Function `calculateDelayDays(seller)` bei diesen Events:
1. **Bei `submitReview`** — neue Bewertung kann Schwelle ueberschreiten
2. **Bei `confirmDelivery`** — `completedSalesCount++` kann Schwelle ueberschreiten
3. **Daily-Cron als Fallback** — fuer Edge-Cases wo Trigger ausfaellt

API-Call beim Update:
```js
await stripe.accounts.update(sellerStripeAccountId, {
  settings: { payouts: { schedule: { delay_days: newDelayDays } } }
});
```

### KEIN per-Order Payout-Override (Architektur-Entscheidung 2026-04-28)

**`confirmDelivery` darf `delay_days` NICHT verkuerzen.** Auch nicht "wenn Kaeufer aktiv bestaetigt → sofort auszahlen". Begruendung:

1. **BaFin-Posture:** Statischer `delay_days` per Connect-Account = reine Schedule-Konfig, keine Plattform-Entscheidung pro Order. Sobald Riftr per Order entscheidet "jetzt freigeben", trifft die Plattform Wertentscheidungen am Geld → das ist genau was Zahlungsdienst-Lizenz erfordert. Cardmarket darf das weil sie Malta-Zahlungsinstitut sind. Riftr nicht.
2. **Stripe-API:** `payout_schedule.delay_days` ist Account-global, nicht per-Charge. Per-Order-Override braucht `payout_schedule: 'manual'` + admin-getriggerte `payouts.create()` — accounting-tricky bei mehreren offenen Orders pro Seller (Stripe `available balance` ist aggregiert, nicht per-Charge gefenced).
3. **Real-World:** ~70-80 % der Kaeufer klicken `confirmDelivery` nie aktiv (Auto-Complete-Fallback dominiert). Komplexitaet fuer Edge-Case nicht wert.

**Stattdessen UX-Aufwertung in Phase 7 (rein Front-End, kein Cashflow-Eingriff):**
- Push an Verkaeufer bei `confirmDelivery`: *"Kaeufer hat Erhalt bestaetigt — Auszahlung wie geplant in X Tagen"*
- Dashboard-Zeile *"Auszahlung gesichert — keine Reklamationsfrist mehr offen"* wenn Bestaetigung vor `delay_days` kommt

Echter Risiko-Hedge bleibt der **€100-Cap** (Bestellungen > 100 € → 7 Tage fuer ALLE Tiers).

**Diese Entscheidung NICHT re-diskutieren** ohne neuen rechtlichen Input (z.B. eigene BaFin-Lizenz oder Mangopay-Wechsel).

### Manueller Admin-Override

Admin-Cloud-Function `setSellerDelayDays(uid, days)` erlaubt manuellen Override fuer Beta-Tester und Edge-Cases (z.B. nach Streit-Schlichtung, fuer Promo-Aktionen, Test-Walkthroughs). Generisch implementiert — kein User-spezifischer Code, keine hardcoded UIDs. Authentifizierung: nur Riftr-Admin-Account. Audit-Log in `users/{uid}/data/sellerProfileAudit/{timestamp}` mit Begruendungs-Feld.

Nach Beta-Launch bleibt die Function als Operations-Tool erhalten (Support-Cases).

## Multi-Seller-Cart Implementation

**Strategie: Sequenzielle PaymentIntents mit Auto-Refund bei Teilfehler.**

### Pre-Step: Karte speichern (einmalig pro User)

```js
const setup = await stripe.setupIntents.create({
  customer: buyerStripeCustomerId,
  payment_method_types: ['card'],
  usage: 'off_session',
});
```
Frontend confirmiert → speichert `payment_method` in `users/{uid}/data/buyer.defaultPaymentMethodId`.

### Sequenzielle Abrechnung

```js
async function processMultiSellerCart(cartGroups, paymentMethodId, customerId) {
  const successful = [];
  for (let i = 0; i < cartGroups.length; i++) {
    const group = cartGroups[i];
    const fees = calculateOrderFees(group.subtotalCents, cartGroups.length);
    // Service-Gebuehr nur auf den ersten Charge
    const serviceFeeForThis = i === 0 ? fees.serviceFeeCents : 0;
    try {
      const pi = await stripe.paymentIntents.create({
        amount: group.subtotalCents + group.shippingCents + serviceFeeForThis,
        currency: 'eur',
        customer: customerId,
        payment_method: paymentMethodId,
        off_session: true,
        confirm: true,
        transfer_data: { destination: group.sellerStripeAccountId },
        application_fee_amount: serviceFeeForThis + fees.platformCommissionCents,
      });
      successful.push({ pi, group });
    } catch (err) {
      await rollbackCharges(successful);  // Refund alle vorherigen
      throw new HttpsError('aborted', `Charge ${i+1}/${cartGroups.length} failed`);
    }
  }
  return successful;
}
```

### Rollback bei Teilfehler

```js
async function rollbackCharges(successful) {
  for (const { pi } of successful) {
    await stripe.refunds.create({
      payment_intent: pi.id,
      reverse_transfer: true,
      refund_application_fee: true,
    });
  }
}
```

**Wichtig:** Stripe-Fixfee (0,25 €) pro refundetem Charge wird **nicht** zurueckerstattet → Riftr-Verlust bei Rollback. Bei 5-Seller-Cart mit Fehler in Charge #5: 4 × 0,25 € = 1,00 € Verlust. Kalkuliert als Akquise-Risiko.

### 3DS-Challenge bei off_session

Wenn Stripe `requires_action` zurueckgibt → Frontend re-confirm on_session. UI muss damit umgehen koennen ("Charge 2 von 3 braucht weitere Authentifizierung").

## Smart-Cart Cost-Function (Gebuehren-aware)

Smart Cart optimiert auf **Gesamtkosten fuer den Kaeufer** inkl. Service-Gebuehr-Skalierung:

```js
function calculateCartTotalCost(sellerCombo) {
  const N = sellerCombo.length;
  const cartSubtotal = sellerCombo.reduce((s, sel) => s + sel.cardSubtotal, 0);
  const shipping = sellerCombo.reduce((s, sel) => s + sel.shippingCost, 0);
  const serviceFee = baseServiceFee(cartSubtotal) + 30 * (N - 1);
  return cartSubtotal + shipping + serviceFee;
}
```

UI-Hinweis: **"Smart Cart spart dir X € vs. günstigste Einzelpreise"** prominent. Top 3-5 Alternativen anzeigen.

Smart Cart bevorzugt natuerlich Buendelung bei einem Verkaeufer wenn moeglich. Kein Hardcap auf Verkaeufer-Anzahl.

## UI / UX — kritische Wording-Regeln

### Was NIE in UI / Marketing / AGB stehen darf

- ❌ "Kaeuferschutz" / "Buyer Protection" — schafft §307 BGB Gewaehrleistungs-Anspruch
- ❌ "Kaeufer-Garantie" / "Geld-zurueck-Garantie"
- ❌ "Sicherheits-Gebuehr" / "Trust-Gebuehr"
- ❌ "100 % Sicherheit" / "Wir erstatten dein Geld"
- ❌ "Auf deinem Stripe-Konto" (User-Verwirrung — User kennt Riftr, nicht Stripe)

### Was OK ist

- ✅ "Service-Gebuehr" — neutral, eBay/Vinted-Standard, kein Versprechen
- ✅ "Mediations-Service bei Streitigkeiten" — beschreibt Service, kein Versprechen
- ✅ "Faire Streitbeilegung ist Teil unserer Plattform"
- ✅ "in deinem Riftr-Konto" / "auf deinem Verkaeufer-Guthaben"

### Verkaeufer-Dashboard bei neuer Bestellung

```
Bestellung #1234
Status: Bezahlt — bitte verschicken
Betrag: 23,75 € (in deinem Riftr-Guthaben)
Auszahlung am 5. Mai (in 7 Tagen)
[Tracking-Nummer eintragen]
```

- "in deinem Riftr-Guthaben" — NICHT "Stripe-Konto"
- Konkretes Datum + "(in X Tagen)" — Doppelinfo gegen Verwirrung
- Tier-aware: 1/3/5/7 Tage je nach Verkaeufer-Status

### Push-Notification-Texte

In `functions/index.js`:
```js
sendNotification(sellerId,
  "Bestellung bezahlt — bitte versenden",
  `${summary} • ${totalEur} • Versand innerhalb 7 Tagen`)
```

Bei `confirmDelivery`:
```js
sendNotification(sellerId,
  "Bestellung abgeschlossen",
  `Auszahlung: in ${delayDays} Tag${delayDays === 1 ? '' : 'en'}.`)
```

### First-Time-Seller Modal (einmalig bei erstem bezahlten Verkauf)

> "Glueckwunsch zu deinem ersten Verkauf!
>
> 1. Verschicke die Karte innerhalb 7 Tagen
> 2. Trage die Tracking-Nummer ein
> 3. Sobald der Kaeufer bestaetigt + Sicherheits-Frist abläuft, geht das Geld an deine Bank
>
> Dein Status: **Neu** — Auszahlung erfolgt 7 Tage nach Bezahlung.
> Mit mehr Verkaeufen + guten Bewertungen schaltest du schnellere Auszahlungen frei."

Trigger: `sellerProfile.completedSalesCount === 0` beim ersten paid-Order.

## Refund / Chargeback / Dispute

### Refund single-seller

```js
await stripe.refunds.create({
  payment_intent: piId,
  amount: refundAmountCents,           // optional, sonst voll
  reverse_transfer: true,              // Geld vom Verkaeufer-Connect zurueck
  refund_application_fee: true,        // Service+Provision zurueck zu Plattform
});
```

### Refund-Policy (Phase 6, 2026-04-28) — differenziert nach Schuld

Implementiert in `functions/index.js` → `resolveRefundPolicy(order, reasonCode, refundPercent)`. Source-of-Truth fuer alle Refund-Pfade (`respondToRefund`, `cancelOrder`, `acceptCancelOrder`, `adminResolveDispute`).

**Voll-Refund inkl. Service-Gebuehr** (`refund_application_fee: true`):
- `not_arrived` + `letter` (untracked) — Verkaeufer haftet by-design
- `not_arrived` + `tracked` ohne `trackingNumber` — Verkaeufer hat Tracking-Pflicht verletzt
- `wrong_card_received` — klar Verkaeufer-Fehler
- `damaged_in_shipping` (NICHT insured) — Plattform springt ein

**Teil-Refund OHNE Service-Gebuehr** (`refund_application_fee: false`, Buyer-Refund cappes auf `totalCents − serviceFeeCents`):
- Beliebiges `refundPercent < 100` — Streitfall, Verkaeufer hat geliefert
- `wrong_condition` (Karten-Zustand-Streit) auch bei 100% — Verkaeufer hat geliefert, war Qualitaets-Streit

**Reject (kein Plattform-Refund)**:
- `not_arrived` + `insured` — Carrier-Pfad, Buyer reklamiert direkt bei Versicherer (Deutsche Post / DHL). `openDispute` rejected mit Hinweis-Message.

**Multi-Seller-Rollback (Phase 4)**: Voll-Refund inkl. Service-Gebuehr (Plattform-Fehler).

**Alle Refunds: `reverse_transfer: true`** — Stripe pulled Geld vom Verkaeufer-Connect-Account zurueck. Pre-Phase-6 fehlte das → Plattform absorbierte den vollen Refund-Betrag (kritischer Production-Bug, gefixed bei der Migration).

### Admin-Mediation (Phase 6.5)

Wenn Buyer + Seller sich nicht ueber `proposeRefund` / `respondToRefund` einigen koennen, kann Admin per `adminResolveDispute(orderId, refundPercent, reason, applyServiceFeePolicy)` als Tie-Breaker entscheiden:
- `refundPercent: 0` → Order zurueck zu `shipped`, neuer 7-Tage-Auto-Release
- `refundPercent: > 0` → Stripe-Refund via Policy-Engine
- `applyServiceFeePolicy: false` → Admin-Override, Service-Fee bleibt IMMER bei Plattform
- Audit-Log: `orders/{orderId}/disputeAudit/{timestamp}` mit Begruendung, Admin-UID, Outcome, Stripe-Refund-ID
- Frontend: `admin_disputes_screen.dart` — sichtbar nur fuer User mit `admin: true` Custom-Claim
- Auth: `request.auth.token.admin === true` Check in beiden Admin-CFs (`adminListDisputes`, `adminResolveDispute`)

### Chargeback-Vermittlung

Stripe holt bei Kaeufer-Bank-Chargeback automatisch Geld vom Verkaeufer-Connect-Account zurueck. Verkaeufer hat keinen Stripe-Dashboard-Zugriff → Riftr muss vermitteln:
- Stripe sendet `charge.dispute.created` Webhook
- Cloud-Function liest Dispute-Reason
- Push an Verkaeufer mit Aufforderung Tracking-Nummer / Versand-Beleg einzureichen
- Riftr-Admin reicht via Stripe-Dashboard-API gegen Chargeback ein
- Falls Verkäufer-Account leer (delay_days bereits abgelaufen + Reserve aufgebraucht): Riftr traegt Restbetrag

### Treuhand-Mechanismus

`delay_days` von Stripe + 5 %-Reserve fuer Power-Seller = de-facto Treuhand. Riftr muss kein eigenes Treuhand-Konto fuehren (das waere BaFin-pflichtig).

## Was BEWUSST nicht eingebaut wird (anti-Patterns)

| Anti-Pattern | Warum nicht | Was stattdessen |
|---|---|---|
| Eigenes Wallet mit `customers.balance` | BaFin-pflichtig laut Stripe Connect Service Agreement | Destination Charges via `transfer_data` + `application_fee_amount` |
| `requestPayout` als manueller Trigger vom Plattform-Konto | Setzt Plattform-Halten voraus | Stripe automatischer Payout via `delay_days` |
| Refund-Rueckholung von Plattform-Konto | Plattform haelt Geld — BaFin-Issue | `reverse_transfer: true` holt's vom Verkaeufer-Connect |
| `customer.balance > 0` fuer Marketplace-Wallets | Stripe T&C Section C verboten fuer Plattformen | Stripe Customer Balance nur fuer Refund-Credits/Promotions |

## AGB-Klausel-Vorlage (Single Source of Truth)

Die AGB muss diese Punkte in genau dieser Sprache enthalten — Anwalts-Reviews ja, aber substanzielle Aenderungen muessen synchronisiert werden mit:
1. Code in `calculateOrderFees`
2. UI-Texte in Cart-Screen / Sell-Sheet
3. FAQ
4. dieser CLAUDE.md

```
§ X — Service-Gebuehr und Provision

Riftr finanziert sich durch zwei transparente Gebuehren-Komponenten:

(1) Service-Gebuehr (Kaeufer)
   Pauschale Service-Gebuehr pro Bestellung, gestaffelt nach Bestellwert
   (siehe Gebuehrenseite). Bei Bestellungen mit mehreren Verkaeufern
   zusaetzlich 0,30 € pro zusaetzlichem Verkaeufer.

   Die Service-Gebuehr deckt die laufenden Plattform-Kosten ab:
   - Bereitstellung und Wartung der Marketplace-Infrastruktur
   - Zahlungsabwicklung
   - Optionaler Mediations-Service bei Streitigkeiten

   Hinweis: Die Service-Gebuehr begruendet KEINE eigenstaendigen
   Gewaehrleistungs- oder Garantieansprueche gegenueber Riftr.
   Die rechtliche Beziehung zur Erfuellung des Kaufvertrags besteht
   ausschliesslich zwischen Kaeufer und Verkaeufer.

(2) Provision (Verkaeufer)
   Provision von 5,0–6,5 % des Verkaufspreises, gestaffelt nach
   Bestellwert (siehe Gebuehrenseite). Wird automatisch vom
   Verkaufserloes abgezogen.

§ Y — Auszahlung

Die Auszahlung an Verkaeufer erfolgt automatisch ueber unseren
Zahlungsdienstleister Stripe. Die Auszahlungsfrist (delay_days) richtet
sich nach dem Verkaeufer-Status:

   Neu (< 10 Verkaeufe):              7 Tage
   Etabliert (10-49, ≥4,75 Sterne):  5 Tage
   Trusted (50-199, ≥4,90 Sterne):    3 Tage
   Power-Seller (200+, ≥4,95 Sterne): 1 Tag (nur bei Bestellungen ≤ 100 €)

Bei Bestellungen ueber 100 € erfolgt die Auszahlung fuer ALLE
Verkaeufer-Stufen nach 7 Tagen.

§ Z — Zahlungsabwicklung

Riftr selbst nimmt keine Zahlungen entgegen. Saemtliche Zahlungen werden
ueber Stripe Connect (Stripe Payments Europe Ltd.) abgewickelt.
Verkaeufer schliessen beim Onboarding einen separaten Vertrag mit
Stripe ab.
```

## FAQ-Antworten (Sprach-Vorlage)

> **Warum gibt es eine Service-Gebuehr?**
> Die Service-Gebuehr deckt die laufenden Kosten der Plattform — von Server-Infrastruktur ueber Zahlungsabwicklung bis hin zu Support- und Mediations-Services. Sie ist gestaffelt nach Bestellwert: 0,49 € fuer kleine Bestellungen bis 1,99 € fuer Bestellungen ueber 200 €.

> **Warum ist die Service-Gebuehr bei Multi-Verkaeufer-Carts hoeher?**
> Pro zusaetzlichem Verkaeufer wird die Bearbeitung aufwendiger (separater Versand, separate Zahlung). Wir berechnen 0,30 € pro zusaetzlichem Verkaeufer. Smart Cart hilft dir automatisch die guenstigste Variante zu finden — meistens lohnt sich Buendelung bei einem Verkaeufer.

> **Wann bekomme ich als Verkaeufer mein Geld?**
> Sobald die Bestellung bezahlt ist, ist das Geld auf deinem Riftr-Guthaben sichtbar. Die Auszahlung an deine Bank erfolgt nach 1–7 Tagen, abhaengig von deinem Verkaeufer-Status. Mit mehr Verkaeufen und guten Bewertungen verkuerzt sich diese Frist automatisch.

> **Was passiert wenn ich nicht zufrieden bin?**
> Riftr bietet einen kostenlosen Mediations-Service bei Streitigkeiten an. Du kannst eine Bestellung im Order-Detail melden — wir vermitteln zwischen dir und dem Verkaeufer. Die rechtliche Beziehung zur Erfuellung des Kaufvertrags besteht zwischen dir und dem Verkaeufer.

> **Hat Riftr selbst Zugriff auf mein Geld?**
> Nein. Riftr ist Vermittler, kein Zahlungsdienstleister. Saemtliche Zahlungen laufen ueber Stripe Connect (Stripe Payments Europe Ltd., reguliert nach EU-PSD2). Riftr berührt zu keinem Zeitpunkt das Geld der User.

## Kritische Dont's bei zukuenftigen Aenderungen

1. **NIEMALS** `topUpBalance` / `purchaseWithBalance` / `requestPayout` wieder einbauen — auch nicht "fuer Marketing-Zwecke" oder "weil's UX-mäßig schöner ist". Die BaFin-Recherche-Linie ist klar. Diese Functions wurden in Phase 2 (2026-04-28) hart entfernt.
2. **NIEMALS** die Wording-Regel "Kaeuferschutz" verletzen — selbst wenn Marketing dafuer drueckt.
3. **NIEMALS** `customers.balance` als End-User-Wallet-Persistenz nutzen.
4. **NIEMALS** `delay_days: 0` auf Connect-Accounts setzen — auch nicht fuer Power-Seller. Stripe-Reserve braucht Buffer-Zeit.
5. **NIEMALS** Service-Gebuehr-Refund per Default einbauen — Default ist non-refundable (Service erbracht).
6. **NIEMALS** Multi-Seller-Cart als Single-PaymentIntent mit `transfer_group` machen — das ist die "Plattform haelt Geld kurz" Variante die BaFin-Risiko ist.

## Offene Themen (Stand 2026-04-28)

Diese Punkte werden parallel mit Anwalt / Steuerberater geklaert:

- **MwSt-Behandlung** der Service-Gebuehr und Provision (gross/netto, B2B/B2C)
- **DAC7-Reporting** Felder im Verkaeufer-Profil (TIN, Geburtsort/-datum, Adresse, Steuer-ID, IBAN)
- **UG-Gruendung** vor Live-Schaltung (persoenliche Haftung sonst)
- **Refund-Policy** fuer Service-Gebuehr (derzeit non-refundable als Default)
- **Custom Käuferschutz-Versicherung** als Phase-2-Premium-Feature (opt-in fuer 0,99 € statt 0,49 €) — explizit OPTIONAL und mit konkreter Leistungsbeschreibung
- **Berufshaftpflicht-Versicherung** fuer Riftr (Plattform-Mediation bringt Haftungs-Komponente)

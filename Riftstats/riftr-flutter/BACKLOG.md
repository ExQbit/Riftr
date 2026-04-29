# Riftr — Master Backlog

Stand: 28. April 2026

---

## ⚡ AKTIVER TRACK: Payment-Architektur-Migration (28.04.2026)

> **Single Source of Truth: [CLAUDE.md → Payment-Architektur](./CLAUDE.md).**
> Alle Aenderungen synchron mit AGB / FAQ / Code halten.

### Phase 0 — Sandbox-Setup ✅ ABGESCHLOSSEN (2026-04-28)
- [x] 3 Test-Connect-Accounts angelegt:
      - TEST-NEU `acct_1TR7kmIXOlGJS5jy` (delay_days logisch: 7)
      - TEST-TRUSTED `acct_1TR8D9I4CVzU7FjG` (delay_days logisch: 3, Stripe-Floor: 7)
      - TEST-POWER `acct_1TR8DDIsGZYtkZqG` (delay_days logisch: 1, Stripe-Floor: 7)
- [x] Test-Verkaeufer-Profile in Firestore unter `_test_seller_TEST-{NEU,TRUSTED,POWER}` mit fake `rating`, `reviewCount`, `completedSalesCount`
- [x] Admin-Cloud-Function `setSellerDelayDays(uid, days, reason)` mit Audit-Log + Floor-Fallback
- [x] `applyTierToStripeAccount` mit Stripe-Floor-Fallback (try/catch + retry mit Floor-Wert)
- [x] Custom-Claim `admin: true` auf Riftr-Admin-Account `DfAEtNC3rYcCIEuvODWwolNVHUA3`
- [ ] **Ops-TODO (Production):** Stripe Reserve 5% / 7d rolling fuer Power-Seller — Express Reserve ist NICHT API-accessible, MUSS manuell im Stripe-Dashboard pro Account ueber Risk Settings → Reserves gesetzt werden, sobald ein Verkaeufer Power-Tier erreicht. Audit-Log triggert den Hinweis. POWER-Sandbox-Account `acct_1TR8DDIsGZYtkZqG` kann nach erstem Test-Charge fuer den Workflow getestet werden.
- [ ] **Manueller Schritt (optional, fuer naechste Session):** Stripe-Dashboard Floor-Override fuer TRUSTED/POWER auf 3/1 — Test-Mode-Dashboard erlaubt das oft sofort, sonst nach Risk-Eval-Periode
- [ ] **Optional fuer echtes End-to-End:** KYC-Onboarding der 3 Test-Accounts via Onboarding-URLs (Stripe Test-Daten: SSN `000-00-0000`, Geburtstag `01-01-1901`, Adresse `address_full_match`). Aktueller Stand: Accounts in "Eingeschraenkt" — PaymentIntents lassen sich erstellen + Math verifizieren, Transfer geht aber in `pending` bis KYC durch.

### Phase 1 — Single-Seller-Path (Code) ✅ ABGESCHLOSSEN (2026-04-28)
- [x] `calculateOrderFees(cartSubtotalCents, sellerCount)` mit Staffel — 37 Unit-Tests gruen
- [x] `calculateDelayDays(seller)` + `getEffectiveDelayDays(seller, total)` mit €100-Cap
- [x] `createPaymentIntent` ergaenzt um `application_fee_amount` + `transfer_data` + `effectiveDelayDays`-Metadata
- [x] Order-Doc mit Cent-Feldern (`cartSubtotalCents`, `serviceFeeCents`, `platformCommissionCents`, `totalApplicationFeeCents`, `sellerPayoutCents`, `commissionRateUsed`, `sellerCount`, `chargeIndex`, `effectiveDelayDays`) parallel zu Legacy-EUR-Feldern
- [x] Trigger-Hooks in `submitReview` + `confirmDelivery` (try/catch, swallow errors damit Hauptpfad nicht blockt)
- [x] Daily-Cron `recalculateAllSellerTiers` (03:00 Berlin)
- [x] Stripe-Floor-Fallback in `applyTierToStripeAccount` (try/catch + retry mit Floor-Wert)
- [x] **Sandbox-Math-Validierung** via `phase1_math_validation.js` — 52/52 Checks gruen fuer NEU/POWER (TRUSTED uebersprungen wegen unvollstaendigem KYC, Math-Logik aber bestaetigt). PIs erzeugt mit korrektem `amount` / `application_fee_amount` / `transfer_data.destination` / `capture_method: manual` / Metadata. Tests ohne Charge-Execution (confirm:false) — End-to-End SCA-Flow laeuft erst ueber Frontend in Phase 3.

### Phase 2 — Wallet-Code raus + Buy-Flow-Switch ✅ ABGESCHLOSSEN (2026-04-28)
- [x] Backend: `topUpBalance`, `purchaseWithBalance`, `requestPayout` entfernt
- [x] Backend: Top-Up-Branch in `stripeWebhook` entfernt
- [x] Backend: tote Wallet-Helper entfernt (getBalance, getAvailableBalance, countTodayTopUps, countHourlyPurchases, getTodayPayoutTotal)
- [x] Backend: `payment_intent.amount_capturable_updated` Webhook-Handler hinzugefuegt — flippt Order pending_payment → paid + Push an Verkaeufer (Phase-1-Voraussetzung die im Phase-1-Code gefehlt hatte)
- [x] Backend: `paymentMethod: "stripe"` ins createPaymentIntent Order-Doc; markShipped Capture-Gate vereinfacht (`if (order.stripePaymentIntentId)`)
- [x] Frontend: `WalletService.topUp/purchaseWithBalance/purchaseCartWithBalance/requestPayout` Methods entfernt
- [x] Frontend: `wallet_screen.dart` zu Read-Only Earnings-View umgebaut (Top-Up + Payout Sektionen weg, Balance-Card + Tx-History bleiben, Header "EARNINGS")
- [x] Frontend: `checkout_sheet.dart` Buy-Flow auf `createPaymentIntent` + `Stripe.presentPaymentSheet` umgestellt — alle Wallet-Balance-Checks + Top-Up-Options + Top-Up-Buy-Loop entfernt
- [x] Frontend: `bulk_checkout_sheet.dart` geloescht (Phase 4 schreibt's neu mit SetupIntent)
- [x] Frontend: `cart_screen.dart` Multi-Seller-Branch auf Toast `'Multi-seller checkout coming soon — please buy from one seller at a time.'` (statt BulkCheckoutSheet) umgestellt
- [x] Frontend: Wallet-FAB im Market-Screen entfernt (war Customer-Balance-Anzeige; nach Wallet-Removal nicht mehr aussagekraeftig). Earnings-View-Konzept entscheidet Phase 6/7 mit Stripe-Connect-Integration.
- [x] **`cancelPendingOrder` CF (neu)** — Frontend ruft sie wenn User PaymentSheet abbricht (oder bei anderen Errors); cancelt Stripe-PI, flippt Order auf cancelled, gibt Listing-Reservation frei. Defensive Doppel-Sicherung: Webhook-Handler `payment_intent.canceled` macht parallel dasselbe (fuer App-Crash / Auto-PI-Expiry).
- [x] Backend `transfer.paid` Dead-Code-Handler entfernt (Event existiert in Stripe nicht).
- [x] **Shipping-Rate-Sync (Phase-2-Fund)** — Backend `SHIPPING_RATES.DE` an Frontend angeglichen (Letter 1.25, Tracked 3.95, Insured 7.19). Drift wurde im Stripe-PaymentSheet-Test sichtbar (Frontend zeigte €17,04, Backend chargte €16,89). Tech-Debt: Tabellen sind getrennt — siehe „Shipping-Rate-Tabellen drift" weiter unten.
- [x] **UI-Bug Fix:** Versandmethoden-Pill `cost`-Text war bei selected gruen-auf-gruen (unsichtbar) → auf dunklen Text gefixt.
- [x] **End-to-End validiert** mit 3 Real-App-Tests:
      - **Cancel-Flow** (Fury Rune €5, NEU-Tier): User-Cancel im PaymentSheet → `cancelPendingOrder` CF → Listing in <1s wieder `active`, Order `cancelled` mit `cancelReason: user_dismissed_payment_sheet`, Stripe-PI `canceled`.
      - **Success-Flow Tier 3** (Darius Trifarian €100, TRUSTED): PaymentSheet → 3DS → `amount_capturable_updated` Webhook → Order `paid`. Math 100% korrekt: cartSubtotal 10000, shipping 395 (Tracked, Cardmarket-Regel >€25 forced), serviceFee 129 (Tier 3 Staffel), commission 600 (6%), totalCharge 10524, sellerPayout 9795, applicationFee 729, effectiveDelayDays 7 (€100-Cap aktiv weil Total > €100,00).
      - **Decline-Flow** (Jinx Demolitionist €250, POWER, Test-Karte 4000-0000-0000-0002): Stripe declined → User schloss PaymentSheet → `cancelPendingOrder` CF → Listing wieder `active`. Defensive `payment_intent.payment_failed` Webhook-Pfad nicht direkt getriggert (cancelPendingOrder hat ihn ueberholt — funktional korrekter Outcome).
      - Auch validiert: Brynhir Thundersong €15 (NEU-Tier 2, 5,5%) Math 100% korrekt (cartSubtotal 1500, shipping 125, serviceFee 79, commission 83, totalCharge 1704, sellerPayout 1542, applicationFee 162, effectiveDelayDays 7).
- [x] Stripe Webhook-Subscriptions erweitert: `payment_intent.amount_capturable_updated` (kritisch), `payment_intent.canceled` (defensiv).
- [x] `getWalletBalance` bleibt als read-only Earnings-Quelle (zeigt Legacy-Wallet-Balance bis Phase 6 sie auf 0 raeumt)
- [x] Wallet-Helper (`ensureStripeCustomer`, `getStripeCustomerId`, `updateBalanceCache`, `logTransaction`, `getTrustLevel`) bleiben — von confirmDelivery / cancelOrder / dispute-handler genutzt; Phase 6 raeumt sie auf
- [x] 37 Unit-Tests gruen, `flutter analyze` clean auf alle geaenderten Files

### Phase 3 — Frontend UI-Polish (Single-Seller) ✅ ABGESCHLOSSEN (2026-04-28)
- [x] **Neue Datei** `lib/data/payment_fees.dart` — Frontend-Single-Source-of-Truth fuer Service-Staffel + Provisions-Staffel + Multi-Seller-Aufschlag. Spiegelt 1:1 das Backend `calculateOrderFees`. Bisher hatte CheckoutSheet die Staffel inline; jetzt importieren cart_screen, sell_sheet, checkout_sheet alle dieselbe Logik.
- [x] **Cart-Screen Service-Gebuehr-Zeile mit Tooltip** — `_buildGrandTotal` zeigt jetzt vollstaendiges Breakdown (Subtotal + Shipping + Service Fee + Total). Service-Fee-Zeile hat info-Icon → tap → `RiftrToast.info` mit Erklaerung "Service fee: €0.49–€1.99 by order size. Covers payment processing, mediation and platform costs." Multi-Seller-Cart bekommt `+0.30 €` Aufschlag-Vorschau plus Warning "Multi-seller checkout coming soon".
- [x] **Bug-Fix: OrderPriceSummary Verkaeufer-View** — zeigte vorher `subtotal + shipping = Total` ohne Provision abzuziehen (€16,25 statt korrekt €15,42 fuer Brynhir €15). Jetzt: "Sale −Riftr commission +Shipping = You'll receive" mit `order.sellerPayout` als autoritativem Wert. Status-aware Wording: "You'll receive" (paid/shipped) → "Received" (delivered/autoCompleted).
- [x] **Sell-Sheet** — Live-Provisions-Vorschau wurde gebaut, dann **bewusst zurueckgenommen**. Anchoring-Effekt bei kleinen Preisen ("du bekommst €0,95 von €1,00") schreckt Verkaeufer ab oder treibt Listing-Preise hoch. Cardmarket-Pattern: keine Vorschau im Listing-Flow, Provision-Disclosure laeuft ueber FAQ/Hilfe. Kann spaeter via separate FAQ-Page (Phase 7+) eingebaut werden — kein In-Field-Snipe.
- [x] **CheckoutSheet** — inline `_serviceFee` Staffel raus, Import auf neue `payment_fees.dart`. DRY mit cart_screen + sell_sheet.

### Phase 4 + 5 — Multi-Seller-Path + Smart-Cart-Erweiterung ✅ ABGESCHLOSSEN (2026-04-28)
- [x] **CF `setupCardForCart`** (NEU) — SetupIntent mit `usage: off_session` + 3DS-challenge upfront. Frontend confirmed via PaymentSheet, Buyer-Karte landet als reusable PaymentMethod auf Stripe-Customer.
- [x] **CF `processMultiSellerCart`** (NEU) — sequenzieller PI-Loop ueber alle Seller-Groups. Per Seller: PI mit `off_session: true, confirm: true, capture_method: "manual"`, `transfer_data.destination`, `application_fee_amount` (Service-Fee NUR auf chargeIndex 0). Auto-rollback bei Teilfehler via `paymentIntents.cancel(piId)` (= Auth-Release, kein Geld floss, da manual-capture). Listing-Reservierungen werden korrekt mit-zurueckgerollt.
- [x] **`BulkCheckoutSheet` rebuild** — Per-Seller-Summary-Cards, Address-Form, Grand-Total mit Service-Fee-Breakdown, Multi-Seller-Info-Banner ("if any charge fails, all are auto-rolled back — your card isn't charged"). Pay-Button zeigt "Processing N orders…" wahrend des sequentiellen Loops.
- [x] **`cart_screen.dart` Multi-Seller-Branch** — Toast „coming soon" raus, push auf BulkCheckoutSheet wieder rein. Auf Erfolg: Cart geleert + Toast „All N orders placed!".
- [x] **Cost-Function update** in `MissingCardsOptimizer.totalCost` — Service-Gebuehr-Staffel + Multi-Seller-Aufschlag (0.30€ × (N-1)) als Teil der Cost-Function. Optimizer sieht jetzt ECHT den Multi-Seller-Tradeoff: ein 4ter Seller fuegt nicht nur Versand-Kosten, sondern auch +0.30€ Aufschlag hinzu → Optimizer minimiert Seller-Anzahl staerker.
- [x] **`BuyPlan.grandTotal`** rechnet jetzt Service-Fee mit ein. **`baselineCost`** (= "buying-each-card-separately") rechnet Per-Seller-Service-Gebuehr ein (jede Sellergroup waere ihr eigener Single-Seller-Cart mit eigener Gebuehr) — Smart-Cart-Savings-Banner zeigt damit ehrliche Differenz inkl. eingesparter Service-Fees.
- [x] **3DS handled upfront** in SetupIntent (`request_three_d_secure: 'challenge'`) — sequenzielle off_session PIs muessen NICHT erneut authentifizieren. Bei seltenem `authentication_required` Edge-Case: Backend rollt zurueck mit klarer Fehlermeldung "Card requires re-authentication. Please retry checkout.". 3DS-Re-Confirm-UX im Frontend ist Phase 7 wenn Volumen relevant wird.

### Phase 4 — deferred
- [ ] Per-Seller Shipping-Method-Picker im BulkCheckoutSheet — aktuell hard-coded `tracked` (Backend forciert per-Seller `insured` wenn ein Listing der Group `insuredOnly: true` hat). UX-Polish, kein Korrektheit-Issue.
- [ ] Per-Seller-Failure-State im UI — bei Backend-Fehler waehrend Loop wuerde der Frontend gerne sagen "Charge X von N fehlgeschlagen, andere wurden zurueckgerollt". Aktuell zeigt nur generische Fehlermeldung. Hilfreiche Detail-Anzeige in Phase 7+.

### Phase 6 + 6.5 — Refund / Chargeback / Dispute / Admin-Mediation ✅ ABGESCHLOSSEN (2026-04-28)
- [x] **Kritischer Production-Bug gefixt** — `respondToRefund` und `cancelOrder` riefen `stripe.refunds.create` ohne `reverse_transfer: true`. Konsequenz pre-Phase-6: Plattform absorbierte den vollen Refund-Betrag (€15-€250 je Order, weil Geld via `transfer_data` schon auf Verkaeufer-Connect-Account war). Jetzt: alle Refunds nutzen `reverse_transfer: true` + policy-aware `refund_application_fee`.
- [x] **Differenzierte Refund-Policy-Engine** (`resolveRefundPolicy(order, reasonCode, percent)` in `functions/index.js`) — Voll-Refund inkl. Service-Gebuehr bei klar-Verkaeufer-Schuld (untracked-not-arrived, tracked-no-tracking, wrong_card, damaged-not-insured); Teil-Refund OHNE Service-Gebuehr bei Streitfaellen; Insurance-Reject mit Carrier-Hint.
- [x] **`evaluateRefundEligibility`** Helper — Insurance-not_arrived wird in `openDispute` direkt mit Hinweis "claim with carrier" rejected, nicht in den Riftr-Mediation-Flow gelassen.
- [x] **`cancelOrder`** Connect-native: Pre-ship Cancel = `paymentIntents.cancel(piId)` (gibt Auth wieder frei, kein Geld floss bei capture_method:manual).
- [x] **`respondToRefund`** Connect-native: bei Buyer-Accept Stripe-Refund mit reverse_transfer + Policy-Engine.
- [x] **`acceptCancelOrder`** Connect-native: gleiche Logik wie cancelOrder.
- [x] **`openDispute`** erweitert: nimmt `disputeReasonCode` (mapped vom Display-Label) ins Order-Doc auf, fuer die Policy-Engine spaeter beim Refund.
- [x] **Chargeback-Webhook erweitert** (`charge.dispute.created`):
      - Push an Verkaeufer der Chargeback-Order ("Tracking-Beleg einreichen")
      - Bug-Fix: `orderId` war `undefined` im "Order paused" Push-Loop, jetzt `orderDoc.id`
      - Defensive try/catch um wallet/balance-freeze (legacy doc kann fehlen)
- [x] **Legacy-Cleanup**: 114 `paymentMethod: "balance"` Test-Orders aus Firestore geloescht, Balance-Branch komplett aus Backend-Code entfernt. Bei eventuellen verbleibenden balance-Orders schlaegt der CF-Aufruf jetzt mit klarer "Legacy balance — contact support" Fehlermeldung fehl.
- [x] **Phase 6.5 Admin-Mediation-UI** mitgezogen:
      - CF `adminListDisputes()` — listet alle `status: disputed` Orders mit allen Mediation-relevanten Feldern (reason, shipping-method, tracking, items, parties, proposals)
      - CF `adminResolveDispute(orderId, refundPercent, reason, applyServiceFeePolicy)` — Tie-Breaker, 0% (seller-win) oder X% (Stripe-Refund + Policy-Engine), Audit-Log unter `orders/{id}/disputeAudit/{timestamp}`
      - Frontend `lib/screens/admin_disputes_screen.dart` — Dispute-Liste mit Quick-Action-Buttons (0/25/50/75/100%) + Reason-Prompt
      - Entry-Point in `social_screen.dart` Profile-Card — sichtbar nur fuer User mit `admin: true` Custom-Claim (async via `getIdTokenResult().claims`)
- [x] **`isCommercialSeller: false` Flag** im `seller_profile.dart` Schema — defensives future-proofing fuer 14-Tage-Widerrufsrecht (B2C). Aktuell nicht aktiviert; Phase 7+ verdrahtet das gegen die Refund-Engine.
- [x] **CLAUDE.md** Refund-Policy-Section mit der differenzierten Logik aktualisiert.

### Phase 6 — deferred to Phase 7+
- [ ] Refund-Flow Multi-Seller (rollback nur betroffene Charges) — abhaengig von Phase 4 (Multi-Seller-Path mit SetupIntent)
- [ ] Wallet-Helper (`ensureStripeCustomer`, `getStripeCustomerId`, `updateBalanceCache`, `logTransaction`) deprecaten — werden noch von chargeback-Webhook (legacy-Defensiv) und `getWalletBalance` genutzt; Cleanup wenn Refund/Dispute komplett auf Connect umgestellt + Beta-Wallet-Reste auf 0
- [ ] Auto-Refund-Cron (14 Tage post-paid ohne Versand → Auto-Refund-eligibility) — UX-Aufwertung, nicht-blocker
- [ ] Frontend `openDispute`-Flow: bei Insurance-Order kein Refund-Button, sondern Carrier-Hint-Banner — Backend rejected schon, aber Frontend zeigt's nicht ueber explizit. Phase 7 UI-Polish.

### Phase 7 — UI-Texte / Wording ✅ ABGESCHLOSSEN (2026-04-28)
- [x] **Push „Bestellung bezahlt — bitte versenden"** — schon in Phase 2 gefixt (`amount_capturable_updated` Webhook → "New order!" mit Cardnames + Total + "Ship within 7 days").
- [x] **Tier-aware Auszahlungs-Datum** — `OrderPriceSummary` (Verkaeufer-View) zeigt jetzt unter „You'll receive €X.XX" eine kleine Sub-Zeile mit konkretem Datum:
       - status `paid` (vor markShipped): „Payout: X days after you mark as shipped"
       - status `shipped`: „Payout on DD MMM YYYY (X days after shipping)" — Datum = `shippedAt + delayDays`
       - status `delivered`/`auto_completed`: „Released — arriving in your bank account in 2–7 business days"
       - effectiveDelayDays kommt aus dem Order-Doc (Phase-1-Schema), Fallback 7 Tage fuer Legacy-Orders.
- [x] **First-Time-Seller-Modal** — `lib/widgets/market/first_seller_modal.dart` (NEU). Triggert in `order_detail_screen.dart::initState` (post-frame) wenn:
       - User ist Verkaeufer dieses Orders
       - Order ist paid/shipped/delivered/auto_completed
       - SellerService.profile.totalSales == 0 (= echter Erst-Verkauf)
       - SharedPreferences-Flag `first_seller_modal_shown_$uid` nicht gesetzt
       Inhalt: 3-Step-Workflow + Tier-Status-Banner mit Auszahlungs-Frist + CTA „Verstanden". Wording aus CLAUDE.md → „First-Time-Seller Modal" Spec uebernommen.
- [x] **`Riftr-Guthaben`-Wording** — Wallet-Screen wurde in Phase 2 zu „EARNINGS" umbenannt; alle Wallet-Buy-Pfade sind weg. Keine weiteren Aenderungen noetig.
- [x] **Tooltip Service-Gebuehr** — schon in Phase 3 gefixt (Cart-Screen info-icon → `RiftrToast.info`).
- [x] **`confirmDelivery` Push erweitert** — alte Message war „Delivery confirmed! — €X.XX released."; neue Message: „${cardNames} — Käufer hat Erhalt bestätigt. Auszahlung in X Tagen (€Y.YY)." Tier-aware ueber `effectiveDelayDays` aus dem Order-Doc.

### Phase 8 — End-to-End Sandbox-Tests ✅ ABGESCHLOSSEN (2026-04-28)
Test-Suite: `functions/test-scenarios/phase8_e2e_tests.js` — 46/46 Checks gruen.
- [x] **Test 1: Single-Seller €5** (Tier 1, 5%) — Math + Stripe-PI-Struktur validiert
- [x] **Test 2: Single-Seller €100** (Tier 3, 6%, €100-Cap-Boundary) — €100-Cap kickt korrekt (Trusted 3d → 7d)
- [x] **Test 3: Multi-Seller 3 × €10** — sellerCount=3, Service-Fee +€0.30 × 2 (= 109ct), Charge#0 traegt Service-Fee, Charge#1+#2 nur Provision
- [x] **Test 4: Multi-Seller-Teilfehler** — simuliert mit invalid `acct_DOES_NOT_EXIST` als 3. Destination, Stripe rejected → Rollback der ersten 2 via `paymentIntents.cancel` validiert
- [x] **Test 5: Refund Voll Single-Seller** — REAL Stripe-charge + capture + full refund mit `reverse_transfer:true, refund_application_fee:true`. Connect-native end-to-end validiert.
- [x] **Test 6: Refund Partial 50%** — REAL Stripe-charge + capture + partial refund mit `reverse_transfer:true, refund_application_fee:false, amount:852ct` (= 50% × 1704ct, gecappt auf totalCents−serviceFeeCents). Service-Fee bleibt bei Plattform.
- [x] **Test 7: Chargeback simuliert** — Stripe API erlaubt keine Chargeback-Trigger im Test-Mode. Webhook-Code-Pfad ist seit Phase 6 deployed + via Code-Inspection verifiziert. Manuelle Test-Anleitung im Test-Skript dokumentiert.
- [x] **Math gegen Stripe-Test-Mode-Fees abgeglichen** — fuer alle Szenarien: `application_fee_amount`, `transfer_data.destination`, `amount`, `capture_method` matchen die `calculateOrderFees`/`resolveRefundPolicy`-Outputs

### Parallel-Track (Anwalt / Steuerberater)
- [ ] **UG-Gruendung** vor Live-Schaltung (persoenliche Haftung sonst)
- [ ] **AGB**: Service-Gebuehr-Klausel (Vorlage in CLAUDE.md), Provision, Auszahlungs-Tier-System, Mediation
- [ ] **Datenschutzerklaerung** mit Stripe-Datenfluss
- [ ] **Impressum**
- [ ] **MwSt-Klaerung**: Service-Gebuehr und Provision gross/netto, B2B/B2C
- [ ] **DAC7-Reporting**: Felder im Verkaeufer-Profil (TIN, Geburtsdatum, Adresse, Steuer-ID, IBAN), jaehrliches Reporting an BZSt
- [ ] **Berufshaftpflicht-Versicherung**
- [ ] **FAQ-Seite** in App + Web mit Vorlage-Antworten aus CLAUDE.md

### Anti-Patterns die NIE eingebaut werden duerfen (Quelle: CLAUDE.md)
- ❌ Eigenes Wallet mit `customers.balance` (BaFin-pflichtig)
- ❌ `requestPayout` als manueller Trigger (Plattform-Halten)
- ❌ "Kaeuferschutz"-Wording in UI / Marketing / AGB
- ❌ `delay_days: 0` (Stripe-Reserve braucht Buffer-Zeit)
- ❌ Service-Gebuehr-Refund per Default
- ❌ Single-PI mit `transfer_group` fuer Multi-Seller
- ❌ Per-Order Payout-Override durch `confirmDelivery` (Plattform-Entscheidung am Geld → BaFin-Issue, siehe CLAUDE.md)

---

## KRITISCH (Marktplatz-Kernfunktionalität)

### Chart / Portfolio
1. ⚠️ **Portfolio Chart plottet v statt p** — Chart muss `p` (Performance/Kursgewinne) plotten, NICHT `v` (totalValue). Karten hinzufügen darf Linie nicht bewegen. `performanceHistory` existiert, aber Fallback-Logik (p → v für Legacy-Snapshots) fehlt noch.

### Wallet / Checkout (OBSOLET nach Payment-Architektur-Migration)
2. ✅ **Wallet-Code entfernt** — Auflade-Custom-Betrag, Stripe-Sheet-Design-Bug etc. mit Phase 2 weggefallen. Siehe Payment-Track oben.

### Bestellungen / Orders
4. ❓ **Sendungsnummer nachträglich eintragbar** — Tracking-Felder existieren, muss getestet werden ob nachträgliches Ändern funktioniert.
5. ❌ **Order-Detail Screen überarbeiten** — Aktuell zu klein/unübersichtlich. Adressen groß sichtbar, Karten erkennbar, Kartenpreis + Versand separat + Gesamt.
6. ✅ **Sprache und Herkunftsland bei Angeboten** — Felder im Code vorhanden.

### Marktplatz-Filter
7. ✅ **Richtig guter Marktplatz-Filter** — Audit 2026-04-28 bestaetigt vollstaendig: Rarity, Set, Domain (multi-select), Preis-Range, Condition, Sprache, Country, Foil, Min-Rating implementiert. Sort nach Preis/Rarity/Neueste vorhanden.
8. ✅ **Angebote nach Preis sortiert** — Sort-Logik implementiert.

### Intelligenter Deck-Kauf
9. ❌ **"Ganzes Deck kaufen" Feature** — Smart-Matching: fehlende Karten bündeln bei wenig Verkäufern + günstigste Preise. Kein Code vorhanden.

---

## HOCH (UX & Features)

### Push Notifications
10. ⚠️ **Deep Linking bei Push** — MVP-only: App öffnet sich, aber kein Deep-Link zu spezifischem Screen (Order-Detail, Karten-Detail etc.). Kommentar im Code: "just open the app".
11. ❌ **Push bei Empfangsbestätigung** — Kein Code vorhanden. Käufer: "Karte in deiner Collection!" / Verkäufer: "Lieferung bestätigt, Erlös auf Guthaben."

### Collection
12. ❌ **Collection-Suche fixen** — Einige Namen (z.B. Irelia) nicht suchbar in Collection, obwohl im Cards Tab gefunden.
13. ❌ **Suchleisten-Markierung fixiert beim Scrollen** — Markierung läuft beim Scrollen mit statt fixed.
14. ⚠️ **Collection nach Sets mit Fortschritt/Achievements** — `setCompletion` in Demo-Service vorhanden, aber vollständige UI (Level-System, Progress-Anzeige) unklar.
15. ✅ **Promos automatisch als Foil erkennen** — Implementiert in `firestore_collection_service.dart`.
16. ❌ **Portfolio-Filter nach Mindestwert** — Karten unter €0,50/€1,00 ausblenden. Kein Code vorhanden.
17. ✅ **Most/Least Value Anzeige** — Gainers/Losers in Stats-Screen implementiert.

### Decks
18. ❌ **Deck-Validierung: Chosen Champion prüfen** — Deck ohne Chosen Champion darf nicht als valide gelten. Kein Code.
19. ❌ **Legend vs Champion Export-Bug** — Legende wird als "Champion" exportiert statt "Legend". Kein Fix.
20. ⚠️ **Überarbeitung öffentliche Decks / Meta Decks** — Code existiert, Redesign nach Vorbild Piltover Archive offen.
21. ✅ **All-in-One Deck-Bild zum Sharen** — Implementiert in `meta_deck_service.dart`.
22. ❌ **Deck-Export Text-Vorlage** — Einheitliches Format (Legend/Champion/MainDeck/Battlefields/Runes/Sideboard). Kein Code.
23. ✅ **Legenden-Auswahl im Deckbuilder: DragToDismiss** — Implementiert mit custom ScrollPhysics.

### Market Screens
24. ❌ **Karten im Market größer anzeigen** — Rahmen beibehalten. Muss im UI angepasst werden.
25. ❓ **Zeitraum-Badges im Chart größer** — `time_range_selector.dart` mit RiftrPill existiert, muss geprüft werden ob groß genug.
26. ✅ **Foil und Non-Foil Preis in einem Graph** — Beide Varianten vorhanden (`foilPrice`, `nonFoilPrice`, `nonFoilHistory`).
27. ❓ **Card Detail View: Alle Daten + kaufbar?** — Offene Entscheidung: Alles in einem vs. Button zum Market.
28. ❌ **Kauf-Button sticky unten** — Button scrollt mit statt fixed am unteren Rand.
29. ❌ **Pending Tab im Market** — Zusätzlich zu Purchases/Sales. Kein Code.

### Scanner
30. ❌ **Karten-Scanner implementieren** — Live-Scan, OCR auf Collector Number, Promo/Signature-Erkennung, Batch-Mode. Kein Code vorhanden.

---

## MITTEL (Polish & Social)

### Social
31. ❌ **Freunde adden** — Offene Entscheidung: Username, E-Mail oder Nickname?
32. ❌ **Wunschliste öffentlich einsehbar** — Trade-Matching, Privacy-Toggle. Kein Code.
33. ❌ **Vorauswählbare Profilbilder** — Legend-Artworks als Avatar. Kein Code.
34. ❌ **Dem Handelspartner schreiben** — Minimales Messaging nur im Kontext einer Bestellung.

### Battle / Tracker
35. ❌ **QR-Code beim Battle** — Gegner scannt QR für Stats/Deck-Auswahl/Banner.
36. ❌ **Win/Loss/Draw Anzeige überarbeiten** — Schöneres Design.
37. ❌ **+ und − Buttons größer im Battle Screen** — Win/Loss Text auch größer.

### Events & Content
38. ❓ **YouTube Videos einbetten** — Rechtliche Klärung nötig.
39. ❓ **News von anderen Seiten zeigen** — Verlinkung ja, Kopieren nein.
40. ❓ **Stores in der Nähe + Events anzeigen** — UVS kontaktieren.
41. ❌ **Errata-Liste für Karten** — Liste/Badge für Karten mit Regeländerungen.

### Onboarding
42. ❌ **Startbildschirm beim ersten Installieren** — 3-4 Screens: Collect, Worth, Buy/Sell, Track.
43. ❌ **Welcome Screen mit League-Flair** — "Welcome, Summoner" etc.

### Bid System
44. ❌ **Bid & Ask System** — Später, erst nach stabilem Marktplatz.

---

## NIEDRIG (UI Bugs & Kosmetik)

### UI Bugs
45. ✅ **DragToDismiss zieht Bild auseinander** — Gefixt mit custom ScrollPhysics + scroll-lock.
46. ❌ **Bewertungs-Sterne Flackern** — Kommentarfeld flackert kurz auf beim Klick.
47. ❌ **Pfeil in Collection überlagert Fortschrittsbalken** — Überlappung beim Ausklappen.
48. ❌ **NavBar-Einklappen komisch** — Animation/Verhalten überarbeiten.
49. ⚠️ **Keyboard-Bounce in New Deck Sheet** — Sheet stabil (High-Water-Mark), Tastatur-Bounce = iOS-Limitation, akzeptiert.

### Design-Anpassungen
50. ❌ **Logout-Button in unserem Design** — Aktuell Standard-Style.
51. ❌ **Save/Discard Menü in unserem Style** — Eigenes Design statt System-Default.
52. ⚠️ **Haptisches Feedback** — Nur im Tracker, nicht überall (orangener Button, Menüleiste).
53. ❌ **Stats-Screen: Runde Elemente kleiner** — Filter im Dropdown-Format.

---

## Aus BACKLOG (zusätzliche Items)

54. ❌ **Preisalarm-Feature** — Karte über/unter Schwellwert → Badge im Cards Tab.
55. ❌ **Portfolio-Wert Badge** — Signifikante Änderung → Badge im Stats Tab.
56. ❌ **Kommentar auf eigenes Deck → Badge** — Social Tab Badge.
57. ✅ **Payout Phase 5 Nachtest** — Obsolet, durch Phase-1–8-Migration ersetzt. Connect-native Payouts via `delay_days` + Tier-System; manuelle Payout-Flow gibt es per Architektur-Entscheidung nicht mehr.
58. ❌ **Seller Cancellation Request** — Anfrage statt sofort stornieren, Buyer Accept/Reject, Auto-Accept 48h, Penalty-System.
59. ❌ **Dispute Photo Uploads** — Firebase Storage für Foto-Beweis im Dispute.

### Shipping-Rate-Tabellen drift (Phase-2-Fund 2026-04-28)

⚠️ **Backend `functions/index.js` SHIPPING_RATES und Frontend `lib/data/shipping_rates.dart` ShippingRates._routes sind getrennte Source-of-Truth-Tabellen** — drift wurde in Phase 2 schmerzhaft sichtbar (DE→DE Letter: Frontend 1.25, Backend 1.10, User-vs-Charge-Diskrepanz im Stripe-Sheet).

**Quickfix Phase 2:** Backend DE-Rates an Frontend angeglichen (Letter 1.25, Tracked 3.95, Insured 7.19). Andere Country-Rates noch nicht 1:1 verifiziert — bei jeder Aenderung in shipping_rates.dart muss man manuell auch index.js nachziehen.

**Architektur-Fehler:**
- Backend nutzt nur First-Tier (Standardbrief 1.25, max 4 Karten), Frontend hat Tier-Ladder mit Bundle-Size-Auswahl (Kompaktbrief 1.40 bis 17 Karten, Grossbrief 2.30 bis 40 Karten).
- Bei Listing-Orders mit > 4 Karten unterschaetzt Backend den Versand → Verkaeufer-Verlust.

**Cleanup-Ansatz (Phase 7+):**
- Shipping-Rates zu shared JSON-Asset extrahieren — z.B. `shared-config/shipping_rates.json` das beide Seiten lesen.
- Tier-Ladder-Logik (Bundle-Size → richtigen Tier waehlen) auch ins Backend portieren.
- Alternativ: Frontend errechnet Shipping + sendet als Trusted-Param mit (Backend validiert nur via Min/Max-Plausibility).

### Design-System-Tech-Debt (aus Smart-Cart-Audit)

60. ⚠️ **`AppTextStyles.bodySmall` ist 13sp, V2-Spec sagt 12sp** — app-weiter Token-Verstoß. Fix: `fontSize: 13 → 12` in `lib/theme/app_theme.dart`. Braucht **visuelle Regression-Prüfung durch alle Screens** (Order-Detail, Collection, Stats, Checkout, Tracker) bevor gemerged wird, weil alle Screens betroffen sind. Nicht Teil von Smart Cart.
61. ⚠️ **Heavy-Weight Body-Tokens fehlen in V2** — OrderTile, CardPriceTile, SmartCart und andere nutzen inline `AppTextStyles.body.copyWith(fontWeight: FontWeight.w800/w900)` für Kartennamen und Preise. V2 kennt nur `bodyBold` (w600). Zwei Varianten:
    - V2 um `bodyHeavy` (body+w800) und `bodyBlack` (body+w900) erweitern, dann alle Call-Sites auf Tokens migrieren
    - Oder inline-Pattern offiziell im Design-Doc dokumentieren
    Eigener Cleanup-PR, nicht Smart Cart.

### CardImage-Widget-Enhancements (aus Smart-Cart-Audit)

62. ✅ **BANNED-Ribbon-Overlay global in `CardImage`** — CardImage unterstützte bereits `card:` Param + CardRibbon-Overlay; fehlte nur an den Call-Sites. Jetzt propagiert: OrderTile, CardPriceTile, OrderItemTile, cart_screen (item-row + more-from-seller), scan_results_screen (3×), smart_cart_review_sheet. Textuelles BANNED-Badge in Smart-Cart-Meta-Row entfernt (Ribbon macht's jetzt). Fertig 2026-04-23.

65. ✅ **Cart-Image-Bug Fix (2026-04-28)** — Test-Listings hatten kein `imageUrl` → leere Card-Slots im Cart. Drei Ebenen gefixt: (a) 4 bestehende Test-Listings via Firestore-Update mit `media.image_url` aus cards.json gepatcht; (b) `seed_test_listings.js` lookt jetzt `imageUrl` aus cards.json + warnt bei Misses; (c) `CardImage` widget defensiv gemacht — wenn `imageUrl` null/empty UND `card:` Param gesetzt ist, fallback auf `card.imageUrl` (= cards.json `media.image_url`). Schuetzt vor zukuenftigen Daten-Bugs.

### Toast-Color Design-System-Compliance

66. ✅ **RiftrToast `info` + `cart` auf `amber500` gefixt (2026-04-28)** — Beide Variants nutzten `amber400` (#DDB855 — laut Design-Doc „Lighter/hover, focused borders, text links"). Korrekt ist `amber500` (#D3A43F — „DER Riftr-Akzent"). `success`/`error`/`sale` waren bereits korrekt (semantische Tokens). Audit der 93 Toast-Call-Sites: `info` (24×) deckt neutrale Feedback-Cases ab (clipboard, „No listings available", Order-Status-Updates) — keine semantische Fehlbenutzung.

69. ✅ **Checkout-Sheets Schriftgroessen design-konform (2026-04-28)** — `checkout_sheet.dart` (single-seller) und `bulk_checkout_sheet.dart` (multi-seller) durchgegangen. Item-Reihen, Seller-Namen, Pre-Release-Banner, Multi-Seller-Info-Banner, Shipping-Method-Pills, Error-Texte und Price-Breakdown-Rows alle von `small`/`tiny` (11sp — laut Design-Doc nur fuer Nav-Labels/inline-stats) auf `bodySmall` (13sp — primary content minimum) hochgezogen. Total-Zeile in beiden Sheets auf `titleMedium` 16sp w900 (matching cart_screen Total). Quantity-Stepper-Number ebenfalls auf `titleMedium`. „Ships from"-Sub-Line auf `caption` (12sp). FormSectionLabel und Sheet-Titel unveraendert (waren schon konform).

81. ✅ **Smart-Cart Stress-Test-Suite (2026-04-29)** — Reddit-User-Vorschlag umgesetzt. `test/smart_cart_stress_helpers.dart` (Synthetic-Data-Generators: deterministic seeded math.Random, log-normale Preise pro Rarität, EU-Cardmarket-Country-Mix) + `test/smart_cart_stress_test.dart` (9 Szenarien, alle in einem Run mit Console-Pretty-Print + Markdown-Report + JSON-Baseline für Regression-Detection). Szenarien: small_abundant / medium_fragmented / large_fragmented / concentrated / playset_tight_stock / rare_heavy / international / scale_stress / foil_only_filter. Hard-Fails: ALLOCATION-BUG (eligible-stock>0 aber 0 alloziert), PERF (>5s Runtime), EMPTY-PLAN. Soft-Warns: TRACKING-BUG (Optimizer untertrackt unavailable), Pareto-Drift, Savings-Drift gegen Baseline. Output `test/smart_cart_stress_report.md` + `test/smart_cart_stress_baseline.json` (committed fuer Diff). Re-run zur Verifikation: deterministic, keine Drift-Warnings. Alle 10 Tests grün, ein TRACKING-BUG entdeckt (#82).

90. ✅ **Security-Audit Findings (2026-04-29)** — Reddit-User-Skepsis triggerte Audit der Firestore Rules. **Zwei echte Findings, beide gefixt + deployed:**
    - **`publicDecks` update zu loose**: Rule war `allow update: if isAuth()`, Kommentar versprach „Author can update own deck, others can increment viewCount/likeCount/copyTimestamps". Tatsaechlich konnte jeder authentifizierte User mit Firebase-SDK direkt fremder Decks `name`, `mainDeck`, `sideboard`, `authorId` etc. ueberschreiben. Fix: `affectedKeys().hasOnly(['viewCount', 'copyTimestamps'])` fuer Non-Author analog zum bereits-korrekten meta_decks-Pattern. Author behaelt vollen Zugriff auf eigene Decks. likeCount geht eh ueber CF (`toggleDeckLike`).
    - **`users/{uid}/data/{docId}` Read zu loose**: alle Docs (`profile`, `sellerProfile`, `cost_basis`, `fcmTokens`) waren mit `allow read: if isAuth()` von jedem auth User lesbar. Gefixt mit doc-name-allowlist: `cost_basis` (FIFO-Kauf-Historie!) + `fcmTokens` (Push-Targets) jetzt owner-only. **`profile` + `sellerProfile` bleiben temporaer public-readable** weil Social-Tab + Listings-Tile aktiv fremde Display-Daten lesen — strikteres Lock-Down wuerde UI brechen. Siehe #91 fuer den richtigen Fix.

92. ✅ **Komplette Security-Hardening: PII-Migration + field-allowlist Writes (2026-04-29)** — Nach Reddit-User-Skepsis kompletten Audit durchgezogen. Drei massive Findings entdeckt + alle gefixt:
    - **PII-Leak via cross-user reads**: jeder authentifizierte User konnte fremde `users/{uid}/data/profile` (street/zip/realizedGains) und `data/sellerProfile` (email/address/totalRevenue/strikes/stripeAccountId) lesen. Lösung: `playerProfiles`-Mirror (existing) erweitert um Public-Stats (rating/reviewCount/totalSales/memberSince), App-Code-Reads (`ProfileService.fetchProfiles` + `social_screen::_loadAuthorData`) auf Mirror umgestellt, Rules auf owner-only-read fuer profile + sellerProfile gehärtet. CF-Helper `syncPlayerProfile(uid)` haelt den Mirror nach jedem `submitReview`/`confirmDelivery` automatisch synchron. Migration-CF (`migratePlayerProfiles`) erweitert + getriggered → 9 existing users sauber migriert (sanity-check verifiziert: kein email/address/stripeAccountId im Mirror).
    - **Self-rating-fraud via owner-write**: `allow write: if isOwner(uid)` ohne field-allowlist. User konnte eigenen `rating`/`reviewCount`/`strikes`/`suspended`/`stripeAccountId` beliebig setzen. Konsequenz unfixed: 5-Sterne-Self-Rating, Strike-Reset, stripeAccountId auf fremden acct_xxx (Geld geht zu falschem Connect-Account!). Lösung: harte field-allowlist via `affectedKeys().hasOnly([...])` fuer profile (displayName/bio/avatar/country/street/city/zip/show*/nameChangesLeft/updatedAt) und sellerProfile (displayName/email/country/address/isCommercialSeller/updatedAt). Alles andere (rating/reviewCount/strikes/suspended/stripeAccountId/totalSales/totalRevenue) bleibt CF-only via Admin-SDK.
    - **Catch-all-data-Doc-Issue**: anstatt eines permissiven `match /data/{docId}`-Defaults expliziter Rule pro Doc-Name. `cost_basis`, `fcmTokens`, `portfolio_history` jetzt owner-only. Unbekannte data-Docs erben Root-deny → secure-by-default.
    - **CF-Args-Audit**: alle 220 auth-checks ueberprueft, alle nutzen `request.auth.uid` (server-trusted), keine User-controlled User-IDs aus den Args. Resource-IDs (orderId, listingId) werden serverside gegen Owner geprüft.
    - Deploy: Rules + CFs (submitReview, confirmDelivery, migratePlayerProfiles) live. **Pre-Launch-Blocker geschlossen.**

137. ⚠️ **Powerseller-Cap (deferred 2026-04-29)** — Round 11 Recherche: Cardmarket limitiert Powersellers global auf EXAKT 100, mit yearly-review-process. Anti-Fraud durch Knappheit der highest-trust-accounts.
    - **Adoption-Frage:** unsere Power-Seller-Tier ist algorithmisch (200+ Verkaeufe, 4.95★) ohne Hard-Cap. Cardmarket-Pattern wuerde es zu manueller Selection machen.
    - **Defer-Begruendung:** operational + business decision, nicht Code-Defense. Pre-Public-Launch evaluieren wenn Power-Seller-Volume relevant wird.

136. ⚠️ **3-Monate Postal-Investigation Window (deferred 2026-04-29)** — Round 11 Cardmarket-Pattern: Bei Lost-Order zahlt Cardmarket Buyer sofort zurueck, Postal-Investigation laeuft bis 3 Monate parallel, Seller kann Compensation beantragen. Setzt eigenes Capital-Pool voraus (vor-finanzierter Refund).
    - **Defer-Begruendung:** Stripe Connect Direct Charges = wir haben kein Plattform-Capital-Pool (BaFin-Reason). Wuerde eigene Wallet-Architektur erfordern. Post-MVP-Feature wenn UG ein Backstop-Konto hat.

135. ⚠️ **IP-Tracking fuer Multi-Account-Detection (deferred 2026-04-29)** — Round 11 Cardmarket sammelt Name+Email+IP fuer Multi-Account-Cluster-Detection. Wir machen das nicht (DSGVO-careful).
    - **Adoption-Frage:** wuerde Strategie 6 (Account-Reset-Loop) deutlich abschwaechen.
    - **Defer-Begruendung:** Privacy-Policy + DSGVO-Datenverarbeitungsvertrag-Update noetig. Pre-Public-Launch + Anwalt-Track.
    - **Alternative:** Stripe macht IBAN-Cross-Reference-Detection bereits Stripe-Account-side.

134. ⚠️ **Loss Prevention Team (deferred 2026-04-29)** — Round 11 TCGplayer hat dedicated team von Menschen fuer Manual-Review fraudulenter Aktivitaeten.
    - **Adoption:** post-launch hire wenn Volume rechtfertigt. Aktuell sendAdminAlert + manueller Email-Check ausreichend fuer Beta-Volume.

133. ⚠️ **Photo-Listing-Policy fuer High-Value-Items (deferred 2026-04-29)** — Round 11 TCGplayer-Pattern: Photo verpflichtend fuer Cards > $X. Reduziert Bait-and-Switch (Strategie 4) drastisch — Buyer hat Foto-Beweis vor Versand.
    - **Defer-Begruendung:** UI-Feature mit Camera-Integration in Listing-Create-Flow + Image-Storage-Backend. Pre-Public-Launch.

132. ✅ **Mandatory Tracked-Shipping >€25 — Server-Side Hard-Enforcement (2026-04-29)** — Cardmarket-Pattern (>€25) + TCGplayer (>$20). Schuetzt vor Bait-and-Switch (Round 10 Strategie 4), Lost-Mail-Scam, Friendly-Fraud-Chargebacks.
    - **Was wir vorher hatten (Soft-Enforcement, Flutter-only):**
      - `lib/data/shipping_rates.dart::requiresTracking(bundleValue)` → true bei >€25
      - `quoteForBundle(forceTracked: true)` skippt letter-tiers
      - `checkout_sheet.dart` auto-picked tracked beim Cart-Add bei bundle >€25
      - `missing_cards_optimizer` respektiert >€25 Rule fuer Smart-Cart-Plans
    - **Was gefehlt hat:** Server-Side-Check. Hacker mit Frida/Burp koennte UI umgehen + direkten CF-Call mit `shippingMethod: "letter"` machen auch bei totalCents > 2500.
    - **Fix:** in createPaymentIntent (post-effectiveMethod-Compute) + processMultiSellerCart (per-Seller-Group): `if (effectiveMethod === "letter" && subtotal > 25) throw HttpsError("failed-precondition", ...)`.
    - **Insured-Override** (anyInsuredOnly) unangetastet — wenn listing insured-only flagged, shippingMethod wird ohnehin auf "insured" forced.
    - **Deployed.** Legit-User unbetroffen (UI picked schon richtig). API-Bypass-Versuche kriegen jetzt clean rejection.

131. ⚠️ **Multi-Source-Verification: Phone + Email + Stripe-IBAN (deferred 2026-04-29)** — Round 11 Recherche: Cardmarket sammelt fuer Fraud-Prevention Multi-Source-Daten. Wir haben Email + Stripe-Connect-Verified-ID — kein Phone.
    - **Adoption:** Phone-Verification beim Seller-Onboarding (zusaetzliche Hurde fuer Fraudster).
    - **Defer-Begruendung:** SMS-Cost + DSGVO-Verarbeitungsvertrag mit SMS-Provider. Pre-Public-Launch evaluieren.

130. ✅ **30-Day Dispute-Window after Delivery (Round 11 TCGplayer-Pattern, 2026-04-29)** — Cardmarket+TCGplayer beide haben extended Dispute-Windows nach Lieferung.
    - **TCGplayer Safeguard:** 30 Tage refund-window von estimated-delivery
    - **Riftr-Stand vor Round 11:** openDispute nur in `shipped`-Status. Nach confirmDelivery oder auto-release konnte Buyer NICHT mehr nachtraeglich disputen — z.B. wenn Karte 10 Tage spaeter als counterfeit erkennbar wird.
    - **Fix:**
      - `confirmDelivery` + `autoReleaseOrders` setzen `disputeWindowEndsAt = deliveredAt + 30d`
      - `openDispute` erlaubt jetzt Disputes auch in `delivered`/`auto_completed`-Status SOLANGE `now < disputeWindowEndsAt`
      - Klare Error-Message bei abgelaufenem Window
    - **Stripe-Side:** Refunds funktionieren bis 180 Tage nach Charge. `reverse_transfer: true` zieht Geld auch von ausgezahltem Connect-Account zurueck (negative-balance Stripe-managed).
    - **Deployed.**

138. ✅ **First-5-Sales Extra-Buyer-Protection-Window (Round 11 Cardmarket-Pattern, 2026-04-29)** — Cardmarket macht Trustee Service mandatory fuer first-5-sales jedes neuen Sellers.
    - **Riftr-Stand vor Round 11:** autoReleaseAt = 7 Tage fuer alle Sellers. Stripe delay_days = Account-Level-Tier (7d fuer neu, 5d/3d/1d fuer hoehere Tier).
    - **Fix:** in markShipped → pruefe sellerProfile.completedSalesCount. Wenn < 5: autoReleaseAt = 14 Tage (statt 7). Order-Doc bekommt firstFiveSalesExtraHold + firstFiveSalesIndex Felder fuer Audit.
    - **Effect:** Buyer hat verdoppelte Dispute-Window fuer first-5-sales jedes neuen Sellers. Bei dispute Tag 8-14: refund-flow + reverse_transfer zieht Geld zurueck (auch nach Stripe-Auszahlung).
    - **Stripe delay_days bleibt unveraendert** (Account-Level, 7d). Unser Window ist jetzt LAENGER als Stripe-Auszahlung — = wir koennen Buyer-Protection geben auch wenn Geld schon Seller-Bank erreicht hat (Stripe-side reversal).
    - **Deployed.**

129. ⚠️ **Account-Reset-Loop Defense (deferred 2026-04-29)** — Round 10 Insider-Threat: Strategie 6. Nach Account-Suspend erstellt Fraudster neuen Account mit anderer Email + Stripe-Connect mit Geschwister-Ausweis + neuer Bank → continued operations.
    - **Fix erforderlich:** Device-Fingerprinting (IP, User-Agent, hardware-id) + Email-Domain-Clustering + Stripe-IBAN-Cross-Reference.
    - **Defer-Begruendung:** signifikanter Engineering-Aufwand, DSGVO-relevant (PII-Storage muss DSGVO-konform sein, Privacy-Policy-Update noetig). Stripe macht Teil dieser Detection bereits selbst (Multiple Connect-Accounts zur gleichen Bank-IBAN werden geflagged). Pre-Public-Launch-Track.

128. ⚠️ **Triangulation-Money-Laundering Velocity-Detection (deferred 2026-04-29)** — Round 10 Insider-Threat: Strategie 2. Seller A koordiniert mit Buyer B (stolen cards). B kauft High-Value-Listings von A, money flows zu A's Connect → Bank → A behaelt 90%, gibt 10% an B. Echter Karteninhaber chargebacked spaeter, A ist schon ausgezahlt.
    - **Primary Defense ist Stripe Radar** (Stripe-side ML-based fraud-detection). Riftr-side Velocity-Detection waere zusaetzlich:
      - Track "neue Buyer (<7d) → High-Value zu gleichem Seller" Pattern
      - Auto-Hold first-purchase >€500 von neuen Buyer-Accounts (extra Buyer-Verify-Step)
    - **Defer-Begruendung:** komplexe Velocity-Logik, Risiko legit-Power-Buyer zu blockieren. Stripe Radar fängt 60-80% in der Praxis. Pre-Public-Launch-Track wenn echte Triangulation-Faelle auftreten.

127. ✅ **Sock-Puppet Wash-Trading Detection (Round 10 Insider-Audit, 2026-04-29)** — HIGHEST-IMPACT-FIX in Round 10.
    - **Attack-Pattern:** Seller A koordiniert mit 5 Friend-Accounts. Friends kaufen €1-Listings (echtes Geld!), leaven 5-Sterne-Reviews. €54 total spending → Trusted-Tier (50 Verkaeufe, 4.95★) → 3-Tage delay_days → A scammt echte Buyer mit High-Value-Listings.
    - **Defense:** `trackBuyerSellerPair()` getriggert bei confirmDelivery + autoReleaseOrders. Per-Pair Tracking in 30d-Window mit timestamps + amounts. Doc-Path: `artifacts/{appId}/buyerSellerPairs/{buyerId}_{sellerId}`.
    - **Threshold-Detection (zwei Pattern):**
      1. HARD: 10+ Transaktionen in 30 Tagen (egal welcher Betrag) → SUSPECT
      2. SOFT: 5+ Transaktionen UND avgAmount < €15 (low-value Wash-Pattern) → SUSPECT
    - **Bei Hit:** Admin-Alert `SOCK_PUPPET_SUSPECT` mit pair-Details + reason. flaggedAt + flaggedReason im Doc gespeichert. Kein Auto-Block — echte Power-Buyer-Pairs existieren (Lieblings-Seller). Admin investigiert manuell + entscheidet ueber Suspension.
    - **Firestore-Rule:** `buyerSellerPairs/{pairId}` ist CF-only (Admin-SDK-write, kein Client-Zugriff). Verhindert dass Fraudster die Threshold-Werte reverse-engineeren.
    - **Memory-bound:** events-Array hat max 50 Eintraege pro Pair (legit-Pair erreicht das nie).
    - **Deployed.**

126. ✅ **Pre-Release Mass-Scam Defense (Round 10 Insider-Audit, 2026-04-29)** — HIGH-IMPACT-FIX:
    - **Attack-Pattern:** Neuer Seller listet 100× Pre-Release-Karten "UNL Aatrox €50". 100 Buyer pre-ordern → €5000 Auth-Hold (capture geblockt vor Release-Date). Mai 8 Release-Day: Seller markShipped × 100 → alle €5000 captured → vanish bevor delay_days-Auszahlung. = €5000 Beute pro Set-Release.
    - **Defense:** im existierenden `enforceListingSpamLimit`-Trigger zusaetzlicher Pre-Release-Cap (account-age-based):
      - <7 Tage:  max 5 Pre-Release-Listings/Tag
      - 7-30 Tage: max 25 Pre-Release-Listings/Tag
      - >30 Tage:  max 100/Tag (= regular daily cap)
    - **Counter:** `rateLimits/{uid}.preReleaseListingCreate` (analog zu existing Round 7 listing-counter).
    - **Bei Hit:** Listing flagged `pre_release_cap_exceeded`, Admin-Alert `PRE_RELEASE_SCAM` mit reason inkl. Account-Age.
    - **Effect:** neuer Seller kann max €250 Pre-Release-Volume aufbauen (5 × €50), nicht €5000. Macht Pre-Release-Mass-Scam uneconomic. Etablierter Seller mit echter Sales-History wird nicht beschraenkt.
    - **Deployed.**

125. ✅ **Listing-Velocity Anti-Burst (Round 9 Red-Team, 2026-04-29)** — vorher 100/Tag erlaubte 100 Listings in 5 Min = Burst-Spam-Vektor.
    - Neuer Hourly-Cap 20/h zusaetzlich zum 100/Tag im `enforceListingSpamLimit`-Trigger
    - Rolling-Window via timestamps-Array, memory-bound auf 50 Events
    - Trigger flagged `status: 'flagged_spam'` mit Begruendung (`hourly_burst` vs `daily_cap`) → Admin-Alert mit klarem Reason
    - **Deployed.**

124. ✅ **Carding-Defense via Age-Based + Hourly-Velocity (Round 9 Red-Team, 2026-04-29)** — Red-Team-Methodik (Hacker-Perspektive von außen):
    - **APK-Recon-Simulation:** durchgesimuliert was extrahierbar ist (Firebase API Key, Project ID, Stripe pk_test_*, CF-URLs via Burp). Alles "designed-public", kein Server-Secret extrahierbar.
    - **23 Attack-Versuche durchgespielt, 20 BLOCKED** durch Round 1-8 Defense-Layers.
    - **3 echte Gaps gefunden:** Email-Enumeration (#107 Console-toggle), Carding-Velocity zu generös, Listing-Spam-Burst.
    - **Carding-Defense-Fix (HIGH):**
      - Vorher 50 PIs/Tag pro Account → Carder konnte 50 stolen cards/Tag testen pro Account, mit catch-all-Email viele Accounts → Mass-Carding-Operation profitabel.
      - **Account-Age-Based-Cap** auf createPaymentIntent: <7d=5/Tag, 7-30d=15/Tag, >30d=25/Tag. Carder muesste 7+ Tage warten BEVOR er einen Account profitabel cardet → uneconomic fuer Mass-Operations.
      - **Hourly-Velocity-Cap**: createPaymentIntent 5/h (war 10), processMultiSellerCart 2/h (war 5). Gibt Stripe-Radar Zeit fuer Pattern-Detection.
      - Same Pattern fuer processMultiSellerCart (Multi-Cart-Path-Bypass-Defense): <7d=3/Tag, 7-30d=8/Tag, >30d=15/Tag.
      - Account-Age via `admin.auth().getUser().metadata.creationTime` — server-trusted, nicht faelschbar.
    - **Economics-Veraenderung:**
      - Pre-Round-9: 50 fresh accounts × 50/Tag = 2500 cards/Tag testbar
      - Post-Round-9: 50 fresh accounts × 5/Tag = 250 cards/Tag (10× weniger) + 7-Tage-Wartezeit
      - = Mass-Carding-Operation nicht mehr profitabel
    - **Helper-Pattern erweitert:** `enforceAgeBasedDailyCap()` + `enforceHourlyVelocity()` reusable fuer kuenftige CFs.
    - **Deployed.**

123. ⚠️ **2FA + CAPTCHA fuer Sellers (deferred 2026-04-29)** — Round 8 marketplace-spezifischer Audit. Stripe-Empfehlung: 2FA-Enforcement fuer Seller-Accounts gegen ATO. Aktueller Stand:
    - Firebase Auth supports MFA — aber UI nicht implementiert
    - Firebase hat default 5-attempts/15-min lockout fuer Brute-Force (OAT-007)
    - App Check Phase 1 active, Phase 2 enforce (#99) ist die cleanere CAPTCHA-Alternative gegen OAT-019 (Account Creation)
    - **Defer-Begruendung:** 2FA-UX braucht eigene Onboarding-Flow + Recovery-Path, das ist Pre-Public-Launch-Aufwand. Fuer Beta sind die existing Defenses (App Check + email-verification + isVerifiedUser) ausreichend.

122. ✅ **Stripe Connect ATO: Bank-Detail-Change Defense (Round 8 Pen-Test, 2026-04-29)** — Marketplace-spezifischer Pen-Test mit Sharetribe + OWASP OAT + Stripe Connect Best-Practices ergab kritisches Finding: `account.updated` Webhook ignoriert vorher external_account-Aenderungen → Bank-Detail-Change-ATO unverteidigt.
    - **Attack-Scenario:** Attacker phishes Seller-Email-Credentials → Magic-Link-Login zu Stripe-Express-Dashboard → aendert IBAN auf eigenes Konto → naechste Auszahlung (delay_days, server-managed) geht an Attacker. Stripe-Empfehlung: "Watch for sensitive data changes (passwords, email addresses, bank details) from new devices."
    - **Fix-Implementation:**
      1. `account.updated` Webhook vergleicht new vs cached `stripeExternalAccountId` (gecached in sellerProfile)
      2. Bei Change: setzt `payoutsPausedReason: 'external_account_changed'` + `payoutsPausedAt` + Audit `previousExternalAccountId` in sellerProfile (CF-only-write per Round-1-Field-Allowlist)
      3. Sendet HIGH-Severity-Push an Seller ("Falls du das nicht warst, kontaktiere uns sofort")
      4. Admin-Alert via `sendAdminAlert("STRIPE_BANK_CHANGE", ...)`
    - **Enforcement an 3 Stellen** (blocking aller Money-Flow auf paused-Account):
      - `createPaymentIntent`: Buyer kriegt clean Error, Karte nie geladen
      - `processMultiSellerCart`: sauberer cart-error, andere Sellers im Cart bleiben kaufbar
      - `markShipped`: PI bleibt in requires_capture, Stripe released Auth nach 7 Tagen automatisch wenn nicht captured
    - **Deployed.** App-Code keine Aenderung — UI behandelt failed-precondition als generic-error.

121. ⚠️ **OWASP OAT umfassend Verification (deferred summary 2026-04-29)** — Round 8 systematisch durch OWASP Automated Threats (OAT) 1-21 angewendet auf P2P-Marketplace-Kontext:
    - **OAT-001 Carding**: Stripe Radar default-aktiv, fingerprinting via mobile-SDK
    - **OAT-005 Scalping / OAT-013 Sniping**: cart-reservedQty-cap (50/listing) + items 9999-cap
    - **OAT-007 Credential Cracking**: Firebase Auth default 5-attempts/15-min lockout
    - **OAT-008 Credential Stuffing**: deferred → 2FA-Path (#123)
    - **OAT-011 Scraping**: Listings sind auth-readable, kein read-volume-cap (acceptable, public-data anyway)
    - **OAT-017 Spamming Reviews**: Round 5 verifiziert (1-per-order, status-check)
    - **OAT-019 Account Creation**: App Check Phase 1 + email-verification gate
    - **OAT-021 Denial of Inventory**: Round 2 reservation-cap-system
    - Alle 21 OAT-Kategorien systematisch bewertet, nur ATO (#122) als HIGH gefunden + gefixed.

120. ⚠️ **MASVS-RESILIENCE Hardening (deferred 2026-04-29)** — Round 7 Pen-Test-Methodik. Aktuell keine eigene Jailbreak/Root-Detection oder Anti-Tampering. Mitigierung schon vorhanden:
    - Stripe-SDK hat `STDSJailbreakChecker` fuer 3DS-Flows aktiv (auf jailbroken iOS gibt's einen 3DS-Block)
    - App Check Phase 1 active → Phase 2 enforce (#99) gibt Defense-in-Depth gegen Token-Theft via Frida
    - Server-Rules + Field-Allowlists limitieren was ein extracted-token machen kann
    - **Defer-Begruendung:** Jailbreak/Root-Detection ist Cat-and-Mouse — jeder Detection wird gebrochen. Diminishing returns vs Beta-Risk. Gehoert in eine spaetere Phase mit anderen Resilience-Themen (binary protection, Frida-detection). 
    - Externer Pen-Test wuerde das ggf. anregen — Solo-Dev-Aufwand zu hoch fuer Marginal-Wert.

119. ⚠️ **MASVS-PLATFORM FLAG_SECURE (deferred 2026-04-29)** — Round 7 Pen-Test-Methodik. Android erlaubt Screenshots + Screen-Recording der App by-default. Sensitive Daten on-screen (z.B. Stripe-Payment-Sheet, Order-Adresse) koennen via Screen-Capture-Apps oder User-shared-Screen geleakt werden.
    - **Real-world impact:** LOW fuer TCG-App. Stripe-Payment-Sheet hat bereits eigene Screen-Capture-Protection.
    - **Fix:** Android `FLAG_SECURE` setzen via Flutter (z.B. `flutter_windowmanager` package). iOS hat keinen direkten Equivalent (UIScreen capture-detection ist begrenzt).
    - **Defer:** wenig Impact, kein Standard-Compliance-Driver. Re-evaluate vor Public-Launch.

118. ⚠️ **MASVS-NETWORK Cert-Pinning (deferred 2026-04-29)** — Round 7 Pen-Test-Methodik. Aktuell vertrauen wir System-Trust-Store fuer alle HTTPS-Calls (Firebase, Stripe, Cardmarket, etc.). Wenn ein User einen malicious Root-CA installiert (MDM-attack auf Corporate-Device), MitM moeglich.
    - **Mitigierung schon da:** Stripe-SDK hat eigene Cert-Pinning fuers 3DS-Flow (Stripe-zertifizierte Endpoints). Firebase-SDK validates Google-Endpoints korrekt.
    - **Real-world risk:** SEHR niedrig — Attacker braucht physischen oder MDM-Access zum Device. Beta-User sind Friends, kein Corporate-Risk.
    - **Defer:** Cert-Pinning bricht haeufig bei API-Cert-Rotations + braucht App-Update um zu fixen. Mehr Maintenance-Cost als Security-Win fuer Beta. Pre-Public-Launch evaluieren wenn Threat-Model anders aussieht.

117. ✅ **createListing Mass-Spam-Limit via Firestore-Trigger (Round 7 Pen-Test, 2026-04-29)** — Round 7 systematisch nach PTES + OWASP MASVS + OWASP API Security Top 10. Echtes HIGH-Finding entdeckt: Listings werden direkt via Flutter `.add()` geschrieben (kein CF involved) → der `enforceRateLimit`-Helper aus Round 5 greift NICHT. Authenticated User koennte 10k Listings/h spammen → Marketplace-Pollution + Quota-Burn.
    - **Fix:** neuer Firestore-Trigger `enforceListingSpamLimit` auf `listings/{listingId}` onCreate.
      - Counter pro User/Tag in `rateLimits/{uid}.listingCreate`
      - Threshold: 100/Tag/User
      - Bei Ueberschreitung: NICHT block, sondern reactive flag → `status: 'flagged_spam'` + adminAlert
      - Marketplace-Queries (filter `status == 'active'`) zeigen flagged-Spam nicht
      - Power-Seller-Bulk-Import (~200-500): erste 100 OK, Rest flagged. Admin unflaggt manuell wenn legitim.
    - **Reactive vs Proactive:** Firestore-Rules-Counter waere proactive aber expensive (cross-doc-reads). Trigger-Reactive ist post-write aber praktisch instant (~1-2s) und bewahrt Audit-Trail.
    - **Deployed.** App-Code keine Aenderung — Flutter `.add()` flow unveraendert.

116. ✅ **Audit-Followup: Chargeback-Unfreeze + Multi-Seller-Rollback (2026-04-29)** — Externer `/security-review` Slash-Command hat 0 Security-Findings ueber die Round-1-6 Commits gemacht (= alle 21 Audit-Fixes verifiziert sauber!), aber 2 Out-of-Scope Functional-Bugs als "worth fixing" geflagged:
    - **Bug 1: `charge.dispute.closed`** Handler las `metadata.uid` statt `buyerId` → Chargeback-WON-Auto-Unfreeze funktionierte NICHT, Manual-Admin noetig. Fix: `buyerId || uid` fallback.
    - **Bug 2: `processMultiSellerCart` Rollback** dekrementierte `reservedQty` immer um `item.quantity` — auch wenn der Erfolgs-Path einen cart-reserved-transfer gemacht hatte (= reservedQty wurde NICHT erhoeht). Konsequenz: nach Rollback ist reservedQty auf 0 statt am tatsaechlichen cart-Wert + cart-doc geloescht = inkonsistenter User-Cart. Fix: neuer `ownCartReservedQty`-Marker pro orderItem; Rollback dekrementiert nur `(quantity - cartTransferQty)`.
    - **Externer Auditor Quote:** *"The 21+ findings the PR author documented have all been verified as properly addressed. No additional high-confidence vulnerabilities identified."*
    - **Deployed.** Beides keine Security-Findings — Money-State + State-Integrity-Bugs.

115. ⚠️ **avatarUrl Tracking-Pixel-Hardening (deferred 2026-04-29)** — Round-6-Audit. User koennen aktuell beliebige URLs als avatarUrl setzen (`social_screen.dart` Z. 1230 — Text-Controller, kein Validation). Wenn andere User das Profil ansehen → Device fetched die URL → Attacker-Server logged IP, User-Agent, Timestamp. = Tracking-Pixel.
    - **Fix-Vorschlag:** Domain-Whitelist in Firestore-Rule + profile_service:
      - Allowed Prefixes: `https://firebasestorage.googleapis.com/`, `https://lh3.googleusercontent.com/` (Google Sign-In Avatare), evtl. `https://i.imgur.com/`.
      - Rule: `request.resource.data.avatarUrl == null || (avatarUrl matches whitelist regex)`.
      - Migration: bestehende User-Avatars die nicht whitelist-conformig sind muessten auf null reset werden (~5-10 betroffene Beta-User).
    - **Aufwand:** ~1h Code + Migration-Script + UI-Polish (file-upload statt URL-paste fuer Beta-Phase).
    - **Defer-Begruendung:** Beta-User sind Friends, malicious-actor-Risk niedrig. Pre-Public-Launch zwingend (DSGVO + Tracker-Defense).

114. ⚠️ **stripe_events-TTL-Policy + rateLimits-TTL (deferred 2026-04-29)** — Round 6 added `enforceRateLimit`-Helper schreibt in `artifacts/{appId}/rateLimits/{uid}` mit `{cfName: {date, count}}`-Sub-Objects. Wachsen forever (1 Doc/User, mit ~5-10 Sub-Objects). Pro User 5kb max, ueber Zeit OK aber nicht aufgeraeumt.
    - **Fix:** Firebase Console TTL-Policy auf `artifacts/{appId}/rateLimits/{uid}` mit Field `lastTouchedAt` (muss noch in CF gesetzt werden) + 90-Tage-TTL. Inactive-User-Counter wird automatisch entsorgt.
    - Plus dasselbe fuer `stripe_events` (siehe #106).
    - **Aufwand:** ~5 Min Console + 5 Min Helper-Update.
    - **Defer-Begruendung:** Quota-Management, kein Sicherheitsproblem.

113. ✅ **toggleDeckLike Rate-Limit (2026-04-29)** — Round-6-Audit. CF hat sauberen Transaction-basierten like/unlike-Counter, aber kein Rate-Limit. User koennte 100k like/unlike-Toggles spammen → Firestore-Quota-Burn auf Riftr-Konto (jeder Toggle = 2 writes: likeRef + deckRef.likeCount).
    - **Fix:** `enforceRateLimit(uid, "toggleDeckLike", 200)` — 200 toggles/User/Tag. Realistischer Heavy-User: ~5-10 Toggles/Tag. 200 = 20-40x headroom, blockt Spam-Bots.
    - **Deployed.** App-Side keine Aenderung.

112. ✅ **Items-Array Duplicate-Listing-Id Over-Allocation (2026-04-29)** — Round-6-Audit kritisches Finding. `createPaymentIntent` und `processMultiSellerCart` iterierten ueber `items` ohne Dedupe. Buyer konnte duplikate listingIds senden → jede Iteration las dasselbe Listing, available-check bestand mehrfach (Firestore-Reads sind keine Reservierung) → Order ueber-allokiert.
    - **Konkretes Exploit:**
      1. Listing X hat quantity=1, price=€100
      2. Buyer sendet `items: [{listingId: "X", qty: 1}, {listingId: "X", qty: 1}]`
      3. Beide Iterationen: available=1, qty=1 ≤ 1 ✓ (read-only check, keine inkrement)
      4. Order erstellt mit 2 Karten (orderItems-Array hat 2 Eintraege)
      5. PI charged fuer 2*€100 = €200
      6. Listing.reservedQty wird via increment(1) zweimal aufgerufen → reservedQty=2 (aber listing.quantity=1!)
      7. Inconsistent state — Seller kann nur 1 ausliefern, Dispute-Track folgt
    - **Verschaerft den Bug:** kombiniert mit Smart-Cart-Algorithmus, koennte ein Angreifer in einem race-with-other-buyers das ganze hot-listing locken bevor andere checken-out koennen.
    - **Fix:** neuer Helper `dedupeAndValidateItems(items)`:
      - Dedupe by listingId, summing quantities
      - Validation: items must be array, length 1-100, jeder entry hat valid listingId + quantity 1-9999
      - Aggregierte Quantity-Cap: kein listing kann > 9999 angefragt werden
    - Aufgerufen ganz am Anfang in `createPaymentIntent` (cart-mode) und `processMultiSellerCart` (immer, da multi-only).
    - **Deployed.** Bestehende valid-Carts unbetroffen — duplicate-listingIds sind ein noch-nie-vom-Frontend-gesendetes Pattern.

111. ⚠️ **Round-5-acceptable-risk: markShipped + cancelOrder Race-Window (deferred, 2026-04-29)** — Wenn Seller `markShipped` und Buyer `cancelOrder` exakt gleichzeitig auf einer `paid`-Order callen:
    - Stripe-Side: capture vs cancel auf demselben PI = mutually-exclusive, Stripe-API serialisiert (eines schlaegt fehl mit "PI in invalid state")
    - Firestore-Side: zwischen den beiden Update-Calls last-write-wins → kurzzeitig inkonsistent, aber selbst-heilend bei naechstem read
    - Money-State ist deterministisch (Stripe-protected). Order-Doc-State koennte 1-2s "schief" stehen
    - **Nicht-exploitable** — kein Money-Leak, kein User-Schaden, nur kurze UX-Inkonsistenz
    - **Defer-Begruendung:** voller TX-Wrap mit "shipping_pending"/"cancelling"-Lease-Pattern waere ~50 LOC + wuerde Stripe-API-Calls aus der TX rauspatchen. Fuer Beta acceptable. Pen-Test-Track empfohlen vor Public-Launch.

110. ✅ **Rate-Limit auf createPaymentIntent + processMultiSellerCart (2026-04-29)** — Round-5-Audit. Beide Funktionen waren unbeschraenkt callable von authentifizierten Usern → Stripe-API-Quota-Burn + Firestore-Order-Doc-Spam-Vektor.
    - **Helper:** `enforceRateLimit(uid, key, dailyLimit)` in functions/index.js. Counter pro UID + key (CF-Name) in `artifacts/{appId}/rateLimits/{uid}` Doc, sub-object pro Key mit `{ date, count }`. CF-only-writes via Admin-SDK; Default-deny-Rule blockt Client-Reads.
    - **Limits:**
      - `createPaymentIntent`: 50/Tag/User. Heavy-Buyer real-world ~10-20/Tag, 50 = 2-3x headroom.
      - `processMultiSellerCart`: 30/Tag/User (teurer per-Call, niedrigeres Limit).
    - **Race-Acceptable:** paralleler Read-then-Write koennte Cap um +1 ueberschreiten. Statistisch akzeptabel — Limit-Wert ist sowieso konservativ.
    - **HttpsError:** `resource-exhausted` mit klarer Message ("Daily limit reached. Try again tomorrow.").
    - **Deployed.** App-Side keine Aenderung — UI behandelt resource-exhausted als generic-error mit Retry-Hinweis.

109. ✅ **confirmDelivery + autoReleaseOrders Double-Run Race (2026-04-29)** — Round-5-Audit kritisches Finding. Vorher: beide CFs flippten den Status auf delivered/auto_completed ohne re-checked TX. Race-Window (millisekunden) zwischen autoReleaseOrders-Cron-Fire (03:00 Berlin) und Buyer-Tap-confirmDelivery erlaubte BEIDE Side-Effect-Loops zu laufen:
    - `totalSales` 2x increment (Seller-Stats inflated)
    - `totalRevenue` 2x increment (Seller-Revenue inflated)
    - `addItemsToCollection` 2x → Buyer kriegt seine Karten DOPPELT in die Collection
    - `recordSales` 2x → Analytics doppelt
    - `updateBalanceCache` 2x → Balance-Cache flackert kurzzeitig
    - **Exploit:** Buyer wartet bis 02:59:59 Berlin time, ruft `confirmDelivery` exakt um 03:00:00 → race auf double-collection. Bei wertvollen Karten (€100+ Singles) lohnt sich der Glücks-Versuch mehrfach.
    - **Fix:** beide CFs nutzen jetzt `db.runTransaction()` mit atomarer state-flip. Transaction liest fresh-state, prueft `status === "shipped"`, dann update. Wenn die andere CF schneller war, schlaegt die TX fehl (status != "shipped") und SIDE-EFFECTS LAUFEN NICHT.
    - **Nur die siegreiche CF** triggert Stats-Inc + Collection-Add + Notify. Loser-CF skippt cleanly mit Log-Message ("status already advanced").
    - **Deployed.** Idempotent zu existing data — keine Migration noetig.

108. ✅ **Self-Buy-Guard in createPaymentIntent (5.(!) Self-Rating-Fraud-Vektor, 2026-04-29)** — Round-5-Audit kritisches Finding. `processMultiSellerCart` (Z. 2689) und `reserveForCart` (Z. 6037) hatten den Self-Buy-Check, ABER `createPaymentIntent` (Z. 2114) NICHT. Direkt-Kauf-Flow (ohne Cart) erlaubte Self-Purchase.
    - **Echtes Exploit-Szenario:**
      1. Seller erstellt Listing fuer €100
      2. Seller ruft `createPaymentIntent` direkt auf (umgeht Cart-UI)
      3. Verlust: ~5% Riftr-App-Fee + 1.5% Stripe = ~€7
      4. Order durchlaeuft normal: confirmPayment → markShipped → confirmDelivery
      5. Seller ruft `submitReview` als Buyer (eigener UID) → 5-Sterne Eigen-Bewertung
      6. = €7 fuer einen fake Review = Power-Seller-Reputation-Pump
    - Bei mehreren fake-Reviews (€7 × 10 = €70) hat Seller einen "Trusted-Tier" Status (10+ Verkaeufe, 4.95 Rating) und kommt auf 5-Tage-Auszahlung.
    - **Fix:** ein-zeiliger Self-Buy-Check nach `const sellerId = listingData[0].sellerId`:
      ```js
      if (sellerId === uid) {
        throw new HttpsError("permission-denied", "Cannot buy your own listings");
      }
      ```
    - **Deployed.** Bestehende Self-Reviews falls vorhanden bleiben unangetastet — Audit-Pass fuer historische Orders waere separater Task.
    - **Lehre:** Defense-in-Depth ist wichtig — der Check existierte an 2 von 3 Stellen, unklar warum die 3. fehlte. Code-Review-Best-Practice waere ein zentraler `assertCanBuy(uid, sellerId)` Helper damit alle 3 Pfade die Logic teilen.

107. ⚠️ **Firebase Console Hardening Phase — Manual Action-Items (offen, 2026-04-29)** — Sachen die nur per Firebase-Console toggle-bar sind, keine Code-Aenderungen:
    - **Anonymous Sign-In: DISABLE** — Firebase Console → Authentication → Sign-in method. Default ist OFF. Wenn versehentlich ON, bringt unser `isVerifiedUser` Defense-in-Depth (#103), aber besser direkt am Provider blocken.
    - **Email Enumeration Protection: ENABLE** — Firebase Console → Authentication → Settings → User actions → "Email enumeration protection" anhaken. Verhindert dass Angreifer ueber sendPasswordResetEmail erfahren ob eine Email registriert ist (Recon-Phase fuer credential-stuffing Angriffe).
    - **Multi-Factor-Authentication (MFA) fuer Admins** — Wenn Admin-Custom-Claims gesetzt sind, MFA fuer den Admin-Account aktivieren. Firebase Console → Authentication → User Tab → Admin User → MFA enrollen oder im Auth-Provider (Apple-Sign-In mit FaceID, Google mit 2FA).
    - **Stripe Live-Key Switch vor Public-Launch** — `lib/main.dart` Z. 68 ist `pk_test_*`. Bei Public-Launch auf `pk_live_*` umstellen + STRIPE_SECRET_KEY Secret in Firebase Functions auf live umstellen. Beide Pfade getrennt, deshalb safe in Beta.

106. ⚠️ **stripe_events-Collection TTL (deferred 2026-04-29)** — Round 4 added Webhook-Event-Dedup via `artifacts/{appId}/stripe_events/{eventId}` Collection. Wird forever wachsen (~100-1000 Events/Tag). Stripe-Retry-Window ist ~3 Tage, Events aelter als 30 Tage werden definitiv nie repliziert.
    - **Fix:** Firebase Console → Firestore → TTL Policies → neue Policy auf `artifacts/{appId}/stripe_events` mit Field `processedAt` und 30-Tage-TTL. Nur Console-Action, keine Code-Aenderung.
    - **Alternativ:** Cron-CF die alle alten Docs >30 Tage loescht. TTL-Policy ist eleganter.
    - **Aufwand:** ~3 Min Console-Click.
    - **Defer-Begruendung:** kein Sicherheitsproblem, nur Quota-Management. Ungefaehr 100k Docs/Jahr = $0.0001 pro Read.

105. ✅ **Stripe Webhook Replay-Schutz via event.id Deduplication (2026-04-29)** — Round-4-Audit-Finding. Stripe schickt Webhook-Events bei Network-Issues / Retries manchmal mehrfach. Status-basierte Idempotenz fängt die meisten ab (z.B. PI succeeded mit status==pending_payment-Check), ABER:
    - `charge.dispute.created` wuerde bei Replay 2× Push an Seller, 2× Admin-Alert, 2× wallet.balance freezen (idempotent aber laute Logs).
    - `payment_intent.succeeded` als Fallback-Path: zwischen den State-Checks koennte Race-Window entstehen.
    - **Fix:** atomare Event-Dedup via `firestore.create()`. Pattern wirft `ALREADY_EXISTS` (gRPC code 6) wenn Doc schon da ist — kein Race-Condition-Window. Wenn create OK → neues Event → normal verarbeiten. Wenn `ALREADY_EXISTS` → Replay → 200 zurueck, kein Re-Run.
    - Dedup-Doc-Path: `artifacts/{appId}/stripe_events/{eventId}`. Stripe-Event-IDs (`evt_xxx`) sind globally unique.
    - Andere errors (transient Firestore-Timeout etc.) → loggen + weiter verarbeiten (lieber doppelt als gar nicht).
    - **Deployed.** Firestore-Rule expliziert: `match /stripe_events/{eventId} { allow read, write: if false; }` (CF-only).
    - TTL-Cleanup als #106 deferred.

104. ✅ **Listings-Create CF-Trigger: server-trusted sellerRating + sellerSales (2026-04-29)** — Folge-Fix zu #103. Nachdem die Firestore-Rule den Client zwingt `sellerRating: 0, sellerSales: 0` zu senden, zeigt die Listing-Tile fuer aktive Power-Seller initial "0 Sales / 0 Rating" — UX-Regression.
    - **Fix:** neue Firestore-Trigger-CF `populateListingSellerStats` (`onDocumentCreated` auf `artifacts/{appId}/listings/{listingId}`):
      1. Liest `sellerProfile`-Doc des Sellers (CF-managed, trusted)
      2. Falls `rating > 0 || totalSales > 0` → `listing.update({ sellerRating, sellerSales })`
      3. Idempotent — falls Trigger replayed wird, unveraendert
    - **Latency:** ~1-2s zwischen Listing-Create und Trigger-Fire. Acceptable — UI rendert in der Zwischenzeit "0 Sales" als „New Seller" (kosmetisch, kein Funktions-Verlust).
    - **Eventarc-Setup:** Erster Deploy schlug fehl mit "Permission denied while using the Eventarc Service Agent" — propagation-issue, nach 90s Retry erfolgreich. Einmalig pro GCP-Projekt.
    - **Deployed.** Trigger ist live in europe-west1.

103. ✅ **Listings-Create Lockdown: Self-Stats-Fraud + Input-Validation + Anti-Bot (2026-04-29)** — Round-4-Audit, fuenfter (!) Self-Rating-Fraud-Vektor entdeckt + gefixt. `listing_service.dart::createListing` (Z. 198-209) hat `sellerRating` und `sellerSales` direkt aus dem eigenen `sellerProfile` ins Listing-Doc geschrieben. Firestore-Rule pruefte nur `sellerId == auth.uid && status == 'active'` — keine Field-Allowlist. **Echtes Exploit:** Seller decompiled die App, schreibt `sellerRating: 5.0, sellerSales: 999` → Marketplace zeigt fake-Power-Seller-Tile → Buyer-Vertrauen-Tausch. (Round 1 hat das fuer sellerProfile gefixt, Round 2/3 fuer Mirror, Round 4 jetzt fuer Listings.)
    - **Firestore-Rule erweitert:**
      - `isVerifiedUser` Helper neu: `isAuth() && request.auth.token.firebase.sign_in_provider != 'anonymous'` — Defense-in-Depth gegen Anonymous-Auth-Bots wenn jemals (versehentlich) in Console enabled.
      - Listings-Create rejected wenn sellerRating oder sellerSales != 0
      - Price-Validation: `price is number && 0 < price <= 100000` (€100k cap, Tippfehler-Schutz)
      - Quantity-Validation: `quantity is int && 0 < qty <= 9999`
      - Listings-Update zusaetzlich isVerifiedUser + price-Cap auch bei Edit-Path
    - **Flutter App-Side:** `listing_service.dart` schreibt jetzt `sellerRating: 0.0, sellerSales: 0` (matched die Rule). Server-side Trigger #104 populiert die korrekten Werte.
    - **Deployed.** Bestehende Listings unangetastet (Rule pruefte nur create/update, existing data bleibt).
    - **App-Code-Compatibility:** `updateListingPrice/Quantity/Cancel` schreiben weiterhin Single-Field-Updates → kompatibel mit Round-3 affectedKeys-Locks.

102. ⚠️ **SSRF-Hardening Tournament-Scraper (deferred 2026-04-29)** — `fetchWithRetries` (functions/index.js Z. 6247) folgt URLs aus geparstem Riot/Mobalytics-HTML. Theoretischer SSRF: wenn jemand Riot's Site kompromittiert + uns präzise URLs unterjubelt → Server koennte interne URLs (z.B. GCP Metadata-Endpoint `metadata.google.internal`) treffen. Wahrscheinlichkeit extrem niedrig (Riot-Site-Compromise = much-bigger-Internet-Problem), aber Defense-in-Depth.
    - **Fix-Vorschlag:** Domain-Whitelist in fetchWithRetries — nur URLs mit `riotgames.com`, `mobalytics.gg`, `lolesports.com` zulassen. URL-parsing via `new URL(url)`, `.hostname`-Check. Falls externe Domain → throw + log.
    - **Aufwand:** ~15 Min Code + Tests.
    - **Defer-Begruendung:** Nicht direkt exploitierbar, kein User-controlled Input, hohes Compromise-Erfordernis bei Drittseite.

101. ✅ **PII-Cleanup: Email aus Cloud-Logs entfernt (2026-04-29)** — Round-3-Audit-Finding: `sendVerificationCode` (Z. 1277) und `verifyEmailCode` (Z. 1347) loggen User-Email in Cloud Logging. DSGVO-Risiko: Logs muessen bei Datenexport-Anfragen mit ausgegeben werden — User-Emails an irgendeinem Drittentwickler-Audit-Zugriff sichtbar.
    - **Fix:** Email aus Log-Strings entfernt, nur noch UID. Email bleibt im Return-Value (geht direkt zur App, nicht in Logs).
    - **Vorher:** `console.log(\`Verification code sent to ${email} for uid ${uid}\`)` und `Email ${data.email} verified for uid ${uid}`
    - **Nachher:** `Verification code sent for uid ${uid}` und `Email verified for uid ${uid}`
    - **Deployed.**

100. ✅ **Firestore Rules Round 3: Listings + playerProfiles tighten (2026-04-29)** — Round-3-Audit nach User-Anfrage „nochmal sehr sehr gruendlich". Zwei zusaetzliche Findings entdeckt + gefixt:
    - **Listings Update — Price-Change-Mid-Cart-Vektor:**
      - Vorheriges Pattern: `allow update: if (status==cancelled OR (qty reduced))` ohne `affectedKeys`-Check. Konsequenz: Seller konnte beliebige Felder aendern solange er die Bedingung erfuellte. Echtes Exploit: Buyer reserviert Listing fuer EUR10 → Seller ruft App-update `{quantity: q-1, price: 1000}` → Rule passt (qty-reduziert) → Checkout liest live `listing.price=1000` → Buyer wird EUR1000 belastet (statt EUR10 wie im UI angezeigt).
      - Fix: 3 disjunkte Update-Pfade, jeder mit `affectedKeys().hasOnly([...])`:
        1. **Cancel:** nur `status` (+ `updatedAt`, `cancelledAt`), Wert muss `'cancelled'` sein
        2. **Qty-Reduce:** nur `quantity` (+ `updatedAt`), status bleibt `'active'`, qty > 0, qty <= original
        3. **Price-Edit:** nur `price` (+ `updatedAt`), ABER `reservedQty == 0` (keine offenen Cart-Reservationen). Sonst muss Seller warten bis Cart-TTL ablaeuft oder Buyer raus-cancelt.
      - Flutter App-Code unveraendert kompatibel: `updateListingQuantity` sendet nur `{quantity}`, `updateListingPrice` nur `{price}`, `cancelListing` nur `{status}` — alles passt zu den Field-Allowlists.
    - **playerProfiles Write — Self-Rating-Fraud-Mirror:**
      - Vorheriges Pattern: `allow write: if isOwner(uid)` ohne Field-Allowlist. Owner konnte direkt rating/reviewCount/totalSales/memberSince schreiben → fake-Power-Seller-Status bis zum naechsten CF-Mirror-Sync (submitReview/confirmDelivery).
      - Fix: Field-Allowlist auf displayName/displayNameLower/avatarUrl/bio/country/city/updatedAt. CF-Writes via Admin SDK bypassen Rules → syncPlayerProfile-Helper kann weiterhin alle Public-Stats-Felder schreiben.
      - App-Code-Check: `profile_service.dart::updateProfile` schreibt nur die erlaubten Felder, kompatibel.
    - **Deployed:** firestore.rules + 2 CFs (sendVerificationCode + verifyEmailCode mit log-cleanup #101).
    - **Round 3 Verifikation Round-2-Fixes:** App-Code-Search bestaetigt — kein Flutter-Caller fuer geschuetzte Manual-CFs (#95), `playerProfiles`-Writes nur in profile_service mit kompatiblen Feldern, `listings`-Writes nur als saubere Single-Field-Updates. Round-2-Fixes haben nichts gebrochen.

99. ⚠️ **App Check Hard-Enforce Phase 2 (offen, 2026-04-29)** — Phase 1 (Flutter-Init + Token-Flow live) ist via #98 erledigt. Phase 2 = Server-side Hard-Enforce auf kritischen CFs:
    - **Vorbedingung:** Apple-DeviceCheck-Key in Firebase Console hinterlegen (Apple Developer Portal → Keys → DeviceCheck-Key generieren → Team-ID + Key-ID + Private-Key in Firebase Console → App Check → Apps → riftrFlutter (iOS) hochladen). Play-Integrity ist auto-konfiguriert für Android.
    - **Debug-Token:** lokal in Debug-Mode den DebugToken aus Console-Output kopieren → Firebase Console → App Check → Debug-Tokens registrieren. Sonst werden Sim-/USB-Builds als invalid markiert.
    - **Token-Flow-Verifikation:** 1-2 Tage Beta-Traffic abwarten, im Firebase Console → App Check → Metrics prüfen ob >95% Requests "Verified" zeigen.
    - **Hard-Enforce aktivieren:** in `functions/index.js` zu den `onCall`-Options `enforceAppCheck: true` hinzufügen. Empfohlene Liste:
      - `sendVerificationCode`, `verifyEmailCode` (E-Mail-Bombing-Schutz)
      - `reserveForCart`, `releaseCartReservation`, `updateCartReservation` (Inventory-DoS-Schutz)
      - `createPaymentIntent`, `processMultiSellerCart`, `confirmPayment` (Money-Flow)
      - `createStripeAccount`, `createStripeAccountLink` (Onboarding)
      - `confirmDelivery`, `submitReview`, `markShipped`, `updateTrackingNumber` (Order-State)
      - `toggleDeckLike` (Like-Spam)
    - **Aufwand:** ~30 Min Firebase-Console-Setup + 10 Min CF-Edit + Test-Run.

98. ✅ **App Check Flutter-Setup (2026-04-29)** — Round-2-Security-Audit: Flutter-App registriert jetzt App-Attestation-Tokens vor jedem Firebase-Call, sodass Bots ohne echte App den Marketplace nicht spammen können. Hard-Enforce kommt in Phase 2 (#99).
    - **pubspec.yaml:** `firebase_app_check: ^0.3.2+1` hinzugefügt.
    - **lib/main.dart:** `FirebaseAppCheck.instance.activate(...)` direkt nach `Firebase.initializeApp` mit:
      - iOS Production/TestFlight: `AppleProvider.deviceCheck` (auto-verfügbar auf iOS 11+, kein extra Setup auf Device-Seite)
      - iOS Debug (Simulator/USB): `AppleProvider.debug` (DebugToken muss in Firebase Console registriert werden)
      - Android Production: `AndroidProvider.playIntegrity`
      - Android Debug: `AndroidProvider.debug`
    - **Try/Catch um activate():** App-Start darf nicht blockieren wenn Tokens nicht aktivierbar — Worst-Case: Tokens fließen nicht, App funktioniert weiter (weil Server noch im Soft-Mode).
    - **iOS-Side:** keine Entitlement-Änderung nötig (DeviceCheck ist freier System-Service, im Gegensatz zu App Attest). `pod install` lief durch, FirebaseAppCheck 11.15.0 installiert.
    - **Server-Side:** intentionally `enforceAppCheck: false` (default) auf allen CFs. Phase 2 (#99) zieht das hoch nachdem >95% Token-Validität im Dashboard verifiziert ist.

97. ✅ **`reserveForCart` + `updateCartReservation` Per-User-Limit (2026-04-29)** — Round-2-Security-Audit: ohne Limit kann ein authentifizierter User (oder ein Bot ohne App Check) beliebig viele Listings dauerhaft blockieren via Reserve → 30min TTL → Re-Reserve-Loop. Inventory-DoS-Vektor.
    - **Cap-Konstanten in `functions/index.js`:**
      - `MAX_ACTIVE_RESERVATIONS_PER_USER = 50` — total aktive Reservationen pro User
      - `MAX_RESERVED_CARDS_PER_USER = 100` — Summe quantity über alle Reservations
      - Per-Listing-Single-Cap: `quantity > 50` rejected (verhindert dass eine Single-Reservation den ganzen User-Quota auffrisst)
    - **Pre-TX-Check:** liest alle aktiven (nicht-expired) cartReservations des Users ein, summiert active-Count + active-Qty, vergleicht gegen Caps. Read-then-write-Race ist sehr unwahrscheinlich (User macht nicht parallel 2 reserveForCart-Calls für DIFFERENT listings) und worst-case ist Cap-Überschreitung um 1 — nicht kritisch.
    - **Mirror in updateCartReservation:** identische Logic damit User nicht via update das Limit umgeht. Per-Listing-Cap (50) wird auch dort enforced.
    - **Werte-Begründung:** 50/100 ist großzügig für ehrliche Smart-Cart-Nutzung (60-Karten-Deck über 5-10 Verkäufer aufgeteilt = ~10 Reservations/60 Karten — locker drunter), aber blockt Bots die 1000 Listings parallel reserven.
    - **HttpsError-Code:** `resource-exhausted` mit Message die User klar sagt "Remove some items before adding more".

96. ✅ **Stripe Idempotency-Keys auf Refunds + PaymentIntents (2026-04-29)** — Round-2-Security-Audit: ohne Idempotency-Key kann ein Network-Retry oder Tap-Spam einen 2. Stripe-Charge oder 2. Refund triggern. Stripe-API ist auf der Server-side stateless ohne Key — sie verlässt sich auf den Caller, dass derselbe Operation-Intent identisch aufgerufen wird.
    - **`stripe.refunds.create`** in `respondToRefund` (Buyer akzeptiert Seller-Proposal) → `idempotencyKey: \`refund-respond-${orderId}-${refundPercent}\``.
    - **`stripe.refunds.create`** in `adminResolveDispute` (Tie-Breaker) → `idempotencyKey: \`refund-admin-${orderId}-${refundPercent}\``. Unterschiedliche Pfad-Prefixes damit zwei Pfade nicht versehentlich kollidieren wenn beide für dieselbe Order aufgerufen werden (sehr unwahrscheinlich, aber sauber).
    - **`stripe.paymentIntents.create`** in `createPaymentIntent` (Single-Seller-Buy) → `idempotencyKey: \`pi-create-${orderId}\``. orderId ist server-generiert (`orderRef.id`, Firestore-Auto-ID), unique pro Order.
    - **`stripe.paymentIntents.create`** in `processMultiSellerCart` (Multi-Seller-Group-Charges) → identisch `pi-create-${orderId}` pro Group (jede Group hat eigenen orderId).
    - **`stripe.paymentIntents.cancel/capture`**: Stripe-side bereits idempotent (cancel von cancelled = no-op, capture von captured = unchanged) → kein Key nötig.
    - **Stripe-API-Verhalten:** bei wiederholtem Call mit identischem Idempotency-Key innerhalb 24h returnt Stripe das ursprüngliche Result, kreiert nichts Neues. Nach 24h kann der Key reused werden (für unsere Order-IDs irrelevant — Order ist dann längst "resolved" oder "paid").

95. ✅ **Bearer-Secret auf 8 manuellen `onRequest`-Endpoints (2026-04-29)** — Round-2-Security-Audit: alle manuellen HTTP-Endpoints (`fetchPricesManual`, `checkNewTournamentDecksManual`, `checkNewUNLCardsManual`, `migratePlayerProfiles`, `migrateCreatedAt`, `discoverTournamentsFromRiotManual`, `backfillTournamentsFromRiot`, `discoverTournamentsFromMobalyticsManual`) waren by-default public-callable (onRequest hat keine Auto-Auth). DoS + Quota-Burn-Vektor: jeder mit der URL (steht im JS-Bundle, trivial via `strings`/Network-Inspector zu finden) konnte:
    - `fetchPricesManual` 1000× spammen → CF-Compute-Quota burn (€)
    - `discoverTournamentsFromRiotManual` spammen → Riot-API-Rate-Limit-Ban (legitimer Cron würde dann auch nicht mehr funktionieren)
    - `migratePlayerProfiles` triggern → idempotent aber CPU+Firestore-Reads
    - `backfillTournamentsFromRiot` triggern → riesige Schreib-Operation
    - **Lösung:** `crypto`-Import an Top-of-File hochgezogen, neuer Helper `requireAdminSecret(req, res)` mit `crypto.timingSafeEqual` (Schutz gegen Timing-Side-Channel beim Secret-Compare). Jeder `onRequest`-Endpoint bekommt:
      - `secrets: ["ADMIN_TRIGGER_SECRET"]` in den Options
      - `if (!requireAdminSecret(req, res)) return;` als ersten Statement
    - **Stripe-Webhook bewusst NICHT geschützt:** dort ist die Stripe-Signature-Validation via `stripe.webhooks.constructEvent` die Auth — Bearer-Check würde Stripe-Webhook-Calls blockieren.
    - **Secret in Firebase:** `firebase functions:secrets:set ADMIN_TRIGGER_SECRET` mit `openssl rand -hex 32` generiertem 64-Zeichen-Hex. Secret muss in Bitwarden/1Password gesichert werden — Verlust = Migration-Endpoints temporarily not callable bis Re-Generate + Re-Deploy.
    - **Verifikation live:** `curl -o /dev/null -w "%{http_code}"` auf alle 8 Endpoints zeigt:
      - Ohne Bearer: HTTP 403
      - Mit falschem Bearer: HTTP 403
      - Mit richtigem Bearer: HTTP 200 (`migratePlayerProfiles` getestet, läuft die Migration durch wie erwartet)
    - **Pre-Launch-Blocker geschlossen.** App Check (#98/#99) ist die nächste Schicht für Defense-in-Depth.

94. ✅ **React Web-App Source archiviert + Repo-Cleanup (2026-04-29)** — Folge-Aktion zu #93. Entscheidung: Web war nie strategisch geplant, App-Store-only ist die einzige Distribution. Repository entrümpelt damit zukünftige Devs (oder ich selbst in 3 Monaten) nicht über totes React-Tooling stolpern.
    - **Archive-Branch:** `archive/web-app` lokal erstellt (Push folgt sobald GitHub-Auth gefixt ist), zeigt auf den letzten Master-Stand mit vollem React-Source. Reaktivierung jederzeit via `git checkout archive/web-app -- src/ public/ package.json …` möglich.
    - **Master-Cleanup-Commit (`3c4c1e3`, 59 files, -51641 LOC):**
      - Gelöscht: `src/`, `public/`, `index.html` (Vite-Entry), `package.json` + `package-lock.json`, `vite.config.js`, `postcss.config.js`, `tailwind.config.js`, `eslint.config.js`, `node_modules/`, lose Test-Files (`TEST_WRITE.md`, `check_legend_data.html`).
      - `dist/` aus `.gitignore` genommen → wird jetzt **manuell gepflegt** als Source-of-Truth für Firebase Hosting (kein Build-Step mehr). Inhalt: `index.html` (Mobile-Only Placeholder), `stripe-return.html`, `stripe-refresh.html`, plus 4 Icon-Dateien (apple-touch-icon, favicon-16/32, icon-192). Insgesamt 7 Files, ~265 KB.
      - Deploy-Pfad bleibt unverändert: `firebase deploy --only hosting:default` lädt dist/ → `https://riftr-10527.web.app`. Ohne `package.json` ist `npm run build` nicht mehr ausführbar — versehentliches Re-Deploy des alten React-Builds ist damit physisch unmöglich.
    - **Behalten (LIVE-Backend):** `functions/`, `firestore.rules`, `firestore.indexes.json`, `firebase.json`, `.firebaserc`, `scripts/` (Admin-/Migration-CLI-Scripts), Doku-MDs.
    - **Verifikation:** `git ls-files riftbound-tracker/` zeigt nur noch Backend + dist/. `ls riftbound-tracker/` ist sauber, kein React-Cruft mehr.

93. ✅ **Web-Version offline + Stripe-Return UX-Verbesserung (2026-04-29)** — Vorbereitung für Beta-Link-Versand: Distribution ist ab jetzt App-Store-only (iOS-TestFlight + Google-Play), keine Web-App mehr.
    - **Phase 1 — Web-App durch Mobile-Only-Placeholder ersetzen:** `riftbound-tracker/dist/index.html` durch minimale „Riftr is mobile-only"-Seite ersetzt (Card-Layout, Brand-Farben, CTA zu `getriftr.app`). Live unter `https://riftr-10527.web.app`. Verhindert dass Beta-Tester oder Reddit-User auf eine alte React-PWA stoßen, die mit den neuen Firestore-Rules + UI-Patterns nicht mehr kompatibel ist.
    - **Phase 2 — Marketing-Site Tracker-Link entfernt:** `riftr-landing/index.html` Z. 512 (`<div class="signin">Already have the app? <a href="riftr-10527.web.app">Sign in at …</a></div>`) raus. Auf `getriftr.app` gibt's jetzt nur noch App-Store-Buttons. CSS-Klasse `.signin` bleibt im Stylesheet, ist aber unbenutzt (Cleanup deferred, schadet nicht).
    - **Phase 3 — Stripe-Return-UX:** Vorher landete der User nach Stripe-Connect-Onboarding auf `https://getriftr.app` (Marketing-Page) ohne jeden Kontext, dass das Setup geklappt hat. Cloud-Functions `RETURN_BASE` von `https://getriftr.app` auf `https://riftr-10527.web.app` umgestellt — die existierenden `/stripe-return` und `/stripe-refresh` Rewrites zeigen jetzt eine dedizierte „Payout Setup Complete"-Card bzw. „Link Expired"-Card. Beide self-contained (Inline-CSS, keine externen Assets). Affected CFs: `createStripeAccount`, `createStripeAccountLink`. Deployed.
    - **Verifikation live:** `getriftr.app` (kein Tracker-Link), `riftr-10527.web.app` (Mobile-Only Placeholder), `riftr-10527.web.app/stripe-return` (Setup-Complete-Card) — alle drei kontrolliert via curl.
    - **Folge-Action:** #94 (Repo-Cleanup React-Source archivieren).

91. ✅ **Schema-Migration PII (s.o. #92, 2026-04-29)** — Erledigt im selben Sprint. Beide Docs enthalten aktuell PII die mit `allow read: if isAuth()` jedem auth User offen liegt:
    - `profile`: street, city, zip, realizedGains, totalCostBasisSold (kumulative finanzielle Aggregate)
    - `sellerProfile`: email, address (vollstaendige Strasse/Stadt/ZIP), totalRevenue (Geschaeftsumsatz), strikes, suspended
    - **DSGVO-relevant**, MUSS vor Live-Schaltung gefixt sein.
    - Loesungs-Pfad: existing `playerProfiles`-Mirror (bereits da fuer displayName/avatar/country) um Public-Stats erweitern (`rating`, `reviewCount`, `totalSales`, `memberSince`). Sensible Felder in neue private Subcollection `users/{uid}/private/...` verschieben (rules: owner-only). App-Code: `ProfileService.fetchProfiles()` (Z. 88+) und `social_screen.dart::_buildAuthorProfile()` (Z. 1300) auf `playerProfiles`-Mirror umstellen statt direkt `data/profile` und `data/sellerProfile` zu lesen. CF-Trigger der bei sellerProfile-Updates die Public-Stats in `playerProfiles` syncht (bei `submitReview`, `confirmDelivery` schon vorhanden, muss nur erweitert werden).
    - Aufwand: ~2-3h (Schema + Code + CF-Trigger + Tests).

89. ✅ **iOS Log-Spam: ML-Kit App-Groups-Warnings (2026-04-29)** — Im Xcode-Console-Log spammten beim Scanner-Start drei Warnings repeated:
    - `MLKITx_SRLRegistry: No binding was found for CCTPolicyVending_API`
    - `container_create_or_lookup_app_group_path: client is not entitled`
    - `MLKITx_GIPPseudonymousIDStore: Shared App Groups unavailable`
    Root-Cause: Google ML Kit will einen App-Group-Container fuer CCT-Telemetry + Pseudonymous-ID-Sharing zwischen ML-Kit-Komponenten nutzen, findet keinen, faellt zurueck und log-spamt. Capability `com.apple.security.application-groups` mit `group.com.riftr.riftrFlutter` zu `Runner.entitlements` hinzugefuegt. Mit Automatic-Signing (Team `HM4NH6RNN3`) registriert Xcode die Group beim naechsten Build automatisch im Apple Developer Portal — kein manueller Portal-Schritt noetig. Function bleibt unveraendert (ML Kit nutzt App Groups nur fuer interne Telemetry-Storage, kein User-Visible-Verhalten).

88. ✅ **Scanner: doppelter Scan derselben Karte wurde nach Overview→Back zu 1 Eintrag mit ×2 (2026-04-29)** — User-Bug-Report: 2× Sneaky Deckhand gescannt → 2 Thumbnails im Scanner-Bottom-Strip. „Overview" tappen + Drag-to-Dismiss zurueck → Scanner zeigte plötzlich nur 1 Thumbnail mit „×2". Root-Cause: `scan_results_screen.dart::initState()` (Z. 106-123) hat eine Merge-Logic die Eintraege per `cardId_isFoil` Key zusammenfasst, plus `_entriesToReturn()` baute daraus 1 ScannedCardEntry mit `quantity=2`. Der Scanner-Pop-Handler ersetzte seine Liste mit dem gemergten Eintrag → 2 separate Scans wurden zu 1 mit Counter. **Hybrid-Fix (zweite Iteration nach User-Klarstellung):** Merge im Result-Screen behalten (sauberere Display-Uebersicht bei vielen Scans), aber `_entriesToReturn()` faltet die Display-Quantity wieder in Einzeln-Entries auseinander (ein `_ResultEntry` mit qty=N → N `ScannedCardEntry`-Objekte mit jeweils qty=1). Resultat: Result-Screen zeigt 1 Zeile mit ×2, Scanner-Bottom-Strip nach Pop zeigt wieder 2 separate Thumbnails. Wenn User Quantity manuell auf 5 hochzaehlt → 5 Einzeln-Entries kommen zurueck. Wenn auf 0 runterzieht → Karte komplett weg.

87. ✅ **NavBar Tracker-Label wrappt auf iPhone 13 mini (2026-04-29)** — Beta-Tester (User's Frau, iPhone 13 mini) berichtete: Tracker-Tab-Icon leicht nach oben verschoben, „r" von „Tracker" auf 2. Zeile darunter. Root-Cause: 7 Tabs in Row mit `Expanded(flex: 4)` — auf 375pt Screen-Breite kriegt jede Cell ~47pt. „Tracker" (7 Zeichen, laengstes Label) ueberschreitet das knapp → Text wrappt auf 2 Zeilen → Column waechst → Icon-Position rutscht hoch. Fix: jedes Label in `FittedBox(fit: BoxFit.scaleDown)` + `maxLines: 1` + `softWrap: false`. Auf grossen Screens bleibt Text Original-Groesse; auf engen schrumpft er minimal (5-10%) statt zu wrappen. Pattern auf alle 7 Tab-Labels angewendet damit konsistente Schrift-Hoehe garantiert ist.

86. ✅ **Scanner triggert nicht auf iPhone 13 mini — Card-Present-Classifier als Hard-Gate (2026-04-29)** — Beta-Tester (User's Frau, iPhone 13 mini) berichtete: Scanner zeigt Camera-Preview + Overlay vollstaendig, loest aber nie aus. Root-Cause-Analyse: in `_onFrame()` State-Machine `waiting`-Branch war `_lastCardPresentProb < 0.55` ein **Hard-Gate** der OCR komplett blockierte. Zwei Failure-Modes auf manchen Devices:
    - **Modell laedt nicht** (Asset-Bundle-Issue) → `isReady=false` → `prob=null` → `_lastCardPresentProb=0.0` → permanent stuck
    - **Modell laedt, aber Sensor-Charakteristik anders** (HDR/Belichtung iPhone 13 mini vs Trainings-Set) → consistent low prob → permanent stuck
    Fix: 3 Fallbacks im waiting-Branch:
    1. **Classifier-not-ready** → Gate komplett ueberspringen, OCR direkt
    2. **Stuck-in-waiting > ~3s** (`_waitingStuckFrames >= 30`) → forciere OCR-Versuch trotz Classifier-low-prob
    3. **Diagnose-Log** alle 30 Frames (`print` statt `debugPrint` damit auch in Release-Build via Xcode Console sichtbar) — User kann Bug-Reports einreichen, Dev kann sehen ob Classifier laedt + welche probs er liefert.
    Counter wird in `_setState` zurueckgesetzt wenn waiting verlassen wird (Re-Entry baut wieder von 0 auf). Classifier bleibt CPU-Optimierung wie urspruenglich, aber **darf nie mehr als Hard-Gate fungieren**.

82. ✅ **„Tracking-Bug" in foil_only_filter Szenario war false-positive (2026-04-29)** — Bei genauer Analyse stellte sich heraus: kein Optimizer-Bug, sondern ein Blindfleck in der Stress-Test-Coverage-Logik. Der Optimizer hat **drei** Buckets, nicht zwei: `plan.sellerPlans` (allokiert) + `plan.unavailable` (definitiv nicht verfuegbar) + `plan.alternativeCards` (Soft-Mismatch, User-opt-in). Bei strict foilPreference=foil rutschen Karten wo es nur non-foil-Stock gibt absichtlich in `alternativeCards` — der User sieht im UI eine „Alternative Cards"-Section mit Opt-in-Toggles („verfuegbar als non-foil, willst du?"). Stress-Test hat die Bucket nicht erkannt → flaggte 3 Copies als „silently dropped". Fix: `altSet` zur Coverage-Accounting hinzugefuegt. Saubere Architektur, kein Code-Aenderung im Optimizer noetig. Stress-Suite jetzt 15/15 Tests gruen, 0 Warnings.

83. ✅ **Optimizer Performance-Cliff gefixt (2026-04-29)** — Stress-Suite hatte O(N^4) Wachstum entdeckt (avg exp 4.20). Profilen mit Stopwatches im Optimizer ergab: **Pareto-Sweep ist 98% der Runtime** — bei whale_collector (mainK=75) liefen 74 Re-Runs mit ~500ms each für gerade mal 6 visible Pareto-Plans nach _filterPareto-Dedupe. Pure Verschwendung.
    - **Fix 1 — Pareto-Sweep auf 2 strategische Probes:** statt jedes k in [1, mainSellerCount-1] zu generieren, nur k=1 (Fewest fuer kleine Carts) + k=mainK/2 (Mid-Punkt fuer große Carts). Plus mainPlan = Balanced + Cheapest = max 4 Candidates. _filterPareto dedupliziert auf 1-3 visible Strip-Optionen.
    - **Fix 2 — Cost-Tiebreaker in `_bestPlanWithMaxSellers` Phase 1:** vorher Coverage-Greedy ohne Tiebreaker → bei 2 Sellern mit gleicher Coverage wurde der erste in Iteration gepickt, nicht der guenstigere. Jetzt bei Tie: bevorzuge Seller mit niedrigerem Sum-of-cheapest-listing-prices.
    - **Speedup gemessen via Stress-Suite:**
      - whale_collector: 37.5s → **1.2s (30×)**
      - mega_market: 6.2s → **530ms (12×)**
      - killer_scale: 280s → **7.7s (36×)**
      - scale_stress: 1.2s → 119ms (10×)
      - typical-deck: 92ms → 33ms (2.8×)
    - **Plan-Costs alle exakt gleich oder besser** (small_abundant sogar guenstiger weil _pickBalanced jetzt direkter zum Cheapest greift bei kleinen Plans). Keine Regression in Optimizer-Qualitaet.
    - **Scaling-Exponent: 4.20 → 2.99** (kubisch, akzeptabel fuer NP-hartes Set-Cover-Problem). Stress-Test-Limit auf 3.5 angehoben.
    - Bleibt UX-noticeable bei 300k+ Listings (killer_scale 7.7s) — fuer naechste Wachstumsstufe braucht's Greedy-mit-Top-K-Heuristik (#83b im Backlog parken).

80. ✅ **ListingTile Quantity-Badge auf Cart-Button (2026-04-29)** — Beta-Tester-Screenshot zeigte `×3€2.55 Letter`-Overlap im Listings-Strip: das inline `×N` Quantity-Indikator in der Seller-Info-Row kollidierte horizontal mit dem Versand-Preis aus der rechten Price-Spalte sobald Seller-Name + Rating + Sales + Condition zusammen genug Breite zogen. Erster Versuch (3-Zeilen-Layout-Refactor) sah „kacke" aus mit inkonsistentem Zeilenabstand → komplett rueckgaengig. Finale Loesung: alte 2-Block-Optik komplett restored, `×N`-Indikator aus der Rating-Row entfernt und stattdessen als kleines Stock-Count-Badge auf dem Cart-Button positioniert (`Stack` mit `Positioned(top:-4, right:-4)`, surface-bg + amber500-border, micro-text, nur sichtbar bei `availableQty > 1`). Zwei Birds, ein Stein: Overlap geloest weil Quantity nicht mehr in der Inline-Row, und semantische Verknuepfung zum Cart („das fuegst du eh dort hinzu").

79. ✅ **Smart-Cart Review-Sheet Service-Fee-Row (2026-04-28)** — User-Audit ergab dass die Cost-Summary-Card im Smart-Cart-Review-Sheet (Best-Picks-Screen) nur Cards/Shipping/Total zeigte — kein Service-Fee-Row. `grandTotal` selbst war fee-aware (kommt aus `BuyPlan.grandTotal` = `cards + shipping + serviceFee`), aber die Differenz war fuer den User unsichtbar/unerklaert (`Cards + Shipping ≠ Total` rechnet er nach und denkt Bug). Inkonsistent zum Cart-Screen Grand-Total-Card der die Zeile schon hatte. Fix: `_displayBreakdown` um `serviceFee` erweitert, `_CostSummaryCard` Widget erweitert um `serviceFee` + `isMultiSeller`-Param, neuer `_ServiceFeeRow`-Widget mit info-Icon und Tap-Tooltip (gleicher Toast-Wording wie Cart-Screen). Optimizer-Logic + savings-Berechnung waren schon korrekt — pure UI-Polish.

78. ✅ **Card-Scanner Debug-Overlay Admin-Gating (2026-04-28)** — Scanner zeigte ALLEN Usern bunte Debug-UI: OCR-Boxen, FPS-Counter, „PROC"-Stats, Trainingsframe-POS/NEG-Buttons (rot/gruen 80×80 px), CardPresent-Probability — total verwirrend fuer Beta-Tester. Compile-time `_debugMode = true` war hardcodiert (sonst kann ich on-device gar nicht debuggen). Fix: `_isAdmin`-State async aus `getIdTokenResult().claims['admin']` ueber den existing Pattern aus `social_screen._checkAdminClaim()`. Alle 4 visible-UI-Guards in `build()` (Training-Buttons, Manual-POS, Manual-NEG, Debug-Overlay) auf `_debugMode && _isAdmin` umgestellt. `_debugMode`-Konstante bleibt, damit Production-Builds die Debug-UI auch bei Admin-Login per einzelnem Flag killen kann. Console-`debugPrint`-Logs unveraendert (sehen User nicht).

77. ✅ **Card-Scanner Camera-Init Error-Handling (2026-04-28)** — Beta-Tester gemeldet: Scanner „funktioniert nicht". Root-Cause-Diagnose ergab dass der Scanner bei jedem Camera-Init-Fehler einen unendlichen Spinner zeigte, ohne Error-Message, ohne Action-Buttons. Drei zusammenwirkende Bugs:
    - **Silent catch in `_initCamera()`** — `catch (e) { debugPrint(...) }` ohne UI-Update. `_isInitialized` blieb false bei jedem Fehler.
    - **Binary build()** — nur `if (_isInitialized) CameraPreview else CircularProgressIndicator`, kein Error-Branch.
    - **Lifecycle-Guard verkehrt** — `didChangeAppLifecycleState` hatte als allerstes `if (_controller == null || !_controller!.value.isInitialized) return;`. Sobald die initiale Init failte, war der Guard immer true → Re-Init nach Settings-Grant + App-Resume war unmoeglich, User musste die App komplett neustarten.
    Fix: neuer `_CameraInitError`-Enum (permissionDenied / noCamera / other) als State, `_initCamera()` setzt ihn differenziert per `CameraException.code`-Inspection (`AccessDenied` / `AccessRestricted` / `permission` → permissionDenied). Build-Method 3-Wege-Switch: Error-State → eigenes `_buildErrorScaffold()` mit Icon + Message + „Open Settings" (iOS: `app-settings:` URI via url_launcher, Android: `package:com.riftr.app`) + „Try again" Buttons. Lifecycle-Guard umgedreht: bei Resume immer `_initCamera()` aufrufen, dispose nur wenn aktiv. Effekt: User kriegt klare Fehlermeldung, kann direkt zu den Settings springen, Permission gewaehren, und beim Resume automatisch wieder im Scanner landen ohne App-Restart. Keine neuen Packages noetig (`url_launcher` war schon Dep).

76. ✅ **Deck-Editor X-Buttons in die Karten-Ecke (2026-04-28)** — Legend- und Battlefield-Remove-Buttons im Deck-Editor sassen visuell ~12 px vom Karten-Eck entfernt weil das `SizedBox(44×44)`-Touch-Target ein zentriertes inneres `Container(28..30 px)` umschloss → effektiver Inset = 4 (Positioned) + 8 (Center-Padding) = 12 px. Beide auf `Align(alignment: Alignment.topRight)` umgestellt — sichtbarer Badge sitzt jetzt in der Karten-Ecke mit nur 4 px Inset. Touch-Zone bleibt voll 44×44 (Apple HIG). Bewusst kein negativer Offset weil die 3 nebeneinander stehenden Battlefield-Slots sonst ueberlappen wuerden.

75. ✅ **Battlefield-Picker Multi-Select Bug-Fix (2026-04-28)** — User-Feedback: Battlefields im Deck-Editor mussten einzeln ausgewaehlt werden (Modal pro Battlefield oeffnen + schliessen). Root-Cause: `bfSlotIndex`-Param wurde dual-purpose fuer ADD- und REPLACE-Use-Cases verwendet. Beim `+`-Button-Tap (Add-Use-Case) wurde `bfSlotIndex: bfs.length` mitgegeben — das funktionierte fuer den ersten Tap (length 0, slotIdx 0, `0 < 0` false → ADD), aber sobald die erste Karte hinzugefuegt war (length 1), kippte die Bedingung `slotIdx < _localBfIds.length` zu true und der naechste Tap landete im REPLACE-Branch. Pro Modal-Session konnte effektiv nur eine Karte hinzugefuegt werden. Fix: in `decks_screen.dart` Zeile 3528 `bfSlotIndex` beim `+`-Button weggelassen (= null → permanent ADD-Modus). Tap auf existierenden Slot bleibt REPLACE-Modus mit explizitem bfSlotIndex. Modal-UX dahinter unveraendert: Counter zeigt 0/3 → 1/3 → 2/3 → 3/3, gruener Confirm-FAB erscheint sobald Aenderungen vorhanden sind.

73. ✅ **Guardian Angel SFDX Promo komplettiert (2026-04-28)** — Beta-Tester gemeldet: SFDX #51 fehlte. Cardmarket hatte 2 Eintraege (cmId 883249 €3.37 + cmId 883250 €30.91 — analog zum Edge-of-Night-Pattern: regular Promo + Champion-Variante). `rarity_variants.json` ergaenzt um `"Guardian Angel|SFDX": ["Rare"]` damit der CF-Variant-Index korrekt zuordnet (1. Cardmarket-Produkt = Rare, 2. faellt auf Showcase). cards.json: 2 neue Entries — „Guardian Angel (SFDX)" Rare + „Guardian Angel (SFDX Champion)" Showcase, beide mit display_name + riftbound_id-Konvention von Edge-of-Night uebernommen. CF deployed + manual fetch verifiziert: cmId 883249 = SFDX/Rare/€3.37 (vi=0) + cmId 883250 = SFDX/Showcase/€30.91 (vi=0) → Frontend `MarketService.name|set|rarity|vi`-Lookup matcht beide zu den richtigen cards.json-UUIDs. Bilder gesourced: Standard von Cardmarket (`sfdx_guardian-angel.webp`, 590 KB), Champion-Variante von dotgg.gg-CDN (`sfdx_guardian-angel-champion.webp`, 57 KB) — beide unter `assets/ognx_images/` abgelegt, cards.json image-paths von `.jpg` auf `.webp` korrigiert, `_ognx_stats.missing_hq` Tracker geleert.

72. ✅ **UNL-Set komplettiert (2026-04-28)** — Beta-Tester meldete fehlende UNL-Karten. Zwei separate Pipelines analysiert:
    - **Cardmarket-Backend (`functions/index.js` EXP_MAP):** UNL fehlte komplett im Mapping, Cardmarket-Expansion `6491` (275 Produkte, sample „Arena Kingpin") wurde seit dem 23.04.2026 ignoriert. Hinzugefuegt → deployed → manueller Run zeigt: 4 von 275 UNL-Produkten haben Preise (Rest pre-release, UNL released 2026-05-08, kommt automatisch ab Verkaufsstart).
    - **Riftcodex-Frontend (`assets/cards.json`):** API hatte 280 UNL-Karten, cards.json nur 246 (Stand 2026-03-28). 35 Diff-Kandidaten, 1 Konflikt (Moonfall cn=198 — selbe riftbound_id mit anderem hash-id, war Schema-Variante kein neues Card), 34 echte neue Karten hinzugefuegt mit Schema-Match (display_name=name, public_code=null wie bei den existing 246). Image-URLs auf demselben Riot-CMS, sofort renderbar. cards.json: 1067 → 1101 Karten. Promo-Sets (OGNX/SFDX/OGSX) und Metadata-Block unveraendert.
    - **Offen (Schritt 3, deferred):** Riftcodex API liefert auch 3 neue Sets ausserhalb cards.json — OPP (107 Karten), PR (12), JDG (1). Cardmarket-IDs noch nicht ermittelt. Wird separat angegangen.

71. ✅ **Tracker Deck-Picker: Set-Badges statt Main/BF/Side (2026-04-28)** — Im Tracker zeigte der Deck-Picker pro Deck drei generische Completion-Badges („Main 40/40", „BF 3/3", „Side 8/8"). Ersetzt durch identische Set-Badges (UNL/SFD/OGN/OGS, Gold-Style) wie im Decks-Tab → My Decks. Logik in neue shared Widget `lib/widgets/deck/deck_set_badges.dart` ausgelagert (Single-Source-of-Truth fuer Set-Order + Promo-Set-Filter). decks_screen `_buildSetBadgesOnly` entfernt, `_buildSetBadgesAndStats` nutzt das neue Widget intern. Konstanten `_setOrder` + `_promoSets` aus decks_screen geloescht (jetzt in DeckSetBadges).

70. ✅ **Cart-FAB im Market-Tab kontext-aware (2026-04-28)** — Cart-FAB blendet sich jetzt in „MY LISTINGS" und „ORDERS" aus. Im Listings-View verkauft der User, im Orders-View prueft er bestehende Kaeufe — der Cart ist dort nicht kontextrelevant und stoert nur. FAB bleibt sichtbar in Discover/Portfolio/Search-Views (wo der User shoppt) sowie im Cart-Detail durch andere Buttons abgedeckt.

68. ✅ **Outlier-Guards deployed + Display-Anchoring (2026-04-28)** — SFD Calm Rune Common (cmId 871894) zeigte +340% c24-Gain durch eine Single-Listing-Anomalie auf Cardmarket. Root-Cause-Analyse: (a) spikeGuard + movementGuard waren seit gestern lokal vorhanden aber **nicht deployed** — 5000 Zeilen Cron-Logs hatten 0 Treffer fuer `🚨`. (b) Selbst nach Deploy blieb c24=340% weil spikeGuard nur `historyWrites` korrigierte, nicht `prices[cmId].pF/pNf` → Display=0.44, mergedHistory=0.11, c24 = (0.44-0.10)/0.10 = +340% Phantom. Fix: spikeGuard + movementGuard beide clampen jetzt `prices[cmId]` synchron mit der korrigierten History. Cleanup: Bad Point aus `market_history/871894.pointsNf` entfernt, Overview gepatcht (pNf=0.10, c24=0). Deploy verifiziert: SFD Calm c24=10% (von 0.10→0.11 = sane), kein Eintrag mehr in topGainers. CLAUDE.md → "Outlier-Guards" Section hinzugefuegt damit der Anchoring-Pattern fuer zukuenftige Aenderungen dokumentiert ist.

67. ✅ **Cart-Layout cleanup (2026-04-28)** — Drei Probleme im Cart-Tab gefixt:
    - „X cards from X sellers" Subtitle unterhalb des CART-Headers entfernt — war redundant zur Zeile „N orders · M cards" oben in der Grand-Total-Karte.
    - „CART"-Header (GoldOrnamentHeader) ist unveraendert konsistent mit allen anderen Tab-Headern (MARKET VALUE, MY LISTINGS, ORDERS, DISCOVER, REVIEWS, KNOWLEDGE IS POWER, KNOW YOUR STRENGTH, ADMIN — DISPUTES).
    - Bottom-Spacer im Scroll-Content erhoeht: vorher `AppSpacing.xl` (20dp) → jetzt `22 + 56 + safeAreaBottom + 24` dp. Grund: fixierter Checkout-Button im Stack (Positioned `bottom: 22`, Hoehe ~56dp) verdeckte sonst die letzten ~80–110 dp der Grand-Total-Karte beim Scrollen ans Ende.

---

## DEFERRED — Scanner Edit-Sheet: Condition-Picker

90. ⏳ **Scanner Edit-Sheet: Condition-Picker hinzufuegen** — Aktuell kann der User beim Tap auf ein Thumbnail im Scanner-Bottom-Strip (`scanner_screen.dart` Z. 2059+) zwischen Karten-Varianten waehlen + Foil-Toggle setzen, aber NICHT die Condition. Das geht erst im Result-Screen, was unintuitiv ist wenn der User schon im Scanner mit dem Karten-Stapel hantiert.
    - **Loesungs-Pfad:**
      1. `ScannedCardEntry` (Z. 33-66) ergaenzen um `CardCondition condition = CardCondition.NM` Default-NM Field
      2. Edit-Sheet (Z. 2120-2186) zwischen Variants-Liste und Foil-Toggle einen Condition-Picker einbauen — analog zum `scan_results_screen.dart`-Pattern (Pills MT/NM/EX/GD/LP/PL/PO oder dropdown). Zentral als shared Widget extrahieren damit beide Screens dasselbe nutzen.
      3. `scan_results_screen.dart::initState()` muss die Condition vom ScannedCardEntry uebernehmen statt blind NM-Default zu setzen
      4. `_entriesToReturn()` muss die Condition zurueckschreiben (aktuell verliert sie sich beim Pop)
      5. **Optional:** Im Scanner-Bottom-Strip kleines Condition-Badge auf dem Thumbnail wenn nicht-NM (z.B. „LP"-Pill in der Ecke), damit der User auf einen Blick sieht welche seine letzten Scans haben.
    - **Default**: `CardCondition.NM` weil 80%+ der gescannten Karten NM sind.
    - **Aufwand:** ~1h Code + UI-Polish + Konsistenz-Check zwischen Scanner-Sheet und Result-Screen.

## DEFERRED — Smart-Cart Opt-in Re-Optimize

84. ⏳ **Smart-Cart: Re-Optimize on Alternative-Card Opt-in (Variante C)** — Aktuell pickt Smart Cart bei Opt-in einer Alternative (z.B. „Karte X als non-foil") naiv den **billigsten Listing** aus `offerings.first` und merged es lokal in den Plan. Problem: ignoriert den ganzen Plan-Kontext.
    - **Beispiel:** User wollte foil. Karte X gibt's nur non-foil bei A (€3, schon im Plan), C (€2.50, neuer Seller) oder D (€2.80, neuer Seller). D hat aber AUCH die 3 Karten von Verkaeufer B im Plan — etwas teurer, aber B koennte komplett aus dem Plan raus. Naive-Pick: C (€2.50). Optimal: D + B-Migration → -€0.20 trotz teurerer Karten weil B-Versand + Multi-Seller-Aufschlag wegfaellt.
    - **Loesungs-Pfad:** Beim Opt-in-Toggle den `MissingCardsOptimizer.computeBestPlan()` neu rufen, aber mit erweitertem `listingsFetcher` der fuer die opt-in Karten zusaetzlich die non-foil-/cross-rarity-Listings als eligible markiert. Optimizer findet dann global-optimalen Plan inkl. Migration-Moeglichkeiten.
    - **UX:** kurzer „Computing..."-Spinner beim Toggle (30ms typical-deck, 600ms whale, 2.4s killer-scale).
    - **Aufwand:** ~1-2h Code + Stress-Suite-Erweiterung fuer Opt-in-Szenarien.
    - **Variante A** (existing-seller-preferred Pick) und **Variante B** (effective-cost Pick) waeren billiger zu bauen, loesen aber den Migration-Fall nicht. Daher direkt zu Variante C.

85. ⏳ **Smart-Cart: Condition-Mismatch als Soft-Mismatch (Pass 2.5)** — Aktuell faellt eine Karte direkt in `unavailable` wenn user `minCondition: NM` strict will und nur LP/PL Listings verfuegbar sind. Foil-Mismatches gehen aber als Soft-Mismatch in `alternativeCards` (Opt-in). Asymmetrie. Loesung: 4. AlternativeReason-Enum-Wert (`worseCondition`) + Pass 2.5 in `_collect()` der bei keinem strict-condition Match die Listings mit relaxed-condition als alternativeCards anbietet. UX-Win fuer Sammler die NM bevorzugen aber LP akzeptieren wuerden wenn die Alternative „nicht verfuegbar" waere.

## DEFERRED — Schritt 3: OPP/PR/JDG Promo-Sets

74. ⚠️ **Neue Promo-Sets aus Riftcodex API integrieren (deferred 2026-04-28)** — Riftcodex API hat 3 Sets die in cards.json fehlen:
    - **PR (12 Karten)** — „Riftbound Promotional Cards", allgemeine Launch-/Magazin-Promos
    - **JDG (1 Karte)** — „Riftbound Judge Promotional Cards", aktuell nur Heimerdinger – Inventor
    - **OPP (107 Karten)** — „Riftbound Organized Play Promotional Cards", Riot OP-Programm (Store-Championships, Game Days). Enthaelt Metal-Variants und ist 3 rid-Suffix-Wellen (-298 = OPP-only neueste, -221 = SFD-Aera Reprints, -024 = OGN-Aera Metal-Variants).
    - **Architektur-Frage:** OPP ueberlappt mit unserem hand-kuratierten OGNX/SFDX/OGSX-Schema. 47 von 107 OPP-Karten haben denselben name+collector_number wie existing cards.json-Eintraege (OGNX/SFDX-Doubletten oder Base-Set-Reprints). Zwei Pfade:
      - **Pfad A (additiv):** OPP komplett mit neuen UUIDs hinzufuegen, OGNX/SFDX/OGSX bleiben parallel (datenverlust-frei, aber Doubletten z.B. „World Atlas" 4×: SFD/SFDX/OPP)
      - **Pfad B (konsolidieren):** Pruefen ob OPP-Eintraege identisch zu existing OGNX/SFDX-Promos sind, ggf. konsolidieren — riskanter
    - **Cardmarket-IDs:** Die 3 Sets haben noch kein EXP_MAP-Mapping. PR/JDG/OPP cmIds muessten ueber Bundle-Inspection oder Spot-Check ermittelt werden.
    - **Empfohlene Reihenfolge wenn picked-up:** PR + JDG first (13 Karten, no conflicts) → dann OPP mit Pfad-Entscheidung.

## OFFENE ENTSCHEIDUNGEN

| # | Frage | Optionen |
|---|-------|----------|
| 1 | Cards + Collection zusammenlegen? | Getrennt lassen vs. Toggle (Alle/Meine/Fehlend) |
| 2 | Card Detail View + Kauf in einem Screen? | Alles in einem vs. Button zum Market |
| 3 | Freunde adden über was? | Username vs. E-Mail vs. Nickname |
| 4 | Wunschliste öffentlich? | Ja mit Toggle vs. Immer privat |
| 5 | YouTube Embeds rechtlich ok? | Prüfen |
| 6 | Store Events anzeigen erlaubt? | UVS kontaktieren |
| 7 | Messaging zwischen Käufer/Verkäufer? | Ja minimal vs. Nein |
| 8 | Bid & Ask System? | Jetzt vs. Später vs. Nie |

---

## PRIORITÄTEN-REIHENFOLGE

1. Portfolio Chart Bug fixen (plottet v statt p) — #1
2. Intelligenter Deck-Kauf — #9
3. Push Deep Linking — #10
4. Order-Detail Screen überarbeiten — #5
5. Collection-Suche fixen — #12
6. Scanner implementieren — #30
7. Onboarding Screen — #42
8. Social Features — #31–34
9. UI Bugs & Kosmetik — #45–53

---

**Legende:** ✅ Erledigt | ⚠️ Teilweise/In Arbeit | ❌ Offen | ❓ Muss getestet/entschieden werden

### Smart-Cart-Detail-Architektur

63. ✅ **Market-Tab-Card-Detail (§7.2) als standalone Route extrahieren** — Extrahiert in `lib/widgets/market/market_card_detail_route.dart`. Vollständige §7.2-UI (image, price, range-selector, chart, overview-card, listings, sticky Buy/Sell CTAs) mit eigenem State (`_selectedRange`, `_detailShowFoil`, `_loadingHistory`, `_card`-snapshot). Sheet-Actions (`onCheckout`, `onAddToCart`, `onSell`) als Callbacks die zu den jetzt public `_MarketScreenState.openCheckoutSheet/addToCart/openSellSheetById` delegieren — Cart/Demo/Wallet-State bleibt mit Market-Tab synchron. Push via `Navigator.of(ctx, rootNavigator: true)` aus DeckShoppingSheet. Fertig 2026-04-24.

64. ❌ **SmartCart art-toggle peek caching** — `MissingCardsOptimizer.computeBestPlan` läuft den vollen Optimizer 2× (einmal mit aktuellen Filtern, einmal mit geflipptem `acceptCheaperArt` für den `grandTotalIfArtToggled`-Hinweis). Pro Tap auf Smart Cart kostet das ~2× CPU. Quick-win-Optionen: (a) Skip-Pfad wenn `ctx.alternativeCards.isEmpty` AND `!filters.acceptCheaperArt` → flip kann nichts sparen. (b) Memo by hash(missingCards + filters + buyerCountry) für Re-Entry-Caching. (a) ist trivial, (b) braucht stabile Filter-Serialisierung. Aktuell läuft <1s und ist nicht User-spürbar — daher P3.

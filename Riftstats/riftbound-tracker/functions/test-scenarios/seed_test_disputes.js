// Test-Disputes Seeder fuer Discogs-UI- und Cron-Tests
// (zuletzt erweitert 2026-05-01 fuer KI-Anwalt-Wording-Pass-Items)
//
// Alle gesetzten Orders haben sellerIsCommercial=true, damit die
// Verkaeufer-Status-Badges, der Hinweis-Dialog (wrong_card/not_arrived)
// und der Widerrufsbelehrungs-Link in der App sichtbar werden.
//
// Erstellt 5 Test-Disputes + 1 Shipped-Order ohne Dispute:
//
//   1. „Frischer Open Dispute" (disputedAt: 2h ago, disputeStatus: open)
//      → Admin-Disputes-Screen zeigt 3-Button-UI (Reject / Pause / Ban)
//      → Vor Auto-Resolve-Frist von 7d, also stabil testbar
//
//   2. „Seller Proposed Refund" (disputedAt: 3h ago, disputeStatus: sellerProposed)
//      → Frontend (Buyer) zeigt „accept/reject"-Sheet
//      → Admin-Disputes-Screen zeigt Order auch (proposed-Badge)
//
//   3. „Alter Dispute" (disputedAt: 15d ago, disputeStatus: open)
//      → Buyer-Eskalations-Card auf Order-Detail-Screen sichtbar
//      → ACHTUNG: morgen 05:00 Berlin wuerde autoResolveSellerSilence
//        diesen auto-refunden. Bis dahin testbar.
//
//   4. „BuyerSilence Cron Test" (proposedAt: 8d ago, disputeStatus: sellerProposed)
//      → Cron-Test: devTriggerBuyerSilence muss diesen Eintrag von
//        sellerProposed → open flippen, disputeReopenedAt setzen,
//        proposedRefund-Felder loeschen.
//
//   5. „Tiebreaker Test" (disputedAt: 20d, disputeReopenedAt: 2d, disputeStatus: open)
//      → Cron-Test: devTriggerSellerSilence MUSS diesen Eintrag SKIPPEN,
//        weil disputeReopenedAt < 7d ist (Off-by-Cron-Schutz).
//
//   6. „Shipped Order ohne Dispute" (status: shipped, kein disputeStatus)
//      → UI-Test: Käufer kann manuell Reklamation eröffnen und mit
//        Reason "Wrong card received" den RefundPathChoiceSheet auslösen
//        (Item 3 Hinweis-Dialog). Auch der Widerrufsbelehrungs-Link
//        in der Order-Info-Section ist hier sichtbar (Item 4).
//
// Run:
//   node test-scenarios/seed_test_disputes.js                    (ohne UID, nur Admin-Test)
//   node test-scenarios/seed_test_disputes.js <DEINE_UID>         (mit UID, alle Tests)
//   node test-scenarios/seed_test_disputes.js --cleanup           (cleanup)

const path = require("path");

process.env.GOOGLE_APPLICATION_CREDENTIALS = path.join(
  process.env.HOME,
  ".config/firebase/eladiorubiohernandez_gmail_com_application_default_credentials.json",
);
process.env.GOOGLE_CLOUD_PROJECT = "riftr-10527";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "riftr-10527" });
const db = admin.firestore();
const APP_ID = "riftr-v1";

const TEST_SELLER_UID = "_test_seller_TEST-NEU";
const SEEDED_TAG = "_phase9TestDispute";

async function cleanup() {
  console.log("🧹 Cleanup: lösche alle _phase9TestDispute=true Docs ...");
  let total = 0;
  for (const col of ["orders", "listings"]) {
    const snap = await db.collection("artifacts").doc(APP_ID)
      .collection(col).where(SEEDED_TAG, "==", true).get();
    for (const doc of snap.docs) {
      await doc.ref.delete();
      total++;
    }
    console.log(`  ${col}: ${snap.size} gelöscht`);
  }
  console.log(`✓ Cleanup fertig: ${total} Docs entfernt.`);
  process.exit(0);
}

async function seedListing({ price, suffix }) {
  const ref = db.collection("artifacts").doc(APP_ID).collection("listings").doc();
  await ref.set({
    sellerId: TEST_SELLER_UID,
    sellerName: "Test Seller (Discogs-UI-Test)",
    sellerCountry: "DE",
    // Item 2 (KI-Anwalt-Wording-Pass): gewerblicher Verkaeufer fuer Badge-Test.
    sellerIsCommercial: true,
    cardId: `phase9_dispute_${suffix}`,
    cardName: `Phase9 Dispute Test Card (${suffix})`,
    price,
    quantity: 5,
    availableQty: 4,
    reservedQty: 1,
    condition: 0,
    isFoil: false,
    status: "reserved",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    [SEEDED_TAG]: true,
  });
  return ref.id;
}

async function seedOrder({
  listingId, buyerUid, buyerName,
  status, disputeStatus,
  hoursAgo, daysAgo,
  proposedRefundPercent, proposedDaysAgo,
  reopenedDaysAgo,
  suffix,
}) {
  const ref = db.collection("artifacts").doc(APP_ID).collection("orders").doc();
  const offsetMs = (daysAgo || 0) * 24 * 60 * 60 * 1000 + (hoursAgo || 0) * 60 * 60 * 1000;
  const disputedAt = new Date(Date.now() - offsetMs);
  const paidAt = new Date(Date.now() - offsetMs - 60 * 60 * 1000); // 1h vor Dispute

  const orderData = {
    buyerId: buyerUid,
    buyerName,
    sellerId: TEST_SELLER_UID,
    sellerName: "Test Seller (Discogs-UI-Test)",
    // Item 2 (KI-Anwalt-Wording-Pass): sellerIsCommercial=true Flag,
    // damit Verkaeufer-Status-Badge, Hinweis-Dialog und Widerrufs-
    // belehrungs-Link in der App sichtbar werden.
    sellerIsCommercial: true,
    // Item 5 (2026-05-01): Pflicht-Kontaktdaten fuer Verbraucher-Kaeufer
    // bei gewerblichen Verkaeufern.
    sellerEmail: "test-seller@example.com",
    sellerAddress: {
      name: "Test Seller GmbH",
      street: "Verkaeuferstrasse 42",
      city: "Hamburg",
      zip: "20095",
      country: "DE",
    },
    items: [{
      listingId,
      cardId: `phase9_dispute_${suffix}`,
      cardName: `Phase9 Dispute Test Card (${suffix})`,
      quantity: 1,
      price: 8.0,
    }],
    totalPaid: 9.74,
    serviceFeeCents: 49,
    buyerServiceFee: 0.49,
    sellerPayout: 7.55,
    paymentMethod: "stripe",
    status,
    disputeStatus,
    disputeReason: "Wrong card received",
    disputeReasonCode: "wrong_card",
    disputeDescription: "Test-Beschreibung: Karte sieht anders aus als beschrieben.",
    paidAt: admin.firestore.Timestamp.fromDate(paidAt),
    disputedAt: admin.firestore.Timestamp.fromDate(disputedAt),
    stripePaymentIntentId: `pi_phase9_disputeUI_${suffix}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    [SEEDED_TAG]: true,
  };

  if (proposedRefundPercent != null) {
    orderData.proposedRefundPercent = proposedRefundPercent;
    orderData.proposedRefundAmount = Math.round(orderData.totalPaid * proposedRefundPercent) / 100;
    // Wenn proposedDaysAgo gesetzt ist, Backdate fuer BuyerSilence-Cron-Test.
    if (proposedDaysAgo != null) {
      const proposedAt = new Date(Date.now() - proposedDaysAgo * 24 * 60 * 60 * 1000);
      orderData.proposedAt = admin.firestore.Timestamp.fromDate(proposedAt);
    } else {
      orderData.proposedAt = admin.firestore.FieldValue.serverTimestamp();
    }
  }

  // Tiebreaker-Test: disputeReopenedAt setzen
  if (reopenedDaysAgo != null) {
    const reopenedAt = new Date(Date.now() - reopenedDaysAgo * 24 * 60 * 60 * 1000);
    orderData.disputeReopenedAt = admin.firestore.Timestamp.fromDate(reopenedAt);
  }

  await ref.set(orderData);
  return ref.id;
}

// Seedet eine Order im Status "shipped" OHNE Dispute, fuer Item-3-UI-Test
// (Hinweis-Dialog manuell aus der App ausloesen). sellerIsCommercial=true,
// damit der Hinweis-Dialog beim Eroeffnen einer Reklamation greift.
async function seedShippedOrder({ listingId, buyerUid, buyerName, daysAgo, suffix }) {
  const ref = db.collection("artifacts").doc(APP_ID).collection("orders").doc();
  const offsetMs = (daysAgo || 0) * 24 * 60 * 60 * 1000;
  const shippedAt = new Date(Date.now() - offsetMs);
  const paidAt = new Date(Date.now() - offsetMs - 24 * 60 * 60 * 1000); // 1d vor Versand
  const trackingAddedAt = new Date(Date.now() - offsetMs);

  const orderData = {
    buyerId: buyerUid,
    buyerName,
    sellerId: TEST_SELLER_UID,
    sellerName: "Test Seller (Discogs-UI-Test)",
    sellerIsCommercial: true,
    // Item 5 (2026-05-01): Pflicht-Kontaktdaten fuer Verbraucher-Kaeufer
    // bei gewerblichen Verkaeufern (§ 312i BGB + Art. 246a EGBGB).
    sellerEmail: "test-seller@example.com",
    sellerAddress: {
      name: "Test Seller GmbH",
      street: "Verkaeuferstrasse 42",
      city: "Hamburg",
      zip: "20095",
      country: "DE",
    },
    items: [{
      listingId,
      cardId: `phase9_dispute_${suffix}`,
      cardName: `Phase9 Dispute Test Card (${suffix})`,
      quantity: 1,
      price: 8.0,
    }],
    totalPaid: 9.74,
    serviceFeeCents: 49,
    buyerServiceFee: 0.49,
    sellerPayout: 7.55,
    paymentMethod: "stripe",
    status: "shipped",
    shippingAddress: {
      name: buyerName,
      street: "Teststrasse 1",
      city: "Berlin",
      zip: "10115",
      country: "DE",
    },
    trackingNumber: "DHL-TEST-PHASE9-XYZ",
    trackingAddedAt: admin.firestore.Timestamp.fromDate(trackingAddedAt),
    paidAt: admin.firestore.Timestamp.fromDate(paidAt),
    shippedAt: admin.firestore.Timestamp.fromDate(shippedAt),
    stripePaymentIntentId: `pi_phase9_disputeUI_${suffix}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    [SEEDED_TAG]: true,
  };

  await ref.set(orderData);
  return ref.id;
}

async function seed(buyerUid) {
  console.log("🌱 Seede Test-Disputes für Discogs-UI-Test ...");
  console.log(`  Buyer-UID: ${buyerUid}`);
  console.log(`  Seller-UID: ${TEST_SELLER_UID} (fixed)`);
  console.log("");

  // Test 1: Frischer Open Dispute (2h alt) — Admin-Disputes-Screen Test
  const l1 = await seedListing({ price: 8.0, suffix: "fresh_open" });
  const o1 = await seedOrder({
    listingId: l1, buyerUid, buyerName: "Test Buyer (Discogs-UI-Test)",
    status: "disputed", disputeStatus: "open", hoursAgo: 2, suffix: "fresh_open",
  });
  console.log(`  ✓ Test 1 — Frischer Open Dispute:`);
  console.log(`    Order-ID: ${o1}`);
  console.log(`    Listing-ID: ${l1}`);
  console.log(`    → In App: Admin-Bereich → Disputes`);
  console.log(`    → Erwartung: 3-Button-UI (Reject / Pause / Ban)`);
  console.log("");

  // Test 2: Seller Proposed Refund (3h alt, 50% vorgeschlagen)
  const l2 = await seedListing({ price: 8.0, suffix: "seller_proposed" });
  const o2 = await seedOrder({
    listingId: l2, buyerUid, buyerName: "Test Buyer (Discogs-UI-Test)",
    status: "disputed", disputeStatus: "sellerProposed", hoursAgo: 3,
    proposedRefundPercent: 50, suffix: "seller_proposed",
  });
  console.log(`  ✓ Test 2 — Seller Proposed Refund (50%):`);
  console.log(`    Order-ID: ${o2}`);
  console.log(`    Listing-ID: ${l2}`);
  console.log(`    → In App (als Käufer): Order-Detail-Screen zeigt Refund-Vorschlag mit Accept/Reject`);
  console.log(`    → Im Admin-Bereich: Order erscheint mit „SELLERPROPOSED"-Badge`);
  console.log("");

  // Test 3: Alter Dispute (15d alt) — Buyer-Eskalations-Card Test
  const l3 = await seedListing({ price: 8.0, suffix: "old_15d" });
  const o3 = await seedOrder({
    listingId: l3, buyerUid, buyerName: "Test Buyer (Discogs-UI-Test)",
    status: "disputed", disputeStatus: "open", daysAgo: 15, suffix: "old_15d",
  });
  console.log(`  ✓ Test 3 — Alter Dispute (15d):`);
  console.log(`    Order-ID: ${o3}`);
  console.log(`    Listing-ID: ${l3}`);
  console.log(`    → In App (als Käufer): Order-Detail-Screen zeigt BUYER-ESKALATIONS-CARD`);
  console.log(`    → 3 Pfade: Stripe-Chargeback / Schlichtungsstelle / Zivilrechtsweg`);
  console.log(`    → Header: "15d offen" Badge`);
  console.log(`    ⚠ Achtung: morgen 05:00 Berlin würde autoResolveSellerSilence-Cron`);
  console.log(`      diese Order auto-refunden. Bis dahin testbar.`);
  console.log("");

  // Test 4: BuyerSilence-Cron Test (proposedAt: 8d alt, sellerProposed)
  // Erwartung: devTriggerBuyerSilence flippt diesen Eintrag von
  // sellerProposed → open, setzt disputeReopenedAt, loescht proposed*-Felder.
  const l4 = await seedListing({ price: 8.0, suffix: "buyer_silence_8d" });
  const o4 = await seedOrder({
    listingId: l4, buyerUid, buyerName: "Test Buyer (Discogs-UI-Test)",
    status: "disputed", disputeStatus: "sellerProposed",
    daysAgo: 9, // disputedAt 9d ago, proposedAt 8d ago (rejected after 1d)
    proposedRefundPercent: 50, proposedDaysAgo: 8,
    suffix: "buyer_silence_8d",
  });
  console.log(`  ✓ Test 4 — BuyerSilence-Cron Test (proposedAt 8d alt):`);
  console.log(`    Order-ID: ${o4}`);
  console.log(`    Listing-ID: ${l4}`);
  console.log(`    → Cron-Test: devTriggerBuyerSilence muss flippen`);
  console.log(`    → Erwartung NACH Cron: disputeStatus=open, disputeReopenedAt=NOW,`);
  console.log(`      proposedRefundPercent/proposedRefundAmount/proposedAt=null`);
  console.log("");

  // Test 5: Tiebreaker Test (disputedAt 20d, disputeReopenedAt 2d, open)
  // Erwartung: devTriggerSellerSilence MUSS diesen SKIPPEN (reopenedAt<7d).
  const l5 = await seedListing({ price: 8.0, suffix: "tiebreaker_2d" });
  const o5 = await seedOrder({
    listingId: l5, buyerUid, buyerName: "Test Buyer (Discogs-UI-Test)",
    status: "disputed", disputeStatus: "open",
    daysAgo: 20, // urspruenglich 20d alt
    reopenedDaysAgo: 2, // aber erst vor 2d wieder geoeffnet
    suffix: "tiebreaker_2d",
  });
  console.log(`  ✓ Test 5 — disputeReopenedAt-Tiebreaker Test:`);
  console.log(`    Order-ID: ${o5}`);
  console.log(`    Listing-ID: ${l5}`);
  console.log(`    → Cron-Test: devTriggerSellerSilence muss SKIPPEN`);
  console.log(`    → Erwartung: trotz disputedAt=20d skipped wegen disputeReopenedAt=2d`);
  console.log(`    → Off-by-Cron-Bug-Schutz (Item 1 KI-Anwalt-Wording-Pass)`);
  console.log("");

  // Test 6: Shipped Order ohne Dispute — UI-Test fuer Item 3 Hinweis-Dialog
  // (Käufer eroeffnet manuell Reklamation in der App, waehlt
  // "Wrong card received" → RefundPathChoiceSheet erscheint).
  const l6 = await seedListing({ price: 8.0, suffix: "shipped_no_dispute" });
  const o6 = await seedShippedOrder({
    listingId: l6, buyerUid, buyerName: "Test Buyer (Discogs-UI-Test)",
    daysAgo: 2, // vor 2d versandt — ist „delivered noch nicht bestaetigt"
    suffix: "shipped_no_dispute",
  });
  console.log(`  ✓ Test 6 — Shipped Order ohne Dispute (UI-Test Item 3):`);
  console.log(`    Order-ID: ${o6}`);
  console.log(`    Listing-ID: ${l6}`);
  console.log(`    → In App (als Käufer): My Orders → diese Order oeffnen`);
  console.log(`    → "Report problem"/Reklamation eroeffnen, Reason "Wrong card received"`);
  console.log(`    → Erwartung: RefundPathChoiceSheet erscheint mit 2 Optionen`);
  console.log(`    → Auch sichtbar: Widerrufsbelehrungs-Link in Order-Info (Item 4)`);
  console.log(`    → Verkaeufer-Status-Badge "Gewerblich" (Item 2)`);
  console.log("");

  console.log("✓ Seeding fertig.");
  console.log("");
  console.log("Naechste Schritte (UI-Smoke):");
  console.log("  1. App öffnen → Admin-Bereich → Disputes → Tests 1+2+5 sichtbar (4 fehlt — kein Open-Status)");
  console.log("  2. Bei Test 1: 3-Button-UI testen (z.B. Reject-Button anklicken, Reason eingeben, bestätigen)");
  console.log("  3. App als Käufer → My Orders → Test 3 öffnen → Buyer-Eskalations-Card sichtbar");
  console.log("  4. App als Käufer → Test 1 öffnen → 'Widerrufsbelehrung'-Karte in Order-Info sichtbar (Item 4)");
  console.log("  5. App als Käufer → Test 6 öffnen → Reklamation eroeffnen → Reason='Wrong card received'");
  console.log("     → RefundPathChoiceSheet erscheint mit 2 Optionen (Item 3)");
  console.log("     → Wahl 'Widerruf' zeigt Widerrufs-Modal; Wahl 'Reklamation' triggert openDispute");
  console.log("     → Test 6 kann mehrfach versucht werden, wenn Cancel/Abort gewählt");
  console.log("");
  console.log("Cron-Tests (admin-only via devTrigger):");
  console.log("  A. devTriggerBuyerSilence → Erwartung: reopened=1 (Test 4)");
  console.log("  B. devTriggerSellerSilence → Erwartung: skipped um Test 5,");
  console.log("     refunded ggf. Test 3 wenn ≥7d alt — sonst skipped.");
  console.log("");
  console.log("Cleanup nach Tests:");
  console.log("  node test-scenarios/seed_test_disputes.js --cleanup");

  process.exit(0);
}

if (process.argv.includes("--cleanup")) {
  cleanup().catch(e => { console.error(e); process.exit(2); });
} else {
  const buyerUid = process.argv.find(a => a.length === 28 && !a.startsWith("--") && !a.includes("/"));
  if (!buyerUid) {
    console.error("❌ Buyer-UID fehlt.");
    console.error("Verwendung: node test-scenarios/seed_test_disputes.js <DEINE_FIREBASE_UID>");
    console.error("UID findest du: Firebase Console → Authentication → deine Email → UID");
    console.error("Oder: in der App → Settings → Profil → UID");
    console.error("");
    console.error("Cleanup-Mode (löscht alle Test-Disputes):");
    console.error("  node test-scenarios/seed_test_disputes.js --cleanup");
    process.exit(1);
  }
  seed(buyerUid).catch(e => { console.error(e); process.exit(2); });
}

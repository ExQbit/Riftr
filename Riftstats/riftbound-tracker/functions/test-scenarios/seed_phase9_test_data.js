// Phase 9 Test-Data Seeder (2026-04-30)
//
// Seedet zwei Test-Orders + dazugehoerige Listings:
//   1. Stale-Shipment: status=paid, paidAt=15d ago → wird vom
//      _runStaleShipmentsResolver gefangen
//   2. Silent-Dispute: status=disputed, disputeStatus=open, disputedAt=8d
//      ago → wird vom _runSellerSilenceResolver gefangen
//
// Run: node test-scenarios/seed_phase9_test_data.js
// Cleanup: node test-scenarios/seed_phase9_test_data.js --cleanup

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
const TEST_BUYER_UID = "_test_buyer_PHASE9";

const SEEDED_DOC_TAG = "_phase9Test"; // Marker für Cleanup

async function cleanup() {
  console.log("🧹 Cleanup: lösche alle _phase9Test=true Docs ...");
  const collections = ["orders", "listings"];
  let total = 0;
  for (const col of collections) {
    const snap = await db.collection("artifacts").doc(APP_ID)
      .collection(col).where(SEEDED_DOC_TAG, "==", true).get();
    for (const doc of snap.docs) {
      await doc.ref.delete();
      total++;
    }
    console.log(`  ${col}: ${snap.size} gelöscht`);
  }
  console.log(`✓ Cleanup fertig: ${total} Docs entfernt.`);
  process.exit(0);
}

async function seed() {
  console.log("🌱 Seede Phase9-Test-Daten ...");

  const listingsRef = db.collection("artifacts").doc(APP_ID).collection("listings");
  const ordersRef = db.collection("artifacts").doc(APP_ID).collection("orders");

  // ─── Test-Order 1: Stale Shipment (paid 15d ago) ───
  const staleListingRef = listingsRef.doc();
  await staleListingRef.set({
    sellerId: TEST_SELLER_UID,
    sellerName: "Phase9 Test Seller",
    sellerCountry: "DE",
    cardId: "phase9_stale_card",
    cardName: "Phase9 Test Card (Stale)",
    price: 5.0,
    quantity: 5,
    availableQty: 4,
    reservedQty: 1,
    condition: 0,
    isFoil: false,
    status: "reserved",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    [SEEDED_DOC_TAG]: true,
  });
  console.log(`  ✓ Stale-Listing seeded: ${staleListingRef.id}`);

  const fifteenDaysAgo = new Date(Date.now() - 15 * 24 * 60 * 60 * 1000);
  const staleOrderRef = ordersRef.doc();
  await staleOrderRef.set({
    buyerId: TEST_BUYER_UID,
    buyerName: "Phase9 Test Buyer",
    sellerId: TEST_SELLER_UID,
    sellerName: "Phase9 Test Seller",
    items: [{
      listingId: staleListingRef.id,
      cardId: "phase9_stale_card",
      cardName: "Phase9 Test Card (Stale)",
      quantity: 1,
      price: 5.0,
    }],
    totalPaid: 6.74,
    serviceFeeCents: 49,
    buyerServiceFee: 0.49,
    sellerPayout: 4.75,
    paymentMethod: "stripe",
    status: "paid",
    paidAt: admin.firestore.Timestamp.fromDate(fifteenDaysAgo),
    // Kein echtes PaymentIntent — Cron try/catched eh, da PI sowieso meist
    // schon expired wäre nach 15d. Helper schreibt status=cancelled in TX.
    stripePaymentIntentId: "pi_phase9_fake_stale",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    [SEEDED_DOC_TAG]: true,
  });
  console.log(`  ✓ Stale-Order seeded: ${staleOrderRef.id} (paidAt: ${fifteenDaysAgo.toISOString()})`);

  // ─── Test-Order 2: Silent Dispute (disputed 8d ago) ───
  const silentListingRef = listingsRef.doc();
  await silentListingRef.set({
    sellerId: TEST_SELLER_UID,
    sellerName: "Phase9 Test Seller",
    sellerCountry: "DE",
    cardId: "phase9_silent_card",
    cardName: "Phase9 Test Card (Silent)",
    price: 8.0,
    quantity: 3,
    availableQty: 2,
    reservedQty: 1,
    condition: 0,
    isFoil: false,
    status: "reserved",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    [SEEDED_DOC_TAG]: true,
  });
  console.log(`  ✓ Silent-Listing seeded: ${silentListingRef.id}`);

  const eightDaysAgo = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000);
  const silentOrderRef = ordersRef.doc();
  await silentOrderRef.set({
    buyerId: TEST_BUYER_UID,
    buyerName: "Phase9 Test Buyer",
    sellerId: TEST_SELLER_UID,
    sellerName: "Phase9 Test Seller",
    items: [{
      listingId: silentListingRef.id,
      cardId: "phase9_silent_card",
      cardName: "Phase9 Test Card (Silent)",
      quantity: 1,
      price: 8.0,
    }],
    totalPaid: 9.74,
    serviceFeeCents: 49,
    buyerServiceFee: 0.49,
    sellerPayout: 7.55,
    paymentMethod: "stripe",
    status: "disputed",
    disputeStatus: "open",
    disputeReason: "Not arrived",
    disputeReasonCode: "not_arrived",
    paidAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)),
    disputedAt: admin.firestore.Timestamp.fromDate(eightDaysAgo),
    // Kein echter PI — Cron versucht refund, faellt mit Stripe-Error
    // zurueck auf disputeStatus=open (sieht man als "errors" im Result).
    stripePaymentIntentId: "pi_phase9_fake_silent",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    [SEEDED_DOC_TAG]: true,
  });
  console.log(`  ✓ Silent-Order seeded: ${silentOrderRef.id} (disputedAt: ${eightDaysAgo.toISOString()})`);

  console.log("\n✓ Seeding fertig. Naechste Schritte:");
  console.log("  1. Live-Cron-Test laufen lassen:");
  console.log("     node test-scenarios/phase9_live_cron_test.js");
  console.log("  2. Resultat erwartet:");
  console.log("     - StaleShipments: candidates=1, cancelled=1 (Stripe-Error wird gecatched)");
  console.log("     - SellerSilence: candidates=1, errors=1 (PI nicht real → Stripe lehnt ab; disputeStatus zurueck auf 'open')");
  console.log("  3. Cleanup wenn fertig:");
  console.log("     node test-scenarios/seed_phase9_test_data.js --cleanup");
  process.exit(0);
}

if (process.argv.includes("--cleanup")) {
  cleanup().catch(e => { console.error(e); process.exit(2); });
} else {
  seed().catch(e => { console.error(e); process.exit(2); });
}

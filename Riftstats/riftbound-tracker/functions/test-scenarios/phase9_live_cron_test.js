// Phase 9 — LIVE Cron-Trigger Test (2026-04-30)
//
// Nutzt Direct-Module-Import statt gcloud functions call. Damit reproduzierbar
// ohne interaktiven gcloud auth login. Importiert _runStaleShipmentsResolver
// und _runSellerSilenceResolver direkt aus dem deployed index.js Module
// (Helper sind als named exports verfügbar — siehe Commit nach diesem File).
//
// WICHTIG: index.js ruft beim Import admin.initializeApp() auf — daher MÜSSEN
// wir das hier NICHT erneut tun. Der Import macht das Setup.
//
// Run: node test-scenarios/phase9_live_cron_test.js
// Exit-Code 0 = alle gruen, 1 = Fehler.

const path = require("path");

// Setze GOOGLE_APPLICATION_CREDENTIALS + GOOGLE_CLOUD_PROJECT BEVOR wir
// index.js requiren — sonst schlägt admin.initializeApp() ohne explizite
// credentials/project fehl. In deployed CFs kommen die aus der GCP-Env
// automatisch; lokal müssen wir's setzen.
process.env.GOOGLE_APPLICATION_CREDENTIALS = path.join(
  process.env.HOME,
  ".config/firebase/eladiorubiohernandez_gmail_com_application_default_credentials.json",
);
process.env.GOOGLE_CLOUD_PROJECT = "riftr-10527";
process.env.GCLOUD_PROJECT = "riftr-10527";

// Setze STRIPE_SECRET_KEY aus Secret Manager (sonst meckert getStripe()).
// Phase8 nutzt SecretManagerServiceClient — wir tun das gleiche, async vor Import.
const { SecretManagerServiceClient } = require("@google-cloud/secret-manager");

const COLORS = {
  ok: "\x1b[32m",
  fail: "\x1b[31m",
  warn: "\x1b[33m",
  cyan: "\x1b[36m",
  dim: "\x1b[90m",
  reset: "\x1b[0m",
};

async function fetchSecretAndSet() {
  const sm = new SecretManagerServiceClient();
  const [v] = await sm.accessSecretVersion({
    name: "projects/riftr-10527/secrets/STRIPE_SECRET_KEY/versions/latest",
  });
  process.env.STRIPE_SECRET_KEY = v.payload.data.toString("utf8").trim();
  if (!process.env.STRIPE_SECRET_KEY.startsWith("sk_test_")) {
    throw new Error("STRIPE_SECRET_KEY ist kein Test-Key — abort.");
  }
}

async function main() {
  console.log(`\n${COLORS.cyan}╔══════════════════════════════════════════════╗${COLORS.reset}`);
  console.log(`${COLORS.cyan}║   Phase 9 — LIVE Cron-Trigger Test           ║${COLORS.reset}`);
  console.log(`${COLORS.cyan}╚══════════════════════════════════════════════╝${COLORS.reset}`);

  console.log(`${COLORS.dim}Loading Stripe Secret from Secret Manager...${COLORS.reset}`);
  await fetchSecretAndSet();
  console.log(`${COLORS.dim}Stripe Test-Key loaded into env.${COLORS.reset}`);

  console.log(`${COLORS.dim}Importing index.js (triggers admin.initializeApp + onCall registrations)...${COLORS.reset}`);
  const index = require("../index.js");
  console.log(`${COLORS.dim}Index loaded. Helpers available: ${Object.keys(index).filter(k => k.startsWith("_run")).join(", ")}${COLORS.reset}`);

  // ── Test 1: autoResolveStaleShipments ──
  console.log(`\n${COLORS.cyan}━━━ Test 1: _runStaleShipmentsResolver (live) ━━━${COLORS.reset}`);
  try {
    const result = await index._runStaleShipmentsResolver();
    console.log(`  ${COLORS.ok}✓${COLORS.reset} Cron executed without error`);
    console.log(`  ${COLORS.dim}Result: ${JSON.stringify(result)}${COLORS.reset}`);
    if (result.candidates === 0) {
      console.log(`  ${COLORS.warn}⚠${COLORS.reset}  No candidates found — keine paid orders ≥14d alt`);
      console.log(`  ${COLORS.dim}Erwarteter Output bei sauberer DB. Fuer echten Test: Test-Order seeden mit paidAt 15d in past.${COLORS.reset}`);
    } else {
      console.log(`  ${COLORS.ok}Processed ${result.candidates} candidates: cancelled=${result.cancelled} skipped=${result.skipped}${COLORS.reset}`);
    }
  } catch (e) {
    console.log(`  ${COLORS.fail}✗${COLORS.reset} Cron threw: ${e.message}`);
    console.error(e.stack);
    process.exit(1);
  }

  // ── Test 2: autoResolveSellerSilence ──
  // (mit disputeReopenedAt-Tiebreaker — KI-Anwalt-Wording-Pass Item 1, 01.05.2026)
  console.log(`\n${COLORS.cyan}━━━ Test 2: _runSellerSilenceResolver (live) ━━━${COLORS.reset}`);
  try {
    const result = await index._runSellerSilenceResolver();
    console.log(`  ${COLORS.ok}✓${COLORS.reset} Cron executed without error`);
    console.log(`  ${COLORS.dim}Result: ${JSON.stringify(result)}${COLORS.reset}`);
    if (result.candidates === 0) {
      console.log(`  ${COLORS.warn}⚠${COLORS.reset}  No candidates found — keine disputed orders ≥7d alt`);
      console.log(`  ${COLORS.dim}Erwarteter Output bei sauberer DB. Fuer echten Test: Test-Dispute seeden mit disputedAt 8d in past.${COLORS.reset}`);
    } else {
      console.log(`  ${COLORS.ok}Processed ${result.candidates} candidates: refunded=${result.refunded} skipped=${result.skipped} errors=${result.errors}${COLORS.reset}`);
      console.log(`  ${COLORS.dim}Tiebreaker-Check: Test-5-Order (reopenedDaysAgo=2) MUSS skipped sein.${COLORS.reset}`);
    }
  } catch (e) {
    console.log(`  ${COLORS.fail}✗${COLORS.reset} Cron threw: ${e.message}`);
    console.error(e.stack);
    process.exit(1);
  }

  // ── Test 3: autoResolveBuyerSilence (Item 1, 01.05.2026) ──
  console.log(`\n${COLORS.cyan}━━━ Test 3: _runBuyerSilenceResolver (live) ━━━${COLORS.reset}`);
  if (typeof index._runBuyerSilenceResolver !== "function") {
    console.log(`  ${COLORS.fail}✗${COLORS.reset} _runBuyerSilenceResolver ist nicht exportiert.`);
    console.log(`  ${COLORS.dim}Functions evtl. nicht deployed. Erst 'firebase deploy --only functions' laufen lassen.${COLORS.reset}`);
    process.exit(1);
  }
  try {
    const result = await index._runBuyerSilenceResolver();
    console.log(`  ${COLORS.ok}✓${COLORS.reset} Cron executed without error`);
    console.log(`  ${COLORS.dim}Result: ${JSON.stringify(result)}${COLORS.reset}`);
    if (result.candidates === 0) {
      console.log(`  ${COLORS.warn}⚠${COLORS.reset}  No candidates found — keine sellerProposed orders mit proposedAt >7d`);
      console.log(`  ${COLORS.dim}Fuer echten Test: seed_test_disputes.js erstellt Test 4 (proposedAt 8d).${COLORS.reset}`);
    } else {
      console.log(`  ${COLORS.ok}Processed ${result.candidates} candidates: reopened=${result.reopened} skipped=${result.skipped}${COLORS.reset}`);
      console.log(`  ${COLORS.dim}Erwartung mit Test-Daten: reopened=1 (Test 4 sellerProposed→open), 0 skipped.${COLORS.reset}`);
    }
  } catch (e) {
    console.log(`  ${COLORS.fail}✗${COLORS.reset} Cron threw: ${e.message}`);
    console.error(e.stack);
    process.exit(1);
  }

  console.log(`\n${COLORS.ok}━━━ Live-Cron-Tests completed successfully ━━━${COLORS.reset}`);
  console.log(`${COLORS.dim}Drei Cron-Helper haben fehlerfrei durchgelaufen. Wenn deine DB`);
  console.log(`saubere Test-Daten haette, waeren sie automatisch resolved worden.`);
  console.log(`Naechster Production-Cron-Run: 04:30 / 05:00 / 05:30 Berlin.${COLORS.reset}`);

  // Async-Cleanup: einige Firebase-Connections koennen den Process offen halten
  process.exit(0);
}

main().catch((e) => {
  console.error(`${COLORS.fail}Fatal: ${e.message}${COLORS.reset}`);
  console.error(e.stack);
  process.exit(2);
});

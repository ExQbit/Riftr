const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const db = admin.firestore();
const APP_ID = "riftr-v1";

// ─── Admin-Trigger-Secret fuer onRequest Maintenance-Endpoints ──────────
//
// Alle manuellen HTTP-Endpoints (fetchPricesManual, migrateXxx,
// checkNewXxxManual, discoverXxx, backfillXxx) sind by-default
// public-callable (onRequest hat keine Auto-Auth) und triggern teure
// Operationen (CF-Compute-Quota, Riot-API-Calls, volle Migration-Loops).
// Ohne Auth = DoS-Vektor + Quota-Burn. Stripe-Webhook bleibt ungeschuetzt
// weil dort die Stripe-Signature die Auth ist.
//
// Aufruf: `Authorization: Bearer <ADMIN_TRIGGER_SECRET>`
// Constant-time-Compare gegen Timing-Attacks.
const ADMIN_TRIGGER_SECRET = (process.env.ADMIN_TRIGGER_SECRET || "").trim();

// ─── Items-Array Sanitizer (Security-Audit Round 6, 2026-04-29) ──
// Dedupe + Size-Cap fuer items-arrays die in createPaymentIntent /
// processMultiSellerCart kommen. Vorher konnte der Client duplikate
// listingIds senden:
//   items: [{listingId: "X", qty: 1}, {listingId: "X", qty: 1}]
// Jede Iteration las dasselbe Listing, available-check bestand beide-mal
// (gleiche Daten) → Order ueber-allokiert. Listing.qty=1 → Order fuer 2.
// Fix: dedupe by listingId mit Quantity-Sum, plus 100-Item-Cap (DoS).
function dedupeAndValidateItems(items) {
  if (!Array.isArray(items)) {
    throw new HttpsError("invalid-argument", "items must be an array");
  }
  if (items.length === 0) {
    throw new HttpsError("invalid-argument", "items array is empty");
  }
  if (items.length > 100) {
    throw new HttpsError(
      "invalid-argument",
      `items array too large (${items.length}, max 100)`,
    );
  }
  const map = new Map();
  for (const entry of items) {
    if (!entry || typeof entry !== "object") {
      throw new HttpsError("invalid-argument", "invalid item entry");
    }
    const lid = entry.listingId;
    if (!lid || typeof lid !== "string") {
      throw new HttpsError("invalid-argument", "item missing listingId");
    }
    const qty = Math.floor(Number(entry.quantity) || 1);
    if (qty < 1 || qty > 9999) {
      throw new HttpsError(
        "invalid-argument",
        `invalid quantity for listing ${lid} (must be 1-9999)`,
      );
    }
    map.set(lid, (map.get(lid) || 0) + qty);
  }
  // Re-cap auf max-quantity-per-listing nach Aggregation
  const deduped = [];
  for (const [listingId, totalQty] of map.entries()) {
    if (totalQty > 9999) {
      throw new HttpsError(
        "invalid-argument",
        `aggregated quantity for ${listingId} exceeds 9999`,
      );
    }
    deduped.push({ listingId, quantity: totalQty });
  }
  return deduped;
}

// ─── Generic Per-User Rate-Limit (Security-Audit Round 5, 2026-04-29) ──
// Schuetzt teure CFs (Stripe-API-Calls, Firestore-Writes) gegen Spam von
// authentifizierten Usern. Pro UID + key (CF-Name) ein Daily-Counter.
// Doc: `artifacts/{appId}/rateLimits/{uid}` mit Sub-Object pro Key.
// CF-only-Schreiben via Admin-SDK; Firestore-Rules-Default-deny blockt
// Client-Zugriff.
//
// Race: paralleler Schreib auf den Counter im selben ms-Fenster koennte
// Cap um 1 ueberschreiten (Lese-then-Write nicht atomar). Acceptable —
// Limit-Wert ist sowieso konservativ + Spam-Schutz ist statistisch.
async function enforceRateLimit(uid, key, dailyLimit) {
  if (!uid) return;
  const today = new Date().toISOString().slice(0, 10);
  const ref = db.collection("artifacts").doc(APP_ID)
    .collection("rateLimits").doc(uid);
  const snap = await ref.get();
  const data = snap.exists ? snap.data() : {};
  const entry = data[key] || {};
  const todayCount = entry.date === today ? (entry.count || 0) : 0;
  if (todayCount >= dailyLimit) {
    throw new HttpsError(
      "resource-exhausted",
      `Daily limit reached (${dailyLimit} ${key} per day). Try again tomorrow.`,
    );
  }
  await ref.set({
    [key]: {
      date: today,
      count: todayCount + 1,
    },
  }, { merge: true });
}

// ─── Account-Age-Based Daily Cap (Round 9 Red-Team-Audit, 2026-04-29) ─
// Carder-Defense via Age-Tiering:
//   Frische Accounts (<7 Tage) → tightest cap (5)
//   Mittel (7-30 Tage)         → moderate cap (15)
//   Etabliert (>30 Tage)       → full cap (25)
//
// Real-Carder muss 7+ Tage warten BEVOR er einen Account profitabel
// carden kann → skaliert nicht fuer Profis (sie wollen schnell Geld).
// Legit Power-Buyer kommt mit 5/Tag in der ersten Woche locker hin
// (wer kauft mehr als 5 Karten in der ersten App-Woche?).
//
// Account-Age via Firebase Auth `user.metadata.creationTime` —
// nicht client-controlled, nicht faelschbar.
async function getAccountAgeDays(uid) {
  try {
    const userRecord = await admin.auth().getUser(uid);
    const creationTime = userRecord.metadata?.creationTime;
    if (!creationTime) return 999; // assume mature on missing data
    const ageMs = Date.now() - new Date(creationTime).getTime();
    return Math.floor(ageMs / (24 * 60 * 60 * 1000));
  } catch (_) {
    return 999; // Auth-failure → treat as mature (don't block legit users)
  }
}

async function enforceAgeBasedDailyCap(uid, key, freshCap, midCap, matureCap) {
  if (!uid) return;
  const ageDays = await getAccountAgeDays(uid);
  let dailyLimit;
  if (ageDays < 7) dailyLimit = freshCap;
  else if (ageDays < 30) dailyLimit = midCap;
  else dailyLimit = matureCap;
  await enforceRateLimit(uid, key, dailyLimit);
}

// ─── Sock-Puppet / Wash-Trading Detection (Round 10, 2026-04-29) ───
// Buyer-Seller-Pair-Velocity-Tracking. Wash-Trading-Pattern:
//   - Seller A + Friends (B, C, D) koordinieren
//   - Friends kaufen ~5-50× kleine Listings von A
//   - Friends leaven 5-Sterne-Reviews
//   - A erreicht Trusted-Tier ohne echte Verkaeufe
//
// Detection-Threshold:
//   - 5+ Transaktionen zwischen gleichem Buyer-Seller-Pair in 30 Tagen
//     UND average-amount < €15 (Wash-Trades nutzen typisch billige Listings)
//   - 10+ Transaktionen in 30 Tagen (egal welcher Betrag) — auch organisiert
//
// Bei Threshold-Hit: Admin-Alert. Kein Auto-Block (legit-Power-Buyer-Pairs
// existieren — Buyer der jede Woche bei Lieblings-Seller kauft = legit).
// Admin investigiert + entscheidet ob Suspension noetig.
const SOCK_PUPPET_TXN_THRESHOLD = 5;          // Transaktionen
const SOCK_PUPPET_AVG_AMOUNT_CAP = 15.0;      // EUR — unter dem = Wash-Pattern
const SOCK_PUPPET_HARD_THRESHOLD = 10;        // egal welcher Betrag

async function trackBuyerSellerPair(buyerId, sellerId, amountEur) {
  if (!buyerId || !sellerId) return;
  if (buyerId === sellerId) return; // self-buy already blocked Round 5
  // Doc-Path: pair-key kombiniert beide UIDs sortiert (deterministisch)
  // Tatsaechlich: behalten wir buyerId_sellerId-order weil wir die
  // Direction tracken wollen (B kauft von S, nicht umgekehrt).
  const pairKey = `${buyerId}_${sellerId}`;
  const pairRef = db.collection("artifacts").doc(APP_ID)
    .collection("buyerSellerPairs").doc(pairKey);

  const pairSnap = await pairRef.get();
  const data = pairSnap.exists ? pairSnap.data() : {};
  const events = Array.isArray(data.events) ? data.events : [];

  // 30-Tage-Window
  const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000;
  const recent = events.filter((e) => (e.ts || 0) >= thirtyDaysAgo);
  recent.push({ ts: Date.now(), amount: amountEur });

  // Memory-bound: max 50 Events pro Pair (vermutlich nie ueberschritten)
  const trimmed = recent.slice(-50);

  // Compute stats
  const txnCount = recent.length;
  const totalAmount = recent.reduce((s, e) => s + (e.amount || 0), 0);
  const avgAmount = txnCount > 0 ? totalAmount / txnCount : 0;

  // Already-flagged check (avoid spam-alerts)
  const alreadyFlagged = data.flaggedAt != null;

  let shouldFlag = false;
  let reason = null;
  if (!alreadyFlagged) {
    if (txnCount >= SOCK_PUPPET_HARD_THRESHOLD) {
      shouldFlag = true;
      reason = `${txnCount} txns in 30d (any amount)`;
    } else if (
      txnCount >= SOCK_PUPPET_TXN_THRESHOLD &&
      avgAmount < SOCK_PUPPET_AVG_AMOUNT_CAP
    ) {
      shouldFlag = true;
      reason = `${txnCount} txns in 30d, avg €${avgAmount.toFixed(2)} (low-value pattern)`;
    }
  }

  const updatePayload = {
    buyerId,
    sellerId,
    events: trimmed,
    lastTransactionAt: admin.firestore.FieldValue.serverTimestamp(),
    txnCount30d: txnCount,
    totalAmount30d: totalAmount,
    avgAmount30d: avgAmount,
  };

  if (shouldFlag) {
    updatePayload.flaggedAt = admin.firestore.FieldValue.serverTimestamp();
    updatePayload.flaggedReason = reason;
    console.warn(
      `🚨 SOCK_PUPPET_SUSPECT: buyer=${buyerId} seller=${sellerId} ${reason}`,
    );
    try {
      sendAdminAlert(
        "SOCK_PUPPET_SUSPECT",
        `Buyer ${buyerId} <-> Seller ${sellerId}: ${reason}. ` +
        `Manual review recommended.`,
      );
    } catch (alertErr) {
      console.error(`Sock-Puppet Alert dispatch failed: ${alertErr.message}`);
    }
  }

  await pairRef.set(updatePayload, { merge: true });
}

// ─── Hourly Velocity Rate-Limit (Round 9 Red-Team-Audit, 2026-04-29) ─
// Schaerfere Velocity-Defense gegen Burst-Attacks:
// "100/day" erlaubt theoretisch 100 in 5 Minuten = Burst-Spam.
// "20/hour" macht Burst-Attacks unattraktiv (max 20 in 1h Fenster).
// Beide Limits parallel — kombiniert: realistisch 480/Tag (24*20),
// aber praktisch limited auf Daily-Cap (100/day). Cap-Aufweichung
// nicht moeglich.
//
// Window-Tracking: rolling 1-Stunde via `hourlyEvents`-Array von
// Timestamps. Wir behalten nur die letzten N Events (memory-bound).
async function enforceHourlyVelocity(uid, key, hourlyLimit) {
  if (!uid) return;
  const ref = db.collection("artifacts").doc(APP_ID)
    .collection("rateLimits").doc(uid);
  const snap = await ref.get();
  const data = snap.exists ? snap.data() : {};
  const entry = data[`${key}Hourly`] || {};
  const events = Array.isArray(entry.events) ? entry.events : [];
  const oneHourAgo = Date.now() - 60 * 60 * 1000;
  const recent = events.filter((ts) => ts >= oneHourAgo);
  if (recent.length >= hourlyLimit) {
    throw new HttpsError(
      "resource-exhausted",
      `Hourly limit reached (${hourlyLimit} ${key} per hour). Try again later.`,
    );
  }
  recent.push(Date.now());
  // Cap array-size auf 2x hourlyLimit fuer memory-safety
  const trimmed = recent.slice(-Math.max(hourlyLimit * 2, 50));
  await ref.set({
    [`${key}Hourly`]: { events: trimmed },
  }, { merge: true });
}

function requireAdminSecret(req, res) {
  if (!ADMIN_TRIGGER_SECRET) {
    console.error("ADMIN_TRIGGER_SECRET not configured — manual endpoint refused");
    res.status(503).json({ error: "Admin secret not configured" });
    return false;
  }
  const auth = (req.headers.authorization || "").trim();
  const expected = `Bearer ${ADMIN_TRIGGER_SECRET}`;
  // Length-check first (timingSafeEqual wirft bei unterschiedlicher Laenge)
  if (auth.length !== expected.length) {
    res.status(403).json({ error: "Forbidden" });
    return false;
  }
  let ok = false;
  try {
    ok = crypto.timingSafeEqual(Buffer.from(auth), Buffer.from(expected));
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    res.status(403).json({ error: "Forbidden" });
    return false;
  }
  return true;
}

// ── Cardmarket public data URLs ──

const CM_PRICE_GUIDE_URL =
  "https://downloads.s3.cardmarket.com/productCatalog/priceGuide/price_guide_22.json";
const CM_PRODUCT_CATALOG_URL =
  "https://downloads.s3.cardmarket.com/productCatalog/productList/products_singles_22.json";

// ── Rarity variants: "name|setId" → ordered rarity list ──
// Generated from cards.json. Products sorted by idProduct (ascending) within
// the same name+set group match 1:1 with this list.
const RARITY_VARIANTS = require("./rarity_variants.json");

// ── Plated Legend (Metal Card) products ──
// Memorabilia category (46) — not in price_guide_22.json.
// We scrape lowest listing price from Cardmarket product pages.
const PLATED_LEGEND_IDS = {
  874509: { name: "Kai'Sa, Daughter of the Void", set: "OGNX" },
  874510: { name: "Volibear, Relentless Storm", set: "OGNX" },
  874511: { name: "Jinx, Loose Cannon", set: "OGNX" },
  874512: { name: "Darius, Hand of Noxus", set: "OGNX" },
  874513: { name: "Ahri, Nine-Tailed Fox", set: "OGNX" },
  874514: { name: "Lee Sin, Blind Monk", set: "OGNX" },
  874515: { name: "Yasuo, Unforgiven", set: "OGNX" },
  874516: { name: "Leona, Radiant Dawn", set: "OGNX" },
  874517: { name: "Teemo, Swift Scout", set: "OGNX" },
  874518: { name: "Viktor, Herald of the Arcane", set: "OGNX" },
  874519: { name: "Miss Fortune, Bounty Hunter", set: "OGNX" },
  874520: { name: "Sett, The Boss", set: "OGNX" },
  874521: { name: "Annie, Dark Child", set: "OGSX" },
  874522: { name: "Master Yi, Wuju Bladesman", set: "OGSX" },
  874523: { name: "Lux, Lady of Luminosity", set: "OGSX" },
  874524: { name: "Garen, Might of Demacia", set: "OGSX" },
  874525: { name: "Rumble, Mechanized Menace", set: "SFDX" },
  874526: { name: "Lucian, Purifier", set: "SFDX" },
  874527: { name: "Draven, Glorious Executioner", set: "SFDX" },
  874528: { name: "Rek'Sai, Void Burrower", set: "SFDX" },
  874529: { name: "Ornn, Fire Below the Mountain", set: "SFDX" },
  874530: { name: "Jax, Grandmaster at Arms", set: "SFDX" },
  874531: { name: "Irelia, Blade Dancer", set: "SFDX" },
  874532: { name: "Azir, Emperor of the Sands", set: "SFDX" },
  874533: { name: "Ezreal, Prodigal Explorer", set: "SFDX" },
  874534: { name: "Renata Glasc, Chem-Baroness", set: "SFDX" },
  874535: { name: "Sivir, Battle Mistress", set: "SFDX" },
  874536: { name: "Fiora, Grand Duelist", set: "SFDX" },
};

// ── Helpers ──

async function fetchJSON(url) {
  const response = await fetch(url);
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`HTTP ${response.status} from ${url}: ${body.substring(0, 300)}`);
  }
  return response.json();
}

function round2(v) {
  return Math.round(v * 100) / 100;
}

function todayEpoch() {
  const d = new Date();
  d.setHours(12, 0, 0, 0);
  return Math.floor(d.getTime() / 1000);
}

// ─── Phase D outlier detection ────────────────────────────────────────
// Two distinct guards run during the daily fetch:
//
// 1. spikeGuard(trend, avg7, ...): catches UPWARD spikes where today's
//    trend has been pulled high by a single recent inflated listing.
//    If trend > avg7 * SPIKE_RATIO, we fall back to avg7 — the 7-day
//    mean is more stable and resists single-listing distortion. Only
//    fires when both values are positive. We don't apply this in the
//    DOWNWARD direction because legitimate market crashes need to
//    propagate through history quickly; movementGuard handles
//    pathological down-spikes against yesterday's stored point.
//
// 2. movementGuard(today, yesterday, ...): catches >2x or <0.5x ratio
//    against the previous stored history point. When triggered, today's
//    point is NOT written (yesterday's value is preserved as the most
//    recent point). This prevents Cardmarket trend-correction events
//    (e.g. "trend was lagged inflated yesterday, snapped to reality
//    today") from being recorded as legitimate -98% market moves.
//
// Thresholds:
//   SPIKE_RATIO     = 2.0  → trend > 2× avg7 = use avg7 instead
//   MOVEMENT_RATIO_HI = 2.0 → today/yesterday > 2 → skip write
//   MOVEMENT_RATIO_LO = 0.5 → today/yesterday < 0.5 → skip write
// Both guards log clearly so anomalies are visible in cron logs.

const SPIKE_RATIO = 2.0;
const MOVEMENT_RATIO_HI = 2.0;
const MOVEMENT_RATIO_LO = 0.5;

function spikeGuard(trend, avg7, cmId, variant) {
  if (trend <= 0) return 0;
  if (avg7 > 0 && trend > avg7 * SPIKE_RATIO) {
    console.warn(
      `🚨 SPIKE GUARD ${cmId} (${variant}): trend=${trend} > ${SPIKE_RATIO}× avg7=${avg7} → using avg7`,
    );
    return avg7;
  }
  return trend;
}

/**
 * Returns true if writing today's point would create an implausible
 * jump against yesterday's stored value. When true, caller should
 * skip the write so yesterday's point remains the latest.
 */
function movementGuard(todayPrice, yesterdayPrice, cmId, variant) {
  if (yesterdayPrice <= 0 || todayPrice <= 0) return false;
  const ratio = todayPrice / yesterdayPrice;
  if (ratio > MOVEMENT_RATIO_HI || ratio < MOVEMENT_RATIO_LO) {
    console.warn(
      `🚨 MOVEMENT GUARD ${cmId} (${variant}): today=${todayPrice} vs yesterday=${yesterdayPrice} ratio=${ratio.toFixed(3)} — skipping write`,
    );
    return true;
  }
  return false;
}

/**
 * Record completed sale prices for each item in an order.
 * Stores in market_sales/{cardId}/sales/{autoId} for future price analytics.
 */
async function recordSales(order, orderId) {
  const items = order.items || [];
  if (items.length === 0) return;

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const item of items) {
    if (!item.cardId || !item.pricePerCard) continue;

    const salesRef = db
      .collection("artifacts").doc(APP_ID)
      .collection("market_sales").doc(item.cardId)
      .collection("sales");

    batch.set(salesRef.doc(), {
      orderId,
      cardName: item.cardName || "",
      condition: item.condition || "NM",
      pricePerCard: item.pricePerCard,
      quantity: item.quantity || 1,
      sellerId: order.sellerId,
      buyerId: order.buyerId,
      soldAt: now,
    });
  }

  await batch.commit();
  console.log(`Recorded ${items.length} sale(s) from order ${orderId}`);
}

/**
 * Calculate realized gains for seller using FIFO cost basis.
 * Removes consumed lots from seller's cost_basis doc.
 * Updates seller's profile with lifetime realizedGains + totalCostBasisSold.
 *
 * @param {string} sellerId - Seller's UID
 * @param {Array} items - Order items [{cardId, pricePerCard, quantity}]
 * @param {number} fee - Platform fee fraction (default 0.05 = 5%)
 * @returns {{ totalRealizedGain: number, totalCostBasisSold: number }}
 */
async function calculateRealizedGains(sellerId, items, fee = 0.05) {
  if (!sellerId || !items || items.length === 0) return { totalRealizedGain: 0, totalCostBasisSold: 0 };

  // 1. Read seller's cost basis BEFORE cards are removed from collection
  const cbRef = db.collection("artifacts").doc(APP_ID)
    .collection("users").doc(sellerId).collection("data").doc("cost_basis");
  const cbDoc = await cbRef.get();
  const entries = cbDoc.exists ? (cbDoc.data().entries || {}) : {};

  let totalRealizedGain = 0;
  let totalCostBasisSold = 0;

  for (const item of items) {
    if (!item.cardId) continue;
    const qty = item.quantity || 1;
    const netPrice = (item.pricePerCard || 0) * (1 - fee); // After platform fee
    const entry = entries[item.cardId];

    if (!entry || !entry.lots || entry.lots.length === 0) {
      // No cost basis recorded — treat as pure gain (cost = 0)
      totalRealizedGain += netPrice * qty;
      continue;
    }

    // FIFO: Sort lots by date ascending (oldest first), consume oldest lots first
    entry.lots.sort((a, b) => (a.date || "").localeCompare(b.date || ""));

    let remaining = qty;
    let costForThisSale = 0;

    while (remaining > 0 && entry.lots.length > 0) {
      const lot = entry.lots[0];
      const take = Math.min(remaining, lot.qty);
      costForThisSale += take * lot.price;
      lot.qty -= take;
      remaining -= take;
      if (lot.qty <= 0) entry.lots.shift(); // Lot fully consumed
    }

    // Update cost basis totals
    entry.totalCost = Math.max(0, (entry.totalCost || 0) - costForThisSale);
    entry.totalQty = Math.max(0, (entry.totalQty || 0) - qty);
    if (entry.totalQty === 0) {
      delete entries[item.cardId]; // Clean up empty entries
    } else {
      entries[item.cardId] = entry;
    }

    totalRealizedGain += (netPrice * qty) - costForThisSale;
    totalCostBasisSold += costForThisSale;
  }

  // 2. Write updated cost basis (lots removed)
  await cbRef.set({ entries, updatedAt: new Date().toISOString() }, { merge: true });

  // 3. Update seller's profile with lifetime realized gains (atomic increment)
  const profileRef = db.collection("artifacts").doc(APP_ID)
    .collection("users").doc(sellerId).collection("data").doc("profile");
  await profileRef.set({
    realizedGains: admin.firestore.FieldValue.increment(totalRealizedGain),
    totalCostBasisSold: admin.firestore.FieldValue.increment(totalCostBasisSold),
  }, { merge: true });

  console.log(`Realized gains for seller ${sellerId}: €${totalRealizedGain.toFixed(2)} (cost basis sold: €${totalCostBasisSold.toFixed(2)})`);
  return { totalRealizedGain, totalCostBasisSold };
}

/**
 * Add purchased items to the buyer's collection after delivery.
 * Increments quantity for each card in the order.
 */
async function addItemsToCollection(order) {
  const items = order.items || [];
  if (items.length === 0 || !order.buyerId) return;

  const userBase = db
    .collection("artifacts").doc(APP_ID)
    .collection("users").doc(order.buyerId)
    .collection("data");

  // Look up card metadata to determine foil status
  const pricesSnap = await db.collection("artifacts").doc(APP_ID).collection("market").get();
  const cardMeta = {};
  pricesSnap.docs.forEach(d => {
    const data = d.data();
    cardMeta[d.id] = {
      rarity: (data.rarity || "").toLowerCase(),
      setId: data.setId || "",
      isPromo: !!(data.isPromo),
    };
  });

  // --- Increment collection quantities ---
  const collRef = userBase.doc("collection");
  const collDoc = await collRef.get();
  const cards = collDoc.exists ? (collDoc.data().cards || {}) : {};

  for (const item of items) {
    if (!item.cardId) continue;
    const qty = item.quantity || 1;

    // Determine if this card is foil-only (same logic as Flutter)
    // OGS = always non-foil, Promos = always foil, Rare+ = foil-only
    const meta = cardMeta[item.cardId] || {};
    const isOGS = meta.setId === "OGS";
    const foilOnly = !isOGS && (meta.isPromo || (meta.rarity !== "common" && meta.rarity !== "uncommon"));

    // Ensure entry is an object with qty + foil_qty
    const existing = (typeof cards[item.cardId] === "object" && cards[item.cardId] !== null)
      ? cards[item.cardId]
      : { qty: 0, foil_qty: 0 };

    if (foilOnly) {
      existing.foil_qty = (existing.foil_qty || 0) + qty;
    } else {
      existing.qty = (existing.qty || 0) + qty;
    }
    cards[item.cardId] = existing;
  }

  await collRef.set({ cards, updatedAt: new Date().toISOString() }, { merge: true });

  // --- Write cost basis entries (purchase price from order) ---
  const cbRef = userBase.doc("cost_basis");
  const cbDoc = await cbRef.get();
  const entries = cbDoc.exists ? (cbDoc.data().entries || {}) : {};

  for (const item of items) {
    if (!item.cardId) continue;
    const qty = item.quantity || 1;
    const price = item.pricePerCard || 0;

    const existing = entries[item.cardId] || { totalCost: 0, totalQty: 0, lots: [] };
    existing.totalCost += price * qty;
    existing.totalQty += qty;
    existing.lots.push({
      qty,
      price,
      date: new Date().toISOString(),
      source: "market",
    });
    entries[item.cardId] = existing;
  }

  await cbRef.set({ entries, updatedAt: new Date().toISOString() }, { merge: true });
  console.log(`Added ${items.length} item(s) to buyer ${order.buyerId} collection + cost basis`);

}

/**
 * Remove sold items from seller's collection when order is shipped.
 * Uses {qty, foil_qty} object format matching Flutter's collection structure.
 */
async function removeItemsFromSellerCollection(order) {
  const items = order.items || [];
  if (items.length === 0 || !order.sellerId) return;

  // Look up card metadata to determine foil status
  const pricesSnap = await db.collection("artifacts").doc(APP_ID).collection("market").get();
  const cardMeta = {};
  pricesSnap.docs.forEach(d => {
    const data = d.data();
    cardMeta[d.id] = {
      rarity: (data.rarity || "").toLowerCase(),
      setId: data.setId || "",
      isPromo: !!(data.isPromo),
    };
  });

  const sellerBase = db
    .collection("artifacts").doc(APP_ID)
    .collection("users").doc(order.sellerId)
    .collection("data");
  const sellerCollRef = sellerBase.doc("collection");
  const sellerCollDoc = await sellerCollRef.get();
  if (!sellerCollDoc.exists) return;

  const sellerCards = sellerCollDoc.data().cards || {};
  let changed = false;

  for (const item of items) {
    if (!item.cardId || sellerCards[item.cardId] === undefined) continue;
    const qty = item.quantity || 1;

    const meta = cardMeta[item.cardId] || {};
    const isOGS = meta.setId === "OGS";
    const foilOnly = !isOGS && (meta.isPromo || (meta.rarity !== "common" && meta.rarity !== "uncommon"));

    const entry = (typeof sellerCards[item.cardId] === "object" && sellerCards[item.cardId] !== null)
      ? sellerCards[item.cardId]
      : { qty: sellerCards[item.cardId] || 0, foil_qty: 0 };

    if (foilOnly) {
      entry.foil_qty = Math.max(0, (entry.foil_qty || 0) - qty);
    } else {
      entry.qty = Math.max(0, (entry.qty || 0) - qty);
    }

    if ((entry.qty || 0) + (entry.foil_qty || 0) <= 0) {
      delete sellerCards[item.cardId];
    } else {
      sellerCards[item.cardId] = entry;
    }
    changed = true;
  }

  if (changed) {
    await sellerCollRef.set({ cards: sellerCards, updatedAt: new Date().toISOString() }, { merge: true });
    console.log(`Removed ${items.length} item(s) from seller ${order.sellerId} collection`);
  }
}

/**
 * Finalize listing quantities after delivery confirmation.
 * Reduces quantity and reservedQty by sold amount.
 * Marks listing as 'sold' when quantity reaches 0.
 */
async function finalizeListingQuantities(items) {
  const listingsCol = db.collection("artifacts").doc(APP_ID).collection("listings");
  for (const item of items) {
    if (!item.listingId) continue;
    const listingRef = listingsCol.doc(item.listingId);
    const listingDoc = await listingRef.get();
    if (!listingDoc.exists) continue;

    const qty = item.quantity || 1;
    const data = listingDoc.data();
    const newQty = Math.max(0, (data.quantity || 1) - qty);
    const newReserved = Math.max(0, (data.reservedQty || 0) - qty);

    if (newQty <= 0) {
      await listingRef.update({ quantity: 0, reservedQty: 0, status: "sold" });
    } else {
      const updateData = { quantity: newQty, reservedQty: newReserved };
      // If there's still available stock, re-activate
      if (newQty > newReserved && data.status === "reserved") {
        updateData.status = "active";
      }
      await listingRef.update(updateData);
    }
    console.log(`Listing ${item.listingId}: qty ${data.quantity} → ${newQty}, reserved ${data.reservedQty || 0} → ${newReserved}`);
  }
}

/**
 * Add a strike to a seller's profile.
 * At 3 strikes, seller is suspended.
 */
async function addStrike(sellerId, reason) {
  const sellerRef = db
    .collection("artifacts").doc(APP_ID)
    .collection("users").doc(sellerId)
    .collection("data").doc("sellerProfile");

  const sellerDoc = await sellerRef.get();
  const currentStrikes = sellerDoc.exists ? (sellerDoc.data().strikes || 0) : 0;
  const newStrikes = currentStrikes + 1;

  const updateData = {
    strikes: newStrikes,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (newStrikes >= 3) {
    updateData.suspended = true;
    console.log(`Seller ${sellerId} SUSPENDED (${newStrikes} strikes)`);
  }

  await sellerRef.update(updateData);
  console.log(`Strike added to seller ${sellerId}: ${reason} (now ${newStrikes}/3)`);
}

// ── Order Description Helper ──

/**
 * Build a short description from order items.
 * "Flammenritter" or "Flammenritter + 2 more"
 */
function orderItemsSummary(items) {
  if (!items || items.length === 0) return "your order";
  const first = items[0].cardName || "Card";
  const totalQty = items.reduce((sum, i) => sum + (i.quantity || 1), 0);
  if (items.length === 1 && totalQty === 1) return first;
  if (items.length === 1) return `${first} ×${totalQty}`;
  const otherCount = items.length - 1;
  return `${first} + ${otherCount} more`;
}

// ── Push Notification Helper ──

/**
 * Send a push notification to a user. Fire-and-forget — never throws.
 * @param {string} uid - Target user's UID
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Optional data payload
 */
async function sendNotification(uid, title, body, data = {}) {
  try {
    // Write notification document for in-app deep linking (works regardless of FCM handler issues)
    // Auto-detect role from order data if not provided
    let role = data.role || null;
    if (!role && data.type === "order" && data.orderId) {
      try {
        const orderDoc = await db.collection("artifacts").doc(APP_ID).collection("orders").doc(data.orderId).get();
        if (orderDoc.exists) {
          role = orderDoc.data().sellerId === uid ? "seller" : "buyer";
        }
      } catch (_) { /* ignore — role stays null */ }
    }

    await db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("notifications").add({
        type: data.type || "general",
        orderId: data.orderId || null,
        role,
        title,
        body,
        seen: false,
        navigated: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    const tokenDoc = await db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("fcmTokens")
      .get();

    if (!tokenDoc.exists) return;

    const tokens = tokenDoc.data().tokens || {};
    const tokenList = Object.keys(tokens);
    if (tokenList.length === 0) return;

    const staleTokens = [];

    for (const token of tokenList) {
      try {
        await admin.messaging().send({
          token,
          notification: { title, body },
          data,
          android: { notification: { channelId: "order_updates" } },
          apns: {
            payload: {
              aps: {
                sound: "default",
                "content-available": 1,
                "mutable-content": 1,
              },
            },
          },
        });
        console.log(`FCM push sent to ${uid}: "${title}" token=${token.substring(0, 15)}...`);
      } catch (err) {
        console.error(`FCM FAILED for ${uid}: code=${err.code} msg=${err.message} token=${token.substring(0, 15)}...`);
        // Only remove truly invalid tokens — NOT transient server errors.
        // third-party-auth-error is an APNs auth issue on Firebase's side, not a bad token.
        if (
          err.code === "messaging/registration-token-not-registered" ||
          err.code === "messaging/invalid-registration-token"
        ) {
          staleTokens.push(token);
        }
      }
    }

    // Clean up stale tokens (but NOT sandbox tokens — those fail with third-party-auth-error in dev builds)
    if (staleTokens.length > 0) {
      const deleteData = {};
      for (const t of staleTokens) {
        deleteData[`tokens.${t}`] = admin.firestore.FieldValue.delete();
      }
      await tokenDoc.ref.update(deleteData);
      console.log(`Removed ${staleTokens.length} stale FCM token(s) for ${uid}`);
    }
  } catch (err) {
    console.error(`sendNotification failed for ${uid}: ${err.message}`);
  }
}

// ── Core update logic ──

async function updatePrices() {
  const [priceGuideData, catalogData] = await Promise.all([
    fetchJSON(CM_PRICE_GUIDE_URL),
    fetchJSON(CM_PRODUCT_CATALOG_URL),
  ]);

  console.log(
    `Fetched: ${priceGuideData.priceGuides.length} price entries, ${catalogData.products.length} products`
  );

  // ── Archive raw price guide (one doc per day) ──
  const archiveDate = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const archiveRef = db.collection("artifacts").doc(APP_ID).collection("price_guide_archive");
  try {
    await archiveRef.doc(archiveDate).set({
      priceGuides: priceGuideData.priceGuides,
      createdAt: priceGuideData.createdAt || null,
      archivedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Price guide archived for ${archiveDate}`);
  } catch (archiveErr) {
    console.error(`Failed to archive price guide: ${archiveErr.message}`);
  }

  // Build idProduct → price guide map
  const priceMap = {};
  for (const pg of priceGuideData.priceGuides) {
    priceMap[pg.idProduct] = pg;
  }

  const EXP_MAP = {
    6286: "OGN", 6289: "OGS", 6399: "SFD",
    6322: "OGNX", 6483: "SFDX", 6480: "OGNX",
    6491: "UNL", // Unleashed — Cardmarket live ab April 2026 (275 Produkte)
    // TODO: OGSX (Proving Grounds Extras) — add idExpansion when available on Cardmarket
    // TODO: OPP / PR / JDG — neue Riftcodex-Sets, Cardmarket-IDs noch nicht ermittelt
  };
  const knownExps = new Set(Object.keys(EXP_MAP).map(Number));

  // Debug: log all unique idExpansion + idCategory combos to discover Metal/new sets
  const unknownCombos = {};
  for (const p of catalogData.products) {
    if (!knownExps.has(p.idExpansion) || p.idCategory !== 1655) {
      const key = `exp:${p.idExpansion} cat:${p.idCategory}`;
      if (!unknownCombos[key]) unknownCombos[key] = { count: 0, sample: p.name };
      unknownCombos[key].count++;
    }
  }
  if (Object.keys(unknownCombos).length > 0) {
    console.log("Unknown expansion/category combos:", JSON.stringify(unknownCombos));
  }

  const allSingles = catalogData.products.filter(
    (p) => p.idCategory === 1655 && knownExps.has(p.idExpansion)
  );
  console.log(`Singles in catalog (known sets): ${allSingles.length}`);

  // ── Group CM products by name+set, sort by idProduct ──
  const productGroups = {};
  for (const product of allSingles) {
    const setId = EXP_MAP[product.idExpansion] || "";
    const key = product.name + "|" + setId;
    if (!productGroups[key]) productGroups[key] = [];
    productGroups[key].push(product);
  }
  for (const v of Object.values(productGroups)) {
    v.sort((a, b) => a.idProduct - b.idProduct);
  }

  const marketRef = db.collection("artifacts").doc(APP_ID).collection("market");
  const historyRef = db.collection("artifacts").doc(APP_ID).collection("market_history");

  const prices = {};
  const historyWrites = [];
  const today = todayEpoch();
  let matched = 0;
  let noPrice = 0;

  const existingOverview = await marketRef.doc("overview").get();

  // ── Process each product group ──
  for (const [groupKey, products] of Object.entries(productGroups)) {
    const variantList = RARITY_VARIANTS[groupKey] || [];

    // Track variant index within same rarity (for Flutter matching)
    const rarityIndexCounters = {};

    let pricedIdx = 0;
    for (let idx = 0; idx < products.length; idx++) {
      const product = products[idx];
      const pg = priceMap[product.idProduct];
      if (!pg) {
        noPrice++;
        continue;
      }

      // Assign rarity: from variant list based on priced-product index (skip unpriced gaps)
      const rarity = pricedIdx < variantList.length ? variantList[pricedIdx] : "Showcase";
      pricedIdx++;
      const rarityLower = rarity.toLowerCase();

      // Variant index: counts up within same rarity for same name+set
      const viKey = rarity;
      if (rarityIndexCounters[viKey] === undefined) rarityIndexCounters[viKey] = 0;
      const variantIndex = rarityIndexCounters[viKey]++;

      // Price guide fields — use trend (matches CM website price)
      const trendFoil = pg["trend-foil"] || 0;
      const trendNonFoil = pg.trend || 0;

      const foilPrice = trendFoil;
      const nonFoilPrice = trendNonFoil;

      const cmId = String(product.idProduct);
      const setId = EXP_MAP[product.idExpansion] || "";

      if (groupKey === "Teemo, Scout|OGNX") {
        console.log(`DEBUG TEEMO: cmId=${cmId} pricedIdx=${pricedIdx - 1} rarity=${rarity} vi=${variantIndex}`);
      }

      // Standard variant based on rarity
      let primaryPrice, isPrimaryFoil;
      if (rarityLower === "common" || rarityLower === "uncommon" || setId === "OGS") {
        isPrimaryFoil = false;
        primaryPrice = nonFoilPrice > 0 ? nonFoilPrice : foilPrice;
      } else {
        isPrimaryFoil = true;
        primaryPrice = foilPrice > 0 ? foilPrice : nonFoilPrice;
        if (primaryPrice === nonFoilPrice && foilPrice === 0) isPrimaryFoil = false;
      }

      // Promo sets (OGNX, SFDX, OGSX) exist only as foil.
      // Foil price is always primary. Fallback to non-foil when foil = 0
      // (CM sellers sometimes list foil cards as non-foil).
      if (setId === "OGNX" || setId === "SFDX" || setId === "OGSX") {
        isPrimaryFoil = true;
        if (foilPrice > 0) {
          primaryPrice = foilPrice;
        } else {
          primaryPrice = nonFoilPrice; // CM-Seller listen Foils manchmal als NF
        }
      }

      if (primaryPrice <= 0) continue;

      // Per-variant stats from CM price guide
      const avg7F = pg["avg7-foil"] || 0;
      const avg30F = pg["avg30-foil"] || 0;
      const c7F = (foilPrice > 0 && avg7F > 0) ? round2(((foilPrice - avg7F) / avg7F) * 100) : 0;
      const c30F = (foilPrice > 0 && avg30F > 0) ? round2(((foilPrice - avg30F) / avg30F) * 100) : 0;
      const l30F = round2(pg["low-foil"] || 0);
      const tF = round2(trendFoil);

      const avg7Nf = pg.avg7 || 0;
      const avg30Nf = pg.avg30 || 0;
      const c7Nf = (nonFoilPrice > 0 && avg7Nf > 0) ? round2(((nonFoilPrice - avg7Nf) / avg7Nf) * 100) : 0;
      const c30Nf = (nonFoilPrice > 0 && avg30Nf > 0) ? round2(((nonFoilPrice - avg30Nf) / avg30Nf) * 100) : 0;
      const l30Nf = round2(pg.low || 0);
      const tNf = round2(trendNonFoil);

      // Primary variant stats (backward compat for sorting/movers)
      const c7 = isPrimaryFoil ? c7F : c7Nf;
      const c30 = isPrimaryFoil ? c30F : c30Nf;

      prices[cmId] = {
        n: product.name,
        p: round2(primaryPrice),
        pF: round2(foilPrice),
        pNf: round2(nonFoilPrice),
        c24: 0, // placeholder — computed from stored history in merge loop
        c7,
        c30,
        l30: round2(isPrimaryFoil ? (l30F || primaryPrice) : (l30Nf || primaryPrice)),
        h30: round2(isPrimaryFoil ? (tF || primaryPrice) : (tNf || primaryPrice)),
        // Per-variant stats
        l30F, l30Nf,
        tF, tNf,
        c7F, c7Nf,
        c30F, c30Nf,
        r: rarity,
        s: setId,
        vi: variantIndex,
        sp: "",
      };

      // ── Phase A: history points = pg.trend directly (= consistent with
      //    prices[cmId].p which is also stored as trend). Old logic used
      //    Math.max(trend, low) to "prevent unrealistic dips on low-
      //    liquidity cards", but in practice that locked in inflated
      //    Pre-Release/Discovery-Phase trend values for new sets — the
      //    Cardmarket trend takes weeks to catch down to reality after a
      //    set drop, while `low` already reflects the post-launch market.
      //    Daily history-points captured the inflated trend, then when
      //    trend finally normalized we'd see phantom -98% c24 events
      //    (Blazing Scorcher OGN #1 Common: history decayed €4.81 → €0.02
      //    over 11 days, today's c24=-98.1% from yesterday's stored
      //    €1.05 → today's €0.02). Trend-only writes a CONSISTENT signal
      //    matching what we display as currentPrice.
      //
      // ── Phase D: Outlier-Detection on top of trend.
      //    spikeGuard(...) handles upward spikes (single inflated listing
      //    pushes trend >>2x avg7) by falling back to avg7. Movement-check
      //    against yesterday's stored point happens later in the merge
      //    loop — see "OUTLIER GUARD" block ~Z. 880.
      const histFoil = spikeGuard(foilPrice, avg7F, cmId, "Foil");
      const histNf = spikeGuard(nonFoilPrice, avg7Nf, cmId, "NonFoil");
      // Spike-corrected display-price: when spikeGuard fired (histX !=
      // raw), clamp the displayed pF/pNf/p to the spike-corrected value
      // so display + history + c24 stay in sync. Otherwise pNf zeigt den
      // anomalen Tageswert (e.g. 0.44), mergedNf hat den korrigierten
      // (e.g. 0.11) → c24 wird 340% statt 10% (Calm Rune SFD 2026-04-28).
      // Wichtig: AUCH wenn movementGuard spaeter im merge-loop NICHT
      // feuert (weil die spike-korrigierte history sane gegen yesterday
      // ist), bleibt das Display sonst ueber-anomal — siehe SFD-Swap-Pfad.
      if (foilPrice > 0 && histFoil > 0 && Math.abs(histFoil - foilPrice) > 0.001) {
        prices[cmId].pF = round2(histFoil);
        if (isPrimaryFoil) prices[cmId].p = round2(histFoil);
      }
      if (nonFoilPrice > 0 && histNf > 0 && Math.abs(histNf - nonFoilPrice) > 0.001) {
        prices[cmId].pNf = round2(histNf);
        if (!isPrimaryFoil) prices[cmId].p = round2(histNf);
      }
      historyWrites.push({
        cmId,
        isPrimaryFoil,
        foilPoint: histFoil > 0 ? { t: today, p: round2(histFoil) } : null,
        nonFoilPoint: histNf > 0 ? { t: today, p: round2(histNf) } : null,
      });

      matched++;
    }
  }

  console.log(`Matched: ${matched} cards with prices, ${noPrice} without`);

  // ── Process Plated Legend (Memorabilia) products ──
  // Check price guide first (future-proof). If not in guide, preserve
  // existing prices from previous overview so manually-seeded data persists.
  const prevPrices = existingOverview.exists ? (existingOverview.data().prices || {}) : {};
  let metalMatched = 0;

  for (const [idStr, meta] of Object.entries(PLATED_LEGEND_IDS)) {
    const cmId = String(idStr);
    const pg = priceMap[Number(idStr)];

    if (pg) {
      // Price guide has data (may happen in the future)
      const foilPrice = pg["trend-foil"] || 0;
      const nonFoilPrice = pg.trend || 0;
      const primaryPrice = nonFoilPrice > 0 ? nonFoilPrice : foilPrice;
      if (primaryPrice > 0) {
        prices[cmId] = {
          n: meta.name,
          p: round2(primaryPrice),
          pF: round2(foilPrice),
          pNf: round2(nonFoilPrice),
          c24: 0, c7: 0, c30: 0,
          l30: round2(pg.low || pg["low-foil"] || primaryPrice),
          h30: round2(pg.trend || pg["trend-foil"] || primaryPrice),
          l30F: round2(pg["low-foil"] || 0),
          l30Nf: round2(pg.low || 0),
          tF: round2(pg["trend-foil"] || 0),
          tNf: round2(pg.trend || 0),
          c7F: 0, c7Nf: 0, c30F: 0, c30Nf: 0,
          r: "Metal", s: meta.set, vi: 0, sp: "", metal: true,
        };
        const metalLowF = round2(pg["low-foil"] || 0);
        const metalLowNf = round2(pg.low || 0);
        const metalHistF = foilPrice > 0 ? Math.max(foilPrice, metalLowF) : 0;
        const metalHistNf = nonFoilPrice > 0 ? Math.max(nonFoilPrice, metalLowNf) : 0;
        historyWrites.push({
          cmId, isPrimaryFoil: false,
          foilPoint: metalHistF > 0 ? { t: today, p: round2(metalHistF) } : null,
          nonFoilPoint: metalHistNf > 0 ? { t: today, p: round2(metalHistNf) } : null,
        });
        metalMatched++;
        continue;
      }
    }

    // Not in price guide — preserve previous overview price if available
    if (prevPrices[cmId]) {
      prices[cmId] = { ...prevPrices[cmId], n: meta.name, s: meta.set, metal: true };
      // Push history point so Metal cards build up chart data over time
      const metalPrice = prices[cmId].pNf || prices[cmId].pF || prices[cmId].p;
      if (metalPrice > 0) {
        historyWrites.push({
          cmId,
          isPrimaryFoil: false,
          foilPoint: null,
          nonFoilPoint: { t: today, p: round2(metalPrice) },
        });
      }
      metalMatched++;
    }
  }
  console.log(`Metal cards: ${metalMatched} of ${Object.keys(PLATED_LEGEND_IDS).length} preserved`);

  // Fix: Cardmarket has prices swapped between SFD Common/Showcase Rune pairs.
  // Swap all price values between each pair so Common gets cents and Showcase gets euros.
  const SFD_RUNE_SWAP = {
    "871893": "872478",  // Fury Rune Common ↔ Showcase
    "871894": "872479",  // Calm Rune
    "871895": "872480",  // Mind Rune
    "871896": "872481",  // Body Rune
    "871897": "872482",  // Chaos Rune
    "871898": "872483",  // Order Rune
  };
  const priceFields = ["pF", "pNf", "p", "l30", "h30", "l30F", "l30Nf", "tF", "tNf", "c7", "c30", "c7F", "c7Nf", "c30F", "c30Nf", "sp"];
  for (const [cmA, cmB] of Object.entries(SFD_RUNE_SWAP)) {
    if (prices[cmA] && prices[cmB]) {
      for (const f of priceFields) {
        const tmp = prices[cmA][f];
        prices[cmA][f] = prices[cmB][f];
        prices[cmB][f] = tmp;
      }
    }
  }

  // Also swap historyWrites for SFD Rune pairs so the correct (post-swap)
  // prices are written to the correct history documents.
  const hwIndex = {};
  for (let i = 0; i < historyWrites.length; i++) hwIndex[historyWrites[i].cmId] = i;
  for (const [cmA, cmB] of Object.entries(SFD_RUNE_SWAP)) {
    const iA = hwIndex[cmA], iB = hwIndex[cmB];
    if (iA !== undefined && iB !== undefined) {
      const tmpFoil = historyWrites[iA].foilPoint;
      const tmpNf = historyWrites[iA].nonFoilPoint;
      const tmpPrimary = historyWrites[iA].isPrimaryFoil;
      historyWrites[iA].foilPoint = historyWrites[iB].foilPoint;
      historyWrites[iA].nonFoilPoint = historyWrites[iB].nonFoilPoint;
      historyWrites[iA].isPrimaryFoil = historyWrites[iB].isPrimaryFoil;
      historyWrites[iB].foilPoint = tmpFoil;
      historyWrites[iB].nonFoilPoint = tmpNf;
      historyWrites[iB].isPrimaryFoil = tmpPrimary;
    }
  }

  // Write initial overview (c24 computed after history merge)
  await marketRef.doc("overview").set({
    prices,
    source: "cardmarket",
    priceSource: "trend-v1",
    topGainers: [],
    topLosers: [],
    cardCount: Object.keys(prices).length,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`Overview written (${Object.keys(prices).length} cards)`);

  // ── Merge history ──

  console.log(`Merging history for ${historyWrites.length} cards...`);
  const BATCH_LIMIT = 100;
  let batch = db.batch();
  let opCount = 0;
  let batchNum = 0;

  const CHUNK_SIZE = 100;
  for (let i = 0; i < historyWrites.length; i += CHUNK_SIZE) {
    const chunk = historyWrites.slice(i, i + CHUNK_SIZE);
    const existingDocs = await Promise.all(
      chunk.map(({ cmId }) => historyRef.doc(cmId).get())
    );

    for (let j = 0; j < chunk.length; j++) {
      let { cmId, isPrimaryFoil, foilPoint, nonFoilPoint } = chunk[j];
      const existingDoc = existingDocs[j];

      // Load existing point counts for safety validation
      const existingFoilCount = existingDoc.exists ? (existingDoc.data().points || []).length : 0;
      const existingNfCount = existingDoc.exists ? (existingDoc.data().pointsNf || []).length : 0;

      // ── OUTLIER GUARD (Phase D) ──
      // movementGuard catches >2x or <0.5x ratio against yesterday's
      // stored point. When the ratio is implausible:
      //   1. skip writing today's history point (yesterday stays latest)
      //   2. ALSO clamp prices[cmId].pF / pNf / p to yesterday's value
      //      so display + history + c24 stay in sync. Otherwise pNf zeigt
      //      den anomalen Tageswert, mergedNf hat ihn nicht → c24 wird
      //      gegen den nicht-geblockten Wert gerechnet und es gibt einen
      //      Phantom-Movement (Calm Rune SFD c24=+340% am 2026-04-28 weil
      //      0.44 Display-Preis gegen 0.10 History-Baseline gerechnet).
      const existingFoilPts = existingDoc.exists ? (existingDoc.data().points || []) : [];
      const existingNfPts = existingDoc.exists ? (existingDoc.data().pointsNf || []) : [];
      const lastFoilPt = existingFoilPts.length > 0 ? existingFoilPts[existingFoilPts.length - 1] : null;
      const lastNfPt = existingNfPts.length > 0 ? existingNfPts[existingNfPts.length - 1] : null;
      if (foilPoint && lastFoilPt && movementGuard(foilPoint.p, lastFoilPt.p, cmId, "Foil")) {
        foilPoint = null;
        if (prices[cmId]) {
          prices[cmId].pF = round2(lastFoilPt.p);
          if (isPrimaryFoil) prices[cmId].p = round2(lastFoilPt.p);
        }
      }
      if (nonFoilPoint && lastNfPt && movementGuard(nonFoilPoint.p, lastNfPt.p, cmId, "NonFoil")) {
        nonFoilPoint = null;
        if (prices[cmId]) {
          prices[cmId].pNf = round2(lastNfPt.p);
          if (!isPrimaryFoil) prices[cmId].p = round2(lastNfPt.p);
        }
      }

      // Merge foil history: load existing + append today's price
      const foilMap = new Map();
      if (existingDoc.exists) {
        const existing = existingDoc.data().points || [];
        for (const p of existing) foilMap.set(p.t, p.p);
      }
      if (foilPoint) foilMap.set(foilPoint.t, foilPoint.p);

      const mergedFoil = Array.from(foilMap.entries())
        .sort((a, b) => a[0] - b[0])
        .map(([t, p]) => ({ t, p }));

      // Merge non-foil history: load existing + append today's price
      const nfMap = new Map();
      if (existingDoc.exists) {
        const existing = existingDoc.data().pointsNf || [];
        for (const p of existing) nfMap.set(p.t, p.p);
      }
      if (nonFoilPoint) nfMap.set(nonFoilPoint.t, nonFoilPoint.p);

      const mergedNf = Array.from(nfMap.entries())
        .sort((a, b) => a[0] - b[0])
        .map(([t, p]) => ({ t, p }));

      // ═══ DATA SAFETY CHECK ═══
      // NEVER allow a write that would lose existing data points.
      // merged count must be >= existing count (can only grow or stay same).
      if (mergedFoil.length < existingFoilCount || mergedNf.length < existingNfCount) {
        console.error(`🚨 DATA LOSS PREVENTED for ${cmId}: foil ${existingFoilCount}→${mergedFoil.length}, nf ${existingNfCount}→${mergedNf.length} — SKIPPING WRITE`);
        continue;
      }

      // Sparkline from standard variant
      const standardHistory = isPrimaryFoil ? mergedFoil : mergedNf;
      const sparkCsv = standardHistory.slice(-180).map((p) => p.p).join(",");

      if (prices[cmId]) {
        prices[cmId].sp = sparkCsv;

        // Compute c24 per variant from own history (most recent point before today).
        // After history migration + historyWrite swap, each doc has its correct prices.
        const prevFoilPts = mergedFoil.filter((pt) => pt.t < today);
        if (prevFoilPts.length > 0 && prices[cmId].pF > 0) {
          const prev = prevFoilPts[prevFoilPts.length - 1].p;
          if (prev > 0) prices[cmId].c24F = round2(((prices[cmId].pF - prev) / prev) * 100);
        }

        const prevNfPts = mergedNf.filter((pt) => pt.t < today);
        if (prevNfPts.length > 0 && prices[cmId].pNf > 0) {
          const prev = prevNfPts[prevNfPts.length - 1].p;
          if (prev > 0) prices[cmId].c24Nf = round2(((prices[cmId].pNf - prev) / prev) * 100);
        }

        // Primary c24 (backward compat for sorting/movers)
        prices[cmId].c24 = isPrimaryFoil
          ? (prices[cmId].c24F || 0)
          : (prices[cmId].c24Nf || 0);
      }

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batchNum++;
        console.log(`History batch ${batchNum} committed (${opCount} docs)`);
        batch = db.batch();
        opCount = 0;
      }

      const historyDoc = {
        points: mergedFoil,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (mergedNf.length > 0) historyDoc.pointsNf = mergedNf;

      batch.set(historyRef.doc(cmId), historyDoc);
      opCount++;
    }
  }

  if (opCount > 0) {
    await batch.commit();
    batchNum++;
    console.log(`History batch ${batchNum} committed (${opCount} docs)`);
  }

  // Compute top movers (c24 now populated from stored history)
  const allC24 = Object.values(prices).map(v => v.c24 || 0);
  const pos = allC24.filter(c => c > 0).length;
  const neg = allC24.filter(c => c < 0).length;
  const zero = allC24.filter(c => c === 0).length;
  console.log(`c24 stats: ${pos} positive, ${neg} negative, ${zero} zero (total ${allC24.length})`);
  if (pos > 0) {
    const topPos = Object.entries(prices).filter(([,v]) => (v.c24||0) > 0).sort((a,b) => b[1].c24 - a[1].c24).slice(0,3);
    for (const [id, v] of topPos) console.log(`  TOP GAINER: ${v.n} c24=${v.c24}% p=${v.p} pF=${v.pF} pNf=${v.pNf}`);
  }
  const entries = Object.entries(prices).filter(([, v]) => v.c24 !== 0);
  entries.sort((a, b) => b[1].c24 - a[1].c24);

  const topGainers = entries
    .filter(([, v]) => v.c24 > 0)
    .slice(0, 10)
    .map(([id, v]) => ({ id, n: v.n, c: v.c24, p: v.p }));

  const topLosers = entries
    .filter(([, v]) => v.c24 < 0)
    .slice(-10)
    .reverse()
    .map(([id, v]) => ({ id, n: v.n, c: v.c24, p: v.p }));

  // Re-write overview with sparklines + c24 + top movers
  await marketRef.doc("overview").set({
    prices,
    source: "cardmarket",
    priceSource: "trend-v1",
    topGainers,
    topLosers,
    cardCount: Object.keys(prices).length,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log("Overview re-written with sparklines + c24");

  const result = {
    cardsUpdated: Object.keys(prices).length,
    historyDocs: historyWrites.length,
    source: "cardmarket",
  };
  console.log("Update complete:", result);
  return result;
}

// ── Cloud Functions ──

exports.fetchPricesDaily = onSchedule(
  {
    schedule: "0 6 * * *",
    timeZone: "Europe/Berlin",
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async () => {
    const result = await updatePrices();
    console.log("Daily price update:", result);
  }
);

exports.fetchPricesManual = onRequest(
  {
    timeoutSeconds: 540,
    memory: "512MiB",
    secrets: ["ADMIN_TRIGGER_SECRET"],
  },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    console.log("Manual fetch triggered");
    try {
      const result = await updatePrices();
      res.json({ success: true, ...result });
    } catch (error) {
      console.error("Manual fetch failed:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════
// ─── Email Verification (Seller Onboarding) ───
// ═══════════════════════════════════════════

// crypto is required at the top of the file (used by requireAdminSecret + email codes)
const RESEND_API_KEY = process.env.RESEND_API_KEY || "";

/**
 * sendVerificationCode — Callable, authenticated.
 * Generates a 6-digit code, stores it in Firestore, sends via email.
 */
exports.sendVerificationCode = onCall(
  { region: "europe-west1", timeoutSeconds: 15, secrets: ["RESEND_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { email } = request.data;
    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email required");
    }

    // ─── Rate-Limit (Security-Audit Round 2, 2026-04-29) ─────────────
    // Schuetzt vor:
    //   1. E-Mail-Bombing: User schickt 10000x sendVerificationCode mit
    //      victim@example.com → 10000 Verification-Mails ans Opfer auf
    //      Riftr-Resend-Kosten + Reputation-Risiko (Resend kann uns
    //      sperren wenn Spam-Reports kommen).
    //   2. Brute-Force-Reset-Loop: Code wird per Send invalidiert; ohne
    //      Limit kann Angreifer beliebig oft Reset → 5-Attempts-Limit
    //      pro Code wird nutzlos (immer neuer Code, neue 5 Attempts).
    // Limit: 5 Codes pro UID pro Tag (UTC). Counter im
    // emailVerification-Doc (gleicher Doc den wir gleich schreiben).
    const verifyRef = db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("emailVerification");

    const today = new Date().toISOString().slice(0, 10); // "YYYY-MM-DD" UTC
    const existing = await verifyRef.get();
    if (existing.exists) {
      const data = existing.data();
      if (data.rateLimitDate === today && (data.sendCountToday || 0) >= 5) {
        throw new HttpsError(
          "resource-exhausted",
          "Too many verification attempts today. Please try again tomorrow."
        );
      }
    }

    // Generate 6-digit code
    const code = crypto.randomInt(100000, 999999).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store code (hashed) in Firestore
    const codeHash = crypto.createHash("sha256").update(code).digest("hex");
    const newCount = existing.exists && existing.data().rateLimitDate === today
      ? (existing.data().sendCountToday || 0) + 1
      : 1;
    await verifyRef.set({
      email,
      codeHash,
      expiresAt: expiresAt.toISOString(),
      attempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      rateLimitDate: today,
      sendCountToday: newCount,
    });

    // Send email via Resend API
    if (!RESEND_API_KEY) {
      throw new HttpsError("failed-precondition", "Email service not configured");
    }

    const emailHtml = `
      <div style="font-family: -apple-system, sans-serif; max-width: 400px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #333;">Riftr Seller Verification</h2>
        <p style="color: #666;">Your verification code is:</p>
        <div style="background: #f5f5f5; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #d4a020;">${code}</span>
        </div>
        <p style="color: #999; font-size: 12px;">This code expires in 10 minutes. If you didn't request this, ignore this email.</p>
      </div>
    `;

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Riftr <onboarding@resend.dev>",
        to: [email],
        subject: "Your Riftr Verification Code",
        html: emailHtml,
      }),
    });

    if (!resendResponse.ok) {
      const errBody = await resendResponse.text();
      console.error(`Resend API error: ${resendResponse.status} ${errBody}`);
      throw new HttpsError("internal", "Failed to send verification email");
    }

    // Security-Audit Round 3 (2026-04-29): kein `email` mehr in Cloud-Logs
    // (DSGVO-relevant, war mildes PII-Leak — Logs werden an Datenexport-
    // Anfragen herausgegeben muessen). Email-Hash via crypto loggen wenn
    // Forensik noetig ist; UID alleine reicht fuer normale Ops.
    console.log(`Verification code sent for uid ${uid}`);
    return { success: true };
  }
);

/**
 * verifyEmailCode — Callable, authenticated.
 * Checks the 6-digit code and marks email as verified.
 */
exports.verifyEmailCode = onCall(
  { region: "europe-west1", timeoutSeconds: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { code } = request.data;
    if (!code || code.length !== 6) {
      throw new HttpsError("invalid-argument", "6-digit code required");
    }

    const verRef = db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("emailVerification");

    const verDoc = await verRef.get();
    if (!verDoc.exists) {
      throw new HttpsError("not-found", "No verification pending");
    }

    const data = verDoc.data();

    // Check expiry
    if (new Date(data.expiresAt) < new Date()) {
      throw new HttpsError("deadline-exceeded", "Code expired. Request a new one.");
    }

    // Check max attempts (prevent brute force)
    if (data.attempts >= 5) {
      throw new HttpsError("resource-exhausted", "Too many attempts. Request a new code.");
    }

    // Increment attempts
    await verRef.update({ attempts: admin.firestore.FieldValue.increment(1) });

    // Verify code
    const codeHash = crypto.createHash("sha256").update(code).digest("hex");
    if (codeHash !== data.codeHash) {
      throw new HttpsError("permission-denied", "Invalid code");
    }

    // Mark email as verified in seller profile
    await db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("sellerProfile")
      .set(
        {
          email: data.email,
          emailVerified: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    // Clean up verification doc
    await verRef.delete();

    // Security-Audit Round 3 (2026-04-29): kein `email` mehr in Cloud-Logs.
    // Return-value behaelt email weil das App-Side-only ist (an den User
    // selbst zurueck, nicht in Logs).
    console.log(`Email verified for uid ${uid}`);
    return { success: true, email: data.email };
  }
);

// ═══════════════════════════════════════════
// ─── Stripe Connect (Seller Onboarding) ───
// ═══════════════════════════════════════════

const STRIPE_SECRET = (process.env.STRIPE_SECRET_KEY || "").trim();
const STRIPE_WEBHOOK_SECRET = (process.env.STRIPE_WEBHOOK_SECRET || "").trim();
// Stripe Connect Onboarding Return-URLs.
// VORHER: "https://getriftr.app" (Marketing-Site) — alle URLs landeten dort
// auf der Landing-Page (catch-all rewrite), Verkaeufer sah nach KYC keine
// klare „Setup-Complete"-Bestaetigung, sondern die generelle Marketing-Page.
// JETZT: dedicated Web-App-Hosting mit echten stripe-return.html /
// stripe-refresh.html — User bekommt nach KYC eine klare Erfolgs-Page mit
// Hinweis „Du kannst zur App zurueck wechseln". Hosting-Site ist nach
// Web-App-Offline-Schaltung (2026-04-29) bewusst minimal — nur die zwei
// Stripe-Pages und ein App-Store-Hinweis-Lander.
const RETURN_BASE = "https://riftr-10527.web.app";

function getStripe() {
  if (!STRIPE_SECRET) {
    throw new HttpsError("failed-precondition", "Stripe not configured");
  }
  return require("stripe")(STRIPE_SECRET);
}

// ═══════════════════════════════════════════
// ─── Wallet Helper Functions ───
// ═══════════════════════════════════════════

/**
 * Ensure a Stripe Customer exists for the given user.
 * Creates one + initialises wallet/balance and trustLevel docs if needed.
 * Returns the Stripe Customer ID.
 */
async function ensureStripeCustomer(uid) {
  const stripeDoc = await db.doc(`artifacts/${APP_ID}/users/${uid}/data/stripe`).get();
  if (stripeDoc.exists && stripeDoc.data().customerId) {
    return stripeDoc.data().customerId;
  }

  // Fetch email from profile
  const profileDoc = await db.doc(`artifacts/${APP_ID}/users/${uid}/data/profile`).get();
  const email = profileDoc.exists ? (profileDoc.data().email || null) : null;

  const stripe = getStripe();
  const customer = await stripe.customers.create({
    email,
    metadata: { uid, platform: "riftr" },
  });

  await db.doc(`artifacts/${APP_ID}/users/${uid}/data/stripe`).set({
    customerId: customer.id,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Initial wallet balance doc
  const balDoc = db.doc(`artifacts/${APP_ID}/users/${uid}/wallet/balance`);
  const balSnap = await balDoc.get();
  if (!balSnap.exists) {
    await balDoc.set({
      amount: 0,
      pendingEscrow: 0,
      available: 0,
      frozen: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Initial trust level doc
  const trustDoc = db.doc(`artifacts/${APP_ID}/users/${uid}/data/trustLevel`);
  const trustSnap = await trustDoc.get();
  if (!trustSnap.exists) {
    await trustDoc.set({
      level: "new",
      accountAge: 0,
      completedPurchases: 0,
      completedSales: 0,
      activeStrikes: 0,
      totalDisputes: 0,
      lastDisputeAt: null,
      flags: [],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  console.log(`Stripe Customer ${customer.id} created for uid ${uid}`);
  return customer.id;
}

/** Get existing Stripe Customer ID or throw. */
async function getStripeCustomerId(uid) {
  const doc = await db.doc(`artifacts/${APP_ID}/users/${uid}/data/stripe`).get();
  if (!doc.exists || !doc.data().customerId) {
    throw new HttpsError("failed-precondition", "No Stripe customer — call ensureStripeCustomer first");
  }
  return doc.data().customerId;
}

/** Get trust level document for a user. Returns defaults for missing docs. */
async function getTrustLevel(uid) {
  const doc = await db.doc(`artifacts/${APP_ID}/users/${uid}/data/trustLevel`).get();
  if (!doc.exists) {
    return { level: "new", accountAge: 0, completedPurchases: 0, completedSales: 0, activeStrikes: 0, totalDisputes: 0, flags: [] };
  }
  return doc.data();
}

// NOTE (Phase 2, 2026-04-28): Helpers `getBalance`, `getAvailableBalance`,
// `countTodayTopUps`, `countHourlyPurchases`, `getTodayPayoutTotal` wurden
// entfernt — sie wurden nur von den geloeschten Wallet-Buy-Functions
// (topUpBalance / purchaseWithBalance / requestPayout) genutzt.

/** Log a wallet transaction and return the doc ref. */
async function logTransaction(uid, type, amount, orderId, description, fee = 0, transferId = null, piId = null) {
  const ref = db.collection(`artifacts/${APP_ID}/users/${uid}/walletTransactions`).doc();
  await ref.set({
    type,
    amount,
    orderId: orderId || null,
    description: description || "",
    platformFee: fee || 0,
    stripePaymentIntentId: piId || null,
    stripeTransferId: transferId || null,
    status: "completed",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return ref;
}

/**
 * Recalculate and cache the user's wallet balance.
 * Reads Stripe customer.balance, computes escrow and frozen state.
 * Available = total - escrow (no hold periods).
 */
async function updateBalanceCache(uid) {
  const stripe = getStripe();
  const customerId = await getStripeCustomerId(uid);
  const customer = await stripe.customers.retrieve(customerId);
  // Stripe: negative = credit. Convert to positive cents for display.
  const totalBalance = Math.abs(Math.min(customer.balance, 0));

  // Escrow: open orders where this user is the seller
  const pendingOrders = await db.collection(`artifacts/${APP_ID}/orders`)
    .where("sellerId", "==", uid)
    .where("status", "in", ["paid", "shipped"])
    .where("paymentMethod", "==", "balance")
    .get();
  let pendingEscrow = 0;
  pendingOrders.forEach(doc => {
    pendingEscrow += Math.round((doc.data().sellerPayout || 0) * 100);
  });

  // Frozen state
  const balDoc = await db.doc(`artifacts/${APP_ID}/users/${uid}/wallet/balance`).get();
  const frozen = balDoc.exists ? (balDoc.data().frozen || false) : false;

  const available = frozen ? 0 : Math.max(totalBalance - pendingEscrow, 0);

  await db.doc(`artifacts/${APP_ID}/users/${uid}/wallet/balance`).set({
    amount: totalBalance,
    pendingEscrow,
    available,
    frozen,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { amount: totalBalance, pendingEscrow, available };
}

/** Send alert email to admin (fire-and-forget). */
function sendAdminAlert(type, message) {
  console.warn(`[ADMIN ALERT] [${type}] ${message}`);
  // TODO: Send actual email via SendGrid/Mailgun in production
}

/**
 * createStripeAccount — Callable, authenticated.
 * Creates a Stripe Express connected account (or reuses existing) and
 * returns an onboarding URL.
 */
exports.createStripeAccount = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { country, email } = request.data;
    if (!country) {
      throw new HttpsError("invalid-argument", "Country is required");
    }

    const stripe = getStripe();
    const sellerRef = db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("sellerProfile");

    const sellerDoc = await sellerRef.get();

    // If account already exists, create a fresh link
    if (sellerDoc.exists && sellerDoc.data().stripeAccountId) {
      const accountId = sellerDoc.data().stripeAccountId;
      const link = await stripe.accountLinks.create({
        account: accountId,
        refresh_url: `${RETURN_BASE}/stripe-refresh`,
        return_url: `${RETURN_BASE}/stripe-return`,
        type: "account_onboarding",
      });
      return { url: link.url, accountId };
    }

    // Create new Express account
    const account = await stripe.accounts.create({
      type: "express",
      country: country.toUpperCase(),
      email: email || undefined,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      metadata: { uid },
    });

    // Save accountId to seller profile
    await sellerRef.set(
      {
        stripeAccountId: account.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Create onboarding link
    const link = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `${RETURN_BASE}/stripe-refresh`,
      return_url: `${RETURN_BASE}/stripe-return`,
      type: "account_onboarding",
    });

    console.log(`Stripe account ${account.id} created for uid ${uid}`);
    return { url: link.url, accountId: account.id };
  }
);

/**
 * createStripeAccountLink — Callable, authenticated.
 * Creates a fresh onboarding link for an existing Stripe account.
 */
exports.createStripeAccountLink = onCall(
  { region: "europe-west1", timeoutSeconds: 15, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const { accountId } = request.data;
    if (!accountId) {
      throw new HttpsError("invalid-argument", "accountId is required");
    }

    const stripe = getStripe();
    const link = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: `${RETURN_BASE}/stripe-refresh`,
      return_url: `${RETURN_BASE}/stripe-return`,
      type: "account_onboarding",
    });

    return { url: link.url };
  }
);

/**
 * stripeWebhook — HTTP endpoint (unauthenticated).
 * Handles Stripe account.updated events to mark seller as onboarded.
 */
exports.stripeWebhook = onRequest(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const stripe = getStripe();
    const sig = req.headers["stripe-signature"];
    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        STRIPE_WEBHOOK_SECRET
      );
    } catch (err) {
      console.error("Webhook signature verification failed:", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    // ─── Event-ID Deduplication (Security-Audit Round 4, 2026-04-29) ─────
    // Stripe schickt Events bei Network-Issues / Retries manchmal mehrfach.
    // Status-basierte Idempotenz fängt die meisten Branches (PI succeeded,
    // payment_failed, canceled), aber `charge.dispute.created` wuerde bei
    // Replay 2× Push an Seller + 2× Admin-Alert + 2× wallet.balance freezen
    // (idempotent aber laute Logs).
    //
    // Pattern: `firestore.create()` failed mit ALREADY_EXISTS wenn Doc da
    // ist — atomar, kein Race-Condition-Window. Wenn create erfolgreich →
    // Event ist neu → normal verarbeiten.
    //
    // Stripe-Event-IDs sind globally unique (`evt_xxx`) — sicher als Key.
    const stripeEventRef = db.collection("artifacts").doc(APP_ID)
      .collection("stripe_events").doc(event.id);
    try {
      await stripeEventRef.create({
        eventId: event.id,
        type: event.type,
        livemode: !!event.livemode,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (createErr) {
      // ALREADY_EXISTS → Replay, schon verarbeitet, einfach 200 zurueck.
      // Andere Errors → loggen + weiterverarbeiten (lieber doppelt als gar
      // nicht — nur ALREADY_EXISTS skipt).
      if (createErr.code === 6 /* ALREADY_EXISTS */ ||
          (createErr.message || "").includes("already exists")) {
        console.log(
          `Stripe webhook replay detected: event ${event.id} (${event.type}) ` +
          `already processed, returning 200 ohne Re-Run`,
        );
        res.status(200).send("ok-already-processed");
        return;
      }
      console.warn(
        `stripe_events.create failed for ${event.id}: ${createErr.message} — ` +
        `proceeding without dedup-record (event will run)`,
      );
    }

    if (event.type === "account.updated") {
      const account = event.data.object;
      const uid = account.metadata?.uid;
      if (!uid) {
        console.log("account.updated: no uid in metadata, skipping");
        res.status(200).send("ok");
        return;
      }

      const isOnboarded =
        account.charges_enabled &&
        account.payouts_enabled &&
        account.details_submitted;

      // ── Bank-Detail-Change ATO Detection (Round 8 Pen-Test, 2026-04-29) ──
      // Stripe-Connect Account-Takeover-Pattern (Stripe-Empfehlung):
      //   1. Attacker phishes Seller-Email-Credentials
      //   2. Attacker logged in Stripe-Express-Dashboard via Magic-Link
      //   3. Attacker aendert external_account (Bank-Konto) auf eigenes
      //   4. Naechste Auszahlung geht an Attacker → Seller-Geld weg
      // Defense: bei jeder account.updated detectieren wir external_account-
      // Aenderungen via Vergleich mit gecachtem Fingerprint, pausen Payouts
      // und alarmieren Admin + Seller. Stripe rate-limit zwingt eh delay,
      // Riftr-side audit gibt Forensik + Recovery-Pfad.
      const sellerProfRef = db
        .collection("artifacts").doc(APP_ID)
        .collection("users").doc(uid)
        .collection("data").doc("sellerProfile");
      const sellerProfDoc = await sellerProfRef.get();
      const existingExtAccountId = sellerProfDoc.exists
        ? (sellerProfDoc.data().stripeExternalAccountId || null)
        : null;
      const newExtAccount = (account.external_accounts?.data || [])[0];
      const newExtAccountId = newExtAccount?.id || null;

      const updatePayload = {
        stripeOnboarded: isOnboarded,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Bank-Wechsel detected: nur wenn vorher schon einer existierte
      // (sonst ist es das initiale Onboarding, kein Takeover).
      const isBankChange = existingExtAccountId
        && newExtAccountId
        && existingExtAccountId !== newExtAccountId;

      if (isBankChange) {
        console.warn(
          `🚨 ATO-WARN: Stripe account ${account.id} (uid=${uid}) external_account ` +
          `changed: ${existingExtAccountId} → ${newExtAccountId}. ` +
          `Pausing payouts via Riftr-flag.`,
        );
        updatePayload.payoutsPausedReason = "external_account_changed";
        updatePayload.payoutsPausedAt = admin.firestore.FieldValue.serverTimestamp();
        updatePayload.previousExternalAccountId = existingExtAccountId;
        updatePayload.stripeExternalAccountId = newExtAccountId;
        // Push an Seller damit er WEISS dass etwas geaendert wurde
        // (legitim oder nicht — er kann reagieren).
        try {
          sendNotification(
            uid,
            "⚠️ Bankverbindung geaendert",
            "Deine Stripe-Bankverbindung wurde geaendert. " +
            "Falls du das nicht warst, kontaktiere uns SOFORT — " +
            "Auszahlungen sind aus Sicherheitsgruenden pausiert.",
            { type: "security", severity: "high" },
          );
          sendAdminAlert(
            "STRIPE_BANK_CHANGE",
            `Seller ${uid} (account ${account.id}) external_account ` +
            `changed: ${existingExtAccountId} → ${newExtAccountId}. ` +
            `Payouts paused. Manual review required.`,
          );
        } catch (alertErr) {
          console.error(`Bank-Change Alert dispatch failed: ${alertErr.message}`);
        }
      } else if (newExtAccountId && !existingExtAccountId) {
        // Initiales Onboarding: external_account zum ersten Mal gesetzt.
        // Cache fuer spaetere Vergleiche.
        updatePayload.stripeExternalAccountId = newExtAccountId;
      }

      await sellerProfRef.set(updatePayload, { merge: true });

      console.log(
        `Stripe account ${account.id} for uid ${uid}: onboarded=${isOnboarded}` +
        (isBankChange ? " ⚠️ BANK CHANGE DETECTED" : ""),
      );
    }

    // ── Buyer-Auth erfolgreich (capture_method: manual) ─────────────
    // createPaymentIntent setzt capture_method:"manual". Stripe feuert
    // `payment_intent.amount_capturable_updated` direkt nach erfolgreicher
    // Buyer-Authorisierung (vor Capture). Hier flippen wir Order
    // pending_payment → paid + benachrichtigen Verkaeufer. Capture selbst
    // passiert spaeter in `markShipped`, wo `payment_intent.succeeded`
    // dann nur noch idempotent durchlaeuft (Order ist schon "paid").
    if (event.type === "payment_intent.amount_capturable_updated") {
      const pi = event.data.object;
      const orderId = pi.metadata?.orderId;
      if (orderId) {
        const orderRef = db.collection("artifacts").doc(APP_ID)
          .collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();
        if (orderDoc.exists && orderDoc.data().status === "pending_payment") {
          await orderRef.update({
            status: "paid",
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`Order ${orderId}: amount_capturable_updated → status=paid`);
          const whOrder = orderDoc.data();
          const whSummary = orderItemsSummary(whOrder.items);
          sendNotification(whOrder.sellerId, "New order!", `${whSummary} — €${(whOrder.totalPaid || 0).toFixed(2)}. Ship within 7 days.`, { type: "order", orderId });
        }
      }
    }

    // Handle PaymentIntent events for order status updates.
    // payment_intent.succeeded fires AFTER capture (markShipped called
    // paymentIntents.capture). For our manual-capture flow this means the
    // order is already in "paid" status from amount_capturable_updated;
    // this handler is therefore idempotent — only triggers if the order
    // somehow missed the capturable_updated event (defensive fallback).
    if (event.type === "payment_intent.succeeded") {
      const pi = event.data.object;
      const orderId = pi.metadata?.orderId;
      if (orderId) {
        const orderRef = db.collection("artifacts").doc(APP_ID)
          .collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();
        if (orderDoc.exists && orderDoc.data().status === "pending_payment") {
          await orderRef.update({
            status: "paid",
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`Order ${orderId} payment confirmed via webhook (succeeded fallback)`);
          const whOrder = orderDoc.data();
          const whSummary = orderItemsSummary(whOrder.items);
          sendNotification(whOrder.sellerId, "New order!", `${whSummary} — €${(whOrder.totalPaid || 0).toFixed(2)}. Ship within 7 days.`, { type: "order", orderId });
        }
      }
    }

    // Order auf cancelled flippen + Listing-Reservation freigeben.
    // Greift bei BEIDEN Events:
    //   - `payment_intent.payment_failed` → echte Decline (Card-Decline,
    //     Radar-Block, 3DS-Failed, etc.)
    //   - `payment_intent.canceled` → User dismissed PaymentSheet, oder die
    //     `cancelPendingOrder` CF hat den PI cancelled, oder Stripe-Auto-
    //     Expiry. Defensive Doppel-Sicherung gegen orphan pending_payment.
    if (
      event.type === "payment_intent.payment_failed" ||
      event.type === "payment_intent.canceled"
    ) {
      const pi = event.data.object;
      const orderId = pi.metadata?.orderId;
      if (orderId) {
        const orderRef = db.collection("artifacts").doc(APP_ID)
          .collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();
        if (orderDoc.exists && orderDoc.data().status === "pending_payment") {
          await orderRef.update({
            status: "cancelled",
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            cancelReason: event.type === "payment_intent.canceled"
              ? "payment_intent_canceled"
              : "payment_intent_failed",
          });
          // Release listing reservation
          const order = orderDoc.data();
          for (const item of (order.items || [])) {
            if (item.listingId) {
              const listingRef = db.collection("artifacts").doc(APP_ID)
                .collection("listings").doc(item.listingId);
              const listingDoc = await listingRef.get();
              if (listingDoc.exists) {
                const listing = listingDoc.data();
                const newReserved = Math.max(0, (listing.reservedQty || 0) - (item.quantity || 1));
                const updateData = { reservedQty: newReserved };
                if (listing.status === "reserved") updateData.status = "active";
                await listingRef.update(updateData);
              }
            }
          }
          console.log(`Order ${orderId} cancelled via webhook (${event.type})`);
        }
      }
    }

    // ── Chargeback: INSTANT account freeze + Verkaeufer-Push ──
    if (event.type === "charge.dispute.created") {
      const dispute = event.data.object;
      try {
        const disputePi = dispute.payment_intent
          ? await stripe.paymentIntents.retrieve(dispute.payment_intent)
          : null;
        const buyerUid = disputePi?.metadata?.buyerId || disputePi?.metadata?.uid;
        const chargebackOrderId = disputePi?.metadata?.orderId;
        const sellerUidFromPi = disputePi?.metadata?.sellerId;

        // Phase 6: Push an Verkaeufer der Chargeback-Order — der Seller
        // muss WISSEN dass eine Bestellung im Chargeback ist und ggf.
        // Tracking-Beleg / Versand-Beweis einreichen kann.
        if (chargebackOrderId && sellerUidFromPi) {
          sendNotification(
            sellerUidFromPi,
            "Chargeback gemeldet",
            `Käufer hat einen Chargeback bei der Bank eingereicht. ` +
            `Bitte sende uns deinen Tracking-Beleg / Versand-Beweis.`,
            { type: "order", orderId: chargebackOrderId },
          );
          console.log(
            `Chargeback-Push an Seller ${sellerUidFromPi} fuer Order ${chargebackOrderId}`,
          );
        }

        if (buyerUid) {
          // Suspend account
          await db.doc(`artifacts/${APP_ID}/users/${buyerUid}/data/trustLevel`).update({
            level: "suspended",
            flags: admin.firestore.FieldValue.arrayUnion("chargeback_dispute"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Freeze balance (legacy wallet — Phase 6+ has no functional balance,
          // aber das Frozen-Flag dient als Defensiv-Marker fuer alte Daten).
          try {
            await db.doc(`artifacts/${APP_ID}/users/${buyerUid}/wallet/balance`).update({
              available: 0,
              frozen: true,
              frozenReason: "chargeback_dispute",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          } catch (e) {
            // wallet/balance Doc existiert evtl. nicht (neue User) — kein Fehler.
            console.log(`Chargeback: wallet/balance freeze skipped for ${buyerUid}: ${e.message}`);
          }

          // Pause open orders (as buyer) — andere Verkaeufer warnen, nicht zu versenden
          const openOrders = await db.collection("artifacts").doc(APP_ID)
            .collection("orders")
            .where("buyerId", "==", buyerUid)
            .where("status", "in", ["paid", "shipped"])
            .get();
          for (const orderDoc of openOrders.docs) {
            await orderDoc.ref.update({
              status: "frozen",
              frozenReason: "buyer_chargeback",
            });
            sendNotification(
              orderDoc.data().sellerId,
              "Order paused",
              "An order has been temporarily paused. Please do not ship.",
              { type: "order", orderId: orderDoc.id }, // Bug-Fix: orderDoc.id (war undefined)
            );
          }

          sendAdminAlert("CHARGEBACK", `User ${buyerUid} chargeback. Account frozen.`);
          console.log(`CHARGEBACK: User ${buyerUid} frozen (dispute ${dispute.id})`);
        }
      } catch (err) {
        console.error("charge.dispute.created handler error:", err);
      }
    }

    // ── Chargeback resolved ──
    if (event.type === "charge.dispute.closed") {
      const dispute = event.data.object;
      try {
        const disputePi = dispute.payment_intent
          ? await stripe.paymentIntents.retrieve(dispute.payment_intent)
          : null;
        // Bug-Fix (Round 6 Audit-Folge, 2026-04-29): vorher `metadata?.uid`
        // — der Key existiert nicht. Wir setzen `buyerId` in PI-Metadata
        // (siehe createPaymentIntent + processMultiSellerCart). Konsequenz
        // des Bugs: bei Chargeback-WON wurde der User-Account nicht
        // automatisch entsperrt — Manual-Admin-Action war noetig.
        const disputeUid = disputePi?.metadata?.buyerId || disputePi?.metadata?.uid;
        if (disputeUid) {
          if (dispute.status === "won") {
            // We won — unfreeze account
            await db.doc(`artifacts/${APP_ID}/users/${disputeUid}/data/trustLevel`).update({
              level: "established",
              flags: admin.firestore.FieldValue.arrayRemove("chargeback_dispute"),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await db.doc(`artifacts/${APP_ID}/users/${disputeUid}/wallet/balance`).update({
              frozen: false,
              frozenReason: null,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await updateBalanceCache(disputeUid);
            console.log(`Chargeback WON for ${disputeUid}: account unfrozen`);
          } else {
            // We lost — keep suspended, deduct from balance
            console.log(`Chargeback LOST for ${disputeUid}: account remains suspended`);
            sendAdminAlert("CHARGEBACK_LOST", `User ${disputeUid} chargeback lost. Manual review needed.`);
          }
        }
      } catch (err) {
        console.error("charge.dispute.closed handler error:", err);
      }
    }

    // (Phase 2 cleanup, 2026-04-28) `transfer.paid` Handler entfernt — das
    // Event existiert in Stripe nicht (war Dead-Code aus dem alten Wallet-
    // requestPayout-Pfad). Stripe-Connect-Payouts an Verkäufer-Bank-Accounts
    // laufen automatisch ueber `delay_days` — kein Webhook-Handling noetig.

    res.status(200).send("ok");
  }
);

/**
 * confirmPayment — Called by Flutter after presentPaymentSheet() succeeds.
 * Verifies with Stripe that the PaymentIntent actually succeeded, then
 * updates order status to "paid". This is the primary confirmation path;
 * the webhook serves as a fallback.
 */
exports.confirmPayment = onCall(
  { region: "europe-west1", secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");

    const { orderId } = request.data;
    if (!orderId) throw new HttpsError("invalid-argument", "orderId required");

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) throw new HttpsError("not-found", "Order not found");

    const order = orderDoc.data();
    if (order.buyerId !== uid) {
      throw new HttpsError("permission-denied", "Not your order");
    }

    // Already paid — idempotent
    if (order.status === "paid") {
      return { success: true, alreadyPaid: true };
    }

    if (order.status !== "pending_payment") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected pending_payment`);
    }

    // Verify with Stripe
    const stripe = getStripe();
    const piId = order.stripePaymentIntentId;
    if (!piId) throw new HttpsError("failed-precondition", "No PaymentIntent on order");

    const pi = await stripe.paymentIntents.retrieve(piId);
    if (pi.status !== "succeeded") {
      console.log(`confirmPayment: PI ${piId} status is ${pi.status}, not succeeded`);
      throw new HttpsError("failed-precondition", `Payment not succeeded (status: ${pi.status})`);
    }

    // Confirmed — update order
    await orderRef.update({
      status: "paid",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Order ${orderId} payment confirmed via confirmPayment call`);

    // Notify seller about new order
    const cpSummary = orderItemsSummary(order.items);
    sendNotification(order.sellerId, "New order!", `${cpSummary} — €${(order.totalPaid || 0).toFixed(2)}. Ship within 7 days.`, { type: "order", orderId: orderId });

    return { success: true };
  }
);

// ═══════════════════════════════════════════
// ─── Marketplace: Buy Flow & Orders ───
// ═══════════════════════════════════════════

// Simplified shipping rates — MUSS mit Flutter `lib/data/shipping_rates.dart`
// (ShippingRates._routes) synchron gehalten werden. Drift fuehrt zu User-vs-
// Charge-Diskrepanz im Checkout (Frontend zeigt €X, Backend zieht €Y).
//
// TECH-DEBT (Phase 7+): Shipping-Rates zu shared JSON-Asset extrahieren, das
// beide Seiten lesen — keine Drift-Quelle mehr. Bis dahin: bei jeder Aenderung
// in shipping_rates.dart muss die hier auch nachgezogen werden.
//
// Backend-Tabelle nutzt nur die billigste Letter-Tier (`Standardbrief` in DE,
// max 4 Karten). Frontend hat das Tier-Ladder fuer Bundle-Size-Optimierung —
// wird hier vereinfacht auf den ersten Tier-Preis reduziert. Multi-Card-
// Bundles > 4 Karten werden im Backend daher zu niedrig berechnet (Phase 7
// Fix muss die Tier-Auswahl auch hierher portieren).
//
// { countryCode: { letter: { domestic, eu }, tracked: {...}, insured: {...} } }
const SHIPPING_RATES = {
  DE: { letter: { domestic: 1.25, eu: 1.80 }, tracked: { domestic: 3.95, eu: 4.45 }, insured: { domestic: 7.19, eu: 6.00 } },
  FR: { letter: { domestic: 1.16, eu: 2.25 }, tracked: { domestic: 5.05, eu: 5.05 }, insured: { domestic: 7.20, eu: 7.20 } },
  NL: { letter: { domestic: 1.14, eu: 1.80 }, tracked: { domestic: 4.00, eu: 8.50 }, insured: { domestic: 5.00, eu: 9.50 } },
  BE: { letter: { domestic: 1.14, eu: 1.80 }, tracked: { domestic: 4.00, eu: 6.00 }, insured: { domestic: 5.00, eu: 7.50 } },
  LU: { letter: { domestic: 1.10, eu: 1.80 }, tracked: { domestic: 3.80, eu: 5.50 }, insured: { domestic: 5.00, eu: 7.00 } },
  AT: { letter: { domestic: 1.10, eu: 1.80 }, tracked: { domestic: 3.75, eu: 4.50 }, insured: { domestic: 4.85, eu: 6.00 } },
  CH: { letter: { domestic: 1.70, eu: 1.90 }, tracked: { domestic: 5.00, eu: 7.00 }, insured: { domestic: 7.00, eu: 9.00 } },
  LI: { letter: { domestic: 1.70, eu: 1.90 }, tracked: { domestic: 5.00, eu: 7.00 }, insured: { domestic: 7.00, eu: 9.00 } },
  ES: { letter: { domestic: 0.90, eu: 2.00 }, tracked: { domestic: 4.50, eu: 6.45 }, insured: { domestic: 5.50, eu: 7.50 } },
  IT: { letter: { domestic: 1.25, eu: 1.35 }, tracked: { domestic: 5.50, eu: 7.65 }, insured: { domestic: 7.00, eu: 8.90 } },
  PT: { letter: { domestic: 0.95, eu: 2.00 }, tracked: { domestic: 4.00, eu: 6.50 }, insured: { domestic: 5.00, eu: 7.50 } },
  GR: { letter: { domestic: 0.90, eu: 1.50 }, tracked: { domestic: 4.00, eu: 6.50 }, insured: { domestic: 5.50, eu: 8.00 } },
  MT: { letter: { domestic: 0.59, eu: 1.50 }, tracked: { domestic: 3.50, eu: 6.00 }, insured: { domestic: 5.00, eu: 7.50 } },
  CY: { letter: { domestic: 0.64, eu: 1.50 }, tracked: { domestic: 3.50, eu: 6.50 }, insured: { domestic: 5.00, eu: 8.00 } },
  IE: { letter: { domestic: 1.85, eu: 3.50 }, tracked: { domestic: 6.00, eu: 9.00 }, insured: { domestic: 8.00, eu: 11.00 } },
  GB: { letter: { domestic: 1.50, eu: 2.80 }, tracked: { domestic: 4.50, eu: 8.10 }, insured: { domestic: 6.00, eu: 10.00 } },
  DK: { letter: { domestic: 2.80, eu: 3.50 }, tracked: { domestic: 7.00, eu: 10.00 }, insured: { domestic: 9.00, eu: 12.00 } },
  SE: { letter: { domestic: 1.95, eu: 3.90 }, tracked: { domestic: 10.25, eu: 13.80 }, insured: { domestic: 12.00, eu: 15.00 } },
  NO: { letter: { domestic: 2.50, eu: 3.50 }, tracked: { domestic: 7.00, eu: 10.00 }, insured: { domestic: 9.00, eu: 12.00 } },
  FI: { letter: { domestic: 2.00, eu: 3.00 }, tracked: { domestic: 6.50, eu: 9.50 }, insured: { domestic: 8.50, eu: 11.00 } },
  IS: { letter: { domestic: 2.50, eu: 3.80 }, tracked: { domestic: 7.00, eu: 10.50 }, insured: { domestic: 9.00, eu: 12.00 } },
  PL: { letter: { domestic: 0.90, eu: 1.80 }, tracked: { domestic: 3.50, eu: 5.50 }, insured: { domestic: 4.50, eu: 6.50 } },
  CZ: { letter: { domestic: 0.80, eu: 1.60 }, tracked: { domestic: 3.50, eu: 5.50 }, insured: { domestic: 4.50, eu: 6.50 } },
  SK: { letter: { domestic: 0.85, eu: 1.65 }, tracked: { domestic: 3.50, eu: 5.50 }, insured: { domestic: 4.50, eu: 6.50 } },
  HU: { letter: { domestic: 0.70, eu: 1.50 }, tracked: { domestic: 3.00, eu: 5.00 }, insured: { domestic: 4.00, eu: 6.00 } },
  RO: { letter: { domestic: 0.50, eu: 1.20 }, tracked: { domestic: 2.50, eu: 4.50 }, insured: { domestic: 3.50, eu: 5.50 } },
  BG: { letter: { domestic: 0.45, eu: 1.20 }, tracked: { domestic: 2.50, eu: 4.50 }, insured: { domestic: 3.50, eu: 5.50 } },
  HR: { letter: { domestic: 0.65, eu: 1.50 }, tracked: { domestic: 3.00, eu: 5.00 }, insured: { domestic: 4.00, eu: 6.00 } },
  SI: { letter: { domestic: 0.80, eu: 1.50 }, tracked: { domestic: 3.50, eu: 5.50 }, insured: { domestic: 4.50, eu: 7.00 } },
  EE: { letter: { domestic: 0.90, eu: 1.80 }, tracked: { domestic: 3.50, eu: 5.50 }, insured: { domestic: 4.50, eu: 6.50 } },
  LV: { letter: { domestic: 0.85, eu: 1.70 }, tracked: { domestic: 3.50, eu: 5.50 }, insured: { domestic: 4.50, eu: 6.50 } },
  LT: { letter: { domestic: 0.75, eu: 1.60 }, tracked: { domestic: 3.00, eu: 5.00 }, insured: { domestic: 4.00, eu: 6.00 } },
};
const SHIPPING_FALLBACK = { letter: { domestic: 1.20, eu: 2.00 }, tracked: { domestic: 4.50, eu: 6.50 }, insured: { domestic: 5.50, eu: 8.00 } };

function getShippingRate(sellerCountry, buyerCountry, method) {
  const seller = (sellerCountry || "").toUpperCase();
  const buyer = (buyerCountry || "").toUpperCase();
  const zone = seller === buyer ? "domestic" : "eu";
  const countryRates = SHIPPING_RATES[seller] || SHIPPING_FALLBACK;
  const methodRates = countryRates[method] || SHIPPING_FALLBACK[method];
  return methodRates[zone] || methodRates.eu;
}

const PLATFORM_FEE_RATE = 0.05; // 5%
const PLATFORM_FEE_CAP = 100.00; // €100 max
const MIN_FEE = 0.05; // €0.05 minimum fee
const CHEAP_CARD_THRESHOLD = 0.50; // Below this, buyer pays service fee

/**
 * Calculate platform fee based on new fee structure.
 * - Card < €0.50: Buyer pays €0.05 service fee, seller gets full price
 * - Card >= €0.50: Seller pays max(€0.05, 5%), buyer pays nothing extra
 * Returns { platformFee, buyerServiceFee, feePayer, sellerPayout, buyerTotal }
 */
function calculateFees(subtotal, shippingCost) {
  if (subtotal < CHEAP_CARD_THRESHOLD) {
    // Buyer pays €0.05 service fee
    return {
      platformFee: MIN_FEE,
      buyerServiceFee: MIN_FEE,
      feePayer: "buyer",
      sellerPayout: round2(subtotal + shippingCost), // Seller gets full price + shipping
      buyerTotal: round2(subtotal + shippingCost + MIN_FEE),
    };
  } else {
    // Seller pays max(€0.05, 5%)
    const fee = Math.min(Math.max(MIN_FEE, round2(subtotal * PLATFORM_FEE_RATE)), PLATFORM_FEE_CAP);
    return {
      platformFee: fee,
      buyerServiceFee: 0,
      feePayer: "seller",
      sellerPayout: round2(subtotal - fee + shippingCost),
      buyerTotal: round2(subtotal + shippingCost),
    };
  }
}

/**
 * createPaymentIntent — Callable, authenticated.
 * Creates a Stripe PaymentIntent for buying a listing.
 * Returns { clientSecret, orderId, total }.
 */
exports.createPaymentIntent = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;

    // Carding-Defense (Round 9 Red-Team-Audit reviewed 2026-04-29):
    // Aelterer 50/Tag-Cap war zu generös. Industry-Best-Practice fuer
    // Marketplaces: 5-10 PIs/Tag fuer neue Accounts, 20-30 fuer etablierte.
    // Age-Based-Tier-Cap macht Mass-Account-Carding uneconomic:
    //   - Frische Accounts (<7d): max 5 PIs/Tag → 5 Card-Tests/Account
    //   - Mittel (7-30d):          max 15 PIs/Tag
    //   - Etabliert (>30d):        max 25 PIs/Tag
    // Real-Power-Buyer hits 25/Tag praktisch nie (das waeren 25 separate
    // Order-Sessions). Carder muesste 7+ Tage warten + 100+ Accounts
    // anlegen → uneconomic.
    await enforceAgeBasedDailyCap(uid, "createPaymentIntent", 5, 15, 25);
    // Hourly velocity ueber alle Tiers: max 5/h (war 10) — gibt Stripe-Radar
    // Zeit fuer Pattern-Detection bei stolen-card-tests.
    await enforceHourlyVelocity(uid, "createPaymentIntent", 5);

    const { listingId, quantity, items, shippingMethod, shippingAddress } = request.data;

    // Support both single-listing and cart (items array) mode
    const isCart = Array.isArray(items) && items.length > 0;

    if (!isCart && (!listingId || !quantity)) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }
    if (!shippingMethod || !shippingAddress) {
      throw new HttpsError("invalid-argument", "Missing shipping info");
    }

    // 1. Fetch all listings (single or cart).
    // Round 6 (2026-04-29): items-array geht durch dedupeAndValidateItems
    // damit Duplicate-listingId-Over-Allocation nicht mehr moeglich ist.
    const cartEntries = isCart
      ? dedupeAndValidateItems(items)
      : [{ listingId, quantity }];
    const listingRefs = [];
    const listingDocs = [];
    const listingData = [];

    for (const entry of cartEntries) {
      const ref = db.collection("artifacts").doc(APP_ID)
        .collection("listings").doc(entry.listingId);
      const doc = await ref.get();
      if (!doc.exists) {
        throw new HttpsError("not-found", `Listing ${entry.listingId} not found`);
      }
      const data = doc.data();
      if (data.status !== "active" && data.status !== "reserved") {
        throw new HttpsError("failed-precondition", `Listing ${entry.listingId} is not active`);
      }
      // Phase 4 Bugfix (2026-04-28): User-eigene Cart-Reservation aus
      // reservedQty rausrechnen, sonst blockiert sich der Buyer selbst
      // (Cart-Service reserviert beim Add-to-Cart). Mirror der Logik in
      // processMultiSellerCart.
      const cartResRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(uid)
        .collection("cartReservations").doc(entry.listingId);
      const cartResDoc = await cartResRef.get();
      const ownCartReservedQty = cartResDoc.exists
        ? (cartResDoc.data().quantity || cartResDoc.data().qty || 0)
        : 0;
      const otherReservedQty = Math.max(0, (data.reservedQty || 0) - ownCartReservedQty);
      const available = data.quantity - otherReservedQty;
      if ((entry.quantity || 1) > available) {
        throw new HttpsError("failed-precondition", `Not enough qty for ${data.cardName}`);
      }
      listingRefs.push(ref);
      listingDocs.push(doc);
      listingData.push(data);
    }

    // 2. All listings must be from the same seller
    const sellerId = listingData[0].sellerId;
    if (listingData.some(l => l.sellerId !== sellerId)) {
      throw new HttpsError("failed-precondition", "All cart items must be from the same seller");
    }

    // SELF-BUY-CHECK (Security-Audit Round 5, 2026-04-29):
    // Vorher fehlte hier der Self-Buy-Guard — `processMultiSellerCart` und
    // `reserveForCart` hatten ihn, `createPaymentIntent` aber nicht. Direkt-
    // Kauf-Flow (ohne Cart) ermoeglichte:
    //   1. Seller erstellt Listing fuer €100
    //   2. Seller ruft createPaymentIntent direkt auf, kauft eigenes Listing
    //   3. Verlust: ~5% Riftr + 1.5% Stripe = ~€7
    //   4. confirmDelivery → submitReview → 5-Sterne Eigen-Bewertung
    //   5. = €7 fuer einen fake Review = Power-Seller-Status pumpen
    if (sellerId === uid) {
      throw new HttpsError(
        "permission-denied",
        "Cannot buy your own listings",
      );
    }

    // 3. Get seller's Stripe account
    const sellerRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(sellerId)
      .collection("data").doc("sellerProfile");
    const sellerDoc = await sellerRef.get();
    if (!sellerDoc.exists || !sellerDoc.data().stripeAccountId) {
      throw new HttpsError("failed-precondition", "Seller has no Stripe account");
    }
    // ATO-Defense (Round 8 Pen-Test, 2026-04-29): block buys auf
    // Sellers deren Stripe-Account due-to-bank-change auf Pause ist.
    // Sonst landet das Geld via transfer_data am potenziell-Attacker-Konto.
    if (sellerDoc.data().payoutsPausedReason) {
      throw new HttpsError(
        "failed-precondition",
        "This seller is temporarily unavailable. Please try again later or contact support.",
      );
    }
    const sellerStripeAccountId = sellerDoc.data().stripeAccountId;

    // 3b. Verify seller's Stripe account has transfer capability
    const stripe = getStripe();
    const sellerAccount = await stripe.accounts.retrieve(sellerStripeAccountId);
    console.log(`Seller Stripe account ${sellerStripeAccountId}: ` +
      `charges_enabled=${sellerAccount.charges_enabled}, ` +
      `payouts_enabled=${sellerAccount.payouts_enabled}, ` +
      `details_submitted=${sellerAccount.details_submitted}, ` +
      `capabilities=${JSON.stringify(sellerAccount.capabilities)}`);

    if (!sellerAccount.charges_enabled || !sellerAccount.details_submitted) {
      throw new HttpsError(
        "failed-precondition",
        "Seller's Stripe account is not fully onboarded. " +
        `charges_enabled=${sellerAccount.charges_enabled}, details_submitted=${sellerAccount.details_submitted}`
      );
    }

    // 4. Calculate amounts
    const orderItems = [];
    let subtotal = 0;
    for (let i = 0; i < cartEntries.length; i++) {
      const entry = cartEntries[i];
      const listing = listingData[i];
      const qty = entry.quantity || 1;
      const pricePerCard = listing.price;
      subtotal += round2(pricePerCard * qty);
      orderItems.push({
        listingId: entry.listingId,
        cardId: listing.cardId || "",
        cardName: listing.cardName || "",
        imageUrl: listing.imageUrl || null,
        condition: listing.condition || "NM",
        quantity: qty,
        pricePerCard,
        ...(listing.setCode ? {setCode: listing.setCode} : {}),
        ...(listing.collectorNumber ? {collectorNumber: listing.collectorNumber} : {}),
        ...(listing.language ? {language: listing.language} : {}),
        // Persist foil flag — seller needs to know which variant to ship.
        ...(listing.isFoil ? {isFoil: true} : {}),
      });
    }
    subtotal = round2(subtotal);

    const sellerCountry = listingData[0].sellerCountry || "";
    const buyerCountry = (shippingAddress.country || "").toUpperCase();
    const anyInsuredOnly = listingData.some(l => l.insuredOnly);
    const effectiveMethod = anyInsuredOnly ? "insured" : shippingMethod;

    // Tracked-Shipping-Required Server-Side Enforcement (Round 11.1, 2026-04-29):
    // Cardmarket/TCGplayer-Standard: Orders > €25 müssen tracked versendet
    // werden (Cardmarket: >€25, TCGplayer: >$20). Schützt vor Bait-and-Switch
    // (Round 10 Strategie 4), Lost-Mail-Scam (Letter ohne Tracking = keine
    // Versand-Beweis), und Friendly-Fraud-Chargebacks. Flutter-UI Picker
    // (lib/data/shipping_rates.dart::requiresTracking) macht das schon
    // soft-enforce, aber ein Hacker mit Frida/Burp könnte direkten API-Call
    // mit `shippingMethod: "letter"` machen → ohne Server-Side-Check würde
    // das durchgehen. Hier hartes Enforcement.
    if (effectiveMethod === "letter" && subtotal > 25) {
      throw new HttpsError(
        "failed-precondition",
        "Orders over €25 must use tracked or insured shipping. " +
        "Please select a different shipping method.",
      );
    }

    // Insured-Shipping-Required Server-Side Enforcement (Discogs-Modell, 2026-04-30):
    // Bei Bestellwert ≥ €300 ist nur insured zulaessig. Bei Verlust/Beschaedigung
    // haftet die Versicherung (DHL Wert-Einschreiben deckt bis €500), nicht
    // die Plattform — das ist eine reine AGB-Klausel-Folge, kein Plattform-
    // Wertentscheid am Geld. Riftbound-Realitaet: Top-Karten ~€100-300, Promos
    // €500+. Bei €300 fangen wir alle reale High-Value-Bestellungen ab.
    if (effectiveMethod !== "insured" && subtotal >= 300) {
      throw new HttpsError(
        "failed-precondition",
        "Orders ≥ €300 must use insured shipping. Insurance covers loss/damage " +
        "(DHL Wert-Einschreiben up to €500). Please select insured shipping.",
      );
    }

    const shippingCost = round2(getShippingRate(sellerCountry, buyerCountry, effectiveMethod));

    // ── Fee-Logik (Phase-1) ──
    // Multi-Seller-Cart: Frontend orchestriert N sequenzielle Calls, einer
    // pro Verkäufer. `sellerCount` (Gesamtzahl im User-Cart) und
    // `chargeIndex` (0-basiert) werden vom Frontend mitgegeben — Service-
    // Gebühr wird NUR auf Charge #0 gepackt, andere PIs tragen nur ihre
    // eigene Provision. Default = Single-Seller-Verhalten (1, 0).
    const sellerCount = Math.max(1, request.data.sellerCount || 1);
    const chargeIndex = Math.max(0, request.data.chargeIndex || 0);

    const cartSubtotalCents = Math.round(subtotal * 100);
    const shippingCents = Math.round(shippingCost * 100);
    const fees = calculateOrderFees(cartSubtotalCents, sellerCount);

    // Service-Gebühr: nur auf erstem Charge berechnen
    const serviceFeeForThisChargeCents = (chargeIndex === 0)
      ? fees.serviceFeeCents : 0;
    const applicationFeeCents =
      serviceFeeForThisChargeCents + fees.platformCommissionCents;

    const totalCents = cartSubtotalCents + shippingCents + serviceFeeForThisChargeCents;
    const sellerPayoutCents = cartSubtotalCents - fees.platformCommissionCents + shippingCents;

    // EUR-Floats für Order-Doc + Frontend-Display
    const platformFee = fees.platformCommissionCents / 100;
    const buyerServiceFee = serviceFeeForThisChargeCents / 100;
    const totalPaid = totalCents / 100;
    const sellerPayout = sellerPayoutCents / 100;
    const feeCents = applicationFeeCents;
    const feePayer = "split"; // Käufer Service-Gebühr, Verkäufer Provision

    // Tier-aware Auszahlungs-Delay (account-level wird via syncSellerTier
    // gesetzt; effective wird hier nur fürs Order-Doc/UI persistiert).
    // High-Value-Cap > €100 wird in Phase 5 via capture-delay enforced;
    // hier nur dokumentiert für Transparenz im Order-Doc.
    const sellerProfileForDelay = sellerDoc.data();
    const effectiveDelayDays = getEffectiveDelayDays(
      sellerProfileForDelay,
      totalCents,
    );

    // 5. Get buyer display name (Firestore profile → Firebase Auth → fallback)
    const buyerProfileRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("profile");
    const buyerProfileDoc = await buyerProfileRef.get();
    let buyerName = buyerProfileDoc.exists
      ? (buyerProfileDoc.data().displayName || null)
      : null;
    if (!buyerName) {
      const buyerAuth = await admin.auth().getUser(uid);
      buyerName = buyerAuth.displayName || "Buyer";
    }

    // 6. Create order doc first (need ID for PI metadata)
    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc();
    const orderId = orderRef.id;

    // 7. Create Stripe PaymentIntent (with 3D Secure for liability shift).
    // capture_method: "manual" — Funds bleiben in Authorisierung bis
    // markShipped (siehe Z. ~2227). Gibt Riftr ein 7-Tage-Buffer (Stripe-
    // Limit) für Buyer-Protection zwischen Charge und tatsächlichem
    // Transfer an Verkäufer.
    const paymentIntent = await stripe.paymentIntents.create({
      amount: totalCents,
      currency: "eur",
      capture_method: "manual",
      transfer_data: { destination: sellerStripeAccountId },
      application_fee_amount: applicationFeeCents,
      payment_method_options: {
        card: { request_three_d_secure: "challenge" },
      },
      metadata: {
        orderId,
        buyerId: uid,
        sellerId,
        sellerCount: String(sellerCount),
        chargeIndex: String(chargeIndex),
        cartSubtotalCents: String(cartSubtotalCents),
        serviceFeeCents: String(serviceFeeForThisChargeCents),
        platformCommissionCents: String(fees.platformCommissionCents),
        commissionRate: String(fees.commissionRateUsed),
        effectiveDelayDays: String(effectiveDelayDays),
        itemCount: String(orderItems.length),
        cardNames: orderItems.map(i => i.cardName).join(", ").substring(0, 500),
      },
    }, {
      // Idempotency-Key (Security-Audit Round 2, 2026-04-29): wenn der
      // Buyer-Frontend-Call retried (Network-Glitch, App-Background-Resume)
      // wuerde Stripe sonst ein 2. PI mit doppeltem Hold auf der Buyer-Karte
      // erstellen. orderId ist server-generiert und unique pro Order, also
      // sicher als Idempotency-Anker.
      idempotencyKey: `pi-create-${orderId}`,
    });

    // 8. Build seller address from seller profile (for buyer to see)
    const sellerProfileData = sellerDoc.data();
    const sellerAddr = sellerProfileData.address || {};
    const sellerAddress = {
      name: sellerProfileData.displayName || listingData[0].sellerName || null,
      ...(sellerAddr.street ? { street: sellerAddr.street } : {}),
      ...(sellerAddr.city ? { city: sellerAddr.city } : {}),
      ...(sellerAddr.zip ? { zip: sellerAddr.zip } : {}),
      ...(sellerAddr.country ? { country: sellerAddr.country } : { country: listingData[0].sellerCountry || "" }),
    };

    // 9. Write order doc — neue Cents-basierte Felder + Legacy-EUR-Felder
    //    fürs Frontend (parallel führen bis Frontend migriert ist).
    await orderRef.set({
      buyerId: uid,
      sellerId,
      sellerStripeAccountId,
      items: orderItems,

      // Legacy EUR-Felder (Frontend kompatibel)
      subtotal,
      platformFee,
      buyerServiceFee,
      feePayer,
      shippingCost,
      totalPaid,
      sellerPayout,

      // Neue Cents-Felder (Source of Truth für Buchhaltung)
      cartSubtotalCents,
      shippingCents,
      serviceFeeCents: serviceFeeForThisChargeCents,
      platformCommissionCents: fees.platformCommissionCents,
      totalApplicationFeeCents: applicationFeeCents,
      totalChargeCents: totalCents,
      sellerPayoutCents,
      commissionRateUsed: fees.commissionRateUsed,

      // Multi-Seller-Cart-Tracking
      sellerCount,
      chargeIndex,

      // Tier / Auszahlungs-Info (Snapshot zum Order-Zeitpunkt)
      effectiveDelayDays,

      shippingAddress,
      sellerAddress,
      shippingMethod: effectiveMethod,
      stripePaymentIntentId: paymentIntent.id,
      paymentMethod: "stripe", // Phase-2 Pfad — Destination Charges (transfer_data + application_fee_amount)
      status: "pending_payment",
      sellerName: listingData[0].sellerName || null,
      buyerName,
      preReleaseDate: listingData[0].preReleaseDate || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 9. Reserve quantity on all listings
    // If items were cart-reserved, reservedQty is already set — don't double-count.
    for (let i = 0; i < cartEntries.length; i++) {
      const entry = cartEntries[i];
      const listing = listingData[i];
      const ref = listingRefs[i];
      const qty = entry.quantity || 1;

      const cartResRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(uid)
        .collection("cartReservations").doc(entry.listingId);
      const cartResDoc = await cartResRef.get();

      if (cartResDoc.exists) {
        await cartResRef.delete();
        if ((listing.reservedQty || 0) >= listing.quantity) {
          await ref.update({ status: "reserved" });
        }
      } else {
        const newReserved = (listing.reservedQty || 0) + qty;
        const updateData = { reservedQty: newReserved };
        if (newReserved >= listing.quantity) {
          updateData.status = "reserved";
        }
        await ref.update(updateData);
      }
    }

    console.log(`Order ${orderId} created: €${totalPaid} (${orderItems.length} items, PI: ${paymentIntent.id})`);
    return { clientSecret: paymentIntent.client_secret, orderId, total: totalPaid };
  }
);

/**
 * cancelPendingOrder — Callable, authenticated.
 *
 * Cleanup-Pfad fuer abgebrochene Buy-Flows: Frontend ruft das auf wenn der
 * User das Stripe-PaymentSheet schliesst ohne zu zahlen. Cancelt die Stripe-
 * PaymentIntent, flippt Order → cancelled, gibt Listing-Reservation frei.
 *
 * Idempotent: bei Order != pending_payment (= bereits paid oder cancelled)
 * gibt's einfach `alreadyHandled: true` zurueck, kein Throw.
 *
 * Defensiver Webhook-Handler `payment_intent.canceled` macht parallel
 * dasselbe — falls App crashed bevor das hier feuert, oder Stripe das PI
 * intern cancellt (z.B. Auto-Expiry).
 */
exports.cancelPendingOrder = onCall(
  { region: "europe-west1", timeoutSeconds: 15, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }
    const uid = request.auth.uid;
    const { orderId } = request.data;
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.buyerId !== uid) {
      throw new HttpsError("permission-denied", "Not your order");
    }
    if (order.status !== "pending_payment") {
      // Bereits behandelt (paid/cancelled/refunded) — silently no-op.
      return { alreadyHandled: true, status: order.status };
    }

    // Stripe PI cancel — idempotent, ignoriert wenn schon cancelled
    if (order.stripePaymentIntentId) {
      const stripe = getStripe();
      try {
        await stripe.paymentIntents.cancel(order.stripePaymentIntentId);
      } catch (e) {
        // PI may already be cancelled, or in a terminal state — log + continue
        console.warn(`cancelPendingOrder: PI ${order.stripePaymentIntentId} cancel skipped: ${e.message}`);
      }
    }

    // Order → cancelled
    await orderRef.update({
      status: "cancelled",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelReason: "user_dismissed_payment_sheet",
    });

    // Listing-Reservations freigeben (Mirror der Logik im
    // payment_intent.payment_failed Webhook-Handler).
    for (const item of (order.items || [])) {
      if (!item.listingId) continue;
      const listingRef = db.collection("artifacts").doc(APP_ID)
        .collection("listings").doc(item.listingId);
      const listingDoc = await listingRef.get();
      if (!listingDoc.exists) continue;
      const listing = listingDoc.data();
      const newReserved = Math.max(0, (listing.reservedQty || 0) - (item.quantity || 1));
      const updateData = { reservedQty: newReserved };
      if (listing.status === "reserved") updateData.status = "active";
      await listingRef.update(updateData);
    }

    console.log(`cancelPendingOrder: order ${orderId} cancelled by buyer ${uid}`);
    return { success: true };
  }
);

// ═══════════════════════════════════════════
// ─── Phase 4: Multi-Seller-Cart Pfad ───
// ═══════════════════════════════════════════
//
// Architektur (siehe CLAUDE.md → Multi-Seller-Cart Implementation):
//
//   1. Buyer tappt „Pay" im BulkCheckoutSheet
//   2. Frontend ruft `setupCardForCart` → SetupIntent mit 3DS-upfront-challenge
//   3. Frontend zeigt Stripe-PaymentSheet; User gibt Karte ein, 3DS authoriziert
//   4. Frontend bekommt `paymentMethodId` aus dem confirmed SetupIntent
//   5. Frontend ruft `processMultiSellerCart({ paymentMethodId, items, ... })`
//   6. Backend Loop: pro Seller-Group ein PI mit off_session+confirm+manual-capture
//   7. Bei Erfolg: alle Orders in `pending_payment` (Webhook flippt auf `paid`)
//   8. Bei Teilfehler: alle vorherigen PIs `paymentIntents.cancel`-Rollback
//      (kein refunds.create noetig — manual-capture-PIs sind in
//       `requires_capture`, kein Geld floss; cancel gibt Auth wieder frei)
//
// Service-Gebuehr (multi-seller): base + 30 × (N-1) Cents, NUR auf den ersten
// PI gepackt (chargeIndex=0). Andere PIs tragen nur ihre eigene Provision.
// Siehe `calculateOrderFees(cartSubtotalCents, sellerCount)`.

/**
 * setupCardForCart — Callable, authenticated.
 *
 * Erstellt einen SetupIntent fuer eine Multi-Seller-Cart-Session. Der Buyer
 * authoriziert seine Karte einmal (mit 3DS-Challenge), der resultierende
 * `payment_method` ist dann fuer die folgenden off_session PaymentIntents
 * verwendbar.
 *
 * Returns: `{ clientSecret, customerId }` — Frontend nutzt clientSecret
 * fuer `Stripe.confirmSetupIntent`, danach gehoert die `payment_method`
 * dauerhaft zum Stripe-Customer (= reusable fuer kuenftige Multi-Seller-Carts).
 */
exports.setupCardForCart = onCall(
  { region: "europe-west1", timeoutSeconds: 15, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }
    const uid = request.auth.uid;
    const stripe = getStripe();
    const customerId = await ensureStripeCustomer(uid);

    const setupIntent = await stripe.setupIntents.create({
      customer: customerId,
      payment_method_types: ["card"],
      usage: "off_session",
      payment_method_options: {
        card: { request_three_d_secure: "challenge" },
      },
      metadata: { uid, type: "multi_seller_cart_setup" },
    });

    console.log(`setupCardForCart: SetupIntent ${setupIntent.id} for ${uid}`);
    return {
      clientSecret: setupIntent.client_secret,
      setupIntentId: setupIntent.id,
      customerId,
    };
  },
);

/**
 * processMultiSellerCart — Callable, authenticated.
 *
 * Verarbeitet einen Multi-Seller-Cart sequenziell: pro Verkaeufer-Gruppe ein
 * PaymentIntent mit `off_session: true, confirm: true, capture_method: "manual"`.
 * Bei Teilfehler werden alle vorherigen PIs auto-cancelled (Auth-Release —
 * kein Geld floss).
 *
 * Body params:
 *   - paymentMethodId: string  — vom SetupIntent confirmed
 *   - items: Array<{listingId, quantity}>  — alle Items im Cart, gemixt
 *   - shippingMethod: string  — "letter" | "tracked" | "insured"
 *   - shippingAddress: object  — { name, street, city, zip, country }
 *
 * Returns:
 *   { status: "all_succeeded", orderIds: string[] }  — Erfolg
 *   ODER throws HttpsError mit details bei Teilfehler.
 *
 * Single-Seller-Cart wird explizit abgewiesen — der Buyer muss
 * `createPaymentIntent` (= das CheckoutSheet-Pfad) nutzen.
 */
exports.processMultiSellerCart = onCall(
  { region: "europe-west1", timeoutSeconds: 60, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }
    const uid = request.auth.uid;

    // Carding-Defense (Round 9 reviewed 2026-04-29):
    // Multi-Seller-Path war 30/Tag — Carder konnte das als Bypass des
    // Single-Seller-Caps nutzen (5 carts × 5 sellers = 25 PIs/Tag extra).
    // Age-Based-Cap analog zu createPaymentIntent, aber strikter (jede
    // Multi-Cart-Submission = N PIs in einer Aktion):
    //   - Fresh:    3/Tag (= max 3×5 = 15 PIs effektiv)
    //   - Mid:      8/Tag
    //   - Etabliert: 15/Tag
    await enforceAgeBasedDailyCap(uid, "processMultiSellerCart", 3, 8, 15);
    // Hourly: max 2/h gegen Burst-Carding via Multi-Cart-Path.
    await enforceHourlyVelocity(uid, "processMultiSellerCart", 2);

    const {
      setupIntentId,
      items,
      shippingMethod,
      shippingAddress,
    } = request.data;

    if (!setupIntentId || typeof setupIntentId !== "string") {
      throw new HttpsError("invalid-argument", "setupIntentId required");
    }
    if (!shippingMethod || !shippingAddress) {
      throw new HttpsError("invalid-argument", "Missing shipping info");
    }

    // Round 6 (2026-04-29): items dedupe + size-cap.
    // Rejected: duplicate listingIds (Over-Allocation), arrays > 100,
    // negative/missing quantities. Aggregiert quantities pro listingId.
    const validatedItems = dedupeAndValidateItems(items);

    // Resolve paymentMethodId server-side via SetupIntent — Frontend kennt
    // den PM-Wert nicht direkt nach dem PaymentSheet (Flutter-Stripe-SDK
    // exposed das nicht idiomatisch). SetupIntent muss vom uid auth'd sein
    // und im status `succeeded`, sonst reject.
    const stripe = getStripe();
    const si = await stripe.setupIntents.retrieve(setupIntentId);
    if (si.metadata?.uid !== uid) {
      throw new HttpsError("permission-denied", "SetupIntent does not belong to caller");
    }
    if (si.status !== "succeeded") {
      throw new HttpsError(
        "failed-precondition",
        `SetupIntent status is ${si.status}, expected succeeded`,
      );
    }
    const paymentMethodId = si.payment_method;
    if (!paymentMethodId || typeof paymentMethodId !== "string") {
      throw new HttpsError(
        "failed-precondition",
        "SetupIntent has no payment method attached",
      );
    }

    // 1. Fetch all listings + group by seller (uses validatedItems for dedupe-safety)
    const listingsBySeller = new Map(); // sellerId -> [{ listingId, quantity, listing }]
    for (const entry of validatedItems) {
      const listingRef = db.collection("artifacts").doc(APP_ID)
        .collection("listings").doc(entry.listingId);
      const listingDoc = await listingRef.get();
      if (!listingDoc.exists) {
        throw new HttpsError("not-found", `Listing ${entry.listingId} not found`);
      }
      const listing = listingDoc.data();
      if (listing.status !== "active" && listing.status !== "reserved") {
        throw new HttpsError(
          "failed-precondition",
          `Listing ${entry.listingId} is not active`,
        );
      }
      // Phase 4 Bugfix (2026-04-28): User-eigene Cart-Reservation aus
      // `reservedQty` rausrechnen, sonst blockiert sich der Buyer selbst.
      // Cart-Service reserviert beim Add-to-Cart → reservedQty++. Beim
      // Checkout-Validate muss diese Reservation explizit nicht-blockend
      // sein. Single-Seller-Pfad (createPaymentIntent) hat denselben
      // Bug — wird parallel gefixed.
      const cartResRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(uid)
        .collection("cartReservations").doc(entry.listingId);
      const cartResDoc = await cartResRef.get();
      const ownCartReservedQty = cartResDoc.exists
        ? (cartResDoc.data().quantity || cartResDoc.data().qty || 0)
        : 0;
      const otherReservedQty = Math.max(0, (listing.reservedQty || 0) - ownCartReservedQty);
      const available = listing.quantity - otherReservedQty;
      if ((entry.quantity || 1) > available) {
        throw new HttpsError(
          "failed-precondition",
          `Not enough qty for ${listing.cardName}`,
        );
      }
      const sellerId = listing.sellerId;
      if (!listingsBySeller.has(sellerId)) {
        listingsBySeller.set(sellerId, []);
      }
      listingsBySeller.get(sellerId).push({
        listingId: entry.listingId,
        quantity: entry.quantity || 1,
        listing,
        ownCartReservedQty, // fuer spaetere Reservierungs-Logik
      });
    }

    if (listingsBySeller.size < 2) {
      throw new HttpsError(
        "invalid-argument",
        "Multi-seller cart requires items from 2+ sellers — use createPaymentIntent for single-seller.",
      );
    }

    // SELF-BUY-CHECK
    if (listingsBySeller.has(uid)) {
      throw new HttpsError(
        "permission-denied",
        "Cannot buy your own listings",
      );
    }

    const sellerCount = listingsBySeller.size;
    const sellerIds = Array.from(listingsBySeller.keys());
    const buyerCountry = (shippingAddress.country || "").toUpperCase();

    // 2. Pre-fetch all sellers' Stripe accounts + verify capabilities
    const sellerStripeIds = new Map(); // sellerId -> stripeAccountId
    const sellerNames = new Map();
    const sellerAddresses = new Map();

    for (const sellerId of sellerIds) {
      const sellerProfRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(sellerId)
        .collection("data").doc("sellerProfile");
      const sellerProfDoc = await sellerProfRef.get();
      if (!sellerProfDoc.exists || !sellerProfDoc.data().stripeAccountId) {
        throw new HttpsError(
          "failed-precondition",
          `Seller ${sellerId} has no Stripe account`,
        );
      }
      // ATO-Defense (Round 8 Pen-Test, 2026-04-29): block multi-seller-cart
      // wenn EINER der Seller pausiert ist. Cart kann nicht teil-erfolgreich
      // gehen — wenn Seller X paused, Buyer kriegt clean error + cart bleibt
      // intakt fuer spaeteren retry.
      if (sellerProfDoc.data().payoutsPausedReason) {
        throw new HttpsError(
          "failed-precondition",
          `Seller ${sellerProfDoc.data().displayName || sellerId} is temporarily unavailable. ` +
          "Remove this seller from your cart or try again later.",
        );
      }
      const stripeAccountId = sellerProfDoc.data().stripeAccountId;
      // Verify capabilities (skip if known-active to save API calls; for safety check first time)
      const sellerAccount = await stripe.accounts.retrieve(stripeAccountId);
      if (!sellerAccount.charges_enabled || !sellerAccount.details_submitted) {
        throw new HttpsError(
          "failed-precondition",
          `Seller ${sellerId} Stripe account is not fully onboarded.`,
        );
      }
      sellerStripeIds.set(sellerId, stripeAccountId);
      const sellerProfData = sellerProfDoc.data();
      const sellerAddr = sellerProfData.address || {};
      sellerNames.set(
        sellerId,
        sellerProfData.displayName ||
          listingsBySeller.get(sellerId)[0].listing.sellerName ||
          null,
      );
      sellerAddresses.set(sellerId, {
        name: sellerProfData.displayName ||
          listingsBySeller.get(sellerId)[0].listing.sellerName ||
          null,
        ...(sellerAddr.street ? { street: sellerAddr.street } : {}),
        ...(sellerAddr.city ? { city: sellerAddr.city } : {}),
        ...(sellerAddr.zip ? { zip: sellerAddr.zip } : {}),
        ...(sellerAddr.country ? { country: sellerAddr.country } : {
          country: listingsBySeller.get(sellerId)[0].listing.sellerCountry || "",
        }),
      });
    }

    // 3. Buyer info
    const buyerProfRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid).collection("data").doc("profile");
    const buyerProfDoc = await buyerProfRef.get();
    let buyerName = buyerProfDoc.exists
      ? (buyerProfDoc.data().displayName || null)
      : null;
    if (!buyerName) {
      const buyerAuth = await admin.auth().getUser(uid);
      buyerName = buyerAuth.displayName || "Buyer";
    }
    const customerId = await ensureStripeCustomer(uid);

    // 4. Build per-seller groups with computed amounts
    const cartGroups = sellerIds.map((sellerId, idx) => {
      const picks = listingsBySeller.get(sellerId);
      const sellerCountry = picks[0].listing.sellerCountry || "";
      const anyInsured = picks.some((p) => p.listing.insuredOnly);
      const effectiveMethod = anyInsured ? "insured" : shippingMethod;
      const shippingCost = round2(getShippingRate(sellerCountry, buyerCountry, effectiveMethod));

      let cardSubtotal = 0;
      const orderItems = [];
      for (const p of picks) {
        const lineTotal = round2(p.listing.price * p.quantity);
        cardSubtotal += lineTotal;
        orderItems.push({
          listingId: p.listingId,
          cardId: p.listing.cardId || "",
          cardName: p.listing.cardName || "",
          imageUrl: p.listing.imageUrl || null,
          condition: p.listing.condition || "NM",
          quantity: p.quantity,
          pricePerCard: p.listing.price,
          // Audit-Folge (2026-04-29): per-Item-Marker fuer Rollback —
          // wenn der Buyer eine cart-reservation auf das Listing hatte,
          // wurde reservedQty NICHT in der Erfolgs-Phase incrementet.
          // Rollback muss das wissen damit er nicht zu viel dekrementiert.
          ownCartReservedQty: p.ownCartReservedQty || 0,
          ...(p.listing.setCode ? { setCode: p.listing.setCode } : {}),
          ...(p.listing.collectorNumber ? { collectorNumber: p.listing.collectorNumber } : {}),
          ...(p.listing.language ? { language: p.listing.language } : {}),
          ...(p.listing.isFoil ? { isFoil: true } : {}),
        });
      }
      cardSubtotal = round2(cardSubtotal);

      // Tracked-Shipping-Required Server-Side Enforcement (Round 11.1, 2026-04-29):
      // Cardmarket-Pattern: Orders > €25 müssen tracked versendet werden.
      // Per-Seller-Group check (jeder Seller-Subtotal individuell, nicht
      // total cart). Schützt vor Bait-and-Switch + Lost-Mail + Friendly-Fraud.
      // Flutter-UI macht das schon soft-enforce, hier hartes Server-Side-Check
      // gegen Frida/Burp-Bypass.
      if (effectiveMethod === "letter" && cardSubtotal > 25) {
        throw new HttpsError(
          "failed-precondition",
          `Seller ${sellerId}: orders over €25 must use tracked or insured ` +
          `shipping. Please select a different shipping method.`,
        );
      }

      // Insured-Shipping-Required (Discogs-Modell, 2026-04-30): siehe Single-
      // Seller-Pfad oben. Hier per-seller-group, gleiche Schwelle €300.
      if (effectiveMethod !== "insured" && cardSubtotal >= 300) {
        throw new HttpsError(
          "failed-precondition",
          `Seller ${sellerId}: orders ≥ €300 must use insured shipping. ` +
          `Insurance covers loss/damage (DHL Wert-Einschreiben up to €500).`,
        );
      }

      const cartSubtotalCents = Math.round(cardSubtotal * 100);
      const shippingCents = Math.round(shippingCost * 100);
      const fees = calculateOrderFees(cartSubtotalCents, sellerCount);
      const serviceFeeForThisChargeCents = idx === 0 ? fees.serviceFeeCents : 0;
      const applicationFeeCents = serviceFeeForThisChargeCents + fees.platformCommissionCents;
      const totalCents = cartSubtotalCents + shippingCents + serviceFeeForThisChargeCents;
      const sellerPayoutCents = cartSubtotalCents - fees.platformCommissionCents + shippingCents;

      return {
        sellerId,
        sellerStripeAccountId: sellerStripeIds.get(sellerId),
        chargeIndex: idx,
        items: orderItems,
        cardSubtotal,
        cartSubtotalCents,
        shippingCost,
        shippingCents,
        effectiveMethod,
        platformCommissionCents: fees.platformCommissionCents,
        commissionRateUsed: fees.commissionRateUsed,
        serviceFeeForThisChargeCents,
        applicationFeeCents,
        totalCents,
        sellerPayoutCents,
        sellerCountry,
        anyInsured,
      };
    });

    // 5. Sequential PI creation with rollback on first failure
    const successful = []; // [{ pi, orderId, group }]

    for (const group of cartGroups) {
      const orderRef = db.collection("artifacts").doc(APP_ID)
        .collection("orders").doc();
      const orderId = orderRef.id;

      // Reserve listings BEFORE PI creation so concurrent buyers see reserved
      // qty even before Stripe call returns.
      //
      // Phase 4 (2026-04-28) cart-res-aware fix: Wenn der User schon eine
      // Cart-Reservation fuer ein Listing hat, ist die Order-Reservation ein
      // Transfer (= reservedQty bleibt gleich, nur status flipt evtl. auf
      // "reserved"). Sonst (= direct buy ohne vorherigen Cart-Add):
      // increment reservedQty wie vorher.
      //
      // Das verhindert Ueber-Inkrementierung und das damit verbundene
      // status="reserved"-stuck-Problem nach Rollback (siehe Test B Befund).
      // Mirror der Logik in createPaymentIntent's Step 9 — beide Pfade
      // muessen identisch sein damit die Reservation-Semantik konsistent ist.
      const listingUpdates = [];
      for (const item of group.items) {
        const listingRef = db.collection("artifacts").doc(APP_ID)
          .collection("listings").doc(item.listingId);
        const listingDoc = await listingRef.get();
        if (!listingDoc.exists) continue;
        const listing = listingDoc.data();

        const cartResRef = db.collection("artifacts").doc(APP_ID)
          .collection("users").doc(uid)
          .collection("cartReservations").doc(item.listingId);
        const cartResDoc = await cartResRef.get();

        if (cartResDoc.exists) {
          // Cart-reserved → order-reserve ist Transfer. Keine reservedQty-Aenderung.
          // Status nur flippen wenn voll-reserviert + bisher nicht-reserved.
          const updateData = {};
          if ((listing.reservedQty || 0) >= listing.quantity &&
              listing.status !== "reserved") {
            updateData.status = "reserved";
          }
          if (Object.keys(updateData).length > 0) {
            await listingRef.update(updateData);
          }
          listingUpdates.push({
            ref: listingRef,
            wasCartReserved: true,
            cartResRef,
            prevStatus: listing.status,
            statusChanged: !!updateData.status,
            qtyAdded: 0,
          });
        } else {
          // Direct order-reserve: increment.
          const newReserved = (listing.reservedQty || 0) + item.quantity;
          const updateData = { reservedQty: newReserved };
          if (newReserved >= listing.quantity) updateData.status = "reserved";
          await listingRef.update(updateData);
          listingUpdates.push({
            ref: listingRef,
            wasCartReserved: false,
            cartResRef: null,
            prevStatus: listing.status,
            statusChanged: false,
            qtyAdded: item.quantity,
          });
        }
      }

      // Compute effectiveDelayDays for this seller
      const sellerProfRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(group.sellerId)
        .collection("data").doc("sellerProfile");
      const sellerProfDoc = await sellerProfRef.get();
      const sellerProfData = sellerProfDoc.exists ? sellerProfDoc.data() : {};
      const effectiveDelayDays = getEffectiveDelayDays(sellerProfData, group.totalCents);

      // EUR floats for legacy fields
      const platformFee = group.platformCommissionCents / 100;
      const buyerServiceFee = group.serviceFeeForThisChargeCents / 100;
      const totalPaid = group.totalCents / 100;
      const sellerPayout = group.sellerPayoutCents / 100;
      const subtotal = group.cardSubtotal;

      let pi;
      try {
        pi = await stripe.paymentIntents.create({
          amount: group.totalCents,
          currency: "eur",
          customer: customerId,
          payment_method: paymentMethodId,
          off_session: true,
          confirm: true,
          capture_method: "manual",
          transfer_data: { destination: group.sellerStripeAccountId },
          application_fee_amount: group.applicationFeeCents,
          metadata: {
            orderId,
            buyerId: uid,
            sellerId: group.sellerId,
            sellerCount: String(sellerCount),
            chargeIndex: String(group.chargeIndex),
            cartSubtotalCents: String(group.cartSubtotalCents),
            serviceFeeCents: String(group.serviceFeeForThisChargeCents),
            platformCommissionCents: String(group.platformCommissionCents),
            commissionRate: String(group.commissionRateUsed),
            effectiveDelayDays: String(effectiveDelayDays),
            multiSellerGroup: "true",
            cardNames: group.items.map((i) => i.cardName).join(", ").substring(0, 500),
          },
        }, {
          // Idempotency-Key (Security-Audit Round 2, 2026-04-29): pro
          // Multi-Seller-Group eindeutig — orderId ist server-generiert und
          // unique pro Order/Group. Verhindert Doppel-Charge bei Retry.
          idempotencyKey: `pi-create-${orderId}`,
        });
      } catch (err) {
        // Rollback: cancel listing reservations for THIS group + all successful PIs
        console.error(
          `processMultiSellerCart: PI failed at chargeIndex ${group.chargeIndex}: ${err.message}`,
        );
        for (const lu of listingUpdates) {
          // revert listing reservation back
          const listingRef = lu.ref;
          const listingDoc = await listingRef.get();
          if (!listingDoc.exists) continue;
          const listing = listingDoc.data();

          if (lu.wasCartReserved) {
            // Cart-reserved Transfer: reservedQty bleibt unveraendert.
            // Nur status zurueck setzen wenn wir ihn geaendert haben.
            if (lu.statusChanged) {
              await listingRef.update({ status: lu.prevStatus });
            }
          } else {
            // Direct order-reserve: decrement reservedQty.
            const newReserved = Math.max(
              0,
              (listing.reservedQty || 0) - lu.qtyAdded,
            );
            const updateData = { reservedQty: newReserved };
            if (listing.status === "reserved" && newReserved < listing.quantity) {
              updateData.status = "active";
            }
            await listingRef.update(updateData);
          }
        }

        // Cancel previous successful PIs (manual-capture = paymentIntents.cancel
        // releases auth, no money flow, no Stripe fee).
        for (const s of successful) {
          try {
            await stripe.paymentIntents.cancel(s.pi.id);
            await s.orderRef.update({
              status: "cancelled",
              cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
              cancelReason: "multi_seller_rollback",
            });
            // Release listings for the cancelled order.
            // Audit-Folge (2026-04-29): nur den Anteil dekrementieren der in
            // der Erfolgs-Phase tatsaechlich incrementet wurde. Bei einem
            // cart-reserved-transfer (ownCartReservedQty > 0) hat der
            // Erfolgs-Path die reservedQty NICHT erhoeht — also dekrementieren
            // wir auch nur die nicht-cart-reserved Differenz. Sonst flackert
            // reservedQty unter den eigentlichen cart-Wert und der User-Cart
            // wird inkonsistent (cart-doc deleted, listing-state mismatched).
            for (const item of (s.group.items || [])) {
              const lref = db.collection("artifacts").doc(APP_ID)
                .collection("listings").doc(item.listingId);
              const ldoc = await lref.get();
              if (!ldoc.exists) continue;
              const ldata = ldoc.data();
              const cartTransferQty = Math.min(
                item.ownCartReservedQty || 0,
                item.quantity || 0,
              );
              const incrementedQty = Math.max(
                0,
                (item.quantity || 0) - cartTransferQty,
              );
              const newR = Math.max(0, (ldata.reservedQty || 0) - incrementedQty);
              const ud = { reservedQty: newR };
              if (ldata.status === "reserved" && newR < ldata.quantity) {
                ud.status = "active";
              }
              await lref.update(ud);
            }
            console.log(`Rolled back: PI ${s.pi.id}, order ${s.orderId}`);
          } catch (rollbackErr) {
            console.error(
              `Rollback error for PI ${s.pi.id}: ${rollbackErr.message}`,
            );
          }
        }

        // Phase 4 (2026-04-28) Toast-Polish: User-facing Texte ohne
        // Implementation-Details (kein "seller 1/2", kein "decline_code").
        // Decline-Code-Mapping fuer die haeufigsten Faelle, sonst generisch.
        if (err.code === "authentication_required") {
          throw new HttpsError(
            "failed-precondition",
            "Your card needs an extra verification step. Please try again.",
          );
        }
        if (err.code === "card_declined") {
          // Decline-Code-Mapping zu nuetzlichen User-Hinweisen
          const declineMessages = {
            insufficient_funds: "Card has insufficient funds. Please try a different card.",
            lost_card: "This card was reported lost. Please use another card.",
            stolen_card: "This card cannot be used. Please use another card.",
            expired_card: "Card is expired. Please use another card.",
            incorrect_cvc: "Incorrect security code (CVC). Please check and try again.",
            processing_error: "Card processing error. Please try again or use another card.",
          };
          const msg = declineMessages[err.decline_code] ||
            "Your card was declined. Please try a different card.";
          throw new HttpsError("failed-precondition", msg);
        }

        // Generischer Fallback — keine Implementation-Details leaken
        throw new HttpsError(
          "aborted",
          "Payment couldn't be completed. Please try again.",
        );
      }

      // PI created successfully — write order doc
      await orderRef.set({
        buyerId: uid,
        sellerId: group.sellerId,
        sellerStripeAccountId: group.sellerStripeAccountId,
        items: group.items,
        // Legacy EUR
        subtotal,
        platformFee,
        buyerServiceFee,
        feePayer: "split",
        shippingCost: group.shippingCost,
        totalPaid,
        sellerPayout,
        // Cents
        cartSubtotalCents: group.cartSubtotalCents,
        shippingCents: group.shippingCents,
        serviceFeeCents: group.serviceFeeForThisChargeCents,
        platformCommissionCents: group.platformCommissionCents,
        totalApplicationFeeCents: group.applicationFeeCents,
        totalChargeCents: group.totalCents,
        sellerPayoutCents: group.sellerPayoutCents,
        commissionRateUsed: group.commissionRateUsed,
        sellerCount,
        chargeIndex: group.chargeIndex,
        effectiveDelayDays,
        shippingAddress,
        sellerAddress: sellerAddresses.get(group.sellerId),
        shippingMethod: group.effectiveMethod,
        stripePaymentIntentId: pi.id,
        paymentMethod: "stripe",
        status: "pending_payment",
        sellerName: sellerNames.get(group.sellerId),
        buyerName,
        preReleaseDate: listingsBySeller.get(group.sellerId)[0].listing.preReleaseDate || null,
        multiSellerGroupSize: sellerCount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Phase 4 (2026-04-28) cart-res-cleanup: Cart-Reservation-Docs werden
      // nach erfolgreichem Order-Doc-Write geloescht. Cart-Service ueber-
      // wacht diese Docs fuers Cart-State-Display; mit Order-Reserve sind
      // sie funktional ueberfluessig. Best-effort (delete-not-found ist OK).
      for (const lu of listingUpdates) {
        if (lu.wasCartReserved && lu.cartResRef) {
          try {
            await lu.cartResRef.delete();
          } catch (_) { /* not-found = already gone */ }
        }
      }

      successful.push({ pi, orderId, orderRef, group });
      console.log(
        `processMultiSellerCart: ${group.chargeIndex + 1}/${sellerCount} PI ${pi.id} order ${orderId} (${group.totalCents}ct)`,
      );
    }

    return {
      status: "all_succeeded",
      orderIds: successful.map((s) => s.orderId),
      sellerCount,
    };
  },
);

/**
 * markShipped — Callable, authenticated.
 * Seller marks order as shipped, captures payment.
 */
exports.markShipped = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId, trackingNumber } = request.data;

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.sellerId !== uid) {
      throw new HttpsError("permission-denied", "Only the seller can mark as shipped");
    }
    if (order.status !== "paid") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected paid`);
    }

    // ATO-Defense (Round 8 Pen-Test, 2026-04-29): block markShipped wenn
    // Seller-Account paused (z.B. nach Bank-Detail-Change). Capture haette
    // sonst Geld zur potenziell-Attacker-Bank geleitet (transfer_data routet
    // ueber Connect-Account das auf die geaenderte Bank zeigt). Order
    // bleibt im "paid" Status — Stripe Auth haelt 7 Tage, danach automatisch
    // released wenn nicht captured. Admin reviewt + entscheidet manuell.
    const shippingSellerRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("sellerProfile");
    const shippingSellerDoc = await shippingSellerRef.get();
    if (shippingSellerDoc.exists && shippingSellerDoc.data().payoutsPausedReason) {
      throw new HttpsError(
        "failed-precondition",
        "Your seller account is temporarily paused for security review. " +
        "Please contact support before shipping orders.",
      );
    }

    // Pre-release: block shipping before release date
    if (order.preReleaseDate) {
      const releaseDate = new Date(order.preReleaseDate + "T00:00:00Z");
      if (releaseDate > new Date()) {
        throw new HttpsError("failed-precondition", `Cannot ship before release date ${order.preReleaseDate}`);
      }
    }

    // Capture the PaymentIntent. Triggers `payment_intent.succeeded` webhook
    // (idempotent — order already in "paid" via amount_capturable_updated).
    // Funds get released from auth-hold and start the delay_days clock for
    // payout to the seller's Connect account.
    //
    // Legacy `paymentMethod === "balance"` orders (pre-Phase-2) had no
    // PaymentIntent — `order.stripePaymentIntentId` is the gate.
    if (order.stripePaymentIntentId) {
      const stripe = getStripe();
      await stripe.paymentIntents.capture(order.stripePaymentIntentId);
    }

    // First-5-Sales Extra-Hold (Round 11, 2026-04-29 — Cardmarket-Pattern):
    // Cardmarket macht "Trustee Service" obligatorisch fuer die ersten
    // 5 Sales jedes neuen Sellers. Sie halten Geld bis Buyer aktiv
    // bestaetigt (kein time-based auto-release).
    // Riftr-Adaption: doppelter Buyer-Protection-Window fuer first-5-sales.
    // Stripe delay_days bleibt 7 (Account-level), aber autoReleaseAt wird
    // auf 14 Tage gesetzt → Buyer hat 14 statt 7 Tage Zeit fuer Disputes.
    // Bei dispute-in-window: refund-flow holt Geld via reverse_transfer
    // zurueck (auch wenn Stripe schon ausgezahlt hat).
    const sellerProfileForHold = await db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("sellerProfile").get();
    const completedSales = sellerProfileForHold.exists
      ? (sellerProfileForHold.data().completedSalesCount || 0)
      : 0;
    const isFirstFiveSales = completedSales < 5;
    const protectionDays = isFirstFiveSales ? 14 : 7;
    const autoReleaseAt = new Date(Date.now() + protectionDays * 24 * 60 * 60 * 1000);

    await orderRef.update({
      status: "shipped",
      trackingNumber: trackingNumber || null,
      shippedAt: admin.firestore.FieldValue.serverTimestamp(),
      autoReleaseAt: autoReleaseAt.toISOString(),
      ...(isFirstFiveSales ? {
        firstFiveSalesExtraHold: true,
        firstFiveSalesIndex: completedSales + 1,
      } : {}),
    });

    if (isFirstFiveSales) {
      console.log(
        `markShipped: order ${orderId} seller=${uid} new-seller-hold ` +
        `(sale #${completedSales + 1}/5, autoReleaseAt=14d instead of 7d)`,
      );
    }

    // 1. Calculate realized gains BEFORE removing from collection (needs cost basis)
    const { totalRealizedGain } = await calculateRealizedGains(order.sellerId, order.items || []);

    // Store realized gain on order doc for potential dispute/storno reversal
    if (totalRealizedGain !== 0) {
      await orderRef.update({ realizedGainOnShip: totalRealizedGain });
    }

    // 2. Remove sold items from seller's collection
    await removeItemsFromSellerCollection(order);

    console.log(`Order ${orderId} shipped (tracking: ${trackingNumber || "none"}, realizedGain: €${totalRealizedGain.toFixed(2)})`);

    // Notify buyer that order shipped
    const shipSummary = orderItemsSummary(order.items);
    sendNotification(order.buyerId, "Order shipped!", `${shipSummary} is on its way.${trackingNumber ? " Tracking: " + trackingNumber : ""}`, { type: "order", orderId });

    return { success: true };
  }
);

// ── Update Tracking Number ──

exports.updateTrackingNumber = onCall(
  { region: "europe-west1", timeoutSeconds: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId, trackingNumber } = request.data;

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.sellerId !== uid) {
      throw new HttpsError("permission-denied", "Only the seller can update tracking");
    }

    const blocked = ["delivered", "autoCompleted", "refunded", "cancelled"];
    if (blocked.includes(order.status)) {
      throw new HttpsError("failed-precondition", "Cannot update tracking on a completed order");
    }

    await orderRef.update({
      trackingNumber: trackingNumber || null,
    });

    // Notify buyer
    if (trackingNumber) {
      const summary = orderItemsSummary(order.items);
      sendNotification(order.buyerId, "Tracking updated", `${summary} — Tracking: ${trackingNumber}`, { type: "order", orderId: orderId });
    }

    console.log(`Order ${orderId} tracking updated: ${trackingNumber || "removed"}`);
    return { success: true };
  }
);

/**
 * confirmDelivery — Callable, authenticated.
 * Buyer confirms receipt. Finalizes order.
 */
exports.confirmDelivery = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId } = request.data;

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    // Race-Protection (Security-Audit Round 5, 2026-04-29):
    // Vorher: separate read + check + update — race vs autoReleaseOrders
    // bei dem beide Side-Effect-Loops laufen koennten (totalSales 2x,
    // addItemsToCollection 2x → Buyer-Collection-Double, Seller-Stats inflated).
    // Jetzt: atomarer state-flip in TX. Wenn autoReleaseOrders schon
    // status=auto_completed gesetzt hat, schlaegt unsere TX fehl (status
    // !== "shipped") und Side-Effects laufen NICHT. Nur die siegreiche
    // CF triggert Side-Effects — Stats + Collection sind dann konsistent.
    let order;
    try {
      order = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(orderRef);
        if (!fresh.exists) throw new HttpsError("not-found", "Order not found");
        const data = fresh.data();
        if (data.buyerId !== uid) {
          throw new HttpsError("permission-denied", "Only the buyer can confirm delivery");
        }
        if (data.status !== "shipped") {
          throw new HttpsError("failed-precondition", `Order status is ${data.status}, expected shipped`);
        }
        // 30-day Dispute-Window (Round 11, 2026-04-29 — TCGplayer-Pattern):
        // TCGplayer "Safeguard": Buyer kann bis 30 Tage nach Lieferung
        // Dispute oeffnen. Wir setzen disputeWindowEndsAt = deliveredAt + 30d
        // damit openDispute auch in delivered/auto_completed-Status moeglich
        // ist (siehe openDispute-Check unten).
        const disputeWindowEndsAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
        tx.update(orderRef, {
          status: "delivered",
          deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
          disputeWindowEndsAt: disputeWindowEndsAt.toISOString(),
        });
        return data;
      });
    } catch (err) {
      // HttpsError-instanceof check fuer richtige Fehlerweitergabe
      if (err instanceof HttpsError) throw err;
      throw new HttpsError("aborted", `confirmDelivery transaction failed: ${err.message}`);
    }

    // All post-status operations: if any fail, order stays delivered
    // but we log the error and still return success to the buyer
    try {
      // Increment seller stats (set+merge so doc is created if missing).
      // totalSales = item count; completedSalesCount = order count (für
      // Tier-System — siehe calculateDelayDays).
      const totalQty = (order.items || []).reduce((sum, item) => sum + (item.quantity || 1), 0);
      const sellerRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(order.sellerId)
        .collection("data").doc("sellerProfile");
      await sellerRef.set({
        totalSales: admin.firestore.FieldValue.increment(totalQty),
        totalRevenue: admin.firestore.FieldValue.increment(order.sellerPayout || 0),
        completedSalesCount: admin.firestore.FieldValue.increment(1),
      }, { merge: true });

      // Record sale prices for analytics
      await recordSales(order, orderId);

      // Realized gains already calculated in markShipped — no need here

      // Add purchased cards to buyer's collection
      await addItemsToCollection(order);

      // Reduce listing quantities (mark sold if 0)
      await finalizeListingQuantities(order.items || []);

      // Recalculate seller balance (moves funds out of escrow → available)
      await updateBalanceCache(order.sellerId);

      console.log(`Order ${orderId} delivered, seller ${order.sellerId} stats updated, balance cache refreshed`);

      // Phase 7: Push an Verkaeufer mit tier-aware Auszahlungs-Info.
      // confirmDelivery setzt status=delivered. Capture lief schon bei
      // markShipped, Geld ist in Stripe-Connect-Pending mit `delay_days`-
      // Hold. Verkaeufer erfaehrt:
      //   - Buyer hat Erhalt bestaetigt
      //   - Plattform-Status: kein Streit moeglich mehr
      //   - Auszahlung erfolgt automatisch nach delay_days (siehe Tier)
      const delSummary = orderItemsSummary(order.items);
      const effDelay = order.effectiveDelayDays != null
        ? order.effectiveDelayDays
        : 7;
      const dayLabel = effDelay === 1 ? "day" : "days";
      sendNotification(
        order.sellerId,
        "Delivery confirmed!",
        `${delSummary} — Käufer hat Erhalt bestätigt. Auszahlung in ${effDelay} ${dayLabel} (€${(order.sellerPayout || 0).toFixed(2)}).`,
        { type: "order", orderId: orderId },
      );

      // Tier-Sync — abgeschlossener Verkauf kann Schwelle für Aufstieg
      // überschreiten. Idempotent + error-safe (loggt nur).
      try {
        await syncSellerTier(order.sellerId);
      } catch (err) {
        console.error(`syncSellerTier after confirmDelivery failed for ${order.sellerId}:`, err.message);
      }

      // Public-Stats-Mirror — totalSales hat sich erhoeht, playerProfiles
      // muss aktualisiert werden damit Listings/Social-Tab den neuen
      // Wert sehen. (Security: PII bleibt im sellerProfile, nicht im Mirror.)
      await syncPlayerProfile(order.sellerId);

      // Sock-Puppet / Wash-Trading Detection (Round 10 Insider-Audit, 2026-04-29):
      // Strategie 1 — Seller A nutzt Friends mit eigenen Accounts um sich Reviews
      // zu erschummeln. Cost: €1-Listing × 50 Wash-Trades = €54 → Trusted-Tier.
      // Defense: track Buyer-Seller-Pair-Velocity. Echter Power-Buyer kauft selten
      // 5+ mal beim gleichen Seller in 30 Tagen — Wash-Trading-Pattern stark
      // korreliert mit "many small txns same pair".
      try {
        await trackBuyerSellerPair(order.buyerId, order.sellerId, order.totalPaid || 0);
      } catch (pairErr) {
        console.error(`trackBuyerSellerPair failed for order ${orderId}:`, pairErr.message);
      }
    } catch (postErr) {
      console.error(`confirmDelivery post-status error for ${orderId}:`, postErr);
      // Don't throw — order IS delivered, buyer should see success
    }

    return { success: true };
  }
);

// ═══════════════════════════════════════════
// ─── Refund / Dispute Policy Engine (Phase 6) ───
// ═══════════════════════════════════════════
//
// Single Source of Truth fuer Refund-Eligibility + Stripe-Refund-Parameter.
// Wird von cancelOrder, acceptCancelOrder, respondToRefund und openDispute
// aufgerufen. Differenzierte Service-Fee-Policy:
//
//   - Voll-Refund inkl. Service-Gebuehr (refund_application_fee: true) bei
//     "klar Verkaeufer-Schuld":
//       • not_arrived + (untracked OR tracked-no-trackingNumber)
//       • wrong_card_received
//       • damaged_in_shipping (NICHT insured)
//
//   - Teil-Refund OHNE Service-Gebuehr (refund_application_fee: false) bei:
//       • Beliebigem percent < 100 (Verkaeufer hat geliefert, Streitfall)
//       • Voll-Refund mit reason "wrong_condition" (Verkaeufer hat geliefert,
//         aber in disputiertem Zustand)
//
//   - Reject (kein Refund) bei:
//       • not_arrived + insured (Carrier-Pfad — Buyer reklamiert bei Versicherer)
//
// Alle Refunds nutzen `reverse_transfer: true` damit das Geld vom Verkaeufer-
// Connect-Account zurueck zur Plattform gezogen wird (sonst absorbiert die
// Plattform den vollen Refund-Betrag — kritischer Production-Bug pre-Phase-6).

const REFUND_REASONS = {
  NOT_ARRIVED: "not_arrived",
  WRONG_CONDITION: "wrong_condition",
  WRONG_CARD: "wrong_card",
  DAMAGED: "damaged",
};

// Frontend `openDispute` sendet noch die alten Display-Labels — Mapping
// zu Reason-Codes. Phase 7+ kann das Frontend auf Codes umstellen.
const DISPUTE_REASON_TO_CODE = {
  "Not arrived": REFUND_REASONS.NOT_ARRIVED,
  "Wrong condition (worse than listed)": REFUND_REASONS.WRONG_CONDITION,
  "Wrong card received": REFUND_REASONS.WRONG_CARD,
  "Damaged in shipping": REFUND_REASONS.DAMAGED,
};

/**
 * Evaluiert ob fuer eine Order + Reason ueberhaupt ein Plattform-Refund
 * moeglich ist. Aktuell hauptsaechlich Insurance-Routing — Versicherte
 * Sendungen die nicht ankommen werden zum Carrier weitergeleitet.
 *
 * @param {object} order — Order-Doc aus Firestore
 * @param {string} reasonCode — REFUND_REASONS.* Wert
 * @returns {{eligible: boolean, message?: string}}
 */
function evaluateRefundEligibility(order, reasonCode) {
  // Insurance: bei not_arrived + insured -> Carrier-Pfad
  if (
    reasonCode === REFUND_REASONS.NOT_ARRIVED &&
    order.shippingMethod === "insured"
  ) {
    return {
      eligible: false,
      message:
        "Insured shipping covers loss — please file a claim with the carrier (Deutsche Post / DHL). " +
        "Riftr does not process refunds for insured shipments.",
    };
  }
  return { eligible: true };
}

/**
 * Berechnet die Stripe-Refund-Parameter fuer eine konkrete Order +
 * Reason + Percent. Differenzierte Service-Fee-Policy basierend auf Schuld.
 *
 * @param {object} order — Order-Doc aus Firestore
 * @param {string} reasonCode — REFUND_REASONS.* Wert (oder null fuer cancel-Faelle)
 * @param {number} refundPercent — 10-100; bei <100 immer service-fee-stays
 * @returns {{
 *   amount: number|null,        — Stripe-Refund-Amount in Cents (null = full PI amount)
 *   refundApplicationFee: boolean,
 *   reverseTransfer: boolean,
 *   serviceFeeStaysWithPlatform: boolean,
 *   refundedAmountEur: number,  — Was der Buyer tatsaechlich zurueck-bekommt
 * }}
 */
function resolveRefundPolicy(order, reasonCode, refundPercent) {
  const totalCents = Math.round((order.totalPaid || 0) * 100);
  const serviceFeeCents =
    order.serviceFeeCents != null
      ? order.serviceFeeCents
      : Math.round((order.buyerServiceFee || 0) * 100);

  // "Klar Verkaeufer-Schuld" Klassifikator — Service-Fee zurueck zum Buyer.
  const trackingNumber = order.trackingNumber || null;
  const shippingMethod = order.shippingMethod;

  const isClearSellerFault =
    (reasonCode === REFUND_REASONS.NOT_ARRIVED &&
      (shippingMethod === "letter" ||
        (shippingMethod === "tracked" && !trackingNumber))) ||
    reasonCode === REFUND_REASONS.WRONG_CARD ||
    (reasonCode === REFUND_REASONS.DAMAGED && shippingMethod !== "insured");

  // Voll-Refund + klar-Verkaeufer-Schuld: alles zurueck inkl. Service-Gebuehr
  if (refundPercent >= 100 && isClearSellerFault) {
    return {
      amount: null, // null = full PI amount
      refundApplicationFee: true,
      reverseTransfer: true,
      serviceFeeStaysWithPlatform: false,
      refundedAmountEur: totalCents / 100,
    };
  }

  // Teil-Refund ODER Voll-Refund-aber-Verkaeufer-hat-geliefert:
  // Service-Gebuehr bleibt bei der Plattform, Rest wird (anteilig) refundet.
  // Buyer-Refund-Amount = totalCents * percent/100, aber gecappt damit nie
  // mehr als (totalCents - serviceFeeCents) refundet wird (= Service-Fee
  // bleibt geschuetzt).
  const proportional = Math.round((totalCents * refundPercent) / 100);
  const maxNonServiceFee = totalCents - serviceFeeCents;
  const finalAmount = Math.min(proportional, maxNonServiceFee);

  return {
    amount: finalAmount,
    refundApplicationFee: false,
    reverseTransfer: true,
    serviceFeeStaysWithPlatform: true,
    refundedAmountEur: finalAmount / 100,
  };
}

/**
 * openDispute — Callable, buyer only.
 * Opens a dispute on a shipped order, pausing auto-release.
 */
exports.openDispute = onCall(
  { region: "europe-west1", timeoutSeconds: 15 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId, reason, description } = request.data;

    if (!orderId || !reason) {
      throw new HttpsError("invalid-argument", "orderId and reason are required");
    }

    const validReasons = [
      "Not arrived",
      "Wrong condition (worse than listed)",
      "Wrong card received",
      "Damaged in shipping",
    ];
    if (!validReasons.includes(reason)) {
      throw new HttpsError("invalid-argument", "Invalid dispute reason");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.buyerId !== uid) {
      throw new HttpsError("permission-denied", "Only the buyer can open a dispute");
    }
    // 30-day Dispute-Window (Round 11, 2026-04-29 — TCGplayer-Pattern):
    // Vorher: Dispute nur in `shipped`-Status moeglich. Nach confirmDelivery
    // oder auto-release wurde der Status zu delivered/auto_completed →
    // Buyer konnte nicht mehr nachtraeglich disputen (z.B. wenn Karte
    // 10 Tage nach „delivered" als counterfeit erkennbar wird).
    // Jetzt: Dispute auch in delivered/auto_completed moeglich, solange
    // disputeWindowEndsAt nicht abgelaufen ist (30 Tage nach Delivery).
    const isShipped = order.status === "shipped";
    const isInPostDeliveryWindow =
      (order.status === "delivered" || order.status === "auto_completed") &&
      order.disputeWindowEndsAt &&
      new Date(order.disputeWindowEndsAt) > new Date();
    if (!isShipped && !isInPostDeliveryWindow) {
      throw new HttpsError(
        "failed-precondition",
        order.status === "delivered" || order.status === "auto_completed"
          ? `Dispute window closed (30-day post-delivery period expired)`
          : `Order status is ${order.status}, dispute not allowed`,
      );
    }

    // Phase 6: Reason-Code-Mapping fuer Refund-Policy-Engine. Frontend sendet
    // weiterhin Display-Labels — das Mapping ist serverseitig.
    const reasonCode = DISPUTE_REASON_TO_CODE[reason];

    // Phase 6: Insurance-Reject. Versicherte „Not arrived"-Faelle gehen zum
    // Carrier (Deutsche Post / DHL), nicht zur Plattform-Schlichtung.
    const eligibility = evaluateRefundEligibility(order, reasonCode);
    if (!eligibility.eligible) {
      throw new HttpsError("failed-precondition", eligibility.message);
    }

    const safeDesc = typeof description === "string" ? description.trim().substring(0, 500) : null;

    await orderRef.update({
      status: "disputed",
      disputeStatus: "open",
      disputeReason: reason,
      disputeReasonCode: reasonCode, // Phase 6: strukturierter Code fuer Policy
      ...(safeDesc ? { disputeDescription: safeDesc } : {}),
      disputedAt: admin.firestore.FieldValue.serverTimestamp(),
      autoReleaseAt: null, // Pause auto-release
    });

    console.log(`Dispute opened on order ${orderId}: ${reason}${safeDesc ? ` — ${safeDesc}` : ""}`);

    // Notify seller about dispute
    const dispSummary = orderItemsSummary(order.items);
    sendNotification(order.sellerId, "Dispute opened", `${dispSummary}: ${reason}`, { type: "order", orderId: orderId });

    // Pattern-Detection: bei ≥3 / ≥5 Disputes in 6 Monaten Auto-Sanktion.
    // Try/catch damit der Hauptpfad nicht blockt — der Dispute ist bereits
    // erfolgreich geoeffnet, Pattern-Detection ist nice-to-have.
    try {
      await _evaluateDisputePatternSanction(order.sellerId, orderId);
    } catch (patternErr) {
      console.error(
        `openDispute: pattern-detection failed for seller=${order.sellerId} order=${orderId}: ${patternErr.message}`,
      );
    }

    return { success: true };
  }
);

/**
 * cancelOrder — Callable, authenticated.
 * Cancels an order (pre-ship only). Refunds if captured.
 */
exports.cancelOrder = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId } = request.data;

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.buyerId !== uid && order.sellerId !== uid) {
      throw new HttpsError("permission-denied", "Only buyer or seller can cancel");
    }
    if (order.status !== "pending_payment" && order.status !== "paid") {
      throw new HttpsError("failed-precondition", "Order cannot be cancelled after shipping");
    }

    // Phase 6 (2026-04-28): Legacy paymentMethod=balance Orders sind alle
    // geloescht (114 Test-Orders). Code-Pfad nicht mehr supported — wenn doch
    // einer durchkommt: explizite Fehlermeldung.
    if (order.paymentMethod === "balance") {
      throw new HttpsError(
        "failed-precondition",
        "Legacy balance order — please contact support.",
      );
    }

    const stripe = getStripe();
    const piId = order.stripePaymentIntentId;
    if (!piId) {
      throw new HttpsError(
        "failed-precondition",
        "Order has no PaymentIntent — cannot cancel.",
      );
    }

    // Phase 6: Pre-ship-Cancel ist KEIN Refund — es ist eine reine PI-
    // Stornierung. Bei capture_method:"manual" (= unser Standard) ist die PI
    // entweder requires_payment_method (pending_payment) oder requires_capture
    // (paid, vor markShipped). Stripe.paymentIntents.cancel() funktioniert in
    // beiden Faellen und gibt die Auth wieder frei — Plattform-neutral, kein
    // Geld floss.
    //
    // Falls ein Order schon den Capture (= shipped) durch hatte, kommt
    // dieser Pfad gar nicht zum Zug (status-Check oben blockiert).
    try {
      await stripe.paymentIntents.cancel(piId);
    } catch (e) {
      // Already cancelled / completed — safe to continue, weiter mit Order/
      // Listing-Cleanup (idempotent).
      console.warn(
        `cancelOrder: PI ${piId} cancel skipped: ${e.message}`,
      );
    }

    // Update order
    await orderRef.update({
      status: "cancelled",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelReason: "user_cancelled_pre_ship",
    });

    // Release listing reservation
    for (const item of (order.items || [])) {
      if (item.listingId) {
        const listingRef = db.collection("artifacts").doc(APP_ID)
          .collection("listings").doc(item.listingId);
        const listingDoc = await listingRef.get();
        if (listingDoc.exists) {
          const listing = listingDoc.data();
          const newReserved = Math.max(0, (listing.reservedQty || 0) - (item.quantity || 1));
          const updateData = { reservedQty: newReserved };
          if (listing.status === "reserved") {
            updateData.status = "active";
          }
          await listingRef.update(updateData);
        }
      }
    }

    console.log(`Order ${orderId} cancelled pre-ship by ${uid}`);

    // Notify the other party
    const otherUid = uid === order.buyerId ? order.sellerId : order.buyerId;
    const cancelSummary = orderItemsSummary(order.items);
    sendNotification(otherUid, "Order cancelled", `${cancelSummary} — refunded.`, { type: "order", orderId: orderId });

    return { success: true };
  }
);

/**
 * proposeRefund — Callable, seller only.
 * Seller proposes a partial or full refund (10-100%) for a disputed order.
 */
exports.proposeRefund = onCall(
  { region: "europe-west1", timeoutSeconds: 15 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId, refundPercent } = request.data;

    if (!orderId || refundPercent == null) {
      throw new HttpsError("invalid-argument", "orderId and refundPercent are required");
    }

    const percent = Math.round(Number(refundPercent));
    if (percent < 10 || percent > 100) {
      throw new HttpsError("invalid-argument", "refundPercent must be 10-100");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.sellerId !== uid) {
      throw new HttpsError("permission-denied", "Only the seller can propose a refund");
    }
    if (order.status !== "disputed") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected disputed`);
    }
    if (order.disputeStatus && order.disputeStatus !== "open") {
      throw new HttpsError("failed-precondition", `Dispute status is ${order.disputeStatus}, expected open`);
    }

    const refundAmount = Math.round(order.totalPaid * percent) / 100;

    await orderRef.update({
      disputeStatus: "sellerProposed",
      proposedRefundPercent: percent,
      proposedRefundAmount: refundAmount,
      proposedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Seller ${uid} proposed ${percent}% refund (€${refundAmount.toFixed(2)}) on order ${orderId}`);

    const summary = orderItemsSummary(order.items);
    sendNotification(order.buyerId, "Refund proposed", `${summary}: ${percent}% refund (€${refundAmount.toFixed(2)}) — review and accept or reject.`, { type: "order", orderId });

    return { success: true, refundPercent: percent, refundAmount };
  }
);

/**
 * respondToRefund — Callable, buyer only.
 * Buyer accepts or rejects the seller's refund proposal.
 */
exports.respondToRefund = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId, accept } = request.data;

    if (!orderId || accept == null) {
      throw new HttpsError("invalid-argument", "orderId and accept are required");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.buyerId !== uid) {
      throw new HttpsError("permission-denied", "Only the buyer can respond to a refund proposal");
    }
    if (order.status !== "disputed") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected disputed`);
    }
    if (order.disputeStatus !== "sellerProposed") {
      throw new HttpsError("failed-precondition", `No pending proposal (status: ${order.disputeStatus})`);
    }

    const summary = orderItemsSummary(order.items);

    if (accept) {
      // Phase 6: Connect-native Refund via stripe.refunds.create mit
      // reverse_transfer + Policy-aware refund_application_fee.
      // Legacy paymentMethod=balance Orders gibt's nicht mehr (alle 114
      // Test-Orders geloescht in Phase 6).
      if (order.paymentMethod === "balance") {
        throw new HttpsError(
          "failed-precondition",
          "Legacy balance order — please contact support.",
        );
      }

      const piId = order.stripePaymentIntentId;
      if (!piId) {
        throw new HttpsError(
          "failed-precondition",
          "No payment intent found",
        );
      }

      const stripe = getStripe();
      const refundPercent = order.proposedRefundPercent || 100;

      // Policy-Engine: bestimmt amount + refund_application_fee basierend
      // auf Reason + Percent (siehe resolveRefundPolicy oben).
      const policy = resolveRefundPolicy(
        order,
        order.disputeReasonCode || null,
        refundPercent,
      );

      const refundParams = {
        payment_intent: piId,
        reverse_transfer: policy.reverseTransfer,
        refund_application_fee: policy.refundApplicationFee,
      };
      if (policy.amount != null) {
        refundParams.amount = policy.amount;
      }

      // Idempotency-Key (Security-Audit Round 2, 2026-04-29): bei
      // Network-Retry oder Buyer-Tap-Spam wird hier sonst ein 2. Refund
      // erstellt. Stripe deduped automatisch wenn idempotencyKey identisch.
      // Key = order-spezifisch + Pfad-spezifisch damit `respondToRefund`
      // und `adminResolveDispute` nicht versehentlich kollidieren.
      const refund = await stripe.refunds.create(refundParams, {
        idempotencyKey: `refund-respond-${orderId}-${refundPercent}`,
      });
      console.log(
        `respondToRefund: refund ${refund.id} created for order ${orderId} ` +
        `(percent=${refundPercent}, amount=${policy.refundedAmountEur.toFixed(2)}, ` +
        `serviceFeeStays=${policy.serviceFeeStaysWithPlatform}, ` +
        `reason=${order.disputeReasonCode})`,
      );

      // Order doc: actual refund amount stays as proposedRefundAmount fuer
      // Audit; refundedAmount-Field zeigt den tatsaechlich an Buyer
      // ausgezahlten Betrag (kann von proposedRefundAmount abweichen wenn
      // Service-Fee bei der Plattform bleibt).
      await orderRef.update({
        status: "refunded",
        disputeStatus: "resolved",
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        refundedAmount: policy.refundedAmountEur,
        refundServiceFeeStaysWithPlatform: policy.serviceFeeStaysWithPlatform,
        stripeRefundId: refund.id,
      });

      // Release listing reservation
      for (const item of (order.items || [])) {
        if (item.listingId) {
          const listingRef = db.collection("artifacts").doc(APP_ID)
            .collection("listings").doc(item.listingId);
          const listingDoc = await listingRef.get();
          if (listingDoc.exists) {
            const listing = listingDoc.data();
            const newReserved = Math.max(0, (listing.reservedQty || 0) - (item.quantity || 1));
            const updateData = { reservedQty: newReserved };
            if (listing.status === "reserved") {
              updateData.status = "active";
            }
            await listingRef.update(updateData);
          }
        }
      }

      // Reverse realized gains proportionally to refund percent
      const gainOnRecord = order.realizedGainOnShip || order.realizedGainOnDelivery || 0;
      if (gainOnRecord && order.sellerId) {
        const reversalAmount = gainOnRecord * (refundPercent / 100);
        const sellerProfileRef = db.collection("artifacts").doc(APP_ID)
          .collection("users").doc(order.sellerId).collection("data").doc("profile");
        await sellerProfileRef.set({
          realizedGains: admin.firestore.FieldValue.increment(-reversalAmount),
        }, { merge: true });
        console.log(`Reversed realized gains for seller ${order.sellerId}: -€${reversalAmount.toFixed(2)} (${refundPercent}% of ${gainOnRecord.toFixed(2)})`);
      }

      // Strike seller only for significant refunds (>50%)
      if (refundPercent > 50) {
        await addStrike(order.sellerId, `Dispute refund ${refundPercent}% on order ${orderId}`);
      }

      sendNotification(
        order.sellerId,
        "Refund accepted",
        `${summary}: €${policy.refundedAmountEur.toFixed(2)} refunded to buyer.`,
        { type: "order", orderId },
      );

      return {
        success: true,
        action: "refunded",
        refundAmount: policy.refundedAmountEur,
        serviceFeeStaysWithPlatform: policy.serviceFeeStaysWithPlatform,
      };
    } else {
      // Reject — reset to open so seller can propose again
      await orderRef.update({
        disputeStatus: "open",
        proposedRefundPercent: null,
        proposedRefundAmount: null,
        proposedAt: null,
      });

      console.log(`Refund rejected by buyer on order ${orderId}`);
      sendNotification(order.sellerId, "Refund rejected", `${summary}: Buyer rejected your proposal. Propose a different amount.`, { type: "order", orderId });

      return { success: true, action: "rejected" };
    }
  }
);

/**
 * cancelDispute — Callable, buyer only.
 * Buyer withdraws the dispute, returning order to shipped status.
 */
exports.cancelDispute = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { orderId } = request.data;

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required");
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data();
    if (order.buyerId !== uid) {
      throw new HttpsError("permission-denied", "Only the buyer can cancel a dispute");
    }
    if (order.status !== "disputed") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected disputed`);
    }

    // Reset to shipped with fresh 7-day auto-release
    const autoRelease = new Date();
    autoRelease.setDate(autoRelease.getDate() + 7);

    await orderRef.update({
      status: "shipped",
      disputeStatus: "cancelled",
      autoReleaseAt: autoRelease.toISOString(),
      proposedRefundPercent: null,
      proposedRefundAmount: null,
      proposedAt: null,
    });

    // Recalculate seller balance (order is back in escrow as "shipped")
    await updateBalanceCache(order.sellerId);

    console.log(`Dispute cancelled by buyer on order ${orderId}`);

    const summary = orderItemsSummary(order.items);
    sendNotification(order.sellerId, "Dispute cancelled", `${summary}: Buyer withdrew the dispute.`, { type: "order", orderId: orderId });

    return { success: true };
  }
);

/**
 * autoReleaseOrders — Scheduled, daily at 03:00 Berlin.
 * Auto-completes orders shipped 7+ days ago without buyer confirmation.
 */
exports.autoReleaseOrders = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "Europe/Berlin",
    timeoutSeconds: 120,
    region: "europe-west1",
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async () => {
    const now = new Date().toISOString();
    const ordersRef = db.collection("artifacts").doc(APP_ID).collection("orders");

    const snap = await ordersRef
      .where("status", "==", "shipped")
      .where("autoReleaseAt", "<=", now)
      .get();

    if (snap.empty) {
      console.log("autoReleaseOrders: no orders to release");
      return;
    }

    for (const doc of snap.docs) {
      // Race-Protection (Security-Audit Round 5, 2026-04-29):
      // Vorher: naiver update ohne State-Re-Check → bei concurrent
      // confirmDelivery liefen beide Side-Effects-Loops (Double-Inc auf
      // totalSales/totalRevenue + Double-addItemsToCollection auf Buyer-
      // Sammlung). Jetzt atomarer State-Flip in TX. Wenn confirmDelivery
      // den Status schon auf "delivered" gehoben hat, skippt diese
      // Iteration cleanly — keine doppelten Side-Effects.
      let order;
      try {
        order = await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return null;
          const data = fresh.data();
          if (data.status !== "shipped") return null;
          // Doppelt-Sicher: autoReleaseAt nochmal pruefen (Doc-Snapshot
          // koennte stale sein nach langer Cron-Iteration).
          if (!data.autoReleaseAt || new Date(data.autoReleaseAt) > new Date()) {
            return null;
          }
          // 30-day dispute window (Round 11 — TCGplayer-Pattern):
          // auch bei auto_completed bekommt Buyer 30 Tage Dispute-Recht
          // ab Auto-Release-Datum. Falls Buyer untaetig war + Karte
          // doch nicht erhalten/wrong-condition, kann er nachtraeglich
          // disputen.
          const disputeWindowEndsAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
          tx.update(doc.ref, {
            status: "auto_completed",
            deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
            disputeWindowEndsAt: disputeWindowEndsAt.toISOString(),
          });
          return data;
        });
      } catch (txErr) {
        console.error(`autoReleaseOrders ${doc.id} TX-flip failed: ${txErr.message}`);
        continue;
      }
      if (!order) {
        // Status wurde bereits durch confirmDelivery o.ae. veraendert —
        // skip, kein Side-Effect-Run.
        console.log(`autoReleaseOrders: skipping ${doc.id} (status already advanced)`);
        continue;
      }

      // Update seller stats (set+merge so doc is created if missing)
      const totalQty = (order.items || []).reduce((sum, item) => sum + (item.quantity || 1), 0);
      const sellerRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(order.sellerId)
        .collection("data").doc("sellerProfile");
      await sellerRef.set({
        totalSales: admin.firestore.FieldValue.increment(totalQty),
        totalRevenue: admin.firestore.FieldValue.increment(order.sellerPayout || 0),
      }, { merge: true });

      // Record sale prices for analytics
      await recordSales(order, doc.id);

      // Realized gains already calculated in markShipped — no need here

      // Add purchased cards to buyer's collection
      await addItemsToCollection(order);

      // Reduce listing quantities (mark sold if 0)
      await finalizeListingQuantities(order.items || []);

      // Recalculate seller balance (escrow → available)
      await updateBalanceCache(order.sellerId);

      // Notify buyer about auto-completion
      sendNotification(order.buyerId, "Order auto-completed", "Your order was automatically completed.", { type: "order", orderId: doc.id });

      // Sock-Puppet-Detection (Round 10) auch hier — Wash-Traders koennten
      // bewusst auto-release laufen lassen um confirmDelivery zu skippen
      // (wenig wahrscheinlich, weil sie Reviews wollen — aber Sicher ist sicher).
      try {
        await trackBuyerSellerPair(order.buyerId, order.sellerId, order.totalPaid || 0);
      } catch (pairErr) {
        console.error(`trackBuyerSellerPair (auto-release) failed:`, pairErr.message);
      }
    }

    console.log(`autoReleaseOrders: completed ${snap.size} orders`);

    // ── Day 5 Reminder: nudge sellers about unshipped orders ──
    const fiveDaysAgo = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString();
    const fourDaysAgo = new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString();
    const reminderSnap = await ordersRef
      .where("status", "==", "paid")
      .where("paidAt", ">=", fiveDaysAgo)
      .where("paidAt", "<=", fourDaysAgo)
      .get();

    for (const doc of reminderSnap.docs) {
      const order = doc.data();
      // Skip pre-release orders — reminders start after release date
      if (order.preReleaseDate && new Date(order.preReleaseDate) > new Date()) continue;
      sendNotification(order.sellerId, "Shipping reminder", "You have an unshipped order. Please ship soon.", { type: "order", orderId: doc.id });
    }

    if (!reminderSnap.empty) {
      console.log(`autoReleaseOrders: sent ${reminderSnap.size} shipping reminder(s)`);
    }

    // ── Pre-Release: Release-day notifications ──
    const todayStr = new Date().toISOString().substring(0, 10);
    const preReleaseSnap = await ordersRef
      .where("status", "==", "paid")
      .where("preReleaseDate", "==", todayStr)
      .get();

    for (const doc of preReleaseSnap.docs) {
      const order = doc.data();
      sendNotification(order.sellerId, "Set released! 🎉", "Your pre-order is ready to ship. Please send it within 5 days.", { type: "order", orderId: doc.id });
      sendNotification(order.buyerId, "Set released! 🎉", "Your pre-order will be shipped soon.", { type: "order", orderId: doc.id });
    }
    if (!preReleaseSnap.empty) {
      console.log(`autoReleaseOrders: sent ${preReleaseSnap.size} release-day notification(s)`);
    }

  }
);

/**
 * autoResolveStaleShipments — Cron, Discogs-Modell-Komponente.
 *
 * **Zweck (2026-04-30, ZAG-Compliance):**
 * Wenn ein Verkaeufer 14 Tage nach Bezahlung nicht versendet (kein
 * markShipped), wird die Order **objektiv-regelbasiert** automatisch
 * storniert. Das ist KEIN Plattform-Schiedsspruch, sondern eine vorab in
 * AGB definierte messbare Folge — analog zu Stripe `delay_days` oder
 * `autoReleaseAt`. Damit ist die Geld-Aktion ZAG-unproblematisch (kein
 * Wertentscheid am Geld, sondern abstrakte AGB-Folge).
 *
 * Mechanik:
 * - Bei status `paid` ist der PaymentIntent mit `capture_method: "manual"`
 *   nur autorisiert, NICHT captured (markShipped capturet erst). Geld liegt
 *   in der Stripe-Auth-Hold auf der Kaeufer-Karte, nicht auf dem Connected
 *   Account des Verkaeufers.
 * - Wir rufen `paymentIntents.cancel(piId)` — gibt die Auth zurueck. Falls
 *   die Auth schon abgelaufen ist (Stripe-Auth-Hold typischerweise 7 Tage,
 *   ist also bei 14 Tagen meist schon expired), gibt Stripe Fehler — den
 *   ignorieren wir (Order kommt trotzdem auf cancelled).
 * - Listing-Reservations werden freigegeben.
 * - Verkaeufer bekommt Strike (klare Pflichtverletzung).
 * - Beide Parteien bekommen Notifications.
 *
 * Kein refunds.create / reverse_transfer noetig, weil das Geld nie auf den
 * Connected Account des Verkaeufers gelangt ist.
 *
 * Schedule: 04:30 Berlin (eine halbe Stunde nach autoReleaseOrders, damit
 * sich die beiden Crons nicht ueberlappen). Der bestehende Day-5-Reminder
 * in autoReleaseOrders nudget den Verkaeufer rechtzeitig.
 */
/**
 * Internal helper for stale-shipment auto-resolve. Wird sowohl vom
 * `autoResolveStaleShipments`-Cron (Production-Schedule) als auch vom
 * Test-Trigger `devTriggerStaleShipments` (admin-only HTTP) aufgerufen.
 * Dadurch reproduzierbare E2E-Tests ohne auf den Cron warten zu muessen.
 */
exports._runStaleShipmentsResolver = _runStaleShipmentsResolver;
exports._runSellerSilenceResolver = _runSellerSilenceResolver;

async function _runStaleShipmentsResolver() {
    // paidAt ist Firestore Timestamp (set via FieldValue.serverTimestamp()
    // beim Bezahl-Webhook). Query muss Date-Object uebergeben — Firestore
    // SDK konvertiert das zu Timestamp fuer den Vergleich. ISO-String wuerde
    // gegen Timestamp-Field NICHT matchen (silent fail). Live-Test 2026-04-30
    // hat den Bug aufgedeckt: Queries gaben candidates=0 obwohl seeded Orders
    // mit paidAt 15d in past existierten.
    const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);
    const ordersRef = db.collection("artifacts").doc(APP_ID).collection("orders");

    const snap = await ordersRef
      .where("status", "==", "paid")
      .where("paidAt", "<=", fourteenDaysAgo)
      .get();

    if (snap.empty) {
      console.log("autoResolveStaleShipments: no stale orders");
      return { cancelled: 0, skipped: 0, candidates: 0 };
    }

    const stripe = getStripe();
    let cancelled = 0;
    let skipped = 0;

    for (const doc of snap.docs) {
      // Race-Protection: Verkaeufer koennte in dem Moment markShipped triggern.
      // Atomarer State-Flip in TX vor dem Stripe-Call.
      let order;
      try {
        order = await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return null;
          const data = fresh.data();
          if (data.status !== "paid") return null;
          // Doppelt-Sicher: paidAt-Alter nochmal pruefen (Doc-Snapshot
          // koennte stale sein nach langer Cron-Iteration).
          const paidAtRaw = data.paidAt;
          let paidAtMs = 0;
          if (paidAtRaw && typeof paidAtRaw.toMillis === "function") {
            paidAtMs = paidAtRaw.toMillis();
          } else if (paidAtRaw) {
            paidAtMs = new Date(paidAtRaw).getTime();
          }
          if (!paidAtMs ||
              (Date.now() - paidAtMs) < 14 * 24 * 60 * 60 * 1000) {
            return null;
          }
          tx.update(doc.ref, {
            status: "cancelled",
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            cancelReason: "auto_stale_shipment_14d",
            autoResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return data;
        });
      } catch (txErr) {
        console.error(
          `autoResolveStaleShipments ${doc.id} TX-flip failed: ${txErr.message}`,
        );
        continue;
      }
      if (!order) {
        skipped++;
        continue;
      }

      // Stripe PI cancel — try/catch weil Auth eventuell schon abgelaufen
      // (Stripe-Auth-Hold ~7 Tage, bei 14 Tagen meist expired = harmlos).
      if (order.stripePaymentIntentId) {
        try {
          await stripe.paymentIntents.cancel(order.stripePaymentIntentId);
          console.log(
            `autoResolveStaleShipments: cancelled PI ${order.stripePaymentIntentId} for order ${doc.id}`,
          );
        } catch (e) {
          // PI ist evtl. bereits in einem Terminal-State (canceled, expired) —
          // log + continue. Order wurde bereits in TX auf cancelled gesetzt.
          console.warn(
            `autoResolveStaleShipments: PI ${order.stripePaymentIntentId} cancel skipped (${e.message})`,
          );
        }
      }

      // Listing-Reservations freigeben (Mirror der cancelPendingOrder-Logik)
      for (const item of (order.items || [])) {
        if (!item.listingId) continue;
        const listingRef = db.collection("artifacts").doc(APP_ID)
          .collection("listings").doc(item.listingId);
        const listingDoc = await listingRef.get();
        if (!listingDoc.exists) continue;
        const listing = listingDoc.data();
        const newReserved = Math.max(
          0,
          (listing.reservedQty || 0) - (item.quantity || 1),
        );
        const updateData = { reservedQty: newReserved };
        if (listing.status === "reserved") updateData.status = "active";
        await listingRef.update(updateData);
      }

      // Strike fuer Verkaeufer — klare Pflichtverletzung. Mehrere Strikes
      // koennen durch Pattern-Detection (Schritt 7) zur Account-Sperre fuehren.
      if (order.sellerId) {
        try {
          await addStrike(
            order.sellerId,
            `Auto-cancelled order ${doc.id} after 14d no shipment`,
          );
        } catch (e) {
          console.error(
            `autoResolveStaleShipments: addStrike failed for ${order.sellerId}: ${e.message}`,
          );
        }
      }

      // Notifications: ehrlich, factual — keine Schuldzuweisung,
      // aber klare Konsequenz fuer den Verkaeufer
      sendNotification(
        order.buyerId,
        "Order auto-cancelled",
        "The seller didn't ship within 14 days. Your payment authorization has been released — please order from a different seller.",
        { type: "order", orderId: doc.id },
      );
      if (order.sellerId) {
        sendNotification(
          order.sellerId,
          "Order auto-cancelled (no shipment)",
          "An order was automatically cancelled because you didn't mark it as shipped within 14 days. Repeated occurrences may lead to listing pauses or account sanctions.",
          { type: "order", orderId: doc.id },
        );
      }

      cancelled++;
    }

    console.log(
      `autoResolveStaleShipments: cancelled=${cancelled} skipped=${skipped} of ${snap.size} candidates`,
    );
    return { cancelled, skipped, candidates: snap.size };
}

exports.autoResolveStaleShipments = onSchedule(
  {
    schedule: "30 4 * * *",
    timeZone: "Europe/Berlin",
    timeoutSeconds: 300,
    region: "europe-west1",
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async () => {
    await _runStaleShipmentsResolver();
  },
);

/**
 * autoResolveSellerSilence — Cron, Discogs-Modell-Komponente.
 *
 * **Zweck (2026-04-30, ZAG-Compliance):**
 * Wenn ein Kaeufer einen Dispute oeffnet und der Verkaeufer 7 Tage nicht
 * reagiert (kein `proposeRefund`, disputeStatus bleibt `open`), wird die
 * Order automatisch zu 100 % refundiert. Wie autoResolveStaleShipments ist
 * das eine vorab in AGB definierte objektive Folge — kein Plattform-
 * Schiedsspruch.
 *
 * Mechanik (anders als autoResolveStaleShipments):
 * - Bei `disputed` Status ist Order schon `shipped` (oder
 *   `delivered`/`auto_completed` im 30-Tage-post-delivery-Window). Geld
 *   wurde bei `markShipped` captured und liegt auf Connected Account des
 *   Verkaeufers (oder ist bereits ausgezahlt).
 * - `stripe.refunds.create` mit `reverse_transfer: true` und
 *   `refund_application_fee: true` — voller Refund inkl. Service-Gebuehr
 *   (Verkaeufer komplett ausgefallen = klare Pflichtverletzung).
 * - Mirrors die Refund-Cleanup-Logik aus respondToRefund: Listing-
 *   Reservation freigeben, Realized Gains reverse, Strike fuer Verkaeufer.
 *
 * Schedule: 05:00 Berlin (30 Min nach autoResolveStaleShipments).
 */
/**
 * Internal helper for seller-silence auto-refund. Wird sowohl vom
 * `autoResolveSellerSilence`-Cron (Production-Schedule) als auch vom
 * Test-Trigger `devTriggerSellerSilence` (admin-only HTTP) aufgerufen.
 */
async function _runSellerSilenceResolver() {
    // disputedAt ist Firestore Timestamp (siehe _runStaleShipmentsResolver-
    // Kommentar zum gleichen Bug-Pattern). Date-Object statt ISO-String.
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const ordersRef = db.collection("artifacts").doc(APP_ID).collection("orders");

    // Disputed Orders mit disputeStatus "open" (= Verkaeufer hat noch nicht
    // proposeRefund aufgerufen) und disputedAt ≥ 7 Tage her.
    const snap = await ordersRef
      .where("status", "==", "disputed")
      .where("disputeStatus", "==", "open")
      .where("disputedAt", "<=", sevenDaysAgo)
      .get();

    if (snap.empty) {
      console.log("autoResolveSellerSilence: no silent disputes");
      return { refunded: 0, skipped: 0, errors: 0, candidates: 0 };
    }

    const stripe = getStripe();
    let refunded = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of snap.docs) {
      // Race-Protection: Verkaeufer koennte parallel proposeRefund triggern,
      // oder Buyer cancelDispute — TX-State-Flip vor Stripe-Call.
      let order;
      try {
        order = await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return null;
          const data = fresh.data();
          if (data.status !== "disputed" || data.disputeStatus !== "open") {
            return null;
          }
          // Doppelt-Sicher: disputedAt-Alter nochmal pruefen
          const disputedAtRaw = data.disputedAt;
          let disputedAtMs = 0;
          if (disputedAtRaw && typeof disputedAtRaw.toMillis === "function") {
            disputedAtMs = disputedAtRaw.toMillis();
          } else if (disputedAtRaw) {
            disputedAtMs = new Date(disputedAtRaw).getTime();
          }
          if (!disputedAtMs ||
              (Date.now() - disputedAtMs) < 7 * 24 * 60 * 60 * 1000) {
            return null;
          }
          // Markiere als "in progress" damit kein anderer Pfad gleichzeitig
          // refunded; finaler State wird nach Stripe-Call gesetzt.
          tx.update(doc.ref, {
            disputeStatus: "auto_resolving",
          });
          return data;
        });
      } catch (txErr) {
        console.error(
          `autoResolveSellerSilence ${doc.id} TX-flip failed: ${txErr.message}`,
        );
        errors++;
        continue;
      }
      if (!order) {
        skipped++;
        continue;
      }

      const piId = order.stripePaymentIntentId;
      if (!piId) {
        // Kein PI = legacy balance-order o.ae. — als skipped markieren,
        // disputeStatus zurueck auf "open" damit Admin manuell eingreifen kann.
        await doc.ref.update({ disputeStatus: "open" });
        console.warn(
          `autoResolveSellerSilence: ${doc.id} has no PaymentIntent — skipping`,
        );
        skipped++;
        continue;
      }

      // 100% Refund inkl. Service-Gebuehr — Verkaeufer-Schuld klar
      // (7 Tage nicht reagiert auf Dispute).
      const refundParams = {
        payment_intent: piId,
        reverse_transfer: true,
        refund_application_fee: true,
      };

      let refund;
      try {
        // Idempotency-Key per orderId — bei Cron-Re-Run keine doppelten Refunds
        refund = await stripe.refunds.create(refundParams, {
          idempotencyKey: `refund-auto-silence-${doc.id}`,
        });
      } catch (stripeErr) {
        console.error(
          `autoResolveSellerSilence: refund failed for ${doc.id}: ${stripeErr.message}`,
        );
        // disputeStatus zurueck auf "open" damit's beim naechsten Cron-Run
        // erneut versucht wird (oder Admin manuell eingreift)
        await doc.ref.update({ disputeStatus: "open" });
        errors++;
        continue;
      }

      console.log(
        `autoResolveSellerSilence: refund ${refund.id} created for order ${doc.id}`,
      );

      // Order final-state setzen
      await doc.ref.update({
        status: "refunded",
        disputeStatus: "resolved",
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        autoResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        autoResolveReason: "seller_silence_7d",
        refundedAmount: order.totalPaid || 0,
        refundServiceFeeStaysWithPlatform: false,
        stripeRefundId: refund.id,
      });

      // Listing-Reservation freigeben (mirror respondToRefund)
      for (const item of (order.items || [])) {
        if (!item.listingId) continue;
        const listingRef = db.collection("artifacts").doc(APP_ID)
          .collection("listings").doc(item.listingId);
        const listingDoc = await listingRef.get();
        if (!listingDoc.exists) continue;
        const listing = listingDoc.data();
        const newReserved = Math.max(
          0,
          (listing.reservedQty || 0) - (item.quantity || 1),
        );
        const updateData = { reservedQty: newReserved };
        if (listing.status === "reserved") updateData.status = "active";
        await listingRef.update(updateData);
      }

      // Realized Gains reversal (volle 100%, da Voll-Refund)
      const gainOnRecord =
        order.realizedGainOnShip || order.realizedGainOnDelivery || 0;
      if (gainOnRecord && order.sellerId) {
        const sellerProfileRef = db.collection("artifacts").doc(APP_ID)
          .collection("users").doc(order.sellerId)
          .collection("data").doc("profile");
        await sellerProfileRef.set({
          realizedGains: admin.firestore.FieldValue.increment(-gainOnRecord),
        }, { merge: true });
      }

      // Strike fuer Verkaeufer (klare Pflichtverletzung — keine Reaktion auf
      // Dispute). Pattern-Detection (Schritt 7) wertet diese aus.
      if (order.sellerId) {
        try {
          await addStrike(
            order.sellerId,
            `Auto-resolved dispute ${doc.id} after 7d seller silence (full refund)`,
          );
        } catch (e) {
          console.error(
            `autoResolveSellerSilence: addStrike failed for ${order.sellerId}: ${e.message}`,
          );
        }
      }

      // Notifications
      sendNotification(
        order.buyerId,
        "Refund issued automatically",
        `The seller didn't respond to your dispute within 7 days. Full refund of €${(order.totalPaid || 0).toFixed(2)} has been processed.`,
        { type: "order", orderId: doc.id },
      );
      sendNotification(
        order.sellerId,
        "Order auto-refunded (no response)",
        `An order was automatically refunded because you didn't respond to the buyer's dispute within 7 days. Repeated occurrences may lead to listing pauses or account sanctions.`,
        { type: "order", orderId: doc.id },
      );

      refunded++;
    }

    console.log(
      `autoResolveSellerSilence: refunded=${refunded} skipped=${skipped} errors=${errors} of ${snap.size} candidates`,
    );
    return { refunded, skipped, errors, candidates: snap.size };
}

exports.autoResolveSellerSilence = onSchedule(
  {
    schedule: "0 5 * * *",
    timeZone: "Europe/Berlin",
    timeoutSeconds: 300,
    region: "europe-west1",
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async () => {
    await _runSellerSilenceResolver();
  },
);

/**
 * devTriggerStaleShipments — Test-only HTTP-Trigger fuer
 * `_runStaleShipmentsResolver`. Admin-only. Erlaubt reproduzierbare E2E-Tests
 * ohne auf den Production-Cron (04:30 Berlin) warten zu muessen.
 *
 * Use case: Phase9-Discogs-E2E-Tests (test-scenarios/phase9_discogs_e2e.js).
 *
 * **NICHT** in Production-UI exposed — nur via Admin-CLI / E2E-Test-Script
 * aufrufbar. Falls bei Phase 10 entschieden, dass Admins manuelle Resolves
 * brauchen, muss eine separate UI-Function gebaut werden mit eigenem Audit-
 * Logging (diese hier hat keinen).
 */
exports.devTriggerStaleShipments = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 300,
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin only (dev-trigger)");
    }
    console.log(`devTriggerStaleShipments invoked by admin=${request.auth.uid}`);
    const result = await _runStaleShipmentsResolver();
    return { success: true, ...result };
  },
);

/**
 * devTriggerSellerSilence — Test-only HTTP-Trigger fuer
 * `_runSellerSilenceResolver`. Siehe `devTriggerStaleShipments`-Doc.
 */
exports.devTriggerSellerSilence = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 300,
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin only (dev-trigger)");
    }
    console.log(`devTriggerSellerSilence invoked by admin=${request.auth.uid}`);
    const result = await _runSellerSilenceResolver();
    return { success: true, ...result };
  },
);

// ── Request Cancel (Buyer) ──
exports.requestCancelOrder = onCall(
  { region: "europe-west1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");
    const { orderId, reason, note } = request.data;
    if (!orderId) throw new HttpsError("invalid-argument", "orderId required");

    const orderRef = db.collection("artifacts").doc(APP_ID).collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) throw new HttpsError("not-found", "Order not found");
    const order = orderDoc.data();

    if (order.buyerId !== uid) throw new HttpsError("permission-denied", "Only buyer can request cancel");
    if (order.status !== "paid") throw new HttpsError("failed-precondition", "Order must be in paid status");
    if (order.cancelRequested) throw new HttpsError("already-exists", "Cancel already requested");

    await orderRef.update({
      cancelRequested: true,
      cancelRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(reason ? { cancelReason: reason } : {}),
      ...(note ? { cancelNote: note } : {}),
    });

    // Notify seller
    const summary = orderItemsSummary(order.items || []);
    const reasonText = reason ? `: ${reason}` : "";
    sendNotification(order.sellerId, "Cancel requested", `Buyer wants to cancel${reasonText} — ${summary}`, { type: "order", orderId });

    return { success: true };
  }
);

// ── Accept Cancel (Seller) ──
exports.acceptCancelOrder = onCall(
  { region: "europe-west1", secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");
    const { orderId } = request.data;
    if (!orderId) throw new HttpsError("invalid-argument", "orderId required");

    const orderRef = db.collection("artifacts").doc(APP_ID).collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) throw new HttpsError("not-found", "Order not found");
    const order = orderDoc.data();

    if (order.sellerId !== uid) throw new HttpsError("permission-denied", "Only seller can accept cancel");
    if (order.status !== "paid") throw new HttpsError("failed-precondition", "Order must be in paid status");

    // Phase 6: Connect-native pre-ship cancel. Bei capture_method:"manual"
    // (= unser Standard) ist die PI nach amount_capturable_updated im Status
    // requires_capture — Geld ist authorized, aber nicht captured. Cancel
    // gibt die Auth wieder frei, kein Geld floss.
    if (order.paymentMethod === "balance") {
      throw new HttpsError(
        "failed-precondition",
        "Legacy balance order — please contact support.",
      );
    }
    const piId = order.stripePaymentIntentId;
    if (!piId) {
      throw new HttpsError(
        "failed-precondition",
        "Order has no PaymentIntent — cannot cancel.",
      );
    }

    const stripe = getStripe();
    try {
      await stripe.paymentIntents.cancel(piId);
    } catch (e) {
      console.warn(`acceptCancelOrder: PI ${piId} cancel skipped: ${e.message}`);
    }

    // Update order
    await orderRef.update({
      status: "cancelled",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelRequested: false,
      cancelReason: "buyer_requested_seller_accepted",
    });

    // Release reserved qty on listings
    for (const item of (order.items || [])) {
      if (item.listingId) {
        const listingRef = db.collection("artifacts").doc(APP_ID).collection("listings").doc(item.listingId);
        const listingDoc = await listingRef.get();
        if (listingDoc.exists) {
          const listing = listingDoc.data();
          const newReserved = Math.max(0, (listing.reservedQty || 0) - (item.quantity || 1));
          await listingRef.update({ reservedQty: newReserved, status: "active" });
        }
      }
    }

    // Notify buyer
    sendNotification(order.buyerId, "Order cancelled", "Your cancellation request was accepted. Refund issued.", { type: "order", orderId });

    return { success: true };
  }
);

// ── Decline Cancel (Seller) ──
exports.declineCancelOrder = onCall(
  { region: "europe-west1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");
    const { orderId } = request.data;
    if (!orderId) throw new HttpsError("invalid-argument", "orderId required");

    const orderRef = db.collection("artifacts").doc(APP_ID).collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) throw new HttpsError("not-found", "Order not found");
    const order = orderDoc.data();

    if (order.sellerId !== uid) throw new HttpsError("permission-denied", "Only seller can decline cancel");

    await orderRef.update({
      cancelRequested: false,
    });

    // Notify buyer
    sendNotification(order.buyerId, "Cancel declined", "Seller declined your cancellation request. Order remains active.", { type: "order", orderId });

    return { success: true };
  }
);

// ── Submit Review ──
exports.submitReview = onCall(
  { region: "europe-west1", timeoutSeconds: 15 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");

    const { orderId, rating, comment, tags } = request.data;
    if (!orderId) throw new HttpsError("invalid-argument", "orderId required");
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      throw new HttpsError("invalid-argument", "Rating must be 1-5");
    }

    // Validate tags — only allow predefined values
    const allowedTags = ["Schneller Versand", "Wie beschrieben", "Gut verpackt", "Gute Kommunikation"];
    const safeTags = Array.isArray(tags) ? tags.filter(t => allowedTags.includes(t)) : [];

    const orderRef = db.collection("artifacts").doc(APP_ID).collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) throw new HttpsError("not-found", "Order not found");

    const order = orderDoc.data();
    if (order.buyerId !== uid) throw new HttpsError("permission-denied", "Only buyer can rate");
    if (order.status !== "delivered" && order.status !== "auto_completed") {
      throw new HttpsError("failed-precondition", "Order not completed");
    }
    if (order.buyerRating) throw new HttpsError("already-exists", "Already rated");

    // Trim and cap comment
    const safeComment = (comment || "").trim().substring(0, 300);

    // Write rating to order
    await orderRef.update({
      buyerRating: rating,
      buyerComment: safeComment || null,
      buyerTags: safeTags.length > 0 ? safeTags : null,
      buyerRatingTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Recalculate seller average: query all rated orders for this seller
    const ratedSnap = await db.collection("artifacts").doc(APP_ID).collection("orders")
      .where("sellerId", "==", order.sellerId)
      .where("buyerRating", ">", 0)
      .get();

    let totalRating = 0;
    let count = 0;
    for (const doc of ratedSnap.docs) {
      const r = doc.data().buyerRating;
      if (r && r > 0) { totalRating += r; count++; }
    }
    // Include current rating (serverTimestamp may not be indexed yet)
    if (!ratedSnap.docs.find(d => d.id === orderId)) {
      totalRating += rating;
      count++;
    }

    const avgRating = count > 0 ? Math.round((totalRating / count) * 10) / 10 : 0;

    // Update seller profile
    const sellerRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(order.sellerId)
      .collection("data").doc("sellerProfile");
    await sellerRef.update({ rating: avgRating, reviewCount: count });

    // Copy review to public reviews subcollection (no order/address data)
    const buyerProfile = await db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("profile").get();
    const reviewerName = buyerProfile.exists
      ? (buyerProfile.data().displayName || buyerProfile.data().username || "Buyer")
      : "Buyer";

    await db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(order.sellerId)
      .collection("reviews").doc(orderId)
      .set({
        reviewerName,
        rating,
        comment: safeComment || null,
        tags: safeTags.length > 0 ? safeTags : null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Notify seller
    const stars = "★".repeat(rating) + "☆".repeat(5 - rating);
    sendNotification(order.sellerId, "New review: " + stars, safeComment || "You received a rating.", { type: "order", orderId: orderId });

    // Tier-Sync — neue Bewertung kann Schwelle für Tier-Aufstieg überschreiten.
    // Idempotent, error-safe (loggt nur, blockt nicht den Review-Flow).
    try {
      await syncSellerTier(order.sellerId);
    } catch (err) {
      console.error(`syncSellerTier after submitReview failed for ${order.sellerId}:`, err.message);
    }

    // Public-Stats-Mirror — rating + reviewCount haben sich geaendert,
    // Listings/Social-Tab brauchen die neuen Werte fuer UI-Display.
    await syncPlayerProfile(order.sellerId);

    return { success: true, avgRating, reviewCount: count };
  }
);

// ═══════════════════════════════════════════
// ─── Payment: Fee Calculation (Phase 0/1) ───
// ═══════════════════════════════════════════
//
// Single source of truth for marketplace fees. Spec lives in
// riftr-flutter/CLAUDE.md → "Payment-Architektur". Any change here MUST
// be mirrored in the Flutter UI (cart summary, seller dashboard) and
// the AGB fee section. See riftr-flutter/BACKLOG.md → "Payment-Track".
//
// Architecture: Stripe Connect Destination Charges with `transfer_data` +
// `application_fee_amount`. NO platform-held funds. NO wallet logic
// (anti-pattern, BaFin risk — see CLAUDE.md "Anti-Patterns").

/**
 * Käufer-Service-Gebühr (Basis), gestaffelt nach Karten-Subtotal.
 * Multi-Seller-Aufschlag wird separat addiert (siehe calculateOrderFees).
 *
 * @param {number} cartSubtotalCents — Karten-Wert ohne Versand
 * @returns {number} Service-Gebühr in Cents
 */
function baseServiceFeeCents(cartSubtotalCents) {
  if (cartSubtotalCents < 1500)  return 49;   // <€15
  if (cartSubtotalCents <= 5000) return 79;   // €15–€50
  if (cartSubtotalCents <= 20000) return 129; // €50–€200
  return 199;                                  // >€200
}

/**
 * Verkäufer-Provisions-Rate, gestaffelt nach Karten-Subtotal.
 *
 * @param {number} cartSubtotalCents
 * @returns {number} Provisions-Rate als Dezimalwert (0.05 = 5%)
 */
function commissionRate(cartSubtotalCents) {
  if (cartSubtotalCents < 1500)  return 0.05;
  if (cartSubtotalCents <= 5000) return 0.055;
  if (cartSubtotalCents <= 20000) return 0.06;
  return 0.065;
}

/**
 * Berechnet alle Gebühren für eine Bestellung.
 * Stripe-Fee trägt IMMER die Plattform (kein dynamisches on_behalf_of).
 *
 * Multi-Seller-Aufschlag: +30 Cents pro zusätzlichem Verkäufer im User-Cart.
 * Wird auf den ERSTEN PaymentIntent gepackt; spätere PIs tragen nur ihre
 * eigene Provision (sonst würde Service-Gebühr mehrfach belastet).
 *
 * @param {number} cartSubtotalCents — Karten-Wert dieser Verkäufer-Gruppe
 * @param {number} sellerCount — Gesamtzahl Verkäufer im User-Cart (≥1)
 * @returns {object} { serviceFeeCents, platformCommissionCents,
 *                     totalApplicationFeeCents, commissionRateUsed }
 */
function calculateOrderFees(cartSubtotalCents, sellerCount) {
  if (typeof cartSubtotalCents !== "number" || cartSubtotalCents < 0) {
    throw new Error(`Invalid cartSubtotalCents: ${cartSubtotalCents}`);
  }
  if (typeof sellerCount !== "number" || sellerCount < 1) {
    throw new Error(`Invalid sellerCount: ${sellerCount}`);
  }

  const baseService = baseServiceFeeCents(cartSubtotalCents);
  const multiSellerSurcharge = 30 * Math.max(0, sellerCount - 1);
  const serviceFeeCents = baseService + multiSellerSurcharge;

  const rate = commissionRate(cartSubtotalCents);
  const platformCommissionCents = Math.round(cartSubtotalCents * rate);

  return {
    serviceFeeCents,
    platformCommissionCents,
    totalApplicationFeeCents: serviceFeeCents + platformCommissionCents,
    commissionRateUsed: rate,
    baseServiceFeeCents: baseService,
    multiSellerSurchargeCents: multiSellerSurcharge,
  };
}

// ═══════════════════════════════════════════
// ─── Payment: Seller Tier / Delay Days ───
// ═══════════════════════════════════════════
//
// Auszahlungs-Tier-System: delay_days dynamisch nach Verkäufer-Reputation.
// Triggers: nach submitReview, nach confirmDelivery, plus täglicher Cron.
// Stripe Reserve (5%/7d rolling) wird zusätzlich für Power-Seller-Tier
// aktiviert — siehe applyTierToStripeAccount.

/**
 * Berechnet das passende delay_days für einen Verkäufer basierend auf
 * Verkaufs-Anzahl + Bewertungs-Schnitt + Mindest-Reviews.
 *
 * Special-Case: Bei Order-Wert > €100 fällt Power-Seller-Tier (1 Tag) auf
 * 7 Tage zurück — siehe getEffectiveDelayDays für Order-spezifische Logik.
 *
 * @param {object} seller — sellerProfile-Doc-Daten
 * @param {number} seller.completedSalesCount
 * @param {number} seller.rating — 0.0–5.0
 * @param {number} seller.reviewCount
 * @returns {number} delay_days (1, 3, 5, oder 7)
 */
function calculateDelayDays(seller) {
  const sales = seller?.completedSalesCount || 0;
  const rating = seller?.rating || 0;
  const reviews = seller?.reviewCount || 0;
  const hasMinReviews = reviews >= 5;

  // Power-Seller: 200+ Verkäufe, ≥4.95 Sterne, ≥5 Reviews
  if (sales >= 200 && hasMinReviews && rating >= 4.95) return 1;

  // Trusted: 50+ Verkäufe, ≥4.90 Sterne, ≥5 Reviews
  if (sales >= 50 && hasMinReviews && rating >= 4.90) return 3;

  // Etabliert: 10+ Verkäufe, ≥4.75 Sterne, ≥5 Reviews
  if (sales >= 10 && hasMinReviews && rating >= 4.75) return 5;

  // Default (Neu): 7 Tage
  return 7;
}

/**
 * Effective delay_days bei einer KONKRETEN Bestellung.
 * Power-Seller-Tier (1 Tag) gilt nur bei Bestellungen ≤ €100. Größere
 * Bestellungen pauschal 7 Tage für ALLE Tiers (Schutz bei High-Value-
 * Karten wie seltene Legends).
 *
 * @param {object} seller — sellerProfile
 * @param {number} orderTotalCents — Charge-Total inkl. Versand + Service
 * @returns {number} effective delay_days
 */
function getEffectiveDelayDays(seller, orderTotalCents) {
  const baseTierDays = calculateDelayDays(seller);
  const isHighValueOrder = orderTotalCents > 10000; // > €100
  if (isHighValueOrder) return Math.max(baseTierDays, 7);
  return baseTierDays;
}

/**
 * Aktualisiert delay_days auf dem Stripe-Connect-Account des Verkäufers
 * UND aktiviert/deaktiviert Stripe Reserve für Power-Seller-Tier.
 *
 * Reserve: 5% rolling 7d ist NUR für Power-Seller (1-Tag-Delay). Andere
 * Tiers haben durch längeren Delay genug Refund-Buffer.
 *
 * @param {string} uid
 * @param {string} sellerStripeAccountId
 * @param {number} delayDays
 */
async function applyTierToStripeAccount(uid, sellerStripeAccountId, delayDays) {
  const stripe = getStripe();

  // 1. Payout-Schedule.
  //
  // Stripe enforced einen Risk-Floor (typisch 7 Tage) fuer neue Connect-Accounts.
  // Versuch `delay_days < 7` setzen, bevor Stripe den Floor lockert, gibt
  // 400 "You cannot lower this merchant's delay below 7" zurueck.
  //
  // Strategie: Wir versuchen den Tier-Soll-Wert. Failed Stripe wegen Floor →
  // wir fallen auf den effektiven Stripe-Floor zurueck (parsen aus Error)
  // und melden via Return-Wert, was tatsaechlich gesetzt wurde. Caller schreibt
  // beide Werte ins Profil (`delayDays` = logischer Tier, `stripeDelayDaysActual`
  // = was Stripe gerade enforced). Floor wird von Stripe nach Onboarding +
  // Risk-Eval-Periode automatisch gesenkt — beim naechsten syncSellerTier-Trigger
  // wird der Tier-Soll-Wert dann erfolgreich gesetzt.
  let stripeDelayDaysActual = delayDays;
  let stripeFloorActive = false;
  try {
    await stripe.accounts.update(sellerStripeAccountId, {
      settings: {
        payouts: {
          schedule: { delay_days: delayDays, interval: "daily" },
        },
      },
    });
  } catch (e) {
    const isFloorError =
      e.type === "StripeInvalidRequestError" &&
      /delay/i.test(e.message || "") &&
      /below/i.test(e.message || "");
    if (!isFloorError) throw e;

    // Floor-Wert aus Message parsen ("...below 7" → 7); Default 7 falls Parse fehlt.
    const m = (e.message || "").match(/below\s+(\d+)/i);
    const floorDays = m ? parseInt(m[1], 10) : 7;
    stripeDelayDaysActual = floorDays;
    stripeFloorActive = true;

    console.warn(
      `applyTierToStripeAccount ${uid}: Stripe-Floor blockiert delay_days=${delayDays}, ` +
      `setze auf Floor=${floorDays}. Wird beim naechsten Tier-Trigger erneut versucht.`,
    );
    await stripe.accounts.update(sellerStripeAccountId, {
      settings: {
        payouts: {
          schedule: { delay_days: floorDays, interval: "daily" },
        },
      },
    });
  }

  // 2. Reserve nur für Power-Seller (delayDays === 1)
  // NB: Stripe-Reserve-Konfiguration via API ist nur für bestimmte
  // Account-Typen verfügbar — Express-Accounts steuern Reserve über
  // Risk-Settings die NICHT direkt API-zugänglich sind. Daher: Reserve
  // muss MANUELL im Stripe-Dashboard pro Account konfiguriert werden
  // wenn Tier auf Power-Seller springt. Audit-Log markiert das Event,
  // Riftr-Admin handelt nach.
  // TODO: Sobald Stripe API für Express-Reserve-Settings verfügbar:
  //       hier `stripe.accounts.update({ settings: { reserve_charges: ... }})`
  //       siehe https://docs.stripe.com/connect/account-balances#reserves

  console.log(
    `Tier-Update ${uid}: delay_days=${delayDays}` +
    (stripeFloorActive ? ` (Stripe-Floor aktiv: actual=${stripeDelayDaysActual})` : "") +
    (delayDays === 1 ? " [POWER-SELLER — manual Reserve setup needed]" : ""),
  );

  return { stripeDelayDaysActual, stripeFloorActive };
}

/**
 * Trigger-Helfer: nach submitReview oder confirmDelivery aufrufen.
 * Liest Verkäufer-Profil, berechnet neuen Tier, aktualisiert wenn Änderung.
 * Idempotent — kann beliebig oft gerufen werden ohne Schaden.
 *
 * @param {string} sellerId
 */
/**
 * Syncs the **public-safe** subset of profile + sellerProfile fields into the
 * `playerProfiles/{uid}` mirror collection. Called after any CF that mutates
 * profile/sellerProfile (submitReview, confirmDelivery, syncSellerTier,
 * processMultiSellerCart).
 *
 * Rationale (Security-Audit 2026-04-29): the source-of-truth docs
 * `users/{uid}/data/profile` + `users/{uid}/data/sellerProfile` contain PII
 * (street/city/zip, email, address, totalRevenue, realizedGains,
 * totalCostBasisSold, strikes, suspended, stripeAccountId) that MUST NOT
 * be readable by other authenticated users. The `playerProfiles` mirror
 * is the only safe surface for cross-user UI reads (Listings-Tile-Stats,
 * Social-Tab Author-View, ProfileService.fetchProfiles).
 *
 * Public-safe fields synced here:
 *   - displayName, avatarUrl, bio, country, city (UI display)
 *   - rating, reviewCount, totalSales (seller reputation)
 *   - memberSince (account-age badge)
 *
 * Idempotent. Failures are logged but never thrown — playerProfiles drift
 * is preferable to breaking the calling CF flow. Worst-case the mirror is
 * stale until the next sync trigger.
 */
async function syncPlayerProfile(uid) {
  if (!uid) return;
  try {
    const userBase = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid);
    const [profileDoc, sellerDoc] = await Promise.all([
      userBase.collection("data").doc("profile").get(),
      userBase.collection("data").doc("sellerProfile").get(),
    ]);
    const profile = profileDoc.exists ? profileDoc.data() : {};
    const seller = sellerDoc.exists ? sellerDoc.data() : {};

    // Build sanitized payload — explicit allowlist, no PII passthrough.
    const payload = {
      // From profile (display)
      ...(profile.displayName ? { displayName: profile.displayName } : {}),
      ...(profile.displayName ? { displayNameLower: String(profile.displayName).toLowerCase() } : {}),
      ...(profile.avatarUrl ? { avatarUrl: profile.avatarUrl } : {}),
      ...(profile.bio ? { bio: profile.bio } : {}),
      ...(profile.country ? { country: profile.country } : {}),
      ...(profile.city ? { city: profile.city } : {}),
      // From sellerProfile (reputation — public stats only, NEVER PII like email/address)
      ...(seller.rating != null ? { rating: seller.rating } : {}),
      ...(seller.reviewCount != null ? { reviewCount: seller.reviewCount } : {}),
      ...(seller.totalSales != null ? { totalSales: seller.totalSales } : {}),
      ...(seller.memberSince ? { memberSince: seller.memberSince } : {}),
      updatedAt: new Date().toISOString(),
    };

    await db.collection("artifacts").doc(APP_ID)
      .collection("playerProfiles").doc(uid)
      .set(payload, { merge: true });
  } catch (err) {
    console.error(`syncPlayerProfile(${uid}) failed: ${err.message}`);
  }
}

async function syncSellerTier(sellerId) {
  if (!sellerId) return;

  const sellerRef = db.collection("artifacts").doc(APP_ID)
    .collection("users").doc(sellerId)
    .collection("data").doc("sellerProfile");
  const doc = await sellerRef.get();
  if (!doc.exists) {
    console.log(`syncSellerTier ${sellerId}: no sellerProfile, skipping`);
    return;
  }
  const seller = doc.data();
  const stripeAccountId = seller.stripeAccountId;
  if (!stripeAccountId) {
    console.log(`syncSellerTier ${sellerId}: no stripeAccountId, skipping`);
    return;
  }

  const newDelay = calculateDelayDays(seller);
  const currentDelay = seller.delayDays || 7;

  if (newDelay === currentDelay) {
    return; // No change
  }

  const { stripeDelayDaysActual, stripeFloorActive } =
    await applyTierToStripeAccount(sellerId, stripeAccountId, newDelay);

  // Audit-Log + Profile-Update
  const auditRef = db.collection("artifacts").doc(APP_ID)
    .collection("users").doc(sellerId)
    .collection("sellerProfileAudit").doc();
  await auditRef.set({
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    field: "delayDays",
    previousValue: currentDelay,
    newValue: newDelay,
    stripeDelayDaysActual,
    stripeFloorActive,
    triggeredBy: "syncSellerTier",
    sellerSnapshot: {
      completedSalesCount: seller.completedSalesCount || 0,
      rating: seller.rating || 0,
      reviewCount: seller.reviewCount || 0,
    },
  });

  await sellerRef.update({
    delayDays: newDelay,
    stripeDelayDaysActual,
    stripeFloorActive,
    delayDaysUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(
    `syncSellerTier ${sellerId}: ${currentDelay} → ${newDelay} days` +
    (stripeFloorActive ? ` (Stripe-Floor aktiv: actual=${stripeDelayDaysActual})` : ""),
  );
}

/**
 * setSellerDelayDays — Admin-Cloud-Function für manuellen Override.
 * Generisch implementiert (kein hardcoded UID). Für Beta-Tester,
 * Streit-Schlichtung, Promo-Aktionen, Test-Walkthroughs.
 *
 * Authentifizierung: nur Riftr-Admin-Account (per UID-Whitelist).
 * Audit-Log mit Begründungs-Feld.
 */
exports.setSellerDelayDays = onCall(
  { region: "europe-west1", timeoutSeconds: 15, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    // Admin-Whitelist via Custom Claim
    const adminClaim = request.auth.token?.admin === true;
    if (!adminClaim) {
      throw new HttpsError("permission-denied", "Admin only");
    }

    const { uid, days, reason } = request.data;
    if (!uid || typeof uid !== "string") {
      throw new HttpsError("invalid-argument", "uid (string) required");
    }
    if (!Number.isInteger(days) || days < 1 || days > 30) {
      throw new HttpsError("invalid-argument", "days must be integer 1-30");
    }
    if (!reason || typeof reason !== "string" || reason.length < 5) {
      throw new HttpsError("invalid-argument", "reason (≥5 chars) required for audit");
    }

    const sellerRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("sellerProfile");
    const doc = await sellerRef.get();
    if (!doc.exists) {
      throw new HttpsError("not-found", "sellerProfile not found");
    }
    const seller = doc.data();
    const stripeAccountId = seller.stripeAccountId;
    if (!stripeAccountId) {
      throw new HttpsError("failed-precondition", "Seller has no Stripe account");
    }

    const previousDelay = seller.delayDays || 7;
    const { stripeDelayDaysActual, stripeFloorActive } =
      await applyTierToStripeAccount(uid, stripeAccountId, days);

    // Audit-Log mit Begründung
    const auditRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("sellerProfileAudit").doc();
    await auditRef.set({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      field: "delayDays",
      previousValue: previousDelay,
      newValue: days,
      stripeDelayDaysActual,
      stripeFloorActive,
      triggeredBy: "setSellerDelayDays (admin override)",
      adminUid: request.auth.uid,
      reason: reason.substring(0, 500),
    });

    await sellerRef.update({
      delayDays: days,
      stripeDelayDaysActual,
      stripeFloorActive,
      delayDaysUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      delayDaysOverride: true, // Markiert: nicht automatisch berechnet
    });

    console.log(
      `setSellerDelayDays admin=${request.auth.uid} target=${uid}: ` +
      `${previousDelay}→${days} ("${reason}")` +
      (stripeFloorActive ? ` (Stripe-Floor aktiv: actual=${stripeDelayDaysActual})` : ""),
    );

    return { success: true, previousDelay, newDelay: days, stripeDelayDaysActual, stripeFloorActive };
  },
);

// ═══════════════════════════════════════════
// ─── Phase 6.5: Admin-Mediation-Tools ───
// ═══════════════════════════════════════════

/**
 * adminListDisputes — Admin-only.
 * Listet alle Orders im Status `disputed` (mit `disputeStatus: 'open'` ODER
 * `'sellerProposed'`) — die wo Admin als Tie-Breaker eingreifen koennte.
 * Frontend Admin-UI rendert diese Liste.
 */
exports.adminListDisputes = onCall(
  { region: "europe-west1", timeoutSeconds: 15 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin only");
    }

    const snap = await db.collection("artifacts").doc(APP_ID)
      .collection("orders")
      .where("status", "==", "disputed")
      .orderBy("disputedAt", "desc")
      .limit(100)
      .get();

    const disputes = snap.docs.map((d) => {
      const o = d.data();
      return {
        orderId: d.id,
        buyerId: o.buyerId,
        sellerId: o.sellerId,
        buyerName: o.buyerName || null,
        sellerName: o.sellerName || null,
        items: (o.items || []).map((i) => ({
          cardName: i.cardName,
          quantity: i.quantity,
          condition: i.condition,
        })),
        totalPaid: o.totalPaid,
        sellerPayout: o.sellerPayout,
        shippingMethod: o.shippingMethod,
        trackingNumber: o.trackingNumber || null,
        disputeReason: o.disputeReason,
        disputeReasonCode: o.disputeReasonCode || null,
        disputeDescription: o.disputeDescription || null,
        disputeStatus: o.disputeStatus,
        proposedRefundPercent: o.proposedRefundPercent || null,
        proposedRefundAmount: o.proposedRefundAmount || null,
        disputedAt: o.disputedAt && o.disputedAt.toDate
          ? o.disputedAt.toDate().toISOString()
          : null,
        proposedAt: o.proposedAt && o.proposedAt.toDate
          ? o.proposedAt.toDate().toISOString()
          : null,
      };
    });

    return { disputes };
  },
);

/**
 * adminResolveDispute — Admin-only Seller-Win Tie-Breaker (KEIN Geld-Routing).
 *
 * **Discogs-Modell-Refactor (2026-04-30, ZAG-Compliance):**
 * Vorher konnte Admin einseitig Refunds mit `refundPercent > 0` ausloesen
 * (`stripe.refunds.create` + `reverse_transfer: true`). Das war
 * „Einwirkungsmoeglichkeit auf den Zahlungsfluss" laut BaFin-Merkblatt zum
 * ZAG (Stand 31.03.2026, Zeile 572 lokale Kopie) und kippte die
 * ZAG-Befreiungs-Position. Industriestandard (Discogs, Cardmarket) ist:
 * Plattform vermittelt nur, Refunds laufen via Konsens (`respondToRefund`)
 * oder objektive Trigger (`autoResolve*`-Crons) oder externe Wege
 * (Stripe-Chargeback, Schlichtung, Zivilrechtsweg).
 *
 * Diese Funktion ist seit dem Refactor ausschliesslich der **Verkaeufer-Win**-
 * Tie-Breaker: Wenn Admin nach Pruefung zum Ergebnis kommt, dass die
 * Verkaeufer-Position richtig ist, kann er den Dispute schliessen — **ohne
 * Geldbewegung**. Order geht zurueck auf `shipped`, neuer 7-Tage-Auto-Release-
 * Timer startet. Buyer hat nach wie vor das 30-Tage-Dispute-Window und kann
 * spaeter erneut disputen falls neue Beweise auftauchen, oder direkt
 * Stripe-Chargeback bei seiner Bank ansetzen.
 *
 * Fuer Account-Sanktionen ohne Geldbewegung (Listings-Pause, Account-Sperre
 * bei Pattern-Verstossen): siehe `adminAccountSanction`.
 *
 * Input:
 *   - orderId: string
 *   - reason: string (>=5 chars, fuer Audit-Log + Notification)
 *
 * Hinweis: `refundPercent` Parameter bleibt nominell akzeptiert fuer
 * Backwards-Compat des Frontend-Callers, MUSS aber 0 sein. Andere Werte
 * werden mit klarem Migrations-Hinweis abgelehnt.
 */
exports.adminResolveDispute = onCall(
  { region: "europe-west1", timeoutSeconds: 15 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin only");
    }

    const { orderId, refundPercent, reason } = request.data;
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId required");
    }
    // Discogs-Modell: nur Seller-Win-Pfad (refundPercent === 0) zulaessig.
    // Refund-Auslösungen via Plattform-Entscheid sind raus (ZAG-Compliance).
    if (refundPercent != null && refundPercent !== 0) {
      throw new HttpsError(
        "failed-precondition",
        "Admin-issued refunds were removed (Discogs-Modell, ZAG-Compliance, " +
        "2026-04-30). For refunds use: 1) respondToRefund (mutual consent), " +
        "2) autoResolveStaleShipments / autoResolveSellerSilence (objective " +
        "triggers), or 3) advise buyer to use Stripe-Chargeback. " +
        "adminResolveDispute can only resolve in seller's favor (state-only).",
      );
    }
    if (!reason || typeof reason !== "string" || reason.length < 5) {
      throw new HttpsError(
        "invalid-argument",
        "reason (≥5 chars) required for audit",
      );
    }

    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }
    const order = orderDoc.data();
    if (order.status !== "disputed") {
      throw new HttpsError(
        "failed-precondition",
        `Order status is ${order.status}, expected disputed`,
      );
    }

    // Admin-Audit-Log
    const auditRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc(orderId)
      .collection("disputeAudit").doc();
    const auditEntry = {
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      adminUid: request.auth.uid,
      action: "adminResolveDispute",
      refundPercent: 0,
      reason: reason.substring(0, 500),
      previousDisputeStatus: order.disputeStatus,
    };

    // Pro Verkaeufer entschieden: Order zurueck zu shipped, neuer Auto-
    // Release in 7 Tagen, dispute resolved. KEINE Geldbewegung.
    const newAutoRelease = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await orderRef.update({
      status: "shipped",
      disputeStatus: "resolved",
      adminResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminResolvedBy: request.auth.uid,
      adminResolutionNote: reason.substring(0, 500),
      autoReleaseAt: newAutoRelease.toISOString(),
    });
    await auditRef.set({ ...auditEntry, outcome: "rejected_no_refund" });

    sendNotification(
      order.buyerId,
      "Dispute resolved",
      `Admin entschied gegen den Refund. Begruendung: ${reason.substring(0, 100)}`,
      { type: "order", orderId },
    );
    sendNotification(
      order.sellerId,
      "Dispute resolved",
      "Admin entschied zu deinen Gunsten. Order setzt fort.",
      { type: "order", orderId },
    );

    console.log(`adminResolveDispute: order ${orderId} resolved 0% (seller win) by ${request.auth.uid}`);
    return { success: true, outcome: "rejected_no_refund" };
  },
);

/**
 * adminAccountSanction — Hausrecht-Sanktion ohne Geldbewegung.
 *
 * **Discogs-Modell-Begleiter (2026-04-30, ZAG-Compliance):**
 * Wo `adminResolveDispute` nur noch Verkaeufer-Win-Status-Resets macht,
 * ist `adminAccountSanction` der Kanal fuer Account-/Listing-Sanktionen
 * bei Pattern-Verstoessen, Betrugs-Verdacht oder AGB-Verletzungen. Diese
 * Funktion bewegt **kein Geld** — sie aendert nur Plattform-State (Listings
 * pausieren, Account-Level setzen, Audit-Log). Damit ist sie ZAG-unproblematisch
 * (reines Hausrecht, keine Verfuegungsmacht ueber Geldfluss).
 *
 * Sanktions-Stufen (`actionType`):
 *   - `pauseListings`: Alle aktiven Listings des Users auf `status:"paused"`
 *     mit `pausedUntil` (default 30 Tage). Listings werden im Marketplace
 *     ausgeblendet, koennen vom User aber gesehen + nach Frist re-aktiviert
 *     werden. trustLevel.level wird auf `suspended` mit Flag `listings_paused`.
 *   - `ban`: Wie pauseListings, aber dauerhaft (ohne pausedUntil). Account-Level
 *     `banned`, neue Listings + neue Bestellungen geblockt.
 *   - `lift`: Sperre aufheben. Listings auf `active` zurueck, level zurueck
 *     auf `established` (oder `new` falls < 10 abgeschlossene Verkaeufe).
 *
 * Input:
 *   - targetUid: string (UID des betroffenen Users)
 *   - actionType: "pauseListings" | "ban" | "lift"
 *   - reason: string (>=5 chars, fuer Audit + Notification)
 *   - durationDays: number (nur fuer pauseListings, default 30, max 365)
 *
 * Audit-Log: `artifacts/{APP_ID}/users/{targetUid}/data/sanctionAudit/{auto}`
 */
/**
 * _applyAccountSanction — Internal helper, callable von HTTP-Wrappern UND
 * von internen Pattern-Detection-Pfaden (siehe `_evaluateDisputePatternSanction`).
 *
 * Macht die eigentliche Sanktions-Arbeit: Listings-Status-Flip, trustLevel-
 * Update, Audit-Log, Notification. Ist sich der Aufrufer-Identitaet bewusst
 * (`adminUid` Parameter — bei Pattern-Detection ist das `"system_pattern_detection"`),
 * damit der Audit-Log nachvollziehbar bleibt.
 *
 * Args:
 *   - targetUid (string, required)
 *   - actionType ("pauseListings" | "ban" | "lift", required)
 *   - reason (string, ≥5 chars, required)
 *   - adminUid (string, required) — UID des Admins ODER "system_*"-Marker
 *     fuer automatische Sanktionen
 *   - durationDays (number, optional) — nur fuer pauseListings, default 30,
 *     clamp 1-365
 *   - actionLabel (string, optional) — Audit-Log-Marker, default
 *     "adminAccountSanction" (HTTP-Caller). Pattern-Detection setzt
 *     "auto_pattern_sanction".
 *
 * Wirft Error wenn `actionType` ungueltig — Validation der HTTP-Inputs ist
 * Aufgabe des Wrappers, dieser Helper validiert nur das Notwendigste.
 */
async function _applyAccountSanction({
  targetUid,
  actionType,
  reason,
  adminUid,
  durationDays,
  actionLabel = "adminAccountSanction",
}) {
  const VALID_ACTIONS = ["pauseListings", "ban", "lift"];
  if (!VALID_ACTIONS.includes(actionType)) {
    throw new Error(`actionType must be one of: ${VALID_ACTIONS.join(", ")}`);
  }

  let pausedUntilIso = null;
  if (actionType === "pauseListings") {
    const days = Number.isFinite(durationDays)
      ? Math.max(1, Math.min(365, Math.round(durationDays)))
      : 30;
    pausedUntilIso = new Date(Date.now() + days * 24 * 60 * 60 * 1000)
      .toISOString();
  }

  const trustRef = db.doc(`artifacts/${APP_ID}/users/${targetUid}/data/trustLevel`);
  const trustSnap = await trustRef.get();
  const previousLevel = trustSnap.exists
    ? (trustSnap.data().level || "new")
    : "new";

  const auditRef = db.collection("artifacts").doc(APP_ID)
    .collection("users").doc(targetUid)
    .collection("data").doc("sanctionAudit").collection("entries").doc();
  const auditEntry = {
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    adminUid,
    action: actionLabel,
    actionType,
    reason: reason.substring(0, 500),
    previousLevel,
    ...(pausedUntilIso ? { pausedUntil: pausedUntilIso } : {}),
  };

  const listingsRef = db.collection("artifacts").doc(APP_ID).collection("listings");
  let listingsAffected = 0;

  if (actionType === "pauseListings" || actionType === "ban") {
    const activeSnap = await listingsRef
      .where("sellerId", "==", targetUid)
      .where("status", "==", "active")
      .get();
    for (const doc of activeSnap.docs) {
      await doc.ref.update({
        status: "paused",
        pausedAt: admin.firestore.FieldValue.serverTimestamp(),
        pausedReason: actionType === "ban" ? "account_banned" : "admin_sanction",
        ...(pausedUntilIso ? { pausedUntil: pausedUntilIso } : {}),
      });
      listingsAffected++;
    }
  } else if (actionType === "lift") {
    const pausedSnap = await listingsRef
      .where("sellerId", "==", targetUid)
      .where("status", "==", "paused")
      .where("pausedReason", "in", ["admin_sanction", "account_banned"])
      .get();
    for (const doc of pausedSnap.docs) {
      await doc.ref.update({
        status: "active",
        pausedAt: admin.firestore.FieldValue.delete(),
        pausedReason: admin.firestore.FieldValue.delete(),
        pausedUntil: admin.firestore.FieldValue.delete(),
      });
      listingsAffected++;
    }
  }

  let newLevel;
  let newFlags;
  if (actionType === "pauseListings") {
    newLevel = "suspended";
    newFlags = admin.firestore.FieldValue.arrayUnion("listings_paused");
  } else if (actionType === "ban") {
    newLevel = "banned";
    newFlags = admin.firestore.FieldValue.arrayUnion("account_banned");
  } else if (actionType === "lift") {
    const completedSales = trustSnap.exists
      ? (trustSnap.data().completedSales || 0)
      : 0;
    newLevel = completedSales >= 10 ? "established" : "new";
    newFlags = admin.firestore.FieldValue.arrayRemove(
      "listings_paused",
      "account_banned",
    );
  }

  await trustRef.set({
    level: newLevel,
    flags: newFlags,
    lastSanctionAt: admin.firestore.FieldValue.serverTimestamp(),
    lastSanctionReason: reason.substring(0, 500),
    lastSanctionType: actionType,
    ...(pausedUntilIso ? { sanctionPausedUntil: pausedUntilIso } : {}),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await auditRef.set({
    ...auditEntry,
    newLevel,
    listingsAffected,
  });

  const notifTitle = actionType === "pauseListings"
    ? "Listings pausiert"
    : actionType === "ban"
      ? "Account gesperrt"
      : "Sperre aufgehoben";
  const notifBody = actionType === "lift"
    ? `Deine Account-Sperre wurde aufgehoben. Listings reaktiviert.`
    : `${listingsAffected} Listings wurden ${actionType === "ban" ? "gesperrt" : "pausiert"}. Begruendung: ${reason.substring(0, 100)}`;
  sendNotification(targetUid, notifTitle, notifBody, { type: "account" });

  console.log(
    `_applyAccountSanction: target=${targetUid} action=${actionType} ` +
    `listingsAffected=${listingsAffected} newLevel=${newLevel} ` +
    `by=${adminUid} (${actionLabel})`,
  );

  return {
    actionType,
    previousLevel,
    newLevel,
    listingsAffected,
    ...(pausedUntilIso ? { pausedUntil: pausedUntilIso } : {}),
  };
}

exports.adminAccountSanction = onCall(
  { region: "europe-west1", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin only");
    }

    const { targetUid, actionType, reason, durationDays } = request.data;

    if (!targetUid || typeof targetUid !== "string") {
      throw new HttpsError("invalid-argument", "targetUid required");
    }
    if (!["pauseListings", "ban", "lift"].includes(actionType)) {
      throw new HttpsError(
        "invalid-argument",
        "actionType must be one of: pauseListings, ban, lift",
      );
    }
    if (!reason || typeof reason !== "string" || reason.length < 5) {
      throw new HttpsError(
        "invalid-argument",
        "reason (≥5 chars) required for audit",
      );
    }
    if (targetUid === request.auth.uid && actionType !== "lift") {
      throw new HttpsError(
        "failed-precondition",
        "Admins cannot sanction themselves",
      );
    }

    const result = await _applyAccountSanction({
      targetUid,
      actionType,
      reason,
      adminUid: request.auth.uid,
      durationDays,
      actionLabel: "adminAccountSanction",
    });

    return { success: true, ...result };
  },
);

/**
 * _evaluateDisputePatternSanction — Pattern-Detection bei Verkaeufer-Disputes.
 *
 * **Discogs-Modell-Komponente (2026-04-30):**
 * Zaehlt die Disputes der letzten 6 Monate gegen einen Verkaeufer und
 * triggert automatische Sanktionen ohne Geldbewegung (Hausrecht):
 *   - ≥3 Disputes/6 Monate → 30 Tage Listings-Pause
 *   - ≥5 Disputes/6 Monate → permanenter Account-Ban
 *
 * Wird von `openDispute` nach erfolgreichem Status-Update aufgerufen
 * (try/catch um den Aufruf, damit Pattern-Detection den openDispute-
 * Hauptpfad nicht blocken kann).
 *
 * Idempotenz: wenn der Verkaeufer schon `banned` ist, wird nicht erneut
 * sanktioniert. Bei `suspended` (= bereits Listings-Pause aktiv) UND
 * Eskalation auf ≥5 → Eskalation zu Ban (lift gefolgt von ban).
 *
 * @returns {object|null} Sanktion-Ergebnis oder null wenn keine Aktion
 */
async function _evaluateDisputePatternSanction(sellerId, currentOrderId) {
  if (!sellerId) return null;

  // disputedAt ist Firestore Timestamp (set via FieldValue.serverTimestamp()
  // in openDispute) — Date-Object statt ISO-String fuer Query (siehe
  // _runStaleShipmentsResolver-Kommentar zum gleichen Bug-Pattern).
  const sixMonthsAgo = new Date(Date.now() - 6 * 30 * 24 * 60 * 60 * 1000);

  // Disputes des Verkaeufers in den letzten 6 Monaten zaehlen.
  // disputedAt wird in openDispute auf serverTimestamp gesetzt — nur Orders
  // mit disputedAt sind „echte" Disputes.
  const ordersRef = db.collection("artifacts").doc(APP_ID).collection("orders");
  const recentDisputesSnap = await ordersRef
    .where("sellerId", "==", sellerId)
    .where("disputedAt", ">=", sixMonthsAgo)
    .get();

  const disputeCount = recentDisputesSnap.size;
  console.log(
    `_evaluateDisputePatternSanction: seller=${sellerId} ` +
    `recent_disputes_6mo=${disputeCount} (current order ${currentOrderId})`,
  );

  if (disputeCount < 3) return null;

  // Aktuellen trustLevel pruefen — falls schon banned, nichts mehr tun.
  const trustSnap = await db.doc(
    `artifacts/${APP_ID}/users/${sellerId}/data/trustLevel`,
  ).get();
  const currentLevel = trustSnap.exists
    ? (trustSnap.data().level || "new")
    : "new";

  if (currentLevel === "banned") {
    console.log(
      `_evaluateDisputePatternSanction: seller=${sellerId} already banned — skip`,
    );
    return null;
  }

  // Sanktions-Stufe waehlen
  let actionType;
  let reason;
  if (disputeCount >= 5) {
    actionType = "ban";
    reason = `Auto-sanction: ${disputeCount} disputes in last 6 months (≥5 threshold = ban). Triggered by order ${currentOrderId}.`;
  } else {
    actionType = "pauseListings";
    reason = `Auto-sanction: ${disputeCount} disputes in last 6 months (≥3 threshold = 30d listings-pause). Triggered by order ${currentOrderId}.`;
  }

  // Wenn schon "suspended" (= Listings-Pause aktiv) und neue Schwelle ist
  // ≥5: erst lift (clean state), dann ban. Sonst direkter Sanktions-Apply.
  if (currentLevel === "suspended" && actionType === "ban") {
    try {
      await _applyAccountSanction({
        targetUid: sellerId,
        actionType: "lift",
        reason: "Lifting prior suspension before escalation to ban",
        adminUid: "system_pattern_detection",
        actionLabel: "auto_pattern_sanction",
      });
    } catch (e) {
      console.error(
        `_evaluateDisputePatternSanction lift-before-ban failed: ${e.message}`,
      );
      // Trotzdem versuchen direkt zu bannen — pause bleibt sonst aktiv,
      // aber level wird neu gesetzt
    }
  }

  // Bei 30-Tage-Pause: nur ausfuehren wenn nicht schon suspended (Idempotenz).
  // Bei ban: ausfuehren auch wenn suspended (Eskalation).
  if (actionType === "pauseListings" && currentLevel === "suspended") {
    console.log(
      `_evaluateDisputePatternSanction: seller=${sellerId} already suspended ` +
      `with ${disputeCount} disputes (still <5) — no escalation yet`,
    );
    return null;
  }

  const result = await _applyAccountSanction({
    targetUid: sellerId,
    actionType,
    reason,
    adminUid: "system_pattern_detection",
    durationDays: actionType === "pauseListings" ? 30 : undefined,
    actionLabel: "auto_pattern_sanction",
  });

  console.log(
    `_evaluateDisputePatternSanction: APPLIED ${actionType} on seller=${sellerId} ` +
    `(${disputeCount} disputes/6mo, prev_level=${currentLevel})`,
  );

  return { ...result, disputeCount, triggerOrderId: currentOrderId };
}

/**
 * recalculateAllSellerTiers — Daily-Cron als Fallback.
 * Läuft jede Nacht 03:00 Berlin und prüft alle aktiven Verkäufer-Profile.
 * Idempotent: ruft syncSellerTier pro Verkäufer auf, der nichts ändert
 * wenn Tier identisch bleibt.
 */
exports.recalculateAllSellerTiers = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "Europe/Berlin",
    timeoutSeconds: 540,
    memory: "512MiB",
    secrets: ["STRIPE_SECRET_KEY"],
  },
  async () => {
    const sellersSnap = await db.collectionGroup("data")
      .where("stripeAccountId", "!=", null)
      .get();

    let processed = 0;
    let updated = 0;
    let errors = 0;

    for (const doc of sellersSnap.docs) {
      // doc.ref looks like artifacts/{APP_ID}/users/{uid}/data/{docId}
      // Only process sellerProfile-docs
      if (doc.id !== "sellerProfile") continue;
      const uid = doc.ref.parent.parent.id;
      try {
        const before = (doc.data().delayDays || 7);
        await syncSellerTier(uid);
        processed++;
        const after = (await doc.ref.get()).data()?.delayDays || 7;
        if (after !== before) updated++;
      } catch (err) {
        console.error(`recalculateAllSellerTiers ${uid}:`, err.message);
        errors++;
      }
    }

    console.log(
      `recalculateAllSellerTiers: processed=${processed} updated=${updated} errors=${errors}`,
    );
  },
);

// ═══════════════════════════════════════════
// ─── Phase 2 (2026-04-28): Wallet-Buy-Pfade entfernt ───
// ═══════════════════════════════════════════
//
// Entfernte Functions: topUpBalance, purchaseWithBalance, requestPayout.
// Architektur-Grundsatz (siehe CLAUDE.md → Payment-Architektur): Riftr
// beruehrt zu KEINEM Zeitpunkt das Geld der User. Saemtliche Buy-Flows
// laufen ueber `createPaymentIntent` mit `transfer_data: { destination }`
// + `application_fee_amount`. Stripe Customer Balance / Manual-Payouts =
// BaFin-Risiko und sind ausgeschlossen.
//
// Wallet-Helper-Funktionen (`ensureStripeCustomer`, `getStripeCustomerId`,
// `updateBalanceCache`, `logTransaction`, `getTrustLevel`) bleiben erhalten —
// sie werden weiterhin von Refund/Dispute/Cancel-Pfaden in `confirmDelivery`,
// `cancelOrder`, dispute-handler genutzt. Phase 6 (Refund/Chargeback/Dispute)
// raeumt diese spaeter sauber auf.
//
// Tote Helper aus dem Wallet-Buy-Pfad weg (Phase 2): getBalance,
// getAvailableBalance, countTodayTopUps, countHourlyPurchases, getTodayPayoutTotal.
//
// `getWalletBalance` bleibt als Read-Only Earnings-View fuer Verkaeufer.

// ═══════════════════════════════════════════
// ─── Wallet: Get Balance (read-only) ───
// ═══════════════════════════════════════════

/**
 * getWalletBalance — Callable, authenticated.
 * Returns cached balance for the Flutter UI.
 */
exports.getWalletBalance = onCall(
  { region: "europe-west1", timeoutSeconds: 15, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;

    // Ensure customer exists (creates wallet docs if first time)
    await ensureStripeCustomer(uid);

    // Return fresh balance
    const balance = await updateBalanceCache(uid);
    return balance;
  }
);

// ══════════════════════════════════════════════════════════════════════
// ── Automatic Meta Deck Import ──
// ══════════════════════════════════════════════════════════════════════

const CARDS_LOOKUP = require("./cards_lookup.json");

function resolveCardId(name) {
  const card = CARDS_LOOKUP[name];
  return card ? card.id : null;
}

function resolveDeckMap(raw) {
  const result = {};
  for (const [name, qty] of Object.entries(raw)) {
    const id = resolveCardId(name);
    if (id) result[id] = (result[id] || 0) + qty;
  }
  return result;
}

function resolveBattlefields(names) {
  return names.map((name) => {
    const card = CARDS_LOOKUP[name];
    return card
      ? { id: card.id, name: card.name, imageUrl: card.imageUrl || "" }
      : { id: name, name, imageUrl: "" };
  });
}

/**
 * Parse Riot's organizedplay decklist page (Puppeteer-rendered innerText).
 *
 * Riot has shipped at least three templates we've seen in the wild:
 *
 *   T1 — Vegas era (mid-2025, original)
 *     Legend Rank: 1 / 33 players
 *     Overall Ranking: #490
 *     Legend:                   <- block form
 *     1 Ornn, ...
 *     Champion:
 *     1 Ornn, Forge God
 *     Main Deck:                <- with colon
 *     ...
 *     Battlefields:
 *     1 ...                     <- with "1 " prefix
 *     Rune Pool:                <- explicit label
 *     ...
 *     Sideboard:
 *
 *   T2 — Bologna (Feb 2026)
 *     Legend Rank: 1 / 33 players
 *     Overall Ranking: #490
 *     Legend: Ornn, ...         <- INLINE
 *     Champion: Ornn, Forge God <- INLINE
 *     Main Deck                 <- NO COLON
 *     ...
 *     8 Calm Rune               <- runes inserted directly after main deck
 *     4 Mind Rune               <- with NO "Rune Pool" label
 *     Battlefields              <- NO COLON
 *     Aspirant's Climb          <- NO "1 " PREFIX
 *     ...
 *     Sideboard
 *
 *   T3 — Lille (Apr 2026)
 *     Legend Rank:              <- EMPTY (just nbsps)
 *     Overall Ranking: #478
 *     Legend:                   <- block again
 *     1 Ornn, ...
 *     Champion:
 *     1 Ornn, Forge God
 *     Main Deck:                <- with colon
 *     ...
 *     Battlefields:             <- explicit label
 *     1 Ornn's Forge            <- "1 " prefix
 *     ...
 *     Rune Pool:
 *     ...
 *     Sideboard:
 *
 * Strategy that works for all three:
 *   - Anchor on `Overall Ranking: #N` (every block has exactly one)
 *   - Player name = nearest non-empty non-label line BEFORE the anchor
 *   - Sections accept label both with and without trailing colon
 *   - Legend/Champion accept both inline (`Legend: <name>`) and block
 *     (`Legend:\n1 <name>`) forms
 *   - Battlefield entries accept both `1 <name>` and `<name>` rows
 *   - Rune Pool: if no explicit label is found, scan within/after the
 *     Main Deck section for `\d+\s+<word>\s+Rune` lines and reclassify
 *     them as runes (Bologna inlines them at the end of Main Deck)
 *
 * Legend-Rank fields (legendRank/legendTotal) default to null when the
 * template doesn't expose them — buildMetaDeck doesn't read them.
 */
function parseDecklistPage(bodyText) {
  // Step 1 — normalise.
  // U+00A0 (NO-BREAK SPACE) ubiquitous in Riot's rendered output.
  // Tabs appear before some section labels.
  const normalised = bodyText
    .replace(/ /g, " ")
    .replace(/\t+/g, " ")
    .split(/\r?\n/)
    .map((l) => l.replace(/\s+$/, "").replace(/^\s+(?=\S)/, (m) => (m.length > 4 ? "" : m)))
    .map((l) => (l.trim() === "" ? "" : l))
    .join("\n");

  const lines = normalised.split("\n");

  // Step 2 — find every "Overall Ranking" anchor position (line index).
  const anchors = [];
  const overallRe = /^\s*Overall Ranking:\s*#?\s*(\d+)\s*$/i;
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(overallRe);
    if (m) anchors.push({ line: i, overall: parseInt(m[1], 10) });
  }
  if (anchors.length === 0) return [];

  // Helpers shared across all blocks.
  // Section-label detector accepts both `Label:` AND `Label` (no-colon).
  // Used to bound section scans — a label line means "stop reading the
  // current section's body here".
  const SECTION_NAMES = [
    "Legend Rank", "Legend", "Champion", "Main Deck",
    "Battlefields", "Rune Pool", "Sideboard",
  ];
  const isSectionLabel = (l) => {
    const trimmed = l.replace(/^\s+/, "").replace(/\s+$/, "");
    for (const name of SECTION_NAMES) {
      // Match "Label" / "Label:" / "Label: <inline-content>". The inline
      // form (T2 Bologna's "Legend: Ornn, ...") still counts as the start
      // of a NEW section so we don't bleed into it from the previous one.
      const re = new RegExp(`^${name}(?::|\\b).*$`, "i");
      if (re.test(trimmed)) return true;
    }
    return false;
  };

  /** Parse "N CardName" lines from a section body, return Map of {name:qty}. */
  const parseCardLines = (sectionLines) => {
    const out = {};
    for (const raw of sectionLines) {
      const cm = raw.match(/^\s*(\d+)\s+(.+?)\s*$/);
      if (cm) out[cm[2].trim()] = parseInt(cm[1], 10);
    }
    return out;
  };

  /** Find the line where a named section starts. Returns:
   *    { idx: <line index>, inline: <string after colon, or "" if block> }
   *  or null if the section isn't present in the window.
   *  Accepts both `Label:` and `Label` (no-colon) variants. */
  const findSectionStart = (label, startLine, endLineExclusive) => {
    // Two regexes: WITH colon (and optional inline content), THEN no-colon.
    // Try with-colon first because it's stricter and avoids matching
    // accidental partial words elsewhere.
    const reColon = new RegExp(`^\\s*${label}\\s*:\\s*(.*)\\s*$`, "i");
    const reBare = new RegExp(`^\\s*${label}\\s*$`, "i");
    for (let i = startLine; i < endLineExclusive; i++) {
      const m = lines[i].match(reColon);
      if (m) return { idx: i, inline: (m[1] || "").trim() };
      if (reBare.test(lines[i])) return { idx: i, inline: "" };
    }
    return null;
  };

  /** Pull the body of a named section, stopping at the next section
   *  label or [endLineExclusive]. Excludes the label line itself. */
  const sliceSection = (label, startLine, endLineExclusive) => {
    const start = findSectionStart(label, startLine, endLineExclusive);
    if (!start) return { lines: [], inline: "", startIdx: -1, endIdx: -1 };
    const out = [];
    let endIdx = endLineExclusive;
    for (let i = start.idx + 1; i < endLineExclusive; i++) {
      const l = lines[i];
      if (l === "") {
        // Allow single blank separator inside the section body, stop on second.
        if (out.length > 0 && out[out.length - 1] === "") {
          endIdx = i;
          break;
        }
        continue;
      }
      if (isSectionLabel(l)) { endIdx = i; break; }
      out.push(l);
    }
    return { lines: out, inline: start.inline, startIdx: start.idx, endIdx };
  };

  // Step 3 — for each anchor walk backwards to find player name.
  // Player name heuristic: scan backwards from the anchor; the first
  // non-empty, non-section-label line is the player. Stop at the
  // previous anchor's footer to avoid bleeding into the prior deck.
  const findPlayerName = (anchorIdx, prevAnchorEnd) => {
    for (let i = anchorIdx - 1; i > prevAnchorEnd; i--) {
      const l = lines[i];
      if (!l) continue;
      if (isSectionLabel(l)) continue;
      // Skip the "Legend Rank:" line itself when it survived as a label.
      if (/^\s*Legend Rank:\s*/i.test(l)) continue;
      // Reject lines that look like card-quantity rows ("3 Pit Crew").
      if (/^\s*\d+\s+/.test(l)) continue;
      return l.trim();
    }
    return "";
  };

  const decks = [];
  for (let a = 0; a < anchors.length; a++) {
    const { line: anchorLine, overall } = anchors[a];
    const prevAnchorEnd = a === 0 ? -1 : anchors[a - 1].line;
    // The block runs from the anchor to the next anchor's player-name
    // search-window boundary — the next deck's player name is ABOVE its
    // anchor, so we stop sections at `nextAnchorLine - 4` (some buffer
    // for empty/separator lines). Simpler & safer: stop at next anchor.
    const nextAnchorLine = a + 1 < anchors.length ? anchors[a + 1].line : lines.length;

    const player = findPlayerName(anchorLine, prevAnchorEnd);
    if (!player) continue;

    const legendSec = sliceSection("Legend", anchorLine, nextAnchorLine);
    const championSec = sliceSection("Champion", anchorLine, nextAnchorLine);
    const mainSec = sliceSection("Main Deck", anchorLine, nextAnchorLine);
    const bfSec = sliceSection("Battlefields", anchorLine, nextAnchorLine);
    const runeSec = sliceSection("Rune Pool", anchorLine, nextAnchorLine);
    const sideSec = sliceSection("Sideboard", anchorLine, nextAnchorLine);

    // ── Legend / Champion: support both inline and block forms. ──
    // T2 (Bologna) writes them inline: `Legend: Ornn, ...`
    // T1/T3 (Vegas/Lille) write them as a block: `Legend:\n1 Ornn, ...`
    const blockFirstCard = (block) => {
      for (const l of block) {
        const m = l.match(/^\s*1\s+(.+?)\s*$/);
        if (m) return m[1].trim();
      }
      return "";
    };
    const legendName = legendSec.inline || blockFirstCard(legendSec.lines);
    const championName = championSec.inline || blockFirstCard(championSec.lines);

    if (!legendName || !championName) continue;

    // ── Main Deck + Runes ──
    // T2 Bologna inlines runes at the END of the Main Deck block with
    // no "Rune Pool" header between them. We split by a heuristic:
    // any "<qty> <Word> Rune" line at the END of the main-deck section
    // is reclassified as a rune entry.
    const allMainEntries = parseCardLines(mainSec.lines);
    let mainDeck = allMainEntries;
    let runes = parseCardLines(runeSec.lines);

    if (Object.keys(runes).length === 0 && Object.keys(mainDeck).length > 0) {
      // No explicit Rune Pool section. Split off trailing rune entries.
      const split = {};
      const cleanMain = {};
      for (const [name, qty] of Object.entries(allMainEntries)) {
        if (/\bRune$/i.test(name)) split[name] = qty;
        else cleanMain[name] = qty;
      }
      if (Object.keys(split).length > 0) {
        mainDeck = cleanMain;
        runes = split;
      }
    }

    if (Object.keys(mainDeck).length === 0) continue;

    // ── Battlefields ──
    // T1/T3: "1 Ornn's Forge"  — accept "1 <name>"
    // T2: "Aspirant's Climb"   — accept bare name (no qty prefix)
    // Filter out any rune-style line that snuck in due to ordering.
    const battlefields = bfSec.lines
      .map((l) => {
        const withQty = l.match(/^\s*1\s+(.+?)\s*$/);
        if (withQty) return withQty[1].trim();
        // Bare line — strip leading/trailing whitespace, ignore empty
        // and ignore obvious non-name junk (single-character/tab lines).
        const bare = l.trim();
        if (!bare || bare.length < 3) return null;
        if (/^\d+\s/.test(bare)) return null; // a quantity line we don't want
        return bare;
      })
      .filter(Boolean);

    decks.push({
      player,
      legendRank: null,
      legendTotal: null,
      overall,
      legend: legendName,
      champion: championName,
      mainDeck,
      battlefields,
      runes,
      sideboard: parseCardLines(sideSec.lines),
    });
  }

  // Deduplicate by player+overall (defensive — Riot occasionally renders
  // the same deck twice in a Top-X / Best-Of section overlap).
  const seen = new Set();
  return decks.filter((d) => {
    const key = d.player.toLowerCase() + "#" + d.overall;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function buildMetaDeck(deck, tournamentName, tournamentDate, sourceUrl) {
  const legend = CARDS_LOOKUP[deck.legend];
  const domains = Object.keys(deck.runes || {});
  const d1 = (domains[0] || "").replace(" Rune", "");
  const d2 = (domains[1] || "").replace(" Rune", "");
  const r1 = deck.runes[domains[0]] || 0;
  const r2 = deck.runes[domains[1]] || 0;
  const legendShort = deck.legend.split(",")[0];

  const isTop8 = deck.overall <= 8;
  let placement;
  if (deck.overall === 1) placement = "1st";
  else if (deck.overall === 2) placement = "2nd";
  else if (deck.overall === 3) placement = "3rd";
  else if (deck.overall <= 4) placement = "Top 4";
  else if (deck.overall <= 8) placement = "Top 8";
  else placement = "Best of";
  const slug = deck.player.toLowerCase().replace(/[^a-z0-9]+/g, "-");
  const tSlug = tournamentName.toLowerCase().replace(/[^a-z0-9]+/g, "-");
  const deckId = isTop8
    ? `meta-${tSlug}-${deck.overall}-${slug}`
    : `meta-${tSlug}-best-${legendShort.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`;

  // Resolve champion → add to mainDeck + store as chosenChampionId
  const mainDeck = resolveDeckMap(deck.mainDeck);
  const championCard = deck.champion ? CARDS_LOOKUP[deck.champion] : null;
  const chosenChampionId = championCard ? championCard.id : "";
  if (chosenChampionId && !mainDeck[chosenChampionId]) {
    mainDeck[chosenChampionId] = 1;
  }

  return {
    id: deckId,
    name: isTop8 ? `${legendShort} ${d1}/${d2}` : `Best ${legendShort}`,
    description: `${tournamentName} ${placement} by ${deck.player} (Overall #${deck.overall})`,
    legendId: legend ? legend.id : "",
    legendName: legend ? legend.name : deck.legend,
    legendImageUrl: legend ? legend.imageUrl || "" : "",
    chosenChampionId,
    domains: [d1, d2],
    runeCount1: r1,
    runeCount2: r2,
    mainDeck,
    sideboard: resolveDeckMap(deck.sideboard),
    battlefields: resolveBattlefields(deck.battlefields),
    placement,
    playerName: deck.player,
    source: tournamentName,
    tournamentName,
    sourceUrl,
    sets: [],
    createdAt: tournamentDate,
    updatedAt: tournamentDate,
  };
}

// ── Toggle Deck Like ──
exports.toggleDeckLike = onCall(
  { region: "europe-west1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");

    // Rate-Limit (Round 6, 2026-04-29): 200 toggle-actions/User/Tag.
    // Vorher konnte ein User toggle-spammen → Firestore-Quota-Burn auf
    // Riftr-Konto. 200/Tag = ein Heavy-User der 100 Decks anschaut +
    // 100 mal entscheidet zu liken/unliken — komfortabel ueber dem
    // realistischen Use-Case (~5-10/Tag).
    await enforceRateLimit(uid, "toggleDeckLike", 200);

    const { deckId, collection } = request.data;
    if (!deckId) throw new HttpsError("invalid-argument", "deckId required");

    // Support both meta_decks and publicDecks
    const validCollections = ["meta_decks", "publicDecks"];
    const col = validCollections.includes(collection) ? collection : "meta_decks";

    const deckRef = db.collection("artifacts").doc(APP_ID).collection(col).doc(deckId);
    const likeRef = deckRef.collection("likes").doc(uid);

    const result = await db.runTransaction(async (tx) => {
      const likeDoc = await tx.get(likeRef);
      const deckDoc = await tx.get(deckRef);
      if (!deckDoc.exists) throw new HttpsError("not-found", "Deck not found");

      if (likeDoc.exists) {
        // Unlike
        tx.delete(likeRef);
        tx.update(deckRef, {
          likeCount: admin.firestore.FieldValue.increment(-1),
        });
        return { liked: false };
      } else {
        // Like
        tx.set(likeRef, { likedAt: new Date().toISOString() });
        tx.update(deckRef, {
          likeCount: admin.firestore.FieldValue.increment(1),
        });
        return { liked: true };
      }
    });

    return result;
  }
);

// Scheduled: Check daily for new tournament decklists
exports.checkNewTournamentDecks = onSchedule(
  { schedule: "every day 08:00", timeoutSeconds: 300, memory: "1GiB", region: "us-central1" },
  async () => {
    const scheduleRef = db.collection("artifacts").doc(APP_ID).collection("meta_tournament_schedule");
    const metaRef = db.collection("artifacts").doc(APP_ID).collection("meta_decks");
    const tournRef = db.collection("artifacts").doc(APP_ID).collection("meta_tournaments");

    const now = new Date();
    const snap = await scheduleRef.where("imported", "==", false).get();
    if (snap.empty) {
      console.log("No pending tournaments to check.");
      return;
    }

    // ── Source-platform branching ──
    // Mobalytics docs are processed via fetch+regex (no Puppeteer). Riot
    // docs need Puppeteer for the Riot SSR rendering. Process Mobalytics
    // first so a Puppeteer-launch failure doesn't block Asia imports.
    const mobalyticsDocs = snap.docs.filter(
      (d) => d.data().sourcePlatform === "mobalytics",
    );
    const riotDocs = snap.docs.filter(
      (d) => (d.data().sourcePlatform || "riot") === "riot",
    );

    for (const doc of mobalyticsDocs) {
      const t = doc.data();
      const eventDate = t.eventDate ? new Date(t.eventDate) : null;
      if (eventDate && eventDate > now) {
        console.log(`Skipping ${t.name} — event date ${t.eventDate} is in the future.`);
        continue;
      }
      try {
        const r = await importMobalyticsTournament(doc.ref, t);
        console.log(
          `[Mobalytics-Import] ${t.name}: imported=${r.imported} ` +
          `failedChampion=${r.failedChampion.length}`,
        );
      } catch (e) {
        console.error(`[Mobalytics-Import] ${t.name} failed: ${e.message}`);
      }
    }

    if (riotDocs.length === 0) {
      console.log(`No Riot docs pending. Done after Mobalytics pass.`);
      return;
    }

    // Lazy-load Puppeteer only when there's actual Riot work to do.
    const chromium = require("@sparticuz/chromium");
    const puppeteer = require("puppeteer-core");
    let browser;

    try {
      browser = await puppeteer.launch({
        args: chromium.args,
        defaultViewport: chromium.defaultViewport,
        executablePath: await chromium.executablePath(),
        headless: chromium.headless,
      });

      for (const doc of riotDocs) {
        const t = doc.data();
        const eventDate = new Date(t.eventDate);
        if (eventDate > now) {
          console.log(`Skipping ${t.name} — event date ${t.eventDate} is in the future.`);
          continue;
        }

        console.log(`Checking ${t.name} (${t.eventDate})...`);
        const slugs = t.urlSlugs || [];
        const baseUrl = "https://riftbound.leagueoflegends.com/en-us/news/organizedplay/";
        let foundUrl = null;
        let pageText = null;

        for (const slug of slugs) {
          const url = baseUrl + slug + "/";
          try {
            const page = await browser.newPage();
            await page.goto(url, { waitUntil: "networkidle2", timeout: 30000 });
            const text = await page.evaluate(() => document.body.innerText);
            await page.close();

            if (text && text.includes("Overall Ranking")) {
              foundUrl = url;
              pageText = text;
              console.log(`  Found decklists at ${url}`);
              break;
            }
          } catch (e) {
            console.log(`  ${slug}: ${e.message}`);
          }
        }

        if (!pageText) {
          console.log(`  No decklists found yet for ${t.name}. Will retry tomorrow.`);
          continue;
        }

        // Parse decks
        const rawDecks = parseDecklistPage(pageText);
        console.log(`  Parsed ${rawDecks.length} decks from ${foundUrl}`);

        if (rawDecks.length === 0) continue;

        // Build and write meta decks
        const metaDecks = rawDecks.map((d) =>
          buildMetaDeck(d, t.name, t.eventDate, foundUrl)
        );

        let batch = db.batch();
        let count = 0;
        for (const md of metaDecks) {
          batch.set(metaRef.doc(md.id), md);
          count++;
          if (count % 400 === 0) {
            await batch.commit();
            batch = db.batch();
          }
        }

        // Mark tournament as imported
        batch.update(doc.ref, { imported: true, importedAt: admin.firestore.FieldValue.serverTimestamp(), deckCount: metaDecks.length, sourceUrl: foundUrl });

        // Update/create tournament doc
        const tId = t.name.toLowerCase().replace(/[^a-z0-9]+/g, "-");
        batch.set(tournRef.doc(tId), {
          name: t.name,
          date: t.eventDate,
          deckCount: metaDecks.length,
          sourceUrl: foundUrl,
          importedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await batch.commit();
        console.log(`  ✅ Imported ${metaDecks.length} decks for ${t.name}`);

        // Broadcast push to all users
        try {
          await admin.messaging().send({
            topic: "all_users",
            notification: {
              title: "New Meta Decks!",
              body: `${metaDecks.length} tournament decks from ${t.name}`,
            },
            data: { type: "meta_decks" },
          });
          console.log(`  📣 Push sent to all_users topic`);
        } catch (pushErr) {
          console.warn(`  ⚠️ Push failed: ${pushErr.message}`);
        }
      }
    } finally {
      if (browser) await browser.close();
    }
  }
);

// Manual trigger for testing
exports.checkNewTournamentDecksManual = onRequest(
  { timeoutSeconds: 300, memory: "1GiB", region: "us-central1", secrets: ["ADMIN_TRIGGER_SECRET"] },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    // Re-use the same logic
    try {
      await exports.checkNewTournamentDecks.run();
      res.json({ success: true });
    } catch (e) {
      console.error(e);
      res.status(500).json({ error: e.message });
    }
  }
);

// ── Check for new UNL cards on Riftcodex ──

const RIFTCODEX_API = "https://api.riftcodex.com";

/**
 * Fetch all UNL cards from Riftcodex API (paginated).
 */
async function fetchRiftcodexUNL() {
  const all = [];
  let page = 1;
  let pages = 1;
  while (page <= pages) {
    const res = await fetch(`${RIFTCODEX_API}/cards?page=${page}`);
    if (!res.ok) throw new Error(`Riftcodex API error: ${res.status}`);
    const data = await res.json();
    pages = data.pages;
    const unl = (data.items || []).filter(c => (c.riftbound_id || "").startsWith("unl"));
    all.push(...unl);
    page++;
  }
  return all;
}

/**
 * Transform a Riftcodex card to our cards.json format.
 */
function transformCard(c) {
  let colNum = String(c.collector_number);
  const isAltArt = c.metadata?.alternate_art || (c.name || "").includes("(Alternate Art)");
  const isSig = c.metadata?.signature || (c.name || "").includes("(Signature)");
  const isOver = c.metadata?.overnumbered || parseInt(colNum) > 219;

  // Clean name: strip variant suffixes, convert " - " → ", "
  let cleanName = (c.name || "")
    .replace(/ \(Alternate Art\)$/i, "")
    .replace(/ \(Overnumbered\)$/i, "")
    .replace(/ \(Signature\)$/i, "")
    .replace(/ - /, ", ");

  // Collector number suffix
  if (isAltArt && !colNum.includes("a")) colNum += "a";
  if (isSig && !colNum.includes("*")) colNum += "*";

  // Baron Nashor Ultimate fix (Riftcodex tags as Showcase, but it's Ultimate — confirmed by Riot)
  let rarity = c.classification?.rarity || "Common";
  if (cleanName === "Baron Nashor" && isOver && parseInt(colNum) >= 220) {
    rarity = "Ultimate";
  }

  return {
    id: c.id,
    name: cleanName,
    riftbound_id: c.riftbound_id,
    tcgplayer_id: c.tcgplayer_id || null,
    public_code: c.public_code || null,
    collector_number: colNum,
    attributes: c.attributes || {},
    classification: { ...c.classification, rarity },
    text: { rich: c.text?.rich || "", plain: c.text?.plain || "" },
    set: { set_id: "UNL", label: "Unleashed" },
    media: c.media || {},
    tags: c.tags || [],
    orientation: c.orientation || "portrait",
    metadata: {
      clean_name: cleanName,
      alternate_art: isAltArt,
      overnumbered: isOver,
      signature: isSig,
    },
    display_name: cleanName,
  };
}

/**
 * Scheduled: Check daily for new UNL cards on Riftcodex.
 * Writes new cards to Firestore card_updates collection.
 * Sends topic push when new cards are found.
 */
exports.checkNewUNLCards = onSchedule(
  { schedule: "every day 09:00", timeoutSeconds: 120, memory: "512MiB", region: "us-central1" },
  async () => {
    const updatesRef = db.collection("artifacts").doc(APP_ID).collection("card_updates");

    // 1. Fetch all UNL cards from Riftcodex
    const riftcodexCards = await fetchRiftcodexUNL();
    console.log(`Riftcodex: ${riftcodexCards.length} UNL cards`);

    // 2. Get known riftbound_ids from Firestore
    const knownDoc = await updatesRef.doc("known_unl_ids").get();
    const knownIds = new Set(knownDoc.exists ? (knownDoc.data().ids || []) : []);
    console.log(`Known: ${knownIds.size} UNL cards`);

    // 3. Find new cards
    const newCards = riftcodexCards.filter(c => !knownIds.has(c.riftbound_id));
    if (newCards.length === 0) {
      console.log("checkNewUNLCards: 0 new cards");
      return;
    }

    // 4. Transform and write to Firestore
    const transformed = newCards.map(transformCard);
    console.log(`checkNewUNLCards: ${transformed.length} new cards:`);
    transformed.forEach(c => console.log(`  ${c.collector_number} ${c.name} (${c.classification.rarity})`));

    // Write cards as individual documents (for app to merge)
    let batch = db.batch();
    let count = 0;
    for (const card of transformed) {
      batch.set(updatesRef.doc(card.riftbound_id.replace(/\//g, "-")), card);
      count++;
      if (count % 400 === 0) {
        await batch.commit();
        batch = db.batch();
      }
    }

    // Update known IDs (all Riftcodex cards, not just new ones)
    batch.set(updatesRef.doc("known_unl_ids"), {
      ids: riftcodexCards.map(c => c.riftbound_id),
      lastChecked: admin.firestore.FieldValue.serverTimestamp(),
      totalCount: riftcodexCards.length,
    });

    await batch.commit();

    // 5. Topic push to all users
    try {
      await admin.messaging().send({
        topic: "all_users",
        notification: {
          title: "New UNL Cards!",
          body: `${transformed.length} new Unleashed cards added`,
        },
        data: { type: "new_cards" },
      });
      console.log(`📣 Push sent to all_users topic`);
    } catch (pushErr) {
      console.warn(`⚠️ Push failed: ${pushErr.message}`);
    }

    console.log(`✅ checkNewUNLCards: imported ${transformed.length} new cards`);
  }
);

// Manual trigger for testing
exports.checkNewUNLCardsManual = onRequest(
  { timeoutSeconds: 120, memory: "512MiB", region: "us-central1", secrets: ["ADMIN_TRIGGER_SECRET"] },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    try {
      await exports.checkNewUNLCards.run();
      res.json({ success: true });
    } catch (e) {
      console.error(e);
      res.status(500).json({ error: e.message });
    }
  }
);

// ═══════════════════════════════════════════
// ─── One-time Migration: playerProfiles ───
// ═══════════════════════════════════════════

exports.migratePlayerProfiles = onRequest(
  { timeoutSeconds: 300, memory: "512MiB", region: "us-central1", secrets: ["ADMIN_TRIGGER_SECRET"] },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    try {
      const usersRef = db.collection("artifacts").doc(APP_ID).collection("users");
      const usersSnap = await usersRef.listDocuments();
      let migrated = 0;
      let skipped = 0;

      // Erweiterte Migration (Security-Audit 2026-04-29): syncht jetzt auch
      // sellerProfile public-Stats (rating, reviewCount, totalSales, memberSince)
      // sowie bio + avatarUrl aus profile in den playerProfiles-Mirror.
      // Existing users bekommen damit den vollen Mirror nachträglich,
      // sodass die Author-View / fetchProfiles korrekt populated sind.
      // Nutzt `syncPlayerProfile` Helper damit die Logik konsistent mit
      // Live-Trigger-Pfaden ist (single source of truth).
      for (const userDoc of usersSnap) {
        const uid = userDoc.id;
        const profileDoc = await userDoc.collection("data").doc("profile").get();
        if (!profileDoc.exists) { skipped++; continue; }
        const displayName = profileDoc.data().displayName;
        if (!displayName || displayName.trim() === "") { skipped++; continue; }

        await syncPlayerProfile(uid);
        migrated++;
      }

      console.log(`Migration done: ${migrated} migrated, ${skipped} skipped`);
      res.json({ success: true, migrated, skipped });
    } catch (e) {
      console.error("Migration failed:", e);
      res.status(500).json({ error: e.message });
    }
  }
);

// ═══════════════════════════════════════════
// ─── Beta Marketplace Cleanup (One-shot, Bearer-protected) ───
// ═══════════════════════════════════════════
//
// Use-Case: vor Public-Beta-Opening allen Marketplace-State wipen damit
// Tester nicht ueber alte Test-Listings/Test-Orders stolpern. Wipe-Scope
// ist marketplace-only — User-Daten (Profile, Collection, Decks, Friends,
// Match-History) bleiben unangetastet.
//
// Trigger: bearer-protected, manuell via curl. Reverse-engineering nicht
// moeglich (ADMIN_TRIGGER_SECRET ist Firebase-Secret, nicht im App-Bundle).
//
// USAGE:
//   curl -X POST -H "Authorization: Bearer $ADMIN_TRIGGER_SECRET" \
//     https://us-central1-riftr-10527.cloudfunctions.net/cleanupBetaMarketplace
//
// Returns JSON-Summary mit gelöschten Counts pro Collection.
// Idempotent — kann mehrfach ausgefuehrt werden.

exports.cleanupBetaMarketplace = onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    region: "us-central1",
    secrets: ["ADMIN_TRIGGER_SECRET"],
  },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;

    const summary = {
      listings_deleted: 0,
      orders_deleted: 0,
      cartReservations_deleted: 0,
      reviews_deleted: 0,
      walletTransactions_deleted: 0,
      walletDocs_deleted: 0,
      buyerSellerPairs_deleted: 0,
      rateLimits_deleted: 0,
      stripe_events_deleted: 0,
      sellerProfiles_reset: 0,
      errors: [],
    };

    // Helper: batched delete eines Snapshot
    async function batchDelete(snap, label) {
      let deleted = 0;
      const docs = snap.docs;
      // Firestore batch limit = 500
      for (let i = 0; i < docs.length; i += 400) {
        const batch = db.batch();
        const slice = docs.slice(i, i + 400);
        for (const d of slice) batch.delete(d.ref);
        await batch.commit();
        deleted += slice.length;
      }
      console.log(`cleanupBetaMarketplace: deleted ${deleted} ${label}`);
      return deleted;
    }

    try {
      // ── 1. Listings ──
      const listingsSnap = await db.collection("artifacts").doc(APP_ID)
        .collection("listings").get();
      summary.listings_deleted = await batchDelete(listingsSnap, "listings");

      // ── 2. Orders ──
      const ordersSnap = await db.collection("artifacts").doc(APP_ID)
        .collection("orders").get();
      summary.orders_deleted = await batchDelete(ordersSnap, "orders");

      // ── 3. CartReservations (collectionGroup über alle users) ──
      const cartResSnap = await db.collectionGroup("cartReservations").get();
      summary.cartReservations_deleted = await batchDelete(cartResSnap, "cartReservations");

      // ── 4. Reviews (collectionGroup) ──
      const reviewsSnap = await db.collectionGroup("reviews").get();
      summary.reviews_deleted = await batchDelete(reviewsSnap, "reviews");

      // ── 5. WalletTransactions (collectionGroup) ──
      const walletTxSnap = await db.collectionGroup("walletTransactions").get();
      summary.walletTransactions_deleted = await batchDelete(walletTxSnap, "walletTransactions");

      // ── 6. Wallet docs (collectionGroup) ──
      const walletSnap = await db.collectionGroup("wallet").get();
      summary.walletDocs_deleted = await batchDelete(walletSnap, "wallet docs");

      // ── 7. SellerProfile-Stats reset (NICHT cost_basis + portfolio_history!) ──
      // KORREKTUR (2026-04-29): cost_basis + portfolio_history wurden urspruenglich
      // ebenfalls geloescht — falsch. Das sind echte Sammlungs-Historie-Daten:
      //   - cost_basis: FIFO-Kauf-Historie (was hat der User pro Karte bezahlt)
      //                 → wichtig fuer realized-gains-Berechnung
      //   - portfolio_history: tägliche Snapshots des Sammlungs-Werts
      //                         → wichtig fuer Portfolio-Performance-Chart
      // Beide werden NICHT durch Test-Marktplatz-Aktivitaet "verschmutzt"
      // (sie tracken die ECHTE Sammlung), daher hier nicht mehr loeschen.
      const usersRef = db.collection("artifacts").doc(APP_ID).collection("users");
      const userDocs = await usersRef.listDocuments();
      let sellerProfilesReset = 0;
      for (const userDoc of userDocs) {
        // Wir behalten displayName, email, country, address, isCommercialSeller,
        // stripeAccountId, etc. Nur die Stats die aus Test-Orders kamen werden
        // genullt damit der Beta-Start-State sauber ist.
        try {
          const spRef = userDoc.collection("data").doc("sellerProfile");
          const spDoc = await spRef.get();
          if (spDoc.exists) {
            await spRef.update({
              rating: 0,
              reviewCount: 0,
              totalSales: 0,
              totalRevenue: 0,
              completedSalesCount: 0,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            sellerProfilesReset++;
          }
        } catch (_) {}
      }
      summary.sellerProfiles_reset = sellerProfilesReset;

      // ── 9. Admin-Tracking-Collections (buyerSellerPairs, rateLimits, stripe_events) ──
      const pairsSnap = await db.collection("artifacts").doc(APP_ID)
        .collection("buyerSellerPairs").get();
      summary.buyerSellerPairs_deleted = await batchDelete(pairsSnap, "buyerSellerPairs");

      const rateLimitsSnap = await db.collection("artifacts").doc(APP_ID)
        .collection("rateLimits").get();
      summary.rateLimits_deleted = await batchDelete(rateLimitsSnap, "rateLimits");

      const stripeEventsSnap = await db.collection("artifacts").doc(APP_ID)
        .collection("stripe_events").get();
      summary.stripe_events_deleted = await batchDelete(stripeEventsSnap, "stripe_events");

      // ── 10. PlayerProfiles Mirror Re-Sync triggern ──
      // Stats-Reset auf sellerProfile bedeutet die Mirror sind out-of-date.
      // Naechster syncPlayerProfile-Call (bei submitReview/confirmDelivery)
      // wird den Mirror updaten. Fuer einen sofortigen sync alle User
      // durchlaufen lassen:
      let mirrorsSynced = 0;
      for (const userDoc of userDocs) {
        try {
          await syncPlayerProfile(userDoc.id);
          mirrorsSynced++;
        } catch (_) {}
      }
      summary.playerProfiles_synced = mirrorsSynced;

      console.log(
        `cleanupBetaMarketplace COMPLETE: ${JSON.stringify(summary)}`,
      );
      res.json({ success: true, ...summary });
    } catch (err) {
      console.error("cleanupBetaMarketplace failed:", err);
      summary.errors.push(err.message);
      res.status(500).json({ success: false, error: err.message, ...summary });
    }
  },
);

// ═══════════════════════════════════════════
// ─── Daily Backup: portfolio_history + cost_basis ───
// ═══════════════════════════════════════════
//
// Belt-and-suspenders Schutz fuer kritische User-Finanz-Daten.
// Auch wenn die Firestore-Rules append-only enforcen + delete blocken,
// koennten Server-side-Bugs (z.B. CF mit Admin-SDK das Rules umgeht)
// die Daten zerstoeren. Daily-Backup gibt 30-Tage-Recovery-Fenster.
//
// Doc-Path: artifacts/{appId}/data_backups/{YYYY-MM-DD}/users/{uid}/{type}
// Retention: 30 Tage (alte Backups werden vom selben Cron geloescht).
//
// Run: jeden Tag 02:00 UTC (Berlin-zeit-spaet aber vor App-Open-Peak).

exports.dailyBackupUserData = onSchedule(
  {
    schedule: "0 2 * * *",
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "1GiB",
    region: "us-central1",
  },
  async () => {
    const today = new Date().toISOString().slice(0, 10); // "YYYY-MM-DD"
    const usersRef = db.collection("artifacts").doc(APP_ID).collection("users");
    const userDocs = await usersRef.listDocuments();

    let phBackedUp = 0;
    let cbBackedUp = 0;
    let errors = 0;

    for (const userDoc of userDocs) {
      const uid = userDoc.id;

      // portfolio_history backup
      try {
        const phRef = userDoc.collection("data").doc("portfolio_history");
        const phSnap = await phRef.get();
        if (phSnap.exists) {
          await db.collection("artifacts").doc(APP_ID)
            .collection("data_backups").doc(today)
            .collection("users").doc(uid)
            .collection("data").doc("portfolio_history")
            .set({
              ...phSnap.data(),
              _backedUpAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          phBackedUp++;
        }
      } catch (e) {
        errors++;
        console.error(`backup portfolio_history ${uid}: ${e.message}`);
      }

      // cost_basis backup
      try {
        const cbRef = userDoc.collection("data").doc("cost_basis");
        const cbSnap = await cbRef.get();
        if (cbSnap.exists) {
          await db.collection("artifacts").doc(APP_ID)
            .collection("data_backups").doc(today)
            .collection("users").doc(uid)
            .collection("data").doc("cost_basis")
            .set({
              ...cbSnap.data(),
              _backedUpAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          cbBackedUp++;
        }
      } catch (e) {
        errors++;
        console.error(`backup cost_basis ${uid}: ${e.message}`);
      }
    }

    // ── Retention: lösche Backup-Tage älter als 30 Tage ──
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      .toISOString().slice(0, 10);
    const allBackupDays = await db.collection("artifacts").doc(APP_ID)
      .collection("data_backups").listDocuments();
    let prunedDays = 0;
    for (const dayDoc of allBackupDays) {
      if (dayDoc.id < cutoff) {
        // Recursive delete: alle subcollections unter diesem day-doc loeschen
        try {
          const usersInBackup = await dayDoc.collection("users").listDocuments();
          for (const ub of usersInBackup) {
            const dataDocs = await ub.collection("data").listDocuments();
            for (const dd of dataDocs) {
              await dd.delete();
            }
            await ub.delete();
          }
          await dayDoc.delete();
          prunedDays++;
        } catch (e) {
          console.error(`prune ${dayDoc.id}: ${e.message}`);
        }
      }
    }

    console.log(
      `dailyBackupUserData: phBackedUp=${phBackedUp} cbBackedUp=${cbBackedUp} ` +
      `errors=${errors} prunedDays=${prunedDays} (date=${today})`,
    );
  },
);

// ═══════════════════════════════════════════
// ─── Restore from Backup (Bearer-protected) ───
// ═══════════════════════════════════════════
//
// Wenn ein User-Doc verloren geht, kann Admin via curl den letzten Backup
// wiederherstellen. Picks automatically the LATEST backup that has the doc.
//
// USAGE:
//   curl -X POST -H "Authorization: Bearer $ADMIN_TRIGGER_SECRET" \
//     -H "Content-Type: application/json" \
//     --data '{"uid":"DfAEtNC3rYcCIEuvODWwolNVHUA3","type":"portfolio_history"}' \
//     https://us-central1-riftr-10527.cloudfunctions.net/restoreFromBackup
//
// type: "portfolio_history" oder "cost_basis"

exports.restoreFromBackup = onRequest(
  {
    timeoutSeconds: 60,
    region: "us-central1",
    secrets: ["ADMIN_TRIGGER_SECRET"],
  },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    const { uid, type } = req.body || {};
    if (!uid || !type || !["portfolio_history", "cost_basis"].includes(type)) {
      res.status(400).json({
        error: "Body needs { uid, type: 'portfolio_history'|'cost_basis' }",
      });
      return;
    }

    // Find latest backup day that has this user+type
    const allDays = await db.collection("artifacts").doc(APP_ID)
      .collection("data_backups").listDocuments();
    const sortedDays = allDays.map(d => d.id).sort().reverse(); // newest first

    for (const day of sortedDays) {
      const backupRef = db.collection("artifacts").doc(APP_ID)
        .collection("data_backups").doc(day)
        .collection("users").doc(uid)
        .collection("data").doc(type);
      const snap = await backupRef.get();
      if (snap.exists) {
        const data = snap.data();
        delete data._backedUpAt; // strip backup metadata
        await db.collection("artifacts").doc(APP_ID)
          .collection("users").doc(uid)
          .collection("data").doc(type)
          .set(data);
        res.json({
          success: true,
          restored_from: day,
          uid,
          type,
        });
        return;
      }
    }

    res.status(404).json({ error: `No backup found for uid=${uid} type=${type}` });
  },
);

// ═══════════════════════════════════════════
// ─── One-time Migration: createdAt from Firebase Auth ───
// ═══════════════════════════════════════════

exports.migrateCreatedAt = onRequest(
  { timeoutSeconds: 300, memory: "512MiB", region: "us-central1", secrets: ["ADMIN_TRIGGER_SECRET"] },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    try {
      let migrated = 0;
      let skipped = 0;
      let nextPageToken;

      do {
        const listResult = await admin.auth().listUsers(100, nextPageToken);
        for (const userRecord of listResult.users) {
          const uid = userRecord.uid;
          const creationTime = userRecord.metadata.creationTime;
          if (!creationTime) { skipped++; continue; }

          const profileRef = db.collection("artifacts").doc(APP_ID)
            .collection("users").doc(uid)
            .collection("data").doc("profile");
          const profileDoc = await profileRef.get();

          // Only set createdAt if it doesn't exist yet
          if (profileDoc.exists && profileDoc.data().createdAt) {
            skipped++;
            continue;
          }

          await profileRef.set({
            createdAt: new Date(creationTime).toISOString(),
          }, { merge: true });

          migrated++;
        }
        nextPageToken = listResult.pageToken;
      } while (nextPageToken);

      console.log(`createdAt migration: ${migrated} migrated, ${skipped} skipped`);
      res.json({ success: true, migrated, skipped });
    } catch (e) {
      console.error("createdAt migration failed:", e);
      res.status(500).json({ error: e.message });
    }
  }
);

// ═══════════════════════════════════════════
// ─── Cart Reservation System ───
// ═══════════════════════════════════════════

const CART_RESERVATION_TTL_MS = 30 * 60 * 1000; // 30 minutes

/**
 * Reserve listing quantity for a cart item.
 * Uses Firestore Transaction to prevent race conditions.
 */
// ─── Cart-Reservation Per-User-Limit (Security-Audit Round 2, 2026-04-29) ──
// Schuetzt vor Inventory-DoS: ohne Limit kann ein User (oder ein Bot ohne
// App Check) beliebig viele Listings dauerhaft blocken (Reserve → 30min
// TTL → Re-Reserve in Endlosschleife). Limit:
//   - max 50 aktive Reservations pro User gleichzeitig
//   - max 100 Karten total summiert ueber alle Reservations
// 50/100 = sehr grosszuegig fuer einen ehrlichen Smart-Cart der bei einem
// 60-Karten-Deck ueber 5-10 Verkaeufer aufteilt; aber blockt Bots die
// 1000 Listings parallel reservieren.
const MAX_ACTIVE_RESERVATIONS_PER_USER = 50;
const MAX_RESERVED_CARDS_PER_USER = 100;

exports.reserveForCart = onCall(
  { region: "europe-west1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Not signed in");

    const { listingId, quantity } = request.data;
    if (!listingId || !quantity || quantity < 1) {
      throw new HttpsError("invalid-argument", "listingId and quantity required");
    }
    // Per-Listing-Cap: Single-Reservation darf nicht das ganze Limit
    // alleine beanspruchen (sonst koennte 1 boeswillige Reservation alle
    // anderen blockieren). Hard-Cap = 50 Karten pro Single-Listing-Res.
    if (quantity > 50) {
      throw new HttpsError("invalid-argument", "Quantity exceeds per-listing reservation cap (50)");
    }

    const listingRef = db.collection("artifacts").doc(APP_ID)
      .collection("listings").doc(listingId);
    const reservationRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("cartReservations").doc(listingId);

    // Pre-Transaction: aktive Reservations des Users auslesen fuer
    // Per-User-Cap-Check. Wir lesen non-transaktional weil:
    //  (a) Reservations werden nur durch reserveForCart/release/update
    //      mutiert, alle gehen durch CFs, kein paralleles Listing-Schreiben.
    //  (b) Read-then-write-Race ist sehr unwahrscheinlich (User macht nicht
    //      gleichzeitig 2 reserveForCart-Calls fuer DIFFERENT listings) und
    //      worst-case ueberschreitet das Limit um 1 — nicht kritisch.
    const userReservationsSnap = await db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("cartReservations")
      .get();

    let activeCount = 0;
    let activeQtyTotal = 0;
    let hasExistingForListing = false;
    let existingQtyForListing = 0;
    const nowMs = Date.now();
    for (const resDoc of userReservationsSnap.docs) {
      const res = resDoc.data();
      const expMs = res.expiresAt ? new Date(res.expiresAt).getTime() : 0;
      if (expMs <= nowMs) continue; // Expired Reservations ignorieren (cleanExpiredReservations cron entfernt sie spaeter)
      activeCount++;
      activeQtyTotal += res.quantity || 0;
      if (resDoc.id === listingId) {
        hasExistingForListing = true;
        existingQtyForListing = res.quantity || 0;
      }
    }

    // Per-User-Cap-Check: nur wenn das eine NEUE Reservation ist (nicht
    // existing-Update) oder die existing-Quantity erhoeht wird.
    const wouldAddCount = hasExistingForListing ? 0 : 1;
    const wouldAddQty = Math.max(0, quantity - existingQtyForListing);

    if (activeCount + wouldAddCount > MAX_ACTIVE_RESERVATIONS_PER_USER) {
      throw new HttpsError(
        "resource-exhausted",
        `Cart reservation limit reached (${MAX_ACTIVE_RESERVATIONS_PER_USER}). Remove some items before adding more.`,
      );
    }
    if (activeQtyTotal + wouldAddQty > MAX_RESERVED_CARDS_PER_USER) {
      throw new HttpsError(
        "resource-exhausted",
        `Total cart card limit reached (${MAX_RESERVED_CARDS_PER_USER}). Remove some items before adding more.`,
      );
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + CART_RESERVATION_TTL_MS);

    await db.runTransaction(async (tx) => {
      const listingDoc = await tx.get(listingRef);
      if (!listingDoc.exists) throw new HttpsError("not-found", "Listing not found");

      const listing = listingDoc.data();
      if (listing.status !== "active") throw new HttpsError("failed-precondition", "Listing not active");
      if (listing.sellerId === uid) throw new HttpsError("failed-precondition", "Cannot buy own listing");

      const available = (listing.quantity || 0) - (listing.reservedQty || 0);

      // Check if user already has a reservation for this listing
      const existingRes = await tx.get(reservationRef);
      const existingQty = existingRes.exists ? (existingRes.data().quantity || 0) : 0;
      const additionalQty = quantity - existingQty;

      if (additionalQty > 0 && available < additionalQty) {
        throw new HttpsError("failed-precondition", `Only ${available + existingQty} available`);
      }

      if (additionalQty !== 0) {
        tx.update(listingRef, {
          reservedQty: admin.firestore.FieldValue.increment(additionalQty),
        });
      }

      tx.set(reservationRef, {
        listingId,
        sellerId: listing.sellerId,
        quantity,
        reservedAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
      });
    });

    return { success: true, expiresAt: expiresAt.toISOString() };
  }
);

/**
 * Release a cart reservation (remove item from cart).
 */
exports.releaseCartReservation = onCall(
  { region: "europe-west1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Not signed in");

    const { listingId } = request.data;
    if (!listingId) throw new HttpsError("invalid-argument", "listingId required");

    const reservationRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("cartReservations").doc(listingId);
    const listingRef = db.collection("artifacts").doc(APP_ID)
      .collection("listings").doc(listingId);

    await db.runTransaction(async (tx) => {
      const resDoc = await tx.get(reservationRef);
      if (!resDoc.exists) return; // Already released, no-op

      const qty = resDoc.data().quantity || 0;
      const listingDoc = await tx.get(listingRef);

      if (listingDoc.exists) {
        const currentReserved = listingDoc.data().reservedQty || 0;
        tx.update(listingRef, {
          reservedQty: Math.max(0, currentReserved - qty),
        });
      }

      tx.delete(reservationRef);
    });

    return { success: true };
  }
);

/**
 * Update quantity of an existing cart reservation.
 */
exports.updateCartReservation = onCall(
  { region: "europe-west1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Not signed in");

    const { listingId, newQuantity } = request.data;
    if (!listingId || newQuantity == null) {
      throw new HttpsError("invalid-argument", "listingId and newQuantity required");
    }

    // Quantity 0 = release
    if (newQuantity <= 0) {
      return exports.releaseCartReservation.run({ auth: request.auth, data: { listingId } });
    }

    // Per-Listing-Cap (Security-Audit Round 2, 2026-04-29): identisch zu
    // reserveForCart, sonst koennte ein User via update das Limit umgehen.
    if (newQuantity > 50) {
      throw new HttpsError("invalid-argument", "Quantity exceeds per-listing reservation cap (50)");
    }

    const reservationRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("cartReservations").doc(listingId);
    const listingRef = db.collection("artifacts").doc(APP_ID)
      .collection("listings").doc(listingId);

    // Per-User-Cap-Check fuer Quantity-Increase (Security-Audit Round 2):
    // updateCartReservation kann nur die quantity einer EXISTING Reservation
    // aendern, also activeCount aendert sich nicht — nur die Total-Card-
    // Summe wird gegen MAX_RESERVED_CARDS_PER_USER geprueft.
    const userReservationsSnap = await db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("cartReservations")
      .get();
    const nowMs = Date.now();
    let activeQtyTotal = 0;
    let currentQtyForListing = 0;
    for (const resDoc of userReservationsSnap.docs) {
      const res = resDoc.data();
      const expMs = res.expiresAt ? new Date(res.expiresAt).getTime() : 0;
      if (expMs <= nowMs) continue;
      activeQtyTotal += res.quantity || 0;
      if (resDoc.id === listingId) {
        currentQtyForListing = res.quantity || 0;
      }
    }
    const wouldAddQty = Math.max(0, newQuantity - currentQtyForListing);
    if (activeQtyTotal + wouldAddQty > MAX_RESERVED_CARDS_PER_USER) {
      throw new HttpsError(
        "resource-exhausted",
        `Total cart card limit reached (${MAX_RESERVED_CARDS_PER_USER}). Remove some items before adding more.`,
      );
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + CART_RESERVATION_TTL_MS);

    await db.runTransaction(async (tx) => {
      const resDoc = await tx.get(reservationRef);
      if (!resDoc.exists) throw new HttpsError("not-found", "No reservation found");

      const currentQty = resDoc.data().quantity || 0;
      const diff = newQuantity - currentQty;

      if (diff !== 0) {
        const listingDoc = await tx.get(listingRef);
        if (!listingDoc.exists) throw new HttpsError("not-found", "Listing not found");

        if (diff > 0) {
          const available = (listingDoc.data().quantity || 0) - (listingDoc.data().reservedQty || 0);
          if (available < diff) {
            throw new HttpsError("failed-precondition", `Only ${available + currentQty} available`);
          }
        }

        tx.update(listingRef, {
          reservedQty: admin.firestore.FieldValue.increment(diff),
        });
      }

      tx.update(reservationRef, {
        quantity: newQuantity,
        expiresAt: expiresAt.toISOString(), // Refresh timer on update
      });
    });

    return { success: true, expiresAt: expiresAt.toISOString() };
  }
);

/**
 * Firestore-Trigger: enforce daily listing-creation rate limit.
 *
 * Hintergrund (Security-Audit Round 7 / Pen-Test, 2026-04-29):
 * Listings werden direct via Flutter `.add()` geschrieben (kein CF-wrapper)
 * → existierender CF-side `enforceRateLimit`-Helper greift NICHT.
 * Mass-Listing-Spam-Vektor (OWASP API #4 Unrestricted Resource Consumption
 * + API #6 Sensitive Business Flow): authenticated User koennte 10000
 * Listings/h erstellen → Marketplace-Pollution + Firestore-Quota-Burn.
 *
 * Reactive-Defense: dieser Trigger zaehlt Listings/User/Tag in
 * `rateLimits/{uid}.listingCreate`. Bei Ueberschreitung des Daily-Cap
 * wird das Listing nicht geblockt (Firestore-Rule liess es schon durch),
 * aber `status: 'flagged_spam'` gesetzt — Marketplace-Queries filtern
 * auf `status == 'active'`, also wird Spam unsichtbar.
 *
 * Threshold: 100 Listings/Tag/User. Real-world Power-Seller bulk-importiert
 * vielleicht 200-500 auf einmal — die ersten 100 gehen durch, der Rest
 * landet flagged. Admin kann unflaggen via direct Firestore-Edit.
 *
 * Idempotent — Counter ist statistisch eventually-consistent (paralleler
 * Race-Window kann Cap um +1-2 ueberschreiten, akzeptabel).
 */
const LISTINGS_PER_DAY_CAP = 100;
const LISTINGS_PER_HOUR_CAP = 20; // Round 9 Red-Team-Audit anti-burst

exports.enforceListingSpamLimit = onDocumentCreated(
  {
    document: `artifacts/${APP_ID}/listings/{listingId}`,
    region: "europe-west1",
    timeoutSeconds: 15,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const listing = snap.data();
    const sellerId = listing.sellerId;
    if (!sellerId) return;

    const today = new Date().toISOString().slice(0, 10);
    const rateRef = db.collection("artifacts").doc(APP_ID)
      .collection("rateLimits").doc(sellerId);

    try {
      const rateSnap = await rateRef.get();
      const data = rateSnap.exists ? rateSnap.data() : {};
      const entry = data.listingCreate || {};
      const todayCount = entry.date === today ? (entry.count || 0) : 0;
      const newCount = todayCount + 1;

      // Round 9 Red-Team-Audit: Hourly-Burst-Defense.
      // 100/Tag erlaubt sonst 100 Listings in 5 Minuten.
      const hourlyEntry = data.listingCreateHourly || {};
      const hourlyEvents = Array.isArray(hourlyEntry.events) ? hourlyEntry.events : [];
      const oneHourAgo = Date.now() - 60 * 60 * 1000;
      const recentEvents = hourlyEvents.filter((ts) => ts >= oneHourAgo);
      recentEvents.push(Date.now());
      const trimmedEvents = recentEvents.slice(-Math.max(LISTINGS_PER_HOUR_CAP * 2, 50));

      await rateRef.set({
        listingCreate: { date: today, count: newCount },
        listingCreateHourly: { events: trimmedEvents },
      }, { merge: true });

      const exceedsHourly = recentEvents.length > LISTINGS_PER_HOUR_CAP;

      // Pre-Release-Cap (Round 10 Insider-Fraudster-Audit, 2026-04-29):
      // Strategie 3 — Pre-Release-Mass-Scam. Neuer Seller kann 100×
      // Pre-Release-Karten listen, alle Buyer pre-ordern lassen, beim
      // Release-Day capture × 100 → vanish bevor delay_days-Auszahlung.
      // = €5000+ Beute pro Set-Release.
      // Defense: account-age-based Pre-Release-Limit.
      let exceedsPreRelease = false;
      let preReleaseReason = null;
      if (listing.preReleaseDate) {
        const ageDays = await getAccountAgeDays(sellerId);
        // Daily Pre-Release-Listing-Cap nach Account-Age:
        //   <7d  : max 5 Pre-Release-Listings/Tag
        //   7-30d: max 25 Pre-Release-Listings/Tag
        //   >30d : max 100 (= regular daily cap)
        let preReleaseCap;
        if (ageDays < 7) preReleaseCap = 5;
        else if (ageDays < 30) preReleaseCap = 25;
        else preReleaseCap = 100;

        // Count today's pre-release-listings for this seller
        const preReleaseEntry = data.preReleaseListingCreate || {};
        const preReleaseTodayCount = preReleaseEntry.date === today
          ? (preReleaseEntry.count || 0)
          : 0;
        const preReleaseNewCount = preReleaseTodayCount + 1;

        await rateRef.set({
          preReleaseListingCreate: {
            date: today,
            count: preReleaseNewCount,
          },
        }, { merge: true });

        if (preReleaseNewCount > preReleaseCap) {
          exceedsPreRelease = true;
          preReleaseReason =
            `pre_release_cap age=${ageDays}d ` +
            `(${preReleaseNewCount}/${preReleaseCap})`;
        }
      }

      if (newCount > LISTINGS_PER_DAY_CAP || exceedsHourly || exceedsPreRelease) {
        await snap.ref.update({
          status: "flagged_spam",
          flaggedReason: exceedsPreRelease
            ? "pre_release_cap_exceeded"
            : "rate_limit_exceeded",
          flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const reason = exceedsPreRelease
          ? preReleaseReason
          : (exceedsHourly
              ? `hourly_burst (${recentEvents.length}/${LISTINGS_PER_HOUR_CAP})`
              : `daily_cap (${newCount}/${LISTINGS_PER_DAY_CAP})`);
        console.warn(
          `enforceListingSpamLimit: seller ${sellerId} ${reason}, ` +
          `listing ${snap.id} marked flagged_spam`,
        );
        try {
          sendAdminAlert(
            exceedsPreRelease ? "PRE_RELEASE_SCAM" : "LISTING_SPAM",
            `Seller ${sellerId} ${reason}. Listing ${snap.id} flagged.`,
          );
        } catch (alertErr) {
          console.error(`Admin-Alert send failed: ${alertErr.message}`);
        }
      }
    } catch (err) {
      console.error(
        `enforceListingSpamLimit: ${snap.id} failed: ${err.message}`,
      );
    }
  },
);

/**
 * Firestore-Trigger: populiert sellerRating + sellerSales auf jedem neuen
 * Listing aus dem `sellerProfile`-Doc (server-trusted source).
 *
 * Hintergrund (Security-Audit Round 4, 2026-04-29):
 * Pre-Round-4 hat der Flutter-Client diese Felder beim Listing-Erstellen
 * mitgeschickt — Self-Stats-Fraud-Vektor (Seller decompiled App, schreibt
 * fake `sellerRating: 5.0, sellerSales: 999`). Firestore-Rules blocken
 * jetzt Client-Writes mit non-zero Werten. Dieser Trigger laedt die
 * authentischen Werte aus sellerProfile (CF-managed) und schreibt sie
 * via Admin-SDK (umgeht Rules) ins Listing.
 *
 * Idempotent — wenn die Werte schon gesetzt sind (z.B. bei Doc-Replay
 * durch GCP), no-op.
 *
 * Latency: ~1-2s zwischen Listing-Create und Trigger-Run. UI sollte
 * `sellerSales: 0` als „New seller" rendern, nicht als „0 Sales".
 */
exports.populateListingSellerStats = onDocumentCreated(
  {
    document: `artifacts/${APP_ID}/listings/{listingId}`,
    region: "europe-west1",
    timeoutSeconds: 30,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const listing = snap.data();
    const sellerId = listing.sellerId;
    if (!sellerId) {
      console.warn(`populateListingSellerStats: ${snap.id} has no sellerId`);
      return;
    }

    // Read trusted sellerProfile + playerProfile mirror.
    // sellerProfile.rating / totalSales sind die Source-of-Truth (CF-managed,
    // wird bei submitReview / confirmDelivery upgedatet).
    try {
      const sellerProfileRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(sellerId)
        .collection("data").doc("sellerProfile");
      const sellerDoc = await sellerProfileRef.get();
      if (!sellerDoc.exists) {
        console.log(
          `populateListingSellerStats: ${snap.id} seller=${sellerId} ` +
          `has no sellerProfile yet — leaving stats at 0`,
        );
        return;
      }
      const seller = sellerDoc.data();
      const sellerRating = (typeof seller.rating === "number") ? seller.rating : 0;
      const sellerSales = (typeof seller.totalSales === "number") ? seller.totalSales : 0;

      if (sellerRating === 0 && sellerSales === 0) {
        // Nichts zu tun — User ist tatsaechlich ein neuer Seller.
        return;
      }

      await snap.ref.update({
        sellerRating,
        sellerSales,
      });
      console.log(
        `populateListingSellerStats: ${snap.id} populated rating=${sellerRating}, sales=${sellerSales}`,
      );
    } catch (err) {
      console.error(
        `populateListingSellerStats: ${snap.id} failed: ${err.message}`,
      );
    }
  },
);

/**
 * Clean up expired cart reservations (runs every 5 minutes).
 */
exports.cleanExpiredReservations = onSchedule(
  { schedule: "every 5 minutes", region: "us-central1", timeoutSeconds: 120 },
  async () => {
    const now = new Date().toISOString();
    const expiredSnap = await db.collectionGroup("cartReservations")
      .where("expiresAt", "<", now)
      .get();

    if (expiredSnap.empty) {
      console.log("No expired reservations");
      return;
    }

    console.log(`Cleaning ${expiredSnap.size} expired reservations`);
    let cleaned = 0;

    for (const doc of expiredSnap.docs) {
      const data = doc.data();
      const listingId = data.listingId;
      const qty = data.quantity || 0;

      try {
        const listingRef = db.collection("artifacts").doc(APP_ID)
          .collection("listings").doc(listingId);

        await db.runTransaction(async (tx) => {
          const listingDoc = await tx.get(listingRef);
          if (listingDoc.exists) {
            const currentReserved = listingDoc.data().reservedQty || 0;
            tx.update(listingRef, {
              reservedQty: Math.max(0, currentReserved - qty),
            });
          }
          tx.delete(doc.ref);
        });
        cleaned++;
      } catch (e) {
        console.error(`Failed to clean reservation ${doc.id}: ${e.message}`);
      }
    }

    console.log(`Cleaned ${cleaned}/${expiredSnap.size} expired reservations`);
  }
);

// ═══════════════════════════════════════════════════════════════════
// ─── Tournament Auto-Discovery ───
// ═══════════════════════════════════════════════════════════════════
//
// Pulls Riot's official "Eyes on <City> – What to Know" announcement
// posts and writes one `meta_tournament_schedule` doc per discovered
// tournament. The existing `checkNewTournamentDecks` cron then picks
// those docs up, scrapes the corresponding `/organizedplay/<slug>/`
// decklist post (when Riot publishes it post-event), and imports the
// decks into `meta_decks`.
//
// Why announcements (not /organizedplay/)?
//   /organizedplay/ posts appear AFTER the event with the decklists.
//   /announcements/ "Eyes on X" posts appear BEFORE the event and are
//   the only reliable signal that tells us "tournament X happens on
//   date Y in city Z" — enough to seed a schedule doc whose decklist
//   slug we predict (top-decks / best-decks / etc — multiple tries).
//
// Architecture:
//   discoverTournamentsFromRiot           — daily 07:30 UTC, scheduled
//   discoverTournamentsFromRiotManual     — HTTP, manual trigger
//   backfillTournamentsFromRiot           — HTTP, one-time deploy backfill
//
// Dedup: Doc-ID = announcement slug. Idempotent — running daily is safe.
// ═══════════════════════════════════════════════════════════════════

const RIOT_BASE = "https://riftbound.leagueoflegends.com";
const RIOT_USER_AGENT = "Riftstats-Discovery/1.0 (+https://riftr.app)";
const ANNOUNCEMENTS_INDEX = `${RIOT_BASE}/en-us/news/announcements/`;
const UPCOMING_EVENTS_PAGE =
  `${RIOT_BASE}/en-us/news/announcements/riftbounds-upcoming-official-events/`;
// Slug pattern Riot uses consistently for pre-event posts:
// "eyes-on-lille-what-to-know", "eyes-on-atlanta-what-to-know" etc.
const ANNOUNCEMENT_SLUG_REGEX = /^eyes-on-[a-z0-9-]+-what-to-know$/i;
// Mobalytics fallback URL for slug-hint lookup. Used when a schedule
// doc has been pending >30 days without any decklist hit.
const MOBALYTICS_TOURNAMENTS = "https://mobalytics.gg/riftbound/tournaments";

/**
 * Fetch a URL with retries on transient failure (timeouts, 5xx).
 * Throws after retries exhausted. We don't currently alert externally —
 * just log loudly so the daily run surfaces in Cloud Logging.
 */
// SSRF-Hardening (Round 11.2 / BACKLOG #102, 2026-04-29):
// Whitelist von Hosts die fetchWithRetries ueberhaupt anhauen darf.
// Verhindert SSRF wenn ein parsed-Slug oder eine konstruierte URL auf
// ein malicious Host zeigt — z.B. "http://metadata.google.internal/"
// (GCP-Internal-Metadata) oder "http://localhost:8080".
//
// Kontext: alle URLs die wir fetchen werden aus Konstanten + parsed
// HTML-Content gebaut. Slug-Regex filtert schon (`[a-z0-9-]+` only),
// aber defense-in-depth: zusaetzlich Hostname-Whitelist enforced.
const FETCH_HOST_WHITELIST = new Set([
  // Riot/Riftbound — Tournament-Discovery
  "riftbound.leagueoflegends.com",
  "www.riftbound.leagueoflegends.com",
  "lolesports.com",
  "www.lolesports.com",
  // Mobalytics — Tournament-Discovery
  "mobalytics.gg",
  "www.mobalytics.gg",
  // Riftcodex — Card-Data-Sync
  "api.riftcodex.com",
  // Cardmarket — Price-Guide-Sync
  "downloads.s3.cardmarket.com",
  "s3.cardmarket.com",
]);

async function fetchWithRetries(url, { retries = 3, timeoutMs = 15000 } = {}) {
  // Hostname-Validation — defense-in-depth gegen SSRF.
  // Auch wenn HTML-Parsing-Bugs malicious Slugs durchlassen, koennen
  // wir nie auf etwas anderes als Whitelist-Hosts treffen.
  let parsedUrl;
  try {
    parsedUrl = new URL(url);
  } catch (_) {
    throw new Error(`fetchWithRetries: invalid URL ${url}`);
  }
  if (parsedUrl.protocol !== "https:" && parsedUrl.protocol !== "http:") {
    throw new Error(
      `fetchWithRetries: refusing non-http(s) protocol ${parsedUrl.protocol} (${url})`,
    );
  }
  if (!FETCH_HOST_WHITELIST.has(parsedUrl.hostname)) {
    throw new Error(
      `fetchWithRetries: host ${parsedUrl.hostname} not in whitelist (${url})`,
    );
  }

  let lastErr;
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const ctrl = new AbortController();
      const timer = setTimeout(() => ctrl.abort(), timeoutMs);
      const res = await fetch(url, {
        headers: { "User-Agent": RIOT_USER_AGENT, Accept: "text/html" },
        signal: ctrl.signal,
      });
      clearTimeout(timer);
      if (!res.ok) {
        throw new Error(`HTTP ${res.status} for ${url}`);
      }
      return await res.text();
    } catch (e) {
      lastErr = e;
      console.warn(`[Discovery] fetch attempt ${attempt}/${retries} failed for ${url}: ${e.message}`);
      if (attempt < retries) {
        // Backoff: 1s, 2s, 4s
        await new Promise(r => setTimeout(r, 1000 * Math.pow(2, attempt - 1)));
      }
    }
  }
  throw lastErr;
}

/**
 * Extract every announcement-slug + best-effort title from the news
 * index HTML. Server-rendered, so we just regex over the article links.
 *
 * Returns [{ slug, title }] — title may be empty when Riot's markup
 * places it outside the <a>; the article-page fetcher fills it in.
 */
function parseAnnouncementIndex(html) {
  const found = new Map();
  const linkRe =
    /<a[^>]+href="\/en-us\/news\/announcements\/([a-z0-9-]+)\/?"[^>]*>([\s\S]*?)<\/a>/gi;
  let m;
  while ((m = linkRe.exec(html)) !== null) {
    const slug = m[1].toLowerCase();
    if (!ANNOUNCEMENT_SLUG_REGEX.test(slug)) continue;
    // Strip nested HTML from the link content to get a rough title.
    const innerText = m[2]
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    if (!found.has(slug) || (!found.get(slug).title && innerText)) {
      found.set(slug, { slug, title: innerText });
    }
  }
  return [...found.values()];
}

/**
 * Parse a single "Eyes on <City>" article body to extract:
 *   - city            (from title or H1)
 *   - eventDate       (ISO yyyy-mm-dd, START of event)
 *   - eventEndDate    (ISO, optional — multi-day events)
 *
 * Heuristics — Riot's body prose is pretty consistent but not perfectly
 * structured. We try several patterns and fall back to null when none
 * match. The outer caller skips schedule-doc creation when we can't
 * derive an eventDate (better to skip than queue garbage).
 */
function parseAnnouncementArticle(html, slug) {
  // Title — prefer <h1>, fall back to <title>, fall back to slug.
  let title =
    (html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i)?.[1] || "")
      .replace(/<[^>]+>/g, "")
      .replace(/\s+/g, " ")
      .trim() ||
    (html.match(/<title>([\s\S]*?)<\/title>/i)?.[1] || "")
      .replace(/\s*\|.*$/, "")
      .trim();
  if (!title) {
    // Last resort: humanise the slug.
    title = slug.replace(/-/g, " ");
  }

  // City — "Eyes on <City> –" or "Eyes on <City>:" patterns.
  let city = "";
  const cityMatch =
    title.match(/Eyes\s+on\s+([A-Z][\w\s'-]+?)\s*[–:\-—]/i) ||
    title.match(/Eyes\s+on\s+([A-Z][\w\s'-]+?)\s*$/i) ||
    slug.match(/^eyes-on-([a-z0-9-]+?)-what-to-know$/i);
  if (cityMatch) {
    city = cityMatch[1]
      .replace(/-/g, " ")
      .replace(/\s+/g, " ")
      .trim()
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }

  // Event-date extraction.
  // Riot's prose looks like:
  //   "join us April 17th-19th at Lille Grand Palais"
  //   "Atlanta, GA on April 24-26"
  //   "in Bologna May 9-11, 2026"
  // — i.e. ordinals (17th/19th), optional year, day-ranges as the
  //  primary signal. Plain regex for single dates would also match
  //  filler dates like "Effective March 31, 2026, four cards..." (the
  //  bans note in the Lille article), so we PREFER date-ranges and
  //  fall back to single dates only when no range exists.
  //
  // Year fallback: the announcement publish-date is in the JSON-LD
  // (datePublished) or near the title. We grab any 20XX year on the
  // page and use it when the inline date omits the year.
  const text = html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ");

  const months = {
    january: 1, february: 2, march: 3, april: 4, may: 5, june: 6,
    july: 7, august: 8, september: 9, october: 10, november: 11, december: 12,
  };
  const monthAlt = "(?:January|February|March|April|May|June|July|August|September|October|November|December)";
  // Accepts ordinals (17th/1st/22nd) and plain digits.
  const dayPart = "(\\d{1,2})(?:st|nd|rd|th)?";

  // Year fallback: take the article's earliest 20XX occurrence (publish
  // year sits at the very top of the body).
  const fallbackYearMatch = text.match(/\b(20\d{2})\b/);
  const fallbackYear = fallbackYearMatch ? parseInt(fallbackYearMatch[1]) : new Date().getFullYear();

  let eventDate = null;
  let eventEndDate = null;

  // Pass 1 — date ranges (highest signal): "April 17th-19th[, 2026]"
  // "April 17 – April 19, 2026"
  const rangeRe = new RegExp(
    `\\b${monthAlt}\\s+${dayPart}\\s*[–\\-]\\s*(?:${monthAlt}\\s+)?${dayPart}(?:\\s*,?\\s*(\\d{4}))?`,
    "i",
  );
  const rm = text.match(rangeRe);
  if (rm) {
    const month = months[rm[0].match(new RegExp(monthAlt, "i"))[0].toLowerCase()];
    const day = parseInt(rm[1]);
    const endDay = parseInt(rm[2]);
    const year = rm[3] ? parseInt(rm[3]) : fallbackYear;
    const pad = (n) => String(n).padStart(2, "0");
    eventDate = `${year}-${pad(month)}-${pad(day)}`;
    if (endDay > day) eventEndDate = `${year}-${pad(month)}-${pad(endDay)}`;
  } else {
    // Pass 2 — single date with explicit year: "April 24, 2026". Skip
    // the first match if it's preceded by "Effective" or "Effective:"
    // (bans-announcement filler that occasionally appears before the
    // event date).
    const singleRe = new RegExp(
      `\\b${monthAlt}\\s+${dayPart}\\s*,\\s*(\\d{4})`,
      "gi",
    );
    let dm;
    while ((dm = singleRe.exec(text)) !== null) {
      const ctxStart = Math.max(0, dm.index - 30);
      const ctx = text.substring(ctxStart, dm.index).toLowerCase();
      if (/\b(effective|since|starting|deadline)\b/.test(ctx)) continue;
      const month = months[dm[0].match(new RegExp(monthAlt, "i"))[0].toLowerCase()];
      const day = parseInt(dm[1]);
      const year = parseInt(dm[2]);
      const pad = (n) => String(n).padStart(2, "0");
      eventDate = `${year}-${pad(month)}-${pad(day)}`;
      break;
    }
  }

  return { city, title, eventDate, eventEndDate };
}

/**
 * Generate decklist-slug candidates for a city. Riot has used multiple
 * naming conventions across events:
 *   - vegas-top-decks                   (Vegas)
 *   - lilles-top-decks                  (Lille — note the trailing "s")
 *   - the-best-decks-out-of-bologna     (Bologna)
 * No single regex predicts all three, so we generate every plausible
 * slug and the existing `checkNewTournamentDecks` cron probes them all.
 */
function buildSlugCandidates(city) {
  const lower = city.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, "");
  if (!lower) return [];
  return [
    `${lower}-top-decks`,
    `${lower}s-top-decks`,
    `the-best-decks-out-of-${lower}`,
    `best-decks-${lower}`,
    `${lower}-decklists`,
    `${lower}-results`,
  ];
}

/**
 * Build a tournament-name from city + slug. Convention used by existing
 * meta_decks: "Vegas Regional Qualifier", "Bologna Regional Qualifier".
 * We can't always tell whether an event is RQ vs Open vs City Challenge
 * just from the announcement, so we default to "Regional Qualifier" —
 * the manual operator can edit the doc if a specific event differs.
 */
function tournamentNameFor(city) {
  return city ? `${city} Regional Qualifier` : "";
}

/**
 * Core discovery pass. Lists the announcements index, filters Eyes-on
 * slugs, fetches each article body for date+city, and writes any new
 * docs to `meta_tournament_schedule`. Returns a summary object.
 *
 * Idempotent: doc.id == slug → existing docs are skipped untouched.
 */
async function runDiscoveryPass({ source = "scheduled" } = {}) {
  const indexHtml = await fetchWithRetries(ANNOUNCEMENTS_INDEX);
  const candidates = parseAnnouncementIndex(indexHtml);
  console.log(`[Discovery] index: ${candidates.length} eyes-on slugs found`);

  if (candidates.length === 0) {
    // Schema change suspected — Riot may have changed the slug naming
    // or the listing's HTML markup. Don't crash; just loudly warn so
    // the daily log surfaces it.
    console.warn(
      "[Discovery] WARNING: 0 eyes-on slugs matched. " +
      "Possible Riot schema change — check ANNOUNCEMENT_SLUG_REGEX or markup."
    );
  }

  const scheduleRef = db.collection("artifacts").doc(APP_ID)
    .collection("meta_tournament_schedule");

  const created = [];
  const skipped = [];
  const failed = [];

  for (const { slug, title: indexTitle } of candidates) {
    try {
      const docRef = scheduleRef.doc(slug);
      const existing = await docRef.get();
      if (existing.exists) {
        skipped.push(slug);
        continue;
      }

      // Fetch the article body to extract city + eventDate.
      const articleUrl = `${RIOT_BASE}/en-us/news/announcements/${slug}/`;
      const articleHtml = await fetchWithRetries(articleUrl);
      const parsed = parseAnnouncementArticle(articleHtml, slug);

      if (!parsed.eventDate) {
        // Body parser couldn't find a date. Don't queue garbage —
        // skip and log; manual operator can address if it persists.
        console.warn(
          `[Discovery] no eventDate parsed for ${slug} (title="${parsed.title}") — skipping`
        );
        failed.push({ slug, reason: "no eventDate parsed" });
        continue;
      }

      const city = parsed.city || indexTitle.replace(/^Eyes on\s+/i, "").split(/[–:\-—]/)[0].trim();
      const slugCandidates = buildSlugCandidates(city);

      await docRef.set({
        name: tournamentNameFor(city),
        eventDate: parsed.eventDate,
        eventEndDate: parsed.eventEndDate || null,
        urlSlugs: slugCandidates,
        imported: false,
        sourceSlug: slug,
        sourceUrl: articleUrl,
        sourceTitle: parsed.title,
        city,
        discoveredAt: admin.firestore.FieldValue.serverTimestamp(),
        discoverySource: source,
        // Schema-erweitert für multi-source: "riot" (default) | "mobalytics".
        // Decklist-Cron branched darauf — Riot benutzt Puppeteer + die
        // urlSlugs[]-Probe gegen /organizedplay/, Mobalytics benutzt
        // direkten Fetch der Tournament-Page + Deck-Subpages.
        sourcePlatform: "riot",
      });

      created.push({ slug, city, eventDate: parsed.eventDate });
      console.log(
        `[Discovery] CREATED ${slug} → ${city} on ${parsed.eventDate} ` +
        `(slugs: ${slugCandidates.join(", ")})`
      );
    } catch (e) {
      failed.push({ slug, reason: e.message });
      console.error(`[Discovery] failed ${slug}: ${e.message}`);
    }
  }

  // 30-day Mobalytics fallback: for any pending schedule doc whose
  // discoveredAt is >30 days old AND that's still imported:false, fetch
  // Mobalytics' tournaments index and append any matching slug-hints
  // to the urlSlugs array. Best-effort — Mobalytics pull failure
  // doesn't fail the discovery pass.
  let fallbackEnriched = 0;
  try {
    fallbackEnriched = await augmentStaleWithMobalytics(scheduleRef);
  } catch (e) {
    console.warn(`[Discovery] Mobalytics fallback skipped: ${e.message}`);
  }

  const summary = {
    candidatesFound: candidates.length,
    created: created.length,
    skipped: skipped.length,
    failed: failed.length,
    mobalyticsEnriched: fallbackEnriched,
    detail: { created, failed },
  };
  console.log(`[Discovery] DONE: ${JSON.stringify(summary, null, 2)}`);
  return summary;
}

/**
 * For schedule docs older than 30 days that still haven't been imported,
 * try to find a slug-hint on Mobalytics' tournaments page and append it
 * to the doc's urlSlugs array so the next decklist-cron has another
 * shot. Returns count of docs enriched.
 *
 * Note: this is a heuristic. Mobalytics's slugs (`vegas-regional-qualifier`)
 * are NOT Riot organizedplay-slugs — but the existing decklist scraper
 * tries each candidate against Riot's `/organizedplay/<slug>/` URL, so
 * a Mobalytics-style slug rarely hits. Real value: if Mobalytics has
 * a "Riot top-decks link" in the tournament page, we surface that.
 *
 * Conservative implementation: just scrape Mobalytics's tournament
 * names and try slug-variants derived from them. Future improvement:
 * fetch each Mobalytics tournament page to grab the embedded Riot URL.
 */
async function augmentStaleWithMobalytics(scheduleRef) {
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const stale = await scheduleRef
    .where("imported", "==", false)
    .get();

  const candidates = stale.docs.filter((d) => {
    const data = d.data();
    const discoveredAt = data.discoveredAt?.toDate?.();
    return discoveredAt && discoveredAt < cutoff;
  });
  if (candidates.length === 0) return 0;

  let mobaHtml;
  try {
    mobaHtml = await fetchWithRetries(MOBALYTICS_TOURNAMENTS, { retries: 2 });
  } catch (e) {
    console.warn(`[Discovery] Mobalytics fetch failed: ${e.message}`);
    return 0;
  }

  // Extract Mobalytics tournament slugs — pattern:
  // /riftbound/tournaments/<slug>
  const mobaSlugs = new Set();
  const slugRe = /\/riftbound\/tournaments\/([a-z0-9-]+)/gi;
  let m;
  while ((m = slugRe.exec(mobaHtml)) !== null) {
    if (m[1] !== "tournaments") mobaSlugs.add(m[1].toLowerCase());
  }

  let enriched = 0;
  for (const doc of candidates) {
    const data = doc.data();
    const city = (data.city || "").toLowerCase();
    if (!city) continue;
    // Find any Mobalytics slug containing the city name.
    const cityKey = city.replace(/\s+/g, "-");
    const matched = [...mobaSlugs].filter((s) => s.includes(cityKey));
    if (matched.length === 0) continue;

    // Append novel candidates to urlSlugs.
    const existingSlugs = new Set(data.urlSlugs || []);
    const additions = matched.filter((s) => !existingSlugs.has(s));
    if (additions.length === 0) continue;

    await doc.ref.update({
      urlSlugs: [...(data.urlSlugs || []), ...additions],
      mobalyticsEnrichedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    enriched++;
    console.log(`[Discovery] Mobalytics-enriched ${doc.id} with ${JSON.stringify(additions)}`);
  }
  return enriched;
}

/**
 * Scheduled discovery — daily 07:30 UTC, 30 minutes before the
 * decklist scraper (08:00) so newly-discovered docs are in the queue
 * by the time the importer runs.
 */
exports.discoverTournamentsFromRiot = onSchedule(
  {
    schedule: "30 7 * * *",
    timeZone: "UTC",
    timeoutSeconds: 300,
    memory: "512MiB",
    region: "us-central1",
  },
  async () => {
    await runDiscoveryPass({ source: "scheduled" });
  }
);

/**
 * Manual trigger for tests / first-deploy verification.
 * Returns the same summary object as the scheduled run.
 */
exports.discoverTournamentsFromRiotManual = onRequest(
  { timeoutSeconds: 300, memory: "512MiB", region: "us-central1", secrets: ["ADMIN_TRIGGER_SECRET"] },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    try {
      const summary = await runDiscoveryPass({ source: "manual" });
      res.json({ success: true, ...summary });
    } catch (e) {
      console.error(`[Discovery] manual trigger failed: ${e.stack || e.message}`);
      res.status(500).json({ error: e.message });
    }
  }
);

/**
 * One-time backfill — pulls the curated `riftbounds-upcoming-official-events`
 * page in addition to the regular announcements index. The page lists
 * past + upcoming events Riot endorses; we walk every link that looks
 * like an Eyes-on post and run them through the same discovery
 * pipeline. Idempotent (Doc-ID = slug), safe to re-run.
 *
 * Triggered manually after deploy:
 *   curl https://us-central1-riftr-10527.cloudfunctions.net/backfillTournamentsFromRiot
 */
exports.backfillTournamentsFromRiot = onRequest(
  { timeoutSeconds: 540, memory: "512MiB", region: "us-central1", secrets: ["ADMIN_TRIGGER_SECRET"] },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    try {
      // Run the standard discovery first (current /announcements/ index).
      const live = await runDiscoveryPass({ source: "backfill-live" });

      // Then crawl the curated upcoming-events page for older
      // tournaments not on the front of the index anymore.
      const curatedHtml = await fetchWithRetries(UPCOMING_EVENTS_PAGE);
      const curated = parseAnnouncementIndex(curatedHtml);
      console.log(`[Backfill] curated page: ${curated.length} eyes-on slugs found`);

      const scheduleRef = db.collection("artifacts").doc(APP_ID)
        .collection("meta_tournament_schedule");

      const created = [];
      const skipped = [];
      const failed = [];
      for (const { slug } of curated) {
        try {
          const docRef = scheduleRef.doc(slug);
          if ((await docRef.get()).exists) {
            skipped.push(slug);
            continue;
          }
          const articleHtml = await fetchWithRetries(
            `${RIOT_BASE}/en-us/news/announcements/${slug}/`
          );
          const parsed = parseAnnouncementArticle(articleHtml, slug);
          if (!parsed.eventDate) {
            failed.push({ slug, reason: "no eventDate parsed" });
            continue;
          }
          const city = parsed.city ||
            slug.match(/^eyes-on-([a-z0-9-]+?)-what-to-know$/i)?.[1] || "";
          await docRef.set({
            name: tournamentNameFor(city),
            eventDate: parsed.eventDate,
            eventEndDate: parsed.eventEndDate || null,
            urlSlugs: buildSlugCandidates(city),
            imported: false,
            sourceSlug: slug,
            sourceUrl: `${RIOT_BASE}/en-us/news/announcements/${slug}/`,
            sourceTitle: parsed.title,
            city,
            discoveredAt: admin.firestore.FieldValue.serverTimestamp(),
            discoverySource: "backfill-curated",
            sourcePlatform: "riot",
          });
          created.push({ slug, city, eventDate: parsed.eventDate });
        } catch (e) {
          failed.push({ slug, reason: e.message });
        }
      }

      const total = {
        live,
        curated: {
          candidatesFound: curated.length,
          created: created.length,
          skipped: skipped.length,
          failed: failed.length,
          detail: { created, failed },
        },
      };
      console.log(`[Backfill] DONE: ${JSON.stringify(total, null, 2)}`);
      res.json({ success: true, ...total });
    } catch (e) {
      console.error(`[Backfill] failed: ${e.stack || e.message}`);
      res.status(500).json({ error: e.message });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════
// ─── Mobalytics Tournament Discovery + Decklist Import ───
// ═══════════════════════════════════════════════════════════════════
//
// Second discovery source covering Asia-region tournaments (S2/S3
// Regional Opens in Fuzhou, Chengdu, Dalian, Nanjing, Shenzhen) which
// Riot's English /announcements/ page doesn't cover. Mobalytics is
// server-rendered (no Puppeteer needed) and exposes:
//   /riftbound/tournaments/<slug>            ← index per tournament
//   /riftbound/decks/<deck-slug>             ← per-pilot decklist
//
// Slug schema (deterministic — we can probe known patterns):
//   s<season>-regional-open-<city>           e.g. s2-regional-open-fuzhou
//   s<season>-<city>-national-open           e.g. s2-shenzhen-national-open
//   <city>-regional-qualifier                e.g. lille-regional-qualifier
//
// Riot-wins dedup: if a Mobalytics tournament's city already has a
// Riot schedule doc (case-insensitive), Mobalytics's doc is skipped.
// First-party data (Riot) trumps aggregator data (Mobalytics).
//
// Champion extraction: 3-stage heuristic (prefix → last-word → first
// qty=1). Decks where ALL three stages fail are NOT imported — they
// land in failed_champion_extraction[] for manual inspection. Riftbound
// format requires exactly one Champion per deck, so a missing Champion
// is treated as a parser bug, not an edge case.
// ═══════════════════════════════════════════════════════════════════

const MOBALYTICS_BASE = "https://mobalytics.gg";
const MOBALYTICS_INDEX = `${MOBALYTICS_BASE}/riftbound/tournaments`;
const MOBALYTICS_USER_AGENT = "Riftstats-Discovery/1.0 (+https://riftr.app)";
// Asia cities we've seen on Mobalytics S2. Used as a deterministic probe
// list when the index page doesn't surface them at top. S1 cities
// (Beijing/Hangzhou/Guangzhou/Chongqing) are kept manual — verified via
// 12 slug-variants all returning 404.
const MOBALYTICS_PROBE_CITIES = [
  "fuzhou", "chengdu", "dalian", "nanjing",
  "shenzhen",
];
const MOBALYTICS_PROBE_SEASONS = [2, 3];

/**
 * Decode HTML entities in a string. Lightweight — only the entities
 * we've observed Mobalytics emit (`&#x27;` for apostrophe, `&amp;`,
 * named ASCII entities). Riftbound card names are otherwise plain ASCII
 * + Unicode pass-through, so this list is complete enough.
 */
function decodeHtmlEntities(s) {
  if (!s) return s;
  return s
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCharCode(parseInt(dec, 10)))
    .replace(/&amp;/g, "&")
    .replace(/&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ");
}

function stripCollectorSuffix(s) {
  return s.replace(/\s*\(\d+\)\s*$/, "").trim();
}

function properCase(s) {
  if (!s) return "";
  return s.split(/[\s-]+/).map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()).join(" ");
}

/**
 * Extract the city portion from a Mobalytics tournament-slug. Handles
 * all three slug patterns. Returns lowercase city name or fallback.
 */
function cityFromMobalyticsSlug(slug) {
  let m = slug.match(/^s\d+-regional-open-(.+)$/i);
  if (m) return m[1];
  m = slug.match(/^s\d+-(.+?)-national-open$/i);
  if (m) return m[1];
  m = slug.match(/^(.+?)-regional-qualifier$/i);
  if (m) return m[1];
  return slug.split(/-(regional|national|open|qualifier)/i)[0] || slug;
}

/**
 * Parse a Mobalytics deck-page (HTML string) into a normalised deck
 * object compatible with `buildMetaDeck`. Returns
 *   { ok: true, deck, championSource } or { ok: false, reason }.
 */
function parseMobalyticsDeckPage(html) {
  const titleMatch = html.match(/<h1[^>]*>([^<]+)<\/h1>/i);
  if (!titleMatch) return { ok: false, reason: "no <h1>" };
  const title = decodeHtmlEntities(titleMatch[1]);
  // "Best of" (with space) vs "Best-Of" (with hyphen) — Mobalytics uses
  // the hyphen variant; Riot uses the space variant. Accept both.
  const titleRe =
    /^(.+?):\s*(.+?)\s+(1st|2nd|3rd|Top \d+|Best[ -]Of)\s*\(([^)]+)\)\s*$/i;
  const tm = title.match(titleRe);
  if (!tm) return { ok: false, reason: `title regex failed: ${title}` };
  const legendFull = tm[1].trim();
  const tournament = tm[2].trim();
  let placement = tm[3];
  if (/^best[ -]of$/i.test(placement)) placement = "Best of";
  if (/^top\s+\d+$/i.test(placement)) placement = placement.replace(/^top/i, "Top");
  const player = tm[4].trim();

  const SECTION_LABELS = ["Legend", "Champion", "Main Deck", "Battlefields", "Rune Pool", "Runes", "Sideboard"];
  const sections = [];
  const labelRe =
    /<p[^>]*><span style="white-space: pre-wrap;">([^<]+)<\/span><\/p>/gi;
  let lm;
  while ((lm = labelRe.exec(html)) !== null) {
    const label = lm[1].trim();
    if (SECTION_LABELS.includes(label)) {
      sections.push({ pos: lm.index, label });
    }
  }
  sections.push({ pos: html.length, label: "__END__" });

  const sliceFor = (label) => {
    for (let i = 0; i < sections.length - 1; i++) {
      if (sections[i].label === label) {
        return html.substring(sections[i].pos, sections[i + 1].pos);
      }
    }
    return "";
  };

  const QTY_RE =
    /<span style="white-space: pre-wrap;">(\d+)\s*<\/span>[\s\S]*?<span class="xirccme xggjnk3">([^<]+)<\/span>/g;
  const BARE_RE = /<span class="xirccme xggjnk3">([^<]+)<\/span>/g;

  const cardsWithQty = (sectionHtml) => {
    const out = [];
    let m;
    QTY_RE.lastIndex = 0;
    while ((m = QTY_RE.exec(sectionHtml)) !== null) {
      const qty = parseInt(m[1], 10);
      const name = stripCollectorSuffix(decodeHtmlEntities(m[2]));
      out.push({ name, qty });
    }
    return out;
  };
  const bareNames = (sectionHtml) => {
    const out = [];
    let m;
    BARE_RE.lastIndex = 0;
    while ((m = BARE_RE.exec(sectionHtml)) !== null) {
      out.push(stripCollectorSuffix(decodeHtmlEntities(m[1])));
    }
    return out;
  };

  const mainList = cardsWithQty(sliceFor("Main Deck"));
  const runesList = cardsWithQty(sliceFor("Runes"));
  const runePoolList = runesList.length ? runesList : cardsWithQty(sliceFor("Rune Pool"));
  const sideList = cardsWithQty(sliceFor("Sideboard"));
  const battlefields = bareNames(sliceFor("Battlefields"));

  // 3-stage Champion heuristic. Riftbound format = exactly one Champion
  // per deck, so a null result is treated as a parser bug (caller rejects).
  const legendPrefix = legendFull.split(",")[0].trim();
  const legendLastWord = legendPrefix.split(/\s+/).pop() || "";

  let champion = null;
  let championSource = null;
  for (const c of mainList) {
    if (c.qty === 1 && c.name.startsWith(legendPrefix + ",")) {
      champion = c.name; championSource = "prefix-match"; break;
    }
  }
  if (!champion && legendLastWord && legendLastWord !== legendPrefix) {
    for (const c of mainList) {
      if (c.qty === 1 && c.name.startsWith(legendLastWord + ",")) {
        champion = c.name; championSource = "last-word-match"; break;
      }
    }
  }
  if (!champion) {
    for (const c of mainList) {
      if (c.qty === 1) {
        champion = c.name; championSource = "first-qty-1-fallback"; break;
      }
    }
  }
  if (!champion) {
    return { ok: false, reason: "champion-heuristic failed (no qty=1 in main deck)" };
  }

  const mainDeck = {};
  let dropped = false;
  for (const c of mainList) {
    if (!dropped && c.name === champion && c.qty === 1) {
      dropped = true;
      continue;
    }
    mainDeck[c.name] = (mainDeck[c.name] || 0) + c.qty;
  }
  const sideboard = {};
  for (const c of sideList) sideboard[c.name] = (sideboard[c.name] || 0) + c.qty;
  const runes = {};
  for (const c of runePoolList) runes[c.name] = (runes[c.name] || 0) + c.qty;

  // Synthetic `overall` for buildMetaDeck's ID-generation logic.
  // Actual placement we store on the doc comes from Mobalytics's title.
  let overall;
  if (placement === "1st") overall = 1;
  else if (placement === "2nd") overall = 2;
  else if (placement === "3rd") overall = 3;
  else if (placement === "Top 4") overall = 4;
  else if (/^Top \d+$/.test(placement)) overall = 5;
  else overall = 999;

  return {
    ok: true,
    deck: {
      player,
      legendRank: null,
      legendTotal: null,
      overall,
      legend: legendFull,
      champion,
      mainDeck,
      battlefields,
      runes,
      sideboard,
      _mobalyticsPlacement: placement,
      _mobalyticsTournament: tournament,
    },
    championSource,
  };
}

/**
 * Fetch a Mobalytics tournament page → list of deck-page slugs +
 * tournament metadata (name/city/date best-effort).
 */
async function fetchMobalyticsTournament(slug) {
  const url = `${MOBALYTICS_BASE}/riftbound/tournaments/${slug}`;
  const html = await fetchWithRetries(url, { retries: 3 });
  const deckSlugs = new Set();
  const re = /\/riftbound\/decks\/([a-z0-9-]+)/gi;
  let m;
  while ((m = re.exec(html)) !== null) deckSlugs.add(m[1]);

  const text = html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ");
  const dm = text.match(
    /\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2})(?:st|nd|rd|th)?\s*,\s*(\d{4})/i,
  );
  let date = null;
  if (dm) {
    const months = {
      january: 1, february: 2, march: 3, april: 4, may: 5, june: 6,
      july: 7, august: 8, september: 9, october: 10, november: 11, december: 12,
    };
    const month = months[dm[1].toLowerCase()];
    const day = parseInt(dm[2], 10);
    const year = parseInt(dm[3], 10);
    const pad = (n) => String(n).padStart(2, "0");
    date = `${year}-${pad(month)}-${pad(day)}`;
  }

  const h1Match = html.match(/<h1[^>]*>([^<]+)<\/h1>/i);
  const name = h1Match ? decodeHtmlEntities(h1Match[1]).trim() : "";
  const city = cityFromMobalyticsSlug(slug);

  return { url, slug, name, city, date, deckSlugs: [...deckSlugs] };
}

async function runMobalyticsDiscoveryPass({ source = "scheduled" } = {}) {
  const scheduleRef = db.collection("artifacts").doc(APP_ID)
    .collection("meta_tournament_schedule");

  const candidates = [];
  for (const season of MOBALYTICS_PROBE_SEASONS) {
    for (const city of MOBALYTICS_PROBE_CITIES) {
      candidates.push(`s${season}-regional-open-${city}`);
      candidates.push(`s${season}-${city}-national-open`);
    }
  }
  console.log(`[Mobalytics] probing ${candidates.length} candidate slugs`);

  // Riot-wins dedup: pre-fetch existing Riot docs so we know which
  // cities are already covered. Schedule isn't huge, single read is fine.
  const existingSnap = await scheduleRef.get();
  const riotCities = new Set();
  for (const d of existingSnap.docs) {
    const data = d.data();
    if ((data.sourcePlatform || "riot") === "riot" && data.city) {
      riotCities.add(data.city.toLowerCase());
    }
  }

  const created = [];
  const skipped = [];
  const dedupSkipped = [];
  const failed = [];

  for (const slug of candidates) {
    try {
      let tournamentInfo;
      try {
        tournamentInfo = await fetchMobalyticsTournament(slug);
      } catch (e) {
        if (/HTTP 404/.test(e.message)) continue;
        throw e;
      }
      if (tournamentInfo.deckSlugs.length === 0) continue;

      const docId = `mobalytics-${slug}`;
      const docRef = scheduleRef.doc(docId);
      if ((await docRef.get()).exists) { skipped.push(slug); continue; }

      const cityNormalized = (tournamentInfo.city || "").toLowerCase();
      if (cityNormalized && riotCities.has(cityNormalized)) {
        dedupSkipped.push({ slug, city: tournamentInfo.city, reason: "Riot doc exists for same city" });
        console.log(`[Mobalytics] DEDUP-SKIP ${slug} — Riot already covers ${tournamentInfo.city}`);
        continue;
      }

      await docRef.set({
        name: tournamentInfo.name || `S2 Regional Open ${properCase(tournamentInfo.city)}`,
        eventDate: tournamentInfo.date || null,
        eventEndDate: null,
        urlSlugs: [],
        imported: false,
        sourceSlug: slug,
        sourceUrl: tournamentInfo.url,
        sourceTitle: tournamentInfo.name,
        city: properCase(tournamentInfo.city),
        discoveredAt: admin.firestore.FieldValue.serverTimestamp(),
        discoverySource: source,
        sourcePlatform: "mobalytics",
        mobalyticsSlug: slug,
      });
      created.push({ slug, city: tournamentInfo.city, date: tournamentInfo.date, decks: tournamentInfo.deckSlugs.length });
      console.log(`[Mobalytics] CREATED ${docId} → ${tournamentInfo.city} on ${tournamentInfo.date || "(no date)"} (${tournamentInfo.deckSlugs.length} decks expected)`);
    } catch (e) {
      failed.push({ slug, reason: e.message });
      console.error(`[Mobalytics] failed ${slug}: ${e.message}`);
    }
  }

  const summary = {
    candidatesProbed: candidates.length,
    created: created.length,
    skipped: skipped.length,
    dedupSkipped: dedupSkipped.length,
    failed: failed.length,
    detail: { created, dedupSkipped, failed },
  };
  console.log(`[Mobalytics] DONE: ${JSON.stringify(summary, null, 2)}`);
  return summary;
}

/**
 * Import all decks for a Mobalytics-sourced schedule doc. Returns
 * `{ imported, failedChampion, failedOther }` so the caller can surface
 * the failure list per spec (`failed_champion_extraction[]` in HTTP response).
 */
async function importMobalyticsTournament(scheduleDocRef, scheduleData) {
  const slug = scheduleData.mobalyticsSlug;
  if (!slug) throw new Error(`schedule doc missing mobalyticsSlug: ${scheduleDocRef.id}`);
  const tournamentInfo = await fetchMobalyticsTournament(slug);
  console.log(`[Mobalytics-Import] ${slug}: ${tournamentInfo.deckSlugs.length} deck-pages to fetch`);

  const metaRef = db.collection("artifacts").doc(APP_ID).collection("meta_decks");
  const tournRef = db.collection("artifacts").doc(APP_ID).collection("meta_tournaments");

  const failedChampion = [];
  const failedOther = [];
  let importedCount = 0;
  let batch = db.batch();
  let batchN = 0;

  for (const deckSlug of tournamentInfo.deckSlugs) {
    const deckUrl = `${MOBALYTICS_BASE}/riftbound/decks/${deckSlug}`;
    try {
      const deckHtml = await fetchWithRetries(deckUrl, { retries: 2 });
      const parsed = parseMobalyticsDeckPage(deckHtml);
      if (!parsed.ok) {
        if (/champion-heuristic/.test(parsed.reason)) {
          failedChampion.push({ url: deckUrl, slug: deckSlug, reason: parsed.reason });
          console.warn(`[Mobalytics-Import] CHAMPION-FAIL ${deckSlug}: ${parsed.reason}`);
        } else {
          failedOther.push({ url: deckUrl, slug: deckSlug, reason: parsed.reason });
          console.warn(`[Mobalytics-Import] PARSE-FAIL ${deckSlug}: ${parsed.reason}`);
        }
        continue;
      }
      const deck = parsed.deck;
      const eventDate = scheduleData.eventDate || tournamentInfo.date || null;
      const md = buildMetaDeck(
        deck,
        scheduleData.name || tournamentInfo.name,
        eventDate,
        deckUrl,
      );
      // Mobalytics-specific overrides:
      //   1. Real placement string (not synthesised from `overall`).
      //   2. Description without fake "Overall #N".
      //   3. Doc-ID derived from Mobalytics's own deck-slug — the existing
      //      Riot deckId logic strips non-ASCII characters from the player
      //      slug (`/[^a-z0-9]+/`), which collapses every Chinese-only
      //      player name to "" and causes silent doc collisions across
      //      the same placement bucket. Mobalytics's deck-slug is already
      //      URL-safe + globally unique by design; using it directly
      //      sidesteps the Unicode issue without touching Riot's path.
      md.id = `meta-mobalytics-${deckSlug}`;
      md.placement = deck._mobalyticsPlacement;
      md.description = `${md.source} ${md.placement} by ${deck.player}`;
      md.sourcePlatform = "mobalytics";

      batch.set(metaRef.doc(md.id), md);
      batchN++;
      importedCount++;
      if (batchN >= 400) { await batch.commit(); batch = db.batch(); batchN = 0; }
    } catch (e) {
      failedOther.push({ url: deckUrl, slug: deckSlug, reason: e.message });
      console.error(`[Mobalytics-Import] FETCH-FAIL ${deckSlug}: ${e.message}`);
    }
  }

  batch.update(scheduleDocRef, {
    imported: true,
    importedAt: admin.firestore.FieldValue.serverTimestamp(),
    deckCount: importedCount,
    failedChampionCount: failedChampion.length,
  });
  const tId = (scheduleData.name || `mobalytics-${slug}`).toLowerCase().replace(/[^a-z0-9]+/g, "-");
  batch.set(tournRef.doc(tId), {
    name: scheduleData.name || tournamentInfo.name,
    date: scheduleData.eventDate || tournamentInfo.date || null,
    deckCount: importedCount,
    sourceUrl: tournamentInfo.url,
    sourcePlatform: "mobalytics",
    importedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (batchN > 0 || importedCount > 0) await batch.commit();

  console.log(`[Mobalytics-Import] ${slug}: imported=${importedCount} failedChampion=${failedChampion.length} failedOther=${failedOther.length}`);
  return { imported: importedCount, failedChampion, failedOther };
}

exports.discoverTournamentsFromMobalytics = onSchedule(
  {
    schedule: "35 7 * * *",
    timeZone: "UTC",
    timeoutSeconds: 300,
    memory: "512MiB",
    region: "us-central1",
  },
  async () => { await runMobalyticsDiscoveryPass({ source: "scheduled" }); },
);

/**
 * Manual trigger — also imports decks for all Mobalytics docs flagged
 * imported:false so the operator can verify the full discovery+import
 * pipeline in one HTTP call. Returns failed_champion_extraction[] per spec.
 */
exports.discoverTournamentsFromMobalyticsManual = onRequest(
  { timeoutSeconds: 540, memory: "1GiB", region: "us-central1", secrets: ["ADMIN_TRIGGER_SECRET"] },
  async (req, res) => {
    if (!requireAdminSecret(req, res)) return;
    try {
      const discoverSummary = await runMobalyticsDiscoveryPass({ source: "manual" });
      const scheduleRef = db.collection("artifacts").doc(APP_ID)
        .collection("meta_tournament_schedule");
      const pending = await scheduleRef
        .where("sourcePlatform", "==", "mobalytics")
        .where("imported", "==", false)
        .get();

      const importResults = [];
      const failed_champion_extraction = [];
      for (const doc of pending.docs) {
        const r = await importMobalyticsTournament(doc.ref, doc.data());
        importResults.push({
          docId: doc.id,
          slug: doc.data().mobalyticsSlug,
          imported: r.imported,
          failedChampion: r.failedChampion.length,
          failedOther: r.failedOther.length,
        });
        for (const f of r.failedChampion) {
          failed_champion_extraction.push({
            ...f,
            tournament: doc.data().name,
            mobalyticsSlug: doc.data().mobalyticsSlug,
          });
        }
      }

      res.json({
        success: true,
        discovery: discoverSummary,
        importResults,
        failed_champion_extraction,
      });
    } catch (e) {
      console.error(`[Mobalytics-Manual] ${e.stack || e.message}`);
      res.status(500).json({ error: e.message });
    }
  },
);



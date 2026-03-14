const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const APP_ID = "riftr-v1";

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
  874521: { name: "Annie, Dark Child", set: "OGNX" },
  874522: { name: "Master Yi, Wuju Bladesman", set: "OGNX" },
  874523: { name: "Lux, Lady of Luminosity", set: "OGNX" },
  874524: { name: "Garen, Might of Demacia", set: "OGNX" },
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

  // --- Increment collection quantities ---
  const collRef = userBase.doc("collection");
  const collDoc = await collRef.get();
  const cards = collDoc.exists ? (collDoc.data().cards || {}) : {};

  for (const item of items) {
    if (!item.cardId) continue;
    const qty = item.quantity || 1;
    cards[item.cardId] = (cards[item.cardId] || 0) + qty;
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

  const EXP_MAP = { 6286: "OGN", 6289: "OGS", 6399: "SFD", 6322: "OGNX", 6483: "SFDX" };
  const knownExps = new Set(Object.keys(EXP_MAP).map(Number));
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

    for (let idx = 0; idx < products.length; idx++) {
      const product = products[idx];
      const pg = priceMap[product.idProduct];
      if (!pg) {
        noPrice++;
        continue;
      }

      // Assign rarity: from variant list if available, else default to "Showcase"
      const rarity = idx < variantList.length ? variantList[idx] : "Showcase";
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

      // History points use max(trend, low) to prevent unrealistic dips
      // on low-liquidity cards where trend can be wildly below actual buy price
      const histFoil = foilPrice > 0 ? Math.max(foilPrice, l30F) : 0;
      const histNf = nonFoilPrice > 0 ? Math.max(nonFoilPrice, l30Nf) : 0;
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
          n: "Plated Legend: " + meta.name,
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
          r: "Metal", s: "MTL", vi: 0, sp: "",
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
      prices[cmId] = { ...prevPrices[cmId] };
      // Keep sparkline + history growing via existing history doc
      metalMatched++;
    }
  }
  console.log(`Metal cards: ${metalMatched} of ${Object.keys(PLATED_LEGEND_IDS).length} preserved`);

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
      const { cmId, isPrimaryFoil, foilPoint, nonFoilPoint } = chunk[j];
      const existingDoc = existingDocs[j];

      // Load existing point counts for safety validation
      const existingFoilCount = existingDoc.exists ? (existingDoc.data().points || []).length : 0;
      const existingNfCount = existingDoc.exists ? (existingDoc.data().pointsNf || []).length : 0;

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

        // Compute c24 per variant from stored history (most recent point before today)
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
  },
  async (req, res) => {
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

const crypto = require("crypto");
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

    // Generate 6-digit code
    const code = crypto.randomInt(100000, 999999).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store code (hashed) in Firestore
    const codeHash = crypto.createHash("sha256").update(code).digest("hex");
    await db
      .collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("emailVerification")
      .set({
        email,
        codeHash,
        expiresAt: expiresAt.toISOString(),
        attempts: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
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

    console.log(`Verification code sent to ${email} for uid ${uid}`);
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

    console.log(`Email ${data.email} verified for uid ${uid}`);
    return { success: true, email: data.email };
  }
);

// ═══════════════════════════════════════════
// ─── Stripe Connect (Seller Onboarding) ───
// ═══════════════════════════════════════════

const STRIPE_SECRET = (process.env.STRIPE_SECRET_KEY || "").trim();
const STRIPE_WEBHOOK_SECRET = (process.env.STRIPE_WEBHOOK_SECRET || "").trim();
const RETURN_BASE = "https://getriftr.app";

function getStripe() {
  if (!STRIPE_SECRET) {
    throw new HttpsError("failed-precondition", "Stripe not configured");
  }
  return require("stripe")(STRIPE_SECRET);
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

      await db
        .collection("artifacts").doc(APP_ID)
        .collection("users").doc(uid)
        .collection("data").doc("sellerProfile")
        .set(
          {
            stripeOnboarded: isOnboarded,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      console.log(
        `Stripe account ${account.id} for uid ${uid}: onboarded=${isOnboarded}`
      );
    }

    // Handle PaymentIntent events for order status updates
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
          console.log(`Order ${orderId} payment confirmed via webhook`);
        }
      }
    }

    if (event.type === "payment_intent.payment_failed") {
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
          console.log(`Order ${orderId} payment failed, cancelled`);
        }
      }
    }

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

    return { success: true };
  }
);

// ═══════════════════════════════════════════
// ─── Marketplace: Buy Flow & Orders ───
// ═══════════════════════════════════════════

// Simplified shipping rates (same as Flutter ShippingRates).
// { countryCode: { letter: { domestic, eu }, tracked: {...}, insured: {...} } }
const SHIPPING_RATES = {
  DE: { letter: { domestic: 1.10, eu: 1.80 }, tracked: { domestic: 3.75, eu: 4.45 }, insured: { domestic: 4.85, eu: 6.00 } },
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
    const { listingId, quantity, items, shippingMethod, shippingAddress } = request.data;

    // Support both single-listing and cart (items array) mode
    const isCart = Array.isArray(items) && items.length > 0;

    if (!isCart && (!listingId || !quantity)) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }
    if (!shippingMethod || !shippingAddress) {
      throw new HttpsError("invalid-argument", "Missing shipping info");
    }

    // 1. Fetch all listings (single or cart)
    const cartEntries = isCart ? items : [{ listingId, quantity }];
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
      const available = data.quantity - (data.reservedQty || 0);
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

    // 3. Get seller's Stripe account
    const sellerRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(sellerId)
      .collection("data").doc("sellerProfile");
    const sellerDoc = await sellerRef.get();
    if (!sellerDoc.exists || !sellerDoc.data().stripeAccountId) {
      throw new HttpsError("failed-precondition", "Seller has no Stripe account");
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
      });
    }
    subtotal = round2(subtotal);

    const rawFee = round2(subtotal * PLATFORM_FEE_RATE);
    const platformFee = Math.min(rawFee, PLATFORM_FEE_CAP);
    const sellerCountry = listingData[0].sellerCountry || "";
    const buyerCountry = (shippingAddress.country || "").toUpperCase();
    const anyInsuredOnly = listingData.some(l => l.insuredOnly);
    const effectiveMethod = anyInsuredOnly ? "insured" : shippingMethod;
    const shippingCost = round2(getShippingRate(sellerCountry, buyerCountry, effectiveMethod));
    const totalPaid = round2(subtotal + shippingCost);
    const sellerPayout = round2(subtotal - platformFee);

    // Amounts in cents for Stripe
    const totalCents = Math.round(totalPaid * 100);
    const feeCents = Math.round(platformFee * 100);

    // 5. Get buyer display name
    const buyerProfileRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("profile");
    const buyerProfileDoc = await buyerProfileRef.get();
    const buyerName = buyerProfileDoc.exists
      ? (buyerProfileDoc.data().displayName || "Buyer")
      : "Buyer";

    // 6. Create order doc first (need ID for PI metadata)
    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc();
    const orderId = orderRef.id;

    // 7. Create Stripe PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: totalCents,
      currency: "eur",
      capture_method: "manual",
      transfer_data: { destination: sellerStripeAccountId },
      application_fee_amount: feeCents,
      metadata: {
        orderId,
        buyerId: uid,
        sellerId,
        itemCount: String(orderItems.length),
        cardNames: orderItems.map(i => i.cardName).join(", ").substring(0, 500),
      },
    });

    // 8. Write order doc
    await orderRef.set({
      buyerId: uid,
      sellerId,
      sellerStripeAccountId,
      items: orderItems,
      subtotal,
      platformFee,
      shippingCost,
      totalPaid,
      sellerPayout,
      shippingAddress,
      shippingMethod: effectiveMethod,
      stripePaymentIntentId: paymentIntent.id,
      status: "pending_payment",
      sellerName: listingData[0].sellerName || null,
      buyerName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 9. Reserve quantity on all listings
    for (let i = 0; i < cartEntries.length; i++) {
      const entry = cartEntries[i];
      const listing = listingData[i];
      const ref = listingRefs[i];
      const qty = entry.quantity || 1;
      const newReserved = (listing.reservedQty || 0) + qty;
      const updateData = { reservedQty: newReserved };
      if (newReserved >= listing.quantity) {
        updateData.status = "reserved";
      }
      await ref.update(updateData);
    }

    console.log(`Order ${orderId} created: €${totalPaid} (${orderItems.length} items, PI: ${paymentIntent.id})`);
    return { clientSecret: paymentIntent.client_secret, orderId, total: totalPaid };
  }
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

    // Capture the PaymentIntent (charge the buyer)
    const stripe = getStripe();
    await stripe.paymentIntents.capture(order.stripePaymentIntentId);

    // Update order
    const autoReleaseAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await orderRef.update({
      status: "shipped",
      trackingNumber: trackingNumber || null,
      shippedAt: admin.firestore.FieldValue.serverTimestamp(),
      autoReleaseAt: autoReleaseAt.toISOString(),
    });

    console.log(`Order ${orderId} shipped (tracking: ${trackingNumber || "none"})`);
    return { success: true };
  }
);

/**
 * confirmDelivery — Callable, authenticated.
 * Buyer confirms receipt. Finalizes order.
 */
exports.confirmDelivery = onCall(
  { region: "europe-west1", timeoutSeconds: 15 },
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
      throw new HttpsError("permission-denied", "Only the buyer can confirm delivery");
    }
    if (order.status !== "shipped") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected shipped`);
    }

    // Mark delivered
    await orderRef.update({
      status: "delivered",
      deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Increment seller stats
    const totalQty = (order.items || []).reduce((sum, item) => sum + (item.quantity || 1), 0);
    const sellerRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(order.sellerId)
      .collection("data").doc("sellerProfile");
    await sellerRef.update({
      totalSales: admin.firestore.FieldValue.increment(totalQty),
      totalRevenue: admin.firestore.FieldValue.increment(order.sellerPayout || 0),
    });

    // Record sale prices for analytics
    await recordSales(order, orderId);

    // Add purchased cards to buyer's collection
    await addItemsToCollection(order);

    console.log(`Order ${orderId} delivered, seller ${order.sellerId} stats updated`);
    return { success: true };
  }
);

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
    const { orderId, reason } = request.data;

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
    if (order.status !== "shipped") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected shipped`);
    }

    await orderRef.update({
      status: "disputed",
      disputeReason: reason,
      disputedAt: admin.firestore.FieldValue.serverTimestamp(),
      autoReleaseAt: null, // Pause auto-release
    });

    console.log(`Dispute opened on order ${orderId}: ${reason}`);
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

    const stripe = getStripe();
    const piId = order.stripePaymentIntentId;

    if (order.status === "paid") {
      // Already authorized/captured — issue refund
      await stripe.refunds.create({ payment_intent: piId });
    } else {
      // Still pending — cancel PI
      await stripe.paymentIntents.cancel(piId);
    }

    // Update order
    await orderRef.update({
      status: "cancelled",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
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

    console.log(`Order ${orderId} cancelled by ${uid}`);
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
      const order = doc.data();
      await doc.ref.update({
        status: "auto_completed",
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update seller stats
      const totalQty = (order.items || []).reduce((sum, item) => sum + (item.quantity || 1), 0);
      const sellerRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(order.sellerId)
        .collection("data").doc("sellerProfile");
      await sellerRef.update({
        totalSales: admin.firestore.FieldValue.increment(totalQty),
        totalRevenue: admin.firestore.FieldValue.increment(order.sellerPayout || 0),
      });

      // Record sale prices for analytics
      await recordSales(order, doc.id);

      // Add purchased cards to buyer's collection
      await addItemsToCollection(order);
    }

    console.log(`autoReleaseOrders: completed ${snap.size} orders`);

    // ── Auto-cancel overdue unshipped orders (7 days after payment) ──
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const overdueSnap = await ordersRef
      .where("status", "==", "paid")
      .where("paidAt", "<=", sevenDaysAgo)
      .get();

    for (const doc of overdueSnap.docs) {
      const order = doc.data();

      // Cancel the order + refund
      try {
        const Stripe = require("stripe");
        const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
        if (order.stripePaymentIntentId) {
          await stripe.refunds.create({ payment_intent: order.stripePaymentIntentId });
        }
      } catch (e) {
        console.error(`Auto-cancel refund failed for ${doc.id}: ${e.message}`);
      }

      await doc.ref.update({
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Release listing reservations
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

      // Add strike to seller for non-shipment
      await addStrike(order.sellerId, "Non-shipment: order " + doc.id);
    }

    if (!overdueSnap.empty) {
      console.log(`autoReleaseOrders: auto-cancelled ${overdueSnap.size} overdue orders`);
    }
  }
);

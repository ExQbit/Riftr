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
          apns: { payload: { aps: { sound: "default" } } },
        });
      } catch (err) {
        if (
          err.code === "messaging/registration-token-not-registered" ||
          err.code === "messaging/invalid-registration-token" ||
          err.code === "messaging/third-party-auth-error"
        ) {
          staleTokens.push(token);
        } else {
          console.error(`FCM send failed for ${uid}: ${err.message}`);
        }
      }
    }

    // Clean up stale tokens
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
    // TODO: UNL (Unleashed) — add idExpansion when available on Cardmarket
    // TODO: OGSX (Proving Grounds Extras) — add idExpansion when available on Cardmarket
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
      // Keep sparkline + history growing via existing history doc
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

/** Get total balance (positive cents) from Stripe customer.balance. */
async function getBalance(uid) {
  const customerId = await getStripeCustomerId(uid);
  const stripe = getStripe();
  const customer = await stripe.customers.retrieve(customerId);
  // Stripe convention: negative balance = credit/funds available
  return Math.abs(Math.min(customer.balance, 0));
}

/** Get available balance (total minus escrow minus pending payouts; 0 if frozen). */
async function getAvailableBalance(uid) {
  const balDoc = await db.doc(`artifacts/${APP_ID}/users/${uid}/wallet/balance`).get();
  if (!balDoc.exists) return 0;
  const data = balDoc.data();
  if (data.frozen) return 0;
  return data.available || 0;
}

/** Count today's top-up transactions for rate limiting. */
async function countTodayTopUps(uid) {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const snap = await db.collection(`artifacts/${APP_ID}/users/${uid}/walletTransactions`)
    .where("type", "==", "top_up")
    .where("createdAt", ">=", startOfDay)
    .get();
  return snap.size;
}

/** Count purchases in the last hour for rate limiting. */
async function countHourlyPurchases(uid) {
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
  const snap = await db.collection(`artifacts/${APP_ID}/users/${uid}/walletTransactions`)
    .where("type", "==", "purchase")
    .where("createdAt", ">=", oneHourAgo)
    .get();
  return snap.size;
}

/** Sum today's payout amounts (in cents) for daily limit. */
async function getTodayPayoutTotal(uid) {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const snap = await db.collection(`artifacts/${APP_ID}/users/${uid}/walletTransactions`)
    .where("type", "==", "payout")
    .where("createdAt", ">=", startOfDay)
    .get();
  let total = 0;
  snap.forEach(doc => { total += Math.abs(doc.data().amount || 0); });
  return total;
}

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

      // ── Wallet Top-Up ──
      if (pi.metadata?.type === "top_up" && pi.metadata?.uid) {
        const topUpUid = pi.metadata.uid;
        const topUpAmount = pi.amount;
        try {
          const customerId = pi.customer;
          if (customerId) {
            // Credit the customer balance (make more negative = more credit)
            const cust = await stripe.customers.retrieve(customerId);
            await stripe.customers.update(customerId, {
              balance: cust.balance - topUpAmount,
            });
          }

          // Transaction log — top-ups are always immediately available
          const txRef = db.collection(`artifacts/${APP_ID}/users/${topUpUid}/walletTransactions`).doc();
          await txRef.set({
            type: "top_up",
            amount: topUpAmount,
            status: "completed",
            stripePaymentIntentId: pi.id,
            description: `Guthaben aufgeladen: €${(topUpAmount / 100).toFixed(2)}`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await updateBalanceCache(topUpUid);

          sendNotification(topUpUid, "Balance topped up!",
            `€${(topUpAmount / 100).toFixed(2)} added to your balance.`);
          console.log(`Top-up ${pi.id} succeeded: ${topUpUid} +€${(topUpAmount / 100).toFixed(2)}`);
        } catch (err) {
          console.error(`Top-up webhook error for ${pi.id}:`, err);
        }
      }

      // ── Legacy Direct Pay (order with orderId in metadata) ──
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
          const whOrder = orderDoc.data();
          const whSummary = orderItemsSummary(whOrder.items);
          sendNotification(whOrder.sellerId, "New order!", `${whSummary} — €${(whOrder.totalPaid || 0).toFixed(2)}. Ship within 7 days.`);
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

    // ── Chargeback: INSTANT account freeze ──
    if (event.type === "charge.dispute.created") {
      const dispute = event.data.object;
      try {
        const disputePi = dispute.payment_intent
          ? await stripe.paymentIntents.retrieve(dispute.payment_intent)
          : null;
        const disputeUid = disputePi?.metadata?.uid;
        if (disputeUid) {
          // Suspend account
          await db.doc(`artifacts/${APP_ID}/users/${disputeUid}/data/trustLevel`).update({
            level: "suspended",
            flags: admin.firestore.FieldValue.arrayUnion("chargeback_dispute"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Freeze balance
          await db.doc(`artifacts/${APP_ID}/users/${disputeUid}/wallet/balance`).update({
            available: 0,
            frozen: true,
            frozenReason: "chargeback_dispute",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Pause open orders (as buyer)
          const openOrders = await db.collection("artifacts").doc(APP_ID)
            .collection("orders")
            .where("buyerId", "==", disputeUid)
            .where("status", "in", ["paid", "shipped"])
            .get();
          for (const orderDoc of openOrders.docs) {
            await orderDoc.ref.update({
              status: "frozen",
              frozenReason: "buyer_chargeback",
            });
            sendNotification(orderDoc.data().sellerId, "Order paused",
              "An order has been temporarily paused. Please do not ship.");
          }

          sendAdminAlert("CHARGEBACK", `User ${disputeUid} chargeback. Account frozen.`);
          console.log(`CHARGEBACK: User ${disputeUid} frozen (dispute ${dispute.id})`);
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
        const disputeUid = disputePi?.metadata?.uid;
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

    // ── Transfer completed (payout to seller bank) ──
    if (event.type === "transfer.paid") {
      const transfer = event.data.object;
      const payoutUid = transfer.metadata?.uid;
      if (payoutUid && transfer.metadata?.type === "payout") {
        sendNotification(payoutUid, "Payout completed",
          `€${(transfer.amount / 100).toFixed(2)} has arrived at your bank account.`);
        console.log(`Transfer ${transfer.id} paid to ${payoutUid}`);
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

    // Notify seller about new order
    const cpSummary = orderItemsSummary(order.items);
    sendNotification(order.sellerId, "New order!", `${cpSummary} — €${(order.totalPaid || 0).toFixed(2)}. Ship within 7 days.`);

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
    const sellerPayout = round2(subtotal - platformFee + shippingCost);

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

    // 7. Create Stripe PaymentIntent (with 3D Secure for liability shift)
    const paymentIntent = await stripe.paymentIntents.create({
      amount: totalCents,
      currency: "eur",
      capture_method: "manual",
      transfer_data: { destination: sellerStripeAccountId },
      application_fee_amount: feeCents,
      payment_method_options: {
        card: { request_three_d_secure: "challenge" },
      },
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
      preReleaseDate: listingData[0].preReleaseDate || null,
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

    // Pre-release: block shipping before release date
    if (order.preReleaseDate) {
      const releaseDate = new Date(order.preReleaseDate + "T00:00:00Z");
      if (releaseDate > new Date()) {
        throw new HttpsError("failed-precondition", `Cannot ship before release date ${order.preReleaseDate}`);
      }
    }

    // Capture the PaymentIntent (only for Stripe-paid orders, not balance purchases)
    if (order.paymentMethod !== "balance" && order.stripePaymentIntentId) {
      const stripe = getStripe();
      await stripe.paymentIntents.capture(order.stripePaymentIntentId);
    }

    // Update order
    const autoReleaseAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await orderRef.update({
      status: "shipped",
      trackingNumber: trackingNumber || null,
      shippedAt: admin.firestore.FieldValue.serverTimestamp(),
      autoReleaseAt: autoReleaseAt.toISOString(),
    });

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
    sendNotification(order.buyerId, "Order shipped!", `${shipSummary} is on its way.${trackingNumber ? " Tracking: " + trackingNumber : ""}`);

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
      sendNotification(order.buyerId, "Tracking updated", `${summary} — Tracking: ${trackingNumber}`);
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

    // All post-status operations: if any fail, order stays delivered
    // but we log the error and still return success to the buyer
    try {
      // Increment seller stats (set+merge so doc is created if missing)
      const totalQty = (order.items || []).reduce((sum, item) => sum + (item.quantity || 1), 0);
      const sellerRef = db.collection("artifacts").doc(APP_ID)
        .collection("users").doc(order.sellerId)
        .collection("data").doc("sellerProfile");
      await sellerRef.set({
        totalSales: admin.firestore.FieldValue.increment(totalQty),
        totalRevenue: admin.firestore.FieldValue.increment(order.sellerPayout || 0),
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

      // Notify seller that delivery confirmed
      const delSummary = orderItemsSummary(order.items);
      sendNotification(order.sellerId, "Delivery confirmed!", `${delSummary} — €${(order.sellerPayout || 0).toFixed(2)} released.`);
    } catch (postErr) {
      console.error(`confirmDelivery post-status error for ${orderId}:`, postErr);
      // Don't throw — order IS delivered, buyer should see success
    }

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
    if (order.status !== "shipped") {
      throw new HttpsError("failed-precondition", `Order status is ${order.status}, expected shipped`);
    }

    const safeDesc = typeof description === "string" ? description.trim().substring(0, 500) : null;

    await orderRef.update({
      status: "disputed",
      disputeStatus: "open",
      disputeReason: reason,
      ...(safeDesc ? { disputeDescription: safeDesc } : {}),
      disputedAt: admin.firestore.FieldValue.serverTimestamp(),
      autoReleaseAt: null, // Pause auto-release
    });

    console.log(`Dispute opened on order ${orderId}: ${reason}${safeDesc ? ` — ${safeDesc}` : ""}`);

    // Notify seller about dispute
    const dispSummary = orderItemsSummary(order.items);
    sendNotification(order.sellerId, "Dispute opened", `${dispSummary}: ${reason}`);

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

    const isBalanceOrder = order.paymentMethod === "balance";

    if (isBalanceOrder) {
      // Balance order: refund buyer's wallet, deduct from seller's wallet
      const stripe = getStripe();
      const totalCents = Math.round((order.totalPaid || 0) * 100);
      const sellerPayoutCents = Math.round((order.sellerPayout || 0) * 100);

      // Refund buyer (add credit back)
      const buyerCustId = await getStripeCustomerId(order.buyerId);
      const buyerCust = await stripe.customers.retrieve(buyerCustId);
      await stripe.customers.update(buyerCustId, {
        balance: buyerCust.balance - totalCents,
      });

      // Deduct from seller (remove credit)
      const sellerCustId = await getStripeCustomerId(order.sellerId);
      const sellerCust = await stripe.customers.retrieve(sellerCustId);
      await stripe.customers.update(sellerCustId, {
        balance: sellerCust.balance + sellerPayoutCents,
      });

      // Log transactions
      await logTransaction(order.buyerId, "refund", totalCents, orderId, "Order cancelled — refund");
      await logTransaction(order.sellerId, "reversal", -sellerPayoutCents, orderId, "Order cancelled — reversal");
    } else {
      // Card order: Stripe refund/cancel
      const stripe = getStripe();
      const piId = order.stripePaymentIntentId;

      if (order.status === "paid") {
        await stripe.refunds.create({ payment_intent: piId });
      } else {
        await stripe.paymentIntents.cancel(piId);
      }
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

    // Update balance caches for balance orders
    if (isBalanceOrder) {
      await updateBalanceCache(order.buyerId);
      await updateBalanceCache(order.sellerId);
    }

    console.log(`Order ${orderId} cancelled by ${uid}`);

    // Notify the other party
    const otherUid = uid === order.buyerId ? order.sellerId : order.buyerId;
    const cancelSummary = orderItemsSummary(order.items);
    sendNotification(otherUid, "Order cancelled", `${cancelSummary} — refunded.`);

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
    sendNotification(order.buyerId, "Refund proposed", `${summary}: ${percent}% refund (€${refundAmount.toFixed(2)}) — review and accept or reject.`);

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
      // WALLET REFUND: Transfer balance from seller → buyer (no Stripe refund API)
      const stripe = getStripe();
      const refundAmount = order.proposedRefundAmount || 0;
      const refundPercent = order.proposedRefundPercent || 100;
      const refundCents = Math.round(refundAmount * 100);

      const isBalanceOrder = order.paymentMethod === "balance";

      if (isBalanceOrder) {
        // ── Balance-paid order: transfer via Stripe Customer Balance ──
        const buyerCustomerId = await ensureStripeCustomer(order.buyerId);
        const sellerCustomerId = await ensureStripeCustomer(order.sellerId);

        // Credit buyer balance (make more negative = more credit)
        const buyerCust = await stripe.customers.retrieve(buyerCustomerId);
        await stripe.customers.update(buyerCustomerId, {
          balance: buyerCust.balance - refundCents,
        });

        // Debit seller balance (make less negative = less credit; can go positive = debt)
        const sellerCust = await stripe.customers.retrieve(sellerCustomerId);
        await stripe.customers.update(sellerCustomerId, {
          balance: sellerCust.balance + refundCents,
        });

        // Log transactions
        await logTransaction(order.buyerId, "refund", refundCents, orderId,
          `Erstattung: ${refundPercent}% von ${summary}`);
        await logTransaction(order.sellerId, "refund", -refundCents, orderId,
          `Erstattung an Käufer: ${refundPercent}% von ${summary}`);

        // Update balance caches
        await updateBalanceCache(order.buyerId);
        await updateBalanceCache(order.sellerId);
      } else {
        // ── Legacy direct-pay order: use Stripe refund API ──
        const piId = order.stripePaymentIntentId;
        if (!piId) {
          throw new HttpsError("failed-precondition", "No payment intent found");
        }
        if (refundPercent >= 100) {
          await stripe.refunds.create({ payment_intent: piId });
        } else {
          await stripe.refunds.create({ payment_intent: piId, amount: refundCents });
        }
      }

      // Update order
      await orderRef.update({
        status: "refunded",
        disputeStatus: "resolved",
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
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

      console.log(`Refund accepted: ${refundPercent}% (€${refundAmount.toFixed(2)}) on order ${orderId} [${isBalanceOrder ? "balance" : "stripe"}]`);
      sendNotification(order.sellerId, "Refund accepted", `${summary}: €${refundAmount.toFixed(2)} refunded to buyer.`);

      return { success: true, action: "refunded", refundAmount };
    } else {
      // Reject — reset to open so seller can propose again
      await orderRef.update({
        disputeStatus: "open",
        proposedRefundPercent: null,
        proposedRefundAmount: null,
        proposedAt: null,
      });

      console.log(`Refund rejected by buyer on order ${orderId}`);
      sendNotification(order.sellerId, "Refund rejected", `${summary}: Buyer rejected your proposal. Propose a different amount.`);

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
    sendNotification(order.sellerId, "Dispute cancelled", `${summary}: Buyer withdrew the dispute.`);

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
      const order = doc.data();
      await doc.ref.update({
        status: "auto_completed",
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      });

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
      sendNotification(order.buyerId, "Order auto-completed", "Your order was automatically completed.");
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
      sendNotification(order.sellerId, "Shipping reminder", "You have an unshipped order. Please ship soon.");
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
      sendNotification(order.sellerId, "Set released! 🎉", "Your pre-order is ready to ship. Please send it within 5 days.");
      sendNotification(order.buyerId, "Set released! 🎉", "Your pre-order will be shipped soon.");
    }
    if (!preReleaseSnap.empty) {
      console.log(`autoReleaseOrders: sent ${preReleaseSnap.size} release-day notification(s)`);
    }

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
    sendNotification(order.sellerId, "New review: " + stars, safeComment || "You received a rating.");

    return { success: true, avgRating, reviewCount: count };
  }
);

// ═══════════════════════════════════════════
// ─── Wallet: Top-Up Balance ───
// ═══════════════════════════════════════════

/**
 * topUpBalance — Callable, authenticated.
 * Creates a Stripe PaymentIntent for wallet top-up.
 * 3D Secure enforced on all card payments (liability shift).
 * Returns { clientSecret } for the Flutter PaymentSheet.
 */
exports.topUpBalance = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { amount } = request.data; // Amount in cents

    if (!amount || !Number.isInteger(amount)) {
      throw new HttpsError("invalid-argument", "amount (integer cents) is required");
    }

    try {
      // Suspended check
      const trust = await getTrustLevel(uid);
      if (trust.level === "suspended") {
        throw new HttpsError("permission-denied", "Account suspended");
      }
      // Same limits for all accounts: €5 – €500
      if (amount < 500) {
        throw new HttpsError("invalid-argument", "Minimum top-up: €5");
      }
      if (amount > 50000) {
        throw new HttpsError("invalid-argument", "Maximum top-up: €500");
      }

      // Rate limit: max 5 top-ups per day (all accounts)
      const todayCount = await countTodayTopUps(uid);
      if (todayCount >= 5) {
        throw new HttpsError("resource-exhausted", "Daily top-up limit reached");
      }

      // Ensure Stripe Customer
      const customerId = await ensureStripeCustomer(uid);
      const stripe = getStripe();

      // Create PaymentIntent with 3D Secure enforced
      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency: "eur",
        customer: customerId,
        payment_method_options: {
          card: { request_three_d_secure: "challenge" },
        },
        metadata: {
          type: "top_up",
          uid,
        },
      });

      console.log(`Top-up PI ${paymentIntent.id} created for ${uid}: €${(amount / 100).toFixed(2)}`);
      return { clientSecret: paymentIntent.client_secret };
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error("topUpBalance unexpected error:", e);
      throw new HttpsError("internal", e.message || "Top-up failed");
    }
  }
);

// ═══════════════════════════════════════════
// ─── Wallet: Purchase with Balance ───
// ═══════════════════════════════════════════

/**
 * purchaseWithBalance — Callable, authenticated.
 * Deducts from buyer's Stripe Customer Balance, credits seller.
 * No Stripe PaymentIntent — pure balance transfer.
 * Supports single listing or cart mode.
 */
exports.purchaseWithBalance = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { listingId, quantity, items, shippingMethod, shippingAddress } = request.data;

    const isCart = Array.isArray(items) && items.length > 0;
    if (!isCart && (!listingId || !quantity)) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }
    if (!shippingMethod || !shippingAddress) {
      throw new HttpsError("invalid-argument", "Missing shipping info");
    }

    // Suspended check
    const trust = await getTrustLevel(uid);
    if (trust.level === "suspended") {
      throw new HttpsError("permission-denied", "Account suspended");
    }

    // Rate limit: 50 purchases per hour (all accounts)
    const hourlyCount = await countHourlyPurchases(uid);
    if (hourlyCount >= 50) {
      throw new HttpsError("resource-exhausted", "Hourly purchase limit reached");
    }

    // Fetch all listings
    const cartEntries = isCart ? items : [{ listingId, quantity }];
    const listingRefs = [];
    const listingDocs = [];
    const listingDataArr = [];

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
      listingDataArr.push(data);
    }

    // All listings must be from the same seller
    const sellerId = listingDataArr[0].sellerId;
    if (listingDataArr.some(l => l.sellerId !== sellerId)) {
      throw new HttpsError("failed-precondition", "All cart items must be from the same seller");
    }

    // SELF-BUY CHECK
    if (uid === sellerId) {
      throw new HttpsError("permission-denied", "Cannot buy your own listings");
    }

    // Calculate amounts
    const orderItems = [];
    let subtotal = 0;
    for (let i = 0; i < cartEntries.length; i++) {
      const entry = cartEntries[i];
      const listing = listingDataArr[i];
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
    const sellerCountry = listingDataArr[0].sellerCountry || "";
    const buyerCountry = (shippingAddress.country || "").toUpperCase();
    const anyInsuredOnly = listingDataArr.some(l => l.insuredOnly);
    const effectiveMethod = anyInsuredOnly ? "insured" : shippingMethod;
    const shippingCost = round2(getShippingRate(sellerCountry, buyerCountry, effectiveMethod));
    const totalPaid = round2(subtotal + shippingCost);
    const sellerPayout = round2(subtotal - platformFee + shippingCost);

    // Amounts in cents for Stripe balance ops
    const totalCents = Math.round(totalPaid * 100);
    const sellerPayoutCents = Math.round(sellerPayout * 100);

    // Check buyer has enough available balance
    const buyerAvailable = await getAvailableBalance(uid);
    if (buyerAvailable < totalCents) {
      throw new HttpsError("failed-precondition", "Not enough balance");
    }

    // Get buyer display name
    const buyerProfileRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("profile");
    const buyerProfileDoc = await buyerProfileRef.get();
    const buyerName = buyerProfileDoc.exists
      ? (buyerProfileDoc.data().displayName || "Buyer")
      : "Buyer";

    // Ensure both parties have Stripe Customers
    const stripe = getStripe();
    const buyerCustomerId = await getStripeCustomerId(uid);
    const sellerCustomerId = await ensureStripeCustomer(sellerId);

    // BALANCE TRANSFER: Deduct from buyer, credit to seller
    const buyerCustomer = await stripe.customers.retrieve(buyerCustomerId);
    await stripe.customers.update(buyerCustomerId, {
      balance: buyerCustomer.balance + totalCents, // Makes balance less negative = less credit
    });

    const sellerCustomer = await stripe.customers.retrieve(sellerCustomerId);
    await stripe.customers.update(sellerCustomerId, {
      balance: sellerCustomer.balance - sellerPayoutCents, // Makes balance more negative = more credit
    });

    // Create order doc
    const orderRef = db.collection("artifacts").doc(APP_ID)
      .collection("orders").doc();
    const orderId = orderRef.id;

    const requiresTracking = subtotal >= 25;

    await orderRef.set({
      buyerId: uid,
      sellerId,
      items: orderItems,
      subtotal,
      platformFee,
      shippingCost,
      totalPaid,
      sellerPayout,
      shippingAddress,
      shippingMethod: effectiveMethod,
      paymentMethod: "balance",
      currency: "EUR",
      status: "paid",
      requiresTracking,
      buyerName,
      sellerName: listingDataArr[0].sellerName || null,
      preReleaseDate: listingDataArr[0].preReleaseDate || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Reserve quantity on all listings
    for (let i = 0; i < cartEntries.length; i++) {
      const entry = cartEntries[i];
      const listing = listingDataArr[i];
      const ref = listingRefs[i];
      const qty = entry.quantity || 1;
      const newReserved = (listing.reservedQty || 0) + qty;
      const updateData = { reservedQty: newReserved };
      if (newReserved >= listing.quantity) {
        updateData.status = "reserved";
      }
      await ref.update(updateData);
    }

    // Transaction logs
    await logTransaction(uid, "purchase", -totalCents, orderId,
      `Kauf: ${orderItems.map(i => i.cardName).join(", ").substring(0, 200)}`);
    await logTransaction(sellerId, "sale", sellerPayoutCents, orderId,
      `Verkauf: ${orderItems.map(i => i.cardName).join(", ").substring(0, 200)}`, Math.round(platformFee * 100));

    // Update balance caches
    await updateBalanceCache(uid);
    await updateBalanceCache(sellerId);

    // Notify seller
    const summary = orderItemsSummary(orderItems);
    sendNotification(sellerId, "New order!", `${summary} — €${totalPaid.toFixed(2)}. Ship within 7 days.`);

    console.log(`Balance purchase: order ${orderId}, €${totalPaid} from ${uid} to ${sellerId}`);
    return { orderId, total: totalPaid };
  }
);

// ═══════════════════════════════════════════
// ─── Wallet: Request Payout ───
// ═══════════════════════════════════════════

/**
 * requestPayout — Callable, authenticated.
 * Transfers from user's Stripe Customer Balance to their Connected Account (→ bank).
 * Requires Stripe Connect onboarding (IBAN).
 */
exports.requestPayout = onCall(
  { region: "europe-west1", timeoutSeconds: 30, secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { amount } = request.data; // Amount in cents

    if (!amount || !Number.isInteger(amount)) {
      throw new HttpsError("invalid-argument", "amount (integer cents) is required");
    }

    // 1. Suspended check
    const trust = await getTrustLevel(uid);
    if (trust.level === "suspended") {
      throw new HttpsError("permission-denied", "Account suspended");
    }

    // 2. Email verified check
    const profileRef = db.collection("artifacts").doc(APP_ID)
      .collection("users").doc(uid)
      .collection("data").doc("sellerProfile");
    const profileDoc = await profileRef.get();
    if (!profileDoc.exists || !profileDoc.data().emailVerified) {
      throw new HttpsError("failed-precondition", "Please verify your email first");
    }

    // 3. Stripe Connect (IBAN) set up
    const stripeAccountId = profileDoc.data().stripeAccountId;
    if (!stripeAccountId) {
      throw new HttpsError("failed-precondition", "Set up bank connection first (Stripe Connect)");
    }

    // 4. Account must be at least 7 days old
    const userRecord = await admin.auth().getUser(uid);
    const accountCreated = new Date(userRecord.metadata.creationTime);
    const accountAgeMs = Date.now() - accountCreated.getTime();
    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
    if (accountAgeMs < sevenDaysMs) {
      const daysLeft = Math.ceil((sevenDaysMs - accountAgeMs) / (24 * 60 * 60 * 1000));
      throw new HttpsError("failed-precondition",
        `Payouts available from day 8. ${daysLeft} day${daysLeft > 1 ? "s" : ""} remaining.`);
    }

    // 5. Minimum €5
    if (amount < 500) {
      throw new HttpsError("invalid-argument", "Minimum payout: €5");
    }

    // 6. Maximum €2,000 per day
    const todayTotal = await getTodayPayoutTotal(uid);
    if (todayTotal + amount > 200000) {
      const remaining = Math.max(200000 - todayTotal, 0);
      throw new HttpsError("resource-exhausted",
        `Daily limit €2,000. €${(remaining / 100).toFixed(2)} remaining today.`);
    }

    // 7. Available balance (minus escrow)
    const available = await getAvailableBalance(uid);
    if (amount > available) {
      throw new HttpsError("failed-precondition", "Not enough available balance");
    }

    // Execute payout — instant, no hold period
    const stripe = getStripe();

    const customerId = await getStripeCustomerId(uid);
    const customer = await stripe.customers.retrieve(customerId);

    // Deduct from customer balance first
    await stripe.customers.update(customerId, {
      balance: customer.balance + amount, // Less negative = less credit
    });

    let transfer;
    try {
      transfer = await stripe.transfers.create({
        amount,
        currency: "eur",
        destination: stripeAccountId,
        metadata: { uid, type: "payout" },
      });
    } catch (stripeErr) {
      // Rollback: restore customer balance
      await stripe.customers.update(customerId, {
        balance: customer.balance,
      });
      console.error(`Payout transfer failed for ${uid}:`, stripeErr.message);

      if (stripeErr.code === "balance_insufficient") {
        throw new HttpsError("unavailable",
          "Payout temporarily unavailable — platform funds are settling. Please try again later.");
      }
      throw new HttpsError("internal", "Payout failed: " + stripeErr.message);
    }

    await logTransaction(uid, "payout", -amount, null,
      "Payout to bank account", 0, transfer.id);

    await updateBalanceCache(uid);

    sendNotification(uid, "Payout initiated",
      `€${(amount / 100).toFixed(2)} will arrive in 2-7 business days.`);

    console.log(`Payout: ${uid} → €${(amount / 100).toFixed(2)} via transfer ${transfer.id}`);
    return { transferId: transfer.id };
  }
);

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

function parseDecklistPage(bodyText) {
  const decks = [];
  const pattern =
    /\n\n\n+([^\n]+)\nLegend Rank:\s*(\d+)\s*\/\s*(\d+)\s*players?\nOverall Ranking:\s*#(\d+)\s*\n+Legend:\n1\s+([^\n]+)\s*\n+Champion:\n1\s+([^\n]+)\s*\n+Main Deck:\n([\s\S]*?)\n+Battlefields:\n([\s\S]*?)\n+Rune Pool:\n([\s\S]*?)\n+Sideboard:\n([\s\S]*?)(?=\n\n\n|$)/g;

  let m;
  while ((m = pattern.exec(bodyText)) !== null) {
    const parseCards = (block) => {
      const r = {};
      for (const line of block.trim().split("\n")) {
        const cm = line.match(/^(\d+)\s+(.+)$/);
        if (cm) r[cm[2].trim()] = parseInt(cm[1]);
      }
      return r;
    };
    decks.push({
      player: m[1].trim(),
      legendRank: parseInt(m[2]),
      legendTotal: parseInt(m[3]),
      overall: parseInt(m[4]),
      legend: m[5].trim(),
      champion: m[6].trim(),
      mainDeck: parseCards(m[7]),
      battlefields: m[8]
        .trim()
        .split("\n")
        .map((l) => {
          const x = l.match(/^1\s+(.+)$/);
          return x ? x[1].trim() : null;
        })
        .filter(Boolean),
      runes: parseCards(m[9]),
      sideboard: parseCards(m[10]),
    });
  }

  // Deduplicate by player+overall
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

  return {
    id: deckId,
    name: isTop8 ? `${legendShort} ${d1}/${d2}` : `Best ${legendShort}`,
    description: `${tournamentName} ${placement} by ${deck.player} (Overall #${deck.overall})`,
    legendId: legend ? legend.id : "",
    legendName: legend ? legend.name : deck.legend,
    legendImageUrl: legend ? legend.imageUrl || "" : "",
    domains: [d1, d2],
    runeCount1: r1,
    runeCount2: r2,
    mainDeck: resolveDeckMap(deck.mainDeck),
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

    // Lazy-load Puppeteer only when needed
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

      for (const doc of snap.docs) {
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
      }
    } finally {
      if (browser) await browser.close();
    }
  }
);

// Manual trigger for testing
exports.checkNewTournamentDecksManual = onRequest(
  { timeoutSeconds: 300, memory: "1GiB", region: "us-central1" },
  async (req, res) => {
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


/**
 * Migration: Replace avg1-based history points with max(trend, low) values.
 * Uses 4 price_guide snapshots from Downloads (Mar 7, 11, 12, 14)
 * and interpolates missing days (8, 9, 10, 13).
 *
 * History point = max(trend, low) per variant. This prevents unrealistic
 * dips on low-liquidity cards where trend can drop far below actual buy price.
 *
 * Run: cd functions && node migrate-to-trend.js
 */
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

// Use Firebase CLI credentials
const credPath = path.join(
  process.env.HOME,
  ".config/firebase/eladiorubiohernandez_gmail_com_application_default_credentials.json"
);
process.env.GOOGLE_APPLICATION_CREDENTIALS = credPath;

admin.initializeApp({ projectId: "riftr-10527" });
const db = admin.firestore();

const APP_ID = "riftr-v1";
const historyRef = db.collection("artifacts").doc(APP_ID).collection("market_history");

function dateToEpoch(dateStr) {
  // dateStr = "2026-03-07"
  const d = new Date(dateStr + "T12:00:00Z");
  return Math.floor(d.getTime() / 1000);
}

function round2(v) {
  return Math.round(v * 100) / 100;
}

// Load price guide snapshots
const SNAPSHOTS = [
  { date: "2026-03-07", file: "/Users/exqbitmac/Downloads/price_guide_22.json" },
  { date: "2026-03-11", file: "/Users/exqbitmac/Downloads/price_guide_22 (1).json" },
  { date: "2026-03-12", file: "/Users/exqbitmac/Downloads/price_guide_22-2.json" },
  { date: "2026-03-14", file: "/Users/exqbitmac/Downloads/price_guide_22-3.json" },
];

// All dates we want in history (Mar 7 through Mar 14)
const ALL_DATES = [
  "2026-03-07", "2026-03-08", "2026-03-09", "2026-03-10",
  "2026-03-11", "2026-03-12", "2026-03-13", "2026-03-14",
];

async function main() {
  // 1. Load all snapshots into a map: idProduct → { date → {foil, nf} }
  // History value = max(trend, low) per variant to prevent unrealistic dips
  const snapshotData = {}; // idProduct → Map<date, {foil, nf}>

  for (const snap of SNAPSHOTS) {
    console.log(`Loading ${snap.file}...`);
    const raw = JSON.parse(fs.readFileSync(snap.file, "utf8"));
    for (const pg of raw.priceGuides) {
      const id = String(pg.idProduct);
      if (!snapshotData[id]) snapshotData[id] = {};
      const trendFoil = round2(pg["trend-foil"] || 0);
      const lowFoil = round2(pg["low-foil"] || 0);
      const trendNf = round2(pg.trend || 0);
      const lowNf = round2(pg.low || 0);
      snapshotData[id][snap.date] = {
        foil: trendFoil > 0 ? Math.max(trendFoil, lowFoil) : 0,
        nf: trendNf > 0 ? Math.max(trendNf, lowNf) : 0,
      };
    }
  }

  console.log(`Loaded trend data for ${Object.keys(snapshotData).length} products`);

  // 2. For each product, interpolate missing days
  const trendHistory = {}; // idProduct → { foilPoints: [{t,p}], nfPoints: [{t,p}] }

  for (const [id, dateMap] of Object.entries(snapshotData)) {
    const foilPoints = [];
    const nfPoints = [];

    for (const date of ALL_DATES) {
      const epoch = dateToEpoch(date);

      if (dateMap[date]) {
        // We have real data for this date
        if (dateMap[date].foil > 0) foilPoints.push({ t: epoch, p: dateMap[date].foil });
        if (dateMap[date].nf > 0) nfPoints.push({ t: epoch, p: dateMap[date].nf });
      } else {
        // Interpolate: find nearest before and after
        const foilVal = interpolate(dateMap, date, "foil");
        const nfVal = interpolate(dateMap, date, "nf");
        if (foilVal > 0) foilPoints.push({ t: epoch, p: round2(foilVal) });
        if (nfVal > 0) nfPoints.push({ t: epoch, p: round2(nfVal) });
      }
    }

    trendHistory[id] = { foilPoints, nfPoints };
  }

  // 3. Update Firestore history docs — replace points for the affected date range
  const epochStart = dateToEpoch("2026-03-07");
  const epochEnd = dateToEpoch("2026-03-14");

  let batch = db.batch();
  let opCount = 0;
  let batchNum = 0;
  let updated = 0;

  for (const [cmId, { foilPoints, nfPoints }] of Object.entries(trendHistory)) {
    const docRef = historyRef.doc(cmId);
    const existing = await docRef.get();

    if (!existing.exists) continue;

    const data = existing.data();
    const existingFoil = data.points || [];
    const existingNf = data.pointsNf || [];

    // Remove old points in the migration date range, keep points outside
    const keptFoil = existingFoil.filter(p => p.t < epochStart || p.t > epochEnd);
    const keptNf = existingNf.filter(p => p.t < epochStart || p.t > epochEnd);

    // Merge: kept old points + new trend-based points, sorted
    const mergedFoil = [...keptFoil, ...foilPoints].sort((a, b) => a.t - b.t);
    const mergedNf = [...keptNf, ...nfPoints].sort((a, b) => a.t - b.t);

    // Safety: never lose data outside the migration range
    if (keptFoil.length + foilPoints.length < existingFoil.length * 0.5) {
      console.warn(`⚠️ Skipping ${cmId}: would lose too many foil points`);
      continue;
    }

    batch.update(docRef, { points: mergedFoil, pointsNf: mergedNf });
    opCount++;
    updated++;

    if (opCount >= 450) {
      await batch.commit();
      batchNum++;
      console.log(`Batch ${batchNum} committed (${opCount} docs)`);
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
    batchNum++;
    console.log(`Batch ${batchNum} committed (${opCount} docs)`);
  }

  console.log(`Migration complete: ${updated} history docs updated with trend-based prices`);
  process.exit(0);
}

function interpolate(dateMap, targetDate, field) {
  const knownDates = Object.keys(dateMap).sort();
  let before = null, after = null;

  for (const d of knownDates) {
    if (d < targetDate && dateMap[d][field] > 0) before = { date: d, val: dateMap[d][field] };
    if (d > targetDate && dateMap[d][field] > 0 && !after) after = { date: d, val: dateMap[d][field] };
  }

  if (before && after) {
    // Linear interpolation
    const totalDays = daysBetween(before.date, after.date);
    const daysFromBefore = daysBetween(before.date, targetDate);
    const ratio = daysFromBefore / totalDays;
    return before.val + (after.val - before.val) * ratio;
  } else if (before) {
    return before.val; // Carry forward
  } else if (after) {
    return after.val; // Carry backward
  }
  return 0;
}

function daysBetween(d1, d2) {
  return (new Date(d2) - new Date(d1)) / (1000 * 60 * 60 * 24);
}

main().catch(err => {
  console.error("Migration failed:", err);
  process.exit(1);
});

/**
 * One-time script to add missing SFDX Top-8 promo cards to Firestore card_updates.
 *
 * These cards exist physically but were missing from the database:
 * - SFDX#22 Long Sword (Cardmarket: 878292)
 * - SFDX#86 World Atlas (Cardmarket: 878268)
 * - SFDX#139 Edge of Night (Cardmarket: 878281)
 *
 * Run: cd functions && node seed_missing_promos.js
 */

const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

const APP_ID = "riftr-v1";

const missingPromos = [
  {
    id: "0070ee38-fa1a-4d13-a0dc-158761634ca6",
    name: "Long Sword",
    riftbound_id: "sfd-22-221",
    collector_number: "22",
    attributes: { energy: 2, might: 2, power: 1 },
    classification: { type: "Gear", supertype: null, rarity: "Rare", domain: ["Fury"] },
    text: {
      plain: "[Quick-Draw] (This has [Reaction]. When you play it, attach it to a unit you control.)[Equip] :rb_rune_fury: (:rb_rune_fury:: Attach this to a unit you control.)",
    },
    set: { set_id: "SFDX", label: "Spiritforged: Promos" },
    media: { image_url: "asset:ognx_images/sfdx_long-sword.jpg" },
    tags: ["Equipment"],
    orientation: "portrait",
    metadata: { clean_name: "Long Sword", alternate_art: false, overnumbered: false, signature: false },
    display_name: "Long Sword (SFDX)",
  },
  {
    id: "23282d80-8eec-46a8-9a8d-3ac41b5d0d8f",
    name: "World Atlas",
    riftbound_id: "sfd-86-221",
    collector_number: "86",
    attributes: { energy: 3, might: 2, power: null },
    classification: { type: "Gear", supertype: null, rarity: "Rare", domain: ["Mind"] },
    text: {
      plain: "[Equip] :rb_rune_mind: (:rb_rune_mind:: Attach this to a unit you control.)",
    },
    set: { set_id: "SFDX", label: "Spiritforged: Promos" },
    media: { image_url: "asset:ognx_images/sfdx_world-atlas.jpg" },
    tags: ["Equipment"],
    orientation: "portrait",
    metadata: { clean_name: "World Atlas", alternate_art: false, overnumbered: false, signature: false },
    display_name: "World Atlas (SFDX)",
  },
  {
    id: "623e3107-b774-45de-bbbc-f17595f097e2",
    name: "Edge of Night",
    riftbound_id: "sfd-139-221",
    collector_number: "139",
    attributes: { energy: 3, might: 2, power: null },
    classification: { type: "Gear", supertype: null, rarity: "Rare", domain: ["Chaos"] },
    text: {
      plain: "[Hidden] (Hide now for :rb_rune_rainbow: to react with later for :rb_energy_0:.)When you play this from [Hidden], give the equipped unit +2 this turn.",
    },
    set: { set_id: "SFDX", label: "Spiritforged: Promos" },
    media: { image_url: "asset:ognx_images/sfdx_edge-of-night.jpg" },
    tags: ["Equipment"],
    orientation: "portrait",
    metadata: { clean_name: "Edge of Night", alternate_art: false, overnumbered: false, signature: false },
    display_name: "Edge of Night (SFDX)",
  },
];

async function main() {
  const updatesRef = db.collection("artifacts").doc(APP_ID).collection("card_updates");

  const batch = db.batch();
  for (const card of missingPromos) {
    const docId = card.riftbound_id.replace(/\//g, "-");
    batch.set(updatesRef.doc(docId), card);
    console.log(`Writing: ${card.set.set_id}#${card.collector_number} ${card.name} → ${docId}`);
  }

  await batch.commit();
  console.log(`\nDone! ${missingPromos.length} cards written to card_updates.`);
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });

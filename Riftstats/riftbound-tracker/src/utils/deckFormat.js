/**
 * Deck Import/Export utilities
 * Supports two formats:
 * 1. Text format (human-readable sections)
 * 2. TTS format (Tabletop Simulator codes, space-separated)
 */

// ========================================
// FORMAT DETECTION
// ========================================
const TTS_CODE_PATTERN = /^[A-Z]{2,4}-\d{2,4}-\d+$/;

export function detectFormat(text) {
  const trimmed = text.trim();
  // If most tokens match TTS pattern, it's TTS
  const tokens = trimmed.split(/\s+/);
  const ttsMatches = tokens.filter(t => TTS_CODE_PATTERN.test(t)).length;
  if (ttsMatches > tokens.length * 0.5 && ttsMatches >= 3) return 'tts';
  return 'text';
}


// ========================================
// EXPORT - TEXT FORMAT
// ========================================
export function exportDeck(deck, allCards, cardLookup) {
  const lines = [];

  const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
  lines.push('Legend:');
  if (legendCard) {
    lines.push(`1 ${legendCard.name}`);
  }

  const champions = [];
  const mainCards = [];

  for (const [cardId, count] of Object.entries(deck.mainDeck || {})) {
    const card = cardLookup?.get(cardId) || allCards.find(c => c.id === cardId);
    if (!card) continue;
    if (card.classification?.type === 'Champion Unit') {
      champions.push({ name: card.name, count });
    } else {
      mainCards.push({ name: card.name, count });
    }
  }

  if (champions.length > 0) {
    lines.push('Champion:');
    champions.sort((a, b) => a.name.localeCompare(b.name));
    for (const { name, count } of champions) lines.push(`${count} ${name}`);
  }

  lines.push('MainDeck:');
  mainCards.sort((a, b) => a.name.localeCompare(b.name));
  for (const { name, count } of mainCards) lines.push(`${count} ${name}`);

  lines.push('Battlefields:');
  for (const bf of (deck.battlefields || [])) lines.push(`1 ${bf.name}`);

  const legendDomains = legendCard?.classification?.domain || [];
  lines.push('Runes:');
  if (legendDomains.length >= 1 && (deck.runeCount1 || 0) > 0)
    lines.push(`${deck.runeCount1} ${legendDomains[0]} Rune`);
  if (legendDomains.length >= 2 && (deck.runeCount2 || 0) > 0)
    lines.push(`${deck.runeCount2} ${legendDomains[1]} Rune`);

  const sideCards = [];
  for (const [cardId, count] of Object.entries(deck.sideboard || {})) {
    const card = cardLookup?.get(cardId) || allCards.find(c => c.id === cardId);
    if (!card) continue;
    sideCards.push({ name: card.name, count });
  }
  lines.push('Sideboard:');
  sideCards.sort((a, b) => a.name.localeCompare(b.name));
  for (const { name, count } of sideCards) lines.push(`${count} ${name}`);

  return lines.join('\n');
}


// ========================================
// EXPORT - TTS FORMAT
// ========================================
function cardToTtsCode(card) {
  if (!card?.set?.set_id || card.collector_number == null) return null;
  const set = card.set.set_id.toUpperCase();
  const num = String(card.collector_number).padStart(3, '0');
  // Variant: 1 for standard, 2 for alternate art, 3 for signature, etc.
  let variant = 1;
  if (card.metadata?.alternate_art) variant = 2;
  if (card.metadata?.signature) variant = 3;
  if (card.metadata?.overnumbered) variant = 2;
  return `${set}-${num}-${variant}`;
}

export function exportDeckTts(deck, allCards, cardLookup) {
  const codes = [];

  // Legend
  const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
  if (legendCard) {
    const code = cardToTtsCode(legendCard);
    if (code) codes.push(code);
  }

  // Champions + Main Deck
  for (const [cardId, count] of Object.entries(deck.mainDeck || {})) {
    const card = cardLookup?.get(cardId) || allCards.find(c => c.id === cardId);
    if (!card) continue;
    const code = cardToTtsCode(card);
    if (code) for (let i = 0; i < count; i++) codes.push(code);
  }

  // Battlefields
  for (const bf of (deck.battlefields || [])) {
    const code = cardToTtsCode(bf);
    if (code) codes.push(code);
  }

  // Runes - need to find rune cards by name
  const legendDomains = legendCard?.classification?.domain || [];
  const runeEntries = [];
  if (legendDomains[0]) runeEntries.push({ name: `${legendDomains[0]} Rune`, count: deck.runeCount1 || 0 });
  if (legendDomains[1]) runeEntries.push({ name: `${legendDomains[1]} Rune`, count: deck.runeCount2 || 0 });

  for (const { name, count } of runeEntries) {
    const runeCard = cardLookup?.get(name) || allCards.find(c => c.name === name);
    if (runeCard) {
      const code = cardToTtsCode(runeCard);
      if (code) for (let i = 0; i < count; i++) codes.push(code);
    }
  }

  // Sideboard
  for (const [cardId, count] of Object.entries(deck.sideboard || {})) {
    const card = cardLookup?.get(cardId) || allCards.find(c => c.id === cardId);
    if (!card) continue;
    const code = cardToTtsCode(card);
    if (code) for (let i = 0; i < count; i++) codes.push(code);
  }

  return codes.join(' ');
}


// ========================================
// IMPORT - TTS FORMAT
// ========================================
export function importDeckTts(text, allCards, cardLookup) {
  const errors = [];
  const warnings = [];

  // Build lookup: "OGN-021" → card (by set + collector_number)
  const codeLookup = new Map();
  for (const card of allCards) {
    if (!card.set?.set_id || card.collector_number == null) continue;
    const set = card.set.set_id.toUpperCase();
    const num = String(card.collector_number).padStart(3, '0');
    const key = `${set}-${num}`;
    const existing = codeLookup.get(key);
    if (!existing) {
      codeLookup.set(key, card);
    } else {
      // Prefer standard version
      const existingIsAlt = existing.metadata?.alternate_art || existing.metadata?.overnumbered || existing.metadata?.signature;
      const newIsStandard = !card.metadata?.alternate_art && !card.metadata?.overnumbered && !card.metadata?.signature;
      if (existingIsAlt && newIsStandard) {
        codeLookup.set(key, card);
      }
    }
  }

  // Parse all TTS codes
  const tokens = text.trim().split(/\s+/).filter(t => TTS_CODE_PATTERN.test(t));
  if (tokens.length === 0) {
    errors.push('No valid TTS codes found');
    return { success: false, errors, warnings, deck: {}, summary: { legend: 'None', mainCount: 0, sideCount: 0, battlefieldCount: 0 } };
  }

  // Count occurrences and resolve cards
  const cardCounts = new Map(); // card → count
  const notFound = new Map();   // code → count

  for (const code of tokens) {
    // Parse: "OGN-036-1" → baseCode="OGN-036", variant=1
    const parts = code.split('-');
    const baseCode = `${parts[0]}-${parts[1]}`;

    const card = codeLookup.get(baseCode);
    if (card) {
      cardCounts.set(card, (cardCounts.get(card) || 0) + 1);
    } else {
      notFound.set(code, (notFound.get(code) || 0) + 1);
    }
  }

  for (const [code, count] of notFound) {
    warnings.push(`Code not found: "${code}" (×${count})`);
  }

  // Categorize cards by type
  let selectedLegend = null;
  const battlefields = [];
  const runeMap = {}; // domain → count
  const deckCards = []; // { card, count } for main + side
  let runeCount1 = 0;
  let runeCount2 = 0;

  for (const [card, count] of cardCounts) {
    const type = card.classification?.type;
    const name = card.name;

    if (type === 'Legend') {
      selectedLegend = card;
    } else if (type === 'Battlefield') {
      battlefields.push(card);
    } else if (type === 'Rune' || name.match(/\bRune$/i)) {
      // Extract rune domain from name: "Chaos Rune" → "Chaos"
      const domain = name.replace(/\s*Rune$/i, '').trim();
      runeMap[domain] = (runeMap[domain] || 0) + count;
    } else {
      deckCards.push({ card, count });
    }
  }

  // Assign rune counts based on legend domains
  if (selectedLegend) {
    const domains = selectedLegend.classification?.domain || [];
    if (domains[0] && runeMap[domains[0]]) runeCount1 = runeMap[domains[0]];
    if (domains[1] && runeMap[domains[1]]) runeCount2 = runeMap[domains[1]];

    const totalRunes = runeCount1 + runeCount2;
    const allRuneTotal = Object.values(runeMap).reduce((s, c) => s + c, 0);
    if (allRuneTotal > 0 && totalRunes !== allRuneTotal) {
      warnings.push(`Some runes didn't match legend domains (${totalRunes}/${allRuneTotal} assigned)`);
    }
  }

  // Split deck cards: first 40 → main, rest → sideboard
  const mainDeck = {};
  const sideboard = {};
  let mainCount = 0;

  for (const { card, count } of deckCards) {
    if (mainCount >= 40) {
      // All to sideboard
      sideboard[card.id] = (sideboard[card.id] || 0) + count;
    } else if (mainCount + count <= 40) {
      // All to main
      mainDeck[card.id] = (mainDeck[card.id] || 0) + count;
      mainCount += count;
    } else {
      // Split between main and sideboard
      const toMain = 40 - mainCount;
      const toSide = count - toMain;
      mainDeck[card.id] = (mainDeck[card.id] || 0) + toMain;
      sideboard[card.id] = (sideboard[card.id] || 0) + toSide;
      mainCount = 40;
    }
  }

  const sideCount = Object.values(sideboard).reduce((s, c) => s + c, 0);
  if (sideCount > 0) {
    warnings.push(`${sideCount} cards auto-assigned to sideboard (overflow from 40 main)`);
  }

  return {
    success: errors.length === 0,
    errors,
    warnings,
    deck: { selectedLegend, battlefields, runeCount1, runeCount2, mainDeck, sideboard },
    summary: {
      legend: selectedLegend?.name || 'None',
      mainCount: Object.values(mainDeck).reduce((s, c) => s + c, 0),
      sideCount,
      battlefieldCount: battlefields.length,
    }
  };
}


// ========================================
// UNIFIED IMPORT (auto-detect format)
// ========================================
export function importDeck(text, allCards, cardLookup) {
  const format = detectFormat(text);
  if (format === 'tts') {
    return importDeckTts(text, allCards, cardLookup);
  }
  return importDeckText(text, allCards, cardLookup);
}


// ========================================
// Section name normalization (text format)
// ========================================
const SECTION_ALIASES = {
  'legend': 'legend', 'legends': 'legend',
  'champion': 'champion', 'champions': 'champion',
  'maindeck': 'maindeck', 'main deck': 'maindeck', 'main': 'maindeck', 'deck': 'maindeck',
  'battlefield': 'battlefields', 'battlefields': 'battlefields', 'battle fields': 'battlefields',
  'rune': 'runes', 'runes': 'runes',
  'sideboard': 'sideboard', 'side board': 'sideboard', 'sidedeck': 'sideboard', 'side deck': 'sideboard', 'side': 'sideboard',
};

function normalizeSection(text) {
  const clean = text.replace(/[:\s]+$/g, '').trim().toLowerCase();
  return SECTION_ALIASES[clean] || null;
}


// ========================================
// IMPORT - TEXT FORMAT
// ========================================
export function importDeckText(text, allCards, cardLookup) {
  const errors = [];
  const warnings = [];

  // Build name lookup (case-insensitive, prefer standard art)
  const nameLookup = new Map();
  for (const card of allCards) {
    const key = card.name.toLowerCase().trim();
    const existing = nameLookup.get(key);
    if (!existing) {
      nameLookup.set(key, card);
    } else {
      const existingIsAlt = existing.metadata?.alternate_art || existing.metadata?.overnumbered || existing.metadata?.signature;
      const newIsStandard = !card.metadata?.alternate_art && !card.metadata?.overnumbered && !card.metadata?.signature;
      if (existingIsAlt && newIsStandard) {
        nameLookup.set(key, card);
      }
    }
  }

  const cleanNameLookup = new Map();
  for (const card of allCards) {
    const cleanName = card.metadata?.clean_name?.toLowerCase().trim();
    if (cleanName && !cleanNameLookup.has(cleanName)) {
      cleanNameLookup.set(cleanName, card);
    }
  }

  const findCard = (name) => {
    const trimmed = name.trim();
    const lower = trimmed.toLowerCase();

    if (cardLookup) {
      const exact = cardLookup.get(trimmed);
      if (exact) return { card: exact, matchType: 'exact' };
    }

    const ciMatch = nameLookup.get(lower);
    if (ciMatch) return { card: ciMatch, matchType: 'exact' };

    const cleanMatch = cleanNameLookup.get(lower);
    if (cleanMatch) return { card: cleanMatch, matchType: 'clean' };

    let bestMatch = null;
    let bestScore = 0;

    for (const [cardName, card] of nameLookup) {
      if (lower.includes(cardName) || cardName.includes(lower)) {
        const score = Math.min(lower.length, cardName.length) / Math.max(lower.length, cardName.length);
        if (score > bestScore) { bestScore = score; bestMatch = card; }
      }
    }

    if (!bestMatch) {
      const commaIdx = lower.indexOf(',');
      if (commaIdx > 0) {
        const firstName = lower.substring(0, commaIdx).trim();
        const candidates = [];
        for (const [cardName, card] of nameLookup) {
          if (cardName.startsWith(firstName + ',') || cardName === firstName) candidates.push(card);
        }
        if (candidates.length === 1) { bestMatch = candidates[0]; bestScore = 0.5; }
        if (candidates.length > 1) { bestMatch = candidates[0]; bestScore = 0.4; }
      }
    }

    if (bestMatch && bestScore >= 0.3) return { card: bestMatch, matchType: 'fuzzy', score: bestScore };
    return null;
  };

  const findCardWithType = (name, preferredType) => {
    const result = findCard(name);
    if (!result) return null;
    if (result.matchType === 'exact') return result;

    if (preferredType && result.matchType === 'fuzzy') {
      const lower = name.toLowerCase().trim();
      const commaIdx = lower.indexOf(',');
      const firstName = commaIdx > 0 ? lower.substring(0, commaIdx).trim() : lower;

      for (const [cardName, card] of nameLookup) {
        if ((cardName.startsWith(firstName + ',') || cardName === firstName) &&
            card.classification?.type === preferredType) {
          return { card, matchType: 'fuzzy-typed', score: 0.6 };
        }
      }
    }
    return result;
  };

  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  let currentSection = null;
  const sections = { legend: [], champion: [], maindeck: [], battlefields: [], runes: [], sideboard: [] };

  for (const line of lines) {
    const possibleSection = normalizeSection(line);
    if (possibleSection && sections[possibleSection] !== undefined) {
      currentSection = possibleSection;
      continue;
    }
    const cardMatch = line.match(/^(\d+)\s+(.+)$/);
    if (cardMatch && currentSection) {
      sections[currentSection].push({ count: parseInt(cardMatch[1], 10), name: cardMatch[2].trim() });
    }
  }

  let selectedLegend = null;
  const mainDeck = {};
  const sideboard = {};
  const battlefields = [];
  let runeCount1 = 6;
  let runeCount2 = 6;

  if (sections.legend.length > 0) {
    const { name } = sections.legend[0];
    const result = findCardWithType(name, 'Legend');
    if (result) {
      selectedLegend = result.card;
      if (result.matchType !== 'exact') warnings.push(`Legend: "${name}" → matched "${result.card.name}" (${result.matchType})`);
    } else {
      errors.push(`Legend not found: "${name}"`);
    }
  } else {
    errors.push('No Legend section found');
  }

  for (const { count, name } of sections.champion) {
    const result = findCardWithType(name, 'Champion Unit');
    if (result) {
      mainDeck[result.card.id] = (mainDeck[result.card.id] || 0) + count;
      if (result.matchType !== 'exact') warnings.push(`Champion: "${name}" → matched "${result.card.name}" (${result.matchType})`);
    } else {
      warnings.push(`Champion not found: "${name}"`);
    }
  }

  for (const { count, name } of sections.maindeck) {
    const result = findCard(name);
    if (result) {
      mainDeck[result.card.id] = (mainDeck[result.card.id] || 0) + count;
      if (result.matchType !== 'exact') warnings.push(`Card: "${name}" → matched "${result.card.name}" (${result.matchType})`);
    } else {
      warnings.push(`Card not found: "${name}"`);
    }
  }

  for (const { count, name } of sections.battlefields) {
    const result = findCardWithType(name, 'Battlefield');
    if (result) {
      battlefields.push(result.card);
      if (result.matchType !== 'exact') warnings.push(`Battlefield: "${name}" → matched "${result.card.name}" (${result.matchType})`);
    } else {
      warnings.push(`Battlefield not found: "${name}"`);
    }
  }

  if (sections.runes.length > 0 && selectedLegend) {
    const domains = selectedLegend.classification?.domain || [];
    runeCount1 = 0;
    runeCount2 = 0;
    for (const { count, name } of sections.runes) {
      const runeName = name.replace(/\s*Rune\s*$/i, '').trim();
      if (domains[0] && runeName.toLowerCase() === domains[0].toLowerCase()) runeCount1 = count;
      else if (domains[1] && runeName.toLowerCase() === domains[1].toLowerCase()) runeCount2 = count;
      else warnings.push(`Unknown rune: "${name}"`);
    }
    const total = runeCount1 + runeCount2;
    if (total !== 12) warnings.push(`Rune total is ${total}, expected 12`);
  }

  for (const { count, name } of sections.sideboard) {
    const result = findCard(name);
    if (result) {
      sideboard[result.card.id] = (sideboard[result.card.id] || 0) + count;
      if (result.matchType !== 'exact') warnings.push(`Sideboard: "${name}" → matched "${result.card.name}" (${result.matchType})`);
    } else {
      warnings.push(`Sideboard card not found: "${name}"`);
    }
  }

  const mainCount = Object.values(mainDeck).reduce((s, c) => s + c, 0);
  const sideCount = Object.values(sideboard).reduce((s, c) => s + c, 0);

  return {
    success: errors.length === 0,
    errors,
    warnings,
    deck: { selectedLegend, battlefields, runeCount1, runeCount2, mainDeck, sideboard },
    summary: { legend: selectedLegend?.name || 'None', mainCount, sideCount, battlefieldCount: battlefields.length }
  };
}

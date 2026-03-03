import { computeStats } from '../utils/computeStats';

/**
 * Generates realistic demo data for Riot Games reviewers.
 * Uses real cards from the API data — no hardcoded IDs.
 */
export function generateDemoData(allCards, cardLookup) {
  if (!allCards || allCards.length === 0) return null;

  // --- Helpers ---
  const standard = (c) => !c.metadata?.alternate_art && !c.metadata?.overnumbered && !c.metadata?.signature;
  const byType = (type) => allCards.filter(c => c.classification?.type === type && standard(c));
  const uniqueByName = (arr) => [...new Map(arr.map(c => [c.name, c])).values()];

  const legends = uniqueByName(byType('Legend'));
  const battlefields = uniqueByName(byType('Battlefield'));
  const runes = uniqueByName(byType('Rune'));
  const deckableCards = uniqueByName(allCards.filter(c =>
    ['Unit', 'Spell', 'Gear'].includes(c.classification?.type) && standard(c) &&
    c.classification?.supertype !== 'Token'
  ));

  if (legends.length < 2 || battlefields.length < 3) return null;

  // Pick two legends for demo decks
  const jinx = legends.find(l => l.name.includes('Jinx')) || legends[0];
  const ahri = legends.find(l => l.name.includes('Ahri')) || legends[1];

  // Build a valid demo deck from a legend
  function buildDemoDeck(legend, deckName, description) {
    const domains = legend.classification?.domain || [];

    // Find cards matching legend domains (single-domain only)
    const matchingCards = deckableCards.filter(c => {
      const cardDomains = c.classification?.domain || [];
      return cardDomains.every(d => domains.includes(d));
    });

    // Build main deck: 40 cards (pick cards, max 3 copies each)
    const mainDeck = {};
    let mainCount = 0;
    for (const card of matchingCards) {
      if (mainCount >= 40) break;
      const copies = Math.min(3, 40 - mainCount);
      mainDeck[card.id] = copies;
      mainCount += copies;
    }
    // Fill remainder with whatever we have
    if (mainCount < 40) {
      for (const card of deckableCards) {
        if (mainCount >= 40) break;
        if (mainDeck[card.id]) continue;
        const cardDomains = card.classification?.domain || [];
        if (cardDomains.length === 1 && domains.includes(cardDomains[0])) {
          const copies = Math.min(3, 40 - mainCount);
          mainDeck[card.id] = copies;
          mainCount += copies;
        }
      }
    }

    // Pick 3 battlefields
    const deckBFs = battlefields.slice(0, 3).map(bf => ({
      id: bf.id, name: bf.name, media: bf.media,
    }));

    // Runes: 6+6 of the two domain runes
    const rune1 = runes.find(r => r.classification?.domain?.[0] === domains[0]);
    const rune2 = runes.find(r => r.classification?.domain?.[0] === (domains[1] || domains[0]));

    const now = new Date().toISOString();
    return {
      id: `demo-deck-${deckName.toLowerCase().replace(/\s+/g, '-')}`,
      name: deckName,
      description,
      legend: legend.id,
      legendData: {
        id: legend.id,
        name: legend.name,
        media: legend.media,
        classification: legend.classification,
      },
      battlefields: deckBFs,
      runeCount1: 6,
      runeCount2: 6,
      mainDeck,
      sideboard: {},
      createdAt: now,
      updatedAt: now,
    };
  }

  const demoDeck1 = buildDemoDeck(jinx, 'Jinx Aggro', 'Fast aggro deck with burn finishers');
  const demoDeck2 = buildDemoDeck(ahri, 'Ahri Control', 'Control deck with card advantage');
  const demoDecks = [demoDeck1, demoDeck2];

  // --- Demo matches ---
  const opponents = ['Ahri', 'Jinx', 'Yasuo', 'Darius', 'Sett', 'Teemo', 'Garen', 'Miss Fortune', 'Kai\'Sa', 'Lux', 'Azir', 'Viktor'];
  const bfIds = demoDeck1.battlefields.map(bf => bf.id);

  function makeMatch(deck, oppName, result, format, daysAgo, isFirst, notes) {
    const ts = new Date();
    ts.setDate(ts.getDate() - daysAgo);
    ts.setHours(Math.floor(Math.random() * 12) + 10, Math.floor(Math.random() * 60));

    // Build games array based on format
    const games = [];
    if (format === 'bo1') {
      const myS = result === 'win' ? 1 : result === 'draw' ? 0 : 0;
      const oppS = result === 'loss' ? 1 : 0;
      games.push({
        myScore: myS,
        oppScore: oppS,
        result,
        isFirst,
        bfChosen: false,
        battlefieldId: bfIds[Math.floor(Math.random() * 3)],
      });
    } else if (format === 'bo3') {
      // Create realistic bo3 games
      const myWins = result === 'win' ? 2 : Math.floor(Math.random() * 2);
      const oppWins = result === 'loss' ? 2 : (result === 'win' ? Math.floor(Math.random() * 2) : 1);
      const gameResults = [];
      let mw = 0, ow = 0;
      while (mw < 2 && ow < 2) {
        if (mw < myWins && (ow >= oppWins || Math.random() > 0.4)) {
          gameResults.push('win'); mw++;
        } else {
          gameResults.push('loss'); ow++;
        }
      }
      gameResults.forEach((gr, i) => {
        games.push({
          myScore: gr === 'win' ? 1 : 0,
          oppScore: gr === 'loss' ? 1 : 0,
          result: gr,
          isFirst: i === 0 ? isFirst : !isFirst,
          bfChosen: i > 0,
          battlefieldId: bfIds[i % 3],
        });
      });
    } else {
      // bo2
      const g1Result = Math.random() > 0.5 ? 'win' : 'loss';
      const g2Result = result === 'win' ? 'win' : (g1Result === 'win' ? 'loss' : (Math.random() > 0.5 ? 'win' : 'loss'));
      [g1Result, g2Result].forEach((gr, i) => {
        games.push({
          myScore: gr === 'win' ? 1 : 0,
          oppScore: gr === 'loss' ? 1 : 0,
          result: gr,
          isFirst: i === 0 ? isFirst : !isFirst,
          bfChosen: i > 0,
          battlefieldId: bfIds[i % 3],
        });
      });
    }

    const myScore = games.filter(g => g.result === 'win').length;
    const oppScore = games.filter(g => g.result === 'loss').length;

    return {
      id: `demo-match-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      deckId: deck.id,
      deckName: deck.name,
      legendName: deck.legendData?.name || null,
      opponent: oppName,
      isFirst,
      myScore,
      oppScore,
      result,
      format,
      games,
      notes: notes || '',
      timestamp: ts.toISOString(),
    };
  }

  const demoMatches = [
    // Jinx Aggro matches (spread over 14 days)
    makeMatch(demoDeck1, 'Yasuo',         'win',  'bo1', 0,  true,  ''),
    makeMatch(demoDeck1, 'Darius',        'win',  'bo3', 1,  false, 'Close game 3, topdecked lethal'),
    makeMatch(demoDeck1, 'Ahri',          'loss', 'bo1', 1,  true,  ''),
    makeMatch(demoDeck1, 'Sett',          'win',  'bo1', 2,  false, ''),
    makeMatch(demoDeck1, 'Teemo',         'win',  'bo3', 2,  true,  'Easy matchup'),
    makeMatch(demoDeck1, 'Miss Fortune',  'loss', 'bo1', 3,  false, 'Bricked hand'),
    makeMatch(demoDeck1, 'Garen',         'win',  'bo1', 4,  true,  ''),
    makeMatch(demoDeck1, 'Lux',           'win',  'bo3', 5,  false, ''),
    makeMatch(demoDeck1, 'Azir',          'loss', 'bo1', 6,  true,  ''),
    makeMatch(demoDeck1, 'Jinx',          'win',  'bo1', 7,  false, 'Mirror match'),
    makeMatch(demoDeck1, 'Kai\'Sa',       'draw', 'bo1', 8,  true,  'Time ran out'),

    // Ahri Control matches
    makeMatch(demoDeck2, 'Viktor',        'win',  'bo1', 0,  false, ''),
    makeMatch(demoDeck2, 'Darius',        'loss', 'bo3', 1,  true,  'Too aggressive, could not stabilize'),
    makeMatch(demoDeck2, 'Kai\'Sa',       'win',  'bo1', 3,  false, ''),
    makeMatch(demoDeck2, 'Yasuo',         'win',  'bo1', 4,  true,  ''),
    makeMatch(demoDeck2, 'Garen',         'loss', 'bo1', 5,  false, ''),
    makeMatch(demoDeck2, 'Sett',          'win',  'bo3', 7,  true,  'Sided in removal, cleaned up G2+G3'),
    makeMatch(demoDeck2, 'Ahri',          'win',  'bo1', 9,  false, ''),
    makeMatch(demoDeck2, 'Teemo',         'loss', 'bo1', 11, true,  'Mushroom lethal on turn 7'),
    makeMatch(demoDeck2, 'Jinx',          'win',  'bo1', 13, false, ''),
    makeMatch(demoDeck2, 'Lux',           'draw', 'bo1', 10, true,  'Both at 0-0, agreed draw'),
  ];

  // Compute stats
  const demoStats = computeStats(demoMatches);

  // --- Demo collection (all cards from both decks) ---
  const demoCollection = {};
  for (const deck of demoDecks) {
    // Legend
    if (deck.legend) demoCollection[deck.legend] = 1;
    // Main deck cards
    for (const [cardId, qty] of Object.entries(deck.mainDeck || {})) {
      demoCollection[cardId] = Math.max(demoCollection[cardId] || 0, qty);
    }
    // Sideboard
    for (const [cardId, qty] of Object.entries(deck.sideboard || {})) {
      demoCollection[cardId] = Math.max(demoCollection[cardId] || 0, qty);
    }
    // Battlefields
    for (const bf of (deck.battlefields || [])) {
      demoCollection[bf.id] = 1;
    }
  }

  return { demoMatches, demoDecks, demoStats, demoCollection };
}

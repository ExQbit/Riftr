/**
 * Meta Deck Filter Utilities
 * Extract filter options and apply filters to meta deck collections.
 */

/** Extract short legend name: "Draven, Glorious Executioner" → "Draven" */
export function getShortLegendName(fullName) {
  if (!fullName) return '';
  // Handle "Name, Title" and "Name, Title - Starter" patterns
  const commaIdx = fullName.indexOf(',');
  return commaIdx > 0 ? fullName.substring(0, commaIdx).trim() : fullName;
}

/** Shorten tournament name for dropdown display */
export function getShortEventName(source) {
  if (!source) return '';
  // Extract city name from tournament strings
  const patterns = [
    /^(\w+)\s+Regional/i,       // "Bologna Regional Qualifier" → "Bologna"
    /^(\w+)\s+S\d+\s+Regional/i, // "Fuzhou S2 Regional Open" → "Fuzhou"
    /^SCG\s+CON\s+(\w+)/i,       // "SCG CON Vegas 10K" → "Vegas"
    /^(\w+)\s+Saturday/i,        // "Orlando Saturday 10K" → "Orlando"
    /^CCS\s+.*?(\w+)\s+\$?10K/i, // "CCS Riftbound $10K Weekend" → fallback
  ];
  for (const pat of patterns) {
    const m = source.match(pat);
    if (m) return m[1];
  }
  // Fallback: first word
  return source.split(' ')[0];
}

/**
 * Extract all unique filter options from meta decks.
 * Returns { legends: [...], events: [...], sets: [...] }
 */
export function extractFilterOptions(metaDecks) {
  const legendCounts = {};
  const eventCounts = {};
  const setCounts = {};

  for (const deck of metaDecks) {
    // Legend (include media for card image display)
    const legendName = deck.legendData?.name || '';
    const shortLegend = getShortLegendName(legendName);
    if (shortLegend) {
      if (!legendCounts[shortLegend]) {
        legendCounts[shortLegend] = {
          name: legendName,
          shortName: shortLegend,
          media: deck.legendData?.media || null,
          count: 0,
        };
      }
      legendCounts[shortLegend].count++;
    }

    // Event/tournament
    const source = deck.source || '';
    if (source) {
      if (!eventCounts[source]) eventCounts[source] = { source, shortName: getShortEventName(source), count: 0 };
      eventCounts[source].count++;
    }

    // Sets
    for (const setId of (deck.sets || [])) {
      if (!setCounts[setId]) setCounts[setId] = { setId, count: 0 };
      setCounts[setId].count++;
    }
  }

  // Sort by count descending
  const legends = Object.values(legendCounts).sort((a, b) => b.count - a.count);
  const events = Object.values(eventCounts).sort((a, b) => b.count - a.count);
  const setOrder = ['OGN', 'OGS', 'SFD'];
  const sets = Object.values(setCounts).sort((a, b) => setOrder.indexOf(a.setId) - setOrder.indexOf(b.setId));

  return { legends, events, sets };
}

/**
 * Apply filters to meta decks.
 * @param {Array} decks - Meta deck array
 * @param {Object} filters - { legends: Set<shortName>, events: Set<source>, sets: Set<setId> }
 * @returns {Array} Filtered decks
 */
export function filterMetaDecks(decks, filters) {
  if (!filters) return decks;
  const { legends, events, sets } = filters;
  const hasLegendFilter = legends && legends.size > 0;
  const hasEventFilter = events && events.size > 0;
  const hasSetFilter = sets && sets.size > 0;

  if (!hasLegendFilter && !hasEventFilter && !hasSetFilter) return decks;

  return decks.filter(deck => {
    if (hasLegendFilter) {
      const shortName = getShortLegendName(deck.legendData?.name || '');
      if (!legends.has(shortName)) return false;
    }
    if (hasEventFilter) {
      if (!events.has(deck.source || '')) return false;
    }
    if (hasSetFilter) {
      const deckSets = deck.sets || [];
      if (!deckSets.some(s => sets.has(s))) return false;
    }
    return true;
  });
}

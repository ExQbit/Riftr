import { useState, useMemo } from 'react';

// Static card data - bundled with the app at build time, no API call needed.
// To update: run `node scripts/fetch-cards.mjs` when a new set drops.
// Vite handles JSON imports natively - this becomes part of the JS bundle.
import staticCards from '../data/cards.json';

export default function useCards() {
  const [allCards] = useState(staticCards);
  const loading = false;

  // O(1) lookup by name or id
  // For names with multiple versions (alternate art), prefer the standard version
  const cardLookup = useMemo(() => {
    const map = new Map();
    allCards.forEach(card => {
      // ID lookup is always unique
      map.set(card.id, card);

      // Name lookup: prefer non-alternate-art (standard) version
      const existing = map.get(card.name);
      if (!existing) {
        map.set(card.name, card);
      } else {
        // Replace if current is alt-art and new one is standard
        const existingIsAlt = existing.metadata?.alternate_art || existing.metadata?.overnumbered || existing.metadata?.signature;
        const newIsStandard = !card.metadata?.alternate_art && !card.metadata?.overnumbered && !card.metadata?.signature;
        if (existingIsAlt && newIsStandard) {
          map.set(card.name, card);
        }
      }
    });
    return map;
  }, [allCards]);

  return { allCards, cardLookup, loading };
}

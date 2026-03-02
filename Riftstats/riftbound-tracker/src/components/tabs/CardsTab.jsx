import React, { useState, useMemo } from 'react';
import { Search } from 'lucide-react';
import FilterDropdown from '../shared/FilterDropdown';
import CardPreview from '../shared/CardPreview';
import { CARD_CONTAINER, CARD_IMAGE, CARD_ASPECT_PORTRAIT, CARD_ASPECT_LANDSCAPE } from '../../constants/design';
import { RUNE_COLORS } from '../../constants/gameData';

// Extract base keyword from text like "[Hidden]", "[Shield 3]" → "Hidden", "Shield"
const parseKeywords = (text) => {
  if (!text) return [];
  return [...new Set(
    (text.match(/\[([^\]]+)\]/g) || [])
      .map(m => m.slice(1, -1).replace(/\s+\d+$/, ''))
  )];
};

const CardsTab = React.memo(function CardsTab({ allCards }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [domainFilters, setDomainFilters] = useState(new Set());
  const [costFilter, setCostFilter] = useState('');
  const [rarityFilter, setRarityFilter] = useState('');
  const [setFilter, setSetFilter] = useState('');
  const [keywordFilter, setKeywordFilter] = useState('');
  const [previewCard, setPreviewCard] = useState(null);

  const filterOptions = useMemo(() => {
    const types = {}, domains = {}, costs = {}, rarities = {}, sets = {}, keywords = {};
    allCards.forEach(card => {
      const type = card.classification?.type;
      if (type) types[type] = (types[type] || 0) + 1;
      (card.classification?.domain || []).forEach(d => { domains[d] = (domains[d] || 0) + 1; });
      const cost = card.attributes?.energy;
      if (cost !== undefined && cost !== null) costs[String(cost)] = (costs[String(cost)] || 0) + 1;
      const rarity = card.classification?.rarity;
      if (rarity) rarities[rarity] = (rarities[rarity] || 0) + 1;
      const setId = card.set?.set_id;
      if (setId) sets[setId] = (sets[setId] || 0) + 1;
      parseKeywords(card.text?.plain).forEach(kw => { keywords[kw] = (keywords[kw] || 0) + 1; });
    });
    return {
      types: Object.entries(types).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      domains: Object.entries(domains).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      costs: Object.entries(costs).sort(([a], [b]) => Number(a) - Number(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      rarities: Object.entries(rarities).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      sets: Object.entries(sets).sort(([a], [b]) => b.localeCompare(a)).map(([v, c]) => ({ value: v, label: v, count: c })),
      keywords: Object.entries(keywords).sort(([, a], [, b]) => b - a).map(([v, c]) => ({ value: v, label: v, count: c })),
    };
  }, [allCards]);

  const filteredCards = useMemo(() => {
    let cards = allCards;
    if (typeFilter) cards = cards.filter(c => c.classification?.type === typeFilter);
    if (domainFilters.size > 0) cards = cards.filter(c => {
      const cardDomains = c.classification?.domain || [];
      return [...domainFilters].every(d => cardDomains.includes(d));
    });
    if (costFilter === '6+') {
      cards = cards.filter(c => (c.attributes?.energy ?? -1) >= 6);
    } else if (costFilter) {
      cards = cards.filter(c => String(c.attributes?.energy) === costFilter);
    }
    if (rarityFilter) cards = cards.filter(c => c.classification?.rarity === rarityFilter);
    if (setFilter) cards = cards.filter(c => c.set?.set_id === setFilter);
    if (keywordFilter) cards = cards.filter(c => parseKeywords(c.text?.plain).includes(keywordFilter));
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      cards = cards.filter(c =>
        c.name.toLowerCase().includes(q) ||
        (c.text?.plain || '').toLowerCase().includes(q)
      );
    }
    cards.sort((a, b) => {
      const setA = a.set?.set_id || '';
      const setB = b.set?.set_id || '';
      if (setA !== setB) return setB.localeCompare(setA);
      return (a.collector_number || 0) - (b.collector_number || 0);
    });
    return cards;
  }, [allCards, typeFilter, domainFilters, costFilter, rarityFilter, setFilter, keywordFilter, searchQuery]);

  return (
    <div className="space-y-4">
      {/* Gold Ornament Header */}
      <div className="text-center pt-3 pb-1">
        <div className="flex items-center justify-center gap-3 mb-2">
          <div className="h-px w-12 bg-gradient-to-r from-transparent to-amber-500/50" />
          <div className="w-1.5 h-1.5 rotate-45 bg-amber-500/60" />
          <div className="h-px w-12 bg-gradient-to-l from-transparent to-amber-500/50" />
        </div>
        <h2 className="text-xs font-black uppercase tracking-[0.3em] bg-gradient-to-r from-amber-200 via-yellow-100 to-amber-200 bg-clip-text text-transparent">
          Knowledge Is Power
        </h2>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-4 top-3.5 text-slate-500" size={18} />
        <input
          type="text"
          placeholder="Search cards..."
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          className="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none"
        />
      </div>

      {/* Filter Dropdowns */}
      <div className="flex gap-2 pb-1 overflow-x-auto no-scrollbar">
        {filterOptions.types.length > 1 && (
          <FilterDropdown label="Type" value={typeFilter} options={filterOptions.types} onChange={setTypeFilter} />
        )}
        {filterOptions.rarities.length > 1 && (
          <FilterDropdown label="Rarity" value={rarityFilter} options={filterOptions.rarities} onChange={setRarityFilter} />
        )}
        {filterOptions.sets.length > 1 && (
          <FilterDropdown label="Set" value={setFilter} options={filterOptions.sets} onChange={setSetFilter} />
        )}
        {filterOptions.keywords.length > 1 && (
          <FilterDropdown label="Keyword" value={keywordFilter} options={filterOptions.keywords} onChange={setKeywordFilter} />
        )}
      </div>

      {/* Domain filter icons */}
      <div className="flex items-center justify-between px-1">
        {[
          { name: 'Fury',  offset: '0px -3.5px' },
          { name: 'Mind',   offset: '-1px 0px' },
          { name: 'Chaos',  offset: '-1px 0px' },
          { name: 'Calm',   offset: '0px 0px' },
          { name: 'Body',   offset: '0px 0px' },
          { name: 'Order',  offset: '0px 1px' },
        ].map(({ name: domain, offset }) => {
          const isActive = domainFilters.has(domain);
          return (
            <button
              key={domain}
              onClick={() => setDomainFilters(prev => {
                const next = new Set(prev);
                if (next.has(domain)) {
                  next.delete(domain);
                } else if (next.size < 2) {
                  next.add(domain);
                }
                return next;
              })}
              className={`p-1.5 rounded-full transition-all active:scale-95 ${isActive ? 'ring-2 ring-amber-400/80 bg-amber-500/10' : 'opacity-40'}`}
            >
              <img src={RUNE_COLORS[domain].icon} alt={domain} className="w-10 h-10" style={{ translate: offset }} />
            </button>
          );
        })}
      </div>

      {/* Cost filter circles */}
      <div className="flex items-center justify-between px-1">
        {['0','1','2','3','4','5','6+'].map(cost => {
          const isActive = costFilter === cost;
          return (
            <button
              key={cost}
              onClick={() => setCostFilter(prev => prev === cost ? '' : cost)}
              className={`w-11 h-11 rounded-full text-xs font-black flex items-center justify-center transition-all active:scale-95 ${
                isActive
                  ? 'bg-amber-500 text-white ring-2 ring-amber-300'
                  : 'bg-slate-800 text-slate-500 opacity-60'
              }`}
            >
              {cost}
            </button>
          );
        })}
      </div>

      {/* Results divider */}
      <div className="flex items-center gap-2 px-1">
        <Search size={12} className="text-amber-500/50" />
        <span className="text-[10px] font-bold uppercase tracking-[0.15em] text-amber-500/40">{filteredCards.length} Cards</span>
        <div className="h-px flex-1 bg-gradient-to-r from-amber-500/15 to-transparent" />
      </div>

      {/* Card Grid */}
      <div className="grid grid-cols-3 gap-2">
        {filteredCards.map(card => (
          <BrowseCardItem key={card.id} card={card} onTap={() => setPreviewCard(card)} />
        ))}
      </div>

      <CardPreview card={previewCard} onClose={() => setPreviewCard(null)} />
    </div>
  );
});

function BrowseCardItem({ card, onTap }) {
  const isLandscape = card.orientation === 'landscape';
  const aspect = isLandscape ? CARD_ASPECT_LANDSCAPE : CARD_ASPECT_PORTRAIT;

  return (
    <div
      className={`relative ${isLandscape ? 'col-span-2' : ''} cursor-pointer active:scale-95 transition-transform`}
      style={{ touchAction: 'manipulation' }}
      onClick={onTap}
    >
      <div className={`${CARD_CONTAINER} ${aspect}`}>
        <img
          src={card.media?.image_url}
          alt={card.name}
          className={CARD_IMAGE}
          loading="lazy"
          draggable={false}
        />
      </div>
      <p className="text-xs font-bold text-center mt-1 truncate pointer-events-none select-none">{card.name}</p>
    </div>
  );
}

export default CardsTab;

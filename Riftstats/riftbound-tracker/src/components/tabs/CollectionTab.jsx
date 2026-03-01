import React, { useState, useMemo, useEffect } from 'react';
import { Search, BookOpen, Package, Check } from 'lucide-react';
import FilterDropdown from '../shared/FilterDropdown';
import CardPreview, { useLongPress } from '../shared/CardPreview';
import { CARD_CONTAINER, CARD_IMAGE, CARD_ASPECT_PORTRAIT, CARD_ASPECT_LANDSCAPE } from '../../constants/design';
import { RUNE_COLORS } from '../../constants/gameData';

const parseKeywords = (text) => {
  if (!text) return [];
  return [...new Set(
    (text.match(/\[([^\]]+)\]/g) || [])
      .map(m => m.slice(1, -1).replace(/\s+\d+$/, ''))
  )];
};

export default function CollectionTab({ allCards, collection, addCard, removeCard, getQuantity, stats: collectionStats }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [ownershipFilter, setOwnershipFilter] = useState('all'); // all | owned | missing
  const [typeFilter, setTypeFilter] = useState('');
  const [domainFilters, setDomainFilters] = useState(new Set());
  const [setFilter, setSetFilter] = useState('');
  const [rarityFilter, setRarityFilter] = useState('');
  const [costFilter, setCostFilter] = useState('');
  const [keywordFilter, setKeywordFilter] = useState('');
  const [previewCard, setPreviewCard] = useState(null);
  const [editingCard, setEditingCard] = useState(null);

  // Close editing overlay on outside click
  useEffect(() => {
    if (!editingCard) return;
    const handler = (e) => {
      const el = document.getElementById(`col-card-${editingCard}`);
      if (el && !el.contains(e.target)) setEditingCard(null);
    };
    const timer = setTimeout(() => document.addEventListener('click', handler), 10);
    return () => { clearTimeout(timer); document.removeEventListener('click', handler); };
  }, [editingCard]);

  // Compute stats
  const stats = useMemo(() => {
    const uniqueCards = allCards.length;
    const owned = allCards.filter(c => getQuantity(c.id) > 0).length;
    const pct = uniqueCards > 0 ? ((owned / uniqueCards) * 100).toFixed(1) : '0.0';

    // Per-set breakdown
    const setMap = {};
    allCards.forEach(c => {
      const setId = c.set?.set_id || 'Unknown';
      if (!setMap[setId]) setMap[setId] = { total: 0, owned: 0 };
      setMap[setId].total++;
      if (getQuantity(c.id) > 0) setMap[setId].owned++;
    });
    const sets = Object.entries(setMap)
      .map(([id, d]) => ({
        id,
        total: d.total,
        owned: d.owned,
        pct: d.total > 0 ? ((d.owned / d.total) * 100).toFixed(1) : '0.0',
      }))
      .sort((a, b) => b.id.localeCompare(a.id));

    return { uniqueCards, owned, pct, totalCopies: collectionStats.totalCopies, sets };
  }, [allCards, getQuantity, collectionStats]);

  // Filter options
  const filterOptions = useMemo(() => {
    const types = {}, domains = {}, rarities = {}, sets = {}, keywords = {};
    allCards.forEach(card => {
      const type = card.classification?.type;
      if (type) types[type] = (types[type] || 0) + 1;
      (card.classification?.domain || []).forEach(d => { domains[d] = (domains[d] || 0) + 1; });
      const rarity = card.classification?.rarity;
      if (rarity) rarities[rarity] = (rarities[rarity] || 0) + 1;
      const setId = card.set?.set_id;
      if (setId) sets[setId] = (sets[setId] || 0) + 1;
      parseKeywords(card.text?.plain).forEach(kw => { keywords[kw] = (keywords[kw] || 0) + 1; });
    });
    return {
      types: Object.entries(types).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      domains: Object.entries(domains).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      rarities: Object.entries(rarities).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      sets: Object.entries(sets).sort(([a], [b]) => b.localeCompare(a)).map(([v, c]) => ({ value: v, label: v, count: c })),
      keywords: Object.entries(keywords).sort(([, a], [, b]) => b - a).map(([v, c]) => ({ value: v, label: v, count: c })),
    };
  }, [allCards]);

  // Filtered cards
  const filteredCards = useMemo(() => {
    let cards = allCards;
    if (ownershipFilter === 'owned') cards = cards.filter(c => getQuantity(c.id) > 0);
    if (ownershipFilter === 'missing') cards = cards.filter(c => getQuantity(c.id) === 0);
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
  }, [allCards, ownershipFilter, typeFilter, domainFilters, costFilter, rarityFilter, setFilter, keywordFilter, searchQuery, getQuantity]);

  const ownedInFilter = filteredCards.filter(c => getQuantity(c.id) > 0).length;

  const pillClass = (isActive) =>
    `px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all active:scale-95 ${
      isActive ? 'bg-riftbound-600 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'
    }`;

  return (
    <div className="space-y-4 pb-24">
      {/* ===== COLLECTION STATS ===== */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6">
        <div className="flex items-center gap-5">
          {/* Progress Ring — same size as Stats WinRateRing (140px) */}
          <div className="relative flex-shrink-0" style={{ width: 140, height: 140 }}>
            <svg width={140} height={140} className="transform -rotate-90">
              <circle cx={70} cy={70} r={60} stroke="rgba(255,255,255,0.05)" strokeWidth={10} fill="none" />
              <circle cx={70} cy={70} r={60} stroke="#7c3aed" strokeWidth={10} fill="none"
                strokeLinecap="round"
                strokeDasharray={2 * Math.PI * 60}
                strokeDashoffset={2 * Math.PI * 60 - (parseFloat(stats.pct) / 100) * 2 * Math.PI * 60}
                style={{ transition: 'stroke-dashoffset 1s ease-out' }} />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-2xl font-black text-white">{stats.pct}%</span>
              <span className="text-[9px] font-bold text-slate-500 uppercase">Complete</span>
            </div>
          </div>

          <div className="flex-1 space-y-2">
            <div>
              <p className="text-[10px] font-black text-slate-500 uppercase mb-0.5">Unique Cards</p>
              <p className="text-lg font-black text-white">
                {stats.owned} <span className="text-slate-600 text-sm">/ {stats.uniqueCards}</span>
              </p>
            </div>
            <div>
              <p className="text-[10px] font-black text-slate-500 uppercase mb-0.5">Total Copies</p>
              <p className="text-lg font-black text-riftbound-400">{stats.totalCopies}</p>
            </div>
          </div>
        </div>

        {/* Per-set progress bars */}
        {stats.sets.length > 0 && (
          <div className="mt-4 space-y-2">
            {stats.sets.map(s => (
              <div key={s.id} className="flex items-center gap-2">
                <span className="text-[10px] font-bold text-slate-400 w-16 truncate">{s.id}</span>
                <div className="flex-1 bg-slate-800 rounded-full h-2 overflow-hidden">
                  <div className="h-2 rounded-full bg-riftbound-500 transition-all duration-500"
                    style={{ width: `${s.pct}%` }} />
                </div>
                <span className="text-[10px] font-bold text-slate-500 w-20 text-right">
                  {s.owned}/{s.total} <span className="text-slate-600">({s.pct}%)</span>
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ===== OWNERSHIP FILTER ===== */}
      <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
        <button onClick={() => setOwnershipFilter('all')} className={pillClass(ownershipFilter === 'all')}>
          All ({allCards.length})
        </button>
        <button onClick={() => setOwnershipFilter('owned')} className={pillClass(ownershipFilter === 'owned')}>
          <Check size={12} className="inline mr-1" />Owned ({stats.owned})
        </button>
        <button onClick={() => setOwnershipFilter('missing')} className={pillClass(ownershipFilter === 'missing')}>
          Missing ({allCards.length - stats.owned})
        </button>
      </div>

      {/* ===== SEARCH ===== */}
      <div className="relative">
        <Search className="absolute left-4 top-3.5 text-slate-500" size={18} />
        <input
          type="text"
          placeholder="Search cards..."
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          className="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-riftbound-600 outline-none"
        />
      </div>

      {/* ===== FILTER DROPDOWNS ===== */}
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
              className={`p-1.5 rounded-full transition-all active:scale-95 ${isActive ? 'ring-2 ring-white bg-slate-800' : 'opacity-40'}`}
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
              className={`w-10 h-10 rounded-full text-xs font-black flex items-center justify-center transition-all active:scale-95 ${
                isActive
                  ? 'bg-riftbound-500 text-white ring-2 ring-riftbound-300'
                  : 'bg-slate-800 text-slate-500 opacity-60'
              }`}
            >
              {cost}
            </button>
          );
        })}
      </div>

      {/* ===== RESULTS COUNT ===== */}
      <p className="text-[10px] text-slate-500 font-bold px-1">
        {filteredCards.length} cards · {ownedInFilter} owned
      </p>

      {/* ===== CARD GRID ===== */}
      <div className="grid grid-cols-3 gap-2">
        {filteredCards.map(card => (
          <CollectionCardItem
            key={card.id}
            card={card}
            quantity={getQuantity(card.id)}
            isEditing={editingCard === card.id}
            onTap={() => {
              if (editingCard === card.id) {
                setEditingCard(null);
              } else {
                setEditingCard(card.id);
              }
            }}
            onLongPress={() => setPreviewCard(card)}
            onAdd={() => addCard(card.id)}
            onRemove={() => removeCard(card.id)}
          />
        ))}
      </div>

      <CardPreview card={previewCard} onClose={() => setPreviewCard(null)} />
    </div>
  );
}

function CollectionCardItem({ card, quantity, isEditing, onTap, onLongPress, onAdd, onRemove }) {
  const handlers = useLongPress(onLongPress, onTap);
  const isLandscape = card.orientation === 'landscape';
  const aspect = isLandscape ? CARD_ASPECT_LANDSCAPE : CARD_ASPECT_PORTRAIT;
  const isOwned = quantity > 0;

  return (
    <div
      className={`relative ${isLandscape ? 'col-span-2' : ''}`}
      style={{ touchAction: 'manipulation' }}
      {...handlers}
    >
      <div className={`${CARD_CONTAINER} ${aspect}`}>
        <img
          src={card.media?.image_url}
          alt={card.name}
          className={`${CARD_IMAGE} ${!isOwned ? 'grayscale opacity-40' : ''} transition-all`}
          loading="lazy"
          draggable={false}
        />

        {/* Quantity badge */}
        <div className={`absolute top-1 right-1 font-black text-xs rounded-full w-6 h-6 flex items-center justify-center pointer-events-none ${
          isOwned ? 'bg-riftbound-600 text-white' : 'bg-slate-800/80 text-slate-500 border border-slate-600'
        }`}>
          {quantity}
        </div>

        {/* Edit overlay */}
        {isEditing && (
          <div
            className="absolute inset-0 bg-black/60 rounded-xl flex items-center justify-center gap-3 animate-in fade-in duration-150"
            onTouchStart={(e) => e.stopPropagation()}
            onTouchEnd={(e) => e.stopPropagation()}
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onTouchEnd={(e) => { e.stopPropagation(); e.preventDefault(); onRemove(); }}
              onClick={(e) => { e.stopPropagation(); onRemove(); }}
              className={`font-black rounded-lg px-4 py-2 text-lg transition-transform ${
                quantity > 0
                  ? 'bg-red-600 active:bg-red-500 active:scale-110 text-white'
                  : 'bg-slate-700 text-slate-500'
              }`}
            >−</button>
            <span className="text-2xl font-black text-white min-w-[28px] text-center">{quantity}</span>
            <button
              onTouchEnd={(e) => { e.stopPropagation(); e.preventDefault(); onAdd(); }}
              onClick={(e) => { e.stopPropagation(); onAdd(); }}
              className="bg-riftbound-600 active:bg-riftbound-500 active:scale-110 text-white font-black rounded-lg px-4 py-2 text-lg transition-transform"
            >+</button>
          </div>
        )}
      </div>
      <p className={`text-xs font-bold text-center mt-1 truncate pointer-events-none select-none ${isOwned ? 'text-white' : 'text-slate-600'}`}>
        {card.name}
      </p>
    </div>
  );
}

import React, { useMemo, useState, useEffect, useRef, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { Search, Plus, Save, ArrowLeft, Check } from 'lucide-react';
import FilterDropdown from '../shared/FilterDropdown';
import CardPreview, { useLongPress } from '../shared/CardPreview';
import { RUNE_COLORS } from '../../constants/gameData';

function getMaxCopies(card) {
  if (!card) return 3;
  if (card.deck_limit !== undefined && card.deck_limit !== null) return card.deck_limit;
  if (card.attributes?.deck_limit !== undefined && card.attributes?.deck_limit !== null) return card.attributes.deck_limit;
  const type = card.classification?.type;
  if (type === 'Legend' || type === 'Battlefield') return 1;
  return 3;
}

export default function CardSelectionModal({
  isOpen,
  onClose,
  onDiscard,
  category,
  allCards,
  cardLookup,
  selectedLegend,
  onSelectCard,
  onRemoveCard,
  selectedBattlefields = [],
  customMainDeck = {},
  customSideboard = {},
}) {
  const [searchQuery, setSearchQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [domainFilter, setDomainFilter] = useState('');
  const [costFilter, setCostFilter] = useState('');
  const [rarityFilter, setRarityFilter] = useState('');
  const [setFilter, setSetFilter] = useState('');

  const [previewCard, setPreviewCard] = useState(null);
  const [hasChanges, setHasChanges] = useState(false);

  const handleCardClick = useCallback((card, nameCopies, thisCopies, maxCopies) => {
    // Legend: tap to select/replace
    if (category === 'legend') {
      onSelectCard(card);
      setHasChanges(true);
      return;
    }
    // Battlefield: tap to toggle
    if (category === 'battlefields') {
      if (nameCopies > 0) {
        onRemoveCard(card);
      } else if (selectedBattlefields.length < 3) {
        onSelectCard(card);
      }
      setHasChanges(true);
      return;
    }
    // Main/Side: per-ID cycling with per-name limit
    if (nameCopies < maxCopies) {
      // Under name limit → just add one of this version
      onSelectCard(card);
    } else {
      // At name limit → try to steal from another version first
      const otherKeys = Object.keys({ ...customMainDeck, ...customSideboard });
      let stealTarget = null;
      for (const key of otherKeys) {
        if (key === card.id) continue;
        const otherCard = cardLookup?.get(key);
        if (otherCard?.name === card.name) {
          const otherCount = (customMainDeck[key] || 0) + (customSideboard[key] || 0);
          if (otherCount > 0) {
            stealTarget = otherCard;
            break;
          }
        }
      }
      if (stealTarget) {
        // Steal: remove one from other version, add one of this version
        onRemoveCard(stealTarget);
        onSelectCard(card, { force: true });
      } else if (thisCopies > 0) {
        // No other version to steal from → remove ALL copies (cycle back to 0)
        for (let i = 0; i < thisCopies; i++) onRemoveCard(card);
      } else {
        return; // At limit, no copies anywhere to swap
      }
    }
    setHasChanges(true);
  }, [onSelectCard, onRemoveCard, category, selectedBattlefields, customMainDeck, customSideboard, cardLookup]);

  useEffect(() => {
    if (isOpen) {
      setSearchQuery('');
      setTypeFilter('');
      setDomainFilter('');
      setCostFilter('');
      setRarityFilter('');
      setSetFilter('');
      setPreviewCard(null);
      setHasChanges(false);
    }
  }, [isOpen]);

  useEffect(() => {
    if (!isOpen) return;
    const scrollY = window.scrollY;
    const prevBodyBg = document.body.style.backgroundColor;
    const prevHtmlBg = document.documentElement.style.backgroundColor;
    document.body.style.position = 'fixed';
    document.body.style.top = `-${scrollY}px`;
    document.body.style.width = '100%';
    document.body.style.overflow = 'hidden';
    document.body.style.backgroundColor = '#020617';
    document.documentElement.style.backgroundColor = '#020617';
    return () => {
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.width = '';
      document.body.style.overflow = '';
      document.body.style.backgroundColor = prevBodyBg;
      document.documentElement.style.backgroundColor = prevHtmlBg;
      window.scrollTo(0, scrollY);
    };
  }, [isOpen]);

  // Build per-name totals and per-ID totals from ID-based deck storage
  const { totalByName, totalById } = useMemo(() => {
    const byName = {};
    const byId = {};
    for (const [key, count] of Object.entries(customMainDeck)) {
      const card = cardLookup?.get(key);
      const name = card?.name || key;
      byName[name] = (byName[name] || 0) + count;
      byId[key] = (byId[key] || 0) + count;
    }
    for (const [key, count] of Object.entries(customSideboard)) {
      const card = cardLookup?.get(key);
      const name = card?.name || key;
      byName[name] = (byName[name] || 0) + count;
      byId[key] = (byId[key] || 0) + count;
    }
    return { totalByName: byName, totalById: byId };
  }, [customMainDeck, customSideboard, cardLookup]);

  const categoryCards = useMemo(() => {
    let cards = allCards;
    if (category === 'legend') {
      cards = cards.filter(c => c.classification?.type === 'Legend');
    } else if (category === 'battlefields') {
      cards = cards.filter(c => c.classification?.type === 'Battlefield');
    } else if (category === 'main' || category === 'side') {
      cards = cards.filter(c => {
        const type = c.classification?.type;
        return type !== 'Legend' && type !== 'Battlefield' && type !== 'Rune';
      });
      if (selectedLegend) {
        const legendDomains = selectedLegend.classification?.domain || [];
        cards = cards.filter(c => {
          const cardDomains = c.classification?.domain || [];
          return cardDomains.length === 0 || cardDomains.every(domain => legendDomains.includes(domain));
        });
      }
    }
    return cards;
  }, [allCards, category, selectedLegend]);

  const filterOptions = useMemo(() => {
    const types = {}, domains = {}, costs = {}, rarities = {}, sets = {};
    categoryCards.forEach(card => {
      const type = card.classification?.type;
      if (type) types[type] = (types[type] || 0) + 1;
      (card.classification?.domain || []).forEach(d => { domains[d] = (domains[d] || 0) + 1; });
      const cost = card.attributes?.energy;
      if (cost !== undefined && cost !== null) costs[String(cost)] = (costs[String(cost)] || 0) + 1;
      const rarity = card.classification?.rarity;
      if (rarity) rarities[rarity] = (rarities[rarity] || 0) + 1;
      const setId = card.set?.set_id;
      if (setId) sets[setId] = (sets[setId] || 0) + 1;
    });
    return {
      types: Object.entries(types).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      domains: Object.entries(domains).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      costs: Object.entries(costs).sort(([a], [b]) => Number(a) - Number(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      rarities: Object.entries(rarities).sort(([a], [b]) => a.localeCompare(b)).map(([v, c]) => ({ value: v, label: v, count: c })),
      sets: Object.entries(sets).sort(([a], [b]) => b.localeCompare(a)).map(([v, c]) => ({ value: v, label: v, count: c })),
    };
  }, [categoryCards]);

  const filteredCards = useMemo(() => {
    let cards = categoryCards;
    if (typeFilter) cards = cards.filter(c => c.classification?.type === typeFilter);
    if (domainFilter) cards = cards.filter(c => (c.classification?.domain || []).includes(domainFilter));
    if (costFilter) {
      if (costFilter === '6+') {
        cards = cards.filter(c => c.attributes?.energy >= 6);
      } else {
        cards = cards.filter(c => String(c.attributes?.energy) === costFilter);
      }
    }
    if (rarityFilter) cards = cards.filter(c => c.classification?.rarity === rarityFilter);
    if (setFilter) cards = cards.filter(c => c.set?.set_id === setFilter);
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
  }, [categoryCards, typeFilter, domainFilter, costFilter, rarityFilter, setFilter, searchQuery]);

  if (!isOpen) return null;

  const isMultiPick = category === 'main' || category === 'side';
  const title =
    category === 'legend' ? 'Select Legend' :
    category === 'battlefields' ? 'Select Battlefield' :
    category === 'main' ? 'Add to Main Deck' :
    'Add to Sideboard';

  const isLandscape = category === 'battlefields';
  const showCopyLimits = category === 'main' || category === 'side';

  const currentCount = category === 'main'
    ? Object.values(customMainDeck).reduce((s, c) => s + c, 0)
    : category === 'side'
    ? Object.values(customSideboard).reduce((s, c) => s + c, 0)
    : category === 'battlefields'
    ? selectedBattlefields.length
    : category === 'legend'
    ? (selectedLegend ? 1 : 0)
    : 0;
  const maxCount = category === 'main' ? 40 : category === 'side' ? 8 : category === 'battlefields' ? 3 : category === 'legend' ? 1 : 0;
  const showCounter = category !== 'legend' || selectedLegend;

  return createPortal(
    <>
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 99999,
        display: 'flex',
        flexDirection: 'column',
        background: '#020617',
        overflow: 'hidden',
      }}
    >
      {/* Search */}
      <div className="px-4 pt-[max(0.75rem,env(safe-area-inset-top,0.75rem))] pb-0 flex-shrink-0">
        <div className="relative">
          <Search className="absolute left-4 top-3.5 text-slate-500" size={18} />
          <input
            type="text"
            placeholder="Search for a card..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="w-full bg-slate-800 border-none rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none text-white"
          />
          {showCounter && (
            <span className={`absolute right-4 top-3.5 text-xs font-bold transition-colors duration-500 ${hasChanges ? 'text-emerald-500' : 'text-amber-500'}`}>{currentCount}/{maxCount}</span>
          )}
        </div>
      </div>

      {/* Domain Icons */}
      {(category === 'main' || category === 'side') && (
        <div className="flex items-center justify-between px-4 pt-2 pb-1 flex-shrink-0">
          {[
            { name: 'Fury',  offset: '0px -3.5px' },
            { name: 'Mind',   offset: '-1px 0px' },
            { name: 'Chaos',  offset: '-1px 0px' },
            { name: 'Calm',   offset: '0px 0px' },
            { name: 'Body',   offset: '0px 0px' },
            { name: 'Order',  offset: '0px 1px' },
          ].map(({ name: domain, offset }) => {
            const legendDomains = selectedLegend?.classification?.domain || [];
            const isLegendDomain = legendDomains.includes(domain);
            const isActive = domainFilter === domain;
            return (
              <button
                key={domain}
                disabled={!isLegendDomain}
                onClick={() => setDomainFilter(prev => prev === domain ? '' : domain)}
                className={`p-1.5 rounded-full transition-all active:scale-95 ${
                  isActive ? 'ring-2 ring-amber-400/80 bg-amber-500/10' :
                  isLegendDomain ? 'opacity-40' : 'opacity-10 grayscale'
                }`}
              >
                <img src={RUNE_COLORS[domain]?.icon} alt={domain} className="w-10 h-10" style={{ translate: offset }} />
              </button>
            );
          })}
        </div>
      )}

      {/* Cost Circles */}
      {filterOptions.costs.length > 1 && (
        <div className="flex items-center justify-between px-4 pt-1 pb-2 flex-shrink-0">
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
      )}

      {/* Filter Dropdowns */}
      <div className="flex gap-2 px-4 py-2 flex-shrink-0 border-b border-slate-800 overflow-x-auto">
        {filterOptions.types.length > 1 && (
          <FilterDropdown label="Type" value={typeFilter} options={filterOptions.types} onChange={setTypeFilter} />
        )}
        {filterOptions.rarities.length > 1 && (
          <FilterDropdown label="Rarity" value={rarityFilter} options={filterOptions.rarities} onChange={setRarityFilter} />
        )}
        {filterOptions.sets.length > 1 && (
          <FilterDropdown label="Set" value={setFilter} options={filterOptions.sets} onChange={setSetFilter} />
        )}
      </div>

      {/* Card Grid */}
      <div
        className="flex-1 min-h-0 overflow-y-auto overscroll-contain p-3"
      >
        {filteredCards.length === 0 ? (
          <div className="flex items-center justify-center h-40 text-slate-500 text-sm font-bold">
            No cards found
          </div>
        ) : (
          <div className={isLandscape ? 'grid grid-cols-2 gap-3' : 'grid grid-cols-3 gap-2'}>
            {filteredCards.map(card => {
              const cardIsLandscape = card.orientation === 'landscape' || card.classification?.type === 'Battlefield';
              const maxCopies = getMaxCopies(card);
              // Per-name total (for limit enforcement) and per-ID count (for this version)
              let nameCopies = totalByName[card.name] || 0;
              let thisCopies = totalById[card.id] || 0;
              if (category === 'legend') {
                nameCopies = selectedLegend?.id === card.id ? 1 : 0;
                thisCopies = nameCopies;
              }
              if (category === 'battlefields') {
                nameCopies = selectedBattlefields.some(bf => bf.id === card.id) ? 1 : 0;
                thisCopies = nameCopies;
              }
              // atLimit: per-name limit OR total battlefield slots full
              let atLimit = nameCopies >= maxCopies;
              if (category === 'battlefields' && nameCopies === 0 && selectedBattlefields.length >= 3) atLimit = true;
              return (
                <ModalCardItem
                  key={card.id}
                  card={card}
                  isLandscape={cardIsLandscape}
                  showCopyLimits={showCopyLimits}
                  currentCopies={thisCopies}
                  nameCopies={nameCopies}
                  maxCopies={maxCopies}
                  atLimit={atLimit}
                  onClick={() => handleCardClick(card, nameCopies, thisCopies, maxCopies)}
                  onLongPress={() => setPreviewCard(card)}
                />
              );
            })}
          </div>
        )}
      </div>

    </div>

    {/* FAB - Back button: slides in from left on open, slides right-to-left when changes exist */}
    <button
      key={`back-${hasChanges}`}
      onClick={hasChanges ? onDiscard : onClose}
      className="fixed bottom-6 w-14 h-14 rounded-full shadow-2xl flex items-center justify-center active:scale-95 bg-slate-700 active:bg-slate-600"
      style={{
        zIndex: 100000,
        left: hasChanges ? '1.5rem' : 'calc(100% - 1.5rem - 3.5rem)',
        animation: hasChanges
          ? 'modal-fab-to-left 0.35s cubic-bezier(0.4, 0, 0.2, 1) both'
          : 'modal-fab-enter-right 0.4s cubic-bezier(0.4, 0, 0.2, 1) both',
      }}
    >
      <ArrowLeft size={24} className="text-white" />
    </button>

    {/* FAB - Confirm button (appears bottom-right when changes exist) */}
    {hasChanges && (
      <button
        onClick={onClose}
        className="fixed bottom-6 right-6 w-14 h-14 rounded-full shadow-2xl flex items-center justify-center active:scale-95 bg-emerald-600 active:bg-emerald-500"
        style={{
          zIndex: 100000,
          animation: 'fab-breathe 3s ease-in-out 0.3s infinite, fab-pop-in 0.3s cubic-bezier(0.4, 0, 0.2, 1) both',
        }}
      >
        <Check size={28} className="text-white" />
      </button>
    )}

    <style>{`
      @keyframes fab-breathe {
        0%, 100% { transform: scale(1); }
        50% { transform: scale(1.12); }
      }
      @keyframes card-pop {
        0% { transform: scale(1); }
        50% { transform: scale(1.08); }
        100% { transform: scale(1); }
      }
      @keyframes fab-pop-in {
        0% { transform: scale(0); opacity: 0; }
        100% { transform: scale(1); opacity: 1; }
      }
      @keyframes modal-fab-enter-right {
        from { left: 1.5rem; }
        to { left: calc(100% - 1.5rem - 3.5rem); }
      }
      @keyframes modal-fab-to-left {
        from { left: calc(100% - 1.5rem - 3.5rem); }
        to { left: 1.5rem; }
      }
    `}</style>

    <CardPreview card={previewCard} onClose={() => setPreviewCard(null)} />
  </>,
    document.body
  );
}

// Individual card in the modal grid
function ModalCardItem({ card, isLandscape, showCopyLimits, currentCopies, nameCopies, maxCopies, atLimit, onClick, onLongPress }) {
  const handlers = useLongPress(onLongPress, onClick);
  const [justAdded, setJustAdded] = useState(false);
  const prevCopies = useRef(currentCopies);

  // Trigger bounce when copies increase
  useEffect(() => {
    if (currentCopies > prevCopies.current) {
      setJustAdded(true);
      const timer = setTimeout(() => setJustAdded(false), 400);
      return () => clearTimeout(timer);
    }
    prevCopies.current = currentCopies;
  }, [currentCopies]);

  const hasCards = currentCopies > 0;
  const anyVersionInDeck = (nameCopies || 0) > 0;

  return (
    <div
      id={`modal-card-${card.id}`}
      {...handlers}
      className={`w-full rounded-xl overflow-hidden transition-all ${
        atLimit && currentCopies === 0 ? 'opacity-40' : ''
      }`}
      style={{
        touchAction: 'manipulation',
        animation: justAdded ? 'card-pop 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)' : 'none',
      }}
    >
      <div className={`relative ${isLandscape ? 'aspect-[3/2]' : 'aspect-[2/3]'} ${
        hasCards ? 'ring-2 ring-amber-400/80 rounded-xl' : ''
      }`}>
        <img
          src={card.media.image_url}
          alt={card.name}
          className="w-full h-full object-cover pointer-events-none select-none rounded-xl"
          loading="lazy"
          draggable={false}
        />
        {/* Copy count badge */}
        {showCopyLimits && currentCopies > 0 && (
          <div className={`absolute bottom-1 left-1 text-white font-black text-[10px] rounded-md px-1.5 py-0.5 flex items-center justify-center pointer-events-none ${atLimit ? 'bg-red-600' : 'bg-amber-600'}`}>
            {currentCopies}/{maxCopies}
          </div>
        )}
      </div>
      <p className={`text-[10px] font-bold text-center mt-1 truncate pointer-events-none select-none ${
        hasCards ? 'text-amber-500' : 'text-slate-300'
      }`}>{card.name}</p>
    </div>
  );
}

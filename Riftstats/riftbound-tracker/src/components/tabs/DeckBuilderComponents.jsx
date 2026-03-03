import React, { useState, useEffect, useMemo } from 'react';
import { Plus } from 'lucide-react';
import CardPreview, { useLongPress } from '../shared/CardPreview';
import { SECTION_BG, SECTION_TITLE } from '../../constants/design';

// Get max allowed copies for a card (across main + side combined)
export function getMaxCopies(card) {
  if (!card) return 3;
  if (card.deck_limit !== undefined && card.deck_limit !== null) return card.deck_limit;
  if (card.attributes?.deck_limit !== undefined && card.attributes?.deck_limit !== null) return card.attributes.deck_limit;
  const type = card.classification?.type;
  if (type === 'Legend' || type === 'Battlefield') return 1;
  return 3;
}

// ========================================
// ManaCurveChart - energy cost distribution
// ========================================
export function ManaCurveChart({ cards, cardLookup }) {
  const { buckets, max, avgCost } = useMemo(() => {
    const dist = Array.from({ length: 8 }, () => ({ units: 0, spells: 0, gear: 0 }));
    let totalCost = 0;
    let totalQty = 0;
    Object.entries(cards).forEach(([cardId, qty]) => {
      const card = cardLookup.get(cardId);
      if (!card) return;
      const cost = card.attributes?.energy;
      if (cost === null || cost === undefined) return;
      totalCost += cost * qty;
      totalQty += qty;
      const bucket = Math.min(cost, 7);
      const type = card.classification?.type;
      if (type === 'Unit' || type === 'Champion Unit') dist[bucket].units += qty;
      else if (type === 'Gear') dist[bucket].gear += qty;
      else dist[bucket].spells += qty;
    });
    const maxVal = Math.max(...dist.flatMap(b => [b.units, b.spells, b.gear]), 1);
    const avg = totalQty > 0 ? (totalCost / totalQty).toFixed(1) : null;
    return { buckets: dist, max: maxVal, avgCost: avg };
  }, [cards, cardLookup]);

  const labels = ['0', '1', '2', '3', '4', '5', '6', '7+'];
  const types = [
    { key: 'units', color: 'bg-red-500' },
    { key: 'spells', color: 'bg-blue-500' },
    { key: 'gear', color: 'bg-amber-500' },
  ];

  return (
    <div className="bg-slate-900/30 p-4 rounded-3xl">
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="flex items-center gap-2">
            <h3 className="text-sm font-black text-slate-400">ENERGY CURVE</h3>
            {avgCost !== null && <span className="text-sm font-black text-amber-500">⌀ {avgCost}</span>}
          </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-red-500" /><span className="text-[10px] text-slate-500">Units</span></div>
          <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-blue-500" /><span className="text-[10px] text-slate-500">Spells</span></div>
          <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-amber-500" /><span className="text-[10px] text-slate-500">Gear</span></div>
        </div>
      </div>
      <div className="flex items-end justify-between gap-2 h-24 px-1">
        {buckets.map((b, i) => {
          const total = b.units + b.spells + b.gear;
          return (
            <div key={i} className="flex-1 flex flex-col items-center gap-1 h-full">
              <span className={`text-xs font-bold ${total > 0 ? 'text-white' : 'text-slate-600'}`}>
                {total > 0 ? total : ''}
              </span>
              <div className="flex-1 w-full flex items-end justify-center gap-px">
                {types.map(({ key, color }) => {
                  const val = b[key];
                  const pct = (val / max) * 100;
                  return (
                    <div
                      key={key}
                      className={`flex-1 rounded-t-sm transition-all ${val > 0 ? color : 'bg-slate-800/40'}`}
                      style={{ height: val > 0 ? `${Math.max(pct, 6)}%` : '3px' }}
                    />
                  );
                })}
              </div>
              <span className="text-xs text-slate-500 font-medium">{labels[i]}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ========================================
// DeckCardSection - card grid with edit controls
// ========================================
export function DeckCardSection({ title, cards, maxCards, allCards, cardLookup, isEditMode, onAdd, onIncrement, onDecrement, getTotalCopies, getQuantity }) {
  const totalCount = Object.values(cards).reduce((sum, c) => sum + c, 0);
  const [activeCard, setActiveCard] = useState(null);
  const [previewCard, setPreviewCard] = useState(null);

  useEffect(() => {
    if (!isEditMode) setActiveCard(null);
  }, [isEditMode]);

  useEffect(() => {
    if (!activeCard) return;
    const handler = (e) => {
      const el = document.getElementById(`deck-card-${title}-${activeCard}`);
      if (el && !el.contains(e.target)) {
        setActiveCard(null);
      }
    };
    const timer = setTimeout(() => {
      document.addEventListener('click', handler);
    }, 10);
    return () => {
      clearTimeout(timer);
      document.removeEventListener('click', handler);
    };
  }, [activeCard, title]);

  return (
    <div className={SECTION_BG}>
      <h3 className={SECTION_TITLE}>{title} ({totalCount}/{maxCards})</h3>
      <div className="grid grid-cols-3 gap-3">
        {Object.entries(cards).map(([cardId, count]) => {
          const card = cardLookup.get(cardId);
          if (!card) return null;
          const maxCopies = getMaxCopies(card);
          const totalCopies = getTotalCopies(card.name);
          const atLimit = totalCopies >= maxCopies;
          const isActive = activeCard === cardId;
          const owned = getQuantity ? getQuantity(cardId) : null;
          return (
            <DeckCardItem
              key={cardId}
              id={`deck-card-${title}-${cardId}`}
              card={card}
              cardName={card.name}
              count={count}
              maxCopies={maxCopies}
              atLimit={atLimit}
              isActive={isActive}
              isEditMode={isEditMode}
              owned={owned}
              onTap={() => {
                if (isEditMode) {
                  setActiveCard(isActive ? null : cardId);
                } else {
                  setPreviewCard(card);
                }
              }}
              onLongPress={() => setPreviewCard(card)}
              onDecrement={() => {
                if (count <= 1) setActiveCard(null);
                onDecrement(cardId);
              }}
              onIncrement={() => { if (!atLimit) onIncrement(cardId); }}
            />
          );
        })}
        {isEditMode && (
          <button onClick={onAdd} className="w-full aspect-[2/3] bg-slate-800 border-2 border-dashed border-slate-700 rounded-xl hover:border-amber-600 transition-all flex items-center justify-center">
            <Plus size={24} className="text-slate-600" />
          </button>
        )}
      </div>
      <CardPreview card={previewCard} onClose={() => setPreviewCard(null)} />
    </div>
  );
}

// Individual deck card with long-press support
function DeckCardItem({ id, card, cardName, count, maxCopies, atLimit, isActive, isEditMode, onTap, onLongPress, onDecrement, onIncrement, owned }) {
  const handlers = useLongPress(onLongPress, onTap);
  const isMissing = owned !== null && !isEditMode && owned < count;
  const isFullyMissing = owned !== null && !isEditMode && owned === 0;

  return (
    <div
      id={id}
      className="relative"
      style={{ touchAction: 'manipulation' }}
      {...handlers}
    >
      <div className={`relative aspect-[2/3] overflow-hidden rounded-xl ${isMissing && !isFullyMissing ? 'ring-1 ring-rose-500/50' : ''}`}>
        <img src={card.media.image_url} alt={card.name} className={`w-full h-full object-cover pointer-events-none select-none ${isFullyMissing ? 'grayscale opacity-50' : ''}`} draggable={false} />
        <div className={`absolute bottom-1 left-1 text-white font-black text-[10px] rounded-md px-1.5 py-0.5 flex items-center justify-center pointer-events-none ${atLimit ? 'bg-red-600' : 'bg-amber-600'}`}>
          {count}/{maxCopies}
        </div>
        {isMissing && (
          <div className="absolute bottom-1 right-1 px-1.5 py-0.5 rounded-md text-[9px] font-black bg-rose-600/90 text-white pointer-events-none">
            {owned}/{count}
          </div>
        )}
        {isEditMode && isActive && (
          <div
            className="absolute inset-0 bg-black/60 rounded-xl flex items-center justify-center gap-3 animate-in fade-in duration-150"
            onTouchStart={(e) => e.stopPropagation()}
            onTouchEnd={(e) => e.stopPropagation()}
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onTouchEnd={(e) => { e.stopPropagation(); e.preventDefault(); onDecrement(); }}
              onClick={(e) => { e.stopPropagation(); onDecrement(); }}
              className="bg-red-600 active:bg-red-500 active:scale-110 text-white font-black rounded-lg px-4 py-2 text-lg transition-transform"
            >−</button>
            <button
              onTouchEnd={(e) => { e.stopPropagation(); e.preventDefault(); onIncrement(); }}
              onClick={(e) => { e.stopPropagation(); onIncrement(); }}
              className={`font-black rounded-lg px-4 py-2 text-lg transition-transform ${atLimit ? 'bg-slate-600 text-slate-400' : 'bg-amber-600 active:bg-amber-500 active:scale-110 text-white'}`}
            >+</button>
          </div>
        )}
      </div>
    </div>
  );
}

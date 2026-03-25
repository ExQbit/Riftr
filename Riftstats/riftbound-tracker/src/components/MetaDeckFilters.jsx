import React, { useState, useRef, useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { X, ChevronDown } from 'lucide-react';

/**
 * MetaDeckFilters — Legend card images + Set/Tournament dropdowns.
 */
export default function MetaDeckFilters({
  legends, events, sets,
  activeLegends, activeEvents, activeSets,
  onToggleLegend, onToggleEvent, onToggleSet,
  onClear,
  filteredCount, totalCount,
  hasExtraFilters = false,
}) {
  const hasActiveFilters = activeLegends.size > 0 || activeEvents.size > 0 || activeSets.size > 0 || hasExtraFilters;

  return (
    <div className="space-y-2.5 mb-3">
      {/* Legend card images — horizontal scroll */}
      <LegendCardRow
        legends={legends}
        activeLegends={activeLegends}
        onToggle={onToggleLegend}
      />

      {/* Set + Tournament dropdowns side by side */}
      <div className="flex gap-2">
        <FilterDropdown
          label="All Sets"
          items={sets.map(s => ({ key: s.setId, label: s.setId, count: s.count }))}
          activeKeys={activeSets}
          onToggle={onToggleSet}
          activeColor="amber"
        />
        <FilterDropdown
          label="All Tournaments"
          items={events.map(e => ({ key: e.source, label: e.shortName, count: e.count }))}
          activeKeys={activeEvents}
          onToggle={onToggleEvent}
          activeColor="amber"
        />
      </div>

      {/* Active filter indicator */}
      {hasActiveFilters && (
        <div className="flex items-center justify-between px-1">
          <span className="text-[11px] text-slate-500 font-medium">
            {filteredCount} of {totalCount} decks
          </span>
          <button
            onClick={onClear}
            className="flex items-center gap-1.5 text-xs text-slate-400 px-3 py-1.5 rounded-full bg-slate-800/60 active:scale-95 transition-all"
          >
            <X size={14} />
            Clear
          </button>
        </div>
      )}
    </div>
  );
}

/** Legend dropdown with 3-column grid (portal-based for full-width) */
export function LegendCardRow({ legends, activeLegends, onToggle }) {
  const [open, setOpen] = useState(false);
  const btnRef = useRef(null);
  const panelRef = useRef(null);
  const [panelTop, setPanelTop] = useState(0);

  const updatePosition = useCallback(() => {
    if (!btnRef.current) return;
    const rect = btnRef.current.getBoundingClientRect();
    setPanelTop(rect.bottom + 4);
  }, []);

  useEffect(() => {
    if (!open) return;
    updatePosition();
    const handler = (e) => {
      if (btnRef.current?.contains(e.target)) return;
      if (panelRef.current?.contains(e.target)) return;
      setOpen(false);
    };
    document.addEventListener('click', handler);
    return () => document.removeEventListener('click', handler);
  }, [open, updatePosition]);

  const activeCount = activeLegends.size;
  const displayLabel = activeCount === 0
    ? 'All Legends'
    : activeCount === 1
      ? [...activeLegends][0]
      : `${activeCount} Legends`;

  return (
    <div>
      <button
        ref={btnRef}
        onClick={() => { if (!open) updatePosition(); setOpen(!open); }}
        className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-bold transition-all ${
          activeCount > 0
            ? 'bg-amber-600/20 text-amber-400 border border-amber-500/30'
            : 'bg-slate-800/80 text-slate-400 border border-slate-700/50'
        }`}
      >
        <span className="truncate">{displayLabel}</span>
        <ChevronDown size={14} className={`flex-shrink-0 ml-1 transition-transform ${open ? 'rotate-180' : ''}`} />
      </button>

      {open && createPortal(
        <div
          ref={panelRef}
          className="bg-slate-900 border-y border-slate-700 shadow-2xl max-h-[70vh] overflow-y-auto overflow-x-hidden overscroll-contain"
          style={{ position: 'fixed', top: panelTop, left: 0, right: 0, zIndex: 9999 }}
        >
          <div className="grid grid-cols-3 gap-0.5">
            {legends.map(({ shortName, media, count }) => {
              const isActive = activeLegends.has(shortName);
              return (
                <button
                  key={shortName}
                  onClick={() => onToggle(shortName)}
                  className="relative overflow-hidden transition-all"
                >
                  <div className={`relative aspect-[2/3] transition-all ${
                    isActive
                      ? 'ring-2 ring-amber-400/80 ring-inset'
                      : 'opacity-50 hover:opacity-80'
                  }`}>
                    {media?.image_url ? (
                      <img src={media.image_url} alt={shortName} className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full bg-slate-800 flex items-center justify-center">
                        <span className="text-xs text-slate-600 font-bold">{shortName[0]}</span>
                      </div>
                    )}
                    <span className="absolute top-1 right-1 bg-black/70 text-[9px] font-bold text-white px-1.5 py-0.5 rounded">
                      {count}
                    </span>
                    <span className={`absolute bottom-0 inset-x-0 text-[10px] font-bold text-center py-1 ${
                      isActive ? 'bg-amber-600/80 text-white' : 'bg-black/60 text-slate-300'
                    }`}>
                      {shortName}
                    </span>
                  </div>
                </button>
              );
            })}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}

/** Reusable dropdown for Set/Tournament filters */
function FilterDropdown({ label, items, activeKeys, onToggle, activeColor = 'purple' }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!open) return;
    const handler = (e) => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('click', handler);
    return () => document.removeEventListener('click', handler);
  }, [open]);

  const activeCount = activeKeys.size;
  const displayLabel = activeCount === 0
    ? label
    : activeCount === 1
      ? items.find(i => activeKeys.has(i.key))?.label || label
      : `${activeCount} selected`;

  const colorClasses = {
    amber: {
      active: 'bg-amber-600/20 text-amber-300 border-amber-500/30',
      item: 'bg-amber-600/20 text-amber-300',
      badge: 'text-amber-400',
    },
  };
  const colors = colorClasses[activeColor] || colorClasses.amber;

  return (
    <div className="relative flex-1" ref={ref}>
      <button
        onClick={() => setOpen(!open)}
        className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-bold transition-all ${
          activeCount > 0
            ? `${colors.active} border`
            : 'bg-slate-800/80 text-slate-400 border border-slate-700/50'
        }`}
      >
        <span className="truncate">{displayLabel}</span>
        <ChevronDown size={14} className={`flex-shrink-0 ml-1 transition-transform ${open ? 'rotate-180' : ''}`} />
      </button>

      {open && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-slate-900 border border-slate-700 rounded-xl shadow-2xl z-50 max-h-56 overflow-y-auto">
          {items.map(({ key, label: itemLabel, count }) => {
            const isActive = activeKeys.has(key);
            return (
              <button
                key={key}
                onClick={() => onToggle(key)}
                className={`w-full flex items-center justify-between px-4 py-2 text-xs font-medium transition-colors ${
                  isActive ? `${colors.item}` : 'text-slate-400 active:bg-slate-800'
                }`}
              >
                <span>{itemLabel}</span>
                <span className={`text-[10px] font-bold ${isActive ? colors.badge : 'text-slate-600'}`}>{count}</span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}

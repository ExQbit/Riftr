import React from 'react';
import { Plus } from 'lucide-react';

export default function LegendFilterModal({ isOpen, onClose, allCards, activeFilter, onFilterChange }) {
  if (!isOpen) return null;

  const legends = allCards
    .filter(card => card.classification?.type === 'Legend')
    .sort((a, b) => a.name.localeCompare(b.name));

  const btnClass = (isActive) =>
    `w-full text-left px-4 py-3 rounded-xl transition-all ${
      isActive ? 'bg-amber-600 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
    }`;

  return (
    <div
      className="fixed inset-0 bg-black/80 z-[100] flex items-end sm:items-center justify-center"
      onClick={onClose}
    >
      <div
        className="bg-slate-900 border border-slate-800 rounded-t-3xl sm:rounded-3xl w-full sm:max-w-lg max-h-[70vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-black text-white">Filter by Legend</h3>
            <button onClick={onClose} className="text-slate-400 hover:text-white">
              <Plus size={24} className="rotate-45" />
            </button>
          </div>

          <div className="space-y-2">
            <button
              onClick={() => { onFilterChange(''); onClose(); }}
              className={btnClass(!activeFilter)}
            >
              All Legends
            </button>

            {legends.map(legend => (
              <button
                key={legend.id}
                onClick={() => { onFilterChange(legend.name); onClose(); }}
                className={btnClass(activeFilter === legend.name)}
              >
                {legend.name}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

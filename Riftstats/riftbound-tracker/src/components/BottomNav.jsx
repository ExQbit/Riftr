import React from 'react';
import { LayoutGrid, Search, Layers, BarChart2, BookOpen, Users } from 'lucide-react';

const TABS = [
  { id: 'tracker', label: 'Tracker', icon: LayoutGrid },
  { id: 'cards', label: 'Cards', icon: Search },
  { id: 'collection', label: 'Collection', icon: BookOpen },
  { id: 'deckbuilder', label: 'Decks', icon: Layers },
  { id: 'stats', label: 'Stats', icon: BarChart2 },
  { id: 'social', label: 'Social', icon: Users },
];

const BottomNav = React.memo(function BottomNav({ activeTab, onTabChange, hidden }) {
  return (
    <nav
      className="fixed bottom-4 left-1/2 z-50"
      style={{
        transform: hidden ? 'translate(-50%, calc(100% + 2rem))' : 'translate(-50%, 0)',
        transition: 'transform 0.35s cubic-bezier(0.4, 0, 0.2, 1)',
        pointerEvents: hidden ? 'none' : 'auto',
      }}
    >
      <div className="flex items-center gap-0.5 bg-slate-900/80 backdrop-blur-xl rounded-full px-2.5 py-1.5 border border-amber-500/10 shadow-2xl shadow-black/50">
        {TABS.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => onTabChange(id)}
            className={`flex flex-col items-center gap-0.5 px-2 py-1 rounded-full transition-all ${
              activeTab === id ? 'text-amber-100' : 'text-slate-500 hover:text-slate-300'
            }`}
          >
            <Icon size={28} />
            <span className="text-[9px] font-bold">{label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
});

export default BottomNav;

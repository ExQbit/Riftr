import React, { useState, useEffect, useRef, useCallback } from 'react';
import { ChevronDown, X } from 'lucide-react';

export default function FilterDropdown({ label, value, options, onChange }) {
  const [isOpen, setIsOpen] = useState(false);
  const [isPositioned, setIsPositioned] = useState(false);
  const buttonRef = useRef(null);
  const menuRef = useRef(null);
  const [menuPos, setMenuPos] = useState({ top: 0, left: 0 });

  // Position menu below the button using fixed positioning
  const updatePosition = useCallback(() => {
    if (buttonRef.current) {
      const rect = buttonRef.current.getBoundingClientRect();
      const menuWidth = 160;
      let left = rect.left;
      // Prevent menu from overflowing right edge
      if (left + menuWidth > window.innerWidth - 8) {
        left = window.innerWidth - menuWidth - 8;
      }
      setMenuPos({
        top: rect.bottom + 4,
        left,
      });
      setIsPositioned(true);
    }
  }, []);

  useEffect(() => {
    if (!isOpen) {
      setIsPositioned(false);
      return;
    }
    // Calculate position immediately
    updatePosition();

    const handler = (e) => {
      if (
        buttonRef.current && !buttonRef.current.contains(e.target) &&
        menuRef.current && !menuRef.current.contains(e.target)
      ) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    document.addEventListener('touchstart', handler);
    return () => {
      document.removeEventListener('mousedown', handler);
      document.removeEventListener('touchstart', handler);
    };
  }, [isOpen, updatePosition]);

  const hasValue = value !== '';
  const displayLabel = hasValue ? options.find(o => o.value === value)?.label || value : label;

  return (
    <>
      <button
        ref={buttonRef}
        onClick={() => setIsOpen(!isOpen)}
        className={`flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all flex-shrink-0 ${
          hasValue
            ? 'bg-amber-600 text-white'
            : 'bg-slate-900 text-slate-400 border border-slate-800'
        }`}
      >
        <span>{displayLabel}</span>
        {hasValue ? (
          <X
            size={14}
            onClick={(e) => { e.stopPropagation(); onChange(''); setIsOpen(false); }}
          />
        ) : (
          <ChevronDown size={14} className={`transition-transform ${isOpen ? 'rotate-180' : ''}`} />
        )}
      </button>

      {isOpen && (
        <div
          ref={menuRef}
          className="fixed bg-slate-800 border border-slate-700 rounded-xl shadow-2xl z-[200] min-w-[160px] max-h-[250px] overflow-y-auto overscroll-contain"
          style={{
            top: menuPos.top,
            left: menuPos.left,
            visibility: isPositioned ? 'visible' : 'hidden',
          }}
        >
          <button
            onClick={() => { onChange(''); setIsOpen(false); }}
            className={`w-full text-left px-4 py-2.5 text-xs font-bold transition-all ${
              !hasValue ? 'text-amber-400 bg-slate-700/50' : 'text-slate-300 hover:bg-slate-700'
            }`}
          >
            All
          </button>
          {options.map(opt => (
            <button
              key={opt.value}
              onClick={() => { onChange(opt.value); setIsOpen(false); }}
              className={`w-full text-left px-4 py-2.5 text-xs font-bold transition-all ${
                value === opt.value ? 'text-amber-400 bg-slate-700/50' : 'text-slate-300 hover:bg-slate-700'
              }`}
            >
              {opt.label}{opt.count !== undefined ? ` (${opt.count})` : ''}
            </button>
          ))}
        </div>
      )}
    </>
  );
}

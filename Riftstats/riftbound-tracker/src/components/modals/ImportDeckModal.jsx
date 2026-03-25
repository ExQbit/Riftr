import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { AlertTriangle, CheckCircle2, X, ClipboardPaste } from 'lucide-react';
import { detectFormat } from '../../utils/deckFormat';

export default function ImportDeckModal({ isOpen, onClose, onImport }) {
  const [text, setText] = useState('');
  const [result, setResult] = useState(null);

  useEffect(() => {
    if (isOpen) {
      setText('');
      setResult(null);
    }
  }, [isOpen]);

  useEffect(() => {
    if (!isOpen) return;
    const scrollY = window.scrollY;
    document.body.style.position = 'fixed';
    document.body.style.top = `-${scrollY}px`;
    document.body.style.width = '100%';
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.width = '';
      document.body.style.overflow = '';
      window.scrollTo(0, scrollY);
    };
  }, [isOpen]);

  const handlePaste = async () => {
    try {
      const clipText = await navigator.clipboard.readText();
      setText(clipText);
    } catch {}
  };

  const handlePreview = () => {
    if (!text.trim()) return;
    const r = onImport(text, true);
    setResult({ ...r, format: detectFormat(text) });
  };

  const handleConfirm = () => {
    if (!result?.success && result?.errors?.length > 0) return;
    onImport(text, false);
    onClose();
  };

  if (!isOpen) return null;

  const detectedFormat = text.trim() ? detectFormat(text) : null;

  return createPortal(
    <div style={{ position: 'fixed', inset: 0, zIndex: 99999, display: 'flex', flexDirection: 'column', background: '#020617' }}>
      <div className="px-4 pt-[max(0.75rem,env(safe-area-inset-top,0.75rem))] pb-3 flex items-center justify-between border-b border-slate-800">
        <h2 className="text-lg font-black text-white">Import Deck</h2>
        <button onClick={onClose} className="p-2 text-slate-400 active:text-white transition-colors">
          <X size={20} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        <button
          onClick={handlePaste}
          className="w-full flex items-center justify-center gap-2 py-3 bg-slate-800 border border-slate-700 rounded-xl text-sm font-bold text-slate-300 active:bg-slate-700 transition-all"
        >
          <ClipboardPaste size={16} />
          Paste from Clipboard
        </button>

        <textarea
          value={text}
          onChange={(e) => { setText(e.target.value); setResult(null); }}
          placeholder={`Paste deck list or TTS code...\n\nText format:\nLegend:\n1 Viktor, Herald of the Arcane\nMainDeck:\n3 Scrapheap\n...\n\nTTS format:\nSFD-185-1 OGN-036-1 ...`}
          rows={12}
          className="w-full bg-slate-800 border border-slate-700 rounded-xl py-3 px-4 text-sm text-white focus:ring-2 ring-amber-500/40 outline-none resize-none font-mono leading-relaxed"
          spellCheck={false}
        />

        {/* Format indicator */}
        {detectedFormat && !result && (
          <div className={`flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-bold ${
            detectedFormat === 'tts' ? 'bg-violet-500/10 text-violet-400 border border-violet-500/30' : 'bg-sky-500/10 text-sky-400 border border-sky-500/30'
          }`}>
            <span className="w-2 h-2 rounded-full bg-current" />
            {detectedFormat === 'tts' ? 'TTS Code detected' : 'Text format detected'}
          </div>
        )}

        {!result && (
          <button
            onClick={handlePreview}
            disabled={!text.trim()}
            className={`w-full py-3 rounded-xl font-bold text-sm transition-all ${
              text.trim() ? 'bg-amber-600 text-white active:bg-amber-500 active:scale-[0.98]' : 'bg-slate-800 text-slate-600'
            }`}
          >
            Preview Import
          </button>
        )}

        {result && (
          <div className="space-y-3 animate-in fade-in slide-in-from-bottom-2 duration-300">
            {/* Format badge */}
            <div className={`flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-bold ${
              result.format === 'tts' ? 'bg-violet-500/10 text-violet-400 border border-violet-500/30' : 'bg-sky-500/10 text-sky-400 border border-sky-500/30'
            }`}>
              <span className="w-2 h-2 rounded-full bg-current" />
              {result.format === 'tts' ? 'Imported as TTS Code' : 'Imported as Text'}
            </div>

            <div className="bg-slate-800 border border-slate-700 rounded-xl p-4 space-y-2">
              <h3 className="text-sm font-black text-white mb-2">Import Summary</h3>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div className="text-slate-400">Legend</div>
                <div className="text-white font-bold">{result.summary.legend}</div>
                <div className="text-slate-400">Main Deck</div>
                <div className="text-white font-bold">{result.summary.mainCount}/40</div>
                <div className="text-slate-400">Battlefields</div>
                <div className="text-white font-bold">{result.summary.battlefieldCount}/3</div>
                <div className="text-slate-400">Sideboard</div>
                <div className="text-white font-bold">{result.summary.sideCount}/8</div>
              </div>
            </div>

            {result.errors.length > 0 && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle size={16} className="text-red-500" />
                  <span className="text-sm font-bold text-red-400">Errors</span>
                </div>
                {result.errors.map((e, i) => (
                  <p key={i} className="text-xs text-red-300 mt-1">• {e}</p>
                ))}
              </div>
            )}

            {result.warnings.length > 0 && (
              <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle size={16} className="text-yellow-500" />
                  <span className="text-sm font-bold text-yellow-400">Warnings ({result.warnings.length})</span>
                </div>
                {result.warnings.map((w, i) => (
                  <p key={i} className="text-xs text-yellow-300 mt-1">• {w}</p>
                ))}
              </div>
            )}

            {result.success && result.warnings.length === 0 && (
              <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-xl p-4 flex items-center gap-2">
                <CheckCircle2 size={16} className="text-emerald-500" />
                <span className="text-sm font-bold text-emerald-400">All cards matched!</span>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => setResult(null)}
                className="flex-1 py-3 rounded-xl font-bold text-sm bg-slate-800 text-slate-300 active:scale-[0.98] transition-all"
              >
                Edit
              </button>
              <button
                onClick={handleConfirm}
                disabled={!result.success}
                className={`flex-1 py-3 rounded-xl font-bold text-sm transition-all active:scale-[0.98] ${
                  result.success ? 'bg-emerald-600 text-white active:bg-emerald-500' : 'bg-slate-800 text-slate-600'
                }`}
              >
                Import Deck
              </button>
            </div>
          </div>
        )}
      </div>
    </div>,
    document.body
  );
}

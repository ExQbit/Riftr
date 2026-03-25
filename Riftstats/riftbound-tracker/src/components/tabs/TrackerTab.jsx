import React, { useState, useMemo, useCallback, useEffect } from 'react';
import {
  ChevronRight, Layers, Swords,
  ArrowLeft, Search, X, Minus, Plus, Check, ChevronDown
} from 'lucide-react';
import { RUNE_COLORS } from '../../constants/gameData';
import { LegendCardRow } from '../MetaDeckFilters';
import { getShortLegendName } from '../../utils/metaDeckFilters';
import { useGameData } from '../../contexts/AppContexts';
import { useAppData } from '../../contexts/AppContexts';

const LAST_DECK_KEY = 'riftbound-tracker-last-deck';
const MATCH_CONTEXT_KEY = 'riftbound-tracker-match-context';

const MATCH_CONTEXTS = [
  { id: 'casual', label: 'Casual' },
  { id: 'nexus-night', label: 'Nexus Night' },
  { id: 'skirmish', label: 'Skirmish' },
  { id: 'regional', label: 'Regional' },
  { id: 'sealed', label: 'Sealed' },
  { id: 'draft', label: 'Draft' },
  { id: 'online', label: 'Online' },
];

// Extract short champion name: "Ahri, Nine-Tailed Fox" -> "Ahri"
const getChampionName = (card) => {
  const name = card?.name || '';
  return name.includes(',') ? name.split(',')[0].trim() : name;
};

export default function TrackerTab({ onSaveMatch, onFullscreenChange }) {
  const { allCards, cardLookup } = useGameData();
  const { savedDecks, validateDeck, isDemoMode, activateDemo: onActivateDemo } = useAppData();
  const [step, setStep] = useState('deck');
  const [selectedDeckId, setSelectedDeckId] = useState(() => {
    try { return localStorage.getItem(LAST_DECK_KEY) || null; } catch { return null; }
  });
  const [opponent, setOpponent] = useState(null);
  const [legendSearch, setLegendSearch] = useState('');
  const [showLegendBrowser, setShowLegendBrowser] = useState(false);
  const [deckSearch, setDeckSearch] = useState('');
  const [domainFilters, setDomainFilters] = useState(new Set());
  const [legendFilters, setLegendFilters] = useState(new Set());
  const [matchContext, setMatchContext] = useState(() => {
    try { return localStorage.getItem(MATCH_CONTEXT_KEY) || 'casual'; } catch { return 'casual'; }
  });
  const [showContextMenu, setShowContextMenu] = useState(false);
  const [isFirst, setIsFirst] = useState(true);
  const [vsReady, setVsReady] = useState(false);
  const [myScore, setMyScore] = useState(0);
  const [oppScore, setOppScore] = useState(0);
  const [pendingResult, setPendingResult] = useState(null); // 'win', 'loss', or 'draw' — shown on VS overview before saving
  const [isFlipping, setIsFlipping] = useState(false);
  const [games, setGames] = useState([]); // completed games in current series
  const [roundAnnounce, setRoundAnnounce] = useState(false); // true = show round badge full, then fade
  const longPressTimer = React.useRef(null);
  const wasFlipped = React.useRef(false); // prevent tap after long-press

  useEffect(() => {
    onFullscreenChange?.(step === 'opponent' || step === 'battle');
  }, [step, onFullscreenChange]);

  const validDecks = useMemo(() => {
    if (!validateDeck) return savedDecks;
    return savedDecks.filter(d => validateDeck(d).isValid);
  }, [savedDecks, validateDeck]);

  // Legend options for filter dropdown
  const deckLegendOptions = useMemo(() => {
    const legendCounts = {};
    validDecks.forEach(d => {
      const legend = d.legendData || (d.legend ? allCards.find(c => c.id === d.legend) : null);
      if (!legend) return;
      const shortName = getShortLegendName(legend.name);
      if (!legendCounts[shortName]) {
        legendCounts[shortName] = { shortName, media: legend.media, count: 0 };
      }
      legendCounts[shortName].count++;
    });
    return Object.values(legendCounts).sort((a, b) => b.count - a.count);
  }, [validDecks, allCards]);

  const filteredDecks = useMemo(() => {
    const searchLower = deckSearch.toLowerCase().trim();
    return validDecks.filter(d => {
      const legend = d.legendData || (d.legend ? allCards.find(c => c.id === d.legend) : null);
      if (searchLower) {
        const name = (d.name || '').toLowerCase();
        const legendName = (legend?.name || '').toLowerCase();
        if (!name.includes(searchLower) && !legendName.includes(searchLower)) return false;
      }
      if (legendFilters.size > 0) {
        const shortName = legend ? getShortLegendName(legend.name) : '';
        if (!legendFilters.has(shortName)) return false;
      }
      if (domainFilters.size > 0) {
        const deckDomains = legend?.classification?.domain || [];
        if (domainFilters.size === 2) {
          if (![...domainFilters].every(dom => deckDomains.includes(dom))) return false;
        } else {
          if (!deckDomains.some(dom => domainFilters.has(dom))) return false;
        }
      }
      return true;
    });
  }, [validDecks, deckSearch, domainFilters, legendFilters, allCards]);

  // All unique Legend cards for opponent picker (type="Legend" only).
  // Deduplicate by name, preferring standard art over alt art.
  const opponentLegends = useMemo(() => {
    const legendMap = new Map();
    allCards
      .filter(c => c.classification?.type === 'Legend')
      .forEach(c => {
        const existing = legendMap.get(c.name);
        const isAlt = c.metadata?.alternate_art || c.metadata?.overnumbered || c.metadata?.signature;
        if (!existing) {
          legendMap.set(c.name, c);
        } else {
          const existIsAlt = existing.metadata?.alternate_art || existing.metadata?.overnumbered || existing.metadata?.signature;
          if (existIsAlt && !isAlt) legendMap.set(c.name, c);
        }
      });
    return [...legendMap.values()].sort((a, b) => a.name.localeCompare(b.name));
  }, [allCards]);

  const selectedDeck = useMemo(() => {
    if (!selectedDeckId) return null;
    return validDecks.find(d => d.id === selectedDeckId) || null;
  }, [selectedDeckId, validDecks]);

  const legendCard = useMemo(() => {
    if (!selectedDeck) return null;
    return selectedDeck.legendData || (selectedDeck.legend ? allCards.find(c => c.id === selectedDeck.legend) : null);
  }, [selectedDeck, allCards]);

  useEffect(() => {
    try {
      if (selectedDeckId) localStorage.setItem(LAST_DECK_KEY, selectedDeckId);
      else localStorage.removeItem(LAST_DECK_KEY);
    } catch {}
  }, [selectedDeckId]);

  useEffect(() => {
    try { localStorage.setItem(MATCH_CONTEXT_KEY, matchContext); } catch {}
  }, [matchContext]);

  const selectDeck = useCallback((deckId) => {
    setSelectedDeckId(deckId);
    setStep('opponent');
    setOpponent(null);
    setVsReady(false);
    setLegendSearch('');
    setShowLegendBrowser(false);
    setGames([]);
  }, []);

  const selectOpponent = useCallback((legendCardData, customName) => {
    if (customName) {
      setOpponent({ name: customName, card: null });
    } else {
      setOpponent(legendCardData ? { name: getChampionName(legendCardData), card: legendCardData } : { name: 'Unknown', card: null });
    }
    setShowLegendBrowser(false);
    setLegendSearch('');
    setVsReady(false);
    requestAnimationFrame(() => setTimeout(() => setVsReady(true), 50));
  }, []);

  const startBattle = useCallback(() => {
    if (!opponent) return;
    setMyScore(0);
    setOppScore(0);
    setPendingResult(null);
    setRoundAnnounce(true);
    setStep('battle');
    setTimeout(() => setRoundAnnounce(false), 2600);
  }, [opponent]);

  const handleRematch = useCallback(() => {
    if (!pendingResult || games.length >= 2) return; // max 3 games
    setGames(prev => [...prev, {
      myScore,
      oppScore,
      result: pendingResult,
      isFirst,
      bfChosen: prev.length > 0, // game 2+ = bf was chosen
    }]);
    setMyScore(0);
    setOppScore(0);
    setPendingResult(null);
    setIsFirst(f => !f); // auto toggle
    setRoundAnnounce(true);
    setStep('battle');
    setTimeout(() => setRoundAnnounce(false), 2600);
  }, [pendingResult, games, myScore, oppScore, isFirst]);

  const goBack = useCallback(() => {
    if (pendingResult) { setPendingResult(null); setStep('battle'); return; }
    if (step === 'battle') { setStep('opponent'); return; }
    if (step === 'opponent' && opponent) { setOpponent(null); setVsReady(false); return; }
    setStep('deck');
    setOpponent(null);
    setVsReady(false);
    setGames([]);
  }, [step, pendingResult, opponent]);

  const saveMatch = useCallback(async (result) => {
    if (!selectedDeck || !opponent) return;

    // Build complete games array including current game
    const allGames = [...games, {
      myScore,
      oppScore,
      result: pendingResult || result,
      isFirst,
      bfChosen: games.length > 0,
    }];

    // Series results
    const seriesMyWins = allGames.filter(g => g.result === 'win').length;
    const seriesOppWins = allGames.filter(g => g.result === 'loss').length;
    const seriesResult = seriesMyWins > seriesOppWins ? 'win' : seriesMyWins < seriesOppWins ? 'loss' : 'draw';
    const format = allGames.length === 1 ? 'bo1' : allGames.length === 2 ? 'bo2' : 'bo3';

    await onSaveMatch({
      deckId: selectedDeckId,
      deckName: selectedDeck.name,
      legendName: legendCard?.name || null,
      opponent: opponent.name,
      isFirst: allGames[0].isFirst, // game 1 starting player
      myScore: seriesMyWins,
      oppScore: seriesOppWins,
      result: seriesResult,
      format,
      matchContext,
      games: allGames,
    });
    setGames([]);
    setStep('opponent');
    setOpponent(null);
    setVsReady(false);
    setLegendSearch('');
    setShowLegendBrowser(false);
  }, [selectedDeck, selectedDeckId, legendCard, opponent, isFirst, myScore, oppScore, games, pendingResult, onSaveMatch, matchContext]);


  // ========================================
  // STEP 1: DECK SELECTION
  // ========================================
  if (step === 'deck') {
    const hasActiveFilters = legendFilters.size > 0 || domainFilters.size > 0 || deckSearch.trim();
    return (
      <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500">
        {validDecks.length === 0 ? (
          <div className="p-12 text-center bg-slate-900/80 rounded-3xl border border-amber-500/10">
            <Layers size={40} className="mx-auto mb-3 text-amber-500/30" />
            <p className="text-amber-200/60 font-bold text-sm">No Decks Ready for Battle</p>
            <p className="text-slate-600 text-xs mt-1">
              {savedDecks.length > 0 ? 'Complete a deck (Legend, 40 Main, 3 BF, 12 Runes)' : 'Forge your first deck in the Decks tab'}
            </p>
            {onActivateDemo && !isDemoMode && (
              <button
                onClick={onActivateDemo}
                className="mt-4 px-4 py-2 rounded-full text-xs font-bold text-amber-300 border border-amber-500/30 hover:bg-amber-500/10 transition-all active:scale-95"
              >
                Try Demo Mode
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-3">
            {/* Match Context Header — LoL-inspired */}
            <div className="text-center pt-3 pb-1">
              {/* Gold decorative line */}
              <div className="flex items-center justify-center gap-3 mb-2">
                <div className="h-px w-12 bg-gradient-to-r from-transparent to-amber-500/50" />
                <div className="w-1.5 h-1.5 rotate-45 bg-amber-500/60" />
                <div className="h-px w-12 bg-gradient-to-l from-transparent to-amber-500/50" />
              </div>
              <h2 className="text-xs font-black uppercase tracking-[0.3em] bg-gradient-to-r from-amber-200 via-yellow-100 to-amber-200 bg-clip-text text-transparent">
                Choose Your Battle
              </h2>
              <div className="relative inline-block mt-2.5">
                <button
                  onClick={() => setShowContextMenu(v => !v)}
                  className="flex items-center gap-2 px-5 py-2 rounded-lg bg-slate-900/80 border border-amber-500/20 transition-all active:scale-95 shadow-[0_0_12px_rgba(245,158,11,0.06)]"
                >
                  <span className="text-sm font-black text-amber-100">{MATCH_CONTEXTS.find(c => c.id === matchContext)?.label || 'Casual'}</span>
                  <ChevronDown size={14} className={`text-amber-500/50 transition-transform ${showContextMenu ? 'rotate-180' : ''}`} />
                </button>
                {showContextMenu && (
                  <div className="absolute top-full left-1/2 -translate-x-1/2 mt-1.5 w-48 bg-slate-900 border border-amber-500/20 rounded-lg shadow-2xl shadow-black/60 z-50 overflow-hidden">
                    {MATCH_CONTEXTS.map(ctx => (
                      <button
                        key={ctx.id}
                        onClick={() => { setMatchContext(ctx.id); setShowContextMenu(false); }}
                        className={`w-full px-4 py-2.5 text-left text-xs font-bold transition-all ${
                          matchContext === ctx.id
                            ? 'bg-amber-500/15 text-amber-300 border-l-2 border-amber-400'
                            : 'text-slate-400 hover:bg-slate-800 hover:text-slate-300 border-l-2 border-transparent'
                        }`}
                      >
                        {ctx.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>
              {/* Bottom gold line */}
              <div className="flex items-center justify-center gap-3 mt-3">
                <div className="h-px flex-1 bg-gradient-to-r from-transparent via-amber-500/20 to-transparent" />
              </div>
            </div>

            {/* Search */}
            <div className="relative">
              <Search className="absolute left-4 top-3.5 text-slate-500" size={18} />
              <input
                type="text"
                placeholder="Search a deck..."
                value={deckSearch}
                onChange={e => setDeckSearch(e.target.value)}
                className="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none text-white placeholder:text-slate-600"
              />
            </div>

            {/* Domain filter row */}
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

            {/* Legend filter */}
            {deckLegendOptions.length > 1 && (
              <LegendCardRow
                legends={deckLegendOptions}
                activeLegends={legendFilters}
                onToggle={(name) => setLegendFilters(prev => {
                  const next = new Set(prev);
                  next.has(name) ? next.delete(name) : next.add(name);
                  return next;
                })}
              />
            )}

            {/* Active filter indicator */}
            {hasActiveFilters && (
              <div className="flex items-center justify-between px-1">
                <span className="text-[11px] text-amber-400/60 font-medium">
                  {filteredDecks.length} of {validDecks.length} decks
                </span>
                <button
                  onClick={() => { setLegendFilters(new Set()); setDomainFilters(new Set()); setDeckSearch(''); }}
                  className="flex items-center gap-1.5 text-xs text-slate-400 px-3 py-1.5 rounded-full bg-slate-800/60 active:scale-95 transition-all"
                >
                  <X size={14} />
                  Clear
                </button>
              </div>
            )}

            {/* Deck list header */}
            <div className="flex items-center gap-2 px-1 pt-1">
              <Swords size={12} className="text-amber-500/50" />
              <span className="text-[10px] font-bold uppercase tracking-[0.15em] text-amber-500/40">Your Arsenal</span>
              <div className="h-px flex-1 bg-gradient-to-r from-amber-500/15 to-transparent" />
            </div>

            {filteredDecks.length === 0 ? (
              <div className="py-8 text-center">
                <p className="text-slate-500 text-sm font-bold">No decks match</p>
              </div>
            ) : filteredDecks.map(deck => {
              const legend = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
              const domains = legend?.classification?.domain || [];
              const mainCount = Object.values(deck.mainDeck || {}).reduce((sum, c) => sum + c, 0);
              const bfCount = (deck.battlefields || []).length;
              const sideCount = Object.values(deck.sideboard || {}).reduce((sum, c) => sum + c, 0);
              return (
                <button key={deck.id} onClick={() => selectDeck(deck.id)}
                  className="group w-full bg-slate-900/80 border border-slate-800 hover:border-amber-500/20 rounded-2xl py-2 px-2 text-left transition-all active:scale-[0.98] hover:shadow-[0_0_16px_rgba(245,158,11,0.04)]">
                  <div className="flex items-center gap-1.5">
                    <div className="relative w-14 h-[84px] flex-shrink-0">
                      {legend ? (
                        <img src={legend.media.image_url} alt={legend.name} className="w-full h-full object-cover rounded-lg ring-1 ring-amber-500/10" />
                      ) : (
                        <div className="w-full h-full rounded-lg bg-slate-800 border-2 border-dashed border-slate-700 flex items-center justify-center">
                          <span className="text-slate-600 text-[9px] font-bold text-center leading-tight">No<br/>Legend</span>
                        </div>
                      )}
                    </div>
                    <div className="flex flex-col gap-1 flex-shrink-0">
                      {domains.length > 0 ? domains.slice(0, 2).map((d, i) => (
                        <img key={i} src={RUNE_COLORS[d]?.icon} alt={d} className="w-8 h-8" />
                      )) : (
                        <>
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                        </>
                      )}
                    </div>
                    <div className="flex-1 flex flex-col justify-center min-w-0">
                      <h3 className="text-lg font-bold text-white group-hover:text-amber-50 mb-1 whitespace-nowrap overflow-hidden text-ellipsis text-left transition-colors">{deck.name}</h3>
                      {deck.description && <p className="text-xs text-slate-500 mb-1.5 line-clamp-1 text-left">{deck.description}</p>}
                      <div className="flex items-center gap-2 text-[11px] text-slate-500 flex-wrap">
                        <span className={`px-2 py-0.5 rounded-md font-bold ${mainCount === 40 ? 'bg-amber-500/10 text-amber-400' : 'bg-slate-800 text-slate-400'}`}>
                          Main {mainCount}/40
                        </span>
                        <span className={`px-2 py-0.5 rounded-md font-bold ${bfCount === 3 ? 'bg-amber-500/10 text-amber-400' : 'bg-slate-800 text-slate-400'}`}>
                          BF {bfCount}/3
                        </span>
                        <span className={`px-2 py-0.5 rounded-md font-bold ${sideCount === 8 ? 'bg-amber-500/10 text-amber-400' : 'bg-slate-800 text-slate-400'}`}>
                          Side {sideCount}/8
                        </span>
                      </div>
                    </div>
                    <ChevronRight size={20} className="text-amber-500/30 group-hover:text-amber-400/60 flex-shrink-0 transition-colors" />
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>
    );
  }




  // ========================================
  // STEP 2 + 3: VS / BATTLE (same layout)
  // ========================================
  const oppCard = opponent?.card;
  const hasOpponent = !!opponent;
  const isBattle = step === 'battle';

  const filteredLegends = opponentLegends.filter(c => {
    if (!legendSearch) return true;
    const q = legendSearch.toLowerCase();
    return c.name.toLowerCase().includes(q) || getChampionName(c).toLowerCase().includes(q);
  });

  return (
    <div className="fixed inset-0 bg-slate-950 z-40 overflow-hidden" style={{ touchAction: 'none' }}>
      <style>{`
        @keyframes clash-top { from { transform: translateY(-60px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
        @keyframes clash-bottom { from { transform: translateY(60px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
        @keyframes vs-slam {
          0% { transform: scale(0) rotate(-20deg); opacity: 0; }
          60% { transform: scale(1.3) rotate(5deg); opacity: 1; }
          100% { transform: scale(1) rotate(0deg); opacity: 1; }
        }
        @keyframes vs-idle { 0%,100% { transform: scale(1); } 50% { transform: scale(1.025); } }
        @keyframes spark { 0% { opacity:0; transform:scaleX(0); } 50% { opacity:1; transform:scaleX(1); } 100% { opacity:0.3; transform:scaleX(1); } }
        @keyframes first-pulse { 0%,100% { opacity: 0.7; } 50% { opacity: 1; } }
        @keyframes card-breathe { 0%,100% { transform: scale(1); } 50% { transform: scale(1.005); } }
        @keyframes card-breathe-flip { 0%,100% { transform: scale(1) rotate(180deg); } 50% { transform: scale(1.005) rotate(180deg); } }
        @keyframes score-pop {
          0% { transform: scale(0.5); opacity: 0; }
          60% { transform: scale(1.15); opacity: 1; }
          100% { transform: scale(1); opacity: 1; }
        }
        @keyframes round-announce {
          0% { transform: scale(0) rotate(-10deg); opacity: 0; }
          15% { transform: scale(1.3) rotate(3deg); opacity: 1; }
          25% { transform: scale(1) rotate(0deg); opacity: 1; }
          40% { transform: scale(1) rotate(0deg); opacity: 1; }
          50% { transform: scale(0.95) rotate(0deg); opacity: 0; }
          70% { transform: scale(0.9) rotate(0deg); opacity: 0; }
          100% { transform: scale(0.9) rotate(0deg); opacity: 0.3; }
        }
        @keyframes fight-announce {
          0% { transform: scale(0) rotate(10deg); opacity: 0; }
          20% { transform: scale(1.4) rotate(-3deg); opacity: 1; }
          40% { transform: scale(1) rotate(0deg); opacity: 1; }
          75% { transform: scale(1) rotate(0deg); opacity: 1; }
          100% { transform: scale(0.8) rotate(0deg); opacity: 0; }
        }
        @keyframes score-pop-flip {
          0% { transform: scale(0.5) rotate(180deg); opacity: 0; }
          60% { transform: scale(1.15) rotate(180deg); opacity: 1; }
          100% { transform: scale(1) rotate(180deg); opacity: 1; }
        }
        @keyframes coin-flip {
          0% { transform: scale(1) rotateY(0deg); }
          25% { transform: scale(1.2) rotateY(180deg); }
          50% { transform: scale(1.3) rotateY(360deg); }
          75% { transform: scale(1.2) rotateY(540deg); }
          100% { transform: scale(1) rotateY(720deg); }
        }
      `}</style>

      <div className="h-full flex flex-col">
        {/* ===== OPPONENT HALF ===== */}
        <div className="flex-1 relative overflow-hidden flex flex-col justify-end"
          style={hasOpponent && vsReady && !isBattle ? { animation: 'clash-top 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)' } : {}}>
          <div className="absolute inset-0 bg-gradient-to-b from-slate-950/50 via-transparent to-slate-950/80 z-10 pointer-events-none" />

          {oppCard ? (
            <button onClick={() => !isBattle && !pendingResult && setShowLegendBrowser(true)}
              className={`block w-full ${!isBattle && !pendingResult ? 'active:opacity-80' : ''} transition-opacity`}>
              <img src={oppCard.media.image_url} alt={oppCard.name} className="w-full pointer-events-none select-none" style={!isBattle ? { animation: 'card-breathe-flip 6s ease-in-out infinite', transform: 'rotate(180deg)' } : { transform: 'rotate(180deg)' }} />
            </button>
          ) : hasOpponent ? (
            <button onClick={() => !isBattle && !pendingResult && setShowLegendBrowser(true)}
              className={`w-full h-full flex items-center justify-center bg-slate-900 ${!pendingResult ? 'active:opacity-80' : ''}`}>
              <div className="text-center">
                <span className="text-4xl text-slate-600 font-black">{opponent.name === 'Unknown' ? '?' : opponent.name.charAt(0)}</span>
                {opponent.name !== 'Unknown' && <p className="text-sm text-slate-500 font-bold mt-2">{opponent.name}</p>}
              </div>
            </button>
          ) : (
            <button onClick={() => setShowLegendBrowser(true)}
              className="w-full h-full flex items-center justify-center bg-slate-900 active:scale-95 transition-all">
              <div className="text-center">
                <div className="w-16 h-16 mx-auto rounded-2xl border-2 border-dashed border-slate-700 flex items-center justify-center mb-3 bg-slate-800/50">
                  <Search size={28} className="text-slate-600" />
                </div>
                <p className="text-sm font-bold text-slate-500">Tap to select opponent</p>
              </div>
            </button>
          )}

          {/* 1ST/2ND or WIN/LOSS/DRAW diagonal banner on opponent */}
          {hasOpponent && !isBattle && (
            <div className="absolute z-20" style={{ pointerEvents: 'none', top: 0, right: 0, overflow: 'hidden', width: '150px', height: '150px' }}>
              <div className={`absolute font-black text-[14px] tracking-widest text-white text-center ${pendingResult ? (pendingResult === 'win' ? 'bg-rose-500' : pendingResult === 'loss' ? 'bg-emerald-500' : 'bg-amber-500') : (!isFirst ? 'bg-emerald-500' : 'bg-amber-500')}`}
                style={{ width: '210px', top: '35px', right: '-42px', transform: 'rotate(45deg) scaleY(-1) scaleX(-1)', padding: '6px 0', boxShadow: '0 2px 8px rgba(0,0,0,0.4)' }}>
                {pendingResult ? (pendingResult === 'win' ? 'LOSS' : pendingResult === 'loss' ? 'WIN' : 'DRAW') : (!isFirst ? '1ST' : '2ND')}
              </div>
            </div>
          )}

          {/* Opponent score — rotated 180° for opponent */}
          {(isBattle || pendingResult) && (
            <div className="absolute inset-x-0 top-[15%] z-20 flex justify-center" style={pendingResult ? { animation: 'score-pop-flip 0.4s cubic-bezier(0.34,1.56,0.64,1) forwards', animationDelay: '0.3s', opacity: 0 } : { transform: 'rotate(180deg)' }}>
              <div className="flex items-center gap-5">
                {!pendingResult && <button onClick={() => setOppScore(s => Math.max(0, s - 1))}
                  className="w-14 h-14 rounded-full bg-black/50 backdrop-blur-sm border border-white/20 flex items-center justify-center active:scale-90 transition-all">
                  <Minus size={24} className="text-white/80" />
                </button>}
                <span className="text-7xl font-black tabular-nums drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)] min-w-[80px] text-center" style={pendingResult ? { color: pendingResult === 'win' ? '#f43f5e' : pendingResult === 'loss' ? '#10b981' : '#f59e0b', textShadow: `0 0 20px ${pendingResult === 'win' ? 'rgba(244,63,94,0.4)' : pendingResult === 'loss' ? 'rgba(16,185,129,0.4)' : 'rgba(245,158,11,0.4)'}, -2px -2px 0 rgba(0,0,0,0.7), 2px -2px 0 rgba(0,0,0,0.7), -2px 2px 0 rgba(0,0,0,0.7), 2px 2px 0 rgba(0,0,0,0.7)` } : { color: 'white' }}>{oppScore}</span>
                {!pendingResult && <button onClick={() => setOppScore(s => s + 1)}
                  className="w-14 h-14 rounded-full bg-black/50 backdrop-blur-sm border border-white/20 flex items-center justify-center active:scale-90 transition-all">
                  <Plus size={24} className="text-white/80" />
                </button>}
              </div>
            </div>
          )}

        </div>

        {/* ===== YOUR HALF ===== */}
        <div className="flex-1 relative overflow-hidden"
          style={hasOpponent && vsReady && !isBattle ? { animation: 'clash-bottom 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)' } : {}}>
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950/50 via-transparent to-slate-950/80 z-10 pointer-events-none" />

          {legendCard ? (
            <button onClick={() => !isBattle && !pendingResult && goBack()} className={`block w-full ${!isBattle && !pendingResult ? 'active:opacity-80' : ''} transition-opacity`}>
              <img src={legendCard.media.image_url} alt={legendCard.name} className="w-full pointer-events-none select-none" style={!isBattle ? { animation: 'card-breathe 6s ease-in-out infinite 3s' } : {}} />
            </button>
          ) : <div className="w-full h-full bg-slate-900" />}

          {/* 1ST/2ND or WIN/LOSS/DRAW diagonal banner on your legend */}
          {hasOpponent && !isBattle && (
            <div className="absolute z-20" style={{ pointerEvents: 'none', bottom: 0, left: 0, overflow: 'hidden', width: '150px', height: '150px' }}>
              <div className={`absolute font-black text-[14px] tracking-widest text-white text-center ${pendingResult ? (pendingResult === 'win' ? 'bg-emerald-500' : pendingResult === 'loss' ? 'bg-rose-500' : 'bg-amber-500') : (isFirst ? 'bg-emerald-500' : 'bg-amber-500')}`}
                style={{ width: '210px', bottom: '35px', left: '-42px', transform: 'rotate(45deg)', padding: '6px 0', boxShadow: '0 2px 8px rgba(0,0,0,0.4)' }}>
                {pendingResult ? (pendingResult === 'win' ? 'WIN' : pendingResult === 'loss' ? 'LOSS' : 'DRAW') : (isFirst ? '1ST' : '2ND')}
              </div>
            </div>
          )}

          {/* Your score */}
          {(isBattle || pendingResult) && (
            <div className="absolute inset-x-0 bottom-[15%] z-20 flex justify-center" style={pendingResult ? { animation: 'score-pop 0.4s cubic-bezier(0.34,1.56,0.64,1) forwards', animationDelay: '0.3s', opacity: 0 } : {}}>
              <div className="flex items-center gap-5">
                {!pendingResult && <button onClick={() => setMyScore(s => Math.max(0, s - 1))}
                  className="w-14 h-14 rounded-full bg-black/50 backdrop-blur-sm border border-white/20 flex items-center justify-center active:scale-90 transition-all">
                  <Minus size={24} className="text-white/80" />
                </button>}
                <span className="text-7xl font-black tabular-nums drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)] min-w-[80px] text-center" style={pendingResult ? { color: pendingResult === 'win' ? '#10b981' : pendingResult === 'loss' ? '#f43f5e' : '#f59e0b', textShadow: `0 0 20px ${pendingResult === 'win' ? 'rgba(16,185,129,0.4)' : pendingResult === 'loss' ? 'rgba(244,63,94,0.4)' : 'rgba(245,158,11,0.4)'}, -2px -2px 0 rgba(0,0,0,0.7), 2px -2px 0 rgba(0,0,0,0.7), -2px 2px 0 rgba(0,0,0,0.7), 2px 2px 0 rgba(0,0,0,0.7)` } : { color: 'white' }}>{myScore}</span>
                {!pendingResult && <button onClick={() => setMyScore(s => s + 1)}
                  className="w-14 h-14 rounded-full bg-black/50 backdrop-blur-sm border border-white/20 flex items-center justify-center active:scale-90 transition-all">
                  <Plus size={24} className="text-white/80" />
                </button>}
              </div>
            </div>
          )}

        </div>
      </div>

      {/* ===== BADGE OVERLAY (outside flex, no touch blocking) ===== */}
      <div style={{ position: 'fixed', left: 0, right: 0, top: '50%', transform: 'translateY(-50%)', zIndex: 25, display: 'flex', justifyContent: 'center', alignItems: 'center', pointerEvents: 'none' }}>
        {/* VS Screen — no opponent yet */}
        {!hasOpponent && !isBattle && !pendingResult && (
          <img src="/select-badge.png?v=2" alt="SELECT" style={{ width: '70vw', maxWidth: 'none', pointerEvents: 'none', animation: 'vs-idle 3s ease-in-out infinite' }} className="select-none" draggable={false} />
        )}

        {/* VS Screen — opponent selected, pre-battle */}
        {hasOpponent && !isBattle && !pendingResult && (
          <button
            className="relative flex flex-col items-center justify-center active:scale-90 transition-transform"
            style={{
              pointerEvents: 'auto',
              width: '80px',
              height: '80px',
              overflow: 'visible',
              ...(vsReady && !isFlipping ? { animation: 'vs-slam 0.5s cubic-bezier(0.34,1.56,0.64,1) forwards, vs-idle 3s ease-in-out 0.5s infinite' } : {}),
              ...(isFlipping ? { animation: 'coin-flip 0.8s ease-in-out' } : {}),
              perspective: '600px'
            }}
            onClick={() => {
              if (isFlipping || wasFlipped.current) { wasFlipped.current = false; return; }
              setIsFirst(f => !f);
            }}
            onTouchStart={() => {
              wasFlipped.current = false;
              longPressTimer.current = setTimeout(() => {
                wasFlipped.current = true;
                setIsFlipping(true);
                const flips = 6 + Math.floor(Math.random() * 4);
                let i = 0;
                const iv = setInterval(() => {
                  setIsFirst(f => f === true ? false : true);
                  i++;
                  if (i >= flips) {
                    clearInterval(iv);
                    setIsFirst(Math.random() < 0.5);
                    setTimeout(() => setIsFlipping(false), 200);
                  }
                }, 80);
                longPressTimer.current = null;
              }, 500);
            }}
            onTouchEnd={() => {
              if (longPressTimer.current) { clearTimeout(longPressTimer.current); longPressTimer.current = null; }
            }}
            onTouchCancel={() => {
              if (longPressTimer.current) { clearTimeout(longPressTimer.current); longPressTimer.current = null; }
            }}
            onMouseDown={() => {
              wasFlipped.current = false;
              longPressTimer.current = setTimeout(() => {
                wasFlipped.current = true;
                setIsFlipping(true);
                const flips = 6 + Math.floor(Math.random() * 4);
                let i = 0;
                const iv = setInterval(() => {
                  setIsFirst(f => f === true ? false : true);
                  i++;
                  if (i >= flips) {
                    clearInterval(iv);
                    setIsFirst(Math.random() < 0.5);
                    setTimeout(() => setIsFlipping(false), 200);
                  }
                }, 80);
                longPressTimer.current = null;
              }, 500);
            }}
            onMouseUp={() => {
              if (longPressTimer.current) { clearTimeout(longPressTimer.current); longPressTimer.current = null; }
            }}
            onMouseLeave={() => {
              if (longPressTimer.current) { clearTimeout(longPressTimer.current); longPressTimer.current = null; }
            }}
          >
            <img src="/vs-badge.png?v=10" alt="VS" style={{ width: '80vw', maxWidth: 'none', position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -50%)' }} className="pointer-events-none select-none" draggable={false} />
          </button>
        )}

        {/* Battle — round badge: announce then dim */}
        {hasOpponent && isBattle && (
          <>
            <img
              src={games.length === 0 ? '/round1-badge.png?v=2' : games.length === 1 ? '/round2-badge.png?v=2' : '/final-badge.png?v=2'}
              alt={games.length === 0 ? 'ROUND 1' : games.length === 1 ? 'ROUND 2' : 'FINAL'}
              style={{
                width: '70vw',
                maxWidth: 'none',
                pointerEvents: 'none',
                position: 'absolute',
                ...(roundAnnounce
                  ? { animation: 'round-announce 2.5s ease-out forwards' }
                  : { opacity: 0.3, transform: 'scale(0.9)' }
                ),
              }}
              className="select-none" draggable={false}
            />
            {roundAnnounce && (
              <img
                src="/fight-badge.png?v=2"
                alt="FIGHT"
                style={{
                  width: '85vw',
                  maxWidth: 'none',
                  pointerEvents: 'none',
                  position: 'absolute',
                  animation: 'fight-announce 1.4s ease-out 1.0s forwards',
                  opacity: 0,
                }}
                className="select-none" draggable={false}
              />
            )}
          </>
        )}

        {/* Finish — FINISH badge, tap = toggle win/loss */}
        {hasOpponent && !isBattle && pendingResult && (
          <button
            className="relative flex flex-col items-center justify-center active:scale-90 transition-transform"
            style={{
              pointerEvents: 'auto',
              width: '80px',
              height: '80px',
              overflow: 'visible',
              animation: 'vs-slam 0.5s cubic-bezier(0.34,1.56,0.64,1) forwards, vs-idle 3s ease-in-out 0.5s infinite'
            }}
            onClick={() => setPendingResult(r => r === 'win' ? 'loss' : r === 'loss' ? 'draw' : 'win')}
          >
            <img src="/finish-badge.png?v=2" alt="FINISH" style={{ width: '80vw', maxWidth: 'none', position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -50%)' }} className="pointer-events-none select-none" draggable={false} />
          </button>
        )}
      </div>





      {/* ===== GAME DOTS — OPPONENT (top, rotated 180°) ===== */}
      {(isBattle || pendingResult) && (
        <div className="absolute top-[env(safe-area-inset-top,12px)] left-1/2 z-30 mt-2 flex items-center gap-2 bg-black/60 backdrop-blur-sm border border-white/10 rounded-full px-3 py-1.5"
          style={{ transform: 'translateX(-50%) rotate(180deg)' }}>
          {/* Completed games — inverted colors for opponent */}
          {games.map((g, i) => (
            <div key={i} className={`w-3 h-3 rounded-full ${g.result === 'win' ? 'bg-rose-500' : g.result === 'loss' ? 'bg-emerald-500' : 'bg-amber-500'}`} />
          ))}
          {/* Current game dot */}
          {pendingResult ? (
            <div className={`w-3 h-3 rounded-full transition-colors ${pendingResult === 'win' ? 'bg-rose-500' : pendingResult === 'loss' ? 'bg-emerald-500' : 'bg-amber-500'}`} />
          ) : (
            <div className="w-3 h-3 rounded-full bg-white/30 border border-white/50" />
          )}
          {/* Remaining */}
          {Array.from({ length: Math.max(0, 2 - games.length - (pendingResult ? 1 : 0)) }).map((_, i) => (
            <div key={`r${i}`} className="w-2.5 h-2.5 rounded-full bg-white/10" />
          ))}
        </div>
      )}

      {/* ===== GAME DOTS — YOU (bottom) ===== */}
      {(isBattle || pendingResult) && (
        <div className="absolute bottom-[env(safe-area-inset-bottom,12px)] left-1/2 -translate-x-1/2 z-30 mb-2 flex items-center gap-2 bg-black/60 backdrop-blur-sm border border-white/10 rounded-full px-3 py-1.5">
          {/* Completed games */}
          {games.map((g, i) => (
            <div key={i} className={`w-3 h-3 rounded-full ${g.result === 'win' ? 'bg-emerald-500' : g.result === 'loss' ? 'bg-rose-500' : 'bg-amber-500'}`} />
          ))}
          {/* Current game dot */}
          {pendingResult ? (
            <div className={`w-3 h-3 rounded-full transition-colors ${pendingResult === 'win' ? 'bg-emerald-500' : pendingResult === 'loss' ? 'bg-rose-500' : 'bg-amber-500'}`} />
          ) : (
            <div className="w-3 h-3 rounded-full bg-white/30 border border-white/50" />
          )}
          {/* Remaining */}
          {Array.from({ length: Math.max(0, 2 - games.length - (pendingResult ? 1 : 0)) }).map((_, i) => (
            <div key={`r${i}`} className="w-2.5 h-2.5 rounded-full bg-white/10" />
          ))}
        </div>
      )}

      {/* ===== BACK BUTTON (bottom-right, orange) ===== */}
      <button onClick={goBack}
        className={`absolute bottom-[env(safe-area-inset-bottom,12px)] right-3 z-30 w-14 h-14 rounded-full flex items-center justify-center shadow-2xl active:scale-90 mb-4 transition-colors duration-300 ${
          hasOpponent && !isBattle && !pendingResult ? 'bg-slate-700 active:bg-slate-600' : 'bg-amber-600 active:bg-amber-500'
        }`}
        style={{
          transform: (!isBattle && hasOpponent && !pendingResult) ? 'translateX(-68px)' : 'translateX(0)',
          transition: 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          animation: 'tracker-fab-enter 0.35s cubic-bezier(0.4, 0, 0.2, 1) both',
        }}>
        <ArrowLeft size={20} className="text-white" />
      </button>
      <style>{`
        @keyframes tracker-fab-enter {
          from { opacity: 0; scale: 0.3; }
          to { opacity: 1; scale: 1; }
        }
      `}</style>

      {/* ===== BATTLE BUTTON — small round (bottom-right) ===== */}
      {!isBattle && hasOpponent && !pendingResult && (
        <button onClick={startBattle}
          className="absolute bottom-[env(safe-area-inset-bottom,12px)] right-3 z-30 w-14 h-14 rounded-full bg-amber-600 active:bg-amber-500 flex items-center justify-center shadow-2xl shadow-amber-900/50 active:scale-90 mb-4"
          style={{ animation: 'tracker-fab-enter 0.35s cubic-bezier(0.4, 0, 0.2, 1) both' }}>
          <Swords size={22} className="text-white" />
        </button>
      )}
      {/* Next Round button (above confirm) */}
      {!isBattle && hasOpponent && pendingResult && games.length < 2 && (
        <button onClick={handleRematch}
          className="absolute bottom-[env(safe-area-inset-bottom,12px)] right-3 z-30 w-14 h-14 rounded-full bg-amber-500 active:bg-amber-400 flex items-center justify-center shadow-2xl shadow-amber-900/50 active:scale-90 mb-[76px]"
          style={{ animation: 'tracker-fab-enter 0.35s cubic-bezier(0.4, 0, 0.2, 1) both' }}>
          <Swords size={22} className="text-white" />
        </button>
      )}
      {/* Confirm/Save button */}
      {!isBattle && hasOpponent && pendingResult && (
        <button onClick={() => saveMatch(pendingResult)}
          className="absolute bottom-[env(safe-area-inset-bottom,12px)] right-3 z-30 w-14 h-14 rounded-full bg-emerald-600 active:bg-emerald-500 flex items-center justify-center shadow-2xl shadow-emerald-900/50 active:scale-90 mb-4"
          style={{ animation: 'tracker-fab-enter 0.35s cubic-bezier(0.4, 0, 0.2, 1) both' }}>
          <Check size={24} strokeWidth={3} className="text-white" />
        </button>
      )}

      {/* ===== FINISH BUTTON — small round (Battle, bottom-right) ===== */}
      {isBattle && (
        <button onClick={() => {
          const result = myScore > oppScore ? 'win' : myScore < oppScore ? 'loss' : 'draw';
          setPendingResult(result);
          setStep('opponent');
        }}
          className="absolute bottom-[env(safe-area-inset-bottom,12px)] right-3 z-30 w-14 h-14 rounded-full bg-amber-600 active:bg-amber-500 flex items-center justify-center shadow-2xl shadow-amber-900/50 active:scale-90 mb-4"
          style={{ animation: 'tracker-fab-enter 0.35s cubic-bezier(0.4, 0, 0.2, 1) both' }}>
          <Check size={24} strokeWidth={3} className="text-white" />
        </button>
      )}

      {/* ===== LEGEND BROWSER ===== */}
      {showLegendBrowser && (
        <div className="fixed inset-0 z-[99999] flex flex-col" onClick={() => setShowLegendBrowser(false)}>
          <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" />
          <div className="relative flex-1 flex flex-col max-h-full" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between px-4 pt-[env(safe-area-inset-top,12px)] pb-3 bg-slate-900 border-b border-slate-800">
              <h3 className="text-base font-black text-white pl-1">Opponent Legend</h3>
              <button onClick={() => setShowLegendBrowser(false)} className="p-2 text-slate-400 active:text-white"><X size={20} /></button>
            </div>
            <div className="px-4 py-3 bg-slate-900/95">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 text-slate-500" size={16} />
                <input type="text" placeholder="Search legend..." value={legendSearch}
                  onChange={e => setLegendSearch(e.target.value)}
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl py-2.5 pl-10 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none" />
              </div>
            </div>
            <div className="flex-1 overflow-y-auto px-3 pb-24 overscroll-contain" style={{ WebkitOverflowScrolling: 'touch' }}>
              <div className="grid grid-cols-3 gap-2 pt-2">
                {filteredLegends.map(card => {
                  const shortName = getChampionName(card);
                  const isSel = opponent?.name === shortName;
                  return (
                    <button key={card.id} onClick={() => selectOpponent(card)}
                      className="relative rounded-xl overflow-hidden transition-all active:scale-95"
                      style={{ touchAction: 'manipulation' }}>
                      <div className={`aspect-[2/3] ${isSel ? 'ring-2 ring-amber-400/80 rounded-xl' : ''}`}>
                        <img src={card.media.image_url} alt={shortName}
                          className="w-full h-full object-cover rounded-xl pointer-events-none select-none" loading="lazy" draggable={false} />
                        {isSel && <div className="absolute inset-0 bg-amber-500/20 rounded-xl border-2 border-amber-500" />}
                      </div>
                      <p className={`text-xs font-bold text-center mt-1 truncate px-0.5 ${isSel ? 'text-amber-400' : 'text-slate-300'}`}>{shortName}</p>
                    </button>
                  );
                })}
                {(!legendSearch || 'unknown'.includes(legendSearch.toLowerCase())) && (
                  <button onClick={() => selectOpponent(null)}
                    className="relative rounded-xl overflow-hidden transition-all active:scale-95">
                    <div className={`aspect-[2/3] bg-slate-800 border-2 border-dashed border-slate-700 rounded-xl flex items-center justify-center ${opponent?.name === 'Unknown' ? 'ring-2 ring-amber-400/80' : ''}`}>
                      <span className="text-slate-600 text-2xl font-black">?</span>
                    </div>
                    <p className={`text-[10px] font-bold text-center mt-1 ${opponent?.name === 'Unknown' ? 'text-amber-400' : 'text-slate-500'}`}>Unknown</p>
                  </button>
                )}
              </div>

              {/* Custom name option when search has text */}
              {legendSearch.trim().length > 0 && (
                <button onClick={() => selectOpponent(null, legendSearch.trim())}
                  className="w-full mt-3 mb-2 py-3 px-4 bg-slate-800 border border-dashed border-slate-600 rounded-xl flex items-center justify-center gap-2 active:scale-95 transition-all">
                  <span className="text-sm text-slate-300 font-bold">Use “{legendSearch.trim()}”</span>
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

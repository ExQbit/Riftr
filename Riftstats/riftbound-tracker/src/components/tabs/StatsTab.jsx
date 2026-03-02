import React, { useState, useMemo, useRef, useCallback } from 'react';
import {
  Download, Trash2, Swords, Target, ChevronDown,
  MessageSquare, Trash, X, Check, Flame, TrendingDown,
  Zap, Shield, BarChart3
} from 'lucide-react';
import { RUNE_COLORS } from '../../constants/gameData';

// ========================================
// SVG Win Rate Ring
// ========================================
function WinRateRing({ rate, size = 140, strokeWidth = 10 }) {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (parseFloat(rate) / 100) * circumference;
  const color = parseFloat(rate) >= 50 ? '#10b981' : '#f43f5e';

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="transform -rotate-90">
        <circle cx={size / 2} cy={size / 2} r={radius}
          stroke="rgba(255,255,255,0.05)" strokeWidth={strokeWidth} fill="none" />
        <circle cx={size / 2} cy={size / 2} r={radius}
          stroke={color} strokeWidth={strokeWidth} fill="none"
          strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={offset}
          style={{ transition: 'stroke-dashoffset 1s ease-out' }} />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-3xl font-black text-white">{rate}%</span>
        <span className="text-[10px] font-black text-slate-500 uppercase">Win Rate</span>
      </div>
    </div>
  );
}

// ========================================
// Form Dots (last N results)
// ========================================
function FormDots({ results, max = 10 }) {
  const dots = results.slice(0, max);
  return (
    <div className="flex gap-1 items-center">
      {dots.map((r, i) => (
        <div key={i} className={`w-2.5 h-2.5 rounded-full ${r === 'win' ? 'bg-emerald-500' : 'bg-rose-500'}`}
          style={{ opacity: 1 - (i * 0.06) }} />
      ))}
    </div>
  );
}

// ========================================
// Mini Bar
// ========================================
function MiniBar({ value, max = 100, color = 'bg-amber-500', height = 'h-2' }) {
  const pct = max > 0 ? Math.min((value / max) * 100, 100) : 0;
  return (
    <div className={`flex-1 bg-slate-700/60 rounded-full ${height} overflow-hidden`}>
      <div className={`${height} rounded-full ${color} transition-all duration-500`} style={{ width: `${pct}%` }} />
    </div>
  );
}

// ========================================
// Stat Card
// ========================================
function StatCard({ icon: Icon, label, value, sub, color = 'text-white' }) {
  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-3 flex flex-col gap-1">
      <div className="flex items-center gap-1.5">
        <Icon size={12} className="text-slate-500" />
        <span className="text-[10px] font-black text-slate-500 uppercase">{label}</span>
      </div>
      <span className={`text-xl font-black ${color}`}>{value}</span>
      {sub && <span className="text-[10px] text-slate-600">{sub}</span>}
    </div>
  );
}

// ========================================
// Win Rate Trend Chart (interactive)
// ========================================
function WinRateTimeline({ timeline }) {
  if (!timeline || timeline.length < 2) return null;

  const [mode, setMode] = useState('cumulative'); // 'cumulative' | 'rolling'
  const [activeIdx, setActiveIdx] = useState(null);
  const svgRef = useRef(null);

  const height = 160;
  const width = 340;
  const padX = 28;
  const padTop = 12;
  const padBot = 20;
  const chartH = height - padTop - padBot;
  const chartW = width - padX - 8;

  const data = timeline.map(t => mode === 'rolling' ? t.rollingWR : t.winRate);
  const rawMin = Math.min(...data);
  const rawMax = Math.max(...data);
  const range = Math.max(rawMax - rawMin, 10);
  const min = Math.max(rawMin - range * 0.1, 0);
  const max = Math.min(rawMax + range * 0.1, 100);
  const finalRange = max - min;

  const getX = (i) => padX + (i / (timeline.length - 1)) * chartW;
  const getY = (val) => padTop + chartH - ((val - min) / finalRange) * chartH;

  // Polyline
  const points = data.map((val, i) => `${getX(i)},${getY(val)}`).join(' ');

  // Gradient area
  const areaPoints = `${getX(0)},${padTop + chartH} ${points} ${getX(data.length - 1)},${padTop + chartH}`;

  // 50% reference line
  const fiftyY = getY(50);
  const show50 = fiftyY >= padTop && fiftyY <= padTop + chartH;

  // Y-axis labels
  const yLabels = [];
  const step = finalRange <= 20 ? 5 : finalRange <= 50 ? 10 : 20;
  for (let v = Math.ceil(min / step) * step; v <= max; v += step) {
    yLabels.push(v);
  }

  // Touch/click handler
  const handleInteraction = useCallback((e) => {
    if (!svgRef.current || timeline.length < 2) return;
    const rect = svgRef.current.getBoundingClientRect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const svgX = ((clientX - rect.left) / rect.width) * width;
    const idx = Math.round(((svgX - padX) / chartW) * (timeline.length - 1));
    const clamped = Math.max(0, Math.min(timeline.length - 1, idx));
    setActiveIdx(clamped);
  }, [timeline.length, width, chartW, padX]);

  const lastPoint = timeline[timeline.length - 1];
  const lastVal = mode === 'rolling' ? lastPoint.rollingWR : lastPoint.winRate;
  const lineColor = lastVal >= 50 ? '#10b981' : '#f43f5e';
  const gradientId = `wr-grad-${mode}`;

  const active = activeIdx !== null ? timeline[activeIdx] : null;
  const activeVal = active ? (mode === 'rolling' ? active.rollingWR : active.winRate) : null;

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
      {/* Header + Tooltip (fixed height so layout doesn't shift) */}
      <div className="flex items-center justify-between mb-3">
        {active ? (
          <div className="flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${active.result === 'win' ? 'bg-emerald-500' : 'bg-rose-500'}`} />
            <span className="text-xs font-bold text-white">#{active.index}</span>
            <span className="text-[10px] text-slate-400">vs {active.opponent}</span>
            <span className={`text-xs font-black ${activeVal >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
              {activeVal}%
            </span>
          </div>
        ) : (
          <p className="text-[10px] font-black text-slate-500 uppercase">Win Rate Trend</p>
        )}
        <div className="flex gap-1">
          {['cumulative', 'rolling'].map(m => (
            <button key={m} onClick={() => { setMode(m); setActiveIdx(null); }}
              className={`px-2 py-0.5 rounded-md text-[9px] font-bold transition-all ${mode === m ? 'bg-slate-700 text-white' : 'text-slate-500 hover:text-slate-300'}`}>
              {m === 'cumulative' ? 'Overall' : 'Last 10'}
            </button>
          ))}
        </div>
      </div>

      {/* SVG Chart */}
      <svg ref={svgRef} viewBox={`0 0 ${width} ${height}`} className="w-full touch-none" style={{ height: 160 }}
        onMouseMove={handleInteraction}
        onTouchMove={handleInteraction}
        onTouchStart={handleInteraction}
        onMouseLeave={() => setActiveIdx(null)}
        onTouchEnd={() => setActiveIdx(null)}
      >
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={lineColor} stopOpacity="0.25" />
            <stop offset="100%" stopColor={lineColor} stopOpacity="0" />
          </linearGradient>
        </defs>

        {/* Y-axis labels */}
        {yLabels.map(v => (
          <g key={v}>
            <line x1={padX} y1={getY(v)} x2={width - 8} y2={getY(v)}
              stroke="rgba(255,255,255,0.04)" strokeWidth="1" />
            <text x={padX - 4} y={getY(v) + 3} textAnchor="end"
              fill="rgba(255,255,255,0.2)" fontSize="8" fontWeight="bold">{v}%</text>
          </g>
        ))}

        {/* 50% reference */}
        {show50 && (
          <line x1={padX} y1={fiftyY} x2={width - 8} y2={fiftyY}
            stroke="rgba(255,255,255,0.15)" strokeWidth="1" strokeDasharray="4,3" />
        )}

        {/* Area fill */}
        <polygon points={areaPoints} fill={`url(#${gradientId})`} />

        {/* Main line */}
        <polyline points={points} fill="none"
          stroke={lineColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />

        {/* Match dots */}
        {timeline.map((t, i) => {
          const x = getX(i);
          const y = getY(data[i]);
          const isActive = activeIdx === i;
          return (
            <circle key={i} cx={x} cy={y}
              r={isActive ? 5 : (timeline.length <= 30 ? 3 : 0)}
              fill={t.result === 'win' ? '#10b981' : '#f43f5e'}
              stroke={isActive ? 'white' : 'none'}
              strokeWidth={isActive ? 2 : 0}
              opacity={isActive ? 1 : 0.7}
            />
          );
        })}

        {/* Active crosshair */}
        {activeIdx !== null && (
          <line x1={getX(activeIdx)} y1={padTop} x2={getX(activeIdx)} y2={padTop + chartH}
            stroke="rgba(255,255,255,0.2)" strokeWidth="1" strokeDasharray="3,3" />
        )}
      </svg>

      {/* Footer */}
      <div className="flex justify-between mt-1 px-1">
        <span className="text-[9px] text-slate-600">Match 1</span>
        <span className={`text-[9px] font-bold ${lastVal >= 50 ? 'text-emerald-500' : 'text-rose-500'}`}>
          {lastVal}%
        </span>
        <span className="text-[9px] text-slate-600">Match {timeline.length}</span>
      </div>
    </div>
  );
}


// ========================================
// MAIN STATS TAB
// ========================================
export default function StatsTab({ stats, matches, allCards = [], savedDecks = [], updateMatchNotes, updateMatchGames, deleteMatch, exportCSV, clearAll, onActivateDemo, isDemoMode }) {
  const [activeSection, setActiveSection] = useState('overview');
  const [expandedMatch, setExpandedMatch] = useState(null);
  const [editingNotes, setEditingNotes] = useState(null);
  const [notesText, setNotesText] = useState('');
  const [expandedDeck, setExpandedDeck] = useState(null);
  const [expandedMatchup, setExpandedMatchup] = useState(null);
  const [expandedBf, setExpandedBf] = useState(null);
  const [expandedBfOpp, setExpandedBfOpp] = useState(null);
  const [historyFilter, setHistoryFilter] = useState('all');
  const [historyDeckFilter, setHistoryDeckFilter] = useState('all');

  // Legend lookup: short name ("Annie") → Legend card object (with media.image_url)
  const legendByShortName = useMemo(() => {
    const map = new Map();
    allCards
      .filter(c => c.classification?.type === 'Legend')
      .forEach(c => {
        const short = c.name?.includes(',') ? c.name.split(',')[0].trim() : c.name;
        if (!short) return;
        const existing = map.get(short);
        const isAlt = c.metadata?.alternate_art || c.metadata?.overnumbered || c.metadata?.signature;
        if (!existing || (existing._isAlt && !isAlt)) {
          map.set(short, { ...c, _isAlt: isAlt });
        }
      });
    return map;
  }, [allCards]);

  const sortedMatches = useMemo(() =>
    [...(matches || [])].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)),
  [matches]);

  const filteredMatches = useMemo(() => {
    let filtered = sortedMatches;
    if (historyFilter === 'wins') filtered = filtered.filter(m => m.result === 'win');
    if (historyFilter === 'losses') filtered = filtered.filter(m => m.result === 'loss');
    if (historyDeckFilter !== 'all') filtered = filtered.filter(m => (m.deckId || m.deckName) === historyDeckFilter);
    return filtered;
  }, [sortedMatches, historyFilter, historyDeckFilter]);

  const deckNames = useMemo(() => {
    const names = new Map();
    (matches || []).forEach(m => {
      const key = m.deckId || m.deckName || 'Unknown';
      if (!names.has(key)) names.set(key, m.deckName || 'Unknown');
    });
    return [...names.entries()];
  }, [matches]);

  // EMPTY STATE
  if (!matches || matches.length === 0) {
    return (
      <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
        <div className="p-20 text-center bg-slate-900 rounded-3xl border border-slate-800">
          <BarChart3 size={48} className="mx-auto mb-4 text-slate-700" />
          <p className="text-slate-600 font-bold">No matches yet</p>
          <p className="text-slate-700 text-xs mt-1">Track matches in the Tracker tab</p>
          {onActivateDemo && !isDemoMode && (
            <button
              onClick={onActivateDemo}
              className="mt-4 px-4 py-2 rounded-full text-xs font-bold text-amber-400 border border-amber-500/30 hover:bg-amber-500/10 transition-all active:scale-95"
            >
              Try Demo Mode
            </button>
          )}
        </div>
      </div>
    );
  }

  const pillClass = (isActive) =>
    `px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all active:scale-95 ${
      isActive ? 'bg-amber-600 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'
    }`;

  const startEditNotes = (match) => {
    setEditingNotes(match.id);
    setNotesText(match.notes || '');
  };

  const saveNotes = async (matchId) => {
    await updateMatchNotes(matchId, notesText);
    setEditingNotes(null);
  };

  const formatDate = (ts) => {
    const d = new Date(ts);
    const now = new Date();
    const diff = now - d;
    if (diff < 60000) return 'Just now';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
    if (diff < 172800000) return 'Yesterday';
    return d.toLocaleDateString('en-US', { day: '2-digit', month: '2-digit', year: '2-digit' });
  };

  return (
    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-24">

      {/* Gold Ornament Header */}
      <div className="text-center pt-3 pb-1">
        <div className="flex items-center justify-center gap-3 mb-2">
          <div className="h-px w-12 bg-gradient-to-r from-transparent to-amber-500/50" />
          <div className="w-1.5 h-1.5 rotate-45 bg-amber-500/60" />
          <div className="h-px w-12 bg-gradient-to-l from-transparent to-amber-500/50" />
        </div>
        <h2 className="text-xs font-black uppercase tracking-[0.3em] bg-gradient-to-r from-amber-200 via-yellow-100 to-amber-200 bg-clip-text text-transparent">
          Know Your Strength
        </h2>
      </div>

      {/* ===== HERO SECTION ===== */}
      <div className="bg-slate-900 border border-amber-500/10 rounded-3xl p-6">
        <div className="flex items-center gap-5">
          <WinRateRing rate={stats.winRate} />
          <div className="flex-1 space-y-3">
            <div>
              <p className="text-[10px] font-black text-slate-500 uppercase mb-1">Record</p>
              <p className="text-lg font-black">
                <span className="text-emerald-400">{stats.wins}W</span>
                <span className="text-slate-600 mx-1">–</span>
                <span className="text-rose-400">{stats.losses}L</span>
              </p>
            </div>
            <div>
              <p className="text-[10px] font-black text-slate-500 uppercase mb-1">Streak</p>
              <div className="flex items-center gap-1.5">
                {stats.currentStreakType === 'win' ? (
                  <Flame size={14} className="text-emerald-400" />
                ) : (
                  <TrendingDown size={14} className="text-rose-400" />
                )}
                <span className={`text-lg font-black ${stats.currentStreakType === 'win' ? 'text-emerald-400' : 'text-rose-400'}`}>
                  {stats.currentStreak}{stats.currentStreakType === 'win' ? 'W' : 'L'}
                </span>
                <span className="text-[10px] text-slate-600 ml-1">Best: {stats.bestWinStreak}W</span>
              </div>
            </div>
            <div>
              <p className="text-[10px] font-black text-slate-500 uppercase mb-1">Last {stats.last5.total}</p>
              <FormDots results={stats.last5.results} max={5} />
            </div>
          </div>
        </div>
      </div>

      {/* Section divider */}
      <div className="flex items-center gap-2 px-1">
        <BarChart3 size={12} className="text-amber-500/50" />
        <span className="text-[10px] font-bold uppercase tracking-[0.15em] text-amber-500/40">Analysis</span>
        <div className="h-px flex-1 bg-gradient-to-r from-amber-500/15 to-transparent" />
      </div>

      <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1 no-scrollbar">
        <button onClick={() => setActiveSection('overview')} className={pillClass(activeSection === 'overview')}>Overview</button>
        <button onClick={() => setActiveSection('showcase')} className={pillClass(activeSection === 'showcase')}>Showcase</button>
        <button onClick={() => setActiveSection('decks')} className={pillClass(activeSection === 'decks')}>Decks</button>
        <button onClick={() => setActiveSection('battlefields')} className={pillClass(activeSection === 'battlefields')}>Battlefields</button>
        <button onClick={() => setActiveSection('matchups')} className={pillClass(activeSection === 'matchups')}>Matchups</button>
        <button onClick={() => setActiveSection('history')} className={pillClass(activeSection === 'history')}>History</button>
      </div>


      {/* ===== SHOWCASE SECTION ===== */}
      {activeSection === 'showcase' && (
        <div className="space-y-3">
          {stats.total > 0 ? (() => {
            // --- Resolve card helper ---
            const resolveCard = (legendName, opponent, deckName) => {
              let cardImg = null, cardDomains = [];
              if (opponent) {
                const legend = legendByShortName.get(opponent);
                cardImg = legend?.media?.image_url;
                cardDomains = legend?.classification?.domain || [];
              } else if (legendName) {
                const sn = legendName.includes(',') ? legendName.split(',')[0].trim() : legendName;
                const legend = legendByShortName.get(sn) || allCards.find(c => c.name === legendName && c.classification?.type === 'Legend');
                cardImg = legend?.media?.image_url;
                cardDomains = legend?.classification?.domain || [];
              } else if (deckName) {
                const sd = savedDecks.find(s => s.name === deckName);
                const legend = sd?.legendData || (sd?.legend ? allCards.find(c => c.id === sd.legend) : null);
                cardImg = legend?.media?.image_url;
                cardDomains = legend?.classification?.domain || [];
              }
              return { cardImg, cardDomains };
            };

            // --- Eigene Legenden aggregiert ---
            const legendAgg = {};
            (stats.deckStats || []).forEach(d => {
              const ln = d.legendName || 'Unknown';
              if (!legendAgg[ln]) legendAgg[ln] = { legendName: ln, wins: 0, losses: 0, total: 0 };
              legendAgg[ln].wins += d.wins;
              legendAgg[ln].losses += d.losses;
              legendAgg[ln].total += d.total;
            });
            const legendStats = Object.values(legendAgg)
              .map(l => ({ ...l, winRate: l.total > 0 ? (l.wins / l.total * 100).toFixed(1) : '0.0' }))
              .sort((a, b) => b.total - a.total);
            const mostPlayed = legendStats[0] || null;

            // --- Opponents ---
            const eligible = (stats.matchupStats || []).filter(m => m.total >= 1);
            const bestMatchup = eligible.length > 0 ? eligible.reduce((best, m) => parseFloat(m.winRate) > parseFloat(best.winRate) ? m : best) : null;
            const worstMatchup = eligible.length > 0 ? eligible.reduce((worst, m) => parseFloat(m.winRate) < parseFloat(worst.winRate) ? m : worst) : null;
            const mostFaced = eligible.length > 0 ? eligible[0] : null; // already sorted by total

            // --- Best Deck ---
            const bestDeck = stats.deckStats?.length > 0 ? stats.deckStats.reduce((best, d) => parseFloat(d.winRate) > parseFloat(best.winRate) ? d : best) : null;

            // --- Biggest Win ---
            const biggestWin = stats.scoreStats?.biggestWin || null;

            // --- Showcase Card Component (consistent with Decks/Matchups style) ---
            const ShowcaseCard = ({ label, cardImg, title, wr, sub }) => {
              const wrNum = parseFloat(wr);
              return (
                <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden p-2.5">
                  <p className="text-[10px] font-black text-slate-500 uppercase mb-2">{label}</p>
                  <div className="flex items-center gap-2.5">
                    <div className="shrink-0">
                      {cardImg ? (
                        <img src={cardImg} alt={title} className="w-14 h-[84px] object-cover rounded-lg" />
                      ) : (
                        <div className="w-14 h-[84px] rounded-lg bg-slate-800 border-2 border-dashed border-slate-700 flex items-center justify-center">
                          <Target size={16} className="text-slate-600" />
                        </div>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-bold text-white truncate">{title}</p>
                      <p className="text-[10px] text-slate-500">{sub}</p>
                    </div>
                    <span className={`text-lg font-black shrink-0 ${wrNum >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>{wr}%</span>
                  </div>
                  <div className="mt-2">
                    <MiniBar value={wrNum} />
                  </div>
                </div>
              );
            };

            // --- Most Played Legend ---
            const mpCard = mostPlayed ? resolveCard(mostPlayed.legendName, null, null) : null;
            const mpName = mostPlayed?.legendName?.includes(',') ? mostPlayed.legendName.split(',')[0].trim() : mostPlayed?.legendName;

            // --- Best Matchup ---
            const bmCard = bestMatchup ? resolveCard(null, bestMatchup.opponent, null) : null;

            // --- Nemesis ---
            const nmCard = worstMatchup && worstMatchup !== bestMatchup && parseFloat(worstMatchup.winRate) < 100 ? resolveCard(null, worstMatchup.opponent, null) : null;

            // --- Most Faced ---
            const mfCard = mostFaced && mostFaced !== bestMatchup && mostFaced !== worstMatchup ? resolveCard(null, mostFaced.opponent, null) : null;

            // --- Best Deck ---
            const bdCard = bestDeck ? resolveCard(bestDeck.legendName, null, bestDeck.name) : null;

            // --- Biggest Win ---
            const bwCard = biggestWin ? resolveCard(null, biggestWin.opponent, null) : null;

            return (
              <div className="grid grid-cols-2 gap-3">
                {mostPlayed && mpCard && (
                  <ShowcaseCard label="Main Legend" cardImg={mpCard.cardImg} title={mpName}
                    wr={mostPlayed.winRate} sub={`${mostPlayed.wins}W ${mostPlayed.losses}L · ${mostPlayed.total} Games`} />
                )}
                {bestMatchup && bmCard && parseFloat(bestMatchup.winRate) > 0 && (
                  <ShowcaseCard label="Best Matchup" cardImg={bmCard.cardImg} title={bestMatchup.opponent}
                    wr={bestMatchup.winRate} sub={`${bestMatchup.wins}W ${bestMatchup.losses}L · ${bestMatchup.total} Games`} />
                )}
                {worstMatchup && nmCard && (
                  <ShowcaseCard label="Nemesis" cardImg={nmCard.cardImg} title={worstMatchup.opponent}
                    wr={worstMatchup.winRate} sub={`${worstMatchup.wins}W ${worstMatchup.losses}L · ${worstMatchup.total} Games`} />
                )}
                {mostFaced && mfCard && (
                  <ShowcaseCard label="Arch Rival" cardImg={mfCard.cardImg} title={mostFaced.opponent}
                    wr={mostFaced.winRate} sub={`${mostFaced.wins}W ${mostFaced.losses}L · ${mostFaced.total} Games`} />
                )}
                {bestDeck && bdCard && (
                  <ShowcaseCard label="Best Deck" cardImg={bdCard.cardImg} title={bestDeck.name}
                    wr={bestDeck.winRate} sub={`${bestDeck.wins}W ${bestDeck.losses}L · ${bestDeck.total} Games`} />
                )}
                {biggestWin && bwCard && (
                  <ShowcaseCard label="Biggest Win" cardImg={bwCard.cardImg} title={`vs ${biggestWin.opponent}`}
                    wr={biggestWin.myScore > 0 ? ((biggestWin.myScore / (biggestWin.myScore + biggestWin.oppScore)) * 100).toFixed(1) : '100.0'}
                    sub={`${biggestWin.myScore} : ${biggestWin.oppScore} · ${new Date(biggestWin.timestamp).toLocaleDateString('en-US', { day: 'numeric', month: 'short' })}`} />
                )}
              </div>
            );
          })() : (
            <p className="text-center text-slate-500 text-sm py-8">Play some matches to see your Showcase.</p>
          )}
        </div>
      )}

      {/* ===== OVERVIEW SECTION ===== */}
      {activeSection === 'overview' && (
        <div className="space-y-4">
          {/* 1st vs 2nd */}
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
            <p className="text-[10px] font-black text-slate-500 uppercase mb-3">1st vs 2nd Player</p>
            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <span className="text-[10px] font-black text-blue-400 w-8">1ST</span>
                <MiniBar value={parseFloat(stats.firstWR)} color={parseFloat(stats.firstWR) >= 50 ? 'bg-blue-500' : 'bg-blue-500/50'} />
                <span className={`text-sm font-black min-w-[48px] text-right ${parseFloat(stats.firstWR) >= 50 ? 'text-blue-400' : 'text-blue-400/60'}`}>
                  {stats.firstWR}%
                </span>
              </div>
              <div className="flex items-center gap-3 ml-11">
                <span className="text-[10px] text-slate-600">{stats.firstWins}W – {stats.firstTotal - stats.firstWins}L ({stats.firstTotal})</span>
                {stats.firstAvgScore !== '-' && <span className="text-[10px] text-slate-600">Avg: {stats.firstAvgScore}</span>}
              </div>
              <div className="flex items-center gap-3">
                <span className="text-[10px] font-black text-orange-400 w-8">2ND</span>
                <MiniBar value={parseFloat(stats.secondWR)} color={parseFloat(stats.secondWR) >= 50 ? 'bg-orange-500' : 'bg-orange-500/50'} />
                <span className={`text-sm font-black min-w-[48px] text-right ${parseFloat(stats.secondWR) >= 50 ? 'text-orange-400' : 'text-orange-400/60'}`}>
                  {stats.secondWR}%
                </span>
              </div>
              <div className="flex items-center gap-3 ml-11">
                <span className="text-[10px] text-slate-600">{stats.secondWins}W – {stats.secondTotal - stats.secondWins}L ({stats.secondTotal})</span>
                {stats.secondAvgScore !== '-' && <span className="text-[10px] text-slate-600">Avg: {stats.secondAvgScore}</span>}
              </div>
            </div>
          </div>

          <WinRateTimeline timeline={stats.timeline} />

          {/* Score Stats */}
          {stats.scoreStats && (
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <p className="text-[10px] font-black text-slate-500 uppercase mb-3">Score Analysis</p>
              <div className="grid grid-cols-3 gap-3 mb-3">
                <div className="text-center">
                  <p className="text-lg font-black text-emerald-400">{stats.scoreStats.avgMyScore}</p>
                  <p className="text-[10px] text-slate-500">Avg You</p>
                </div>
                <div className="text-center">
                  <p className="text-lg font-black text-rose-400">{stats.scoreStats.avgOppScore}</p>
                  <p className="text-[10px] text-slate-500">Avg Opp</p>
                </div>
                <div className="text-center">
                  <p className={`text-lg font-black ${parseFloat(stats.scoreStats.avgDiff) >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                    {parseFloat(stats.scoreStats.avgDiff) >= 0 ? '+' : ''}{stats.scoreStats.avgDiff}
                  </p>
                  <p className="text-[10px] text-slate-500">Avg Diff</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 mt-2">
                {stats.scoreStats.biggestWin && (
                  <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-2.5 text-center">
                    <p className="text-[9px] font-bold text-emerald-500 uppercase">Biggest Win</p>
                    <p className="text-sm font-black text-emerald-400">
                      {stats.scoreStats.biggestWin.myScore} : {stats.scoreStats.biggestWin.oppScore}
                    </p>
                    <p className="text-[9px] text-slate-500 truncate">vs {stats.scoreStats.biggestWin.opponent}</p>
                  </div>
                )}
                {stats.scoreStats.biggestLoss && (
                  <div className="bg-rose-500/10 border border-rose-500/20 rounded-xl p-2.5 text-center">
                    <p className="text-[9px] font-bold text-rose-500 uppercase">Biggest Loss</p>
                    <p className="text-sm font-black text-rose-400">
                      {stats.scoreStats.biggestLoss.myScore} : {stats.scoreStats.biggestLoss.oppScore}
                    </p>
                    <p className="text-[9px] text-slate-500 truncate">vs {stats.scoreStats.biggestLoss.opponent}</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Format Stats */}
          {stats.formatStats && stats.formatStats.length > 1 && (
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <p className="text-[10px] font-black text-slate-500 uppercase mb-3">By Format</p>
              <div className="space-y-2">
                {stats.formatStats.map((f, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <span className="text-[10px] font-black text-amber-400 w-8 uppercase">{f.format}</span>
                    <MiniBar value={parseFloat(f.winRate)} color={parseFloat(f.winRate) >= 50 ? 'bg-amber-500' : 'bg-amber-500/50'} />
                    <span className={`text-sm font-black min-w-[48px] text-right ${parseFloat(f.winRate) >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                      {f.winRate}%
                    </span>
                    <span className="text-[9px] text-slate-600">({f.total})</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Quick Stats Grid */}
          <div className="grid grid-cols-2 gap-3">
            <StatCard icon={Flame} label="Best Streak" value={`${stats.bestWinStreak}W`} color="text-emerald-400" sub={`Worst: ${stats.bestLossStreak}L`} />
            <StatCard icon={BarChart3} label="Last 10" value={`${stats.last10.winRate}%`}
              color={parseFloat(stats.last10.winRate) >= 50 ? 'text-emerald-400' : 'text-rose-400'}
              sub={`${stats.last10.wins}W – ${stats.last10.losses}L`} />
            <StatCard icon={Shield} label="1st Player" value={`${stats.firstWR}%`}
              color="text-blue-400" sub={`${stats.firstTotal} games`} />
            <StatCard icon={Zap} label="2nd Player" value={`${stats.secondWR}%`}
              color="text-orange-400" sub={`${stats.secondTotal} games`} />
          </div>
        </div>
      )}


      {/* ===== DECKS SECTION ===== */}
      {activeSection === 'decks' && stats.deckStats && (
        <div className="space-y-3">
          {stats.deckStats.map((deck, i) => {
            const isExpanded = expandedDeck === i;
            // Find the saved deck to get legend image and domains
            const savedDeck = savedDecks.find(sd => sd.name === deck.name);
            const legendCard = savedDeck?.legendData || (savedDeck?.legend ? allCards.find(c => c.id === savedDeck.legend) : null);
            const domains = legendCard?.classification?.domain || [];
            return (
              <div key={i} className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                <button onClick={() => setExpandedDeck(isExpanded ? null : i)}
                  className="w-full py-2 px-2 text-left active:bg-slate-800/50 transition-all">
                  <div className="flex items-center gap-1.5">
                    <div className="relative w-14 h-[84px] flex-shrink-0">
                      {legendCard ? (
                        <img src={legendCard.media.image_url} alt={legendCard.name} className="w-full h-full object-cover rounded-lg" />
                      ) : (
                        <div className="w-full h-full rounded-lg bg-slate-800 border-2 border-dashed border-slate-700 flex items-center justify-center">
                          <span className="text-slate-600 text-[9px] font-bold text-center leading-tight">No<br/>Legend</span>
                        </div>
                      )}
                    </div>
                    <div className="flex flex-col gap-1 flex-shrink-0">
                      {domains.length > 0 ? domains.slice(0, 2).map((d, idx) => {
                        const runeData = RUNE_COLORS[d];
                        return <img key={idx} src={runeData?.icon} alt={d} className="w-8 h-8" />;
                      }) : (
                        <>
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                        </>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1.5">
                        <h4 className="text-sm font-bold text-white truncate">{deck.name}</h4>
                        <span className={`text-lg font-black ${parseFloat(deck.winRate) >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                          {deck.winRate}%
                        </span>
                      </div>
                      <div className="flex items-center gap-2 mb-1.5">
                        <MiniBar value={parseFloat(deck.winRate)} color={parseFloat(deck.winRate) >= 50 ? 'bg-emerald-500' : 'bg-rose-500'} />
                        <span className="text-[10px] text-slate-500 font-bold flex-shrink-0">{deck.wins}W {deck.losses}L ({deck.total})</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <div className="flex gap-3">
                          {deck.firstWR !== '-' && (
                            <span className="text-[10px]">
                              <span className="text-blue-400 font-bold">1st:</span>
                              <span className="text-slate-400 ml-1">{deck.firstWR}%</span>
                              <span className="text-slate-600 ml-0.5">({deck.firstTotal})</span>
                            </span>
                          )}
                          {deck.secondWR !== '-' && (
                            <span className="text-[10px]">
                              <span className="text-orange-400 font-bold">2nd:</span>
                              <span className="text-slate-400 ml-1">{deck.secondWR}%</span>
                              <span className="text-slate-600 ml-0.5">({deck.secondTotal})</span>
                            </span>
                          )}
                        </div>
                        {deck.recentResults.length > 0 && <FormDots results={deck.recentResults} max={5} />}
                      </div>
                    </div>
                    <ChevronDown size={16} className={`text-slate-600 flex-shrink-0 transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
                  </div>
                </button>

                {isExpanded && (
                  <div className="px-4 pb-4 border-t border-slate-800/50 space-y-3">
                    {deck.avgMyScore !== '-' && (
                      <div className="pt-3">
                        <p className="text-[10px] font-black text-slate-500 uppercase mb-2">Avg Score</p>
                        <div className="flex gap-4">
                          <span className="text-xs"><span className="text-emerald-400 font-black">{deck.avgMyScore}</span><span className="text-slate-600"> You</span></span>
                          <span className="text-xs"><span className="text-rose-400 font-black">{deck.avgOppScore}</span><span className="text-slate-600"> Opp</span></span>
                          <span className="text-xs">
                            <span className={`font-black ${parseFloat(deck.avgDiff) >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                              {parseFloat(deck.avgDiff) >= 0 ? '+' : ''}{deck.avgDiff}
                            </span>
                            <span className="text-slate-600"> Diff</span>
                          </span>
                        </div>
                      </div>
                    )}

                    {deck.matchups.length > 0 && (
                      <div className={deck.avgMyScore === '-' ? 'pt-3' : ''}>
                        <p className="text-[10px] font-black text-slate-500 uppercase mb-2">Matchups</p>
                        <div className="space-y-2">
                          {deck.matchups.slice(0, 5).map((mu, j) => {
                            const muLegend = legendByShortName.get(mu.opponent);
                            const muDomains = muLegend?.classification?.domain || [];
                            const muWr = parseFloat(mu.winRate);
                            return (
                              <div key={j} className="bg-slate-800/50 rounded-xl p-2">
                                <div className="flex items-center gap-1.5">
                                  <div className="w-10 h-[60px] flex-shrink-0">
                                    {muLegend?.media?.image_url ? (
                                      <img src={muLegend.media.image_url} alt={mu.opponent} className="w-full h-full object-cover rounded-lg" />
                                    ) : (
                                      <div className="w-full h-full rounded-lg bg-slate-700 border border-dashed border-slate-600 flex items-center justify-center">
                                        <Target size={12} className="text-slate-500" />
                                      </div>
                                    )}
                                  </div>
                                  <div className="flex flex-col gap-0.5 flex-shrink-0">
                                    {muDomains.length > 0 ? muDomains.slice(0, 2).map((d, idx) => {
                                      const runeData = RUNE_COLORS[d];
                                      return <img key={idx} src={runeData?.icon} alt={d} className="w-6 h-6" />;
                                    }) : null}
                                  </div>
                                  <div className="flex-1 min-w-0">
                                    <div className="flex items-center justify-between">
                                      <span className="text-xs font-bold text-white truncate">{mu.opponent}</span>
                                      <span className={`text-sm font-black ${muWr >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>{mu.winRate}%</span>
                                    </div>
                                    <div className="flex items-center gap-2 mt-1">
                                      <MiniBar value={muWr} color={muWr >= 50 ? 'bg-emerald-500' : 'bg-rose-500'} height="h-1.5" />
                                      <span className="text-[10px] text-slate-500 font-bold flex-shrink-0">{mu.wins}W {mu.losses}L</span>
                                    </div>
                                    {mu.recentResults?.length > 0 && (
                                      <div className="mt-1"><FormDots results={mu.recentResults} max={5} /></div>
                                    )}
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}


      {/* ===== BATTLEFIELDS SECTION ===== */}
      {activeSection === 'battlefields' && (
        <div className="space-y-3">
          {/* Chosen vs Random */}
          {stats.bfStats && stats.bfStats.chosenWR && stats.bfStats.randomWR && (
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <p className="text-[10px] font-black text-slate-500 uppercase mb-3">Chosen vs Random</p>
              <div className="space-y-2">
                <div className="flex items-center gap-3">
                  <span className="text-[10px] font-black text-amber-400 w-16">Chosen</span>
                  <MiniBar value={parseFloat(stats.bfStats.chosenWR)} color="bg-amber-500" />
                  <span className={`text-sm font-black min-w-[48px] text-right ${parseFloat(stats.bfStats.chosenWR) >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                    {stats.bfStats.chosenWR}%
                  </span>
                  <span className="text-[9px] text-slate-600">({stats.bfStats.chosenTotal})</span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-[10px] font-black text-slate-400 w-16">Random</span>
                  <MiniBar value={parseFloat(stats.bfStats.randomWR)} color="bg-slate-500" />
                  <span className={`text-sm font-black min-w-[48px] text-right ${parseFloat(stats.bfStats.randomWR) >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                    {stats.bfStats.randomWR}%
                  </span>
                  <span className="text-[9px] text-slate-600">({stats.bfStats.randomTotal})</span>
                </div>
              </div>
            </div>
          )}

          {/* Per-Battlefield Winrates (Expandable) */}
          {(() => {
            const bfWinData = {};
            matches.forEach(m => {
              if (!m.games) return;
              const deck = savedDecks.find(sd => sd.id === m.deckId || sd.name === m.deckName);
              m.games.forEach(g => {
                if (!g.battlefieldId) return;
                if (!bfWinData[g.battlefieldId]) {
                  const bfCard = deck?.battlefields?.find(b => b.id === g.battlefieldId);
                  bfWinData[g.battlefieldId] = {
                    name: bfCard?.name || 'Unknown',
                    image: bfCard?.media?.image_url,
                    wins: 0, losses: 0, total: 0, opponents: {},
                  };
                }
                const bf = bfWinData[g.battlefieldId];
                bf.total++;
                if (g.result === 'win') bf.wins++; else bf.losses++;
                // Per-opponent breakdown
                const opp = m.opponent;
                if (!bf.opponents[opp]) bf.opponents[opp] = { wins: 0, losses: 0, total: 0, decks: {} };
                const oppData = bf.opponents[opp];
                oppData.total++;
                if (g.result === 'win') oppData.wins++; else oppData.losses++;
                // Per-deck within opponent
                const deckName = m.deckName || 'Unknown';
                if (!oppData.decks[deckName]) oppData.decks[deckName] = { wins: 0, losses: 0, total: 0, legendName: m.legendName };
                const dd = oppData.decks[deckName];
                dd.total++;
                if (g.result === 'win') dd.wins++; else dd.losses++;
              });
            });
            const bfEntries = Object.entries(bfWinData).filter(([, d]) => d.total > 0)
              .sort((a, b) => b[1].total - a[1].total);
            if (bfEntries.length === 0) return (
              <div className="p-8 text-center">
                <p className="text-slate-500 font-bold text-sm">No battlefield data yet</p>
                <p className="text-slate-600 text-xs mt-1">Assign battlefields in the Match History</p>
              </div>
            );
            return bfEntries.map(([bfId, data]) => {
              const wr = ((data.wins / data.total) * 100).toFixed(1);
              const wrNum = parseFloat(wr);
              const isExp = expandedBf === bfId;
              const oppEntries = Object.entries(data.opponents).sort((a, b) => b[1].total - a[1].total);
              return (
                <div key={bfId} className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                  <button onClick={() => { setExpandedBf(isExp ? null : bfId); setExpandedBfOpp(null); }}
                    className="w-full p-3 text-left active:bg-slate-800/50 transition-all">
                    <div className="flex items-center gap-3">
                      {data.image ? (
                        <img src={data.image} alt={data.name} className="w-20 aspect-[3/2] object-cover rounded-lg shrink-0" />
                      ) : (
                        <div className="w-20 aspect-[3/2] rounded-lg bg-slate-800 shrink-0" />
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-bold text-white truncate">{data.name}</p>
                        <div className="mt-1"><MiniBar value={wrNum} /></div>
                        <p className="text-[10px] text-slate-500 mt-0.5">{data.wins}W – {data.losses}L ({data.total} games)</p>
                      </div>
                      <span className={`text-lg font-black shrink-0 ${wrNum >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                        {wr}%
                      </span>
                      <ChevronDown size={16} className={`text-slate-600 shrink-0 transition-transform ${isExp ? 'rotate-180' : ''}`} />
                    </div>
                  </button>

                  {/* Expanded: Opponent Breakdown */}
                  {isExp && (
                    <div className="px-3 pb-3 border-t border-slate-800/50 space-y-2 pt-2">
                      <p className="text-[10px] font-black text-slate-500 uppercase mb-1">Opponents on {data.name}</p>
                      {oppEntries.map(([opp, oppData]) => {
                        const oppWr = ((oppData.wins / oppData.total) * 100).toFixed(1);
                        const oppWrNum = parseFloat(oppWr);
                        const oppLegend = legendByShortName.get(opp);
                        const isOppExp = expandedBfOpp === `${bfId}-${opp}`;
                        const deckEntries = Object.entries(oppData.decks).sort((a, b) => b[1].total - a[1].total);
                        return (
                          <div key={opp} className="bg-slate-800/50 rounded-xl overflow-hidden">
                            <button onClick={() => setExpandedBfOpp(isOppExp ? null : `${bfId}-${opp}`)}
                              className="w-full p-2 text-left active:bg-slate-700/50 transition-all">
                              <div className="flex items-center gap-2">
                                <div className="w-10 h-[60px] shrink-0">
                                  {oppLegend?.media?.image_url ? (
                                    <img src={oppLegend.media.image_url} alt={opp} className="w-full h-full object-cover rounded-lg" />
                                  ) : (
                                    <div className="w-full h-full rounded-lg bg-slate-700 border border-dashed border-slate-600 flex items-center justify-center">
                                      <Target size={12} className="text-slate-500" />
                                    </div>
                                  )}
                                </div>
                                <div className="flex-1 min-w-0">
                                  <p className="text-xs font-bold text-white">{opp}</p>
                                  <MiniBar value={oppWrNum} />
                                  <p className="text-[9px] text-slate-500">{oppData.wins}W – {oppData.losses}L</p>
                                </div>
                                <span className={`text-sm font-black shrink-0 ${oppWrNum >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                                  {oppWr}%
                                </span>
                                <ChevronDown size={12} className={`text-slate-600 shrink-0 transition-transform ${isOppExp ? 'rotate-180' : ''}`} />
                              </div>
                            </button>

                            {/* Expanded: Deck Breakdown per Opponent */}
                            {isOppExp && (
                              <div className="px-2 pb-2 space-y-1">
                                {deckEntries.map(([dName, dd]) => {
                                  const ddWr = ((dd.wins / dd.total) * 100).toFixed(1);
                                  const ddWrNum = parseFloat(ddWr);
                                  const deckSaved = savedDecks.find(sd => sd.name === dName);
                                  const deckLegend = deckSaved?.legendData || (deckSaved?.legend ? allCards.find(c => c.id === deckSaved.legend) : null)
                                    || (dd.legendName ? allCards.find(c => c.name === dd.legendName && c.classification?.type === 'Legend') : null);
                                  return (
                                    <div key={dName} className="flex items-center gap-2 bg-slate-700/30 rounded-lg p-1.5">
                                      <div className="w-8 h-[48px] shrink-0">
                                        {deckLegend?.media?.image_url ? (
                                          <img src={deckLegend.media.image_url} alt={dName} className="w-full h-full object-cover rounded-md" />
                                        ) : (
                                          <div className="w-full h-full rounded-md bg-slate-700 border border-dashed border-slate-600" />
                                        )}
                                      </div>
                                      <div className="flex-1 min-w-0">
                                        <p className="text-[10px] font-bold text-white truncate">{dName}</p>
                                        <MiniBar value={ddWrNum} />
                                      </div>
                                      <span className={`text-xs font-black shrink-0 ${ddWrNum >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                                        {ddWr}%
                                      </span>
                                      <span className="text-[9px] text-slate-600 shrink-0">{dd.wins}W-{dd.losses}L</span>
                                    </div>
                                  );
                                })}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            });
          })()}
        </div>
      )}


      {/* ===== MATCHUPS SECTION ===== */}
      {activeSection === 'matchups' && stats.matchupStats && (
        <div className="space-y-3">
          {stats.matchupStats.map((mu, i) => {
            const legendCard = legendByShortName.get(mu.opponent);
            const domains = legendCard?.classification?.domain || [];
            const wr = parseFloat(mu.winRate);
            const isExpMu = expandedMatchup === i;
            return (
              <div key={i} className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                <button onClick={() => setExpandedMatchup(isExpMu ? null : i)}
                  className="w-full py-2 px-2 text-left active:bg-slate-800/50 transition-all">
                  <div className="flex items-center gap-1.5">
                    {/* Legend Card Image */}
                    <div className="relative w-14 h-[84px] flex-shrink-0">
                      {legendCard?.media?.image_url ? (
                        <img src={legendCard.media.image_url} alt={mu.opponent}
                          className="w-full h-full object-cover rounded-lg" />
                      ) : (
                        <div className="w-full h-full rounded-lg bg-slate-800 border-2 border-dashed border-slate-700 flex items-center justify-center">
                          <Target size={16} className="text-slate-600" />
                        </div>
                      )}
                    </div>
                    {/* Rune Icons */}
                    <div className="flex flex-col gap-1 flex-shrink-0 justify-center">
                      {domains.length > 0 ? domains.slice(0, 2).map((d, idx) => {
                        const runeData = RUNE_COLORS[d];
                        return <img key={idx} src={runeData?.icon} alt={d} className="w-8 h-8" />;
                      }) : (
                        <>
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                        </>
                      )}
                    </div>
                    {/* Stats */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1.5">
                        <h4 className="text-sm font-bold text-white truncate">{mu.opponent}</h4>
                        <span className={`text-lg font-black ${wr >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>
                          {mu.winRate}%
                        </span>
                      </div>
                      <div className="flex items-center gap-2 mb-1.5">
                        <MiniBar value={wr} color={wr >= 50 ? 'bg-emerald-500' : 'bg-rose-500'} />
                        <span className="text-[10px] text-slate-500 font-bold flex-shrink-0">{mu.wins}W {mu.losses}L ({mu.total})</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <div className="flex gap-3">
                          {mu.firstWR !== '-' && (
                            <span className="text-[10px]">
                              <span className="text-blue-400 font-bold">1st:</span>
                              <span className="text-slate-400 ml-1">{mu.firstWR}%</span>
                              <span className="text-slate-600 ml-0.5">({mu.firstTotal})</span>
                            </span>
                          )}
                          {mu.secondWR !== '-' && (
                            <span className="text-[10px]">
                              <span className="text-orange-400 font-bold">2nd:</span>
                              <span className="text-slate-400 ml-1">{mu.secondWR}%</span>
                              <span className="text-slate-600 ml-0.5">({mu.secondTotal})</span>
                            </span>
                          )}
                        </div>
                        {mu.recentResults.length > 0 && <FormDots results={mu.recentResults} max={5} />}
                      </div>
                    </div>
                    <ChevronDown size={16} className={`text-slate-600 flex-shrink-0 transition-transform ${isExpMu ? 'rotate-180' : ''}`} />
                  </div>
                </button>

                {/* Expanded: Deck Breakdown */}
                {isExpMu && mu.deckBreakdown && mu.deckBreakdown.length > 0 && (
                  <div className="px-4 pb-4 border-t border-slate-800/50 space-y-3">
                    <p className="text-[10px] font-black text-slate-500 uppercase pt-3 mb-2">Decks vs {mu.opponent}</p>
                    {mu.deckBreakdown.map((dd, j) => {
                      const deckSaved = savedDecks.find(sd => sd.name === dd.name);
                      const deckLegend = deckSaved?.legendData || (deckSaved?.legend ? allCards.find(c => c.id === deckSaved.legend) : null)
                        || (dd.legendName ? allCards.find(c => c.name === dd.legendName && c.classification?.type === 'Legend') : null);
                      const deckDomains = deckLegend?.classification?.domain || [];
                      const ddWr = parseFloat(dd.winRate);
                      return (
                        <div key={j} className="bg-slate-800/50 rounded-xl p-2">
                          <div className="flex items-center gap-1.5 mb-2">
                            <div className="w-10 h-[60px] flex-shrink-0">
                              {deckLegend?.media?.image_url ? (
                                <img src={deckLegend.media.image_url} alt={dd.name} className="w-full h-full object-cover rounded-lg" />
                              ) : (
                                <div className="w-full h-full rounded-lg bg-slate-700 border border-dashed border-slate-600 flex items-center justify-center">
                                  <span className="text-slate-500 text-[8px] font-bold">?</span>
                                </div>
                              )}
                            </div>
                            <div className="flex flex-col gap-0.5 flex-shrink-0">
                              {deckDomains.length > 0 ? deckDomains.slice(0, 2).map((d, idx) => {
                                const runeData = RUNE_COLORS[d];
                                return <img key={idx} src={runeData?.icon} alt={d} className="w-6 h-6" />;
                              }) : null}
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center justify-between">
                                <span className="text-xs font-bold text-white truncate">{dd.name}</span>
                                <span className={`text-sm font-black ${ddWr >= 50 ? 'text-emerald-400' : 'text-rose-400'}`}>{dd.winRate}%</span>
                              </div>
                              <div className="flex items-center gap-2 mt-1">
                                <MiniBar value={ddWr} color={ddWr >= 50 ? 'bg-emerald-500' : 'bg-rose-500'} height="h-1.5" />
                                <span className="text-[10px] text-slate-500 font-bold flex-shrink-0">{dd.wins}W {dd.losses}L</span>
                              </div>
                              {dd.recentResults.length > 0 && (
                                <div className="mt-1"><FormDots results={dd.recentResults} max={5} /></div>
                              )}
                            </div>
                          </div>
                          <div className="flex gap-4 pl-1">
                            <div className="flex gap-3">
                              {dd.firstWR !== '-' && (
                                <span className="text-[10px]">
                                  <span className="text-blue-400 font-bold">1st:</span>
                                  <span className="text-slate-400 ml-1">{dd.firstWR}%</span>
                                  <span className="text-slate-600 ml-0.5">({dd.firstTotal})</span>
                                </span>
                              )}
                              {dd.secondWR !== '-' && (
                                <span className="text-[10px]">
                                  <span className="text-orange-400 font-bold">2nd:</span>
                                  <span className="text-slate-400 ml-1">{dd.secondWR}%</span>
                                  <span className="text-slate-600 ml-0.5">({dd.secondTotal})</span>
                                </span>
                              )}
                            </div>
                            {dd.avgMyScore !== '-' && (
                              <div className="flex gap-2">
                                <span className="text-[10px]"><span className="text-emerald-400 font-bold">{dd.avgMyScore}</span><span className="text-slate-600"> You</span></span>
                                <span className="text-[10px]"><span className="text-rose-400 font-bold">{dd.avgOppScore}</span><span className="text-slate-600"> Opp</span></span>
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}


      {/* ===== HISTORY SECTION ===== */}
      {activeSection === 'history' && (
        <div className="space-y-3">
          <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
            <button onClick={() => setHistoryFilter('all')}
              className={`px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all active:scale-95 ${historyFilter === 'all' ? 'bg-slate-700 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'}`}>
              All ({sortedMatches.length})
            </button>
            <button onClick={() => setHistoryFilter('wins')}
              className={`px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all active:scale-95 ${historyFilter === 'wins' ? 'bg-emerald-600/20 text-emerald-400 border border-emerald-600/30' : 'bg-slate-900 text-slate-400 border border-slate-800'}`}>
              Wins
            </button>
            <button onClick={() => setHistoryFilter('losses')}
              className={`px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all active:scale-95 ${historyFilter === 'losses' ? 'bg-rose-600/20 text-rose-400 border border-rose-600/30' : 'bg-slate-900 text-slate-400 border border-slate-800'}`}>
              Losses
            </button>
            {deckNames.length > 1 && (
              <select value={historyDeckFilter} onChange={e => setHistoryDeckFilter(e.target.value)}
                className="px-4 py-2 rounded-full text-xs font-bold bg-slate-900 text-slate-400 border border-slate-800 outline-none">
                <option value="all">All Decks</option>
                {deckNames.map(([key, name]) => <option key={key} value={key}>{name}</option>)}
              </select>
            )}
          </div>

          <p className="text-[10px] text-slate-500 font-bold px-1">{filteredMatches.length} matches</p>

          {filteredMatches.map(match => {
            const isExpanded = expandedMatch === match.id;
            const isEditing = editingNotes === match.id;
            const isWin = match.result === 'win';
            const hasNotes = match.notes && match.notes.trim().length > 0;
            const hasScore = match.myScore !== undefined && match.oppScore !== undefined;

            return (
              <div key={match.id} className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                <button onClick={() => setExpandedMatch(isExpanded ? null : match.id)}
                  className="w-full py-2 px-2 flex items-center gap-1.5 active:bg-slate-800/50 transition-all">
                  {/* Own Deck Legend Card */}
                  {(() => {
                    const ownSavedDeck = savedDecks.find(sd => sd.id === match.deckId || sd.name === match.deckName);
                    const ownLegend = ownSavedDeck?.legendData || (ownSavedDeck?.legend ? allCards.find(c => c.id === ownSavedDeck.legend) : null)
                      || (match.legendName ? allCards.find(c => c.name === match.legendName && c.classification?.type === 'Legend') : null);
                    const ownDomains = ownLegend?.classification?.domain || [];
                    return (
                      <>
                        <div className="relative w-14 h-[84px] flex-shrink-0">
                          {ownLegend?.media?.image_url ? (
                            <img src={ownLegend.media.image_url} alt={match.legendName || match.deckName}
                              className="w-full h-full object-cover rounded-lg" />
                          ) : (
                            <div className="w-full h-full rounded-lg bg-slate-800 border-2 border-dashed border-slate-700 flex items-center justify-center">
                              <span className="text-slate-600 text-[9px] font-bold text-center leading-tight">No<br/>Legend</span>
                            </div>
                          )}
                          <div className={`absolute -top-1 -right-1 w-3.5 h-3.5 rounded-full border-2 border-slate-900 ${isWin ? 'bg-emerald-500' : 'bg-rose-500'}`} />
                          <span className={`absolute bottom-0 left-0 text-[8px] font-black px-1 py-0.5 rounded-tr-md rounded-bl-lg ${
                            match.isFirst ? 'bg-blue-600 text-white' : 'bg-orange-600 text-white'
                          }`}>{match.isFirst ? '1ST' : '2ND'}</span>
                        </div>
                        <div className="flex flex-col gap-0.5 flex-shrink-0 justify-center">
                          {ownDomains.length > 0 ? ownDomains.slice(0, 2).map((d, idx) => {
                            const runeData = RUNE_COLORS[d];
                            return <img key={idx} src={runeData?.icon} alt={d} className="w-5 h-5" />;
                          }) : (
                            <>
                              <div className="w-5 h-5 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                              <div className="w-5 h-5 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                            </>
                          )}
                        </div>
                      </>
                    );
                  })()}
                  <div className="flex-1 min-w-0 text-left">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-white truncate">{match.deckName || 'Unknown'}</span>
                      {match.format && match.format !== 'bo1' && (
                        <span className="text-[10px] font-black px-1.5 py-0.5 rounded bg-amber-600/20 text-amber-400">
                          {match.format.toUpperCase()}
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-1.5 mt-0.5">
                      <span className="text-[10px] text-slate-600">{formatDate(match.timestamp)}</span>
                      {hasNotes && <MessageSquare size={10} className="text-amber-500 ml-1" />}
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    {hasScore && (
                      <p className="text-sm font-black">
                        <span className={isWin ? 'text-emerald-400' : 'text-white'}>{match.myScore}</span>
                        <span className="text-slate-600 mx-1">:</span>
                        <span className={!isWin ? 'text-rose-400' : 'text-white'}>{match.oppScore}</span>
                      </p>
                    )}
                    <p className={`text-xs font-black ${isWin ? 'text-emerald-400' : 'text-rose-400'}`}>{isWin ? 'WIN' : 'LOSS'}</p>
                  </div>
                  {/* Opponent Legend Card (right side) */}
                  {(() => {
                    const oppLegend = legendByShortName.get(match.opponent);
                    const oppDomains = oppLegend?.classification?.domain || [];
                    return (
                      <>
                        <div className="flex flex-col gap-0.5 flex-shrink-0 justify-center">
                          {oppDomains.length > 0 ? oppDomains.slice(0, 2).map((d, idx) => {
                            const runeData = RUNE_COLORS[d];
                            return <img key={idx} src={runeData?.icon} alt={d} className="w-5 h-5" />;
                          }) : (
                            <>
                              <div className="w-5 h-5 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                              <div className="w-5 h-5 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                            </>
                          )}
                        </div>
                        <div className="w-14 h-[84px] flex-shrink-0">
                          {oppLegend?.media?.image_url ? (
                            <img src={oppLegend.media.image_url} alt={match.opponent}
                              className="w-full h-full object-cover rounded-lg" />
                          ) : (
                            <div className="w-full h-full rounded-lg bg-slate-800 border-2 border-dashed border-slate-700 flex items-center justify-center">
                              <Target size={16} className="text-slate-600" />
                            </div>
                          )}
                        </div>
                      </>
                    );
                  })()}
                  <ChevronDown size={14} className={`text-slate-600 flex-shrink-0 transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
                </button>

                {isExpanded && (
                  <div className="px-4 pb-4 border-t border-slate-800/50 pt-3">

                    {/* Individual games for Bo2/Bo3 */}
                    {match.games && match.games.length > 1 && (
                      <div className="mb-3">
                        <p className="text-[10px] font-black text-slate-500 uppercase mb-1.5">Games</p>
                        <div className="flex gap-2">
                          {match.games.map((g, gi) => (
                            <div key={gi} className="flex-1 flex items-center gap-1.5 bg-slate-800/50 rounded-lg px-2.5 py-1.5">
                              <div className={`w-1.5 h-6 rounded-full ${g.result === 'win' ? 'bg-emerald-500' : 'bg-rose-500'}`} />
                              <span className="text-[10px] font-bold text-slate-400">G{gi + 1}</span>
                              <span className={`text-[10px] font-black px-1 rounded ${
                                g.isFirst ? 'text-blue-400' : 'text-orange-400'
                              }`}>{g.isFirst ? '1ST' : '2ND'}</span>
                              <span className="text-xs font-black text-white">{g.myScore} : {g.oppScore}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Battlefield Selection per Game */}
                    {(() => {
                      const deckBFs = savedDecks.find(sd => sd.id === match.deckId || sd.name === match.deckName)?.battlefields || [];
                      const gameCount = match.games?.length || 1;
                      if (deckBFs.length === 0) return null;
                      const handleBFSelect = (gameIndex, bfId) => {
                        const updatedGames = (match.games || [{ ...match, battlefieldId: null }]).map((g, i) => {
                          if (i !== gameIndex) return g;
                          return { ...g, battlefieldId: g.battlefieldId === bfId ? null : bfId };
                        });
                        updateMatchGames(match.id, updatedGames);
                      };
                      // Collect which games each BF is assigned to (with results)
                      const bfGameMap = {};
                      for (let gi = 0; gi < gameCount; gi++) {
                        const game = match.games?.[gi];
                        const bfId = game?.battlefieldId;
                        if (bfId) {
                          if (!bfGameMap[bfId]) bfGameMap[bfId] = [];
                          bfGameMap[bfId].push({ num: gi + 1, result: game?.result });
                        }
                      }
                      // Find which game still needs a BF assignment
                      const nextUnassigned = Array.from({ length: gameCount }, (_, i) => i)
                        .find(i => !match.games?.[i]?.battlefieldId);
                      // Sort BFs: assigned first (by game number), unassigned last
                      const sortedBFs = [...deckBFs].sort((a, b) => {
                        const aGames = bfGameMap[a.id];
                        const bGames = bfGameMap[b.id];
                        if (aGames && !bGames) return -1;
                        if (!aGames && bGames) return 1;
                        if (aGames && bGames) return aGames[0].num - bGames[0].num;
                        return 0;
                      });
                      return (
                        <div className="mb-3">
                          <p className="text-[10px] font-black text-slate-500 uppercase mb-1.5">Battlefields</p>
                          <div className="flex gap-2">
                            {sortedBFs.map(bf => {
                              const assignedGames = bfGameMap[bf.id] || [];
                              const isAssigned = assignedGames.length > 0;
                              return (
                                <button key={bf.id}
                                  onClick={() => {
                                    if (isAssigned) {
                                      // Unassign from all games
                                      assignedGames.forEach(g => handleBFSelect(g.num - 1, bf.id));
                                    } else if (nextUnassigned !== undefined) {
                                      handleBFSelect(nextUnassigned, bf.id);
                                    }
                                  }}
                                  className="relative flex-1 rounded-xl overflow-hidden transition-all">
                                  <div className={`relative aspect-[3/2] ${isAssigned ? 'ring-2 ring-amber-400/80 rounded-xl opacity-100' : 'opacity-40 hover:opacity-70'}`}>
                                    <img src={bf.media?.image_url} alt={bf.name} className="w-full h-full object-cover" />
                                    {isAssigned && (
                                      <div className="absolute bottom-0 left-0 right-0 bg-black/70 px-2 py-1 flex items-center justify-center gap-2">
                                        {assignedGames.map(g => (
                                          <div key={g.num} className="flex items-center gap-1">
                                            <span className="text-xs font-black text-white">G{g.num}</span>
                                            <span className={`text-[10px] font-black ${g.result === 'win' ? 'text-emerald-400' : 'text-rose-400'}`}>
                                              {g.result === 'win' ? 'WIN' : 'LOSS'}
                                            </span>
                                          </div>
                                        ))}
                                      </div>
                                    )}
                                  </div>
                                </button>
                              );
                            })}
                          </div>
                        </div>
                      );
                    })()}

                    <div className="mt-1">
                      <p className="text-[10px] font-black text-slate-500 uppercase mb-1.5">Notes</p>
                      {isEditing ? (
                        <div className="space-y-2">
                          <textarea value={notesText} onChange={e => setNotesText(e.target.value)}
                            placeholder="How did the match go? Key plays, mistakes, takeaways..."
                            rows={3} autoFocus
                            className="w-full bg-slate-800 border border-slate-700 rounded-xl p-3 text-sm text-slate-200 placeholder-slate-600 focus:ring-2 ring-amber-500/40 outline-none resize-none" />
                          <div className="flex gap-2 justify-end">
                            <button onClick={() => setEditingNotes(null)}
                              className="px-3 py-1.5 rounded-lg text-xs font-bold text-slate-400 bg-slate-800 border border-slate-700 active:scale-95 transition-all">
                              <X size={12} className="inline mr-1" />Cancel
                            </button>
                            <button onClick={() => saveNotes(match.id)}
                              className="px-3 py-1.5 rounded-lg text-xs font-bold text-white bg-amber-600 active:bg-amber-500 active:scale-95 transition-all">
                              <Check size={12} className="inline mr-1" />Save
                            </button>
                          </div>
                        </div>
                      ) : (
                        <button onClick={() => startEditNotes(match)}
                          className="w-full text-left p-3 bg-slate-800/50 rounded-xl border border-dashed border-slate-700 active:bg-slate-800 transition-all min-h-[48px]">
                          {hasNotes ? (
                            <p className="text-xs text-slate-300 whitespace-pre-wrap">{match.notes}</p>
                          ) : (
                            <p className="text-xs text-slate-600 italic">Tap to add notes...</p>
                          )}
                        </button>
                      )}
                    </div>
                    <button onClick={() => deleteMatch(match.id)}
                      className="mt-3 flex items-center gap-1.5 text-[10px] font-bold text-rose-500/70 active:text-rose-400 transition-all">
                      <Trash size={11} /> Delete match
                    </button>
                  </div>
                )}
              </div>
            );
          })}

          {filteredMatches.length === 0 && (
            <div className="p-8 text-center">
              <p className="text-slate-600 text-sm font-bold">No matches found</p>
            </div>
          )}
        </div>
      )}


    </div>
  );
}

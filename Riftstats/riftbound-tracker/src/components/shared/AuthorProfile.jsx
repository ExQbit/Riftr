import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { ArrowLeft, Heart, Layers, TrendingUp, Target, Copy } from 'lucide-react';
import { RUNE_COLORS } from '../../constants/gameData';
import { t } from '../../constants/i18n';
import { db, appId } from '../../constants/firebase';
import { collection, getDocs } from 'firebase/firestore';
import { computeStats } from '../../utils/computeStats';
import { getShortLegendName } from '../../utils/metaDeckFilters';

export default function AuthorProfile({
  selectedAuthor,
  authorProfile, // { displayName, bio, avatarUrl } from useProfile cache
  user,
  onBack,
  // Data
  allCards,
  publicDecks,
  savedDecks,
  stats,
  getQuantity,
  // Follow
  follow,
  unfollow,
  isFollowing,
  getFollowerCount,
  // Actions
  onLoadDeck,
  onDuplicateDeck,
}) {
  if (!selectedAuthor) return null;

  const isOwnProfile = user && user.uid === selectedAuthor.authorId;
  const displayName = authorProfile?.displayName || selectedAuthor.authorName;
  const initial = (displayName || '?')[0].toUpperCase();
  const followerCount = getFollowerCount?.(selectedAuthor.authorId) || 0;
  const amFollowing = isFollowing?.(selectedAuthor.authorId);

  // --- Computed data ---
  const authorDecks = useMemo(() => {
    if (!selectedAuthor) return [];
    return publicDecks.filter(d => d.authorId === selectedAuthor.authorId);
  }, [publicDecks, selectedAuthor]);

  const authorLegendCount = useMemo(() => {
    const legends = new Set();
    for (const deck of authorDecks) {
      const name = deck.legendData?.name || deck.legendName;
      if (name) legends.add(name);
    }
    return legends.size;
  }, [authorDecks]);

  const fullCollectionStats = useMemo(() => {
    if (!getQuantity || !allCards.length) return null;
    const uniqueCards = allCards.length;
    const owned = allCards.filter(c => getQuantity(c.id) > 0).length;
    const pct = uniqueCards > 0 ? ((owned / uniqueCards) * 100).toFixed(1) : '0.0';
    const totalCopies = allCards.reduce((sum, c) => sum + getQuantity(c.id), 0);
    const setMap = {};
    allCards.forEach(c => {
      const setId = c.set?.set_id || 'Unknown';
      if (!setMap[setId]) setMap[setId] = { total: 0, owned: 0 };
      setMap[setId].total++;
      if (getQuantity(c.id) > 0) setMap[setId].owned++;
    });
    const sets = Object.entries(setMap)
      .map(([id, d]) => ({ id, total: d.total, owned: d.owned, pct: d.total > 0 ? ((d.owned / d.total) * 100).toFixed(1) : '0.0' }))
      .sort((a, b) => b.id.localeCompare(a.id));
    return { uniqueCards, owned, pct, totalCopies, sets };
  }, [allCards, getQuantity]);

  const legendByShortName = useMemo(() => {
    const map = new Map();
    allCards.filter(c => c.classification?.type === 'Legend').forEach(c => {
      const short = c.name?.includes(',') ? c.name.split(',')[0].trim() : c.name;
      if (!short) return;
      const existing = map.get(short);
      const isAlt = c.metadata?.alternate_art || c.metadata?.overnumbered || c.metadata?.signature;
      if (!existing || (existing._isAlt && !isAlt)) map.set(short, { ...c, _isAlt: isAlt });
    });
    return map;
  }, [allCards]);

  const mostPlayedDeck = useMemo(() => {
    if (!isOwnProfile || !stats?.deckStats?.length) return null;
    return stats.deckStats[0];
  }, [isOwnProfile, stats]);

  const computeCollectionRate = useCallback((deck) => {
    if (!getQuantity) return null;
    const deckCards = { ...(deck.mainDeck || {}), ...(deck.sideboard || {}) };
    const totalCards = Object.values(deckCards).reduce((s, q) => s + q, 0);
    if (totalCards === 0) return null;
    const ownedCards = Object.entries(deckCards).reduce((s, [id, qty]) => s + Math.min(getQuantity(id), qty), 0);
    return Math.round(ownedCards / totalCards * 100);
  }, [getQuantity]);

  // Author legend filter options
  const authorLegendOptions = useMemo(() => {
    const legendCounts = {};
    for (const deck of authorDecks) {
      const legendCard = deck.legendData;
      if (!legendCard) continue;
      const shortName = getShortLegendName(legendCard.name);
      if (!shortName) continue;
      if (!legendCounts[shortName]) {
        legendCounts[shortName] = { shortName, media: legendCard.media || null, count: 0 };
      }
      legendCounts[shortName].count++;
    }
    return Object.values(legendCounts).sort((a, b) => b.count - a.count);
  }, [authorDecks]);

  // --- Local state ---
  const [authorProfileTab, setAuthorProfileTab] = useState('decks');
  const [authorLegendFilters, setAuthorLegendFilters] = useState(new Set());
  const [authorStats, setAuthorStats] = useState(null);
  const [authorStatsLoading, setAuthorStatsLoading] = useState(false);

  // Reset state when author changes
  useEffect(() => {
    setAuthorLegendFilters(new Set());
    setAuthorProfileTab('decks');
  }, [selectedAuthor?.authorId]);

  // Fetch other player's match stats
  useEffect(() => {
    if (!selectedAuthor) { setAuthorStats(null); return; }
    if (isOwnProfile) { setAuthorStats(null); return; }
    setAuthorStats(null);
    setAuthorStatsLoading(true);
    const ref = collection(db, 'artifacts', appId, 'users', selectedAuthor.authorId, 'matches');
    getDocs(ref).then(snap => {
      const matches = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      setAuthorStats(computeStats(matches));
    }).catch(() => {
      setAuthorStats(null);
    }).finally(() => {
      setAuthorStatsLoading(false);
    });
  }, [selectedAuthor?.authorId, isOwnProfile]);

  // Filtered author decks
  const filteredAuthorDecks = useMemo(() => {
    if (authorLegendFilters.size === 0) return authorDecks;
    return authorDecks.filter(d => {
      const legendCard = d.legendData;
      if (!legendCard) return false;
      const shortName = getShortLegendName(legendCard.name);
      return authorLegendFilters.has(shortName);
    });
  }, [authorDecks, authorLegendFilters]);

  const decksToShow = filteredAuthorDecks;

  // --- Render ---
  return (
    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-24 px-2 pt-4">
      {/* Back button */}
      <button onClick={onBack} className="flex items-center gap-2 text-slate-400 hover:text-white transition-all active:scale-95">
        <ArrowLeft size={18} />
        <span className="text-sm font-bold">Back</span>
      </button>

      {/* Author Card */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6">
        <div className="flex items-center gap-4">
          {authorProfile?.avatarUrl ? (
            <img src={authorProfile.avatarUrl} alt={displayName} className="w-16 h-16 rounded-full object-cover flex-shrink-0" />
          ) : (
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-amber-600 to-amber-400 flex items-center justify-center flex-shrink-0">
              <span className="text-2xl font-black text-white">{initial}</span>
            </div>
          )}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-black text-white truncate">{displayName}</h2>
              {isOwnProfile && <span className="text-[10px] font-bold text-amber-400 uppercase bg-amber-500/10 px-2 py-0.5 rounded-full">You</span>}
            </div>
            {authorProfile?.bio && (
              <p className="text-xs text-slate-400 mt-1 line-clamp-2">{authorProfile.bio}</p>
            )}
            {!isOwnProfile && (
              <button
                onClick={() => amFollowing ? unfollow(selectedAuthor.authorId) : follow(selectedAuthor.authorId)}
                className={`mt-2 flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-bold transition-all active:scale-95 ${
                  amFollowing
                    ? 'bg-slate-800 text-slate-400 border border-slate-700'
                    : 'bg-amber-600 text-white'
                }`}
              >
                <Heart size={12} fill={amFollowing ? 'currentColor' : 'none'} />
                {amFollowing ? (t.unfollow || 'Unfollow') : t.follow}
              </button>
            )}
          </div>
        </div>

        {/* Stats row */}
        <div className="flex items-center justify-center gap-4 mt-5 bg-slate-800/50 rounded-2xl py-3 px-2">
          <div className="text-center flex-1">
            <p className="text-lg font-black text-white">{authorDecks.length}</p>
            <p className="text-[10px] text-slate-500 font-bold uppercase">Decks</p>
          </div>
          <div className="w-px h-8 bg-slate-700" />
          <div className="text-center flex-1">
            <p className="text-lg font-black text-white">{authorLegendCount}</p>
            <p className="text-[10px] text-slate-500 font-bold uppercase">Legends</p>
          </div>
          <div className="w-px h-8 bg-slate-700" />
          <div className="text-center flex-1">
            <p className="text-lg font-black text-white">{followerCount}</p>
            <p className="text-[10px] text-slate-500 font-bold uppercase">{t.followers}</p>
          </div>
        </div>
      </div>

      {/* Profile tab pills */}
      <div className="flex gap-2 px-1">
        {['decks', 'collection', 'showcase'].map(tab => (
          <button
            key={tab}
            onClick={() => setAuthorProfileTab(tab)}
            className={`px-4 py-2 rounded-full text-xs font-bold transition-all active:scale-95 ${
              authorProfileTab === tab ? 'bg-amber-600 text-white' : 'bg-slate-900 border border-slate-800 text-slate-400'
            }`}
          >
            {tab === 'decks' ? 'Decks' : tab === 'collection' ? t.collectionRate : 'Showcase'}
          </button>
        ))}
      </div>

      {/* ===== COLLECTION TAB ===== */}
      {authorProfileTab === 'collection' && fullCollectionStats && (() => {
        const cs = fullCollectionStats;
        const ringSize = 140;
        const ringRadius = 60;
        const ringCirc = 2 * Math.PI * ringRadius;
        const ringOffset = ringCirc - (parseFloat(cs.pct) / 100) * ringCirc;
        return (
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6">
            <div className="flex items-center gap-5">
              <div className="relative flex-shrink-0" style={{ width: ringSize, height: ringSize }}>
                <svg width={ringSize} height={ringSize} className="transform -rotate-90">
                  <circle cx={70} cy={70} r={ringRadius} stroke="rgba(255,255,255,0.05)" strokeWidth={10} fill="none" />
                  <circle cx={70} cy={70} r={ringRadius} stroke="#7c3aed" strokeWidth={10} fill="none"
                    strokeLinecap="round"
                    strokeDasharray={ringCirc}
                    strokeDashoffset={ringOffset}
                    style={{ transition: 'stroke-dashoffset 1s ease-out' }} />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="text-2xl font-black text-white">{cs.pct}%</span>
                  <span className="text-[9px] font-bold text-slate-500 uppercase">Complete</span>
                </div>
              </div>
              <div className="flex-1 space-y-2">
                <div>
                  <p className="text-[10px] font-black text-slate-500 uppercase mb-0.5">Unique Cards</p>
                  <p className="text-lg font-black text-white">
                    {cs.owned} <span className="text-slate-600 text-sm">/ {cs.uniqueCards}</span>
                  </p>
                </div>
                <div>
                  <p className="text-[10px] font-black text-slate-500 uppercase mb-0.5">Total Copies</p>
                  <p className="text-lg font-black text-amber-400">{cs.totalCopies}</p>
                </div>
              </div>
            </div>
            {cs.sets.length > 0 && (
              <div className="mt-4 space-y-2">
                {cs.sets.map(s => (
                  <div key={s.id} className="flex items-center gap-2">
                    <span className="text-[10px] font-bold text-slate-400 w-16 truncate">{s.id}</span>
                    <div className="flex-1 bg-slate-800 rounded-full h-2 overflow-hidden">
                      <div className="h-2 rounded-full bg-amber-500 transition-all duration-500"
                        style={{ width: `${s.pct}%` }} />
                    </div>
                    <span className="text-[10px] font-bold text-slate-500 w-20 text-right">
                      {s.owned}/{s.total} <span className="text-slate-600">({s.pct}%)</span>
                    </span>
                  </div>
                ))}
              </div>
            )}
            {isOwnProfile && mostPlayedDeck && (
              <div className="mt-4 pt-3 border-t border-slate-800">
                <p className="text-[10px] font-bold text-slate-500 uppercase mb-1.5">{t.mostPlayed}</p>
                <div className="bg-slate-800/50 rounded-xl px-3 py-2 flex items-center gap-3">
                  <TrendingUp size={14} className="text-amber-400 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold text-white truncate">{mostPlayedDeck.name}</p>
                    <p className="text-[10px] text-slate-500">{mostPlayedDeck.total} games · {mostPlayedDeck.winRate}% WR</p>
                  </div>
                </div>
              </div>
            )}
          </div>
        );
      })()}

      {/* ===== SHOWCASE TAB ===== */}
      {authorProfileTab === 'showcase' && (() => {
        const showcaseStats = isOwnProfile ? stats : authorStats;

        if (authorStatsLoading) return (
          <div className="p-12 text-center bg-slate-900 rounded-3xl border border-slate-800">
            <div className="w-8 h-8 border-2 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
            <p className="text-slate-500 font-bold text-sm">Loading Showcase...</p>
          </div>
        );

        if (!showcaseStats?.total) return (
          <div className="p-12 text-center bg-slate-900 rounded-3xl border border-slate-800">
            <Target size={40} className="mx-auto mb-4 text-slate-700" />
            <p className="text-slate-500 font-bold text-sm">
              {isOwnProfile ? 'Play some matches to see your Showcase.' : 'No matches tracked yet.'}
            </p>
          </div>
        );

        const resolveCard = (legendName, opponent, deckName) => {
          let cardImg = null;
          if (opponent) {
            const legend = legendByShortName.get(opponent);
            cardImg = legend?.media?.image_url;
          } else if (legendName) {
            const sn = legendName.includes(',') ? legendName.split(',')[0].trim() : legendName;
            const legend = legendByShortName.get(sn) || allCards.find(c => c.name === legendName && c.classification?.type === 'Legend');
            cardImg = legend?.media?.image_url;
          } else if (deckName) {
            const sd = savedDecks.find(s => s.name === deckName);
            const legend = sd?.legendData || (sd?.legend ? allCards.find(c => c.id === sd.legend) : null);
            cardImg = legend?.media?.image_url;
          }
          return { cardImg };
        };

        const legendAgg = {};
        (showcaseStats.deckStats || []).forEach(d => {
          const ln = d.legendName || 'Unknown';
          if (!legendAgg[ln]) legendAgg[ln] = { legendName: ln, wins: 0, losses: 0, total: 0 };
          legendAgg[ln].wins += d.wins; legendAgg[ln].losses += d.losses; legendAgg[ln].total += d.total;
        });
        const legendStats = Object.values(legendAgg)
          .map(l => ({ ...l, winRate: l.total > 0 ? (l.wins / l.total * 100).toFixed(1) : '0.0' }))
          .sort((a, b) => b.total - a.total);
        const mostPlayed = legendStats[0] || null;
        const eligible = (showcaseStats.matchupStats || []).filter(m => m.total >= 1);
        const bestMatchup = eligible.length > 0 ? eligible.reduce((best, m) => parseFloat(m.winRate) > parseFloat(best.winRate) ? m : best) : null;
        const worstMatchup = eligible.length > 0 ? eligible.reduce((worst, m) => parseFloat(m.winRate) < parseFloat(worst.winRate) ? m : worst) : null;
        const mostFaced = eligible.length > 0 ? eligible[0] : null;
        const bestDeck = showcaseStats.deckStats?.length > 0 ? showcaseStats.deckStats.reduce((best, d) => parseFloat(d.winRate) > parseFloat(best.winRate) ? d : best) : null;
        const biggestWin = showcaseStats.scoreStats?.biggestWin || null;

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
                <div className="flex-1 bg-slate-700/60 rounded-full h-2 overflow-hidden">
                  <div className="h-2 rounded-full transition-all duration-500 bg-amber-500" style={{ width: `${Math.min(wrNum, 100)}%` }} />
                </div>
              </div>
            </div>
          );
        };

        const mpCard = mostPlayed ? resolveCard(mostPlayed.legendName, null, null) : null;
        const mpName = mostPlayed?.legendName?.includes(',') ? mostPlayed.legendName.split(',')[0].trim() : mostPlayed?.legendName;
        const bmCard = bestMatchup ? resolveCard(null, bestMatchup.opponent, null) : null;
        const nmCard = worstMatchup && worstMatchup !== bestMatchup && parseFloat(worstMatchup.winRate) < 100 ? resolveCard(null, worstMatchup.opponent, null) : null;
        const mfCard = mostFaced && mostFaced !== bestMatchup && mostFaced !== worstMatchup ? resolveCard(null, mostFaced.opponent, null) : null;
        const bdCard = bestDeck ? resolveCard(bestDeck.legendName, null, bestDeck.name) : null;
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
      })()}

      {/* ===== DECKS TAB ===== */}
      {authorProfileTab === 'decks' && (<>
        <div className="flex items-center justify-between px-1">
          <h3 className="text-xs font-black text-slate-500 uppercase">
            {t.decksByAuthor} {displayName}
          </h3>
          {authorLegendFilters.size > 0 && (
            <button onClick={() => setAuthorLegendFilters(new Set())} className="text-[10px] font-bold text-amber-400 active:scale-95">
              Clear
            </button>
          )}
        </div>

        {authorLegendOptions.length > 1 && (
          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar px-1">
            {authorLegendOptions.map(opt => {
              const isActive = authorLegendFilters.has(opt.shortName);
              return (
                <button
                  key={opt.shortName}
                  onClick={() => setAuthorLegendFilters(prev => {
                    const next = new Set(prev);
                    if (next.has(opt.shortName)) next.delete(opt.shortName);
                    else next.add(opt.shortName);
                    return next;
                  })}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold transition-all active:scale-95 flex-shrink-0 ${
                    isActive ? 'bg-amber-600 text-white' : 'bg-slate-900 border border-slate-800 text-slate-400'
                  }`}
                >
                  {opt.media?.image_url && <img src={opt.media.image_url} alt={opt.shortName} className="w-5 h-5 rounded-full object-cover" />}
                  <span>{opt.shortName}</span>
                  <span className="text-[10px] opacity-60">{opt.count}</span>
                </button>
              );
            })}
          </div>
        )}

        {decksToShow.length === 0 ? (
          <div className="p-12 text-center bg-slate-900 rounded-3xl border border-slate-800">
            <Layers size={40} className="mx-auto mb-4 text-slate-700" />
            <p className="text-slate-500 font-bold text-sm">{t.noDecksByAuthor}</p>
          </div>
        ) : (
          <div className="space-y-4">
            {decksToShow.map(deck => {
              const mainCount = Object.values(deck.mainDeck || {}).reduce((sum, c) => sum + c, 0);
              const bfCount = (deck.battlefields || []).length;
              const legendCard = deck.legendData;
              const legendDomains = legendCard?.classification?.domain || deck.domains || [];
              const colRate = computeCollectionRate(deck);
              const publishDate = deck.publishedAt ? new Date(deck.publishedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : null;

              return (
                <div key={deck.id} onClick={() => onLoadDeck?.(deck)} className="bg-slate-900 border border-slate-700 py-2 px-2 rounded-2xl cursor-pointer relative">
                  <div className="flex items-center gap-1.5">
                    <div className="relative w-14 h-[84px] flex-shrink-0">
                      {legendCard ? (
                        <img src={legendCard.media?.image_url} alt={legendCard.name} className="w-full h-full object-cover rounded-lg" />
                      ) : (
                        <div className="w-full h-full rounded-lg bg-slate-800 border-2 border-dashed border-slate-700 flex items-center justify-center">
                          <span className="text-slate-600 text-[9px] font-bold text-center leading-tight">No<br/>Legend</span>
                        </div>
                      )}
                    </div>
                    <div className="flex flex-col gap-1 flex-shrink-0">
                      {legendDomains.length > 0 ? legendDomains.slice(0, 2).map((domain, idx) => {
                        const runeData = RUNE_COLORS[domain];
                        return <img key={idx} src={runeData?.icon} alt={domain} className="w-8 h-8" />;
                      }) : (
                        <>
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                          <div className="w-8 h-8 rounded-full bg-slate-800 border border-dashed border-slate-700" />
                        </>
                      )}
                    </div>
                    <div className="flex-1 flex flex-col justify-center min-w-0">
                      <h3 className="text-lg font-bold text-white mb-1 whitespace-nowrap overflow-hidden text-ellipsis text-left">{deck.name}</h3>
                      <div className="flex items-center gap-2 text-[11px] text-slate-500 flex-wrap">
                        <span className="px-2 py-0.5 rounded-md font-bold bg-emerald-500/10 text-emerald-400">Main {mainCount}/40</span>
                        <span className="px-2 py-0.5 rounded-md font-bold bg-emerald-500/10 text-emerald-400">BF {bfCount}/3</span>
                        {colRate !== null && (
                          <span className={`px-2 py-0.5 rounded-md font-bold ${
                            colRate === 100 ? 'bg-emerald-500/10 text-emerald-400' :
                            colRate >= 70 ? 'bg-amber-500/10 text-amber-400' :
                            'bg-red-500/10 text-red-400'
                          }`}>
                            {colRate}%
                          </span>
                        )}
                        {publishDate && <span className="text-slate-600 text-[10px]">{publishDate}</span>}
                      </div>
                    </div>
                    <button onClick={(e) => { e.stopPropagation(); onDuplicateDeck?.(deck); }} className="flex-shrink-0 ml-auto p-2 text-slate-500 hover:text-amber-400 active:scale-110 transition-all" title="Copy to My Decks">
                      <Copy size={18} />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </>)}
    </div>
  );
}

import React, { useState, useEffect, useMemo } from 'react';
import {
  Plus, Search, Layers, TrendingUp, TrendingDown, Copy, X,
  MoreVertical, CheckCircle2, AlertCircle, Globe, Heart,
} from 'lucide-react';
import { RUNE_COLORS } from '../../constants/gameData';
import { t } from '../../constants/i18n';
import { useGameData, useAppData } from '../../contexts/AppContexts';
import { useUI } from '../shared/UIProvider';
import getMetaDecks from '../../data/meta-decks';
import { extractFilterOptions, filterMetaDecks, getShortLegendName } from '../../utils/metaDeckFilters';
import MetaDeckFilters, { LegendCardRow } from '../MetaDeckFilters';
import DeckMenu from '../DeckMenu';
import LegendFilterModal from '../modals/LegendFilterModal';
import EditDeckModal from '../modals/EditDeckModal';
import { exportDeck, exportDeckTts } from '../../utils/deckFormat';

export default function DeckBuilderOverview({ onLoadDeck, onNewDeck, onShowAuthor, lastEditedDeckId, onHighlightDeck }) {
  const { allCards, cardLookup } = useGameData();
  const {
    savedDecks, publicDecks, myPublishedDeckNames, validateDeck,
    deleteDeck, duplicateDeck, publishDeck: onPublishDeck,
    updateDeckMeta, myFollowing,
  } = useAppData();
  const ui = useUI();

  // Filter & UI state (overview-only)
  const [deckViewFilter, setDeckViewFilter] = useState('my');
  const [deckSortOrder, setDeckSortOrder] = useState('newest');
  const [deckSearchQuery, setDeckSearchQuery] = useState('');
  const [openDeckMenuId, setOpenDeckMenuId] = useState(null);
  const [metaLegendFilters, setMetaLegendFilters] = useState(new Set());
  const [metaEventFilters, setMetaEventFilters] = useState(new Set());
  const [metaSetFilters, setMetaSetFilters] = useState(new Set());
  const [myLegendFilters, setMyLegendFilters] = useState(new Set());
  const [publicLegendFilters, setPublicLegendFilters] = useState(new Set());
  const [domainFilters, setDomainFilters] = useState(new Set());
  const [deckLegendFilter, setDeckLegendFilter] = useState('');
  const [showLegendFilterModal, setShowLegendFilterModal] = useState(false);
  const [showEditDeckModal, setShowEditDeckModal] = useState(false);
  const [editingDeckData, setEditingDeckData] = useState(null);

  // Close deck menu on any click
  useEffect(() => {
    if (!openDeckMenuId) return;
    const handler = () => setOpenDeckMenuId(null);
    document.addEventListener('click', handler);
    return () => document.removeEventListener('click', handler);
  }, [openDeckMenuId]);

  // Legend options from public decks
  const publicDeckLegendOptions = useMemo(() => {
    const legendCounts = {};
    for (const deck of publicDecks) {
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
  }, [publicDecks]);

  // Pre-built meta decks resolved from card data
  const metaDecks = useMemo(() => getMetaDecks(cardLookup), [cardLookup]);
  const metaFilterOptions = useMemo(() => extractFilterOptions(metaDecks), [metaDecks]);

  // Legend options from user's saved decks
  const myDeckLegendOptions = useMemo(() => {
    const legendCounts = {};
    for (const deck of savedDecks) {
      const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
      if (!legendCard) continue;
      const shortName = getShortLegendName(legendCard.name);
      if (!shortName) continue;
      if (!legendCounts[shortName]) {
        legendCounts[shortName] = { shortName, media: legendCard.media || null, count: 0 };
      }
      legendCounts[shortName].count++;
    }
    return Object.values(legendCounts).sort((a, b) => b.count - a.count);
  }, [savedDecks, allCards]);

  const filteredMetaByFilters = useMemo(
    () => filterMetaDecks(metaDecks, { legends: metaLegendFilters, events: metaEventFilters, sets: metaSetFilters }),
    [metaDecks, metaLegendFilters, metaEventFilters, metaSetFilters]
  );

  const openEditModal = (deck) => {
    setEditingDeckData(deck);
    setShowEditDeckModal(true);
    setOpenDeckMenuId(null);
  };

  const handleSaveEditedDeck = async (deckId, name, description) => {
    await updateDeckMeta(deckId, name, description);
    onHighlightDeck(deckId);
    setShowEditDeckModal(false);
    setEditingDeckData(null);
  };

  const pillClass = (isActive) =>
    `px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all active:scale-95 ${
      isActive ? 'bg-amber-600 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'
    }`;

  // Filtering logic
  const searchLower = deckSearchQuery.toLowerCase().trim();

  const filterDeckList = (decks, legendFilterSet) => decks.filter(deck => {
    if (searchLower) {
      const name = (deck.name || '').toLowerCase();
      const desc = (deck.description || '').toLowerCase();
      const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
      const legendName = (legendCard?.name || '').toLowerCase();
      const authorName = (deck.authorName || '').toLowerCase();
      if (!name.includes(searchLower) && !desc.includes(searchLower) && !legendName.includes(searchLower) && !authorName.includes(searchLower)) return false;
    }
    if (legendFilterSet.size > 0) {
      const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
      const shortName = getShortLegendName(legendCard?.name || '');
      if (!legendFilterSet.has(shortName)) return false;
    }
    if (domainFilters.size > 0) {
      const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
      const deckDomains = legendCard?.classification?.domain || deck.domains || [];
      if (domainFilters.size === 2) {
        if (![...domainFilters].every(d => deckDomains.includes(d))) return false;
      } else {
        if (!deckDomains.some(d => domainFilters.has(d))) return false;
      }
    }
    return true;
  });

  const filteredDecks = deckViewFilter === 'my'
    ? filterDeckList(savedDecks, myLegendFilters).sort((a, b) => {
        const timeA = new Date(a.timestamp || 0).getTime();
        const timeB = new Date(b.timestamp || 0).getTime();
        return deckSortOrder === 'newest' ? timeB - timeA : timeA - timeB;
      })
    : deckViewFilter === 'public'
      ? filterDeckList(publicDecks, publicLegendFilters).sort((a, b) => {
          const timeA = new Date(a.publishedAt || 0).getTime();
          const timeB = new Date(b.publishedAt || 0).getTime();
          return deckSortOrder === 'newest' ? timeB - timeA : timeA - timeB;
        })
      : deckViewFilter === 'following'
        ? publicDecks.filter(d => myFollowing.includes(d.authorId)).sort((a, b) => {
            const timeA = new Date(a.publishedAt || 0).getTime();
            const timeB = new Date(b.publishedAt || 0).getTime();
            return deckSortOrder === 'newest' ? timeB - timeA : timeA - timeB;
          })
        : [];

  const searchedMeta = searchLower
    ? filteredMetaByFilters.filter(deck => {
        const name = (deck.name || '').toLowerCase();
        const desc = (deck.description || '').toLowerCase();
        const legendName = (deck.legendData?.name || '').toLowerCase();
        const player = (deck.player || '').toLowerCase();
        return name.includes(searchLower) || desc.includes(searchLower) || legendName.includes(searchLower) || player.includes(searchLower);
      })
    : filteredMetaByFilters;

  const domainFilteredMeta = domainFilters.size > 0
    ? searchedMeta.filter(deck => {
        const deckDomains = deck.legendData?.classification?.domain || [];
        if (domainFilters.size === 2) {
          return [...domainFilters].every(d => deckDomains.includes(d));
        }
        return deckDomains.some(d => domainFilters.has(d));
      })
    : searchedMeta;

  const filteredMeta = deckViewFilter === 'meta' ? [...domainFilteredMeta].sort((a, b) => {
    const timeA = new Date(a.createdAt || 0).getTime();
    const timeB = new Date(b.createdAt || 0).getTime();
    if (timeA !== timeB) return deckSortOrder === 'newest' ? timeB - timeA : timeA - timeB;
    const rankOrder = (p) => {
      if (!p) return 99;
      const m = p.match(/^(\d+)/);
      if (m) return parseInt(m[1]);
      if (/top\s*4/i.test(p)) return 4;
      if (/top\s*8/i.test(p)) return 8;
      if (/top\s*16/i.test(p)) return 16;
      if (/top\s*32/i.test(p)) return 32;
      if (/top\s*64/i.test(p)) return 64;
      if (/top\s*128/i.test(p)) return 128;
      return 50;
    };
    return rankOrder(a.placement) - rankOrder(b.placement);
  }) : [];

  const displayDecks = deckViewFilter === 'meta' ? filteredMeta : filteredDecks;
  const isPublicView = deckViewFilter === 'public' || deckViewFilter === 'following';

  return (
    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-24 px-2 pt-4">
      {/* Gold Ornament Header */}
      <div className="text-center pt-3 pb-1">
        <div className="flex items-center justify-center gap-3 mb-2">
          <div className="h-px w-12 bg-gradient-to-r from-transparent to-amber-500/50" />
          <div className="w-1.5 h-1.5 rotate-45 bg-amber-500/60" />
          <div className="h-px w-12 bg-gradient-to-l from-transparent to-amber-500/50" />
        </div>
        <h2 className="text-xs font-black uppercase tracking-[0.3em] bg-gradient-to-r from-amber-200 via-yellow-100 to-amber-200 bg-clip-text text-transparent">
          Forge Your Strategy
        </h2>
      </div>

      <div className="relative">
        <Search className="absolute left-4 top-3.5 text-slate-500" size={18} />
        <input type="text" placeholder="Search a deck..." value={deckSearchQuery} onChange={(e) => setDeckSearchQuery(e.target.value)} className="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 pl-12 pr-4 text-sm focus:ring-2 ring-amber-500/40 outline-none" />
      </div>

      <div className="flex items-center gap-1.5 flex-wrap">
        <button onClick={() => setDeckViewFilter('my')} className={pillClass(deckViewFilter === 'my')}>My Decks</button>
        <button onClick={() => setDeckViewFilter('meta')} className={pillClass(deckViewFilter === 'meta')}>Meta Decks</button>
        <button onClick={() => setDeckViewFilter('public')} className={pillClass(deckViewFilter === 'public')}>Public</button>
        {myFollowing.length > 0 && (
          <button onClick={() => setDeckViewFilter('following')} className={`${pillClass(deckViewFilter === 'following')} flex items-center gap-1`}>
            <Heart size={12} fill={deckViewFilter === 'following' ? 'currentColor' : 'none'} />
            {t.following}
          </button>
        )}
        <button onClick={() => setDeckSortOrder(deckSortOrder === 'newest' ? 'oldest' : 'newest')} className="flex items-center gap-1.5 bg-slate-900 border border-slate-800 px-3 py-2 rounded-full text-xs font-bold transition-all active:scale-95">
          {deckSortOrder === 'newest' ? <><TrendingUp size={14} /><span>New</span></> : <><TrendingDown size={14} /><span>Old</span></>}
        </button>
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
              className={`p-1.5 rounded-full transition-all active:scale-95 ${isActive ? 'ring-2 ring-white bg-slate-800' : 'opacity-40'}`}
            >
              <img src={RUNE_COLORS[domain].icon} alt={domain} className="w-10 h-10" style={{ translate: offset }} />
            </button>
          );
        })}
      </div>

      {deckViewFilter === 'my' && myDeckLegendOptions.length > 1 && (
        <LegendCardRow
          legends={myDeckLegendOptions}
          activeLegends={myLegendFilters}
          onToggle={(name) => setMyLegendFilters(prev => {
            const next = new Set(prev);
            next.has(name) ? next.delete(name) : next.add(name);
            return next;
          })}
        />
      )}

      {deckViewFilter === 'my' && (myLegendFilters.size > 0 || domainFilters.size > 0 || searchLower) && (
        <div className="flex items-center justify-between px-1">
          <span className="text-[11px] text-slate-500 font-medium">
            {filteredDecks.length} of {savedDecks.length} decks
          </span>
          <button
            onClick={() => { setMyLegendFilters(new Set()); setDomainFilters(new Set()); setDeckSearchQuery(''); }}
            className="flex items-center gap-1.5 text-xs text-slate-400 px-3 py-1.5 rounded-full bg-slate-800/60 active:scale-95 transition-all"
          >
            <X size={14} />
            Clear
          </button>
        </div>
      )}

      {deckViewFilter === 'public' && publicDeckLegendOptions.length > 1 && (
        <LegendCardRow
          legends={publicDeckLegendOptions}
          activeLegends={publicLegendFilters}
          onToggle={(name) => setPublicLegendFilters(prev => {
            const next = new Set(prev);
            next.has(name) ? next.delete(name) : next.add(name);
            return next;
          })}
        />
      )}

      {deckViewFilter === 'public' && (publicLegendFilters.size > 0 || domainFilters.size > 0 || searchLower) && (
        <div className="flex items-center justify-between px-1">
          <span className="text-[11px] text-slate-500 font-medium">
            {filteredDecks.length} of {publicDecks.length} decks
          </span>
          <button
            onClick={() => { setPublicLegendFilters(new Set()); setDomainFilters(new Set()); setDeckSearchQuery(''); }}
            className="flex items-center gap-1.5 text-xs text-slate-400 px-3 py-1.5 rounded-full bg-slate-800/60 active:scale-95 transition-all"
          >
            <X size={14} />
            Clear
          </button>
        </div>
      )}

      {deckViewFilter === 'meta' && (
        <MetaDeckFilters
          legends={metaFilterOptions.legends}
          events={metaFilterOptions.events}
          sets={metaFilterOptions.sets || []}
          activeLegends={metaLegendFilters}
          activeEvents={metaEventFilters}
          activeSets={metaSetFilters}
          onToggleLegend={(name) => setMetaLegendFilters(prev => {
            const next = new Set(prev);
            next.has(name) ? next.delete(name) : next.add(name);
            return next;
          })}
          onToggleEvent={(source) => setMetaEventFilters(prev => {
            const next = new Set(prev);
            next.has(source) ? next.delete(source) : next.add(source);
            return next;
          })}
          onToggleSet={(setId) => setMetaSetFilters(prev => {
            const next = new Set(prev);
            next.has(setId) ? next.delete(setId) : next.add(setId);
            return next;
          })}
          onClear={() => { setMetaLegendFilters(new Set()); setMetaEventFilters(new Set()); setMetaSetFilters(new Set()); setDomainFilters(new Set()); setDeckSearchQuery(''); }}
          filteredCount={filteredMeta.length}
          totalCount={metaDecks.length}
          hasExtraFilters={domainFilters.size > 0 || !!searchLower}
        />
      )}

      {/* Deck list divider */}
      <div className="flex items-center gap-2 px-1">
        <Layers size={12} className="text-amber-500/50" />
        <span className="text-[10px] font-bold uppercase tracking-[0.15em] text-amber-500/40">{displayDecks.length} {displayDecks.length === 1 ? 'Deck' : 'Decks'}</span>
        <div className="h-px flex-1 bg-gradient-to-r from-amber-500/15 to-transparent" />
      </div>

      {displayDecks.length === 0 ? (
        <div className="p-12 text-center bg-slate-900 rounded-3xl border border-slate-800">
          <Layers size={40} className="mx-auto mb-4 text-slate-700" />
          <p className="text-slate-500 font-bold text-sm">
            {deckViewFilter === 'meta' ? 'No meta decks available' : deckViewFilter === 'public' ? 'No public decks yet' : 'No decks created yet'}
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {displayDecks.map(deck => {
            const mainCount = Object.values(deck.mainDeck || {}).reduce((sum, c) => sum + c, 0);
            const sideCount = Object.values(deck.sideboard || {}).reduce((sum, c) => sum + c, 0);
            const bfCount = (deck.battlefields || []).length;
            const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
            const legendDomains = legendCard?.classification?.domain || deck.domains || [];
            const validation = !isPublicView ? validateDeck(deck) : { isValid: true };
            const isMeta = deck.isPrebuilt;
            const displayName = isMeta ? deck.name.replace(/\s*(?:Fury|Mind|Chaos|Calm|Body|Order)\/(?:Fury|Mind|Chaos|Calm|Body|Order)\s*/g, ' ').trim() : deck.name;
            const metaDate = isMeta && deck.createdAt ? new Date(deck.createdAt).toLocaleDateString('en-US', { month: 'short', year: 'numeric' }) : null;
            const publishDate = isPublicView && deck.publishedAt ? new Date(deck.publishedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : null;
            const deckSets = isPublicView ? [...new Set(
              Object.keys(deck.mainDeck || {}).concat(Object.keys(deck.sideboard || {}))
                .map(id => cardLookup.get(id)?.set?.set_id).filter(Boolean)
            )] : null;
            return (
              <div key={deck.id} onClick={() => onLoadDeck(deck)} className={`bg-slate-900 border py-2 px-2 rounded-2xl cursor-pointer relative ${lastEditedDeckId === deck.id ? 'border-amber-600' : isMeta ? 'border-slate-700' : isPublicView ? 'border-slate-700' : 'border-slate-800'}`}>
                <div className="absolute top-1.5 right-1.5 z-10 flex items-center gap-1">
                  {isMeta ? (
                    <span className="px-1.5 py-0.5 rounded text-[10px] font-black bg-amber-500/20 text-amber-400 border border-amber-500/30">{deck.placement || deck.source}</span>
                  ) : isPublicView ? null : (
                    <>
                      {myPublishedDeckNames.has(deck.name) && (
                        <Globe size={14} className="text-amber-400" />
                      )}
                      {validation.isValid ? <CheckCircle2 size={16} className="text-emerald-500" /> : <AlertCircle size={16} className="text-red-500" />}
                    </>
                  )}
                </div>
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
                    <h3 className="text-lg font-bold text-white mb-1 whitespace-nowrap overflow-hidden text-ellipsis text-left">{displayName}</h3>
                    {isPublicView && deck.authorName && (
                      <p className="text-[11px] text-slate-500 mb-1 text-left">by <button onClick={(e) => { e.stopPropagation(); onShowAuthor({ authorId: deck.authorId, authorName: deck.authorName }); }} className="text-amber-400 font-medium hover:underline">{deck.authorName}</button></p>
                    )}
                    {!isPublicView && deck.description && <p className="text-xs text-slate-500 mb-1.5 line-clamp-1 text-left">{deck.description}</p>}
                    <div className="flex items-center gap-1.5 text-[11px] text-slate-500 flex-wrap">
                      {isMeta ? (
                        <>
                          {(deck.sets || []).map(set => (
                            <span key={set} className="px-2 py-0.5 rounded-md font-bold bg-amber-600/15 text-amber-400 border border-amber-600/20">
                              {set}
                            </span>
                          ))}
                          {metaDate && <span className="text-slate-600 text-[10px]">{metaDate}</span>}
                        </>
                      ) : isPublicView ? (
                        <>
                          {(deckSets || []).map(set => (
                            <span key={set} className="px-2 py-0.5 rounded-md font-bold bg-amber-600/15 text-amber-400 border border-amber-600/20">
                              {set}
                            </span>
                          ))}
                          {publishDate && <span className="text-slate-600 text-[10px]">{publishDate}</span>}
                        </>
                      ) : (
                        <>
                          <span className={`px-2 py-0.5 rounded-md font-bold ${mainCount === 40 ? 'bg-amber-500/10 text-amber-400' : 'bg-slate-800 text-slate-400'}`}>
                            Main {mainCount}/40
                          </span>
                          <span className={`px-2 py-0.5 rounded-md font-bold ${bfCount === 3 ? 'bg-amber-500/10 text-amber-400' : 'bg-slate-800 text-slate-400'}`}>
                            BF {bfCount}/3
                          </span>
                          <span className={`px-2 py-0.5 rounded-md font-bold ${sideCount === 8 ? 'bg-amber-500/10 text-amber-400' : 'bg-slate-800 text-slate-400'}`}>
                            Side {sideCount}/8
                          </span>
                        </>
                      )}
                    </div>
                  </div>
                  {(isMeta || isPublicView) && (
                    <button onClick={(e) => { e.stopPropagation(); duplicateDeck(deck); }} className="flex-shrink-0 ml-auto p-2 text-slate-500 hover:text-amber-400 active:scale-110 transition-all" title="Copy to My Decks">
                      <Copy size={18} />
                    </button>
                  )}
                  {!isMeta && !isPublicView && <div className="relative flex-shrink-0">
                    <button onClick={(e) => { e.stopPropagation(); setOpenDeckMenuId(openDeckMenuId === deck.id ? null : deck.id); }} className="p-1 -mr-1 text-slate-400 hover:text-white transition-all">
                      <MoreVertical size={18} />
                    </button>
                    {openDeckMenuId === deck.id && (
                      <DeckMenu deck={deck} isValid={validation.isValid}
                        onPublish={() => onPublishDeck(deck)}
                        onExport={() => {
                          const text = exportDeck(deck, allCards, cardLookup);
                          navigator.clipboard.writeText(text).then(() => ui.toast('Deck list copied!', 'success')).catch(() => ui.toast('Could not copy', 'error'));
                        }}
                        onExportTts={() => {
                          const text = exportDeckTts(deck, allCards, cardLookup);
                          navigator.clipboard.writeText(text).then(() => ui.toast('TTS code copied!', 'success')).catch(() => ui.toast('Could not copy', 'error'));
                        }}
                        onEdit={() => openEditModal(deck)}
                        onDuplicate={() => { duplicateDeck(deck); setOpenDeckMenuId(null); }}
                        onDelete={() => { deleteDeck(deck.id); setOpenDeckMenuId(null); }}
                        onClose={() => setOpenDeckMenuId(null)}
                      />
                    )}
                  </div>}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {deckViewFilter === 'my' && (
        <button onClick={onNewDeck}
          className="fixed bottom-24 right-6 w-14 h-14 bg-amber-600 hover:bg-amber-500 rounded-full shadow-2xl flex items-center justify-center active:scale-95 z-50"
          style={{ animation: 'fab-slide-up 0.4s cubic-bezier(0.4, 0, 0.2, 1) both' }}>
          <Plus size={28} className="text-white" />
        </button>
      )}
      <style>{`
        @keyframes fab-slide-up {
          from { transform: translateY(4.5rem); }
          to { transform: translateY(0); }
        }
      `}</style>
      <LegendFilterModal isOpen={showLegendFilterModal} onClose={() => setShowLegendFilterModal(false)} allCards={allCards} activeFilter={deckLegendFilter} onFilterChange={setDeckLegendFilter} />
      <EditDeckModal isOpen={showEditDeckModal} onClose={() => { setShowEditDeckModal(false); setEditingDeckData(null); }} deck={editingDeckData} onSave={handleSaveEditedDeck} />
    </div>
  );
}

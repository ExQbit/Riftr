import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import CardPreview, { useLongPress } from '../shared/CardPreview';
import {
  Plus, Search, Layers, TrendingUp, TrendingDown, Filter, Copy, X,
  MoreVertical, Eye, EyeOff, Save, Edit, CheckCircle2, AlertCircle, ArrowLeft, Check, Globe, User, Heart, Users
} from 'lucide-react';
import { RUNE_COLORS } from '../../constants/gameData';
import { t } from '../../constants/i18n';
import CardSelectionModal from '../modals/CardSelectionModal';
import AuthorProfile from '../shared/AuthorProfile';
import EditDeckModal from '../modals/EditDeckModal';
import LegendFilterModal from '../modals/LegendFilterModal';
import ImportDeckModal from '../modals/ImportDeckModal';
import DeckMenu from '../DeckMenu';
import { exportDeck, exportDeckTts, importDeck } from '../../utils/deckFormat';
import { useUI } from '../shared/UIProvider';
import getMetaDecks from '../../data/meta-decks';
import { extractFilterOptions, filterMetaDecks } from '../../utils/metaDeckFilters';
import MetaDeckFilters, { LegendCardRow } from '../MetaDeckFilters';
import { getShortLegendName } from '../../utils/metaDeckFilters';

// Get max allowed copies for a card (across main + side combined)
function getMaxCopies(card) {
  if (!card) return 3;
  // Check for explicit deck_limit field on card data
  if (card.deck_limit !== undefined && card.deck_limit !== null) return card.deck_limit;
  if (card.attributes?.deck_limit !== undefined && card.attributes?.deck_limit !== null) return card.attributes.deck_limit;
  // Legends and Battlefields are handled separately (1 each), so this is for main/side cards
  const type = card.classification?.type;
  if (type === 'Legend' || type === 'Battlefield') return 1;
  // Default: 3 copies
  return 3;
}

export default function DeckBuilderTab({
  allCards,
  cardLookup,
  savedDecks,
  saveDeck,
  deleteDeck,
  duplicateDeck,
  onPublishDeck,
  updateDeckMeta,
  validateDeck,
  onEditModeChange,
  getQuantity,
  publicDecks = [],
  myPublishedDeckNames = new Set(),
  user,
  stats,
  follow,
  unfollow,
  isFollowing,
  getFollowerCount,
  myFollowing = [],
}) {
  const [view, setView] = useState('overview');
  const [editingDeckId, setEditingDeckId] = useState(null);
  const [isEditMode, setIsEditMode] = useState(false);
  const [showSaveDialog, setShowSaveDialog] = useState(false);
  const [editSnapshot, setEditSnapshot] = useState(null);
  const [lastEditedDeckId, setLastEditedDeckId] = useState(null);
  const [loadedDeckMeta, setLoadedDeckMeta] = useState(null); // { source, placement, sets, sourceUrl, createdAt }
  const [selectedAuthor, setSelectedAuthor] = useState(null); // { authorId, authorName }
  const [loadedDeckAuthor, setLoadedDeckAuthor] = useState(null); // { authorId, authorName }

  const [deckName, setDeckName] = useState('');
  const [deckDescription, setDeckDescription] = useState('');
  const [selectedLegend, setSelectedLegend] = useState(null);
  const [selectedBattlefields, setSelectedBattlefields] = useState([]);
  const [runes, setRunes] = useState({ r1: 6, r2: 6 });
  const [customMainDeck, setCustomMainDeck] = useState({});
  const [customSideboard, setCustomSideboard] = useState({});
  const [showCollectionStatus, setShowCollectionStatus] = useState(false);

  // Compute real changes by comparing with snapshot
  const hasUnsavedChanges = useMemo(() => {
    if (!isEditMode || !editSnapshot) return false;
    try {
      if ((selectedLegend?.id || null) !== (editSnapshot.selectedLegend?.id || null)) return true;
      const bfIds = (selectedBattlefields || []).map(b => b?.id).join(',');
      const snapBfIds = (editSnapshot.selectedBattlefields || []).map(b => b?.id).join(',');
      if (bfIds !== snapBfIds) return true;
      if (runes.r1 !== editSnapshot.runes.r1 || runes.r2 !== editSnapshot.runes.r2) return true;
      const mainKeys = Object.keys(customMainDeck);
      const snapMainKeys = Object.keys(editSnapshot.customMainDeck || {});
      if (mainKeys.length !== snapMainKeys.length) return true;
      for (const k of mainKeys) { if (customMainDeck[k] !== (editSnapshot.customMainDeck || {})[k]) return true; }
      const sideKeys = Object.keys(customSideboard);
      const snapSideKeys = Object.keys(editSnapshot.customSideboard || {});
      if (sideKeys.length !== snapSideKeys.length) return true;
      for (const k of sideKeys) { if (customSideboard[k] !== (editSnapshot.customSideboard || {})[k]) return true; }
      return false;
    } catch (e) {
      return false;
    }
  }, [isEditMode, editSnapshot, selectedLegend, selectedBattlefields, runes, customMainDeck, customSideboard]);

  const [showCardModal, setShowCardModal] = useState(false);
  const [cardSelectionCategory, setCardSelectionCategory] = useState('');
  const [showEditDeckModal, setShowEditDeckModal] = useState(false);
  const [editingDeckData, setEditingDeckData] = useState(null);
  const [showLegendFilterModal, setShowLegendFilterModal] = useState(false);
  const [showImportModal, setShowImportModal] = useState(false);

  const [deckViewFilter, setDeckViewFilter] = useState('my');
  const [deckSortOrder, setDeckSortOrder] = useState('newest');
  const [deckLegendFilter, setDeckLegendFilter] = useState('');
  const [deckSearchQuery, setDeckSearchQuery] = useState('');
  const [openDeckMenuId, setOpenDeckMenuId] = useState(null);
  const [metaLegendFilters, setMetaLegendFilters] = useState(new Set());
  const [metaEventFilters, setMetaEventFilters] = useState(new Set());
  const [metaSetFilters, setMetaSetFilters] = useState(new Set());
  const [myLegendFilters, setMyLegendFilters] = useState(new Set());
  const [publicLegendFilters, setPublicLegendFilters] = useState(new Set());
  const [domainFilters, setDomainFilters] = useState(new Set());
  const ui = useUI();

  // Legend options extracted from public decks
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

  // Meta deck filter options + filtered results
  const metaFilterOptions = useMemo(() => extractFilterOptions(metaDecks), [metaDecks]);
  // Legend options extracted from user's saved decks
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

  // Scroll to top on every view change (with iOS Safari workaround)
  useEffect(() => {
    // Immediate attempt
    window.scrollTo(0, 0);
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
    // Retry after render + paint (iOS Safari needs this)
    requestAnimationFrame(() => {
      window.scrollTo(0, 0);
      document.documentElement.scrollTop = 0;
      document.body.scrollTop = 0;
      // One more after layout settles
      setTimeout(() => {
        window.scrollTo(0, 0);
        document.documentElement.scrollTop = 0;
        document.body.scrollTop = 0;
      }, 100);
    });
  }, [view]);

  useEffect(() => {
    const handler = () => { if (openDeckMenuId) setOpenDeckMenuId(null); };
    document.addEventListener('click', handler);
    return () => document.removeEventListener('click', handler);
  }, [openDeckMenuId]);

  // Notify parent about edit mode changes (hide nav when not on overview)
  useEffect(() => {
    onEditModeChange?.(view !== 'overview');
  }, [view, onEditModeChange]);


  const adjustRune1 = useCallback((delta) => {
    setRunes(prev => {
      const n = Math.max(0, Math.min(12, prev.r1 + delta));
      return { r1: n, r2: 12 - n };
    });
  }, []);

  const adjustRune2 = useCallback((delta) => {
    setRunes(prev => {
      const n = Math.max(0, Math.min(12, prev.r2 + delta));
      return { r1: 12 - n, r2: n };
    });
  }, []);

  // Get total copies of a card name across both main + side (ID-based storage)
  const getTotalCopies = useCallback((cardName) => {
    let total = 0;
    for (const [cardId, count] of Object.entries(customMainDeck)) {
      const c = cardLookup.get(cardId);
      if (c && c.name === cardName) total += count;
    }
    for (const [cardId, count] of Object.entries(customSideboard)) {
      const c = cardLookup.get(cardId);
      if (c && c.name === cardName) total += count;
    }
    return total;
  }, [customMainDeck, customSideboard, cardLookup]);

  // Check if a card can be added (respects copy limit)
  const canAddCard = useCallback((card) => {
    const max = getMaxCopies(card);
    const current = getTotalCopies(card.name);
    return current < max;
  }, [getTotalCopies]);

  const enterEditMode = () => {
    setEditSnapshot({
      selectedLegend,
      selectedBattlefields: [...selectedBattlefields],
      runes: { ...runes },
      customMainDeck: { ...customMainDeck },
      customSideboard: { ...customSideboard },
    });
    setIsEditMode(true);
  };

  const handleSaveAndExit = async () => {
    await handleSaveDeck();
    setIsEditMode(false);
    setShowSaveDialog(false);
    setEditSnapshot(null);
  };

  const handleDiscard = () => {
    if (editSnapshot) {
      setSelectedLegend(editSnapshot.selectedLegend);
      setSelectedBattlefields(editSnapshot.selectedBattlefields);
      setRunes(editSnapshot.runes);
      setCustomMainDeck(editSnapshot.customMainDeck);
      setCustomSideboard(editSnapshot.customSideboard);
    }
    setIsEditMode(false);
    setShowSaveDialog(false);
    setEditSnapshot(null);
  };

  const resetEditor = () => {
    setEditingDeckId(null);
    setDeckName('');
    setDeckDescription('');
    setSelectedLegend(null);
    setSelectedBattlefields([]);
    setRunes({ r1: 6, r2: 6 });
    setCustomMainDeck({});
    setCustomSideboard({});
    setIsEditMode(false);
    setLoadedDeckAuthor(null);
  };

  // Migrate name-based deck keys to ID-based (for decks saved before ID migration)
  const migrateToIds = useCallback((deckMap) => {
    if (!deckMap || !cardLookup) return deckMap || {};
    const result = {};
    for (const [key, count] of Object.entries(deckMap)) {
      const card = cardLookup.get(key); // Works for both name and ID keys
      if (card) {
        result[card.id] = (result[card.id] || 0) + count;
      } else {
        result[key] = count; // Keep unknown keys as-is
      }
    }
    return result;
  }, [cardLookup]);

  const loadDeck = (deck) => {
    setEditingDeckId(deck.id);
    setDeckName(deck.name);
    setDeckDescription(deck.description || '');
    const legend = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);
    setSelectedLegend(legend);
    const battlefields = (deck.battlefields || []).map(bf =>
      bf.id ? (allCards.find(c => c.id === bf.id) || bf) : bf
    );
    setSelectedBattlefields(battlefields);
    setRunes({ r1: deck.runeCount1 ?? 6, r2: deck.runeCount2 ?? 6 });
    setCustomMainDeck(migrateToIds(deck.mainDeck));
    setCustomSideboard(migrateToIds(deck.sideboard));
    setLastEditedDeckId(deck.id);
    setLoadedDeckMeta(deck.isPrebuilt ? { source: deck.source, placement: deck.placement, sets: deck.sets, sourceUrl: deck.sourceUrl, createdAt: deck.createdAt } : null);
    setLoadedDeckAuthor(deck.authorId ? { authorId: deck.authorId, authorName: deck.authorName } : null);
    setIsEditMode(false);
    setView('edit');
  };

  const handleSaveDeck = async () => {
    await saveDeck({
      name: deckName,
      description: deckDescription,
      selectedLegend,
      battlefields: selectedBattlefields,
      runeCount1: runes.r1,
      runeCount2: runes.r2,
      mainDeck: customMainDeck,
      sideboard: customSideboard,
    }, editingDeckId);
  };

  const getCurrentDeckForValidation = () => ({
    name: deckName,
    description: deckDescription,
    legendData: selectedLegend,
    legend: selectedLegend?.id,
    runeCount1: runes.r1,
    runeCount2: runes.r2,
    battlefields: selectedBattlefields,
    mainDeck: customMainDeck,
    sideboard: customSideboard,
  });

  const handleSelectCard = (card, { force = false } = {}) => {
    if (cardSelectionCategory === 'legend') {
      setSelectedLegend(card);
    } else if (cardSelectionCategory === 'battlefields') {
      setSelectedBattlefields(prev => {
        if (prev.some(bf => bf.id === card.id)) return prev;
        if (prev.length >= 3) return prev;
        return [...prev, card];
      });
    } else if (cardSelectionCategory === 'main') {
      if (!force && !canAddCard(card)) return;
      setCustomMainDeck(prev => ({ ...prev, [card.id]: (prev[card.id] || 0) + 1 }));
    } else if (cardSelectionCategory === 'side') {
      if (!force && !canAddCard(card)) return;
      setCustomSideboard(prev => ({ ...prev, [card.id]: (prev[card.id] || 0) + 1 }));
    }
  };

  const cardModalSnapshotRef = useRef(null);

  const openCardModal = (category) => {
    // Snapshot current deck state so we can restore on discard
    cardModalSnapshotRef.current = {
      legend: selectedLegend,
      battlefields: [...selectedBattlefields],
      mainDeck: { ...customMainDeck },
      sideboard: { ...customSideboard },
    };
    setCardSelectionCategory(category);
    setShowCardModal(true);
  };

  const handleCardModalDiscard = () => {
    const snap = cardModalSnapshotRef.current;
    if (snap) {
      setSelectedLegend(snap.legend);
      setSelectedBattlefields(snap.battlefields);
      setCustomMainDeck(snap.mainDeck);
      setCustomSideboard(snap.sideboard);
    }
    setShowCardModal(false);
  };

  const openEditModal = (deck) => {
    setEditingDeckData(deck);
    setShowEditDeckModal(true);
    setOpenDeckMenuId(null);
  };

  const handleSaveEditedDeck = async (deckId, name, description) => {
    await updateDeckMeta(deckId, name, description);
    setLastEditedDeckId(deckId);
    if (editingDeckId === deckId) {
      setDeckName(name);
      setDeckDescription(description);
    }
    setShowEditDeckModal(false);
    setEditingDeckData(null);
  };

  // Export current deck to clipboard
  const handleExportDeck = useCallback(() => {
    const deckData = getCurrentDeckForValidation();
    const text = exportDeck(deckData, allCards, cardLookup);
    navigator.clipboard.writeText(text).then(() => {
      ui.toast('Deck list copied to clipboard!', 'success');
    }).catch(() => {
      ui.toast('Could not copy to clipboard', 'error');
    });
  }, [allCards, cardLookup, deckName, deckDescription, selectedLegend, selectedBattlefields, runes, customMainDeck, customSideboard, ui]);

  // Export current deck as TTS code to clipboard
  const handleExportTts = useCallback(() => {
    const deckData = getCurrentDeckForValidation();
    const text = exportDeckTts(deckData, allCards, cardLookup);
    navigator.clipboard.writeText(text).then(() => {
      ui.toast('TTS code copied to clipboard!', 'success');
    }).catch(() => {
      ui.toast('Could not copy to clipboard', 'error');
    });
  }, [allCards, cardLookup, deckName, deckDescription, selectedLegend, selectedBattlefields, runes, customMainDeck, customSideboard]);

  // Import deck from text
  const handleImportDeck = useCallback((text, previewOnly) => {
    const result = importDeck(text, allCards, cardLookup);
    if (previewOnly) return result;

    // Apply imported data
    const { deck } = result;
    if (deck.selectedLegend) setSelectedLegend(deck.selectedLegend);
    setSelectedBattlefields(deck.battlefields || []);
    setRunes({ r1: deck.runeCount1 ?? 6, r2: deck.runeCount2 ?? 6 });
    setCustomMainDeck(deck.mainDeck || {});
    setCustomSideboard(deck.sideboard || {});

    // Auto-enter edit mode if not already
    if (!isEditMode) enterEditMode();

    return result;
  }, [allCards, cardLookup, isEditMode]);

  // Increment with copy limit check (ID-based)
  const handleIncrement = useCallback((cardId, setDeck) => {
    const card = cardLookup.get(cardId);
    if (!card) return;
    const max = getMaxCopies(card);
    const total = getTotalCopies(card.name);
    if (total >= max) return; // At limit
    setDeck(prev => ({ ...prev, [cardId]: (prev[cardId] || 0) + 1 }));
  }, [cardLookup, getTotalCopies]);

  const pillClass = (isActive) =>
    `px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all active:scale-95 ${
      isActive ? 'bg-amber-600 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'
    }`;

  // ========================================
  // OVERVIEW VIEW
  // ========================================
  if (view === 'overview') {
    const searchLower = deckSearchQuery.toLowerCase().trim();
    // Filter function shared between my decks and public decks
    const filterDeckList = (decks, legendFilterSet) => decks
      .filter(deck => {
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
      // Primary: date newest first
      const timeA = new Date(a.createdAt || 0).getTime();
      const timeB = new Date(b.createdAt || 0).getTime();
      if (timeA !== timeB) return deckSortOrder === 'newest' ? timeB - timeA : timeA - timeB;
      // Secondary: placement rank (1st < 2nd < Top 4 < Top 8 < ...)
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

        {/* Domain filter row — offset corrections for off-center PNGs */}
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
              // Strip rune names from meta deck titles (already shown as icons)
              const displayName = isMeta ? deck.name.replace(/\s*(?:Fury|Mind|Chaos|Calm|Body|Order)\/(?:Fury|Mind|Chaos|Calm|Body|Order)\s*/g, ' ').trim() : deck.name;
              // Format tournament date for meta decks
              const metaDate = isMeta && deck.createdAt ? new Date(deck.createdAt).toLocaleDateString('en-US', { month: 'short', year: 'numeric' }) : null;
              // Format publish date for public decks
              const publishDate = isPublicView && deck.publishedAt ? new Date(deck.publishedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : null;
              // Derive sets from deck cards for public/following decks
              const deckSets = isPublicView ? [...new Set(
                Object.keys(deck.mainDeck || {}).concat(Object.keys(deck.sideboard || {}))
                  .map(id => cardLookup.get(id)?.set?.set_id).filter(Boolean)
              )] : null;
              return (
                <div key={deck.id} onClick={() => loadDeck(deck)} className={`bg-slate-900 border py-2 px-2 rounded-2xl cursor-pointer relative ${lastEditedDeckId === deck.id ? 'border-amber-600' : isMeta ? 'border-slate-700' : isPublicView ? 'border-slate-700' : 'border-slate-800'}`}>
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
                        <p className="text-[11px] text-slate-500 mb-1 text-left">by <button onClick={(e) => { e.stopPropagation(); setSelectedAuthor({ authorId: deck.authorId, authorName: deck.authorName }); setView('author'); }} className="text-amber-400 font-medium hover:underline">{deck.authorName}</button></p>
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
          <button onClick={() => { resetEditor(); setView('create'); }}
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

  // ========================================
  // AUTHOR PROFILE VIEW
  // ========================================
  if (view === 'author' && selectedAuthor) {
    return (
      <AuthorProfile
        selectedAuthor={selectedAuthor}
        user={user}
        onBack={() => setView('overview')}
        allCards={allCards}
        publicDecks={publicDecks}
        savedDecks={savedDecks}
        stats={stats}
        getQuantity={getQuantity}
        follow={follow}
        unfollow={unfollow}
        isFollowing={isFollowing}
        getFollowerCount={getFollowerCount}
        onLoadDeck={loadDeck}
        onDuplicateDeck={duplicateDeck}
      />
    );
  }

  // ========================================
  // CREATE VIEW
  // ========================================
  if (view === 'create') {
    const hasName = deckName.trim().length > 0;
    return (
      <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-24 px-2 pt-4">
        <div className="bg-slate-900 border border-slate-800 p-6 rounded-3xl shadow-xl max-w-2xl mx-auto">
          <h2 className="text-2xl font-black text-amber-500 mb-6">NEW DECK</h2>
          <div className="space-y-4">
            <div>
              <label className="text-xs font-black text-slate-500 uppercase mb-2 block">Deck Name</label>
              <input type="text" placeholder="e.g. Dark Witch Aggro" value={deckName} onChange={e => setDeckName(e.target.value)} onBlur={() => setTimeout(() => window.scrollTo(0, 0), 50)} className="w-full bg-slate-800 border-none rounded-xl py-3 px-4 text-sm focus:ring-2 ring-amber-500/40 outline-none" />
            </div>
            <div>
              <label className="text-xs font-black text-slate-500 uppercase mb-2 block">Description (Optional)</label>
              <textarea placeholder="Describe your deck strategy..." value={deckDescription} onChange={e => setDeckDescription(e.target.value)} onBlur={() => setTimeout(() => window.scrollTo(0, 0), 50)} rows={3} className="w-full bg-slate-800 border-none rounded-xl py-3 px-4 text-sm focus:ring-2 ring-amber-500/40 outline-none resize-none" />
            </div>
          </div>
        </div>
        <button
          onClick={() => { if (hasName) { setView('edit'); enterEditMode(); } else { setView('overview'); resetEditor(); } }}
          className={`fixed bottom-6 right-6 w-14 h-14 rounded-full shadow-2xl flex items-center justify-center transition-[background-color] duration-[350ms] active:scale-95 z-50 ${
            hasName ? 'bg-emerald-600 active:bg-emerald-500' : 'bg-amber-600 active:bg-amber-500'
          }`}
          style={{ animation: 'fab-slide-down 0.4s cubic-bezier(0.4, 0, 0.2, 1) both' }}
        >
          {hasName ? <Check size={28} className="text-white" /> : <ArrowLeft size={24} className="text-white" />}
        </button>
        <style>{`
          @keyframes fab-slide-down {
            from { transform: translateY(-4.5rem); }
            to { transform: translateY(0); }
          }
        `}</style>
      </div>
    );
  }

  // ========================================
  // EDIT VIEW
  // ========================================
  const currentValidation = validateDeck(getCurrentDeckForValidation());
  const isMetaDeck = !!loadedDeckMeta;

  const handleBack = () => {
    if (isEditMode && hasUnsavedChanges) {
      setShowSaveDialog(true);
    } else {
      setIsEditMode(false);
      setEditSnapshot(null);
      setView('overview');
    }
  };

  const legendMissing = showCollectionStatus && getQuantity && selectedLegend && getQuantity(selectedLegend.id) === 0;
  const bfMissingIds = showCollectionStatus && getQuantity ? new Set(selectedBattlefields.filter(c => getQuantity(c.id) === 0).map(c => c.id)) : new Set();

  // Pre-compute collection badge data
  const collectionBadge = (() => {
    if (isEditMode || !getQuantity) return null;
    const deckCards = { ...customMainDeck, ...customSideboard };
    const totalNeeded = Object.values(deckCards).reduce((s, q) => s + q, 0);
    const totalOwned = Object.entries(deckCards).reduce((s, [id, qty]) => s + Math.min(getQuantity(id), qty), 0);
    const missing = totalNeeded - totalOwned;
    return { totalNeeded, totalOwned, missing };
  })();

  return (
    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-24 pt-4">
      <div className="pb-3 border-b border-slate-800/50 px-2">
        <div className="relative text-center">
          <h2 className="text-2xl font-black text-amber-500 px-10">{deckName}</h2>
          {deckDescription && <p className="text-sm text-slate-500 mt-1 px-10">{deckDescription}</p>}

          {/* Author link for public decks */}
          {loadedDeckAuthor && (
            <p className="text-[11px] text-slate-500 mt-1">
              by{' '}
              <button
                onClick={() => { setSelectedAuthor(loadedDeckAuthor); setView('author'); }}
                className="text-amber-400 font-medium hover:underline"
              >
                {loadedDeckAuthor.authorName}
              </button>
            </p>
          )}

          {/* Meta deck: source info */}
          {isMetaDeck && (
            <div className="flex items-center justify-center gap-2 mt-2 flex-wrap">
              {loadedDeckMeta.placement && (
                <span className="px-2 py-0.5 rounded text-[10px] font-black bg-amber-500/20 text-amber-400 border border-amber-500/30">{loadedDeckMeta.placement}</span>
              )}
              {loadedDeckMeta.source && (
                <span className="text-[11px] text-slate-500 font-medium">{loadedDeckMeta.source}</span>
              )}
              {(loadedDeckMeta.sets || []).map(set => (
                <span key={set} className="px-2 py-0.5 rounded-md text-[10px] font-bold bg-amber-600/15 text-amber-400 border border-amber-600/20">{set}</span>
              ))}
              {loadedDeckMeta.createdAt && (
                <span className="text-[10px] text-slate-600">{new Date(loadedDeckMeta.createdAt).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}</span>
              )}
            </div>
          )}

          {/* Right: menu for user decks only (meta decks use FAB for copy) */}
          {!isMetaDeck && (
            <div className="absolute top-0 right-0">
              <button onClick={(e) => { e.stopPropagation(); setOpenDeckMenuId(openDeckMenuId === 'current' ? null : 'current'); }} className="p-2 text-slate-400 hover:text-white transition-all">
                <MoreVertical size={20} />
              </button>
              {openDeckMenuId === 'current' && (
                <DeckMenu deck={getCurrentDeckForValidation()} isValid={currentValidation.isValid}
                  onPublish={() => { if (editingDeckId) onPublishDeck(getCurrentDeckForValidation()); }}
                  onExport={handleExportDeck}
                  onExportTts={handleExportTts}
                  onImport={() => setShowImportModal(true)}
                  onEdit={() => openEditModal({ id: editingDeckId, name: deckName, description: deckDescription })}
                  onDuplicate={() => { if (editingDeckId) duplicateDeck(getCurrentDeckForValidation()); }}
                  onDelete={() => { if (editingDeckId) { deleteDeck(editingDeckId); setView('overview'); } }}
                  onClose={() => setOpenDeckMenuId(null)}
                />
              )}
            </div>
          )}
        </div>
      </div>

      {/* Collection Status Badge (toggleable) */}
      {collectionBadge && (
        <div className="flex justify-center px-2">
          <button
            onClick={() => setShowCollectionStatus(!showCollectionStatus)}
            className={`px-3 py-1 rounded-full text-xs font-bold border transition-all ${
              showCollectionStatus
                ? (collectionBadge.missing === 0 ? 'text-emerald-400 bg-emerald-500/20 border-emerald-500/40' : 'text-amber-400 bg-amber-500/20 border-amber-500/40')
                : 'text-slate-400 bg-slate-800/50 border-slate-700'
            }`}
          >
            <span className="flex items-center gap-1.5">
              {collectionBadge.missing === 0
                ? `✓ Alle ${collectionBadge.totalNeeded} Karten in Sammlung`
                : `${collectionBadge.totalOwned}/${collectionBadge.totalNeeded} Karten in Sammlung · ${collectionBadge.missing} fehlen`}
              {showCollectionStatus ? <Eye size={12} /> : <EyeOff size={12} />}
            </span>
          </button>
        </div>
      )}

      {/* Legend & Runes Row */}
      <div className="grid grid-cols-2 gap-4 px-2">
        <div className="py-3">
          <h3 className="text-sm font-black text-slate-400 mb-3 text-center">LEGEND ({selectedLegend ? 1 : 0}/1)</h3>
          <div className="grid grid-cols-1 gap-3">
            {selectedLegend ? (
              <div className="relative aspect-[2/3] group">
                <img src={selectedLegend.media.image_url} alt={selectedLegend.name} className={`w-full h-full object-cover rounded-xl ${legendMissing ? 'grayscale opacity-50' : ''}`} />
                {isEditMode && (
                  <button onClick={() => setSelectedLegend(null)} className="absolute top-2 right-2 p-1 bg-red-600 hover:bg-red-500 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity">
                    <Plus size={16} className="rotate-45 text-white" />
                  </button>
                )}
                <p className="text-xs font-bold text-center mt-2">{selectedLegend.name}</p>
              </div>
            ) : isEditMode ? (
              <button onClick={() => openCardModal('legend')} className="aspect-[2/3] bg-slate-800 border-2 border-dashed border-slate-700 rounded-xl hover:border-amber-600 transition-all flex items-center justify-center group">
                <Plus size={48} className="text-slate-600 group-hover:text-amber-500 transition-colors" />
              </button>
            ) : (
              <div className="aspect-[2/3] bg-slate-800/50 border-2 border-slate-700 rounded-xl flex items-center justify-center">
                <span className="text-slate-600 text-sm">No Legend</span>
              </div>
            )}
          </div>
        </div>

        {/* Runes */}
        <div className="py-3 flex flex-col justify-center">
          <h3 className="text-sm font-black text-slate-400 mb-3 text-center">RUNES ({runes.r1 + runes.r2}/12)</h3>
          {selectedLegend?.classification?.domain ? (
            <div className="flex flex-col gap-4 justify-center flex-1">
              {selectedLegend.classification.domain.slice(0, 2).map((runeName, index) => {
                const runeData = RUNE_COLORS[runeName] || RUNE_COLORS['Colorless'];
                const count = index === 0 ? runes.r1 : runes.r2;
                const adjustFn = index === 0 ? adjustRune1 : adjustRune2;
                return (
                  <div key={index} className="flex items-center justify-center">
                    <div className="text-center w-full">
                      <img src={runeData.icon} alt={runeData.name} className="w-16 h-16 mx-auto mb-2 object-contain" />
                      <p className="text-xs font-bold text-slate-300 mb-2">{runeData.name}</p>
                      <div className="h-[32px] flex items-center justify-center">
                        {isEditMode ? (
                          <div className="flex items-center justify-center gap-2">
                            <button onClick={() => adjustFn(-1)} className="text-slate-500 hover:text-white transition-colors px-2 text-2xl leading-none">−</button>
                            <span className="font-bold text-lg w-8 text-center">{count}</span>
                            <button onClick={() => adjustFn(+1)} className="text-slate-500 hover:text-white transition-colors px-2 text-2xl leading-none">+</button>
                          </div>
                        ) : (
                          <span className="font-bold text-lg">{count}</span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="flex-1 flex items-center justify-center text-slate-500"><p className="text-sm">Choose a Legend first</p></div>
          )}
        </div>
      </div>

      {/* Battlefields */}
      <div className="bg-slate-900/30 p-2 rounded-3xl">
        <h3 className="text-sm font-black text-slate-400 mb-2 px-1">BATTLEFIELDS ({selectedBattlefields.length}/3)</h3>
        <div className="grid grid-cols-3 gap-3">
          {selectedBattlefields.map((card, index) => (
            <div key={index} className="relative aspect-[3/2] group">
              <img src={card.media.image_url} alt={card.name} className={`w-full h-full object-cover rounded-xl ${bfMissingIds.has(card.id) ? 'grayscale opacity-50' : ''}`} />
              {isEditMode && (
                <button onClick={() => setSelectedBattlefields(selectedBattlefields.filter((_, i) => i !== index))} className="absolute top-2 right-2 p-1 bg-red-600 hover:bg-red-500 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity">
                  <Plus size={16} className="rotate-45 text-white" />
                </button>
              )}
              <p className="text-xs font-bold text-center mt-2">{card.name}</p>
            </div>
          ))}
          {isEditMode && selectedBattlefields.length < 3 && (
            <button onClick={() => openCardModal('battlefields')} className="aspect-[3/2] bg-slate-800 border-2 border-dashed border-slate-700 rounded-xl hover:border-amber-600 transition-all flex items-center justify-center group">
              <Plus size={32} className="text-slate-600 group-hover:text-amber-500 transition-colors" />
            </button>
          )}
        </div>
      </div>

      {/* Main Deck */}
      <DeckCardSection title="MAIN DECK" cards={customMainDeck} maxCards={40} allCards={allCards} cardLookup={cardLookup} isEditMode={isEditMode}
        getTotalCopies={getTotalCopies} getQuantity={showCollectionStatus ? getQuantity : null}
        onAdd={() => openCardModal('main')}
        onIncrement={(cardId) => handleIncrement(cardId, setCustomMainDeck)}
        onDecrement={(cardId) => setCustomMainDeck(prev => { const n = prev[cardId] - 1; if (n <= 0) { const d = { ...prev }; delete d[cardId]; return d; } return { ...prev, [cardId]: n }; })}
      />

      {/* Side Deck */}
      <DeckCardSection title="SIDE DECK" cards={customSideboard} maxCards={8} allCards={allCards} cardLookup={cardLookup} isEditMode={isEditMode}
        getTotalCopies={getTotalCopies} getQuantity={showCollectionStatus ? getQuantity : null}
        onAdd={() => openCardModal('side')}
        onIncrement={(cardId) => handleIncrement(cardId, setCustomSideboard)}
        onDecrement={(cardId) => setCustomSideboard(prev => { const n = prev[cardId] - 1; if (n <= 0) { const d = { ...prev }; delete d[cardId]; return d; } return { ...prev, [cardId]: n }; })}
      />

      {/* Energy Curve */}
      <ManaCurveChart cards={customMainDeck} cardLookup={cardLookup} />

      {/* Spacer for FABs */}
      <div className="h-20" />

      {/* FAB - Back (bottom-left, slides from Save button position) */}
      <button
        onClick={handleBack}
        className="fixed left-6 bottom-6 w-14 h-14 rounded-full shadow-2xl flex items-center justify-center active:scale-95 z-50 bg-slate-700 active:bg-slate-600"
        style={{ animation: 'fab-back-from-right 0.4s cubic-bezier(0.4, 0, 0.2, 1) both' }}
        title="Back"
      >
        <ArrowLeft size={24} className="text-white" />
      </button>

      {/* FAB - Edit/Save (user decks) or Copy (meta decks) */}
      {isMetaDeck ? (
        <button
          onClick={() => duplicateDeck(getCurrentDeckForValidation())}
          className="fixed right-6 bottom-6 w-14 h-14 rounded-full shadow-2xl flex items-center justify-center active:scale-95 z-50 bg-amber-600 active:bg-amber-500"
          style={{ animation: 'fab-slide-down 0.4s cubic-bezier(0.4, 0, 0.2, 1) both' }}
          title="Copy to My Decks"
        >
          <Copy size={24} className="text-white" />
        </button>
      ) : (
        <button
          onClick={() => { if (isEditMode) { if (hasUnsavedChanges) { setShowSaveDialog(true); } else { setIsEditMode(false); setEditSnapshot(null); } } else { enterEditMode(); } }}
          className={`fixed right-6 bottom-6 w-14 h-14 rounded-full shadow-2xl flex items-center justify-center active:scale-95 z-50 transition-[background-color] duration-[350ms] ${
            isEditMode && hasUnsavedChanges ? 'bg-emerald-600 active:bg-emerald-500' : 'bg-amber-600 active:bg-amber-500'
          }`}
          style={{
            animation: isEditMode && hasUnsavedChanges
              ? 'fab-slide-down 0.4s cubic-bezier(0.4, 0, 0.2, 1) both, fab-breathe 3s ease-in-out 0.4s infinite'
              : 'fab-slide-down 0.4s cubic-bezier(0.4, 0, 0.2, 1) both',
          }}
        >
          {isEditMode ? <Save size={24} className="text-white" /> : <Edit size={24} className="text-white" />}
        </button>
      )}
      <style>{`
        @keyframes fab-slide-down {
          from { transform: translateY(-4.5rem); }
          to { transform: translateY(0); }
        }
        @keyframes fab-back-from-right {
          from { transform: translateX(calc(100vw - 6.5rem)); }
          to { transform: translateX(0); }
        }
        @keyframes fab-breathe {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.12); }
        }
      `}</style>

      {/* Save/Discard Dialog */}
      {showSaveDialog && (
        <div className="fixed inset-0 z-[99999] flex items-center justify-center" onClick={() => setShowSaveDialog(false)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative bg-slate-900 border border-slate-700 rounded-2xl p-6 mx-6 max-w-sm w-full shadow-2xl" onClick={e => e.stopPropagation()}>
            <h3 className="text-lg font-black text-white mb-2">Save Changes?</h3>
            <p className="text-sm text-slate-400 mb-6">Do you want to save your changes or discard them?</p>
            <div className="flex gap-3">
              <button
                onClick={handleDiscard}
                className="flex-1 py-3 rounded-xl font-bold text-sm bg-slate-800 text-slate-300 active:scale-95 transition-all"
              >
                Discard
              </button>
              <button
                onClick={handleSaveAndExit}
                className="flex-1 py-3 rounded-xl font-bold text-sm bg-emerald-600 text-white active:scale-95 transition-all"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}

      <CardSelectionModal isOpen={showCardModal} onClose={() => setShowCardModal(false)} onDiscard={handleCardModalDiscard} category={cardSelectionCategory} allCards={allCards} cardLookup={cardLookup} selectedLegend={selectedLegend} selectedBattlefields={selectedBattlefields} onSelectCard={handleSelectCard}
        onRemoveCard={(card) => {
          if (cardSelectionCategory === 'battlefields') {
            setSelectedBattlefields(prev => prev.filter(bf => bf.id !== card.id));
          } else if (cardSelectionCategory === 'main') {
            setCustomMainDeck(prev => {
              const n = (prev[card.id] || 0) - 1;
              if (n <= 0) { const d = { ...prev }; delete d[card.id]; return d; }
              return { ...prev, [card.id]: n };
            });
          } else if (cardSelectionCategory === 'side') {
            setCustomSideboard(prev => {
              const n = (prev[card.id] || 0) - 1;
              if (n <= 0) { const d = { ...prev }; delete d[card.id]; return d; }
              return { ...prev, [card.id]: n };
            });
          }
        }}
        customMainDeck={customMainDeck} customSideboard={customSideboard}
      />
      <EditDeckModal isOpen={showEditDeckModal} onClose={() => { setShowEditDeckModal(false); setEditingDeckData(null); }} deck={editingDeckData} onSave={handleSaveEditedDeck} />
      <ImportDeckModal isOpen={showImportModal} onClose={() => setShowImportModal(false)} onImport={handleImportDeck} />
    </div>
  );
}

// ========================================
// ManaCurveChart - energy cost distribution
// ========================================
function ManaCurveChart({ cards, cardLookup }) {
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
// DeckCardSection - shows + button disabled when at copy limit
// ========================================
function DeckCardSection({ title, cards, maxCards, allCards, cardLookup, isEditMode, onAdd, onIncrement, onDecrement, getTotalCopies, getQuantity }) {
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
    <div className="bg-slate-900/30 p-2 rounded-3xl">
      <h3 className="text-sm font-black text-slate-400 mb-2 px-1">{title} ({totalCount}/{maxCards})</h3>
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

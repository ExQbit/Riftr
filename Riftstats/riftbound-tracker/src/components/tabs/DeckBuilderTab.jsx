import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  Plus, Eye, EyeOff, Save, Edit, Copy,
  MoreVertical, ArrowLeft, Check,
} from 'lucide-react';
import { RUNE_COLORS } from '../../constants/gameData';
import CardSelectionModal from '../modals/CardSelectionModal';
import AuthorProfile from '../shared/AuthorProfile';
import EditDeckModal from '../modals/EditDeckModal';
import ImportDeckModal from '../modals/ImportDeckModal';
import DeckMenu from '../DeckMenu';
import { exportDeck, exportDeckTts, importDeck } from '../../utils/deckFormat';
import { SECTION_BG, SECTION_TITLE } from '../../constants/design';
import { useUI } from '../shared/UIProvider';
import { useGameData, useAppData } from '../../contexts/AppContexts';
import { getMaxCopies, ManaCurveChart, DeckCardSection } from './DeckBuilderComponents';
import DeckBuilderOverview from './DeckBuilderOverview';

export default function DeckBuilderTab({ onEditModeChange }) {
  const { allCards, cardLookup } = useGameData();
  const {
    savedDecks, saveDeck, deleteDeck, duplicateDeck,
    publishDeck: onPublishDeck, updateDeckMeta, validateDeck,
    getQuantity, publicDecks, myPublishedDeckNames,
    user, matchStats: stats,
    follow, unfollow, isFollowing, getFollowerCount, myFollowing,
  } = useAppData();
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
  const [showImportModal, setShowImportModal] = useState(false);
  const [showDeckMenu, setShowDeckMenu] = useState(false);
  const ui = useUI();

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
    if (!showDeckMenu) return;
    const handler = () => setShowDeckMenu(false);
    document.addEventListener('click', handler);
    return () => document.removeEventListener('click', handler);
  }, [showDeckMenu]);

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
    setShowDeckMenu(false);
  };

  const handleSaveEditedDeck = async (deckId, name, description) => {
    await updateDeckMeta(deckId, name, description);
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

  // ========================================
  // OVERVIEW VIEW
  // ========================================
  if (view === 'overview') {
    return (
      <DeckBuilderOverview
        onLoadDeck={loadDeck}
        onNewDeck={() => { resetEditor(); setView('create'); }}
        onShowAuthor={(author) => { setSelectedAuthor(author); setView('author'); }}
        lastEditedDeckId={lastEditedDeckId}
        onHighlightDeck={setLastEditedDeckId}
      />
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
              <button onClick={(e) => { e.stopPropagation(); setShowDeckMenu(!showDeckMenu); }} className="p-2 text-slate-400 hover:text-white transition-all">
                <MoreVertical size={20} />
              </button>
              {showDeckMenu && (
                <DeckMenu deck={getCurrentDeckForValidation()} isValid={currentValidation.isValid}
                  onPublish={() => { if (editingDeckId) onPublishDeck(getCurrentDeckForValidation()); }}
                  onExport={handleExportDeck}
                  onExportTts={handleExportTts}
                  onImport={() => setShowImportModal(true)}
                  onEdit={() => openEditModal({ id: editingDeckId, name: deckName, description: deckDescription })}
                  onDuplicate={() => { if (editingDeckId) duplicateDeck(getCurrentDeckForValidation()); }}
                  onDelete={() => { if (editingDeckId) { deleteDeck(editingDeckId); setView('overview'); } }}
                  onClose={() => setShowDeckMenu(false)}
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
      <div className={SECTION_BG}>
        <h3 className={SECTION_TITLE}>BATTLEFIELDS ({selectedBattlefields.length}/3)</h3>
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


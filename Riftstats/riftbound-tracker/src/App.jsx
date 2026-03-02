import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { X, Zap } from 'lucide-react';

// --- Hooks ---
import useAuth from './hooks/useAuth';
import useCards from './hooks/useCards';
import useMatches from './hooks/useMatches';
import useDecks from './hooks/useDecks';
import useCollection from './hooks/useCollection';
import usePublicDecks from './hooks/usePublicDecks';
import useFollows from './hooks/useFollows';

// --- Components ---
import LoginScreen from './components/LoginScreen';
import BottomNav from './components/BottomNav';
import UIProvider, { useUI } from './components/shared/UIProvider';
import ProModal from './components/modals/ProModal';

// --- Tabs ---
import CardsTab from './components/tabs/CardsTab';
import CollectionTab from './components/tabs/CollectionTab';
import TrackerTab from './components/tabs/TrackerTab';
import StatsTab from './components/tabs/StatsTab';
import DeckBuilderTab from './components/tabs/DeckBuilderTab';
import SocialTab from './components/tabs/SocialTab';

// --- Demo ---
import { generateDemoData } from './data/demoData';

export default function App() {
  return (
    <UIProvider>
      <AppContent />
    </UIProvider>
  );
}

function LandscapeOverlay() {
  const [isLandscape, setIsLandscape] = useState(false);

  useEffect(() => {
    const check = () => {
      setIsLandscape(window.innerWidth > window.innerHeight && window.innerWidth < 1024);
    };
    check();
    window.addEventListener('resize', check);
    window.addEventListener('orientationchange', () => setTimeout(check, 100));
    return () => {
      window.removeEventListener('resize', check);
    };
  }, []);

  if (!isLandscape) return null;

  return (
    <div className="fixed inset-0 z-[999999] bg-slate-950 flex items-center justify-center">
      <div className="text-center px-8">
        <div className="text-6xl mb-6" style={{ animation: 'rotate-phone 2s ease-in-out infinite' }}>📱</div>
        <h2 className="text-xl font-black text-white mb-2">Please Rotate</h2>
        <p className="text-sm text-slate-400">Riftbound Pro works best in portrait mode</p>
      </div>
      <style>{`
        @keyframes rotate-phone {
          0%, 100% { transform: rotate(90deg); }
          50% { transform: rotate(0deg); }
        }
      `}</style>
    </div>
  );
}

function AppContent() {
  const [activeTab, setActiveTab] = useState('tracker');
  const [deckResetKey, setDeckResetKey] = useState(0);
  const [deckEditMode, setDeckEditMode] = useState(false);
  const [trackerFullscreen, setTrackerFullscreen] = useState(false);

  // --- Demo Mode ---
  const [isDemoMode, setIsDemoMode] = useState(false);
  const [demoData, setDemoData] = useState(null);

  // --- Hooks ---
  const { user, loading: authLoading, logout } = useAuth();
  const { allCards, cardLookup } = useCards();
  const ui = useUI();
  const { matches, stats, saveMatch, updateMatchNotes, updateMatchGames, deleteMatch, clearAll, exportCSV } = useMatches(user, ui);
  const {
    savedDecks, saveDeck, deleteDeck, duplicateDeck,
    updateDeckMeta, validateDeck
  } = useDecks(user, allCards, cardLookup, ui);
  const {
    collection, addCard, removeCard, getQuantity,
    stats: collectionStats, loading: collectionLoading
  } = useCollection(user);
  const { publicDecks, myPublishCount, myPublishedDeckNames, publishDeckToPublic } = usePublicDecks(user, ui);
  const { myFollowing, follow, unfollow, isFollowing, getFollowerCount } = useFollows(user);

  // --- Pro Modal ---
  const [showProModal, setShowProModal] = useState(false);

  const handlePublishDeck = useCallback(async (deck) => {
    const validation = validateDeck(deck);
    const result = await publishDeckToPublic(deck, validation);
    if (result?.blocked) {
      setShowProModal(true);
    }
  }, [validateDeck, publishDeckToPublic]);

  // --- Demo Mode Handlers ---
  const activateDemo = useCallback(() => {
    const data = generateDemoData(allCards, cardLookup);
    if (!data) return;
    setDemoData(data);
    setIsDemoMode(true);
  }, [allCards, cardLookup]);

  const deactivateDemo = useCallback(() => {
    setIsDemoMode(false);
    setDemoData(null);
  }, []);

  // --- Effective data (demo or real) ---
  const effectiveMatches = isDemoMode && demoData ? demoData.demoMatches : matches;
  const effectiveStats = isDemoMode && demoData ? demoData.demoStats : stats;
  const effectiveDecks = isDemoMode && demoData ? demoData.demoDecks : savedDecks;
  const effectiveCollection = isDemoMode && demoData ? demoData.demoCollection : collection;
  const effectiveGetQuantity = useCallback((cardId) => {
    if (isDemoMode && demoData) return demoData.demoCollection[cardId] || 0;
    return getQuantity(cardId);
  }, [isDemoMode, demoData, getQuantity]);
  const effectiveCollectionStats = useMemo(() => {
    if (isDemoMode && demoData) {
      const col = demoData.demoCollection;
      const ownedIds = Object.keys(col).filter(id => col[id] > 0);
      return { totalOwned: ownedIds.length, totalCopies: Object.values(col).reduce((s, q) => s + q, 0), collection: col };
    }
    return collectionStats;
  }, [isDemoMode, demoData, collectionStats]);

  // Demo collection mutators — update demoData state so +/- buttons work
  const demoAddCard = useCallback((cardId) => {
    setDemoData(prev => {
      if (!prev) return prev;
      const col = { ...prev.demoCollection };
      col[cardId] = (col[cardId] || 0) + 1;
      return { ...prev, demoCollection: col };
    });
  }, []);

  const demoRemoveCard = useCallback((cardId) => {
    setDemoData(prev => {
      if (!prev) return prev;
      const col = { ...prev.demoCollection };
      if ((col[cardId] || 0) > 0) col[cardId] = col[cardId] - 1;
      return { ...prev, demoCollection: col };
    });
  }, []);

  // Demo deck mutators — allow creating, editing, deleting decks in demo mode
  const demoSaveDeck = useCallback(async (deckData, editingDeckId) => {
    if (!deckData.name?.trim()) return;
    setDemoData(prev => {
      if (!prev) return prev;
      const now = new Date().toISOString();
      const data = {
        name: deckData.name,
        description: deckData.description || '',
        legend: deckData.selectedLegend?.id || null,
        legendData: deckData.selectedLegend ? {
          id: deckData.selectedLegend.id,
          name: deckData.selectedLegend.name,
          media: deckData.selectedLegend.media,
          classification: deckData.selectedLegend.classification
        } : null,
        battlefields: (deckData.battlefields || []).map(bf => ({ id: bf.id, name: bf.name, media: bf.media })),
        runeCount1: deckData.runeCount1,
        runeCount2: deckData.runeCount2,
        mainDeck: deckData.mainDeck,
        sideboard: deckData.sideboard,
        updatedAt: now,
      };
      if (editingDeckId) {
        const decks = prev.demoDecks.map(d => d.id === editingDeckId ? { ...d, ...data } : d);
        return { ...prev, demoDecks: decks };
      } else {
        const id = `demo-deck-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
        return { ...prev, demoDecks: [...prev.demoDecks, { ...data, id, createdAt: now }] };
      }
    });
  }, []);

  const demoDeleteDeck = useCallback(async (deckId) => {
    setDemoData(prev => {
      if (!prev) return prev;
      return { ...prev, demoDecks: prev.demoDecks.filter(d => d.id !== deckId) };
    });
  }, []);

  const demoDuplicateDeck = useCallback(async (deck) => {
    setDemoData(prev => {
      if (!prev) return prev;
      const now = new Date().toISOString();
      const id = `demo-deck-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
      const copy = { ...deck, id, name: deck.name + ' (Copy)', updatedAt: now, createdAt: now };
      delete copy.isPrebuilt;
      delete copy.source;
      delete copy.sourceUrl;
      delete copy.placement;
      delete copy.sets;
      return { ...prev, demoDecks: [...prev.demoDecks, copy] };
    });
  }, []);

  const demoUpdateDeckMeta = useCallback(async (deckId, name, description) => {
    if (!name?.trim()) return;
    setDemoData(prev => {
      if (!prev) return prev;
      const decks = prev.demoDecks.map(d => d.id === deckId ? { ...d, name: name.trim(), description: (description || '').trim() } : d);
      return { ...prev, demoDecks: decks };
    });
  }, []);

  // No-op wrappers for demo mode
  const noop = useCallback(() => {}, []);
  const effectiveSaveMatch = isDemoMode ? noop : saveMatch;
  const effectiveUpdateNotes = isDemoMode ? noop : updateMatchNotes;
  const effectiveUpdateGames = isDemoMode ? noop : updateMatchGames;
  const effectiveDeleteMatch = isDemoMode ? noop : deleteMatch;
  const effectiveClearAll = isDemoMode ? noop : clearAll;
  const effectiveExportCSV = isDemoMode ? noop : exportCSV;

  // --- Loading ---
  if (authLoading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center text-amber-500 font-bold">
        Loading...
      </div>
    );
  }

  // --- Login ---
  if (!user) {
    return <LoginScreen />;
  }

  // --- Save match and switch to stats ---
  const handleSaveMatch = async (matchData) => {
    await effectiveSaveMatch(matchData);
    setActiveTab('stats');
    setTrackerFullscreen(false);
  };

  // --- Tab change handler ---
  const handleTabChange = (tab) => {
    if (tab === 'deckbuilder') {
      setDeckResetKey(k => k + 1);
    }
    setDeckEditMode(false);
    setTrackerFullscreen(false);
    setActiveTab(tab);
    window.scrollTo(0, 0);
  };

  const hideNav = deckEditMode || trackerFullscreen;
  const hidePadding = trackerFullscreen || activeTab === 'deckbuilder'; // tracker + deckbuilder handle own padding

  // --- Render active tab ---
  const renderTab = () => {
    switch (activeTab) {
      case 'cards':
        return <CardsTab allCards={allCards} />;

      case 'collection':
        return (
          <CollectionTab
            allCards={allCards}
            collection={effectiveCollection}
            addCard={isDemoMode ? demoAddCard : addCard}
            removeCard={isDemoMode ? demoRemoveCard : removeCard}
            getQuantity={effectiveGetQuantity}
            stats={effectiveCollectionStats}
          />
        );

      case 'tracker':
        return (
          <TrackerTab
            allCards={allCards}
            cardLookup={cardLookup}
            savedDecks={effectiveDecks}
            validateDeck={validateDeck}
            onSaveMatch={handleSaveMatch}
            onFullscreenChange={setTrackerFullscreen}
            onActivateDemo={activateDemo}
            isDemoMode={isDemoMode}
          />
        );

      case 'stats':
        return (
          <StatsTab
            stats={effectiveStats}
            matches={effectiveMatches}
            allCards={allCards}
            savedDecks={effectiveDecks}
            updateMatchNotes={effectiveUpdateNotes}
            updateMatchGames={effectiveUpdateGames}
            deleteMatch={effectiveDeleteMatch}
            exportCSV={effectiveExportCSV}
            clearAll={effectiveClearAll}
            onActivateDemo={activateDemo}
            isDemoMode={isDemoMode}
          />
        );

      case 'deckbuilder':
        return (
          <DeckBuilderTab
            key={deckResetKey}
            allCards={allCards}
            cardLookup={cardLookup}
            savedDecks={isDemoMode ? effectiveDecks : savedDecks}
            saveDeck={isDemoMode ? demoSaveDeck : saveDeck}
            deleteDeck={isDemoMode ? demoDeleteDeck : deleteDeck}
            duplicateDeck={isDemoMode ? demoDuplicateDeck : duplicateDeck}
            onPublishDeck={isDemoMode ? noop : handlePublishDeck}
            updateDeckMeta={isDemoMode ? demoUpdateDeckMeta : updateDeckMeta}
            validateDeck={validateDeck}
            onEditModeChange={setDeckEditMode}
            getQuantity={getQuantity}
            publicDecks={publicDecks}
            myPublishedDeckNames={myPublishedDeckNames}
            user={user}
            stats={effectiveStats}
            follow={isDemoMode ? noop : follow}
            unfollow={isDemoMode ? noop : unfollow}
            isFollowing={isFollowing}
            getFollowerCount={getFollowerCount}
            myFollowing={myFollowing}
          />
        );

      case 'social':
        return (
          <SocialTab
            user={user}
            allCards={allCards}
            cardLookup={cardLookup}
            publicDecks={publicDecks}
            savedDecks={isDemoMode ? effectiveDecks : savedDecks}
            stats={effectiveStats}
            myFollowing={myFollowing}
            follow={isDemoMode ? noop : follow}
            unfollow={isDemoMode ? noop : unfollow}
            isFollowing={isFollowing}
            getFollowerCount={getFollowerCount}
            getQuantity={effectiveGetQuantity}
            onTabChange={handleTabChange}
            logout={logout}
          />
        );

      default:
        return null;
    }
  };

  // --- Main App ---
  return (
    <div className={`min-h-screen bg-slate-950 text-slate-100 select-none ${hideNav ? '' : 'pb-24'}`}>
      <LandscapeOverlay />

      {/* Demo Mode Banner */}
      {isDemoMode && (
        <div className="sticky top-0 z-[100] bg-amber-500/10 border-b border-amber-500/30 px-4 py-2.5 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Zap size={14} className="text-amber-400" />
            <span className="text-xs font-bold text-amber-300">Demo Mode</span>
            <span className="text-[10px] text-amber-400/70">Viewing sample data</span>
          </div>
          <button
            onClick={deactivateDemo}
            className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-500/20 text-amber-300 text-[10px] font-bold active:scale-95 transition-all"
          >
            <X size={12} />
            Exit Demo
          </button>
        </div>
      )}

      <main className={hidePadding ? '' : 'max-w-full mx-auto px-2 py-4'}>
        {renderTab()}
      </main>
      <BottomNav activeTab={activeTab} onTabChange={handleTabChange} hidden={hideNav} />
      <ProModal isOpen={showProModal} onClose={() => setShowProModal(false)} />
    </div>
  );
}

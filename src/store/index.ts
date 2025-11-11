import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  Card,
  CollectionEntry,
  Deck,
  UserSettings,
  UserStats,
  BoosterPack,
  CardPrice,
  PointTransaction,
  PointsStats,
  FeaturedCard,
  CommunityStats,
  LeaderboardEntry
} from '../types';
import { STORAGE_KEYS } from '../constants';

// Collection Store
interface CollectionStore {
  collection: Map<string, CollectionEntry>;
  addToCollection: (cardId: string, quantity?: number) => void;
  removeFromCollection: (cardId: string, quantity?: number) => void;
  toggleOwned: (cardId: string) => void;
  updateQuantity: (cardId: string, quantity: number) => void;
  importCollection: (data: Record<string, CollectionEntry>) => void;
  exportCollection: () => Record<string, CollectionEntry>;
  clearCollection: () => void;
  getCollectionStats: () => {
    totalCards: number;
    uniqueCards: number;
    completionRate: number;
  };
}

export const useCollectionStore = create<CollectionStore>()(
  persist(
    (set, get) => ({
      collection: new Map(),
      
      addToCollection: (cardId: string, quantity = 1) => {
        set((state) => {
          const newCollection = new Map(state.collection);
          const existing = newCollection.get(cardId);
          
          if (existing) {
            newCollection.set(cardId, {
              ...existing,
              quantity: existing.quantity + quantity,
              owned: true,
            });
          } else {
            newCollection.set(cardId, {
              cardId,
              owned: true,
              quantity,
              foil: false,
              dateAdded: new Date().toISOString(),
              variants: ['normal'],
            });
          }
          
          return { collection: newCollection };
        });
      },
      
      removeFromCollection: (cardId: string, quantity = 1) => {
        set((state) => {
          const newCollection = new Map(state.collection);
          const existing = newCollection.get(cardId);
          
          if (existing) {
            const newQuantity = Math.max(0, existing.quantity - quantity);
            
            if (newQuantity === 0) {
              newCollection.delete(cardId);
            } else {
              newCollection.set(cardId, {
                ...existing,
                quantity: newQuantity,
              });
            }
          }
          
          return { collection: newCollection };
        });
      },
      
      toggleOwned: (cardId: string) => {
        set((state) => {
          const newCollection = new Map(state.collection);
          const existing = newCollection.get(cardId);
          
          if (existing) {
            newCollection.set(cardId, {
              ...existing,
              owned: !existing.owned,
            });
          } else {
            newCollection.set(cardId, {
              cardId,
              owned: true,
              quantity: 1,
              foil: false,
              dateAdded: new Date().toISOString(),
              variants: ['normal'],
            });
          }
          
          return { collection: newCollection };
        });
      },
      
      updateQuantity: (cardId: string, quantity: number) => {
        set((state) => {
          const newCollection = new Map(state.collection);
          
          if (quantity === 0) {
            newCollection.delete(cardId);
          } else {
            const existing = newCollection.get(cardId);
            if (existing) {
              newCollection.set(cardId, {
                ...existing,
                quantity,
              });
            } else {
              newCollection.set(cardId, {
                cardId,
                owned: true,
                quantity,
                foil: false,
                dateAdded: new Date().toISOString(),
                variants: ['normal'],
              });
            }
          }
          
          return { collection: newCollection };
        });
      },
      
      importCollection: (data: Record<string, CollectionEntry>) => {
        set({ collection: new Map(Object.entries(data)) });
      },
      
      exportCollection: () => {
        const state = get();
        return Object.fromEntries(state.collection);
      },
      
      clearCollection: () => {
        set({ collection: new Map() });
      },
      
      getCollectionStats: () => {
        const state = get();
        const totalCards = Array.from(state.collection.values()).reduce(
          (sum, entry) => sum + entry.quantity,
          0
        );
        const uniqueCards = state.collection.size;
        // Assume 50 total cards for now (from mock data)
        const completionRate = (uniqueCards / 50) * 100;
        
        return {
          totalCards,
          uniqueCards,
          completionRate,
        };
      },
    }),
    {
      name: STORAGE_KEYS.collection,
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        collection: Object.fromEntries(state.collection),
      }),
      onRehydrateStorage: () => (state) => {
        if (state && state.collection) {
          state.collection = new Map(Object.entries(state.collection as any));
        }
      },
    }
  )
);

// Deck Store
interface DeckStore {
  decks: Deck[];
  createDeck: (deck: Omit<Deck, 'id' | 'dateCreated' | 'dateModified'>) => void;
  updateDeck: (deckId: string, updates: Partial<Deck>) => void;
  deleteDeck: (deckId: string) => void;
  duplicateDeck: (deckId: string) => void;
}

export const useDeckStore = create<DeckStore>()(
  persist(
    (set) => ({
      decks: [],
      
      createDeck: (deckData) => {
        const newDeck: Deck = {
          ...deckData,
          id: Date.now().toString(),
          dateCreated: new Date().toISOString(),
          dateModified: new Date().toISOString(),
        };
        
        set((state) => ({
          decks: [...state.decks, newDeck],
        }));
      },
      
      updateDeck: (deckId, updates) => {
        set((state) => ({
          decks: state.decks.map((deck) =>
            deck.id === deckId
              ? { ...deck, ...updates, dateModified: new Date().toISOString() }
              : deck
          ),
        }));
      },
      
      deleteDeck: (deckId) => {
        set((state) => ({
          decks: state.decks.filter((deck) => deck.id !== deckId),
        }));
      },
      
      duplicateDeck: (deckId) => {
        set((state) => {
          const deckToDuplicate = state.decks.find((deck) => deck.id === deckId);
          if (!deckToDuplicate) return state;
          
          const newDeck: Deck = {
            ...deckToDuplicate,
            id: Date.now().toString(),
            name: `${deckToDuplicate.name} (Copy)`,
            dateCreated: new Date().toISOString(),
            dateModified: new Date().toISOString(),
          };
          
          return { decks: [...state.decks, newDeck] };
        });
      },
    }),
    {
      name: STORAGE_KEYS.decks,
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

// Settings Store
interface SettingsStore {
  settings: UserSettings;
  updateSettings: (settings: Partial<UserSettings>) => void;
  resetSettings: () => void;
}

const defaultSettings: UserSettings = {
  theme: 'dark',
  animationsEnabled: true,
  soundEnabled: true,
  hapticEnabled: true,
  gridColumns: 3,
  showOwned: true,
  showUnowned: true,
};

export const useSettingsStore = create<SettingsStore>()(
  persist(
    (set) => ({
      settings: defaultSettings,

      updateSettings: (newSettings) => {
        set((state) => ({
          settings: { ...state.settings, ...newSettings },
        }));
      },

      resetSettings: () => {
        set({ settings: defaultSettings });
      },
    }),
    {
      name: STORAGE_KEYS.settings,
      storage: createJSONStorage(() => AsyncStorage),
      merge: (persistedState, currentState) => {
        // Ensure boolean types are preserved during rehydration
        const merged = { ...currentState, ...persistedState } as SettingsStore;
        if (merged.settings) {
          merged.settings = {
            ...defaultSettings,
            ...merged.settings,
            animationsEnabled: Boolean(merged.settings.animationsEnabled),
            soundEnabled: Boolean(merged.settings.soundEnabled),
            hapticEnabled: Boolean(merged.settings.hapticEnabled),
            showOwned: Boolean(merged.settings.showOwned),
            showUnowned: Boolean(merged.settings.showUnowned),
          };
        }
        return merged;
      },
    }
  )
);

// Pack History Store
interface PackHistoryStore {
  packHistory: BoosterPack[];
  currency: number;
  lastClaimDate: string | null;
  addPackOpening: (pack: BoosterPack) => void;
  updateCurrency: (amount: number) => void;
  spendCurrency: (amount: number) => boolean;
  claimDailyBonus: () => boolean;
  canClaimDaily: () => boolean;
  clearHistory: () => void;
}

export const usePackStore = create<PackHistoryStore>()(
  persist(
    (set, get) => ({
      packHistory: [],
      currency: 500, // Start with 500 virtual currency
      lastClaimDate: null,

      addPackOpening: (pack) => {
        set((state) => ({
          packHistory: [
            { ...pack, openedDate: new Date().toISOString() },
            ...state.packHistory,
          ].slice(0, 100), // Keep only last 100 pack openings
        }));
      },

      updateCurrency: (amount) => {
        set((state) => ({
          currency: Math.max(0, state.currency + amount),
        }));
      },

      spendCurrency: (amount) => {
        const state = get();
        if (state.currency >= amount) {
          set({ currency: state.currency - amount });
          return true;
        }
        return false;
      },

      canClaimDaily: () => {
        const state = get();
        if (!state.lastClaimDate) return true;

        const lastClaim = new Date(state.lastClaimDate);
        const now = new Date();
        const hoursSinceLastClaim = (now.getTime() - lastClaim.getTime()) / (1000 * 60 * 60);

        return hoursSinceLastClaim >= 24;
      },

      claimDailyBonus: () => {
        const state = get();
        if (!state.canClaimDaily()) return false;

        set({
          currency: state.currency + 100,
          lastClaimDate: new Date().toISOString(),
        });
        return true;
      },

      clearHistory: () => {
        set({ packHistory: [] });
      },
    }),
    {
      name: STORAGE_KEYS.packHistory,
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

// Stats Store
interface StatsStore {
  stats: UserStats;
  updateStats: (stats: Partial<UserStats>) => void;
  incrementPacksOpened: () => void;
  calculateCollectionValue: () => void;
}

const defaultStats: UserStats = {
  totalPacksOpened: 0,
  totalCards: 0,
  uniqueCards: 0,
  collectionValue: 0,
  completionRate: 0,
};

export const useStatsStore = create<StatsStore>()(
  persist(
    (set) => ({
      stats: defaultStats,
      
      updateStats: (newStats) => {
        set((state) => ({
          stats: { ...state.stats, ...newStats },
        }));
      },
      
      incrementPacksOpened: () => {
        set((state) => ({
          stats: {
            ...state.stats,
            totalPacksOpened: state.stats.totalPacksOpened + 1,
            lastPackOpened: new Date().toISOString(),
          },
        }));
      },
      
      calculateCollectionValue: () => {
        // Placeholder calculation - would use actual market prices in production
        const collection = useCollectionStore.getState().collection;
        const value = Array.from(collection.values()).reduce((sum, entry) => {
          // Simple value calculation based on assumed rarity values
          return sum + entry.quantity * 10; // Placeholder value
        }, 0);
        
        set((state) => ({
          stats: { ...state.stats, collectionValue: value },
        }));
      },
    }),
    {
      name: STORAGE_KEYS.stats,
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

// First Launch Store
interface FirstLaunchStore {
  isFirstLaunch: boolean;
  setFirstLaunchComplete: () => void;
}

export const useFirstLaunchStore = create<FirstLaunchStore>()(
  persist(
    (set) => ({
      isFirstLaunch: true,

      setFirstLaunchComplete: () => {
        set({ isFirstLaunch: false });
      },
    }),
    {
      name: STORAGE_KEYS.firstLaunch,
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

// Points Tracker Store
interface PointsStore {
  points: PointsStats;
  addPoints: (amount: number, reason: string) => void;
  spendPoints: (amount: number, reason: string) => boolean;
  updateDailyStreak: () => void;
  resetPoints: () => void;
}

const defaultPoints: PointsStats = {
  totalPoints: 0,
  pointsEarned: 0,
  pointsSpent: 0,
  transactions: [],
  dailyStreak: 0,
  lastActivity: new Date().toISOString(),
};

export const usePointsStore = create<PointsStore>()(
  persist(
    (set, get) => ({
      points: defaultPoints,

      addPoints: (amount, reason) => {
        const transaction: PointTransaction = {
          id: Date.now().toString(),
          type: 'earn',
          amount,
          reason,
          date: new Date().toISOString(),
        };

        set((state) => ({
          points: {
            ...state.points,
            totalPoints: state.points.totalPoints + amount,
            pointsEarned: state.points.pointsEarned + amount,
            transactions: [transaction, ...state.points.transactions].slice(0, 100),
            lastActivity: new Date().toISOString(),
          },
        }));
      },

      spendPoints: (amount, reason) => {
        const state = get();
        if (state.points.totalPoints < amount) {
          return false;
        }

        const transaction: PointTransaction = {
          id: Date.now().toString(),
          type: 'spend',
          amount,
          reason,
          date: new Date().toISOString(),
        };

        set({
          points: {
            ...state.points,
            totalPoints: state.points.totalPoints - amount,
            pointsSpent: state.points.pointsSpent + amount,
            transactions: [transaction, ...state.points.transactions].slice(0, 100),
            lastActivity: new Date().toISOString(),
          },
        });

        return true;
      },

      updateDailyStreak: () => {
        set((state) => {
          const lastActivity = new Date(state.points.lastActivity);
          const now = new Date();
          const hoursSinceLastActivity = (now.getTime() - lastActivity.getTime()) / (1000 * 60 * 60);

          let newStreak = state.points.dailyStreak;
          if (hoursSinceLastActivity >= 24 && hoursSinceLastActivity < 48) {
            newStreak += 1;
          } else if (hoursSinceLastActivity >= 48) {
            newStreak = 1;
          }

          return {
            points: {
              ...state.points,
              dailyStreak: newStreak,
              lastActivity: new Date().toISOString(),
            },
          };
        });
      },

      resetPoints: () => {
        set({ points: defaultPoints });
      },
    }),
    {
      name: STORAGE_KEYS.points,
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

// Card Pricing Store
interface PricingStore {
  prices: Map<string, CardPrice>;
  updatePrice: (cardId: string, price: Omit<CardPrice, 'cardId'>) => void;
  getPrice: (cardId: string) => CardPrice | undefined;
  clearPrices: () => void;
}

export const usePricingStore = create<PricingStore>()(
  persist(
    (set, get) => ({
      prices: new Map(),

      updatePrice: (cardId, priceData) => {
        set((state) => {
          const newPrices = new Map(state.prices);
          newPrices.set(cardId, {
            ...priceData,
            cardId,
          });
          return { prices: newPrices };
        });
      },

      getPrice: (cardId) => {
        const state = get();
        return state.prices.get(cardId);
      },

      clearPrices: () => {
        set({ prices: new Map() });
      },
    }),
    {
      name: STORAGE_KEYS.pricing,
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        prices: Object.fromEntries(state.prices),
      }),
      onRehydrateStorage: () => (state) => {
        if (state && state.prices) {
          state.prices = new Map(Object.entries(state.prices as any));
        }
      },
    }
  )
);

// Featured Cards Store
interface FeaturedCardsStore {
  featuredCards: FeaturedCard[];
  currentFeaturedCard: FeaturedCard | null;
  setFeaturedCards: (cards: FeaturedCard[]) => void;
  updateCurrentFeaturedCard: () => void;
}

export const useFeaturedCardsStore = create<FeaturedCardsStore>()(
  persist(
    (set, get) => ({
      featuredCards: [],
      currentFeaturedCard: null,

      setFeaturedCards: (cards) => {
        set({ featuredCards: cards });
        get().updateCurrentFeaturedCard();
      },

      updateCurrentFeaturedCard: () => {
        const state = get();
        const now = new Date();

        const currentCard = state.featuredCards.find((card) => {
          const start = new Date(card.startDate);
          const end = new Date(card.endDate);
          return now >= start && now <= end;
        });

        set({ currentFeaturedCard: currentCard || null });
      },
    }),
    {
      name: STORAGE_KEYS.featuredCards,
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

// Community Stats Store (Read-only, fetched from backend)
interface CommunityStore {
  stats: CommunityStats | null;
  leaderboard: LeaderboardEntry[];
  updateCommunityStats: (stats: CommunityStats) => void;
  updateLeaderboard: (leaderboard: LeaderboardEntry[]) => void;
}

const defaultCommunityStats: CommunityStats = {
  totalUsers: 0,
  totalCardsCollected: 0,
  mostCollectedCard: '',
  rarityDistribution: {
    common: 0,
    uncommon: 0,
    rare: 0,
    legendary: 0,
  },
};

export const useCommunityStore = create<CommunityStore>()(
  persist(
    (set) => ({
      stats: defaultCommunityStats,
      leaderboard: [],

      updateCommunityStats: (stats) => {
        set({ stats });
      },

      updateLeaderboard: (leaderboard) => {
        set({ leaderboard });
      },
    }),
    {
      name: STORAGE_KEYS.community,
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

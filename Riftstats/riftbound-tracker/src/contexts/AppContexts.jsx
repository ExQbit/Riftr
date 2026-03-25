import { createContext, useContext, useMemo } from 'react';

// --- Game Data Context (static card data) ---
const GameContext = createContext(null);

export function GameProvider({ allCards, cardLookup, children }) {
  const value = useMemo(() => ({ allCards, cardLookup }), [allCards, cardLookup]);
  return <GameContext.Provider value={value}>{children}</GameContext.Provider>;
}

export function useGameData() {
  const ctx = useContext(GameContext);
  if (!ctx) throw new Error('useGameData must be used within GameProvider');
  return ctx;
}

// --- App Data Context (user data + mutators, demo-aware) ---
const DataContext = createContext(null);

export function DataProvider({ value, children }) {
  return <DataContext.Provider value={value}>{children}</DataContext.Provider>;
}

export function useAppData() {
  const ctx = useContext(DataContext);
  if (!ctx) throw new Error('useAppData must be used within DataProvider');
  return ctx;
}

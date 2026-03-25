import { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { db, appId } from '../constants/firebase';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';

const CACHE_KEY = (uid) => `riftstats_${uid}_collection`;
const DEBOUNCE_MS = 500;

export default function useCollection(user) {
  const [collection, setCollection] = useState({}); // { cardId: quantity }
  const [loading, setLoading] = useState(true);
  const debounceTimerRef = useRef(null);
  const pendingCollectionRef = useRef(null);

  // Listen to collection doc
  useEffect(() => {
    if (!user) { setCollection({}); setLoading(false); return; }

    // Load cached data immediately
    try {
      const cached = localStorage.getItem(CACHE_KEY(user.uid));
      if (cached) {
        setCollection(JSON.parse(cached));
        setLoading(false);
      }
    } catch { /* ignore corrupt cache */ }

    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'data', 'collection');
    return onSnapshot(ref, (snap) => {
      const data = snap.exists() ? (snap.data().cards || {}) : {};
      setCollection(data);
      setLoading(false);
      try { localStorage.setItem(CACHE_KEY(user.uid), JSON.stringify(data)); } catch { /* quota */ }
    });
  }, [user]);

  // Cleanup debounce timer on unmount
  useEffect(() => {
    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, []);

  // Save entire collection to Firestore (called by debounce)
  const saveCollection = useCallback(async (newCollection) => {
    if (!user) return;
    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'data', 'collection');
    await setDoc(ref, { cards: newCollection, updatedAt: new Date().toISOString() }, { merge: true });
  }, [user]);

  // Debounced save — batches rapid writes into a single Firestore call
  const debouncedSave = useCallback((newCollection) => {
    pendingCollectionRef.current = newCollection;
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }
    debounceTimerRef.current = setTimeout(() => {
      debounceTimerRef.current = null;
      if (pendingCollectionRef.current !== null) {
        saveCollection(pendingCollectionRef.current);
        pendingCollectionRef.current = null;
      }
    }, DEBOUNCE_MS);
  }, [saveCollection]);

  // Update single card quantity
  const updateCard = useCallback((cardId, quantity) => {
    setCollection(prev => {
      const newCollection = { ...prev };
      if (quantity <= 0) {
        delete newCollection[cardId];
      } else {
        newCollection[cardId] = quantity;
      }
      debouncedSave(newCollection);
      return newCollection;
    });
  }, [debouncedSave]);

  // Increment card
  const addCard = useCallback((cardId) => {
    setCollection(prev => {
      const current = prev[cardId] || 0;
      const newCollection = { ...prev, [cardId]: current + 1 };
      debouncedSave(newCollection);
      return newCollection;
    });
  }, [debouncedSave]);

  // Decrement card
  const removeCard = useCallback((cardId) => {
    setCollection(prev => {
      const current = prev[cardId] || 0;
      if (current <= 0) return prev;
      const newCollection = { ...prev };
      if (current - 1 <= 0) {
        delete newCollection[cardId];
      } else {
        newCollection[cardId] = current - 1;
      }
      debouncedSave(newCollection);
      return newCollection;
    });
  }, [debouncedSave]);

  // Get quantity for a card
  const getQuantity = useCallback((cardId) => {
    return collection[cardId] || 0;
  }, [collection]);

  // Stats
  const stats = useMemo(() => {
    const ownedIds = Object.keys(collection).filter(id => collection[id] > 0);
    const totalOwned = ownedIds.length;
    const totalCopies = Object.values(collection).reduce((sum, q) => sum + q, 0);
    return { totalOwned, totalCopies, collection };
  }, [collection]);

  return {
    collection,
    loading,
    addCard,
    removeCard,
    updateCard,
    getQuantity,
    stats,
  };
}

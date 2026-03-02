import { useState, useEffect, useMemo, useCallback } from 'react';
import { db, appId } from '../constants/firebase';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';

export default function useCollection(user) {
  const [collection, setCollection] = useState({}); // { cardId: quantity }
  const [loading, setLoading] = useState(true);

  // Listen to collection doc
  useEffect(() => {
    if (!user) { setCollection({}); setLoading(false); return; }
    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'data', 'collection');
    return onSnapshot(ref, (snap) => {
      if (snap.exists()) {
        setCollection(snap.data().cards || {});
      } else {
        setCollection({});
      }
      setLoading(false);
    });
  }, [user]);

  // Save entire collection (debounced writes)
  const saveCollection = useCallback(async (newCollection) => {
    if (!user) return;
    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'data', 'collection');
    await setDoc(ref, { cards: newCollection, updatedAt: new Date().toISOString() }, { merge: true });
  }, [user]);

  // Update single card quantity
  const updateCard = useCallback(async (cardId, quantity) => {
    const newCollection = { ...collection };
    if (quantity <= 0) {
      delete newCollection[cardId];
    } else {
      newCollection[cardId] = quantity;
    }
    setCollection(newCollection); // optimistic update
    await saveCollection(newCollection);
  }, [collection, saveCollection]);

  // Increment card
  const addCard = useCallback(async (cardId) => {
    const current = collection[cardId] || 0;
    await updateCard(cardId, current + 1);
  }, [collection, updateCard]);

  // Decrement card
  const removeCard = useCallback(async (cardId) => {
    const current = collection[cardId] || 0;
    if (current > 0) await updateCard(cardId, current - 1);
  }, [collection, updateCard]);

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

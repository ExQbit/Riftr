import { useState, useEffect, useCallback } from 'react';
import { db, appId } from '../constants/firebase';
import { collection, doc, addDoc, deleteDoc, setDoc, updateDoc, onSnapshot } from 'firebase/firestore';
// Note: publishDeck removed — now handled by usePublicDecks hook

export default function useDecks(user, allCards, cardLookup, ui) {
  const [savedDecks, setSavedDecks] = useState([]);

  useEffect(() => {
    if (!user) return;
    const ref = collection(db, `artifacts/${appId}/users/${user.uid}/decks`);
    return onSnapshot(ref, (snap) => {
      setSavedDecks(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
  }, [user]);

  const saveDeck = useCallback(async (deckData, editingDeckId) => {
    if (!user) { ui?.toast('You must be signed in!', 'error'); return; }
    if (!deckData.name?.trim()) { ui?.toast('Please enter a deck name!', 'warning'); return; }

    try {
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
        updatedAt: new Date().toISOString()
      };
      if (!editingDeckId) data.createdAt = new Date().toISOString();

      const ref = editingDeckId
        ? doc(db, `artifacts/${appId}/users/${user.uid}/decks/${editingDeckId}`)
        : doc(collection(db, `artifacts/${appId}/users/${user.uid}/decks`));
      await setDoc(ref, data);
    } catch (error) {
      ui?.toast('Error saving: ' + error.message, 'error');
    }
  }, [user, ui]);

  const deleteDeck = useCallback(async (deckId) => {
    if (!user) return;
    const confirmed = await ui?.confirm('Are you sure you want to delete this deck?', {
      title: 'Delete Deck',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      danger: true,
    });
    if (!confirmed) return;
    try {
      await deleteDoc(doc(db, `artifacts/${appId}/users/${user.uid}/decks/${deckId}`));
      ui?.toast('Deck deleted', 'success');
    } catch (error) {
      ui?.toast('Error deleting: ' + error.message, 'error');
    }
  }, [user, ui]);

  const duplicateDeck = useCallback(async (deck) => {
    if (!user) return;
    try {
      const now = new Date().toISOString();
      const copy = { ...deck, name: deck.name + ' (Copy)', updatedAt: now };
      // Strip meta-deck-specific fields
      delete copy.id;
      delete copy.isPrebuilt;
      delete copy.source;
      delete copy.sourceUrl;
      delete copy.placement;
      delete copy.sets;
      if (!copy.createdAt || deck.isPrebuilt) copy.createdAt = now;
      await addDoc(collection(db, `artifacts/${appId}/users/${user.uid}/decks`), copy);
      ui?.toast('Deck duplicated!', 'success');
    } catch (error) {
      ui?.toast('Error duplicating: ' + error.message, 'error');
    }
  }, [user, ui]);

  const updateDeckMeta = useCallback(async (deckId, name, description) => {
    if (!user || !name?.trim()) return;
    try {
      await updateDoc(doc(db, `artifacts/${appId}/users/${user.uid}/decks/${deckId}`), {
        name: name.trim(),
        description: (description || '').trim()
      });
    } catch (error) {
      ui?.toast('Error: ' + error.message, 'error');
    }
  }, [user, ui]);

  const validateDeck = useCallback((deck) => {
    const errors = [];
    const legendCard = deck.legendData || (deck.legend ? allCards.find(c => c.id === deck.legend) : null);

    if (!legendCard) errors.push('No Legend selected');

    const totalRunes = (deck.runeCount1 || 0) + (deck.runeCount2 || 0);
    if (totalRunes !== 12) errors.push(`Runes: ${totalRunes}/12 (must be exactly 12)`);

    const bfCount = (deck.battlefields || []).length;
    if (bfCount !== 3) errors.push(`Battlefields: ${bfCount}/3 (must be exactly 3)`);

    const mainCount = Object.values(deck.mainDeck || {}).reduce((s, c) => s + c, 0);
    if (mainCount !== 40) errors.push(`Main Deck: ${mainCount}/40 cards`);

    const sideCount = Object.values(deck.sideboard || {}).reduce((s, c) => s + c, 0);
    if (sideCount > 0 && sideCount !== 8) errors.push(`Sideboard: ${sideCount}/8 (must be 0 or 8)`);

    const nameCountMap = {};
    for (const [key, count] of Object.entries(deck.mainDeck || {})) {
      const card = cardLookup?.get(key) || allCards.find(c => c.id === key || c.name === key);
      if (card) nameCountMap[card.name] = (nameCountMap[card.name] || 0) + count;
    }
    for (const [key, count] of Object.entries(deck.sideboard || {})) {
      const card = cardLookup?.get(key) || allCards.find(c => c.id === key || c.name === key);
      if (card) nameCountMap[card.name] = (nameCountMap[card.name] || 0) + count;
    }
    for (const [name, count] of Object.entries(nameCountMap)) {
      const card = cardLookup?.get(name) || allCards.find(c => c.name === name);
      const max = card?.deck_limit ?? card?.attributes?.deck_limit ?? 3;
      if (count > max) errors.push(`${name}: ${count} copies (max ${max})`);
    }

    if (legendCard) {
      const domains = legendCard.classification?.domain || [];
      for (const [name] of Object.entries(nameCountMap)) {
        const card = cardLookup?.get(name) || allCards.find(c => c.name === name);
        if (card) {
          const cardDomains = card.classification?.domain || [];
          if (!cardDomains.every(d => domains.includes(d))) {
            errors.push(`${name}: Domain mismatch`);
          }
        }
      }
    }

    return { isValid: errors.length === 0, errors };
  }, [allCards, cardLookup]);

  return { savedDecks, saveDeck, deleteDeck, duplicateDeck, updateDeckMeta, validateDeck };
}

import { useState, useEffect, useCallback, useMemo } from 'react';
import { db, appId } from '../constants/firebase';
import { collection, addDoc, onSnapshot, query, orderBy, getDocs, where } from 'firebase/firestore';
import { t } from '../constants/i18n';

const FREE_PUBLISH_LIMIT = 2;

export default function usePublicDecks(user, ui) {
  const [publicDecks, setPublicDecks] = useState([]);

  // Listen to all public decks
  useEffect(() => {
    const ref = collection(db, `artifacts/${appId}/publicDecks`);
    const q = query(ref, orderBy('publishedAt', 'desc'));
    return onSnapshot(q, (snap) => {
      setPublicDecks(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    }, (err) => {
      console.error('Public decks listener error:', err);
    });
  }, []);

  // Count how many decks this user has published
  const myPublishCount = useMemo(() => {
    if (!user) return 0;
    return publicDecks.filter(d => d.authorId === user.uid).length;
  }, [publicDecks, user]);

  // Publish a deck to the public collection
  const publishDeckToPublic = useCallback(async (deck, validation) => {
    if (!user) {
      ui?.toast('You must be signed in!', 'error');
      return { blocked: false, error: true };
    }

    if (user.isAnonymous) {
      ui?.alert(t.guestCannotPublish, { title: t.loginToPublish });
      return { blocked: false, error: true };
    }

    if (!validation?.isValid) {
      ui?.alert('Deck is not valid:\n\n' + (validation?.errors || []).join('\n'), { title: 'Cannot Publish' });
      return { blocked: false, error: true };
    }

    // Check publish limit with real-time Firestore query (avoids stale state race)
    try {
      const ref = collection(db, `artifacts/${appId}/publicDecks`);
      const q = query(ref, where('authorId', '==', user.uid));
      const snap = await getDocs(q);
      if (snap.size >= FREE_PUBLISH_LIMIT) {
        return { blocked: true };
      }
    } catch (err) {
      console.error('Error checking publish limit:', err);
      // Fall back to local count
      if (myPublishCount >= FREE_PUBLISH_LIMIT) {
        return { blocked: true };
      }
    }

    try {
      const legendCard = deck.legendData || null;
      const domains = legendCard?.classification?.domain || [];

      const publicDeckData = {
        name: deck.name || 'Untitled Deck',
        description: deck.description || '',
        legendData: legendCard ? {
          id: legendCard.id,
          name: legendCard.name,
          media: legendCard.media,
          classification: legendCard.classification,
        } : null,
        battlefields: (deck.battlefields || []).map(bf => ({
          id: bf.id,
          name: bf.name,
          media: bf.media,
        })),
        runeCount1: deck.runeCount1 ?? deck.runeCount1 ?? 6,
        runeCount2: deck.runeCount2 ?? deck.runeCount2 ?? 6,
        mainDeck: deck.mainDeck || {},
        sideboard: deck.sideboard || {},
        authorId: user.uid,
        authorName: user.displayName || user.email?.split('@')[0] || 'Anonymous',
        domains,
        legendName: legendCard?.name || '',
        publishedAt: new Date().toISOString(),
      };

      const ref = collection(db, `artifacts/${appId}/publicDecks`);
      await addDoc(ref, publicDeckData);
      ui?.toast('Deck published!', 'success');
      return { blocked: false };
    } catch (error) {
      ui?.toast('Error publishing: ' + error.message, 'error');
      return { blocked: false, error: true };
    }
  }, [user, ui, myPublishCount]);

  // Set of deck names the current user has published (for "published" badge in My Decks)
  const myPublishedDeckNames = useMemo(() => {
    if (!user) return new Set();
    return new Set(publicDecks.filter(d => d.authorId === user.uid).map(d => d.name));
  }, [publicDecks, user]);

  return { publicDecks, myPublishCount, myPublishedDeckNames, publishDeckToPublic };
}

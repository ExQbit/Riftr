import { useState, useEffect, useMemo } from 'react';
import { db, appId } from '../constants/firebase';
import { collection, addDoc, deleteDoc, getDocs, doc, onSnapshot, updateDoc } from 'firebase/firestore';
import { computeStats } from '../utils/computeStats';

export default function useMatches(user, ui) {
  const [matches, setMatches] = useState([]);

  useEffect(() => {
    if (!user) { setMatches([]); return; }
    const ref = collection(db, 'artifacts', appId, 'users', user.uid, 'matches');
    return onSnapshot(ref, (snap) => {
      setMatches(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
  }, [user]);

  const saveMatch = async (matchData) => {
    if (!user) return;
    await addDoc(collection(db, 'artifacts', appId, 'users', user.uid, 'matches'), {
      ...matchData,
      notes: '',
      timestamp: new Date().toISOString(),
    });
  };

  const updateMatchNotes = async (matchId, notes) => {
    if (!user || !matchId) return;
    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'matches', matchId);
    await updateDoc(ref, { notes });
  };

  const updateMatchGames = async (matchId, games) => {
    if (!user || !matchId) return;
    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'matches', matchId);
    await updateDoc(ref, { games });
  };

  const deleteMatch = async (matchId) => {
    if (!user || !matchId) return;
    const confirmed = await ui?.confirm('Delete this match?', {
      title: 'Delete Match',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      danger: true,
    });
    if (!confirmed) return;
    await deleteDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'matches', matchId));
    ui?.toast('Match deleted', 'success');
  };

  const clearAll = async () => {
    if (!user) return;
    const confirmed = await ui?.confirm('This will permanently delete all your match data.', {
      title: 'Delete All Data',
      confirmText: 'Delete All',
      cancelText: 'Cancel',
      danger: true,
    });
    if (!confirmed) return;
    const snap = await getDocs(collection(db, 'artifacts', appId, 'users', user.uid, 'matches'));
    await Promise.all(snap.docs.map(d => deleteDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'matches', d.id))));
    ui?.toast('All data deleted', 'success');
  };

  const exportCSV = () => {
    if (matches.length === 0) return;
    const headers = 'Date,Deck,Legend,Opponent,Start,My Score,Opp Score,Result,Notes\n';
    const rows = matches.map(m =>
      `${new Date(m.timestamp).toLocaleDateString()},${m.deckName || 'Unknown'},${m.legendName || ''},${m.opponent},${m.isFirst ? '1st' : '2nd'},${m.myScore ?? '-'},${m.oppScore ?? '-'},${m.result},"${(m.notes || '').replace(/"/g, '""')}"`
    ).join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'riftbound_stats.csv';
    a.click();
  };

  // Stats computation (extracted to utility)
  const stats = useMemo(() => computeStats(matches), [matches]);

  return { matches, stats, saveMatch, updateMatchNotes, updateMatchGames, deleteMatch, clearAll, exportCSV };
}

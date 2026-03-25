import { useState, useEffect, useCallback, useMemo } from 'react';
import { db, appId } from '../constants/firebase';
import { collection, addDoc, deleteDoc, onSnapshot, query, where, getDocs } from 'firebase/firestore';

export default function useFollows(user) {
  const [allFollows, setAllFollows] = useState([]);

  // Listen to all follows
  useEffect(() => {
    const ref = collection(db, `artifacts/${appId}/follows`);
    return onSnapshot(ref, (snap) => {
      setAllFollows(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    }, (err) => {
      console.error('Follows listener error:', err);
    });
  }, []);

  // IDs the current user is following
  const myFollowing = useMemo(() => {
    if (!user) return [];
    return allFollows.filter(f => f.followerId === user.uid).map(f => f.followedId);
  }, [allFollows, user]);

  // Follower counts per author
  const followerCounts = useMemo(() => {
    const counts = {};
    for (const f of allFollows) {
      counts[f.followedId] = (counts[f.followedId] || 0) + 1;
    }
    return counts;
  }, [allFollows]);

  const isFollowing = useCallback((authorId) => {
    return myFollowing.includes(authorId);
  }, [myFollowing]);

  const getFollowerCount = useCallback((authorId) => {
    return followerCounts[authorId] || 0;
  }, [followerCounts]);

  const follow = useCallback(async (authorId) => {
    if (!user || user.uid === authorId) return;
    if (myFollowing.includes(authorId)) return;
    try {
      const ref = collection(db, `artifacts/${appId}/follows`);
      await addDoc(ref, {
        followerId: user.uid,
        followedId: authorId,
        followedAt: new Date().toISOString(),
      });
    } catch (err) {
      console.error('Error following:', err);
    }
  }, [user, myFollowing]);

  const unfollow = useCallback(async (authorId) => {
    if (!user) return;
    try {
      const ref = collection(db, `artifacts/${appId}/follows`);
      const q = query(ref, where('followerId', '==', user.uid), where('followedId', '==', authorId));
      const snap = await getDocs(q);
      for (const doc of snap.docs) {
        await deleteDoc(doc.ref);
      }
    } catch (err) {
      console.error('Error unfollowing:', err);
    }
  }, [user]);

  return { myFollowing, follow, unfollow, isFollowing, getFollowerCount };
}

import { useState, useEffect, useCallback, useRef } from 'react';
import { db, appId } from '../constants/firebase';
import { doc, onSnapshot, setDoc, getDoc } from 'firebase/firestore';
import { updateProfile as firebaseUpdateProfile } from 'firebase/auth';

export default function useProfile(user) {
  const [profile, setProfile] = useState(null);
  const [profileLoading, setProfileLoading] = useState(true);
  const [profileCache, setProfileCache] = useState(new Map());
  const fetchedRef = useRef(new Set()); // track already-fetched UIDs

  // Listen to own profile doc
  useEffect(() => {
    if (!user) { setProfile(null); setProfileLoading(false); return; }
    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'data', 'profile');
    return onSnapshot(ref, (snap) => {
      if (snap.exists()) {
        setProfile(snap.data());
      } else {
        setProfile(null);
      }
      setProfileLoading(false);
    });
  }, [user]);

  // Update own profile
  const updateProfile = useCallback(async (updates) => {
    if (!user) return;
    const ref = doc(db, 'artifacts', appId, 'users', user.uid, 'data', 'profile');
    const data = { ...updates, updatedAt: new Date().toISOString() };
    await setDoc(ref, data, { merge: true });

    // Sync displayName to Firebase Auth
    if (updates.displayName) {
      try {
        await firebaseUpdateProfile(user, { displayName: updates.displayName });
      } catch (err) {
        console.error('Error syncing displayName to Auth:', err);
      }
    }
  }, [user]);

  // Fetch profiles for a list of UIDs (cached)
  const fetchProfiles = useCallback(async (uids) => {
    if (!uids || uids.length === 0) return;
    const toFetch = uids.filter(uid => !fetchedRef.current.has(uid));
    if (toFetch.length === 0) return;

    const results = new Map(profileCache);
    await Promise.all(toFetch.map(async (uid) => {
      try {
        const ref = doc(db, 'artifacts', appId, 'users', uid, 'data', 'profile');
        const snap = await getDoc(ref);
        if (snap.exists()) {
          results.set(uid, snap.data());
        }
        fetchedRef.current.add(uid);
      } catch (err) {
        console.error('Error fetching profile for', uid, err);
        fetchedRef.current.add(uid); // don't retry on error
      }
    }));
    setProfileCache(results);
  }, [profileCache]);

  return { profile, profileLoading, updateProfile, fetchProfiles, profileCache };
}

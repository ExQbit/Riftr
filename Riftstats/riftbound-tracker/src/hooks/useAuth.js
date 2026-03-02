import { useState, useEffect } from 'react';
import { auth } from '../constants/firebase';
import { onAuthStateChanged, signOut } from 'firebase/auth';

export default function useAuth() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // onAuthStateChanged fires once immediately with persisted user (or null)
    // This is the ONLY place we set loading to false
    const unsubscribe = onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  const logout = () => signOut(auth);

  return { user, loading, logout };
}
